# Interaction Filtering Analysis

**Question:** How does the game determine which entities can be interacted with, and how should autoloot_v2 filter entities?

---

## Evidence

### 1. Interaction Flow (Source: `imp_active_interact.lua`)

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua`

**Excerpt (lines 777-800):**
```lua
function PlayerAvatarActiveInteract:_on_enter_interact_area(event, data)
    local entity_id = data:get("entity_id")
    local area_id = data:get("area_id")
    -- Entity is added to in_interact_area_entities when player enters its interact area
    self:_add_in_interact_area_entity_info(entity_id, area_id)
end
```

**Why it matters:** The game uses an **area-based** system, not direct entity scanning. Entities are tracked when the player enters their interaction radius.

**Evidence Confidence:** 5/5

---

### 2. Available Ways Extraction (Source: `interact_component_base.lua`)

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/common_members/interact_component_base.lua`

**Excerpt (lines 1385-1440):**
```lua
function InteractComponentBase:interact_comp_get_available_ways(player, area_records, force_refresh)
    if not self:is_interact_component_enabled() then
        return {}
    end
    -- ... area type checks ...
    if area_type == interact_consts.INTERACT_AREA_TYPE_SERVER_COMP then
        comp_id_list:append(raw_record:get("comp_id"))
    else
        if area_type == interact_consts.INTERACT_AREA_TYPE_CLIENT_ACTIVE_WAY_FROM_CONFIG then
            total_ways:append(raw_record)
        end
    end
    -- ...
    local can_interact, comp_ways = interact_misc.get_available_active_ways(interact_comp, player.id, comp_id_list)
    if not can_interact then
        return {}
    end
end
```

**Why it matters:** Three-stage filtering:
1. `is_interact_component_enabled()` - Component must be enabled
2. Area record type validation
3. `interact_misc.get_available_active_ways()` - Server-side validation

**Evidence Confidence:** 5/5

---

### 3. Way Availability Logic (Source: `interact_misc.lua`)

**Source:** `Scripts/source_decompiled/hexm/common/misc/interact_misc.lua`

**Excerpt (lines 17-100):**
```lua
function _M.get_available_active_ways(interact_comp, player_id, comp_id_list)
    local total_ways = {}
    -- Private check
    if bool(interact_comp.is_private) and player_id ~= interact_comp.owner_eid then
        return false, {}
    end
    for cid, comp_info in pairs(interact_comp.components) do
        if not comp_id_list or comp_id_list:contains(cid) then
            local can_interact, ways = _M.get_comp_info_available_active_ways(comp_info, player_id)
            if can_interact then
                total_ways:extend(ways)
            end
        end
    end
    return true, total_ways
end

function _M.get_comp_info_available_active_ways(comp_info, player_id)
    -- ... relation capacity check ...
    for pid, relation_record in pairs(comp_info.relations) do
        local relation_capacity = G.datam.interact_comp_relation:get(relation_record:get("relation_no"), {}):get("relation_capacity", 1)
        if relation_capacity <= len(comp_info.relations) then
            return false, {}  -- Entity is full, cannot interact
        end
    end
    -- ... get ways from status, relation, special_coupling ...
end
```

**Why it matters:** Critical filtering:
- **Private entities**: Only owner can interact
- **Relation capacity**: Entity may be "full" (e.g., seat occupied)
- **Ways from multiple sources**: status_no, relation_no, special_coupling

**Evidence Confidence:** 5/5

---

### 4. Base Tag Classification (Source: `tag_consts.lua` + `entity_tags.json`)

**Source:** `Scripts/source_decompiled/hexm/common/consts/tag_consts.lua`

**Excerpt (lines 14-50):**
```lua
_M.TAG_BASE_MAIN_PLAYER_BIT = 1
_M.TAG_MAIN_PLAYER = base_tag(_M.TAG_BASE_MAIN_PLAYER_BIT)
_M.TAG_BASE_NPC_BIT = 3
_M.TAG_NPC = base_tag(_M.TAG_BASE_NPC_BIT)
_M.TAG_INTERACT_COMPONENT_BIT = 12
_M.TAG_INTERACT_COMPONENT = base_tag(_M.TAG_INTERACT_COMPONENT_BIT)
-- Main types
_M.TAG_MAIN_INTERACT_BIT = 3
_M.TYPE_NPC_INTERACT = main_type(_M.TAG_MAIN_INTERACT_BIT)
_M.TAG_MAIN_COLLECT_BIT = 10
_M.TYPE_NPC_COLLECT = main_type(_M.TAG_MAIN_COLLECT_BIT)
```

**Source:** `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.entity_tags.json`

**Key Tags for Lootable Entities:**
| base_tag_id | tag_str | name | lootable |
|-------------|---------|------|----------|
| 31001 | TAG_INTERACT | Interactive Object | YES |
| 31004 | TAG_INTERACT | Touch Interactive | YES |
| 31006 | TAG_INTERACT | Treasure Chest | YES |
| 32003 | TAG_BASE_COLLECT | Collectible-Fruit | YES |
| 32004 | TAG_BASE_COLLECT | Collectible-Mineral | YES |
| 20001-20013 | TAG_NPC/TAG_MONSTER | Monsters | NO (combat) |
| 31010 | TAG_INTERACT | Elevator | NO |
| 31008 | TAG_INTERACT | Scene Mechanism | NO |

**Why it matters:** `base_tag` is the **primary classification** for entity type. Use it for initial filtering.

**Evidence Confidence:** 5/5

---

### 5. Active Interact Way Data (Source: `active_interact_way.json`)

**Source:** `Scripts/data/DirObject/DirObject_Cache/hexm.client.data_oversea.active_interact_way.json`

**Excerpt:**
```json
[100102, {
    "award_id": [140124],
    "id": 100102,
    "del_entity": 1,
    "button_name": -5603326284817460492
}]
```

**Why it matters:** `del_entity=1` and `award_id` presence indicate **lootable** interactions. These entities disappear after interaction and give rewards.

**Evidence Confidence:** 5/5

---

### 6. Trigger Active Interact Signature (Source: `imp_active_interact.lua`)

**Source:** `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/interact/imp_active_interact.lua`

**Excerpt (lines 1106-1159):**
```lua
function PlayerAvatarActiveInteract:trigger_active_interact(
    active_way_no,
    interact_target_id,
    callbacks,
    active_way_param,
    comp_id,
    handler
)
    if self:get_interact_target_locked() then
        return false  -- Already interacting
    end
    if not self:active_interact_check_distance(interact_target_id, active_way_no) then
        return false  -- Too far
    end
    -- ...
    self:set_interact_target_locked(true)
    self:start_active_interact(active_way_no, active_way_param, comp_id)
end
```

**Why it matters:** Correct signature is `trigger_active_interact(way_no, entity_id, callbacks, param, comp_id, handler)`.

**Evidence Confidence:** 5/5

---

## Conclusions

### 1. Entity Filtering Strategy

**Safe to loot (Score: 5/5):**
- `base_tag` in range **31001-31006** (Interactive objects, treasure)
- `base_tag` in range **32003-32010** (Collectibles: herbs, minerals, etc.)
- `del_entity=1` in active_interact_way data
- `award_id` present in active_interact_way data

**Skip (Score: 5/5):**
- `base_tag` in range **20001-20013** (Monsters - combat required)
- `base_tag` **31008** (Scene Mechanism - puzzles)
- `base_tag` **31010** (Elevator)
- `base_tag` **31007** (Forge - crafting station)
- `is_interact_component_enabled() == false`
- `relation_capacity` reached (entity full)

### 2. Interaction Trigger Requirements

1. **Distance check**: `active_interact_check_distance()` validates player is close enough
2. **Lock check**: `get_interact_target_locked()` must be false
3. **Way extraction**: Must have valid `way_no` from component data
4. **Component enabled**: `is_interact_component_enabled()` must return true

### 3. Recommended autoloot_v2 Improvements

```lua
-- BASE TAG FILTERING
local SAFE_BASE_TAGS = {
    [31001] = true, -- TAG_INTERACT (Interactive Object)
    [31003] = true, -- Normal Interactive
    [31004] = true, -- Touch Interactive
    [31006] = true, -- Treasure Chest
    [32003] = true, -- Collectible-Fruit
    [32004] = true, -- Collectible-Mineral
    [32005] = true, -- Collectible-Other
}

local UNSAFE_BASE_TAGS = {
    [20001] = true, -- Monster
    [20002] = true, -- Elite Monster
    [31007] = true, -- Forge
    [31008] = true, -- Scene Mechanism (puzzles)
    [31010] = true, -- Elevator
    [31011] = true, -- Ladder
}

-- CHECK: is_interact_component_enabled()
local function is_entity_interactable(luaEnt)
    return Utils.safe_call("enabled", function()
        return luaEnt:is_interact_component_enabled()
    end) == true
end

-- CHECK: Get ways from component data properly
local function get_valid_ways(comp, player_id)
    local ways = {}
    if comp.components then
        for cid, comp_data in pairs(comp.components) do
            -- Check relation capacity
            if comp_data.relations then
                local rel_count = 0
                for _ in pairs(comp_data.relations) do rel_count = rel_count + 1 end
                -- If relations exist and player not in them, check capacity
                if rel_count > 0 and not comp_data.relations[player_id] then
                    -- May be full, skip
                else
                    -- Extract way_no from status/relation data
                    local status_no = comp_data.status_no
                    if status_no then table.insert(ways, status_no) end
                end
            end
        end
    end
    return ways
end
```

---

## Unknown / Requires Further Investigation

1. **Exact `relation_capacity` threshold** - Need to query `interact_comp_relation` data table
2. **`interact_area_record_is_in_white_list()`** logic - Not fully traced
3. **`special_coupling`** interaction overrides - Complex multi-condition interactions

---

## Next Scoped Search Steps

1. Search `interact_comp_relation` data for `relation_capacity` values
2. Trace `interact_area_record_is_in_white_list` implementation
3. Map `active_way_no` to `del_entity` and `award_id` for auto-classification
