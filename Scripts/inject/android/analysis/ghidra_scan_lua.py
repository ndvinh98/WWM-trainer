# ghidra_scan_lua.py — Ghidra Headless Jython script
# Scans libGame.so (ARM64) for Lua API functions relevant to hooking.
#
# Strategy:
#   1. Find all exported luaopen_* symbols
#   2. Trace call-graph (BL instructions) from luaopen_* to find internal Lua API
#   3. Cross-reference known VA addresses from sig_config.h
#   4. Classify functions by ARM64 heuristics (frame size, register usage, etc.)
#   5. Find lua_pcallk, lua_load, luaD_pcall, luaV_execute, etc.
#
# Usage (Ghidra headless):
#   analyzeHeadless <project_dir> <project_name> \
#       -import libGame.so -processor AARCH64:LE:64:v8A \
#       -postScript ghidra_scan_lua.py \
#       -scriptlog scan_lua_log.txt
#
# @category Analysis

import os
import sys
import time
from collections import defaultdict

from ghidra.program.model.symbol import SymbolType
from ghidra.program.model.listing import CodeUnit
from ghidra.program.model.block import BasicBlockModel
from ghidra.app.decompiler import DecompileOptions, DecompInterface

# ============================================================================
# Known VA addresses from sig_config.h / inject_android.cpp
# These are the expected virtual addresses for the CURRENT binary version.
# ============================================================================
KNOWN_VAS = {
    # Exported
    "luaopen_socket_core":        0x323D354,
    "luaopen_mime_core":          0x323D5D0,
    "luaopen_socket_serial":      0x3240E64,
    "luaopen_socket_unix":        0x3243044,
    "luaopen_memory_leak_checker":0x324AB0C,
    # Internal API (from prior analysis)
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
    "luaD_pcall_candidate":       0x319E750,
    "luaD_call":                  0x3195D4C,
}

# Functions we are most interested in finding for hooking
TARGET_FUNCTIONS = [
    "lua_pcall",
    "lua_pcallk",
    "lua_load",
    "luaL_loadbufferx",
    "luaL_loadstring",
    "luaL_dostring",
    "luaD_pcall",
    "luaD_call",
    "luaD_precall",
    "luaD_protectedparser",
    "luaD_rawrunprotected",
    "luaV_execute",
    "lua_createtable",
    "lua_setfield",
    "lua_getfield",
    "lua_pushstring",
    "lua_pushcclosure",
    "lua_settop",
    "lua_gettop",
    "luaL_setfuncs",
    "lua_newstate",
    "luaL_newstate",
    "lua_close",
]

# ============================================================================
# Output file path
# ============================================================================
OUTPUT_DIR = r"F:\Coding\Where Winds Meet\Scripts\inject\android\analysis"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "ghidra_lua_scan_results.txt")


def log(msg):
    """Print to both console and println (Ghidra script log)."""
    println(str(msg))


def write_results(lines):
    """Write results to output file."""
    try:
        if not os.path.exists(OUTPUT_DIR):
            os.makedirs(OUTPUT_DIR)
        with open(OUTPUT_FILE, "w") as f:
            for line in lines:
                f.write(str(line) + "\n")
        log("Results written to: %s" % OUTPUT_FILE)
    except Exception as e:
        log("ERROR writing results: %s" % str(e))


def get_bytes_at(addr, length):
    """Read bytes from the program at given address."""
    try:
        result = []
        for i in range(length):
            b = getByte(addr.add(i))
            result.append(b & 0xFF)
        return result
    except:
        return []


def bytes_to_hex(byte_list):
    """Convert byte list to hex string."""
    return " ".join(["%02X" % b for b in byte_list])


def get_function_prologue_sig(func, length=32):
    """Get the first N bytes of a function as a signature."""
    entry = func.getEntryPoint()
    raw = get_bytes_at(entry, length)
    return bytes_to_hex(raw)


def count_bl_calls(func):
    """Count BL (branch and link) instructions in a function."""
    count = 0
    body = func.getBody()
    listing = currentProgram.getListing()
    inst_iter = listing.getInstructions(body, True)
    while inst_iter.hasNext():
        inst = inst_iter.next()
        mnemonic = inst.getMnemonicString()
        if mnemonic == "bl":
            count += 1
    return count


def count_blr_calls(func):
    """Count BLR (indirect branch and link) instructions."""
    count = 0
    body = func.getBody()
    listing = currentProgram.getListing()
    inst_iter = listing.getInstructions(body, True)
    while inst_iter.hasNext():
        inst = inst_iter.next()
        mnemonic = inst.getMnemonicString()
        if mnemonic == "blr":
            count += 1
    return count


def get_function_size(func):
    """Get the size of a function in bytes."""
    body = func.getBody()
    return body.getNumAddresses()


def get_frame_size(func):
    """Try to extract the stack frame size from function prologue."""
    entry = func.getEntryPoint()
    listing = currentProgram.getListing()
    inst = listing.getInstructionAt(entry)
    if inst is None:
        return 0

    mnemonic = inst.getMnemonicString()
    # SUB sp, sp, #imm pattern
    rep = inst.toString()
    if "sub" in rep.lower() and "sp" in rep.lower():
        # Try to extract immediate
        try:
            for op_idx in range(inst.getNumOperands()):
                op_rep = inst.getDefaultOperandRepresentation(op_idx)
                if op_rep.startswith("#") or op_rep.startswith("0x"):
                    val = op_rep.replace("#", "").replace("0x", "")
                    return int(val, 16) if "x" in op_rep.lower() else int(val)
        except:
            pass

    return 0


def has_sxtw(func):
    """Check if function uses SXTW (sign-extend word) instruction."""
    body = func.getBody()
    listing = currentProgram.getListing()
    inst_iter = listing.getInstructions(body, True)
    while inst_iter.hasNext():
        inst = inst_iter.next()
        rep = inst.toString().lower()
        if "sxtw" in rep:
            return True
    return False


def get_bl_targets(func):
    """Get all BL call targets from a function."""
    targets = []
    body = func.getBody()
    listing = currentProgram.getListing()
    inst_iter = listing.getInstructions(body, True)
    while inst_iter.hasNext():
        inst = inst_iter.next()
        mnemonic = inst.getMnemonicString()
        if mnemonic == "bl":
            refs = inst.getReferencesFrom()
            for ref in refs:
                if ref.getReferenceType().isCall():
                    targets.append(ref.getToAddress())
    return targets


def get_calling_functions(func):
    """Get all functions that call this function (callers/xrefs-to)."""
    callers = set()
    entry = func.getEntryPoint()
    refs = getReferencesTo(entry)
    for ref in refs:
        if ref.getReferenceType().isCall():
            caller_func = getFunctionContaining(ref.getFromAddress())
            if caller_func is not None:
                callers.add(caller_func)
    return callers


def classify_function(func):
    """Classify a function based on ARM64 heuristics."""
    tags = {}
    tags["bl_calls"] = count_bl_calls(func)
    tags["blr_indirect"] = count_blr_calls(func)
    tags["size"] = get_function_size(func)
    tags["frame_size"] = get_frame_size(func)
    tags["has_sxtw"] = has_sxtw(func)
    tags["callers"] = len(get_calling_functions(func))
    return tags


def guess_lua_function(func, tags, sig):
    """
    Heuristic classification of Lua functions based on code patterns.
    Returns list of possible identifications.
    """
    guesses = []
    size = tags["size"]
    bl_calls = tags["bl_calls"]
    blr_indirect = tags["blr_indirect"]
    frame_size = tags["frame_size"]
    callers_count = tags["callers"]

    # lua_load: uses BLR (indirect call to reader callback), large frame
    if blr_indirect >= 2 and frame_size >= 0x100:
        guesses.append("lua_load")

    # lua_pcallk: zeros out k/ctx, sign-extends nargs/nresults
    if tags["has_sxtw"] and bl_calls >= 1 and bl_calls <= 5:
        # Check for MOV xN, #0 pattern (zeroing k/ctx)
        guesses.append("lua_pcallk?")

    # luaD_pcall: medium frame with setjmp-like behavior
    if frame_size >= 0x30 and frame_size <= 0x60 and bl_calls >= 2 and bl_calls <= 8:
        # Could be luaD_pcall
        if callers_count > 100:
            guesses.append("luaD_pcall?")

    # luaD_rawrunprotected: very large frame (0x1D0+) for setjmp buffer
    if frame_size >= 0x1C0:
        guesses.append("luaD_rawrunprotected")

    # luaV_execute: very large function (27KB+)
    if size > 20000:
        guesses.append("luaV_execute")

    # luaD_protectedparser: medium-large, calls rawrunprotected
    if frame_size >= 0x60 and bl_calls >= 3:
        guesses.append("luaD_protectedparser?")

    # lua_createtable: small, called by all luaopen
    if size < 200 and callers_count > 200:
        guesses.append("lua_createtable?")

    return guesses


def run():
    """Main analysis entry point."""
    start_time = time.time()
    results = []
    results.append("=" * 78)
    results.append("  Ghidra Headless Lua Function Scanner for libGame.so (ARM64)")
    results.append("  Scan time: %s" % time.strftime("%Y-%m-%d %H:%M:%S"))
    results.append("=" * 78)
    results.append("")

    program = currentProgram
    if program is None:
        log("ERROR: No program loaded!")
        return

    results.append("Program: %s" % program.getName())
    results.append("Language: %s" % program.getLanguageID())
    results.append("Image Base: 0x%s" % program.getImageBase())
    results.append("")

    fm = program.getFunctionManager()
    sm = program.getSymbolTable()
    listing = program.getListing()
    address_factory = program.getAddressFactory()
    space = address_factory.getDefaultAddressSpace()

    # ========================================================================
    # Step 1: Find all exported luaopen_* symbols
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 1: Exported luaopen_* symbols")
    results.append("-" * 78)

    luaopen_funcs = []
    all_symbols = sm.getAllSymbols(True)
    for sym in all_symbols:
        name = sym.getName()
        if name.startswith("luaopen_"):
            addr = sym.getAddress()
            func = fm.getFunctionAt(addr)
            if func is not None:
                luaopen_funcs.append((name, func))
                results.append("  %-40s  VA=0x%s" % (name, addr))
            else:
                results.append("  %-40s  VA=0x%s (NO FUNCTION)" % (name, addr))

    results.append("")
    results.append("  Found %d luaopen_* functions" % len(luaopen_funcs))
    results.append("")

    if len(luaopen_funcs) == 0:
        results.append("WARNING: No luaopen_* found. Checking all exported symbols...")
        ext_symbols = sm.getExternalSymbols()
        # Also check dynamic symbols
        sym_iter = sm.getAllSymbols(True)
        exported_count = 0
        for sym in sym_iter:
            if sym.isExternalEntryPoint() or sym.getSymbolType() == SymbolType.FUNCTION:
                name = sym.getName()
                if "lua" in name.lower():
                    results.append("  Found: %-40s  VA=0x%s" % (name, sym.getAddress()))
                    exported_count += 1
        results.append("  Total lua-related symbols: %d" % exported_count)
        results.append("")

    # ========================================================================
    # Step 2: Trace BL call targets from luaopen_* (depth=2)
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 2: BL call-graph from luaopen_* (depth=2)")
    results.append("-" * 78)

    # depth=1 targets
    depth1_targets = defaultdict(set)  # addr -> set of calling luaopen names
    depth2_targets = defaultdict(set)

    for name, func in luaopen_funcs:
        targets = get_bl_targets(func)
        for target_addr in targets:
            key = str(target_addr)
            depth1_targets[key].add(name)

    results.append("  Depth-1 unique targets: %d" % len(depth1_targets))

    # depth=2: follow one more level
    for addr_str, callers in list(depth1_targets.items()):
        try:
            addr = address_factory.getAddress(addr_str)
            func = fm.getFunctionAt(addr)
            if func is None:
                continue
            sub_targets = get_bl_targets(func)
            for sub_addr in sub_targets:
                sub_key = str(sub_addr)
                depth2_targets[sub_key].update(callers)
        except:
            pass

    # Merge depth1 and depth2
    all_targets = dict(depth1_targets)
    for k, v in depth2_targets.items():
        if k in all_targets:
            all_targets[k].update(v)
        else:
            all_targets[k] = v

    results.append("  Depth-2 unique targets: %d" % len(depth2_targets))
    results.append("  Total unique call targets: %d" % len(all_targets))
    results.append("")

    # ========================================================================
    # Step 3: Check known VA addresses
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 3: Verification of known VA addresses")
    results.append("-" * 78)

    for known_name, known_va in sorted(KNOWN_VAS.items(), key=lambda x: x[1]):
        try:
            addr = space.getAddress(known_va)
            func = fm.getFunctionAt(addr)
            if func is not None:
                ghidra_name = func.getName()
                sig = get_function_prologue_sig(func, 16)
                func_size = get_function_size(func)
                callers = len(get_calling_functions(func))
                results.append("  %-35s  VA=0x%08X  ghidra_name=%-30s  size=%5d  xrefs=%d" %
                              (known_name, known_va, ghidra_name, func_size, callers))
                results.append("    sig: %s" % sig)
            else:
                # Try to find instruction at address even if no function
                inst = listing.getInstructionAt(addr)
                if inst is not None:
                    raw = get_bytes_at(addr, 16)
                    results.append("  %-35s  VA=0x%08X  (no function, but code exists)" % (known_name, known_va))
                    results.append("    bytes: %s" % bytes_to_hex(raw))
                else:
                    results.append("  %-35s  VA=0x%08X  NOT FOUND (no function or code)" % (known_name, known_va))
        except Exception as e:
            results.append("  %-35s  VA=0x%08X  ERROR: %s" % (known_name, known_va, str(e)))

    results.append("")

    # ========================================================================
    # Step 4: Find and classify core Lua API functions
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 4: Core API functions (called by 2+ luaopen_*)")
    results.append("-" * 78)

    # Sort by fan-in (number of luaopen callers)
    core_funcs = []
    for addr_str, callers in sorted(all_targets.items(), key=lambda x: -len(x[1])):
        if len(callers) < 2:
            continue
        try:
            addr = address_factory.getAddress(addr_str)
            func = fm.getFunctionAt(addr)
            if func is None:
                continue

            tags = classify_function(func)
            sig = get_function_prologue_sig(func, 32)
            guesses = guess_lua_function(func, tags, sig)

            core_funcs.append({
                "addr": addr_str,
                "func": func,
                "tags": tags,
                "sig": sig,
                "guesses": guesses,
                "luaopen_callers": callers,
            })
        except Exception as e:
            pass

    for info in core_funcs:
        addr = info["addr"]
        func = info["func"]
        tags = info["tags"]
        sig = info["sig"]
        guesses = info["guesses"]
        callers = info["luaopen_callers"]

        tag_str = "bl=%d blr=%d size=%d frame=0x%X sxtw=%s xrefs=%d" % (
            tags["bl_calls"], tags["blr_indirect"], tags["size"],
            tags["frame_size"], tags["has_sxtw"], tags["callers"]
        )

        results.append("")
        results.append("  VA=0x%-12s  fan-in=%d  name=%s" % (addr, len(callers), func.getName()))
        results.append("  sig: %s" % sig)
        results.append("  tags: %s" % tag_str)
        if guesses:
            results.append("  >>> GUESS: %s" % ", ".join(guesses))
        results.append("  called by: %s" % ", ".join(sorted(callers)))

    results.append("")
    results.append("  Total core API functions: %d" % len(core_funcs))
    results.append("")

    # ========================================================================
    # Step 5: Focused search for key hook targets
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 5: Focused search for hook targets")
    results.append("-" * 78)

    # 5a. lua_pcallk — look for function at known VA or by pattern
    results.append("")
    results.append("--- lua_pcallk (primary hook target for Android port) ---")

    pcallk_va = 0x31B47F4
    try:
        pcallk_addr = space.getAddress(pcallk_va)
        pcallk_func = fm.getFunctionAt(pcallk_addr)
        if pcallk_func is not None:
            sig = get_function_prologue_sig(pcallk_func, 48)
            tags = classify_function(pcallk_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (pcallk_va, pcallk_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X sxtw=%s xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["has_sxtw"], tags["callers"]))

            # Show BL targets (what does pcallk call?)
            bl_targets = get_bl_targets(pcallk_func)
            results.append("  BL call targets from lua_pcallk:")
            for t in bl_targets:
                target_func = fm.getFunctionAt(t)
                tname = target_func.getName() if target_func else "(unknown)"
                results.append("    -> 0x%s  %s" % (t, tname))
        else:
            results.append("  NOT FOUND at VA=0x%08X (no function boundary)" % pcallk_va)
            # Check if there's code there
            inst = listing.getInstructionAt(pcallk_addr)
            if inst:
                raw = get_bytes_at(pcallk_addr, 32)
                results.append("  Code exists, bytes: %s" % bytes_to_hex(raw))
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5b. lua_load
    results.append("")
    results.append("--- lua_load (code loading) ---")

    lua_load_va = 0x31B2DE8
    try:
        load_addr = space.getAddress(lua_load_va)
        load_func = fm.getFunctionAt(load_addr)
        if load_func is not None:
            sig = get_function_prologue_sig(load_func, 48)
            tags = classify_function(load_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (lua_load_va, load_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X sxtw=%s xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["has_sxtw"], tags["callers"]))
            bl_targets = get_bl_targets(load_func)
            results.append("  BL call targets from lua_load:")
            for t in bl_targets:
                target_func = fm.getFunctionAt(t)
                tname = target_func.getName() if target_func else "(unknown)"
                results.append("    -> 0x%s  %s" % (t, tname))
        else:
            results.append("  NOT FOUND at VA=0x%08X" % lua_load_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5c. luaD_pcall
    results.append("")
    results.append("--- luaD_pcall (protected call dispatcher) ---")

    luad_pcall_va = 0x319E750
    try:
        dp_addr = space.getAddress(luad_pcall_va)
        dp_func = fm.getFunctionAt(dp_addr)
        if dp_func is not None:
            sig = get_function_prologue_sig(dp_func, 48)
            tags = classify_function(dp_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (luad_pcall_va, dp_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X sxtw=%s xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["has_sxtw"], tags["callers"]))
            bl_targets = get_bl_targets(dp_func)
            results.append("  BL call targets from luaD_pcall:")
            for t in bl_targets:
                target_func = fm.getFunctionAt(t)
                tname = target_func.getName() if target_func else "(unknown)"
                results.append("    -> 0x%s  %s" % (t, tname))
        else:
            results.append("  NOT FOUND at VA=0x%08X" % luad_pcall_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5d. luaV_execute (27KB VM loop)
    results.append("")
    results.append("--- luaV_execute (VM main loop) ---")

    luav_exec_va = 0x31DA9F4
    try:
        ve_addr = space.getAddress(luav_exec_va)
        ve_func = fm.getFunctionAt(ve_addr)
        if ve_func is not None:
            sig = get_function_prologue_sig(ve_func, 48)
            func_size = get_function_size(ve_func)
            results.append("  FOUND at VA=0x%08X  name=%s  size=%d bytes (%.1f KB)" %
                          (luav_exec_va, ve_func.getName(), func_size, func_size / 1024.0))
            results.append("  sig: %s" % sig)
        else:
            results.append("  NOT FOUND at VA=0x%08X" % luav_exec_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5e. luaD_precall
    results.append("")
    results.append("--- luaD_precall ---")

    luad_precall_va = 0x31B3F0C
    try:
        pc_addr = space.getAddress(luad_precall_va)
        pc_func = fm.getFunctionAt(pc_addr)
        if pc_func is not None:
            sig = get_function_prologue_sig(pc_func, 48)
            tags = classify_function(pc_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (luad_precall_va, pc_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["callers"]))
        else:
            results.append("  NOT FOUND at VA=0x%08X" % luad_precall_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5f. luaD_protectedparser
    results.append("")
    results.append("--- luaD_protectedparser ---")

    protparser_va = 0x31B7010
    try:
        pp_addr = space.getAddress(protparser_va)
        pp_func = fm.getFunctionAt(pp_addr)
        if pp_func is not None:
            sig = get_function_prologue_sig(pp_func, 48)
            tags = classify_function(pp_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (protparser_va, pp_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["callers"]))
        else:
            results.append("  NOT FOUND at VA=0x%08X" % protparser_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # 5g. luaD_rawrunprotected
    results.append("")
    results.append("--- luaD_rawrunprotected ---")

    rawrun_va = 0x319DDD8
    try:
        rr_addr = space.getAddress(rawrun_va)
        rr_func = fm.getFunctionAt(rr_addr)
        if rr_func is not None:
            sig = get_function_prologue_sig(rr_func, 48)
            tags = classify_function(rr_func)
            results.append("  FOUND at VA=0x%08X  name=%s" % (rawrun_va, rr_func.getName()))
            results.append("  sig: %s" % sig)
            results.append("  tags: bl=%d blr=%d size=%d frame=0x%X xrefs=%d" % (
                tags["bl_calls"], tags["blr_indirect"], tags["size"],
                tags["frame_size"], tags["callers"]))
        else:
            results.append("  NOT FOUND at VA=0x%08X" % rawrun_va)
    except Exception as e:
        results.append("  ERROR: %s" % str(e))

    # ========================================================================
    # Step 6: Scan for ALL large functions (potential luaV_execute)
    # ========================================================================
    results.append("")
    results.append("-" * 78)
    results.append("STEP 6: Large functions (>15KB, potential VM loops)")
    results.append("-" * 78)

    large_funcs = []
    func_iter = fm.getFunctions(True)
    while func_iter.hasNext():
        f = func_iter.next()
        f_size = get_function_size(f)
        if f_size > 15000:
            large_funcs.append((f, f_size))

    large_funcs.sort(key=lambda x: -x[1])
    for f, f_size in large_funcs[:20]:
        entry = f.getEntryPoint()
        sig = get_function_prologue_sig(f, 16)
        results.append("  VA=0x%s  size=%6d (%5.1f KB)  name=%s" %
                      (entry, f_size, f_size / 1024.0, f.getName()))
        results.append("    sig: %s" % sig)

    results.append("")

    # ========================================================================
    # Step 7: Search for functions with "lua" in Ghidra-assigned names
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 7: Functions with 'lua' in name (Ghidra auto-analysis)")
    results.append("-" * 78)

    lua_named = []
    func_iter = fm.getFunctions(True)
    while func_iter.hasNext():
        f = func_iter.next()
        fname = f.getName().lower()
        if "lua" in fname:
            lua_named.append(f)

    results.append("  Found %d functions with 'lua' in name" % len(lua_named))
    for f in lua_named[:50]:
        entry = f.getEntryPoint()
        f_size = get_function_size(f)
        sig = get_function_prologue_sig(f, 16)
        results.append("  VA=0x%s  size=%5d  name=%s" % (entry, f_size, f.getName()))

    results.append("")

    # ========================================================================
    # Step 8: Search for string references containing "lua" keywords
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 8: String references containing Lua keywords")
    results.append("-" * 78)

    lua_strings_found = 0
    # Search defined strings for lua-related content
    data_iter = listing.getDefinedData(True)
    count = 0
    max_check = 500000  # Limit to avoid timeout
    while data_iter.hasNext() and count < max_check:
        data = data_iter.next()
        count += 1
        if data.hasStringValue():
            try:
                val = data.getValue()
                if val is not None:
                    val_str = str(val)
                    if len(val_str) > 3 and any(kw in val_str.lower() for kw in
                        ["lua_", "lual_", "luad_", "luav_", "luao_", "pcall", "loadfile",
                         "loadstring", "require", "dofile", "luaopen"]):
                        if lua_strings_found < 50:
                            addr = data.getAddress()
                            # Find functions referencing this string
                            refs = getReferencesTo(addr)
                            ref_funcs = []
                            for ref in refs:
                                rf = getFunctionContaining(ref.getFromAddress())
                                if rf:
                                    ref_funcs.append("0x%s(%s)" % (rf.getEntryPoint(), rf.getName()))
                            results.append("  0x%s: \"%s\"" % (addr, val_str[:80]))
                            if ref_funcs:
                                results.append("    referenced by: %s" % ", ".join(ref_funcs[:5]))
                        lua_strings_found += 1
            except:
                pass

    results.append("  Total lua-related strings found: %d (checked %d data items)" %
                  (lua_strings_found, count))
    results.append("")

    # ========================================================================
    # Step 9: Cross-reference analysis for lua_pcallk
    # ========================================================================
    results.append("-" * 78)
    results.append("STEP 9: Cross-reference analysis for hook targets")
    results.append("-" * 78)

    # If we found lua_pcallk, show what calls it
    try:
        pcallk_addr = space.getAddress(pcallk_va)
        pcallk_func = fm.getFunctionAt(pcallk_addr)
        if pcallk_func is not None:
            callers = get_calling_functions(pcallk_func)
            results.append("")
            results.append("  lua_pcallk (0x%08X) is called by %d functions:" % (pcallk_va, len(callers)))
            for caller in sorted(callers, key=lambda f: str(f.getEntryPoint())):
                results.append("    0x%s  %s" % (caller.getEntryPoint(), caller.getName()))
    except:
        pass

    # If we found lua_load, show what calls it
    try:
        load_addr = space.getAddress(lua_load_va)
        load_func = fm.getFunctionAt(load_addr)
        if load_func is not None:
            callers = get_calling_functions(load_func)
            results.append("")
            results.append("  lua_load (0x%08X) is called by %d functions:" % (lua_load_va, len(callers)))
            for caller in sorted(callers, key=lambda f: str(f.getEntryPoint()))[:30]:
                results.append("    0x%s  %s" % (caller.getEntryPoint(), caller.getName()))
    except:
        pass

    results.append("")

    # ========================================================================
    # Summary
    # ========================================================================
    elapsed = time.time() - start_time
    results.append("=" * 78)
    results.append("  SUMMARY — Key Hook Targets for Android Port")
    results.append("=" * 78)
    results.append("")
    results.append("  Priority hook targets (mirror Windows inject.cpp pattern):")
    results.append("  ┌─────────────────────────┬────────────────┬─────────────────────────────┐")
    results.append("  │ Function                │ VA             │ Status                      │")
    results.append("  ├─────────────────────────┼────────────────┼─────────────────────────────┤")

    for name, va in [
        ("lua_pcallk", pcallk_va),
        ("lua_load", lua_load_va),
        ("luaD_pcall", luad_pcall_va),
        ("luaD_precall", luad_precall_va),
        ("luaV_execute", luav_exec_va),
        ("luaD_protectedparser", protparser_va),
        ("luaD_rawrunprotected", rawrun_va),
    ]:
        try:
            addr = space.getAddress(va)
            func = fm.getFunctionAt(addr)
            status = "FOUND (%s)" % func.getName() if func else "NO FUNCTION"
        except:
            status = "ERROR"
        results.append("  │ %-23s │ 0x%08X     │ %-27s │" % (name, va, status))

    results.append("  └─────────────────────────┴────────────────┴─────────────────────────────┘")
    results.append("")
    results.append("  Scan completed in %.1f seconds" % elapsed)
    results.append("")

    # Write results
    write_results(results)

    # Also print summary to console
    for line in results:
        log(line)


# Entry point
run()
