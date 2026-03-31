# Android Lua Injection Port - Status Report

## 🎯 Objective
Port the Windows-based Lua injection pipeline to Android to enable automated in-game reward collection on non-rooted devices.

---

## ✅ What We Have Done

1. **Native Hook Library (`libinject.so`):**
   * Successfully cross-compiled for `arm64-v8a` using NDK and CMake.
   * Implemented inline hooking using **Dobby** instead of MinHook.
   * Replaced Windows Named Pipes with a **local TCP Server (127.0.0.1:19840)** for command execution.
   * Transitioned from a JNI (`JNI_OnLoad`) entry point to an ELF `__attribute__((constructor))` entry point to support native dependency injection.
   * Added a `/proc/self/maps` parser fallback to successfully locate `libGame.so`'s `.text` segment even when linker API (`dl_iterate_phdr`) fails due to load-timing issues.

2. **APK Repackaging Pipeline ([build_apk.py](file:///c:/temp/Where%20Winds%20Meet/Scripts/inject/android/build_apk.py)):**
   * Replaced the `apktool`/[smali](file:///c:/temp/Where%20Winds%20Meet/Scripts/inject/android/smali/SigSpoof.smali) DEX injection strategy with an **ELF `DT_NEEDED` injection strategy**.
   * **Why?** Modifying [base.apk](file:///c:/temp/Where%20Winds%20Meet/WWM_APK/base.apk)'s DEX files triggered the game's protection shell integrity checks (resulting in `StubApp` / `CoreComponentFactory` crashes).
   * The new pipeline uses **LIEF** to patch a native library (`.so`) inside the ARM64 split APK to automatically load `libinject.so` as a dependency.
   * **Advantage:** [base.apk](file:///c:/temp/Where%20Winds%20Meet/WWM_APK/base.apk) is never decompiled or modified, evading standard DEX integrity checks. All splits are successfully re-signed with a consistent debug key.

---

## ⚠️ Current Problems

While the hooks install perfectly when our code executes, the game crashes depending on *which* library we patch to load our injector. We are currently hunting for the perfect `DT_NEEDED` host library.

**Host Library Attempts & Results:**

1. **`libybuaxz.so`** (Protection Shell):
   - *Result:* **Crash loop (Signal 4 / SIGILL)**.
   - *Why:* It's the anti-cheat itself. Modifying its ELF header with LIEF triggers its own self-integrity hash check.
2. **`libxxhash.so`** (Tiny Utility):
   - *Result:* **Game runs stably! No crashes.**
   - *Why it failed:* The inject never fired because the game never actually loads this library at startup.
3. **`libGame.so`** (The Core Game Engine - 133MB):
   - *Result:* **Process crashes during linker load.**
   - *Why:* Our constructor fires, but the process dies immediately. Likely, LIEF corrupts the massive 133MB binary during patching, or circular dependency issues occur.

**Current Test:** We are currently testing **`libandroidmainruns.so`** (1.4MB) as it sounds like an early-startup library and is small enough for reliable LIEF patching. The background process just finished, and if it fails, we need to iterate.

---

## 🚀 Next Steps (Focus on Non-Rooted)

1. **Evaluate `libandroidmainruns.so`:** Verify if the game boots and the hooks fire using the currently built APKs. (Use the command below).
2. **Iterate Host Libraries:** If it fails, systematically test other `.so` files in the ARM64 split that might load at startup but aren't heavily protected.
   * Examples: `libPxlwCheckIris.so`, `libCommonLib.so`, `libunisdkdctool.so`, `libccplayer.so`
3. **Alternative Non-Rooted Methods:** If *all* modified `.so` files are detected by the anti-cheat, we may need to explore:
   - Injecting via an unprotected `NativeActivity` metadata tag in `AndroidManifest.xml` (requires fixing `apktool` v3 missing manifest bug).
   - Patching the `libGame.so` import table manually without LIEF.
   - Tracing precisely when/how `libGame.so` is loaded by Java to find the Java-level `System.loadLibrary()` caller, then modifying its surrounding DEX bytecode (if base DEX check can be spoofed).

---

## 💻 Developer Command Reference

To rapidly iterate, build, and test the pipeline, use the following commands in PowerShell.

### 1. Build and Patch APK
*(Automatically builds the NDK library if needed, patches the target `.so`, packages, and signs all splits)*
```powershell
$env:ANDROID_HOME = "C:\Android"
# Replace "--target-lib" with any other library to test a new host
.venv\Scripts\python.exe Scripts\inject\android\build_apk.py --skip-native --apk-dir "F:\Coding\Where Winds Meet\WWM_APK" --target-lib libandroidmainruns.so
```
*(Remove `--skip-native` if you changed C++ code).*

### 2. Uninstall & Reinstall All Splits
```powershell
adb -s 10AF891YKY006E3 shell am force-stop com.netease.yysls
adb -s 10AF891YKY006E3 uninstall com.netease.yysls

adb -s 10AF891YKY006E3 install-multiple Scripts\inject\android\output\patched_base.apk Scripts\inject\android\output\patched_arm64.apk Scripts\inject\android\output\patched_split_config.en.apk Scripts\inject\android\output\patched_split_config.xxhdpi.apk Scripts\inject\android\output\patched_split_yysls_it1.apk Scripts\inject\android\output\patched_split_yysls_it2.apk
```

### 3. Launch Game & Monitor Logs
```powershell
# Clear logs and launch via Monkey
adb -s 10AF891YKY006E3 logcat -c
adb -s 10AF891YKY006E3 shell monkey -p com.netease.yysls -c android.intent.category.LAUNCHER 1

# Wait ~30-40 seconds, then check if our hooks fired
adb -s 10AF891YKY006E3 logcat -d | Select-String "WWM_INJECT"

# Check if process is alive (Look for 'R' running, or 'Z' zombie/crashed)
adb -s 10AF891YKY006E3 shell "ps -A | grep yysls"
```

### 4. Execute Lua (Once Injected)
```powershell
adb forward tcp:19840 tcp:19840
python run_android.py push
python run_android.py inject
```
