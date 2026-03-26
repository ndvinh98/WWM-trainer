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

import lief

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
# ELF patching — add DT_NEEDED for libinject.so
# =========================================================================

def find_best_target_lib(arm64_dir: Path) -> str:
    """Find the best .so to patch in the ARM64 split.

    Prefers a small, early-loading library to minimize risk.
    Falls back to the first .so found.
    """
    lib_dir = arm64_dir / "lib" / "arm64-v8a"
    if not lib_dir.exists():
        raise FileNotFoundError(f"No lib/arm64-v8a in {arm64_dir}")

    # Priority list: small utility libs that load early
    preferred = [
        "libybuaxz.so",       # protection shell stub — loads very early
        "libxxhash.so",       # tiny utility
        "libandroidndkp.so",  # NDK profiling
    ]
    for name in preferred:
        if (lib_dir / name).exists():
            return name

    # Fallback: first .so
    for f in sorted(lib_dir.glob("*.so")):
        return f.name

    raise FileNotFoundError("No .so files found in ARM64 lib dir")


def patch_elf_add_needed(so_path: Path, needed_lib: str = "libinject.so") -> bool:
    """Add DT_NEEDED entry for libinject.so to an existing .so using LIEF."""
    print(f"  Patching {so_path.name} to add DT_NEEDED: {needed_lib}")

    binary = lief.parse(str(so_path))
    if binary is None:
        print(f"  ERROR: LIEF failed to parse {so_path}")
        return False

    # Check if already patched
    existing = [lib for lib in binary.libraries]
    if needed_lib in existing:
        print(f"  Already has {needed_lib} in DT_NEEDED, skipping")
        return True

    # Add DT_NEEDED
    binary.add_library(needed_lib)

    # Write back
    binary.write(str(so_path))
    print(f"  Patched! DT_NEEDED now includes: {needed_lib}")
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
