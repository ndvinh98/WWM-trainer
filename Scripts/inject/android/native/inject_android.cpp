// inject_android.cpp — ARM64 Lua hook library for Android
// Loaded as ELF DT_NEEDED dependency via patched native .so
// Uses Dobby for inline hooking (replaces MinHook)

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

#include "dobby.h"
#include "sig_config.h"

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
// auto-clear any pending exception before proceeding. This prevents
// ART from ever seeing the stale Firebase exception.
// ===========================================================================

static JavaVM *g_javaVM = nullptr;

// Original JNI function pointers
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
  // Round up to page boundary
  span = (span + 4095) & ~(size_t)(4095);
  if (mprotect((void *)page, span, PROT_READ | PROT_WRITE) != 0) {
    LOGE("[bypass] mprotect failed: %s (addr=%p len=%zu)", strerror(errno),
         addr, len);
    return false;
  }
  return true;
}

static void InstallJniExceptionGuard(JNIEnv *env) {
  // The JNINativeInterface (C function table) is pointed to by env->functions
  // JNIEnv in C++ is a wrapper; the actual table is at *((void**)env)
  auto **table = reinterpret_cast<void ***>(env);
  auto *funcs = *table;

  // JNINativeInterface function offsets (ARM64, Android):
  // FindClass        = index 6
  // GetFieldID       = index 94
  // GetStaticFieldID = index 144
  // These indices are stable across Android versions.

  oFindClass = reinterpret_cast<jclass (*)(JNIEnv *, const char *)>(funcs[6]);
  oGetFieldID = reinterpret_cast<jfieldID (*)(JNIEnv *, jclass, const char *,
                                              const char *)>(funcs[94]);
  oGetStaticFieldID = reinterpret_cast<jfieldID (*)(
      JNIEnv *, jclass, const char *, const char *)>(funcs[144]);

  // The JNI function table may be in read-only memory — make it writable
  // We need to cover indices 6 through 144, so mprotect the whole range
  void *start = &funcs[0];
  size_t tableSize = 256 * sizeof(void *); // generous — full table
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

// --- abort() diagnostic hook: log caller before allowing crash ---
typedef void (*tAbort)(void);
static tAbort oAbort = nullptr;

static void hkAbort() {
  void *caller = __builtin_return_address(0);
  void *caller2 = __builtin_return_address(1);
  LOGE("[bypass] abort() called from %p (caller2=%p)", caller, caller2);

  // Log the maps around the caller address to identify the library
  char line[512];
  FILE *fp = fopen("/proc/self/maps", "r");
  if (fp) {
    while (fgets(line, sizeof(line), fp)) {
      uintptr_t start, end;
      if (sscanf(line, "%lx-%lx", &start, &end) == 2) {
        if ((uintptr_t)caller >= start && (uintptr_t)caller < end) {
          LOGE("[bypass] abort caller is in: %s", line);
        }
        if ((uintptr_t)caller2 >= start && (uintptr_t)caller2 < end) {
          LOGE("[bypass] abort caller2 is in: %s", line);
        }
      }
    }
    fclose(fp);
  }

  // Call original abort
  oAbort();
  // abort is _Noreturn but just in case
  __builtin_unreachable();
}

// --- getaddrinfo hook: block UniSDK network checks ---
typedef int (*tGetaddrinfo)(const char *node, const char *service,
                            const struct addrinfo *hints,
                            struct addrinfo **res);
static tGetaddrinfo oGetaddrinfo = nullptr;

static const char *BLOCKED_HOSTS[] = {"protocol.unisdk.easebar.com", nullptr};

static int hkGetaddrinfo(const char *node, const char *service,
                         const struct addrinfo *hints, struct addrinfo **res) {
  if (node) {
    for (int i = 0; BLOCKED_HOSTS[i]; i++) {
      if (strcmp(node, BLOCKED_HOSTS[i]) == 0) {
        LOGI("[bypass] blocked DNS: %s", node);
        return EAI_NONAME;
      }
    }
  }
  return oGetaddrinfo(node, service, hints, res);
}

static void InstallBypassHooks() {
  // Hook abort() for diagnostic logging
  void *abortAddr = DobbySymbolResolver(nullptr, "abort");
  if (abortAddr) {
    int ret = DobbyHook(abortAddr, (void *)hkAbort, (void **)&oAbort);
    if (ret == 0)
      LOGI("[bypass] abort() hooked for diagnostics");
    else
      LOGE("[bypass] abort() hook FAILED: %d", ret);
  }

  // Hook getaddrinfo via Dobby
  void *gai = DobbySymbolResolver(nullptr, "getaddrinfo");
  if (gai) {
    int ret = DobbyHook(gai, (void *)hkGetaddrinfo, (void **)&oGetaddrinfo);
    if (ret == 0)
      LOGI("[bypass] getaddrinfo hooked");
    else
      LOGE("[bypass] getaddrinfo hook FAILED: %d", ret);
  }
}

// ===========================================================================
// Lua function types — correct signatures from call-graph analysis
//
// lua_load:      int lua_load(L, reader, data, chunkname, mode)
// luaD_pcall:    int luaD_pcall(L, Pfunc func, void* ud, ptrdiff_t old_top,
// ptrdiff_t ef) luaD_call:     void luaD_call(L, StkId func, int nresults)
//
// luaD_pcall is the protected call wrapper (fan-in=3051).
// luaD_call is the unprotected call dispatch (used to execute loaded chunks).
// ===========================================================================

typedef int (*tLua_Load)(void *L, void *reader, void *dt, const char *chunkname,
                         const char *mode);
typedef int (*tLuaD_Pcall)(void *L, void *func, void *ud, ptrdiff_t old_top,
                           ptrdiff_t ef);
typedef void (*tLuaD_Call)(void *L, void *func_stkid, int nresults);

static tLua_Load oLua_Load = nullptr;
static tLuaD_Pcall oLuaD_Pcall = nullptr;
static tLuaD_Call pLuaD_Call = nullptr;

static std::atomic<int> pcallCount{0};
static std::atomic<bool> bInjected{false};
static std::string cmdQueue;
static std::mutex mtx;

// ===========================================================================
// Lua reader callback (same as Windows version)
// ===========================================================================

struct ReaderData {
  const char *s;
  size_t size;
};

static const char *MyLuaReader(void *L, void *ud, size_t *sz) {
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
// lua_gettop equivalent — reads stack top from lua_State
// lua_State layout (Lua 5.4): L->top is at offset 0x18 (field ci is at 0x28)
// From probe: lua_gettop at 0x3194C78 does:
//   LDR x8, [x0, #0x28]   -- L->ci
//   LDR x9, [x0, #0x18]   -- L->top
//   LDR x8, [x8, #0x00]   -- ci->func
//   SUB x8, x9, x8        -- top - func
//   SUB x8, x8, #0x10     -- adjust (size of TValue = 16 on 64-bit)
//   LSR x0, x8, #4        -- divide by 16
// So: L->top is at offset 0x18, L->ci at 0x28, ci->func at ci+0
// ===========================================================================

// Read the stack top pointer from lua_State
static inline void *LuaGetTop(void *L) {
  return *(void **)((char *)L + 0x18); // L->top.p (Lua 5.4)
}

// Read L->ci (current CallInfo)
static inline void *LuaGetCI(void *L) {
  return *(void **)((char *)L + 0x28); // L->ci
}

// Read ci->func (the function StkId at bottom of current call frame)
static inline void *CIGetFunc(void *ci) {
  return *(void **)((char *)ci + 0x00); // ci->func
}

// Compute savestack(L, p) = (char*)p - (char*)L->stack
static inline ptrdiff_t SaveStack(void *L, void *p) {
  void *stack = *(void **)((char *)L + 0x10); // L->stack (offset 0x10)
  return (char *)p - (char *)stack;
}

// ===========================================================================
// Execute Lua code string via lua_load + luaD_pcall
//
// Mirrors the Windows DLL pattern:
//   lua_load(L, reader, data, name, mode)  → compile source to chunk
//   luaD_pcall(L, f_call, &c, old_top, ef) → execute chunk (protected)
//
// We use luaD_pcall (not luaD_call) so errors are caught, not crashed.
//
// f_call (at 0x319E5F4 in libGame.so) is the function that luaD_pcall
// uses to actually invoke the chunk via luaD_call. We call it directly.
// ===========================================================================

// Wrapper that mimics Lua's internal f_call for luaD_pcall:
//   void f_call(lua_State *L, void *ud) {
//       StkId func = ((struct CallS *)ud)->func;
//       luaD_call(L, func, ((struct CallS *)ud)->nresults);
//   }
struct CallS {
  void *func; // StkId — pointer to the TValue of the function
  int nresults;
};

static void our_f_call(void *L, void *ud) {
  CallS *c = (CallS *)ud;
  LOGI("[f_call] invoking luaD_call (L=%p, func=%p, nresults=%d)", L, c->func,
       c->nresults);
  pLuaD_Call(L, c->func, c->nresults);
}

static bool ExecuteLua(void *L, const std::string &code, const char *label) {
  LOGI("[%s] ExecuteLua called (code=%zu bytes, L=%p)", label, code.size(), L);

  // The function at 0x31B2DE8 is NOT standard lua_load — it's a game wrapper
  // with a custom mutex at L+0x58 that deadlocks.
  // Instead, call luaD_protectedparser directly at 0x31B7010.
  // From the disassembly:
  //   - Parser reads L+0x40 for its buffer/reader struct
  //   - Wrapper passes L+0x38 as arg2, and mode as arg3 (w2)

  uintptr_t delta = (uintptr_t)oLua_Load - 0x31B2DE8;
  typedef int (*tLuaD_ProtParser)(void *L, void *zio, int mode);
  auto pProtParser = (tLuaD_ProtParser)(delta + 0x31B7010);

  // Set up Zio structure
  ReaderData rdata = {code.c_str(), code.length()};
  uint8_t zio[48] = {};
  *(size_t *)(zio + 0x00) = code.length();      // n
  *(const char **)(zio + 0x08) = code.c_str();  // p
  *(void **)(zio + 0x10) = (void *)MyLuaReader; // reader
  *(void **)(zio + 0x18) = (void *)&rdata;      // data
  *(void **)(zio + 0x20) = L;                   // L

  // Save and set L+0x40 (where the parser actually reads from)
  void **bufPtr40 = (void **)((char *)L + 0x40);
  void *savedBuf40 = *bufPtr40;
  *bufPtr40 = (void *)zio;

  // Also set L+0x38 (passed as arg2 by the wrapper)
  void **zioPtr38 = (void **)((char *)L + 0x38);
  void *savedZio38 = *zioPtr38;
  *zioPtr38 = (void *)zio;

  LOGI("[%s] calling luaD_protectedparser(L=%p, zio=%p, mode=0)...", label, L,
       (void *)zio);
  int loadRc = pProtParser(L, (void *)zio, 0);

  *bufPtr40 = savedBuf40;
  *zioPtr38 = savedZio38;

  LOGI("[%s] luaD_protectedparser returned: rc=%d", label, loadRc);

  if (loadRc != 0) {
    LOGE("[%s] Parser FAILED: rc=%d", label, loadRc);
    return false;
  }

  // The loaded chunk is now on top of the stack.
  void *top = LuaGetTop(L);
  void *func_stkid = (char *)top - 16; // The chunk TValue

  LOGI("[%s] load OK, chunk at %p, calling luaD_call directly...", label,
       func_stkid);

  // Use luaD_call directly instead of luaD_pcall.
  // luaD_pcall has its own locking/TLS checks that may block.
  // luaD_call(L, StkId func, int nresults) is simpler.
  pLuaD_Call(L, func_stkid, 0); // nresults=0 (LUA_MULTRET)

  LOGI("[%s] luaD_call returned — executed OK!", label);
  return true;
}

// Same as ExecuteLua but expects 1 return value and reads it as a string.
// Wraps the code in "return <code>" to get a result.
static bool ExecuteLuaReturn(void *L, const std::string &expr,
                             const char *label) {
  // Wrap expression to return a value
  std::string code = "return tostring(" + expr + ")";
  LOGI("[%s] ExecuteLuaReturn: %s", label, code.c_str());

  uintptr_t delta = (uintptr_t)oLua_Load - 0x31B2DE8;
  typedef int (*tLuaD_ProtParser)(void *L, void *zio, int mode);
  auto pProtParser = (tLuaD_ProtParser)(delta + 0x31B7010);

  ReaderData rdata = {code.c_str(), code.length()};
  uint8_t zio[48] = {};
  *(size_t *)(zio + 0x00) = code.length();
  *(const char **)(zio + 0x08) = code.c_str();
  *(void **)(zio + 0x10) = (void *)MyLuaReader;
  *(void **)(zio + 0x18) = (void *)&rdata;
  *(void **)(zio + 0x20) = L;

  void **bufPtr40 = (void **)((char *)L + 0x40);
  void *saved40 = *bufPtr40;
  *bufPtr40 = (void *)zio;
  void **zioPtr38 = (void **)((char *)L + 0x38);
  void *saved38 = *zioPtr38;
  *zioPtr38 = (void *)zio;

  int loadRc = pProtParser(L, (void *)zio, 0);
  *bufPtr40 = saved40;
  *zioPtr38 = saved38;

  if (loadRc != 0) {
    LOGE("[%s] parse failed: rc=%d", label, loadRc);
    return false;
  }

  void *topBefore = LuaGetTop(L);
  void *func_stkid = (char *)topBefore - 16;

  // Call with nresults=1 to get exactly one return value
  pLuaD_Call(L, func_stkid, 1);

  // Read the returned value from top of stack
  void *topAfter = LuaGetTop(L);
  if (topAfter > topBefore) {
    // The return value is at topBefore (where the function was)
    // After call, the return value replaces the function slot
    // Actually: luaD_call with nresults=1 leaves 1 value at func_stkid
    void *resultSlot = func_stkid;

    // Read TValue: value(8 bytes) + tt_(8 bytes) in Lua 5.4
    void *value = *(void **)((char *)resultSlot);
    int64_t tt = *(int64_t *)((char *)resultSlot + 8);
    int baseType = tt & 0x0F;

    if (baseType == 4) { // LUA_TSTRING
      // In Lua 5.4, string TValue.value_ is a GCObject* pointing to TString
      // TString has: CommonHeader (16 bytes in 64-bit), then...
      // For short strings: header + extra(1) + shrlen(1) + hash(4) + data
      // The actual string bytes start at TString + offsetof(data)
      // Common offset: TString + 0x18 (24 bytes header)
      char *str = (char *)value;
      // Try reading at offset 0x18 (most common for Lua 5.4 64-bit)
      const char *sdata = str + 0x18;
      LOGI("[%s] RESULT (string): '%.200s'", label, sdata);
    } else {
      LOGI("[%s] RESULT: type=0x%lX value=%p", label, (unsigned long)tt, value);
    }
  } else {
    LOGI("[%s] RESULT: no return value (top unchanged)", label);
  }

  // Restore stack: pop the return value
  *(void **)((char *)L + 0x18) = (char *)func_stkid;
  return true;
}

// ===========================================================================
// Shared lua_State capture — luaD_pcall hook stores L here
// ===========================================================================
static std::atomic<void *> g_luaState{nullptr};

// ===========================================================================
// Runtime Probes — C-level diagnostics using known VA offsets
//
// These bypass lua_load entirely and use direct Lua C API calls
// resolved from the SO base address at runtime.
// ===========================================================================

// Known VA offsets from call-graph analysis
static constexpr uintptr_t VA_LUA_GETTOP = 0x3194C78;
static constexpr uintptr_t VA_LUA_SETTOP = 0x3194FB8;
static constexpr uintptr_t VA_LUA_GETFIELD = 0x319A660;
static constexpr uintptr_t VA_LUA_PUSHSTRING = 0x3196570;
static constexpr uintptr_t VA_LUA_PUSHNIL = 0x31964A0;
static constexpr uintptr_t VA_LUA_TYPE = 0x3194E30; // lua_type(L, idx)
static constexpr uintptr_t VA_LUA_TOLSTRING =
    0x3195160; // lua_tolstring(L, idx, len*)
static constexpr uintptr_t VA_LUA_TOBOOLEAN =
    0x31950F4; // lua_toboolean(L, idx)
static constexpr uintptr_t VA_LUA_CHECKSTACK = 0x3194C94;

typedef int (*tLua_GetTop)(void *L);
typedef void (*tLua_SetTop)(void *L, int idx);
typedef int (*tLua_GetField)(void *L, int idx, const char *k);
typedef const char *(*tLua_PushString)(void *L, const char *s);
typedef void (*tLua_PushNil)(void *L);
typedef int (*tLua_Type)(void *L, int idx);
typedef const char *(*tLua_ToLString)(void *L, int idx, size_t *len);
typedef int (*tLua_ToBoolean)(void *L, int idx);
typedef int (*tLua_CheckStack)(void *L, int n);

// Lua type constants
static const char *lua_typename_str(int t) {
  switch (t) {
  case 0:
    return "nil";
  case 1:
    return "boolean";
  case 2:
    return "lightuserdata";
  case 3:
    return "number";
  case 4:
    return "string";
  case 5:
    return "table";
  case 6:
    return "function";
  case 7:
    return "userdata";
  case 8:
    return "thread";
  default:
    return "unknown";
  }
}

// LUA_REGISTRYINDEX for Lua 5.4
#define LUA_REGISTRYINDEX (-1001000)
// LUA_RIDX_GLOBALS = 2
#define LUA_RIDX_GLOBALS 2

static void RunProbe(void *L, const std::string &cmd) {
  // Compute runtime base delta from known function addresses
  uintptr_t delta = 0;
  if (oLua_Load) {
    delta = (uintptr_t)oLua_Load - 0x31B2DE8;
  } else if (oLuaD_Pcall) {
    delta = (uintptr_t)oLuaD_Pcall - 0x319E750;
  }

  if (!delta) {
    LOGE("[probe] cannot compute base delta");
    return;
  }

  auto pGetTop = (tLua_GetTop)(delta + VA_LUA_GETTOP);
  auto pSetTop = (tLua_SetTop)(delta + VA_LUA_SETTOP);
  auto pGetField = (tLua_GetField)(delta + VA_LUA_GETFIELD);
  auto pPushString = (tLua_PushString)(delta + VA_LUA_PUSHSTRING);
  auto pPushNil = (tLua_PushNil)(delta + VA_LUA_PUSHNIL);
  auto pType = (tLua_Type)(delta + VA_LUA_TYPE);
  auto pToLString = (tLua_ToLString)(delta + VA_LUA_TOLSTRING);
  auto pCheckStack = (tLua_CheckStack)(delta + VA_LUA_CHECKSTACK);

  LOGI("[probe] delta=0x%lx", (unsigned long)delta);
  LOGI("[probe] resolved: gettop=%p settop=%p getfield=%p pushstr=%p type=%p",
       (void *)pGetTop, (void *)pSetTop, (void *)pGetField, (void *)pPushString,
       (void *)pType);

  if (cmd == "__probe_state") {
    // Dump lua_State structure
    LOGI("[probe] === lua_State dump (L=%p) ===", L);
    for (int off = 0; off < 0x80; off += 8) {
      void *val = *(void **)((char *)L + off);
      LOGI("[probe]   L+0x%02X = %p", off, val);
    }

    int top = pGetTop(L);
    LOGI("[probe] lua_gettop(L) = %d", top);

    void *ci = LuaGetCI(L);
    void *ci_func = CIGetFunc(ci);
    LOGI("[probe] L->ci=%p, ci->func=%p", ci, ci_func);

  } else if (cmd == "__probe_globals") {
    // Step-by-step safe probing of the Lua VM
    LOGI("[probe] === Safe globals probe ===");

    int topBefore = pGetTop(L);
    LOGI("[probe] gettop OK: %d", topBefore);

    // Test pushstring + pop (confirmed working)
    pCheckStack(L, 5);
    const char *pushed = pPushString(L, "hello");
    int topAfterPush = pGetTop(L);
    LOGI("[probe] pushstring='%s', top: %d -> %d", pushed, topBefore,
         topAfterPush);
    pSetTop(L, topBefore);
    LOGI("[probe] after pop: top=%d", pGetTop(L));

    // Dump G(L) and registry pointer
    void *G = *(void **)((char *)L + 0x20);
    LOGI("[probe] G(L) = %p", G);
    if (G) {
      // Registry TValue is at G+0x40 (from lua_getfield disasm: ADD x8, x8,
      // #0x40)
      void *reg_value = *(void **)((char *)G + 0x40);
      int reg_tt = *(int *)((char *)G + 0x48); // TValue.tt_ is at +8
      LOGI("[probe] G+0x40 (registry value) = %p", reg_value);
      LOGI("[probe] G+0x48 (registry tt_)   = 0x%X", reg_tt);
    }

    // Try lua_getfield(L, REGISTRYINDEX, "_LOADED")
    LOGI("[probe] >>> lua_getfield(L, %d, '_LOADED')...", LUA_REGISTRYINDEX);
    int ft = pGetField(L, LUA_REGISTRYINDEX, "_LOADED");
    LOGI("[probe] <<< getfield returned type=%d (%s)", ft,
         lua_typename_str(ft));
    pSetTop(L, topBefore);
    LOGI("[probe] Done!");

  } else if (cmd == "__probe_load") {
    // Test lua_load with minimal input — using ONLY raw memory reads
    LOGI("[probe] === Testing lua_load (raw, no API calls) ===");

    // Read L->top directly from memory (confirmed: L+0x18)
    void *topBefore = LuaGetTop(L);
    LOGI("[probe] L->top before = %p", topBefore);

    // Bypass the game's custom mutex at L+0x58
    void **lockPtr = (void **)((char *)L + 0x58);
    void *savedLock = *lockPtr;
    *lockPtr = nullptr;

    // Dump what's currently at L+0x38 (the existing Zio)
    void *existingZio = *(void **)((char *)L + 0x38);
    LOGI("[probe] existing L+0x38 (Zio) = %p", existingZio);
    if (existingZio) {
      for (int off = 0; off < 0x30; off += 8) {
        void *v = *(void **)((char *)existingZio + off);
        LOGI("[probe]   Zio+0x%02X = %p", off, v);
      }
    }

    // Instead of calling the wrapper (which may have issues with our Zio),
    // call luaD_protectedparser (0x31B7010) directly with the existing L+0x38.
    // luaD_protectedparser(L, Zio_ptr)
    uintptr_t delta = (uintptr_t)oLua_Load - 0x31B2DE8;
    typedef int (*tLuaD_ProtParser)(void *L, void *zio);
    auto pProtParser = (tLuaD_ProtParser)(delta + 0x31B7010);

    // Set up OUR Zio with a simple "do end" script
    const char *code = "do end";
    ReaderData rd = {code, 6};
    uint8_t zio[48] = {};
    *(size_t *)(zio + 0x00) = 6;                  // n
    *(const char **)(zio + 0x08) = code;          // p
    *(void **)(zio + 0x10) = (void *)MyLuaReader; // reader
    *(void **)(zio + 0x18) = (void *)&rd;         // data
    *(void **)(zio + 0x20) = L;                   // L

    // Option 1: set L+0x38 to our Zio and call the wrapper
    void **zioPtr = (void **)((char *)L + 0x38);
    void *savedZio = *zioPtr;
    *zioPtr = (void *)zio;

    LOGI("[probe] calling luaD_protectedparser(%p, %p) directly...", L,
         (void *)zio);
    int rc = pProtParser(L, (void *)zio);

    *lockPtr = savedLock;
    *zioPtr = savedZio;
    LOGI("[probe] luaD_protectedparser returned: %d", rc);

  } else if (cmd == "__probe_exec") {
    // Full load+execute test — NO wrong API calls, all raw memory
    LOGI("[probe] === Full load+exec test (raw) ===");

    void *topBefore = LuaGetTop(L);
    LOGI("[probe] L->top before = %p", topBefore);

    const char *code = "local f=io.open('/sdcard/wwm_test.txt','w') if f then "
                       "f:write('OK') f:close() end";

    LOGI("[probe] calling ExecuteLua with file-write test...");
    bool ok = ExecuteLua(L, code, "probe_exec");
    LOGI("[probe] ExecuteLua returned: %s", ok ? "true" : "false");

    // Check if file was created
    LOGI("[probe] Checking if /sdcard/wwm_test.txt was created...");

    // Restore stack
    *(void **)((char *)L + 0x18) = topBefore;
    LOGI("[probe] Done, stack restored");
  }
}

// ===========================================================================
// Hook: luaD_pcall — the single bottleneck for ALL protected Lua calls
//   int luaD_pcall(L, Pfunc func, void* ud, ptrdiff_t old_top, ptrdiff_t ef)
//   fan-in = 3,051 — fires constantly during gameplay
// ===========================================================================

// Re-entrancy guard: when we call lua_load or luaD_pcall from our code,
// lua_load internally calls luaD_pcall → re-enters this hook.
// We must just pass through to oLuaD_Pcall during re-entrant calls.
static thread_local bool g_inExecute = false;

static int hkLuaD_Pcall(void *L, void *func, void *ud, ptrdiff_t old_top,
                        ptrdiff_t ef) {
  // Fast path: if we're inside our own ExecuteLua/RunProbe, just call original
  if (g_inExecute) {
    static thread_local int reentryCount = 0;
    reentryCount++;
    if (reentryCount <= 3 || reentryCount % 100 == 0) {
      LOGI("[hook] re-entrant call #%d (skipping hook logic)", reentryCount);
    }
    int r = oLuaD_Pcall(L, func, ud, old_top, ef);
    if (reentryCount <= 3 || reentryCount % 100 == 0) {
      LOGI("[hook] re-entrant call #%d returned %d", reentryCount, r);
    }
    return r;
  }

  int count = pcallCount.fetch_add(1);
  if (count == 0) {
    LOGI("[hook] luaD_pcall FIRST call (L=%p func=%p ud=%p)", L, func, ud);
    g_luaState.store(L);
  } else if (count < 10 || (count < 100 && count % 10 == 0) ||
             count % 1000 == 0) {
    LOGI("[hook] luaD_pcall #%d (L=%p)", count, L);
  }

  // After warmup (~100 calls), mark as ready for injection
  if (count == 100 && !bInjected.load()) {
    bInjected.store(true);
    LOGI("[hook] warmup complete, TCP injection ENABLED (L=%p)", L);
  }

  // Call original FIRST — the Lua stack must be in a clean state
  int result = oLuaD_Pcall(L, func, ud, old_top, ef);

  // Execute queued TCP commands AFTER the original pcall completes
  if (bInjected.load()) {
    std::string cmdToRun;
    {
      std::lock_guard<std::mutex> lock(mtx);
      if (!cmdQueue.empty()) {
        cmdToRun = std::move(cmdQueue);
        cmdQueue.clear();
      }
    }
    if (!cmdToRun.empty()) {
      LOGI("[hook] executing TCP cmd (%zu bytes) on luaD_pcall #%d",
           cmdToRun.size(), count);
      // Set re-entrancy guard before calling any Lua functions
      g_inExecute = true;
      if (cmdToRun.rfind("__probe", 0) == 0) {
        RunProbe(L, cmdToRun);
      } else if (cmdToRun.rfind("__eval:", 0) == 0) {
        // __eval:expr — evaluate expression and log tostring(expr)
        std::string expr = cmdToRun.substr(7);
        ExecuteLuaReturn(L, expr, "eval");
      } else {
        ExecuteLua(L, cmdToRun, "tcp_cmd");
      }
      g_inExecute = false;
    }
  }

  return result;
}

// ===========================================================================
// No delayed inject thread needed — luaD_pcall hook auto-enables after
// warmup. The first TCP command will trigger execution.
// ===========================================================================

// ===========================================================================
// Pattern scanner for ELF .text
// ===========================================================================

struct MemRegion {
  uintptr_t base;
  size_t size;
};

static MemRegion g_gameText = {0, 0};

static int dl_callback(struct dl_phdr_info *info, size_t size, void *data) {
  if (!info->dlpi_name)
    return 0;
  if (strstr(info->dlpi_name, "libGame.so") == nullptr)
    return 0;

  LOGI("Found libGame.so at base=0x%lx name=%s", (unsigned long)info->dlpi_addr,
       info->dlpi_name);

  // Find the executable LOAD segment (PF_X = 0x1)
  for (int i = 0; i < info->dlpi_phnum; i++) {
    if (info->dlpi_phdr[i].p_type == PT_LOAD &&
        (info->dlpi_phdr[i].p_flags & PF_X)) {
      MemRegion *region = (MemRegion *)data;
      region->base = info->dlpi_addr + info->dlpi_phdr[i].p_vaddr;
      region->size = info->dlpi_phdr[i].p_memsz;
      LOGI("  .text segment: base=0x%lx size=0x%lx (%.1f MB)",
           (unsigned long)region->base, (unsigned long)region->size,
           region->size / 1048576.0);
      break;
    }
  }
  return 1; // stop iteration
}

static uintptr_t PatternScan(const SigEntry *sig, MemRegion *region) {
  const uint8_t *base = (const uint8_t *)region->base;
  size_t scanLen = region->size - sig->length;

  for (size_t i = 0; i < scanLen; i++) {
    bool found = true;
    for (size_t j = 0; j < sig->length; j++) {
      if (sig->mask[j] == 0x00)
        continue; // wildcard
      if (base[i + j] != sig->pattern[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      LOGI("  [%s] matched at 0x%lx (offset +0x%lx)", sig->name,
           (unsigned long)(region->base + i), (unsigned long)i);
      return region->base + i;
    }
  }
  return 0;
}

static uintptr_t ScanForFunction(const SigEntry *sigs, size_t count,
                                 MemRegion *region, const char *funcName) {
  for (size_t i = 0; i < count; i++) {
    uintptr_t result = PatternScan(&sigs[i], region);
    if (result) {
      LOGI("Found %s via sig '%s' at 0x%lx", funcName, sigs[i].name,
           (unsigned long)result);
      return result;
    }
  }
  LOGE("FAILED to find %s (tried %zu signatures)", funcName, count);
  return 0;
}

// ===========================================================================
// TCP command server (replaces Windows named pipe)
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
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); // 127.0.0.1 only
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
    // Use select() with timeout so we can check g_tcpRunning
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(server_fd, &fds);
    struct timeval tv = {1, 0}; // 1 second timeout

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
      if (content.size() > 4 && content.substr(content.size() - 4) == ".lua") {
        cmd = "local f, err = loadfile([[" + content +
              "]])\n"
              "if f then\n"
              "  local ok, rerr = pcall(f)\n"
              "  if not ok then print('[gate] exec error: '"
              " .. tostring(rerr)) end\n"
              "else\n"
              "  print('[gate] load error: ' .. tostring(err))\n"
              "end";
      } else {
        cmd = content;
      }

      LOGI("[TCP] received %zd bytes", total);
      {
        std::lock_guard<std::mutex> lock(mtx);
        cmdQueue = cmd;
      }

      // Send ack
      const char *ack = "OK";
      write(client_fd, ack, 2);
    }

    close(client_fd);
  }

  close(server_fd);
  LOGI("[TCP] server stopped");
  return nullptr;
}

// ===========================================================================
// /proc/self/maps parser — fallback when dl_iterate_phdr can't find the lib
// (happens when we're loaded as DT_NEEDED of the target lib itself)
// ===========================================================================

static bool find_lib_in_maps(const char *libname, MemRegion *region) {
  FILE *fp = fopen("/proc/self/maps", "r");
  if (!fp)
    return false;

  char line[1024];
  uintptr_t first_rx_start = 0;
  uintptr_t first_rx_end = 0;

  while (fgets(line, sizeof(line), fp)) {
    if (strstr(line, libname) == nullptr)
      continue;
    if (strstr(line, "r-xp") == nullptr && strstr(line, "r--p") == nullptr)
      continue;

    uintptr_t start, end;
    if (sscanf(line, "%lx-%lx", &start, &end) != 2)
      continue;

    // We want r-xp (executable) segments
    if (strstr(line, "r-xp")) {
      if (first_rx_start == 0) {
        first_rx_start = start;
        first_rx_end = end;
      } else {
        // Extend to cover contiguous executable regions
        if (start <= first_rx_end + 0x1000) {
          first_rx_end = end;
        }
      }
    }
  }
  fclose(fp);

  if (first_rx_start != 0) {
    region->base = first_rx_start;
    region->size = first_rx_end - first_rx_start;
    LOGI("[maps] Found %s: base=0x%lx size=0x%lx (%.1f MB)", libname,
         (unsigned long)region->base, (unsigned long)region->size,
         region->size / 1048576.0);
    return true;
  }
  return false;
}

// ===========================================================================
// Background init thread — polls until libGame.so is loaded, then hooks
// ===========================================================================

static void *InitThread(void * /*arg*/) {
  LOGI("[init] Waiting for libGame.so to load...");

  // Poll every 500ms for up to 120 seconds
  for (int i = 0; i < 240; ++i) {
    // Try dl_iterate_phdr first (works when loaded via a different lib)
    dl_iterate_phdr(dl_callback, &g_gameText);
    if (g_gameText.base != 0 && g_gameText.size != 0)
      break;
    g_gameText.base = 0;
    g_gameText.size = 0;
    usleep(500 * 1000);
  }

  if (g_gameText.base == 0 || g_gameText.size == 0) {
    LOGE("[init] Timed out waiting for libGame.so (120s)");
    return nullptr;
  }
  LOGI("[init] libGame.so found, scanning for signatures...");

  // --- Scan for all 3 required functions ---

  // 1. lua_load (confirmed at offset 0x31B2DE8)
  uintptr_t luaLoadAddr = ScanForFunction(LUA_LOAD_SIGS, LUA_LOAD_SIG_COUNT,
                                          &g_gameText, "lua_load");

  // 2. luaD_pcall (confirmed at offset 0x319E750, fan-in=3051)
  //    First entry in LUA_PCALL_SIGS is "luaD_pcall"
  uintptr_t luaDPcallAddr = PatternScan(&LUA_PCALL_SIGS[0], &g_gameText);
  if (luaDPcallAddr) {
    LOGI("Found luaD_pcall via sig at 0x%lx (offset +0x%lx)",
         (unsigned long)luaDPcallAddr,
         (unsigned long)(luaDPcallAddr - g_gameText.base));
  }

  // 3. luaD_call (confirmed at offset 0x3195D4C)
  //    Third entry in LUA_PCALL_SIGS is "luaD_call"
  uintptr_t luaDCallAddr = 0;
  for (size_t i = 0; i < LUA_PCALL_SIG_COUNT; i++) {
    if (strcmp(LUA_PCALL_SIGS[i].name, "luaD_call") == 0) {
      luaDCallAddr = PatternScan(&LUA_PCALL_SIGS[i], &g_gameText);
      if (luaDCallAddr) {
        LOGI("Found luaD_call via sig at 0x%lx (offset +0x%lx)",
             (unsigned long)luaDCallAddr,
             (unsigned long)(luaDCallAddr - g_gameText.base));
      }
      break;
    }
  }

  // Also log luaD_rawrunprotected for reference (not hooked)
  for (size_t i = 0; i < LUA_PCALL_SIG_COUNT; i++) {
    if (strcmp(LUA_PCALL_SIGS[i].name, "luaD_rawrunprotected") == 0) {
      uintptr_t addr = PatternScan(&LUA_PCALL_SIGS[i], &g_gameText);
      if (addr) {
        LOGI("Found luaD_rawrunprotected at 0x%lx (offset +0x%lx) [not hooked]",
             (unsigned long)addr, (unsigned long)(addr - g_gameText.base));
      }
      break;
    }
  }

  // --- Validate ---
  if (!luaLoadAddr || !luaDPcallAddr || !luaDCallAddr) {
    LOGE("[init] Signature scan FAILED (load=0x%lx, dpcall=0x%lx, dcall=0x%lx)",
         (unsigned long)luaLoadAddr, (unsigned long)luaDPcallAddr,
         (unsigned long)luaDCallAddr);
    // Start TCP server anyway for diagnostics
    g_tcpRunning.store(true);
    pthread_t tid;
    pthread_create(&tid, nullptr, TcpServerThread, nullptr);
    pthread_detach(tid);
    LOGI("[init] TCP server started (hook-less mode) on port %d", TCP_PORT);
    return nullptr;
  }

  // --- Store function pointers ---
  oLua_Load = (tLua_Load)luaLoadAddr;
  pLuaD_Call = (tLuaD_Call)luaDCallAddr;

  // --- Install luaD_pcall hook ---
  int ret = DobbyHook((void *)luaDPcallAddr, (void *)hkLuaD_Pcall,
                      (void **)&oLuaD_Pcall);
  if (ret == 0) {
    LOGI("[init] luaD_pcall hook installed at 0x%lx",
         (unsigned long)luaDPcallAddr);
  } else {
    LOGE("[init] luaD_pcall hook FAILED: %d", ret);
  }

  LOGI("[init] Hook installed. lua_load=0x%lx luaD_pcall=0x%lx luaD_call=0x%lx",
       (unsigned long)luaLoadAddr, (unsigned long)luaDPcallAddr,
       (unsigned long)luaDCallAddr);

  // Start TCP command server
  g_tcpRunning.store(true);
  pthread_t tid;
  pthread_create(&tid, nullptr, TcpServerThread, nullptr);
  pthread_detach(tid);

  LOGI("[init] TCP server started on port %d. Ready.", TCP_PORT);
  return nullptr;
}

// ===========================================================================
// Entry point — __attribute__((constructor))
// Called by the dynamic linker when libinject.so is loaded as a DT_NEEDED
// dependency of a game native library.
// No JNI_OnLoad needed — we don't go through System.loadLibrary.
// ===========================================================================

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
  LOGI("=== JNI_OnLoad: inject library loaded ===");
  g_javaVM = vm;

  // Patch JNI function table to auto-clear pending exceptions.
  // This prevents ART's AssertNoPendingException from aborting when
  // libunisec.so does JNI calls after Firebase fails during init.
  JNIEnv *env = nullptr;
  if (vm->GetEnv((void **)&env, JNI_VERSION_1_6) == JNI_OK && env) {
    InstallJniExceptionGuard(env);
  } else {
    LOGE("[bypass] could not get JNIEnv — JNI guard not installed");
  }

  // Install DNS blocking hook
  InstallBypassHooks();

  // Spawn background thread to wait for libGame.so and install hooks
  pthread_t initTid;
  pthread_create(&initTid, nullptr, InitThread, nullptr);
  pthread_detach(initTid);

  LOGI("Init thread spawned, returning to linker");
}
