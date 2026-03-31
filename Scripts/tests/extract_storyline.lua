


-- Dump the "collecting_challenge" storyline for GUIHUO (type 8)
local json = require("SunshineSDK.compat").json

-- 1. Extract the .etsb storyline via MPatch
local st_path = "client/wanfa/miaomiaomiao/collecting_challenge"
local mgr = require("SunshineSDK.Storyline.StorylineSystem").GetRepositoryMgr()
local real_path = mgr:GetStorylineRealPath(st_path)
print("Real path:", real_path)

local exists = MPatch.FileExistInPackage("Storyline/" .. real_path)
print("File exists in package:", exists)

if exists then
    local raw = MPatch.GetRawDataInPackage("Storyline/" .. real_path)
    print("Raw data size:", #raw)
    
    local data = json.decode(raw)
    
    -- 2. Extract Variables
    print("\n=== VARIABLES ===")
    for key, var in pairs(data.Variables or {}) do
        print(string.format("  %s: type=%s default=%s", var.name or "?", var.type or "?", tostring(var.defaultValue)))
    end
    
    -- 3. Extract Node types and connections
    print("\n=== NODES ===")
    local nodes = data.Storyline and data.Storyline.NodeBuffer or {}
    for idx, node in ipairs(nodes) do
        local node_type = node.Type or "?"
        local node_data = node.Data or {}
        
        -- Format key data fields
        local data_str = ""
        for k, v in pairs(node_data) do
            data_str = data_str .. string.format("%s=%s ", k, tostring(v))
        end
        
        -- Format connections
        local conn_str = ""
        local connect = node.ConnectData or {}
        for port_name, connections in pairs(connect) do
            for _, c in ipairs(connections) do
                conn_str = conn_str .. string.format("[%s→node%s:%s] ", port_name, c.dstNodeID, c.dstPortName)
            end
        end
        
        print(string.format("  [%d] %s | %s| %s", idx, node_type, data_str, conn_str))
    end
    
    -- 4. Save pretty JSON for later analysis
    local pretty = json.encode(data)
    local f = io.open("Scripts/logs/guihuo_storyline.json", "w")
    if f then
        f:write(pretty)
        f:close()
        print("\nSaved to Scripts/logs/guihuo_storyline.json")
    end
else
    print("ERROR: Storyline file not found in package!")
end

-- 5. Also check: find a nearby guihuo game_id
print("\n=== GUIHUO GAME IDS (type=8) ===")
local all_games = G.datam.region_game_config:items()
local guihuo_games = {}
for _, item in pairs(all_games) do
    local game_id = item[1]
    local config = item[2]
    if config.type == 8 then
        local pos = config.position
        local pos_str = pos and string.format("(%s,%s,%s)", pos[1] or pos.x, pos[2] or pos.y, pos[3] or pos.z) or "?"
        table.insert(guihuo_games, {game_id, pos_str, config.space or "?", config.flow_id or "?"})
    end
end
table.sort(guihuo_games, function(a, b) return a[1] < b[1] end)
for _, g in pairs(guihuo_games) do
    print(string.format("  game_id=%s pos=%s space=%s flow_id=%s", g[1], g[2], g[3], g[4]))
end
print("Total guihuo games:", #guihuo_games)