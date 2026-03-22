# Remote Entity Destroy — Research Report

## Question
How to remotely destroy an entity (InteractComEntity, Npc, etc.) via direct API call, without performing any game action (fire arrow, use skill, etc.)?

## Answer

```lua
G.space:remove_entity(entity_id, strategy)
```

This is the **public API** for destroying any entity in the current space. It requires only the entity's string ID and an optional destroy strategy.

---

## Evidence

### 1. API Signature — Score 5/5 (Probe Confirmed)

**Source**: [imp_entity_manager.lua](file:///c:/temp/Where%20Winds%20Meet/Scripts/source_decompiled/hexm/client/entities/local/space_members/imp_entity_manager.lua#L1016-L1038)

```lua
function SpaceMember:remove_entity(entity_id, remove_strategy)
    local entity_loader = self._entity_loaders:get(entity_id)
    remove_strategy = (remove_strategy or entity_consts.ENT_DESTROY_DEFAULT) & ~self._forbid_destroy_strategy
    return entity_loader:start_destroy_entity(remove_strategy)
end
```

**Probe result** (`probe_entity_destroy2.txt`):
```
Target: id=ins_entity1630240629_interact_comp no=6600212 sid=1630240629 dist=1.1
ok=true result/err=nil
Entity exists after: false

Target NPC: id=p_npc_1630240599 dist=22.2
ok=true result/err=nil
NPC exists after: false
```

Both InteractComEntity and Npc destroyed successfully in one call. Entity vanished from `get_entities()` and `get_entity_loader()` immediately.

### 2. Destroy Strategies — Score 5/5 (Probe Confirmed)

| Constant | Value | Behavior |
|---|---|---|
| `ENT_DESTROY_FORCE_IMMEDIATE` | `0` | Destroy immediately, no animation |
| `ENT_DESTROY_DELAY` | `1` | Queue for delayed destroy |
| `ENT_DESTROY_FADE_OUT` | `4` | Play fade-out animation |
| `ENT_DESTROY_PAR` | `8` | Parallel destroy allowed |
| `ENT_DESTROY_DEFAULT` | `12` | `FADE_OUT | PAR` |

For instant destruction, use strategy `0` (FORCE_IMMEDIATE).

### 3. Entity Access — Score 5/5 (Probe Confirmed)

| Method | Returns | Use Case |
|---|---|---|
| `G.space:get_entities()` | `{entity_id: entity}` map | Enumerate all entities |
| `G.space:get_entity(entity_id)` | entity or nil | Get by exact ID |
| `G.space:get_entities_with_type("Npc")` | `{entity_id: entity}` | Filter by type |
| `G.space:get_npc_by_no(entity_no)` | list of entities | Find by NPC number |
| `G.space:get_entity_by_serial_no(serial_no)` | entity | Find by serial ID |
| `entity.entity_no` / `entity.serial_id` / `entity.id` | number/string | Entity identifiers |

Entity types found at runtime: `InteractComEntity(22), StaticEntity(27), Trap(18), AirWall(6), Npc(5), SimpleVisualEntity(5), Accessory(4), LocalEntity(3), SimpleInteractComEntity(3), EffectEntity(1), FakeAvatar(1), PlayerAvatar(1)`.

### 4. Destroy Call Chain (from tracecall)

```
G.space:remove_entity(entity_id)
  └─ entity_loader:start_destroy_entity(remove_strategy)
       └─ execute_once_destroy_task()
            └─ Stage pipeline: LEAVE_SPACE → DESTROY_SHOW → PRE_FINISH → COSTLY_FINI → FINISH → DESTROY_LOADER
                 └─ entity:_destroy_pre_fini() → _callReverseComponents("behit") → behit_base.lua
```

---

## Usage Examples

```lua
-- Destroy specific entity by ID
G.space:remove_entity("ins_entity1630240629_interact_comp", 0)

-- Destroy nearest NPC
local entities = G.space:get_entities()
for eid, entity in pairs(entities) do
    if entity.__class__.__name__ == "Npc" then
        G.space:remove_entity(eid, 0)
        break
    end
end

-- Destroy all entities matching entity_no
for _, entity in pairs(G.space:get_npc_by_no(6600212)) do
    G.space:remove_entity(entity.id, 0)
end

-- Destroy all non-player entities within radius
for eid, entity in pairs(G.space:get_entities()) do
    if eid ~= G.main_player.id and entity:get_distance_to_player() < 50 then
        G.space:remove_entity(eid, 0)
    end
end
```

## Probe Logs
- [probe_entity_destroy.txt](file:///c:/temp/Where%20Winds%20Meet/Scripts/logs/probe_entity_destroy.txt) — API enumeration (dry run)
- [probe_entity_destroy2.txt](file:///c:/temp/Where%20Winds%20Meet/Scripts/logs/probe_entity_destroy2.txt) — Live destroy confirmation
