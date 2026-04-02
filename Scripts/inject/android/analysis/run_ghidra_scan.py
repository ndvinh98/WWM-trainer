"""
run_ghidra_scan.py — Run Lua function scanner on the already-imported Ghidra project.

Uses PyGhidra (headless) to open the existing WWM_libGame project and scan
libGame.so for Lua API functions relevant to Android hooking.

Usage:
    python run_ghidra_scan.py
"""

import os
import sys
import time
from pathlib import Path
from collections import defaultdict

# Ghidra install dir
GHIDRA_INSTALL = Path(r"F:\Coding\Where Winds Meet\ghidra\ghidra")
PROJECT_DIR = Path(r"F:\Coding\Where Winds Meet\ghidra")
PROJECT_NAME = "WWM_libGame"
OUTPUT_DIR = Path(r"F:\Coding\Where Winds Meet\Scripts\inject\android\analysis")
OUTPUT_FILE = OUTPUT_DIR / "ghidra_lua_scan_results.txt"

# Set GHIDRA_INSTALL_DIR env var (PyGhidra needs this)
os.environ["GHIDRA_INSTALL_DIR"] = str(GHIDRA_INSTALL)

# ============================================================================
# Address mapping
# ELF VAs (from prior python analysis) differ from Ghidra VAs by a consistent
# delta of 0xB8634. Ghidra rebased the binary (Image Base = 0x100000).
# All addresses below are GHIDRA addresses (ELF VA - 0xB8634).
# ============================================================================
REBASE_DELTA = 0xB8634  # ELF_VA - GHIDRA_VA

# Original ELF VAs for reference (stored so we can report both)
ELF_VAS = {
    "luaopen_socket_core":        0x323D354,
    "luaopen_mime_core":          0x323D5D0,
    "luaopen_socket_serial":      0x3240E64,
    "luaopen_socket_unix":        0x3243044,
    "luaopen_memory_leak_checker":0x324AB0C,
    "lua_createtable":            0x3198664,
    "luaL_setfuncs":              0x319F8F4,
    "lua_setfield":               0x3196738,
    "luaD_rawrunprotected":       0x319DDD8,
    "luaD_precall":               0x31B3F0C,
    "luaV_execute":               0x31DA9F4,
    "luaD_protectedparser":       0x31B7010,
    "lua_load_wrapper":           0x31B2DE8,
    "lua_pcallk_candidate":       0x31B47F4,
    "dispatch_hook":              0x319E750,
    "luaD_call":                  0x3195D4C,
}

# Ghidra-rebased addresses (ELF VA - REBASE_DELTA)
KNOWN_VAS = {k: v - REBASE_DELTA for k, v in ELF_VAS.items()}

# Key hook targets with Ghidra VAs
HOOK_TARGETS = [
    ("lua_pcallk",          0x31B47F4 - REBASE_DELTA),
    ("lua_load",            0x31B2DE8 - REBASE_DELTA),
    ("luaD_pcall",          0x319E750 - REBASE_DELTA),
    ("luaD_precall",        0x31B3F0C - REBASE_DELTA),
    ("luaV_execute",        0x31DA9F4 - REBASE_DELTA),
    ("luaD_protectedparser",0x31B7010 - REBASE_DELTA),
    ("luaD_rawrunprotected",0x319DDD8 - REBASE_DELTA),
    ("luaD_call",           0x3195D4C - REBASE_DELTA),
    ("lua_createtable",     0x3198664 - REBASE_DELTA),
    ("lua_setfield",        0x3196738 - REBASE_DELTA),
    ("luaL_setfuncs",       0x319F8F4 - REBASE_DELTA),
]


def main():
    print("=" * 78)
    print("  PyGhidra Lua Function Scanner for libGame.so (ARM64)")
    print("=" * 78)
    print()

    # Start PyGhidra headless
    print("[*] Starting PyGhidra headless launcher...")
    from pyghidra import HeadlessPyGhidraLauncher
    launcher = HeadlessPyGhidraLauncher(verbose=True, install_dir=GHIDRA_INSTALL)
    launcher.start()

    print("[*] PyGhidra started, importing Ghidra modules...")

    import ghidra
    from ghidra.base.project import GhidraProject
    from ghidra.program.model.symbol import SymbolType
    from ghidra.program.model.listing import CodeUnit
    from java.io import File

    results = []
    results.append("=" * 78)
    results.append("  Ghidra Headless Lua Function Scanner for libGame.so (ARM64)")
    results.append("  Scan time: %s" % time.strftime("%Y-%m-%d %H:%M:%S"))
    results.append("  Rebase delta: 0x%X (ELF_VA - GHIDRA_VA)" % REBASE_DELTA)
    results.append("=" * 78)
    results.append("")

    start_time = time.time()

    # Open existing project
    print("[*] Opening existing project: %s/%s" % (PROJECT_DIR, PROJECT_NAME))
    project_file = File(str(PROJECT_DIR))
    project = GhidraProject.openProject(str(PROJECT_DIR), PROJECT_NAME)

    # Find libGame.so in the project
    print("[*] Looking for libGame.so in project...")
    program = project.openProgram("/", "libGame.so", False)

    if program is None:
        print("[!] ERROR: Could not find libGame.so in project!")
        project.close()
        return

    print("[+] Opened: %s" % program.getName())
    results.append("Program: %s" % program.getName())
    results.append("Language: %s" % program.getLanguageID())
    results.append("Image Base: 0x%s" % program.getImageBase())
    results.append("")

    fm = program.getFunctionManager()
    sm = program.getSymbolTable()
    listing = program.getListing()
    af = program.getAddressFactory()
    space = af.getDefaultAddressSpace()

    # Helper functions
    def get_bytes_at(addr, length):
        try:
            result = []
            mem = program.getMemory()
            for i in range(length):
                b = mem.getByte(addr.add(i))
                result.append(b & 0xFF)
            return result
        except:
            return []

    def bytes_to_hex(byte_list):
        return " ".join(["%02X" % b for b in byte_list])

    def get_prologue_sig(func, length=32):
        entry = func.getEntryPoint()
        raw = get_bytes_at(entry, length)
        return bytes_to_hex(raw)

    def get_function_size(func):
        return func.getBody().getNumAddresses()

    def count_bl(func):
        count = 0
        inst_iter = listing.getInstructions(func.getBody(), True)
        while inst_iter.hasNext():
            inst = inst_iter.next()
            if inst.getMnemonicString() == "bl":
                count += 1
        return count

    def count_blr(func):
        count = 0
        inst_iter = listing.getInstructions(func.getBody(), True)
        while inst_iter.hasNext():
            inst = inst_iter.next()
            if inst.getMnemonicString() == "blr":
                count += 1
        return count

    def has_sxtw(func):
        inst_iter = listing.getInstructions(func.getBody(), True)
        while inst_iter.hasNext():
            inst = inst_iter.next()
            if "sxtw" in inst.toString().lower():
                return True
        return False

    def get_bl_targets(func):
        targets = []
        inst_iter = listing.getInstructions(func.getBody(), True)
        while inst_iter.hasNext():
            inst = inst_iter.next()
            if inst.getMnemonicString() == "bl":
                refs = inst.getReferencesFrom()
                for ref in refs:
                    if ref.getReferenceType().isCall():
                        targets.append(ref.getToAddress())
        return targets

    def get_callers(func):
        from ghidra.program.model.symbol import RefType
        callers = set()
        rm = program.getReferenceManager()
        refs = rm.getReferencesTo(func.getEntryPoint())
        for ref in refs:
            if ref.getReferenceType().isCall():
                caller = fm.getFunctionContaining(ref.getFromAddress())
                if caller is not None:
                    callers.add(caller)
        return callers

    def get_xref_count(addr):
        rm = program.getReferenceManager()
        count = 0
        refs = rm.getReferencesTo(addr)
        for ref in refs:
            count += 1
            if count > 50000:  # Cap for performance
                break
        return count

    # ========================================================================
    # Step 1: Find exported luaopen_* symbols
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 1: Exported luaopen_* symbols")
    results.append("-" * 78)
    print("[*] Step 1: Finding luaopen_* symbols...")

    luaopen_funcs = []
    sym_iter = sm.getAllSymbols(True)
    for sym in sym_iter:
        name = sym.getName()
        if name.startswith("luaopen_"):
            addr = sym.getAddress()
            func = fm.getFunctionAt(addr)
            if func is not None:
                luaopen_funcs.append((name, func))
                sig = get_prologue_sig(func, 16)
                results.append("  %-40s VA=0x%s  sig=%s" % (name, addr, sig))

    results.append("")
    results.append("  Found %d luaopen_* functions" % len(luaopen_funcs))
    results.append("")
    print("[+] Found %d luaopen_* functions" % len(luaopen_funcs))

    # ========================================================================
    # Step 2: BL call-graph from luaopen_* (depth=2)
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 2: BL call-graph from luaopen_* (depth=2)")
    results.append("-" * 78)
    print("[*] Step 2: Tracing BL call-graph...")

    depth1 = defaultdict(set)
    for name, func in luaopen_funcs:
        for target in get_bl_targets(func):
            depth1[str(target)].add(name)

    results.append("  Depth-1 unique targets: %d" % len(depth1))

    depth2 = defaultdict(set)
    for addr_str, callers in list(depth1.items()):
        try:
            addr = af.getAddress(addr_str)
            func = fm.getFunctionAt(addr)
            if func is None:
                continue
            for sub in get_bl_targets(func):
                depth2[str(sub)].update(callers)
        except:
            pass

    all_targets = dict(depth1)
    for k, v in depth2.items():
        if k in all_targets:
            all_targets[k].update(v)
        else:
            all_targets[k] = v

    results.append("  Depth-2 unique targets: %d" % len(depth2))
    results.append("  Total unique targets: %d" % len(all_targets))
    results.append("")
    print("[+] Total unique call targets: %d" % len(all_targets))

    # ========================================================================
    # Step 3: Verify known VA addresses
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 3: Verification of known VA addresses")
    results.append("-" * 78)
    print("[*] Step 3: Verifying known VAs...")

    for known_name, known_va in sorted(KNOWN_VAS.items(), key=lambda x: x[1]):
        elf_va = known_va + REBASE_DELTA
        try:
            addr = space.getAddress(known_va)
            func = fm.getFunctionAt(addr)
            if func is not None:
                ghidra_name = func.getName()
                sig = get_prologue_sig(func, 16)
                fsize = get_function_size(func)
                xrefs = get_xref_count(addr)
                results.append("  %-35s ghidra=0x%08X  elf=0x%08X  name=%-25s size=%5d  xrefs=%d" %
                              (known_name, known_va, elf_va, ghidra_name, fsize, xrefs))
                results.append("    sig: %s" % sig)
            else:
                inst = listing.getInstructionAt(addr)
                if inst is not None:
                    raw = get_bytes_at(addr, 16)
                    results.append("  %-35s ghidra=0x%08X  elf=0x%08X  (no function, code exists)" % (known_name, known_va, elf_va))
                    results.append("    bytes: %s" % bytes_to_hex(raw))
                else:
                    results.append("  %-35s ghidra=0x%08X  elf=0x%08X  NOT FOUND" % (known_name, known_va, elf_va))
        except Exception as e:
            results.append("  %-35s ghidra=0x%08X  elf=0x%08X  ERROR: %s" % (known_name, known_va, elf_va, str(e)))

    results.append("")

    # ========================================================================
    # Step 4: Core API functions (called by 2+ luaopen_*)
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 4: Core API functions (called by 2+ luaopen_*)")
    results.append("-" * 78)
    print("[*] Step 4: Classifying core API functions...")

    core_funcs = []
    for addr_str, callers in sorted(all_targets.items(), key=lambda x: -len(x[1])):
        if len(callers) < 2:
            continue
        try:
            addr = af.getAddress(addr_str)
            func = fm.getFunctionAt(addr)
            if func is None:
                continue

            fsize = get_function_size(func)
            bl = count_bl(func)
            blr = count_blr(func)
            sxtw = has_sxtw(func)
            sig = get_prologue_sig(func, 32)
            xrefs = get_xref_count(func.getEntryPoint())

            guesses = []
            if blr >= 2 and fsize > 200:
                guesses.append("lua_load?")
            if sxtw and bl >= 1 and bl <= 5:
                guesses.append("lua_pcallk?")
            if fsize > 20000:
                guesses.append("luaV_execute?")
            if xrefs > 200 and fsize < 200:
                guesses.append("lua_createtable?")

            core_funcs.append((addr_str, func, len(callers), sig, bl, blr, sxtw, fsize, xrefs, guesses, callers))
        except:
            pass

    for addr_str, func, fan_in, sig, bl, blr, sxtw, fsize, xrefs, guesses, callers in core_funcs:
        results.append("")
        results.append("  VA=0x%-12s  fan-in=%d  name=%s" % (addr_str, fan_in, func.getName()))
        results.append("  sig: %s" % sig)
        results.append("  tags: bl=%d blr=%d size=%d sxtw=%s xrefs=%d" % (bl, blr, fsize, sxtw, xrefs))
        if guesses:
            results.append("  >>> GUESS: %s" % ", ".join(guesses))
        results.append("  called by: %s" % ", ".join(sorted(callers)))

    results.append("")
    results.append("  Total core API functions: %d" % len(core_funcs))
    results.append("")

    # ========================================================================
    # Step 5: Detailed analysis of key hook targets
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 5: Detailed analysis of key hook targets")
    results.append("-" * 78)
    print("[*] Step 5: Analyzing key hook targets...")

    for target_name, target_va in HOOK_TARGETS:
        elf_va = target_va + REBASE_DELTA
        results.append("")
        results.append("--- %s (ghidra=0x%08X  elf=0x%08X) ---" % (target_name, target_va, elf_va))
        try:
            addr = space.getAddress(target_va)
            func = fm.getFunctionAt(addr)
            if func is not None:
                sig = get_prologue_sig(func, 48)
                fsize = get_function_size(func)
                bl = count_bl(func)
                blr = count_blr(func)
                xrefs = get_xref_count(addr)

                results.append("  FOUND  name=%s  size=%d bytes (%.1f KB)" %
                              (func.getName(), fsize, fsize / 1024.0))
                results.append("  sig: %s" % sig)
                results.append("  tags: bl=%d blr=%d xrefs=%d" % (bl, blr, xrefs))

                # Show BL targets
                bl_targets = get_bl_targets(func)
                if bl_targets:
                    results.append("  BL call targets:")
                    for t in bl_targets[:15]:
                        tf = fm.getFunctionAt(t)
                        tname = tf.getName() if tf else "(unknown)"
                        results.append("    -> 0x%s  %s" % (t, tname))
                    if len(bl_targets) > 15:
                        results.append("    ... and %d more" % (len(bl_targets) - 15))

                # Show callers (limited)
                callers = get_callers(func)
                results.append("  Called by %d functions" % len(callers))
                for c in sorted(callers, key=lambda f: str(f.getEntryPoint()))[:10]:
                    results.append("    <- 0x%s  %s" % (c.getEntryPoint(), c.getName()))
                if len(callers) > 10:
                    results.append("    ... and %d more" % (len(callers) - 10))
            else:
                inst = listing.getInstructionAt(addr)
                if inst:
                    raw = get_bytes_at(addr, 32)
                    results.append("  NO FUNCTION (but code exists)")
                    results.append("  bytes: %s" % bytes_to_hex(raw))
                    # Try to find containing function
                    containing = fm.getFunctionContaining(addr)
                    if containing:
                        results.append("  Inside function: %s at 0x%s" %
                                      (containing.getName(), containing.getEntryPoint()))
                else:
                    results.append("  NOT FOUND (no code)")
        except Exception as e:
            results.append("  ERROR: %s" % str(e))

    results.append("")

    # ========================================================================
    # Step 6: Large functions (potential luaV_execute)
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 6: Large functions (>15KB)")
    results.append("-" * 78)
    print("[*] Step 6: Finding large functions...")

    large_funcs = []
    func_iter = fm.getFunctions(True)
    while func_iter.hasNext():
        f = func_iter.next()
        fsize = get_function_size(f)
        if fsize > 15000:
            large_funcs.append((f, fsize))

    large_funcs.sort(key=lambda x: -x[1])
    for f, fsize in large_funcs[:20]:
        sig = get_prologue_sig(f, 16)
        results.append("  VA=0x%s  size=%6d (%5.1f KB)  name=%s" %
                      (f.getEntryPoint(), fsize, fsize / 1024.0, f.getName()))
        results.append("    sig: %s" % sig)

    results.append("")

    # ========================================================================
    # Step 7: Functions with "lua" in name
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 7: Functions with 'lua' in name")
    results.append("-" * 78)
    print("[*] Step 7: Finding lua-named functions...")

    lua_named = []
    func_iter = fm.getFunctions(True)
    while func_iter.hasNext():
        f = func_iter.next()
        if "lua" in f.getName().lower():
            lua_named.append(f)

    results.append("  Found %d functions with 'lua' in name" % len(lua_named))
    for f in lua_named[:100]:
        fsize = get_function_size(f)
        results.append("  VA=0x%s  size=%5d  name=%s" % (f.getEntryPoint(), fsize, f.getName()))

    results.append("")

    # ========================================================================
    # Step 8: String references containing Lua keywords
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 8: String references with Lua keywords")
    results.append("-" * 78)
    print("[*] Step 8: Searching for Lua-related strings...")

    lua_strings = 0
    keywords = ["lua_", "lual_", "luad_", "luav_", "pcall", "loadfile",
                "loadstring", "require", "dofile", "luaopen", "lua_state",
                "attempt to", "stack overflow", "coroutine"]

    data_iter = listing.getDefinedData(True)
    count = 0
    max_check = 500000
    while data_iter.hasNext() and count < max_check:
        data = data_iter.next()
        count += 1
        if data.hasStringValue():
            try:
                val = str(data.getValue())
                if len(val) > 3 and any(kw in val.lower() for kw in keywords):
                    if lua_strings < 100:
                        addr = data.getAddress()
                        rm = program.getReferenceManager()
                        ref_funcs = []
                        refs = rm.getReferencesTo(addr)
                        for ref in refs:
                            rf = fm.getFunctionContaining(ref.getFromAddress())
                            if rf:
                                ref_funcs.append("0x%s(%s)" % (rf.getEntryPoint(), rf.getName()))
                        results.append("  0x%s: \"%s\"" % (addr, val[:100]))
                        if ref_funcs:
                            results.append("    refs: %s" % ", ".join(ref_funcs[:5]))
                    lua_strings += 1
            except:
                pass

    results.append("  Total lua-related strings: %d (searched %d items)" % (lua_strings, count))
    results.append("")

    # ========================================================================
    # Summary
    # ========================================================================
    elapsed = time.time() - start_time
    results.append("=" * 78)
    results.append("  SUMMARY — Key Hook Targets for Android Port")
    results.append("=" * 78)
    results.append("")
    results.append("  ┌─────────────────────────┬────────────────┬────────────────┬──────────┬─────────────────────────────┐")
    results.append("  │ Function                │ Ghidra VA      │ ELF VA         │ Size     │ Status                      │")
    results.append("  ├─────────────────────────┼────────────────┼────────────────┼──────────┼─────────────────────────────┤")

    for name, va in HOOK_TARGETS:
        elf_va = va + REBASE_DELTA
        try:
            addr = space.getAddress(va)
            func = fm.getFunctionAt(addr)
            if func:
                fsize = get_function_size(func)
                status = "FOUND (%s)" % func.getName()
                size_str = "%d B" % fsize
            else:
                # Check if it's inside a function
                containing = fm.getFunctionContaining(addr)
                if containing:
                    status = "INSIDE %s" % containing.getName()
                else:
                    status = "NO FUNCTION"
                size_str = "—"
        except:
            status = "ERROR"
            size_str = "—"
        results.append("  │ %-23s │ 0x%08X     │ 0x%08X     │ %8s │ %-27s │" % (name, va, elf_va, size_str, status))

    results.append("  └─────────────────────────┴────────────────┴────────────────┴──────────┴─────────────────────────────┘")
    results.append("")

    # Function count stats
    total_funcs = 0
    func_iter = fm.getFunctions(True)
    while func_iter.hasNext():
        func_iter.next()
        total_funcs += 1
    results.append("  Total functions in binary: %d" % total_funcs)
    results.append("  Scan completed in %.1f seconds" % elapsed)
    results.append("")

    # Write results
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        for line in results:
            f.write(line + "\n")
    print("[+] Results written to: %s" % OUTPUT_FILE)

    # Print summary to console
    print()
    for line in results[-20:]:
        print(line)

    # Clean up
    project.close()
    print("[*] Done!")


if __name__ == "__main__":
    main()
