"""Unified runner for Android inject — test, probe, inline Lua, push scripts.

Usage:
    python run_android.py push                  # push Scripts/ to device
    python run_android.py inject                # trigger Test.lua reload
    python run_android.py lua "print(type(X))"  # inline Lua
    python run_android.py forward               # setup adb port forward
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from debug_android import send_to_lua_gate

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent
SCRIPTS_DIR = PROJECT_ROOT / "Scripts"
DEVICE_SCRIPTS = "/sdcard/Android/data/com.netease.yysls/files/Scripts"


def cmd_push() -> int:
    """Push Lua scripts to device via adb."""
    # Push key directories
    for subdir in ["lib", "ui", "actions", "data"]:
        src = SCRIPTS_DIR / subdir
        if src.exists():
            dst = f"{DEVICE_SCRIPTS}/{subdir}"
            print(f"  Pushing {subdir}/...")
            subprocess.run(["adb", "push", str(src) + "/", dst], check=True)

    # Push Test.lua (entry point)
    test_lua = SCRIPTS_DIR / "Test.lua"
    if test_lua.exists():
        subprocess.run(
            ["adb", "push", str(test_lua), f"{DEVICE_SCRIPTS}/Test.lua"],
            check=True
        )

    print("  Done. Scripts pushed to device.")
    return 0


def cmd_forward() -> int:
    """Setup adb port forwarding."""
    subprocess.run(
        ["adb", "forward", "tcp:19840", "tcp:19840"],
        check=True
    )
    print("  Port forwarding active: localhost:19840 -> device:19840")
    return 0


def cmd_inject() -> int:
    """Trigger Test.lua reload on device."""
    lua = (
        f"local f, err = loadfile('{DEVICE_SCRIPTS}/Test.lua')\n"
        f"if f then pcall(f) else print('[inject] ' .. tostring(err)) end"
    )
    reply = send_to_lua_gate(lua)
    print(f"  Reply: {reply}")
    return 0


def cmd_lua(code: str) -> int:
    """Execute inline Lua on device."""
    reply = send_to_lua_gate(code)
    print(f"  Reply: {reply}")
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    cmd = sys.argv[1]

    if cmd == "push":
        return cmd_push()
    elif cmd == "forward":
        return cmd_forward()
    elif cmd == "inject":
        return cmd_inject()
    elif cmd == "lua":
        if len(sys.argv) < 3:
            print('Usage: run_android.py lua "<lua code>"')
            return 1
        return cmd_lua(" ".join(sys.argv[2:]))
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
