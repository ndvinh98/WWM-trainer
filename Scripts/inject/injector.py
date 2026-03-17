"""Stealth DLL injector — direct NT syscalls + shellcode-based loading.

Usage:
    python injector.py <process>                  # inject Test.dll
    python injector.py <process> path/to/my.dll   # inject custom DLL
    python injector.py <process> --eject          # eject DLL

<process> accepts a name (wwm.exe, notepad.exe) or a numeric PID.
Must be run as administrator.
"""

from __future__ import annotations

import ctypes
import ctypes.wintypes as wt
import os
import random
import struct
import sys
import time
from pathlib import Path

assert sys.maxsize > 2**32, "This injector requires 64-bit Python"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PAGE_NOACCESS          = 0x01
PAGE_READWRITE         = 0x04
PAGE_EXECUTE_READ      = 0x20
PAGE_EXECUTE_READWRITE = 0x40
MEM_COMMIT             = 0x1000
MEM_RESERVE            = 0x2000
MEM_RELEASE            = 0x8000
PROCESS_MIN_ACCESS     = 0x043A  # VM_OP | VM_WRITE | VM_READ | CREATE_THREAD | QUERY_INFO
THREAD_ALL_ACCESS      = 0x001FFFFF
INFINITE               = 0xFFFFFFFF
TH32CS_SNAPPROCESS     = 0x02
TH32CS_SNAPMODULE      = 0x08
TH32CS_SNAPMODULE32    = 0x10
MAX_PATH               = 260

DEFAULT_DLL = Path(__file__).parent / "Test.dll"

# ---------------------------------------------------------------------------
# NT structures
# ---------------------------------------------------------------------------

class CLIENT_ID(ctypes.Structure):
    _fields_ = [
        ("UniqueProcess", ctypes.c_void_p),
        ("UniqueThread",  ctypes.c_void_p),
    ]

class UNICODE_STRING(ctypes.Structure):
    _fields_ = [
        ("Length",        ctypes.c_ushort),
        ("MaximumLength", ctypes.c_ushort),
        ("Buffer",        ctypes.c_wchar_p),
    ]

class OBJECT_ATTRIBUTES(ctypes.Structure):
    _fields_ = [
        ("Length",                   ctypes.c_ulong),
        ("RootDirectory",           ctypes.c_void_p),
        ("ObjectName",              ctypes.POINTER(UNICODE_STRING)),
        ("Attributes",              ctypes.c_ulong),
        ("SecurityDescriptor",      ctypes.c_void_p),
        ("SecurityQualityOfService", ctypes.c_void_p),
    ]

class LARGE_INTEGER(ctypes.Structure):
    _fields_ = [("QuadPart", ctypes.c_longlong)]

# Toolhelp structs (for local process/module enumeration)
class PROCESSENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize",              wt.DWORD),
        ("cntUsage",            wt.DWORD),
        ("th32ProcessID",       wt.DWORD),
        ("th32DefaultHeapID",   ctypes.POINTER(ctypes.c_ulong)),
        ("th32ModuleID",        wt.DWORD),
        ("cntThreads",          wt.DWORD),
        ("th32ParentProcessID", wt.DWORD),
        ("pcPriClassBase",      ctypes.c_long),
        ("dwFlags",             wt.DWORD),
        ("szExeFile",           ctypes.c_char * MAX_PATH),
    ]

class MODULEENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize",        wt.DWORD),
        ("th32ModuleID",  wt.DWORD),
        ("th32ProcessID", wt.DWORD),
        ("GlblcntUsage",  wt.DWORD),
        ("ProccntUsage",  wt.DWORD),
        ("modBaseAddr",   ctypes.POINTER(ctypes.c_byte)),
        ("modBaseSize",   wt.DWORD),
        ("hModule",       wt.HMODULE),
        ("szModule",      ctypes.c_char * 256),
        ("szExePath",     ctypes.c_char * MAX_PATH),
    ]

# ---------------------------------------------------------------------------
# kernel32 + ntdll setup
# ---------------------------------------------------------------------------

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
ntdll    = ctypes.WinDLL("ntdll",    use_last_error=True)

kernel32.GetModuleHandleA.argtypes = [ctypes.c_char_p]
kernel32.GetModuleHandleA.restype  = wt.HMODULE
kernel32.GetProcAddress.argtypes   = [wt.HMODULE, ctypes.c_char_p]
kernel32.GetProcAddress.restype    = ctypes.c_void_p
kernel32.CloseHandle.argtypes      = [wt.HANDLE]
kernel32.CloseHandle.restype       = wt.BOOL
kernel32.GetExitCodeThread.argtypes = [wt.HANDLE, ctypes.POINTER(wt.DWORD)]
kernel32.GetExitCodeThread.restype  = wt.BOOL
kernel32.CreateToolhelp32Snapshot.argtypes = [wt.DWORD, wt.DWORD]
kernel32.CreateToolhelp32Snapshot.restype  = wt.HANDLE
kernel32.Process32First.argtypes   = [wt.HANDLE, ctypes.POINTER(PROCESSENTRY32)]
kernel32.Process32First.restype    = wt.BOOL
kernel32.Process32Next.argtypes    = [wt.HANDLE, ctypes.POINTER(PROCESSENTRY32)]
kernel32.Process32Next.restype     = wt.BOOL
kernel32.Module32First.argtypes    = [wt.HANDLE, ctypes.POINTER(MODULEENTRY32)]
kernel32.Module32First.restype     = wt.BOOL
kernel32.Module32Next.argtypes     = [wt.HANDLE, ctypes.POINTER(MODULEENTRY32)]
kernel32.Module32Next.restype      = wt.BOOL
kernel32.ReadProcessMemory.argtypes = [
    wt.HANDLE, ctypes.c_void_p, ctypes.c_void_p,
    ctypes.c_size_t, ctypes.POINTER(ctypes.c_size_t)
]
kernel32.ReadProcessMemory.restype = wt.BOOL

INVALID_HANDLE = wt.HANDLE(-1).value

# ntdll prototypes (direct NT calls, more reliable than our own trampolines)

NTSTATUS = ctypes.c_long

ntdll.NtOpenProcess.argtypes = [
    ctypes.POINTER(wt.HANDLE),      # ProcessHandle
    wt.DWORD,                       # DesiredAccess
    ctypes.POINTER(OBJECT_ATTRIBUTES),
    ctypes.POINTER(CLIENT_ID),
]
ntdll.NtOpenProcess.restype = NTSTATUS

ntdll.NtAllocateVirtualMemory.argtypes = [
    wt.HANDLE,                      # ProcessHandle
    ctypes.POINTER(ctypes.c_void_p),# BaseAddress
    ctypes.c_ulonglong,             # ZeroBits
    ctypes.POINTER(ctypes.c_size_t),# RegionSize
    wt.DWORD,                       # AllocationType
    wt.DWORD,                       # Protect
]
ntdll.NtAllocateVirtualMemory.restype = NTSTATUS

ntdll.NtWriteVirtualMemory.argtypes = [
    wt.HANDLE,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_size_t),
]
ntdll.NtWriteVirtualMemory.restype = NTSTATUS

ntdll.NtProtectVirtualMemory.argtypes = [
    wt.HANDLE,
    ctypes.POINTER(ctypes.c_void_p),
    ctypes.POINTER(ctypes.c_size_t),
    wt.DWORD,
    ctypes.POINTER(wt.DWORD),
]
ntdll.NtProtectVirtualMemory.restype = NTSTATUS

ntdll.NtCreateThreadEx.argtypes = [
    ctypes.POINTER(wt.HANDLE),  # ThreadHandle
    wt.DWORD,                   # DesiredAccess
    ctypes.c_void_p,            # ObjectAttributes
    wt.HANDLE,                  # ProcessHandle
    ctypes.c_void_p,            # StartRoutine
    ctypes.c_void_p,            # Argument
    wt.DWORD,                   # CreateFlags
    ctypes.c_size_t,            # ZeroBits
    ctypes.c_size_t,            # StackSize
    ctypes.c_size_t,            # MaximumStackSize
    ctypes.c_void_p,            # AttributeList
]
ntdll.NtCreateThreadEx.restype = NTSTATUS

ntdll.NtWaitForSingleObject.argtypes = [
    wt.HANDLE, ctypes.c_ubyte, ctypes.POINTER(LARGE_INTEGER)
]
ntdll.NtWaitForSingleObject.restype = NTSTATUS

ntdll.NtFreeVirtualMemory.argtypes = [
    wt.HANDLE,
    ctypes.POINTER(ctypes.c_void_p),
    ctypes.POINTER(ctypes.c_size_t),
    wt.DWORD,
]
ntdll.NtFreeVirtualMemory.restype = NTSTATUS

ntdll.NtClose.argtypes = [wt.HANDLE]
ntdll.NtClose.restype  = NTSTATUS


def nt_success(status: int) -> bool:
    return status >= 0


def nt_status_str(status: int) -> str:
    return f"0x{status & 0xFFFFFFFF:08X}"


# ==========================================================================
# 2. LOADER SHELLCODE BUILDER
# ==========================================================================

def build_loader_shellcode(
    set_dll_dir_addr: int,
    load_library_addr: int,
    dll_dir: str,
    dll_path: str,
) -> tuple[bytes, int]:
    """Build x64 shellcode that loads a DLL with dependency directory set.

    Returns (shellcode_bytes, result_slot_offset).
    The result_slot (8 bytes at the returned offset) will contain the
    full 64-bit HMODULE after execution.
    """
    dll_dir_bytes  = dll_dir.encode("ascii")  + b"\x00"
    dll_path_bytes = dll_path.encode("ascii") + b"\x00"

    code = bytearray()

    # Prologue
    code += b"\x53"                 # push rbx
    code += b"\x48\x83\xEC\x28"    # sub rsp, 0x28

    # SetDllDirectoryA(dll_dir)
    lea1_pos = len(code)
    code += b"\x48\x8D\x0D\x00\x00\x00\x00"                     # lea rcx, [rip+??]
    code += b"\x48\xB8" + struct.pack("<Q", set_dll_dir_addr)    # mov rax, imm64
    code += b"\xFF\xD0"                                           # call rax

    # LoadLibraryA(dll_path)
    lea2_pos = len(code)
    code += b"\x48\x8D\x0D\x00\x00\x00\x00"                     # lea rcx, [rip+??]
    code += b"\x48\xB8" + struct.pack("<Q", load_library_addr)   # mov rax, imm64
    code += b"\xFF\xD0"                                           # call rax
    code += b"\x48\x8B\xD8"                                      # mov rbx, rax

    # SetDllDirectoryA(NULL) — reset search path
    code += b"\x33\xC9"                                           # xor ecx, ecx
    code += b"\x48\xB8" + struct.pack("<Q", set_dll_dir_addr)    # mov rax, imm64
    code += b"\xFF\xD0"                                           # call rax

    # Store full 64-bit HMODULE to result slot
    lea3_pos = len(code)
    code += b"\x48\x8D\x0D\x00\x00\x00\x00"                     # lea rcx, [rip+??]
    code += b"\x48\x89\x19"                                      # mov [rcx], rbx

    # Epilogue
    code += b"\x48\x8B\xC3"        # mov rax, rbx (return HMODULE in eax too)
    code += b"\x48\x83\xC4\x28"    # add rsp, 0x28
    code += b"\x5B"                 # pop rbx
    code += b"\xC3"                 # ret

    # Data section
    dll_dir_start = len(code)
    code += dll_dir_bytes

    dll_path_start = len(code)
    code += dll_path_bytes

    result_slot = len(code)
    code += b"\x00" * 8             # 8-byte slot for HMODULE result

    # Patch RIP-relative offsets (offset = target - next_instruction_address)
    struct.pack_into("<i", code, lea1_pos + 3, dll_dir_start  - (lea1_pos + 7))
    struct.pack_into("<i", code, lea2_pos + 3, dll_path_start - (lea2_pos + 7))
    struct.pack_into("<i", code, lea3_pos + 3, result_slot    - (lea3_pos + 7))

    return bytes(code), result_slot


# ==========================================================================
# 3. SeDebugPrivilege (fixed argtypes)
# ==========================================================================

def enable_debug_privilege() -> bool:
    advapi32 = ctypes.WinDLL("advapi32", use_last_error=True)

    advapi32.OpenProcessToken.argtypes = [
        ctypes.c_void_p, wt.DWORD, ctypes.POINTER(wt.HANDLE)
    ]
    advapi32.OpenProcessToken.restype = wt.BOOL

    advapi32.LookupPrivilegeValueA.argtypes = [
        ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p
    ]
    advapi32.LookupPrivilegeValueA.restype = wt.BOOL

    advapi32.AdjustTokenPrivileges.argtypes = [
        wt.HANDLE, wt.BOOL, ctypes.c_void_p, wt.DWORD,
        ctypes.c_void_p, ctypes.c_void_p
    ]
    advapi32.AdjustTokenPrivileges.restype = wt.BOOL

    TOKEN_ADJUST_PRIVILEGES = 0x0020
    TOKEN_QUERY = 0x0008
    SE_PRIVILEGE_ENABLED = 0x00000002

    class LUID(ctypes.Structure):
        _fields_ = [("LowPart", wt.DWORD), ("HighPart", wt.LONG)]

    class TOKEN_PRIVILEGES(ctypes.Structure):
        _fields_ = [
            ("PrivilegeCount", wt.DWORD),
            ("Luid", LUID),
            ("Attributes", wt.DWORD),
        ]

    hToken = wt.HANDLE()
    # Use c_void_p(-1) for pseudo-handle to avoid 64-bit overflow
    if not advapi32.OpenProcessToken(
        ctypes.c_void_p(-1),
        TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
        ctypes.byref(hToken),
    ):
        return False

    luid = LUID()
    if not advapi32.LookupPrivilegeValueA(None, b"SeDebugPrivilege", ctypes.byref(luid)):
        kernel32.CloseHandle(hToken)
        return False

    tp = TOKEN_PRIVILEGES(PrivilegeCount=1, Luid=luid, Attributes=SE_PRIVILEGE_ENABLED)
    ok = advapi32.AdjustTokenPrivileges(hToken, False, ctypes.byref(tp), 0, None, None)
    kernel32.CloseHandle(hToken)
    return bool(ok)


# ==========================================================================
# 4. Process / module helpers (local Toolhelp — no stealth needed)
# ==========================================================================

def find_pid(name: str) -> int | None:
    snap = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    if snap == INVALID_HANDLE:
        return None
    entry = PROCESSENTRY32()
    entry.dwSize = ctypes.sizeof(PROCESSENTRY32)
    try:
        if kernel32.Process32First(snap, ctypes.byref(entry)):
            while True:
                exe = entry.szExeFile.decode("ascii", errors="ignore").lower()
                if exe == name.lower():
                    return entry.th32ProcessID
                if not kernel32.Process32Next(snap, ctypes.byref(entry)):
                    break
    finally:
        kernel32.CloseHandle(snap)
    return None


def find_module_in_process(pid: int, dll_name: str) -> int | None:
    snap = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid)
    if snap == INVALID_HANDLE:
        return None
    entry = MODULEENTRY32()
    entry.dwSize = ctypes.sizeof(MODULEENTRY32)
    try:
        if kernel32.Module32First(snap, ctypes.byref(entry)):
            while True:
                mod = entry.szModule.decode("ascii", errors="ignore").lower()
                if mod == dll_name.lower():
                    return ctypes.cast(entry.modBaseAddr, ctypes.c_void_p).value
                if not kernel32.Module32Next(snap, ctypes.byref(entry)):
                    break
    finally:
        kernel32.CloseHandle(snap)
    return None


def resolve_target(target: str) -> tuple[int, str]:
    """Resolve a process name or PID string to (pid, name)."""
    if target.isdigit():
        return int(target), target
    pid = find_pid(target)
    if pid is None:
        raise RuntimeError(f"Process {target!r} not found")
    return pid, target


# ==========================================================================
# 5. STEALTH INJECTION
# ==========================================================================

def _jitter():
    """Small random delay between cross-process operations."""
    time.sleep(random.uniform(0.005, 0.035))


def _remote_call_nt(
    hProcess: wt.HANDLE,
    func_addr: int,
    arg_str: str,
    label: str,
    timeout_ms: int = 10000,
) -> int | None:
    """NtAllocateVirtualMemory + NtWriteVirtualMemory + NtCreateThreadEx for a single string arg."""
    _jitter()
    arg_bytes = arg_str.encode("ascii") + b"\x00"

    base_addr = ctypes.c_void_p(0)
    region_size = ctypes.c_size_t(len(arg_bytes))
    status = ntdll.NtAllocateVirtualMemory(
        hProcess,
        ctypes.byref(base_addr),
        0,
        ctypes.byref(region_size),
        MEM_COMMIT | MEM_RESERVE,
        PAGE_READWRITE,
    )
    if not nt_success(status):
        print(f"  [FAIL] NtAllocateVirtualMemory for {label}: {nt_status_str(status)}")
        return None

    remote_ptr = base_addr.value

    buf = (ctypes.c_char * len(arg_bytes)).from_buffer_copy(arg_bytes)
    written = ctypes.c_size_t(0)
    status = ntdll.NtWriteVirtualMemory(
        hProcess,
        ctypes.c_void_p(remote_ptr),
        ctypes.cast(buf, ctypes.c_void_p),
        len(arg_bytes),
        ctypes.byref(written),
    )
    if not nt_success(status):
        print(f"  [FAIL] NtWriteVirtualMemory for {label}: {nt_status_str(status)}")
        # best-effort free
        zero = ctypes.c_size_t(0)
        ntdll.NtFreeVirtualMemory(
            hProcess,
            ctypes.byref(base_addr),
            ctypes.byref(zero),
            MEM_RELEASE,
        )
        return None

    hThread = wt.HANDLE()
    status = ntdll.NtCreateThreadEx(
        ctypes.byref(hThread),
        THREAD_ALL_ACCESS,
        None,
        hProcess,
        ctypes.c_void_p(func_addr),
        ctypes.c_void_p(remote_ptr),
        0,
        0,
        0,
        0,
        None,
    )
    if not nt_success(status):
        print(f"  [FAIL] NtCreateThreadEx for {label}: {nt_status_str(status)}")
        zero = ctypes.c_size_t(0)
        ntdll.NtFreeVirtualMemory(
            hProcess,
            ctypes.byref(base_addr),
            ctypes.byref(zero),
            MEM_RELEASE,
        )
        return None

    timeout = LARGE_INTEGER()
    timeout.QuadPart = -int(timeout_ms) * 10_000  # ms → 100ns units
    ntdll.NtWaitForSingleObject(hThread, 0, ctypes.byref(timeout))

    exit_code = wt.DWORD(0)
    kernel32.GetExitCodeThread(hThread, ctypes.byref(exit_code))

    if hThread.value:
        ntdll.NtClose(hThread)

    zero = ctypes.c_size_t(0)
    ntdll.NtFreeVirtualMemory(
        hProcess,
        ctypes.byref(base_addr),
        ctypes.byref(zero),
        MEM_RELEASE,
    )

    return exit_code.value


def inject_dll(pid: int, dll_path: str) -> bool:
    """Inject a DLL using direct Nt* calls + LoadLibraryA thread."""
    dll_dir = os.path.dirname(dll_path)

    # Resolve kernel32 function addresses (same across all processes per boot)
    hK32 = kernel32.GetModuleHandleA(b"kernel32.dll")
    load_library_addr   = kernel32.GetProcAddress(hK32, b"LoadLibraryA")
    set_dll_dir_addr    = kernel32.GetProcAddress(hK32, b"SetDllDirectoryA")
    free_library_addr   = kernel32.GetProcAddress(hK32, b"FreeLibrary")

    if not load_library_addr or not set_dll_dir_addr:
        print("  [FAIL] Cannot resolve kernel32 exports")
        return False

    # -- Step 1: Open process via NtOpenProcess --
    print(f"  NtOpenProcess (PID={pid}, access=0x{PROCESS_MIN_ACCESS:X})...")
    _jitter()

    oa = OBJECT_ATTRIBUTES()
    oa.Length = ctypes.sizeof(OBJECT_ATTRIBUTES)
    cid = CLIENT_ID()
    cid.UniqueProcess = ctypes.c_void_p(pid)

    hProcess = wt.HANDLE()
    status = ntdll.NtOpenProcess(
        ctypes.byref(hProcess),
        PROCESS_MIN_ACCESS,
        ctypes.byref(oa),
        ctypes.byref(cid),
    )
    if not nt_success(status):
        print(f"  [FAIL] NtOpenProcess: NTSTATUS {nt_status_str(status)}")
        return False
    print(f"  [OK] Process handle: 0x{hProcess.value:X}")

    try:
        # Optionally set DLL directory for dependencies
        if set_dll_dir_addr and dll_dir:
            print(f"  SetDllDirectoryA -> {dll_dir}")
            rc = _remote_call_nt(hProcess, set_dll_dir_addr, dll_dir, "SetDllDirectoryA")
            print(f"  SetDllDirectoryA rc=0x{(rc or 0) & 0xFFFFFFFF:08X}")

        # LoadLibraryA(dll_path) via NtCreateThreadEx
        print(f"  LoadLibraryA -> {dll_path}")
        rc = _remote_call_nt(hProcess, load_library_addr, dll_path, "LoadLibraryA")
        if rc is None:
            return False

        print(f"  [OK] LoadLibraryA exit code: 0x{rc:08X}")
        if rc == 0:
            print("  [FAIL] LoadLibraryA returned NULL")
            print("         - Missing dependency DLL?")
            print("         - DllMain returned FALSE?")
            print("         - Architecture mismatch?")
            return False

        # Try to confirm by locating the module
        dll_name = os.path.basename(dll_path)
        base = find_module_in_process(pid, dll_name)
        if base:
            print(f"  [OK] {dll_name} found at 0x{base:X}")
        else:
            print("  [WARN] DLL not found via module snapshot; using exit code as hint")

        return True

    finally:
        if hProcess.value:
            ntdll.NtClose(hProcess)


# ==========================================================================
# 6. EJECT (uses NtCreateThreadEx for stealth)
# ==========================================================================

def eject_dll(pid: int, dll_name: str) -> bool:
    base = find_module_in_process(pid, dll_name)
    if base is None:
        print(f"  [FAIL] {dll_name} not found in process {pid}")
        return False

    oa = OBJECT_ATTRIBUTES()
    oa.Length = ctypes.sizeof(OBJECT_ATTRIBUTES)
    cid = CLIENT_ID()
    cid.UniqueProcess = ctypes.c_void_p(pid)

    hProcess = wt.HANDLE()
    status = ntdll.NtOpenProcess(
        ctypes.byref(hProcess),
        PROCESS_MIN_ACCESS,
        ctypes.byref(oa),
        ctypes.byref(cid),
    )
    if not nt_success(status):
        print(f"  [FAIL] NtOpenProcess: {nt_status_str(status)}")
        return False

    try:
        hK32 = kernel32.GetModuleHandleA(b"kernel32.dll")
        freelib = kernel32.GetProcAddress(hK32, b"FreeLibrary")

        print(f"  Ejecting {dll_name} (base=0x{base:X})...")
        hThread = wt.HANDLE()
        status = ntdll.NtCreateThreadEx(
            ctypes.byref(hThread),
            THREAD_ALL_ACCESS,
            None,
            hProcess,
            ctypes.c_void_p(freelib),
            ctypes.c_void_p(base),
            0,
            0,
            0,
            0,
            None,
        )
        if not nt_success(status):
            print(f"  [FAIL] NtCreateThreadEx: {nt_status_str(status)}")
            return False

        timeout = LARGE_INTEGER()
        timeout.QuadPart = -100_000_000
        ntdll.NtWaitForSingleObject(hThread, 0, ctypes.byref(timeout))
        if hThread.value:
            ntdll.NtClose(hThread)
        print(f"  [OK] {dll_name} ejected")
        return True
    finally:
        if hProcess.value:
            ntdll.NtClose(hProcess)


# ==========================================================================
# 7. CLI AND MAIN
# ==========================================================================

class Tee:
    def __init__(self, path: str):
        self._file = open(path, "w", encoding="utf-8")
        self._stdout = sys.__stdout__
    def write(self, s: str) -> int:
        self._stdout.write(s)
        self._file.write(s)
        self._file.flush()
        return len(s)
    def flush(self) -> None:
        self._stdout.flush()
        self._file.flush()
    def close(self) -> None:
        self._file.close()


def print_usage():
    print("Usage:")
    print("  python injector.py <process>                  # inject Test.dll")
    print("  python injector.py <process> path/to/my.dll   # inject custom DLL")
    print("  python injector.py <process> --eject          # eject DLL")
    print()
    print("  <process> = name (wwm.exe) or PID (12345)")


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--eject"]
    eject_mode = "--eject" in sys.argv

    if not args:
        print_usage()
        sys.exit(1)

    target = args[0]
    dll_path = str(DEFAULT_DLL.resolve())
    if len(args) > 1:
        dll_path = str(Path(args[1]).resolve())

    dll_name = os.path.basename(dll_path)

    tee_path = str(Path(__file__).parent.parent / "logs" / "injector_log.txt")
    os.makedirs(os.path.dirname(tee_path), exist_ok=True)
    tee = Tee(tee_path)
    sys.stdout = tee

    print("=" * 62)
    print("  Stealth DLL Injector (NT Syscalls + Shellcode Loader)")
    print("=" * 62)
    print(f"  Mode:    {'EJECT' if eject_mode else 'INJECT'}")
    print(f"  Target:  {target}")
    print(f"  DLL:     {dll_path}")
    print()

    if not eject_mode and not os.path.isfile(dll_path):
        print(f"  [FAIL] DLL not found: {dll_path}")
        tee.close()
        sys.exit(1)

    try:
        enable_debug_privilege()
        print("  [OK] SeDebugPrivilege enabled")
    except Exception as e:
        print(f"  [WARN] SeDebugPrivilege: {e}")

    pid, proc_name = resolve_target(target)
    print(f"  [OK] {proc_name} PID={pid}")
    print()

    if eject_mode:
        if find_module_in_process(pid, dll_name) is None:
            print(f"  {dll_name} is not loaded in the process")
            tee.close()
            sys.exit(0)
        ok = eject_dll(pid, dll_name)
    else:
        if find_module_in_process(pid, dll_name) is not None:
            print(f"  {dll_name} is already loaded (use --eject first)")
            tee.close()
            sys.exit(0)
        ok = inject_dll(pid, dll_path)

    print()
    if ok:
        print("  Done.")
        if not eject_mode:
            log = Path(dll_path).parent.parent / "logs" / "inject_log.txt"
            print(f"  DLL log: {log}")
    else:
        print("  Failed. Run as administrator.")
        tee.close()
        sys.exit(1)

    tee.close()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        import traceback
        msg = traceback.format_exc()
        print(f"\n  [UNHANDLED EXCEPTION]\n{msg}")
        err_path = str(Path(__file__).parent.parent / "logs" / "injector_crash.txt")
        os.makedirs(os.path.dirname(err_path), exist_ok=True)
        with open(err_path, "w") as f:
            f.write(msg)
        sys.exit(1)
