# Fix Android Inject: dlsym Hooking + Error Pipeline

The current [inject_android.cpp](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/inject_android.cpp) has 5 confirmed bugs that make it appear to work (TCP returns "OK") while silently failing to produce any observable effect. This plan replaces the unreliable pattern-scan approach with deterministic `dlsym`-based hooking and adds a proper error/output feedback pipeline.

## User Review Required

> [!IMPORTANT]
> **Strategy change**: We are abandoning the pattern-scan for `luaD_pcall` (73 false matches) and instead hooking exported `luaopen_socket_core` via `dlsym`. This is guaranteed to find the right function and gives us a valid `lua_State*` in a safe calling context.

> [!WARNING]
> **`luaopen_socket_core` may load early or late** — timing depends on when the game calls `require("socket.core")`. If it never fires, we fall back to `luaopen_memory_leak_checker` or any other exported `luaopen_*`. All 5 are hooked; whichever fires first wins.

---

## Proposed Changes

### Core Injection Logic

#### [MODIFY] [inject_android.cpp](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/inject_android.cpp)

**Bug Fix 1: Missing return in JNI_OnLoad (line 1121)**
```diff
 extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
   // ... existing code ...
   LOGI("Init thread spawned, returning to linker");
+  return JNI_VERSION_1_6;
 }
```

**Bug Fix 2: Replace pattern-scan hooking with dlsym-based hooking**

Remove the `luaD_pcall` pattern scan and Dobby hook. Instead:

1. In [InitThread](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/inject_android.cpp#987-1090), after finding `libGame.so`, use `dlsym` to find all 5 exported `luaopen_*` functions
2. Hook each one with Dobby — they all take `lua_State* L` as first arg
3. On first fire of any hooked `luaopen_*`:
   - Capture `L` into `g_luaState`
   - Disassemble the hooked function's first ~64 instructions to extract BL targets
   - Cross-reference BL targets with the confirmed API address list:
     - `lua_createtable` (called by 4/5 luaopen functions)
     - `luaL_setfuncs` (called by 3/5)
     - `lua_setfield` (called by 2/5)
   - Compute the base delta from these confirmed anchors
   - Resolve `luaD_protectedparser` and `luaD_call` via the delta
   - Mark injection as ready

```cpp
// New: exported symbol names we can dlsym
static const char* LUAOPEN_NAMES[] = {
    "luaopen_socket_core",
    "luaopen_mime_core", 
    "luaopen_socket_serial",
    "luaopen_socket_unix",
    "luaopen_memory_leak_checker",
};

// Hook handler for any luaopen_* function
static int hkLuaOpen_Generic(void* L) {
    if (!g_luaState.load()) {
        g_luaState.store(L);
        LOGI("[hook] Captured lua_State L=%p from luaopen_*", L);
        // Resolve API addresses from the hooked function's BL targets
        ResolveApiFromBLTargets();
        bInjected.store(true);
    }
    // Call original
    return oLuaOpen(L);
}
```

**Bug Fix 3: Wrap injected code in pcall + LOGI output**

Replace [ExecuteLua](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/inject.cpp#211-234) to wrap user code in a Lua-level pcall with C-callback output:

```cpp
static bool ExecuteLua(void* L, const std::string& code, const char* label) {
    // Wrap code so errors are caught and output goes to logcat
    std::string wrapped =
        "local __ok, __err = pcall(function()\n"
        + code + "\n"
        "end)\n"
        "if not __ok then\n"
        "  -- error will be captured by our C-side stack read\n"
        "end\n"
        "return __ok, __err\n";
    
    // Compile via luaD_protectedparser
    // Execute via luaD_call with nresults=2
    // Read __ok and __err from stack
    // Log result via LOGI
}
```

**Bug Fix 4: Execution context — use luaopen hook instead of luaD_pcall hook**

Since we're now hooking `luaopen_*` (which fires only once per module), we need a secondary mechanism to execute queued commands. Two options:

- **Option A**: Keep a minimal `luaD_pcall` hook just for command dispatch (find it via delta from confirmed APIs, not pattern scan)
- **Option B**: Use a timer/poll thread that calls into Lua on the game's main thread via `luaD_call`

**Recommended: Option A** — compute `luaD_pcall` address as `confirmed_lua_createtable_addr - (0x3198664 - 0x319E750)` (relative offset between two known functions). Hook it with Dobby for command dispatch only.

**Bug Fix 5: TCP response with execution result**

After execution completes, send the result back through TCP instead of just "OK":

```cpp
// In TCP handler, after execution:
const char* response = lastExecOk ? "OK" : lastExecError.c_str();
write(client_fd, response, strlen(response));
```

This requires making execution synchronous from TCP's perspective — have the TCP thread wait for the hook to pick up and complete the command, then read the result.

---

### Signature Config

#### [MODIFY] [sig_config.h](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/sig_config.h)

No longer the primary hook target source. Keep signatures for reference/fallback but add a comment that `dlsym` is the preferred method. Optionally extend the `luaD_pcall` signature to 40+ bytes to reduce false matches if used as fallback.

---

## Verification Plan

### On-Device Testing

All testing requires: patched APK installed, game launched, port forwarded (`adb forward tcp:19840 tcp:19840`).

**Build & deploy:**
```bash
cd Scripts/inject/android
python3 fast_deploy.py
```

**Watch logs:**
```bash
adb logcat -s 'WWM_INJECT:*'
```

**Test 1: Hook fires and captures L**
```bash
# After game launches, logcat should show:
# WWM_INJECT: [hook] Captured lua_State L=0x... from luaopen_socket_core
# WWM_INJECT: [hook] API resolution complete
# WWM_INJECT: [init] TCP server started on port 19840. Ready.
```

**Test 2: print() produces logcat output**
```bash
printf "print('HELLO_FROM_LUA')" | nc -w 5 localhost 19840
# Should see in logcat:
# WWM_INJECT: [tcp_cmd] HELLO_FROM_LUA
# TCP should return: "OK"  (or the output string)
```

**Test 3: Error produces visible feedback**
```bash
printf "error('test_error')" | nc -w 5 localhost 19840
# Should see in logcat:
# WWM_INJECT: [tcp_cmd] ERROR: ...test_error...
# TCP should return: "ERR: ...test_error..."
```

**Test 4: nil dereference error**
```bash
printf "local x = nil; x.foo = 1" | nc -w 5 localhost 19840
# Should see error in logcat about indexing nil
```

**Test 5: File creation**
```bash
printf "local f=io.open('/sdcard/wwm_test.txt','w') if f then f:write('OK') f:close() end" | nc -w 5 localhost 19840
adb shell cat /sdcard/wwm_test.txt
# Should print: OK
```

### Manual Verification by User
- Confirm game doesn't crash after hook installation
- Confirm game remains playable during and after Lua injection
- Check logcat for any unexpected errors or warnings
