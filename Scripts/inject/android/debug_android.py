"""TCP client for sending Lua commands to the Android inject server.

Replaces debug.py (Windows named pipes) with cross-platform TCP sockets.
Requires: adb forward tcp:19840 tcp:19840

Usage:
    python debug_android.py "print('hello')"
    python debug_android.py /sdcard/.../Scripts/Test.lua
"""

from __future__ import annotations

import socket
import sys

HOST = "127.0.0.1"
PORT = 19840
TIMEOUT = 5.0


def send_to_lua_gate(message: str, timeout: float = TIMEOUT) -> str:
    """Send a command to the TCP inject server and return the response."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        sock.connect((HOST, PORT))
        sock.sendall(message.encode("utf-8"))
        sock.shutdown(socket.SHUT_WR)  # signal end of message
        data = sock.recv(64)
        return data.decode("utf-8", errors="replace")


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage:")
        print('  python debug_android.py "print(\'hello\')"')
        print("  python debug_android.py /path/to/script.lua")
        print()
        print("Prerequisite: adb forward tcp:19840 tcp:19840")
        return 1

    message = " ".join(sys.argv[1:])

    try:
        reply = send_to_lua_gate(message)
        print(f"Server reply: {reply}")
        return 0
    except ConnectionRefusedError:
        print("ERROR: Connection refused. Is the game running with inject loaded?")
        print("  1. Install patched APK: adb install wwm_patched.apk")
        print("  2. Launch game")
        print("  3. Forward port: adb forward tcp:19840 tcp:19840")
        return 1
    except socket.timeout:
        print("ERROR: Connection timed out")
        return 1
    except Exception as e:
        print(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
