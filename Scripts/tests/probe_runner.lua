-- Scripts/tests/probe_runner.lua
-- Wraps probe.lua with standard logging boilerplate.
-- Output: Scripts/logs/probe.txt (cleared on each run)
-- Usage: dofile('C:/temp/Where Winds Meet/Scripts/tests/probe_runner.lua')
-- Write your probe code in: Scripts/tests/probe.lua (no boilerplate needed)

pcall(function()
	local f = io.open("C:/temp/Where Winds Meet/Scripts/logs/probe.txt", "w")
	if f then
		f:close()
	end
end)

_G.print_file = "probe.txt"

local ok, err = pcall(dofile, "C:\\temp\\Where Winds Meet\\Scripts\\tests\\probe.lua")
if not ok then
	print("[PROBE] ERROR: " .. tostring(err))
end

print("\n========== PROBE COMPLETE ==========")
_G.print_file = nil
