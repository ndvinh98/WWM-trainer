"""
ghidra_deep_scan.py — Deep analysis of lua_pcallk candidate and related functions.
Focuses on verifying whether FUN_030fc1b0 is really lua_pcallk.

Key questions:
1. What does FUN_030fc1b0 actually do? (size, callers, callees)
2. Does it call luaD_rawrunprotected (characteristic of lua_pcallk)?
3. How many callers does it have? (should be very many if it's lua_pcall/pcallk)
4. What other functions near the corrected VA could be lua_pcallk?
5. Scan for the REAL lua_pcallk by structural pattern matching.
"""

import os
import sys
import time
from pathlib import Path
from collections import defaultdict

GHIDRA_INSTALL = Path(r"F:\Coding\Where Winds Meet\ghidra\ghidra")
PROJECT_DIR = Path(r"F:\Coding\Where Winds Meet\ghidra")
PROJECT_NAME = "WWM_libGame"
OUTPUT_DIR = Path(r"F:\Coding\Where Winds Meet\Scripts\inject\android\analysis")
OUTPUT_FILE = OUTPUT_DIR / "ghidra_deep_scan_results.txt"

os.environ["GHIDRA_INSTALL_DIR"] = str(GHIDRA_INSTALL)

REBASE_DELTA = 0xB8634

# Known Ghidra function addresses (from prior scan)
KNOWN_GHIDRA = {
    "luaD_rawrunprotected": 0x030e5794,  # 288 bytes, 30800 xrefs
    "luaD_precall":         0x030fb8c8,
    "luaV_execute":         0x031223ac,  # 28524 bytes
    "luaD_protectedparser": 0x030fe9cc,
    "lua_createtable":      0x030e0020,
    "lua_setfield":         0x030de0f4,  # 220 bytes, 3762 xrefs
    "luaL_setfuncs":        0x030e72b0,
    "luaD_call":            0x030dd708,
}

# The supposed lua_pcallk function and its old BL-target VA
PCALLK_FUNC_START = 0x030fc1b0   # Ghidra func start
PCALLK_OLD_VA     = 0x030fc1c0   # Old VA (0x10 into function)
LOAD_FUNC_START   = 0x030fa7a4
LOAD_OLD_VA       = 0x030fa7b4


def main():
    print("=" * 78)
    print("  Deep Ghidra Analysis: lua_pcallk Verification")
    print("=" * 78)

    from pyghidra import HeadlessPyGhidraLauncher
    launcher = HeadlessPyGhidraLauncher(verbose=False, install_dir=GHIDRA_INSTALL)
    launcher.start()

    from ghidra.base.project import GhidraProject

    results = []
    results.append("=" * 78)
    results.append("  Deep Ghidra Analysis: lua_pcallk Verification")
    results.append("  Time: %s" % time.strftime("%Y-%m-%d %H:%M:%S"))
    results.append("=" * 78)
    results.append("")

    project = GhidraProject.openProject(str(PROJECT_DIR), PROJECT_NAME)
    program = project.openProgram("/", "libGame.so", False)

    fm = program.getFunctionManager()
    listing = program.getListing()
    af = program.getAddressFactory()
    space = af.getDefaultAddressSpace()
    mem = program.getMemory()
    rm = program.getReferenceManager()

    def get_bytes_hex(addr, n):
        try:
            bs = []
            for i in range(n):
                bs.append(mem.getByte(addr.add(i)) & 0xFF)
            return " ".join("%02X" % b for b in bs)
        except:
            return "(read error)"

    def get_func_size(func):
        return func.getBody().getNumAddresses()

    def get_bl_targets(func):
        targets = []
        inst_iter = listing.getInstructions(func.getBody(), True)
        while inst_iter.hasNext():
            inst = inst_iter.next()
            if inst.getMnemonicString() == "bl":
                for ref in inst.getReferencesFrom():
                    if ref.getReferenceType().isCall():
                        targets.append((inst.getAddress(), ref.getToAddress()))
        return targets

    def get_callers(addr):
        callers = []
        refs = rm.getReferencesTo(addr)
        for ref in refs:
            if ref.getReferenceType().isCall():
                caller_func = fm.getFunctionContaining(ref.getFromAddress())
                if caller_func:
                    callers.append((ref.getFromAddress(), caller_func))
        return callers

    def dump_instructions(func, max_insts=80):
        lines = []
        inst_iter = listing.getInstructions(func.getBody(), True)
        count = 0
        while inst_iter.hasNext() and count < max_insts:
            inst = inst_iter.next()
            addr = inst.getAddress()
            raw = get_bytes_hex(addr, 4)
            lines.append("    0x%s  %s  %s" % (addr, raw, inst.toString()))
            count += 1
        return lines

    def analyze_function(ghidra_va, label, detail_level="full"):
        """Deep analysis of a function at given Ghidra VA."""
        elf_va = ghidra_va + REBASE_DELTA
        addr = space.getAddress(ghidra_va)
        func = fm.getFunctionAt(addr)

        results.append("")
        results.append("=" * 70)
        results.append("  %s" % label)
        results.append("  Ghidra VA: 0x%08X   ELF VA: 0x%08X" % (ghidra_va, elf_va))
        results.append("=" * 70)

        if func is None:
            # Check if addr is inside a function
            containing = fm.getFunctionContaining(addr)
            if containing:
                results.append("  !! NOT at function start !!")
                results.append("  Containing function: %s at 0x%s" % (containing.getName(), containing.getEntryPoint()))
                results.append("  Offset into function: +0x%X" % (ghidra_va - int(str(containing.getEntryPoint()), 16)))
                func = containing
            else:
                results.append("  NO FUNCTION at this address")
                return None

        entry = func.getEntryPoint()
        fsize = get_func_size(func)
        results.append("  Function: %s" % func.getName())
        results.append("  Entry: 0x%s (ELF: 0x%X)" % (entry, int(str(entry), 16) + REBASE_DELTA))
        results.append("  Size: %d bytes (%.1f KB)" % (fsize, fsize / 1024.0))
        results.append("  Prologue (32 bytes): %s" % get_bytes_hex(entry, 32))

        # BL targets (what this function calls)
        bl_targets = get_bl_targets(func)
        results.append("")
        results.append("  BL call targets (%d):" % len(bl_targets))
        for call_addr, target_addr in bl_targets:
            target_func = fm.getFunctionAt(target_addr)
            tname = target_func.getName() if target_func else "(unknown)"
            telf = int(str(target_addr), 16) + REBASE_DELTA

            # Check if target is a known function
            known_label = ""
            target_int = int(str(target_addr), 16)
            for kname, kva in KNOWN_GHIDRA.items():
                if kva == target_int:
                    known_label = " <<< %s" % kname
                    break

            results.append("    at 0x%s -> 0x%s elf=0x%08X %s%s" %
                          (call_addr, target_addr, telf, tname, known_label))

        # Callers (who calls this function)
        callers = get_callers(entry)
        results.append("")
        results.append("  Callers / xrefs-to (%d):" % len(callers))
        for call_from, caller_func in callers[:30]:
            celf = int(str(caller_func.getEntryPoint()), 16) + REBASE_DELTA
            results.append("    from 0x%s in %s (elf=0x%08X)" %
                          (call_from, caller_func.getName(), celf))
        if len(callers) > 30:
            results.append("    ... and %d more callers" % (len(callers) - 30))

        # Disassembly
        if detail_level == "full":
            results.append("")
            results.append("  Disassembly (first 80 instructions):")
            for line in dump_instructions(func, 80):
                results.append(line)

        return func

    # ========================================================================
    # 1. Analyze the supposed lua_pcallk (FUN_030fc1b0)
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 1: Supposed lua_pcallk candidate")
    results.append("#" * 78)

    pcallk_func = analyze_function(PCALLK_FUNC_START, "FUN_030fc1b0 (supposed lua_pcallk)")

    # Also check what's at the OLD VA directly
    results.append("")
    results.append("--- What's at the OLD VA 0x030fc1c0 (elf 0x31B47F4)? ---")
    old_addr = space.getAddress(PCALLK_OLD_VA)
    inst = listing.getInstructionAt(old_addr)
    if inst:
        results.append("  Instruction: %s" % inst.toString())
        results.append("  Bytes: %s" % get_bytes_hex(old_addr, 4))
    else:
        results.append("  No instruction at this address")

    # ========================================================================
    # 2. Analyze the supposed lua_load (FUN_030fa7a4)
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 2: Supposed lua_load candidate")
    results.append("#" * 78)

    analyze_function(LOAD_FUNC_START, "FUN_030fa7a4 (supposed lua_load)")

    # ========================================================================
    # 3. Search for the REAL lua_pcallk by structural pattern
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 3: Structural search for lua_pcallk")
    results.append("  Pattern: calls luaD_rawrunprotected (0x030e5794)")
    results.append("           + medium size (100-800 bytes)")
    results.append("           + many callers (>50)")
    results.append("#" * 78)

    # Find all functions that call luaD_rawrunprotected
    rawrun_addr = space.getAddress(KNOWN_GHIDRA["luaD_rawrunprotected"])
    rawrun_callers = get_callers(rawrun_addr)
    results.append("")
    results.append("  Functions calling luaD_rawrunprotected (%d):" % len(rawrun_callers))

    # For each caller, analyze it as a pcallk candidate
    caller_funcs = set()
    for call_from, caller_func in rawrun_callers:
        caller_funcs.add(caller_func)

    pcallk_candidates = []
    for func in caller_funcs:
        fsize = get_func_size(func)
        entry = func.getEntryPoint()
        entry_int = int(str(entry), 16)
        elf_va = entry_int + REBASE_DELTA

        # Count callers of this function
        func_callers = get_callers(entry)
        caller_count = len(func_callers)

        # Get BL targets
        bl_targets = get_bl_targets(func)
        bl_count = len(bl_targets)

        # Check what it calls
        calls_precall = False
        calls_rawrun = False
        calls_execute = False
        target_names = []
        for _, target in bl_targets:
            target_int = int(str(target), 16)
            if target_int == KNOWN_GHIDRA["luaD_rawrunprotected"]:
                calls_rawrun = True
            if target_int == KNOWN_GHIDRA["luaD_precall"]:
                calls_precall = True
            if target_int == KNOWN_GHIDRA["luaV_execute"]:
                calls_execute = True
            tf = fm.getFunctionAt(target)
            if tf:
                target_names.append(tf.getName())

        info = {
            "func": func,
            "entry_ghidra": entry_int,
            "entry_elf": elf_va,
            "size": fsize,
            "callers": caller_count,
            "bl_count": bl_count,
            "calls_rawrun": calls_rawrun,
            "calls_precall": calls_precall,
            "calls_execute": calls_execute,
            "target_names": target_names,
        }
        pcallk_candidates.append(info)

        results.append("")
        results.append("  0x%08X (elf=0x%08X) %s  size=%d  callers=%d  BLs=%d" %
                      (entry_int, elf_va, func.getName(), fsize, caller_count, bl_count))
        results.append("    calls: rawrun=%s precall=%s execute=%s" %
                      (calls_rawrun, calls_precall, calls_execute))
        results.append("    prologue: %s" % get_bytes_hex(entry, 16))
        results.append("    BL targets: %s" % ", ".join(target_names[:10]))

    results.append("")

    # Rank candidates: lua_pcallk should call rawrunprotected and have MANY callers
    results.append("-" * 70)
    results.append("  RANKED lua_pcallk candidates (sorted by caller count):")
    results.append("-" * 70)
    pcallk_candidates.sort(key=lambda x: -x["callers"])
    for i, c in enumerate(pcallk_candidates[:15]):
        marker = ""
        if c["entry_ghidra"] == PCALLK_FUNC_START:
            marker = " <<<< CURRENT CANDIDATE"
        results.append("  #%d  0x%08X (elf=0x%08X)  callers=%d  size=%d  rawrun=%s precall=%s %s" %
                      (i + 1, c["entry_ghidra"], c["entry_elf"], c["callers"],
                       c["size"], c["calls_rawrun"], c["calls_precall"], marker))

    # ========================================================================
    # 4. Check ALL functions that call luaD_precall
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 4: Functions calling luaD_precall (0x030fb8c8)")
    results.append("  These are candidates for lua_pcallk / luaD_call / lua_callk")
    results.append("#" * 78)

    precall_addr = space.getAddress(KNOWN_GHIDRA["luaD_precall"])
    precall_callers = get_callers(precall_addr)
    results.append("")
    results.append("  Found %d functions calling luaD_precall:" % len(precall_callers))

    precall_caller_funcs = set()
    for call_from, caller_func in precall_callers:
        precall_caller_funcs.add(caller_func)

    for func in sorted(precall_caller_funcs, key=lambda f: str(f.getEntryPoint())):
        entry = func.getEntryPoint()
        entry_int = int(str(entry), 16)
        elf_va = entry_int + REBASE_DELTA
        fsize = get_func_size(func)
        func_callers_count = len(get_callers(entry))

        # What does this function call?
        bl_targets = get_bl_targets(func)
        calls_rawrun = any(int(str(t), 16) == KNOWN_GHIDRA["luaD_rawrunprotected"] for _, t in bl_targets)
        calls_execute = any(int(str(t), 16) == KNOWN_GHIDRA["luaV_execute"] for _, t in bl_targets)

        marker = ""
        if entry_int == PCALLK_FUNC_START:
            marker = " <<<< CURRENT CANDIDATE"

        results.append("  0x%08X (elf=0x%08X) %s  size=%d  callers=%d  rawrun=%s execute=%s%s" %
                      (entry_int, elf_va, func.getName(), fsize, func_callers_count,
                       calls_rawrun, calls_execute, marker))

    # ========================================================================
    # 5. Analyze ALL functions near the pcallk region (0x030fb000 - 0x03100000)
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 5: All functions in region 0x030fb000 - 0x03100000")
    results.append("  (near the supposed lua_pcallk)")
    results.append("#" * 78)

    region_start = space.getAddress(0x030fb000)
    region_end = space.getAddress(0x03100000)

    func_iter = fm.getFunctions(region_start, True)
    region_funcs = []
    while func_iter.hasNext():
        f = func_iter.next()
        entry_int = int(str(f.getEntryPoint()), 16)
        if entry_int > int(str(region_end), 16):
            break
        fsize = get_func_size(f)
        callers_count = len(get_callers(f.getEntryPoint()))

        bl_targets = get_bl_targets(f)
        calls_rawrun = any(int(str(t), 16) == KNOWN_GHIDRA["luaD_rawrunprotected"] for _, t in bl_targets)
        calls_precall = any(int(str(t), 16) == KNOWN_GHIDRA["luaD_precall"] for _, t in bl_targets)

        elf_va = entry_int + REBASE_DELTA
        marker = ""
        if entry_int == PCALLK_FUNC_START:
            marker = " <<<< CURRENT lua_pcallk CANDIDATE"
        if entry_int == LOAD_FUNC_START:
            marker = " <<<< CURRENT lua_load CANDIDATE"

        results.append("  0x%08X (elf=0x%08X) %-25s size=%5d callers=%5d rawrun=%s precall=%s%s" %
                      (entry_int, elf_va, f.getName(), fsize, callers_count,
                       calls_rawrun, calls_precall, marker))
        region_funcs.append((f, entry_int, fsize, callers_count, calls_rawrun, calls_precall))

    # ========================================================================
    # 6. Check if the OLD VA (pre-correction) works better as a hook point
    # ========================================================================
    results.append("")
    results.append("#" * 78)
    results.append("  SECTION 6: Analysis at OLD (uncorrected) VAs")
    results.append("  Checking if the old VAs pointed to better hook points")
    results.append("#" * 78)

    for label, old_ghidra_va in [
        ("lua_pcallk OLD", PCALLK_OLD_VA),
        ("lua_load OLD", LOAD_OLD_VA),
    ]:
        elf_va = old_ghidra_va + REBASE_DELTA
        addr = space.getAddress(old_ghidra_va)
        func = fm.getFunctionContaining(addr)
        if func:
            entry = func.getEntryPoint()
            entry_int = int(str(entry), 16)
            offset = old_ghidra_va - entry_int
            results.append("")
            results.append("  %s: ghidra=0x%08X elf=0x%08X" % (label, old_ghidra_va, elf_va))
            results.append("    Inside: %s at 0x%s (offset +0x%X = +%d bytes)" %
                          (func.getName(), entry, offset, offset))
            results.append("    Function size: %d" % get_func_size(func))
            results.append("    Callers: %d" % len(get_callers(entry)))

            # Show what instruction is at the old VA
            inst = listing.getInstructionAt(addr)
            if inst:
                results.append("    Instruction at old VA: %s" % inst.toString())
                # Show the 5 instructions before
                results.append("    Context (5 insts before):")
                temp_addr = addr
                prev_insts = []
                for _ in range(5):
                    prev_inst = listing.getInstructionBefore(temp_addr)
                    if prev_inst:
                        prev_insts.append("      0x%s  %s" % (prev_inst.getAddress(), prev_inst.toString()))
                        temp_addr = prev_inst.getAddress()
                for line in reversed(prev_insts):
                    results.append(line)
                results.append("    >>> 0x%s  %s  <-- OLD VA" % (addr, inst.toString()))
                # And 5 after
                temp_addr = addr
                for _ in range(5):
                    next_inst = listing.getInstructionAfter(temp_addr)
                    if next_inst:
                        results.append("      0x%s  %s" % (next_inst.getAddress(), next_inst.toString()))
                        temp_addr = next_inst.getAddress()

    # ========================================================================
    # Summary
    # ========================================================================
    results.append("")
    results.append("=" * 78)
    results.append("  VERDICT")
    results.append("=" * 78)

    # Find the best pcallk candidate
    if pcallk_candidates:
        best = pcallk_candidates[0]  # Highest caller count
        results.append("")
        results.append("  Best lua_pcallk candidate by caller count:")
        results.append("    0x%08X (elf=0x%08X) callers=%d size=%d" %
                      (best["entry_ghidra"], best["entry_elf"], best["callers"], best["size"]))
        if best["entry_ghidra"] != PCALLK_FUNC_START:
            results.append("    !! DIFFERS from current candidate 0x%08X !!" % PCALLK_FUNC_START)
            results.append("    The current candidate (0x%08X) has only %d callers" %
                          (PCALLK_FUNC_START,
                           next((c["callers"] for c in pcallk_candidates
                                 if c["entry_ghidra"] == PCALLK_FUNC_START), 0)))

    # Write output
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        for line in results:
            f.write(line + "\n")
    print("[+] Results written to: %s" % OUTPUT_FILE)

    for line in results:
        print(line)

    project.close()
    print("[*] Done!")


if __name__ == "__main__":
    main()
