```powershell
cd 'F:\Coding\Where Winds Meet'

# Run all tests → Scripts/logs/test_results.txt
& ".venv\Scripts\python.exe" Scripts/inject/run.py test

# Run probe (scratch file: probe.lua) → Scripts/logs/probe.txt
& ".venv\Scripts\python.exe" Scripts/inject/run.py probe

# Run inline Lua → Scripts/logs/probe.txt
& ".venv\Scripts\python.exe" Scripts/inject/run.py lua "print(type(G.main_player.foo))"
```
