"""Find lua_load / lua_pcall byte signatures from the Android game's libGame.so.

Unlike the Windows version which requires a running process (the .text is packed),
the Android .so file contains real code on disk — fully static analysis.

This script:
  1. Parses the ELF64 AArch64 binary (libGame.so)
  2. Resolves luaopen_* symbols from .dynsym
  3. Traces BL (Branch-Link) call chains from luaopen_* functions
  4. Classifies call targets by AArch64 heuristics to identify lua_load / lua_pcall
  5. Dumps candidate signatures ready for an Android injector

Usage:
    python find_lua_sigs_android.py [path_to_libGame.so]
"""

from __future__ import annotations

import struct
import sys
import os
from collections import defaultdict

# Default path relative to project root
DEFAULT_SO = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "WWM_APK", "arm64_extracted", "lib", "arm64-v8a", "libGame.so",
)

# ---------------------------------------------------------------------------
# ELF64 parsing
# ---------------------------------------------------------------------------

ELF_MAGIC = b"\x7fELF"
ELFCLASS64 = 2
ELFDATA2LSB = 1
EM_AARCH64 = 0xB7
SHT_DYNSYM = 11
SHT_SYMTAB = 2
STT_FUNC = 2


def parse_elf(data: bytes) -> dict:
    """Parse ELF64 headers from raw bytes."""
    if data[:4] != ELF_MAGIC:
        raise ValueError("Not an ELF file")
    if data[4] != ELFCLASS64:
        raise ValueError("Not ELF64")
    if data[5] != ELFDATA2LSB:
        raise ValueError("Not little-endian")

    e_machine = struct.unpack_from("<H", data, 18)[0]
    if e_machine != EM_AARCH64:
        raise ValueError(f"Not AArch64 (machine=0x{e_machine:X})")

    e_entry = struct.unpack_from("<Q", data, 24)[0]
    e_phoff = struct.unpack_from("<Q", data, 32)[0]
    e_shoff = struct.unpack_from("<Q", data, 40)[0]
    e_phentsize = struct.unpack_from("<H", data, 54)[0]
    e_phnum = struct.unpack_from("<H", data, 56)[0]
    e_shentsize = struct.unpack_from("<H", data, 58)[0]
    e_shnum = struct.unpack_from("<H", data, 60)[0]
    e_shstrndx = struct.unpack_from("<H", data, 62)[0]

    # Parse section headers
    sections = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh_name = struct.unpack_from("<I", data, off)[0]
        sh_type = struct.unpack_from("<I", data, off + 4)[0]
        sh_flags = struct.unpack_from("<Q", data, off + 8)[0]
        sh_addr = struct.unpack_from("<Q", data, off + 16)[0]
        sh_offset = struct.unpack_from("<Q", data, off + 24)[0]
        sh_size = struct.unpack_from("<Q", data, off + 32)[0]
        sh_link = struct.unpack_from("<I", data, off + 40)[0]
        sh_info = struct.unpack_from("<I", data, off + 44)[0]
        sh_addralign = struct.unpack_from("<Q", data, off + 48)[0]
        sh_entsize = struct.unpack_from("<Q", data, off + 56)[0]
        sections.append({
            "name_off": sh_name,
            "type": sh_type,
            "flags": sh_flags,
            "addr": sh_addr,
            "offset": sh_offset,
            "size": sh_size,
            "link": sh_link,
            "info": sh_info,
            "addralign": sh_addralign,
            "entsize": sh_entsize,
        })

    # Parse program headers for LOAD segments (to map VA -> file offset)
    PT_LOAD = 1
    loads = []
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        p_type = struct.unpack_from("<I", data, off)[0]
        if p_type != PT_LOAD:
            continue
        p_flags = struct.unpack_from("<I", data, off + 4)[0]
        p_offset = struct.unpack_from("<Q", data, off + 8)[0]
        p_vaddr = struct.unpack_from("<Q", data, off + 16)[0]
        p_filesz = struct.unpack_from("<Q", data, off + 32)[0]
        p_memsz = struct.unpack_from("<Q", data, off + 40)[0]
        loads.append({
            "offset": p_offset,
            "vaddr": p_vaddr,
            "filesz": p_filesz,
            "memsz": p_memsz,
            "flags": p_flags,
        })

    # Resolve section names
    if e_shstrndx < len(sections):
        strtab = sections[e_shstrndx]
        for sec in sections:
            name_start = strtab["offset"] + sec["name_off"]
            null = data.find(b"\x00", name_start)
            sec["name"] = data[name_start:null].decode("ascii", errors="replace")
    else:
        for sec in sections:
            sec["name"] = f"<#{sec['name_off']}>"

    return {
        "entry": e_entry,
        "sections": sections,
        "loads": loads,
    }


def va_to_offset(elf: dict, va: int) -> int | None:
    """Convert a virtual address to file offset using LOAD segments."""
    for seg in elf["loads"]:
        if seg["vaddr"] <= va < seg["vaddr"] + seg["filesz"]:
            return seg["offset"] + (va - seg["vaddr"])
    return None


def offset_to_va(elf: dict, off: int) -> int | None:
    """Convert file offset to virtual address."""
    for seg in elf["loads"]:
        if seg["offset"] <= off < seg["offset"] + seg["filesz"]:
            return seg["vaddr"] + (off - seg["offset"])
    return None


def read_at_va(data: bytes, elf: dict, va: int, size: int) -> bytes:
    """Read `size` bytes from file at the given VA."""
    off = va_to_offset(elf, va)
    if off is None:
        return b""
    return data[off : off + size]


# ---------------------------------------------------------------------------
# Symbol parsing
# ---------------------------------------------------------------------------

def parse_symbols(data: bytes, elf: dict) -> dict[str, int]:
    """Extract luaopen_* and lua_* symbols from .dynsym and .symtab."""
    result: dict[str, int] = {}

    for sec in elf["sections"]:
        if sec["type"] not in (SHT_DYNSYM, SHT_SYMTAB):
            continue

        strtab_sec = elf["sections"][sec["link"]]
        strtab_off = strtab_sec["offset"]
        entsize = sec["entsize"] or 24  # Elf64_Sym = 24 bytes

        num_syms = sec["size"] // entsize
        for i in range(num_syms):
            sym_off = sec["offset"] + i * entsize
            st_name = struct.unpack_from("<I", data, sym_off)[0]
            st_info = data[sym_off + 4]
            st_shndx = struct.unpack_from("<H", data, sym_off + 6)[0]
            st_value = struct.unpack_from("<Q", data, sym_off + 8)[0]

            st_type = st_info & 0xF

            if st_type != STT_FUNC or st_value == 0:
                continue

            # Read name
            name_start = strtab_off + st_name
            null = data.find(b"\x00", name_start)
            name = data[name_start:null].decode("ascii", errors="replace")

            if name.startswith("luaopen_") or name.startswith("lua_") or name.startswith("luaL_"):
                result[name] = st_value

    return result


# ---------------------------------------------------------------------------
# AArch64 instruction decoding
# ---------------------------------------------------------------------------

def decode_bl(insn: int, pc: int) -> int | None:
    """Decode BL instruction → target VA.  BL = 0b100101 imm26."""
    if (insn >> 26) != 0b100101:
        return None
    imm26 = insn & 0x03FFFFFF
    # Sign-extend 26-bit
    if imm26 & (1 << 25):
        imm26 |= ~0x03FFFFFF
        imm26 = ctypes_sign_extend(imm26)
    offset = imm26 * 4
    return pc + offset


def ctypes_sign_extend(val: int) -> int:
    """Sign-extend to Python int from 26-bit."""
    if val & (1 << 25):
        return val - (1 << 26)
    return val


def decode_bl_proper(insn: int, pc: int) -> int | None:
    """Decode a BL (Branch with Link) instruction. Opcode: 1 00101 imm26."""
    if (insn >> 26) != 0x25:  # 0b100101 = 0x25
        return None
    imm26 = insn & 0x03FFFFFF
    # Sign-extend
    if imm26 & (1 << 25):
        imm26 -= (1 << 26)
    return pc + imm26 * 4


def is_ret(insn: int) -> bool:
    """Check if instruction is RET (0xD65F03C0)."""
    return insn == 0xD65F03C0


def is_blr(insn: int) -> bool:
    """Check if instruction is BLR Xn (indirect call). BLR = 1101 0110 0011 1111 0000 00nn nnn0 0000."""
    return (insn & 0xFFFFFC1F) == 0xD63F0000


def is_b(insn: int) -> bool:
    """Check if instruction is B (unconditional branch). B = 0 00101 imm26."""
    return (insn >> 26) == 0b000101


def is_stp_pre(insn: int) -> bool:
    """Check for STP with pre-index (common prologue). STP x29,x30,[sp,#-N]!"""
    # 1010 1001 1xxx xxxx xxxx xxxx xxxx xxxx
    return (insn & 0xFFC00000) == 0xA9800000


# ---------------------------------------------------------------------------
# BL call tracing (static, on-disk)
# ---------------------------------------------------------------------------

def find_bl_calls(data: bytes, elf: dict, va: int, max_insns: int = 256) -> list[int]:
    """Find BL targets from function at `va`, stopping at RET."""
    targets: list[int] = []
    for i in range(max_insns):
        pc = va + i * 4
        raw = read_at_va(data, elf, pc, 4)
        if len(raw) < 4:
            break
        insn = struct.unpack_from("<I", raw)[0]

        target = decode_bl_proper(insn, pc)
        if target is not None:
            targets.append(target)

        if is_ret(insn):
            break

    return targets


def trace_calls(
    data: bytes, elf: dict, roots: dict[str, int],
    max_depth: int = 2, max_insns: int = 256,
) -> dict[int, set[str]]:
    """BFS call tracing from root symbols."""
    target_sources: dict[int, set[str]] = defaultdict(set)

    for name, va in roots.items():
        queue: list[tuple[int, int]] = [(va, 0)]
        visited: set[int] = set()

        while queue:
            addr, depth = queue.pop(0)
            if addr in visited or depth > max_depth:
                continue
            visited.add(addr)

            calls = find_bl_calls(data, elf, addr, max_insns=max_insns if depth == 0 else 128)
            for t in calls:
                target_sources[t].add(name)
                if depth + 1 <= max_depth and t not in visited:
                    queue.append((t, depth + 1))

    return target_sources


# ---------------------------------------------------------------------------
# AArch64 classification heuristics
# ---------------------------------------------------------------------------

def classify_arm64(data_bytes: bytes, elf: dict, func_va: int) -> list[str]:
    """Classify an AArch64 function by instruction patterns."""
    code = read_at_va(data_bytes, elf, func_va, 512)
    tags: list[str] = []

    if not code or len(code) < 16:
        return ["<unreadable>"]

    num_insns = len(code) // 4

    blr_count = 0
    bl_count = 0
    stp_frame = False
    frame_size = 0
    sxtw_count = 0
    movz_wzr = 0  # MOV with zero register (zeroing)
    b_count = 0

    for i in range(num_insns):
        insn = struct.unpack_from("<I", code, i * 4)[0]

        # BLR Xn (indirect call)
        if is_blr(insn):
            blr_count += 1

        # BL (direct call)
        if decode_bl_proper(insn, func_va + i * 4) is not None:
            bl_count += 1

        # STP x29, x30, [sp, #-N]! (function prologue - stack frame allocation)
        if (insn & 0xFFE00000) == 0xA9800000:
            stp_frame = True
            # Extract immediate (bits [21:15], signed, *8)
            imm7 = (insn >> 15) & 0x7F
            if imm7 & 0x40:
                imm7 -= 0x80
            frame_size = abs(imm7 * 8)

        # SUB sp, sp, #N (additional stack allocation)
        if (insn & 0xFFC003FF) == 0xD10003FF:
            imm12 = (insn >> 10) & 0xFFF
            sh = (insn >> 22) & 1
            alloc = imm12 << (12 if sh else 0)
            if alloc > frame_size:
                frame_size = alloc

        # SXTW (sign-extend word to doubleword) — like MOVSXD on x86
        # SXTW Xd, Wn = SBFM Xd, Xn, #0, #31
        # 1001 0011 0100 0000 0111 11nn nnn0 dddd = 0x93407C00 mask 0xFFFFFC00
        if (insn & 0xFFFFFC00) == 0x93407C00:
            sxtw_count += 1

        # MOV WZR / XZR patterns (zeroing)
        # MOVZ Wd, #0 -> indicates zero
        # ORR Xd, XZR, Xm  (mov alias) where source is XZR
        if (insn & 0xFFE0001F) == 0xAA1F0000:  # MOV Xd, XZR (ORR Xd, XZR, XZR)
            movz_wzr += 1
        # MOVZ Wd, #0
        if (insn & 0xFFE0001F) == 0x52800000 and ((insn >> 5) & 0xFFFF) == 0:
            movz_wzr += 1

        # B (unconditional)
        if is_b(insn):
            b_count += 1

        # RET
        if is_ret(insn):
            break

    if blr_count:
        tags.append(f"blr_indirect={blr_count}")
    if sxtw_count:
        tags.append(f"sxtw={sxtw_count}")
    if movz_wzr:
        tags.append(f"zero_mov={movz_wzr}")
    if frame_size:
        tags.append(f"frame=0x{frame_size:X}")
    tags.append(f"bl_calls={bl_count}")
    if b_count:
        tags.append(f"b_jumps={b_count}")

    return tags


def guess_arm64(tags: list[str]) -> str:
    """Guess whether function is lua_load or lua_pcall based on AArch64 patterns."""
    t = " ".join(tags)
    hints = []

    has_blr = "blr_indirect" in t
    has_sxtw = "sxtw" in t
    has_zero = "zero_mov" in t

    # lua_load: has indirect call (reader callback), larger frame
    if has_blr:
        for tag in tags:
            if tag.startswith("frame="):
                frame = int(tag.split("=")[1], 16)
                if frame >= 0x40:
                    hints.append("lua_load?")
                    break

    # lua_pcall: zeros k/ctx, sign-extends int params
    if has_zero and has_sxtw:
        hints.append("lua_pcall?")
    elif has_sxtw and not has_blr:
        for tag in tags:
            if tag.startswith("frame="):
                frame = int(tag.split("=")[1], 16)
                if 0x20 <= frame <= 0x60:
                    hints.append("lua_pcall?")
                    break

    return ", ".join(hints) if hints else ""


# ---------------------------------------------------------------------------
# Signature scanning (for verifying old sigs if any)
# ---------------------------------------------------------------------------

def format_sig(raw: bytes) -> str:
    return " ".join(f"{b:02X}" for b in raw)


def format_sig_arm64(data_bytes: bytes, elf: dict, va: int, num_insns: int = 8) -> str:
    """Format first N instructions as hex signature."""
    code = read_at_va(data_bytes, elf, va, num_insns * 4)
    return format_sig(code)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    so_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SO
    print("=" * 78)
    print("  lua_load / lua_pcall Signature Finder  (Android ARM64, static analysis)")
    print("=" * 78)
    print(f"\nReading: {so_path}")
    print(f"Size: {os.path.getsize(so_path) / 1048576:.1f} MB")

    with open(so_path, "rb") as f:
        data = f.read()

    elf = parse_elf(data)

    # Print section info
    print(f"\nEntry point: 0x{elf['entry']:X}")
    print(f"LOAD segments: {len(elf['loads'])}")
    print(f"Sections: {len(elf['sections'])}")

    # Find executable sections
    print("\nExecutable sections:")
    for sec in elf["sections"]:
        if sec["flags"] & 4:  # SHF_EXECINSTR
            print(f"  {sec['name']:16s}  addr=0x{sec['addr']:012X}  "
                  f"size=0x{sec['size']:X} ({sec['size']/1048576:.1f} MB)")

    # Step 1: Get luaopen_* symbols
    print("\n" + "-" * 78)
    print("Resolving luaopen_* / lua_* / luaL_* exports from symbol tables...")
    print("-" * 78)
    symbols = parse_symbols(data, elf)

    luaopen = {k: v for k, v in symbols.items() if k.startswith("luaopen_")}
    lua_api = {k: v for k, v in symbols.items() if k.startswith("lua_") or k.startswith("luaL_")}

    print(f"\n  Found {len(luaopen)} luaopen_* symbols")
    print(f"  Found {len(lua_api)} lua_*/luaL_* symbols")

    if luaopen:
        print("\n  luaopen_* symbols:")
        for name, va in sorted(luaopen.items()):
            sig = format_sig_arm64(data, elf, va, 4)
            print(f"    {name:40s}  VA=0x{va:012X}  [{sig}]")

    # Print known Lua API symbols (these are our ground truth!)
    if lua_api:
        print("\n  Direct lua_*/luaL_* symbols (ground truth):")
        lua_load_va = None
        lua_pcall_va = None
        for name, va in sorted(lua_api.items()):
            sig = format_sig_arm64(data, elf, va, 4)
            marker = ""
            if name == "lua_load":
                lua_load_va = va
                marker = " <<<< TARGET"
            elif name in ("lua_pcall", "lua_pcallk"):
                lua_pcall_va = va
                marker = " <<<< TARGET"
            print(f"    {name:40s}  VA=0x{va:012X}  [{sig}]{marker}")

        # If we found them directly, dump their full signatures
        if lua_load_va:
            print("\n" + "=" * 78)
            print("FOUND lua_load DIRECTLY IN SYMBOL TABLE!")
            print("=" * 78)
            full_sig = format_sig_arm64(data, elf, lua_load_va, 16)
            tags = classify_arm64(data, elf, lua_load_va)
            print(f"  VA=0x{lua_load_va:012X}")
            print(f"  sig (64 bytes): {full_sig}")
            print(f"  tags: {' '.join(tags)}")

        if lua_pcall_va:
            print("\n" + "=" * 78)
            print("FOUND lua_pcall/pcallk DIRECTLY IN SYMBOL TABLE!")
            print("=" * 78)
            full_sig = format_sig_arm64(data, elf, lua_pcall_va, 16)
            tags = classify_arm64(data, elf, lua_pcall_va)
            print(f"  VA=0x{lua_pcall_va:012X}")
            print(f"  sig (64 bytes): {full_sig}")
            print(f"  tags: {' '.join(tags)}")

        if lua_load_va or lua_pcall_va:
            print("\n  >>> Symbols found directly! Heuristic tracing may still be useful")
            print("      for verification or finding stripped builds.\n")

    if not luaopen:
        print("  [!] No luaopen_* exports found — symbols may be stripped")
        if not lua_api:
            print("  [!] No lua_* symbols either — binary is fully stripped")
            print("  [!] Cannot proceed with symbol-based analysis")
            return

    # Step 2: Trace calls from luaopen_* if available
    if luaopen:
        print("\n" + "-" * 78)
        print("Tracing BL call chains from luaopen_* (depth=2)...")
        print("-" * 78)
        targets = trace_calls(data, elf, luaopen, max_depth=2, max_insns=256)
        print(f"  Found {len(targets)} unique call targets\n")

        # Step 3: Rank and classify
        ranked = sorted(targets.items(), key=lambda kv: (-len(kv[1]), kv[0]))

        load_candidates: list[tuple[int, bytes, list[str], int]] = []
        pcall_candidates: list[tuple[int, bytes, list[str], int]] = []
        core_api: list[tuple[int, bytes, list[str], int, set[str]]] = []

        for va, sources in ranked:
            code = read_at_va(data, elf, va, 64)
            if not code or len(code) < 16:
                continue
            tags = classify_arm64(data, elf, va)
            g = guess_arm64(tags)
            fan_in = len(sources)

            if "lua_load?" in g:
                load_candidates.append((va, code[:32], tags, fan_in))
            if "lua_pcall?" in g:
                pcall_candidates.append((va, code[:32], tags, fan_in))
            if fan_in >= 2:
                core_api.append((va, code[:32], tags, fan_in, sources))

        # Cross-reference with known symbols
        known_vas = {v: k for k, v in lua_api.items()}

        print("=" * 78)
        print("LIKELY lua_load CANDIDATES (via heuristic)")
        print("  (BLR indirect call to reader callback + large stack frame)")
        print("=" * 78)
        if load_candidates:
            for va, raw, tags, fan_in in sorted(load_candidates, key=lambda x: -x[3]):
                known = known_vas.get(va, "")
                label = f"  ** CONFIRMED: {known} **" if known else ""
                print(f"\n  VA=0x{va:012X}  fan-in={fan_in}{label}")
                print(f"  sig: {format_sig(raw)}")
                print(f"  tags: {' '.join(tags)}")
        else:
            print("  (none matched heuristic — check core API list below)")

        print()
        print("=" * 78)
        print("LIKELY lua_pcall CANDIDATES (via heuristic)")
        print("  (zero_mov + sxtw sign-extension of int params)")
        print("=" * 78)
        if pcall_candidates:
            for va, raw, tags, fan_in in sorted(pcall_candidates, key=lambda x: -x[3]):
                known = known_vas.get(va, "")
                label = f"  ** CONFIRMED: {known} **" if known else ""
                print(f"\n  VA=0x{va:012X}  fan-in={fan_in}{label}")
                print(f"  sig: {format_sig(raw)}")
                print(f"  tags: {' '.join(tags)}")
        else:
            print("  (none matched heuristic — check core API list below)")

        print()
        print("=" * 78)
        print("ALL CORE API FUNCTIONS (called by 2+ luaopen_* functions)")
        print("=" * 78)
        for va, raw, tags, fan_in, sources in core_api:
            g = guess_arm64(tags)
            known = known_vas.get(va, "")
            label = f"  ** {known} **" if known else ""
            print(f"\n  VA=0x{va:012X}  fan-in={fan_in}{label}")
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
    print("1. If symbols are present: use VA offsets directly for hooking")
    print("2. If symbols are stripped in release: use the byte signatures above")
    print("3. For injection: use Frida / Xposed / plt hooking on libGame.so")
    print("4. lua_load: 5 params (L, reader, data, chunkname, mode)")
    print("5. lua_pcall wraps lua_pcallk, zeros out k/ctx, sign-extends nargs/nresults")
    print("6. Signature = first 16-32 bytes of function, enough to be unique in .text")


if __name__ == "__main__":
    import io
    log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sig_results_android.txt")

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
