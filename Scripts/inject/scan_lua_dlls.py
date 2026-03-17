"""Recursively scan a game directory for Lua DLLs, statically-linked Lua,
and Lua C API symbols (including stripped/obfuscated binaries)."""

from __future__ import annotations

import os
import re
import struct
import sys
from pathlib import Path

SCAN_ROOT = Path(r"F:\SteamData\steamapps\common\Where Winds Meet")

DLL_PATTERN = re.compile(r"^lua\d{0,2}\.dll$", re.IGNORECASE)

BINARY_EXTS = (".dll", ".exe", ".so", ".dylib")

# Byte signatures for stripped Lua C API functions (IDA-style hex strings).
# "??" = wildcard byte.  Obtained from reverse-engineering the game binary.
BYTE_SIGNATURES: dict[str, str] = {
    "lua_load": (
        "48 89 5C 24 10 56 48 83 EC 50 49 8B D9 48 8B F1 "
        "4D 8B C8 4C 8B C2 48 8D 54 24 20"
    ),
    "lua_pcall": (
        "48 89 74 24 18 57 48 83 EC 40 33 F6 48 89 6C 24 58 "
        "49 63 C1 41 8B E8 48 8B F9 45 85 C9"
    ),
}

# Standard Lua C API symbols (plain-text in non-stripped binaries)
API_SYMBOLS = [
    b"lua_load",
    b"lua_pcall",
    b"lua_pcallk",
    b"lua_call",
    b"lua_callk",
    b"lua_newstate",
    b"lua_close",
    b"lua_newthread",
    b"lua_settop",
    b"lua_pushvalue",
    b"lua_type",
    b"lua_typename",
    b"lua_toboolean",
    b"lua_tolstring",
    b"lua_rawlen",
    b"lua_touserdata",
    b"lua_pushnil",
    b"lua_pushnumber",
    b"lua_pushinteger",
    b"lua_pushlstring",
    b"lua_pushstring",
    b"lua_pushcclosure",
    b"lua_pushboolean",
    b"lua_getglobal",
    b"lua_gettable",
    b"lua_getfield",
    b"lua_rawget",
    b"lua_rawgeti",
    b"lua_createtable",
    b"lua_setglobal",
    b"lua_settable",
    b"lua_setfield",
    b"lua_rawset",
    b"lua_rawseti",
    b"lua_gc",
    b"lua_error",
    b"lua_next",
    b"lua_concat",
    b"luaL_newstate",
    b"luaL_openlibs",
    b"luaL_loadbuffer",
    b"luaL_loadbufferx",
    b"luaL_loadfile",
    b"luaL_loadfilex",
    b"luaL_loadstring",
    b"luaL_ref",
    b"luaL_unref",
    b"luaL_error",
    b"luaL_checkstring",
    b"luaL_checknumber",
    b"luaL_checkinteger",
    b"luaL_optstring",
    b"luaL_optnumber",
    b"luaL_optinteger",
]

# Regex patterns for heuristic detection in stripped binaries
HEURISTIC_PATTERNS: list[tuple[str, re.Pattern[bytes]]] = [
    ("luaopen_* modules", re.compile(rb"luaopen_\w+")),
    ("Lua version string", re.compile(rb"Lua 5\.[1234]\.\d+")),
    ("LuaJIT version", re.compile(rb"LuaJIT[ -]\d+\.\d+")),
    ("_VERSION constant", re.compile(rb"Lua 5\.[1234]")),
    ("Lua-specific error msgs", re.compile(
        rb"(?:attempt to (?:call|index|compare|concatenate|perform arithmetic on) a \w+ value"
        rb"|cannot resume dead coroutine"
        rb"|C stack overflow"
        rb"|unfinished long (?:string|comment)"
        rb"|table index is (?:nil|NaN))"
    )),
    ("Lua bytecode header", re.compile(rb"\x1bLua")),
    ("LuaJIT bytecode header", re.compile(rb"\x1bLJ")),
]


def parse_sig(sig: str) -> tuple[bytes, bytes]:
    """Convert an IDA-style hex signature to (pattern, mask) for matching.

    Each token is either a two-char hex byte or "??" for wildcard.
    Returns (pattern_bytes, mask_bytes) where mask 0xFF = must match, 0x00 = wildcard.
    """
    tokens = sig.split()
    pattern = bytearray()
    mask = bytearray()
    for t in tokens:
        if t == "??":
            pattern.append(0)
            mask.append(0)
        else:
            pattern.append(int(t, 16))
            mask.append(0xFF)
    return bytes(pattern), bytes(mask)


def find_signature(data: bytes, pattern: bytes, mask: bytes) -> list[int]:
    """Return all offsets where *pattern* matches *data* respecting *mask*."""
    plen = len(pattern)
    if plen == 0:
        return []

    # Fast pre-filter: find candidate positions using the first non-wildcard byte
    first_fixed = next((i for i, m in enumerate(mask) if m == 0xFF), None)
    if first_fixed is None:
        return []

    needle = pattern[first_fixed]
    hits: list[int] = []
    start = 0
    while True:
        pos = data.find(bytes([needle]), start)
        if pos == -1:
            break
        base = pos - first_fixed
        if base < 0 or base + plen > len(data):
            start = pos + 1
            continue
        if all(
            mask[i] == 0 or data[base + i] == pattern[i]
            for i in range(plen)
        ):
            hits.append(base)
        start = pos + 1
    return hits


def scan_byte_signatures(data: bytes) -> list[tuple[str, list[int]]]:
    """Scan binary data against all BYTE_SIGNATURES, return (name, offsets) pairs."""
    results: list[tuple[str, list[int]]] = []
    for name, sig_str in BYTE_SIGNATURES.items():
        pattern, mask = parse_sig(sig_str)
        offsets = find_signature(data, pattern, mask)
        if offsets:
            results.append((name, offsets))
    return results


def read_binary(path: Path) -> bytes | None:
    try:
        return path.read_bytes()
    except (OSError, PermissionError):
        return None


def find_lua_dlls(root: Path) -> list[Path]:
    matches: list[Path] = []
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if DLL_PATTERN.match(f):
                matches.append(Path(dirpath) / f)
    return matches


def scan_api_symbols(data: bytes) -> list[str]:
    return [sym.decode() for sym in API_SYMBOLS if sym in data]


def scan_heuristics(data: bytes) -> list[tuple[str, list[str]]]:
    results: list[tuple[str, list[str]]] = []
    for label, pat in HEURISTIC_PATTERNS:
        found = sorted({m.group().decode("ascii", errors="replace") for m in pat.finditer(data)})
        if found:
            results.append((label, found))
    return results


def parse_pe_exports(data: bytes) -> list[str]:
    """Minimal PE export-table parser — no external dependencies."""
    if len(data) < 64 or data[:2] != b"MZ":
        return []
    try:
        pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
        if pe_offset + 4 > len(data) or data[pe_offset : pe_offset + 4] != b"PE\x00\x00":
            return []

        coff_hdr = pe_offset + 4
        machine = struct.unpack_from("<H", data, coff_hdr)[0]
        optional_offset = coff_hdr + 20

        if machine == 0x8664:  # PE32+
            export_rva, export_size = struct.unpack_from("<II", data, optional_offset + 112)
            num_sections_offset = coff_hdr + 2
        elif machine == 0x14C:  # PE32
            export_rva, export_size = struct.unpack_from("<II", data, optional_offset + 96)
            num_sections_offset = coff_hdr + 2
        else:
            return []

        if export_rva == 0 or export_size == 0:
            return []

        size_of_optional = struct.unpack_from("<H", data, coff_hdr + 16)[0]
        num_sections = struct.unpack_from("<H", data, num_sections_offset)[0]
        sections_offset = optional_offset + size_of_optional

        def rva_to_offset(rva: int) -> int | None:
            for i in range(num_sections):
                sec = sections_offset + i * 40
                va = struct.unpack_from("<I", data, sec + 12)[0]
                raw_size = struct.unpack_from("<I", data, sec + 16)[0]
                raw_ptr = struct.unpack_from("<I", data, sec + 20)[0]
                vs = struct.unpack_from("<I", data, sec + 8)[0]
                sec_size = max(raw_size, vs)
                if va <= rva < va + sec_size:
                    return rva - va + raw_ptr
            return None

        exp_off = rva_to_offset(export_rva)
        if exp_off is None:
            return []

        num_names = struct.unpack_from("<I", data, exp_off + 24)[0]
        names_rva = struct.unpack_from("<I", data, exp_off + 32)[0]
        names_off = rva_to_offset(names_rva)
        if names_off is None:
            return []

        exports: list[str] = []
        lua_prefix = re.compile(r"^(?:lua[L_]|luaopen_|luaJIT_)", re.IGNORECASE)
        for i in range(num_names):
            name_rva = struct.unpack_from("<I", data, names_off + i * 4)[0]
            name_off = rva_to_offset(name_rva)
            if name_off is None:
                continue
            end = data.index(b"\x00", name_off)
            name = data[name_off:end].decode("ascii", errors="replace")
            if lua_prefix.match(name):
                exports.append(name)

        return exports
    except (struct.error, ValueError, IndexError):
        return []


def scan_directory(root: Path) -> None:
    print(f"Scanning: {root}\n")

    # --- Phase 1: filename matches ---
    print("=" * 72)
    print("Phase 1 — DLL filenames matching lua*.dll")
    print("=" * 72)
    lua_dlls = find_lua_dlls(root)
    if lua_dlls:
        for p in lua_dlls:
            print(f"  {p.relative_to(root)}  ({p.stat().st_size / 1024:,.1f} KB)")
    else:
        print("  (none found)")

    # --- Phase 2: PE exports + raw symbol scan + heuristics ---
    print()
    print("=" * 72)
    print("Phase 2 — Binary analysis (PE exports, API symbols, heuristics)")
    print("=" * 72)

    any_hit = False
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if not any(f.lower().endswith(e) for e in BINARY_EXTS):
                continue
            p = Path(dirpath) / f
            data = read_binary(p)
            if data is None:
                continue

            pe_lua_exports = parse_pe_exports(data)
            api_hits = scan_api_symbols(data)
            heuristic_hits = scan_heuristics(data)
            sig_hits = scan_byte_signatures(data)

            if not pe_lua_exports and not api_hits and not heuristic_hits and not sig_hits:
                continue

            any_hit = True
            rel = p.relative_to(root)
            size_kb = len(data) / 1024
            print(f"\n  {rel}  ({size_kb:,.1f} KB)")

            if sig_hits:
                print(f"    [Byte Signatures]")
                for name, offsets in sig_hits:
                    addrs = ", ".join(f"0x{off:X}" for off in offsets)
                    print(f"      {name}: found at {addrs}")

            if pe_lua_exports:
                print(f"    [PE Exports] ({len(pe_lua_exports)} Lua-related)")
                for name in sorted(pe_lua_exports)[:40]:
                    print(f"      - {name}")
                if len(pe_lua_exports) > 40:
                    print(f"      ... and {len(pe_lua_exports) - 40} more")

            if api_hits:
                print(f"    [API Symbols] ({len(api_hits)} found)")
                for s in sorted(api_hits):
                    print(f"      - {s}")

            if heuristic_hits:
                print("    [Heuristic Matches]")
                for label, values in heuristic_hits:
                    print(f"      {label}: {', '.join(values)}")

    if not any_hit:
        print("  (none found)")

    print(f"\nDone. Scanned from: {root}")


def main() -> None:
    root = SCAN_ROOT
    if len(sys.argv) > 1:
        root = Path(sys.argv[1])
    if not root.exists():
        print(f"[ERROR] Scan root does not exist: {root}")
        sys.exit(1)
    scan_directory(root)


if __name__ == "__main__":
    main()
