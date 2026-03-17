"""Find new lua_load / lua_pcall byte signatures from the RUNNING game process.

The game binary is packed — .text is empty on disk and only exists unpacked
in memory at runtime. This script attaches to the running wwm.exe process,
reads its unpacked memory, then:

  1. Resolves luaopen_* export RVAs to in-memory addresses
  2. Reads the unpacked code at those addresses
  3. Traces E8 (CALL) chains from luaopen_* functions
  4. Classifies call targets by heuristic to identify lua_load / lua_pcall
  5. Dumps candidate signatures ready for inject.cpp

Run WHILE the game is running (admin may be required).
"""

from __future__ import annotations

import ctypes
import ctypes.wintypes as wt
import struct
import sys
from collections import defaultdict

# ---------------------------------------------------------------------------
# Win32 API
# ---------------------------------------------------------------------------

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
psapi = ctypes.WinDLL("psapi", use_last_error=True)

PROCESS_VM_READ = 0x0010
PROCESS_QUERY_INFORMATION = 0x0400
TH32CS_SNAPPROCESS = 0x00000002

class PROCESSENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize", wt.DWORD),
        ("cntUsage", wt.DWORD),
        ("th32ProcessID", wt.DWORD),
        ("th32DefaultHeapID", ctypes.POINTER(ctypes.c_ulong)),
        ("th32ModuleID", wt.DWORD),
        ("cntThreads", wt.DWORD),
        ("th32ParentProcessID", wt.DWORD),
        ("pcPriClassBase", ctypes.c_long),
        ("dwFlags", wt.DWORD),
        ("szExeFile", ctypes.c_char * 260),
    ]


def find_pid(name: str) -> int | None:
    snap = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    if snap == -1:
        return None
    entry = PROCESSENTRY32()
    entry.dwSize = ctypes.sizeof(PROCESSENTRY32)
    if kernel32.Process32First(snap, ctypes.byref(entry)):
        while True:
            if entry.szExeFile.decode("ascii", errors="ignore").lower() == name.lower():
                kernel32.CloseHandle(snap)
                return entry.th32ProcessID
            if not kernel32.Process32Next(snap, ctypes.byref(entry)):
                break
    kernel32.CloseHandle(snap)
    return None


def open_process(pid: int) -> int:
    h = kernel32.OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, False, pid)
    if not h:
        raise OSError(f"OpenProcess failed (run as admin?): error {ctypes.get_last_error()}")
    return h


def read_mem(handle: int, addr: int, size: int) -> bytes:
    buf = (ctypes.c_char * size)()
    read = ctypes.c_size_t(0)
    if not kernel32.ReadProcessMemory(handle, ctypes.c_void_p(addr), buf, size, ctypes.byref(read)):
        return b""
    return bytes(buf[: read.value])


def get_module_base(handle: int, pid: int) -> int:
    """Get base address of the main module (wwm.exe)."""
    hMods = (ctypes.c_void_p * 1024)()
    cbNeeded = wt.DWORD()
    if not psapi.EnumProcessModules(handle, ctypes.byref(hMods), ctypes.sizeof(hMods), ctypes.byref(cbNeeded)):
        return 0
    return hMods[0] or 0


# ---------------------------------------------------------------------------
# PE helpers (operating on in-memory PE)
# ---------------------------------------------------------------------------

def parse_pe_in_memory(handle: int, base: int) -> dict:
    """Parse PE headers from process memory."""
    header = read_mem(handle, base, 0x1000)
    if len(header) < 0x200 or header[:2] != b"MZ":
        raise ValueError("Invalid PE at base")

    pe_off = struct.unpack_from("<I", header, 0x3C)[0]
    coff = pe_off + 4
    num_sec = struct.unpack_from("<H", header, coff + 2)[0]
    size_opt = struct.unpack_from("<H", header, coff + 16)[0]
    opt = coff + 20
    machine = struct.unpack_from("<H", header, coff)[0]

    if machine == 0x8664:
        image_base = struct.unpack_from("<Q", header, opt + 24)[0]
        size_of_image = struct.unpack_from("<I", header, opt + 56)[0]
        export_rva, export_sz = struct.unpack_from("<II", header, opt + 112)
    else:
        image_base = struct.unpack_from("<I", header, opt + 28)[0]
        size_of_image = struct.unpack_from("<I", header, opt + 56)[0]
        export_rva, export_sz = struct.unpack_from("<II", header, opt + 96)

    sec_off = opt + size_opt
    sections = []
    for i in range(num_sec):
        s = sec_off + i * 40
        name = header[s : s + 8].rstrip(b"\x00").decode("ascii", errors="replace")
        vs = struct.unpack_from("<I", header, s + 8)[0]
        va = struct.unpack_from("<I", header, s + 12)[0]
        chars = struct.unpack_from("<I", header, s + 36)[0]
        sections.append({"name": name, "va": va, "vs": vs, "chars": chars})

    return {
        "image_base": image_base,
        "size_of_image": size_of_image,
        "sections": sections,
        "export_rva": export_rva,
        "export_sz": export_sz,
    }


def parse_exports_mem(handle: int, base: int, pe: dict) -> dict[str, int]:
    """Return {name: VA} for luaopen_* exports from process memory."""
    if pe["export_rva"] == 0:
        return {}

    exp_addr = base + pe["export_rva"]
    exp_data = read_mem(handle, exp_addr, pe["export_sz"])
    if len(exp_data) < 40:
        return {}

    num_funcs = struct.unpack_from("<I", exp_data, 20)[0]
    num_names = struct.unpack_from("<I", exp_data, 24)[0]
    funcs_rva = struct.unpack_from("<I", exp_data, 28)[0]
    names_rva = struct.unpack_from("<I", exp_data, 32)[0]
    ords_rva = struct.unpack_from("<I", exp_data, 36)[0]

    funcs_data = read_mem(handle, base + funcs_rva, num_funcs * 4)
    names_data = read_mem(handle, base + names_rva, num_names * 4)
    ords_data = read_mem(handle, base + ords_rva, num_names * 2)

    result: dict[str, int] = {}
    for i in range(num_names):
        name_rva = struct.unpack_from("<I", names_data, i * 4)[0]
        name_bytes = read_mem(handle, base + name_rva, 128)
        null = name_bytes.find(b"\x00")
        if null == -1:
            continue
        name = name_bytes[:null].decode("ascii", errors="replace")

        ord_idx = struct.unpack_from("<H", ords_data, i * 2)[0]
        func_rva = struct.unpack_from("<I", funcs_data, ord_idx * 4)[0]
        func_va = base + func_rva

        if name.startswith("luaopen_"):
            result[name] = func_va

    return result


# ---------------------------------------------------------------------------
# Call tracing
# ---------------------------------------------------------------------------

def find_e8_calls(data: bytes, base_va: int) -> list[int]:
    """Find relative CALL (E8) targets as VAs."""
    targets: list[int] = []
    i = 0
    while i < len(data) - 5:
        if data[i] == 0xE8:
            rel = struct.unpack_from("<i", data, i + 1)[0]
            target = base_va + i + 5 + rel
            targets.append(target)
            i += 5
        elif data[i] == 0xC3:
            break
        elif data[i:i+2] == b"\xCC\xCC":
            break
        else:
            i += 1
    return targets


def trace_calls_mem(
    handle: int, roots: dict[str, int], max_depth: int = 2, read_size: int = 512
) -> dict[int, set[str]]:
    """BFS call tracing in process memory."""
    target_sources: dict[int, set[str]] = defaultdict(set)

    for name, va in roots.items():
        queue: list[tuple[int, int]] = [(va, 0)]
        visited: set[int] = set()

        while queue:
            addr, depth = queue.pop(0)
            if addr in visited or depth > max_depth:
                continue
            visited.add(addr)

            code = read_mem(handle, addr, read_size if depth == 0 else 256)
            if not code:
                continue

            calls = find_e8_calls(code, addr)
            for t in calls:
                target_sources[t].add(name)
                if depth + 1 <= max_depth and t not in visited:
                    queue.append((t, depth + 1))

    return target_sources


# ---------------------------------------------------------------------------
# Classification heuristics
# ---------------------------------------------------------------------------

def classify(data: bytes) -> list[str]:
    tags: list[str] = []
    if not data or len(data) < 16:
        return ["<unreadable>"]

    # Indirect calls (FF D0..FF D7 = call rax..call rdi, FF 15 = call [rip+xx])
    indirect = sum(
        1 for i in range(len(data) - 1)
        if data[i] == 0xFF and (
            (0xD0 <= data[i + 1] <= 0xD7) or
            data[i + 1] == 0x15
        )
    )
    if indirect:
        tags.append(f"indirect_call={indirect}")

    # XOR reg,reg (zeroing)
    xors = sum(1 for i in range(len(data) - 1) if data[i] == 0x33)
    if xors:
        tags.append(f"xor_zero={xors}")

    # MOVSXD (sign-extend int32 → int64, common for int params like nargs/nresults)
    movsxd = sum(1 for i in range(len(data) - 1) if data[i] == 0x48 and i + 1 < len(data) and data[i + 1] == 0x63)
    movsxd += sum(1 for i in range(len(data) - 1) if data[i] == 0x49 and i + 1 < len(data) and data[i + 1] == 0x63)
    movsxd += sum(1 for i in range(len(data) - 1) if data[i] == 0x4C and i + 1 < len(data) and data[i + 1] == 0x63)
    movsxd_plain = sum(1 for i in range(len(data) - 1) if data[i] == 0x63 and (data[max(0,i-1)] & 0x40) == 0x40)
    if movsxd or movsxd_plain:
        tags.append(f"movsxd={movsxd + movsxd_plain}")

    # Stack frame
    for i in range(min(32, len(data) - 3)):
        if data[i:i+3] == b"\x48\x83\xEC":
            tags.append(f"frame=0x{data[i+3]:02X}")
            break
        if data[i:i+3] == b"\x48\x81\xEC" and i + 6 < len(data):
            frame = struct.unpack_from("<I", data, i + 3)[0]
            tags.append(f"frame=0x{frame:X}")
            break

    # E8 call count
    calls = sum(1 for i in range(len(data) - 4) if data[i] == 0xE8)
    tags.append(f"e8_calls={calls}")

    return tags


def guess(tags: list[str]) -> str:
    t = " ".join(tags)
    hints = []

    has_indirect = "indirect_call" in t
    has_xor = "xor_zero" in t
    has_movsxd = "movsxd" in t

    # lua_load: reader callback (indirect call), 5 params, larger stack frame
    if has_indirect:
        for tag in tags:
            if tag.startswith("frame="):
                frame = int(tag.split("=")[1], 16)
                if frame >= 0x40:
                    hints.append("lua_load?")
                    break

    # lua_pcall/pcallk: zeros k/ctx, sign-extends int params (nargs, nresults, errfunc)
    if has_xor and has_movsxd:
        hints.append("lua_pcall?")
    elif has_movsxd and not has_indirect:
        for tag in tags:
            if tag.startswith("frame="):
                frame = int(tag.split("=")[1], 16)
                if 0x30 <= frame <= 0x60:
                    hints.append("lua_pcall?")
                    break

    return ", ".join(hints) if hints else ""


# ---------------------------------------------------------------------------
# Verification: try old signatures as reference
# ---------------------------------------------------------------------------

OLD_SIGS = {
    "lua_load (old sig1)":
        "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 48 83 EC 50 48 8B E9 49 8B F1",
    "lua_load (old sig2)":
        "48 89 5C 24 10 56 48 83 EC 50 49 8B D9 48 8B F1 4D 8B C8 4C 8B C2 48 8D 54 24",
    "lua_pcall (old sig3)":
        "48 89 74 24 18 57 48 83 EC 40 33 F6 48 89 6C 24 58 49 63 C1 41 8B E8 48 8B F9 45 85 C9",
}


def scan_memory_for_sig(handle: int, base: int, size: int, sig_hex: str) -> list[int]:
    """Pattern-scan process memory for an IDA-style sig (supports ?? wildcards)."""
    tokens = sig_hex.split()
    pattern = []
    for t in tokens:
        pattern.append(-1 if t == "??" else int(t, 16))

    chunk_size = 0x100000  # 1MB
    hits: list[int] = []
    plen = len(pattern)

    for off in range(0, size - plen, chunk_size):
        read_sz = min(chunk_size + plen, size - off)
        data = read_mem(handle, base + off, read_sz)
        if not data:
            continue
        for i in range(len(data) - plen):
            if all(pattern[j] == -1 or data[i + j] == pattern[j] for j in range(plen)):
                hits.append(base + off + i)
    return hits


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def format_sig(raw: bytes) -> str:
    return " ".join(f"{b:02X}" for b in raw)


def main() -> None:
    print("=" * 78)
    print("  lua_load / lua_pcall Signature Finder  (reads live game memory)")
    print("=" * 78)

    pid = find_pid("wwm.exe")
    if not pid:
        print("\n[!] wwm.exe is not running. Start the game first.")
        sys.exit(1)
    print(f"\nFound wwm.exe  PID={pid}")

    handle = open_process(pid)
    base = get_module_base(handle, pid)
    print(f"Module base: 0x{base:X}")

    pe = parse_pe_in_memory(handle, base)
    print(f"Image base:  0x{pe['image_base']:X}")
    print(f"Image size:  0x{pe['size_of_image']:X}")

    # Print sections
    print("\nSections:")
    text_va_start = 0
    text_va_end = 0
    for s in pe["sections"]:
        exe = "X" if s["chars"] & 0x20000000 else " "
        print(f"  {s['name']:8s}  VA=0x{s['va']:08X}  VS=0x{s['vs']:08X}  [{exe}]")
        if s["name"] == ".text":
            text_va_start = base + s["va"]
            text_va_end = text_va_start + s["vs"]

    # Step 1: Check old sigs in memory
    print("\n" + "-" * 78)
    print("Checking OLD signatures in memory (for reference)...")
    print("-" * 78)
    for name, sig in OLD_SIGS.items():
        hits = scan_memory_for_sig(handle, text_va_start, text_va_end - text_va_start, sig)
        if hits:
            for h in hits:
                print(f"  {name}: FOUND at 0x{h:X}  (still valid!)")
        else:
            print(f"  {name}: not found (signature changed)")

    # Step 2: Get exports
    print("\n" + "-" * 78)
    print("Resolving luaopen_* exports...")
    print("-" * 78)
    exports = parse_exports_mem(handle, base, pe)
    if not exports:
        print("  [!] No luaopen_* exports found")
        kernel32.CloseHandle(handle)
        sys.exit(1)

    for name, va in sorted(exports.items()):
        code = read_mem(handle, va, 16)
        print(f"  {name}")
        print(f"    VA=0x{va:X}  prologue: {format_sig(code)}")

    # Step 3: Trace calls
    print("\n" + "-" * 78)
    print("Tracing CALL chains from exports (depth=2)...")
    print("-" * 78)
    targets = trace_calls_mem(handle, exports, max_depth=2, read_size=512)
    print(f"  Found {len(targets)} unique call targets\n")

    # Step 4: Rank and classify
    ranked = sorted(targets.items(), key=lambda kv: (-len(kv[1]), kv[0]))

    # Separate into categories
    load_candidates: list[tuple[int, bytes, list[str], int]] = []
    pcall_candidates: list[tuple[int, bytes, list[str], int]] = []
    core_api: list[tuple[int, bytes, list[str], int, set[str]]] = []

    for va, sources in ranked:
        code = read_mem(handle, va, 128)
        if not code or len(code) < 16:
            continue
        tags = classify(code)
        g = guess(tags)
        fan_in = len(sources)

        if "lua_load?" in g:
            load_candidates.append((va, code[:32], tags, fan_in))
        if "lua_pcall?" in g:
            pcall_candidates.append((va, code[:32], tags, fan_in))
        if fan_in >= 2:
            core_api.append((va, code[:32], tags, fan_in, sources))

    # Print results
    print("=" * 78)
    print("LIKELY lua_load CANDIDATES")
    print("  (indirect call to reader callback + large stack frame)")
    print("=" * 78)
    if load_candidates:
        for va, raw, tags, fan_in in sorted(load_candidates, key=lambda x: -x[3]):
            print(f"\n  VA=0x{va:X}  fan-in={fan_in}")
            print(f"  sig: {format_sig(raw)}")
            print(f"  tags: {' '.join(tags)}")
    else:
        print("  (none matched heuristic — check core API list below)")

    print()
    print("=" * 78)
    print("LIKELY lua_pcall CANDIDATES")
    print("  (xor zeroing + movsxd sign-extension of int params)")
    print("=" * 78)
    if pcall_candidates:
        for va, raw, tags, fan_in in sorted(pcall_candidates, key=lambda x: -x[3]):
            print(f"\n  VA=0x{va:X}  fan-in={fan_in}")
            print(f"  sig: {format_sig(raw)}")
            print(f"  tags: {' '.join(tags)}")
    else:
        print("  (none matched heuristic — check core API list below)")

    print()
    print("=" * 78)
    print("ALL CORE API FUNCTIONS (called by 2+ luaopen_* functions)")
    print("=" * 78)
    for va, raw, tags, fan_in, sources in core_api:
        g = guess(tags)
        print(f"\n  VA=0x{va:X}  fan-in={fan_in}")
        print(f"  sig: {format_sig(raw)}")
        print(f"  tags: {' '.join(tags)}")
        if g:
            print(f"  >>> {g}")
        if fan_in <= 5:
            print(f"  called by: {', '.join(sorted(sources))}")

    print()
    print("-" * 78)
    print("NEXT STEPS:")
    print("-" * 78)
    print("1. Copy candidate sigs into x64dbg → go to VA → verify disassembly")
    print("2. lua_load: 5 params (L, reader, data, chunkname, mode), calls reader indirectly")
    print("3. lua_pcall: wraps lua_pcallk, zeros out k/ctx, sign-extends nargs/nresults/errfunc")
    print("4. Quick test: set breakpoint on candidate, press F3 — lua_pcall hits every frame")
    print("5. Take first ~25 unique bytes of the function prologue as the new signature")

    kernel32.CloseHandle(handle)


if __name__ == "__main__":
    import io, os
    log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sig_results.txt")

    class Tee:
        """Write to both stdout and a file."""
        def __init__(self, path: str):
            self._file = open(path, "w", encoding="utf-8")
            self._stdout = sys.stdout
        def write(self, s: str) -> int:
            self._stdout.write(s)
            self._file.write(s)
            return len(s)
        def flush(self) -> None:
            self._stdout.flush()
            self._file.flush()

    sys.stdout = Tee(log_path)
    try:
        main()
    finally:
        print(f"\nResults saved to: {log_path}")
        sys.stdout._file.close()
        sys.stdout = sys.stdout._stdout
