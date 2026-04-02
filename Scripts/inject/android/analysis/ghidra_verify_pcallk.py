"""
ghidra_verify_pcallk.py — Verify FUN_030e55b0 as the real lua_pcallk.
"""
import os, time
from pathlib import Path

GHIDRA_INSTALL = Path(r"F:\Coding\Where Winds Meet\ghidra\ghidra")
PROJECT_DIR = Path(r"F:\Coding\Where Winds Meet\ghidra")
PROJECT_NAME = "WWM_libGame"
OUTPUT_FILE = Path(r"F:\Coding\Where Winds Meet\Scripts\inject\android\analysis\ghidra_verify_pcallk.txt")
os.environ["GHIDRA_INSTALL_DIR"] = str(GHIDRA_INSTALL)
REBASE_DELTA = 0xB8634

KNOWN = {
    "luaD_rawrunprotected": 0x030e5794,
    "luaD_precall": 0x030fb8c8,
    "luaV_execute": 0x031223ac,
    "luaD_protectedparser": 0x030fe9cc,
    "lua_load": 0x030fa7a4,
}

# Candidates to verify
CANDIDATES = [
    (0x030e55b0, "FUN_030e55b0 (rank#3, 151 callers, calls rawrun)"),
    (0x030e610c, "FUN_030e610c (old 'dispatch hook' containing func)"),
    (0x030fc1b0, "FUN_030fc1b0 (CURRENT candidate, 8 callers)"),
    (0x030fc12c, "FUN_030fc12c (6 callers, calls precall+execute)"),
    (0x030fb1d0, "FUN_030fb1d0 (2 callers, calls precall+execute)"),
]


def main():
    from pyghidra import HeadlessPyGhidraLauncher
    launcher = HeadlessPyGhidraLauncher(verbose=False, install_dir=GHIDRA_INSTALL)
    launcher.start()
    from ghidra.base.project import GhidraProject

    results = []
    project = GhidraProject.openProject(str(PROJECT_DIR), PROJECT_NAME)
    program = project.openProgram("/", "libGame.so", False)
    fm = program.getFunctionManager()
    listing = program.getListing()
    af = program.getAddressFactory()
    space = af.getDefaultAddressSpace()
    mem = program.getMemory()
    rm = program.getReferenceManager()

    def hex_bytes(addr, n):
        try:
            return " ".join("%02X" % (mem.getByte(addr.add(i)) & 0xFF) for i in range(n))
        except:
            return "?"

    def get_bl_targets(func):
        targets = []
        it = listing.getInstructions(func.getBody(), True)
        while it.hasNext():
            inst = it.next()
            if inst.getMnemonicString() == "bl":
                for ref in inst.getReferencesFrom():
                    if ref.getReferenceType().isCall():
                        targets.append((inst.getAddress(), ref.getToAddress()))
            elif inst.getMnemonicString() == "blr":
                targets.append((inst.getAddress(), None))
        return targets

    def get_callers(addr):
        callers = []
        for ref in rm.getReferencesTo(addr):
            if ref.getReferenceType().isCall():
                f = fm.getFunctionContaining(ref.getFromAddress())
                if f:
                    callers.append(f)
        return callers

    def dump_full(func, label):
        entry = func.getEntryPoint()
        entry_int = int(str(entry), 16)
        elf = entry_int + REBASE_DELTA
        size = func.getBody().getNumAddresses()
        callers = get_callers(entry)
        bl_targets = get_bl_targets(func)

        results.append("")
        results.append("=" * 70)
        results.append("  %s" % label)
        results.append("  ghidra=0x%08X  elf=0x%08X  size=%d  callers=%d" % (entry_int, elf, size, len(callers)))
        results.append("  prologue: %s" % hex_bytes(entry, 32))
        results.append("=" * 70)

        # Full disassembly
        results.append("  DISASSEMBLY:")
        it = listing.getInstructions(func.getBody(), True)
        count = 0
        while it.hasNext() and count < 120:
            inst = it.next()
            a = inst.getAddress()
            results.append("    0x%s  %s  %s" % (a, hex_bytes(a, 4), inst.toString()))
            count += 1

        # BL targets with known identification
        results.append("")
        results.append("  BL/BLR TARGETS (%d):" % len(bl_targets))
        for call_addr, target_addr in bl_targets:
            if target_addr is None:
                results.append("    0x%s -> BLR (indirect)" % call_addr)
                continue
            tf = fm.getFunctionAt(target_addr)
            tname = tf.getName() if tf else "?"
            tint = int(str(target_addr), 16)
            telf = tint + REBASE_DELTA
            known = ""
            for kn, kv in KNOWN.items():
                if kv == tint:
                    known = " <<<< %s" % kn
            results.append("    0x%s -> 0x%s elf=0x%08X %s%s" % (call_addr, target_addr, telf, tname, known))

        # Callers
        results.append("")
        results.append("  CALLERS (%d):" % len(callers))
        # Deduplicate
        seen = set()
        for cf in callers:
            ce = str(cf.getEntryPoint())
            if ce not in seen:
                seen.add(ce)
                ceint = int(ce, 16)
                ceelf = ceint + REBASE_DELTA
                results.append("    0x%s elf=0x%08X %s (size=%d)" % (ce, ceelf, cf.getName(), cf.getBody().getNumAddresses()))

        # Check if this function matches lua_pcallk pattern:
        # lua_pcallk(L, nargs, nresults, errfunc, ctx, k)
        # - Should manipulate L->ci, L->allowhook
        # - Should call luaD_rawrunprotected
        # - Should set up f_call struct {L, func, nresults}
        # - Should save/restore ci->callstatus
        calls_rawrun = any(t and int(str(t), 16) == KNOWN["luaD_rawrunprotected"] for _, t in bl_targets)
        calls_precall = any(t and int(str(t), 16) == KNOWN["luaD_precall"] for _, t in bl_targets)
        calls_execute = any(t and int(str(t), 16) == KNOWN["luaV_execute"] for _, t in bl_targets)
        calls_protparser = any(t and int(str(t), 16) == KNOWN["luaD_protectedparser"] for _, t in bl_targets)

        results.append("")
        results.append("  PATTERN MATCH:")
        results.append("    calls luaD_rawrunprotected: %s" % calls_rawrun)
        results.append("    calls luaD_precall: %s" % calls_precall)
        results.append("    calls luaV_execute: %s" % calls_execute)
        results.append("    calls luaD_protectedparser: %s" % calls_protparser)

        if calls_rawrun and not calls_precall and not calls_execute:
            results.append("    >>> STRONG MATCH for lua_pcallk (calls rawrun, not precall/execute)")
        elif calls_precall and calls_execute and not calls_rawrun:
            results.append("    >>> Matches luaD_callnoyield / luaD_call pattern")
        elif calls_rawrun and calls_protparser:
            results.append("    >>> Matches luaD_pcall pattern")

    for ghidra_va, label in CANDIDATES:
        addr = space.getAddress(ghidra_va)
        func = fm.getFunctionAt(addr)
        if func:
            dump_full(func, label)
        else:
            containing = fm.getFunctionContaining(addr)
            if containing:
                dump_full(containing, label + " (resolved to containing)")
            else:
                results.append("\n  %s: NO FUNCTION AT 0x%08X" % (label, ghidra_va))

    # Also analyze what calls lua_load
    results.append("")
    results.append("#" * 70)
    results.append("  BONUS: Who calls lua_load? (to find lua_pcallk)")
    results.append("#" * 70)
    load_addr = space.getAddress(KNOWN["lua_load"])
    load_callers = get_callers(load_addr)
    results.append("  lua_load has %d callers:" % len(load_callers))
    seen = set()
    for cf in load_callers:
        ce = str(cf.getEntryPoint())
        if ce not in seen:
            seen.add(ce)
            ceint = int(ce, 16)
            ceelf = ceint + REBASE_DELTA
            csize = cf.getBody().getNumAddresses()
            # Does this caller also call rawrunprotected?
            cf_targets = get_bl_targets(cf)
            cf_rawrun = any(t and int(str(t), 16) == KNOWN["luaD_rawrunprotected"] for _, t in cf_targets)
            cf_precall = any(t and int(str(t), 16) == KNOWN["luaD_precall"] for _, t in cf_targets)
            cf_callers = len(get_callers(cf.getEntryPoint()))
            results.append("    0x%s elf=0x%08X %s size=%d callers=%d rawrun=%s precall=%s" %
                          (ce, ceelf, cf.getName(), csize, cf_callers, cf_rawrun, cf_precall))

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        for line in results:
            f.write(line + "\n")
    print("[+] Written to %s" % OUTPUT_FILE)
    for line in results:
        print(line)
    project.close()

if __name__ == "__main__":
    main()
