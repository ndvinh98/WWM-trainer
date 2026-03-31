#define _CRT_SECURE_NO_WARNINGS
#include <Windows.h>
#include <vector>
#include <string>
#include <mutex>
#include <random>
#include <atomic>
#include <MinHook.h>
#include <cstdio>

// =================================================================================
// Polymorphic String Obfuscation
// =================================================================================

template <size_t N>
struct ObfuscatedString {
private:
    char m_obfuscated[N];
    mutable char m_decrypted[N];
    mutable bool m_decryptedFlag;
    uint32_t m_seed;

    constexpr uint32_t compileTimeSeed(const char* str, size_t index = 0) {
        return (index >= N) ? 2166136261u :
            (compileTimeSeed(str, index + 1) * 16777619u) ^ static_cast<uint32_t>(str[index]);
    }

    constexpr char xorChar(char c, size_t i, uint32_t seed) const {
        return c ^ static_cast<char>(((seed * (i + 1)) ^ (seed >> ((i % 4) * 8))) % 256);
    }

public:
    constexpr ObfuscatedString(const char* str)
        : m_obfuscated{}, m_decrypted{}, m_decryptedFlag(false),
        m_seed(compileTimeSeed(str)) {
        for (size_t i = 0; i < N; ++i) {
            m_obfuscated[i] = xorChar(str[i], i, m_seed);
        }
    }

    const char* decrypt() const {
        if (!m_decryptedFlag) {
            for (size_t i = 0; i < N; ++i) {
                m_decrypted[i] = xorChar(m_obfuscated[i], i, m_seed);
            }
            m_decryptedFlag = true;
        }
        return m_decrypted;
    }

    void wipe() const {
        if (m_decryptedFlag) {
            SecureZeroMemory(m_decrypted, N);
            m_decryptedFlag = false;
        }
    }

    std::string get() const {
        const char* dec = decrypt();
        std::string result(dec, N - 1);
        return result;
    }

    std::string getAndWipe() const {
        std::string result = get();
        wipe();
        return result;
    }
};

#define OBFUSCATE_IMPL(str, size) ObfuscatedString<size>(str)
#define OBFUSCATE(str) OBFUSCATE_IMPL(str, sizeof(str))

// =================================================================================
// File Logger
// =================================================================================

class FileLogger {
    std::mutex m_mtx;
    std::string m_path;

public:
    void init(const std::string& path) {
        m_path = path;
        FILE* f = fopen(m_path.c_str(), "w");
        if (f) {
            SYSTEMTIME st;
            GetLocalTime(&st);
            fprintf(f, "[%04d-%02d-%02d %02d:%02d:%02d] === Inject session started ===\n",
                st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
            fclose(f);
        }
    }

    void log(const char* fmt, ...) {
        if (m_path.empty()) return;
        std::lock_guard<std::mutex> lock(m_mtx);
        FILE* f = fopen(m_path.c_str(), "a");
        if (!f) return;

        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);

        va_list args;
        va_start(args, fmt);
        vfprintf(f, fmt, args);
        va_end(args);

        fprintf(f, "\n");
        fclose(f);
    }
};

static FileLogger g_log;

// =================================================================================
// Lua Payload
// =================================================================================

struct LuaPayloadFragments {
    static std::string build() {
        constexpr auto fragment1 = OBFUSCATE("local path = [[F:\\Coding\\Where Winds Meet\\Scripts\\Test.lua]]");
        constexpr auto fragment2 = OBFUSCATE("local f, err = loadfile(path)");
        constexpr auto fragment3 = OBFUSCATE("if f then pcall(f) end");

        std::string payload;
        payload = fragment1.getAndWipe() + "\n" +
            fragment2.getAndWipe() + "\n" +
            fragment3.getAndWipe();
        return payload;
    }
};

// =================================================================================
// Hook Types & Globals
// =================================================================================

typedef int(__fastcall* tLua_Load)(void* L, void* reader, void* dt, const char* chunkname, const char* mode);
typedef int(__fastcall* tLua_Pcall)(void* L, int nargs, int nresults, int errfunc, void* k, void* ctx);
typedef void(__fastcall* tLua_Settop)(void* L, int index);

tLua_Load oLua_Load = nullptr;
tLua_Pcall oLua_Pcall = nullptr;

std::atomic<bool> bInjectPayload{ false };
std::string cmdQueue;
std::mutex mtx;

// =================================================================================
// Lua Reader Callback
// =================================================================================

struct ReaderData { const char* s; size_t size; };

const char* __fastcall MyLuaReader(void* L, void* ud, size_t* size) {
    ReaderData* data = (ReaderData*)ud;
    if (data->size == 0) { *size = 0; return nullptr; }
    *size = data->size; data->size = 0; return data->s;
}

// =================================================================================
// Dynamic Chunk Names
// =================================================================================

std::string getDynamicChunkName() {
    constexpr auto prefix = OBFUSCATE("@");
    static std::random_device rd;
    static std::mt19937 gen(rd());
    std::uniform_int_distribution<> dist(0, 3);

    std::string result = prefix.getAndWipe();
    switch (dist(gen)) {
    case 0: { constexpr auto n = OBFUSCATE("SysInit");      result += n.getAndWipe(); break; }
    case 1: { constexpr auto n = OBFUSCATE("GameScript");   result += n.getAndWipe(); break; }
    case 2: { constexpr auto n = OBFUSCATE("UserCode");     result += n.getAndWipe(); break; }
    case 3: { constexpr auto n = OBFUSCATE("RuntimeChunk"); result += n.getAndWipe(); break; }
    }
    return result;
}

// =================================================================================
// Execute Lua code via lua_load + lua_pcall, with logging
// =================================================================================

// Pop one item from the Lua stack without needing lua_settop.
// Loads a no-op chunk and calls it with nargs=1, which pops both
// the loaded function and the top stack item (the one we want gone).
static void LuaPopOne(void* L) {
    static const char noop[] = "do end";
    ReaderData rd = { noop, sizeof(noop) - 1 };
    int rc = oLua_Load(L, &MyLuaReader, &rd, "=_pop", "t");
    if (rc == 0) {
        oLua_Pcall(L, 1, 0, 0, nullptr, nullptr);
    }
}

static const char* LuaRetCodeStr(int rc) {
    switch (rc) {
    case 0: return "OK";
    case 1: return "YIELD";
    case 2: return "ERRRUN";
    case 3: return "ERRSYNTAX";
    case 4: return "ERRMEM";
    case 5: return "ERRGCMM";
    case 6: return "ERRERR";
    default: return "UNKNOWN";
    }
}

static bool ExecuteLua(void* L, const std::string& code, const char* label) {
    ReaderData data = { code.c_str(), code.length() };
    std::string chunkname = getDynamicChunkName();
    constexpr auto mode = OBFUSCATE("t");
    std::string modeStr = mode.getAndWipe();

    int loadRc = oLua_Load(L, &MyLuaReader, &data, chunkname.c_str(), modeStr.c_str());
    if (loadRc != 0) {
        g_log.log("[%s] lua_load FAILED: rc=%d (%s)", label, loadRc, LuaRetCodeStr(loadRc));
        LuaPopOne(L);  // Pop error message to keep stack balanced
        return false;
    }

    int pcallRc = oLua_Pcall(L, 0, 0, 0, nullptr, nullptr);
    if (pcallRc != 0) {
        g_log.log("[%s] lua_pcall FAILED: rc=%d (%s)", label, pcallRc, LuaRetCodeStr(pcallRc));
        LuaPopOne(L);  // Pop error message to keep stack balanced
        return false;
    }

    g_log.log("[%s] executed successfully", label);
    return true;
}

// =================================================================================
// Hook: lua_pcall
// =================================================================================

int __fastcall hkLua_Pcall(void* L, int nargs, int nresults, int errfunc, void* k, void* ctx) {
    if (bInjectPayload.exchange(false)) {
        std::string payload = LuaPayloadFragments::build();
        ExecuteLua(L, payload, "F3_inject");
        SecureZeroMemory(&payload[0], payload.size());
    }
    else {
        std::string cmdToRun;
        {
            std::lock_guard<std::mutex> lock(mtx);
            if (!cmdQueue.empty()) {
                cmdToRun = std::move(cmdQueue);
                cmdQueue.clear();
            }
        }

        if (!cmdToRun.empty()) {
            ExecuteLua(L, cmdToRun, "command");
            SecureZeroMemory(&cmdToRun[0], cmdToRun.size());
        }
    }

    return oLua_Pcall(L, nargs, nresults, errfunc, k, ctx);
}

// =================================================================================
// Pattern Scanner
// =================================================================================

uintptr_t PatternScan(const char* signature) {
    auto dos = (PIMAGE_DOS_HEADER)GetModuleHandleA(nullptr);
    if (!dos) return 0;
    auto nt = (PIMAGE_NT_HEADERS)((std::uint8_t*)dos + dos->e_lfanew);
    auto size = nt->OptionalHeader.SizeOfImage;
    auto bytes = reinterpret_cast<std::uint8_t*>(dos);

    std::vector<int> pattern;
    const char* cur = signature;
    while (*cur) {
        if (*cur == ' ') { cur++; continue; }
        if (*cur == '?') { pattern.push_back(-1); cur++; if (*cur == '?') cur++; }
        else { pattern.push_back(strtoul(cur, (char**)&cur, 16)); }
    }

    for (size_t i = 0; i < size - pattern.size(); ++i) {
        bool found = true;
        for (size_t j = 0; j < pattern.size(); ++j) {
            if (bytes[i + j] != pattern[j] && pattern[j] != -1) {
                found = false;
                break;
            }
        }
        if (found) return (uintptr_t)&bytes[i];
    }
    return 0;
}

// =================================================================================
// Send Command (exported for external use)
// =================================================================================

extern "C" __declspec(dllexport)
void SendCommand(const char* cmd) {
    std::lock_guard<std::mutex> lock(mtx);
    cmdQueue = cmd;
    g_log.log("[SendCommand] queued %zu bytes", strlen(cmd));
}

// =================================================================================
// Named Pipe Server — accepts commands from mylua.exe
// =================================================================================

static std::atomic<bool> g_pipeRunning{ false };

static DWORD WINAPI PipeServerThread(LPVOID) {
    const char* pipeName = "\\\\.\\pipe\\wwm_lua_gate";
    g_log.log("[Pipe] starting server on %s", pipeName);

    while (g_pipeRunning.load()) {
        HANDLE hPipe = CreateNamedPipeA(
            pipeName,
            PIPE_ACCESS_DUPLEX,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            1, 65536, 65536, 100, nullptr);

        if (hPipe == INVALID_HANDLE_VALUE) {
            g_log.log("[Pipe] CreateNamedPipe failed: %d", GetLastError());
            Sleep(1000);
            continue;
        }

        // Wait for client with a timeout so we can check g_pipeRunning
        OVERLAPPED ov = {};
        ov.hEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
        ConnectNamedPipe(hPipe, &ov);

        while (g_pipeRunning.load()) {
            DWORD waitResult = WaitForSingleObject(ov.hEvent, 500);
            if (waitResult == WAIT_OBJECT_0) break;
        }
        CloseHandle(ov.hEvent);

        if (!g_pipeRunning.load()) {
            CloseHandle(hPipe);
            break;
        }

        // Read command
        char buf[65536] = {};
        DWORD bytesRead = 0;
        if (ReadFile(hPipe, buf, sizeof(buf) - 1, &bytesRead, nullptr) && bytesRead > 0) {
            buf[bytesRead] = '\0';

            // Trim trailing whitespace
            while (bytesRead > 0 && (buf[bytesRead - 1] == '\n' || buf[bytesRead - 1] == '\r' || buf[bytesRead - 1] == ' '))
                buf[--bytesRead] = '\0';

            std::string content(buf);
            std::string cmd;

            // If it ends with .lua, wrap in loadfile+pcall
            if (content.size() > 4 && content.substr(content.size() - 4) == ".lua") {
                cmd = "local f, err = loadfile([[" + content + "]])\n"
                      "if f then\n"
                      "  local ok, rerr = pcall(f)\n"
                      "  if not ok then print('[gate] exec error: ' .. tostring(rerr)) end\n"
                      "else\n"
                      "  print('[gate] load error: ' .. tostring(err))\n"
                      "end";
            } else {
                cmd = content;
            }

            g_log.log("[Pipe] received: %s", content.c_str());
            {
                std::lock_guard<std::mutex> lock(mtx);
                cmdQueue = cmd;
            }

            // Send ack
            const char* ack = "OK";
            DWORD written = 0;
            WriteFile(hPipe, ack, 2, &written, nullptr);
        }

        FlushFileBuffers(hPipe);
        DisconnectNamedPipe(hPipe);
        CloseHandle(hPipe);
    }

    g_log.log("[Pipe] server stopped");
    return 0;
}

// =================================================================================
// Hide DLL from PEB (all 3 loader lists)
// =================================================================================

static void UnlinkFromList(uintptr_t listHead, HMODULE hModule, ptrdiff_t dllBaseOffset) {
    uintptr_t head = listHead;
    uintptr_t current = *reinterpret_cast<uintptr_t*>(head);

    while (current != head) {
        uintptr_t dllBase = *reinterpret_cast<uintptr_t*>(current + dllBaseOffset);
        if (reinterpret_cast<HMODULE>(dllBase) == hModule) {
            uintptr_t flink = *reinterpret_cast<uintptr_t*>(current);
            uintptr_t blink = *reinterpret_cast<uintptr_t*>(current + 0x8);
            *reinterpret_cast<uintptr_t*>(blink) = flink;
            *reinterpret_cast<uintptr_t*>(flink + 0x8) = blink;
            break;
        }
        current = *reinterpret_cast<uintptr_t*>(current);
    }
}

void HideDllFromPEB(HMODULE hModule) {
#ifdef _WIN64
    uintptr_t pPeb = __readgsqword(0x60);
#else
    uintptr_t pPeb = __readfsdword(0x30);
#endif
    uintptr_t pLdr = *reinterpret_cast<uintptr_t*>(pPeb + 0x18);

    // Existing code used InMemoryOrderModuleList (Ldr+0x20) with DllBase at link+0x30.
    // InMemoryOrderLinks sits at struct offset 0x10, so DllBase is at struct offset 0x40.
    // Derive offsets for the other two lists accordingly:
    //   InLoadOrderLinks        at struct+0x00 → DllBase = link + 0x40
    //   InMemoryOrderLinks      at struct+0x10 → DllBase = link + 0x30
    //   InInitializationOrderLinks at struct+0x20 → DllBase = link + 0x20
    UnlinkFromList(pLdr + 0x10, hModule, 0x40);  // InLoadOrderModuleList
    UnlinkFromList(pLdr + 0x20, hModule, 0x30);  // InMemoryOrderModuleList
    UnlinkFromList(pLdr + 0x30, hModule, 0x20);  // InInitializationOrderModuleList
}

// =================================================================================
// Wait for the unpacker to finish populating .text
// =================================================================================

static bool WaitForUnpacker(int timeoutMs = 15000, int pollMs = 200) {
    auto base = reinterpret_cast<std::uint8_t*>(GetModuleHandleA(nullptr));
    if (!base) return false;

    auto dos = (PIMAGE_DOS_HEADER)base;
    auto nt = (PIMAGE_NT_HEADERS)(base + dos->e_lfanew);
    auto sec = IMAGE_FIRST_SECTION(nt);

    // Find .text section
    PIMAGE_SECTION_HEADER textSec = nullptr;
    for (WORD i = 0; i < nt->FileHeader.NumberOfSections; ++i) {
        if (sec[i].Characteristics & IMAGE_SCN_MEM_EXECUTE) {
            textSec = &sec[i];
            break;
        }
    }
    if (!textSec) return false;

    auto textStart = base + textSec->VirtualAddress;
    auto textSize = textSec->Misc.VirtualSize;
    if (textSize < 64) return false;

    // Poll until .text contains non-zero code (unpacker has written to it)
    int elapsed = 0;
    while (elapsed < timeoutMs) {
        // Check multiple spots in .text for non-zero bytes
        bool hasCode = false;
        for (size_t off = 0; off < textSize && off < 0x100000; off += 0x1000) {
            DWORD val = *reinterpret_cast<DWORD*>(textStart + off);
            if (val != 0) { hasCode = true; break; }
        }
        if (hasCode) {
            g_log.log("Unpacker ready after %d ms", elapsed);
            return true;
        }
        Sleep(pollMs);
        elapsed += pollMs;
    }

    g_log.log("WARNING: unpacker timeout after %d ms", timeoutMs);
    return false;
}

// =================================================================================
// Main Thread
// =================================================================================

DWORD WINAPI MainThread(LPVOID lpReserved) {
    HMODULE hModule = (HMODULE)lpReserved;

    // Init logger
    {
        constexpr auto logPath = OBFUSCATE("F:\\Coding\\Where Winds Meet\\Scripts\\logs\\inject_log.txt");
        g_log.init(logPath.getAndWipe());
    }

    g_log.log("DLL loaded at 0x%p, hiding from PEB...", hModule);
    HideDllFromPEB(hModule);
    g_log.log("PEB unlink done (all 3 lists)");

    // Wait for unpacker to populate .text before scanning
    g_log.log("Waiting for .text unpacker...");
    if (!WaitForUnpacker()) {
        g_log.log("FATAL: .text section not populated, aborting");
        ExitThread(0);
        return 0;
    }

    // Scan signatures
    constexpr auto sig1_obj = OBFUSCATE("48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 48 83 EC 50 48 8B E9 49 8B F1");
    constexpr auto sig2_obj = OBFUSCATE("48 89 5C 24 10 56 48 83 EC 50 49 8B D9 48 8B F1 4D 8B C8 4C 8B C2 48 8D 54 24");
    constexpr auto sig3_obj = OBFUSCATE("48 89 74 24 18 57 48 83 EC 40 33 F6 48 89 6C 24 58 49 63 C1 41 8B E8 48 8B F9 45 85 C9");

    std::string sig1_str = sig1_obj.getAndWipe();
    std::string sig2_str = sig2_obj.getAndWipe();
    std::string sig3_str = sig3_obj.getAndWipe();

    g_log.log("Scanning for lua_load (sig1)...");
    uintptr_t load = PatternScan(sig1_str.c_str());
    if (load) {
        g_log.log("lua_load found via sig1 at 0x%p", (void*)load);
    } else {
        g_log.log("sig1 not found, trying sig2...");
        load = PatternScan(sig2_str.c_str());
        if (load)
            g_log.log("lua_load found via sig2 at 0x%p", (void*)load);
        else
            g_log.log("ERROR: lua_load not found by any signature");
    }

    g_log.log("Scanning for lua_pcall (sig3)...");
    uintptr_t pcall = PatternScan(sig3_str.c_str());
    if (pcall)
        g_log.log("lua_pcall found at 0x%p", (void*)pcall);
    else
        g_log.log("ERROR: lua_pcall not found");

    SecureZeroMemory(&sig1_str[0], sig1_str.size());
    SecureZeroMemory(&sig2_str[0], sig2_str.size());
    SecureZeroMemory(&sig3_str[0], sig3_str.size());

    if (!load || !pcall) {
        g_log.log("FATAL: signature scan failed (load=0x%p, pcall=0x%p), aborting", (void*)load, (void*)pcall);
        ExitThread(0);
        return 0;
    }

    oLua_Load = (tLua_Load)load;
    MH_STATUS mhStatus = MH_Initialize();
    g_log.log("MH_Initialize: %d", mhStatus);

    mhStatus = MH_CreateHook((void*)pcall, &hkLua_Pcall, (void**)&oLua_Pcall);
    g_log.log("MH_CreateHook: %d", mhStatus);

    mhStatus = MH_EnableHook(MH_ALL_HOOKS);
    g_log.log("MH_EnableHook: %d", mhStatus);

    // Start named pipe server for mylua.exe commands
    g_pipeRunning.store(true);
    HANDLE hPipeThread = CreateThread(nullptr, 0, PipeServerThread, nullptr, 0, nullptr);
    g_log.log("Hook active. Pipe server started. F3=inject, F12=unload");

    while (true) {
        HWND foreground = GetForegroundWindow();
        DWORD foregroundPid = 0;
        if (foreground) GetWindowThreadProcessId(foreground, &foregroundPid);

        if (foregroundPid == GetCurrentProcessId()) {
            if (GetAsyncKeyState(VK_F3) & 1) {
                g_log.log("F3 pressed — queueing payload inject");
                bInjectPayload.store(true);
            }
            if (GetAsyncKeyState(VK_F12) & 1) {
                g_log.log("F12 pressed — unloading");
                break;
            }
        }
        Sleep(50);
    }

    // Clean unhook
    MH_DisableHook((void*)pcall);
    Sleep(100);
    MH_RemoveHook((void*)pcall);
    Sleep(100);
    MH_Uninitialize();
    g_log.log("Hooks removed, exiting thread");

    // After PEB unlink, FreeLibraryAndExitThread can crash because the loader
    // can't find our module in the (now-unlinked) lists. Use ExitThread instead
    // and leave the DLL mapped.
    ExitThread(0);
    return 0;
}

// =================================================================================
// Entry Point
// =================================================================================

BOOL WINAPI DllMain(HMODULE hMod, DWORD dwReason, LPVOID lpReserved) {
    if (dwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hMod);
        HANDLE hThread = CreateThread(nullptr, 0, MainThread, hMod, 0, nullptr);
        if (hThread) CloseHandle(hThread);
    }
    return TRUE;
}
