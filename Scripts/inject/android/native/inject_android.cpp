// inject_android.cpp — ARM64 Lua hook library for Android (v3)
//
// Strategy: dlsym-based hooking of exported luaopen_* symbols
// No pattern scanning needed — all API addresses computed via delta
// from the known VA of the hooked exported function.
//
// Execution pipeline (mirrors Windows inject.cpp):
//   luaopen_* hook → capture lua_State* L → compute API delta
//   → hook lua_pcallk (0x0319DBE4, FUN_030e55b0, 151 callers)
//   hkLuaPcallk intercepts → dispatches queued TCP commands
//   ExecuteLua → lua_load + lua_pcallk (original trampoline)
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
// Known VA offsets — from Ghidra deep analysis (2026-04-02)
//
// These are the virtual addresses in the libGame.so binary.
// lua_pcallk: FUN_030e55b0 — 151 callers, 484 bytes, calls luaD_rawrunprotected ×3
// lua_load:   FUN_030fa7a4 — 38 callers, 292 bytes, calls luaD_protectedparser
// ===========================================================================

// Exported symbols (findable via dlsym)
static constexpr uintptr_t VA_LUAOPEN_SOCKET_CORE = 0x323D354;
static constexpr uintptr_t VA_LUAOPEN_MIME_CORE = 0x323D5D0;
static constexpr uintptr_t VA_LUAOPEN_SOCKET_SERIAL = 0x3240E64;
static constexpr uintptr_t VA_LUAOPEN_SOCKET_UNIX = 0x3243044;
static constexpr uintptr_t VA_LUAOPEN_MEMLEAK = 0x324AB0C;

// High-level Lua C API (Ghidra deep-verified)
static constexpr uintptr_t VA_LUA_PCALLK = 0x0319DBE4;  // FUN_030e55b0 — the REAL lua_pcallk (151 callers, 484 bytes)
static constexpr uintptr_t VA_LUA_LOAD   = 0x031B2DD8;  // FUN_030fa7a4 — lua_load (38 callers, 292 bytes)

// ===========================================================================
// Lua function types (mirrors Windows inject.cpp)
// ===========================================================================

typedef int (*tLuaOpen)(void *L);

// lua_load: int (L, reader, data, chunkname, mode)
typedef int (*tLuaLoad)(void *L, void *reader, void *data,
                        const char *chunkname, const char *mode);

// lua_pcallk: int (L, nargs, nresults, errfunc, ctx, k)
typedef int (*tLuaPcallk)(void *L, int nargs, int nresults,
                          int errfunc, void *ctx, void *k);

static tLuaLoad oLuaLoad = nullptr;
static tLuaPcallk oLuaPcallk = nullptr;



// Base delta: runtime_addr - compile_time_VA
static uintptr_t g_delta = 0;

// Lua state captured from luaopen_* hook
static std::atomic<void *> g_luaState{nullptr};
static std::atomic<bool> g_ready{false};

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
  auto *d = (ReaderData *)ud;
  if (d->size == 0) {
    *sz = 0;
    return nullptr;
  }
  *sz = d->size;
  d->size = 0;
  return d->s;
}

// ===========================================================================
// Execute Lua code via lua_load + lua_pcallk (mirrors Windows inject.cpp)
// ===========================================================================

static bool ExecuteLua(void *L, const std::string &code, const char *label) {
  if (!oLuaLoad || !oLuaPcallk) {
    LOGE("[%s] APIs not resolved! load=%p pcallk=%p", label,
         (void *)oLuaLoad, (void *)oLuaPcallk);
    return false;
  }

  LOGI("[%s] ExecuteLua (%zu bytes)", label, code.size());

  ReaderData rdata = {code.c_str(), code.length()};

  int loadRc = oLuaLoad(L, (void *)MyLuaReader, (void *)&rdata, "@cmd", "t");
  if (loadRc != 0) {
    LOGE("[%s] lua_load FAILED: rc=%d", label, loadRc);
    std::string result = "LOAD_ERR: rc=" + std::to_string(loadRc);
    {
      std::lock_guard<std::mutex> lock(g_resultMtx);
      g_lastResult = result;
      g_resultReady.store(true);
    }
    g_resultCv.notify_one();
    return false;
  }

  LOGI("[%s] lua_load OK. Calling lua_pcallk...", label);

  int pcallRc = oLuaPcallk(L, 0, 0, 0, nullptr, nullptr);
  if (pcallRc != 0) {
    LOGE("[%s] lua_pcallk FAILED: rc=%d", label, pcallRc);
    std::string result = "PCALL_ERR: rc=" + std::to_string(pcallRc);
    {
      std::lock_guard<std::mutex> lock(g_resultMtx);
      g_lastResult = result;
      g_resultReady.store(true);
    }
    g_resultCv.notify_one();
    return false;
  }

  LOGI("[%s] ✅ executed successfully", label);
  {
    std::lock_guard<std::mutex> lock(g_resultMtx);
    g_lastResult = "OK";
    g_resultReady.store(true);
  }
  g_resultCv.notify_one();
  return true;
}

// ===========================================================================
// Hook: lua_pcallk — mirrors Windows hkLua_Pcall
//
// FUN_030e55b0 (ELF VA 0x0319DBE4) — the REAL lua_pcallk
// 151 callers, 484 bytes, calls luaD_rawrunprotected ×3
// ===========================================================================

static thread_local bool g_inExecute = false;

static int hkLuaPcallk(void *L, int nargs, int nresults,
                       int errfunc, void *ctx, void *k) {
  // Re-entrancy guard
  if (g_inExecute) {
    return oLuaPcallk(L, nargs, nresults, errfunc, ctx, k);
  }

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
    LOGI("[hook] executing cmd (%zu bytes) via lua_pcallk hook", cmdToRun.size());
    g_inExecute = true;
    ExecuteLua(L, cmdToRun, "cmd");
    g_inExecute = false;
  }

  return oLuaPcallk(L, nargs, nresults, errfunc, ctx, k);
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
// Whichever fires first captures L, computes the base delta,
// and hooks lua_pcallk for command dispatch.
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
        /* Resolve lua_load as direct function pointer */                       \
        oLuaLoad = (tLuaLoad)(g_delta + VA_LUA_LOAD);                          \
        LOGI("[luaopen] lua_load = %p", (void *)oLuaLoad);                     \
        /* Hook lua_pcallk — mirrors Windows inject.cpp */                      \
        void *pcallkAddr = (void *)(g_delta + VA_LUA_PCALLK);                  \
        int ret = DobbyHook(pcallkAddr, (void *)hkLuaPcallk,                   \
                            (void **)&oLuaPcallk);                             \
        if (ret == 0) {                                                        \
          LOGI("[luaopen] lua_pcallk hooked at %p ✅", pcallkAddr);            \
          g_ready.store(true);                                                 \
        } else {                                                               \
          LOGE("[luaopen] lua_pcallk hook FAILED: %d", ret);                   \
        }                                                                      \
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
    LOGI("[init]   lua_pcallk = %p (VA=0x%lX)",
         (void *)(g_delta + VA_LUA_PCALLK), (unsigned long)VA_LUA_PCALLK);
    LOGI("[init]   lua_load   = %p (VA=0x%lX)",
         (void *)(g_delta + VA_LUA_LOAD), (unsigned long)VA_LUA_LOAD);
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
