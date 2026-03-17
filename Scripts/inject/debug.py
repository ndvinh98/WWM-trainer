import sys
import pywintypes
import win32file
import win32pipe

PIPE_NAME = r"\\.\pipe\wwm_lua_gate"


def send_to_lua_gate(message: str, timeout_ms: int = 3000) -> str:
    try:
        win32pipe.WaitNamedPipe(PIPE_NAME, timeout_ms)
    except pywintypes.error as e:
        raise RuntimeError(f"WaitNamedPipe failed: {e}") from e

    handle = None
    try:
        handle = win32file.CreateFile(
            PIPE_NAME,
            win32file.GENERIC_READ | win32file.GENERIC_WRITE,
            0,
            None,
            win32file.OPEN_EXISTING,
            0,
            None,
        )

        win32pipe.SetNamedPipeHandleState(
            handle,
            win32pipe.PIPE_READMODE_MESSAGE,
            None,
            None,
        )

        win32file.WriteFile(handle, message.encode("utf-8"))

        _, data = win32file.ReadFile(handle, 64)
        return data.decode("utf-8", errors="replace")

    except pywintypes.error as e:
        raise RuntimeError(f"Pipe I/O failed: {e}") from e

    finally:
        if handle is not None:
            win32file.CloseHandle(handle)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage:")
        print(r'  python sendlua.py "print(\'hello\')"')
        print(r'  python sendlua.py "C:\temp\test.lua"')
        return 1

    message = " ".join(sys.argv[1:])

    try:
        reply = send_to_lua_gate(message)
        print(f"Server reply: {reply}")
        return 0
    except Exception as e:
        print(e)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())