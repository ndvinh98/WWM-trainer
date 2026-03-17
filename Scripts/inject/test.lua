local Reg = _G.Reg
local Utils = Reg.get("Utils")
local Logger = Reg.get("Logger")

local ok, rs = pcall(function()
	-- Test 1: plain Lua values
	print("=== dump_value tests ===")
	print("1. string: " .. Utils.dump_value("hello"))
	print("2. number: " .. Utils.dump_value(42))
	print("3. table: " .. Utils.dump_value({ a = 1, b = "two", c = { 3, 4 } }))
	print("4. nil: " .. Utils.dump_value(nil))

	-- Test 2: game objects (main_player is always available)
	local mp = G.main_player
	if mp then
		print("5. main_player type: " .. type(mp))
		print("6. dump main_player: " .. Utils.dump_value(mp, { max_depth = 2 }))

		-- Test entity_id (string)
		local eid = mp.entity_id or mp.id
		print("7. entity_id: " .. Utils.dump_value(eid))

		-- Test position (likely Vector3 instance with to_tuple)
		local ok_pos, pos = pcall(function() return mp:get_position() end)
		if ok_pos and pos then
			print("8. position: " .. Utils.dump_value(pos))
		end
	end

	-- Test 3: G.datam (dict-like game data)
	if G.datam then
		print("9. G.datam type: " .. type(G.datam))
		print("10. G.datam (shallow): " .. Utils.dump_value(G.datam, { max_depth = 1 }))
	end

	-- Test 4: space entities (if available)
	if G.space then
		local ok_ents, ents = pcall(function() return G.space:get_entities() end)
		if ok_ents and ents then
			local count = 0
			for _ in pairs(ents) do
				count = count + 1
				if count > 2 then break end
			end
			print("11. entities count sample: " .. count .. "+")
		end
	end

	print("=== all tests passed ===")
end)
if not ok then
	print("ERROR: " .. tostring(rs))
else
	print("OK: done")
end
