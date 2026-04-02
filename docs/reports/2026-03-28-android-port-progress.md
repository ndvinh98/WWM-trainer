## 1. Summary

The Android injection pipeline is operational — native lib loads, dispatch hook active,
TCP server works, and `luaD_protectedparser` successfully compiles Lua code into `LUA_TFUNCTION`.

**Status: ⚠️ Parse works. Execution pipeline hangs via `luaD_precall`.**

**Current blocker (2026-04-02):** We correctly identified the REAL `luaV_execute` (27KB VM loop at `0x31DA9F4`) and the REAL `luaD_precall` (`0x31B3F0C`). We corrected the signature to `CallInfo* luaD_precall(L, func, nresults)` and passed `(L, func_stkid, 0)`. However, the execution still hangs inside the `luaD_precall` call and times out via TCP. The thread may be blocked on a mutex or expecting a different surrounding context/state that `lua_load` callers normally perform (like `luaD_callnoyield`).

---

## 2. Environment Setup

```bash
export ANDROID_HOME="/usr/local/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.2.12479018"
export PATH="$PATH:$ANDROID_HOME/build-tools/34.0.0"
```

Required: JDK (Temurin 25), apktool 3.0.1, Android NDK r27c, Build-tools 34.0.0, Ninja, CMake, ADB.

---

## 3. Build & Deploy

Use [`fast_deploy.py`](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/fast_deploy.py) for the full rebuild+deploy cycle:

```bash
python3 Scripts/inject/android/fast_deploy.py
```

This handles: native `.so` rebuild → replace in APK → zipalign + resign → `adb install-multiple` → port forward → launch. Takes ~150-300s depending on device.

For native-only changes (skip APK repack):
```bash
cmake --build Scripts/inject/android/native/build --config Release
python3 Scripts/inject/android/fast_deploy.py --skip-native
```

**Watch logs:**
```bash
adb logcat -s 'WWM_INJECT:*'
```

**Send commands:**
```bash
printf "print('HELLO')" | nc -w 15 localhost 19840
```

---

## 4. Architecture

### Injection Entry Point
- `System.loadLibrary("inject")` injected into `StubApp.attachBaseContext()` via smali patching
- `JNI_OnLoad` spawns init thread → polls for `libGame.so` → hooks `luaopen_*` via `dlsym` + Dobby
- First `luaopen_*` fire → captures `lua_State*`, resolves API addresses via delta, hooks dispatch function

### JNI Exception Guard
JNI function table patched (`GetFieldID`, `GetStaticFieldID`, `FindClass`) to auto-clear pending exceptions. Required because Firebase's `ResourceNotFoundException` was left pending, causing `abort()` in `libunisec.so`. Required `mprotect()` on vivo V2405A (Android 16) where JNI table is in read-only memory.

### Execution Pipeline
```
TCP command (port 19840)
  → Construct Zio struct, install at L+0x38
  → luaD_protectedparser(L, zio_ptr, mode=0)   → rc=0 (compilation) ✅
  → luaD_precall(L, func, nresults=0)          → ⚠️ HANGS HERE
  → execute(L, ci)                             → NEVER REACHED
```

### Key Constraints
- `lua_load` wrapper at `0x31B2DE8` has mutex at `L+0x58` → **deadlock from hook context**. Must call `luaD_protectedparser` directly.
- `luaopen_*` symbols are exported (hookable via `dlsym`), but all standard Lua C API symbols are stripped.

---

## 5. Confirmed API Map (Updated 2026-04-02)

### Verification Method

1. **Anchor functions**: `luaopen_socket_core` BL targets cross-referenced with known Lua C API call patterns → confirmed `lua_createtable` (`0x3198664`), `luaL_setfuncs` (`0x319F8F4`), `lua_pushstring` (`0x3196570`), `lua_settable` (`0x3199020`)
2. **Delta computation**: Base delta from confirmed anchors → all internal API addresses
3. **Disassembly Chain Analysis**: Traced `lua_load` (wrapper) → callers (dostring/pcall equivalents) → `lua_pcallk` candidate (`0x31B47F4`) → `luaD_precall` (`0x31B3F0C`) and `luaD_callnoyield` / `luaV_execute` (`0x31DA9F4`).

### Confirmed Functions

| VA | Function | Status | Evidence |
|---|---|---|---|
| `0x31B7010` | `luaD_protectedparser` | ✅ Working | 3-param `(L, zio_ptr, mode_int)`. Parser returns rc=0 with correct Zio setup |
| `0x319F8F4` | `luaL_setfuncs` | ✅ Confirmed | Called by 3/5 `luaopen_*` |
| `0x3198664` | `lua_createtable` | ✅ Confirmed | Called by all 5 `luaopen_*` with `w1=0, w2=0` |
| `0x3196570` | `lua_pushstring` | ✅ Confirmed | Called by `luaopen_socket_core` 3 times |
| `0x31DA9F4` | `luaV_execute` (real) | ⚠️ Suspect | 27KB function with 299 BLs. This is the VM loop. Prologue takes `(L, ci)`. |
| `0x31B3F0C` | `luaD_precall` (real) | ⚠️ Suspect | Precall frame setup. Takes `(L, func, nresults)`. Called by `0x31B47F4` (pcallk). Hangs on call. |
| `0x31B47F4` | `lua_pcallk` (wrapper) | 📋 Untested | Likely `lua_pcallk` macro or `luaD_callnoyield`. Calls precall then execute. |

### Misidentified Functions (Corrected 2026-04-02)

| VA | Previously Claimed | Actual | Evidence |
|---|---|---|---|
| `0x319E750` | `luaD_pcall` | **Unknown utility** (NOT pcall) | 136 bytes only. Receives small int args (1, 2, 3, -1). Fires ~5000-160K/s. Used as dispatch hook timing only. |
| `0x3195D4C` | `luaD_precall` | **No-op / Unknown** | Returns 0 instantly, no side effects, doesn't change `ci`. |
| `0x31AFCA4` | `luaV_execute` | **80-byte helper** | Tiny check function storing to `[x2, #0xE8]`. Not the VM loop. |
| `G(L)+0x100`| VM dispatch ptr | **Post-load hook ptr** | Points to `0x319FE1C` which calls the `0x3195D4C` no-op. |

---

## 6. Execution Pipeline (Current State)

### What Works

| Component | Status | Details |
|-----------|--------|---------|
| Hook installation | ✅ | 5/5 `luaopen_*` hooked via `dlsym` + Dobby |
| `lua_State` capture | ✅ | Captured from first `luaopen_socket_core` fire |
| Dispatch hook | ✅ | Hooked `0x319E750`, fires 5000-160K/s during gameplay |
| TCP command server | ✅ | Port 19840, receives commands, sends responses |
| `luaD_protectedparser` | ✅ | Parser succeeds (rc=0) with correct Zio at `L+0x38` |
| JNI exception guard | ✅ | Auto-clears pending exceptions (Firebase fix) |
| Compiled chunk type | ✅ | TValue type=6 (`LUA_TFUNCTION`) at func_stkid |

### Current Blocker: Execution Hangs in `luaD_precall`

After compiling the Lua chunk and verifying it sits at `L->top`, we call `pLuaD_Precall(L, func, 0)` (`0x31B3F0C`). The game thread freezes and times out from the TCP client. 

**Hypotheses:**
1. **Missing State/Context**: We are hooking a high-frequency dispatch utility that may execute in a sensitive context (e.g., during GC or internal VM state transition) where starting a completely new frame via `luaD_precall` causes a deadlock or corruption.
2. **Missing Call Graph Wrapper**: The game's `lua_load` callers don't call `precall` directly; they call `0x31B47F4` (`lua_pcallk`) or `0x31B0800`.
3. **Threading**: The thread firing the dispatch hook (28339) might hold a lock we need.

---

## 7. Next Steps for Next Session

1. **Abandon Raw Internal APIs**: Stop trying to chain `luaD_precall` and `luaV_execute` directly. The game's modified Lua 5.4 VM is too complex (5 internal for-state vars, custom mutexes, etc) to forge the stack frame manually without side-effects.
2. **Target High-Level Wrappers**:
    - Disassemble and test calling the `lua_pcallk` candidate at `0x31B47F4` directly: `lua_pcallk(L, nargs, nresults, errfunc)`.
    - Alternatively, test `0x31B0800` (another post-load call target).
3. **Use the Dedicated Script Thread** (If applicable): Verify if the dispatch hook thread `(L, a1=-1, a2=7)` is safe for execution, or if we should run commands from an OS thread using a game-provided thread-safe job queue.
4. **Hook `luaB_load` or `luaL_dostring`**: Try to locate the global `load` or `loadstring` function implementation instead of compiling manually.

---

## 8. File Map

```
Scripts/inject/android/
├── fast_deploy.py             # Quick rebuild+deploy
├── native/
│   ├── inject_android.cpp     # Core injection: Dobby hooks, Zio construction, TCP server, ExecuteLua
│   ├── CMakeLists.txt         # NDK build (FetchContent for Dobby)
│   └── build/
│       └── libinject.so       # Compiled ARM64 shared library
└── output/
    ├── patched_base.apk       # Patched base (smali injection)
    ├── patched_arm64.apk      # Patched arm64 split (libinject.so)
```

---

## 9. Session Timeline

| Date | Key Achievement |
|------|----------------|
| 2026-03-28 | Hook active, TCP server working, API offsets identified (some wrong) |
| 2026-03-29 | Discovered mutex, wrapper, TLS blockers. Parser working via `luaD_protectedparser` |
| 2026-04-01 | Progress report created |
| 2026-04-02 | **Major reversal**: Real `luaV_execute` found at 0x31DA9F4 (27KB). Real `luaD_precall` at 0x31B3F0C. Previous VAs were wrong. Corrected signatures but execution hangs inside `luaD_precall`. Next session to focus on high-level wrappers like `lua_pcallk`. |
