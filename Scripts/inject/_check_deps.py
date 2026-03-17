"""Check PE imports of Test.dll to find missing dependencies."""
import struct
from pathlib import Path

data = (Path(__file__).parent / "Test.dll").read_bytes()
pe_off = struct.unpack_from("<I", data, 0x3C)[0]
coff = pe_off + 4
num_sec = struct.unpack_from("<H", data, coff + 2)[0]
size_opt = struct.unpack_from("<H", data, coff + 16)[0]
opt = coff + 20
machine = struct.unpack_from("<H", data, coff)[0]

if machine == 0x8664:
    imp_rva, imp_sz = struct.unpack_from("<II", data, opt + 120)
    arch = "x64"
else:
    imp_rva, imp_sz = struct.unpack_from("<II", data, opt + 104)
    arch = "x86"

sec_off = opt + size_opt
sections = []
for i in range(num_sec):
    s = sec_off + i * 40
    va = struct.unpack_from("<I", data, s + 12)[0]
    raw_sz = struct.unpack_from("<I", data, s + 16)[0]
    raw_ptr = struct.unpack_from("<I", data, s + 20)[0]
    vs = struct.unpack_from("<I", data, s + 8)[0]
    sections.append((va, max(raw_sz, vs), raw_ptr, raw_sz))

def rva_to_off(rva):
    for va, sz, rp, rs in sections:
        if va <= rva < va + sz:
            return rva - va + rp
    return None

print(f"Architecture: {arch}")
print(f"Import DLLs:")

off = rva_to_off(imp_rva)
dlls = []
if off:
    i = 0
    while True:
        entry_off = off + i * 20
        name_rva = struct.unpack_from("<I", data, entry_off + 12)[0]
        if name_rva == 0:
            break
        name_off = rva_to_off(name_rva)
        if name_off:
            end = data.index(b"\x00", name_off)
            name = data[name_off:end].decode("ascii", errors="replace")
            dlls.append(name)
            print(f"  {name}")
        i += 1

print(f"\nTotal: {len(dlls)} import DLLs")

# Check which ones exist on disk next to Test.dll
dll_dir = Path(__file__).parent
print("\nAvailability check:")
for dll in dlls:
    local = dll_dir / dll
    sys32 = Path(r"C:\Windows\System32") / dll
    if local.exists():
        print(f"  {dll}: found locally")
    elif sys32.exists():
        print(f"  {dll}: system DLL")
    else:
        print(f"  {dll}: *** MISSING ***")
