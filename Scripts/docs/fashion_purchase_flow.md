# Question / Scope
Map the client flow for buying fashion / appearance items (weapon skins, effects, hair, accessories, clothes, skins) and assess whether a client could apply an item without purchasing it (server-authority bypass).

# Evidence
- Source: Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_shops.lua  
  Excerpt: `...request_shop_buy... G.net:call_server("rpc_shop_buy", shop_no, sid, count, kwargs)` after inventory checks.  
  Why it matters: Purchase requests are sent to the server; the client does not grant items locally.  
  Evidence Confidence: 5/5

- Source: Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_shops.lua  
  Excerpt: `function PlayerAvatarMember:rpc_shop_buy(err, shop_no, ldata, ex)... if err ~= ERR_OK then ... return end ... dispatch(E_STORE_BUY_BACK, {ldata, ex}) ... build reward_pack from ldata`  
  Why it matters: Server returns success/failure and the item list; rewards are built only from server-provided data.  
  Evidence Confidence: 5/5

- Source: Scripts/source_decompiled/hexm/common/property_define/avatar/fashion.lua  
  Excerpt: `_flag_own = Property.OWN_CLIENT | Property.PERSISTENT ... Property(FashionProp, "assets", CustomMapType, _flag_own)`  
  Why it matters: Fashion ownership (`assets`) is a server-persisted property; the server is the source of truth.  
  Evidence Confidence: 4/5

- Source: Scripts/source_decompiled/hexm/client/manager/fashion_data_manager.lua  
  Excerpt: `G.uwsgi_manager:post_to_uwsgi("/fashion_service/get_player_guise_bag", {pid, hostnum}, ...)` with cache fallback to `G.net:get_avatar().guise.bag`.  
  Why it matters: Ownership/bag data is fetched from server endpoints (or synced avatar state for self), not from local assets.  
  Evidence Confidence: 4/5

- Source: Scripts/source_decompiled/hexm/common/misc/fashion_misc.lua  
  Excerpt: `is_asset_owned(avt, fashion_no) -> return avt.fashion.assets:contains(fashion_no) or default unlocks`.  
  Why it matters: UI ownership checks rely on the server-synced `assets` list; client files alone do not mark items owned.  
  Evidence Confidence: 4/5

- Source: Scripts/source_decompiled/hexm/client/util/guise_utils.lua  
  Excerpt: `one_click_use_stuff` sends `G.net:call_server("guise_force_wear_suit_by_stuff"...), ...("guise_force_equip_by_No", stuff_no), ("closing_show_use", stuff_no), ("kongfu_fx_use", kongfu_id, fx_no)` before applying visuals.  
  Why it matters: Equipping/using appearance items is executed via server RPCs, not purely client-side.  
  Evidence Confidence: 4/5

- Source: Scripts/source_decompiled/hexm/client/entities/server/player_avatar_members/imp_guise.lua  
  Excerpt: `guise_force_equip_cb(e_c)` / `guise_equip_cb(e_c)` handle server callbacks; on non-OK errcode the client aborts updates.  
  Why it matters: Server approval is required for equip; unauthorized requests can be rejected.  
  Evidence Confidence: 4/5

# Conclusions (score ≥3 only)
- Purchase flow is server-authoritative: the client only issues `rpc_shop_buy`; items and rewards are granted based on server response payloads (E1, E2).  
- Fashion/guise ownership is stored as server-persisted properties (`fashion.assets`, `guise.bag`) and fetched from `/fashion_service` endpoints; local asset files do not confer ownership (E3, E4, E5).  
- Equipping/using skins, suits, FX, rides, and closing-show items always goes through server RPCs with errcode-checked callbacks; client visuals update only after server approval (E6, E7).  
- Therefore a client cannot persistently apply an unpurchased fashion/appearance item by client-side asset injection alone; it would need the server to accept an equip RPC for an item absent from the server-owned inventories (E3–E7).

# Unknown / Missing Evidence
- Server-side logic for `rpc_shop_buy`, `guise_force_equip_by_No`, `closing_show_use`, etc. is not in this repo; we cannot verify the exact entitlement checks performed server-side.  
- Mapping from `fashion_no` to shop `sid` is stubbed (`fashion_no2sid` returns 0), so direct fashion-item sale handling is unclear.  
- No client request for changing fashion scene indices was located; the corresponding RPC name is obscured, so apply-flow specifics for fashion “scenes” remain unverified.

# Next Scoped Search Steps
- Inspect server handlers (or traces) for `rpc_shop_buy` and `guise_force_equip_by_No` to confirm they validate ownership and deduct currency.  
- Validate `/fashion_service` responses against server inventories/logs to ensure clients cannot spoof `pid/hostnum` or item lists.  
- Map fashion items to shop entries by examining `DirObject/score_stuff_data` and any server-side mapping for `fashion_no2sid`; confirm unsold items cannot be equipped via RPCs.
