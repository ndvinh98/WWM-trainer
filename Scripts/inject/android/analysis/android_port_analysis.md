# Android Port: Approach Analysis & Recommendations

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
- The game's Lua 5.4 has **custom modifications** (mutexes, 5-var for-loops, etc.)
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

### 1. ⭐ Hook `lua_pcall` via Signature Scan on libGame.so (Best Option)

This is what the Windows version does. The fact that symbols are stripped doesn't matter — you can **pattern scan the ARM64 bytecode** of `libGame.so` just like you pattern scan the x86_64 `.text` on Windows.

**Steps:**
1. Extract `lua_pcallk` and `lua_load` byte patterns from `libGame.so` (you already identified `lua_pcallk` at `0x31B47F4` and `lua_load` wrapper at `0x31B2DE8`)
2. Create ARM64 signature patterns from the function prologues (first 16-32 bytes)
3. Use Dobby to hook them at runtime just like you hook `luaopen_*`
4. In the hook, use the original trampolines to call `lua_load` + `lua_pcall` — **exactly like Windows**

**You already have the addresses!** From your report:
- `lua_pcallk` candidate: `0x31B47F4`
- `lua_load` wrapper: `0x31B2DE8`

You don't even need signature scanning — just hook them directly via delta:

```c
// In your luaopen hook, after computing g_delta:
void *pcallAddr = (void *)(g_delta + 0x31B47F4);
void *loadAddr  = (void *)(g_delta + 0x31B2DE8);

// Hook pcall, save original as trampoline
DobbyHook(pcallAddr, (void *)hkLuaPcall, (void **)&oLuaPcall);

// For lua_load, just save the function pointer (no hook needed)
oLuaLoad = (tLuaLoad)loadAddr;
```

**The mutex issue:** You noted `lua_load` has a mutex at `L+0x58`. But that's only a problem if you call it from **inside the dispatch hook** where the mutex is already held. If you hook `lua_pcall` instead (like Windows), the mutex won't be held because pcall doesn't acquire it.

### 2. Hook `lua_pcallk` Directly (Your Own "Next Step #2")

Your report already suggests this — test `0x31B47F4` directly. This is the same as option 1 but using `lua_pcallk` which is the actual implementation behind `lua_pcall`. The signature is:

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
        // Use lua_load (0x31B2DE8) + oLuaPcallk (original trampoline)
        ExecuteLua(L, cmd, "cmd");
    }
    return oLuaPcallk(L, nargs, nresults, errfunc, ctx, k);
}
```

### 3. Use `luaL_dostring` / `luaL_loadstring` if Locatable

If you can find `luaL_dostring` or `luaL_loadbufferx` in the binary (via cross-refs from `luaopen_*`), these are even simpler — single function call to compile + execute.

### 4. Re-scan Signatures in WWM-decompiled (Fallback)

`F:\Coding\Where Winds Meet\WWM-decompiled` appears to be **empty** (0 results from fd search). If you have a decompiled `libGame.so` from IDA/Ghidra, you could:
- Extract ARM64 byte patterns for `lua_pcallk` prologue
- Make them version-resilient with wildcards (like the Windows version's `?? ??` pattern)
- This protects against game updates changing the delta

But this is **overkill for now** — the delta approach is sufficient.

---

## Summary: What To Do Next Session

| Priority | Action | Effort |
|----------|--------|--------|
| 🥇 | Hook `lua_pcallk` at `g_delta + 0x31B47F4` via Dobby, use `lua_load` at `g_delta + 0x31B2DE8` as direct call. Mirror Windows `inject.cpp` pattern exactly. | ~1 hour |
| 🥈 | If `lua_load` mutex still deadlocks from pcall hook context, try `luaL_loadbufferx` (find via xrefs from `luaopen_*` BL targets) | ~2 hours |
| 🥉 | Extract ARM64 byte signatures from function prologues for version-resilient scanning | ~3 hours |
| ❌ | **Stop** chasing `luaD_precall` + `luaV_execute` — this path is a dead end for a modified VM | — |

> [!IMPORTANT]
> The fundamental insight: **mirror the Windows architecture exactly**. Hook high-level API → use original trampolines → let the game's own Lua implementation handle all the internal state management.
