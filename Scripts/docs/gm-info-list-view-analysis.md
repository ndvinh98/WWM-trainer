1. Question / Scope

What does `Scripts/source_decompiled/hexm/client/ui/generated_view/gm_info_list_view.lua` actually do in the current decompiled client UI?

2. Evidence

- Source: `Scripts/source_decompiled/hexm/client/ui/generated_view/gm_info_list_view.lua`
  Excerpt: `local GmInfoListView = class("GmInfoListView", Widget)`, `inheritclass(GmInfoListView, CsbInterface)`, `GmInfoListView.CSB_NAME = "UIScript/gm_info_list.csb"`, and `NODES_INDEX_PATH` contains `node_cell`, `text_res_c`, `text_state`, `text_res_o`, `listview_fz`.
  Why it matters: This is a generated Cocos view wrapper. It declares the view class, points it at the `gm_info_list.csb` asset, and exposes a small set of indexed child nodes.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/generated_view/gm_info_list_view.lua`
  Excerpt: `if raw_node then soul = raw_node else soul = cocos.load_cocos(csb_name) end`, followed by `Widget.ctor(self, soul)` and `CsbInterface.ctor(self)`. Later, `on_create`, `on_set_window`, and `safe_refresh_layout` only call the base `Widget` methods, and `destroy_object` only calls `CsbInterface.on_csb_unloaded(self)` then `Widget.destroy_object(self)`.
  Why it matters: The file does not implement feature logic. Its runtime job is loading or wrapping the `.csb` node tree and forwarding normal UI lifecycle events to the base framework.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/generated_view/gm_info_list_view.lua` and `Scripts/source_decompiled/hexm/client/ui/base/node.lua`
  Excerpt: `GmInfoListView.seek_other = nil`, `clear_attr_values = nil`, `generate_children_view = nil`, `init_platform_diffs = nil`; and `Node:on_reuse()` only calls those hooks `if self.seek_other then`, `if self.generate_children_view then`, `if self.init_platform_diffs then`.
  Why it matters: This generated view has no extra generated child-view setup, no extra node seeking helpers, and no platform-specific adaptation code in the decompiled output.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/ui/windows/gm/gm_sound_info_window.lua`
  Excerpt: `self.view = self:load_view(GmInfoListView)`, then it clears `text_state`, `text_res_o`, `text_res_c`, shows `layout_h`, stores `text_1`..`text_4`, and `set_info(infos)` writes text and color into those entries.
  Why it matters: The actual feature logic using this view lives outside the generated file. In current source, this view is used as the UI shell for `SoundInfoWindow`.
  Evidence Confidence: 5/5

- Source: `Scripts/source_decompiled/hexm/client/entities/local/player_avatar_members/imp_region_sound.lua`
  Excerpt: `function PlayerAvatarMember:_debug_human_ground_noise()`, it builds `infos` from `debug_consts.HUMAN_NOISE_DIR[idx] .. ": " .. self._debug_num[idx]`, then `local w = G.ui_manager:get_or_load_window(SoundInfoWindow)` and `w:set_info(infos)`.
  Why it matters: This identifies the concrete behavior currently attached to the view shell: a GM/debug overlay for human ground noise / region sound diagnostics.
  Evidence Confidence: 4/5

3. Conclusions

- `gm_info_list_view.lua` is an auto-generated UI wrapper around `UIScript/gm_info_list.csb`. It provides structure and lifecycle wiring, not feature-specific behavior. (Score: 5/5)
- In the current decompiled client, the view is used by `gm_sound_info_window.lua` as a debug information panel. That window writes colored text rows into the view. (Score: 5/5)
- The panel is fed by `PlayerAvatarMember:_debug_human_ground_noise()`, which assembles directional debug values and pushes them into `SoundInfoWindow`. (Score: 4/5)

4. Unknown / Missing Evidence

- `gm_sound_info_window.lua` accesses `layout_h` and `text_1`..`text_4`, but those nodes are not indexed in `gm_info_list_view.lua`. The authoritative source scope used here does not include the actual `UIScript/gm_info_list.csb` asset, so the exact full node layout cannot be confirmed from current evidence alone.
- `listview_fz` is declared in `NODES_INDEX_PATH`, but its usage was not found in the current scoped search. Not found in current investigation scope - requires broader review.

5. Next Scoped Search Steps

- Inspect the original `UIScript/gm_info_list.csb` export or another authoritative asset dump to confirm the hidden nodes used by `gm_sound_info_window.lua`.
- Search the GM/debug toggles that call `_debug_human_ground_noise()` if you want the full feature entry path instead of just the view behavior.
