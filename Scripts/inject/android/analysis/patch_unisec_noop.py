#!/usr/bin/env python3
"""
patch_unisec_noop.py — Patch libunisec.so so all exported functions are NOPs.

Extracts libunisec.so from the original APK, finds all exported FUNC symbols
in the ELF dynamic symbol table, and patches each one's entry point with:
  - JNI_OnLoad: MOV W0, #6; MOVK W0, #1, LSL#16; RET  (returns JNI_VERSION_1_6)
  - Everything else: MOV W0, #0; RET  (returns 0 / NULL)

The patched .so is saved alongside the original for use by fast_deploy.py.

Usage:
    python3 Scripts/inject/android/analysis/patch_unisec_noop.py
"""
import os
import struct
import sys
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent.parent
APK_DIR = PROJECT_ROOT / "WWM_APK"
ARM64_APK = APK_DIR / "split_config.arm64_v8a.apk"
OUTPUT_DIR = SCRIPT_DIR.parent / "output"

# ARM64 instruction bytes
RET = bytes.fromhex("C0035FD6")                          # RET
MOV_W0_0 = bytes.fromhex("00008052")                     # MOV W0, #0
MOV_W0_6 = bytes.fromhex("C0008052")                     # MOV W0, #6
MOVK_W0_1_16 = bytes.fromhex("2000A072")                 # MOVK W0, #1, LSL#16

# Patches
NOOP_RETURN_0 = MOV_W0_0 + RET                           # 8 bytes: return 0
JNI_ONLOAD_RET = MOV_W0_6 + MOVK_W0_1_16 + RET           # 12 bytes: return 0x10006


def parse_elf_exports(data: bytes) -> list[tuple[str, int, int, int]]:
    """Parse ELF64 ARM64 and return list of (name, vaddr, file_offset, size)."""
    if data[:4] != b"\x7fELF" or data[4] != 2:
        raise ValueError("Not an ELF64 file")

    # Section headers
    e_shoff = struct.unpack_from("<Q", data, 40)[0]
    e_shentsize = struct.unpack_from("<H", data, 58)[0]
    e_shnum = struct.unpack_from("<H", data, 60)[0]

    # Program headers (for vaddr -> file offset mapping)
    e_phoff = struct.unpack_from("<Q", data, 32)[0]
    e_phentsize = struct.unpack_from("<H", data, 54)[0]
    e_phnum = struct.unpack_from("<H", data, 56)[0]

    loads = []
    for i in range(e_phnum):
        ph = e_phoff + i * e_phentsize
        p_type = struct.unpack_from("<I", data, ph)[0]
        if p_type == 1:  # PT_LOAD
            p_offset = struct.unpack_from("<Q", data, ph + 8)[0]
            p_vaddr = struct.unpack_from("<Q", data, ph + 16)[0]
            p_filesz = struct.unpack_from("<Q", data, ph + 32)[0]
            loads.append((p_offset, p_vaddr, p_filesz))

    def vaddr_to_foff(va):
        for loff, lvaddr, lfsz in loads:
            if lvaddr <= va < lvaddr + lfsz:
                return loff + (va - lvaddr)
        return None

    # Find .dynsym and .dynstr
    dynsym_off = dynsym_size = dynsym_entsize = 0
    dynstr_off = dynstr_size = 0
    for i in range(e_shnum):
        sh = e_shoff + i * e_shentsize
        sh_type = struct.unpack_from("<I", data, sh + 4)[0]
        sh_offset = struct.unpack_from("<Q", data, sh + 24)[0]
        sh_size = struct.unpack_from("<Q", data, sh + 32)[0]
        sh_entsize = struct.unpack_from("<Q", data, sh + 56)[0]
        if sh_type == 11:  # SHT_DYNSYM
            dynsym_off, dynsym_size, dynsym_entsize = sh_offset, sh_size, sh_entsize
        elif sh_type == 3 and dynstr_off == 0:  # SHT_STRTAB (first = .dynstr)
            dynstr_off, dynstr_size = sh_offset, sh_size

    if dynsym_off == 0 or dynstr_off == 0:
        raise ValueError("Could not find .dynsym or .dynstr sections")

    if dynsym_entsize == 0:
        dynsym_entsize = 24  # Elf64_Sym default size

    # Enumerate exported FUNC symbols
    count = dynsym_size // dynsym_entsize
    funcs = []
    for i in range(count):
        pos = dynsym_off + i * dynsym_entsize
        st_name = struct.unpack_from("<I", data, pos)[0]
        st_info = data[pos + 4]
        st_value = struct.unpack_from("<Q", data, pos + 8)[0]
        st_size = struct.unpack_from("<Q", data, pos + 16)[0]

        st_bind = st_info >> 4
        st_type = st_info & 0xF

        # STT_FUNC (2), GLOBAL (1) or WEAK (2), non-zero address
        if st_type == 2 and st_bind in (1, 2) and st_value != 0:
            name_end = data.index(0, dynstr_off + st_name)
            name = data[dynstr_off + st_name : name_end].decode("latin-1")
            foff = vaddr_to_foff(st_value)
            if foff is not None:
                funcs.append((name, st_value, foff, st_size))

    return sorted(funcs, key=lambda x: x[0])


def patch_unisec(so_data: bytes) -> tuple[bytearray, list[str]]:
    """Patch detection functions in libunisec.so to return immediately.

    IMPORTANT: libunisec.so exports ~1300 C++ runtime symbols (operator new,
    __cxa_*, _ZN*, _ZSt*, etc.) that other libraries depend on. We must NOT
    touch those. We only NOOP:
      - JNI_OnLoad (return JNI_VERSION_1_6 so dlopen succeeds)
      - Any function whose name does NOT match known C++ runtime patterns
    """
    # Prefixes that indicate C++ runtime / standard library symbols — do NOT patch
    KEEP_PREFIXES = (
        "_Z",           # All C++ mangled names (std::, operator, etc.)
        "__cxa_",       # C++ ABI exception handling
        "__gxx_",       # GCC personality routines
        "__emutls_",    # Thread-local storage
        "__dynamic_",   # RTTI dynamic_cast
    )
    # Functions to NEVER patch — required for startup
    NEVER_PATCH = {
        "JNI_OnLoad",   # Must run to register ShellSupporter JNI methods
    }

    funcs = parse_elf_exports(so_data)
    patched = bytearray(so_data)
    log = []
    patched_count = 0
    skipped_count = 0

    for name, va, foff, size in funcs:
        if name in NEVER_PATCH:
            log.append(f"  KEEP  {name}: VA=0x{va:08x} (required for startup)")
            skipped_count += 1
            continue
        elif any(name.startswith(p) for p in KEEP_PREFIXES):
            skipped_count += 1
            continue  # C++ runtime — leave untouched
        else:
            patch = NOOP_RETURN_0
            desc = "MOV W0,#0; RET"

        if foff + len(patch) > len(patched):
            log.append(f"  SKIP {name} (offset out of bounds)")
            continue

        patched[foff : foff + len(patch)] = patch
        log.append(f"  {name}: VA=0x{va:08x} foff=0x{foff:06x} size={size:5d} → {desc}")
        patched_count += 1

    log.append(f"  --- Patched {patched_count} detection funcs, kept {skipped_count} C++ runtime funcs ---")
    return patched, log


def patch_detect(so_data: bytes) -> tuple[bytearray, list[str]]:
    """Patch all exported functions in libdetect.so to return immediately."""
    funcs = parse_elf_exports(so_data)
    patched = bytearray(so_data)
    log = []

    for name, va, foff, size in funcs:
        patch = NOOP_RETURN_0
        desc = "MOV W0,#0; RET"

        if foff + len(patch) > len(patched):
            log.append(f"  SKIP {name} (offset out of bounds)")
            continue

        patched[foff : foff + len(patch)] = patch
        log.append(f"  {name}: VA=0x{va:08x} foff=0x{foff:06x} size={size:5d} → {desc}")

    return patched, log


def main():
    if not ARM64_APK.exists():
        print(f"ERROR: {ARM64_APK} not found")
        sys.exit(1)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(ARM64_APK) as z:
        # --- libunisec.so: LEFT UNTOUCHED ---
        # JNI_OnLoad must run fully (registers ShellSupporter JNI methods,
        # calls .datadiv_decode* string decryptors). We cannot NOOP any of
        # its exported functions without breaking startup.
        print("  libunisec.so: LEFT UNTOUCHED (required for startup)")

        # --- Patch libdetect.so ---
        print()
        print("=" * 60)
        print("  Patching libdetect.so → NOOP NtDetect* functions")
        print("=" * 60)
        detect_data = z.read("lib/arm64-v8a/libdetect.so")
        print(f"  Original size: {len(detect_data):,} bytes")

        patched_detect, detect_log = patch_detect(detect_data)
        for line in detect_log:
            print(line)
        print(f"  Patched {len(detect_log)} functions")

        out_detect = OUTPUT_DIR / "libdetect_noop.so"
        out_detect.write_bytes(bytes(patched_detect))
        print(f"  Saved: {out_detect}")

    print()
    print("Done! Use these in fast_deploy.py to replace the originals.")


if __name__ == "__main__":
    main()
