## 1. Summary

The Android injection pipeline is operational — native lib loads, dispatch hook active,
TCP server works, and `luaD_protectedparser` successfully compiles Lua code into `LUA_TFUNCTION`.

**Status: ⚠️ Parse works. Execution pipeline hangs via `luaD_precall`.**

**Current blocker (2026-04-02):** ~~We correctly identified the REAL `luaV_execute` (27KB VM loop at `0x31DA9F4`) and the REAL `luaD_precall` (`0x31B3F0C`). We corrected the signature to `CallInfo* luaD_precall(L, func, nresults)` and passed `(L, func_stkid, 0)`. However, the execution still hangs inside the `luaD_precall` call and times out via TCP.~~ **Root cause identified**: The entire approach of manually calling `luaD_precall` + `luaV_execute` is fundamentally wrong — the Windows version never uses internal APIs. See Section 7.

**Ghidra update (2026-04-02 22:00):** Headless Ghidra scan of `libGame.so` (192,553 functions, 131MB) confirmed all VAs but revealed a **consistent 0x10 byte offset error** in prior analysis. All function VAs from Python BL-target tracing point 0x10 bytes past the actual prologues. See [ghidra_lua_scan_results.txt](file:///f:/Coding/Where%20Winds%20Meet/Scripts/inject/android/analysis/ghidra_lua_scan_results.txt).

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

Use [`fast_deploy.py`](file:///f:/Coding/Where%20Winds%20Meet/Scripts/inject/android/fast_deploy.py) for the full rebuild+deploy cycle:

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
- First `luaopen_*` fire → captures `lua_State*`, resolves API addresses via delta, hooks ~~dispatch function~~ **`lua_pcallk`** (plan — not yet implemented)

### JNI Exception Guard
JNI function table patched (`GetFieldID`, `GetStaticFieldID`, `FindClass`) to auto-clear pending exceptions. Required because Firebase's `ResourceNotFoundException` was left pending, causing `abort()` in `libunisec.so`. Required `mprotect()` on vivo V2405A (Android 16) where JNI table is in read-only memory.

### Execution Pipeline

**Current (broken — will be replaced):**
```
TCP command (port 19840)
  → Construct Zio struct, install at L+0x38
  → luaD_protectedparser(L, zio_ptr, mode=0)   → rc=0 (compilation) ✅
  → luaD_precall(L, func, nresults=0)          → ⚠️ HANGS HERE
  → execute(L, ci)                             → NEVER REACHED
```

**Planned (mirror Windows — see Section 7):**
```
TCP command (port 19840)
  → queued in g_cmdQueue
  → hkLuaPcallk intercepts next game lua_pcallk call
  → lua_load(L, reader, data, "@cmd", "t")     → compile
  → oLuaPcallk(L, 0, 0, 0, NULL, NULL)         → execute via trampoline
  → oLuaPcallk(L, orig_args...)                → game's original call proceeds
```

### Key Constraints
- ~~`lua_load` wrapper at `0x31B2DE8` has mutex at `L+0x58` → **deadlock from hook context**. Must call `luaD_protectedparser` directly.~~ **Correction**: Mutex deadlock only occurs from the *dispatch hook* context (`0x319E750`), which already holds the lock. When called from the `lua_pcallk` hook context (like Windows), the mutex should NOT be held.
- `luaopen_*` symbols are exported (hookable via `dlsym`), but all standard Lua C API symbols are stripped. **Ghidra confirmed**: Only 5 `luaopen_*` + 4 `luaopen_*` symbol name strings found in the entire binary. No Lua error strings present (obfuscated/stripped).

---

## 5. Confirmed API Map (Updated 2026-04-02 + Ghidra)

### Verification Method

1. **Anchor functions**: `luaopen_socket_core` BL targets cross-referenced with known Lua C API call patterns → confirmed `lua_createtable`, `luaL_setfuncs`, `lua_pushstring`, `lua_settable`
2. **Delta computation**: Base delta from confirmed anchors → all internal API addresses
3. **Disassembly Chain Analysis**: Traced `lua_load` (wrapper) → callers (dostring/pcall equivalents) → `lua_pcallk` candidate → `luaD_precall` and `luaV_execute`.
4. **Ghidra headless scan (2026-04-02)**: Full auto-analysis of libGame.so (2526 sec, 192,553 functions). Confirmed all VAs exist as code but are offset 0x10 bytes from actual function entries. Rebase delta: `0xB8634` (ELF VA → Ghidra VA).

### Confirmed Functions (Ghidra-Corrected VAs)

> [!IMPORTANT]
> All VAs below are the **corrected** function-entry VAs (subtract 0x10 from prior Python BL-target VAs). The "Old VA" column shows what was in prior versions of this document and in `inject_android.cpp`.

| Old VA | Corrected VA | Function | Ghidra Entry | Size | Xrefs | Status | Evidence |
|---|---|---|---|---|---|---|---|
| ~~`0x31B7010`~~ | `0x31B7000` | `luaD_protectedparser` | `FUN_030fe9cc` | — | — | ✅ Working | Parser returns rc=0 with correct Zio setup |
| ~~`0x319F8F4`~~ | `0x319F8E4` | `luaL_setfuncs` | `FUN_030e72b0` | 212 | 66 | ✅ Confirmed | Called by 4/5 `luaopen_*` (BL graph) |
| ~~`0x3198664`~~ | `0x3198654` | `lua_createtable` | `FUN_030e0020` | 148 | 254 | ✅ Confirmed | Called by all 5 `luaopen_*` (BL graph, fan-in=5) |
| `0x3196570` | `0x3196560` | `lua_pushstring` | `FUN_030ddf2c` | 116 | 5176 | ✅ Confirmed | Very high xref count matches expected usage |
| ~~`0x31DA9F4`~~ | `0x31DA9E0` | `luaV_execute` | `FUN_031223ac` | **28524** (27.9KB) | — | ✅ Confirmed | 9th largest function in binary. Size matches known Lua 5.4 VM loop |
| ~~`0x31B3F0C`~~ | `0x31B3EFC` | `luaD_precall` | `FUN_030fb8c8` | — | — | ⚠️ Hangs | Takes `(L, func, nresults)`. Hangs when called from dispatch hook |
| ~~`0x31B47F4`~~ | `0x31B47E4` | `lua_pcallk` | `FUN_030fc1b0` | — | — | 📋 Untested | **NEXT TARGET**: Hook this instead of dispatch func |
| ~~`0x31B2DE8`~~ | `0x31B2DD8` | `lua_load` | `FUN_030fa7a4` | — | — | 📋 Untested | Use as direct call from pcallk hook. Has mutex — safe from pcallk context |
| ~~`0x319DDD8`~~ | `0x319DDC8` | `luaD_rawrunprotected` | `FUN_030e5794` | 288 | **30800** | ✅ Confirmed | Extremely high xref count — consistent with being called on every protected call |

### Misidentified Functions (Corrected 2026-04-02)

| VA | Previously Claimed | Actual | Evidence |
|---|---|---|---|
| `0x319E750` | `luaD_pcall` | **Unknown utility** (NOT pcall) | 136 bytes only. Receives small int args (1, 2, 3, -1). Fires ~5000-160K/s. Used as dispatch hook timing only. ~~Ghidra: inside `FUN_030e610c`.~~ **Ghidra: VA 0x319E740 is function start `FUN_030e610c`.** |
| `0x3195D4C` | `luaD_precall` | **No-op / Unknown** | Returns 0 instantly, no side effects, doesn't change `ci`. ~~Ghidra: inside `FUN_030dd708`.~~ |
| `0x31AFCA4` | `luaV_execute` | **80-byte helper** | Tiny check function storing to `[x2, #0xE8]`. Not the VM loop. |
| `G(L)+0x100`| VM dispatch ptr | **Post-load hook ptr** | Points to `0x319FE1C` which calls the `0x3195D4C` no-op. |

### New Functions Discovered via Ghidra BL Call-Graph

| Ghidra VA | ELF VA | Size | Xrefs | Fan-in | Potential ID |
|---|---|---|---|---|---|
| `FUN_030de0f4` | `0x3196728` | 220 | 3762 | 5 (all luaopen) | `lua_setfield` — has sxtw, called by all 5 luaopen |
| `FUN_030e0798` | `0x3198DCC` | 152 | 468 | 4 | `lua_gettop` or `lua_checkstack` — no BL calls, inline |
| `FUN_030dc974` | `0x3194FA8` | 172 | 498 | 4 | `lua_rawgeti` or `lua_getfield` — inline, sxtw |
| `FUN_030de1d0` | `0x3196804` | 36 | 2304 | 4 | `lua_pushboolean` or `lua_settop` — tiny, extremely hot |
| `FUN_030ffecc` | `0x31B8500` | 2016 | 45 | 2 | `luaL_loadbufferx` candidate — large, 19 BL calls |
| `FUN_0311a04c` | `0x3212680` | 1076 | 7 | 4 | Complex API function — 10 BL calls |

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
| **Ghidra project** | ✅ | `ghidra/WWM_libGame` — 192,553 functions, reusable |

### Current Blocker: ~~Execution Hangs in `luaD_precall`~~ Wrong approach entirely

~~After compiling the Lua chunk and verifying it sits at `L->top`, we call `pLuaD_Precall(L, func, 0)` (`0x31B3F0C`). The game thread freezes and times out from the TCP client.~~

**Root cause (2026-04-02):** Calling internal VM functions (`luaD_precall`, `luaV_execute`) directly is fundamentally wrong. The Windows version hooks `lua_pcall` (public C API) and lets the game handle internals. The dispatch hook context (`0x319E750`) fires during sensitive VM state and likely holds locks that `luaD_precall` tries to acquire.

**Solution:** Hook `lua_pcallk` at corrected VA `0x31B47E4` instead, execute code from that context using `lua_load` + original `lua_pcallk` trampoline. See Section 7.

~~**Hypotheses:**~~
~~1. **Missing State/Context**: We are hooking a high-frequency dispatch utility that may execute in a sensitive context (e.g., during GC or internal VM state transition) where starting a completely new frame via `luaD_precall` causes a deadlock or corruption.~~
~~2. **Missing Call Graph Wrapper**: The game's `lua_load` callers don't call `precall` directly; they call `0x31B47F4` (`lua_pcallk`) or `0x31B0800`.~~
~~3. **Threading**: The thread firing the dispatch hook (28339) might hold a lock we need.~~

**All three hypotheses were correct** — #1 and #3 explain the hang, #2 points to the solution.

---

## 7. Next Steps (Updated 2026-04-02 with Ghidra Evidence)

> [!IMPORTANT]
> **Critical path**: Hook `lua_pcallk` (Ghidra-verified at `0x31B47E4`), use `lua_load` (at `0x31B2DD8`) + original trampoline. This mirrors the Windows architecture exactly.

### Phase 1: Clean Rewrite (~2 hours)

1. **Remove** all internal API code: dispatch hook, `luaD_precall`, `luaV_execute`, Zio construction, `L+0x38` manipulation
2. **Add** `lua_pcallk` hook at corrected VA `0x31B47E4` via Dobby
3. **Add** `lua_load` direct call at corrected VA `0x31B2DD8`
4. **Rewrite** `ExecuteLua()` to use `lua_load` + `oLuaPcallk(original trampoline)` — same pattern as Windows `inject.cpp`

See [android_port_analysis.md](file:///f:/Coding/Where%20Winds%20Meet/Scripts/inject/android/analysis/android_port_analysis.md) Section "Detailed Implementation Plan" for step-by-step code.

### Phase 2: Test & Validate (~30 min)

1. Build + deploy via `fast_deploy.py`
2. Send: `printf "print('HELLO')" | nc -w 15 localhost 19840`
3. Verify `OK` response (not `TIMEOUT`)
4. If works: bootstrap.lua loading

### Phase 3: Signature Resilience (~1 hour)

Extract function prologue bytes from Ghidra for version-resilient pattern scanning (protects against game updates).

---

## 8. File Map

```
Scripts/inject/android/
├── fast_deploy.py             # Quick rebuild+deploy
├── native/
│   ├── inject_android.cpp     # Core injection: Dobby hooks, TCP server, ExecuteLua
│   ├── sig_config.h           # ARM64 byte signatures (needs update with Ghidra VAs)
│   ├── CMakeLists.txt         # NDK build (FetchContent for Dobby)
│   └── build/
│       └── libinject.so       # Compiled ARM64 shared library
├── analysis/
│   ├── android_port_analysis.md      # This approach analysis
│   ├── run_ghidra_scan.py            # PyGhidra scanner (reusable)
│   ├── ghidra_scan_lua.py            # Original Jython script (doesn't work with Ghidra 12+)
│   └── ghidra_lua_scan_results.txt   # Full scan output
└── output/
    ├── patched_base.apk       # Patched base (smali injection)
    ├── patched_arm64.apk      # Patched arm64 split (libinject.so)

ghidra/
├── WWM_libGame/               # Ghidra project (192,553 functions analyzed)
```

---

## 9. Session Timeline

| Date | Key Achievement |
|------|----------------|
| 2026-03-28 | Hook active, TCP server working, API offsets identified (some wrong) |
| 2026-03-29 | Discovered mutex, wrapper, TLS blockers. Parser working via `luaD_protectedparser` |
| 2026-04-01 | Progress report created |
| 2026-04-02 AM | **Major reversal**: Real `luaV_execute` found at ~~0x31DA9F4~~ `0x31DA9E0` (27.9KB). Real `luaD_precall` at ~~0x31B3F0C~~ `0x31B3EFC`. Previous VAs were wrong. Corrected signatures but execution hangs inside `luaD_precall`. |
| 2026-04-02 PM | **Ghidra headless scan completed** (42 min analysis, 192,553 functions). All VAs confirmed 0x10 bytes off from function entries. Corrected all VAs. PyGhidra scanner operational. **Decision: abandon internal API approach, mirror Windows `lua_pcallk` hook pattern.** |
