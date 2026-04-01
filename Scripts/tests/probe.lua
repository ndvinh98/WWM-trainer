local targets = G.space:get_entities_in_range(G.main_player:get_position(), 20, nil, nil, true)
local gmath = require("hexm.common.math.gmath")
local fmt = {}
for _, t in pairs(targets) do
	table.insert(fmt, {t, t.tag, gmath.distance(t:get_position(), G.main_player:get_position()), t.id, t.no, t.sid, t.entity_id})
end

-- sort by distance
table.sort(fmt, function(a, b) return a[3] < b[3] end)

for _, v in pairs(fmt) do
	print(string.format("\t[%.2f] %s | %s | id=%s | no=%s | sid=%s", v[3], tostring(v[1]), v[2], v[4], v[5], v[6]))
end

local dat = G.datam.entity_interact:get(4500114)
print(dat.interaction_reward)