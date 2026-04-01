#!/usr/bin/env python3
"""Decode the ORR bitmask immediate at 0x319A6A4 to find actual REGISTRYINDEX."""
import struct, os

SO = os.path.join(os.path.dirname(os.path.abspath(__file__)),
    "output/work_arm64/lib/arm64-v8a/libGame.so")
with open(SO, "rb") as f:
    data = f.read()

# ORR at 0x319A6A4: 0A 01 00 32 => 0x3200010A
insn = struct.unpack_from("<I", data, 0x319A6A4)[0]
print(f"ORR instruction: 0x{insn:08X}")

# Decode bitmask immediate for 32-bit ORR
# Format: ORR Wd, Wn, #imm
# sf=0, opc=01, N=0
rd = insn & 0x1F
rn = (insn >> 5) & 0x1F
N = (insn >> 22) & 1
immr = (insn >> 16) & 0x3F
imms = (insn >> 10) & 0x3F

print(f"  rd=w{rd}, rn=w{rn}, N={N}, immr={immr}, imms={imms}")

# Decode bitmask immediate (ARM64 encoding)
# For 32-bit: N must be 0
# len = highest set bit of (N:NOT(imms)) - gives element size
# S = imms, R = immr
# Pattern: (S+1) ones rotated right by R within element

def decode_bitmask_imm(N, imms, immr, is64):
    """Decode ARM64 logical immediate."""
    if is64:
        len_val = 6  # 64-bit
        if N == 1:
            len_val = 6
        else:
            # Find highest set bit of ~imms[5:0]
            combined = (~imms) & 0x3F
            for i in range(5, -1, -1):
                if combined & (1 << i):
                    len_val = i + 1
                    break
    else:
        # 32-bit: N must be 0
        combined = (~imms) & 0x3F
        len_val = None
        for i in range(5, -1, -1):
            if combined & (1 << i):
                len_val = i + 1
                break
        if len_val is None:
            return None
    
    esize = 1 << len_val
    mask = (1 << esize) - 1
    
    # S and R within element
    S = imms & (esize - 1)
    R = immr & (esize - 1)
    
    # Create pattern: (S+1) ones
    pattern = (1 << (S + 1)) - 1
    
    # Rotate right by R
    rotated = ((pattern >> R) | (pattern << (esize - R))) & mask
    
    # Replicate to fill 32 or 64 bits
    result = 0
    bits = 64 if is64 else 32
    for i in range(0, bits, esize):
        result |= rotated << i
    
    if not is64:
        result &= 0xFFFFFFFF
    
    return result

bitmask = decode_bitmask_imm(N, imms, immr, False)
print(f"  Bitmask = 0x{bitmask:08X}" if bitmask else "  Failed to decode bitmask")

# w8 = 0xFFF0B9D8 (-1001000)
w8 = 0xFFF0B9D8
if bitmask is not None:
    w10 = w8 | bitmask
    import ctypes
    print(f"  w8 OR bitmask = 0x{w10:08X}")
    print(f"  As signed = {ctypes.c_int32(w10).value}")
    print(f"  This is the value compared against idx (w1)")
    
    # The comparison is: CMP w1, w10  =>  if idx >= w10 (signed), branch to negative index handler
    # if idx == w8 (0x319A6B0: SUBS w10, w8, w1 then B.NE), it's REGISTRYINDEX
    # So the REGISTRYINDEX is w8 = -1001000, and the ORR creates a boundary check value

print(f"\nConclusion: LUA_REGISTRYINDEX = {ctypes.c_int32(w8).value} = -1001000")
print("The ORR creates a range check boundary, but the actual REGISTRYINDEX is -1001000")
print()
print("Logic flow:")
print("  if idx >= 1:  positive index (stack from bottom)")
print("  elif idx >= (w8|bitmask):  negative index (stack from top)")
print("  elif idx == w8:  REGISTRYINDEX -> L+0x20 offset 0x40")  
print("  else: upvalue/other pseudo-index")
