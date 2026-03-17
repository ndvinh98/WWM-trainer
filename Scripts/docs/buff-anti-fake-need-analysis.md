# Question / Scope

What are the `has_anti_need` and `has_fake_need` buff tags actually used for?

# Evidence

## Evidence 1
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `if`
  - `show_type == buff_consts.SHOW_SERVER_ONLY`
  - `and space`
  - `and space:mode_is_single()`
  - `and sys_d:get("has_fake_need")`
  - `then`
  - `show_type = buff_consts.SHOW_ALL_CLIENTS`
- Why it matters:
  - In server buff sync, `has_fake_need` changes a server-only display mode into client-visible sync in single-mode spaces.
- Evidence Confidence: 5/5

## Evidence 2
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `local function buff_need_fake_logic(sys_d)`
  - `if sys_d:get("has_fake_need") then`
  - `return true`
  - `end`
- Why it matters:
  - `has_fake_need` is a direct positive condition for "needs fake logic" on the client fake-server side.
- Evidence Confidence: 5/5

## Evidence 3
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `if buff_need_fake_logic(sys_d) then`
  - `bh = self.buff:_add_buff_handler(buff, sys_d, true, { ["duration"] = -1 })`
  - `else`
  - `self.buff:check_dispel(sys_d, buff.fromid)`
  - `self.buff:immune_on_add(bid, sys_d)`
  - `if 0 ~= sys_d:get("buff_control_type", 0) then`
  - `self.buff:control_check_local(bid, sys_d, buff)`
- Why it matters:
  - When `has_fake_need` is true, the client creates or refreshes a real local buff handler. Without it, the fake-server path only does lightweight checks such as dispel, immunity, control, and shield sync.
- Evidence Confidence: 5/5

## Evidence 4
- Source: `Scripts/source_decompiled/hexm/client/fake_server/entities/common_members/buff_base.lua`
- Excerpt:
  - `local conf_res = sys_d:get("buff_add_resource")`
  - `if conf_res and attr_consts.is_local_res(conf_res[2]) then`
  - `return true`
  - `end`
  - `if BuffAddShieldCharged.should_enable(sys_d) then`
  - `return true`
- Why it matters:
  - `has_fake_need` sits in the same decision bucket as other cases that clearly require local simulation, such as local resources and charged shields.
- Evidence Confidence: 4/5

## Evidence 5
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/imp_buff.lua`
- Excerpt:
  - `function BaseMember:_buff_anti_on_check(event, data)`
  - `for bno, bid in pairs(self._buff_anti_records) do`
  - `local it = self.buff.buffs:get(bid)`
  - `if it and it.sys_d:get("has_anti_need") then`
  - `rm_buffs:append(it.ID)`
  - `end`
  - `self._buff_anti_records:clear()`
  - `if #rm_buffs > 0 then`
  - `self.buff:remove_buffs(rm_buffs, event)`
  - `end`
- Why it matters:
  - `has_anti_need` marks buffs that should be removed during the `_buff_anti_on_check` cleanup flow if they are present in `_buff_anti_records`.
- Evidence Confidence: 4/5

## Evidence 6
- Source: `Scripts/source_decompiled/hexm/common/combat/buff/buff_comp.lua` and `Scripts/source_decompiled/hexm/common/combat/buff/buff_funcs.lua`
- Excerpt:
  - `if owner._buff_anti_clear and kwargs:get("anti_clear") then`
  - `owner._buff_anti_clear[bid] = true`
  - `if self.owner and self.owner._buff_anti_clear then`
  - `self.owner._buff_anti_clear:pop(buffid)`
- Why it matters:
  - There is a separate `anti_clear` tracking path, but it does not reference `has_anti_need` directly in the current investigation scope.
- Evidence Confidence: 3/5

# Conclusions

1. `has_fake_need` means the buff needs local/fake-server simulation rather than only passive sync or display. It can force server-only buffs to be shown to the client in single-mode and can trigger creation of a local buff handler. Confidence: 5/5
2. `has_fake_need` is grouped with other cases that obviously require client-side logic, including local resource buffs and charged shield buffs. Confidence: 4/5
3. `has_anti_need` marks buffs that are eligible to be removed by the `_buff_anti_on_check` cleanup path when their IDs are present in `_buff_anti_records`. Confidence: 4/5

# Unknown / Missing Evidence

- The code that populates `_buff_anti_records` or dispatches `_buff_anti_on_check` was not found in the current scoped search.
- The exact gameplay event behind the "anti" check therefore remains unresolved in current investigation scope.
- `anti_clear` appears related by name but is not directly linked to `has_anti_need` in the located code.

# Next Scoped Search Steps

1. Trace `_buff_anti_records` initialization and writes outside the current narrowed combat-buff scope.
2. Trace event/dispatcher bindings for `_buff_anti_on_check`.
3. Compare `anti_clear` kwargs producers with `has_anti_need` buff rows to see whether they participate in the same gameplay mechanic.
