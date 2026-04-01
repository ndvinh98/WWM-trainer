# Android Port — Progress Report

**Date:** 2026-03-28  
**Plan:** [`docs/plans/2026-03-25-android-port.md`](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/docs/plans/2026-03-25-android-port.md)  
**Test Device:** vivo V2405A (serial `10AF891YKY006E3`)

---

## 1. Summary

The Android injection pipeline is **fully operational**. The native hook library loads,
finds `libGame.so`, pattern-scans for Lua function signatures, installs a single Dobby
hook on `luaD_pcall`, and starts a TCP command server — all confirmed working.

**Status: ✅ Hook active, game stable, TCP injection ready.**

The `luaD_pcall` hook fires continuously (~1000 calls/5s) during gameplay with no crashes.
All 4 Lua function signatures are confirmed correct via call-graph analysis from exported
`luaopen_*` symbols. Previous misidentified signatures (v1=`lua_createtable`,
v2=`luaD_call`, v3=`luaD_rawrunprotected`) have been replaced.

---

## 2. macOS Toolchain Setup

Installed all required tools on macOS for cross-compiling and APK patching:

| Tool | Version | Install Method |
|---|---|---|
| JDK | Temurin 25.0.2 LTS | `brew install --cask temurin` |
| apktool | 3.0.1 | Manual jar + wrapper from [GitHub releases](https://github.com/iBotPeaches/Apktool/releases/tag/v3.0.1) |
| Android NDK | r27c (27.2.12479018) | `sdkmanager "ndk;27.2.12479018"` |
| Build-tools | 34.0.0 (zipalign, apksigner) | `sdkmanager "build-tools;34.0.0"` |
| Ninja | 1.13.2 | `brew install ninja` |
| CMake | 4.3.1 | Pre-existing |
| ADB | 34.0.0 | Pre-existing |
| Python | 3.10.0 (pyenv) | Pre-existing |

Environment variables added to `~/.zshrc`:
```bash
export ANDROID_HOME="/usr/local/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.2.12479018"
export PATH="$PATH:$ANDROID_HOME/build-tools/34.0.0"
```

---

## 3. What We Built & Tested

### 3.1 Native Library Build

```bash
# Build libinject.so for ARM64 via NDK + Dobby
cd Scripts/inject/android
export ANDROID_HOME="/usr/local/share/android-commandlinetools"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.2.12479018"
export PATH="$PATH:$ANDROID_HOME/build-tools/34.0.0"

python3 build_apk.py --mode merge
# Or to skip native rebuild on subsequent runs:
python3 build_apk.py --mode split --skip-native
```

**Result:** `native/build/libinject.so` — 391.7 KB, ARM64 ELF shared object.
Fetches Dobby via CMake FetchContent, cross-compiles with NDK toolchain.

### 3.2 APK Build — Mode A (Merge)

Merges `base.apk` + selected splits into a single APK.

```bash
python3 build_apk.py --mode merge
```

- Produced `output/wwm_patched.apk` (125.3 MB)
- **Problem:** Missing game asset packs (`split_yysls_it1` = 3.1 GB, `split_yysls_it2` = 452 MB)
- Game crash-looped immediately because assets were absent

### 3.3 APK Build — Mode B (Split) ✅

Patches base & arm64 splits individually, resigns all splits with same debug key.

```bash
python3 build_apk.py --mode split --skip-native
```

**Output files:**

| File | Size |
|---|---|
| `patched_base.apk` | 56 MB |
| `patched_arm64.apk` | 70 MB |
| `patched_split_config.en.apk` | 873 KB |
| `patched_split_config.xxhdpi.apk` | 1.3 MB |
| `patched_split_yysls_it1.apk` | 3.1 GB |
| `patched_split_yysls_it2.apk` | 452 MB |

### 3.4 Deploy to Device

```bash
# Uninstall previous version
adb -s 10AF891YKY006E3 uninstall com.netease.yysls

# Install all patched splits
adb -s 10AF891YKY006E3 install-multiple \
  output/patched_base.apk \
  output/patched_arm64.apk \
  output/patched_split_config.en.apk \
  output/patched_split_config.xxhdpi.apk \
  output/patched_split_yysls_it1.apk \
  output/patched_split_yysls_it2.apk

# Set up port forwarding for TCP injection
adb -s 10AF891YKY006E3 forward tcp:19840 tcp:19840

# Launch the game
adb -s 10AF891YKY006E3 shell monkey -p com.netease.yysls -c android.intent.category.LAUNCHER 1
```

### 3.5 Observe Logs

```bash
# Filter for our injection tag
adb -s 10AF891YKY006E3 logcat -s 'WWM_INJECT:*'

# Check for crashes
adb -s 10AF891YKY006E3 logcat -d | grep -E "FATAL|sig=|SIGABRT|WWM_INJECT|NCCrashHandler"

# Full game process logs
adb -s 10AF891YKY006E3 logcat -d | grep "com.netease.yysls"
```

---

## 4. Injection Pipeline — Verified Working ✅

The logcat output confirms every stage of our injection works:

```
15:57:34.501  WWM_INJECT: === JNI_OnLoad: inject library loaded ===
15:57:34.501  WWM_INJECT: Init thread spawned, returning to app startup
15:57:34.501  WWM_INJECT: [init] Waiting for libGame.so to load...
15:57:34.584  WWM_INJECT:   .text segment: base=0x732a732000 size=0x76f5490 (119.0 MB)
15:57:34.584  WWM_INJECT: [init] libGame.so found, scanning for signatures...
15:57:34.629  WWM_INJECT:   [lua_load_v1] matched at 0x732d8e4de8 (offset +0x31b2de8)
15:57:34.629  WWM_INJECT: Found lua_load via sig 'lua_load_v1' at 0x732d8e4de8
15:57:34.664  WWM_INJECT:   [lua_pcall_v1] matched at 0x732d8ca664 (offset +0x3198664)
15:57:34.664  WWM_INJECT: Found lua_pcall via sig 'lua_pcall_v1' at 0x732d8ca664
15:57:34.664  WWM_INJECT: [init] Hook installed. lua_load=0x732d8e4de8, lua_pcall=0x732d8ca664
15:57:34.664  WWM_INJECT: [init] TCP server started on port 19840. Ready.
15:57:34.665  WWM_INJECT: [TCP] server listening on 127.0.0.1:19840
```

**All phases succeeded:**
1. ✅ Native lib loads via `System.loadLibrary("inject")` from patched `StubApp.attachBaseContext()`
2. ✅ Background init thread polls for `libGame.so`
3. ✅ `libGame.so` found, executable `.text` segment located (119 MB)
4. ✅ Pattern scan matches `lua_load_v1` and `lua_pcall_v1` signatures
5. ✅ Dobby inline hook installed on `lua_pcall`
6. ✅ TCP command server listening on `127.0.0.1:19840`

---

## 5. Current Blocker — SIGABRT from UniSDK Signature Check

### Crash Timeline

```
15:57:34.664  ✅ Hook installed, TCP server ready
15:57:35.470  🔗 TLS handshake with protocol.unisdk.easebar.com
15:57:35.472  💥 NCCrashHandler sig=6 (SIGABRT)
15:57:35.473  ⏱️ Watchdog activated, 15s timeout
```

### Root Cause

The NetEase UniSDK performs a **server-side APK signature check**:
1. App connects to `protocol.unisdk.easebar.com` over TLS
2. Sends the APK's signing certificate as part of the protocol handshake
3. Server rejects it — our **debug key** doesn't match the original NetEase signing key
4. SDK native code calls `abort()` → SIGABRT → process killed

### Why SigSpoof Doesn't Help

| Issue | Detail |
|---|---|
| No v1 cert available | APK uses v2/v3 signing only — no JAR certs in `META-INF/` |
| SigSpoof is a stub | Only logs messages, doesn't hook `PackageManager.getPackageInfo()` |
| Native-level check | UniSDK likely reads signing info via JNI or directly from APK bytes, bypassing Java PM |

---

## 6. Bypass Attempts — Detailed Log

### Attempt 1: Hook `getaddrinfo` to Block DNS (Option A)
**Result:** ❌ DNS hook never fires
The UniSDK uses OkHttp (Java-level HTTP), which resolves DNS through Java's networking
stack, not libc `getaddrinfo`. The `protocol.unisdk.easebar.com` requests use cached
data from `/data/user/0/com.netease.yysls/files/protocol/cache/` anyway.

### Attempt 2: Hook `abort()` + `pthread_exit()`
**Result:** ❌ Black screen — engine thread killed
Abort is called on the **Messiah engine init thread** (the one setting up EGL, fonts,
the render loop). Killing it with `pthread_exit` prevents the crash but the engine
never completes initialization → BLASTBufferQueue gets destroyed → permanent black screen.

### Attempt 3: Hook `abort()` + plain `return`
**Result:** ❌ SIGSEGV → crash loop
`abort()` is `_Noreturn`. The compiler does not generate valid code after the `bl abort`
callsite. Returning from the hook causes the engine thread to execute garbage bytes →
SIGSEGV (sig=11) → NCCrashHandler minidump → process restart → infinite crash loop.

### Attempt 4: Hook `raise()` + `_exit()` to neutralize `abort()` internals
**Result:** ❌ Hooks never fire
Bionic's `abort()` calls `raise()` and `_exit()` internally within `libc.so`. Dobby
hooks the function entry point (PLT), but intra-library calls bypass the PLT. Our
hooks are never invoked. Also, hooking `_exit()` globally broke the fork-exec pattern
(`_exit(0)` from child processes was suppressed, causing ANR).

### Attempt 5: Hook `abort()` + `siglongjmp` from SIGABRT handler
**Result:** ⚠️ Escape works, but caller code is garbage → crash loop
Installed a custom `SIGABRT` handler that `siglongjmp`s back into the abort hook.
Successfully escaped `abort()` — the thread continued. However, the code path after
the `abort()` callsite in `libunisec.so` is invalid (compiler _Noreturn optimization),
so execution immediately hits SIGSEGV → crash → restart. ~2.5s per cycle.

---

## 7. Revised Root Cause — NOT Signature Verification

**The original diagnosis was wrong.** The crash is NOT caused by server-side APK
signature rejection. Tombstone analysis reveals the true call chain:

### Tombstone Backtrace
```
#00  abort+156                        (libc.so)
#01  art::Runtime::Abort              (libart.so)
#04  art::Thread::AssertNoPendingException  (libart.so)
#05  art::ClassLinker::FindClass      (libart.so)
#07  art::JNI::GetFieldID             (libart.so)
#08  libunisec.so+0x4a551c           ← anti-tamper library
#09  libunisec.so+0x20b71c
#10  libunisec.so+0x213084
```

### Actual Cause
1. `apktool d -r` preserves binary resources, but after APK re-signing, resource ID
   `#0x7f0d0046` becomes unresolvable (likely `google_app_id` or similar Firebase config)
2. `FirebaseInitProvider.onCreate()` throws `ResourceNotFoundException`
3. The Java exception is left **pending** on the thread (not caught by the framework)
4. `StubApp.onCreate()` is a **native method** implemented in `libunisec.so`
5. `libunisec.so` performs JNI calls (`GetFieldID`) → ART's `AssertNoPendingException`
   finds the stale Firebase exception → calls `abort()`

### Key Evidence
- Tombstone abort message: `No pending exception expected: java.lang.RuntimeException:
  Unable to get provider com.google.firebase.provider.FirebaseInitProvider:
  android.content.res.Resources$NotFoundException: Unable to find resource ID #0x7f0d0046`
- The abort comes from **ART runtime** (not UniSDK signature verification)
- `StubApp.onCreate()` is native (`libunisec.so`), so we cannot inject smali into it

---

## 8. Bypass Progress — JNI Table Patch + Signature Investigation

### Attempt 6: Patch JNI Function Table ✅ (Firebase crash fixed)
**Result:** ✅ Firebase crash eliminated — game survives past init

Overwrote JNI function table entries for `GetFieldID`, `GetStaticFieldID`, and `FindClass`
with wrappers that auto-clear any pending exception before calling the original.

**Key detail:** The JNI function table is in read-only memory on this device (vivo V2405A,
Android 16). Required `mprotect()` to make the table writable before patching. Without
`mprotect`, writing to the table caused an immediate SIGSEGV at `JNI_OnLoad+140`.

```cpp
// mprotect the function table to make it writable
auto* funcs = *(reinterpret_cast<void***>(env));
uintptr_t page = (uintptr_t)&funcs[0] & ~(4096-1);
mprotect((void*)page, 256*sizeof(void*), PROT_READ|PROT_WRITE);

// Indices in JNINativeInterface (stable across Android versions)
funcs[6]   = hkFindClass;        // auto-clears exceptions
funcs[94]  = hkGetFieldID;       // auto-clears exceptions
funcs[144] = hkGetStaticFieldID; // auto-clears exceptions
```

**Result:** Firebase now initializes successfully:
```
FirebaseApp: Device unlocked: initializing all Firebase APIs for app [DEFAULT]
FirebaseInitProvider: FirebaseApp initialization successful
```

### Attempt 7: Hooking pcall candidates — Dobby v2 hook causes abort ❌→✅

After fixing the Firebase crash, the game still aborted. Investigation revealed:

1. **Hooking pcall candidate v2 (offset `0x3195D4C`) with Dobby causes SIGABRT.**
   The inline hook corrupts the code path — the game's own code calls through the
   hooked function and crashes. Both `caller` and `caller2` in the abort are in
   `libGame.so`, not our code. Skipping v2 hook fixes this.

2. **Game survives 30+ seconds** with v1+v3 hooks and v2 skipped, as long as we
   don't call `oLua_Load`.

### Current Blocker: Wrong lua_load signature

The function at offset `0x31B2DE8` (matched by `lua_load_v1` signature) is **NOT lua_load**.
Calling it with any parameters always aborts at +0x124. The abort happens inside
`libGame.so` itself — a subroutine called by this function triggers `abort()`.

**Evidence:**
- Calling the function from a background thread after 30s delay still aborts
- The abort caller chain: our `ExecuteLua` → `oLua_Load` → BL to subroutine → `abort()`
- The byte at +0x120 is `BL +0x532B28` (branch to a subroutine), +0x124 is a new function
  prologue (`SUB SP, SP, #0x160`) — the abort return address points here

### Current Blocker: Wrong lua_pcall signatures

All three pcall candidates have issues:
- **v1** (`0x3198664`): Only fires ~50 times during init (25ms burst), then never again
  during gameplay. Not the runtime `lua_pcall`.
- **v2** (`0x3195D4C`): Dobby inline hook corrupts the function → instant SIGABRT.
- **v3** (`0x319DDD8`): Hook installs OK but was not observed firing during the test.

Lua symbols are **fully stripped** from `libGame.so` — `dlsym` finds nothing for any of:
`lua_load`, `lua_pcall`, `lua_pcallk`, `luaL_loadbufferx`, `luaL_loadstring`,
`luaL_dostring`, `luaD_pcall`, `luaD_rawrunprotected`.

---

## 9. RESOLVED — Correct Lua Function Mapping (via Call-Graph Analysis)

### Method: `luaopen_*` Call-Graph + Fan-In Analysis

Option A (string xrefs) **failed** — all Lua error strings (`"attempt to call a %s value"`,
`"error in error handling"`, etc.) are **encrypted/obfuscated** in the Android binary. No
standard `\x1bLua` bytecode headers found either.

**Solution:** Traced BL call targets from 5 exported `luaopen_*` functions, which MUST call
Lua C API functions. Then performed fan-in analysis scanning all 119MB of `.text` for BL
instructions targeting the Lua API address range (`0x3190000-0x31A0000`).

### Previous Misidentifications

| Old Name | Offset | Actually Is |
|---|---|---|
| `lua_pcall_v1` | `0x3198664` | `lua_createtable(L, narr, nrec)` — fan-in=273 |
| `lua_pcall_v2` | `0x3195D4C` | `luaD_call(L, func, nresults)` — Dobby hook corrupts it |
| `lua_pcall_v3` | `0x319DDD8` | `luaD_rawrunprotected` — fan-in=32007! Too hot to hook |
| `lua_load_v1`  | `0x31B2DE8` | `lua_load` — **actually correct**, but crashed because the pcall to execute the loaded chunk was wrong |

### Confirmed API Map (20+ functions)

| VA | Function | Fan-in | Evidence |
|---|---|---|---|
| `0x319DDD8` | `luaD_rawrunprotected` | **32,007** | 0x1D0 frame (setjmp), universal protector |
| `0x3194C78` | `lua_gettop` | **18,910** | No prologue, pure stack calc, RET |
| `0x3194C94` | `lua_checkstack` | 6,492 | Stack limit check |
| `0x3196570` | `lua_pushstring` | 5,446 | Called by `luaopen_*` with `x1=str` |
| `0x31964A0` | `lua_pushnil` | 4,564 | 6 insns: set type + advance stack |
| `0x3196738` | `lua_setfield` | 3,948 | Called by `luaL_setfuncs` |
| `0x319A660` | `lua_getfield` | 3,111 | Index resolve + field access |
| `0x319E750` | **`luaD_pcall`** | **3,051** | Calls `luaD_rawrunprotected` at +0x2F8 |
| `0x31964B8` | `lua_pushnumber` | 2,812 | MOVZ w8,#19 (LUA_TNUMFLT) |
| `0x3196814` | `lua_pushcclosure` | 2,564 | Called by `luaL_setfuncs` |
| `0x31964D8` | `lua_pushinteger` | 2,170 | MOVZ w8,#3 (LUA_TNUMINT) |
| `0x3199020` | `lua_settable` | 689 | Called with idx=-3 |
| `0x3198DDC` | `lua_rawseti` | 457 | Index + store pattern |
| `0x3198664` | `lua_createtable` | 273 | Called by all `luaopen_*` |
| `0x319F8F4` | `luaL_setfuncs` | — | 3 `luaopen_*` callers |
| `0x31AFCA4` | `luaV_execute` | — | 8KB+, 74 BL calls — the VM loop |
| `0x31B2DE8` | `lua_load` | — | Correct — calls `luaD_protectedparser` |
| `0x31B7010` | `luaD_protectedparser` | — | Called by `lua_load` at +0x14 |
| `0x3195D4C` | `luaD_call` | — | Lower-level call dispatch |

### Call Chain

```
lua_pcallk (TBD — wrapper around luaD_pcall)
  └→ luaD_pcall (0x319E750) ← HOOK TARGET
      └→ luaD_rawrunprotected (0x319DDD8)
          └→ luaV_execute (0x31AFCA4) — interpreter loop

lua_load (0x31B2DE8) ← CALL TARGET
  └→ luaD_protectedparser (0x31B7010)
      └→ [parser/compiler chain]
```

### New Hook Strategy

1. **Hook `luaD_pcall` (`0x319E750`)** — single bottleneck for ALL protected Lua calls
   - Signature: `int luaD_pcall(L, Pfunc func, void* ud, ptrdiff_t old_top, ptrdiff_t ef)`
   - `lua_State* L` is always in `x0`
   - fan-in=3051 — active during gameplay (not just init)

2. **Call `lua_load` (`0x31B2DE8`)** to compile Lua source
   - This was correct all along! The crash was because the "pcall" to execute the
     loaded chunk was actually `lua_createtable`, not `lua_pcallk`

3. **Use `luaD_pcall` itself to execute** — after `lua_load` pushes the chunk,
   call `luaD_pcall` with `f_call` as the protected function

### Updated `sig_config.h`

Signatures rewritten with correct identifications. Primary scan targets:
- `luaD_pcall` (SUB sp,#0x40 + FP save prologue)
- `lua_load` (same as before — was correctly identified)
- `luaD_rawrunprotected` (0x1D0 frame — for reference only, not hooked)

---

## 7. File Map

```
Scripts/inject/android/
├── build_apk.py               # APK patching pipeline (mode merge/split)
├── debug_android.py            # TCP client for Lua injection
├── run_android.py              # Unified runner (push/inject/lua/forward)
├── debug.keystore              # Debug signing key (auto-generated)
├── native/
│   ├── inject_android.cpp      # Native hook lib — Dobby + TCP server
│   ├── sig_config.h            # ARM64 byte signatures for lua_load/lua_pcall
│   ├── CMakeLists.txt          # NDK build config (FetchContent for Dobby)
│   └── build/
│       └── libinject.so        # Compiled ARM64 shared library (391.7 KB)
├── smali/
│   ├── InjectProvider.smali    # ContentProvider loader (unused — using StubApp instead)
│   └── SigSpoof.smali          # Signature spoof stub (currently non-functional)
└── output/
    ├── patched_base.apk        # Patched base (smali injection)
    ├── patched_arm64.apk       # Patched arm64 split (libinject.so added)
    ├── patched_split_config.en.apk
    ├── patched_split_config.xxhdpi.apk
    ├── patched_split_yysls_it1.apk  # 3.1 GB game assets (resigned)
    └── patched_split_yysls_it2.apk  # 452 MB game assets (resigned)
```

---

## 8. Key Decisions & Notes

1. **StubApp injection over ContentProvider:** apktool 3.x has issues rebuilding decoded resources in the AndroidManifest. We inject `System.loadLibrary("inject")` directly into `StubApp.attachBaseContext()` via smali patching instead of adding a ContentProvider in the manifest.

2. **Split mode over merge mode:** Mode A (merge) produces a smaller APK but misses the 3.5 GB of game assets in the `split_yysls_it*` APKs. Mode B (split) patches base/arm64 individually and resigns all splits with the same key.

3. **`-r` flag (no resource decode):** Using `apktool d -r` to skip resource decoding avoids apktool 3.x rebuild errors with binary XML resources. Trade-off: can't modify resource files, but we only need smali access.

4. **Binary manifest patching:** For merge mode, `_patch_binary_manifest_splits()` directly edits the binary `AndroidManifest.xml` to remove `requiredSplitTypes` / `splitTypes` attributes so Android doesn't reject the merged single APK.

---

## 10. Runtime Probing — API Offset Validation (2026-03-29)

### Method: C-Level Probes via TCP Commands

Added a runtime probe system (`__probe_state`, `__probe_globals`, `__probe_load`)
that runs diagnostic C code directly inside the `luaD_pcall` hook context,
bypassing `lua_load` entirely. This lets us test individual Lua C API functions
in isolation on the live VM.

### Results: Several API Offsets Are WRONG

| Expected Function | VA Offset | Runtime Behavior | Verdict |
|---|---|---|---|
| `lua_gettop` | `0x3194C78` | Returns 2, but stack math inconsistent | ⚠️ Suspect |
| `lua_pushstring` | `0x3196570` | `pushstring("hello")` returns `"hello"` but top jumps +4 | ❌ WRONG |
| `lua_settop` | `0x3194FB8` | `settop(L, 2)` sets top to 7 | ❌ WRONG |
| `lua_type` | `0x3194E30` | Crashes with valid arguments | ❌ WRONG |
| `lua_checkstack` | `0x3194C94` | Doesn't crash, but effect unverified | ⚠️ Unknown |
| `lua_getfield` | `0x319A660` | Process dies after call with `REGISTRYINDEX` | ❌ Crashes |

### Results: Core Hook + Constants Confirmed

| Item | Value | Evidence |
|---|---|---|
| `luaD_pcall` hook | `0x319E750` | Fires continuously, stable | ✅ |
| `lua_load` | `0x31B2DE8` | Calls `luaD_protectedparser` | ✅ |
| `luaD_call` | `0x3195D4C` | Called by `f_call` at `0x319E5F4` | ✅ |
| `LUA_REGISTRYINDEX` | `-1001000` | Decoded from `lua_getfield` MOVZ+MOVK | ✅ |
| Registry `tt_` tag | `0x45` | `LUA_TTABLE \| BIT_ISCOLLECTABLE` — valid | ✅ |
| `G(L)` pointer | `L+0x20` | Valid pointer, readable | ✅ |
| `L->top` | `L+0x18` | Readable, but gettop math may be wrong | ⚠️ |
| `L->ci` | `L+0x28` | Valid pointer | ✅ |

### Key Insight

The call-graph fan-in analysis correctly identified **internal** functions
(`luaD_pcall`, `luaD_call`, `luaD_rawrunprotected`) but **misidentified
many public API functions** (`lua_gettop`, `lua_pushstring`, `lua_settop`,
`lua_type`). The functions at those addresses have similar structure but
different behavior — they may be game-specific wrappers, inlined variants,
or entirely different functions.

### `lua_pcallk` Not Found

Exhaustive search of all 70 callers of `luaD_pcall` across the entire
binary found **no function matching `lua_pcallk`'s expected signature**
(6 params: `L, nargs, nresults, errfunc, ctx, k`). The compiler appears
to have **inlined `lua_pcallk`** into every call site. This means we
cannot replicate the Windows DLL's approach of hooking `lua_pcallk`.

### `lua_load` Behavior Clarified

`lua_load` does NOT abort — it calls `luaD_protectedparser` which calls
`luaD_pcall` (re-entering our hook). The "hang" was because:

1. `lua_load` calls `luaD_pcall` internally (parser runs inside protected call)
2. Our hook fires on the re-entrant call, calls `oLuaD_Pcall` (original), parser runs
3. `lua_load` returns... but the log message `"lua_load returned"` never appears

The likely cause: `lua_load` succeeds but subsequent stack operations using
wrong API functions corrupt the VM state, killing the thread.

### Fast Deploy Tool

Created `Scripts/inject/android/fast_deploy.py` — reduces iteration from
~3min to ~30s by:
1. Incremental `.so` rebuild (~5s)
2. Replace `libinject.so` inside existing `patched_arm64.apk` via `zipfile`
3. Re-sign only the modified APK
4. `adb install-multiple` + launch

### ✅ RESOLVED — Lua Code Execution Working! (Session 2)

Three critical issues were discovered and fixed:

1. **Custom mutex at `L+0x58`**: The game added a mutex to `lua_State`.
   The wrapper at `0x31B2DE8` acquires this lock before calling the parser.
   Since our hook runs on the same thread that already holds the lock,
   calling the wrapper caused **deadlock** (not a crash).

2. **Wrong function identification**: The function at `0x31B2DE8` is
   **NOT standard `lua_load`**. It's a 2-arg game wrapper:
   `int load_wrapper(lua_State* L, int mode)` that reads its Zio from
   `L+0x38`. Our reader/data args were silently ignored.
   
3. **`oLuaD_Pcall` blocks**: Even after successful parsing, calling
   `oLuaD_Pcall` to execute the chunk blocks indefinitely. The hooked
   function at `0x319E750` has TLS-based synchronization that prevents
   re-entrant calls.

**Solution**: Bypass both the wrapper and `luaD_pcall`:
- Call `luaD_protectedparser` (`0x31B7010`) directly with a manually-set-up
  Zio at `L+0x40`
- Execute the compiled chunk via `luaD_call` (`0x3195D4C`) instead of
  `luaD_pcall`

**Working execution pipeline**:
```
TCP command → hook fires → set up Zio at L+0x40
  → luaD_protectedparser(L, zio, 0) → rc=0 ✅ (compilation success)
  → pLuaD_Call(L, chunk_stkid, 0)   → returns ✅ (execution success)
```

**Confirmed working commands**:
```bash
printf "print('HELLO_FROM_LUA')" | nc -w 5 localhost 19840    # ✅ executes
printf "local x=1+1" | nc -w 5 localhost 19840                 # ✅ executes
printf "error('test')" | nc -w 5 localhost 19840               # ✅ executes (error caught by outer pcall)
```

### Remaining Work

1. **Verify game globals**: Confirm `G`, `G.main_player`, etc. are accessible
2. **Test I/O**: `io.open` may be stripped; check if file writes work via 
   game's own file APIs
3. **Error handling**: `luaD_call` is unprotected — errors in injected code
   propagate to the game's error handler. May need to wrap in `pcall`.
4. **Port trainer scripts**: Adapt the Windows DLL's Lua payload for Android

---

## 11. File Map (Updated)

```
Scripts/inject/android/
├── build_apk.py               # APK patching pipeline (mode merge/split)
├── fast_deploy.py             # Quick rebuild+deploy (30s iteration)
├── debug_android.py            # TCP client for Lua injection
├── run_android.py              # Unified runner (push/inject/lua/forward)
├── probe_lua.py               # Binary analysis — find Lua functions
├── decode_regidx.py           # Decode ARM64 instructions for constants
├── debug.keystore              # Debug signing key (auto-generated)
├── native/
│   ├── inject_android.cpp      # Native hook lib — Dobby + TCP + probes
│   ├── sig_config.h            # ARM64 byte signatures
│   ├── CMakeLists.txt          # NDK build config (FetchContent for Dobby)
│   └── build/
│       └── libinject.so        # Compiled ARM64 shared library
├── smali/
│   ├── InjectProvider.smali    # ContentProvider loader (unused)
│   └── SigSpoof.smali          # Signature spoof stub (non-functional)
└── output/
    ├── patched_base.apk        # Patched base (smali injection)
    ├── patched_arm64.apk       # Patched arm64 split (libinject.so)
    └── ...                     # Other signed splits
```

