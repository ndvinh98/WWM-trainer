// inject_android.cpp — ARM64 Lua hook library for Android (v2)
//
// Strategy: dlsym-based hooking of exported luaopen_* symbols
// No pattern scanning needed — all API addresses computed via delta
// from the known VA of the hooked exported function.
//
// Execution pipeline:
//   luaopen_* hook → capture lua_State* L → compute API delta
//   luaD_pcall hook → dispatch queued TCP commands
//   ExecuteLua → pcall-wrapped compilation + execution via luaD_protectedparser + luaD_call
//   Output → logcat LOGI (print() goes to /dev/null on Android)

#include <android/log.h>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <jni.h>
#include <link.h>
#include <mutex>
#include <netdb.h>
#include <netinet/in.h>
#include <pthread.h>
#include <string>
#include <sys/mman.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>
#include <condition_variable>

#include "dobby.h"

#define TAG "WWM_INJECT"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// ===========================================================================
// Anti-tamper bypass — JNI exception auto-clear
//
// Root cause: FirebaseInitProvider throws ResourceNotFoundException during
// StubApp.onCreate() → pending Java exception → libunisec.so calls JNI
// GetFieldID → ART's AssertNoPendingException fires → abort().
//
// Fix: patch the JNIEnv function table so GetFieldID (and FindClass)
// auto-clear any pending exception before proceeding.
// ===========================================================================

static JavaVM *g_javaVM = nullptr;

static jfieldID (*oGetFieldID)(JNIEnv *, jclass, const char *,
                               const char *) = nullptr;
static jfieldID (*oGetStaticFieldID)(JNIEnv *, jclass, const char *,
                                     const char *) = nullptr;
static jclass (*oFindClass)(JNIEnv *, const char *) = nullptr;

static jfieldID hkGetFieldID(JNIEnv *env, jclass cls, const char *name,
                             const char *sig) {
  if (env->ExceptionCheck()) {
    LOGI("[bypass] cleared pending exception before GetFieldID(%s)", name);
    env->ExceptionClear();
  }
  return oGetFieldID(env, cls, name, sig);
}

static jfieldID hkGetStaticFieldID(JNIEnv *env, jclass cls, const char *name,
                                   const char *sig) {
  if (env->ExceptionCheck()) {
    LOGI("[bypass] cleared pending exception before GetStaticFieldID(%s)",
         name);
    env->ExceptionClear();
  }
  return oGetStaticFieldID(env, cls, name, sig);
}

static jclass hkFindClass(JNIEnv *env, const char *name) {
  if (env->ExceptionCheck()) {
    LOGI("[bypass] cleared pending exception before FindClass(%s)", name);
    env->ExceptionClear();
  }
  return oFindClass(env, name);
}

static bool MakeWritable(void *addr, size_t len) {
  uintptr_t page = (uintptr_t)addr & ~(uintptr_t)(4096 - 1);
  size_t span = ((uintptr_t)addr + len) - page;
  span = (span + 4095) & ~(size_t)(4095);
  if (mprotect((void *)page, span, PROT_READ | PROT_WRITE) != 0) {
    LOGE("[bypass] mprotect failed: %s (addr=%p len=%zu)", strerror(errno),
         addr, len);
    return false;
  }
  return true;
}

static void InstallJniExceptionGuard(JNIEnv *env) {
  auto **table = reinterpret_cast<void ***>(env);
  auto *funcs = *table;

  oFindClass = reinterpret_cast<jclass (*)(JNIEnv *, const char *)>(funcs[6]);
  oGetFieldID = reinterpret_cast<jfieldID (*)(JNIEnv *, jclass, const char *,
                                              const char *)>(funcs[94]);
  oGetStaticFieldID = reinterpret_cast<jfieldID (*)(
      JNIEnv *, jclass, const char *, const char *)>(funcs[144]);

  void *start = &funcs[0];
  size_t tableSize = 256 * sizeof(void *);
  if (!MakeWritable(start, tableSize)) {
    LOGE("[bypass] cannot make JNI table writable — guard NOT installed");
    return;
  }

  funcs[6] = reinterpret_cast<void *>(hkFindClass);
  funcs[94] = reinterpret_cast<void *>(hkGetFieldID);
  funcs[144] = reinterpret_cast<void *>(hkGetStaticFieldID);

  LOGI("[bypass] JNI exception guard installed "
       "(FindClass/GetFieldID/GetStaticFieldID)");
}

// --- abort() diagnostic hook ---
typedef void (*tAbort)(void);
static tAbort oAbort = nullptr;

static void hkAbort() {
  void *caller = __builtin_return_address(0);
  void *caller2 = __builtin_return_address(1);
  LOGE("[bypass] abort() called from %p (caller2=%p)", caller, caller2);

  char line[512];
  FILE *fp = fopen("/proc/self/maps", "r");
  if (fp) {
    while (fgets(line, sizeof(line), fp)) {
      uintptr_t start, end;
      if (sscanf(line, "%lx-%lx", &start, &end) == 2) {
        if ((uintptr_t)caller >= start && (uintptr_t)caller < end)
          LOGE("[bypass] abort caller is in: %s", line);
        if ((uintptr_t)caller2 >= start && (uintptr_t)caller2 < end)
          LOGE("[bypass] abort caller2 is in: %s", line);
      }
    }
    fclose(fp);
  }
  oAbort();
  __builtin_unreachable();
}

static void InstallBypassHooks() {
  void *abortAddr = DobbySymbolResolver(nullptr, "abort");
  if (abortAddr) {
    int ret = DobbyHook(abortAddr, (void *)hkAbort, (void **)&oAbort);
    if (ret == 0)
      LOGI("[bypass] abort() hooked for diagnostics");
    else
      LOGE("[bypass] abort() hook FAILED: %d", ret);
  }
}

// ===========================================================================
// Known VA offsets — from luaopen_* BL disassembly (ground truth)
//
// These are the virtual addresses in the libGame.so binary. All confirmed
// by tracing BL targets from exported luaopen_* functions.
// ===========================================================================

// Exported symbols (findable via dlsym)
static constexpr uintptr_t VA_LUAOPEN_SOCKET_CORE = 0x323D354;
static constexpr uintptr_t VA_LUAOPEN_MIME_CORE = 0x323D5D0;
static constexpr uintptr_t VA_LUAOPEN_SOCKET_SERIAL = 0x3240E64;
static constexpr uintptr_t VA_LUAOPEN_SOCKET_UNIX = 0x3243044;
static constexpr uintptr_t VA_LUAOPEN_MEMLEAK = 0x324AB0C;

// Internal API (resolved via delta from exported symbols)
static constexpr uintptr_t VA_LUA_CREATETABLE = 0x3198664;
static constexpr uintptr_t VA_LUAL_SETFUNCS = 0x319F8F4;
static constexpr uintptr_t VA_LUA_SETFIELD = 0x3196738;
static constexpr uintptr_t VA_DISPATCH_HOOK = 0x319E750;  // 136-byte utility, used for dispatch timing only
static constexpr uintptr_t VA_LUAD_RAWRUNPROTECTED = 0x319DDD8;
// REAL luaD_precall: void*(L) — returns ptr passed as arg2 to execute
static constexpr uintptr_t VA_LUAD_PRECALL = 0x31B3F0C;
// REAL luaV_execute: void(L, ci_ptr) — 27KB VM loop entry (prologue at 0x31DA9F4, loop at 0x31DAA14)
static constexpr uintptr_t VA_LUAV_EXECUTE = 0x31DA9F4;
static constexpr uintptr_t VA_LUAD_PROTPARSER = 0x31B7010;
static constexpr uintptr_t VA_LUA_LOAD_WRAPPER = 0x31B2DE8;

// ===========================================================================
// Lua function types
// ===========================================================================

// luaD_rawrunprotected: int (L, Pfunc func, void *ud)
// Wraps a call in setjmp for C-level error protection.
typedef int (*tLuaD_RawRunProtected)(void *L, void (*func)(void *L, void *ud), void *ud);
// REAL luaV_execute at 0x31DA9F4 — entry to 27KB VM loop
typedef void (*tLuaV_Execute)(void *L, void *ci);
// REAL luaD_precall at 0x31B3F0C — returns ptr (CallInfo*) for execute
// Signature matches Lua 5.4: CallInfo* luaD_precall(lua_State *L, StkId func, int nresults)
typedef void* (*tLuaD_Precall)(void *L, void *func, int nresults);

// The dispatch hook original — NOT a Lua API function, just used for timing
typedef int (*tDispatchHookOrig)(void *L, int a1, int a2);

static tDispatchHookOrig oDispatchHook = nullptr;
static tLuaD_RawRunProtected pRawRunProtected = nullptr;
static tLuaD_ProtParser pProtParser = nullptr;
static tLuaD_Precall pLuaD_Precall = nullptr;
static tLuaV_Execute pLuaV_Execute = nullptr;



// Base delta: runtime_addr - compile_time_VA
static uintptr_t g_delta = 0;

// Lua state captured from luaopen_* hook
static std::atomic<void *> g_luaState{nullptr};
static std::atomic<bool> g_ready{false};
static std::atomic<int> g_pcallCount{0};

// Command queue
static std::string g_cmdQueue;
static std::mutex g_mtx;

// Execution result (for TCP response)
static std::string g_lastResult;
static std::mutex g_resultMtx;
static std::condition_variable g_resultCv;
static std::atomic<bool> g_resultReady{false};

// ===========================================================================
// Lua reader callback (same as Windows version)
// ===========================================================================

struct ReaderData {
  const char *s;
  size_t size;
};

static const char *MyLuaReader(void * /*L*/, void *ud, size_t *sz) {
  ReaderData *d = (ReaderData *)ud;
  if (d->size == 0) {
    *sz = 0;
    return nullptr;
  }
  *sz = d->size;
  d->size = 0;
  return d->s;
}

// ===========================================================================
// Read lua_State fields (offsets from runtime probing)
// ===========================================================================

static inline void *LuaGetTop(void *L) {
  return *(void **)((char *)L + 0x18);
}

// ===========================================================================
// Execute Lua code via luaD_protectedparser + luaD_call
//
// We bypass lua_load() because it acquires a mutex at L+0x58 which is
// already held inside hkLuaD_Pcall context → deadlock.
// Instead we call luaD_protectedparser directly with a properly
// constructed ZIO struct, mimicking what lua_load does internally.
//
// From lua_load disassembly:
//   LDR x1, [L, #0x38]   ← reads existing Zio pointer from L+0x38
//   MOV x0, L
//   BL luaD_protectedparser(L, zio_ptr, mode_flag)
//
// So we must:
//   1. Build a Zio struct on the stack
//   2. Store its address at L+0x38 (luaD_protectedparser reads it internally)
//   3. Call pProtParser(L, &zio, 0)  where 0 = text mode
//   4. Restore L+0x38 after
//
// All user code is wrapped in pcall() at the Lua level so errors are
// ===========================================================================
// Safe Execution Wrapper (lua_pcall equivalent)
// ===========================================================================

struct CustomCallS {
  void *func_stkid;
  int nresults;
};

static void custom_f_call(void *L, void *ud) {
  CustomCallS *c = (CustomCallS *)ud;
  LOGI("[exec] custom_f_call: L=%p func_stkid=%p", L, c->func_stkid);
  // Not used in the new approach — kept for reference
}

static bool ExecuteLua(void *L, const std::string &code, const char *label) {
  if (!pProtParser || !pLuaD_Precall || !pLuaV_Execute) {
    LOGE("[%s] APIs not resolved! protparser=%p precall=%p execute=%p", label,
         (void *)pProtParser, (void *)pLuaD_Precall, (void *)pLuaV_Execute);
    return false;
  }

  LOGI("[%s] ExecuteLua (%zu bytes)", label, code.size());

  // Wrap user code in pcall so errors are caught at Lua level.
  std::string wrapped =
      "local __ok, __res = pcall(function()\n" + code +
      "\nend)\n"
      "if not __ok then\n"
      "  return false, tostring(__res)\n"
      "else\n"
      "  return true, tostring(__res)\n"
      "end\n";

  // Construct ZIO struct
  ReaderData rdata = {wrapped.c_str(), wrapped.length()};
  uint8_t zio[48] = {};
  *(void **)(zio + 0x10) = (void *)MyLuaReader;
  *(void **)(zio + 0x18) = (void *)&rdata;
  *(void **)(zio + 0x20) = L;

  // Install ZIO at L+0x38
  void **zioSlot = (void **)((char *)L + 0x38);
  void *savedZio = *zioSlot;
  *zioSlot = (void *)zio;

  int loadRc = pProtParser(L, (void *)zio, 0);
  *zioSlot = savedZio;

  if (loadRc != 0) {
    LOGE("[%s] luaD_protectedparser FAILED: rc=%d", label, loadRc);
    void *top = LuaGetTop(L);
    void *errSlot = (char *)top - 16;
    int64_t errTt = *(int64_t *)((char *)errSlot + 8);
    const char *errStr = "(unknown parse error)";
    if ((errTt & 0x0F) == 4) {
      void *strObj = *(void **)errSlot;
      errStr = (const char *)strObj + 0x18;
    }
    LOGE("[%s] parse error: %.500s", label, errStr);
    {
      std::lock_guard<std::mutex> lock(g_resultMtx);
      g_lastResult = std::string("PARSE_ERR: ") + errStr;
      g_resultReady.store(true);
    }
    g_resultCv.notify_one();
    *(void **)((char *)L + 0x18) = errSlot;
    return false;
  }

  LOGI("[%s] parse OK. Compiled chunk on stack.", label);

  // The chunk is at top (this game uses top-inclusive convention)
  void *topBeforeCall = LuaGetTop(L);
  void *func_stkid = topBeforeCall;  // function IS at top, not top-1
  
  // Verify it's a function
  int64_t tt = *(int64_t *)((char *)func_stkid + 8);
  int baseType = (int)(tt & 0x0F);
  LOGI("[%s] func_stkid=%p tt=0x%llX baseType=%d", label, func_stkid, (long long)tt, baseType);

  // ======================================================================
  // Execute via the REAL luaD_precall + luaV_execute
  //
  // From lua_pcallk disassembly (0x31B47F4):
  //   void *ci = luaD_precall(L);         // 0x31B3F0C — sets up call frame
  //   if (ci) luaV_execute(L, ci);         // 0x31DA9F4 — 27KB VM loop
  //
  // Before calling precall, advance L->top past the function:
  //   L->top = func + 1 TValue
  // ======================================================================

  // Advance L->top past the function
  void *new_top = (char *)func_stkid + 16;
  *(void **)((char *)L + 0x18) = new_top;
  
  // Advance ci->top if needed
  void *ci = *(void **)((char *)L + 0x28);
  void *old_ci_top = *(void **)((char *)ci + 0x8);
  if ((uintptr_t)new_top > (uintptr_t)old_ci_top) {
    *(void **)((char *)ci + 0x8) = new_top;
  }
  
  LOGI("[%s] calling luaD_precall(%p)...", label, L);
  void *precall_ret = pLuaD_Precall(L);
  LOGI("[%s] luaD_precall returned %p", label, precall_ret);

  if (precall_ret) {
    LOGI("[%s] calling luaV_execute(%p, %p)...", label, L, precall_ret);
    pLuaV_Execute(L, precall_ret);
    LOGI("[%s] luaV_execute returned!", label);
  } else {
    LOGI("[%s] precall returned NULL — C function already executed or error", label);
  }

  // Check results
  void *postTop = LuaGetTop(L);
  int stackDiff = ((char *)postTop - (char *)func_stkid) / 16;
  LOGI("[%s] post-exec: top=%p stackDiff=%d", label, postTop, stackDiff);

  std::string result = "OK (precall=" + 
                       std::string(precall_ret ? "ci" : "NULL") +
                       ", stackDiff=" + std::to_string(stackDiff) + ")";
  LOGI("[%s] ✅ %s", label, result.c_str());

  // Restore stack
  *(void **)((char *)L + 0x18) = func_stkid;

  {
    std::lock_guard<std::mutex> lock(g_resultMtx);
    g_lastResult = result;
    g_resultReady.store(true);
  }
  g_resultCv.notify_one();

  return true;
}

// ===========================================================================
// ===========================================================================
// Hook: Dispatch hook (0x319E750)
//
// This function is NOT luaD_pcall. It's a ~136 byte utility that receives
// small integer arguments (1, 2, 3) and fires ~5000/s. We hook it purely
// for dispatch timing — after the original returns, we check for queued
// TCP commands and execute them on the game thread.
// ===========================================================================

static thread_local bool g_inExecute = false;

static int hkDispatch(void *L, int a1, int a2) {
  // Re-entrancy guard
  if (g_inExecute) {
    return oDispatchHook(L, a1, a2);
  }

  int count = g_pcallCount.fetch_add(1);
  if (count < 5 || (count < 100 && count % 20 == 0) || count % 5000 == 0) {
    LOGI("[hook] dispatch #%d (L=%p a1=%d a2=%d)", count, L, a1, a2);
  }

  // Update lua_State
  g_luaState.store(L);

  // Call original FIRST
  int result = oDispatchHook(L, a1, a2);

  // Dispatch queued command AFTER original returns
  if (g_ready.load()) {
    std::string cmdToRun;
    {
      std::lock_guard<std::mutex> lock(g_mtx);
      if (!g_cmdQueue.empty()) {
        cmdToRun = std::move(g_cmdQueue);
        g_cmdQueue.clear();
      }
    }
    if (!cmdToRun.empty()) {
      LOGI("[hook] executing cmd (%zu bytes) on dispatch #%d", cmdToRun.size(),
           count);
      g_inExecute = true;
      ExecuteLua(L, cmdToRun, "cmd");
      g_inExecute = false;
    }
  }

  return result;
}

// ===========================================================================
// TCP command server
// ===========================================================================

#define TCP_PORT 19840

static std::atomic<bool> g_tcpRunning{false};

static void *TcpServerThread(void *) {
  int server_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (server_fd < 0) {
    LOGE("[TCP] socket() failed: %s", strerror(errno));
    return nullptr;
  }

  int opt = 1;
  setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

  struct sockaddr_in addr = {};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons(TCP_PORT);

  if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    LOGE("[TCP] bind() failed: %s", strerror(errno));
    close(server_fd);
    return nullptr;
  }

  if (listen(server_fd, 1) < 0) {
    LOGE("[TCP] listen() failed: %s", strerror(errno));
    close(server_fd);
    return nullptr;
  }

  LOGI("[TCP] server listening on 127.0.0.1:%d", TCP_PORT);

  while (g_tcpRunning.load()) {
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(server_fd, &fds);
    struct timeval tv = {1, 0};

    int sel = select(server_fd + 1, &fds, nullptr, nullptr, &tv);
    if (sel <= 0)
      continue;

    int client_fd = accept(server_fd, nullptr, nullptr);
    if (client_fd < 0)
      continue;

    // Read command (up to 64KB)
    char buf[65536] = {};
    ssize_t total = 0;
    while (total < (ssize_t)sizeof(buf) - 1) {
      ssize_t n = read(client_fd, buf + total, sizeof(buf) - 1 - total);
      if (n <= 0)
        break;
      total += n;
    }
    buf[total] = '\0';

    // Trim trailing whitespace
    while (total > 0 && (buf[total - 1] == '\n' || buf[total - 1] == '\r' ||
                         buf[total - 1] == ' '))
      buf[--total] = '\0';

    if (total > 0) {
      std::string content(buf, total);
      std::string cmd;

      // If it ends with .lua, wrap in loadfile+pcall
      if (content.size() > 4 &&
          content.substr(content.size() - 4) == ".lua") {
        cmd = "local f, err = loadfile([[" + content +
              "]])\n"
              "if f then\n"
              "  local ok, rerr = pcall(f)\n"
              "  if not ok then error('[gate] exec: ' .. tostring(rerr)) end\n"
              "else\n"
              "  error('[gate] load: ' .. tostring(err))\n"
              "end";
      } else {
        cmd = content;
      }

      LOGI("[TCP] received %zd bytes: %.100s%s", total, content.c_str(),
           total > 100 ? "..." : "");

      // Queue command and wait for result
      {
        std::lock_guard<std::mutex> lock(g_resultMtx);
        g_resultReady.store(false);
        g_lastResult.clear();
      }
      {
        std::lock_guard<std::mutex> lock(g_mtx);
        g_cmdQueue = cmd;
      }

      // Wait for execution result (up to 10s)
      std::string response;
      {
        std::unique_lock<std::mutex> lock(g_resultMtx);
        if (g_resultCv.wait_for(lock, std::chrono::seconds(10),
                                [] { return g_resultReady.load(); })) {
          response = g_lastResult;
        } else {
          response = "TIMEOUT: command queued but not executed within 10s";
          LOGE("[TCP] execution timeout — hook may not be firing");
        }
      }

      // Send result back to client
      write(client_fd, response.c_str(), response.size());
      LOGI("[TCP] response: %.200s", response.c_str());
    }

    close(client_fd);
  }

  close(server_fd);
  LOGI("[TCP] server stopped");
  return nullptr;
}

// ===========================================================================
// luaopen_* hook — capture lua_State and compute API delta
//
// We hook all 5 exported luaopen_* functions via dlsym.
// Whichever fires first captures L and computes the base delta.
// ===========================================================================

struct LuaOpenEntry {
  const char *name;
  uintptr_t known_va;
  tLuaOpen original;
};

static LuaOpenEntry g_luaopenEntries[] = {
    {"luaopen_socket_core", VA_LUAOPEN_SOCKET_CORE, nullptr},
    {"luaopen_mime_core", VA_LUAOPEN_MIME_CORE, nullptr},
    {"luaopen_socket_serial", VA_LUAOPEN_SOCKET_SERIAL, nullptr},
    {"luaopen_socket_unix", VA_LUAOPEN_SOCKET_UNIX, nullptr},
    {"luaopen_memory_leak_checker", VA_LUAOPEN_MEMLEAK, nullptr},
};

static constexpr int LUAOPEN_COUNT =
    sizeof(g_luaopenEntries) / sizeof(g_luaopenEntries[0]);

// Which entry fired
static int g_firedIndex = -1;

static int hkLuaOpen(void *L) {
  // Determine which luaopen fired by checking return address against
  // known addresses, or just use atomic compare-exchange on g_firedIndex
  int expected = -1;

  // Find which entry this is from __builtin_return_address context
  // Actually, all hooks point here, so we check which original to call
  // by matching the lua_State first-fire pattern
  for (int i = 0; i < LUAOPEN_COUNT; i++) {
    if (g_luaopenEntries[i].original != nullptr && g_firedIndex == -1) {
      // Try this one
      void *funcAddr = (void *)(g_delta + g_luaopenEntries[i].known_va);
      // We can't easily distinguish which one called us since all hooks
      // point to the same function. Use a different approach:
      // Each hook gets its own trampoline. We'll set this up below.
    }
  }

  LOGI("[luaopen] hook fired! L=%p", L);

  // First time: capture L and compute delta
  if (!g_ready.load()) {
    g_luaState.store(L);
    LOGI("[luaopen] Captured lua_State L=%p", L);

    // Resolve API addresses via delta
    if (g_delta != 0) {
      pProtParser = (tLuaD_ProtParser)(g_delta + VA_LUAD_PROTPARSER);
      pLuaD_Precall = (tLuaD_Precall)(g_delta + VA_LUAD_PRECALL);
      pLuaV_Execute = (tLuaV_Execute)(g_delta + VA_LUAV_EXECUTE);
      pRawRunProtected = (tLuaD_RawRunProtected)(g_delta + VA_LUAD_RAWRUNPROTECTED);

      LOGI("[luaopen] API resolved: protparser=%p precall=%p execute=%p rawrun=%p",
           (void *)pProtParser, (void *)pLuaD_Precall, (void *)pLuaV_Execute, (void *)pRawRunProtected);

      // Hook dispatch function for command timing
      void *hookAddr = (void *)(g_delta + VA_DISPATCH_HOOK);
      int ret =
          DobbyHook(hookAddr, (void *)hkDispatch, (void **)&oDispatchHook);
      if (ret == 0) {
        LOGI("[luaopen] dispatch hooked at %p for command dispatch",
             hookAddr);
        g_ready.store(true);
      } else {
        LOGE("[luaopen] dispatch hook FAILED: %d", ret);
      }
    }
  }

  return 0; // This won't be reached — see per-index hooks
}

// Per-index hook functions (each calls the right original)
#define MAKE_LUAOPEN_HOOK(IDX)                                                 \
  static int hkLuaOpen_##IDX(void *L) {                                        \
    LOGI("[luaopen] %s fired (L=%p)", g_luaopenEntries[IDX].name, L);          \
    if (!g_ready.load()) {                                                     \
      g_luaState.store(L);                                                     \
      g_firedIndex = IDX;                                                      \
      LOGI("[luaopen] Captured lua_State L=%p from %s", L,                     \
           g_luaopenEntries[IDX].name);                                        \
      if (g_delta != 0) {                                                      \
        pProtParser = (tLuaD_ProtParser)(g_delta + VA_LUAD_PROTPARSER);       \
        pLuaD_Precall = (tLuaD_Precall)(g_delta + VA_LUAD_PRECALL);            \
        pLuaV_Execute = (tLuaV_Execute)(g_delta + VA_LUAV_EXECUTE);            \
        pRawRunProtected = (tLuaD_RawRunProtected)(g_delta + VA_LUAD_RAWRUNPROTECTED); \
        LOGI("[luaopen] API resolved: protparser=%p precall=%p execute=%p rawrun=%p", \
             (void *)pProtParser, (void *)pLuaD_Precall, (void *)pLuaV_Execute, \
             (void *)pRawRunProtected);                                        \
        void *hookAddr = (void *)(g_delta + VA_DISPATCH_HOOK);                 \
        int ret =                                                              \
            DobbyHook(hookAddr, (void *)hkDispatch, (void **)&oDispatchHook);  \
        if (ret == 0) {                                                        \
          LOGI("[luaopen] dispatch hooked at %p", hookAddr);                   \
        }                                                                      \
        g_ready.store(true);                                                 \
      }                                                                        \
    }                                                                          \
    return g_luaopenEntries[IDX].original(L);                                  \
  }

MAKE_LUAOPEN_HOOK(0)
MAKE_LUAOPEN_HOOK(1)
MAKE_LUAOPEN_HOOK(2)
MAKE_LUAOPEN_HOOK(3)
MAKE_LUAOPEN_HOOK(4)

typedef int (*LuaOpenHookFn)(void *);
static LuaOpenHookFn g_luaopenHooks[LUAOPEN_COUNT] = {
    hkLuaOpen_0, hkLuaOpen_1, hkLuaOpen_2, hkLuaOpen_3, hkLuaOpen_4,
};

// ===========================================================================
// InitThread — find libGame.so, dlsym exported symbols, install hooks
// ===========================================================================

static void *InitThread(void * /*arg*/) {
  LOGI("[init] Waiting for libGame.so...");

  // Wait for libGame.so to be loaded (poll up to 120s)
  void *gameHandle = nullptr;
  for (int i = 0; i < 240; ++i) {
    gameHandle = dlopen("libGame.so", RTLD_NOLOAD | RTLD_NOW);
    if (gameHandle)
      break;
    usleep(500 * 1000);
  }

  if (!gameHandle) {
    LOGE("[init] Timed out waiting for libGame.so (120s)");
    // Start TCP anyway for diagnostics
    g_tcpRunning.store(true);
    pthread_t tid;
    pthread_create(&tid, nullptr, TcpServerThread, nullptr);
    pthread_detach(tid);
    return nullptr;
  }

  LOGI("[init] libGame.so found (handle=%p)", gameHandle);

  // Resolve all exported luaopen_* functions via dlsym
  int hookedCount = 0;
  for (int i = 0; i < LUAOPEN_COUNT; i++) {
    void *sym = dlsym(gameHandle, g_luaopenEntries[i].name);
    if (!sym) {
      LOGI("[init] dlsym(%s) = NULL (not exported?)", g_luaopenEntries[i].name);
      continue;
    }

    LOGI("[init] dlsym(%s) = %p (expected VA=0x%lX)", g_luaopenEntries[i].name,
         sym, (unsigned long)g_luaopenEntries[i].known_va);

    // Compute delta from the first symbol we find
    if (g_delta == 0) {
      g_delta = (uintptr_t)sym - g_luaopenEntries[i].known_va;
      LOGI("[init] Base delta = 0x%lX (from %s)", (unsigned long)g_delta,
           g_luaopenEntries[i].name);

      // Validate: check if another exported symbol also matches
      for (int j = i + 1; j < LUAOPEN_COUNT; j++) {
        void *check = dlsym(gameHandle, g_luaopenEntries[j].name);
        if (check) {
          uintptr_t checkDelta =
              (uintptr_t)check - g_luaopenEntries[j].known_va;
          if (checkDelta == g_delta) {
            LOGI("[init] Delta confirmed by %s ✅", g_luaopenEntries[j].name);
          } else {
            LOGE("[init] Delta MISMATCH for %s: 0x%lX vs 0x%lX ❌",
                 g_luaopenEntries[j].name, (unsigned long)checkDelta,
                 (unsigned long)g_delta);
          }
          break;
        }
      }
    }

    // Hook this luaopen function
    int ret = DobbyHook(sym, (void *)g_luaopenHooks[i],
                        (void **)&g_luaopenEntries[i].original);
    if (ret == 0) {
      LOGI("[init] Hooked %s ✅", g_luaopenEntries[i].name);
      hookedCount++;
    } else {
      LOGE("[init] Hook %s FAILED: %d", g_luaopenEntries[i].name, ret);
    }
  }

  dlclose(gameHandle);

  if (hookedCount == 0) {
    LOGE("[init] No luaopen_* functions hooked! Falling back to scan...");
    // Could add pattern-scan fallback here
  } else {
    LOGI("[init] Hooked %d/%d luaopen_* functions. Waiting for first fire...",
         hookedCount, LUAOPEN_COUNT);
  }

  // Log resolved API addresses (computed from delta, not yet hooked)
  if (g_delta != 0) {
    LOGI("[init] Pre-computed API addresses (delta=0x%lX):",
         (unsigned long)g_delta);
    LOGI("[init]   dispatch_hook   = %p",
         (void *)(g_delta + VA_DISPATCH_HOOK));
    LOGI("[init]   rawrunprotected = %p",
         (void *)(g_delta + VA_LUAD_RAWRUNPROTECTED));
    LOGI("[init]   luaD_precall    = %p",
         (void *)(g_delta + VA_LUAD_PRECALL));
    LOGI("[init]   luaD_protparser = %p",
         (void *)(g_delta + VA_LUAD_PROTPARSER));
    LOGI("[init]   luaV_execute    = %p",
         (void *)(g_delta + VA_LUAV_EXECUTE));
  }

  // Start TCP command server
  g_tcpRunning.store(true);
  pthread_t tid;
  pthread_create(&tid, nullptr, TcpServerThread, nullptr);
  pthread_detach(tid);

  LOGI("[init] TCP server started on port %d. Waiting for luaopen_* to fire...",
       TCP_PORT);
  return nullptr;
}

// ===========================================================================
// Entry point — JNI_OnLoad
// ===========================================================================

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void * /*reserved*/) {
  LOGI("=== JNI_OnLoad: inject library loaded ===");
  g_javaVM = vm;

  // Patch JNI function table to auto-clear pending exceptions
  JNIEnv *env = nullptr;
  if (vm->GetEnv((void **)&env, JNI_VERSION_1_6) == JNI_OK && env) {
    InstallJniExceptionGuard(env);
  } else {
    LOGE("[bypass] could not get JNIEnv — JNI guard not installed");
  }

  // Install abort diagnostic hook
  InstallBypassHooks();

  // Spawn background thread to wait for libGame.so and install hooks
  pthread_t initTid;
  pthread_create(&initTid, nullptr, InitThread, nullptr);
  pthread_detach(initTid);

  LOGI("Init thread spawned, returning to app startup");
  return JNI_VERSION_1_6;
}
