"""Unified runner for WWM game injection: tests, probes, and inline Lua.

Usage:
  python Scripts/inject/run.py test                    # run all tests → logs/test_results.txt
  python Scripts/inject/run.py probe                   # run probe.lua → logs/probe.txt
  python Scripts/inject/run.py lua "print(type(X))"    # inline Lua   → logs/probe.txt
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from debug import send_to_lua_gate

ROOT = "C:/temp/Where Winds Meet/Scripts"

COMMANDS = {
    "test": f"dofile('{ROOT}/tests/run_all.lua')",
    "probe": f"dofile('{ROOT}/tests/probe_runner.lua')",
}


def wrap_inline(code: str) -> str:
    """Wrap inline Lua with log file setup and pcall."""
    return (
        f"pcall(function() local f=io.open('{ROOT}/logs/probe.txt','w') "
        f"if f then f:close() end end) "
        f"_G.print_file='probe.txt' "
        f"local __ok,__err=pcall(function() {code} end) "
        f"if not __ok then print('[PROBE] ERROR: '..tostring(__err)) end "
        f"_G.print_file=nil"
    )


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    cmd = sys.argv[1]

    if cmd in COMMANDS:
        lua = COMMANDS[cmd]
    elif cmd == "lua":
        if len(sys.argv) < 3:
            print('Usage: run.py lua "<lua code>"')
            return 1
        lua = wrap_inline(" ".join(sys.argv[2:]))
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
        return 1

    try:
        reply = send_to_lua_gate(lua)
        print(f"Server reply: {reply}")
        return 0
    except Exception as e:
        print(e)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
