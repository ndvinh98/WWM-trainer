#!/usr/bin/env python3
"""Disassemble luaD_pcall (0x319E750) to check for mutex checks."""
import struct, os

SO = os.path.join(os.path.dirname(os.path.abspath(__file__)),
    "output/work_arm64/lib/arm64-v8a/libGame.so")
with open(SO, "rb") as f:
    data = f.read()

print("luaD_pcall (0x319E750) — first 30 instructions")
print("=" * 60)
for i in range(30):
    off = 0x319E750 + i * 4
    insn = struct.unpack_from("<I", data, off)[0]
    raw = " ".join(f"{b:02X}" for b in data[off:off+4])
    desc = ""
    
    if insn == 0xD65F03C0: desc = "RET"
    elif (insn & 0xFC000000) == 0x94000000:
        imm26 = insn & 0x03FFFFFF
        if imm26 & 0x02000000: imm26 -= 0x04000000
        target = off + imm26 * 4
        desc = f"BL 0x{target:X}"
    elif (insn & 0xFF800000) == 0xD1000000:
        rd = insn & 0x1F; rn = (insn >> 5) & 0x1F
        imm = (insn >> 10) & 0xFFF
        desc = f"SUB x{rd}, x{rn}, #0x{imm:X}"
    elif (insn & 0xFF800000) == 0x91000000:
        rd = insn & 0x1F; rn = (insn >> 5) & 0x1F
        imm = (insn >> 10) & 0xFFF
        desc = f"ADD x{rd}, x{rn}, #0x{imm:X}"
    elif (insn & 0xFFC00000) == 0xF9400000:
        rt = insn & 0x1F; rn = (insn >> 5) & 0x1F; imm = ((insn >> 10) & 0xFFF) * 8
        desc = f"LDR x{rt}, [x{rn}, #0x{imm:X}]"
    elif (insn & 0xFFC00000) == 0xF9000000:
        rt = insn & 0x1F; rn = (insn >> 5) & 0x1F; imm = ((insn >> 10) & 0xFFF) * 8
        desc = f"STR x{rt}, [x{rn}, #0x{imm:X}]"
    elif (insn & 0xFFE0FFE0) == 0xAA0003E0:
        rd = insn & 0x1F; rm = (insn >> 16) & 0x1F; desc = f"MOV x{rd}, x{rm}"
    elif (insn & 0x7FE0FFE0) == 0x2A0003E0:
        rd = insn & 0x1F; rm = (insn >> 16) & 0x1F; desc = f"MOV w{rd}, w{rm}"
    elif (insn & 0x7F000000) == 0x35000000:
        sf = (insn >> 31) & 1; rt = insn & 0x1F
        imm19 = (insn >> 5) & 0x7FFFF
        if imm19 & 0x40000: imm19 -= 0x80000
        target = off + imm19 * 4
        reg = f"x{rt}" if sf else f"w{rt}"
        desc = f"CBNZ {reg}, 0x{target:X}"
    elif (insn & 0x7F000000) == 0x34000000:
        sf = (insn >> 31) & 1; rt = insn & 0x1F
        imm19 = (insn >> 5) & 0x7FFFF
        if imm19 & 0x40000: imm19 -= 0x80000
        target = off + imm19 * 4
        reg = f"x{rt}" if sf else f"w{rt}"
        desc = f"CBZ {reg}, 0x{target:X}"
    elif (insn & 0xFF000000) == 0x54000000:
        cond = insn & 0xF
        conds = ["EQ","NE","CS","CC","MI","PL","VS","VC","HI","LS","GE","LT","GT","LE","AL","NV"]
        imm19 = (insn >> 5) & 0x7FFFF
        if imm19 & 0x40000: imm19 -= 0x80000
        target = off + imm19 * 4
        desc = f"B.{conds[cond]} 0x{target:X}"
    else:
        desc = f"??? (0x{insn:08X})"
    
    marker = ""
    if "LDR" in desc and "#0x58" in desc: marker = "  <--- MUTEX?"
    if "BL" in desc and "BL " in desc: marker = "  <--- CALL"
    if "CBNZ" in desc and "#0x58" in desc: marker = "  <--- MUTEX CHECK?"
    print(f"  0x{off:08X}: {raw}  {desc}{marker}")
    if insn == 0xD65F03C0:
        break

print("\nDone.")
