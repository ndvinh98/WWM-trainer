"""PyInjector — A generic DLL injector GUI.

Launch:
    python injector_ui.py

Requires 64-bit Python on Windows. Run as administrator for injection.
"""

from __future__ import annotations

import ctypes
import json
import os
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext, ttk
from pathlib import Path

# ---------------------------------------------------------------------------
# Import core injection functions from injector.py (same directory)
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from injector import (
    find_pid,
    find_module_in_process,
    inject_dll,
    eject_dll,
    enable_debug_privilege,
    Tee,
)

# Also import pipe client for "Send Command"
try:
    from debug import send_to_lua_gate
    HAS_PIPE_CLIENT = True
except ImportError:
    HAS_PIPE_CLIENT = False

# ---------------------------------------------------------------------------
# Admin elevation
# ---------------------------------------------------------------------------

def is_admin() -> bool:
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()  # type: ignore[union-attr]
    except Exception:
        return False


def elevate_and_exit() -> None:
    """Re-launch ourselves as admin via UAC prompt, then exit."""
    script = os.path.abspath(sys.argv[0])
    params = " ".join(f'"{a}"' for a in sys.argv[1:])
    # ShellExecuteW returns >32 on success
    ret = ctypes.windll.shell32.ShellExecuteW(  # type: ignore[union-attr]
        None, "runas", sys.executable, f'"{script}" {params}', None, 1,
    )
    if ret > 32:
        sys.exit(0)
    # If UAC was cancelled, continue without admin


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPT_DIR / "injector_ui_config.json"
LOGS_DIR = SCRIPT_DIR.parent / "logs"

DEFAULT_CONFIG = {
    "process_name": "",
    "dll_folder": str(SCRIPT_DIR),
    "selected_dll": "Test.dll",
    "auto_inject": False,
    "start_command": "steam://rungameid/3564740",
    "pipe_name": r"\\.\pipe\wwm_lua_gate",
    "tcp_host": "127.0.0.1",
    "tcp_port": "5555",
    "log_file": "inject_log.txt",
    "log_max_lines": 500,
}

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

def load_config() -> dict:
    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH, "r") as f:
                cfg = json.load(f)
            # Merge with defaults for any missing keys
            for k, v in DEFAULT_CONFIG.items():
                cfg.setdefault(k, v)
            return cfg
        except Exception:
            pass
    return dict(DEFAULT_CONFIG)


def save_config(cfg: dict) -> None:
    try:
        with open(CONFIG_PATH, "w") as f:
            json.dump(cfg, f, indent=2)
    except Exception:
        pass

# ---------------------------------------------------------------------------
# Redirect stdout/stderr so injection prints appear in the log viewer
# ---------------------------------------------------------------------------

class OutputCapture:
    """Captures writes to stdout and stores them in a list for the log viewer."""

    def __init__(self):
        self.lines: list[str] = []
        self._original = sys.__stdout__

    def write(self, s: str) -> int:
        if s.strip():
            self.lines.append(s.rstrip("\n"))
        if self._original:
            self._original.write(s)
        return len(s)

    def flush(self) -> None:
        if self._original:
            self._original.flush()

# ---------------------------------------------------------------------------
# Main Application
# ---------------------------------------------------------------------------

class PyInjectorApp:
    POLL_PROCESS_MS = 2000
    POLL_LOG_MS = 1000

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("PyInjector")
        self.root.geometry("780x720")
        self.root.minsize(680, 600)
        self.root.configure(bg="#1e1e2e")

        self.cfg = load_config()
        self._detected_pid: int | None = None
        self._auto_injected = False  # one-shot guard per process launch
        self._auto_inject_failed = False  # prevent retry spam on failure
        self._is_admin = is_admin()
        self._log_pos: dict[str, int] = {}  # file -> last read position
        self._capture = OutputCapture()
        sys.stdout = self._capture  # type: ignore[assignment]

        # Try to enable debug privilege early
        try:
            enable_debug_privilege()
        except Exception:
            pass

        self._style()
        self._build_ui()
        self._load_config_into_ui()

        # Start background polling
        self._poll_process()
        self._poll_log()

        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

    # ------------------------------------------------------------------
    # Styling
    # ------------------------------------------------------------------

    def _style(self):
        style = ttk.Style()
        style.theme_use("clam")

        # Colors
        BG = "#1e1e2e"
        FG = "#cdd6f4"
        ACCENT = "#89b4fa"
        SURFACE = "#313244"
        SURFACE2 = "#45475a"
        GREEN = "#a6e3a1"
        RED = "#f38ba8"
        YELLOW = "#f9e2af"

        self._colors = {
            "bg": BG, "fg": FG, "accent": ACCENT,
            "surface": SURFACE, "surface2": SURFACE2,
            "green": GREEN, "red": RED, "yellow": YELLOW,
        }

        style.configure("TFrame", background=BG)
        style.configure("TLabel", background=BG, foreground=FG, font=("Segoe UI", 10))
        style.configure("Header.TLabel", background=BG, foreground=ACCENT, font=("Segoe UI", 11, "bold"))
        style.configure("Status.TLabel", background=BG, foreground=RED, font=("Segoe UI", 10, "bold"))
        style.configure("TButton", background=SURFACE2, foreground=FG, font=("Segoe UI", 10), padding=(10, 4))
        style.map("TButton", background=[("active", ACCENT)], foreground=[("active", BG)])
        style.configure("Accent.TButton", background=ACCENT, foreground=BG, font=("Segoe UI", 10, "bold"), padding=(12, 6))
        style.map("Accent.TButton", background=[("active", GREEN)])
        style.configure("Danger.TButton", background=RED, foreground=BG, font=("Segoe UI", 10, "bold"), padding=(12, 6))
        style.map("Danger.TButton", background=[("active", YELLOW)])
        style.configure("TCheckbutton", background=BG, foreground=FG, font=("Segoe UI", 10))
        style.configure("TCombobox", fieldbackground=SURFACE, foreground=FG, font=("Segoe UI", 10))
        style.configure("TEntry", fieldbackground=SURFACE, foreground=FG, font=("Consolas", 10))
        style.configure("TLabelframe", background=BG, foreground=ACCENT, font=("Segoe UI", 10, "bold"))
        style.configure("TLabelframe.Label", background=BG, foreground=ACCENT, font=("Segoe UI", 10, "bold"))

    # ------------------------------------------------------------------
    # Build UI
    # ------------------------------------------------------------------

    def _build_ui(self):
        pad = {"padx": 8, "pady": 4}
        C = self._colors

        # ---- Title bar ----
        title_frame = ttk.Frame(self.root)
        title_frame.pack(fill="x", **pad)
        ttk.Label(title_frame, text="⚡ PyInjector", font=("Segoe UI", 16, "bold"),
                  foreground=C["accent"]).pack(side="left")
        ttk.Label(title_frame, text="Generic DLL Injector",
                  foreground=C["surface2"], font=("Segoe UI", 9)).pack(side="left", padx=(10, 0))

        # Admin status indicator
        if self._is_admin:
            ttk.Label(title_frame, text="🛡 Admin", foreground=C["green"],
                      font=("Segoe UI", 9, "bold")).pack(side="right", padx=5)
        else:
            admin_frame = ttk.Frame(title_frame)
            admin_frame.pack(side="right", padx=5)
            ttk.Label(admin_frame, text="⚠ Not Admin", foreground=C["yellow"],
                      font=("Segoe UI", 9, "bold")).pack(side="left")
            ttk.Button(admin_frame, text="Elevate", command=lambda: elevate_and_exit()).pack(side="left", padx=3)

        # ---- 1. Target Process ----
        proc_frame = ttk.LabelFrame(self.root, text="  Target Process  ")
        proc_frame.pack(fill="x", padx=10, pady=(6, 3))

        row1 = ttk.Frame(proc_frame)
        row1.pack(fill="x", **pad)
        ttk.Label(row1, text="Process:").pack(side="left")
        self.proc_entry = ttk.Entry(row1, width=30)
        self.proc_entry.pack(side="left", padx=5)
        ttk.Button(row1, text="Browse .exe…", command=self._browse_exe).pack(side="left", padx=3)

        self.proc_status = ttk.Label(row1, text="● Not detected", style="Status.TLabel")
        self.proc_status.pack(side="right", padx=5)

        row1b = ttk.Frame(proc_frame)
        row1b.pack(fill="x", **pad)
        ttk.Label(row1b, text="Start cmd:").pack(side="left")
        self.start_cmd_entry = ttk.Entry(row1b, width=45)
        self.start_cmd_entry.pack(side="left", padx=5, fill="x", expand=True)
        ttk.Button(row1b, text="🚀 Start", style="Accent.TButton",
                   command=self._do_start_process).pack(side="left", padx=3)

        # ---- 2. DLL Folder ----
        dll_frame = ttk.LabelFrame(self.root, text="  DLL Selection  ")
        dll_frame.pack(fill="x", padx=10, pady=3)

        row2 = ttk.Frame(dll_frame)
        row2.pack(fill="x", **pad)
        ttk.Label(row2, text="Folder:").pack(side="left")
        self.dll_folder_entry = ttk.Entry(row2, width=45)
        self.dll_folder_entry.pack(side="left", padx=5, fill="x", expand=True)
        ttk.Button(row2, text="Browse…", command=self._browse_dll_folder).pack(side="left", padx=3)

        row2b = ttk.Frame(dll_frame)
        row2b.pack(fill="x", **pad)
        ttk.Label(row2b, text="DLLs found:").pack(side="left", anchor="n")
        self.dll_listbox = tk.Listbox(
            row2b, height=4, bg=C["surface"], fg=C["fg"],
            selectbackground=C["accent"], selectforeground=C["bg"],
            font=("Consolas", 10), relief="flat", bd=0,
        )
        self.dll_listbox.pack(side="left", padx=5, fill="x", expand=True)

        # ---- 3. Actions ----
        action_frame = ttk.Frame(self.root)
        action_frame.pack(fill="x", padx=10, pady=6)

        self.inject_btn = ttk.Button(action_frame, text="⚡ Inject", style="Accent.TButton", command=self._do_inject)
        self.inject_btn.pack(side="left", padx=4)
        self.eject_btn = ttk.Button(action_frame, text="⏏ Eject", style="Danger.TButton", command=self._do_eject)
        self.eject_btn.pack(side="left", padx=4)

        self.auto_inject_var = tk.BooleanVar()
        self.auto_cb = ttk.Checkbutton(action_frame, text="Auto-inject on process detect",
                                       variable=self.auto_inject_var, command=self._on_auto_toggle)
        self.auto_cb.pack(side="left", padx=12)

        # ---- 4. Log Viewer ----
        log_frame = ttk.LabelFrame(self.root, text="  Log Viewer  ")
        log_frame.pack(fill="both", expand=True, padx=10, pady=3)

        log_toolbar = ttk.Frame(log_frame)
        log_toolbar.pack(fill="x", **pad)
        ttk.Label(log_toolbar, text="Source:").pack(side="left")
        self.log_source_var = tk.StringVar()
        self.log_combo = ttk.Combobox(log_toolbar, textvariable=self.log_source_var,
                                      state="readonly", width=25)
        self.log_combo["values"] = self._get_log_files()
        self.log_combo.pack(side="left", padx=5)
        self.log_combo.bind("<<ComboboxSelected>>", lambda _: self._reset_log_pos())
        ttk.Button(log_toolbar, text="Clear", command=self._clear_log).pack(side="left", padx=4)
        ttk.Button(log_toolbar, text="↻ Refresh List", command=self._refresh_log_list).pack(side="left", padx=4)

        self.log_text = scrolledtext.ScrolledText(
            log_frame, height=12, bg=C["surface"], fg=C["fg"],
            insertbackground=C["fg"], font=("Consolas", 9),
            relief="flat", bd=0, state="disabled",
        )
        self.log_text.pack(fill="both", expand=True, padx=6, pady=(0, 6))

        # ---- 5. Communication Settings ----
        comm_frame = ttk.LabelFrame(self.root, text="  Communication  ")
        comm_frame.pack(fill="x", padx=10, pady=(3, 8))

        row_comm = ttk.Frame(comm_frame)
        row_comm.pack(fill="x", **pad)
        ttk.Label(row_comm, text="Pipe:").pack(side="left")
        self.pipe_entry = ttk.Entry(row_comm, width=30)
        self.pipe_entry.pack(side="left", padx=5)
        ttk.Label(row_comm, text="TCP:").pack(side="left", padx=(10, 0))
        self.tcp_host_entry = ttk.Entry(row_comm, width=14)
        self.tcp_host_entry.pack(side="left", padx=3)
        ttk.Label(row_comm, text=":").pack(side="left")
        self.tcp_port_entry = ttk.Entry(row_comm, width=6)
        self.tcp_port_entry.pack(side="left", padx=3)

        row_send = ttk.Frame(comm_frame)
        row_send.pack(fill="x", **pad)
        ttk.Label(row_send, text="Command:").pack(side="left")
        self.cmd_entry = ttk.Entry(row_send, width=50)
        self.cmd_entry.pack(side="left", padx=5, fill="x", expand=True)
        self.cmd_entry.bind("<Return>", lambda _: self._send_command())
        ttk.Button(row_send, text="Send", command=self._send_command).pack(side="left", padx=4)

    # ------------------------------------------------------------------
    # Config load / save
    # ------------------------------------------------------------------

    def _load_config_into_ui(self):
        cfg = self.cfg
        self.proc_entry.insert(0, cfg.get("process_name", ""))
        self.start_cmd_entry.insert(0, cfg.get("start_command", "steam://rungameid/3564740"))
        self.dll_folder_entry.insert(0, cfg.get("dll_folder", str(SCRIPT_DIR)))
        self.auto_inject_var.set(cfg.get("auto_inject", False))
        self.pipe_entry.insert(0, cfg.get("pipe_name", r"\\.\pipe\wwm_lua_gate"))
        self.tcp_host_entry.insert(0, cfg.get("tcp_host", "127.0.0.1"))
        self.tcp_port_entry.insert(0, cfg.get("tcp_port", "5555"))

        # Populate DLL list
        self._refresh_dll_list()

        # Select DLL
        selected = cfg.get("selected_dll", "Test.dll")
        items = self.dll_listbox.get(0, "end")
        for i, item in enumerate(items):
            if item == selected:
                self.dll_listbox.selection_set(i)
                break

        # Log source
        log_file = cfg.get("log_file", "inject_log.txt")
        self.log_source_var.set(log_file)

    def _gather_config(self) -> dict:
        sel = self.dll_listbox.curselection()
        selected_dll = self.dll_listbox.get(sel[0]) if sel else "Test.dll"
        return {
            "process_name": self.proc_entry.get().strip(),
            "dll_folder": self.dll_folder_entry.get().strip(),
            "selected_dll": selected_dll,
            "auto_inject": self.auto_inject_var.get(),
            "start_command": self.start_cmd_entry.get().strip(),
            "pipe_name": self.pipe_entry.get().strip(),
            "tcp_host": self.tcp_host_entry.get().strip(),
            "tcp_port": self.tcp_port_entry.get().strip(),
            "log_file": self.log_source_var.get(),
            "log_max_lines": 500,
        }

    def _on_close(self):
        save_config(self._gather_config())
        sys.stdout = sys.__stdout__  # type: ignore[assignment]
        self.root.destroy()

    # ------------------------------------------------------------------
    # Browse helpers
    # ------------------------------------------------------------------

    def _browse_exe(self):
        path = filedialog.askopenfilename(
            title="Select target executable",
            filetypes=[("Executables", "*.exe"), ("All files", "*.*")],
        )
        if path:
            self.proc_entry.delete(0, "end")
            self.proc_entry.insert(0, Path(path).name)

    def _browse_dll_folder(self):
        folder = filedialog.askdirectory(title="Select DLL folder")
        if folder:
            self.dll_folder_entry.delete(0, "end")
            self.dll_folder_entry.insert(0, folder)
            self._refresh_dll_list()

    def _refresh_dll_list(self):
        self.dll_listbox.delete(0, "end")
        folder = self.dll_folder_entry.get().strip()
        if folder and os.path.isdir(folder):
            dlls = sorted(
                f for f in os.listdir(folder)
                if f.lower().endswith(".dll")
            )
            for d in dlls:
                self.dll_listbox.insert("end", d)

    # ------------------------------------------------------------------
    # Start process
    # ------------------------------------------------------------------

    def _do_start_process(self):
        """Launch the game or target process using the configured start command."""
        cmd = self.start_cmd_entry.get().strip()
        if not cmd:
            messagebox.showwarning("PyInjector", "No start command configured.")
            return

        self._append_log(f"[UI] Starting process: {cmd}")
        try:
            # Handle protocol URLs (steam://, etc.) and regular commands
            if "://" in cmd:
                os.startfile(cmd)  # noqa: S606
            else:
                subprocess.Popen(cmd, shell=True)  # noqa: S602
            self._append_log("[UI] Start command sent successfully.")
        except Exception as e:
            self._append_log(f"[UI] Failed to start process: {e}")

    # ------------------------------------------------------------------
    # Process detection polling
    # ------------------------------------------------------------------

    def _poll_process(self):
        proc_name = self.proc_entry.get().strip()
        C = self._colors

        if proc_name:
            pid = find_pid(proc_name)
            if pid:
                self.proc_status.configure(text=f"● Running (PID: {pid})", foreground=C["green"])
                self._detected_pid = pid

                # Auto-inject logic (one-shot, no retry on failure)
                if (self.auto_inject_var.get()
                        and not self._auto_injected
                        and not self._auto_inject_failed):
                    self._auto_injected = True
                    self._append_log("[UI] Auto-inject will fire in 10s...")
                    self.root.after(10000, self._do_inject)
            else:
                self.proc_status.configure(text="● Not detected", foreground=C["red"])
                if self._detected_pid is not None:
                    # Process died — reset guards for next launch
                    self._auto_injected = False
                    self._auto_inject_failed = False
                self._detected_pid = None
        else:
            self.proc_status.configure(text="● No target set", foreground=C["surface2"])
            self._detected_pid = None

        self.root.after(self.POLL_PROCESS_MS, self._poll_process)

    # ------------------------------------------------------------------
    # Inject / Eject
    # ------------------------------------------------------------------

    def _get_selected_dll_path(self) -> str | None:
        sel = self.dll_listbox.curselection()
        if not sel:
            messagebox.showwarning("PyInjector", "No DLL selected.")
            return None
        dll_name = self.dll_listbox.get(sel[0])
        folder = self.dll_folder_entry.get().strip()
        return str(Path(folder) / dll_name)

    def _do_inject(self):
        if self._detected_pid is None:
            messagebox.showwarning("PyInjector", "Target process not detected.")
            return
        dll_path = self._get_selected_dll_path()
        if not dll_path:
            return
        if not os.path.isfile(dll_path):
            messagebox.showerror("PyInjector", f"DLL not found:\n{dll_path}")
            return

        dll_name = os.path.basename(dll_path)
        pid = self._detected_pid

        # Check if already loaded
        if find_module_in_process(pid, dll_name) is not None:
            self._append_log(f"[UI] {dll_name} is already loaded in PID {pid}")
            return

        self._append_log(f"[UI] Injecting {dll_name} into PID {pid}...")
        # Run injection in a thread to avoid freezing the UI
        threading.Thread(target=self._inject_thread, args=(pid, dll_path), daemon=True).start()

    def _inject_thread(self, pid: int, dll_path: str):
        try:
            ok = inject_dll(pid, dll_path)
            msg = f"[UI] Injection {'succeeded' if ok else 'FAILED'}: {os.path.basename(dll_path)}"
            if not ok:
                self._auto_inject_failed = True
        except Exception as e:
            msg = f"[UI] Injection error: {e}"
            self._auto_inject_failed = True
        self.root.after(0, self._append_log, msg)

    def _do_eject(self):
        if self._detected_pid is None:
            messagebox.showwarning("PyInjector", "Target process not detected.")
            return
        dll_path = self._get_selected_dll_path()
        if not dll_path:
            return

        dll_name = os.path.basename(dll_path)
        pid = self._detected_pid

        if find_module_in_process(pid, dll_name) is None:
            self._append_log(f"[UI] {dll_name} is not loaded in PID {pid}")
            return

        self._append_log(f"[UI] Ejecting {dll_name} from PID {pid}...")
        threading.Thread(target=self._eject_thread, args=(pid, dll_name), daemon=True).start()

    def _eject_thread(self, pid: int, dll_name: str):
        try:
            ok = eject_dll(pid, dll_name)
            msg = f"[UI] Eject {'succeeded' if ok else 'FAILED'}: {dll_name}"
        except Exception as e:
            msg = f"[UI] Eject error: {e}"
        self.root.after(0, self._append_log, msg)

    def _on_auto_toggle(self):
        if self.auto_inject_var.get():
            self._auto_injected = False
            self._auto_inject_failed = False
            self._append_log("[UI] Auto-inject enabled")
        else:
            self._append_log("[UI] Auto-inject disabled")

    # ------------------------------------------------------------------
    # Log viewer
    # ------------------------------------------------------------------

    def _get_log_files(self) -> list[str]:
        files = ["-- captured output --"]
        if LOGS_DIR.is_dir():
            files.extend(sorted(
                f for f in os.listdir(LOGS_DIR)
                if f.endswith(".txt")
            ))
        return files

    def _refresh_log_list(self):
        current = self.log_source_var.get()
        self.log_combo["values"] = self._get_log_files()
        if current:
            self.log_source_var.set(current)

    def _reset_log_pos(self):
        self._log_pos.clear()
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    def _poll_log(self):
        source = self.log_source_var.get()
        new_lines: list[str] = []

        if source == "-- captured output --":
            # Show captured stdout lines
            cap = self._capture.lines
            last = self._log_pos.get("__capture__", 0)
            if len(cap) > last:
                new_lines = cap[last:]
                self._log_pos["__capture__"] = len(cap)
        elif source:
            log_path = LOGS_DIR / source
            if log_path.is_file():
                try:
                    pos = self._log_pos.get(source, 0)
                    with open(log_path, "r", encoding="utf-8", errors="replace") as f:
                        f.seek(pos)
                        data = f.read()
                        if data:
                            new_lines = data.splitlines()
                            self._log_pos[source] = f.tell()
                except Exception:
                    pass

        if new_lines:
            self._append_log_lines(new_lines)

        self.root.after(self.POLL_LOG_MS, self._poll_log)

    def _append_log(self, line: str):
        self._append_log_lines([line])

    def _append_log_lines(self, lines: list[str]):
        self.log_text.configure(state="normal")
        for line in lines:
            self.log_text.insert("end", line + "\n")

        # Truncate if too many lines
        max_lines = self.cfg.get("log_max_lines", 500)
        current_lines = int(self.log_text.index("end-1c").split(".")[0])
        if current_lines > max_lines:
            self.log_text.delete("1.0", f"{current_lines - max_lines}.0")

        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _clear_log(self):
        # Clear display
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

        # Truncate the file
        source = self.log_source_var.get()
        if source and source != "-- captured output --":
            log_path = LOGS_DIR / source
            if log_path.is_file():
                try:
                    with open(log_path, "w") as f:
                        f.write("")
                except Exception:
                    pass
            self._log_pos[source] = 0
        elif source == "-- captured output --":
            self._capture.lines.clear()
            self._log_pos["__capture__"] = 0

    # ------------------------------------------------------------------
    # Communication
    # ------------------------------------------------------------------

    def _send_command(self):
        cmd = self.cmd_entry.get().strip()
        if not cmd:
            return

        pipe_name = self.pipe_entry.get().strip()
        self._append_log(f"[UI] Sending: {cmd}")

        if HAS_PIPE_CLIENT:
            threading.Thread(
                target=self._send_pipe_thread,
                args=(cmd, pipe_name),
                daemon=True,
            ).start()
        else:
            self._append_log("[UI] Pipe client (debug.py) not available")

        self.cmd_entry.delete(0, "end")

    def _send_pipe_thread(self, cmd: str, pipe_name: str):
        try:
            # The current debug.py uses a hardcoded pipe name.
            # For now, call directly. Future: pass pipe_name through.
            reply = send_to_lua_gate(cmd)
            msg = f"[UI] Reply: {reply}"
        except Exception as e:
            msg = f"[UI] Pipe error: {e}"
        self.root.after(0, self._append_log, msg)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    # Auto-elevate to admin if not already
    if not is_admin():
        elevate_and_exit()

    root = tk.Tk()
    app = PyInjectorApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
