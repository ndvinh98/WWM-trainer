"""APK repackage pipeline — merge/patch/rebuild WWM for Android injection.

Usage:
    python build_apk.py                        # Mode A (merge) — default
    python build_apk.py --mode split           # Mode B (patch splits)
    python build_apk.py --apk-dir /path/to/WWM_APK
    python build_apk.py --skip-native          # skip NDK build (use existing .so)
"""

from __future__ import annotations

import argparse
import base64
import os
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent  # -> Where Winds Meet/
DEFAULT_APK_DIR = PROJECT_ROOT / "WWM_APK"
NATIVE_DIR = SCRIPT_DIR / "native"
SMALI_DIR = SCRIPT_DIR / "smali"
OUTPUT_DIR = SCRIPT_DIR / "output"

PACKAGE_NAME = "com.netease.yysls"

# Splits to merge in Mode A (skip large game asset packs)
MERGE_SPLITS = [
    "split_config.arm64_v8a.apk",
    "split_config.en.apk",
    "split_config.xxhdpi.apk",
]

KEYSTORE = SCRIPT_DIR / "debug.keystore"
KEY_ALIAS = "wwm_debug"
KEY_PASS = "android"


def run(cmd: list[str], check: bool = True, **kw) -> subprocess.CompletedProcess:
    """Run a subprocess with logging."""
    print(f"  $ {' '.join(cmd)}")
    # On Windows, tools like apktool/apksigner are .cmd/.bat shims
    # that require shell=True for subprocess to find them
    if sys.platform == "win32":
        kw.setdefault("shell", True)
    return subprocess.run(cmd, check=check, **kw)


def find_tool(name: str) -> str:
    """Find a tool in PATH or common locations."""
    result = shutil.which(name)
    if result:
        return result
    # Check common Android SDK locations
    sdk_root = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if sdk_root:
        for bt in Path(sdk_root).glob("build-tools/*/"):
            candidate = bt / (name + (".bat" if sys.platform == "win32" else ""))
            if candidate.exists():
                return str(candidate)
    raise FileNotFoundError(f"Tool not found: {name}. Add it to PATH.")


def extract_original_cert(apk_dir: Path) -> str:
    """Extract the original signing certificate from base.apk as base64.

    Falls back to placeholder for v2/v3-only signed APKs (no JAR signing in META-INF).
    SigSpoof.smali checks for the placeholder and skips if cert wasn't patched.
    """
    base_apk = apk_dir / "base.apk"
    with zipfile.ZipFile(base_apk) as z:
        # Look for CERT.RSA or similar in META-INF/ (v1 / JAR signing)
        for name in z.namelist():
            if name.startswith("META-INF/") and name.endswith((".RSA", ".DSA", ".EC")):
                cert_data = z.read(name)
                b64 = base64.b64encode(cert_data).decode("ascii")
                print(f"  Extracted cert from {name} ({len(cert_data)} bytes)")
                return b64
    # v2/v3-only signed APK — no JAR certs in META-INF
    print("  WARNING: No v1 signing cert in META-INF/ (APK uses v2/v3 signing)")
    print("  SigSpoof will skip cert spoofing (stub mode)")
    return "ORIGINAL_CERT_PLACEHOLDER"


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

    # Find cmake — prefer NDK bundled, fall back to system
    cmake = shutil.which("cmake")
    sdk_root = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if sdk_root:
        for cm in Path(sdk_root).glob("cmake/*/bin/cmake*"):
            cmake = str(cm)
            break
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


def decompile_apk(apk_path: Path, out_dir: Path, no_res: bool = False) -> None:
    """Decompile APK with apktool.

    Args:
        no_res: If True, use -r flag to skip resource decoding.
                Keeps AndroidManifest.xml and res/ in binary form,
                which avoids apktool 3.x rebuild issues.
    """
    if out_dir.exists():
        shutil.rmtree(out_dir)
    cmd = ["apktool", "d", str(apk_path), "-o", str(out_dir), "-f"]
    if no_res:
        cmd.append("-r")
    run(cmd)


def merge_split(split_apk: Path, work_dir: Path) -> None:
    """Merge a split APK's contents into the work directory."""
    print(f"  Merging {split_apk.name}...")
    with zipfile.ZipFile(split_apk) as z:
        for entry in z.namelist():
            # Skip META-INF and manifest (use base's)
            if entry.startswith("META-INF/") or entry == "AndroidManifest.xml":
                continue
            if entry == "stamp-cert-sha256":
                continue
            # Extract to work dir
            target = work_dir / entry
            target.parent.mkdir(parents=True, exist_ok=True)
            with z.open(entry) as src, open(target, "wb") as dst:
                dst.write(src.read())


def inject_patches(work_dir: Path, libinject_so: Path, cert_b64: str,
                    copy_native: bool = True) -> None:
    """Apply all patches to the decompiled APK.

    Uses smali-level injection into StubApp.attachBaseContext() instead of
    manifest modification, since apktool 3.x has issues recompiling resources
    when the decoded manifest references app resources.

    Args:
        copy_native: If True, copy libinject.so into lib/arm64-v8a/.
                     Set False for split mode where native goes in arm64 split.
    """
    # 1. Copy native libraries (skip in split mode — goes in arm64 split)
    if copy_native:
        lib_dir = work_dir / "lib" / "arm64-v8a"
        lib_dir.mkdir(parents=True, exist_ok=True)

        shutil.copy2(libinject_so, lib_dir / "libinject.so")
        print(f"  Copied libinject.so to {lib_dir}")

    # 2. Copy SigSpoof smali
    existing = sorted(work_dir.glob("smali_classes*"))
    if existing:
        last_num = int(existing[-1].name.replace("smali_classes", "") or "1")
        smali_target = work_dir / f"smali_classes{last_num + 1}"
    else:
        smali_target = work_dir / "smali_classes2"

    inject_smali_dir = smali_target / "com" / "wwm" / "inject"
    inject_smali_dir.mkdir(parents=True, exist_ok=True)

    for smali_file in SMALI_DIR.glob("*.smali"):
        # Skip InjectProvider — we inject via StubApp.smali instead
        if smali_file.name == "InjectProvider.smali":
            continue
        content = smali_file.read_text(encoding="utf-8")
        content = content.replace("ORIGINAL_CERT_PLACEHOLDER", cert_b64)
        (inject_smali_dir / smali_file.name).write_text(content, encoding="utf-8")
        print(f"  Copied {smali_file.name} -> {inject_smali_dir}")

    # 3. Inject System.loadLibrary("inject") into StubApp.attachBaseContext()
    _inject_into_stubapp(work_dir)


def _inject_into_stubapp(work_dir: Path) -> None:
    """Inject System.loadLibrary("inject") into StubApp.attachBaseContext().

    Inserts the call right after invoke-super in attachBaseContext, which runs
    before any other app code. Our native lib starts a background thread that
    waits for libGame.so to appear before hooking.
    """
    stubapp = work_dir / "smali" / "com" / "netease" / "android" / "protect" / "StubApp.smali"
    if not stubapp.exists():
        print("  WARNING: StubApp.smali not found, skipping smali injection")
        return

    content = stubapp.read_text(encoding="utf-8")

    if 'const-string' in content and '"inject"' in content:
        print("  StubApp.smali already patched")
        return

    # The loadLibrary smali snippet — uses the method's existing registers
    # attachBaseContext has .locals 9, so we can bump to 10 and use v9
    load_lib_smali = (
        '\n'
        '    # --- WWM inject: load native hook library ---\n'
        '    const-string v0, "inject"\n'
        '    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n'
        '    # --- end WWM inject ---\n'
    )

    # Insert after invoke-super in attachBaseContext
    target = 'invoke-super {p0, p1}, Landroid/app/Application;->attachBaseContext(Landroid/content/Context;)V'
    if target not in content:
        print("  WARNING: Could not find attachBaseContext invoke-super, skipping")
        return

    content = content.replace(target, target + load_lib_smali)
    stubapp.write_text(content, encoding="utf-8")
    print("  Injected System.loadLibrary(\"inject\") into StubApp.attachBaseContext()")


def rebuild_apk(work_dir: Path, output_apk: Path) -> None:
    """Rebuild, zipalign, and sign the APK."""
    raw_apk = work_dir.parent / "raw.apk"

    # Rebuild
    run(["apktool", "b", str(work_dir), "-o", str(raw_apk)])

    # Zipalign
    zipalign = find_tool("zipalign")
    aligned_apk = work_dir.parent / "aligned.apk"
    run([zipalign, "-f", "4", str(raw_apk), str(aligned_apk)])

    # Generate keystore if it doesn't exist
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
    apksigner = find_tool("apksigner")
    run([apksigner, "sign",
         "--ks", str(KEYSTORE),
         "--ks-key-alias", KEY_ALIAS,
         "--ks-pass", f"pass:{KEY_PASS}",
         "--key-pass", f"pass:{KEY_PASS}",
         str(aligned_apk)])

    # Move to final output
    output_apk.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(aligned_apk), str(output_apk))

    # Cleanup
    raw_apk.unlink(missing_ok=True)

    print(f"\n  OUTPUT: {output_apk}")
    print(f"  SIZE:   {output_apk.stat().st_size / 1048576:.1f} MB")


def _patch_binary_manifest_splits(work_dir: Path) -> None:
    """Remove split-related attributes from the binary AndroidManifest.xml.

    When merging splits into a single APK, Android refuses to install if
    requiredSplitTypes/splitTypes attributes are present. We remove them
    from the binary XML element tree.
    """
    manifest = work_dir / "AndroidManifest.xml"
    data = bytearray(manifest.read_bytes())

    # --- Parse string pool to find target attribute name indices ---
    # AXML header: magic(4) + filesize(4)
    # String pool chunk starts at offset 8
    sp_type, sp_hdr_size, sp_chunk_size = struct.unpack_from("<HHI", data, 8)
    if sp_type != 0x0001:
        print("  WARNING: Unexpected string pool type, skipping manifest patch")
        return

    str_count, style_count, sp_flags = struct.unpack_from("<III", data, 16)
    strings_start = struct.unpack_from("<I", data, 28)[0]  # relative to chunk start (8)
    sp_base = 8  # string pool chunk starts at byte 8

    # Read string offsets
    offsets_start = sp_base + sp_hdr_size
    str_offsets = []
    for i in range(str_count):
        off = struct.unpack_from("<I", data, offsets_start + i * 4)[0]
        str_offsets.append(off)

    is_utf8 = bool(sp_flags & (1 << 8))

    def read_pool_string(idx: int) -> str:
        abs_off = sp_base + strings_start + str_offsets[idx]
        if is_utf8:
            # UTF-8: u16len(1-2 bytes), u8len(1-2 bytes), then UTF-8 data, null
            b = data[abs_off]
            if b & 0x80:
                abs_off += 2
            else:
                abs_off += 1
            b = data[abs_off]
            if b & 0x80:
                u8len = ((b & 0x7F) << 8) | data[abs_off + 1]
                abs_off += 2
            else:
                u8len = b
                abs_off += 1
            return data[abs_off:abs_off + u8len].decode("utf-8", errors="replace")
        else:
            # UTF-16: u16 charcount, then UTF-16LE data, then u16 null
            charcount = struct.unpack_from("<H", data, abs_off)[0]
            if charcount & 0x8000:
                charcount = ((charcount & 0x7FFF) << 16) | struct.unpack_from("<H", data, abs_off + 2)[0]
                abs_off += 4
            else:
                abs_off += 2
            return data[abs_off:abs_off + charcount * 2].decode("utf-16-le", errors="replace")

    # Find string pool indices for the target attribute names
    remove_names = {"requiredSplitTypes", "splitTypes"}
    remove_indices = set()
    for i in range(str_count):
        try:
            s = read_pool_string(i)
            if s in remove_names:
                remove_indices.add(i)
        except Exception:
            continue

    if not remove_indices:
        print("  No split type attributes found in manifest (OK)")
        return

    # --- Find and patch START_ELEMENT chunks to remove these attributes ---
    # Binary XML element layout:
    #   pos+0:  chunk type (2) = 0x0102
    #   pos+2:  header size (2)
    #   pos+4:  chunk size (4)
    #   pos+8:  line number (4)
    #   pos+12: comment (4)
    #   pos+16: namespace URI (4)    <- ext start
    #   pos+20: element name (4)
    #   pos+24: attributeStart (2)   <- offset from ext start (pos+16)
    #   pos+26: attributeSize (2)    <- bytes per attribute (20)
    #   pos+28: attributeCount (2)
    #   pos+30: idIndex (2)
    #   pos+32: classIndex (2)
    #   pos+34: styleIndex (2)
    #   pos+16+attributeStart: first attribute
    pos = sp_base + sp_chunk_size  # skip past string pool
    patched = 0

    while pos < len(data) - 8:
        chunk_type, chunk_hdr_size, chunk_size = struct.unpack_from("<HHI", data, pos)

        # START_ELEMENT = 0x0102
        if chunk_type == 0x0102 and chunk_size >= 36:
            attr_start_off = struct.unpack_from("<H", data, pos + 24)[0]
            attr_size = struct.unpack_from("<H", data, pos + 26)[0]
            attr_count = struct.unpack_from("<H", data, pos + 28)[0]

            if attr_size == 0:
                attr_size = 20

            ext_start = pos + 16
            attrs_base = ext_start + attr_start_off
            to_remove = []

            for a in range(attr_count):
                a_off = attrs_base + a * attr_size
                a_name_idx = struct.unpack_from("<I", data, a_off + 4)[0]
                if a_name_idx in remove_indices:
                    to_remove.append(a)

            # Remove attributes in reverse order
            for a in reversed(to_remove):
                a_off = attrs_base + a * attr_size
                del data[a_off:a_off + attr_size]
                attr_count -= 1
                chunk_size -= attr_size
                patched += 1

            if to_remove:
                struct.pack_into("<H", data, pos + 28, attr_count)
                struct.pack_into("<I", data, pos + 4, chunk_size)

        if chunk_size < 8:
            break
        pos += chunk_size

    if patched:
        struct.pack_into("<I", data, 4, len(data))
        manifest.write_bytes(data)
        print(f"  Removed {patched} split-type attribute(s) from binary manifest")
    else:
        print("  Split type attributes not found in XML elements (OK)")


def mode_merge(apk_dir: Path, libinject_so: Path, cert_b64: str) -> None:
    """Mode A: Merge splits into single patched APK."""
    print("\n=== MODE A: Merge splits into single APK ===\n")

    work_dir = OUTPUT_DIR / "work_merged"
    output_apk = OUTPUT_DIR / "wwm_patched.apk"

    # Decompile base with -r (no resource decode) to avoid apktool 3.x issues
    print("[1/5] Decompiling base.apk (no-res mode)...")
    decompile_apk(apk_dir / "base.apk", work_dir, no_res=True)

    # Merge splits
    print("\n[2/5] Merging split APKs...")
    for split_name in MERGE_SPLITS:
        split_path = apk_dir / split_name
        if split_path.exists():
            merge_split(split_path, work_dir)
        else:
            print(f"  WARNING: {split_name} not found, skipping")

    # Patch binary manifest for merged mode
    _patch_binary_manifest_splits(work_dir)

    # Inject patches
    print("\n[3/5] Injecting patches...")
    inject_patches(work_dir, libinject_so, cert_b64)

    # Rebuild
    print("\n[4/5] Rebuilding APK...")
    rebuild_apk(work_dir, output_apk)

    # Install instructions
    print("\n[5/5] Install:")
    print(f"  adb install {output_apk}")
    print(f"  adb forward tcp:19840 tcp:19840")


def mode_split(apk_dir: Path, libinject_so: Path, cert_b64: str) -> None:
    """Mode B: Patch individual splits, resign all."""
    print("\n=== MODE B: Patch splits individually ===\n")

    work_base = OUTPUT_DIR / "work_base"
    work_arm64 = OUTPUT_DIR / "work_arm64"
    out_base = OUTPUT_DIR / "patched_base.apk"
    out_arm64 = OUTPUT_DIR / "patched_arm64.apk"

    # Decompile base
    print("[1/5] Decompiling base.apk...")
    decompile_apk(apk_dir / "base.apk", work_base, no_res=True)

    # Decompile arm64 split
    print("\n[2/5] Decompiling arm64 split...")
    decompile_apk(apk_dir / "split_config.arm64_v8a.apk", work_arm64, no_res=True)

    # Inject patches to base (smali only — native lib goes in arm64 split)
    print("\n[3/5] Injecting patches to base...")
    inject_patches(work_base, libinject_so, cert_b64, copy_native=False)

    # Copy libinject.so to arm64 split too
    arm64_lib = work_arm64 / "lib" / "arm64-v8a"
    arm64_lib.mkdir(parents=True, exist_ok=True)
    shutil.copy2(libinject_so, arm64_lib / "libinject.so")
    dobby_so = libinject_so.parent / "libdobby.so"
    if dobby_so.exists():
        shutil.copy2(dobby_so, arm64_lib / "libdobby.so")

    # Rebuild both
    print("\n[4/5] Rebuilding APKs...")
    rebuild_apk(work_base, out_base)
    rebuild_apk(work_arm64, out_arm64)

    # Resign remaining splits with same key
    print("\n[5/5] Resigning remaining splits...")
    apksigner = find_tool("apksigner")
    zipalign_tool = find_tool("zipalign")

    signed_splits = [str(out_base), str(out_arm64)]
    for split_name in ["split_config.en.apk", "split_config.xxhdpi.apk",
                        "split_yysls_it1.apk", "split_yysls_it2.apk"]:
        src = apk_dir / split_name
        if not src.exists():
            continue
        dst = OUTPUT_DIR / f"patched_{split_name}"
        shutil.copy2(src, dst)
        # Resign with our key
        run([apksigner, "sign",
             "--ks", str(KEYSTORE),
             "--ks-key-alias", KEY_ALIAS,
             "--ks-pass", f"pass:{KEY_PASS}",
             "--key-pass", f"pass:{KEY_PASS}",
             str(dst)])
        signed_splits.append(str(dst))

    print("\n  Install:")
    print(f"  adb install-multiple {' '.join(signed_splits)}")
    print(f"  adb forward tcp:19840 tcp:19840")


def main() -> None:
    parser = argparse.ArgumentParser(description="WWM Android APK Patcher")
    parser.add_argument("--mode", choices=["merge", "split"], default="merge",
                        help="Mode A (merge) or Mode B (split). Default: merge")
    parser.add_argument("--apk-dir", type=Path, default=DEFAULT_APK_DIR,
                        help="Path to WWM_APK directory")
    parser.add_argument("--skip-native", action="store_true",
                        help="Skip NDK build, use existing libinject.so")
    parser.add_argument("--ndk", type=str, default=None,
                        help="Path to Android NDK")
    args = parser.parse_args()

    print("=" * 62)
    print("  WWM Android APK Patcher")
    print("=" * 62)
    print(f"  Mode:    {args.mode.upper()}")
    print(f"  APK dir: {args.apk_dir}")
    print()

    # Verify base.apk exists
    if not (args.apk_dir / "base.apk").exists():
        print(f"ERROR: base.apk not found in {args.apk_dir}")
        sys.exit(1)

    # Step 1: Extract original cert
    print("[*] Extracting original signing certificate...")
    cert_b64 = extract_original_cert(args.apk_dir)

    # Step 2: Build native library
    if args.skip_native:
        so_path = NATIVE_DIR / "build" / "libinject.so"
        if not so_path.exists():
            print(f"ERROR: --skip-native but {so_path} not found")
            sys.exit(1)
        print(f"[*] Using existing {so_path}")
    else:
        print("[*] Building libinject.so...")
        so_path = build_native(args.ndk)

    # Step 3: Patch and rebuild
    if args.mode == "merge":
        mode_merge(args.apk_dir, so_path, cert_b64)
    else:
        mode_split(args.apk_dir, so_path, cert_b64)

    print("\n  Done.")


if __name__ == "__main__":
    main()
