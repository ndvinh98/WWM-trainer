# Android Port: Approach Analysis & Recommendations

> **Updated 2026-04-02** with Ghidra headless scan evidence. See [ghidra_lua_scan_results.txt](file:///f:/Coding/Where%20Winds%20Meet/Scripts/inject/android/analysis/ghidra_lua_scan_results.txt) for raw data.

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

### 1. ⭐ Hook `lua_pcallk` via Dobby at Corrected VA (Best Option)

> [!IMPORTANT]
> **Ghidra evidence (2026-04-02)**: The prior VAs from Python BL-tracing all land **0x10 bytes past** the actual function entry points. Ghidra (192,553 functions analyzed) consistently identifies function boundaries 0x10 bytes earlier. All VAs below are **corrected**.

**Corrected addresses** (Ghidra-verified function starts):

| Function | ~~Old VA~~ | Corrected VA | Ghidra Name | Evidence |
|---|---|---|---|---|
| `lua_pcallk` | ~~`0x31B47F4`~~ | **`0x31B47E4`** | `FUN_030fc1b0` | Inside function confirmed, +0x10 offset |
| `lua_load` | ~~`0x31B2DE8`~~ | **`0x31B2DD8`** | `FUN_030fa7a4` | Inside function confirmed, +0x10 offset |

**Steps:**
1. ~~Extract `lua_pcallk` and `lua_load` byte patterns from `libGame.so` (you already identified `lua_pcallk` at `0x31B47F4` and `lua_load` wrapper at `0x31B2DE8`)~~ **Use corrected VAs from Ghidra analysis**
2. Create ARM64 signature patterns from the function prologues (first 16-32 bytes)
3. Use Dobby to hook them at runtime just like you hook `luaopen_*`
4. In the hook, use the original trampolines to call `lua_load` + `lua_pcall` — **exactly like Windows**

**Corrected hooking code:**

```c
// CORRECTED VAs from Ghidra analysis (subtract 0x10 from prior VAs)
static constexpr uintptr_t VA_LUA_PCALLK = 0x31B47E4;  // was 0x31B47F4
static constexpr uintptr_t VA_LUA_LOAD   = 0x31B2DD8;  // was 0x31B2DE8

// In your luaopen hook, after computing g_delta:
void *pcallAddr = (void *)(g_delta + VA_LUA_PCALLK);
void *loadAddr  = (void *)(g_delta + VA_LUA_LOAD);

// Hook pcall, save original as trampoline
DobbyHook(pcallAddr, (void *)hkLuaPcall, (void **)&oLuaPcall);

// For lua_load, just save the function pointer (no hook needed)
oLuaLoad = (tLuaLoad)loadAddr;
```

**The mutex issue:** You noted `lua_load` has a mutex at `L+0x58`. But that's only a problem if you call it from **inside the dispatch hook** where the mutex is already held. If you hook `lua_pcallk` instead (like Windows), the mutex won't be held because pcall doesn't acquire it.

### 2. Hook `lua_pcallk` Directly (Your Own "Next Step #2")

Your report already suggests this — test ~~`0x31B47F4`~~ **`0x31B47E4`** directly. This is the same as option 1 but using `lua_pcallk` which is the actual implementation behind `lua_pcall`. The signature is:

```c
int lua_pcallk(lua_State *L, int nargs, int nresults, int errfunc, lua_KContext ctx, lua_KFunction k)
```

Hook this, and in your hook do:
```c
int hkLuaPcallk(void *L, int nargs, int nresults, int errfunc, void *ctx, void *k) {
    // Check for queued commands (same pattern as Windows)
    std::string cmd;
    {
        std::lock_guard<std::mutex> lock(g_mtx);
        if (!g_cmdQueue.empty()) {
            cmd = std::move(g_cmdQueue);
            g_cmdQueue.clear();
        }
    }
    if (!cmd.empty()) {
        // Use lua_load (0x31B2DD8) + oLuaPcallk (original trampoline)
        ExecuteLua(L, cmd, "cmd");
    }
    return oLuaPcallk(L, nargs, nresults, errfunc, ctx, k);
}
```

### 3. ~~Use `luaL_dostring` / `luaL_loadstring` if Locatable~~ (Low Priority)

~~If you can find `luaL_dostring` or `luaL_loadbufferx` in the binary (via cross-refs from `luaopen_*`), these are even simpler — single function call to compile + execute.~~

**Ghidra finding:** Lua error strings are **obfuscated** — only 9 lua-related strings found in the entire 131MB binary (all `luaopen_*` symbol names). Standard Lua error messages like `"attempt to"`, `"stack overflow"`, etc. are absent. This makes string-based xref identification of `luaL_*` functions impractical. However, the luaopen_* BL call-graph tracing found 46 unique targets, and `FUN_030ffecc` (2016 bytes, 19 BL calls) is a strong candidate for `luaL_loadbufferx` — it's called by both `luaopen_mime_core` and `luaopen_socket_core`.

### 4. ~~Re-scan Signatures in WWM-decompiled (Fallback)~~ ✅ Done via Ghidra

~~`F:\Coding\Where Winds Meet\WWM-decompiled` appears to be **empty** (0 results from fd search). If you have a decompiled `libGame.so` from IDA/Ghidra, you could:~~

**Done.** Ghidra headless analysis completed 2026-04-02:
- Project: `F:\Coding\Where Winds Meet\ghidra\WWM_libGame`
- 192,553 functions identified
- ARM64 function prologues extracted for all hook targets
- Reusable for future queries via `run_ghidra_scan.py`

**Ghidra-verified function prologue signatures for version-resilient scanning:**

| Function | Corrected VA | Prologue (first 16 bytes at function start) |
|---|---|---|
| `lua_pcallk` | `0x31B47E4` | `FUN_030fc1b0` — query Ghidra |
| `lua_load` | `0x31B2DD8` | `08 2C 40 F9 F3 03 00 AA E2 03 01 2A 28 03 00 B5` (at +0x10) |
| `luaD_rawrunprotected` | `0x319DDC8` | `FD 7B BC A9 FC 0B 00 F9 F6 57 02 A9 F4 4F 03 A9` (288 bytes, 30800 xrefs) |
| `luaV_execute` | `0x31DA9E0` | `E9 23 B9 6D FD 7B 01 A9 FC 6F 02 A9 FA 67 03 A9` (28524 bytes = 27.9KB) |

---

## Summary: What To Do Next Session

| Priority | Action | Effort |
|----------|--------|--------|
| 🥇 | **Hook `lua_pcallk`** at `g_delta + 0x31B47E4` (~~0x31B47F4~~) via Dobby, use `lua_load` at `g_delta + 0x31B2DD8` (~~0x31B2DE8~~) as direct call. Mirror Windows `inject.cpp` pattern exactly. **Remove dispatch hook + luaD_protectedparser pipeline entirely.** | ~2 hours |
| 🥈 | If `lua_load` mutex still deadlocks from pcallk hook context, try `FUN_030ffecc` (2016 bytes, candidate `luaL_loadbufferx`) | ~2 hours |
| 🥉 | Extract ARM64 byte signatures from **Ghidra function entry** prologues for version-resilient scanning | ~1 hour |
| ❌ | ~~**Stop** chasing `luaD_precall` + `luaV_execute` — this path is a dead end for a modified VM~~ **Already stopped. Remove dead code.** | — |

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
// - VA_DISPATCH_HOOK (the 136-byte utility)

// ADD corrected high-level API VAs:
static constexpr uintptr_t VA_LUA_PCALLK   = 0x31B47E4;  // Ghidra: FUN_030fc1b0
static constexpr uintptr_t VA_LUA_LOAD     = 0x31B2DD8;  // Ghidra: FUN_030fa7a4
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
        // Pop error message: load no-op chunk with nargs=1
        ReaderData noop = {"do end", 6};
        if (oLuaLoad(L, (void *)MyLuaReader, &noop, "=_pop", "t") == 0)
            oLuaPcallk(L, 1, 0, 0, nullptr, nullptr);
        return false;
    }
    
    int pcallRc = oLuaPcallk(L, 0, 0, 0, nullptr, nullptr);
    if (pcallRc != 0) {
        LOGE("[%s] lua_pcallk FAILED: rc=%d", label, pcallRc);
        // Pop error
        ReaderData noop = {"do end", 6};
        if (oLuaLoad(L, (void *)MyLuaReader, &noop, "=_pop", "t") == 0)
            oLuaPcallk(L, 1, 0, 0, nullptr, nullptr);
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
