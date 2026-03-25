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
    """Extract the original signing certificate from base.apk as base64."""
    base_apk = apk_dir / "base.apk"
    with zipfile.ZipFile(base_apk) as z:
        # Look for CERT.RSA or similar in META-INF/
        for name in z.namelist():
            if name.startswith("META-INF/") and name.endswith((".RSA", ".DSA", ".EC")):
                cert_data = z.read(name)
                b64 = base64.b64encode(cert_data).decode("ascii")
                print(f"  Extracted cert from {name} ({len(cert_data)} bytes)")
                return b64
    raise FileNotFoundError("No signing certificate found in base.apk META-INF/")


def build_native(ndk_path: str | None = None) -> Path:
    """Build libinject.so via NDK cmake."""
    ndk = ndk_path or os.environ.get("ANDROID_NDK_HOME")
    if not ndk or not Path(ndk).exists():
        raise FileNotFoundError(
            "Android NDK not found. Set ANDROID_NDK_HOME or pass --ndk"
        )

    build_dir = NATIVE_DIR / "build_arm64"
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


def decompile_apk(apk_path: Path, out_dir: Path) -> None:
    """Decompile APK with apktool."""
    if out_dir.exists():
        shutil.rmtree(out_dir)
    run(["apktool", "d", str(apk_path), "-o", str(out_dir), "-f"])


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


def inject_patches(work_dir: Path, libinject_so: Path, cert_b64: str) -> None:
    """Apply all patches to the decompiled APK."""
    # 1. Copy native libraries
    lib_dir = work_dir / "lib" / "arm64-v8a"
    lib_dir.mkdir(parents=True, exist_ok=True)

    shutil.copy2(libinject_so, lib_dir / "libinject.so")
    print(f"  Copied libinject.so to {lib_dir}")

    # Copy libdobby.so if it was built as a shared lib
    dobby_so = libinject_so.parent / "libdobby.so"
    if dobby_so.exists():
        shutil.copy2(dobby_so, lib_dir / "libdobby.so")
        print(f"  Copied libdobby.so to {lib_dir}")

    # 2. Copy smali files
    # Find the highest-numbered smali_classes directory to avoid conflicts
    existing = sorted(work_dir.glob("smali_classes*"))
    if existing:
        last_num = int(existing[-1].name.replace("smali_classes", "") or "1")
        smali_target = work_dir / f"smali_classes{last_num + 1}"
    else:
        smali_target = work_dir / "smali_classes2"

    inject_smali_dir = smali_target / "com" / "wwm" / "inject"
    inject_smali_dir.mkdir(parents=True, exist_ok=True)

    for smali_file in SMALI_DIR.glob("*.smali"):
        content = smali_file.read_text(encoding="utf-8")
        # Inject the real cert bytes
        content = content.replace("ORIGINAL_CERT_PLACEHOLDER", cert_b64)
        (inject_smali_dir / smali_file.name).write_text(content, encoding="utf-8")
        print(f"  Copied {smali_file.name} -> {inject_smali_dir}")

    # 3. Patch AndroidManifest.xml — add our ContentProvider
    manifest = work_dir / "AndroidManifest.xml"
    manifest_text = manifest.read_text(encoding="utf-8")

    provider_xml = (
        '        <provider\n'
        '            android:name="com.wwm.inject.InjectProvider"\n'
        f'            android:authorities="{PACKAGE_NAME}.inject_init"\n'
        '            android:exported="false"\n'
        '            android:initOrder="999"/>\n'
    )

    if "InjectProvider" not in manifest_text:
        # Insert before closing </application> tag
        manifest_text = manifest_text.replace(
            "</application>",
            provider_xml + "    </application>"
        )
        manifest.write_text(manifest_text, encoding="utf-8")
        print("  Patched AndroidManifest.xml with InjectProvider")
    else:
        print("  AndroidManifest.xml already patched")

    # 4. Remove isSplitRequired if present (needed for merged APK)
    if 'android:isSplitRequired="true"' in manifest_text:
        manifest_text = manifest_text.replace(
            'android:isSplitRequired="true"',
            'android:isSplitRequired="false"'
        )
        manifest.write_text(manifest_text, encoding="utf-8")
        print("  Disabled isSplitRequired in manifest")


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


def mode_merge(apk_dir: Path, libinject_so: Path, cert_b64: str) -> None:
    """Mode A: Merge splits into single patched APK."""
    print("\n=== MODE A: Merge splits into single APK ===\n")

    work_dir = OUTPUT_DIR / "work_merged"
    output_apk = OUTPUT_DIR / "wwm_patched.apk"

    # Decompile base
    print("[1/5] Decompiling base.apk...")
    decompile_apk(apk_dir / "base.apk", work_dir)

    # Merge splits
    print("\n[2/5] Merging split APKs...")
    for split_name in MERGE_SPLITS:
        split_path = apk_dir / split_name
        if split_path.exists():
            merge_split(split_path, work_dir)
        else:
            print(f"  WARNING: {split_name} not found, skipping")

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
    decompile_apk(apk_dir / "base.apk", work_base)

    # Decompile arm64 split
    print("\n[2/5] Decompiling arm64 split...")
    decompile_apk(apk_dir / "split_config.arm64_v8a.apk", work_arm64)

    # Inject patches to base (smali + manifest)
    print("\n[3/5] Injecting patches to base...")
    inject_patches(work_base, libinject_so, cert_b64)

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
        so_path = NATIVE_DIR / "build_arm64" / "libinject.so"
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
