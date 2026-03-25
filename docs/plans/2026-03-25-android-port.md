# Android Port Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Port the Windows Lua injection pipeline to Android, targeting non-rooted devices via APK repackaging with Dobby inline hooks and signature spoofing.

**Architecture:** Inject a precompiled `libinject.so` into the game APK. A smali `ContentProvider` loads it before `Application.onCreate()`. The native lib pattern-scans `libGame.so` for lua_load/lua_pcall ARM64 signatures, hooks lua_pcall via Dobby, and serves a TCP socket for live Lua command injection from PC via `adb forward`.

**Tech Stack:** C (ARM64 NDK + Dobby), smali (Android bytecode), Python (build pipeline + TCP client), Lua (payloads)

**Spec:** `docs/superpowers/specs/2026-03-25-android-port-design.md`
**Source plan:** `docs/superpowers/plans/2026-03-25-android-port.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `Scripts/inject/android/native/sig_config.h` | Create | ARM64 byte signatures for lua_load/lua_pcall |
| `Scripts/inject/android/native/inject_android.cpp` | Create | Hook library: pattern scan, Dobby hooks, TCP server |
| `Scripts/inject/android/native/CMakeLists.txt` | Create | NDK cross-compile config for libinject.so |
| `Scripts/inject/android/build_native.sh` | Create | Shell helper to invoke NDK cmake build |
| `Scripts/inject/android/smali/InjectProvider.smali` | Create | ContentProvider that calls System.loadLibrary |
| `Scripts/inject/android/smali/SigSpoof.smali` | Create | IPackageManager proxy for cert spoofing |
| `Scripts/inject/android/build_apk.py` | Create | APK decompile/patch/rebuild pipeline (mode A+B) |
| `Scripts/inject/android/debug_android.py` | Create | TCP client replacing Windows named pipe client |
| `Scripts/inject/android/run_android.py` | Create | Unified runner (test/probe/lua) for Android |

---

### Task 1: ARM64 Signature Config

**Files:**
- Create: `Scripts/inject/android/native/sig_config.h`

**Reference:** Signatures extracted from `Scripts/inject/sig_results_android.txt`

- [ ] **Step 1:** Create `sig_config.h` with `SigEntry` struct, `SIG_LUA_LOAD_1` / `SIG_LUA_PCALL_1..3` byte arrays + masks, and `LUA_LOAD_SIGS` / `LUA_PCALL_SIGS` lookup tables. Copy verbatim from source plan lines 39–156.

- [ ] **Step 2:** Commit: `feat(android): add ARM64 byte signatures for lua_load/lua_pcall`

---

### Task 2: Native Hook Library

**Files:**
- Create: `Scripts/inject/android/native/inject_android.cpp`

Port of `Scripts/inject/inject.cpp` (Windows/x86_64/MinHook) → Android/ARM64/Dobby. Removes Windows-specific code (PEB unlinking, named pipes, VK_F3 hotkeys). Adds: `dl_iterate_phdr` ELF scanning, Dobby hook, TCP socket server, `__android_log_print`.

- [ ] **Step 1:** Create `inject_android.cpp` with these sections:
  - Lua function types (`tLua_Load`, `tLua_Pcall`)
  - `ReaderData` + `MyLuaReader` + `LuaPopOne` + `ExecuteLua` (same logic as Windows)
  - `hkLua_Pcall` hook: first-call auto-inject from `/sdcard/.../Test.lua`, then check TCP `cmdQueue`
  - `dl_callback` + `PatternScan` + `ScanForFunction` for ELF `.text` scanning
  - `TcpServerThread` on port 19840 (127.0.0.1 only, 64KB buffer)
  - `JNI_OnLoad` entry point: find libGame.so → scan sigs → DobbyHook → start TCP server
  - Copy verbatim from source plan lines 176–533.

- [ ] **Step 2:** Commit: `feat(android): native hook library with Dobby + TCP server`

---

### Task 3: NDK Build Config

**Files:**
- Create: `Scripts/inject/android/native/CMakeLists.txt`
- Create: `Scripts/inject/android/build_native.sh`

- [ ] **Step 1:** Create `CMakeLists.txt` — FetchContent for Dobby, `add_library(inject SHARED)`, link `dobby`, `log`, `dl`. Copy from source plan lines 552–588.

- [ ] **Step 2:** Create `build_native.sh` — takes NDK path arg or `$ANDROID_NDK_HOME`, cmake configure + build, verify output. Copy from source plan lines 595–627.

- [ ] **Step 3:** Build and verify:
```bash
cd Scripts/inject/android && bash build_native.sh
file native/build_arm64/libinject.so
# Expected: ELF 64-bit LSB shared object, ARM aarch64
```

- [ ] **Step 4:** Commit: `feat(android): NDK build config for libinject.so`

---

### Task 4: Smali Injection Files

**Files:**
- Create: `Scripts/inject/android/smali/InjectProvider.smali`
- Create: `Scripts/inject/android/smali/SigSpoof.smali`

- [ ] **Step 1:** Create `InjectProvider.smali` — ContentProvider that calls `System.loadLibrary("inject")` in `onCreate()` + installs `SigSpoof`. Includes required stub methods (query/getType/insert/delete/update). Copy from source plan lines 667–747.

- [ ] **Step 2:** Create `SigSpoof.smali` — stub with `ORIGINAL_CERT_PLACEHOLDER` field, `install()` method that checks context and logs. `build_apk.py` replaces the placeholder at build time. Copy from source plan lines 754–794.

- [ ] **Step 3:** Commit: `feat(android): smali ContentProvider loader + signature spoof stub`

---

### Task 5: APK Repackage Pipeline

**Files:**
- Create: `Scripts/inject/android/build_apk.py`

Main build script handling Mode A (merge splits → single APK) and Mode B (patch individual splits). Uses `apktool`, `zipalign`, `apksigner`.

- [ ] **Step 1:** Create `build_apk.py` with:
  - `extract_original_cert()` — reads cert from base.apk META-INF
  - `build_native()` — invokes cmake NDK build
  - `decompile_apk()` / `merge_split()` — apktool decompile + zip merge
  - `inject_patches()` — copy .so, copy smali (replacing cert placeholder), patch AndroidManifest.xml with provider, disable isSplitRequired
  - `rebuild_apk()` — apktool build → zipalign → apksigner
  - `mode_merge()` / `mode_split()` — orchestrate the two modes
  - `main()` — argparse with `--mode`, `--apk-dir`, `--skip-native`, `--ndk`
  - Copy from source plan lines 817–1213.

- [ ] **Step 2:** Verify: `python build_apk.py --help` shows expected options.

- [ ] **Step 3:** Commit: `feat(android): APK repackage pipeline with mode A (merge) and B (split)`

---

### Task 6: TCP Communication Client

**Files:**
- Create: `Scripts/inject/android/debug_android.py`

Drop-in replacement for `Scripts/inject/debug.py` using TCP sockets instead of Windows named pipes.

- [ ] **Step 1:** Create `debug_android.py` — `send_to_lua_gate()` function + CLI. Host 127.0.0.1, port 19840, 5s timeout. Copy from source plan lines 1244–1307.

- [ ] **Step 2:** Commit: `feat(android): TCP client for Lua command injection`

---

### Task 7: Android Runner

**Files:**
- Create: `Scripts/inject/android/run_android.py`

Unified runner matching `Scripts/inject/run.py` but for Android.

- [ ] **Step 1:** Create `run_android.py` with subcommands:
  - `push` — adb push Scripts/{lib,ui,actions,data} + path-rewritten Test.lua to device
  - `forward` — `adb forward tcp:19840 tcp:19840`
  - `inject` — send loadfile command via TCP
  - `lua "<code>"` — send inline Lua via TCP
  - Copy from source plan lines 1327–1443.

- [ ] **Step 2:** Commit: `feat(android): unified runner with push/inject/lua/forward commands`

---

### Task 8: End-to-End Verification

No new files. Verifies the full pipeline.

- [ ] **Step 1:** Build native: `bash build_native.sh` → verify `libinject.so` is ARM64 ELF
- [ ] **Step 2:** Build APK: `python build_apk.py --mode merge` → verify `output/wwm_patched.apk`
- [ ] **Step 3:** Install: `adb install output/wwm_patched.apk`
- [ ] **Step 4:** Push scripts: `python run_android.py push`
- [ ] **Step 5:** Launch game, then: `python run_android.py forward` + `python debug_android.py "print('hello')"`
- [ ] **Step 6:** Check logcat: `adb logcat -s WWM_INJECT:*` for JNI_OnLoad, sig scan, hook install, TCP start
- [ ] **Step 7:** Commit: `feat(android): complete Android injection port`

## Verification Plan

### Automated Tests
- `python build_apk.py --help` — verify CLI parses without error
- `file native/build_arm64/libinject.so` — verify ARM64 ELF output
- `python debug_android.py --help` — verify TCP client loads

### Manual Verification (requires Android device + NDK)
1. Build native library with NDK (`build_native.sh`)
2. Place original APK splits in `WWM_APK/` directory
3. Run `python build_apk.py --mode merge` to produce patched APK
4. `adb install` the patched APK on a test device
5. Launch game → `adb forward tcp:19840 tcp:19840` → `python debug_android.py "print('hello')"`
6. Verify `adb logcat -s WWM_INJECT:*` shows hook installation and TCP server startup
