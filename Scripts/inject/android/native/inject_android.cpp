// inject_android.cpp — ARM64 Lua hook library for Android
// Loaded as ELF DT_NEEDED dependency via patched native .so
// Uses Dobby for inline hooking (replaces MinHook)

#include <jni.h>
#include <android/log.h>
#include <dlfcn.h>
#include <link.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <pthread.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <atomic>
#include <mutex>
#include <string>
#include <vector>

#include "dobby.h"
#include "sig_config.h"

#define TAG "WWM_INJECT"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// ===========================================================================
// Lua function types (ARM64 calling convention — same signature as x86_64)
// ===========================================================================

typedef int (*tLua_Load)(void* L, void* reader, void* dt,
                         const char* chunkname, const char* mode);
typedef int (*tLua_Pcall)(void* L, int nargs, int nresults,
                          int errfunc, void* k, void* ctx);

static tLua_Load  oLua_Load  = nullptr;
static tLua_Pcall oLua_Pcall = nullptr;

static std::atomic<bool> bFirstInject{true};
static std::string       cmdQueue;
static std::mutex         mtx;

// ===========================================================================
// Lua reader callback (same as Windows version)
// ===========================================================================

struct ReaderData { const char* s; size_t size; };

static const char* MyLuaReader(void* L, void* ud, size_t* sz) {
    ReaderData* d = (ReaderData*)ud;
    if (d->size == 0) { *sz = 0; return nullptr; }
    *sz = d->size; d->size = 0; return d->s;
}

// Pop one value from Lua stack without lua_settop
static void LuaPopOne(void* L) {
    static const char noop[] = "do end";
    ReaderData rd = { noop, sizeof(noop) - 1 };
    int rc = oLua_Load(L, (void*)MyLuaReader, &rd, "=_pop", "t");
    if (rc == 0) oLua_Pcall(L, 1, 0, 0, nullptr, nullptr);
}

// ===========================================================================
// Execute Lua code string via lua_load + lua_pcall
// ===========================================================================

static bool ExecuteLua(void* L, const std::string& code, const char* label) {
    ReaderData data = { code.c_str(), code.length() };

    int loadRc = oLua_Load(L, (void*)MyLuaReader, &data, "=@inject", "t");
    if (loadRc != 0) {
        LOGE("[%s] lua_load FAILED: rc=%d", label, loadRc);
        LuaPopOne(L);
        return false;
    }

    int pcallRc = oLua_Pcall(L, 0, 0, 0, nullptr, nullptr);
    if (pcallRc != 0) {
        LOGE("[%s] lua_pcall FAILED: rc=%d", label, pcallRc);
        LuaPopOne(L);
        return false;
    }

    LOGI("[%s] executed OK", label);
    return true;
}

// ===========================================================================
// Hook: lua_pcall
// ===========================================================================

static int hkLua_Pcall(void* L, int nargs, int nresults,
                       int errfunc, void* k, void* ctx) {
    // First-time auto-inject
    if (bFirstInject.exchange(false)) {
        // Try external path first, then bundled assets
        std::string payload =
            "local paths = {\n"
            "  '/sdcard/Android/data/com.netease.yysls/files/Scripts/Test.lua',\n"
            "  '/storage/emulated/0/Android/data/com.netease.yysls/files/Scripts/Test.lua',\n"
            "}\n"
            "for _, p in ipairs(paths) do\n"
            "  local f = io.open(p, 'r')\n"
            "  if f then\n"
            "    f:close()\n"
            "    local fn, err = loadfile(p)\n"
            "    if fn then pcall(fn) end\n"
            "    break\n"
            "  end\n"
            "end\n";
        ExecuteLua(L, payload, "auto_inject");
    }

    // Check TCP command queue
    std::string cmdToRun;
    {
        std::lock_guard<std::mutex> lock(mtx);
        if (!cmdQueue.empty()) {
            cmdToRun = std::move(cmdQueue);
            cmdQueue.clear();
        }
    }
    if (!cmdToRun.empty()) {
        ExecuteLua(L, cmdToRun, "tcp_cmd");
    }

    return oLua_Pcall(L, nargs, nresults, errfunc, k, ctx);
}

// ===========================================================================
// Pattern scanner for ELF .text
// ===========================================================================

struct MemRegion {
    uintptr_t base;
    size_t    size;
};

static MemRegion g_gameText = {0, 0};

static int dl_callback(struct dl_phdr_info* info, size_t size, void* data) {
    if (!info->dlpi_name) return 0;
    if (strstr(info->dlpi_name, "libGame.so") == nullptr) return 0;

    LOGI("Found libGame.so at base=0x%lx name=%s",
         (unsigned long)info->dlpi_addr, info->dlpi_name);

    // Find the executable LOAD segment (PF_X = 0x1)
    for (int i = 0; i < info->dlpi_phnum; i++) {
        if (info->dlpi_phdr[i].p_type == PT_LOAD &&
            (info->dlpi_phdr[i].p_flags & PF_X)) {
            MemRegion* region = (MemRegion*)data;
            region->base = info->dlpi_addr + info->dlpi_phdr[i].p_vaddr;
            region->size = info->dlpi_phdr[i].p_memsz;
            LOGI("  .text segment: base=0x%lx size=0x%lx (%.1f MB)",
                 (unsigned long)region->base,
                 (unsigned long)region->size,
                 region->size / 1048576.0);
            break;
        }
    }
    return 1;  // stop iteration
}

static uintptr_t PatternScan(const SigEntry* sig, MemRegion* region) {
    const uint8_t* base = (const uint8_t*)region->base;
    size_t scanLen = region->size - sig->length;

    for (size_t i = 0; i < scanLen; i++) {
        bool found = true;
        for (size_t j = 0; j < sig->length; j++) {
            if (sig->mask[j] == 0x00) continue;  // wildcard
            if (base[i + j] != sig->pattern[j]) {
                found = false;
                break;
            }
        }
        if (found) {
            LOGI("  [%s] matched at 0x%lx (offset +0x%lx)",
                 sig->name, (unsigned long)(region->base + i), (unsigned long)i);
            return region->base + i;
        }
    }
    return 0;
}

static uintptr_t ScanForFunction(const SigEntry* sigs, size_t count,
                                 MemRegion* region, const char* funcName) {
    for (size_t i = 0; i < count; i++) {
        uintptr_t result = PatternScan(&sigs[i], region);
        if (result) {
            LOGI("Found %s via sig '%s' at 0x%lx",
                 funcName, sigs[i].name, (unsigned long)result);
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

static void* TcpServerThread(void*) {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        LOGE("[TCP] socket() failed: %s", strerror(errno));
        return nullptr;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);  // 127.0.0.1 only
    addr.sin_port = htons(TCP_PORT);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
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
        struct timeval tv = {1, 0};  // 1 second timeout

        int sel = select(server_fd + 1, &fds, nullptr, nullptr, &tv);
        if (sel <= 0) continue;

        int client_fd = accept(server_fd, nullptr, nullptr);
        if (client_fd < 0) continue;

        // Read command (up to 64KB)
        char buf[65536] = {};
        ssize_t total = 0;
        while (total < (ssize_t)sizeof(buf) - 1) {
            ssize_t n = read(client_fd, buf + total, sizeof(buf) - 1 - total);
            if (n <= 0) break;
            total += n;
        }
        buf[total] = '\0';

        // Trim trailing whitespace
        while (total > 0 && (buf[total-1] == '\n' || buf[total-1] == '\r' ||
                             buf[total-1] == ' '))
            buf[--total] = '\0';

        if (total > 0) {
            std::string content(buf, total);
            std::string cmd;

            // If it ends with .lua, wrap in loadfile+pcall
            if (content.size() > 4 &&
                content.substr(content.size() - 4) == ".lua") {
                cmd = "local f, err = loadfile([[" + content + "]])\n"
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
            const char* ack = "OK";
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

static bool find_lib_in_maps(const char* libname, MemRegion* region) {
    FILE* fp = fopen("/proc/self/maps", "r");
    if (!fp) return false;

    char line[1024];
    uintptr_t first_rx_start = 0;
    uintptr_t first_rx_end = 0;

    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, libname) == nullptr) continue;
        if (strstr(line, "r-xp") == nullptr && strstr(line, "r--p") == nullptr) continue;

        uintptr_t start, end;
        if (sscanf(line, "%lx-%lx", &start, &end) != 2) continue;

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
        LOGI("[maps] Found %s: base=0x%lx size=0x%lx (%.1f MB)",
             libname, (unsigned long)region->base,
             (unsigned long)region->size, region->size / 1048576.0);
        return true;
    }
    return false;
}

// ===========================================================================
// Background init thread — polls until libGame.so is loaded, then hooks
// ===========================================================================

static void* InitThread(void* /*arg*/) {
    LOGI("[init] Waiting for libGame.so to load...");

    // Poll every 500ms for up to 120 seconds
    for (int i = 0; i < 240; ++i) {
        // Try dl_iterate_phdr first (works when loaded via a different lib)
        dl_iterate_phdr(dl_callback, &g_gameText);
        if (g_gameText.base != 0 && g_gameText.size != 0)
            break;

        // Fallback: parse /proc/self/maps (works when loaded as DT_NEEDED
        // of libGame.so itself — dl_iterate_phdr can't see it yet)
        if (find_lib_in_maps("libGame.so", &g_gameText))
            break;

        // Reset for next attempt
        g_gameText.base = 0;
        g_gameText.size = 0;
        usleep(500 * 1000);  // 500ms
    }

    if (g_gameText.base == 0 || g_gameText.size == 0) {
        LOGE("[init] Timed out waiting for libGame.so (120s)");
        return nullptr;
    }
    LOGI("[init] libGame.so found, scanning for signatures...");

    // Pattern scan for lua_load
    uintptr_t luaLoadAddr = ScanForFunction(
        LUA_LOAD_SIGS, LUA_LOAD_SIG_COUNT, &g_gameText, "lua_load");

    // Pattern scan for lua_pcall
    uintptr_t luaPcallAddr = ScanForFunction(
        LUA_PCALL_SIGS, LUA_PCALL_SIG_COUNT, &g_gameText, "lua_pcall");

    if (!luaLoadAddr || !luaPcallAddr) {
        LOGE("[init] Signature scan failed (load=0x%lx, pcall=0x%lx)",
             (unsigned long)luaLoadAddr, (unsigned long)luaPcallAddr);
        return nullptr;
    }

    oLua_Load = (tLua_Load)luaLoadAddr;

    // Install Dobby hook on lua_pcall
    int ret = DobbyHook(
        (void*)luaPcallAddr,
        (void*)hkLua_Pcall,
        (void**)&oLua_Pcall
    );
    if (ret != 0) {
        LOGE("[init] DobbyHook failed: %d", ret);
        return nullptr;
    }
    LOGI("[init] Hook installed. lua_load=0x%lx, lua_pcall=0x%lx",
         (unsigned long)luaLoadAddr, (unsigned long)luaPcallAddr);

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

__attribute__((constructor))
static void inject_init() {
    LOGI("=== inject_init: library loaded via ELF dependency ===");

    // Spawn background thread to wait for libGame.so and install hooks
    pthread_t initTid;
    pthread_create(&initTid, nullptr, InitThread, nullptr);
    pthread_detach(initTid);

    LOGI("Init thread spawned, returning to linker");
}
