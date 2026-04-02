# Android Port: Approach Analysis & Recommendations

> **Updated 2026-04-02 22:54** with deep Ghidra verification. See [ghidra_verify_pcallk.txt](file:///f:/Coding/Where%20Winds%20Meet/Scripts/inject/android/analysis/ghidra_verify_pcallk.txt) for raw data.

## Diagnosis: Why Windows Works and Android Doesn't

The Windows version succeeds because of **one critical design decision**: it hooks `lua_pcall` (the high-level C API) and piggybacks on the game's own call to execute code. The flow is:

```
Game calls lua_pcall(L, nargs, nresults, errfunc) 
  → your hook intercepts 
  → calls lua_load() + lua_pcall() using the ORIGINAL trampolines
  → game's original pcall proceeds normally
```

This works because:
1. **`lua_load` and `lua_pcall` are the PUBLIC C API** — they handle all state setup, stack management, error recovery, mutexes, etc.
2. **You never touch internals** like `luaD_precall`, `luaV_execute`, or Zio structs
3. **The L pointer is in a valid, safe state** when pcall is called by the game

The Android version fails because you're trying to **manually replicate what `lua_pcall` does internally** — calling `luaD_protectedparser` → `luaD_precall` → `luaV_execute`. This is fragile because:
- The game's Lua 5.4 has **custom modifications** (mutexes, 5-var for-loops, shuffled opcodes +14 offset, alt-encoding pairs, custom NEWTABLE0 opcode, shifted TMS tags — see [luac/README.md](file:///f:/Coding/Where%20Winds%20Meet/luac/README.md))
- Internal functions expect **precise VM state** that's hard to set up from outside
- The dispatch hook fires in an **unknown/unsafe context** (possibly mid-GC, mid-instruction)

> [!CAUTION]
> You've spent days reverse-engineering internal VM functions that the Windows version never needed. The approach is fundamentally wrong — not the execution details.

---

## The Core Problem on Android

On Windows you found `lua_pcall` via **pattern scanning** on the unpacked `.text` section. On Android:
- **All standard Lua C API symbols are stripped** from `libGame.so`
- Only `luaopen_*` symbols are exported
- You can't `dlsym("lua_pcall")` or `dlsym("lua_load")`

So you went down the rabbit hole of calling internal functions directly. **Don't.**

---

## Recommended Approaches (Priority Order)

### 1. ⭐ Hook `lua_pcallk` via Dobby (Best Option)

> [!IMPORTANT]
> **Deep Ghidra verification (2026-04-02 22:50)**: The function previously identified as `lua_pcallk` (`FUN_030fc1b0` at `0x31B47E4`) is actually **`luaD_callnoyield`** — an unprotected call with only 8 callers that calls `luaD_precall` + `luaV_execute` directly.
>
> The **REAL `lua_pcallk`** is **`FUN_030e55b0`** at ELF VA **`0x0319DBE4`** — confirmed by 151 callers, 484 bytes, and 3 calls to `luaD_rawrunprotected`.

**Corrected addresses** (deep Ghidra verification):

| Function | ~~All wrong VAs~~ | **Correct VA** | Ghidra Name | Evidence |
|---|---|---|---|---|
| `lua_pcallk` | ~~`0x31B47F4`~~, ~~`0x31B47E4`~~ | **`0x0319DBE4`** | `FUN_030e55b0` | **151 callers**, 484 bytes, calls `luaD_rawrunprotected` ×3, has `__stack_chk_fail` |
| `lua_load` | ~~`0x31B2DE8`~~ | **`0x31B2DD8`** | `FUN_030fa7a4` | 38 callers, 292 bytes, calls `luaD_protectedparser` |
| `lua_pcall` (alt) | — | **`0x0319E740`** | `FUN_030e610c` | **215 callers**, 140 bytes, calls through to pcallk. Simpler signature |

> [!WARNING]
> **Why the previous VA was wrong:** `FUN_030fc1b0` (`0x31B47E4`) calls `luaD_precall` + `luaV_execute` **directly** (unprotected). The real `lua_pcallk` calls `luaD_rawrunprotected` which internally invokes `f_call` → `luaD_precall` + `luaV_execute`. This "protected" wrapper is what makes pcall safe — it catches errors instead of crashing.

**Corrected hooking code:**

```c
// REAL lua_pcallk — deep Ghidra verified
static constexpr uintptr_t VA_LUA_PCALLK = 0x0319DBE4;  // FUN_030e55b0, 151 callers, 484 bytes
static constexpr uintptr_t VA_LUA_LOAD   = 0x031B2DD8;  // FUN_030fa7a4, 38 callers, 292 bytes

// ALTERNATIVE: lua_pcall wrapper (even more callers, simpler args)
// static constexpr uintptr_t VA_LUA_PCALL = 0x0319E740;  // FUN_030e610c, 215 callers

// In your luaopen hook, after computing g_delta:
void *pcallAddr = (void *)(g_delta + VA_LUA_PCALLK);
void *loadAddr  = (void *)(g_delta + VA_LUA_LOAD);

// Hook pcall, save original as trampoline
DobbyHook(pcallAddr, (void *)hkLuaPcallk, (void **)&oLuaPcallk);

// For lua_load, just save the function pointer (no hook needed)
oLuaLoad = (tLuaLoad)loadAddr;
```

**The mutex issue:** You noted `lua_load` has a mutex at `L+0x58`. But that's only a problem if you call it from **inside the dispatch hook** where the mutex is already held. If you hook `lua_pcallk` instead (like Windows), the mutex won't be held because pcall doesn't acquire it.

### Misidentified Functions (Corrected 2026-04-02 22:50)

| ELF VA | Previously claimed | **Actual identity** | Evidence |
|---|---|---|---|
| `0x31B47E4` | `lua_pcallk` | **`luaD_callnoyield`** | Only 8 callers, 140 bytes. Calls `luaD_precall` + `luaV_execute` directly (UNPROTECTED). No `luaD_rawrunprotected`. |
| `0x31B47F4` | `lua_pcallk` (original) | Mid-function (+0x10 into `luaD_callnoyield`) | `ldr w8,[x0, #0xb0]` instruction, not a function start |
| `0x319E750` | `luaD_pcall` | Unknown dispatch utility | 136 bytes, fires 5K-160K/s, mid-function (+0x10 into `FUN_030e610c`) |

### 2. Alternative: Hook `lua_pcall` wrapper at `0x0319E740`

`FUN_030e610c` has **215 callers** (more than `lua_pcallk`'s 151) and a simpler signature. It calls through `FUN_030e58b4` → `FUN_030e55b0` (the real `lua_pcallk`). This may be:
- `lua_pcall(L, nargs, nresults, errfunc)` (4-arg simplified wrapper)
- Or a game-specific protected call wrapper

**Pros:** More callers = fires more often = lower latency for command dispatch.
**Cons:** Unknown exact signature — need to verify arg count.

### 3. ~~Use `luaL_dostring` / `luaL_loadstring` if Locatable~~ (Low Priority)

~~If you can find `luaL_dostring` or `luaL_loadbufferx` in the binary (via cross-refs from `luaopen_*`), these are even simpler — single function call to compile + execute.~~

**Ghidra finding:** Lua error strings are **obfuscated** — only 9 lua-related strings found in the entire 131MB binary (all `luaopen_*` symbol names). Standard Lua error messages like `"attempt to"`, `"stack overflow"`, etc. are absent. This makes string-based xref identification of `luaL_*` functions impractical. However, the luaopen_* BL call-graph tracing found 46 unique targets, and `FUN_030ffecc` (2016 bytes, 19 BL calls) is a strong candidate for `luaL_loadbufferx` — it's called by both `luaopen_mime_core` and `luaopen_socket_core`.

### 4. ~~Re-scan Signatures in WWM-decompiled (Fallback)~~ ✅ Done via Ghidra

**Done.** Ghidra headless analysis completed 2026-04-02:
- Project: `F:\Coding\Where Winds Meet\ghidra\WWM_libGame`
- 192,553 functions identified
- ARM64 function prologues extracted for all hook targets
- Reusable for future queries via `run_ghidra_scan.py`

**Ghidra-verified function prologue signatures:**

| Function | Correct VA | Prologue (first 32 bytes) | Size | Callers |
|---|---|---|---|---|
| `lua_pcallk` | **`0x0319DBE4`** | `FF 43 05 D1 FD 7B 10 A9 FC 8B 00 F9 F8 5F 12 A9 F6 57 13 A9 F4 4F 14 A9 FD 03 04 91 58 D0 3B D5` | 484 | 151 |
| `lua_load` | `0x031B2DD8` | `FD 7B BD A9 F5 0B 00 F9 F4 4F 02 A9 FD 03 00 91 08 2C 40 F9 F3 03 00 AA E2 03 01 2A 28 03 00 B5` | 292 | 38 |
| `lua_pcall` (alt) | `0x0319E740` | `FF 03 01 D1 E8 0B 00 FD FD FB 01 A9 F5 17 00 F9 F4 4F 03 A9 FD 63 00 91 55 D0 3B D5 E2 13 00 91` | 140 | 215 |
| `luaD_rawrunprotected` | `0x0319DDC8` | `FD 7B BC A9 FC 0B 00 F9 F6 57 02 A9 F4 4F 03 A9` | 288 | 30800 |
| `luaV_execute` | `0x031DA9E0` | `E9 23 B9 6D FD 7B 01 A9 FC 6F 02 A9 FA 67 03 A9` | 28524 | 8 |

---

## Summary: What To Do Next

| Priority | Action | Effort |
|----------|--------|--------|
| 🥇 | **Hook `lua_pcallk`** at `g_delta + 0x0319DBE4` via Dobby, use `lua_load` at `g_delta + 0x031B2DD8` as direct call. Mirror Windows `inject.cpp` pattern exactly. **Remove dispatch hook + luaD_protectedparser pipeline entirely.** | ~2 hours |
| 🥈 | If pcallk fires too infrequently, try the `lua_pcall` wrapper at `0x0319E740` (215 callers, fires more often) | ~30 min |
| 🥉 | If `lua_load` mutex still deadlocks from pcallk hook context, try `FUN_030ffecc` (2016 bytes, candidate `luaL_loadbufferx`) | ~2 hours |
| ❌ | ~~**Stop** chasing `luaD_precall` + `luaV_execute`~~ **Already stopped. Remove dead code.** | — |

> [!IMPORTANT]
> The fundamental insight: **mirror the Windows architecture exactly**. Hook high-level API → use original trampolines → let the game's own Lua implementation handle all the internal state management.

---

## Detailed Implementation Plan

### Phase 1: Clean Rewrite of inject_android.cpp (~2 hours)

**Goal:** Replace the current `luaD_protectedparser` → `luaD_precall` → `luaV_execute` pipeline with the Windows-equivalent `lua_load` + `lua_pcallk` pattern.

#### Step 1.1: Update VA Constants

```c
// REMOVE all internal API VAs:
// - VA_LUAD_RAWRUNPROTECTED, VA_LUAD_PRECALL, VA_LUAV_EXECUTE, VA_LUAD_PROTPARSER
// - VA_DISPATCH_HOOK (the 136-byte utility — was luaD_callnoyield, not pcallk)

// ADD: Real lua_pcallk (deep Ghidra verified)
static constexpr uintptr_t VA_LUA_PCALLK = 0x0319DBE4;  // FUN_030e55b0, 151 callers
static constexpr uintptr_t VA_LUA_LOAD   = 0x031B2DD8;  // FUN_030fa7a4, 38 callers
```

#### Step 1.2: New Function Types

```c
// lua_load: int (L, reader, data, chunkname, mode)  — same as Windows
typedef int (*tLuaLoad)(void *L, void *reader, void *data, 
                         const char *chunkname, const char *mode);

// lua_pcallk: int (L, nargs, nresults, errfunc, ctx, k) — same as Windows
typedef int (*tLuaPcallk)(void *L, int nargs, int nresults, 
                           int errfunc, void *ctx, void *k);

static tLuaLoad oLuaLoad = nullptr;
static tLuaPcallk oLuaPcallk = nullptr;
```

#### Step 1.3: New ExecuteLua (Mirror Windows)

```c
static bool ExecuteLua(void *L, const std::string &code, const char *label) {
    ReaderData data = {code.c_str(), code.length()};
    
    int loadRc = oLuaLoad(L, (void *)MyLuaReader, &data, "@cmd", "t");
    if (loadRc != 0) {
        LOGE("[%s] lua_load FAILED: rc=%d", label, loadRc);
        return false;
    }
    
    int pcallRc = oLuaPcallk(L, 0, 0, 0, nullptr, nullptr);
    if (pcallRc != 0) {
        LOGE("[%s] lua_pcallk FAILED: rc=%d", label, pcallRc);
        return false;
    }
    
    LOGI("[%s] executed successfully", label);
    return true;
}
```

#### Step 1.4: New Hook (Mirror Windows hkLua_Pcall)

```c
static int hkLuaPcallk(void *L, int nargs, int nresults, 
                        int errfunc, void *ctx, void *k) {
    // Dispatch queued command (same pattern as Windows)
    std::string cmdToRun;
    {
        std::lock_guard<std::mutex> lock(g_mtx);
        if (!g_cmdQueue.empty()) {
            cmdToRun = std::move(g_cmdQueue);
            g_cmdQueue.clear();
        }
    }
    if (!cmdToRun.empty()) {
        ExecuteLua(L, cmdToRun, "cmd");
    }
    
    return oLuaPcallk(L, nargs, nresults, errfunc, ctx, k);
}
```

#### Step 1.5: Hook Installation (in luaopen_* handler)

```c
// After computing g_delta from luaopen_* dlsym:
void *pcallkAddr = (void *)(g_delta + VA_LUA_PCALLK);
void *loadAddr   = (void *)(g_delta + VA_LUA_LOAD);

// Save lua_load as direct function pointer (no hook needed)
oLuaLoad = (tLuaLoad)loadAddr;

// Hook lua_pcallk
int ret = DobbyHook(pcallkAddr, (void *)hkLuaPcallk, (void **)&oLuaPcallk);
if (ret == 0) {
    LOGI("[luaopen] lua_pcallk hooked at %p ✅", pcallkAddr);
    g_ready.store(true);
} else {
    LOGE("[luaopen] lua_pcallk hook FAILED: %d", ret);
}
```

#### Step 1.6: Remove Dead Code

Remove:
- `VA_DISPATCH_HOOK`, `VA_LUAD_RAWRUNPROTECTED`, `VA_LUAD_PRECALL`, `VA_LUAV_EXECUTE`, `VA_LUAD_PROTPARSER`
- `tLuaD_RawRunProtected`, `tLuaV_Execute`, `tLuaD_Precall`, `tDispatchHookOrig`
- `hkDispatch()` and dispatch hook installation
- `CustomCallS`, `custom_f_call()`
- Zio struct construction and `L+0x38` manipulation
- `LuaGetTop()` and manual stack pointer manipulation
- All `pProtParser`, `pLuaD_Precall`, `pLuaV_Execute`, `pRawRunProtected` globals

### Phase 2: Test & Validate (~30 min)

1. Build with NDK, deploy via `fast_deploy.py`
2. Watch logcat: `adb logcat -s 'WWM_INJECT:*'`
3. Send test: `printf "print('HELLO FROM PCALLK')" | nc -w 15 localhost 19840`
4. Verify response is `OK` (not `TIMEOUT`)
5. If works: send `loadfile` command for `bootstrap.lua`

### Phase 3: Extract Resilient Signatures (~1 hour)

If Phase 1 works, use Ghidra project to extract function prologue bytes at the corrected VAs for signature-scan fallback (protects against game updates changing the delta).
