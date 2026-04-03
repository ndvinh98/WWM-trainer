# Crash Loop Root Cause Analysis (2026-04-03)

## Timeline Evidence

| Time | Event |
|------|-------|
| `09:24:08.207` | `[luaopen] lua_pcallk hooked ✅` |
| `09:24:08.919` | `[getSoNameByDynamic] get so name: libunisec.so` |
| `09:24:09.642` | `[SignalHandler] working on only one signal 1` → KILL |

**Crash is exactly 1.4s after Dobby hooks `lua_pcallk`. Every time. Reproducible.**

## Root Cause: Dobby Inline Hook Detected by SdkNgDetect

`libunisec.so` (NetEase `SdkNgDetect` anti-cheat) performs **memory integrity checks**:
- Scans `/proc/self/maps` for loaded SO names → only sees `libGame.so`, `libunisec.so`, `libandroidmainruns.so` (NOT `libinject.so` — so it's not name-based)
- Uses `getSoNameByDynamic` to walk the loaded `.so` ELF headers  
- **Checks the `.text` section bytes of `libGame.so`** against a known hash or prologue pattern
- Dobby's inline hook **overwrites the first 4 bytes** of `lua_pcallk` (`FUN_030e55b0`) with a branch instruction → detected as memory tampering
- Game sends report to `h72naxx2gb.appdump.nie.easebar.com` → server confirms tamper → SIGHUP sent

## Why `libinject.so` is NOT detected by name
The anti-cheat only checks SO names it finds via the ELF dynamic section, not via `/proc/maps` text scanning. Since `libinject.so` is loaded via `System.loadLibrary` before `libGame.so` fully initializes, it's not in the check list. The problem is **byte-level modification of `libGame.so` memory**.

## What Won't Work
- Renaming `libinject.so` → won't help, name isn't detected
- Simple Dobby hook of any `libGame.so` function → always detected  
- Hiding the SO from `/proc/maps` → not the detection method

## Solution: Do NOT use Dobby inline hooks on `libGame.so` functions

### Option A: PLT/GOT Hook (Preferred)
Instead of patching the function's code bytes, patch the **GOT entry** that `libGame.so` uses when calling `lua_pcallk` internally. GOT patching modifies a data section (not `.text`) — integrity checks of `.text` won't trigger.

Steps:
1. Find the GOT entry for `lua_pcallk` in `libGame.so` (it's internal, may not have a PLT — but Lua internal calls may use a function pointer table)
2. If `lua_pcallk` is called via a global function pointer stored in a data section, patch that pointer instead

### Option B: luaopen_* trampoline (Cleanest — no libGame.so modification)
Instead of hooking `lua_pcallk`, use the `luaopen_*` interception we already have:
- We already capture `L` from `luaopen_socket_core`
- Instead of hooking pcallk for dispatch, **spawn a thread** that polls `g_cmdQueue` and calls `lua_pcallk` directly (using the function pointer we already computed from `g_delta`)
- **Never call DobbyHook on any `libGame.so` address** — only read/call those addresses

This approach:
- Zero bytes modified in `libGame.so` text section
- Direct function call to `oLuaPcallk` (computed via g_delta, no hook needed)
- Thread waits on a condition variable for commands
- Commands execute via the direct function pointer

### Option C: Hook `luaopen_*` return only (minimal modification)
Dobby already hooks the `luaopen_socket_core` function (in `libGame.so`). Wait — this IS also patching `libGame.so` bytes! But the crash happens 1.4s after `lua_pcallk` hook, not after `luaopen_*` hook. This means either:
- `luaopen_*` hook bytes are NOT checked (perhaps they're in a section the anti-cheat ignores)
- OR `lua_pcallk`'s specific memory region is checksummed

## Recommended Fix: Thread-based dispatch, NO pcallk hook

```cpp
// After capturing L in luaopen hook:
// 1. Compute oLuaPcallk as a direct function pointer (already done via g_delta)
// 2. Spawn dispatch thread  
// 3. NEVER call DobbyHook on lua_pcallk

static void *DispatchThread(void *) {
    while (g_tcpRunning.load()) {
        std::string cmd;
        {
            std::unique_lock<std::mutex> lock(g_mtx);
            g_cmdCv.wait_for(lock, std::chrono::milliseconds(100),
                             [] { return !g_cmdQueue.empty(); });
            if (!g_cmdQueue.empty()) {
                cmd = std::move(g_cmdQueue);
                g_cmdQueue.clear();
            }
        }
        
        if (!cmd.empty() && g_luaState.load() && oLuaLoad && oLuaPcallk) {
            void *L = g_luaState.load();
            ExecuteLua(L, cmd, "dispatch");
        }
    }
    return nullptr;
}
```

**Risk:** Calling Lua from a non-game thread may cause thread-safety issues inside the Lua VM. The game's Lua may not be thread-safe.

## Best Fix: Use lua_lock / the existing game mutex

From previous analysis, `lua_load` acquires the mutex at `L+0x58`. If we call from our own thread, we need to acquire the same mutex first, OR we need to call from within the game's own thread context.

The Windows solution works because it calls from within the game's own pcall → the game thread is already in a clean Lua state. We need to replicate this WITHOUT patching `libGame.so`.

## Alternate Hook Target: `luaopen_socket_core` itself (already hooked, no NEW patch)
We already Dobby-hook `luaopen_socket_core`. The luaopen call happens on the game thread, from within the Lua VM. Instead of hooking pcallk, **execute the command inside the luaopen hook** — we're already on the game thread with a valid L. The game calls this once during startup, but if it's called multiple times...

Actually, better: **hook `luaopen_socket_serial`** or any luaopen that fires repeatedly, and use that as the dispatch point.

Check: does `luaopen_socket_core` fire more than once per session? From logs, each PID shows it firing exactly once. Not suitable for repeated dispatch.

## Conclusion: Thread-based call with proper Lua locking is the path forward.
Need to investigate the Lua state mutex (at `L+0x58`) and acquire it before calling from our thread.
