"""APK repackage pipeline — ELF dependency injection for Android.

Patches the ARM64 split APK to load libinject.so via DT_NEEDED.
Does NOT touch base.apk DEX files (avoids protection shell detection).

Usage:
    python build_apk.py                        # default: patch arm64 split
    python build_apk.py --skip-native          # skip NDK build (use existing .so)
    python build_apk.py --apk-dir /path/to/WWM_APK
    python build_apk.py --target-lib libGame.so  # which .so to patch (default: auto)
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent  # -> Where Winds Meet/
DEFAULT_APK_DIR = PROJECT_ROOT / "WWM_APK"
NATIVE_DIR = SCRIPT_DIR / "native"
OUTPUT_DIR = SCRIPT_DIR / "output"

KEYSTORE = SCRIPT_DIR / "debug.keystore"
KEY_ALIAS = "wwm_debug"
KEY_PASS = "android"


def run(cmd: list[str], check: bool = True, **kw) -> subprocess.CompletedProcess:
    """Run a subprocess with logging."""
    print(f"  $ {' '.join(cmd)}")
    # On Windows, tools like apktool/apksigner are .cmd/.bat shims
    if sys.platform == "win32":
        kw.setdefault("shell", True)
    return subprocess.run(cmd, check=check, **kw)


def find_tool(name: str) -> str:
    """Find a tool in PATH or common Android SDK locations."""
    result = shutil.which(name)
    if result:
        return result
    sdk_root = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if sdk_root:
        for bt in Path(sdk_root).glob("build-tools/*/"):
            candidate = bt / (name + (".bat" if sys.platform == "win32" else ""))
            if candidate.exists():
                return str(candidate)
    raise FileNotFoundError(f"Tool not found: {name}. Add it to PATH.")


def build_native(ndk_path: str | None = None) -> Path:
    """Build libinject.so via NDK cmake."""
    ndk = ndk_path or os.environ.get("ANDROID_NDK_HOME")
    if not ndk or not Path(ndk).exists():
        raise FileNotFoundError(
            "Android NDK not found. Set ANDROID_NDK_HOME or pass --ndk"
        )

    build_dir = NATIVE_DIR / "build"
    build_dir.mkdir(parents=True, exist_ok=True)

    toolchain = Path(ndk) / "build" / "cmake" / "android.toolchain.cmake"
    cmake = shutil.which("cmake")
    if not cmake:
        raise FileNotFoundError("cmake not found")

    run([cmake, "-S", str(NATIVE_DIR), "-B", str(build_dir),
         f"-DCMAKE_TOOLCHAIN_FILE={toolchain}",
         "-DANDROID_ABI=arm64-v8a",
         "-DANDROID_PLATFORM=android-24",
         "-DCMAKE_BUILD_TYPE=Release",
         "-G", "Ninja"])
    run([cmake, "--build", str(build_dir), "--config", "Release"])

    so_path = build_dir / "libinject.so"
    if not so_path.exists():
        raise FileNotFoundError(f"Build failed: {so_path} not found")

    print(f"  Built: {so_path} ({so_path.stat().st_size / 1024:.1f} KB)")
    return so_path


# =========================================================================
# ELF patching — surgical byte-level DT_NEEDED injection
# Avoids LIEF's binary.write() which rewrites the entire ELF and corrupts
# GOT/PLT entries, causing SIGSEGV in the patched library's constructors.
# =========================================================================

import struct as _struct


def find_best_target_lib(arm64_dir: Path) -> str:
    """Find the best .so to patch in the ARM64 split.

    Requires: >=2 DT_NULL entries (1 spare + 1 terminator) and >=13 bytes
    of zero padding after .dynstr for the "libinject.so\\0" string.
    AVOID libybuaxz.so — it's the protection shell and hash-checks itself.
    """
    lib_dir = arm64_dir / "lib" / "arm64-v8a"
    if not lib_dir.exists():
        raise FileNotFoundError(f"No lib/arm64-v8a in {arm64_dir}")

    # Priority: libraries confirmed to have spare DT_NULL + strtab padding
    # and that load at game startup (audio subsystem inits early)
    preferred = [
        "libAudioCore.so",    # 1.1MB, 5 DT_NULL, 16B strtab padding, loads early
        "libAudioEngine.so",  # 2.1MB, 5 DT_NULL, audio subsystem
        "libccplayer.so",     # 1.1MB, 5 DT_NULL, media player
        "libCommonLib.so",    # 3.9MB, 5 DT_NULL, common utility
    ]
    for name in preferred:
        if (lib_dir / name).exists():
            return name

    # Fallback: first .so with enough room for manual patching
    for f in sorted(lib_dir.glob("*.so"), key=lambda p: p.stat().st_size):
        if f.name == "libybuaxz.so":
            continue
        info = _analyze_elf_for_patch(f)
        if info and info["spare_null"] >= 1 and info["after_padding"] >= 13:
            return f.name

    raise FileNotFoundError("No patchable .so files found in ARM64 lib dir")


def _analyze_elf_for_patch(so_path: Path) -> dict | None:
    """Analyze an ELF for manual DT_NEEDED patching feasibility."""
    data = so_path.read_bytes()
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4] != 2:
        return None  # not ELF64

    e_phoff = _struct.unpack_from("<Q", data, 32)[0]
    e_phentsize = _struct.unpack_from("<H", data, 54)[0]
    e_phnum = _struct.unpack_from("<H", data, 56)[0]

    dyn_off = dyn_size = 0
    loads = []
    for i in range(e_phnum):
        ph = e_phoff + i * e_phentsize
        p_type = _struct.unpack_from("<I", data, ph)[0]
        p_offset = _struct.unpack_from("<Q", data, ph + 8)[0]
        p_vaddr = _struct.unpack_from("<Q", data, ph + 16)[0]
        p_filesz = _struct.unpack_from("<Q", data, ph + 32)[0]
        if p_type == 2:  # PT_DYNAMIC
            dyn_off, dyn_size = p_offset, p_filesz
        if p_type == 1:  # PT_LOAD
            loads.append((p_offset, p_vaddr, p_filesz))

    if dyn_off == 0:
        return None

    strtab_addr = strsz = 0
    null_count = 0
    for j in range(dyn_size // 16):
        pos = dyn_off + j * 16
        d_tag = _struct.unpack_from("<q", data, pos)[0]
        d_val = _struct.unpack_from("<Q", data, pos + 8)[0]
        if d_tag == 0:
            null_count += 1
        elif d_tag == 5:
            strtab_addr = d_val
        elif d_tag == 10:
            strsz = d_val

    strtab_foff = 0
    for loff, lvaddr, lfsz in loads:
        if lvaddr <= strtab_addr < lvaddr + lfsz:
            strtab_foff = loff + (strtab_addr - lvaddr)
            break

    after_padding = 0
    if strtab_foff > 0 and strsz > 0:
        end_pos = strtab_foff + strsz
        for k in range(min(64, len(data) - end_pos)):
            if data[end_pos + k] == 0:
                after_padding += 1
            else:
                break

    return {
        "spare_null": null_count - 1,
        "after_padding": after_padding,
    }


def patch_elf_add_needed(so_path: Path, needed_lib: str = "libinject.so") -> bool:
    """Surgically patch an ELF to add a DT_NEEDED entry via byte-level writes.

    Strategy (no LIEF rewrite — preserves all existing relocations):
      1. Write the library name string in zero-padding after .dynstr
      2. Update DT_STRSZ to cover the new string
      3. Overwrite one spare DT_NULL entry with DT_NEEDED
    """
    print(f"  Patching {so_path.name} to add DT_NEEDED: {needed_lib}")

    data = bytearray(so_path.read_bytes())
    needed_bytes = needed_lib.encode("ascii") + b"\x00"
    needed_len = len(needed_bytes)  # 13 for "libinject.so\0"

    # ---- Parse ELF64 program headers ----
    e_phoff = _struct.unpack_from("<Q", data, 32)[0]
    e_phentsize = _struct.unpack_from("<H", data, 54)[0]
    e_phnum = _struct.unpack_from("<H", data, 56)[0]

    dyn_off = dyn_size = 0
    loads = []
    for i in range(e_phnum):
        ph = e_phoff + i * e_phentsize
        p_type = _struct.unpack_from("<I", data, ph)[0]
        p_offset = _struct.unpack_from("<Q", data, ph + 8)[0]
        p_vaddr = _struct.unpack_from("<Q", data, ph + 16)[0]
        p_filesz = _struct.unpack_from("<Q", data, ph + 32)[0]
        if p_type == 2:  # PT_DYNAMIC
            dyn_off, dyn_size = p_offset, p_filesz
        if p_type == 1:  # PT_LOAD
            loads.append((p_offset, p_vaddr, p_filesz))

    if dyn_off == 0:
        print("  ERROR: No PT_DYNAMIC segment found")
        return False

    # ---- Parse .dynamic entries ----
    DT_NEEDED, DT_NULL, DT_STRTAB, DT_STRSZ = 1, 0, 5, 10
    strtab_addr = strsz = 0
    strsz_entry_off = 0
    null_entries = []  # file offsets of DT_NULL entries
    existing_needed = []

    for j in range(dyn_size // 16):
        pos = dyn_off + j * 16
        d_tag = _struct.unpack_from("<q", data, pos)[0]
        d_val = _struct.unpack_from("<Q", data, pos + 8)[0]

        if d_tag == DT_NULL:
            null_entries.append(pos)
        elif d_tag == DT_NEEDED:
            existing_needed.append(d_val)
        elif d_tag == DT_STRTAB:
            strtab_addr = d_val
        elif d_tag == DT_STRSZ:
            strsz = d_val
            strsz_entry_off = pos

    # Convert strtab vaddr -> file offset
    strtab_foff = 0
    for loff, lvaddr, lfsz in loads:
        if lvaddr <= strtab_addr < lvaddr + lfsz:
            strtab_foff = loff + (strtab_addr - lvaddr)
            break

    if strtab_foff == 0:
        print("  ERROR: Could not resolve DT_STRTAB to file offset")
        return False

    # Check if already patched
    str_write_off = strtab_foff + strsz
    for nval in existing_needed:
        name_start = strtab_foff + nval
        name_end = data.index(0, name_start)
        name = data[name_start:name_end].decode("latin-1")
        if name == needed_lib:
            print(f"  Already has {needed_lib} in DT_NEEDED, skipping")
            return True

    # Validate space
    if len(null_entries) < 2:
        print(f"  ERROR: Need >=2 DT_NULL entries (have {len(null_entries)})")
        return False

    # Check zero-padding after .dynstr
    for k in range(needed_len):
        if str_write_off + k >= len(data) or data[str_write_off + k] != 0:
            print(f"  ERROR: Not enough zero-padding after .dynstr "
                  f"(need {needed_len} bytes, byte {k} is non-zero)")
            return False

    # ---- Patch 1: Write library name string after .dynstr ----
    new_str_offset = strsz  # offset relative to DT_STRTAB
    data[str_write_off:str_write_off + needed_len] = needed_bytes
    print(f"  Wrote '{needed_lib}' at file offset 0x{str_write_off:x} "
          f"(strtab offset {new_str_offset})")

    # ---- Patch 2: Update DT_STRSZ to cover the new string ----
    new_strsz = strsz + needed_len
    _struct.pack_into("<Q", data, strsz_entry_off + 8, new_strsz)
    print(f"  Updated DT_STRSZ: {strsz} -> {new_strsz}")

    # ---- Patch 3: Replace first DT_NULL with DT_NEEDED ----
    patch_pos = null_entries[0]
    _struct.pack_into("<q", data, patch_pos, DT_NEEDED)
    _struct.pack_into("<Q", data, patch_pos + 8, new_str_offset)
    print(f"  Wrote DT_NEEDED at file offset 0x{patch_pos:x} "
          f"(remaining DT_NULL: {len(null_entries) - 1})")

    # ---- Write patched binary ----
    so_path.write_bytes(bytes(data))
    print(f"  Patched! {so_path.name} now loads {needed_lib}")
    return True


# =========================================================================
# APK manipulation
# =========================================================================

def patch_arm64_split(
    apk_dir: Path,
    libinject_so: Path,
    target_lib: str | None = None,
) -> Path:
    """Patch the ARM64 split APK with libinject.so via ELF DT_NEEDED injection.

    1. Extract ARM64 split
    2. Add libinject.so to lib/arm64-v8a/
    3. Patch target .so to add DT_NEEDED for libinject.so
    4. Repack, zipalign, sign
    """
    split_apk = apk_dir / "split_config.arm64_v8a.apk"
    if not split_apk.exists():
        raise FileNotFoundError(f"ARM64 split not found: {split_apk}")

    work_dir = OUTPUT_DIR / "work_arm64"
    if work_dir.exists():
        shutil.rmtree(work_dir)
    work_dir.mkdir(parents=True)

    # --- Step 1: Extract split ---
    print("\n[1/4] Extracting ARM64 split...")
    with zipfile.ZipFile(split_apk) as z:
        z.extractall(work_dir)

    lib_dir = work_dir / "lib" / "arm64-v8a"
    if not lib_dir.exists():
        raise FileNotFoundError("No lib/arm64-v8a in ARM64 split")

    # --- Step 2: Copy libinject.so ---
    print("\n[2/4] Injecting libinject.so...")
    shutil.copy2(libinject_so, lib_dir / "libinject.so")
    print(f"  Copied libinject.so ({libinject_so.stat().st_size / 1024:.1f} KB)")

    # Also copy libdobby.so if built as shared
    dobby_so = libinject_so.parent / "libdobby.so"
    if dobby_so.exists():
        shutil.copy2(dobby_so, lib_dir / "libdobby.so")
        print(f"  Copied libdobby.so ({dobby_so.stat().st_size / 1024:.1f} KB)")

    # --- Step 3: Patch target .so ELF ---
    print("\n[3/4] Patching native library ELF...")
    if target_lib is None:
        target_lib = find_best_target_lib(work_dir)
    target_so = lib_dir / target_lib
    if not target_so.exists():
        raise FileNotFoundError(f"Target lib not found: {target_so}")

    if not patch_elf_add_needed(target_so):
        raise RuntimeError(f"Failed to patch {target_lib}")

    # --- Step 4: Repack ZIP, zipalign, sign ---
    print("\n[4/4] Repacking ARM64 split APK...")
    output_apk = OUTPUT_DIR / "patched_arm64.apk"
    _repack_zip(work_dir, output_apk)

    return output_apk


def _repack_zip(work_dir: Path, output_apk: Path) -> None:
    """Repack directory into APK, zipalign, and sign."""
    raw_apk = OUTPUT_DIR / "raw_arm64.apk"

    # Create ZIP (APK is just a ZIP)
    print("  Creating ZIP...")
    with zipfile.ZipFile(raw_apk, "w", zipfile.ZIP_DEFLATED) as zf:
        for fpath in sorted(work_dir.rglob("*")):
            if fpath.is_file():
                arcname = str(fpath.relative_to(work_dir)).replace("\\", "/")
                # Use STORED (no compression) for .so files and resources.arsc
                if arcname.endswith(".so") or arcname == "resources.arsc":
                    zf.write(fpath, arcname, compress_type=zipfile.ZIP_STORED)
                else:
                    zf.write(fpath, arcname)

    # Zipalign
    print("  Zipaligning...")
    zipalign = find_tool("zipalign")
    aligned_apk = OUTPUT_DIR / "aligned_arm64.apk"
    run([zipalign, "-f", "4", str(raw_apk), str(aligned_apk)])

    # Generate keystore if needed
    if not KEYSTORE.exists():
        print("  Generating debug keystore...")
        run(["keytool", "-genkey", "-v",
             "-keystore", str(KEYSTORE),
             "-alias", KEY_ALIAS,
             "-keyalg", "RSA", "-keysize", "2048",
             "-validity", "10000",
             "-storepass", KEY_PASS,
             "-keypass", KEY_PASS,
             "-dname", "CN=Debug,O=Debug,C=US"])

    # Sign
    print("  Signing...")
    apksigner = find_tool("apksigner")
    run([apksigner, "sign",
         "--ks", str(KEYSTORE),
         "--ks-key-alias", KEY_ALIAS,
         "--ks-pass", f"pass:{KEY_PASS}",
         "--key-pass", f"pass:{KEY_PASS}",
         "--min-sdk-version", "24",
         str(aligned_apk)])

    # Move to final output
    output_apk.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(aligned_apk), str(output_apk))

    # Cleanup
    raw_apk.unlink(missing_ok=True)

    size_mb = output_apk.stat().st_size / 1048576
    print(f"\n  OUTPUT: {output_apk}")
    print(f"  SIZE:   {size_mb:.1f} MB")


def resign_apk(apk_path: Path, output_path: Path) -> None:
    """Re-sign an APK with our debug key (for base.apk and other splits)."""
    shutil.copy2(apk_path, output_path)

    if not KEYSTORE.exists():
        run(["keytool", "-genkey", "-v",
             "-keystore", str(KEYSTORE),
             "-alias", KEY_ALIAS,
             "-keyalg", "RSA", "-keysize", "2048",
             "-validity", "10000",
             "-storepass", KEY_PASS,
             "-keypass", KEY_PASS,
             "-dname", "CN=Debug,O=Debug,C=US"])

    # Zipalign first
    zipalign = find_tool("zipalign")
    aligned = output_path.with_suffix(".aligned.apk")
    run([zipalign, "-f", "4", str(output_path), str(aligned)])
    shutil.move(str(aligned), str(output_path))

    # Sign
    apksigner = find_tool("apksigner")
    run([apksigner, "sign",
         "--ks", str(KEYSTORE),
         "--ks-key-alias", KEY_ALIAS,
         "--ks-pass", f"pass:{KEY_PASS}",
         "--key-pass", f"pass:{KEY_PASS}",
         "--min-sdk-version", "24",
         str(output_path)])


# =========================================================================
# Main
# =========================================================================

def main() -> None:
    parser = argparse.ArgumentParser(description="WWM Android APK Patcher (ELF injection)")
    parser.add_argument("--apk-dir", type=Path, default=DEFAULT_APK_DIR,
                        help="Path to WWM_APK directory")
    parser.add_argument("--skip-native", action="store_true",
                        help="Skip NDK build, use existing libinject.so")
    parser.add_argument("--ndk", type=str, default=None,
                        help="Path to Android NDK")
    parser.add_argument("--target-lib", type=str, default=None,
                        help="Which .so to patch with DT_NEEDED (default: auto)")
    args = parser.parse_args()

    print("=" * 62)
    print("  WWM Android APK Patcher — ELF Injection")
    print("=" * 62)
    print(f"  APK dir: {args.apk_dir}")
    print()

    # Verify input
    arm64_split = args.apk_dir / "split_config.arm64_v8a.apk"
    base_apk = args.apk_dir / "base.apk"
    if not arm64_split.exists():
        print(f"ERROR: ARM64 split not found: {arm64_split}")
        sys.exit(1)

    # Step 1: Build native library
    if args.skip_native:
        so_path = NATIVE_DIR / "build" / "libinject.so"
        if not so_path.exists():
            print(f"ERROR: --skip-native but {so_path} not found")
            sys.exit(1)
        print(f"[*] Using existing {so_path}")
    else:
        print("[*] Building libinject.so...")
        so_path = build_native(args.ndk)

    # Step 2: Patch ARM64 split
    print("\n[*] Patching ARM64 split APK...")
    patched_arm64 = patch_arm64_split(args.apk_dir, so_path, args.target_lib)

    # Step 3: Re-sign base.apk and other needed splits with same key
    print("\n[*] Re-signing base.apk and splits with debug key...")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    signed_apks = []

    # Re-sign base.apk (untouched DEX, just re-signed)
    out_base = OUTPUT_DIR / "patched_base.apk"
    resign_apk(base_apk, out_base)
    signed_apks.append(str(out_base))
    signed_apks.append(str(patched_arm64))

    # Re-sign other required splits
    other_splits = [
        "split_config.en.apk",
        "split_config.xxhdpi.apk",
        "split_yysls_it1.apk",
        "split_yysls_it2.apk",
    ]
    for split_name in other_splits:
        src = args.apk_dir / split_name
        if not src.exists():
            print(f"  SKIP: {split_name} (not found)")
            continue
        dst = OUTPUT_DIR / f"patched_{split_name}"
        resign_apk(src, dst)
        signed_apks.append(str(dst))

    # Done — print install command
    print("\n" + "=" * 62)
    print("  Build complete!")
    print("=" * 62)
    print()
    print("  Install with:")
    print(f"  adb install-multiple {' '.join(signed_apks)}")
    print()
    print("  Then:")
    print("  adb forward tcp:19840 tcp:19840")
    print("  python run_android.py push")
    print("  python run_android.py inject")
    print()
    print("  Monitor: adb logcat -s WWM_INJECT:*")

    print("\n  Done.")


if __name__ == "__main__":
    main()
