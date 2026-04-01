#!/usr/bin/env python3
"""
fast_deploy.py — Quick rebuild cycle for libinject.so iteration.

1. Rebuild native .so only (incremental, ~2-5s)
2. Replace libinject.so inside patched_arm64.apk
3. Re-sign that one APK
4. Uninstall + reinstall all APKs
5. Launch game + forward port

Usage:
    python3 Scripts/inject/android/fast_deploy.py
    python3 Scripts/inject/android/fast_deploy.py --skip-native   # use existing .so
"""
import subprocess, os, sys, shutil, time

PROJ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
os.chdir(PROJ)

NATIVE_BUILD = "Scripts/inject/android/native/build"
SO_PATH = f"{NATIVE_BUILD}/libinject.so"
OUTPUT = "Scripts/inject/android/output"
ARM64_APK = f"{OUTPUT}/patched_arm64.apk"
KEYSTORE = "Scripts/inject/android/debug.keystore"
PKG = "com.netease.yysls"
ACTIVITY = f"{PKG}/com.netease.ntunisdk.external.protocol.ProtocolLauncher"

# Detect tools
def find_tool(name, search_paths):
    for p in search_paths:
        full = os.path.join(p, name)
        if os.path.isfile(full):
            return full
    result = shutil.which(name)
    if result: return result
    raise FileNotFoundError(f"Cannot find {name}")

BUILD_TOOLS = "/usr/local/share/android-commandlinetools/build-tools/34.0.0"
ZIPALIGN = find_tool("zipalign", [BUILD_TOOLS])
APKSIGNER = find_tool("apksigner", [BUILD_TOOLS])

def run(cmd, **kw):
    print(f"  $ {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    return subprocess.run(cmd, shell=isinstance(cmd, str), check=True, **kw)

def main():
    skip_native = "--skip-native" in sys.argv
    t0 = time.time()

    # Step 1: Rebuild native
    if not skip_native:
        print("\n[1/5] Rebuilding native .so...")
        run(["cmake", "--build", NATIVE_BUILD, "--config", "Release"])
        size = os.path.getsize(SO_PATH)
        print(f"  Built: {SO_PATH} ({size/1024:.1f} KB)")
    else:
        print("\n[1/5] Skipping native build (--skip-native)")

    # Step 2: Replace .so inside patched_arm64.apk
    print("\n[2/5] Replacing libinject.so in patched_arm64.apk...")
    if not os.path.exists(ARM64_APK):
        print(f"  ERROR: {ARM64_APK} not found. Run full build_apk.py first.")
        sys.exit(1)

    # Use zip to replace the file inside the APK
    # The path inside the APK is lib/arm64-v8a/libinject.so
    import tempfile, zipfile

    # Create temp dir with the correct structure
    with tempfile.TemporaryDirectory() as tmpdir:
        lib_dir = os.path.join(tmpdir, "lib", "arm64-v8a")
        os.makedirs(lib_dir)
        shutil.copy2(SO_PATH, os.path.join(lib_dir, "libinject.so"))

        # Remove old .so from APK and add new one
        tmp_apk = ARM64_APK + ".tmp"
        with zipfile.ZipFile(ARM64_APK, 'r') as zin:
            with zipfile.ZipFile(tmp_apk, 'w') as zout:
                for item in zin.infolist():
                    if item.filename == "lib/arm64-v8a/libinject.so":
                        continue  # skip old .so
                    zout.writestr(item, zin.read(item.filename))
                # Add new .so
                zout.write(os.path.join(lib_dir, "libinject.so"),
                          "lib/arm64-v8a/libinject.so")

        os.replace(tmp_apk, ARM64_APK)
        print(f"  Replaced libinject.so in {ARM64_APK}")

    # Step 3: Zipalign + re-sign
    print("\n[3/5] Zipalign + re-sign...")
    aligned = ARM64_APK + ".aligned"
    run([ZIPALIGN, "-f", "4", ARM64_APK, aligned])
    os.replace(aligned, ARM64_APK)
    run([APKSIGNER, "sign",
         "--ks", KEYSTORE,
         "--ks-key-alias", "wwm_debug",
         "--ks-pass", "pass:android",
         "--key-pass", "pass:android",
         ARM64_APK])
    print(f"  Signed: {ARM64_APK}")

    # Step 4: Uninstall + reinstall
    print("\n[4/5] Uninstall + reinstall...")
    subprocess.run(["adb", "uninstall", PKG], capture_output=True)

    apks = [
        f"{OUTPUT}/patched_base.apk",
        ARM64_APK,
        f"{OUTPUT}/patched_split_config.en.apk",
        f"{OUTPUT}/patched_split_config.xxhdpi.apk",
        f"{OUTPUT}/patched_split_yysls_it1.apk",
        f"{OUTPUT}/patched_split_yysls_it2.apk",
    ]
    existing = [a for a in apks if os.path.exists(a)]
    run(["adb", "install-multiple"] + existing)

    # Step 5: Forward port + launch
    print("\n[5/5] Forward port + launch...")
    run(["adb", "forward", "tcp:19840", "tcp:19840"])
    run(["adb", "shell", "am", "start", "-n", ACTIVITY])

    elapsed = time.time() - t0
    print(f"\n  Done in {elapsed:.1f}s")
    print(f"  Wait ~15s for hook to activate, then:")
    print(f"    echo \"local f=io.open('/sdcard/wwm_test.txt','w') f:write('OK') f:close()\" | nc -w 5 localhost 19840")

if __name__ == "__main__":
    main()
