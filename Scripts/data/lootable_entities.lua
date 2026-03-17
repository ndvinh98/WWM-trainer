-- ============================================================
-- AUTO-GENERATED LOOTABLE ENTITY DATA
-- ============================================================
-- Generated: 2026-02-05 12:00:39
-- Use with AutoLoot for reliable entity filtering
--
-- TERMINOLOGY:
-- - npc_no: Entity config ID (applies to ALL entities, not just NPCs)
-- - base_tag: Primary entity classification ID (numeric)
-- - base_tag_str: Tag string identifier (e.g., TAG_INTERACT)
-- - entity_type: Entity category (0=NPC, 1=Player, 3=Interactive)
-- - wanfa_type: Gameplay category (1=herbs, 2=minerals, 9=treasure, etc.)
-- - serial_id: Unique instance ID for spawned entity
-- - interaction_reward: Reward data attached to entity
-- - interact_config: Interaction configuration ID array
-- - is_far_visible: Whether entity visible from distance (1=yes)
-- - client_interact_save_type: 2 = Collectible (per-character save)
-- - addition_tags: Additional tag strings applied to entity
-- ============================================================

local LOOT_DATA = {}

-- ============================================================
-- BASE TAG DEFINITIONS
-- ============================================================
-- base_tag is the PRIMARY entity classification system
-- Maps numeric IDs to TAG_* string identifiers
-- Key for determining entity type and lootability
-- ============================================================
LOOT_DATA.BASE_TAG_DEFS = {
	[20001] = {
		tag_str = "TAG_NPC",
		name = "Normal Monster",
		safe = false,
		desc = "Regular enemy monsters",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_SMALL_MONSTER",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20002] = {
		tag_str = "TAG_NPC",
		name = "Elite Monster",
		safe = false,
		desc = "Elite/stronger enemies",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_ELITE_MONSTER",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20003] = {
		tag_str = "TAG_NPC",
		name = "Boss",
		safe = false,
		desc = "Boss monsters",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_BOSS_MONSTER",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20004] = {
		tag_str = "TAG_COMBATIVE_ANIMAL",
		name = "Combat Animal",
		safe = false,
		desc = "Hostile animals",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_NPC",
			"TAG_ANIMAL_NPC",
			"TAG_ATTACK_STROKE",
			"TAG_SMALL_MONSTER",
			"TAG_MODE_INTERACT_ALL",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20005] = {
		tag_str = "TAG_NPC",
		name = "Robot Monster",
		safe = false,
		desc = "Mechanical enemies",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_ROBOT_MONSTER",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20006] = {
		tag_str = "TAG_NPC",
		name = "Mini Boss",
		safe = false,
		desc = "Minor boss enemies (Small Leader)",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_SMALL_BOSS",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20007] = {
		tag_str = "TAG_COMBATIVE_ANIMAL",
		name = "Combat Animal Normal",
		safe = false,
		desc = "Normal tier hostile animals",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_SMALL_MONSTER",
			"TAG_ANIMAL_NPC",
			"TAG_ATTACK_STROKE",
			"TAG_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20008] = {
		tag_str = "TAG_COMBATIVE_ANIMAL",
		name = "Combat Animal Elite",
		safe = false,
		desc = "Elite tier hostile animals",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_ELITE_MONSTER",
			"TAG_ANIMAL_NPC",
			"TAG_ATTACK_STROKE",
			"TAG_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20009] = {
		tag_str = "TAG_COMBATIVE_ANIMAL",
		name = "Combat Animal Boss",
		safe = false,
		desc = "Boss tier animals",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_BOSS_MONSTER",
			"TAG_ANIMAL_NPC",
			"TAG_ATTACK_STROKE",
			"TAG_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20010] = {
		tag_str = "TAG_COMBATIVE_ANIMAL",
		name = "Combat Animal Leader",
		safe = false,
		desc = "Leader tier animals",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_SMALL_BOSS",
			"TAG_ANIMAL_NPC",
			"TAG_ATTACK_STROKE",
			"TAG_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20011] = {
		tag_str = "TAG_AI_AVATAR",
		name = "New Robot",
		safe = false,
		desc = "New version robot NPCs (AI Avatar)",
		addition_tags = { "TAG_ATTACK_STROKE", "TAG_MODE_INTERACT_ALL", "TAG_MODE_MISSION_SYNC", "TAG_CHARACTER_TYPE" },
	},
	[20012] = {
		tag_str = "TAG_NPC",
		name = "Spike Plate No Listen",
		safe = false,
		desc = "Spike trap (no wind detection - cannot be detected by listening skill)",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_SMALL_MONSTER",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[20013] = {
		tag_str = "TAG_NPC",
		name = "Multiplayer Boss",
		safe = false,
		desc = "Multi-player boss monsters",
		addition_tags = {
			"TAG_MONSTER",
			"TAG_BOSS_MONSTER",
			"TAG_MULTI_BOSS",
			"TAG_ATTACK_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
		},
	},
	[30001] = {
		tag_str = "TAG_DESTRUCT",
		name = "Destructible",
		safe = false,
		desc = "Breakable objects",
		addition_tags = {},
	},
	[31001] = {
		tag_str = "TAG_INTERACT",
		name = "Interactive Object",
		safe = true,
		desc = "General interactive objects (main category)",
		addition_tags = { "TAG_GENERAL_STROKE" },
	},
	[31002] = {
		tag_str = "TAG_INTERACT_SCENE_STATIC",
		name = "Scene Static Object",
		safe = false,
		desc = "Static scene interactables",
		addition_tags = { "TAG_INTERACT", "TAG_GENERAL_STROKE" },
	},
	[31003] = {
		tag_str = "TAG_INTERACT",
		name = "Normal Interactive",
		safe = true,
		desc = "Standard interactive objects",
		addition_tags = { "TAG_INTERACT_ITEM_STATIC", "TAG_GENERAL_STROKE" },
	},
	[31004] = {
		tag_str = "TAG_INTERACT",
		name = "Touch Interactive",
		safe = true,
		desc = "Touch-triggered interactables",
		addition_tags = { "TAG_INTERACT_TOUCH", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31005] = {
		tag_str = "TAG_INTERACT",
		name = "Carryable Object",
		safe = false,
		desc = "Objects that can be carried/picked up",
		addition_tags = { "TAG_INTERACT_CARRY", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31006] = {
		tag_str = "TAG_INTERACT",
		name = "Treasure Chest",
		safe = true,
		desc = "Treasure boxes/chests (TAG_TREASURE_BOX)",
		addition_tags = { "TAG_TREASURE_BOX", "TAG_GENERAL_STROKE" },
	},
	[31007] = {
		tag_str = "TAG_INTERACT",
		name = "Forge Station",
		safe = false,
		desc = "Crafting forge (TAG_FORGE)",
		addition_tags = { "TAG_FORGE", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31008] = {
		tag_str = "TAG_INTERACT",
		name = "Scene Mechanism",
		safe = false,
		desc = "Puzzle mechanisms (TAG_SCENE_MECHANISM)",
		addition_tags = { "TAG_SCENE_MECHANISM", "TAG_GENERAL_STROKE" },
	},
	[31009] = {
		tag_str = "TAG_VEHICLE",
		name = "Vehicle Platform",
		safe = false,
		desc = "Vehicle/mount platforms",
		addition_tags = { "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31010] = {
		tag_str = "TAG_INTERACT",
		name = "Elevator",
		safe = false,
		desc = "Elevators (TAG_ELEVATOR)",
		addition_tags = { "TAG_ELEVATOR", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31011] = {
		tag_str = "TAG_LADDER",
		name = "Ladder",
		safe = false,
		desc = "Climbable ladders",
		addition_tags = { "TAG_INTERACT", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE", "TAG_STATIONARY" },
	},
	[31012] = {
		tag_str = "TAG_JIEBEI",
		name = "Boundary Marker",
		safe = false,
		desc = "Area boundary markers (world discovery points)",
		addition_tags = {
			"TAG_INTERACT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_GENERAL_STROKE",
			"TAG_STATIONARY",
			"TAG_XS_XUANSHANG",
		},
	},
	[31013] = {
		tag_str = "TAG_INTERACT",
		name = "Outpost Interactive",
		safe = false,
		desc = "Outpost/camp interactables (TAG_JUDIAN)",
		addition_tags = { "TAG_JUDIAN", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31014] = {
		tag_str = "TAG_INTERACT",
		name = "Bomb",
		safe = false,
		desc = "Explosive bombs (TAG_ZHADAN)",
		addition_tags = { "TAG_ZHADAN", "TAG_GENERAL_STROKE" },
	},
	[31015] = {
		tag_str = "TAG_INTERACT",
		name = "Door",
		safe = false,
		desc = "Doors (TAG_GATE)",
		addition_tags = { "TAG_GATE", "TAG_GENERAL_STROKE" },
	},
	[31016] = {
		tag_str = "TAG_INTERACT",
		name = "Suspicious Object",
		safe = true,
		desc = "Investigation points (Qiqiao - something suspicious)",
		addition_tags = { "TAG_GENERAL_STROKE" },
	},
	[31017] = {
		tag_str = "TAG_INTERACT",
		name = "Campfire",
		safe = false,
		desc = "Rest campfires",
		addition_tags = { "TAG_GENERAL_STROKE", "TAG_MODE_INTERACT_ALL", "TAG_STATIONARY" },
	},
	[31018] = {
		tag_str = "TAG_INTERACT",
		name = "Dynamite Barrel",
		safe = false,
		desc = "Explosive barrels (TAG_DYNAMITE)",
		addition_tags = { "TAG_DYNAMITE", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31019] = {
		tag_str = "TAG_INTERACT",
		name = "Turret",
		safe = false,
		desc = "Cannon/turret/fire mechanism/crossbow platforms (TAG_TURRET)",
		addition_tags = { "TAG_TURRET", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31020] = {
		tag_str = "TAG_INTERACT",
		name = "Rotating Platform",
		safe = false,
		desc = "Rotating puzzle platforms (TAG_ROTATE_MOVE_PLATFORM)",
		addition_tags = { "TAG_ROTATE_MOVE_PLATFORM", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31021] = {
		tag_str = "TAG_INTERACT",
		name = "Telekinesis Cable",
		safe = false,
		desc = "Ink Mountain chain mechanism (Moshan Dao Iron Chain Box)",
		addition_tags = { "TAG_TELEKINESIS_CABLE" },
	},
	[31022] = {
		tag_str = "TAG_INTERACT",
		name = "Telekinesis Box",
		safe = false,
		desc = "Ink Mountain portal box (Moshan Dao Tongtian Box)",
		addition_tags = { "TAG_TELEKINESIS_TRANSBOX" },
	},
	[31023] = {
		tag_str = "TAG_SIGN",
		name = "Signpost",
		safe = false,
		desc = "Road signs (low interaction priority) - ALWAYS SKIP",
		addition_tags = { "TAG_INTERACT", "TAG_NO_STROKE", "TAG_MODE_INTERACT_ALL", "TAG_STATIONARY" },
	},
	[31024] = {
		tag_str = "TAG_INTERACT",
		name = "Gameplay Interactive",
		safe = true,
		desc = "Gameplay-specific interactables",
		addition_tags = { "TAG_INTERACT_SCENE_STATIC", "TAG_GENERAL_STROKE", "TAG_STROKE_RANGE_70" },
	},
	[31025] = {
		tag_str = "TAG_INTERACT",
		name = "Interactive No Outline",
		safe = true,
		desc = "Interactive without wind detection outline (no listening skill highlight)",
		addition_tags = {},
	},
	[31026] = {
		tag_str = "TAG_INTERACT_SCENE_STATIC",
		name = "Client Interactive Static",
		safe = false,
		desc = "Client-side static interactables (multiplayer: treated as client-side interactive)",
		addition_tags = { "TAG_INTERACT", "TAG_CLIENT_INTERACT", "TAG_GENERAL_STROKE" },
	},
	[31027] = {
		tag_str = "TAG_INTERACT",
		name = "Interactive General Alt",
		safe = true,
		desc = "Alternative general interactive (with multiplayer support)",
		addition_tags = { "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[31028] = {
		tag_str = "TAG_AI_MODEL",
		name = "AI Created Model",
		safe = false,
		desc = "AI-generated models",
		addition_tags = {},
	},
	[31029] = {
		tag_str = "TAG_LocalEntity",
		name = "Local Entity",
		safe = false,
		desc = "Client-local entities",
		addition_tags = {},
	},
	[32000] = {
		tag_str = "TAG_BASE_COLLECT",
		name = "Collectible Base",
		safe = true,
		desc = "Base collectible type (total type)",
		addition_tags = { "TAG_INTERACT", "TAG_COLLECT_STROKE" },
	},
	[32001] = {
		tag_str = "TAG_BASE_COLLECT",
		name = "Collectible Tree",
		safe = true,
		desc = "Wood/tree gathering nodes",
		addition_tags = {
			"TAG_COLLECT_TREE",
			"TAG_INTERACT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_STATIONARY",
		},
	},
	[32002] = {
		tag_str = "TAG_BASE_COLLECT",
		name = "Collectible Grass",
		safe = true,
		desc = "Herb/grass gathering nodes",
		addition_tags = {
			"TAG_COLLECT_GRASS",
			"TAG_INTERACT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_STATIONARY",
		},
	},
	[32003] = {
		tag_str = "TAG_BASE_COLLECT",
		name = "Collectible Fruit",
		safe = true,
		desc = "Fruit gathering nodes",
		addition_tags = {
			"TAG_COLLECT_GRASS",
			"TAG_INTERACT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_STATIONARY",
		},
	},
	[32004] = {
		tag_str = "TAG_BASE_COLLECT",
		name = "Collectible Ore",
		safe = true,
		desc = "Mining/ore nodes",
		addition_tags = {
			"TAG_COLLECT_MINE",
			"TAG_INTERACT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_STATIONARY",
		},
	},
	[32007] = {
		tag_str = "TAG_SIMPLE_MOVABLE_INTERACT",
		name = "Small Movable Collectible",
		safe = true,
		desc = "Small movable gathering items",
		addition_tags = { "TAG_BASE_COLLECT", "TAG_MODE_INTERACT_ALL", "TAG_COLLECT_STROKE", "TAG_DEFAULT_NEAR_AOI" },
	},
	[32008] = {
		tag_str = "TAG_NPC",
		name = "Collectible Fish",
		safe = true,
		desc = "Fishing spots",
		addition_tags = {
			"TAG_COLLECT_FISH",
			"TAG_BASE_COLLECT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_STATIONARY",
			"TAG_CHARACTER_TYPE",
		},
	},
	[32019] = {
		tag_str = "TAG_INTERACT",
		name = "Small Static Collectible",
		safe = true,
		desc = "Small non-movable gathering items",
		addition_tags = {
			"TAG_COLLECT_GRASS",
			"TAG_BASE_COLLECT",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COLLECT_STROKE",
			"TAG_DEFAULT_NEAR_AOI",
			"TAG_STATIONARY",
		},
	},
	[33001] = {
		tag_str = "TAG_SCENE_ENTITY",
		name = "Scene Decoration",
		safe = false,
		desc = "Non-interactive scene decoration (deprecated - use 33003 instead)",
		addition_tags = {},
	},
	[33002] = {
		tag_str = "TAG_DATA_NPC",
		name = "Empty Entity",
		safe = false,
		desc = "Data-only entity with no function",
		addition_tags = {},
	},
	[33003] = {
		tag_str = "TAG_SCENE_HEX_MODEL_ENTITY",
		name = "Scene Hex Model",
		safe = false,
		desc = "Scene decoration using hex model (non-interactive, no tracking)",
		addition_tags = {},
	},
	[34001] = {
		tag_str = "TAG_ENTRY_COLLECT",
		name = "Lost Item Collection",
		safe = true,
		desc = "Lost/dropped item collection points (Shiyi - lost items)",
		addition_tags = { "TAG_DEFAULT_NEAR_AOI" },
	},
	[35001] = {
		tag_str = "TAG_INTERACT",
		name = "Extended Interactive",
		safe = true,
		desc = "Extended interactive object type (with multiplayer support)",
		addition_tags = { "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35002] = {
		tag_str = "TAG_INTERACT_SCENE_STATIC",
		name = "Extended Scene Static",
		safe = false,
		desc = "Extended static scene objects",
		addition_tags = { "TAG_INTERACT", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35003] = {
		tag_str = "TAG_INTERACT",
		name = "Extended Normal Interactive",
		safe = true,
		desc = "Extended standard interactables",
		addition_tags = { "TAG_INTERACT_ITEM_STATIC", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35004] = {
		tag_str = "TAG_INTERACT",
		name = "Extended Touch Interactive",
		safe = true,
		desc = "Extended touch-triggered objects",
		addition_tags = { "TAG_INTERACT_TOUCH", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35005] = {
		tag_str = "TAG_INTERACT_SCENE_STATIC",
		name = "Scene Static Highlight",
		safe = false,
		desc = "Static with wind detection highlight (listening skill visible)",
		addition_tags = { "TAG_INTERACT", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35006] = {
		tag_str = "TAG_INTERACT",
		name = "Scene Static Yellow",
		safe = false,
		desc = "Static with yellow highlight (attack stroke)",
		addition_tags = { "TAG_MODE_INTERACT_ALL", "TAG_ATTACK_STROKE" },
	},
	[35015] = {
		tag_str = "TAG_INTERACT",
		name = "Extended Door",
		safe = false,
		desc = "Extended door type",
		addition_tags = { "TAG_GATE", "TAG_MODE_INTERACT_ALL", "TAG_GENERAL_STROKE" },
	},
	[35024] = {
		tag_str = "TAG_INTERACT",
		name = "Extended Gameplay",
		safe = true,
		desc = "Extended gameplay interactive",
		addition_tags = {
			"TAG_INTERACT_SCENE_STATIC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_GENERAL_STROKE",
			"TAG_STROKE_RANGE_70",
		},
	},
	[35025] = {
		tag_str = "TAG_INTERACT",
		name = "Extended No Outline",
		safe = true,
		desc = "Extended no wind outline (no listening skill highlight)",
		addition_tags = { "TAG_MODE_INTERACT_ALL" },
	},
	[35026] = {
		tag_str = "TAG_INTERACT_SCENE_STATIC",
		name = "Extended Client Static",
		safe = false,
		desc = "Extended client-side static (multiplayer: client-side interactive)",
		addition_tags = { "TAG_INTERACT", "TAG_MODE_INTERACT_ALL", "TAG_CLIENT_INTERACT", "TAG_GENERAL_STROKE" },
	},
	[36001] = {
		tag_str = "TAG_SCENE_EFFECT_ENTITY",
		name = "Effect Entity",
		safe = false,
		desc = "Visual effect entities (supports effects + attachment only)",
		addition_tags = {},
	},
	[37001] = {
		tag_str = "TAG_EAVESDROP_ENTITY",
		name = "Eavesdrop Entity",
		safe = false,
		desc = "Eavesdropping/listening points (Qieting - secret listening)",
		addition_tags = {},
	},
	[38001] = {
		tag_str = "TAG_ANCHOR_MOVE",
		name = "Cloud Step UI",
		safe = false,
		desc = "Grappling hook UI anchor (Lingyun Ta UI)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[41001] = {
		tag_str = "TAG_NPC",
		name = "General NPC",
		safe = false,
		desc = "Standard friendly NPCs (Tongyong NPC)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_GUNDAM_CONSTRUCTION",
		},
	},
	[41002] = {
		tag_str = "TAG_IDLER_NPC",
		name = "Ambient NPC",
		safe = false,
		desc = "Background/atmosphere NPCs (Fenwei NPC / Xianren NPC)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_BASE_BAG",
			"TAG_RAIN_HAT_REPLACE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_TAIJI_TUIDONG",
		},
	},
	[41003] = {
		tag_str = "TAG_PEACEFUL_ANIMAL",
		name = "Peaceful Animal",
		safe = false,
		desc = "Non-hostile animals (Fei Jingong Dongwu)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_ANIMAL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_CHARACTER_TYPE",
		},
	},
	[41004] = {
		tag_str = "TAG_NPC",
		name = "Cat",
		safe = false,
		desc = "Cat NPCs (Miaomiao Mao Mao - petting feature)",
		addition_tags = { "TAG_CAT_NPC", "TAG_PEACEFUL_NPC", "TAG_CHARACTER_TYPE", "TAG_XS_XUANSHANG" },
	},
	[41005] = {
		tag_str = "TAG_NPC",
		name = "Pet Dog",
		safe = false,
		desc = "Pet dog NPCs (Chongwu Gou)",
		addition_tags = { "TAG_PET_DOG_NPC", "TAG_PEACEFUL_NPC", "TAG_CHARACTER_TYPE" },
	},
	[41006] = {
		tag_str = "TAG_COMPANY_NPC",
		name = "Companion NPC",
		safe = false,
		desc = "Story companion NPCs (Peiban NPC)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_IMPORTANT_ENTITY",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
		},
	},
	[41007] = {
		tag_str = "TAG_SIMPLE_NPC",
		name = "Simple Interactive NPC",
		safe = false,
		desc = "Simple NPCs (corpses, etc.) (Jiandan Ke Jiaohu NPC - Shiti)",
		addition_tags = { "TAG_NPC", "TAG_PEACEFUL_NPC", "TAG_STROKE_RANGE_30", "TAG_CHARACTER_TYPE" },
	},
	[41010] = {
		tag_str = "TAG_NPC",
		name = "Cat Petting",
		safe = false,
		desc = "Pettable cat NPCs (Maomi - Mo Mao)",
		addition_tags = {
			"TAG_CAT_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_MODE_MISSION_SYNC",
			"TAG_CHARACTER_TYPE",
			"TAG_XS_XUANSHANG",
		},
	},
	[41011] = {
		tag_str = "TAG_NPC",
		name = "Guide Butterfly",
		safe = false,
		desc = "Guiding butterfly NPCs (Tiandi Wanlai Hudie)",
		addition_tags = {
			"TAG_GUIDER_BUTTERFLY",
			"TAG_PEACEFUL_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_GENERAL_STROKE",
			"TAG_CHARACTER_TYPE",
			"TAG_XS_XUANSHANG",
		},
	},
	[41012] = {
		tag_str = "TAG_NPC",
		name = "Pressure Point Mechanism",
		safe = false,
		desc = "Acupuncture/pressure point objects (Dianxue Jiguan)",
		addition_tags = { "TAG_DIANXUE_ITEM", "TAG_PEACEFUL_NPC", "TAG_MODE_MISSION_SYNC" },
	},
	[41013] = {
		tag_str = "TAG_PEACEFUL_ANIMAL",
		name = "Mahjong Dog",
		safe = false,
		desc = "Mahjong minigame dog (Majiang Chaiquan)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_ANIMAL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_CHARACTER_TYPE",
			"TAG_MODE_OWNER_ONLY",
		},
	},
	[41014] = {
		tag_str = "TAG_NPC",
		name = "Feeding Dog",
		safe = false,
		desc = "Dog NPCs that can be fed (Touwei Gougou)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_QINCHUAN_FEED_DOG",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
		},
	},
	[41015] = {
		tag_str = "TAG_NPC",
		name = "Feeding Dog Daily",
		safe = false,
		desc = "Daily refresh feeding dogs (Touwei Gougou - Ri Shuaxin)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_QINCHUAN_FEED_DOG",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_QINCHUAN_FEED_DOG_DAILY",
		},
	},
	[41016] = {
		tag_str = "TAG_NPC",
		name = "Jade Cicada",
		safe = false,
		desc = "Jade cicada collectible NPCs (Yuming Chan)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GP_YMC_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_GUNDAM_CONSTRUCTION",
		},
	},
	[41099] = {
		tag_str = "TAG_NPC",
		name = "Temp NPC",
		safe = false,
		desc = "Temporary NPC (to be removed in future version)",
		addition_tags = { "TAG_MONSTER", "TAG_BOSS_MONSTER", "TAG_GENERAL_STROKE", "TAG_MODE_MISSION_SYNC" },
	},
	[41102] = {
		tag_str = "TAG_IDLER_NPC",
		name = "Permanent Ambient NPC",
		safe = false,
		desc = "Non-reducible ambient NPCs (Bu Ke Xuejian de Fenwei NPC)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_BASE_BAG",
			"TAG_RAIN_HAT_REPLACE",
			"TAG_MODE_INTERACT_ALL",
			"TAG_COOP_AI_RETAIN",
			"TAG_CHARACTER_TYPE",
			"TAG_STROKE_RANGE_30",
		},
	},
	[41103] = {
		tag_str = "TAG_SIMPLE_HEX_MODEL_ENTITY",
		name = "Performance NPC",
		safe = false,
		desc = "Pure performance/cutscene NPCs (Chun Biaoyan NPC)",
		addition_tags = {},
	},
	[43001] = {
		tag_str = "TAG_CUSTOM_SHOP",
		name = "Merchant/Shop",
		safe = false,
		desc = "Merchant NPCs and shops (Shangren / Shangdian)",
		addition_tags = {
			"TAG_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_MODE_INTERACT_ALL",
			"TAG_RAIN_HAT_REPLACE",
			"TAG_CHARACTER_TYPE",
		},
	},
	[43002] = {
		tag_str = "TAG_RIDE",
		name = "Mount",
		safe = false,
		desc = "Rideable mounts (Zuoqi)",
		addition_tags = { "TAG_NPC", "TAG_PEACEFUL_NPC", "TAG_CHARACTER_TYPE" },
	},
	[43003] = {
		tag_str = "TAG_CARRIAGE",
		name = "Carriage",
		safe = false,
		desc = "Horse carriage vehicles (Mache)",
		addition_tags = { "TAG_CHARACTER_TYPE" },
	},
	[43004] = {
		tag_str = "TAG_CARRIAGE",
		name = "Prison Cart",
		safe = false,
		desc = "Prisoner transport cart (Qiuche)",
		addition_tags = { "TAG_CHARACTER_TYPE" },
	},
	[50001] = {
		tag_str = "TAG_AIR_WALL",
		name = "Invisible Wall",
		safe = false,
		desc = "Invisible boundary walls (Kongqi Qiang)",
		addition_tags = {},
	},
	[50002] = {
		tag_str = "TAG_TRAP",
		name = "Trap",
		safe = false,
		desc = "Environmental traps (Xianjing)",
		addition_tags = {},
	},
	[50003] = {
		tag_str = "TAG_MAGIC_FILED",
		name = "Magic Field",
		safe = false,
		desc = "Magical effect areas (Fashu Chang)",
		addition_tags = {},
	},
	[50004] = {
		tag_str = "TAG_RADIATION",
		name = "Radiation Source",
		safe = false,
		desc = "Damaging radiation zones (Fushe Yuan)",
		addition_tags = {},
	},
	[50005] = {
		tag_str = "TAG_NEED_MATCH",
		name = "Exchange Match",
		safe = false,
		desc = "Item exchange matching (Jiaohuan Xuqiu Pipei)",
		addition_tags = {},
	},
	[60001] = {
		tag_str = "TAG_WEAPON",
		name = "Weapon",
		safe = false,
		desc = "Weapon entities (Wuqi)",
		addition_tags = {},
	},
	[60002] = {
		tag_str = "TAG_ACCESSORY",
		name = "Accessory",
		safe = false,
		desc = "Decoration/accessory items (Zhuangshiwu / Guashi)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90001] = {
		tag_str = "TAG_PLANT_CHUNK",
		name = "Plant Chunk",
		safe = false,
		desc = "Vegetation + gameplay sync entity (Zhibei + Wanfa Shuju Tongbu)",
		addition_tags = {},
	},
	[90002] = {
		tag_str = "TAG_LOCAL_LIGHT",
		name = "Local Light",
		safe = false,
		desc = "Light source entity (Guangyuan - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90003] = {
		tag_str = "TAG_POINT",
		name = "Point",
		safe = false,
		desc = "Point marker entity (Dian - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90005] = {
		tag_str = "TAG_INDUSTRY_ENTITY",
		name = "Industry Entity",
		safe = false,
		desc = "Industrial/crafting entity (Chanye - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90006] = {
		tag_str = "TAG_INDUSTRY_AREA",
		name = "Industry Area",
		safe = false,
		desc = "Industrial area marker (Chanye - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90007] = {
		tag_str = "TAG_ICE_FIELD",
		name = "Ice Field",
		safe = false,
		desc = "Skill-created ice field (IceField - Jineng Chuangsheng - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90008] = {
		tag_str = "TAG_DOVE_ENTITY",
		name = "Dove Entity",
		safe = false,
		desc = "Dove/bird entity (DoveEntity - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90009] = {
		tag_str = "TAG_EFFECT_ENTITY",
		name = "Effect Entity",
		safe = false,
		desc = "Visual effect entity (EffectEntity - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90010] = {
		tag_str = "TAG_AUX_SHAPE",
		name = "Aux Shape",
		safe = false,
		desc = "Auxiliary shape entity (AuxShape - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90011] = {
		tag_str = "TAG_AUX_AREA_CUBE",
		name = "Aux Area Cube",
		safe = false,
		desc = "Auxiliary area cube (AuxAreaCube - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90012] = {
		tag_str = "TAG_AUX_AREA_SINGLE_CUBE",
		name = "Aux Area Single Cube",
		safe = false,
		desc = "Single auxiliary cube (AuxAreaSingleCube - local entity)",
		addition_tags = { "TAG_LOCAL_ENTITY" },
	},
	[90013] = {
		tag_str = "TAG_BUILDING",
		name = "Simple Building",
		safe = false,
		desc = "Simple building structure (Jiandan Jianzhu)",
		addition_tags = { "TAG_SIMPLE_BUILDING" },
	},
	[90014] = {
		tag_str = "TAG_BUILDING",
		name = "Normal Building",
		safe = false,
		desc = "Standard building structure (Putong Jianzhu Building - local entity)",
		addition_tags = { "TAG_NORMAL_BUILDING" },
	},
	[90015] = {
		tag_str = "TAG_BUILDING",
		name = "Group Building",
		safe = false,
		desc = "Combined building complex (Zuhe Jianzhu RoomBuildings - local entity)",
		addition_tags = { "TAG_GROUP_BUILDING" },
	},
	[90016] = {
		tag_str = "TAG_BUILDING",
		name = "Building Blueprint",
		safe = false,
		desc = "Building blueprint entity (Lantu Zhengti)",
		addition_tags = { "TAG_BUILDING_BLUEPRINT" },
	},
	[90017] = {
		tag_str = "TAG_GRID_BUILDING",
		name = "Grid Building",
		safe = false,
		desc = "Grid building manager (GridBuilding - Guanliqi - pure client)",
		addition_tags = {},
	},
	[90018] = {
		tag_str = "TAG_STATIC_ENTITY",
		name = "Static Entity",
		safe = false,
		desc = "Scene static object (Changjing Jingtai Wuti - static_entity)",
		addition_tags = {},
	},
	[90019] = {
		tag_str = "TAG_MAIN_PLAYER",
		name = "Main Player",
		safe = false,
		desc = "Player character (Zhujue)",
		addition_tags = {},
	},
	[90020] = {
		tag_str = "TAG_OTHER_PLAYER",
		name = "Other Player",
		safe = false,
		desc = "Other player characters (Qita Wanjia)",
		addition_tags = {},
	},
	[90021] = {
		tag_str = "TAG_AI_AVATAR",
		name = "AI Avatar",
		safe = false,
		desc = "AI-controlled avatars (AIAvatar)",
		addition_tags = {},
	},
	[90022] = {
		tag_str = "TAG_ROBOT_PLAYER",
		name = "Robot Player",
		safe = false,
		desc = "Bot/robot players (RobotPlayer)",
		addition_tags = {},
	},
	[90023] = {
		tag_str = "TAG_SPACE_DATA",
		name = "Space Data",
		safe = false,
		desc = "Space/zone data entity (Space Data)",
		addition_tags = {},
	},
	[90024] = {
		tag_str = "TAG_COMMON_PLAY",
		name = "Common Play",
		safe = false,
		desc = "Common gameplay entity (Common Play)",
		addition_tags = {},
	},
	[90025] = {
		tag_str = "TAG_DESTRUCT",
		name = "Destructible Temp",
		safe = false,
		desc = "Temporary destructible state (Ke Pohuaiwu - Posui Shi de Linshi Leixing)",
		addition_tags = {},
	},
	[500001] = {
		tag_str = "FILTER_ALL_COLLECT",
		name = "All Collectibles Filter",
		safe = true,
		desc = "Filter for all collectible types",
		addition_tags = { "TAG_COLLECT_TREE", "TAG_COLLECT_GRASS", "TAG_COLLECT_MINE", "TAG_COLLECT_FISH" },
	},
	[500002] = {
		tag_str = "FILTER_ALL_NPC",
		name = "All NPCs Filter",
		safe = false,
		desc = "Filter for all NPC types",
		addition_tags = { "TAG_NPC", "TAG_SIMPLE_NPC", "TAG_CAT_NPC", "TAG_PET_DOG_NPC" },
	},
	[500003] = {
		tag_str = "FILTER_ALL_ANIMAL",
		name = "All Animals Filter",
		safe = false,
		desc = "Filter for all animal types",
		addition_tags = { "TAG_COMBATIVE_ANIMAL", "TAG_PEACEFUL_ANIMAL" },
	},
	[500012] = {
		tag_str = "TAG_MONSTER",
		name = "Wind Listen Filter",
		safe = false,
		desc = "Listening skill positive filter - monsters + ambient NPCs + interactables + collectibles",
		addition_tags = { "TAG_NPC", "TAG_INTERACT", "TAG_BASE_COLLECT" },
	},
	[600001] = {
		tag_str = "TAG_OTHER_PLAYER",
		name = "Other Players",
		safe = false,
		desc = "Other player filter",
		addition_tags = { "TAG_AI_AVATAR" },
	},
	[600002] = {
		tag_str = "TAG_SMALL_MONSTER",
		name = "Small Monster",
		safe = false,
		desc = "Small monster filter",
		addition_tags = {},
	},
	[600003] = {
		tag_str = "TAG_ELITE_MONSTER",
		name = "All Except Small",
		safe = false,
		desc = "All monsters except small monsters",
		addition_tags = { "TAG_BOSS_MONSTER", "TAG_SMALL_BOSS" },
	},
	[600004] = {
		tag_str = "TAG_PEACEFUL_NPC",
		name = "Non-Monster NPC",
		safe = false,
		desc = "Non-monster NPCs",
		addition_tags = {},
	},
	[600005] = {
		tag_str = "TAG_OTHER_PLAYER",
		name = "All Damageable Except Main",
		safe = false,
		desc = "All damageable targets except main player",
		addition_tags = { "TAG_AI_AVATAR", "TAG_MONSTER", "TAG_PEACEFUL_NPC" },
	},
	[600011] = {
		tag_str = "TAG_MONSTER",
		name = "All Damageable Except Players",
		safe = false,
		desc = "All damageable targets except all players",
		addition_tags = { "TAG_PEACEFUL_NPC" },
	},
	[600018] = {
		tag_str = "TAG_MAIN_PLAYER",
		name = "All Damageable",
		safe = false,
		desc = "All damageable objects",
		addition_tags = { "TAG_OTHER_PLAYER", "TAG_AI_AVATAR", "TAG_MONSTER", "TAG_PEACEFUL_NPC" },
	},
	[800010] = {
		tag_str = "TAG_NPC",
		name = "Martial Healing NPC",
		safe = false,
		desc = "Martial arts healing NPCs (Yi Wu Yuxin NPC)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_MONSTER",
			"TAG_SMALL_MONSTER",
		},
	},
	[800011] = {
		tag_str = "TAG_ROLLER_COASTER",
		name = "Cloud Chariot",
		safe = false,
		desc = "Roller coaster ride (Yuncha Feiche)",
		addition_tags = {},
	},
	[800012] = {
		tag_str = "TAG_GUNDAM_COMPONENT",
		name = "Ultimate Hand Component",
		safe = false,
		desc = "Building/crafting component (Jiuji Shou Zujian)",
		addition_tags = {},
	},
	[800013] = {
		tag_str = "TAG_NPC",
		name = "Training Partner",
		safe = false,
		desc = "Training ground teammate (Xunlianchang Duiyou)",
		addition_tags = { "TAG_MONSTER", "TAG_NPC_ZHUZHAN" },
	},
	[800014] = {
		tag_str = "TAG_NPC",
		name = "Pot Throwing NPC",
		safe = false,
		desc = "Pot throwing game NPC (owner only) (Touhu NPC - Jin Zhuren Jiaohu)",
		addition_tags = {
			"TAG_GENERAL_NPC",
			"TAG_PEACEFUL_NPC",
			"TAG_GENERAL_STROKE",
			"TAG_EXTREM_WEATHER_REPLACE",
			"TAG_MODE_OWNER_ONLY",
			"TAG_COOP_AI_RETAIN",
			"TAG_STROKE_RANGE_30",
			"TAG_CHARACTER_TYPE",
			"TAG_GUNDAM_CONSTRUCTION",
		},
	},
	[800015] = {
		tag_str = "TAG_ELITE_MONSTER",
		name = "All Monsters",
		safe = false,
		desc = "Filter for all monster types (Suoyou Guai)",
		addition_tags = { "TAG_BOSS_MONSTER", "TAG_SMALL_BOSS", "TAG_SMALL_MONSTER" },
	},
}

-- Quick lookup: which base_tag IDs are safe to auto-loot
LOOT_DATA.LOOTABLE_BASE_TAGS = {
	[31001] = true, -- Interactive Object
	[31003] = true, -- Normal Interactive
	[31004] = true, -- Touch Interactive
	[31006] = true, -- Treasure Chest
	[31016] = true, -- Suspicious Object
	[31024] = true, -- Gameplay Interactive
	[31025] = true, -- Interactive No Outline
	[31027] = true, -- Interactive General Alt
	[32000] = true, -- Collectible Base
	[32001] = true, -- Collectible Tree
	[32002] = true, -- Collectible Grass
	[32003] = true, -- Collectible Fruit
	[32004] = true, -- Collectible Ore
	[32007] = true, -- Small Movable Collectible
	[32008] = true, -- Collectible Fish
	[32019] = true, -- Small Static Collectible
	[34001] = true, -- Lost Item Collection
	[35001] = true, -- Extended Interactive
	[35003] = true, -- Extended Normal Interactive
	[35004] = true, -- Extended Touch Interactive
	[35024] = true, -- Extended Gameplay
	[35025] = true, -- Extended No Outline
	[500001] = true, -- All Collectibles Filter
}

-- Quick lookup: which base_tag IDs to skip
LOOT_DATA.SKIP_BASE_TAGS = {
	[20001] = true, -- Normal Monster
	[20002] = true, -- Elite Monster
	[20003] = true, -- Boss
	[20004] = true, -- Combat Animal
	[20005] = true, -- Robot Monster
	[20006] = true, -- Mini Boss
	[20007] = true, -- Combat Animal Normal
	[20008] = true, -- Combat Animal Elite
	[20009] = true, -- Combat Animal Boss
	[20010] = true, -- Combat Animal Leader
	[20011] = true, -- New Robot
	[20012] = true, -- Spike Plate No Listen
	[20013] = true, -- Multiplayer Boss
	[30001] = true, -- Destructible
	[31002] = true, -- Scene Static Object
	[31005] = true, -- Carryable Object
	[31007] = true, -- Forge Station
	[31008] = true, -- Scene Mechanism
	[31009] = true, -- Vehicle Platform
	[31010] = true, -- Elevator
	[31011] = true, -- Ladder
	[31012] = true, -- Boundary Marker
	[31013] = true, -- Outpost Interactive
	[31014] = true, -- Bomb
	[31015] = true, -- Door
	[31017] = true, -- Campfire
	[31018] = true, -- Dynamite Barrel
	[31019] = true, -- Turret
	[31020] = true, -- Rotating Platform
	[31021] = true, -- Telekinesis Cable
	[31022] = true, -- Telekinesis Box
	[31023] = true, -- Signpost
	[31026] = true, -- Client Interactive Static
	[31028] = true, -- AI Created Model
	[31029] = true, -- Local Entity
	[33001] = true, -- Scene Decoration
	[33002] = true, -- Empty Entity
	[33003] = true, -- Scene Hex Model
	[35002] = true, -- Extended Scene Static
	[35005] = true, -- Scene Static Highlight
	[35006] = true, -- Scene Static Yellow
	[35015] = true, -- Extended Door
	[35026] = true, -- Extended Client Static
	[36001] = true, -- Effect Entity
	[37001] = true, -- Eavesdrop Entity
	[38001] = true, -- Cloud Step UI
	[41001] = true, -- General NPC
	[41002] = true, -- Ambient NPC
	[41003] = true, -- Peaceful Animal
	[41004] = true, -- Cat
	[41005] = true, -- Pet Dog
	[41006] = true, -- Companion NPC
	[41007] = true, -- Simple Interactive NPC
	[41010] = true, -- Cat Petting
	[41011] = true, -- Guide Butterfly
	[41012] = true, -- Pressure Point Mechanism
	[41013] = true, -- Mahjong Dog
	[41014] = true, -- Feeding Dog
	[41015] = true, -- Feeding Dog Daily
	[41016] = true, -- Jade Cicada
	[41099] = true, -- Temp NPC
	[41102] = true, -- Permanent Ambient NPC
	[41103] = true, -- Performance NPC
	[43001] = true, -- Merchant/Shop
	[43002] = true, -- Mount
	[43003] = true, -- Carriage
	[43004] = true, -- Prison Cart
	[50001] = true, -- Invisible Wall
	[50002] = true, -- Trap
	[50003] = true, -- Magic Field
	[50004] = true, -- Radiation Source
	[50005] = true, -- Exchange Match
	[60001] = true, -- Weapon
	[60002] = true, -- Accessory
	[90001] = true, -- Plant Chunk
	[90002] = true, -- Local Light
	[90003] = true, -- Point
	[90005] = true, -- Industry Entity
	[90006] = true, -- Industry Area
	[90007] = true, -- Ice Field
	[90008] = true, -- Dove Entity
	[90009] = true, -- Effect Entity
	[90010] = true, -- Aux Shape
	[90011] = true, -- Aux Area Cube
	[90012] = true, -- Aux Area Single Cube
	[90013] = true, -- Simple Building
	[90014] = true, -- Normal Building
	[90015] = true, -- Group Building
	[90016] = true, -- Building Blueprint
	[90017] = true, -- Grid Building
	[90018] = true, -- Static Entity
	[90019] = true, -- Main Player
	[90020] = true, -- Other Player
	[90021] = true, -- AI Avatar
	[90022] = true, -- Robot Player
	[90023] = true, -- Space Data
	[90024] = true, -- Common Play
	[90025] = true, -- Destructible Temp
	[500002] = true, -- All NPCs Filter
	[500003] = true, -- All Animals Filter
	[500012] = true, -- Wind Listen Filter
	[600001] = true, -- Other Players
	[600002] = true, -- Small Monster
	[600003] = true, -- All Except Small
	[600004] = true, -- Non-Monster NPC
	[600005] = true, -- All Damageable Except Main
	[600011] = true, -- All Damageable Except Players
	[600018] = true, -- All Damageable
	[800010] = true, -- Martial Healing NPC
	[800011] = true, -- Cloud Chariot
	[800012] = true, -- Ultimate Hand Component
	[800013] = true, -- Training Partner
	[800014] = true, -- Pot Throwing NPC
	[800015] = true, -- All Monsters
}

-- Critical skip list: NEVER interact with these base_tags
LOOT_DATA.ALWAYS_SKIP_BASE_TAGS = {
	[31023] = true, -- Signpost (TAG_SIGN)
}

-- ============================================================
-- ENTITY TYPE DEFINITIONS
-- ============================================================
-- entity_type is a numeric classification found in sys_d
-- ============================================================
LOOT_DATA.ENTITY_TYPE_DEFS = {
	[0] = { name = "npc", desc = "NPC/Character entities", lootable = false },
	[1] = { name = "player", desc = "Player-related entities", lootable = false },
	[3] = { name = "interactive", desc = "Interactive objects (chests, collectibles)", lootable = true },
}

-- Quick lookup: which entity_type values indicate lootable entities
LOOT_DATA.LOOTABLE_ENTITY_TYPES = {
	[3] = true, -- interactive
}

-- ============================================================
-- WANFA TYPES (Gameplay Categories)
-- ============================================================
-- wanfa = 'way to play' or 'gameplay mode'
-- Used to categorize different types of interactive content
-- ============================================================
LOOT_DATA.WANFA_TYPES = {
	[1] = { name = "herbs", lootable = true, desc = "Herbal collectibles (plants, flowers)" },
	[2] = { name = "minerals", lootable = true, desc = "Mining nodes (ores, gems)" },
	[3] = { name = "mechanism", lootable = false, desc = "Mechanisms, puzzles" },
	[4] = { name = "special", lootable = true, desc = "Special collectibles" },
	[5] = { name = "quest_item", lootable = false, desc = "Quest-related items (ins_entity)" },
	[6] = { name = "minigame", lootable = false, desc = "Minigame interactions" },
	[7] = { name = "fishing", lootable = true, desc = "Fishing spots" },
	[8] = { name = "cooking", lootable = false, desc = "Cooking stations" },
	[9] = { name = "treasure", lootable = true, desc = "Treasure boxes/chests" },
	[10] = { name = "viewpoint", lootable = false, desc = "Scenic viewpoints (map mini-game)" },
	[11] = { name = "lost_item", lootable = true, desc = "Lost items to collect (Shiyi)" },
	[12] = { name = "hidden", lootable = true, desc = "Hidden collectibles" },
	[13] = { name = "challenge", lootable = false, desc = "Challenge points" },
	[15] = { name = "region_special", lootable = true, desc = "Region-specific special items" },
	[19] = { name = "region_misc", lootable = true, desc = "Miscellaneous region items" },
	[20] = { name = "region_collect", lootable = true, desc = "Region collection items" },
	[21] = { name = "region_explore", lootable = true, desc = "Exploration collectibles" },
	[30] = { name = "explore_a", lootable = true, desc = "Exploration category A" },
	[31] = { name = "explore_b", lootable = true, desc = "Exploration category B" },
	[32] = { name = "explore_c", lootable = true, desc = "Exploration category C" },
	[33] = { name = "explore_d", lootable = true, desc = "Exploration category D" },
	[34] = { name = "explore_e", lootable = true, desc = "Exploration category E" },
	[35] = { name = "explore_f", lootable = true, desc = "Exploration category F" },
	[40] = { name = "region_treasure_a", lootable = true, desc = "Region treasure category A" },
	[41] = { name = "region_treasure_b", lootable = true, desc = "Region treasure category B" },
	[45] = {
		name = "region_treasure_chest",
		lootable = true,
		desc = "Region treasure collection (e.g., damaged carriage treasure)",
	},
	[46] = { name = "region_treasure_d", lootable = true, desc = "Region treasure category D" },
	[47] = { name = "region_treasure_e", lootable = true, desc = "Region treasure category E" },
	[49] = { name = "task_group", lootable = false, desc = "Task group category" },
}

-- Quick lookup: which wanfa types are safe to auto-loot
LOOT_DATA.LOOTABLE_WANFA = {
	[1] = true, -- herbs
	[2] = true, -- minerals
	[4] = true, -- special
	[7] = true, -- fishing
	[9] = true, -- treasure
	[11] = true, -- lost_item
	[12] = true, -- hidden
	[15] = true, -- region_special
	[19] = true, -- region_misc
	[20] = true, -- region_collect
	[21] = true, -- region_explore
	[30] = true, -- explore_a
	[31] = true, -- explore_b
	[32] = true, -- explore_c
	[33] = true, -- explore_d
	[34] = true, -- explore_e
	[35] = true, -- explore_f
	[40] = true, -- region_treasure_a
	[41] = true, -- region_treasure_b
	[45] = true, -- region_treasure_chest
	[46] = true, -- region_treasure_d
	[47] = true, -- region_treasure_e
}

-- Quick lookup: which wanfa types to skip
LOOT_DATA.SKIP_WANFA = {
	[3] = true, -- mechanism
	[5] = true, -- quest_item
	[6] = true, -- minigame
	[8] = true, -- cooking
	[10] = true, -- viewpoint
	[13] = true, -- challenge
	[49] = true, -- task_group
}

-- ============================================================
-- TAG STRING CATEGORIES
-- ============================================================
-- base_tag_str values from entity_tags.json
-- ============================================================
LOOT_DATA.SAFE_TAGS = {
	["TAG_BASE_COLLECT"] = true, -- Base collectible type
	["TAG_COLLECT_FISH"] = true, -- Fishing spots
	["TAG_COLLECT_GRASS"] = true, -- Grass/herb collectibles
	["TAG_COLLECT_MINE"] = true, -- Mining nodes
	["TAG_COLLECT_STROKE"] = true, -- Collectible outline stroke (listening skill highlight)
	["TAG_COLLECT_TREE"] = true, -- Tree collectibles (wood)
	["TAG_ENTRY_COLLECT"] = true, -- Collection entry points (lost items)
	["TAG_GENERAL_STROKE"] = true, -- General outline stroke
	["TAG_INTERACT"] = true, -- Generic interact objects
	["TAG_INTERACT_ITEM_STATIC"] = true, -- Static item interactables
	["TAG_INTERACT_TOUCH"] = true, -- Touch-triggered interactables
	["TAG_MODE_INTERACT_ALL"] = true, -- All players can interact (multiplayer)
	["TAG_RARE_COLLECT"] = true, -- Rare collectibles
	["TAG_SIMPLE_MOVABLE_INTERACT"] = true, -- Simple movable interacts
	["TAG_TREASURE_BOX"] = true, -- Treasure chests
}

LOOT_DATA.SKIP_TAGS = {
	["TAG_ACCESSORY"] = true, -- Accessories
	["TAG_AIR_WALL"] = true, -- Invisible walls
	["TAG_AI_AVATAR"] = true, -- AI avatars
	["TAG_ANIMAL_NPC"] = true, -- Animal NPCs
	["TAG_ATTACK_STROKE"] = true, -- Attack target stroke (yellow outline)
	["TAG_BOSS_MONSTER"] = true, -- Boss monsters
	["TAG_BUILDING"] = true, -- Building structures
	["TAG_CARRIAGE"] = true, -- Carriages
	["TAG_CAT_NPC"] = true, -- Cat NPCs
	["TAG_CHARACTER_TYPE"] = true, -- Character type entities
	["TAG_CLIENT_INTERACT"] = true, -- Client-side interaction only
	["TAG_COMBATIVE_ANIMAL"] = true, -- Combat animals
	["TAG_COMPANY_NPC"] = true, -- Companion NPCs
	["TAG_COOP_AI_RETAIN"] = true, -- Co-op AI retention
	["TAG_CUSTOM_SHOP"] = true, -- Shop/merchant NPCs
	["TAG_DATA_NPC"] = true, -- Data-only entity
	["TAG_DEFAULT_NEAR_AOI"] = true, -- Default near AOI (small entities)
	["TAG_DESTRUCT"] = true, -- Destructible objects
	["TAG_DYNAMITE"] = true, -- Dynamite barrels
	["TAG_ELEVATOR"] = true, -- Elevators
	["TAG_ELITE_MONSTER"] = true, -- Elite monsters
	["TAG_EXTREM_WEATHER_REPLACE"] = true, -- Extreme weather replacement
	["TAG_FORGE"] = true, -- Crafting forges
	["TAG_GATE"] = true, -- Doors/gates
	["TAG_GENERAL_NPC"] = true, -- General NPCs
	["TAG_IDLER_NPC"] = true, -- Idle/ambient NPCs
	["TAG_IMPORTANT_ENTITY"] = true, -- Important entity (higher creation priority)
	["TAG_INTERACT_SCENE_STATIC"] = true, -- Static scene objects
	["TAG_JIEBEI"] = true, -- Boundary markers
	["TAG_JUDIAN"] = true, -- Outpost/stronghold
	["TAG_LADDER"] = true, -- Ladders
	["TAG_LOCAL_ENTITY"] = true, -- Local entities
	["TAG_MAIN_PLAYER"] = true, -- Main player
	["TAG_MODE_MISSION_SYNC"] = true, -- Mission sync mode
	["TAG_MODE_OWNER_ONLY"] = true, -- Owner only interaction
	["TAG_MONSTER"] = true, -- Monsters/enemies
	["TAG_MULTI_BOSS"] = true, -- Multiplayer boss monsters
	["TAG_NO_STROKE"] = true, -- No outline/stroke (signposts, hidden from listening skill)
	["TAG_NPC"] = true, -- NPCs (characters)
	["TAG_OTHER_PLAYER"] = true, -- Other players
	["TAG_PEACEFUL_ANIMAL"] = true, -- Peaceful animals
	["TAG_PEACEFUL_NPC"] = true, -- Peaceful NPCs
	["TAG_PET_DOG_NPC"] = true, -- Pet dog NPCs
	["TAG_RIDE"] = true, -- Mounts
	["TAG_ROBOT_PLAYER"] = true, -- Robot players
	["TAG_ROTATE_MOVE_PLATFORM"] = true, -- Rotating platforms
	["TAG_SCENE_EFFECT_ENTITY"] = true, -- Scene effect entity
	["TAG_SCENE_ENTITY"] = true, -- Scene decoration
	["TAG_SCENE_HEX_MODEL_ENTITY"] = true, -- Scene hex model
	["TAG_SCENE_MECHANISM"] = true, -- Scene mechanisms/puzzles
	["TAG_SIGN"] = true, -- Signs/signposts - ALWAYS SKIP
	["TAG_SIMPLE_NPC"] = true, -- Simple NPCs
	["TAG_SMALL_BOSS"] = true, -- Mini boss monsters
	["TAG_SMALL_MONSTER"] = true, -- Small monsters
	["TAG_STATIC_ENTITY"] = true, -- Static entities
	["TAG_STATIONARY"] = true, -- Stationary objects
	["TAG_TELEKINESIS_CABLE"] = true, -- Telekinesis cable mechanism
	["TAG_TELEKINESIS_TRANSBOX"] = true, -- Telekinesis transport box
	["TAG_TRAP"] = true, -- Traps
	["TAG_TURRET"] = true, -- Turrets/cannons
	["TAG_VEHICLE"] = true, -- Vehicles
	["TAG_WEAPON"] = true, -- Weapons
	["TAG_XS_XUANSHANG"] = true, -- Bounty/commission related
	["TAG_ZHADAN"] = true, -- Bombs
}

-- ============================================================
-- INTERACT CONFIG RANGES
-- ============================================================
-- interact_config values define interaction types
-- ============================================================
LOOT_DATA.INTERACT_CONFIG_RANGES = {
	{ low = 100000, high = 199999, type = "basic", desc = "Basic interactions (inspect, signposts)" },
	{ low = 200000, high = 299999, type = "npc", desc = "NPC interactions (dialog, trade)" },
	{ low = 300000, high = 399999, type = "mechanism", desc = "Mechanism interactions (puzzles)" },
	{ low = 400000, high = 499999, type = "loot", desc = "Loot interactions (chests, collectibles)" },
	{ low = 500000, high = 599999, type = "special", desc = "Special interactions (quests)" },
}

-- ============================================================
-- NPC_NO RANGES (Entity Config ID Patterns)
-- ============================================================
-- Despite the name, npc_no applies to ALL spawnable entities
-- including chests, gathering nodes, and interactive objects
-- ============================================================
LOOT_DATA.NPC_NO_RANGES = {
	{ low = 1900000, high = 1999999, type = "signpost", safe = false, desc = "Signposts and markers" },
	{ low = 2000000, high = 2999999, type = "npc", safe = false, desc = "NPCs and monsters" },
	{ low = 3000000, high = 3999999, type = "animal", safe = false, desc = "Animals" },
	{ low = 4000000, high = 4099999, type = "static", safe = "maybe", desc = "Static entities" },
	{ low = 4100000, high = 4199999, type = "interact", safe = "maybe", desc = "Interactive objects" },
	{ low = 4400000, high = 4499999, type = "collectible", safe = true, desc = "Gathering nodes" },
	{ low = 4500000, high = 4599999, type = "treasure", safe = true, desc = "Treasure boxes, chests" },
	{ low = 6300000, high = 6399999, type = "treasure_alt", safe = true, desc = "Alternative treasure chests" },
}

-- ============================================================
-- LOOTABLE NPC_NO SET (Known Lootable Entity Configs)
-- ============================================================
-- Total: 2542 unique entity configurations
-- ============================================================
LOOT_DATA.LOOTABLE_NPC_NOS = {
	[10005] = true, -- 天涯客篝火-隐月山
	[91001] = true, -- 模板表
	[93212] = true, -- 模板表
	[96001] = true, -- 模板表
	[96002] = true, -- 模板表
	[96003] = true, -- 模板表
	[96007] = true, -- 徐佳琦
	[96009] = true, -- 模板表
	[96012] = true, -- 模板表
	[96014] = true, -- 储一民
	[96018] = true, -- 模板表
	[96020] = true, -- 模板表
	[96021] = true, -- 徐佳琦
	[96024] = true, -- 模板表
	[96026] = true, -- 模板表
	[96031] = true, -- 模板表
	[98588] = true, -- 模板表
	[98590] = true, -- 模板表
	[98592] = true, -- 模板表
	[98593] = true, -- 模板表
	[98599] = true, -- 模板表
	[98605] = true, -- 模板表
	[98606] = true, -- 模板表
	[98608] = true, -- 模板表
	[98610] = true, -- 张益豪
	[98611] = true, -- 模板表
	[98629] = true, -- 模板表
	[98630] = true, -- 模板表
	[98638] = true, -- 程伟建
	[98639] = true, -- 程伟建
	[98640] = true, -- 总表
	[98645] = true, -- 模板表
	[98650] = true, -- 模板表
	[98651] = true, -- 模板表
	[98653] = true, -- 模板表
	[98654] = true, -- 模板表
	[98663] = true, -- 总表
	[98679] = true, -- 总表
	[98682] = true, -- 模板表
	[98684] = true, -- 总表
	[98686] = true, -- 模板表
	[98689] = true, -- 程伟建
	[98690] = true, -- 总表
	[98691] = true, -- 总表
	[98692] = true, -- 模板表
	[99155] = true, -- 程伟建
	[300223] = true, -- 石九亮
	[300233] = true, -- 石九亮
	[300234] = true, -- 石九亮
	[300235] = true, -- 石九亮
	[300236] = true, -- 石九亮
	[300237] = true, -- 石九亮
	[300238] = true, -- 石九亮
	[300239] = true, -- 石九亮
	[300280] = true, -- 石九亮
	[700039] = true, -- 梦傀-原地站立-剧情
	[700044] = true, -- 胖梦傀-趴在地上
	[800103] = true, -- 陈嘉铮
	[900977] = true, -- 陈舟畔
	[1200468] = true, -- 胡健力
	[1200472] = true, -- 胡健力
	[1200473] = true, -- 胡健力
	[1200474] = true, -- 胡健力
	[1200475] = true, -- 胡健力
	[1200480] = true, -- 区域灶台-神仙渡
	[1200481] = true, -- 胡健力
	[1200517] = true, -- 胡健力
	[1200534] = true,
	[1200565] = true, -- 八卦盘
	[1200567] = true, -- 胡健力
	[1200570] = true, -- 通用操控台-大厅
	[1200571] = true, -- 通用操控台-房间2
	[1200578] = true, -- 地面浑仪替代
	[1200586] = true, -- 胡健力
	[1200593] = true, -- 共工台上部
	[1200595] = true, -- 共工台上部-梯子6-底座2米短
	[1200596] = true, -- 胡健力
	[1200600] = true, -- 胡健力
	[1200602] = true, -- 胡健力
	[1200606] = true, -- 小吊机测试
	[1200608] = true, -- 任宽
	[1200609] = true, -- 小吊机底盘-仓库
	[1200610] = true, -- 水闸散件-左
	[1200611] = true, -- 水闸散件-闸门
	[1200612] = true, -- 水闸散件-右
	[1200614] = true, -- 胡健力
	[1200615] = true, -- 胡健力
	[1200616] = true, -- 胡健力
	[1200617] = true, -- 胡健力
	[1200618] = true, -- 胡健力
	[1200623] = true, -- 共工台上部-梯子3-室外中，关键帧
	[1200625] = true, -- 共工台上部-梯子3-1楼固定
	[1200626] = true, -- 共工台上部-梯子5-内部短
	[1200627] = true, -- 胡健力
	[1200628] = true, -- 胡健力
	[1200635] = true,
	[1200642] = true,
	[1200647] = true, -- 胡健力
	[1200659] = true, -- 大厅浑仪
	[1200661] = true, -- 胡健力
	[1200662] = true, -- 胡健力
	[1200663] = true, -- 胡健力
	[1200664] = true, -- 胡健力
	[1200665] = true, -- 胡健力
	[1200666] = true, -- 胡健力
	[1200667] = true, -- 胡健力
	[1200668] = true, -- 胡健力
	[1200669] = true, -- 胡健力
	[1200670] = true, -- 胡健力
	[1200671] = true, -- 胡健力
	[1200672] = true, -- 胡健力
	[1200673] = true, -- 胡健力
	[1200674] = true, -- 胡健力
	[1200675] = true, -- 胡健力
	[1200676] = true, -- 胡健力
	[1200677] = true, -- 胡健力
	[1200678] = true, -- 胡健力
	[1200679] = true, -- 胡健力
	[1200680] = true, -- 胡健力
	[1200681] = true, -- 胡健力
	[1200682] = true, -- 胡健力
	[1200683] = true, -- 胡健力
	[1200684] = true, -- 胡健力
	[1200685] = true, -- 胡健力
	[1200686] = true, -- 胡健力
	[1200687] = true, -- 胡健力
	[1200688] = true, -- 胡健力
	[1200690] = true, -- 穹顶
	[1200696] = true, -- 胡健力
	[1200697] = true, -- 胡健力
	[1200701] = true, -- 供桌2
	[1200706] = true, -- 胡健力
	[1200707] = true, -- 胡健力
	[1200708] = true, -- 大厅浑仪操控台-脚底
	[1201020] = true, -- 建隆观后山入口石板
	[1201037] = true, -- 胡健力
	[1201038] = true, -- 胡健力
	[1201039] = true, -- 胡健力
	[1201040] = true, -- 胡健力
	[1201041] = true, -- 胡健力
	[1201042] = true, -- 一楼挂接面具
	[1201063] = true, -- 胡健力
	[1201098] = true, -- 胡健力
	[1201132] = true, -- 闸口盘车水特效1
	[1201133] = true, -- 闸口盘车水特效2
	[1201134] = true, -- 胡健力
	[1201153] = true, -- 上清真境灵宝天尊
	[1201154] = true, -- 玉清圣境元始天尊
	[1201155] = true, -- 太清仙境道德天尊
	[1501110] = true, -- 孙亦鸣
	[1501304] = true, -- 孙亦鸣
	[1700000] = true, -- 不羡仙悬赏板
	[1700050] = true, -- 宋磊
	[1700068] = true, -- 宋磊
	[1700203] = true, -- 狂澜喝酒测试-斗茶
	[1700204] = true, -- 多人投壶-清河
	[1700205] = true, -- 斗茶酒缸-PVP-开封
	[1700311] = true, -- 宋磊
	[1800119] = true, -- 袁国振
	[1800149] = true, -- 袁国振
	[1800262] = true, -- 袁国振
	[1800268] = true, -- 袁国振
	[1800269] = true, -- 袁国振
	[1800289] = true, -- 袁国振
	[1800301] = true, -- 袁国振
	[1800336] = true, -- 袁国振
	[1800634] = true, -- 袁国振
	[1800641] = true, -- 袁国振
	[1800647] = true, -- 袁国振
	[1900297] = true, -- 烹饪
	[1900327] = true, -- 皮影落座按钮
	[1900350] = true, -- 欧阳书舟
	[1900389] = true, -- 欧阳书舟
	[1900444] = true, -- 武库据点-鹏的羽毛
	[1900448] = true, -- 扶摇山据点外围-窃听
	[1900449] = true, -- 模板表
	[2000017] = true, -- 宝箱-杨显彬
	[2100129] = true, -- 杨翥宇
	[2100142] = true, -- 杨翥宇
	[2100143] = true, -- 杨翥宇
	[2100225] = true, -- 杨翥宇
	[2100227] = true, -- 伤害仲裁2号
	[2100228] = true, -- 井口藤蔓-可烧毁
	[2100232] = true, -- 火盆触发器5
	[2100243] = true, -- 第二个房间的捂脸1
	[2100244] = true, -- 第三个房间的尸体3
	[2100245] = true, -- 第三个房间的诈尸
	[2100246] = true, -- 移动的无面人
	[2100248] = true, -- 地宫火箭宝箱1
	[2100250] = true, -- 地宫镇守传送道具
	[2100252] = true, -- 解谜的留言
	[2100255] = true, -- 第一个房间的监管者
	[2100256] = true, -- 第二个房间的监管者
	[2100258] = true, -- 合唱的加入笛子
	[2100271] = true, -- 门派树枝收集物
	[2100272] = true, -- 门派水坛收集物
	[2100273] = true, -- 门派算珠收集物
	[2100277] = true, -- 寒香寻的钱1
	[2100278] = true, -- 寒香寻的钱2
	[2100279] = true, -- 追忆投放
	[2100282] = true, -- 程心的匣子
	[2100285] = true, -- 二层火盆
	[2100287] = true, -- 地宫蜡烛4号
	[2100289] = true, -- 听黄河
	[2100301] = true, -- 增补的一层唱歌捂脸
	[2100304] = true, -- 门震动
	[2100305] = true, -- 独立的捂脸者
	[2100308] = true, -- 杨翥宇
	[2100320] = true, -- 泛黄的婚书
	[2100336] = true, -- 杨翥宇
	[2100337] = true, -- 杨翥宇
	[2100338] = true, -- 杨翥宇
	[2100343] = true, -- 追忆装备-清泉
	[2100350] = true, -- 合唱的加入笛子
	[2100351] = true, -- 重型龙头机关
	[2100352] = true, -- 重型龙头机关
	[2100355] = true, -- 杨翥宇
	[2100356] = true, -- 红色托盘
	[2100386] = true, -- 镰刀箱子看戏怪
	[2100387] = true, -- 火把敲箱子怪
	[2100398] = true, -- 掉落的吓人毒人
	[2100399] = true, -- 氛围毒人
	[2100400] = true, -- 氛围毒人
	[2100401] = true, -- 猛火油柜--假
	[2100419] = true, -- 狼王
	[2100445] = true, -- 杨翥宇
	[2100481] = true, -- 袁国振
	[2100550] = true, -- 杨翥宇
	[2100553] = true, -- 杨翥宇
	[2100559] = true, -- 井口藤蔓-不可烧毁
	[2100561] = true, -- 杨翥宇
	[2200113] = true, -- 杨心仪
	[2200114] = true, -- 杨心仪
	[2200115] = true, -- 杨心仪
	[2200116] = true, -- 杨心仪
	[2200118] = true, -- 杨心仪
	[2400292] = true, -- 贺江婷
	[2500002] = true, -- 清河主线
	[2500029] = true, -- 贺江婷
	[2500030] = true, -- 贺江婷
	[2500031] = true, -- 贺江婷
	[2500047] = true, -- 宝箱
	[2500048] = true, -- 宝箱
	[2500049] = true, -- 宝箱
	[2500050] = true, -- 宝箱
	[2500051] = true, -- 宝箱
	[2500053] = true, -- 清河主线
	[2500056] = true, -- 开封主线
	[2500059] = true, -- 贺江婷
	[2500060] = true, -- 贺江婷
	[2500069] = true, -- 清河主线
	[2620052] = true, -- 金雪松
	[2700009] = true, -- 周一舟
	[2700010] = true, -- 周一舟
	[2700011] = true, -- 周一舟
	[2700012] = true, -- 周一舟
	[2700013] = true, -- 周一舟
	[2703151] = true, -- 周一舟
	[2703152] = true, -- 周一舟
	[2703153] = true, -- 周一舟
	[2703156] = true, -- 周一舟
	[2703158] = true, -- 周一舟
	[2703165] = true, -- 周一舟
	[2703177] = true, -- 周一舟
	[2703178] = true, -- 周一舟
	[2703179] = true, -- 周一舟
	[2703180] = true, -- 周一舟
	[2703181] = true, -- 周一舟
	[2703182] = true, -- 周一舟
	[2703183] = true, -- 周一舟
	[2703184] = true, -- 周一舟
	[2703185] = true, -- 周一舟
	[2703186] = true, -- 周一舟
	[2703199] = true, -- 周一舟
	[2703214] = true, -- 周一舟
	[2703225] = true, -- 周一舟
	[2703226] = true, -- 周一舟
	[2703227] = true, -- 周一舟
	[2703228] = true, -- 周一舟
	[2703250] = true, -- 周一舟
	[2703251] = true, -- 周一舟
	[2703253] = true, -- 周一舟
	[2703254] = true, -- 周一舟
	[2703257] = true, -- 周一舟
	[2703266] = true, -- 周一舟
	[2703267] = true, -- 周一舟
	[2703268] = true, -- 周一舟
	[2703269] = true, -- 周一舟
	[2703278] = true, -- 周一舟
	[2703279] = true, -- 周一舟
	[2703280] = true, -- 周一舟
	[2703281] = true, -- 周一舟
	[2703282] = true, -- 周一舟
	[2703283] = true, -- 周一舟
	[2703284] = true, -- 周一舟
	[2800055] = true, -- 易楷宁
	[3000006] = true, -- 张增辉
	[3000008] = true, -- 张增辉
	[3200838] = true, -- 施天来
	[3200850] = true, -- 应悔偷灵药-遗失的药包
	[3200858] = true, -- 被划去的名字-杨氏族谱
	[3200859] = true, -- 谁言慈父心-圆润的小佛雕
	[3200860] = true, -- 谁言慈父心-有棱有角的小佛雕
	[3200861] = true, -- 业火不熄-没烧干净的家书
	[3200862] = true, -- 残佛不语-诅咒人偶
	[3200867] = true, -- 神仙渡-离人泪
	[3200876] = true, -- 深夜犬吠-鲜肉
	[3200877] = true, -- 深夜犬吠-火焰龙纹令牌
	[3200879] = true, -- 欲望深渊-大坛离人泪
	[3200882] = true, -- 大鹅争锋-火折子
	[3200883] = true, -- 大鹅争锋-宋九的臭袜子
	[3200885] = true, -- 失窃美酒-一撮黄毛
	[3200886] = true, -- 失窃美酒-头坛酒
	[3200889] = true, -- 欲望深渊-精酿离人泪
	[3202210] = true, -- 小木笼
	[3202231] = true, -- 施天来
	[3202232] = true, -- 施天来
	[3202233] = true, -- 施天来
	[3202234] = true, -- 施天来
	[3202235] = true, -- 施天来
	[3202236] = true, -- 施天来
	[3202240] = true, -- 施天来
	[3202309] = true, -- 施天来
	[3202310] = true, -- 施天来
	[3202332] = true, -- 施天来
	[3202334] = true, -- 施天来
	[3202340] = true, -- 华中承
	[3202341] = true, -- 华中承
	[3202342] = true, -- 施天来
	[3203001] = true, -- 花中愿-摩诃曼殊沙华
	[3203003] = true, -- 本心善妙-善妙手书
	[3203005] = true, -- 良人胡不归-神秘梦傀
	[3203006] = true, -- 神秘的小药瓶
	[3203008] = true, -- 祁飞骏的日记
	[3203009] = true, -- 未央商会的来信
	[3203012] = true, -- 祁氏家驯
	[3203015] = true, -- 将军祠万物交互-小屁孩的鼓
	[3203026] = true, -- 施天来
	[3205600] = true, -- 耿赟
	[3205701] = true, -- 施天来
	[3600070] = true, -- 酒逢知己-墓碑-任务后
	[3600096] = true, -- 酒逢知己-墓碑酒坛
	[3600121] = true, -- 追忆-九曲石船-破旧的酒坛
	[3600122] = true, -- 追忆-医馆地底-洛神手记
	[3700602] = true, -- 场景大鹅-神仙渡
	[3700622] = true, -- 徐佳琦
	[3700635] = true, -- 徐佳琦
	[3700637] = true, -- 徐佳琦
	[3700638] = true, -- 徐佳琦
	[3700646] = true, -- 徐佳琦
	[3800033] = true, -- 彭冉
	[3800035] = true, -- 武林录解锁-真磕头点
	[3800036] = true, -- 武林录解锁-无头雕像
	[3800060] = true, -- 石碑1
	[3800061] = true, -- 石碑2
	[3800062] = true, -- 石碑3
	[3800063] = true, -- 石碑4
	[3800064] = true, -- 石碑5
	[3800065] = true, -- 彭冉
	[3800102] = true, -- 任宽
	[3900039] = true, -- 猫_橙-神仙渡喂猫2
	[3900040] = true, -- 猫_橙-神仙渡喂猫3
	[3900041] = true, -- 猫_橙-神仙渡喂猫5
	[3900042] = true, -- 猫_印花-神仙渡喂猫1
	[3900043] = true, -- 猫_印花-不羡仙摸猫2
	[3900044] = true, -- 猫_印花-伏嘛庄摸猫
	[3900045] = true, -- 猫_白-不羡仙摸猫1
	[3900046] = true, -- 猫_白-瓷窑摸猫1
	[3900047] = true, -- 猫_白-来生岸摸猫1
	[3900048] = true, -- 猫_黑（狸花）-神仙渡喂猫4
	[3900049] = true, -- 猫_黑（狸花）-不羡仙摸猫3
	[3900050] = true, -- 猫_黑（狸花）-丰禾村摸猫1
	[3900051] = true, -- 猫_橙-不羡仙摸猫4
	[3900052] = true, -- 白草野摸猫2
	[3900053] = true, -- 猫_白-慈心镇摸猫1
	[3900054] = true, -- 猫_黑（狸花）-佛光顶摸猫2
	[3904046] = true, -- 张筱诺
	[3904052] = true, -- 张筱诺
	[3904055] = true, -- 张筱诺
	[3904067] = true, -- 张筱诺
	[3904069] = true, -- 张筱诺
	[3904070] = true, -- 张筱诺
	[3904071] = true, -- 张筱诺
	[3904073] = true, -- 田野
	[3904093] = true, -- 张筱诺
	[3904094] = true, -- 张筱诺
	[3904096] = true, -- 张筱诺
	[3904098] = true, -- 张筱诺
	[3904099] = true, -- 张筱诺
	[3904101] = true, -- 张筱诺
	[3904102] = true, -- 张筱诺
	[3904103] = true, -- 张筱诺
	[3904104] = true, -- 张筱诺
	[3904105] = true, -- 张筱诺
	[3904106] = true, -- 张筱诺
	[3904108] = true, -- 张筱诺
	[3904109] = true, -- 张筱诺
	[3904119] = true, -- 张筱诺
	[3904123] = true, -- 张筱诺
	[3905210] = true, -- 张筱诺
	[3905212] = true, -- 张筱诺
	[3905226] = true, -- 荧渊-记忆1-柳青衣
	[3905227] = true, -- 荧渊-记忆2-哀帝
	[3905228] = true, -- 荧渊-记忆3-柳青衣
	[3905233] = true, -- 荧渊-记忆1-哀帝
	[3905234] = true, -- 荧渊-记忆3-哀帝
	[3905237] = true, -- 荧渊-鹿头骨（红）01
	[3905238] = true, -- 荧渊-鹿头骨（红）02
	[3905239] = true, -- 荧渊-鹿头骨（红）03
	[3905241] = true, -- 荧渊-吊桥-绳子-一捆
	[3905244] = true, -- 荧渊-柳哀小屋-鹿灵
	[3905248] = true, -- 张筱诺
	[3905249] = true, -- 荧渊-人蛹留书+钥匙
	[3905250] = true, -- 荧渊-叙事-孙不弃手札（一）
	[3905251] = true, -- 荧渊-叙事-孙不弃手札（二）
	[3905254] = true, -- 荧渊-叙事-孙不弃手札（三）
	[3905255] = true, -- 荧渊-叙事-水月先生回信
	[3905256] = true, -- 荧渊-叙事-凝露酿
	[3905257] = true, -- 荧渊-叙事-木雕雌鹿
	[3905262] = true, -- 荧渊-实验室门机关
	[3905274] = true, -- 荧渊-柳青衣墓-鹿灵
	[3905275] = true, -- 荧渊-终局-鹿灵
	[3905276] = true, -- 荧渊-污染鹿头骨1-鹿灵
	[3905277] = true, -- 荧渊-污染鹿头骨2-鹿灵
	[3905278] = true, -- 荧渊-污染鹿头骨3-鹿灵
	[3905280] = true, -- 荧渊-柳哀小屋-机关
	[3905282] = true, -- 荧渊-前往下层
	[3905285] = true, -- 荧渊-太极点亮-负手石像灯
	[3905288] = true, -- 俞立
	[3905289] = true, -- 荧渊-叙事道具-长生仙人传中
	[3905290] = true, -- 荧渊-叙事道具-长生仙人传下
	[3905291] = true, -- 荧渊-叙事道具-巴梧自传上
	[3905292] = true, -- 荧渊-叙事道具-巴梧自传中
	[3905293] = true, -- 荧渊-叙事道具-巴梧自传下
	[3905294] = true, -- 荧渊-银锁
	[3905296] = true, -- 张筱诺
	[3905297] = true, -- 张筱诺
	[3905298] = true, -- 张筱诺
	[3905299] = true, -- 张筱诺
	[3905300] = true, -- 张筱诺
	[3905301] = true, -- 张筱诺
	[3905302] = true, -- 荧渊-祭祀-鹿头仙人壁画
	[3905304] = true, -- 荧渊-祭祀-玩家祭拜点
	[3905332] = true, -- 荧渊-祭祀-血书
	[3905342] = true, -- 荧渊-进入老荧渊洞口
	[3905344] = true, -- 张筱诺
	[3905345] = true, -- 张筱诺
	[3905350] = true, -- 模板表
	[3905351] = true, -- 模板表
	[3905354] = true, -- 张筱诺
	[4100005] = true, -- 开封琼林苑
	[4100007] = true, -- 开封琼林苑
	[4100032] = true, -- 开封琼林苑
	[4100051] = true, -- 秦臻
	[4200073] = true, -- 刘海歌
	[4200074] = true, -- 刘海歌
	[4200075] = true, -- 刘海歌
	[4200078] = true, -- 第三次佛光-遗失的旧账本
	[4200203] = true, -- 刘海歌
	[4200204] = true, -- 刘海歌
	[4200205] = true, -- 刘海歌
	[4200206] = true, -- 刘海歌
	[4500012] = true, -- 宝箱
	[4500014] = true, -- 劫车宝箱
	[4500015] = true, -- 破损马车珍宝匣
	[4500016] = true, -- 宝箱
	[4500017] = true, -- 种植曼陀罗营地宝箱
	[4500037] = true, -- 宝箱
	[4500040] = true, -- 花海-宝箱
	[4500042] = true, -- 寒房心法宝箱
	[4500045] = true, -- 地宫宝箱增补3（珍贵）
	[4500046] = true, -- 宝箱
	[4500047] = true, -- 宝箱
	[4500048] = true, -- 宝箱
	[4500050] = true, -- 红尘无眼水下指引宝箱1
	[4500051] = true, -- 红尘无眼水下指引宝箱2
	[4500052] = true, -- 红尘无眼水下指引宝箱3
	[4500053] = true, -- 红尘无眼水下指引宝箱4
	[4500054] = true, -- 红尘无眼水下指引宝箱5
	[4500055] = true, -- 红尘无眼水下指引宝箱6
	[4500057] = true, -- 荧渊-柳哀小屋-一品宝箱（心法所恨年年）
	[4500058] = true, -- 敌袭立体通路一层高级宝箱-2
	[4500059] = true, -- 敌袭宝箱
	[4500060] = true, -- 张联鑫
	[4500061] = true, -- 宝箱
	[4500062] = true, -- 宝箱
	[4500063] = true, -- 宝箱
	[4500064] = true, -- 木条箱【丹崖】
	[4500066] = true, -- 毒人诞生
	[4500068] = true, -- 宝箱
	[4500074] = true, -- 宝箱
	[4500075] = true, -- 宝箱
	[4500076] = true, -- 宝箱
	[4500077] = true, -- 宝箱
	[4500078] = true, -- 宝箱
	[4500079] = true, -- 宝箱
	[4500080] = true, -- 宝箱
	[4500081] = true, -- 宝箱
	[4500082] = true, -- 宝箱
	[4500083] = true, -- 宝箱
	[4500084] = true, -- 宝箱
	[4500085] = true, -- 宝箱
	[4500086] = true, -- 宝箱
	[4500087] = true, -- 宝箱
	[4500088] = true, -- 宝箱
	[4500089] = true, -- 宝箱
	[4500090] = true, -- 宝箱
	[4500091] = true, -- 九曲断魂枪心法
	[4500092] = true, -- 青山执笔心法
	[4500093] = true, -- 宝箱
	[4500094] = true, -- 珍宝匣
	[4500103] = true, -- 袁国振
	[4500105] = true, -- 鬼寺宝箱-药物
	[4500106] = true, -- 张联鑫
	[4500113] = true, -- 宝箱
	[4500114] = true, -- 宝箱
	[4500115] = true, -- 宝箱
	[4500117] = true, -- 宝箱
	[4500120] = true, -- 宝箱
	[4500121] = true, -- 宝箱
	[4500122] = true, -- 宝箱
	[4500123] = true, -- 宝箱
	[4500129] = true, -- 不羡仙-追忆装备-翼甲
	[4500130] = true, -- 周雨霖
	[4500131] = true, -- 赵伟业
	[4500135] = true, -- 宝箱
	[4500136] = true, -- 【无忧洞】木制三品宝箱
	[4500137] = true, -- 宝箱
	[4500138] = true, -- 宝箱
	[4500139] = true, -- 宝箱
	[4500140] = true, -- 【偷师】铁制二品宝箱-枪
	[4500141] = true, -- 宝箱
	[4500142] = true, -- 宝箱
	[4500143] = true, -- 【偷师】木制三品宝箱-扇
	[4500144] = true, -- 宝箱
	[4500145] = true, -- 宝箱
	[4500146] = true, -- 宝箱
	[4500147] = true, -- 宝箱
	[4500148] = true, -- 宝箱
	[4500149] = true, -- 宝箱
	[4500150] = true, -- 宝箱
	[4500151] = true, -- 宝箱
	[4500152] = true, -- 宝箱
	[4500153] = true, -- 宝箱
	[4500154] = true, -- 宝箱
	[4500155] = true, -- 宝箱
	[4500156] = true, -- 宝箱
	[4500158] = true, -- 宝箱
	[4500160] = true, -- 宝箱
	[4500162] = true, -- 宝箱
	[4500163] = true, -- 宝箱
	[4500164] = true, -- 将军祠-战斗-四品宝箱（无追踪标）
	[4500165] = true, -- 宝箱
	[4500166] = true, -- 孙佳楠
	[4500167] = true, -- 孙佳楠
	[4500168] = true, -- 宝箱
	[4500172] = true, -- 宝箱
	[4500173] = true, -- 宝箱
	[4500174] = true, -- 宝箱
	[4500175] = true, -- 宝箱
	[4500179] = true, -- 宝箱
	[4500181] = true, -- 李嘉栋
	[4500182] = true, -- 李嘉栋
	[4500183] = true, -- 李嘉栋
	[4500184] = true, -- 黄乐孳
	[4500185] = true, -- 孙佳楠
	[4500186] = true, -- 宝箱
	[4500188] = true, -- 宝箱
	[4500189] = true, -- 【无忧洞】金制一品宝箱
	[4500193] = true, -- 宝箱
	[4500194] = true, -- 宝箱
	[4500195] = true, -- 宝箱
	[4500196] = true, -- 宝箱
	[4500203] = true, -- 袁国振
	[4500204] = true, -- 俞立
	[4500207] = true, -- 宝箱
	[4500208] = true, -- 宝箱
	[4500209] = true, -- 宝箱
	[4500212] = true, -- 宝箱
	[4500213] = true, -- 张俊杰
	[4500214] = true, -- 宝箱
	[4500215] = true, -- 普通宝箱（野外）-瓷窑
	[4500217] = true, -- 李弘扬
	[4500219] = true, -- 赵伟业
	[4500220] = true, -- 宝箱
	[4500221] = true, -- 宝箱
	[4500222] = true, -- 宝箱
	[4500224] = true, -- 宝箱
	[4500225] = true, -- 宝箱
	[4500226] = true, -- 宝箱
	[4500227] = true, -- 陈晓翰
	[4500228] = true, -- 宝箱
	[4500229] = true, -- 宝箱
	[4500232] = true, -- 宝箱
	[4500233] = true, -- 宝箱
	[4500234] = true, -- 宝箱
	[4500241] = true, -- 宝箱
	[4500246] = true, -- 宝箱
	[4500247] = true, -- 宝箱
	[4500248] = true, -- 石九亮
	[4500294] = true, -- 宝箱
	[4500299] = true, -- 宝箱
	[4500300] = true, -- 宝箱
	[4500301] = true, -- 宝箱
	[4500302] = true, -- 宝箱
	[4501000] = true, -- 宝箱
	[4501001] = true, -- 宝箱
	[4501002] = true, -- 宝箱
	[4501003] = true, -- 宝箱
	[4501006] = true, -- 宝箱
	[4600083] = true, -- 梁程宏
	[4600103] = true, -- 梁程宏
	[4600104] = true, -- 梁程宏
	[4600132] = true, -- 胡健力
	[4700013] = true, -- 搬石像-底座
	[4700020] = true, -- 搬石像-场景石像
	[4700023] = true, -- 鲍文旭
	[4700039] = true, -- 北盟遗址-烈不尽
	[4700040] = true, -- 北盟遗址-烈不灭
	[4700054] = true, -- 北盟遗址-张豹
	[4700058] = true, -- 鲍文旭
	[4700059] = true, -- 鲍文旭
	[4700060] = true, -- 鲍文旭
	[4700061] = true, -- 鲍文旭
	[4700063] = true, -- 鲍文旭
	[4700064] = true, -- 鲍文旭
	[4700066] = true, -- 鲍文旭
	[4700067] = true, -- 鲍文旭
	[4700068] = true, -- 鲍文旭
	[4700069] = true, -- 鲍文旭
	[4700071] = true, -- 鲍文旭
	[4700073] = true, -- 俞立
	[4700086] = true, -- 鲍文旭
	[4810011] = true, -- 生态物种
	[4834002] = true, -- 生态物种
	[4834003] = true, -- 生态物种
	[4835001] = true, -- 周一舟
	[4900028] = true, -- 曼陀罗花1
	[4900030] = true, -- 曼陀罗花2
	[4900039] = true, -- 据点-笼子
	[4900071] = true, -- 妙妙喵-石像圆盘
	[4900072] = true, -- 孙浩声
	[4900087] = true, -- 孙浩声
	[4900098] = true, -- 妙妙喵-忘川河石碑
	[4900100] = true, -- 妙妙喵-新供奉玩法-佛像B
	[4900101] = true, -- 妙妙喵-新供奉玩法-佛像C
	[4900108] = true, -- 妙妙喵-新供奉玩法-宝藏
	[4900109] = true, -- 孙浩声
	[4900114] = true, -- 北盟遗址-火炬
	[4900115] = true, -- 北盟遗址-转动石像
	[4900116] = true, -- 北盟遗址-位移的石块-万
	[4900119] = true, -- 烈言遗书
	[4900127] = true, -- 北盟遗址-离开密室
	[4900128] = true, -- 任宽
	[4900129] = true, -- 北盟遗址-窃听A
	[4900130] = true, -- 北盟遗址-位移的石块-水
	[4900131] = true, -- 北盟遗址-位移的石块-千
	[4900132] = true, -- 北盟遗址-位移的石块-山
	[4900133] = true, -- 北盟遗址-位移的石块-锦
	[4900134] = true, -- 北盟遗址-位移的石块-绣
	[4900135] = true, -- 北盟遗址-位移的石块-山
	[4900136] = true, -- 北盟遗址-位移的石块-河
	[4900137] = true, -- 北盟遗址-位移的石块-寸
	[4900138] = true, -- 北盟遗址-位移的石块-草
	[4900139] = true, -- 北盟遗址-位移的石块-不
	[4900140] = true, -- 北盟遗址-位移的石块-生
	[4900141] = true, -- 北盟遗址-位移的石块-土
	[4900142] = true, -- 北盟遗址-位移的石块-流
	[4900143] = true, -- 北盟遗址-位移的石块-漂
	[4900144] = true, -- 北盟遗址-位移的石块-橹
	[4900145] = true, -- 北盟遗址-位移的石块-海
	[4900146] = true, -- 北盟遗址-位移的石块-誓
	[4900147] = true, -- 北盟遗址-位移的石块-山
	[4900148] = true, -- 北盟遗址-位移的石块-盟
	[4900149] = true, -- 北盟遗址-位移的石块-同
	[4900150] = true, -- 北盟遗址-位移的石块-生
	[4900151] = true, -- 北盟遗址-位移的石块-共
	[4900152] = true, -- 北盟遗址-位移的石块-死
	[4900153] = true, -- 北盟遗址-位移的石块-百
	[4900154] = true, -- 北盟遗址-位移的石块-折
	[4900155] = true, -- 北盟遗址-位移的石块-不
	[4900156] = true, -- 北盟遗址-位移的石块-回
	[4900157] = true, -- 北盟遗址-位移的石块-移
	[4900158] = true, -- 北盟遗址-位移的石块-天
	[4900159] = true, -- 北盟遗址-位移的石块-易
	[4900160] = true, -- 北盟遗址-位移的石块-日
	[4900169] = true, -- 追忆装备宝箱-琴
	[4900170] = true, -- 追忆装备宝箱-盔甲
	[4900182] = true, -- 孙浩声
	[4900184] = true, -- 孙浩声
	[4900186] = true, -- 孙浩声
	[4900187] = true, -- 孙浩声
	[4900193] = true, -- 宝箱
	[4900195] = true, -- 孙浩声
	[4900201] = true, -- 孙浩声
	[4900207] = true, -- 孙浩声
	[4900208] = true, -- 孙浩声
	[4900256] = true, -- 张筱诺
	[4900257] = true, -- 孙浩声
	[4900260] = true, -- 孙浩声
	[4900265] = true, -- 孙浩声
	[4900266] = true, -- 孙浩声
	[4900267] = true, -- 孙浩声
	[4900269] = true, -- 孙浩声
	[4900276] = true, -- 蒙名恒
	[4900280] = true, -- 孙浩声
	[4900285] = true, -- 孙浩声
	[4900289] = true, -- 孙浩声
	[4900290] = true, -- 张俊杰
	[4900293] = true, -- 孙浩声
	[4900294] = true, -- 孙浩声
	[4900295] = true, -- 孙浩声
	[4900296] = true, -- 孙浩声
	[4900301] = true, -- 孙浩声
	[4900302] = true, -- 孙浩声
	[4900303] = true, -- 孙浩声
	[4900304] = true, -- 孙浩声
	[4900306] = true, -- 孙浩声
	[4900307] = true, -- 孙浩声
	[4900308] = true, -- 孙浩声
	[4900309] = true, -- 孙浩声
	[4900312] = true, -- 孙浩声
	[4900320] = true, -- 孙浩声
	[4900326] = true, -- 孙浩声
	[4900327] = true, -- 孙浩声
	[4900328] = true, -- 孙浩声
	[4900329] = true, -- 孙浩声
	[4900330] = true, -- 张益豪
	[4900331] = true, -- 鲍文旭
	[4900332] = true, -- 孙浩声
	[4900334] = true, -- 孙浩声
	[4900337] = true, -- 孙浩声
	[4900338] = true, -- 孙浩声
	[4900339] = true, -- 孙浩声
	[4900340] = true, -- 孙浩声
	[4900341] = true, -- 孙浩声
	[4900345] = true, -- 孙浩声
	[4900346] = true, -- 模板表
	[4900347] = true, -- 杨翥宇
	[4900348] = true, -- 孙浩声
	[4900352] = true, -- 孙浩声
	[4900356] = true, -- 孙浩声
	[4900366] = true, -- 孙浩声
	[4900368] = true, -- 孙浩声
	[4900373] = true, -- 孙浩声
	[4900389] = true, -- 孙浩声
	[4900429] = true, -- 孙浩声
	[4900444] = true, -- 孙浩声
	[5000014] = true, -- 陈宸
	[5000015] = true, -- 陈宸
	[5000016] = true, -- 陈宸
	[5000023] = true, -- 陈宸
	[5000024] = true, -- 陈宸
	[5000025] = true, -- 陈宸
	[5000066] = true, -- 陈宸
	[5000068] = true, -- 追忆装备宝箱-严氏屋武器
	[5000108] = true, -- 陈宸
	[5000109] = true, -- 陈宸
	[5000110] = true, -- 陈宸
	[5000135] = true, -- 陈宸
	[5000136] = true, -- 陈宸
	[5000137] = true, -- 陈宸
	[5000138] = true, -- 陈宸
	[5000139] = true, -- 陈宸
	[5000140] = true, -- 陈宸
	[5000180] = true, -- 陈宸
	[5000248] = true, -- 将军祠-出口房间-三品宝箱（追忆装备护符）
	[5010000] = true, -- 陈宸
	[5010001] = true, -- 陈宸
	[5010002] = true, -- 陈宸
	[5010003] = true, -- 陈宸
	[5010004] = true, -- 陈宸
	[5010005] = true, -- 陈宸
	[5010006] = true, -- 陈宸
	[5010007] = true, -- 陈宸
	[5010008] = true, -- 陈宸
	[5010009] = true, -- 陈宸
	[5010010] = true, -- 陈宸
	[5010011] = true, -- 陈宸
	[5010012] = true, -- 陈宸
	[5010013] = true, -- 陈宸
	[5010014] = true, -- 陈宸
	[5010015] = true, -- 陈宸
	[5010016] = true, -- 陈宸
	[5010017] = true, -- 陈宸
	[5010018] = true, -- 陈宸
	[5010019] = true, -- 陈宸
	[5010020] = true, -- 陈宸
	[5010023] = true, -- 鲍文旭
	[5010024] = true, -- 地宫宝箱增补1
	[5010025] = true, -- 地宫宝箱增补2
	[5010026] = true, -- 王思越
	[5010027] = true, -- 春秋别馆-博物-绘画解锁宝箱
	[5010028] = true, -- 菩提苦海全家福
	[5100002] = true, -- 奇术-鸟巢（投食观察点）
	[5100022] = true, -- 奇术-铜钟-将军祠里面
	[5100023] = true, -- 奇术-铜钟-将军祠外围
	[5100025] = true, -- 奇术-铜钟-佛爷寨
	[5100026] = true, -- 奇术-铜钟-荒魂村和鹿食岭界碑中间
	[5100033] = true, -- 吴小莹
	[5100035] = true, -- 监狱-氛围-古琴-清河
	[5100202] = true, -- 吴小莹
	[5100208] = true, -- 吴小莹
	[5100209] = true, -- 叶子戏-PVP-开封
	[5210010] = true, -- 王智超
	[5210011] = true, -- 丁纪文
	[5210012] = true, -- 丁纪文
	[5210020] = true, -- 丁纪文
	[5210021] = true, -- 储一民
	[5210042] = true, -- 储一民
	[5210100] = true, -- 丁纪文
	[5210101] = true, -- 丁纪文
	[5210102] = true, -- 丁纪文
	[5210110] = true, -- 储一民
	[5210190] = true, -- 储一民
	[5210202] = true, -- 储一民
	[5210292] = true, -- 储一民
	[5210350] = true, -- 储一民
	[5210360] = true, -- 储一民
	[5300118] = true, -- 掌心采花-佛像调查
	[5300120] = true, -- 掌心采花-采花
	[5300122] = true, -- 妙妙喵枯树
	[5300124] = true, -- 塔顶荷花-佛像调查
	[5300131] = true, -- 打乱画像-佛像调查
	[5300178] = true, -- 王智超
	[5300179] = true, -- 王智超
	[5300195] = true, -- 王智超
	[5300196] = true, -- 王智超
	[5300490] = true, -- 太仓粟清心圃野怪绣金楼B1
	[5300500] = true, -- 王智超
	[5300520] = true, -- 王智超
	[5300530] = true, -- 太仓粟鹰愁岭野怪绿林B46
	[5300540] = true, -- 太仓粟雾隐林野怪绿林B34
	[5300600] = true, -- 太仓粟清心圃野怪绣金楼B2
	[5300622] = true, -- 太仓粟东郊野怪绿林B17
	[5400112] = true, -- 赵伟业
	[5400201] = true, -- 话术npc-贾仁
	[5400202] = true, -- 话术npc-戒莲
	[5400203] = true, -- 话术npc-静衍
	[5400204] = true, -- 话术npc-叶惜花
	[5400205] = true, -- 话术npc-江缘起
	[5400206] = true, -- 话术npc-公孙龙
	[5400207] = true, -- 话术npc-梁大有
	[5400208] = true, -- 话术npc-良心龙虎寨盗贼
	[5400209] = true, -- 话术npc-书生陆有方
	[5400210] = true, -- 话术npc-刘婶
	[5400211] = true, -- 话术npc-胡百里
	[5400213] = true, -- 话术npc-王狗子
	[5400215] = true, -- 话术npc-钓鱼老头
	[5400216] = true, -- 悬壶npc-毛大
	[5400217] = true, -- 悬壶npc-毛二
	[5400218] = true, -- 悬壶npc-酒伯
	[5400219] = true, -- 悬壶npc-阿丹
	[5400220] = true, -- 悬壶npc-丰野
	[5400221] = true, -- 悬壶npc-刘顺子
	[5400222] = true, -- 悬壶npc-周振岩
	[5400223] = true, -- 悬壶npc-谢惟祖
	[5400224] = true, -- 悬壶npc-何藕娘
	[5400225] = true, -- 悬壶npc-孙半城
	[5400228] = true, -- 赵伟业
	[5400229] = true, -- 赵伟业
	[5400230] = true, -- 赵伟业
	[5400245] = true, -- 追忆装备宝箱-千机匣武器
	[5400246] = true, -- 追忆装备宝箱-衣冠冢护符
	[5400247] = true, -- 追忆装备宝箱-医馆一楼腰带
	[5400266] = true, -- 赵伟业
	[5400272] = true, -- 荧渊-实验室-二品宝箱（奇术枯骨）
	[5400288] = true, -- 斑驳的遗书
	[5400289] = true, -- 静难的包袱
	[5400290] = true, -- 叶万山的匕首
	[5400414] = true, -- 孙浩声
	[5400578] = true, -- 赵伟业
	[5400579] = true, -- 赵伟业
	[5400580] = true, -- 赵伟业
	[5400583] = true, -- 赵伟业
	[5400587] = true, -- 赵伟业
	[5400588] = true, -- 赵伟业
	[5400590] = true, -- 赵伟业
	[5400591] = true, -- 赵伟业
	[5400593] = true, -- 赵伟业
	[5400597] = true, -- 赵伟业
	[5400848] = true, -- 模板表
	[5401023] = true, -- 施天来
	[5401024] = true, -- 施天来
	[5401025] = true, -- 施天来
	[5401433] = true, -- 天不收椅子
	[5500091] = true, -- 陈凯
	[5800116] = true, -- 张益豪
	[5800117] = true, -- 张益豪
	[5800120] = true, -- 张益豪
	[5800121] = true, -- 张益豪
	[5800156] = true, -- 张益豪
	[5800157] = true, -- 太仓粟雾隐林野怪梦傀B33
	[5800180] = true, -- 张益豪
	[5800181] = true, -- 张益豪
	[5800182] = true, -- 张益豪
	[5900004] = true, -- 陈凯
	[5900005] = true, -- 陈凯
	[5900017] = true, -- 陈凯
	[5900018] = true, -- 张筱诺
	[5900022] = true, -- 陈凯
	[5900025] = true, -- 陈凯
	[5900030] = true, -- 陈凯
	[5900032] = true, -- 陈凯
	[5900035] = true, -- 陈凯
	[5900037] = true, -- 陈凯
	[5900038] = true, -- 陈凯
	[5900043] = true, -- 陈凯
	[5900044] = true, -- 陈凯
	[5900046] = true, -- 陈凯
	[5900047] = true, -- 陈凯
	[5900048] = true, -- 陈凯
	[5900052] = true, -- 陈凯
	[5900060] = true, -- 陈凯
	[5900061] = true, -- 陈凯
	[5900065] = true, -- 张筱诺
	[5900066] = true, -- 王治
	[5900067] = true, -- 华中承
	[5900068] = true, -- 王治
	[5900069] = true, -- 王治
	[5900070] = true, -- 陈凯
	[5900071] = true, -- 王治
	[5900074] = true, -- 陈凯
	[5900075] = true, -- 陈凯
	[5900078] = true, -- 陈凯
	[5900079] = true, -- 陈凯
	[5900080] = true, -- 陈凯
	[5900081] = true, -- 陈凯
	[5900083] = true, -- 陈凯
	[5900084] = true, -- 陈凯
	[5900085] = true, -- 陈凯
	[5900086] = true, -- 陈凯
	[5900087] = true, -- 陈凯
	[5900088] = true, -- 陈凯
	[5900089] = true, -- 陈凯
	[5900116] = true, -- 陈凯
	[5900117] = true, -- 陈凯
	[5900120] = true, -- 陈凯
	[5900124] = true, -- 任宽
	[5900125] = true, -- 任宽
	[5900203] = true, -- 陈凯
	[6090019] = true, -- 梁子寒
	[6090020] = true, -- 梁子寒
	[6090021] = true, -- 梁子寒
	[6090050] = true, -- 梁子寒
	[6090054] = true, -- 梁子寒
	[6090127] = true, -- 梁子寒
	[6090201] = true, -- 梁子寒
	[6091013] = true, -- 梁子寒
	[6100039] = true, -- 华中承
	[6100058] = true, -- 华中承
	[6100059] = true, -- 华中承
	[6100060] = true, -- 华中承
	[6100063] = true, -- 华中承
	[6100067] = true, -- 华中承
	[6100071] = true, -- 任宽
	[6100072] = true, -- 华中承
	[6100073] = true, -- 华中承
	[6100076] = true, -- 华中承
	[6100083] = true, -- 华中承
	[6100097] = true, -- 华中承
	[6100099] = true, -- 华中承
	[6100100] = true, -- 水闸-叶轮
	[6100101] = true, -- 华中承
	[6100145] = true, -- 华中承
	[6100164] = true, -- 华中承
	[6100166] = true, -- 华中承
	[6100167] = true, -- 华中承
	[6100168] = true, -- 华中承
	[6100178] = true, -- 华中承
	[6200002] = true, -- 认祖离宗-牌位
	[6200006] = true, -- 星火不熄-秘密信件（交互）
	[6200008] = true, -- 财神归位-财神像（交互）
	[6200017] = true, -- 稚子童戏-布娃娃
	[6200019] = true, -- 何日归家-长枪
	[6200126] = true, -- 凌佳欣
	[6200127] = true, -- 凌佳欣
	[6200148] = true, -- 凌佳欣
	[6200149] = true, -- 凌佳欣
	[6200150] = true, -- 凌佳欣
	[6200151] = true, -- 凌佳欣
	[6200152] = true, -- 寿焓宇
	[6200155] = true, -- 凌佳欣
	[6200156] = true, -- 寿焓宇
	[6200157] = true, -- 寿焓宇
	[6200158] = true, -- 寿焓宇
	[6200159] = true, -- 寿焓宇
	[6200171] = true, -- 凌佳欣
	[6300031] = true, -- 任众
	[6300049] = true, -- 任众
	[6300050] = true, -- 华中承
	[6300065] = true, -- 任众
	[6300073] = true, -- 任众
	[6300075] = true, -- 任众
	[6300077] = true, -- 任众
	[6300084] = true, -- 任众
	[6300085] = true, -- 任众
	[6300086] = true, -- 贺江婷
	[6300087] = true, -- 任众
	[6300088] = true, -- 任众
	[6300091] = true, -- 任众
	[6300092] = true, -- 任众
	[6300093] = true, -- 任众
	[6300112] = true, -- 任众
	[6300113] = true, -- 任众
	[6300114] = true, -- 任众
	[6300115] = true, -- 任众
	[6300116] = true, -- 任众
	[6300117] = true, -- 任众
	[6300118] = true, -- 任众
	[6300125] = true, -- 任众
	[6300128] = true, -- 任众
	[6300255] = true, -- 任众
	[6300256] = true, -- 任众
	[6400001] = true, -- 张联鑫
	[6400009] = true, -- 张联鑫
	[6400101] = true, -- 张联鑫
	[6400102] = true, -- 张联鑫
	[6400104] = true, -- 张联鑫
	[6400105] = true, -- 闫菲
	[6400106] = true, -- 闫菲
	[6400108] = true, -- 张联鑫
	[6400111] = true, -- 张联鑫
	[6400115] = true, -- 张联鑫
	[6400116] = true, -- 张联鑫
	[6400117] = true, -- 张联鑫
	[6400120] = true, -- 张联鑫
	[6400121] = true, -- 张联鑫
	[6400126] = true, -- 张联鑫
	[6400127] = true, -- 张联鑫
	[6400128] = true, -- 张联鑫
	[6400129] = true, -- 张联鑫
	[6400132] = true, -- 张联鑫
	[6400133] = true, -- 张联鑫
	[6400134] = true, -- 张联鑫
	[6400135] = true, -- 张联鑫
	[6400136] = true, -- 张联鑫
	[6400143] = true, -- 张联鑫
	[6400144] = true, -- 张联鑫
	[6400145] = true, -- 张联鑫
	[6400155] = true, -- 张联鑫
	[6400161] = true, -- 张联鑫
	[6400162] = true, -- 张联鑫
	[6400163] = true, -- 张联鑫
	[6400165] = true, -- 张联鑫
	[6400166] = true, -- 张联鑫
	[6400171] = true, -- 张联鑫
	[6400175] = true, -- 张联鑫
	[6400176] = true, -- 张联鑫
	[6400177] = true, -- 张联鑫
	[6400181] = true, -- 张联鑫
	[6400182] = true, -- 北盟遗址-将军尸体旁置景宝箱
	[6400212] = true, -- 张联鑫
	[6400234] = true, -- 张联鑫
	[6400249] = true, -- 张联鑫
	[6500006] = true, -- 丁纪文
	[6500007] = true, -- 丁纪文
	[6500008] = true, -- 丁纪文
	[6500021] = true, -- 丁纪文
	[6500022] = true, -- 丁纪文
	[6500023] = true, -- 丁纪文
	[6500041] = true, -- 丁纪文
	[6500042] = true, -- 丁纪文
	[6500044] = true, -- 丁纪文
	[6500056] = true, -- 丁纪文
	[6500057] = true, -- 丁纪文
	[6500059] = true, -- 丁纪文
	[6500060] = true, -- 丁纪文
	[6500061] = true, -- 丁纪文
	[6500062] = true, -- 丁纪文
	[6500063] = true, -- 丁纪文
	[6500064] = true, -- 丁纪文
	[6500065] = true, -- 丁纪文
	[6500066] = true, -- 丁纪文
	[6500067] = true, -- 丁纪文
	[6500068] = true, -- 丁纪文
	[6500069] = true, -- 丁纪文
	[6500070] = true, -- 丁纪文
	[6500071] = true, -- 明皇御影花钱
	[6500072] = true, -- 丁纪文
	[6500073] = true, -- 丁纪文
	[6500074] = true, -- 丁纪文
	[6500075] = true, -- 丁纪文
	[6500076] = true, -- 丁纪文
	[6500089] = true, -- 丁纪文
	[6500095] = true, -- 丁纪文
	[6500125] = true, -- 丁纪文
	[6500212] = true, -- 丁纪文
	[6500213] = true, -- 丁纪文
	[6500330] = true, -- 袁国振
	[6500350] = true, -- 丁纪文
	[6500454] = true, -- 丁纪文
	[6500455] = true, -- 丁纪文
	[6500481] = true, -- 丁纪文
	[6500482] = true, -- 丁纪文
	[6510000] = true, -- 丁纪文
	[6510001] = true, -- 丁纪文
	[6510002] = true, -- 丁纪文
	[6510003] = true, -- 孙亦鸣
	[6510004] = true, -- 丁纪文
	[6510006] = true, -- 丁纪文
	[6510007] = true, -- 丁纪文
	[6510008] = true, -- 丁纪文
	[6510009] = true, -- 丁纪文
	[6510013] = true, -- 丁纪文
	[6510015] = true, -- 丁纪文
	[6510021] = true, -- 丁纪文
	[6510022] = true, -- 丁纪文
	[6510023] = true, -- 丁纪文
	[6510028] = true, -- 丁纪文
	[6510029] = true, -- 丁纪文
	[6510036] = true, -- 丁纪文
	[6510037] = true, -- 丁纪文
	[6510038] = true, -- 丁纪文
	[6510039] = true, -- 丁纪文
	[6510043] = true, -- 丁纪文
	[6510044] = true, -- 丁纪文
	[6510045] = true, -- 丁纪文
	[6510046] = true, -- 丁纪文
	[6510047] = true, -- 丁纪文
	[6510048] = true, -- 丁纪文
	[6510049] = true, -- 丁纪文
	[6510061] = true, -- 丁纪文
	[6510065] = true, -- 丁纪文
	[6510066] = true, -- 丁纪文
	[6510067] = true, -- 丁纪文
	[6510071] = true, -- 丁纪文
	[6510073] = true, -- 丁纪文
	[6510075] = true, -- 丁纪文
	[6510076] = true, -- 丁纪文
	[6510077] = true, -- 丁纪文
	[6510085] = true, -- 丁纪文
	[6510087] = true, -- 丁纪文
	[6511001] = true, -- 丁纪文
	[6511003] = true, -- 丁纪文
	[6511004] = true, -- 丁纪文
	[6511006] = true, -- 丁纪文
	[6511007] = true, -- 丁纪文
	[6511008] = true, -- 丁纪文
	[6511011] = true, -- 丁纪文
	[6511012] = true, -- 丁纪文
	[6511013] = true, -- 丁纪文
	[6600015] = true, -- 黄乐孳
	[6600016] = true, -- 黄乐孳
	[6600018] = true, -- 黄乐孳
	[6600019] = true, -- 黄乐孳
	[6600020] = true, -- 黄乐孳
	[6600022] = true, -- 黄乐孳
	[6600023] = true, -- 黄乐孳
	[6600026] = true, -- 黄乐孳
	[6600027] = true, -- 黄乐孳
	[6600030] = true, -- 黄乐孳
	[6600031] = true, -- 任宽
	[6600047] = true, -- 孙佳楠
	[6600048] = true, -- 黄乐孳
	[6600050] = true, -- 黄乐孳
	[6600058] = true, -- 黄乐孳
	[6600059] = true, -- 黄乐孳
	[6600060] = true, -- 黄乐孳
	[6600062] = true, -- 黄乐孳
	[6600063] = true, -- 黄乐孳
	[6600064] = true, -- 黄乐孳
	[6600065] = true, -- 黄乐孳
	[6600066] = true, -- 黄乐孳
	[6600067] = true, -- 黄乐孳
	[6600068] = true, -- 黄乐孳
	[6600076] = true, -- 黄乐孳
	[6600077] = true, -- 陈凯
	[6600079] = true, -- 黄乐孳
	[6600090] = true, -- 黄乐孳
	[6600091] = true, -- 黄乐孳
	[6600103] = true, -- 黄乐孳
	[6600104] = true, -- 黄乐孳
	[6600108] = true, -- 黄乐孳
	[6600109] = true, -- 黄乐孳
	[6600110] = true, -- 黄乐孳
	[6600111] = true, -- 黄乐孳
	[6600112] = true, -- 黄乐孳
	[6600113] = true, -- 黄乐孳
	[6600114] = true, -- 黄乐孳
	[6600116] = true, -- 黄乐孳
	[6600117] = true, -- 黄乐孳
	[6600118] = true, -- 黄乐孳
	[6600119] = true, -- 黄乐孳
	[6600120] = true, -- 黄乐孳
	[6600121] = true, -- 黄乐孳
	[6600122] = true, -- 黄乐孳
	[6600123] = true, -- 黄乐孳
	[6600143] = true, -- 黄乐孳
	[6600144] = true, -- 黄乐孳
	[6600145] = true, -- 黄乐孳
	[6600183] = true, -- 黄乐孳
	[6600184] = true, -- 黄乐孳
	[6600197] = true, -- 黄乐孳
	[6600198] = true, -- 黄乐孳
	[6600211] = true, -- 黄乐孳
	[6600225] = true, -- 黄乐孳
	[6600226] = true, -- 黄乐孳
	[6600481] = true, -- 徐佳琦
	[6600482] = true, -- 张俊杰
	[6600483] = true, -- 黄乐孳
	[6600484] = true, -- 黄乐孳
	[6600485] = true, -- 黄乐孳
	[6600486] = true, -- 黄乐孳
	[6600496] = true, -- 黄乐孳
	[6600497] = true, -- 黄乐孳
	[6600500] = true, -- 黄乐孳
	[6600501] = true, -- 黄乐孳
	[6600521] = true, -- 李晨
	[6600524] = true, -- 黄乐孳
	[6600525] = true, -- 猫_橙-不羡仙摸猫5
	[6600526] = true, -- 猫_橙-佛光顶摸猫1
	[6600527] = true, -- 猫_黑（狸花）-千佛谷摸猫
	[6600528] = true, -- 猫_白-佛光定摸猫2
	[6600529] = true, -- 白草野摸猫1
	[6600530] = true, -- 白草野摸猫3
	[6600531] = true, -- 白草野摸猫4
	[6600532] = true, -- 白草野摸猫5
	[6600533] = true, -- 白草野摸猫6
	[6600534] = true, -- 白草野摸猫7
	[6600535] = true, -- 白草野摸猫8
	[6600536] = true, -- 白草野摸猫9
	[6600537] = true, -- 听经猫1-摸猫
	[6600538] = true, -- 听经猫2-摸猫
	[6600539] = true, -- 听经猫3-摸猫
	[6600540] = true, -- 听经猫4-摸猫
	[6600541] = true, -- 听经猫5-摸猫
	[6600542] = true, -- 听经猫6-摸猫
	[6600543] = true, -- 善妙舟新猫4
	[6600544] = true, -- 善妙舟新猫5
	[6600545] = true, -- 黄乐孳
	[6600546] = true, -- 黄乐孳
	[6600646] = true, -- 黄乐孳
	[6600647] = true, -- 黄乐孳
	[6600732] = true, -- 黄乐孳
	[6600733] = true, -- 黄乐孳
	[6600734] = true, -- 黄乐孳
	[6600735] = true, -- 黄乐孳
	[6600736] = true, -- 黄乐孳
	[6600737] = true, -- 黄乐孳
	[6600738] = true, -- 黄乐孳
	[6600739] = true, -- 黄乐孳
	[6600741] = true, -- 黄乐孳
	[6600742] = true, -- 黄乐孳
	[6600743] = true, -- 黄乐孳
	[6600744] = true, -- 黄乐孳
	[6600745] = true, -- 黄乐孳
	[6600746] = true, -- 黄乐孳
	[6600766] = true, -- 黄乐孳
	[6601077] = true, -- 黄乐孳
	[6601082] = true, -- 黄乐孳
	[6601083] = true, -- 黄乐孳
	[6601084] = true, -- 黄乐孳
	[6601085] = true, -- 黄乐孳
	[6601086] = true, -- 黄乐孳
	[6601090] = true, -- 陈胜
	[6601094] = true, -- 黄乐孳
	[6601095] = true, -- 黄乐孳
	[6601096] = true, -- 黄乐孳
	[6601097] = true, -- 黄乐孳
	[6601098] = true, -- 黄乐孳
	[6601099] = true, -- 黄乐孳
	[6601100] = true, -- 黄乐孳
	[6601101] = true, -- 黄乐孳
	[6601102] = true, -- 黄乐孳
	[6601103] = true, -- 黄乐孳
	[6601104] = true, -- 黄乐孳
	[6601105] = true, -- 黄乐孳
	[6601106] = true, -- 黄乐孳
	[6601107] = true, -- 黄乐孳
	[6601150] = true, -- 黄乐孳
	[6601152] = true, -- 黄乐孳
	[6601167] = true, -- 黄乐孳
	[6601174] = true, -- 黄乐孳
	[6601223] = true, -- 黄乐孳
	[6601248] = true, -- 黄乐孳
	[6601249] = true, -- 黄乐孳
	[6601250] = true, -- 黄乐孳
	[6601251] = true, -- 黄乐孳
	[6601252] = true, -- 黄乐孳
	[6601253] = true, -- 黄乐孳
	[6601254] = true, -- 黄乐孳
	[6601255] = true, -- 黄乐孳
	[6601256] = true, -- 黄乐孳
	[6601257] = true, -- 黄乐孳
	[6601258] = true, -- 黄乐孳
	[6601259] = true, -- 黄乐孳
	[6601260] = true, -- 黄乐孳
	[6601261] = true, -- 黄乐孳
	[6601262] = true, -- 黄乐孳
	[6601263] = true, -- 黄乐孳
	[6601264] = true, -- 黄乐孳
	[6601265] = true, -- 黄乐孳
	[6601276] = true, -- 黄乐孳
	[6601277] = true, -- 黄乐孳
	[6601278] = true, -- 黄乐孳
	[6700001] = true, -- 偷师-无归-机关开关
	[6700004] = true, -- 俞立
	[6700205] = true, -- 俞立
	[6700206] = true, -- 俞立
	[6700207] = true, -- 俞立
	[6700209] = true, -- 俞立
	[6700214] = true, -- 俞立
	[6700215] = true, -- 俞立
	[6700220] = true, -- 俞立
	[6700221] = true, -- 俞立
	[6700222] = true, -- 俞立
	[6700225] = true, -- 俞立
	[6700226] = true, -- 俞立
	[6700227] = true, -- 俞立
	[6700232] = true, -- 俞立
	[6700235] = true, -- 俞立
	[6700236] = true, -- 俞立
	[6700246] = true, -- 俞立
	[6700339] = true, -- 俞立
	[6700407] = true, -- 俞立
	[6700416] = true, -- 俞立
	[6700459] = true, -- 俞立
	[6700465] = true, -- 俞立
	[6700486] = true, -- 俞立
	[6800026] = true, -- 刘铭册
	[6800027] = true, -- 李弘扬
	[6800029] = true, -- 李弘扬
	[6800081] = true, -- 李弘扬
	[6920002] = true, -- 田野
	[6920003] = true, -- 田野
	[6920004] = true, -- 田野
	[6920005] = true, -- 张联鑫
	[6920006] = true, -- 张联鑫
	[6920021] = true, -- 田野
	[6920023] = true, -- 田野
	[6920027] = true, -- 田野
	[6920034] = true, -- 田野
	[6920054] = true, -- 太仓粟平野原野怪大宋官兵B43
	[6920055] = true, -- 太仓粟平野原野怪大宋官兵B44
	[6920057] = true, -- 田野
	[6920058] = true, -- 田野
	[6920061] = true, -- 田野
	[6920062] = true, -- 田野
	[6920084] = true, -- 田野
	[6920085] = true, -- 田野
	[6920086] = true, -- 田野
	[6920087] = true, -- 田野
	[6920088] = true, -- 田野
	[6920089] = true, -- 田野
	[6920090] = true, -- 田野
	[6920091] = true, -- 田野
	[6920092] = true, -- 田野
	[6920093] = true, -- 田野
	[6920094] = true, -- 田野
	[6920095] = true, -- 田野
	[6920096] = true, -- 田野
	[6920097] = true, -- 田野
	[6920098] = true, -- 田野
	[6920099] = true, -- 田野
	[6920100] = true, -- 田野
	[6920101] = true, -- 田野
	[6920102] = true, -- 田野
	[6920103] = true, -- 田野
	[6920104] = true, -- 田野
	[6920105] = true, -- 田野
	[6920106] = true, -- 田野
	[6920107] = true, -- 田野
	[6920117] = true, -- 张俊杰
	[6920118] = true, -- 田野
	[6920122] = true, -- 田野
	[6920159] = true, -- 模板表
	[6920160] = true, -- 模板表
	[7100103] = true, -- 任宽
	[7100104] = true, -- 任宽
	[7100200] = true, -- 任宽
	[7100203] = true, -- 任宽
	[7100205] = true, -- 任宽
	[7100207] = true, -- 任宽
	[7100211] = true, -- 任宽
	[7100212] = true, -- 任宽
	[7100213] = true, -- 任宽
	[7100214] = true, -- 任宽
	[7100215] = true, -- 任宽
	[7100217] = true, -- 任宽
	[7100219] = true, -- 任宽
	[7100220] = true, -- 任宽
	[7100222] = true, -- 任宽
	[7100223] = true, -- 任宽
	[7100224] = true, -- 任宽
	[7100225] = true, -- 任宽
	[7100226] = true, -- 任宽
	[7100228] = true, -- 任宽
	[7100231] = true, -- 任宽
	[7100237] = true, -- 任宽
	[7100238] = true, -- 任宽
	[7100239] = true, -- 任宽
	[7100240] = true, -- 任宽
	[7100241] = true, -- 任宽
	[7100243] = true, -- 任宽
	[7100244] = true, -- 任宽
	[7100245] = true, -- 任宽
	[7100246] = true, -- 任宽
	[7100250] = true, -- 任宽
	[7102002] = true, -- 任宽
	[7102007] = true, -- 任宽
	[7102018] = true, -- 任宽
	[7102020] = true, -- 任宽
	[7102065] = true, -- 任宽
	[7102067] = true, -- 任宽
	[7102076] = true, -- 任宽
	[7102094] = true, -- 任宽
	[7102095] = true, -- 任宽
	[7102101] = true, -- 任宽
	[7102102] = true, -- 任宽
	[7102103] = true, -- 任宽
	[7102104] = true, -- 任宽
	[7102106] = true, -- 任宽
	[7102109] = true, -- 任宽
	[7102110] = true, -- 任宽
	[7102116] = true, -- 任宽
	[7102117] = true, -- 任宽
	[7102119] = true, -- 任宽
	[7102121] = true, -- 任宽
	[7102122] = true, -- 任宽
	[7102123] = true, -- 任宽
	[7102127] = true, -- 任宽
	[7103029] = true, -- 任宽
	[7200001] = true, -- 李嘉栋
	[7200004] = true, -- 李嘉栋
	[7200005] = true, -- 李嘉栋
	[7200007] = true, -- 李嘉栋
	[7200038] = true, -- 李嘉栋
	[7200039] = true, -- 李嘉栋
	[7200045] = true, -- 李嘉栋
	[7200051] = true, -- 李嘉栋
	[7200054] = true, -- 李嘉栋
	[7200055] = true, -- 李嘉栋
	[7200059] = true, -- 李嘉栋
	[7200060] = true, -- 李嘉栋
	[7200061] = true, -- 李嘉栋
	[7200062] = true, -- 李嘉栋
	[7200071] = true, -- 李嘉栋
	[7200072] = true, -- 李嘉栋
	[7200091] = true, -- 李嘉栋
	[7200092] = true, -- 李嘉栋
	[7200093] = true, -- 李嘉栋
	[7200095] = true, -- 李嘉栋
	[7200096] = true, -- 李嘉栋
	[7200098] = true, -- 李嘉栋
	[7200102] = true, -- 李嘉栋
	[7200103] = true, -- 李嘉栋
	[7200104] = true, -- 李嘉栋
	[7200105] = true, -- 李嘉栋
	[7200106] = true, -- 李嘉栋
	[7200182] = true, -- 李嘉栋
	[7200214] = true, -- 李嘉栋
	[7200221] = true, -- 李嘉栋
	[7200229] = true, -- 李嘉栋
	[7200405] = true, -- 李嘉栋
	[7200408] = true, -- 李嘉栋
	[7200409] = true, -- 李嘉栋
	[7200503] = true, -- 李嘉栋
	[7200507] = true, -- 李嘉栋
	[7200509] = true, -- 李嘉栋
	[7200511] = true, -- 李嘉栋
	[7200512] = true, -- 李嘉栋
	[7200513] = true, -- 李嘉栋
	[7200514] = true, -- 李嘉栋
	[7200515] = true, -- 李嘉栋
	[7200516] = true, -- 李嘉栋
	[7200517] = true, -- 李嘉栋
	[7200518] = true, -- 李嘉栋
	[7200519] = true, -- 李嘉栋
	[7200520] = true, -- 李嘉栋
	[7200521] = true, -- 李嘉栋
	[7200526] = true, -- 李嘉栋
	[7300002] = true, -- 王思越
	[7300003] = true, -- 王思越
	[7300004] = true, -- 王思越
	[7300005] = true, -- 王思越
	[7300009] = true, -- 王思越
	[7400003] = true, -- 周雨霖
	[7400011] = true, -- 周雨霖
	[7400032] = true, -- 周雨霖
	[7400034] = true, -- 周雨霖
	[7400045] = true, -- 周雨霖
	[7400050] = true, -- 周雨霖
	[7400051] = true, -- 周雨霖
	[7400056] = true, -- 周雨霖
	[7400059] = true, -- 徐佳琦
	[7410029] = true, -- 周雨霖
	[7410081] = true, -- 万事知-画像
	[7410082] = true, -- 万事知-钱袋
	[7410083] = true, -- 万事知-平安福
	[7420143] = true, -- 周雨霖
	[7420145] = true, -- 周雨霖
	[7420147] = true, -- 周雨霖
	[7420158] = true, -- 周雨霖
	[7420159] = true, -- 周雨霖
	[7420160] = true, -- 周雨霖
	[7420161] = true, -- 周雨霖
	[7420162] = true, -- 周雨霖
	[7420163] = true, -- 周雨霖
	[7420164] = true, -- 周雨霖
	[7440026] = true, -- 任宽
	[7440036] = true, -- 周雨霖
	[7450110] = true, -- 周雨霖
	[7450115] = true, -- 周雨霖
	[7450116] = true, -- 周雨霖
	[7450117] = true, -- 周雨霖
	[7450118] = true, -- 周雨霖
	[7450119] = true, -- 周雨霖
	[7450175] = true, -- 周雨霖
	[7450176] = true, -- 周雨霖
	[7450177] = true, -- 周雨霖
	[7450178] = true, -- 周雨霖
	[7450179] = true, -- 周雨霖
	[7470018] = true, -- 周雨霖
	[7470045] = true, -- 周雨霖
	[7470046] = true, -- 周雨霖
	[7600004] = true, -- 竺頔
	[7600008] = true, -- 竺頔
	[7600009] = true, -- 竺頔
	[7600014] = true, -- 竺頔
	[7600016] = true, -- 竺頔
	[7600018] = true, -- 竺頔
	[7600023] = true, -- 竺頔
	[7600031] = true, -- 竺頔
	[7600040] = true, -- 竺頔
	[7600041] = true, -- 竺頔
	[7600042] = true, -- 竺頔
	[7600057] = true, -- 竺頔
	[7600058] = true, -- 竺頔
	[7600062] = true, -- 竺頔
	[7600063] = true, -- 竺頔
	[7600064] = true, -- 竺頔
	[7600067] = true, -- 竺頔
	[7600068] = true, -- 竺頔
	[7600073] = true, -- 竺頔
	[7600075] = true, -- 竺頔
	[7600076] = true, -- 竺頔
	[7600077] = true, -- 竺頔
	[7600078] = true, -- 竺頔
	[7600079] = true, -- 竺頔
	[7600081] = true, -- 华中承
	[7600084] = true, -- 竺頔
	[7600087] = true, -- 孙浩声
	[7600088] = true, -- 竺頔
	[7600089] = true, -- 竺頔
	[7600091] = true, -- 竺頔
	[7600092] = true, -- 竺頔
	[7600094] = true, -- 竺頔
	[7600095] = true, -- 竺頔
	[7600098] = true, -- 竺頔
	[7600099] = true, -- 竺頔
	[7600100] = true, -- 竺頔
	[7600101] = true, -- 胡健力
	[7600108] = true, -- 竺頔
	[7710006] = true, -- 郭宇昂
	[7710017] = true, -- 郭宇昂
	[7720008] = true, -- 郭宇昂
	[7720012] = true, -- 郭宇昂
	[7720017] = true, -- 郭宇昂
	[7720018] = true, -- 郭宇昂
	[7720019] = true, -- 郭宇昂
	[7720022] = true, -- 郭宇昂
	[7720023] = true, -- 郭宇昂
	[7720024] = true, -- 郭宇昂
	[7720025] = true, -- 郭宇昂
	[7720026] = true, -- 郭宇昂
	[7720027] = true, -- 郭宇昂
	[7720028] = true, -- 郭宇昂
	[7720029] = true, -- 郭宇昂
	[7900335] = true, -- 何纪希
	[7900336] = true, -- 何纪希
	[7900337] = true, -- 何纪希
	[7900338] = true, -- 何纪希
	[7900339] = true, -- 何纪希
	[7900340] = true, -- 何纪希
	[7900590] = true, -- 何纪希
	[7900591] = true, -- 何纪希
	[7900592] = true, -- 何纪希
	[7910011] = true, -- 何纪希
	[7910021] = true, -- 何纪希
	[7910022] = true, -- 何纪希
	[7910023] = true, -- 何纪希
	[7910024] = true, -- 何纪希
	[7910025] = true, -- 何纪希
	[7910026] = true, -- 何纪希
	[7910027] = true, -- 何纪希
	[7910028] = true, -- 何纪希
	[7910030] = true, -- 何纪希
	[7910032] = true, -- 何纪希
	[7910035] = true, -- 何纪希
	[7910036] = true, -- 何纪希
	[7910037] = true, -- 何纪希
	[7910038] = true, -- 何纪希
	[7910042] = true, -- 何纪希
	[7910043] = true, -- 何纪希
	[7910048] = true, -- 曹涵松
	[7920058] = true, -- 何纪希
	[7920061] = true, -- 周雨霖
	[7920065] = true, -- 何纪希
	[7920066] = true, -- 何纪希
	[7940001] = true, -- 万事知-围罛
	[7940002] = true, -- 万事知-荼蘼花签
	[7940003] = true, -- 万事知-美人皮影
	[7940004] = true, -- 万事知-梅花丸
	[7940013] = true, -- 何纪希
	[7940014] = true, -- 何纪希
	[7940015] = true, -- 何纪希
	[7940016] = true, -- 何纪希
	[7940020] = true, -- 何纪希
	[7940026] = true, -- 何纪希
	[7940027] = true, -- 何纪希
	[7940028] = true, -- 何纪希
	[7940029] = true, -- 何纪希
	[7940030] = true, -- 何纪希
	[7940031] = true, -- 何纪希
	[7940032] = true, -- 何纪希
	[7940033] = true, -- 何纪希
	[7940034] = true, -- 何纪希
	[7940035] = true, -- 何纪希
	[7940036] = true, -- 何纪希
	[7940037] = true, -- 何纪希
	[7940038] = true, -- 何纪希
	[7940039] = true, -- 何纪希
	[7940041] = true, -- 何纪希
	[7940043] = true, -- 何纪希
	[7940044] = true, -- 何纪希
	[7940045] = true, -- 何纪希
	[7940046] = true, -- 何纪希
	[7940047] = true, -- 何纪希
	[7940053] = true, -- 何纪希
	[7940054] = true, -- 何纪希
	[7940055] = true, -- 何纪希
	[7940056] = true, -- 何纪希
	[7940057] = true, -- 何纪希
	[7950057] = true, -- 何纪希
	[7950058] = true, -- 何纪希
	[7950059] = true, -- 何纪希
	[7950143] = true, -- 何纪希
	[8000025] = true, -- 欧嘉昊
	[8000032] = true, -- 欧嘉昊
	[8000033] = true, -- 欧嘉昊
	[8000053] = true, -- 欧嘉昊
	[8000054] = true, -- 欧嘉昊
	[8000055] = true, -- 欧嘉昊
	[8000056] = true, -- 欧嘉昊
	[8000057] = true, -- 欧嘉昊
	[8000058] = true, -- 欧嘉昊
	[8000140] = true, -- 欧嘉昊
	[8000151] = true, -- 欧嘉昊
	[8000198] = true, -- 欧嘉昊
	[8000199] = true, -- 欧嘉昊
	[8000200] = true, -- 欧嘉昊
	[8000201] = true, -- 欧嘉昊
	[8000202] = true, -- 欧嘉昊
	[8000203] = true, -- 欧嘉昊
	[8000215] = true, -- 欧嘉昊
	[8000216] = true, -- 欧嘉昊
	[8000218] = true, -- 欧嘉昊
	[8000232] = true, -- 欧嘉昊
	[8000250] = true, -- 欧嘉昊
	[8000251] = true, -- 欧嘉昊
	[8000252] = true, -- 欧嘉昊
	[8000254] = true, -- 欧嘉昊
	[8000255] = true, -- 欧嘉昊
	[8000256] = true, -- 欧嘉昊
	[8000280] = true, -- 欧嘉昊
	[8000282] = true, -- 欧嘉昊
	[8000283] = true, -- 欧嘉昊
	[8000284] = true, -- 欧嘉昊
	[8000286] = true, -- 欧嘉昊
	[8000288] = true, -- 欧嘉昊
	[8000312] = true, -- 欧嘉昊
	[8000322] = true, -- 欧嘉昊
	[8000333] = true, -- 欧嘉昊
	[8000334] = true, -- 欧嘉昊
	[8000335] = true, -- 欧嘉昊
	[8000336] = true, -- 欧嘉昊
	[8000337] = true, -- 欧嘉昊
	[8000338] = true, -- 欧嘉昊
	[8000339] = true, -- 欧嘉昊
	[8000340] = true, -- 欧嘉昊
	[8000341] = true, -- 欧嘉昊
	[8000342] = true, -- 欧嘉昊
	[8000356] = true, -- 欧嘉昊
	[8000357] = true, -- 欧嘉昊
	[8000358] = true, -- 欧嘉昊
	[8000359] = true, -- 欧嘉昊
	[8000360] = true, -- 欧嘉昊
	[8000362] = true, -- 欧嘉昊
	[8000419] = true, -- 欧嘉昊
	[8000422] = true, -- 欧嘉昊
	[8100001] = true, -- 张震
	[8100002] = true, -- 张震
	[8100005] = true, -- 张震
	[8100023] = true, -- 张震
	[8100031] = true, -- 张震
	[8100032] = true, -- 张震
	[8100033] = true, -- 张震
	[8100034] = true, -- 张震
	[8100037] = true, -- 张震
	[8100040] = true, -- 张震
	[8100042] = true, -- 袁国振
	[8100045] = true, -- 张震
	[8100046] = true, -- 张震
	[8100048] = true, -- 张震
	[8100115] = true, -- 张俊杰
	[8100116] = true, -- 张俊杰
	[8100255] = true, -- 张震
	[8100309] = true, -- 张震
	[8100421] = true, -- 张震
	[8100422] = true, -- 张震
	[8100423] = true, -- 张震
	[8100424] = true, -- 张震
	[8100425] = true, -- 张震
	[8100447] = true, -- 张震
	[8100448] = true, -- 张震
	[8100449] = true, -- 张震
	[8100450] = true, -- 张震
	[8100451] = true, -- 张震
	[8100501] = true, -- 星垣1转转乐
	[8100502] = true, -- 星垣1转转乐
	[8100503] = true, -- 星垣1转转乐
	[8100504] = true, -- 星垣1转转乐
	[8100505] = true, -- 胡健力
	[8100506] = true, -- 张震
	[8100507] = true, -- 张震
	[8100509] = true, -- 星垣2转转乐
	[8100510] = true, -- 星垣2转转乐
	[8100511] = true, -- 星垣2转转乐
	[8100512] = true, -- 星垣2转转乐
	[8100513] = true, -- 星垣3转转乐
	[8100514] = true, -- 星垣3转转乐
	[8100515] = true, -- 星垣3转转乐
	[8100516] = true, -- 星垣3转转乐
	[8100518] = true, -- 张震
	[8100543] = true, -- 张俊杰
	[8100544] = true, -- 胡健力
	[8102070] = true, -- 胡健力
	[8102071] = true, -- 胡健力
	[8200009] = true, -- 林野
	[8200012] = true, -- 林野
	[8200013] = true, -- 林野
	[8200014] = true, -- 林野
	[8200015] = true, -- 林野
	[8200016] = true, -- 林野
	[8200022] = true, -- 林野
	[8200023] = true, -- 林野
	[8200024] = true, -- 林野
	[8200025] = true, -- 林野
	[8200026] = true, -- 林野
	[8200028] = true, -- 林野
	[8200030] = true, -- 林野
	[8200031] = true, -- 林野
	[8200032] = true, -- 林野
	[8200034] = true, -- 林野
	[8200035] = true, -- 林野
	[8200036] = true, -- 林野
	[8200037] = true, -- 林野
	[8200039] = true, -- 林野
	[8200041] = true, -- 林野
	[8200042] = true, -- 林野
	[8200045] = true, -- 林野
	[8300007] = true, -- 万斌
	[8300008] = true, -- 万斌
	[8300009] = true, -- 万斌
	[8300014] = true, -- 万斌
	[8300020] = true, -- 万斌
	[8400082] = true, -- 孙浚凯
	[8500031] = true, -- 李晨
	[8500032] = true, -- 李晨
	[8500033] = true, -- 李晨
	[8500034] = true, -- 李晨
	[8500035] = true, -- 李晨
	[8500036] = true, -- 李晨
	[8500037] = true, -- 李晨
	[8500038] = true, -- 李晨
	[8500055] = true, -- 李晨
	[8900219] = true, -- 杨梦洁
	[9000112] = true, -- 开封主线
	[10000004] = true, -- 蒙名恒
	[10000035] = true, -- 蒙名恒
	[10000081] = true, -- 蒙名恒
	[10000116] = true, -- 蒙名恒
	[10000134] = true, -- 蒙名恒
	[10000138] = true, -- 蒙名恒
	[10000140] = true, -- 蒙名恒
	[10000141] = true, -- 蒙名恒
	[10000143] = true, -- 蒙名恒
	[10000180] = true, -- 蒙名恒
	[10000181] = true, -- 蒙名恒
	[10000284] = true, -- 蒙名恒
	[10200105] = true, -- 刘鹏程
	[10200149] = true, -- 刘鹏程
	[11500056] = true, -- 雷淞雯
	[11500057] = true, -- 雷淞雯
	[11500058] = true, -- 雷淞雯
	[12800038] = true, -- 张星翼
	[12800045] = true, -- 张星翼
	[12800052] = true, -- 张星翼
	[12800053] = true, -- 张星翼
	[12800054] = true, -- 张星翼
	[13100162] = true, -- 李泽昊
	[13100170] = true, -- 李泽昊
	[13100200] = true, -- 李泽昊
	[13100208] = true, -- 李泽昊
	[13100209] = true, -- 李泽昊
	[13100210] = true, -- 李泽昊
	[13100217] = true, -- 李泽昊
	[13101303] = true, -- 李泽昊
	[13101306] = true, -- 李泽昊
	[13101309] = true, -- 李泽昊
	[13101316] = true, -- 李泽昊
	[13101320] = true, -- 李泽昊
	[13101332] = true, -- 李泽昊
	[13101338] = true, -- 李泽昊
	[13101339] = true, -- 李泽昊
	[13101457] = true, -- 李泽昊
	[13110067] = true, -- 李佳颖
	[13110068] = true, -- 李佳颖
	[13110075] = true, -- 李佳颖
	[14000011] = true, -- 刘铭册
	[14000012] = true, -- 刘铭册
	[14000013] = true, -- 刘铭册
	[14000016] = true, -- 刘铭册
	[14000017] = true, -- 刘铭册
	[14000018] = true, -- 刘铭册
	[14000021] = true, -- 刘铭册
	[14000027] = true, -- 刘铭册
	[14000028] = true, -- 刘铭册
	[14000029] = true, -- 刘铭册
	[14000035] = true, -- 刘铭册
	[14001211] = true, -- 夜修罗
	[14001270] = true, -- 刘铭册
	[14001271] = true, -- 大侠试炼-马车
	[14002072] = true, -- 刘铭册
	[14002482] = true, -- 刘铭册
	[14003129] = true, -- 刘铭册
	[14003130] = true, -- 刘铭册
	[14003131] = true, -- 刘铭册
	[14003170] = true, -- 寿昌坊-老年乐团交互
	[14003778] = true, -- 刘铭册
	[15600027] = true, -- 虞峰镔
	[15600077] = true, -- 虞峰镔
	[15600098] = true, -- 虞峰镔
	[15600104] = true, -- 虞峰镔
	[15600106] = true, -- 虞峰镔
	[15600128] = true, -- 虞峰镔
	[15600130] = true, -- 虞峰镔
	[15600132] = true, -- 虞峰镔
	[15600133] = true, -- 虞峰镔
	[15600134] = true, -- 虞峰镔
	[15600141] = true, -- 虞峰镔
	[15700266] = true, -- 齐毅恒
	[15700267] = true, -- 齐毅恒
	[15700284] = true, -- 齐毅恒
	[15700365] = true, -- 齐毅恒
	[15700374] = true, -- 齐毅恒
	[15700375] = true, -- 齐毅恒
	[15700377] = true, -- 齐毅恒
	[15800032] = true, -- 陈凯
	[15900013] = true, -- 凌志坚
	[15900014] = true, -- 凌志坚
	[15900015] = true, -- 凌志坚
	[15900016] = true, -- 凌志坚
	[15900101] = true, -- 凌志坚
	[15900102] = true, -- 凌志坚
	[15900104] = true, -- 凌志坚
	[15900105] = true, -- 凌志坚
	[15900106] = true, -- 凌志坚
	[15900107] = true, -- 凌志坚
	[15900108] = true, -- 凌志坚
	[15900109] = true, -- 凌志坚
	[15900110] = true, -- 凌志坚
	[15900114] = true, -- 凌志坚
	[16000000] = true, -- 袁闵鸿皓
	[16000001] = true, -- 袁闵鸿皓
	[16000002] = true, -- 袁闵鸿皓
	[16000003] = true, -- 袁闵鸿皓
	[16000004] = true, -- 袁闵鸿皓
	[16000005] = true, -- 袁闵鸿皓
	[16000006] = true, -- 袁闵鸿皓
	[16000007] = true, -- 袁闵鸿皓
	[16000008] = true, -- 袁闵鸿皓
	[16000009] = true, -- 袁闵鸿皓
	[16000010] = true, -- 袁闵鸿皓
	[16000011] = true, -- 袁闵鸿皓
	[16000012] = true, -- 袁闵鸿皓
	[16000013] = true, -- 袁闵鸿皓
	[16000014] = true, -- 袁闵鸿皓
	[16000015] = true, -- 袁闵鸿皓
	[16000016] = true, -- 袁闵鸿皓
	[16000034] = true, -- 袁闵鸿皓
	[16001065] = true, -- 王震宇
	[18000008] = true, -- 任众
	[18000015] = true, -- 袁权炜
	[19001118] = true, -- 仇金翰
	[19001119] = true, -- 羽绒草-藤蔓墙2-挡路
	[19001127] = true, -- 仇金翰
	[19002000] = true, -- 仇金翰
	[19002001] = true, -- 仇金翰
	[19002002] = true, -- 仇金翰
	[19002003] = true, -- 仇金翰
	[19002004] = true, -- 仇金翰
	[19002005] = true, -- 田野
	[19002007] = true, -- 仇金翰
	[19002015] = true, -- 仇金翰
	[19002021] = true, -- 仇金翰
	[19002022] = true, -- 仇金翰
	[19002023] = true, -- 仇金翰
	[19002025] = true, -- 仇金翰
	[19002041] = true, -- 张益豪
	[20000004] = true, -- 李子晨
	[21000234] = true, -- 张懿
	[21000235] = true, -- 张懿
	[21000236] = true, -- 张懿
	[21000238] = true, -- 张懿
	[21000239] = true, -- 张懿
	[21000421] = true, -- 张懿
	[21000423] = true, -- 张懿
	[21000426] = true, -- 张懿
	[23000449] = true, -- 王治
	[23000600] = true, -- 欧嘉昊
	[23000601] = true, -- 欧嘉昊
	[23000603] = true, -- 欧嘉昊
	[23000604] = true, -- 欧嘉昊
	[23000605] = true, -- 欧嘉昊
	[23000606] = true, -- 欧嘉昊
	[23000607] = true, -- 欧嘉昊
	[23000608] = true, -- 欧嘉昊
	[23000609] = true, -- 欧嘉昊
	[23000610] = true, -- 欧嘉昊
	[23000620] = true, -- 欧嘉昊
	[23000621] = true, -- 欧嘉昊
	[23000622] = true, -- 欧嘉昊
	[23000623] = true, -- 欧嘉昊
	[23000624] = true, -- 欧嘉昊
	[23000625] = true, -- 欧嘉昊
	[23000626] = true, -- 欧嘉昊
	[23000627] = true, -- 欧嘉昊
	[23000628] = true, -- 欧嘉昊
	[23000629] = true, -- 欧嘉昊
	[23000630] = true, -- 欧嘉昊
	[24003065] = true, -- 张筱诺
	[29000001] = true, -- 张余熙
	[29000011] = true, -- 张余熙
	[29000012] = true, -- 张余熙
	[29000013] = true, -- 张余熙
	[29000016] = true, -- 张余熙
	[29000017] = true, -- 张余熙
	[29000046] = true, -- 张余熙
	[29000047] = true, -- 张余熙
	[29000048] = true, -- 张余熙
	[29000049] = true, -- 张余熙
	[29000050] = true, -- 张余熙
	[29000051] = true, -- 张余熙
	[29000079] = true, -- 张余熙
	[29000085] = true, -- 张余熙
	[29000102] = true, -- 张余熙
	[31000007] = true, -- 寿焓宇
	[31000008] = true, -- 寿焓宇
	[31000009] = true, -- 寿焓宇
	[31000010] = true, -- 寿焓宇
	[32000066] = true, -- 曹雨虹
	[32000067] = true, -- 曹雨虹
	[32000286] = true, -- 曹雨虹
	[32000287] = true, -- 曹雨虹
	[32000288] = true, -- 曹雨虹
	[32000289] = true, -- 曹雨虹
	[32000291] = true, -- 曹雨虹
	[33000040] = true, -- 林文杰
	[33000042] = true, -- 林文杰
	[33000054] = true, -- 林文杰
	[33000055] = true, -- 林文杰
	[33000057] = true, -- 林文杰
	[33000058] = true, -- 林文杰
	[33000066] = true, -- 林文杰
	[33000067] = true, -- 林文杰
	[33000068] = true, -- 林文杰
	[33000069] = true, -- 林文杰
	[33000070] = true, -- 林文杰
	[33000101] = true, -- 林文杰
	[33000102] = true, -- 林文杰
	[33000103] = true, -- 林文杰
	[33000104] = true, -- 林文杰
	[33000105] = true, -- 林文杰
	[33000106] = true, -- 林文杰
	[33000107] = true, -- 林文杰
	[33000108] = true, -- 林文杰
	[33000109] = true, -- 林文杰
	[33000110] = true, -- 林文杰
	[33000111] = true, -- 林文杰
	[33000112] = true, -- 林文杰
	[33000113] = true, -- 林文杰
	[33000114] = true, -- 林文杰
	[33000115] = true, -- 林文杰
	[33000116] = true, -- 林文杰
	[33000117] = true, -- 林文杰
	[33000118] = true, -- 林文杰
	[33000119] = true, -- 林文杰
	[33000120] = true, -- 林文杰
	[33000121] = true, -- 林文杰
	[33000122] = true, -- 林文杰
	[33000123] = true, -- 林文杰
	[33000124] = true, -- 林文杰
	[33000125] = true, -- 林文杰
	[33000126] = true, -- 林文杰
	[33000127] = true, -- 林文杰
	[33000128] = true, -- 林文杰
	[33000129] = true, -- 林文杰
	[33000225] = true, -- 林文杰
	[33000241] = true, -- 林文杰
	[33000274] = true, -- 林文杰
	[34000007] = true, -- 陈晓翰
	[34000011] = true, -- 陈晓翰
	[34000044] = true, -- 陈晓翰
	[34000065] = true, -- 陈晓翰
	[34000074] = true, -- 何纪希
	[34000258] = true, -- 陈晓翰
	[34000259] = true, -- 陈晓翰
	[34000260] = true, -- 陈晓翰
	[34000261] = true, -- 陈晓翰
	[34000342] = true, -- 陈晓翰
	[34000345] = true, -- 陈晓翰
	[34000346] = true, -- 陈晓翰
	[34000347] = true, -- 陈晓翰
	[34000348] = true, -- 陈晓翰
	[34000359] = true, -- 陈晓翰
	[34000360] = true, -- 陈晓翰
	[34000361] = true, -- 陈晓翰
	[34000362] = true, -- 陈晓翰
	[34000424] = true, -- 陈晓翰
	[35000006] = true, -- 耿赟
	[35000012] = true, -- 耿赟
	[35000013] = true, -- 耿赟
	[35000014] = true, -- 耿赟
	[35000017] = true, -- 耿赟
	[35000018] = true, -- 耿赟
	[35000020] = true, -- 耿赟
	[35000021] = true, -- 耿赟
	[35000023] = true, -- 耿赟
	[35000039] = true, -- 耿赟
	[35000040] = true, -- 耿赟
	[35000041] = true, -- 耿赟
	[35000051] = true, -- 耿赟
	[35000052] = true, -- 耿赟
	[35000053] = true, -- 耿赟
	[35000056] = true, -- 耿赟
	[35000057] = true, -- 耿赟
	[35000058] = true, -- 耿赟
	[35000060] = true, -- 耿赟
	[35000061] = true, -- 耿赟
	[35000062] = true, -- 耿赟
	[35000063] = true, -- 耿赟
	[35000064] = true, -- 耿赟
	[35000065] = true, -- 丁纪文
	[35000067] = true, -- 宝箱
	[35000072] = true, -- 耿赟
	[35000077] = true, -- 耿赟
	[35000078] = true, -- 耿赟
	[35000079] = true, -- 耿赟
	[35000081] = true, -- 耿赟
	[35000082] = true, -- 耿赟
	[35000084] = true, -- 耿赟
	[35000085] = true, -- 耿赟
	[35000086] = true, -- 耿赟
	[35000088] = true, -- 耿赟
	[35000089] = true, -- 耿赟
	[35000091] = true, -- 耿赟
	[35000092] = true, -- 耿赟
	[35000093] = true, -- 耿赟
	[35000094] = true, -- 耿赟
	[35000095] = true, -- 耿赟
	[35000096] = true, -- 耿赟
	[35000097] = true, -- 耿赟
	[35000098] = true, -- 何纪希
	[35000100] = true, -- 耿赟
	[35000105] = true, -- 耿赟
	[35000119] = true, -- 耿赟
	[35000120] = true, -- 耿赟
	[35000121] = true, -- 耿赟
	[35000122] = true, -- 耿赟
	[35000126] = true, -- 耿赟
	[35000127] = true, -- 耿赟
	[35000128] = true, -- 耿赟
	[35000129] = true, -- 耿赟
	[35000130] = true, -- 耿赟
	[35000131] = true, -- 耿赟
	[35000132] = true, -- 耿赟
	[35000133] = true, -- 耿赟
	[35000134] = true, -- 耿赟
	[35000135] = true, -- 耿赟
	[35000136] = true, -- 耿赟
	[35000138] = true, -- 耿赟
	[35000141] = true, -- 耿赟
	[35000143] = true, -- 任众
	[35000144] = true, -- 任众
	[35000145] = true, -- 任众
	[35000146] = true, -- 耿赟
	[35000149] = true, -- 耿赟
	[35000150] = true, -- 耿赟
	[35000151] = true, -- 耿赟
	[35000152] = true, -- 耿赟
	[35000153] = true, -- 耿赟
	[35000156] = true, -- 耿赟
	[35000157] = true, -- 耿赟
	[35000161] = true, -- 耿赟
	[35000162] = true, -- 耿赟
	[35000163] = true, -- 耿赟
	[35000164] = true, -- 耿赟
	[35000188] = true, -- 耿赟
	[35000199] = true, -- 竺頔
	[35000214] = true, -- 凌佳欣
	[35000217] = true, -- 任众
	[35000220] = true, -- 耿赟
	[36000014] = true, -- 张益豪
	[36000020] = true, -- 太仓粟东郊野怪绿林B19
	[36000021] = true, -- 太仓粟鹰愁岭野怪绿林B50
	[36000028] = true, -- 孙佳楠
	[38000000] = true, -- 梁栋
	[38000001] = true, -- 梁栋
	[38000011] = true, -- 梁栋
	[38000027] = true, -- 梁栋
	[38000029] = true, -- 梁栋
	[38000030] = true, -- 梁栋
	[38000032] = true, -- 梁栋
	[38000033] = true, -- 梁栋
	[38000034] = true, -- 梁栋
	[38000038] = true, -- 梁栋
	[38000102] = true, -- 梁栋
	[38000114] = true, -- 张益豪
	[38000115] = true, -- 张益豪
	[38000122] = true, -- 梁栋
	[38000125] = true, -- 梁栋
	[38000168] = true, -- 刘铭册
	[38000169] = true, -- 刘铭册
	[38000171] = true, -- 行政区-上朝-大宋官兵站岗
	[39000021] = true, -- 张俊杰
	[39000054] = true, -- 张俊杰
	[39000055] = true, -- 张俊杰
	[39000057] = true, -- 张俊杰
	[39000058] = true, -- 张俊杰
	[39000059] = true, -- 张俊杰
	[39000067] = true, -- 张俊杰
	[39000105] = true, -- 张俊杰
	[39000106] = true, -- 张益豪
	[39000107] = true, -- 张俊杰
	[39000108] = true, -- 张俊杰
	[39000119] = true, -- 张俊杰
	[39000120] = true, -- 张俊杰
	[39000121] = true, -- 张俊杰
	[39000122] = true, -- 张俊杰
	[39000124] = true, -- 张俊杰
	[39000125] = true, -- 张俊杰
	[39000126] = true, -- 张俊杰
	[39000127] = true, -- 田野
	[39000128] = true, -- 张俊杰
	[39000129] = true, -- 张俊杰
	[39000133] = true, -- 张俊杰
	[39000137] = true, -- 张俊杰
	[39000139] = true, -- 张俊杰
	[39000152] = true, -- 张俊杰
	[39000153] = true, -- 张俊杰
	[39000168] = true, -- 张俊杰
	[39000169] = true, -- 张俊杰
	[39000170] = true, -- 黄乐孳
	[39000171] = true, -- 张俊杰
	[39000172] = true, -- 张俊杰
	[39000173] = true, -- 张俊杰
	[39000175] = true, -- 模板表
	[39000176] = true, -- 模板表
	[39000177] = true, -- 模板表
	[39000205] = true, -- 张俊杰
	[42000051] = true, -- 张硕
	[42000068] = true, -- 张硕
	[42000081] = true, -- 张硕
	[42000082] = true, -- 张硕
	[42000085] = true, -- 张硕
	[42000086] = true, -- 张硕
	[42000100] = true, -- 张硕
	[42000101] = true, -- 张硕
	[42000107] = true, -- 张硕
	[42000108] = true, -- 张硕
	[42000118] = true, -- 张硕
	[42000121] = true, -- 张硕
	[42000122] = true, -- 张硕
	[42000123] = true, -- 张硕
	[42000124] = true, -- 张硕
	[42000127] = true, -- 张硕
	[42000128] = true, -- 张硕
	[42000129] = true, -- 张硕
	[42000130] = true, -- 张硕
	[42000132] = true, -- 张硕
	[42000135] = true, -- 张硕
	[42000138] = true, -- 张硕
	[42000145] = true, -- 张硕
	[42000146] = true, -- 张硕
	[42000147] = true, -- 张硕
	[42000148] = true, -- 张硕
	[42000149] = true, -- 张硕
	[42000150] = true, -- 张硕
	[42000151] = true, -- 张硕
	[42000152] = true, -- 张硕
	[42000153] = true, -- 张硕
	[42000154] = true, -- 张硕
	[42000155] = true, -- 张硕
	[42000156] = true, -- 张硕
	[42000158] = true, -- 张硕
	[42000159] = true, -- 张硕
	[42000160] = true, -- 张硕
	[42000161] = true, -- 张硕
	[42000162] = true, -- 张硕
	[42000167] = true, -- 张硕
	[42000168] = true, -- 张硕
	[42000178] = true, -- 张硕
	[42000179] = true, -- 张硕
	[43000015] = true, -- 管骏涛
	[43000016] = true, -- 管骏涛
	[43000018] = true, -- 管骏涛
	[43000019] = true, -- 管骏涛
	[43000020] = true, -- 管骏涛
	[43000060] = true, -- 管骏涛
	[43000093] = true, -- 管骏涛
	[44000033] = true, -- 陆俊庆
	[44000034] = true, -- 陆俊庆
	[46000016] = true, -- 唐懿
	[49000002] = true, -- 陈实
	[49000160] = true, -- 陈实
	[49000196] = true, -- 陈实
	[57000202] = true, -- 陈胜
	[59000001] = true, -- 赵昊斐
	[60000121] = true, -- 吕佳男
	[60000128] = true, -- 吕佳男
	[60000412] = true, -- 吕佳男
	[60000413] = true, -- 吕佳男
	[60000414] = true, -- 吕佳男
	[60000416] = true, -- 吕佳男
	[60000423] = true, -- 吕佳男
	[60000449] = true, -- 吕佳男
	[60000450] = true, -- 吕佳男
	[60000451] = true, -- 吕佳男
	[60000452] = true, -- 吕佳男
	[60000453] = true, -- 吕佳男
	[60000464] = true, -- 吕佳男
	[60000473] = true, -- 张懿
	[60000475] = true, -- 吕佳男
	[60000488] = true, -- 吕佳男
	[60000489] = true, -- 吕佳男
	[60000521] = true, -- 吕佳男
	[60000550] = true, -- 吕佳男
	[60000551] = true, -- 吕佳男
	[60000564] = true, -- 吕佳男
	[60000565] = true, -- 吕佳男
	[60000566] = true, -- 吕佳男
	[60000591] = true, -- 吕佳男
	[60000609] = true, -- 吕佳男
	[60000615] = true, -- 吕佳男
	[60000618] = true, -- 吕佳男
	[60000621] = true, -- 吕佳男
	[60000629] = true, -- 吕佳男
	[60000630] = true, -- 吕佳男
	[60000631] = true, -- 吕佳男
	[60000635] = true, -- 吕佳男
	[60000637] = true, -- 吕佳男
	[61000002] = true, -- 曹涵松
	[61000003] = true, -- 模板表
	[61000004] = true, -- 仇金翰
	[61000009] = true, -- 仇金翰
	[61000010] = true, -- 竺頔
	[61000011] = true, -- 竺頔
	[61000012] = true, -- 曹涵松
	[66000009] = true, -- 任俊霖
	[66000017] = true, -- 任俊霖
	[66000093] = true, -- 任俊霖
	[66000094] = true, -- 任俊霖
	[66000095] = true, -- 任俊霖
	[66000096] = true, -- 任俊霖
	[66000128] = true, -- 任俊霖
	[66000130] = true, -- 任俊霖
	[66000131] = true, -- 任俊霖
	[66000132] = true, -- 任俊霖
	[66000134] = true, -- 任俊霖
	[66000135] = true, -- 任俊霖
	[66100051] = true, -- 任俊霖
	[66100052] = true, -- 任俊霖
	[66100054] = true, -- 任俊霖
	[66100055] = true, -- 王治
	[66100129] = true, -- 任俊霖
	[66100236] = true, -- 程龙亲友
	[66100237] = true, -- 程龙亲友
	[66100238] = true, -- 印刷-程龙围观2
	[66100239] = true, -- 印刷-程龙围观3
	[66100315] = true, -- 奋发实录·其一
	[66100316] = true, -- 奋发实录·其二
	[66100317] = true, -- 奋发实录·其三
	[66100318] = true, -- 学间哲思
	[66100319] = true, -- 墨山道门派记事·晋之卷
	[66100320] = true, -- 墨山道巨子札记·鹉
	[66100321] = true, -- 书本
	[66100322] = true, -- 书本
	[66100323] = true,
	[66100350] = true,
	[66100351] = true, -- 包袱
	[69000002] = true, -- 韦华栋
	[70000005] = true, -- 向茎格
	[70000064] = true, -- 向茎格
	[70000257] = true, -- 向茎格
	[70000263] = true, -- 王煊量
	[70000571] = true, -- 黄乐孳
	[70000855] = true, -- 向茎格
	[71000106] = true, -- 毛龙
	[71000107] = true, -- 毛龙
	[71000108] = true, -- 毛龙
	[71000109] = true, -- 毛龙
	[71000110] = true, -- 毛龙
	[71000111] = true, -- 毛龙
	[71000112] = true, -- 毛龙
	[71000113] = true, -- 毛龙
	[71000114] = true, -- 毛龙
	[71000115] = true, -- 毛龙
	[71000116] = true, -- 毛龙
	[71000117] = true, -- 毛龙
	[71000118] = true, -- 毛龙
	[71000119] = true, -- 毛龙
	[71000120] = true, -- 毛龙
	[71000130] = true, -- 毛龙
	[71000131] = true, -- 毛龙
	[71000132] = true, -- 毛龙
	[71000133] = true, -- 毛龙
	[71000135] = true, -- 毛龙
	[71000150] = true, -- 毛龙
	[71000151] = true, -- 毛龙
	[71000152] = true, -- 毛龙
	[71000153] = true, -- 毛龙
	[71000154] = true, -- 毛龙
	[71000155] = true, -- 毛龙
	[71000156] = true, -- 毛龙
	[71000157] = true, -- 毛龙
	[71000158] = true, -- 毛龙
	[71000159] = true, -- 毛龙
	[71000160] = true, -- 毛龙
	[71000161] = true, -- 毛龙
	[71000162] = true, -- 毛龙
	[71000163] = true, -- 毛龙
	[71000164] = true, -- 毛龙
	[71000165] = true, -- 毛龙
	[71000166] = true, -- 毛龙
	[71000216] = true, -- 毛龙
	[71000221] = true, -- 毛龙
	[71000222] = true, -- 毛龙
	[71000223] = true, -- 毛龙
	[77000000] = true, -- 王凯
	[88000038] = true, -- 张昊岳
	[89000002] = true, -- 魏子奥
	[89001000] = true, -- 郭宇昂
	[89001004] = true, -- 魏子奥
	[89001006] = true, -- 魏子奥
	[89001009] = true, -- 魏子奥
	[89001010] = true, -- 魏子奥
	[89001011] = true, -- 魏子奥
	[89001013] = true, -- 魏子奥
	[89001015] = true, -- 魏子奥
	[89001016] = true, -- 魏子奥
	[89001017] = true, -- 魏子奥
	[89001018] = true, -- 魏子奥
	[89001019] = true, -- 魏子奥
	[89001022] = true, -- 魏子奥
	[89001024] = true, -- 魏子奥
	[89001026] = true, -- 魏子奥
	[89001027] = true, -- 魏子奥
	[89001029] = true, -- 魏子奥
	[89001030] = true, -- 魏子奥
	[89001033] = true, -- 魏子奥
	[89001036] = true, -- 竺頔
	[89001038] = true, -- 魏子奥
	[89001039] = true, -- 魏子奥
	[89001040] = true, -- 魏子奥
	[89001041] = true, -- 蒙名恒
	[89001042] = true, -- 模板表
	[89001043] = true, -- 模板表
	[89001044] = true, -- 魏子奥
	[89001046] = true, -- 魏子奥
	[89001047] = true, -- 魏子奥
	[89001048] = true, -- 魏子奥
	[89001049] = true, -- 魏子奥
	[89001050] = true, -- 魏子奥
	[89001051] = true, -- 魏子奥
	[89001052] = true, -- 魏子奥
	[89001053] = true, -- 魏子奥
	[89001054] = true, -- 魏子奥
	[89001055] = true, -- 魏子奥
	[89001056] = true, -- 魏子奥
	[89001057] = true, -- 魏子奥
	[89001058] = true, -- 魏子奥
	[89001060] = true, -- 魏子奥
	[89001061] = true, -- 魏子奥
	[89001062] = true, -- 魏子奥
	[89001065] = true, -- 魏子奥
	[89001066] = true, -- 魏子奥
	[89001067] = true, -- 魏子奥
	[89001069] = true, -- 宝箱
	[89001070] = true, -- 宝箱
	[89001071] = true, -- 宝箱
	[89001072] = true, -- 魏子奥
	[89001073] = true, -- 宝箱
	[89001074] = true, -- 宝箱
	[89001075] = true, -- 宝箱
	[89001076] = true, -- 林野
	[89001081] = true, -- 魏子奥
	[89001082] = true, -- 魏子奥
	[89001083] = true, -- 魏子奥
	[89001084] = true, -- 魏子奥
	[89001085] = true, -- 魏子奥
	[89001098] = true, -- 魏子奥
	[89001099] = true, -- 魏子奥
	[89001100] = true, -- 魏子奥
	[89001101] = true, -- 魏子奥
	[89001104] = true, -- 魏子奥
	[89001105] = true, -- 魏子奥
	[89001106] = true, -- 魏子奥
	[89001107] = true, -- 魏子奥
	[89001108] = true, -- 魏子奥
	[89001109] = true, -- 魏子奥
	[89001110] = true, -- 魏子奥
	[90000093] = true, -- 王蔺景
	[94000086] = true, -- 刘飘扬
	[110000015] = true, -- 王靖博
	[110000032] = true, -- 王靖博
	[120000176] = true, -- 生态物种
	[120000197] = true, -- 生态物种
	[120000198] = true, -- 生态物种
	[120000201] = true, -- 刘铭册
	[120000202] = true, -- 刘铭册
	[120000204] = true, -- 生态物种
	[120000206] = true, -- 生态物种
	[120000212] = true, -- 生态物种
	[120000213] = true, -- 生态物种
	[120000237] = true, -- 张建楠
	[126000001] = true, -- 傅泽宇
	[142001000] = true, -- 墨城旧址-机关楼1动力源查看1
	[142001001] = true, -- 墨城旧址-机关楼1动力源查看2
	[142001012] = true, -- 墨城旧址-查看-残破的手稿
	[142001013] = true, -- 墨城旧址-查看-桌上手稿
	[142001034] = true, -- 操纵杆
	[142001044] = true, -- 灰狼
	[142001052] = true, -- 鄢朔
	[142001053] = true, -- 鄢朔
	[142001054] = true, -- 鄢朔
	[142001055] = true, -- 鄢朔
	[142001056] = true, -- 鄢朔
	[142001059] = true, -- 鄢朔
	[142001060] = true, -- 鄢朔
	[142001061] = true, -- 鄢朔
	[142001063] = true, -- 鄢朔
	[142001064] = true, -- 鄢朔
	[170000030] = true, -- 吃饭桌椅-椅
	[180000087] = true, -- 曾一洪
	[190000014] = true, -- 王浩祎
	[190000015] = true, -- 王浩祎
	[190000021] = true, -- 王浩祎
	[190000022] = true, -- 王浩祎
	[190000023] = true, -- 王浩祎
	[190000027] = true, -- 林野
	[190000028] = true, -- 竖直滑索底部空交互物
	[190000037] = true, -- 王浩祎
	[190000041] = true, -- 王浩祎
	[190000042] = true, -- 王浩祎
	[190000043] = true, -- 王浩祎
	[190000044] = true, -- 王浩祎
	[190000045] = true, -- 王浩祎
	[190000046] = true, -- 王浩祎
	[190000047] = true, -- 王浩祎
	[190000048] = true, -- 王浩祎
	[190000049] = true, -- 王浩祎
	[190000050] = true, -- 王浩祎
	[190000060] = true, -- 王浩祎
	[190000061] = true, -- 王浩祎
	[190000062] = true, -- 王浩祎
	[190000067] = true, -- 王浩祎
	[190000068] = true, -- 王浩祎
	[190000069] = true, -- 王浩祎
	[190000070] = true, -- 王浩祎
	[190000071] = true, -- 王浩祎
	[190000072] = true, -- 王浩祎
	[190000073] = true, -- 王浩祎
	[190000074] = true, -- 王浩祎
	[190000077] = true, -- 王浩祎
	[190000078] = true, -- 王浩祎
	[190000079] = true, -- 王浩祎
	[190000080] = true, -- 王浩祎
	[190000081] = true, -- 王浩祎
	[190000082] = true, -- 王浩祎
	[220000384] = true, -- 千纸鹤
	[220000385] = true, -- 陆楚文
	[220000396] = true, -- 陆楚文
	[220000397] = true, -- 陆楚文
	[220000398] = true, -- 陆楚文
	[220000406] = true, -- 陆楚文
	[220000408] = true, -- 陆楚文
	[220000411] = true, -- 陆楚文
	[220000414] = true, -- 墨工桌子
	[220000415] = true, -- 木牛核心1
	[220000416] = true, -- 碧水云涛-见闻-停云石碑
	[220000418] = true, -- 碧水云涛-见闻-女子画像
	[220000422] = true, -- 碧水云涛-见闻-绕树三匝
	[220000431] = true, -- 任老汉的摆渡船
	[220000432] = true, -- 裘索的麻袋1
	[220000433] = true, -- 裘索的麻袋3
	[220000434] = true, -- 裘索的货箱1
	[220000439] = true, -- 阿浑的青鸟[摆件1]
	[220000440] = true, -- 阿浑的青鸟[可交互7]
	[220000444] = true, -- 碧水云涛-风波悼-李兰露父母墓碑
	[220000457] = true, -- 碧水云涛-风波悼-李兰露的信
	[220000459] = true, -- 碧水云涛-万事知-破坏的机关牛
	[220000500] = true, -- 峰林区-九女峰-老翁的烤鱼
	[220000537] = true, -- 不见山-嗟叹崖-日晷
	[220000538] = true, -- 陆楚文
	[220000539] = true, -- 不见山-嗟叹崖-妙算算的书
	[220000542] = true, -- 驿站旗子
	[220000543] = true, -- 气氛棕马
	[220000544] = true, -- 气氛黑马
	[220000583] = true, -- 陆楚文
	[220000584] = true, -- 陆楚文
	[220000585] = true, -- 陆楚文
	[220000586] = true, -- 陆楚文
	[220000597] = true, -- 陆楚文
	[220000598] = true, -- 陆楚文
	[220000599] = true, -- 陆楚文
	[220000608] = true, -- 陆楚文
	[220000611] = true, -- 陆楚文
	[220000638] = true, -- 陆楚文
	[220000639] = true, -- 陆楚文
	[250000152] = true, -- 张泽华
	[270000110] = true, -- 李洁
	[270000111] = true, -- 李洁
	[270000128] = true, -- 李洁
	[270000129] = true, -- 李洁
	[321000023] = true, -- 戴昊翔
	[330000158] = true, -- 刘彦辰
	[330000302] = true, -- 刘彦辰
	[350000043] = true, -- 林思静
	[700000060] = true, -- 李霞
	[700000104] = true, -- 李霞
}

-- ============================================================
-- DETAILED ENTITY DATA (by npc_no)
-- ============================================================
-- Fields:
--   designer: Designer label describing entity purpose
--   wanfa_types: List of gameplay categories this entity belongs to
--   has_reward: Whether entity has interaction_reward (loot)
--   save_type: client_interact_save_type (2=collectible)
--   space: Space ID where entity was found (s1=main world)
--   reasons: Why entity was marked as lootable
-- ============================================================
LOOT_DATA.ENTITY_DATA = {
	[10005] = {
		designer = "",
		notes = "天涯客篝火-隐月山",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[91001] = {
		designer = "模板表",
		notes = "据点-世界等级-绣金楼-黑衣人（弓箭）（高塔哨兵专用）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[93212] = {
		designer = "模板表",
		notes = "世界等级标准小怪偏肉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96001] = {
		designer = "模板表",
		notes = "大世界-绣金楼-绝阴部弟子-火把和刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96002] = {
		designer = "模板表",
		notes = "世界等级-绣金楼-黑衣人（弓箭）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96003] = {
		designer = "模板表",
		notes = "世界等级精英-绣金楼-黑衣人（镰刀）（精英）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96007] = {
		designer = "徐佳琦",
		notes = "毒师测试-猴子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96009] = {
		designer = "模板表",
		notes = "善妙州-绿林刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96012] = {
		designer = "模板表",
		notes = "善妙州-佛爷寨-月牙铲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96014] = {
		designer = "储一民",
		notes = "（将军祠右上）大世界-绣金楼-绝阴部弟子-火把和刀-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96018] = {
		designer = "模板表",
		notes = "善妙州-佛爷寨-弓箭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96020] = {
		designer = "模板表",
		notes = "世界等级-佛爷寨-酒肉和尚（醉拳）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96021] = {
		designer = "徐佳琦",
		notes = "毒师测试-毒师",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96024] = {
		designer = "模板表",
		notes = "1世界等级-绿林-草贼（骑马）（精英）\n巡逻定制动作：无",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96026] = {
		designer = "模板表",
		notes = "世界等级战斗动物模板-鳄鱼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[96031] = {
		designer = "模板表",
		notes = "善妙州-佛爷寨-醉拳精英",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98588] = {
		designer = "模板表",
		notes = "菩提苦海周边天虎军朴刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98590] = {
		designer = "模板表",
		notes = "世界等级-胖梦傀（精英）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98592] = {
		designer = "模板表",
		notes = "TBG-P2.1战斗-精英怪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98593] = {
		designer = "模板表",
		notes = "世界等级-瘦梦傀\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98599] = {
		designer = "模板表",
		notes = "世界等级-机关人\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98605] = {
		designer = "模板表",
		notes = "世界等级-玄元教-月相盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98606] = {
		designer = "模板表",
		notes = "世界等级-玄元教-勾镰+月相盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98608] = {
		designer = "模板表",
		notes = "世界等级-玄元教-月相剑+月相盘（精英）-不巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98610] = {
		designer = "张益豪",
		notes = "《地下粮仓》-寒菌梦傀-连枷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98611] = {
		designer = "模板表",
		notes = "世界等级-寒菌梦傀-铡草刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98629] = {
		designer = "模板表",
		notes = "世界等级-漕帮-投枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98630] = {
		designer = "模板表",
		notes = "世界等级-漕帮-鱼叉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98638] = {
		designer = "程伟建",
		notes = "墨城旧址 野怪 穷奇师盾戟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98639] = {
		designer = "程伟建",
		notes = "碧水云涛 野怪 穷奇师弩炮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98640] = {
		designer = "总表",
		notes = "世界等级-墨山道-挖掘单位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98645] = {
		designer = "模板表",
		notes = "宝箱怪-土行孙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98650] = {
		designer = "模板表",
		notes = "世界等级-漕帮-投枪红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98651] = {
		designer = "模板表",
		notes = "世界等级-漕帮-鱼叉红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98653] = {
		designer = "模板表",
		notes = "世界等级-漕帮-斩骨刀红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98654] = {
		designer = "模板表",
		notes = "世界等级-漕帮-斩骨刀（精英）红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98663] = {
		designer = "总表",
		notes = "世界等级-穷奇师-重锤",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98679] = {
		designer = "总表",
		notes = "弩箭-晦谷-前往分水机关中心轨道-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98682] = {
		designer = "模板表",
		notes = "不见山天工地窟02-2号洞小房间机关蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98684] = {
		designer = "总表",
		notes = "世界等级-墨山道-木牛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98686] = {
		designer = "模板表",
		notes = "世界等级-墨山道-运输单位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98689] = {
		designer = "程伟建",
		notes = "墨城 野怪 木牛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98690] = {
		designer = "总表",
		notes = "世界等级-墨山道-机关人-精英",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98691] = {
		designer = "总表",
		notes = "世界等级-墨山道-机关人-小怪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[98692] = {
		designer = "模板表",
		notes = "不见山天工地窟02-机关蛇-中央区域入口2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[99155] = {
		designer = "程伟建",
		notes = "碧水云涛 野怪 豺狼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[300223] = {
		designer = "石九亮",
		notes = "墨守之心水道灯光",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[300233] = {
		designer = "石九亮",
		notes = "飞天残垣-入口石碑交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[300234] = {
		designer = "石九亮",
		notes = "飞天残垣-同天匣开启机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[300235] = {
		designer = "石九亮",
		notes = "飞天残垣-同天匣使用图纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[300236] = {
		designer = "石九亮",
		notes = "飞天残垣-尸体的遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[300237] = {
		designer = "石九亮",
		notes = "飞天残垣-破损的机关人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[300238] = {
		designer = "石九亮",
		notes = "飞天残垣-暗格交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[300239] = {
		designer = "石九亮",
		notes = "飞天残垣-吊死的尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[300280] = {
		designer = "石九亮",
		notes = "清河书籍-时一墨李安",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[700039] = {
		designer = "",
		notes = "梦傀-原地站立-剧情",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[700044] = {
		designer = "",
		notes = "胖梦傀-趴在地上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[800103] = {
		designer = "陈嘉铮",
		notes = "镰刀黑衣人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[900977] = {
		designer = "陈舟畔",
		notes = "市买地图追踪挂接",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200468] = {
		designer = "胡健力",
		notes = "雪山探境-板车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200472] = {
		designer = "胡健力",
		notes = "基础锻造台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200473] = {
		designer = "胡健力",
		notes = "基础灶台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200474] = {
		designer = "胡健力",
		notes = "基础炼药台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200475] = {
		designer = "胡健力",
		notes = "基础手工台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200480] = {
		designer = "",
		notes = "区域灶台-神仙渡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200481] = {
		designer = "胡健力",
		notes = "将军祠-炸药桶物理破碎版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200517] = {
		designer = "胡健力",
		notes = "基础木工台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200534] = {
		designer = "",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200565] = {
		designer = "",
		notes = "八卦盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200567] = {
		designer = "胡健力",
		notes = "太一宫补漏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200570] = {
		designer = "",
		notes = "通用操控台-大厅",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200571] = {
		designer = "",
		notes = "通用操控台-房间2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200578] = {
		designer = "",
		notes = "地面浑仪替代",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200586] = {
		designer = "胡健力",
		notes = "太岳台遗物袋子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[1200593] = {
		designer = "",
		notes = "共工台上部",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200595] = {
		designer = "",
		notes = "共工台上部-梯子6-底座2米短",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200596] = {
		designer = "胡健力",
		notes = "木梯5米",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200600] = {
		designer = "胡健力",
		notes = "不见山主线-机关仓库-书房梯子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200602] = {
		designer = "胡健力",
		notes = "竹梯5m-70度",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200606] = {
		designer = "",
		notes = "小吊机测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200608] = {
		designer = "任宽",
		notes = "小吊机-箱子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200609] = {
		designer = "",
		notes = "小吊机底盘-仓库",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200610] = {
		designer = "",
		notes = "水闸散件-左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200611] = {
		designer = "",
		notes = "水闸散件-闸门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200612] = {
		designer = "",
		notes = "水闸散件-右",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200614] = {
		designer = "胡健力",
		notes = "共工台-一楼主轴",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200615] = {
		designer = "胡健力",
		notes = "共工台-地下室主轴",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200616] = {
		designer = "胡健力",
		notes = "共工台-齿轮组件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200617] = {
		designer = "胡健力",
		notes = "共工台-齿轮盒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200618] = {
		designer = "胡健力",
		notes = "共工台-大门闸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200623] = {
		designer = "",
		notes = "共工台上部-梯子3-室外中，关键帧",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200625] = {
		designer = "",
		notes = "共工台上部-梯子3-1楼固定",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200626] = {
		designer = "",
		notes = "共工台上部-梯子5-内部短",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200627] = {
		designer = "胡健力",
		notes = "共工台梯子6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200628] = {
		designer = "胡健力",
		notes = "TBG-移动缆车-钩子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200635] = {
		designer = "",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200642] = {
		designer = "",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200647] = {
		designer = "胡健力",
		notes = "石底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200659] = {
		designer = "",
		notes = "大厅浑仪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200661] = {
		designer = "胡健力",
		notes = "太岳台-门A右-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200662] = {
		designer = "胡健力",
		notes = "太岳台-门A右-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200663] = {
		designer = "胡健力",
		notes = "太岳台-门A右-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200664] = {
		designer = "胡健力",
		notes = "太岳台-门A右-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200665] = {
		designer = "胡健力",
		notes = "太岳台-门A左-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200666] = {
		designer = "胡健力",
		notes = "太岳台-门A左-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200667] = {
		designer = "胡健力",
		notes = "太岳台-门A左-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200668] = {
		designer = "胡健力",
		notes = "太岳台-门A左-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200669] = {
		designer = "胡健力",
		notes = "太岳台-门C右-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200670] = {
		designer = "胡健力",
		notes = "太岳台-门C右-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200671] = {
		designer = "胡健力",
		notes = "太岳台-门C右-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200672] = {
		designer = "胡健力",
		notes = "太岳台-门C右-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200673] = {
		designer = "胡健力",
		notes = "太岳台-门C左-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200674] = {
		designer = "胡健力",
		notes = "太岳台-门C左-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200675] = {
		designer = "胡健力",
		notes = "太岳台-门C左-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200676] = {
		designer = "胡健力",
		notes = "太岳台-门C左-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200677] = {
		designer = "胡健力",
		notes = "太岳台-门B右-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200678] = {
		designer = "胡健力",
		notes = "太岳台-门B右-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200679] = {
		designer = "胡健力",
		notes = "太岳台-门B右-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200680] = {
		designer = "胡健力",
		notes = "太岳台-门B右-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200681] = {
		designer = "胡健力",
		notes = "太岳台-门B左-base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200682] = {
		designer = "胡健力",
		notes = "太岳台-门B左-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200683] = {
		designer = "胡健力",
		notes = "太岳台-门B左-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200684] = {
		designer = "胡健力",
		notes = "太岳台-门B左-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200685] = {
		designer = "胡健力",
		notes = "太岳台-谜面地砖底部base",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200686] = {
		designer = "胡健力",
		notes = "太岳台-谜面地砖底部1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200687] = {
		designer = "胡健力",
		notes = "太岳台-谜面地砖底部2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200688] = {
		designer = "胡健力",
		notes = "太岳台-谜面地砖底部3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200690] = {
		designer = "",
		notes = "穹顶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200696] = {
		designer = "胡健力",
		notes = "装藏轮结局门右",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200697] = {
		designer = "胡健力",
		notes = "装藏轮结局门左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1200701] = {
		designer = "",
		notes = "供桌2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200706] = {
		designer = "胡健力",
		notes = "解谜洞窟闸门-右侧室",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200707] = {
		designer = "胡健力",
		notes = "3号房间-飞来索后旋转底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1200708] = {
		designer = "",
		notes = "大厅浑仪操控台-脚底",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201020] = {
		designer = "",
		notes = "建隆观后山入口石板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201037] = {
		designer = "胡健力",
		notes = "范宅钥匙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[1201038] = {
		designer = "胡健力",
		notes = "闸口盘车-水力机关1-磨",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201039] = {
		designer = "胡健力",
		notes = "闸口盘车-水力机关2-筛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201040] = {
		designer = "胡健力",
		notes = "闸口盘车-水力机关3-水锥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201041] = {
		designer = "胡健力",
		notes = "闸口盘车-水力机关4-动力",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201042] = {
		designer = "",
		notes = "一楼挂接面具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1201063] = {
		designer = "胡健力",
		notes = "梨花潭深-酒坛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[1201098] = {
		designer = "胡健力",
		notes = "点火机关-可燃物组件-会自动熄灭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1201132] = {
		designer = "",
		notes = "闸口盘车水特效1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201133] = {
		designer = "",
		notes = "闸口盘车水特效2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1201134] = {
		designer = "胡健力",
		notes = "府宅区门板-密室2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1201153] = {
		designer = "",
		notes = "上清真境灵宝天尊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1201154] = {
		designer = "",
		notes = "玉清圣境元始天尊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1201155] = {
		designer = "",
		notes = "太清仙境道德天尊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1501110] = {
		designer = "孙亦鸣",
		notes = "春秋别馆转动机关1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1501304] = {
		designer = "孙亦鸣",
		notes = "组织玩法组件-相扑玩法台子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1700000] = {
		designer = "",
		notes = "不羡仙悬赏板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1700050] = {
		designer = "宋磊",
		notes = "斗茶酒缸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1700068] = {
		designer = "宋磊",
		notes = "清河长椅",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1700203] = {
		designer = "",
		notes = "狂澜喝酒测试-斗茶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1700204] = {
		designer = "",
		notes = "多人投壶-清河",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1700205] = {
		designer = "",
		notes = "斗茶酒缸-PVP-开封",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1700311] = {
		designer = "宋磊",
		notes = "脚手架2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800119] = {
		designer = "袁国振",
		notes = "smallgate 小重门3.6m",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800149] = {
		designer = "袁国振",
		notes = "炸药桶big（可抱起）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800262] = {
		designer = "袁国振",
		notes = "炸药桶原版：炸药桶-物理破碎版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800268] = {
		designer = "袁国振",
		notes = "祈缘树",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1800269] = {
		designer = "袁国振",
		notes = "功德池",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1800289] = {
		designer = "袁国振",
		notes = "菊花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800301] = {
		designer = "袁国振",
		notes = "功德池的池",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1800336] = {
		designer = "袁国振",
		notes = "丰禾村-小报示意",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800634] = {
		designer = "袁国振",
		notes = "三更天觉醒的觉障树（临时，后续搬到觉障林）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1800641] = {
		designer = "袁国振",
		notes = "假宝箱-炸弹-楼顶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[1800647] = {
		designer = "袁国振",
		notes = "书籍-三更天杀人名单",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900297] = {
		designer = "",
		notes = "烹饪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900327] = {
		designer = "",
		notes = "皮影落座按钮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900350] = {
		designer = "欧阳书舟",
		notes = "红尘无眼-田英书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900389] = {
		designer = "欧阳书舟",
		notes = "无忧洞-怪物-无忧帮-帮众-铁壁谷-窃听-石块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900444] = {
		designer = "",
		notes = "武库据点-鹏的羽毛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[1900448] = {
		designer = "",
		notes = "扶摇山据点外围-窃听",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[1900449] = {
		designer = "模板表",
		notes = "据点-世界等级-绣金楼-黑衣人（弓箭）（高塔哨兵专用）\n巡逻定制动作：有",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2000017] = {
		designer = "宝箱-杨显彬",
		notes = "走火入魔秘籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100129] = {
		designer = "杨翥宇",
		notes = "行会放楼顶的箱子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100142] = {
		designer = "杨翥宇",
		notes = "飞刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100143] = {
		designer = "杨翥宇",
		notes = "账本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100225] = {
		designer = "杨翥宇",
		notes = "稀有宝箱（医馆二楼通宝）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[2100227] = {
		designer = "",
		notes = "伤害仲裁2号",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100228] = {
		designer = "",
		notes = "井口藤蔓-可烧毁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100232] = {
		designer = "",
		notes = "火盆触发器5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100243] = {
		designer = "",
		notes = "第二个房间的捂脸1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100244] = {
		designer = "",
		notes = "第三个房间的尸体3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100245] = {
		designer = "",
		notes = "第三个房间的诈尸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100246] = {
		designer = "",
		notes = "移动的无面人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100248] = {
		designer = "",
		notes = "地宫火箭宝箱1",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[2100250] = {
		designer = "",
		notes = "地宫镇守传送道具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100252] = {
		designer = "",
		notes = "解谜的留言",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100255] = {
		designer = "",
		notes = "第一个房间的监管者",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100256] = {
		designer = "",
		notes = "第二个房间的监管者",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100258] = {
		designer = "",
		notes = "合唱的加入笛子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100271] = {
		designer = "",
		notes = "门派树枝收集物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100272] = {
		designer = "",
		notes = "门派水坛收集物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100273] = {
		designer = "",
		notes = "门派算珠收集物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100277] = {
		designer = "",
		notes = "寒香寻的钱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100278] = {
		designer = "",
		notes = "寒香寻的钱2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100279] = {
		designer = "",
		notes = "追忆投放",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[2100282] = {
		designer = "",
		notes = "程心的匣子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100285] = {
		designer = "",
		notes = "二层火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100287] = {
		designer = "",
		notes = "地宫蜡烛4号",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100289] = {
		designer = "",
		notes = "听黄河",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100301] = {
		designer = "",
		notes = "增补的一层唱歌捂脸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100304] = {
		designer = "",
		notes = "门震动",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100305] = {
		designer = "",
		notes = "独立的捂脸者",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100308] = {
		designer = "杨翥宇",
		notes = "地宫宝箱增补3（珍贵）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[2100320] = {
		designer = "",
		notes = "泛黄的婚书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100336] = {
		designer = "杨翥宇",
		notes = "万古一人殿-一层氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100337] = {
		designer = "杨翥宇",
		notes = "万古一人殿-一层氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100338] = {
		designer = "杨翥宇",
		notes = "万古一人殿-一层氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100343] = {
		designer = "",
		notes = "追忆装备-清泉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100350] = {
		designer = "",
		notes = "合唱的加入笛子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2100351] = {
		designer = "",
		notes = "重型龙头机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100352] = {
		designer = "",
		notes = "重型龙头机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100355] = {
		designer = "杨翥宇",
		notes = "返回关卡入口特效传送",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100356] = {
		designer = "",
		notes = "红色托盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100386] = {
		designer = "",
		notes = "镰刀箱子看戏怪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100387] = {
		designer = "",
		notes = "火把敲箱子怪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100398] = {
		designer = "",
		notes = "掉落的吓人毒人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100399] = {
		designer = "",
		notes = "氛围毒人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100400] = {
		designer = "",
		notes = "氛围毒人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100401] = {
		designer = "",
		notes = "猛火油柜--假",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100419] = {
		designer = "",
		notes = "狼王",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100445] = {
		designer = "杨翥宇",
		notes = "路障猛火油柜1-操作员",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100481] = {
		designer = "袁国振",
		notes = "万古一人殿-地下三层开门搬运模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100550] = {
		designer = "杨翥宇",
		notes = "宝藏镇守-千夜-传送物品",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100553] = {
		designer = "杨翥宇",
		notes = "敌袭门口空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100559] = {
		designer = "",
		notes = "井口藤蔓-不可烧毁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2100561] = {
		designer = "杨翥宇",
		notes = "返回塔下面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2200113] = {
		designer = "杨心仪",
		notes = "天泉-清泉帮书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2200114] = {
		designer = "杨心仪",
		notes = "天泉-风雪林场书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2200115] = {
		designer = "杨心仪",
		notes = "天泉-田产书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2200116] = {
		designer = "杨心仪",
		notes = "天泉-处决公文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2200118] = {
		designer = "杨心仪",
		notes = "天泉-叶承霜之信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2400292] = {
		designer = "贺江婷",
		notes = "鬼寺-进入暗道-交互-永久",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500002] = {
		designer = "清河主线",
		notes = "竹林小屋-暗盒的信-特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500029] = {
		designer = "贺江婷",
		notes = "瓷窑-氛围麻袋1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500030] = {
		designer = "贺江婷",
		notes = "瓷窑-氛围麻袋2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500031] = {
		designer = "贺江婷",
		notes = "瓷窑-氛围麻袋3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500047] = {
		designer = "宝箱",
		notes = "秘密小屋的宝箱-钱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[2500048] = {
		designer = "宝箱",
		notes = "秘密小屋的宝箱-金疮药",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[2500049] = {
		designer = "宝箱",
		notes = "秘密小屋的宝箱-莲花鱼宝",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[2500050] = {
		designer = "宝箱",
		notes = "秘密小屋的宝箱-万象饮·一等",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[2500051] = {
		designer = "宝箱",
		notes = "秘密小屋的宝箱-振玉",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[2500053] = {
		designer = "清河主线",
		notes = "河边倒酒-酒坛大",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500056] = {
		designer = "开封主线",
		notes = "长板凳",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[2500059] = {
		designer = "贺江婷",
		notes = "将军祠-路过方旭-布景木板-左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500060] = {
		designer = "贺江婷",
		notes = "酒香塔地下-秘密小屋门口-返回特效传送",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2500069] = {
		designer = "清河主线",
		notes = "死掉的鹦鹉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2620052] = {
		designer = "金雪松",
		notes = "货物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2700009] = {
		designer = "周一舟",
		notes = "神秘手札",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2700010] = {
		designer = "周一舟",
		notes = "地理志·神仙渡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2700011] = {
		designer = "周一舟",
		notes = "严君皓家书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2700012] = {
		designer = "周一舟",
		notes = "游记·不羡仙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2700013] = {
		designer = "周一舟",
		notes = "京城别筑罗城诏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703151] = {
		designer = "周一舟",
		notes = "老梨树",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703152] = {
		designer = "周一舟",
		notes = "探索酿造",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703153] = {
		designer = "周一舟",
		notes = "制曲工艺",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703156] = {
		designer = "周一舟",
		notes = "寒千夜墓地",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703158] = {
		designer = "周一舟",
		notes = "冥婚探索点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703165] = {
		designer = "周一舟",
		notes = "镶花小剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703177] = {
		designer = "周一舟",
		notes = "荒魂村血屋调查",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703178] = {
		designer = "周一舟",
		notes = "荒魂村医书1食魄经",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703179] = {
		designer = "周一舟",
		notes = "荒魂村医书2陈藏器本草",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703180] = {
		designer = "周一舟",
		notes = "荒魂村医书3异苑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703181] = {
		designer = "周一舟",
		notes = "荒魂村熬汤骨头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703182] = {
		designer = "周一舟",
		notes = "荒魂村灵位查看",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703183] = {
		designer = "周一舟",
		notes = "荒魂村田英来信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703184] = {
		designer = "周一舟",
		notes = "荒魂村血色夜悼文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703185] = {
		designer = "周一舟",
		notes = "死鸡-荒魂村探索",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703186] = {
		designer = "周一舟",
		notes = "香炉线香",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703199] = {
		designer = "周一舟",
		notes = "火焰触发器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703214] = {
		designer = "周一舟",
		notes = "书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703225] = {
		designer = "周一舟",
		notes = "墨守巳蛇·1-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703226] = {
		designer = "周一舟",
		notes = "墨守巳蛇·1-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703227] = {
		designer = "周一舟",
		notes = "墨守巳蛇·2-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703228] = {
		designer = "周一舟",
		notes = "墨守巳蛇·2-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703250] = {
		designer = "周一舟",
		notes = "铜钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703251] = {
		designer = "周一舟",
		notes = "小剧场-甜水厂比拼-钱袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703253] = {
		designer = "周一舟",
		notes = "神秘药瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703254] = {
		designer = "周一舟",
		notes = "小匣子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703257] = {
		designer = "周一舟",
		notes = "百草野皮影师-尸体1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703266] = {
		designer = "周一舟",
		notes = "百草野皮影师-尸体1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703267] = {
		designer = "周一舟",
		notes = "百草野皮影师-尸体3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703268] = {
		designer = "周一舟",
		notes = "荒魂村临行之宴来信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703269] = {
		designer = "周一舟",
		notes = "荒魂村鹿仙祭祀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[2703278] = {
		designer = "周一舟",
		notes = "墨城求学守则 · 下篇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703279] = {
		designer = "周一舟",
		notes = "给鸟长老的求学自荐信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703280] = {
		designer = "周一舟",
		notes = "不醒解惑 · 残片一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703281] = {
		designer = "周一舟",
		notes = "墨城粪男三宗罪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703282] = {
		designer = "周一舟",
		notes = "长老批语辑录",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703283] = {
		designer = "周一舟",
		notes = "关于<民兵训练手册>的修复回信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2703284] = {
		designer = "周一舟",
		notes = "鸽与不鸽的猜想",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[2800055] = {
		designer = "易楷宁",
		notes = "鳄鱼小怪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3000006] = {
		designer = "张增辉",
		notes = "隔空取物的物品1绣帕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3000008] = {
		designer = "张增辉",
		notes = "隔空取物的物品3罗盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3200838] = {
		designer = "施天来",
		notes = "万物交互-神秘的信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200850] = {
		designer = "",
		notes = "应悔偷灵药-遗失的药包",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200858] = {
		designer = "",
		notes = "被划去的名字-杨氏族谱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200859] = {
		designer = "",
		notes = "谁言慈父心-圆润的小佛雕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200860] = {
		designer = "",
		notes = "谁言慈父心-有棱有角的小佛雕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200861] = {
		designer = "",
		notes = "业火不熄-没烧干净的家书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200862] = {
		designer = "",
		notes = "残佛不语-诅咒人偶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200867] = {
		designer = "",
		notes = "神仙渡-离人泪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200876] = {
		designer = "",
		notes = "深夜犬吠-鲜肉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200877] = {
		designer = "",
		notes = "深夜犬吠-火焰龙纹令牌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200879] = {
		designer = "",
		notes = "欲望深渊-大坛离人泪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200882] = {
		designer = "",
		notes = "大鹅争锋-火折子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200883] = {
		designer = "",
		notes = "大鹅争锋-宋九的臭袜子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200885] = {
		designer = "",
		notes = "失窃美酒-一撮黄毛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200886] = {
		designer = "",
		notes = "失窃美酒-头坛酒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3200889] = {
		designer = "",
		notes = "欲望深渊-精酿离人泪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3202210] = {
		designer = "",
		notes = "小木笼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202231] = {
		designer = "施天来",
		notes = "石灯（临时）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202232] = {
		designer = "施天来",
		notes = "妙妙喵石碑-荧光辉夜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202233] = {
		designer = "施天来",
		notes = "妙妙喵石碑-荧光辉夜（碎1）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202234] = {
		designer = "施天来",
		notes = "妙妙喵石碑-荧光辉夜（碎2）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202235] = {
		designer = "施天来",
		notes = "妙妙喵石碑-荧光辉夜（碎3）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202236] = {
		designer = "施天来",
		notes = "妙妙喵石碑-荧光辉夜（碎4）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202240] = {
		designer = "施天来",
		notes = "放置佛光玉·能放",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202309] = {
		designer = "施天来",
		notes = "p3-1暗淡旧刀拾取",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3202310] = {
		designer = "施天来",
		notes = "慈心山院战斗大黄狗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3202332] = {
		designer = "施天来",
		notes = "聊以慰英灵-祭拜的香饮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3202334] = {
		designer = "施天来",
		notes = "宝藏挖掘点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3202340] = {
		designer = "华中承",
		notes = "长明灯-熄灭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202341] = {
		designer = "华中承",
		notes = "长明灯-熄灭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3202342] = {
		designer = "施天来",
		notes = "品酒册",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3203001] = {
		designer = "",
		notes = "花中愿-摩诃曼殊沙华",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203003] = {
		designer = "",
		notes = "本心善妙-善妙手书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203005] = {
		designer = "",
		notes = "良人胡不归-神秘梦傀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3203006] = {
		designer = "",
		notes = "神秘的小药瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203008] = {
		designer = "",
		notes = "祁飞骏的日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203009] = {
		designer = "",
		notes = "未央商会的来信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203012] = {
		designer = "",
		notes = "祁氏家驯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203015] = {
		designer = "",
		notes = "将军祠万物交互-小屁孩的鼓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3203026] = {
		designer = "施天来",
		notes = "灵葵-祁氏家训",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3205600] = {
		designer = "耿赟",
		notes = "书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3205701] = {
		designer = "施天来",
		notes = "熔炉-升降桶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3600070] = {
		designer = "",
		notes = "酒逢知己-墓碑-任务后",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3600096] = {
		designer = "",
		notes = "酒逢知己-墓碑酒坛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3600121] = {
		designer = "",
		notes = "追忆-九曲石船-破旧的酒坛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3600122] = {
		designer = "",
		notes = "追忆-医馆地底-洛神手记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3700602] = {
		designer = "",
		notes = "场景大鹅-神仙渡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3700622] = {
		designer = "徐佳琦",
		notes = "隔空取物-蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3700635] = {
		designer = "徐佳琦",
		notes = "旧村遗址据点-弩机3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3700637] = {
		designer = "徐佳琦",
		notes = "【常平仓地下】悬挂重物-锁扣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3700638] = {
		designer = "徐佳琦",
		notes = "【常平仓地下】悬挂重物-重物1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3700646] = {
		designer = "徐佳琦",
		notes = "疯龙王替代鳄鱼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800033] = {
		designer = "彭冉",
		notes = "武林录解锁-易碎的地板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800035] = {
		designer = "",
		notes = "武林录解锁-真磕头点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800036] = {
		designer = "",
		notes = "武林录解锁-无头雕像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800060] = {
		designer = "",
		notes = "石碑1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800061] = {
		designer = "",
		notes = "石碑2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800062] = {
		designer = "",
		notes = "石碑3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800063] = {
		designer = "",
		notes = "石碑4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800064] = {
		designer = "",
		notes = "石碑5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800065] = {
		designer = "彭冉",
		notes = "苦海有声-洞口石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3800102] = {
		designer = "任宽",
		notes = "熔炉内-工业区-吊桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3900039] = {
		designer = "",
		notes = "猫_橙-神仙渡喂猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900040] = {
		designer = "",
		notes = "猫_橙-神仙渡喂猫3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900041] = {
		designer = "",
		notes = "猫_橙-神仙渡喂猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900042] = {
		designer = "",
		notes = "猫_印花-神仙渡喂猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900043] = {
		designer = "",
		notes = "猫_印花-不羡仙摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900044] = {
		designer = "",
		notes = "猫_印花-伏嘛庄摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900045] = {
		designer = "",
		notes = "猫_白-不羡仙摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900046] = {
		designer = "",
		notes = "猫_白-瓷窑摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900047] = {
		designer = "",
		notes = "猫_白-来生岸摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900048] = {
		designer = "",
		notes = "猫_黑（狸花）-神仙渡喂猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900049] = {
		designer = "",
		notes = "猫_黑（狸花）-不羡仙摸猫3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900050] = {
		designer = "",
		notes = "猫_黑（狸花）-丰禾村摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900051] = {
		designer = "",
		notes = "猫_橙-不羡仙摸猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900052] = {
		designer = "",
		notes = "白草野摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900053] = {
		designer = "",
		notes = "猫_白-慈心镇摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3900054] = {
		designer = "",
		notes = "猫_黑（狸花）-佛光顶摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[3904046] = {
		designer = "张筱诺",
		notes = "TBG-核心",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904052] = {
		designer = "张筱诺",
		notes = "铁壁谷（白盒）-传动铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904055] = {
		designer = "张筱诺",
		notes = "TBG-流水-P1教学-旋转轨道出水",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904067] = {
		designer = "张筱诺",
		notes = "假门1-入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904069] = {
		designer = "张筱诺",
		notes = "TBG-磁板怪-P2.1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904070] = {
		designer = "张筱诺",
		notes = "TBG-P1-下面的洞滑索",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904071] = {
		designer = "张筱诺",
		notes = "MSD天工地窟005-P2移动平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904073] = {
		designer = "田野",
		notes = "MSD天工地窟005-P1-门开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904093] = {
		designer = "张筱诺",
		notes = "TBG-磁板-P1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904094] = {
		designer = "张筱诺",
		notes = "TBG-P1-磁板开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904096] = {
		designer = "张筱诺",
		notes = "铁壁谷-P2.2望远镜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904098] = {
		designer = "张筱诺",
		notes = "TBG-矿球射箭怪01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904099] = {
		designer = "张筱诺",
		notes = "TBG-移动缆车-开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904101] = {
		designer = "张筱诺",
		notes = "TBG-P2.3-机关门开关（杀怪开关）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904102] = {
		designer = "张筱诺",
		notes = "铁壁谷-矿球轨道螺旋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3904103] = {
		designer = "张筱诺",
		notes = "骨头堆01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904104] = {
		designer = "张筱诺",
		notes = "骨头堆02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904105] = {
		designer = "张筱诺",
		notes = "土堆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904106] = {
		designer = "张筱诺",
		notes = "鱼骨01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904108] = {
		designer = "张筱诺",
		notes = "鱼骨03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904109] = {
		designer = "张筱诺",
		notes = "鱼骨04",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904119] = {
		designer = "张筱诺",
		notes = "石剑（大）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3904123] = {
		designer = "张筱诺",
		notes = "基础墙壁石头004b",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3905210] = {
		designer = "张筱诺",
		notes = "【界碑-传送】嗟叹崖前",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[3905212] = {
		designer = "张筱诺",
		notes = "【侠之冢-复活】",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905226] = {
		designer = "",
		notes = "荧渊-记忆1-柳青衣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905227] = {
		designer = "",
		notes = "荧渊-记忆2-哀帝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905228] = {
		designer = "",
		notes = "荧渊-记忆3-柳青衣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905233] = {
		designer = "",
		notes = "荧渊-记忆1-哀帝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905234] = {
		designer = "",
		notes = "荧渊-记忆3-哀帝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905237] = {
		designer = "",
		notes = "荧渊-鹿头骨（红）01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905238] = {
		designer = "",
		notes = "荧渊-鹿头骨（红）02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905239] = {
		designer = "",
		notes = "荧渊-鹿头骨（红）03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905241] = {
		designer = "",
		notes = "荧渊-吊桥-绳子-一捆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905244] = {
		designer = "",
		notes = "荧渊-柳哀小屋-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905248] = {
		designer = "张筱诺",
		notes = "荧渊-记忆2的荆棘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905249] = {
		designer = "",
		notes = "荧渊-人蛹留书+钥匙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905250] = {
		designer = "",
		notes = "荧渊-叙事-孙不弃手札（一）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905251] = {
		designer = "",
		notes = "荧渊-叙事-孙不弃手札（二）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905254] = {
		designer = "",
		notes = "荧渊-叙事-孙不弃手札（三）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905255] = {
		designer = "",
		notes = "荧渊-叙事-水月先生回信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905256] = {
		designer = "",
		notes = "荧渊-叙事-凝露酿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905257] = {
		designer = "",
		notes = "荧渊-叙事-木雕雌鹿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905262] = {
		designer = "",
		notes = "荧渊-实验室门机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905274] = {
		designer = "",
		notes = "荧渊-柳青衣墓-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905275] = {
		designer = "",
		notes = "荧渊-终局-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905276] = {
		designer = "",
		notes = "荧渊-污染鹿头骨1-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905277] = {
		designer = "",
		notes = "荧渊-污染鹿头骨2-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905278] = {
		designer = "",
		notes = "荧渊-污染鹿头骨3-鹿灵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905280] = {
		designer = "",
		notes = "荧渊-柳哀小屋-机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905282] = {
		designer = "",
		notes = "荧渊-前往下层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905285] = {
		designer = "",
		notes = "荧渊-太极点亮-负手石像灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905288] = {
		designer = "俞立",
		notes = "荧渊-叙事道具-长生仙人传上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905289] = {
		designer = "",
		notes = "荧渊-叙事道具-长生仙人传中",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905290] = {
		designer = "",
		notes = "荧渊-叙事道具-长生仙人传下",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905291] = {
		designer = "",
		notes = "荧渊-叙事道具-巴梧自传上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905292] = {
		designer = "",
		notes = "荧渊-叙事道具-巴梧自传中",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905293] = {
		designer = "",
		notes = "荧渊-叙事道具-巴梧自传下",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905294] = {
		designer = "",
		notes = "荧渊-银锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[3905296] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-近棺者死",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905297] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-陈怀卿碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905298] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-赫代久碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905299] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-阿黎耶碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905300] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-蒙赫夫妇碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905301] = {
		designer = "张筱诺",
		notes = "荧渊-场景交互-仰氏祖孙五人碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905302] = {
		designer = "",
		notes = "荧渊-祭祀-鹿头仙人壁画",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905304] = {
		designer = "",
		notes = "荧渊-祭祀-玩家祭拜点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905332] = {
		designer = "",
		notes = "荧渊-祭祀-血书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905342] = {
		designer = "",
		notes = "荧渊-进入老荧渊洞口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905344] = {
		designer = "张筱诺",
		notes = "将军祠-尸体交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905345] = {
		designer = "张筱诺",
		notes = "将军祠-最终房间碑文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905350] = {
		designer = "模板表",
		notes = "将军祠-龙虎寨盗贼A世界等级-绿林-山匪（单刀）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905351] = {
		designer = "模板表",
		notes = "将军祠-龙虎寨盗贼D世界等级-绿林-佛爷寨弟子（单刀）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[3905354] = {
		designer = "张筱诺",
		notes = "将军祠-火焰触发器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4100005] = {
		designer = "开封琼林苑",
		notes = "棚子短蜡烛-常亮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4100007] = {
		designer = "开封琼林苑",
		notes = "短蜡烛-交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4100032] = {
		designer = "开封琼林苑",
		notes = "井边-空模型传送静夜思",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4100051] = {
		designer = "秦臻",
		notes = "新壁画-空模型对话交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200073] = {
		designer = "刘海歌",
		notes = "海歌-伏马庄-神秘的锦盒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200074] = {
		designer = "刘海歌",
		notes = "海歌-伏马庄-锦盒旁的密信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200075] = {
		designer = "刘海歌",
		notes = "海歌-慈心山院-慧药的日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200078] = {
		designer = "",
		notes = "第三次佛光-遗失的旧账本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4200203] = {
		designer = "刘海歌",
		notes = "碧水云涛-孩子们的书桌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200204] = {
		designer = "刘海歌",
		notes = "碧水云涛-鸦旧屋的书架全都空了，没有一本书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200205] = {
		designer = "刘海歌",
		notes = "碧水云涛-鸦的床榻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4200206] = {
		designer = "刘海歌",
		notes = "碧水云涛-鸦的旧屋书桌墙上增加一个女子画像（青）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4500012] = {
		designer = "宝箱",
		notes = "A24绣金楼营地普通宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500014] = {
		designer = "",
		notes = "劫车宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500015] = {
		designer = "",
		notes = "破损马车珍宝匣",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500016] = {
		designer = "宝箱",
		notes = "A0绿林营地宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500017] = {
		designer = "",
		notes = "种植曼陀罗营地宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500037] = {
		designer = "宝箱",
		notes = "千斤坠-珍宝匣",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500040] = {
		designer = "",
		notes = "花海-宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500042] = {
		designer = "",
		notes = "寒房心法宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500045] = {
		designer = "",
		notes = "地宫宝箱增补3（珍贵）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500046] = {
		designer = "宝箱",
		notes = "洞穴营地-民兵库宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500047] = {
		designer = "宝箱",
		notes = "洞穴营地-秀金楼宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500048] = {
		designer = "宝箱",
		notes = "洞穴营地-绿林盗匪宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500050] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱1",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500051] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱2",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500052] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱3",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500053] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱4",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500054] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱5",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500055] = {
		designer = "",
		notes = "红尘无眼水下指引宝箱6",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500057] = {
		designer = "",
		notes = "荧渊-柳哀小屋-一品宝箱（心法所恨年年）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500058] = {
		designer = "",
		notes = "敌袭立体通路一层高级宝箱-2",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500059] = {
		designer = "",
		notes = "敌袭宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500060] = {
		designer = "张联鑫",
		notes = "据点自选宝箱-怜花禅院",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4500061] = {
		designer = "宝箱",
		notes = "MSD天工地窟005-P3金制一品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500062] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-清河",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500063] = {
		designer = "宝箱",
		notes = "据点-【正式】木制三品宝箱-清河",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500064] = {
		designer = "",
		notes = "木条箱【丹崖】",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500066] = {
		designer = "毒人诞生",
		notes = "敌袭立体通路二层高级宝箱-1",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500068] = {
		designer = "宝箱",
		notes = "千斤坠石板宝箱",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500074] = {
		designer = "宝箱",
		notes = "A9绣金楼营地-5级装备宝箱束巾（对应1-5区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500075] = {
		designer = "宝箱",
		notes = "5级装备宝箱衣襟（对应1-5区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500076] = {
		designer = "宝箱",
		notes = "A3绿林营地宝箱-5级装备宝箱护臂（对应1-5区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500077] = {
		designer = "宝箱",
		notes = "A5绿林宝箱-（五级装备）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500078] = {
		designer = "宝箱",
		notes = "A21绣金楼营地-10级装备宝箱束巾（对应6-15区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500079] = {
		designer = "宝箱",
		notes = "A20绣金楼营地-10级装备宝箱衣襟（对应6-15区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500080] = {
		designer = "宝箱",
		notes = "A41绿林营地-10级装备宝箱护臂（对应6-15区域）\n",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500081] = {
		designer = "宝箱",
		notes = "A45绣金楼营地-10级装备宝箱行缠（对应6-15区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500082] = {
		designer = "宝箱",
		notes = "A39绣金楼营地-25级装备宝箱束巾（对应16-25区域）\n",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500083] = {
		designer = "宝箱",
		notes = "A37绿林营地-25级装备宝箱衣襟（对应16-25区域）\n",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500084] = {
		designer = "宝箱",
		notes = "A30绣金楼营地-25级装备宝箱护臂（对应16-25区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500085] = {
		designer = "宝箱",
		notes = "25级装备宝箱行缠（对应16-25区域）\n",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500086] = {
		designer = "宝箱",
		notes = "35级装备宝箱束巾（对应26-35区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500087] = {
		designer = "宝箱",
		notes = "35级装备宝箱衣襟（对应26-35区域）\n",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500088] = {
		designer = "宝箱",
		notes = "35级装备宝箱护臂（对应26-35区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500089] = {
		designer = "宝箱",
		notes = "35级装备宝箱行缠（对应26-35区域）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500090] = {
		designer = "宝箱",
		notes = "佛爷和尚营地宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500091] = {
		designer = "",
		notes = "九曲断魂枪心法",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500092] = {
		designer = "",
		notes = "青山执笔心法",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500093] = {
		designer = "宝箱",
		notes = "偷师洞窟明心药典-一等心法宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500094] = {
		designer = "",
		notes = "珍宝匣",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500103] = {
		designer = "袁国振",
		notes = "天泉入门宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4500105] = {
		designer = "",
		notes = "鬼寺宝箱-药物",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500106] = {
		designer = "张联鑫",
		notes = "佛光顶-铜人钥匙交互-罗汉堂",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4500113] = {
		designer = "宝箱",
		notes = "【正式】木制三品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500114] = {
		designer = "宝箱",
		notes = "【正式】木制三品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500115] = {
		designer = "宝箱",
		notes = "【正式】木制四品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500117] = {
		designer = "宝箱",
		notes = "开封机关锁宝箱（微解谜）",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500120] = {
		designer = "宝箱",
		notes = "【正式】木制三品宝箱-金明池（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500121] = {
		designer = "宝箱",
		notes = "【正式】木制四品宝箱-金明池（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500122] = {
		designer = "宝箱",
		notes = "春秋别馆地下一层机关二品宝箱（有禁用态）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500123] = {
		designer = "宝箱",
		notes = "春秋别馆夹层珍宝匣-追忆装备投放",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500129] = {
		designer = "",
		notes = "不羡仙-追忆装备-翼甲",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500130] = {
		designer = "周雨霖",
		notes = "复合解密-屋内奖励宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500131] = {
		designer = "赵伟业",
		notes = "龙湖寨-上锁宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500135] = {
		designer = "宝箱",
		notes = "解谜洞窟二品宝箱（踏雪无痕洞窟专用）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500136] = {
		designer = "",
		notes = "【无忧洞】木制三品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500137] = {
		designer = "宝箱",
		notes = "抱山湖秘宝-木制三品宝箱-禁用态",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500138] = {
		designer = "宝箱",
		notes = "抱山湖秘宝-钥匙1-木制四品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500139] = {
		designer = "宝箱",
		notes = "抱山湖秘宝-钥匙2-木制四品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500140] = {
		designer = "",
		notes = "【偷师】铁制二品宝箱-枪",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500141] = {
		designer = "宝箱",
		notes = "【偷师】木制三品宝箱-扇",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500142] = {
		designer = "宝箱",
		notes = "【偷师】木制三品宝箱-剑",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500143] = {
		designer = "",
		notes = "【偷师】木制三品宝箱-扇",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500144] = {
		designer = "宝箱",
		notes = "【偷师】木制三品宝箱-双刀",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500145] = {
		designer = "宝箱",
		notes = "解谜洞窟（火箭简单）-关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500146] = {
		designer = "宝箱",
		notes = "解谜洞窟（爆炸之力）-关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500147] = {
		designer = "宝箱",
		notes = "解谜洞窟（空中冲刺）-关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500148] = {
		designer = "宝箱",
		notes = "解谜洞窟（止水射箭）-关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500149] = {
		designer = "宝箱",
		notes = "清河-解密洞窟（点穴机关人）关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500150] = {
		designer = "宝箱",
		notes = "凌云踏洞窟-鬼市子-关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500151] = {
		designer = "宝箱",
		notes = "宝箱-鸢之翼",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500152] = {
		designer = "宝箱",
		notes = "宝箱-鸢之腹",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500153] = {
		designer = "宝箱",
		notes = "宝箱-鸢之首",
		wanfa_types = { 9 },
		has_reward = true,
		save_type = 2,
		space = "s1",
		reasons = { "has_reward", "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500154] = {
		designer = "宝箱",
		notes = "宝箱-术之玉",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500155] = {
		designer = "宝箱",
		notes = "宝箱-器之玉",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500156] = {
		designer = "宝箱",
		notes = "宝箱-道之玉",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500158] = {
		designer = "宝箱",
		notes = "A52天虎军营地普通宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500160] = {
		designer = "宝箱",
		notes = "赵普宅秘籍宝箱",
		wanfa_types = { 9 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward", "wanfa_9" },
	},
	[4500162] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-清河（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500163] = {
		designer = "宝箱",
		notes = "【正式】木制三品宝箱-清河（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500164] = {
		designer = "",
		notes = "将军祠-战斗-四品宝箱（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500165] = {
		designer = "宝箱",
		notes = "【正式】金制一品宝箱-古渠",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500166] = {
		designer = "孙佳楠",
		notes = "【正式】铁制二品宝箱-开封（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500167] = {
		designer = "孙佳楠",
		notes = "【正式】木制三品宝箱-开封（无追踪标）",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500168] = {
		designer = "宝箱",
		notes = "【正式】木制四品宝箱-开封",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500172] = {
		designer = "宝箱",
		notes = "醉花阴-一品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500173] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-开封（短追踪距离）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500174] = {
		designer = "宝箱",
		notes = "【正式】木制三品宝箱-开封（短追踪距离）",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500175] = {
		designer = "宝箱",
		notes = "【正式】木制四品宝箱-开封（短追踪距离）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500179] = {
		designer = "宝箱",
		notes = "偷师洞窟-时楼-武器宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500181] = {
		designer = "李嘉栋",
		notes = "鬼市子-阴兵借道-宝箱-铠甲",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500182] = {
		designer = "李嘉栋",
		notes = "鬼市子-阴兵借道-宝箱-长枪",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500183] = {
		designer = "李嘉栋",
		notes = "鬼市子-阴兵借道-宝箱-头盔",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500184] = {
		designer = "黄乐孳",
		notes = "宝箱",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9" },
	},
	[4500185] = {
		designer = "孙佳楠",
		notes = "【正式】三品珍宝匣-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500186] = {
		designer = "宝箱",
		notes = "【墨山道】蹊跷-麒麟甲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4500188] = {
		designer = "宝箱",
		notes = "开封大宋官兵营地宝箱-A19",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500189] = {
		designer = "",
		notes = "【无忧洞】金制一品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500193] = {
		designer = "宝箱",
		notes = "开封绣金楼营地宝箱-A5",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500194] = {
		designer = "宝箱",
		notes = "开封绿林营地宝箱-A11",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500195] = {
		designer = "宝箱",
		notes = "博浪沙怪物营地5-玄元教宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500196] = {
		designer = "宝箱",
		notes = "开封漕帮营地宝箱-16",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500203] = {
		designer = "袁国振",
		notes = "三更夫的假宝箱（门派任务道具）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4500204] = {
		designer = "俞立",
		notes = "熔炉外主线关卡-四品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500207] = {
		designer = "宝箱",
		notes = "奇术-回马枪-珍宝匣",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500208] = {
		designer = "宝箱",
		notes = "武庙定制-金制一品宝箱-道具投放（有追踪标）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4500209] = {
		designer = "宝箱",
		notes = "武庙定制-金制一品宝箱-钥匙投放（无追踪标）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500212] = {
		designer = "宝箱",
		notes = "开封-凌云踏洞窟-鬼市子关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500213] = {
		designer = "张俊杰",
		notes = "博浪沙-淤泥微解谜宝箱",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500214] = {
		designer = "宝箱",
		notes = "旧村营地1-大宋官兵-营地宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500215] = {
		designer = "",
		notes = "普通宝箱（野外）-瓷窑",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4500217] = {
		designer = "李弘扬",
		notes = "复合解谜-百草野-1宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9" },
	},
	[4500219] = {
		designer = "赵伟业",
		notes = "新手-推熊-宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4500220] = {
		designer = "宝箱",
		notes = "太仓粟-天泉偷师-武器宝箱-30级陌刀",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500221] = {
		designer = "宝箱",
		notes = "【正式】金制一品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500222] = {
		designer = "宝箱",
		notes = "【正式】木制四品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500224] = {
		designer = "宝箱",
		notes = "【测试】木制三品宝箱-开封（短追踪距离）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500225] = {
		designer = "宝箱",
		notes = "偷师-九流门洞窟-一品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500226] = {
		designer = "宝箱",
		notes = "偷师-无心谷-宝箱一品",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500227] = {
		designer = "陈晓翰",
		notes = "金明池关卡-万事知-万华终陨-宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4500228] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-开封",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500229] = {
		designer = "宝箱",
		notes = "关底宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500232] = {
		designer = "宝箱",
		notes = "万古一人殿-【正式】铁制二品宝箱-开封-追忆装备-红袖环",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500233] = {
		designer = "宝箱",
		notes = "追忆装备-红袖甲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4500234] = {
		designer = "宝箱",
		notes = "追忆装备-投龙简",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4500241] = {
		designer = "宝箱",
		notes = "鬼吹灯摸宝宝箱-实际一品",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500246] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-开封（短追踪距离）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500247] = {
		designer = "宝箱",
		notes = "【正式】金制一品宝箱-鬼新娘结尾",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500248] = {
		designer = "石九亮",
		notes = "追忆装备-严奇人宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4500294] = {
		designer = "宝箱",
		notes = "凤首铜圆壶-2凹槽",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4500299] = {
		designer = "宝箱",
		notes = "【正式】金制一品宝箱-清河",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500300] = {
		designer = "宝箱",
		notes = "【正式】铁制二品宝箱-清河",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500301] = {
		designer = "宝箱",
		notes = "三品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4500302] = {
		designer = "宝箱",
		notes = "四品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4501000] = {
		designer = "宝箱",
		notes = "【正式】一品宝箱-不见山",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4501001] = {
		designer = "宝箱",
		notes = "【正式】二品宝箱-不见山",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4501002] = {
		designer = "宝箱",
		notes = "【正式】三品宝箱-不见山",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4501003] = {
		designer = "宝箱",
		notes = "【不见山】四品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2", "wanfa_tag" },
	},
	[4501006] = {
		designer = "宝箱",
		notes = "双峰岛-土匪营地2-三品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[4600083] = {
		designer = "梁程宏",
		notes = "孤云遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4600103] = {
		designer = "梁程宏",
		notes = "化龙丹方",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4600104] = {
		designer = "梁程宏",
		notes = "墨山道机关兽",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4600132] = {
		designer = "胡健力",
		notes = "张家旧宅遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700013] = {
		designer = "",
		notes = "搬石像-底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700020] = {
		designer = "",
		notes = "搬石像-场景石像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700023] = {
		designer = "鲍文旭",
		notes = "法华禅院-弓箭黑衣人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700039] = {
		designer = "",
		notes = "北盟遗址-烈不尽",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700040] = {
		designer = "",
		notes = "北盟遗址-烈不灭 ",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700054] = {
		designer = "",
		notes = "北盟遗址-张豹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4700058] = {
		designer = "鲍文旭",
		notes = "北盟遗址-机关2绳",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700059] = {
		designer = "鲍文旭",
		notes = "北盟遗址-机关2长矛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700060] = {
		designer = "鲍文旭",
		notes = "北盟遗址-机关1长矛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700061] = {
		designer = "鲍文旭",
		notes = "北盟遗址-点火机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700063] = {
		designer = "鲍文旭",
		notes = "北盟遗址-开门机关空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700064] = {
		designer = "鲍文旭",
		notes = "【常平仓地下】北盟遗址-地下水车-临时",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700066] = {
		designer = "鲍文旭",
		notes = "空entity-1010192-调查水车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4700067] = {
		designer = "鲍文旭",
		notes = "空entity-1010193-调查将军尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4700068] = {
		designer = "鲍文旭",
		notes = "空entity-1010194-调查桌上地图",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700069] = {
		designer = "鲍文旭",
		notes = "空entity-1010196-调查契丹尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700071] = {
		designer = "鲍文旭",
		notes = "红尘无眼-箭袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4700073] = {
		designer = "俞立",
		notes = "红尘无眼-伤害来源",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4700086] = {
		designer = "鲍文旭",
		notes = "北盟遗址-点火机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4810011] = {
		designer = "生态物种",
		notes = "菌子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4834002] = {
		designer = "生态物种",
		notes = "灰狼-头目(含团队行为规划)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4834003] = {
		designer = "生态物种",
		notes = "灰狼-随从(含团队行为规划)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4835001] = {
		designer = "周一舟",
		notes = "大鹅（静态）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900028] = {
		designer = "",
		notes = "曼陀罗花1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900030] = {
		designer = "",
		notes = "曼陀罗花2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900039] = {
		designer = "",
		notes = "据点-笼子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900071] = {
		designer = "",
		notes = "妙妙喵-石像圆盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900072] = {
		designer = "孙浩声",
		notes = "妙妙喵-石像圆盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900087] = {
		designer = "孙浩声",
		notes = "妙妙喵-解穴-提示书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900098] = {
		designer = "",
		notes = "妙妙喵-忘川河石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900100] = {
		designer = "",
		notes = "妙妙喵-新供奉玩法-佛像B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900101] = {
		designer = "",
		notes = "妙妙喵-新供奉玩法-佛像C",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900108] = {
		designer = "",
		notes = "妙妙喵-新供奉玩法-宝藏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4900109] = {
		designer = "孙浩声",
		notes = "北盟遗址-张豹藏宝图宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4900114] = {
		designer = "",
		notes = "北盟遗址-火炬",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900115] = {
		designer = "",
		notes = "北盟遗址-转动石像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900116] = {
		designer = "",
		notes = "北盟遗址-位移的石块-万",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900119] = {
		designer = "",
		notes = "烈言遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900127] = {
		designer = "",
		notes = "北盟遗址-离开密室",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900128] = {
		designer = "任宽",
		notes = "北盟遗址-石块底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900129] = {
		designer = "",
		notes = "北盟遗址-窃听A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900130] = {
		designer = "",
		notes = "北盟遗址-位移的石块-水",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900131] = {
		designer = "",
		notes = "北盟遗址-位移的石块-千",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900132] = {
		designer = "",
		notes = "北盟遗址-位移的石块-山",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900133] = {
		designer = "",
		notes = "北盟遗址-位移的石块-锦",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900134] = {
		designer = "",
		notes = "北盟遗址-位移的石块-绣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900135] = {
		designer = "",
		notes = "北盟遗址-位移的石块-山",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900136] = {
		designer = "",
		notes = "北盟遗址-位移的石块-河",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900137] = {
		designer = "",
		notes = "北盟遗址-位移的石块-寸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900138] = {
		designer = "",
		notes = "北盟遗址-位移的石块-草",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900139] = {
		designer = "",
		notes = "北盟遗址-位移的石块-不",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900140] = {
		designer = "",
		notes = "北盟遗址-位移的石块-生",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900141] = {
		designer = "",
		notes = "北盟遗址-位移的石块-土",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900142] = {
		designer = "",
		notes = "北盟遗址-位移的石块-流",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900143] = {
		designer = "",
		notes = "北盟遗址-位移的石块-漂",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900144] = {
		designer = "",
		notes = "北盟遗址-位移的石块-橹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900145] = {
		designer = "",
		notes = "北盟遗址-位移的石块-海",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900146] = {
		designer = "",
		notes = "北盟遗址-位移的石块-誓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900147] = {
		designer = "",
		notes = "北盟遗址-位移的石块-山",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900148] = {
		designer = "",
		notes = "北盟遗址-位移的石块-盟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900149] = {
		designer = "",
		notes = "北盟遗址-位移的石块-同",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900150] = {
		designer = "",
		notes = "北盟遗址-位移的石块-生",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900151] = {
		designer = "",
		notes = "北盟遗址-位移的石块-共",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900152] = {
		designer = "",
		notes = "北盟遗址-位移的石块-死",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900153] = {
		designer = "",
		notes = "北盟遗址-位移的石块-百",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900154] = {
		designer = "",
		notes = "北盟遗址-位移的石块-折",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900155] = {
		designer = "",
		notes = "北盟遗址-位移的石块-不",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900156] = {
		designer = "",
		notes = "北盟遗址-位移的石块-回",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900157] = {
		designer = "",
		notes = "北盟遗址-位移的石块-移",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900158] = {
		designer = "",
		notes = "北盟遗址-位移的石块-天",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900159] = {
		designer = "",
		notes = "北盟遗址-位移的石块-易",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900160] = {
		designer = "",
		notes = "北盟遗址-位移的石块-日",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900169] = {
		designer = "",
		notes = "追忆装备宝箱-琴",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[4900170] = {
		designer = "",
		notes = "追忆装备宝箱-盔甲",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4900182] = {
		designer = "孙浩声",
		notes = "太极武林录-阴阳盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900184] = {
		designer = "孙浩声",
		notes = "太极武林录-玄武雕像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900186] = {
		designer = "孙浩声",
		notes = "太极武林录-白虎雕像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900187] = {
		designer = "孙浩声",
		notes = "太极武林录-机关底盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900193] = {
		designer = "宝箱",
		notes = "太极武林录-叙事宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[4900195] = {
		designer = "孙浩声",
		notes = "太极武林录-传送点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900201] = {
		designer = "孙浩声",
		notes = "千斤坠解谜-神龛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900207] = {
		designer = "孙浩声",
		notes = "太极武林录-奇术书册（模型）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900208] = {
		designer = "孙浩声",
		notes = "太极武林录-拜请书（模型）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900256] = {
		designer = "张筱诺",
		notes = "将军祠-火焰触发器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900257] = {
		designer = "孙浩声",
		notes = "金明池-喷水装置",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900260] = {
		designer = "孙浩声",
		notes = "金明池-水面特效-墙面V2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900265] = {
		designer = "孙浩声",
		notes = "金明池-旋转板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900266] = {
		designer = "孙浩声",
		notes = "金明池-窗户木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900267] = {
		designer = "孙浩声",
		notes = "密室出口-门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900269] = {
		designer = "孙浩声",
		notes = "金明池-通道拉板-验收版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900276] = {
		designer = "蒙名恒",
		notes = "中山遗址分水机关启动开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900280] = {
		designer = "孙浩声",
		notes = "武庙-升起的雕像台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[4900285] = {
		designer = "孙浩声",
		notes = "金明池-卡住的电梯机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900289] = {
		designer = "孙浩声",
		notes = "金明池-限制铁门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900290] = {
		designer = "张俊杰",
		notes = "雕像台电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900293] = {
		designer = "孙浩声",
		notes = "复合解谜-拍照检测BOXdemo",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900294] = {
		designer = "孙浩声",
		notes = "复合解谜-槐树拍照打开",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900295] = {
		designer = "孙浩声",
		notes = "复合解谜-杀神壁画打开",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900296] = {
		designer = "孙浩声",
		notes = "复合解谜-渡口游侠打开",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900301] = {
		designer = "孙浩声",
		notes = "金明池-水道口水花特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900302] = {
		designer = "孙浩声",
		notes = "金明池-水道口流水特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900303] = {
		designer = "孙浩声",
		notes = "金明池-通道水流特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900304] = {
		designer = "孙浩声",
		notes = "金明池-拉杆机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900306] = {
		designer = "孙浩声",
		notes = "解谜洞窟-线索初始",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900307] = {
		designer = "孙浩声",
		notes = "解谜洞窟-线索终",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900308] = {
		designer = "孙浩声",
		notes = "解谜洞窟-开过的宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[4900309] = {
		designer = "孙浩声",
		notes = "解谜洞窟-大刺板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900312] = {
		designer = "孙浩声",
		notes = "金明池-暗线邀请函",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4900320] = {
		designer = "孙浩声",
		notes = "武庙-进入",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900326] = {
		designer = "孙浩声",
		notes = "解谜洞窟-水之道门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900327] = {
		designer = "孙浩声",
		notes = "解谜洞窟-水之道水渠门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900328] = {
		designer = "孙浩声",
		notes = "解谜洞窟-金玉手闸门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900329] = {
		designer = "孙浩声",
		notes = "解谜洞窟-竖直水流",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900330] = {
		designer = "张益豪",
		notes = "武庙-火焰灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900331] = {
		designer = "鲍文旭",
		notes = "地下水车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900332] = {
		designer = "孙浩声",
		notes = "萤火虫level",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900334] = {
		designer = "孙浩声",
		notes = "武庙-李筠甲胄",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900337] = {
		designer = "孙浩声",
		notes = "安息交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900338] = {
		designer = "孙浩声",
		notes = "解谜洞窟-水之道-传送点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900339] = {
		designer = "孙浩声",
		notes = "解谜洞窟-鬼新娘-传送点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900340] = {
		designer = "孙浩声",
		notes = "金明池-残破木鸢",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4900341] = {
		designer = "孙浩声",
		notes = "武庙-拉杆机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900345] = {
		designer = "孙浩声",
		notes = "鲁班祠地下-传送点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900346] = {
		designer = "模板表",
		notes = "胖梦傀（精英）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900347] = {
		designer = "杨翥宇",
		notes = "氛围怪-梦槐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900348] = {
		designer = "孙浩声",
		notes = "金明池-暗线邀请函",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[4900352] = {
		designer = "孙浩声",
		notes = "野外BOSS-无名将军触发剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900356] = {
		designer = "孙浩声",
		notes = "武庙-房梁护栏手搓版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900366] = {
		designer = "孙浩声",
		notes = "隐雾之狱-单向门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900368] = {
		designer = "孙浩声",
		notes = "隐雾之狱-进入1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900373] = {
		designer = "孙浩声",
		notes = "解谜洞窟-破碎地板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900389] = {
		designer = "孙浩声",
		notes = "临时修复石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900429] = {
		designer = "孙浩声",
		notes = "【隐雾之城】进入",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[4900444] = {
		designer = "孙浩声",
		notes = "悬河之墟前置-字条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000014] = {
		designer = "陈宸",
		notes = "菩提苦海-法鼓1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000015] = {
		designer = "陈宸",
		notes = "菩提苦海-法鼓2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000016] = {
		designer = "陈宸",
		notes = "菩提苦海-法鼓3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000023] = {
		designer = "陈宸",
		notes = "金玉手：交互点01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000024] = {
		designer = "陈宸",
		notes = "金玉手：交互点02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000025] = {
		designer = "陈宸",
		notes = "金玉手：交互点03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000066] = {
		designer = "陈宸",
		notes = "菩提苦海：张隐芒_鼓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000068] = {
		designer = "",
		notes = "追忆装备宝箱-严氏屋武器",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5000108] = {
		designer = "陈宸",
		notes = "天雄打坐兵-不主动03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000109] = {
		designer = "陈宸",
		notes = "天雄打坐兵-不主动04",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000110] = {
		designer = "陈宸",
		notes = "菩提苦海-复刷传送",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000135] = {
		designer = "陈宸",
		notes = "千佛村：残存的凤冠珠坠",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000136] = {
		designer = "陈宸",
		notes = "千佛村：儿童拨浪鼓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000137] = {
		designer = "陈宸",
		notes = "千佛村：一封旧信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000138] = {
		designer = "陈宸",
		notes = "千佛村：佛石像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000139] = {
		designer = "陈宸",
		notes = "千佛村：石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000140] = {
		designer = "陈宸",
		notes = "千佛村：天外精石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5000180] = {
		designer = "陈宸",
		notes = "将军祠_尸体交互投放奇术",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5000248] = {
		designer = "",
		notes = "将军祠-出口房间-三品宝箱（追忆装备护符）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5010000] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱01",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010001] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱02",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010002] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱03",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010003] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱04",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010004] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱05",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010005] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱06",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010006] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱07",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010007] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱08",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010008] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱09",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010009] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱10",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010010] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱11",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010011] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱12",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010012] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱13",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010013] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱14",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010014] = {
		designer = "陈宸",
		notes = "菩提苦海：冒泡宝箱15",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010015] = {
		designer = "陈宸",
		notes = "菩提苦海：佛光玉宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010016] = {
		designer = "陈宸",
		notes = "燕云别馆：魏仁浦心法01",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010017] = {
		designer = "陈宸",
		notes = "燕云别馆：魏仁浦心法02",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[5010018] = {
		designer = "陈宸",
		notes = "燕云别馆：魏仁浦心法03",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[5010019] = {
		designer = "陈宸",
		notes = "燕云别馆：魏仁浦心法04",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[5010020] = {
		designer = "陈宸",
		notes = "燕云别馆：魏仁浦心法05",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[5010023] = {
		designer = "鲍文旭",
		notes = "新手小屋追忆装备",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5010024] = {
		designer = "",
		notes = "地宫宝箱增补1",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010025] = {
		designer = "",
		notes = "地宫宝箱增补2",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[5010026] = {
		designer = "王思越",
		notes = "村落追忆装备平安喜乐配",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5010027] = {
		designer = "",
		notes = "春秋别馆-博物-绘画解锁宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5010028] = {
		designer = "",
		notes = "菩提苦海全家福",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5100002] = {
		designer = "",
		notes = "奇术-鸟巢（投食观察点）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5100022] = {
		designer = "",
		notes = "奇术-铜钟-将军祠里面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5100023] = {
		designer = "",
		notes = "奇术-铜钟-将军祠外围",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5100025] = {
		designer = "",
		notes = "奇术-铜钟-佛爷寨",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5100026] = {
		designer = "",
		notes = "奇术-铜钟-荒魂村和鹿食岭界碑中间",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5100033] = {
		designer = "吴小莹",
		notes = "监狱-狱材打造-打造台-清河",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[5100035] = {
		designer = "",
		notes = "监狱-氛围-古琴-清河",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[5100202] = {
		designer = "吴小莹",
		notes = "【叶子戏-桌搭】叶子牌（纯模型）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[5100208] = {
		designer = "吴小莹",
		notes = "【叶子戏-桌子】",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[5100209] = {
		designer = "",
		notes = "叶子戏-PVP-开封",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[5210010] = {
		designer = "王智超",
		notes = "B24绿林弓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210011] = {
		designer = "丁纪文",
		notes = "隐月山-绿林-持刀-弱A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210012] = {
		designer = "丁纪文",
		notes = "隐月山-绿林-持刀-弱B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210020] = {
		designer = "丁纪文",
		notes = "隐月山-绿林-弓-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210021] = {
		designer = "储一民",
		notes = "B9草贼弓弱A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210042] = {
		designer = "储一民",
		notes = "白草野-绿林-弱B-7",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210100] = {
		designer = "丁纪文",
		notes = "隐月山-绣金楼-火把和刀-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210101] = {
		designer = "丁纪文",
		notes = "白草野-秀金楼-弱A-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210102] = {
		designer = "丁纪文",
		notes = "隐月山-绣金楼-火把和刀-弱B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210110] = {
		designer = "储一民",
		notes = "复合解谜-绣金楼-绝阴部精英-镰刀-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210190] = {
		designer = "储一民",
		notes = "大世界-佛爷寨-酒肉和尚-弓箭-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210202] = {
		designer = "储一民",
		notes = "隐月山-绿林-持刀-弱B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210292] = {
		designer = "储一民",
		notes = "大世界-狼-弱B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210350] = {
		designer = "储一民",
		notes = "B15绣金火弓无弱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5210360] = {
		designer = "储一民",
		notes = "大世界-佛爷寨-酒肉和尚精英-月牙铲-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300118] = {
		designer = "",
		notes = "掌心采花-佛像调查",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300120] = {
		designer = "",
		notes = "掌心采花-采花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5300122] = {
		designer = "",
		notes = "妙妙喵枯树",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300124] = {
		designer = "",
		notes = "塔顶荷花-佛像调查",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300131] = {
		designer = "",
		notes = "打乱画像-佛像调查",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300178] = {
		designer = "王智超",
		notes = "14号绿林洞穴-门口守卫A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300179] = {
		designer = "王智超",
		notes = "14号绿林洞穴-门口守卫B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300195] = {
		designer = "王智超",
		notes = "燕云民兵洞口巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300196] = {
		designer = "王智超",
		notes = "燕云民兵洞口巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300490] = {
		designer = "",
		notes = "太仓粟清心圃野怪绣金楼B1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300500] = {
		designer = "王智超",
		notes = "隐月山-绣金楼-火把和刀-无弱点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300520] = {
		designer = "王智超",
		notes = "（将军祠上）大世界-绣金楼-绝阴部弟子-火把和刀-弱A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300530] = {
		designer = "",
		notes = "太仓粟鹰愁岭野怪绿林B46",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300540] = {
		designer = "",
		notes = "太仓粟雾隐林野怪绿林B34",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300600] = {
		designer = "",
		notes = "太仓粟清心圃野怪绣金楼B2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5300622] = {
		designer = "",
		notes = "太仓粟东郊野怪绿林B17",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400112] = {
		designer = "赵伟业",
		notes = "蒲团",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400201] = {
		designer = "",
		notes = "话术npc-贾仁",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400202] = {
		designer = "",
		notes = "话术npc-戒莲",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400203] = {
		designer = "",
		notes = "话术npc-静衍",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400204] = {
		designer = "",
		notes = "话术npc-叶惜花",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400205] = {
		designer = "",
		notes = "话术npc-江缘起",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400206] = {
		designer = "",
		notes = "话术npc-公孙龙",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400207] = {
		designer = "",
		notes = "话术npc-梁大有",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400208] = {
		designer = "",
		notes = "话术npc-良心龙虎寨盗贼",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400209] = {
		designer = "",
		notes = "话术npc-书生陆有方",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400210] = {
		designer = "",
		notes = "话术npc-刘婶",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400211] = {
		designer = "",
		notes = "话术npc-胡百里",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400213] = {
		designer = "",
		notes = "话术npc-王狗子",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400215] = {
		designer = "",
		notes = "话术npc-钓鱼老头",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5400216] = {
		designer = "",
		notes = "悬壶npc-毛大",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400217] = {
		designer = "",
		notes = "悬壶npc-毛二",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400218] = {
		designer = "",
		notes = "悬壶npc-酒伯",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400219] = {
		designer = "",
		notes = "悬壶npc-阿丹",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400220] = {
		designer = "",
		notes = "悬壶npc-丰野",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400221] = {
		designer = "",
		notes = "悬壶npc-刘顺子",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400222] = {
		designer = "",
		notes = "悬壶npc-周振岩",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400223] = {
		designer = "",
		notes = "悬壶npc-谢惟祖",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400224] = {
		designer = "",
		notes = "悬壶npc-何藕娘",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400225] = {
		designer = "",
		notes = "悬壶npc-孙半城",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400228] = {
		designer = "赵伟业",
		notes = "悬壶npc-刘鞋儿",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400229] = {
		designer = "赵伟业",
		notes = "悬壶npc-流浪乞丐",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400230] = {
		designer = "赵伟业",
		notes = "悬壶npc-昏迷的和尚",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400245] = {
		designer = "",
		notes = "追忆装备宝箱-千机匣武器",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5400246] = {
		designer = "",
		notes = "追忆装备宝箱-衣冠冢护符",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5400247] = {
		designer = "",
		notes = "追忆装备宝箱-医馆一楼腰带",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5400266] = {
		designer = "赵伟业",
		notes = "悬壶npc-天泉弟子叶明远",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5400272] = {
		designer = "",
		notes = "荧渊-实验室-二品宝箱（奇术枯骨）",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[5400288] = {
		designer = "",
		notes = "斑驳的遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400289] = {
		designer = "",
		notes = "静难的包袱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400290] = {
		designer = "",
		notes = "叶万山的匕首",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400414] = {
		designer = "孙浩声",
		notes = "北盟遗址-火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400578] = {
		designer = "赵伟业",
		notes = "红尘无眼尸体道具1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400579] = {
		designer = "赵伟业",
		notes = "红尘无眼尸体道具2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400580] = {
		designer = "赵伟业",
		notes = "红尘无眼尸体道具3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400583] = {
		designer = "赵伟业",
		notes = "绝笔信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[5400587] = {
		designer = "赵伟业",
		notes = "红尘无言-红衣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400588] = {
		designer = "赵伟业",
		notes = "红尘无言-书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400590] = {
		designer = "赵伟业",
		notes = "偷师洞窟-石碑1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400591] = {
		designer = "赵伟业",
		notes = "偷师洞窟-书信1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400593] = {
		designer = "赵伟业",
		notes = "偷师洞窟-书信1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400597] = {
		designer = "赵伟业",
		notes = "红尘无眼包袱（空模型）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5400848] = {
		designer = "模板表",
		notes = "世界等级战斗动物模板-大鹅（精英）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5401023] = {
		designer = "施天来",
		notes = "疾病NPC-丁巳",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5401024] = {
		designer = "施天来",
		notes = "话术NPC-喜儿",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[5401025] = {
		designer = "施天来",
		notes = "疾病NPC-文俊",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[5401433] = {
		designer = "",
		notes = "天不收椅子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5500091] = {
		designer = "陈凯",
		notes = "【常平仓地下】飞来锁平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800116] = {
		designer = "张益豪",
		notes = "【常平仓堡】城堡守备队长-点将台上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800117] = {
		designer = "张益豪",
		notes = "【常平仓堡】粮仓门卫-陌刀卫（右）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800120] = {
		designer = "张益豪",
		notes = "【常平仓堡】货区运粮兵-步兵（弩手）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800121] = {
		designer = "张益豪",
		notes = "【常平仓堡】货物停卸区-搬运工（步兵）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800156] = {
		designer = "张益豪",
		notes = "《地下粮仓》-寒菌梦傀-铡草刀（精英）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800157] = {
		designer = "",
		notes = "太仓粟雾隐林野怪梦傀B33",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800180] = {
		designer = "张益豪",
		notes = "球形菌团",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800181] = {
		designer = "张益豪",
		notes = "椭圆形菌团",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5800182] = {
		designer = "张益豪",
		notes = "圆锥形菌团",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900004] = {
		designer = "陈凯",
		notes = "可以烧的洞窟PK荆棘（1.3）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900005] = {
		designer = "陈凯",
		notes = "可以烧的洞窟PK荆棘（1.8）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900017] = {
		designer = "陈凯",
		notes = "荆棘吊桥-测试（荆棘）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900018] = {
		designer = "张筱诺",
		notes = "[喵]跳水坛-临时木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900022] = {
		designer = "陈凯",
		notes = "荆棘吊桥-测试（45度吊桥）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900025] = {
		designer = "陈凯",
		notes = "TBG-飞来索-P1-移动平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900030] = {
		designer = "陈凯",
		notes = "TBG-飞来索-P1-起",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900032] = {
		designer = "陈凯",
		notes = "电梯绳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900035] = {
		designer = "陈凯",
		notes = "大型电梯绳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900037] = {
		designer = "陈凯",
		notes = "点火机关-可燃物组件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900038] = {
		designer = "陈凯",
		notes = "点火机关-柱子机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900043] = {
		designer = "陈凯",
		notes = "铁链匣挂接点测试（墨山道）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900044] = {
		designer = "陈凯",
		notes = "同天匣（测试-可丢）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900046] = {
		designer = "陈凯",
		notes = "潜水钟测试（墨山道）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900047] = {
		designer = "陈凯",
		notes = "同天匣（临时-默认可Z）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900048] = {
		designer = "陈凯",
		notes = "黄钟钟摆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900052] = {
		designer = "陈凯",
		notes = "铁链匣测试（墨山道）-3节铁链版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900060] = {
		designer = "陈凯",
		notes = "动力匣外观",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900061] = {
		designer = "陈凯",
		notes = "铁链匣测试（墨山道）-7节铁链版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900065] = {
		designer = "张筱诺",
		notes = "TBG-旋转轨道（P1）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900066] = {
		designer = "王治",
		notes = "MSD天工地窟005-P1-流水轨道组件-双页",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900067] = {
		designer = "华中承",
		notes = "MSD天工地窟005-P3-压力板-移动平台01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900068] = {
		designer = "王治",
		notes = "MSD天工地窟005-P2-传动匣-上半部分",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900069] = {
		designer = "王治",
		notes = "MSD天工地窟005-P3-传动匣-下半部分",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900070] = {
		designer = "陈凯",
		notes = "MSD天工地窟005-P2传动匣上方铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900071] = {
		designer = "王治",
		notes = "MSD天工地窟005-P1-传动匣下方铁链-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900074] = {
		designer = "陈凯",
		notes = "TBG-挂接点P1-桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900075] = {
		designer = "陈凯",
		notes = "不见山-正式铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900078] = {
		designer = "陈凯",
		notes = "P4-发射环02左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900079] = {
		designer = "陈凯",
		notes = "铁链匣接收柱-铁环",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900080] = {
		designer = "陈凯",
		notes = "嗟叹崖-P4-发射柱-右-柱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900081] = {
		designer = "陈凯",
		notes = "P3-后-接受柱右",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900083] = {
		designer = "陈凯",
		notes = "墨山道-点穴机关鸟3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900084] = {
		designer = "陈凯",
		notes = "不见山天工地窟03-最终大门机关鸟_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900085] = {
		designer = "陈凯",
		notes = "不见山天工地窟03-最终大门机关鸟_3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900086] = {
		designer = "陈凯",
		notes = "墨山道-点穴机关鸟4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900087] = {
		designer = "陈凯",
		notes = "墨山道-底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900088] = {
		designer = "陈凯",
		notes = "传动匣上方铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900089] = {
		designer = "陈凯",
		notes = "不见山通用电梯-平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900116] = {
		designer = "陈凯",
		notes = "竖直滑索-站台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900117] = {
		designer = "陈凯",
		notes = "水平滑索-站台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900120] = {
		designer = "陈凯",
		notes = "双层石墙外层2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900124] = {
		designer = "任宽",
		notes = "压力板电梯箱体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900125] = {
		designer = "任宽",
		notes = "电梯-压力板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[5900203] = {
		designer = "陈凯",
		notes = "P1-发射环01左-铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6090019] = {
		designer = "梁子寒",
		notes = "红炉雅集-柜台测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6090020] = {
		designer = "梁子寒",
		notes = "红炉雅集-靠墙测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6090021] = {
		designer = "梁子寒",
		notes = "红炉雅集-看花测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6090050] = {
		designer = "梁子寒",
		notes = "偷师-狂澜-弟子1-巡逻测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6090054] = {
		designer = "梁子寒",
		notes = "偷师开门机关-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6090127] = {
		designer = "梁子寒",
		notes = "许愿池抽卡树-空交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6090201] = {
		designer = "梁子寒",
		notes = "据点清剿-宝剑机关-门口开启玩法-慈心山院",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6091013] = {
		designer = "梁子寒",
		notes = "叠罗汉鼓-起跳点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100039] = {
		designer = "华中承",
		notes = "金鸡独立-2001",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100058] = {
		designer = "华中承",
		notes = "电梯测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100059] = {
		designer = "华中承",
		notes = "【常平仓地下】电梯开关-呼叫开关2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100060] = {
		designer = "华中承",
		notes = "压力板-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100063] = {
		designer = "华中承",
		notes = "松动地板-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100067] = {
		designer = "华中承",
		notes = "太岳台-电梯中控",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100071] = {
		designer = "任宽",
		notes = "电梯开关-中控开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100072] = {
		designer = "华中承",
		notes = "大型电梯测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100073] = {
		designer = "华中承",
		notes = "炸药桶刷新机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100076] = {
		designer = "华中承",
		notes = "燕云别馆-大型电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100083] = {
		designer = "华中承",
		notes = "炸药桶（机关刷新-可破碎）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100097] = {
		designer = "华中承",
		notes = "万古一人殿-水龙首1层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100099] = {
		designer = "华中承",
		notes = "万古一人殿-喷水机关-压力板1层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100100] = {
		designer = "",
		notes = "水闸-叶轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6100101] = {
		designer = "华中承",
		notes = "万古一人殿-喷水机关结算entity-1层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100145] = {
		designer = "华中承",
		notes = "【常平仓地下】电梯开关-中控开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100164] = {
		designer = "华中承",
		notes = "朝生暮落花-普通花苞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100166] = {
		designer = "华中承",
		notes = "朝生暮落花-藤蔓墙1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100167] = {
		designer = "华中承",
		notes = "朝生暮落花-藤蔓墙2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100168] = {
		designer = "华中承",
		notes = "朝生暮落花-藤蔓墙3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6100178] = {
		designer = "华中承",
		notes = "电梯开关-呼叫开关（交互范围缩小版）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6200002] = {
		designer = "",
		notes = "认祖离宗-牌位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200006] = {
		designer = "",
		notes = "星火不熄-秘密信件（交互）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200008] = {
		designer = "",
		notes = "财神归位-财神像（交互）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200017] = {
		designer = "",
		notes = "稚子童戏-布娃娃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200019] = {
		designer = "",
		notes = "何日归家-长枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200126] = {
		designer = "凌佳欣",
		notes = "红尘无眼乔迁贺信（交互）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6200127] = {
		designer = "凌佳欣",
		notes = "追忆装备-素月护手-观察交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6200148] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-山月心事·田篇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200149] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-山月心事·黎篇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200150] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-寒夜梨花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200151] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-少年欢",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200152] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-无名刀法",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200155] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-天不收育娃往事",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200156] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-庙堂将倾",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200157] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-绣金舞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200158] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-一个江湖里的故事",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200159] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-秋月孤悬",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6200171] = {
		designer = "凌佳欣",
		notes = "清河cp书籍-惊鸿影",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6300031] = {
		designer = "任众",
		notes = "火中取栗-宝箱10-佛爷寨",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9" },
	},
	[6300049] = {
		designer = "任众",
		notes = "太岳台-电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300050] = {
		designer = "华中承",
		notes = "太岳台-电梯呼叫开关-上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300065] = {
		designer = "任众",
		notes = "妙妙喵-平衡中药-权衡-鬼市子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300073] = {
		designer = "任众",
		notes = "妙妙喵-平衡中药-交互开启天平玩法-鬼市子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300075] = {
		designer = "任众",
		notes = "武成王庙-墙刺板-朝左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300077] = {
		designer = "任众",
		notes = "假刺板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300084] = {
		designer = "任众",
		notes = "妙妙喵-步调一致-提示书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300085] = {
		designer = "任众",
		notes = "妙妙喵-救济之粮-提示书册",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300086] = {
		designer = "贺江婷",
		notes = "隔空取物-鹿潭-石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6300087] = {
		designer = "任众",
		notes = "妙妙喵-步调一致-木板2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300088] = {
		designer = "任众",
		notes = "妙妙喵-步调一致-柱子3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300091] = {
		designer = "任众",
		notes = "武成王庙-上升刺板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300092] = {
		designer = "任众",
		notes = "妙妙喵-步调一致-观众喵黑",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6300093] = {
		designer = "任众",
		notes = "妙妙喵-步调一致-观众喵白",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6300112] = {
		designer = "任众",
		notes = "武庙-镜像通道-左房间-偃月刀-偷袭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300113] = {
		designer = "任众",
		notes = "武庙-拐角后区域-突火枪2-守卫",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300114] = {
		designer = "任众",
		notes = "武庙-金钲间-偃月刀精英-窃听对象",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300115] = {
		designer = "任众",
		notes = "武庙-镜像通道-左房间-偃月刀-看信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300116] = {
		designer = "任众",
		notes = "武庙-正殿-枪盾精英-观察",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300117] = {
		designer = "任众",
		notes = "武庙-正殿-偃月刀精英-观察",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300118] = {
		designer = "任众",
		notes = "武庙-正殿-旗帜号角-等待",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300125] = {
		designer = "任众",
		notes = "武庙-左通道天台-突火枪1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300128] = {
		designer = "任众",
		notes = "武庙-右通道天台-突火枪1-守宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300255] = {
		designer = "任众",
		notes = "墨城旧址 野怪 穷奇师盾戟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6300256] = {
		designer = "任众",
		notes = "碧水云涛 野怪 穷奇师弩炮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400001] = {
		designer = "张联鑫",
		notes = "佛光顶深洞洞底折射机关（用来转）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400009] = {
		designer = "张联鑫",
		notes = "佛光顶铜镜房间折射机关1（用来转）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400101] = {
		designer = "张联鑫",
		notes = "太极武林录-石玦",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6400102] = {
		designer = "张联鑫",
		notes = "太极钟塔底部传送空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400104] = {
		designer = "张联鑫",
		notes = "北盟遗址敌人-单刀-普通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400105] = {
		designer = "闫菲",
		notes = "北盟遗址上方休息怪2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400106] = {
		designer = "闫菲",
		notes = "北盟遗址看东北弓兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400108] = {
		designer = "张联鑫",
		notes = "易碎地板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400111] = {
		designer = "张联鑫",
		notes = "佛光顶-折射机关（悬挂式）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400115] = {
		designer = "张联鑫",
		notes = "佛光顶铜人怪4-房间2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400116] = {
		designer = "张联鑫",
		notes = "佛光顶-藏经阁佛像调查空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400117] = {
		designer = "张联鑫",
		notes = "佛光顶-宝相花-藏经阁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400120] = {
		designer = "张联鑫",
		notes = "佛光顶-僧人幻影-罗汉堂地下",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400121] = {
		designer = "张联鑫",
		notes = "佛光顶-解谜房正确佛像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400126] = {
		designer = "张联鑫",
		notes = "佛光顶-墙面刻字1-空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400127] = {
		designer = "张联鑫",
		notes = "佛光顶-墙面刻字2-空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400128] = {
		designer = "张联鑫",
		notes = "佛光顶-墙面刻字3-空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400129] = {
		designer = "张联鑫",
		notes = "佛光顶-落石粉尘空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400132] = {
		designer = "张联鑫",
		notes = "佛光顶-道具拾取-大佛顶首楞严经",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6400133] = {
		designer = "张联鑫",
		notes = "佛光顶-道具拾取-金箔残末",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6400134] = {
		designer = "张联鑫",
		notes = "佛光顶-道具拾取-画匠手抄本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6400135] = {
		designer = "张联鑫",
		notes = "佛光顶-场景交互-打窟人刻字",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400136] = {
		designer = "张联鑫",
		notes = "佛光顶-过道粉尘空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400143] = {
		designer = "张联鑫",
		notes = "太平钟楼-天泉刀法交互空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400144] = {
		designer = "张联鑫",
		notes = "太平钟楼-飘带交互空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400145] = {
		designer = "张联鑫",
		notes = "太平钟楼-柳叶标交互空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400155] = {
		designer = "张联鑫",
		notes = "佛光顶铜镜房间折射机关6（用来转）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400161] = {
		designer = "张联鑫",
		notes = "佛光顶铜镜房间折射机关5（监听点穴）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400162] = {
		designer = "张联鑫",
		notes = "佛光顶铜镜房间折射机关1（监听点穴）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400163] = {
		designer = "张联鑫",
		notes = "太平钟楼-楼顶储清泉书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400165] = {
		designer = "张联鑫",
		notes = "太平钟楼-一层石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400166] = {
		designer = "张联鑫",
		notes = "佛光顶铜人怪5-房间2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400171] = {
		designer = "张联鑫",
		notes = "佛光顶铜镜房间折射机关5（用来转）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400175] = {
		designer = "张联鑫",
		notes = "太平钟楼-四层破损交互空entity\n",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400176] = {
		designer = "张联鑫",
		notes = "太平钟楼-顶层刻字交互空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400177] = {
		designer = "张联鑫",
		notes = "太平钟楼-寒香寻布条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400181] = {
		designer = "张联鑫",
		notes = "佛光顶-佛光塔-木板门开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400182] = {
		designer = "",
		notes = "北盟遗址-将军尸体旁置景宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[6400212] = {
		designer = "张联鑫",
		notes = "太平钟楼-柳叶标（不扫光）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400234] = {
		designer = "张联鑫",
		notes = "佛光顶-水路尽头堵路用的石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6400249] = {
		designer = "张联鑫",
		notes = "太平钟楼-攀登用脚手架",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500006] = {
		designer = "丁纪文",
		notes = "老鼠洞氛围交互物-灵位1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500007] = {
		designer = "丁纪文",
		notes = "老鼠洞氛围交互物-灵位2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500008] = {
		designer = "丁纪文",
		notes = "老鼠洞氛围交互物-药方",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500021] = {
		designer = "丁纪文",
		notes = "奇遇佛花小屋外围巡逻1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500022] = {
		designer = "丁纪文",
		notes = "奇遇下-收花信徒乙-战斗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500023] = {
		designer = "丁纪文",
		notes = "奇遇下-收花信徒氛围1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500041] = {
		designer = "丁纪文",
		notes = "奇怪的木盒-苦海万事知",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500042] = {
		designer = "丁纪文",
		notes = "一封密信-苦海万事知",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500044] = {
		designer = "丁纪文",
		notes = "菩提苦海-石碑交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500056] = {
		designer = "丁纪文",
		notes = "吉小鼠灵位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500057] = {
		designer = "丁纪文",
		notes = "笼子-关吉小鼠的爹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500059] = {
		designer = "丁纪文",
		notes = "偷师明川药典-石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500060] = {
		designer = "丁纪文",
		notes = "偷师青山执笔-信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[6500061] = {
		designer = "丁纪文",
		notes = "永福禅院花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500062] = {
		designer = "丁纪文",
		notes = "法华禅寺花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500063] = {
		designer = "丁纪文",
		notes = "慈心山院花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500064] = {
		designer = "丁纪文",
		notes = "妙善圣僧花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500065] = {
		designer = "丁纪文",
		notes = "龟鹤齐寿花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500066] = {
		designer = "丁纪文",
		notes = "龟龄鹤寿花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500067] = {
		designer = "丁纪文",
		notes = "福寿延长花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500068] = {
		designer = "丁纪文",
		notes = "福德长寿花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500069] = {
		designer = "丁纪文",
		notes = "五男二女花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500070] = {
		designer = "丁纪文",
		notes = "忠孝传家花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500071] = {
		designer = "",
		notes = "明皇御影花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500072] = {
		designer = "丁纪文",
		notes = "清河肖孺花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500073] = {
		designer = "丁纪文",
		notes = "汉将李广花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500074] = {
		designer = "丁纪文",
		notes = "秦将白起花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500075] = {
		designer = "丁纪文",
		notes = "吴将孙武花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500076] = {
		designer = "丁纪文",
		notes = "赵骑特勒花钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500089] = {
		designer = "丁纪文",
		notes = "猫毛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500095] = {
		designer = "丁纪文",
		notes = "残破的秘籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6500125] = {
		designer = "丁纪文",
		notes = "黑煞阴阳-石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500212] = {
		designer = "丁纪文",
		notes = "朱鱼手札",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500213] = {
		designer = "丁纪文",
		notes = "朱鱼遗书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500330] = {
		designer = "袁国振",
		notes = "饭碗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500350] = {
		designer = "丁纪文",
		notes = "进入梦中世界道具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500454] = {
		designer = "丁纪文",
		notes = "君不见",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500455] = {
		designer = "丁纪文",
		notes = "君不见",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500481] = {
		designer = "丁纪文",
		notes = "别馆蜡烛1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6500482] = {
		designer = "丁纪文",
		notes = "别馆蜡烛2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510000] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围2-火把1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510001] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围4-弓箭1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510002] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围5-镰刀精英",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510003] = {
		designer = "孙亦鸣",
		notes = "燕云别馆-1层电梯井-跳下来敌人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510004] = {
		designer = "丁纪文",
		notes = "燕云别馆2内部3-仆人-燕新",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510006] = {
		designer = "丁纪文",
		notes = "隐龙石碑-交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510007] = {
		designer = "丁纪文",
		notes = "陈旧的请帖-交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510008] = {
		designer = "丁纪文",
		notes = "举荐书-交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510009] = {
		designer = "丁纪文",
		notes = "密信-交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510013] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围4-弓箭1-窃听",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510015] = {
		designer = "丁纪文",
		notes = "燕云别馆3外围2-弓箭1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510021] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围1-弓箭1-氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6510022] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围1-弓箭3-氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6510023] = {
		designer = "丁纪文",
		notes = "燕云别馆1外围1-弓箭2-氛围尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6510028] = {
		designer = "丁纪文",
		notes = "猴子怪-别馆用-高处跳下",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510029] = {
		designer = "丁纪文",
		notes = "旋转灯架交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510036] = {
		designer = "丁纪文",
		notes = "陈列架调查物1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510037] = {
		designer = "丁纪文",
		notes = "陈列架调查物2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510038] = {
		designer = "丁纪文",
		notes = "陈列架调查物3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510039] = {
		designer = "丁纪文",
		notes = "陈列架调查物4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510043] = {
		designer = "丁纪文",
		notes = "小十七的日记·壹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510044] = {
		designer = "丁纪文",
		notes = "燕云遗民清单",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510045] = {
		designer = "丁纪文",
		notes = "契丹文书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510046] = {
		designer = "丁纪文",
		notes = "攘敌策",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510047] = {
		designer = "丁纪文",
		notes = "平边策",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510048] = {
		designer = "丁纪文",
		notes = "沙盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510049] = {
		designer = "丁纪文",
		notes = "地下二层开门空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510061] = {
		designer = "丁纪文",
		notes = "别馆回忆交互物-B3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510065] = {
		designer = "丁纪文",
		notes = "地下一层电梯机关-开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510066] = {
		designer = "丁纪文",
		notes = "地上二层追忆弓获取",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510067] = {
		designer = "丁纪文",
		notes = "地下一层-重型龙头机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510071] = {
		designer = "丁纪文",
		notes = "传送到小十七房间交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510073] = {
		designer = "丁纪文",
		notes = "普通老仆尸体1-交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6510075] = {
		designer = "丁纪文",
		notes = "悬剑刍议·壹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510076] = {
		designer = "丁纪文",
		notes = "悬剑刍议·贰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510077] = {
		designer = "丁纪文",
		notes = "小悬剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510085] = {
		designer = "丁纪文",
		notes = "小十七的日记2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6510087] = {
		designer = "丁纪文",
		notes = "醒骨纱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6511001] = {
		designer = "丁纪文",
		notes = "遗失的语录-妙善语录上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6511003] = {
		designer = "丁纪文",
		notes = "遗失的语录-妙善语录下",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6511004] = {
		designer = "丁纪文",
		notes = "遗失的语录-石盒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6511006] = {
		designer = "丁纪文",
		notes = "遗失的语录-石碑空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6511007] = {
		designer = "丁纪文",
		notes = "遗失的语录-石盒空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6511008] = {
		designer = "丁纪文",
		notes = "遗失的语录-石盒空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6511011] = {
		designer = "丁纪文",
		notes = "辟邪钱袋-钱袋1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6511012] = {
		designer = "丁纪文",
		notes = "辟邪钱袋-钱袋2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6511013] = {
		designer = "丁纪文",
		notes = "辟邪钱袋-钱袋3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600015] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_脾气差猫】-清河庙-七六",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600016] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_梦中情猫】-六一",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600018] = {
		designer = "黄乐孳",
		notes = "【猫_三花_脾气差猫】-二五",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600019] = {
		designer = "黄乐孳",
		notes = "【猫_三花_梦中情猫】-清河庙-九九",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600020] = {
		designer = "黄乐孳",
		notes = "【猫_白色_普通猫猫】-五九",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600022] = {
		designer = "黄乐孳",
		notes = "【猫_白色_梦中情猫】-十七",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600023] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_普通猫猫】-喵八",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600026] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_贴贴猫猫】-三二",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600027] = {
		designer = "黄乐孳",
		notes = "【猫_三花_贴贴猫猫】-四六",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600030] = {
		designer = "黄乐孳",
		notes = "将军祠-破碎墙体01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600031] = {
		designer = "任宽",
		notes = "电梯箱体-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600047] = {
		designer = "孙佳楠",
		notes = "破碎地板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600048] = {
		designer = "黄乐孳",
		notes = "破碎地板（框）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600050] = {
		designer = "黄乐孳",
		notes = "妙妙喵-鬼火（亮）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600058] = {
		designer = "黄乐孳",
		notes = "可爆破墙体-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600059] = {
		designer = "黄乐孳",
		notes = "宝箱-长剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600060] = {
		designer = "黄乐孳",
		notes = "宝箱-短剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600062] = {
		designer = "黄乐孳",
		notes = "甲胄调查",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600063] = {
		designer = "黄乐孳",
		notes = "宝箱-长剑提交",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600064] = {
		designer = "黄乐孳",
		notes = "宝箱-短剑提交",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600065] = {
		designer = "黄乐孳",
		notes = "调查1-剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600066] = {
		designer = "黄乐孳",
		notes = "调查2-剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600067] = {
		designer = "黄乐孳",
		notes = "调查1-枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600068] = {
		designer = "黄乐孳",
		notes = "调查2-枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600076] = {
		designer = "黄乐孳",
		notes = "火堆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600077] = {
		designer = "陈凯",
		notes = "飞来锁平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600079] = {
		designer = "黄乐孳",
		notes = "飞来锁开关-呼叫开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600090] = {
		designer = "黄乐孳",
		notes = "飞来锁移动平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600091] = {
		designer = "黄乐孳",
		notes = "解密洞窟启动器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600103] = {
		designer = "黄乐孳",
		notes = "绳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600104] = {
		designer = "黄乐孳",
		notes = "蜘蛛网",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600108] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_普通猫猫】-鬼市子-判官",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600109] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_脾气差猫】-鬼市子-无常",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600110] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_梦中情猫】-鬼市子-孟婆",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600111] = {
		designer = "黄乐孳",
		notes = "【猫_三花_普通猫猫】-勾栏瓦肆-小梨花",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600112] = {
		designer = "黄乐孳",
		notes = "【猫_三花_脾气差猫】-角门里-常富贵",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600113] = {
		designer = "黄乐孳",
		notes = "【猫_三花_梦中情猫】-勾栏瓦肆-懒懒",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600114] = {
		designer = "黄乐孳",
		notes = "【猫_白色_普通猫猫】-勾栏瓦肆-棠花",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600116] = {
		designer = "黄乐孳",
		notes = "【猫_白色_梦中情猫】-勾栏瓦肆-玄色",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600117] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_普通猫猫】-鬼市-鱼鳃",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600118] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_脾气差猫】-勾栏瓦肆-阿骨",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600119] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_梦中情猫】-鬼市-黄蜂",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600120] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_贴贴猫猫】-鬼市子-豹尾",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600121] = {
		designer = "黄乐孳",
		notes = "【猫_三花_贴贴猫猫】-鬼市子-鸟嘴",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600122] = {
		designer = "黄乐孳",
		notes = "【猫_三花_贴贴猫猫】-勾栏瓦肆-虎哥儿",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600123] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_贴贴猫猫】-开封-狸财神",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600143] = {
		designer = "黄乐孳",
		notes = "【猫_橘色_贴贴猫猫】-勾栏瓦肆-橘座",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600144] = {
		designer = "黄乐孳",
		notes = "【猫_三花_贴贴猫猫】-勾栏瓦肆-黑木叶",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600145] = {
		designer = "黄乐孳",
		notes = "【猫_白色_贴贴猫猫】-勾栏瓦肆-棉花球",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600183] = {
		designer = "黄乐孳",
		notes = "解谜洞窟大门指引标",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600184] = {
		designer = "黄乐孳",
		notes = "底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600197] = {
		designer = "黄乐孳",
		notes = "武城王庙-破碎地板A",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600198] = {
		designer = "黄乐孳",
		notes = "武城王庙-破碎地板B",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600211] = {
		designer = "黄乐孳",
		notes = "包裹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600225] = {
		designer = "黄乐孳",
		notes = "武城王庙-关闭机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600226] = {
		designer = "黄乐孳",
		notes = "操控台-移动",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600481] = {
		designer = "徐佳琦",
		notes = "金钲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600482] = {
		designer = "张俊杰",
		notes = "金玉手门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6600483] = {
		designer = "黄乐孳",
		notes = "金玉手门锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600484] = {
		designer = "黄乐孳",
		notes = "金玉手-定向金钲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600485] = {
		designer = "黄乐孳",
		notes = "喷火机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600486] = {
		designer = "黄乐孳",
		notes = "麻将桌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6600496] = {
		designer = "黄乐孳",
		notes = "金玉手门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600497] = {
		designer = "黄乐孳",
		notes = "金玉手门锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600500] = {
		designer = "黄乐孳",
		notes = "嗟叹崖-木板组件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600501] = {
		designer = "黄乐孳",
		notes = "位移石块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600521] = {
		designer = "李晨",
		notes = "鲁墨信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6600524] = {
		designer = "黄乐孳",
		notes = "麻将-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600525] = {
		designer = "",
		notes = "猫_橙-不羡仙摸猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600526] = {
		designer = "",
		notes = "猫_橙-佛光顶摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600527] = {
		designer = "",
		notes = "猫_黑（狸花）-千佛谷摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600528] = {
		designer = "",
		notes = "猫_白-佛光定摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600529] = {
		designer = "",
		notes = "白草野摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600530] = {
		designer = "",
		notes = "白草野摸猫3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600531] = {
		designer = "",
		notes = "白草野摸猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600532] = {
		designer = "",
		notes = "白草野摸猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600533] = {
		designer = "",
		notes = "白草野摸猫6",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600534] = {
		designer = "",
		notes = "白草野摸猫7",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600535] = {
		designer = "",
		notes = "白草野摸猫8",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600536] = {
		designer = "",
		notes = "白草野摸猫9",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600537] = {
		designer = "",
		notes = "听经猫1-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600538] = {
		designer = "",
		notes = "听经猫2-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600539] = {
		designer = "",
		notes = "听经猫3-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600540] = {
		designer = "",
		notes = "听经猫4-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600541] = {
		designer = "",
		notes = "听经猫5-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600542] = {
		designer = "",
		notes = "听经猫6-摸猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600543] = {
		designer = "",
		notes = "善妙舟新猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600544] = {
		designer = "",
		notes = "善妙舟新猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600545] = {
		designer = "黄乐孳",
		notes = "【猫_三花_梦中情猫】-琼林苑-太花",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600546] = {
		designer = "黄乐孳",
		notes = "【猫_白色_普通猫猫】-琼林苑-太白",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600646] = {
		designer = "黄乐孳",
		notes = "金钲-碎玉底座铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600647] = {
		designer = "黄乐孳",
		notes = "金钲-金钲铁链1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600732] = {
		designer = "黄乐孳",
		notes = "金钲-铁链底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600733] = {
		designer = "黄乐孳",
		notes = "金钲-架子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6600734] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_普通猫猫】-南门大街3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600735] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_脾气差猫】-南门大街1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600736] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_普通猫猫】-南门大街2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600737] = {
		designer = "黄乐孳",
		notes = "【猫_白色_普通猫猫】-醉花阴-杨棉棉",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600738] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_贴贴猫猫】-醉花阴-庞达达",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600739] = {
		designer = "黄乐孳",
		notes = "【猫_白色_贴贴猫猫】-醉花阴-竺圆圆",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600741] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_贴贴猫猫】-醉花阴-戚柚柚",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600742] = {
		designer = "黄乐孳",
		notes = "【猫_三花_贴贴猫猫】-醉花阴-唐妆妆",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600743] = {
		designer = "黄乐孳",
		notes = "【猫_白色_贴贴猫猫】-醉花阴-蔡猫猫",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600744] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_贴贴猫猫】-百工坊1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600745] = {
		designer = "黄乐孳",
		notes = "【猫_狸花_梦中情猫】-百工坊2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600746] = {
		designer = "黄乐孳",
		notes = "【猫_三花_普通猫猫】-百工坊3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6600766] = {
		designer = "黄乐孳",
		notes = "【猫_橙色_普通猫猫】-百工坊4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601077] = {
		designer = "黄乐孳",
		notes = "鲁墨-船工-钱袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6601082] = {
		designer = "黄乐孳",
		notes = "猫_印花-梓匠居猫咪1-猫猫·浪浪",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601083] = {
		designer = "黄乐孳",
		notes = "猫_橙-望淮南山崖喂猫2-猫猫·吓破胆",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601084] = {
		designer = "黄乐孳",
		notes = "猫_奶牛_蓝眼睛-猫猫·太皮",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601085] = {
		designer = "黄乐孳",
		notes = "猫_暹罗_黄眼睛-猫猫·太黑",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601086] = {
		designer = "黄乐孳",
		notes = "猫_银狸花_黄眼睛-猫猫·太银",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601090] = {
		designer = "陈胜",
		notes = "麻将桌（PVE）-狗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6601094] = {
		designer = "黄乐孳",
		notes = "猫_印花-大宋府衙猫咪1-猫猫·猫翰林",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601095] = {
		designer = "黄乐孳",
		notes = "猫_黑-大宋府衙猫咪2-猫猫·猫青天",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601096] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601097] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601098] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601099] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601100] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601101] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫6",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601102] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫7",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601103] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫8",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601104] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫9",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601105] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫10",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601106] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫11",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601107] = {
		designer = "黄乐孳",
		notes = "寿昌坊摸猫12",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601150] = {
		designer = "黄乐孳",
		notes = "麻将桌（使用）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601152] = {
		designer = "黄乐孳",
		notes = "麻将桌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601167] = {
		designer = "黄乐孳",
		notes = "金玉手-金钲",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601174] = {
		designer = "黄乐孳",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601223] = {
		designer = "黄乐孳",
		notes = "武城王庙-关闭机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601248] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601249] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601250] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601251] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601252] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601253] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫6",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601254] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫7",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601255] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫8",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601256] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫9",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601257] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫10",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601258] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫11",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601259] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫12",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601260] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫13",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601261] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫14",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601262] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫15",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601263] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫16",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601264] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫17",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601265] = {
		designer = "黄乐孳",
		notes = "博浪沙摸猫18",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[6601276] = {
		designer = "黄乐孳",
		notes = "金玉手门锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601277] = {
		designer = "黄乐孳",
		notes = "金玉手门锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6601278] = {
		designer = "黄乐孳",
		notes = "金玉手门锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700001] = {
		designer = "",
		notes = "偷师-无归-机关开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700004] = {
		designer = "俞立",
		notes = "偷师-青溪-石壁-博物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6700205] = {
		designer = "俞立",
		notes = "红尘无眼-钟声解谜-拜月花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700206] = {
		designer = "俞立",
		notes = "红尘无眼-钟声解谜-启动机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700207] = {
		designer = "俞立",
		notes = "红尘无眼-钟声解谜-石块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700209] = {
		designer = "俞立",
		notes = "红尘无眼-钟声解谜-编钟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700214] = {
		designer = "俞立",
		notes = "红尘无眼-铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700215] = {
		designer = "俞立",
		notes = "红尘无眼-雕像玩法宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[6700220] = {
		designer = "俞立",
		notes = "红尘无眼-放水机关卡口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700221] = {
		designer = "俞立",
		notes = "红尘无眼-雕像玩法石板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700222] = {
		designer = "俞立",
		notes = "红尘无眼-石质宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700225] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700226] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700227] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700232] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700235] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700236] = {
		designer = "俞立",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700246] = {
		designer = "俞立",
		notes = "偷师-途中存档点侠之冢模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700339] = {
		designer = "俞立",
		notes = "荆棘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700407] = {
		designer = "俞立",
		notes = "荧渊-记忆点2-二品宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "wanfa_9", "save_type_2" },
	},
	[6700416] = {
		designer = "俞立",
		notes = "红尘无眼-天不收隐藏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700459] = {
		designer = "俞立",
		notes = "熔炉外-军营-木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700465] = {
		designer = "俞立",
		notes = "熔炉内-隐藏铁桶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6700486] = {
		designer = "俞立",
		notes = "坎儿井-移动端增加木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6800026] = {
		designer = "刘铭册",
		notes = "据点大篝火",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6800027] = {
		designer = "李弘扬",
		notes = "复合解谜-空entity（石碑上暗鹿特效）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6800029] = {
		designer = "李弘扬",
		notes = "棺材boss浓烟1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6800081] = {
		designer = "李弘扬",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6920002] = {
		designer = "田野",
		notes = "佛光顶-氛围机关人1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920003] = {
		designer = "田野",
		notes = "佛光顶-氛围机关人2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920004] = {
		designer = "田野",
		notes = "佛光顶-氛围机关人3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920005] = {
		designer = "张联鑫",
		notes = "佛光顶铜人怪1-房间1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920006] = {
		designer = "张联鑫",
		notes = "佛光顶铜人怪3-房间1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920021] = {
		designer = "田野",
		notes = "汴河渡口行当-日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920023] = {
		designer = "田野",
		notes = "无相皇入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6920027] = {
		designer = "田野",
		notes = "小十七入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6920034] = {
		designer = "田野",
		notes = "叶万山入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[6920054] = {
		designer = "",
		notes = "太仓粟平野原野怪大宋官兵B43",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920055] = {
		designer = "",
		notes = "太仓粟平野原野怪大宋官兵B44",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920057] = {
		designer = "田野",
		notes = "燕云别馆超远视距弓箭手（80m）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920058] = {
		designer = "田野",
		notes = "燕云别馆超远视距弓箭手（45m）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920061] = {
		designer = "田野",
		notes = "《六疾馆》-寒菌梦傀-铡草刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920062] = {
		designer = "田野",
		notes = "《六疾馆》-寒菌梦傀-连枷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920084] = {
		designer = "田野",
		notes = "六疾馆碎片化交互-散落的杂物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920085] = {
		designer = "田野",
		notes = "六疾馆碎片化交互-枯萎的杏树枝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920086] = {
		designer = "田野",
		notes = "六疾馆碎片化交互-陈旧的书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920087] = {
		designer = "田野",
		notes = "六疾馆碎片化交互-破旧的旗帜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920088] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-陈年草药",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920089] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-未寄出的书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920090] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-青绿山水扇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920091] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-艰深医书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920092] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-入门医书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920093] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-陈旧的被褥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920094] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-傩面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920095] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-傩面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920096] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-书籍与信笺",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920097] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-隔断屏风",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920098] = {
		designer = "田野",
		notes = "隐雾林碎片化交互-火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920099] = {
		designer = "田野",
		notes = "达安村碎片化交互-破旧的船只",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920100] = {
		designer = "田野",
		notes = "达安村碎片化交互-破旧的长命锁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920101] = {
		designer = "田野",
		notes = "达安村碎片化交互-破旧的书信匣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920102] = {
		designer = "田野",
		notes = "临津渡碎片化交互-青绿山水扇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920103] = {
		designer = "田野",
		notes = "临津渡碎片化交互-往来书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920104] = {
		designer = "田野",
		notes = "临津渡碎片化交互-繁杂医书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920105] = {
		designer = "田野",
		notes = "临津渡碎片化交互-火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920106] = {
		designer = "田野",
		notes = "临津渡碎片化交互-陈旧的佛堂",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920107] = {
		designer = "田野",
		notes = "临津渡碎片化交互-群英请柬",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[6920117] = {
		designer = "张俊杰",
		notes = "太岳台-玄元教月相盘（远程）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920118] = {
		designer = "田野",
		notes = "太岳台-玄元教勾镰（近战小怪）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920122] = {
		designer = "田野",
		notes = "太岳台-玄元教勾镰（精英，偷袭）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920159] = {
		designer = "模板表",
		notes = "世界等级-玄元教-月相盘-不巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[6920160] = {
		designer = "模板表",
		notes = "世界等级-玄元教-勾镰+月相盘-不巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100103] = {
		designer = "任宽",
		notes = "放置暗星稻草人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100104] = {
		designer = "任宽",
		notes = "赵承宗-空模型-用来对准暗星机关2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100200] = {
		designer = "任宽",
		notes = "赵普宅-赵承宗-帽子-放在模式桌子上",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[7100203] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜子-最终密室模块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100205] = {
		designer = "任宽",
		notes = "赵普宅-密室书柜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100207] = {
		designer = "任宽",
		notes = "正房钥匙",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[7100211] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100212] = {
		designer = "任宽",
		notes = "星星暗器-可拾取-密室1层",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[7100213] = {
		designer = "任宽",
		notes = "赵普宅-机关花墙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100214] = {
		designer = "任宽",
		notes = "赵普宅-山水画",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100215] = {
		designer = "任宽",
		notes = "赵普宅-破碎柜子门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100217] = {
		designer = "任宽",
		notes = "赵普宅-机关塔",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100219] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100220] = {
		designer = "任宽",
		notes = "赵普宅-手拉石狮子开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100222] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜子-mishi一层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100223] = {
		designer = "任宽",
		notes = "赵普宅-千斤门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100224] = {
		designer = "任宽",
		notes = "赵普宅-密室书柜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100225] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100226] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100228] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜子-正房",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100231] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯开关（实体）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100237] = {
		designer = "任宽",
		notes = "赵普宅-栅栏门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100238] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜3-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100239] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜3-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100240] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜3-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100241] = {
		designer = "任宽",
		notes = "赵普宅-暗星-放置在机关柜解谜用-4刃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100243] = {
		designer = "任宽",
		notes = "赵普宅—石狮子（无交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100244] = {
		designer = "任宽",
		notes = "赵普宅-暗星机关柜子-最终密室",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100245] = {
		designer = "任宽",
		notes = "赵普宅-手拉石狮子开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100246] = {
		designer = "任宽",
		notes = "赵普宅-手拉链灯开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7100250] = {
		designer = "任宽",
		notes = "放置暗星的盒子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102002] = {
		designer = "任宽",
		notes = "熔炉文职官员",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102007] = {
		designer = "任宽",
		notes = "熔炉-军营表演点位4-号角兵可偷袭杀-站岗1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102018] = {
		designer = "任宽",
		notes = "熔炉地牢-烧毁的书信",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[7102020] = {
		designer = "任宽",
		notes = "熔炉地牢-叠叠乐4人-温盈衣物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102065] = {
		designer = "任宽",
		notes = "熔炉内-工业区-吊桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102067] = {
		designer = "任宽",
		notes = "熔炉内-工业区-缆车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102076] = {
		designer = "任宽",
		notes = "熔炉内-雕龙铁板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102094] = {
		designer = "任宽",
		notes = "熔炉内-升降桶-带特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102095] = {
		designer = "任宽",
		notes = "熔炉外-码头二层楼窗户（会碎",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102101] = {
		designer = "任宽",
		notes = "熔炉外-地牢-钱神论",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[7102102] = {
		designer = "任宽",
		notes = "熔炉外-地牢-烛台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102103] = {
		designer = "任宽",
		notes = "熔炉外-地牢-铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102104] = {
		designer = "任宽",
		notes = "熔炉外-地牢-铁链捆状态",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102106] = {
		designer = "任宽",
		notes = "熔炉外-地牢-买命钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102109] = {
		designer = "任宽",
		notes = "熔炉地牢-温盈帽子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102110] = {
		designer = "任宽",
		notes = "熔炉地牢-温盈帽子-交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102116] = {
		designer = "任宽",
		notes = "熔炉文职官员",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102117] = {
		designer = "任宽",
		notes = "熔炉文职官员",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102119] = {
		designer = "任宽",
		notes = "熔炉地牢-假书架门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102121] = {
		designer = "任宽",
		notes = "熔炉-军营表演点位4-号角兵可偷袭杀-站岗1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102122] = {
		designer = "任宽",
		notes = "放置暗星的盒子-无扫光",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102123] = {
		designer = "任宽",
		notes = "百工坊-老头家门口的树",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7102127] = {
		designer = "任宽",
		notes = "赵普宅-正房门移动端补",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7103029] = {
		designer = "任宽",
		notes = "赵普宅-亭子移动端补",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200001] = {
		designer = "李嘉栋",
		notes = "TBG-磁板怪-P1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200004] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-老鼠-管道初段偷袭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200005] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-鬼娘子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200007] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-沙陀武士（头目）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200038] = {
		designer = "李嘉栋",
		notes = "无忧洞-赃物宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[7200039] = {
		designer = "李嘉栋",
		notes = "无忧洞-垃圾大王的火箭宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9" },
	},
	[7200045] = {
		designer = "李嘉栋",
		notes = "无忧洞-易碎的地板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200051] = {
		designer = "李嘉栋",
		notes = "无忧洞-人市交易清单",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200054] = {
		designer = "李嘉栋",
		notes = "无忧洞-水下-木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200055] = {
		designer = "李嘉栋",
		notes = "空模型entity-河灯寄语",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[7200059] = {
		designer = "李嘉栋",
		notes = "无忧洞-追忆装备-剑-垃圾大王",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7200060] = {
		designer = "李嘉栋",
		notes = "无忧洞-追忆装备-环-杨絮房间",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7200061] = {
		designer = "李嘉栋",
		notes = "无忧洞-追忆装备-剑-主管道尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7200062] = {
		designer = "李嘉栋",
		notes = "无忧洞-无忧酒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200071] = {
		designer = "李嘉栋",
		notes = "无忧洞-鬼樊楼推门-传入",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200072] = {
		designer = "李嘉栋",
		notes = "无忧洞-鬼樊楼推门-传出",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200091] = {
		designer = "李嘉栋",
		notes = "无忧洞-道主场景的墓碑-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200092] = {
		designer = "李嘉栋",
		notes = "无忧洞-道主场景的墓碑-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200093] = {
		designer = "李嘉栋",
		notes = "无忧洞-道主场景的墓碑-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200095] = {
		designer = "李嘉栋",
		notes = "无忧洞-道主场景的墓碑-4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200096] = {
		designer = "李嘉栋",
		notes = "无忧洞-道主场景的墓碑-5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200098] = {
		designer = "李嘉栋",
		notes = "无忧洞-歧路人的另一份书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200102] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-花鼓-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200103] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-花鼓-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200104] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-花鼓-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200105] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-花鼓-4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200106] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-花鼓-5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200182] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-收集线索-时刻表-交互用",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200214] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-待定",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200221] = {
		designer = "李嘉栋",
		notes = "樊楼-武林录-特效挂接-花鼓-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200229] = {
		designer = "李嘉栋",
		notes = "樊楼-小型烟花-窜天猴",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200405] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-鬼娘子-哭泣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200408] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-鬼娘子-友方单位-哭泣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200409] = {
		designer = "李嘉栋",
		notes = "无忧洞-怪物-鬼娘子-友方单位-抓笼子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200503] = {
		designer = "李嘉栋",
		notes = "鬼市子-阴兵借道-阴兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200507] = {
		designer = "李嘉栋",
		notes = "鬼市子-阴兵借道-长眠冢墓碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200509] = {
		designer = "李嘉栋",
		notes = "勾栏瓦肆-看皮影-1-交互点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200511] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-艳湖",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200512] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-云华楼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200513] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-评花坊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200514] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-春水阁",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200515] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-银花铺",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200516] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-风回小院",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200517] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-繁花居",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200518] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-鹊仙桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200519] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-卧波亭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200520] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-灼华馆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200521] = {
		designer = "李嘉栋",
		notes = "醉花阴-花间集-景点打卡-红绡铺",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7200526] = {
		designer = "李嘉栋",
		notes = "勾栏瓦肆-看皮影-2-交互点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7300002] = {
		designer = "王思越",
		notes = "武成王庙-交互物demo-李筠祭文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7300003] = {
		designer = "王思越",
		notes = "武成王庙-交互物demo-兵甲辑录长兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7300004] = {
		designer = "王思越",
		notes = "武成王庙-交互物demo-兵甲辑录短兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7300005] = {
		designer = "王思越",
		notes = "武成王庙-交互物demo-李筠祭文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7300009] = {
		designer = "王思越",
		notes = "不羡仙梳妆台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400003] = {
		designer = "周雨霖",
		notes = "妙妙喵-摇铃祈福-石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400011] = {
		designer = "周雨霖",
		notes = "妙妙喵-摇铃祈福-石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400032] = {
		designer = "周雨霖",
		notes = "棺材铺-桌上纸条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400034] = {
		designer = "周雨霖",
		notes = "空模型entity-传送瘴面窟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400045] = {
		designer = "周雨霖",
		notes = "通用纯空模型空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400050] = {
		designer = "周雨霖",
		notes = "妙妙喵石碑-摇铃祈福-琼林苑-武成王庙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400051] = {
		designer = "周雨霖",
		notes = "妙妙喵石碑-摇铃祈福-寿昌坊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400056] = {
		designer = "周雨霖",
		notes = "妙妙喵石碑-摇铃祈福-承恩镇-丰收祠",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7400059] = {
		designer = "徐佳琦",
		notes = "九曜灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7410029] = {
		designer = "周雨霖",
		notes = "左街3-孤独诗人-张大仙",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[7410081] = {
		designer = "",
		notes = "万事知-画像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7410082] = {
		designer = "",
		notes = "万事知-钱袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7410083] = {
		designer = "",
		notes = "万事知-平安福",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7420143] = {
		designer = "周雨霖",
		notes = "万事知-破旧的长枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7420145] = {
		designer = "周雨霖",
		notes = "鬼市子-桃木辟邪-窗户空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420147] = {
		designer = "周雨霖",
		notes = "万事知-桃木剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7420158] = {
		designer = "周雨霖",
		notes = "鬼市子-付坟典-阅读1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420159] = {
		designer = "周雨霖",
		notes = "鬼市子-付坟典-阅读2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420160] = {
		designer = "周雨霖",
		notes = "鬼市子-付坟典-阅读3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420161] = {
		designer = "周雨霖",
		notes = "鬼市子-倒悬壶-毒物1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420162] = {
		designer = "周雨霖",
		notes = "鬼市子-倒悬壶-毒物2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420163] = {
		designer = "周雨霖",
		notes = "鬼市子-倒悬壶-毒物3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7420164] = {
		designer = "周雨霖",
		notes = "鬼市子-黄泉里-账本-无交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7440026] = {
		designer = "任宽",
		notes = "熔炉-军营表演点位4-号角兵可偷袭杀-站岗1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7440036] = {
		designer = "周雨霖",
		notes = "熔炉-军营-竹梯5m",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450110] = {
		designer = "周雨霖",
		notes = "羽衣楼万事知-风弄梅花-红梅纸伞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7450115] = {
		designer = "周雨霖",
		notes = "羽衣楼-碎片化叙事交互物-时楼正门旁的告示-名姝手迹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450116] = {
		designer = "周雨霖",
		notes = "羽衣楼-碎片化叙事交互物-时楼柜台-碧光酒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450117] = {
		designer = "周雨霖",
		notes = "羽衣楼-碎片化叙事交互物-山水李家柜台-独胜丸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450118] = {
		designer = "周雨霖",
		notes = "羽衣楼-碎片化叙事交互物-羽衣楼后院石桌-江南丝帛引",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450119] = {
		designer = "周雨霖",
		notes = "告示牌-纯场景静态物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450175] = {
		designer = "周雨霖",
		notes = "樊楼3D音效点位-amb_kf_zuihuayin_walla_common_04",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450176] = {
		designer = "周雨霖",
		notes = "樊楼3D音效点位-amb_kf_zuihuayin_walla_common_02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450177] = {
		designer = "周雨霖",
		notes = "樊楼3D音效点位-amb_kf_zuihuayin_walla_common_05",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450178] = {
		designer = "周雨霖",
		notes = "樊楼3D音效点位-amb_kf_zuihuayin_walla_common_weiguan",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7450179] = {
		designer = "周雨霖",
		notes = "樊楼3D音效点位-amb_kf_zuihuayin_walla_common_win",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7470018] = {
		designer = "周雨霖",
		notes = "开封-金龙支线-门锁1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7470045] = {
		designer = "周雨霖",
		notes = "开封-金龙支线-门锁2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7470046] = {
		designer = "周雨霖",
		notes = "开封-金龙支线-门锁3-砸坏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600004] = {
		designer = "竺頔",
		notes = "万古一人殿-二层通道水片",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[7600008] = {
		designer = "竺頔",
		notes = "万古一人殿-河伯像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600009] = {
		designer = "竺頔",
		notes = "可以烧的荆棘-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600014] = {
		designer = "竺頔",
		notes = "万古一人殿-潜水前石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600016] = {
		designer = "竺頔",
		notes = "万古一人殿-河图一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7600018] = {
		designer = "竺頔",
		notes = "万古一人殿-洛书一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7600023] = {
		designer = "竺頔",
		notes = "万古一人殿-返回特效空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600031] = {
		designer = "竺頔",
		notes = "万古一人殿-隔空取物-蛇-一层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600040] = {
		designer = "竺頔",
		notes = "万古一人殿-机关-石面具03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600041] = {
		designer = "竺頔",
		notes = "万古一人殿-空entity-养鱼人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600042] = {
		designer = "竺頔",
		notes = "万古一人殿-空entity-小阮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600057] = {
		designer = "竺頔",
		notes = "火焰触发器-鬼火二层常亮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600058] = {
		designer = "竺頔",
		notes = "万古一人殿-涨水支路巨石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600062] = {
		designer = "竺頔",
		notes = "万古一人殿-下水口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600063] = {
		designer = "竺頔",
		notes = "万古一人殿-地下二层龙首提交",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600064] = {
		designer = "竺頔",
		notes = "万古一人殿-地下三层龙首提交",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600067] = {
		designer = "竺頔",
		notes = "万古一人殿-药瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7600068] = {
		designer = "竺頔",
		notes = "万古一人殿-蒙尘的牌位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7600073] = {
		designer = "竺頔",
		notes = "火焰触发器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600075] = {
		designer = "竺頔",
		notes = "地下二层震开假门1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600076] = {
		designer = "竺頔",
		notes = "地下二层震开假门2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600077] = {
		designer = "竺頔",
		notes = "地下二层掉下石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600078] = {
		designer = "竺頔",
		notes = "万古一人殿-地下三层升起石台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600079] = {
		designer = "竺頔",
		notes = "万古一人殿-地下三层掉落陷阱石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600081] = {
		designer = "华中承",
		notes = "万古一人殿-地下二层降水用-龙头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600084] = {
		designer = "竺頔",
		notes = "万古一人殿-石碑空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600087] = {
		designer = "孙浩声",
		notes = "万古一人殿-喷水装置-二层1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600088] = {
		designer = "竺頔",
		notes = "地下台阶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600089] = {
		designer = "竺頔",
		notes = "交互机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600091] = {
		designer = "竺頔",
		notes = "交互机关踏板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600092] = {
		designer = "竺頔",
		notes = "万古一人殿-石灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600094] = {
		designer = "竺頔",
		notes = "万古一人殿-铁门1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600095] = {
		designer = "竺頔",
		notes = "万古一人殿-铁门2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600098] = {
		designer = "竺頔",
		notes = "水龙首碎片",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600099] = {
		designer = "竺頔",
		notes = "万人殿三层新掉落巨石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600100] = {
		designer = "竺頔",
		notes = "万人殿三层破碎石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600101] = {
		designer = "胡健力",
		notes = "水闸-叶轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7600108] = {
		designer = "竺頔",
		notes = "万古一人殿-河伯像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7710006] = {
		designer = "郭宇昂",
		notes = "将军祠-雕像作揖点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7710017] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-木板组件-小高台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7720008] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-上升平台-静止",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720012] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-巨石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720017] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-上升平台边缘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720018] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-木板箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720019] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-伸缩木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720022] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-平台边缘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720023] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-铁链匣底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720024] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-上升平台3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720025] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-吊桥-动画版-左",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720026] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-青铜推杆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720027] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-伸缩木桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720028] = {
		designer = "郭宇昂",
		notes = "嗟叹崖守门黑雾",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7720029] = {
		designer = "郭宇昂",
		notes = "嗟叹崖-木板组件-入口-假",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900335] = {
		designer = "何纪希",
		notes = "花鸟店铺-金翅雀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900336] = {
		designer = "何纪希",
		notes = "花鸟店铺-翠鸟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900337] = {
		designer = "何纪希",
		notes = "花鸟店铺-喜鹊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900338] = {
		designer = "何纪希",
		notes = "花鸟店铺-白鸽",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900339] = {
		designer = "何纪希",
		notes = "花鸟店铺-麻雀（暂改喜鹊）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900340] = {
		designer = "何纪希",
		notes = "花鸟店铺-八哥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900590] = {
		designer = "何纪希",
		notes = "跪拜空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900591] = {
		designer = "何纪希",
		notes = "坐下空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7900592] = {
		designer = "何纪希",
		notes = "空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910011] = {
		designer = "何纪希",
		notes = "武馆门口遮挡警戒视线的碰撞盒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910021] = {
		designer = "何纪希",
		notes = "木匣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7910022] = {
		designer = "何纪希",
		notes = "书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910023] = {
		designer = "何纪希",
		notes = "食谱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910024] = {
		designer = "何纪希",
		notes = "床塌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910025] = {
		designer = "何纪希",
		notes = "服饰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910026] = {
		designer = "何纪希",
		notes = "书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910027] = {
		designer = "何纪希",
		notes = "话本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910028] = {
		designer = "何纪希",
		notes = "宝剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910030] = {
		designer = "何纪希",
		notes = "夜行衣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910032] = {
		designer = "何纪希",
		notes = "信件1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910035] = {
		designer = "何纪希",
		notes = "棋盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910036] = {
		designer = "何纪希",
		notes = "卷轴",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910037] = {
		designer = "何纪希",
		notes = "山水画",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910038] = {
		designer = "何纪希",
		notes = "通缉令",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910042] = {
		designer = "何纪希",
		notes = "九流门偷师门派告示",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910043] = {
		designer = "何纪希",
		notes = "鬼市九流门偷师用传送",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7910048] = {
		designer = "曹涵松",
		notes = "鱼卵-不爆炸模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7920058] = {
		designer = "何纪希",
		notes = "妙妙喵-一灯一诺--灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7920061] = {
		designer = "周雨霖",
		notes = "妙妙喵石碑-摇铃祈福",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7920065] = {
		designer = "何纪希",
		notes = "首饰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7920066] = {
		designer = "何纪希",
		notes = "陈旧残破的日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940001] = {
		designer = "",
		notes = "万事知-围罛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940002] = {
		designer = "",
		notes = "万事知-荼蘼花签",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940003] = {
		designer = "",
		notes = "万事知-美人皮影",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940004] = {
		designer = "",
		notes = "万事知-梅花丸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940013] = {
		designer = "何纪希",
		notes = "达安村碎片化交互3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940014] = {
		designer = "何纪希",
		notes = "达安村碎片化交互4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940015] = {
		designer = "何纪希",
		notes = "达安村碎片化交互5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940016] = {
		designer = "何纪希",
		notes = "达安村碎片化交互6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940020] = {
		designer = "何纪希",
		notes = "达安村碎片化交互10",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940026] = {
		designer = "何纪希",
		notes = "常平仓-粮食",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940027] = {
		designer = "何纪希",
		notes = "常平仓-旗帜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940028] = {
		designer = "何纪希",
		notes = "常平仓-冯如之书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940029] = {
		designer = "何纪希",
		notes = "常平仓-东阙的书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940030] = {
		designer = "何纪希",
		notes = "平安福",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940031] = {
		designer = "何纪希",
		notes = "九流秘药",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940032] = {
		designer = "何纪希",
		notes = "绳镖",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940033] = {
		designer = "何纪希",
		notes = "账簿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940034] = {
		designer = "何纪希",
		notes = "无心谷偷师-信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940035] = {
		designer = "何纪希",
		notes = "无心谷偷师-人蛹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940036] = {
		designer = "何纪希",
		notes = "无心谷偷师-桌上笔记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940037] = {
		designer = "何纪希",
		notes = "无心谷偷师-尸堆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940038] = {
		designer = "何纪希",
		notes = "无心谷偷师-尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940039] = {
		designer = "何纪希",
		notes = "大相国寺烟雾特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940041] = {
		designer = "何纪希",
		notes = "鬼市-九流门偷师-倪老山的信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[7940043] = {
		designer = "何纪希",
		notes = "开封皇宫-城门1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[7940044] = {
		designer = "何纪希",
		notes = "开封皇宫-城门2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[7940045] = {
		designer = "何纪希",
		notes = "常平仓BOSS战地块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940046] = {
		designer = "何纪希",
		notes = "万古一人殿石头模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940047] = {
		designer = "何纪希",
		notes = "万古一人殿二层门模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940053] = {
		designer = "何纪希",
		notes = "勾栏瓦肆房门模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940054] = {
		designer = "何纪希",
		notes = "勾栏瓦肆房门模型-右",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940055] = {
		designer = "何纪希",
		notes = "府宅区亭子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940056] = {
		designer = "何纪希",
		notes = "池塘石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7940057] = {
		designer = "何纪希",
		notes = "柜子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7950057] = {
		designer = "何纪希",
		notes = "南门大街见闻-查看不死树",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7950058] = {
		designer = "何纪希",
		notes = "南门大街见闻-查看石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7950059] = {
		designer = "何纪希",
		notes = "南门大街见闻-查看划痕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[7950143] = {
		designer = "何纪希",
		notes = "一叶平生-荷花酥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000025] = {
		designer = "欧嘉昊",
		notes = "话术-乔松云-寿昌坊-学识之趣",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000032] = {
		designer = "欧嘉昊",
		notes = "话术-勾栏瓦肆3",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000033] = {
		designer = "欧嘉昊",
		notes = "话术-勾栏瓦肆4",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000053] = {
		designer = "欧嘉昊",
		notes = "悬壶-陈之风",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000054] = {
		designer = "欧嘉昊",
		notes = "悬壶-金小竹",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000055] = {
		designer = "欧嘉昊",
		notes = "悬壶-时小之",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000056] = {
		designer = "欧嘉昊",
		notes = "悬壶-花鸾",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000057] = {
		designer = "欧嘉昊",
		notes = "悬壶-净虚",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000058] = {
		designer = "欧嘉昊",
		notes = "悬壶-澹台钰",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000140] = {
		designer = "欧嘉昊",
		notes = "六疾馆复合解谜-六疾手札",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000151] = {
		designer = "欧嘉昊",
		notes = "六疾馆复合解谜-地窖门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000198] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000199] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000200] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000201] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000202] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000203] = {
		designer = "欧嘉昊",
		notes = "南门大街复合解谜-大世界交互物6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000215] = {
		designer = "欧嘉昊",
		notes = "雾林残方1——隐雾林复合解谜/雾林秘宝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000216] = {
		designer = "欧嘉昊",
		notes = "雾林残方2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000218] = {
		designer = "欧嘉昊",
		notes = "孙不弃手札",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000232] = {
		designer = "欧嘉昊",
		notes = "澡堂玩法-二楼按摩床-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8000250] = {
		designer = "欧嘉昊",
		notes = "阿材-博浪沙-天籁之声",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000251] = {
		designer = "欧嘉昊",
		notes = "宋千杯-博浪沙-似醉非醉",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000252] = {
		designer = "欧嘉昊",
		notes = "悬壶-谷世-醉花阴",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000254] = {
		designer = "欧嘉昊",
		notes = "话术-郭大-手工业区-心如乌墨",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000255] = {
		designer = "欧嘉昊",
		notes = "话术-舒绸-羽衣楼-何以为真",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000256] = {
		designer = "欧嘉昊",
		notes = "话术-孙武-琼林苑-文武之争",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000280] = {
		designer = "欧嘉昊",
		notes = "租房玩法-勾栏瓦肆跪拜空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000282] = {
		designer = "欧嘉昊",
		notes = "澡堂玩法-二楼按摩床-2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8000283] = {
		designer = "欧嘉昊",
		notes = "澡堂玩法-二楼按摩床-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8000284] = {
		designer = "欧嘉昊",
		notes = "澡堂玩法-二楼按摩床-4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8000286] = {
		designer = "欧嘉昊",
		notes = "万事知-百工坊-摸金校尉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000288] = {
		designer = "欧嘉昊",
		notes = "万事知-百工坊-神龙覆面-神龙面具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8000312] = {
		designer = "欧嘉昊",
		notes = "祛除buff-1631601180",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000322] = {
		designer = "欧嘉昊",
		notes = "火盆-带特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000333] = {
		designer = "欧嘉昊",
		notes = "净慈-博浪沙-老子化胡",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000334] = {
		designer = "欧嘉昊",
		notes = "梁山汉-博浪沙-躺平之道",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000335] = {
		designer = "欧嘉昊",
		notes = "胡壮壮-博浪沙-顽童劝学",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[8000336] = {
		designer = "欧嘉昊",
		notes = "鲁大帕-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000337] = {
		designer = "欧嘉昊",
		notes = "何禾中-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000338] = {
		designer = "欧嘉昊",
		notes = "沙老三-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000339] = {
		designer = "欧嘉昊",
		notes = "田甜儿-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000340] = {
		designer = "欧嘉昊",
		notes = "杜婆婆-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000341] = {
		designer = "欧嘉昊",
		notes = "田心文-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000342] = {
		designer = "欧嘉昊",
		notes = "吕三儿-博浪沙",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[8000356] = {
		designer = "欧嘉昊",
		notes = "碎片化交互2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000357] = {
		designer = "欧嘉昊",
		notes = "碎片化交互3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000358] = {
		designer = "欧嘉昊",
		notes = "碎片化交互4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000359] = {
		designer = "欧嘉昊",
		notes = "碎片化交互5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000360] = {
		designer = "欧嘉昊",
		notes = "碎片化交互6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000362] = {
		designer = "欧嘉昊",
		notes = "碎片化交互8",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000419] = {
		designer = "欧嘉昊",
		notes = "花边小报-报纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8000422] = {
		designer = "欧嘉昊",
		notes = "象棋棋盘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100001] = {
		designer = "张震",
		notes = "解谜洞窟-齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100002] = {
		designer = "张震",
		notes = "解谜洞窟-飞来锁平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100005] = {
		designer = "张震",
		notes = "炸药桶超大（可抱起）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100023] = {
		designer = "张震",
		notes = "电梯运输箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100031] = {
		designer = "张震",
		notes = "电梯开关-中控开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100032] = {
		designer = "张震",
		notes = "石门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100033] = {
		designer = "张震",
		notes = "守财奴宝箱（带锁）",
		wanfa_types = { 9, 22, 12 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[8100034] = {
		designer = "张震",
		notes = "【常平仓地下】飞来锁电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100037] = {
		designer = "张震",
		notes = "不爆炸桶（可抱起）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100040] = {
		designer = "张震",
		notes = "常平仓镇守新增-火箭袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8100042] = {
		designer = "袁国振",
		notes = "炸药桶原版：炸药桶-物理破碎版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100045] = {
		designer = "张震",
		notes = "空中冲刺-半边铁栏杆a",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100046] = {
		designer = "张震",
		notes = "空中冲刺-半边铁栏杆b",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100048] = {
		designer = "张震",
		notes = "电梯开关-中控开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100115] = {
		designer = "张俊杰",
		notes = "妙妙喵-斗转星移转转乐底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100116] = {
		designer = "张俊杰",
		notes = "妙妙喵-斗转星移转转乐石柱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100255] = {
		designer = "张震",
		notes = "同甘共苦-草席（布景）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100309] = {
		designer = "张震",
		notes = "开封引导任务-萝莉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100421] = {
		designer = "张震",
		notes = "豌豆糕",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[8100422] = {
		designer = "张震",
		notes = "论语",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8100423] = {
		designer = "张震",
		notes = "信纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8100424] = {
		designer = "张震",
		notes = "伞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8100425] = {
		designer = "张震",
		notes = "香囊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[8100447] = {
		designer = "张震",
		notes = "百工坊见闻-旧账簿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100448] = {
		designer = "张震",
		notes = "百工坊见闻-郑懔的字条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100449] = {
		designer = "张震",
		notes = "百工坊见闻-锻闲杂记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100450] = {
		designer = "张震",
		notes = "百工坊见闻-黑色痕迹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100451] = {
		designer = "张震",
		notes = "百工坊见闻-书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100501] = {
		designer = "",
		notes = "星垣1转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100502] = {
		designer = "",
		notes = "星垣1转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100503] = {
		designer = "",
		notes = "星垣1转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100504] = {
		designer = "",
		notes = "星垣1转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100505] = {
		designer = "胡健力",
		notes = "黑煞阴阳-北--八卦转转乐基座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100506] = {
		designer = "张震",
		notes = "太岳台-八卦转转乐环1-外",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100507] = {
		designer = "张震",
		notes = "太岳台-八卦转转乐环2-中",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100509] = {
		designer = "",
		notes = "星垣2转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100510] = {
		designer = "",
		notes = "星垣2转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100511] = {
		designer = "",
		notes = "星垣2转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100512] = {
		designer = "",
		notes = "星垣2转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100513] = {
		designer = "",
		notes = "星垣3转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100514] = {
		designer = "",
		notes = "星垣3转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100515] = {
		designer = "",
		notes = "星垣3转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100516] = {
		designer = "",
		notes = "星垣3转转乐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8100518] = {
		designer = "张震",
		notes = "太岳台-电梯平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100543] = {
		designer = "张俊杰",
		notes = "太岳台-八卦无字转转乐环2-中",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8100544] = {
		designer = "胡健力",
		notes = "黑煞阴阳-北--八卦转转乐环3-内",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8102070] = {
		designer = "胡健力",
		notes = "黑煞阴阳-南--八卦转转乐环1-外",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8102071] = {
		designer = "胡健力",
		notes = "黑煞阴阳-南--八卦转转乐环2-中",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200009] = {
		designer = "林野",
		notes = "墨守之心外部旋浆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200012] = {
		designer = "林野",
		notes = "墨守之心一层中轴",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200013] = {
		designer = "林野",
		notes = "墨守之心拉杆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200014] = {
		designer = "林野",
		notes = "墨守之心一层闸门开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200015] = {
		designer = "林野",
		notes = "墨守之心1层水面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200016] = {
		designer = "林野",
		notes = "墨守之心2层水面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200022] = {
		designer = "林野",
		notes = "飞天残垣齿轮_大",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200023] = {
		designer = "林野",
		notes = "飞天残垣齿轮_小",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200024] = {
		designer = "林野",
		notes = "齿轮轴承01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200025] = {
		designer = "林野",
		notes = "齿轮轴承02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200026] = {
		designer = "林野",
		notes = "齿轮轴承03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200028] = {
		designer = "林野",
		notes = "飞天残垣机关鸟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200030] = {
		designer = "林野",
		notes = "墨守之心2层通道水面",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200031] = {
		designer = "林野",
		notes = "墨守之心-机关门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200032] = {
		designer = "林野",
		notes = "墨守之心墙面齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200034] = {
		designer = "林野",
		notes = "墨守之心二层通道履带",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200035] = {
		designer = "林野",
		notes = "墨守之心中轴齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200036] = {
		designer = "林野",
		notes = "墨守之心二层地图机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200037] = {
		designer = "林野",
		notes = "墨守之心二层水流特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200039] = {
		designer = "林野",
		notes = "墨守之心水面特效-圆形小",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200041] = {
		designer = "林野",
		notes = "墨守之心2层水面-状态2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200042] = {
		designer = "林野",
		notes = "墨守之心2层水面-状态3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8200045] = {
		designer = "林野",
		notes = "墨守之心水下开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8300007] = {
		designer = "万斌",
		notes = "龙虎寨盗匪（双斧）（精英）-氛围怪物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8300008] = {
		designer = "万斌",
		notes = "龙虎寨招牌-氛围物件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8300009] = {
		designer = "万斌",
		notes = "装钱的箱子-氛围物件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8300014] = {
		designer = "万斌",
		notes = "商旅马车-氛围物件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8300020] = {
		designer = "万斌",
		notes = "闻高的商旅马车-氛围物件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[8400082] = {
		designer = "孙浚凯",
		notes = "天上来-漕帮-鱼叉鱼桶偷袭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500031] = {
		designer = "李晨",
		notes = "齐声-摔倒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500032] = {
		designer = "李晨",
		notes = "黄钟碎片",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500033] = {
		designer = "李晨",
		notes = "斗笠外观",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500034] = {
		designer = "李晨",
		notes = "心法书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500035] = {
		designer = "李晨",
		notes = "丹药瓶子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500036] = {
		designer = "李晨",
		notes = "曲谱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500037] = {
		designer = "李晨",
		notes = "黄帝内经",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500038] = {
		designer = "李晨",
		notes = "齐声-任务2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8500055] = {
		designer = "李晨",
		notes = "齐声-摔倒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[8900219] = {
		designer = "杨梦洁",
		notes = "拍照检测-鱼龙蔓延前集市",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[9000112] = {
		designer = "开封主线",
		notes = "黑市追逃-木架",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000004] = {
		designer = "蒙名恒",
		notes = "通用无交互空entity",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000035] = {
		designer = "蒙名恒",
		notes = "农田水车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000081] = {
		designer = "蒙名恒",
		notes = "分水机关开关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000116] = {
		designer = "蒙名恒",
		notes = "天上来堵着的船",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000134] = {
		designer = "蒙名恒",
		notes = "阵眼室第一个区域-特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000138] = {
		designer = "蒙名恒",
		notes = "第二阵眼室区域1-特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000140] = {
		designer = "蒙名恒",
		notes = "水车-阵眼室区域-特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000141] = {
		designer = "蒙名恒",
		notes = "中山遗址-旋转机关鸟平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000143] = {
		designer = "蒙名恒",
		notes = "中山遗址-电梯压力板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000180] = {
		designer = "蒙名恒",
		notes = "中山遗址-最后解谜电梯-升降平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000181] = {
		designer = "蒙名恒",
		notes = "中山遗址-最后解谜电梯-升降平台底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10000284] = {
		designer = "蒙名恒",
		notes = "碧水云涛-鸦房间-书架门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10200105] = {
		designer = "刘鹏程",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[10200149] = {
		designer = "刘鹏程",
		notes = "小柳boss-传送蜡烛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[11500056] = {
		designer = "雷淞雯",
		notes = "花边小报-报纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[11500057] = {
		designer = "雷淞雯",
		notes = "花边小报-报纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[11500058] = {
		designer = "雷淞雯",
		notes = "花边小报-报纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[12800038] = {
		designer = "张星翼",
		notes = "【万事知-荒词暗影】道具-瘪蹴鞠",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[12800045] = {
		designer = "张星翼",
		notes = "【奇遇-疯狂的石头】道具-八音窍贴纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[12800052] = {
		designer = "张星翼",
		notes = "八音窃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[12800053] = {
		designer = "张星翼",
		notes = "八音窃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[12800054] = {
		designer = "张星翼",
		notes = "八音窃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100162] = {
		designer = "李泽昊",
		notes = "归去来兮后置-衣冠冢空entity（挂文本用）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100170] = {
		designer = "李泽昊",
		notes = "酒塔之底-玩家掉落重返单向轻功组件-无飘带",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100200] = {
		designer = "李泽昊",
		notes = "荧渊关卡-鹿头面具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100208] = {
		designer = "李泽昊",
		notes = "荧渊关卡-空entity-地上鹿特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100209] = {
		designer = "李泽昊",
		notes = "荧渊关卡-老BOSS房门口蝴蝶特效+传送",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100210] = {
		designer = "李泽昊",
		notes = "荧渊关卡-空entity-传送到老雾门后",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13100217] = {
		designer = "李泽昊",
		notes = "荧渊关卡-鹿头石门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13101303] = {
		designer = "李泽昊",
		notes = "万事知-一盏明灯-灯笼（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101306] = {
		designer = "李泽昊",
		notes = "万事知-传家之宝－馒头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101309] = {
		designer = "李泽昊",
		notes = "万事知-鸟尽弓藏－香囊（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101316] = {
		designer = "李泽昊",
		notes = "万事知-回首无路-小木箱（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101320] = {
		designer = "李泽昊",
		notes = "万事知-不是怕！是尊重！－池底的铜钱袋（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101332] = {
		designer = "李泽昊",
		notes = "万事知-对手和朋友－赏花文集（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101338] = {
		designer = "李泽昊",
		notes = "万事知-不是怕！是尊重！－鸡笼里的铜钱袋（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101339] = {
		designer = "李泽昊",
		notes = "万事知-不是怕！是尊重！－酒坛底的铜钱袋（可拾取）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[13101457] = {
		designer = "李泽昊",
		notes = "熔炉-潜入-交互开门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[13110067] = {
		designer = "李佳颖",
		notes = "九流门驻地-十大骗术之雀-寿才努",
		wanfa_types = { 12 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_12" },
	},
	[13110068] = {
		designer = "李佳颖",
		notes = "九流门驻地-十大骗术之雀-关野",
		wanfa_types = { 12 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_12" },
	},
	[13110075] = {
		designer = "李佳颖",
		notes = "九流门驻地-十大骗术之雀-寿才努-任务无ai",
		wanfa_types = { 12 },
		has_reward = false,
		save_type = 0,
		space = "s501",
		reasons = { "wanfa_12" },
	},
	[14000011] = {
		designer = "刘铭册",
		notes = "美味惊喜-鸡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000012] = {
		designer = "刘铭册",
		notes = "美味惊喜-打火折",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000013] = {
		designer = "刘铭册",
		notes = "美味惊喜-蘑菇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000016] = {
		designer = "刘铭册",
		notes = "如此解忧-药瓶1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000017] = {
		designer = "刘铭册",
		notes = "如此解忧-药瓶2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000018] = {
		designer = "刘铭册",
		notes = "如此解忧-药瓶3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000021] = {
		designer = "刘铭册",
		notes = "猎户-npc",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[14000027] = {
		designer = "刘铭册",
		notes = "当饮好茶-破外氅",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000028] = {
		designer = "刘铭册",
		notes = "当饮好茶-破凳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000029] = {
		designer = "刘铭册",
		notes = "当饮好茶-馊奶酪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14000035] = {
		designer = "刘铭册",
		notes = "大侠试炼-证",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[14001211] = {
		designer = "",
		notes = "夜修罗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14001270] = {
		designer = "刘铭册",
		notes = "如此解忧-鸟窝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[14001271] = {
		designer = "",
		notes = "大侠试炼-马车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[14002072] = {
		designer = "刘铭册",
		notes = "寿昌坊-马车",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14002482] = {
		designer = "刘铭册",
		notes = "吃人村-石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[14003129] = {
		designer = "刘铭册",
		notes = "行政区-榜报交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14003130] = {
		designer = "刘铭册",
		notes = "行政区-折扇交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14003131] = {
		designer = "刘铭册",
		notes = "行政区-柳树交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14003170] = {
		designer = "",
		notes = "寿昌坊-老年乐团交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[14003778] = {
		designer = "刘铭册",
		notes = "床",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600027] = {
		designer = "虞峰镔",
		notes = "双子舞傀隐藏BOSS前置-氛围漂浮木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600077] = {
		designer = "虞峰镔",
		notes = "栖鸟岩氛围增补-皮影艺人的火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600098] = {
		designer = "虞峰镔",
		notes = "不见山声望引导-听翁上的纸条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600104] = {
		designer = "虞峰镔",
		notes = "栖鸟岩书籍-墨城诡事",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15600106] = {
		designer = "虞峰镔",
		notes = "栖鸟岩氛围增补-猕猴交互坐空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600128] = {
		designer = "虞峰镔",
		notes = "双子舞姬-罪湖小屋的发簪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15600130] = {
		designer = "虞峰镔",
		notes = "双子舞姬前置探索-百工坊浮木上的发簪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15600132] = {
		designer = "虞峰镔",
		notes = "双子舞姬-湖下木门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15600133] = {
		designer = "虞峰镔",
		notes = "墨城东书籍-异闻录·云槎揽胜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15600134] = {
		designer = "虞峰镔",
		notes = "双子舞姬-湖下小屋中的笔记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15600141] = {
		designer = "虞峰镔",
		notes = "不见山追忆装备-无事牌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15700266] = {
		designer = "齐毅恒",
		notes = "壁画交互（空模型）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15700267] = {
		designer = "齐毅恒",
		notes = "木牌交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15700284] = {
		designer = "齐毅恒",
		notes = "云生花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15700365] = {
		designer = "齐毅恒",
		notes = "牛乳瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15700374] = {
		designer = "齐毅恒",
		notes = "书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15700375] = {
		designer = "齐毅恒",
		notes = "书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15700377] = {
		designer = "齐毅恒",
		notes = "坐铜钱交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15800032] = {
		designer = "陈凯",
		notes = "飞来锁平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15900013] = {
		designer = "凌志坚",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[15900014] = {
		designer = "凌志坚",
		notes = "鲜花种子",
		wanfa_types = {},
		has_reward = true,
		save_type = 1,
		space = "s501",
		reasons = { "has_reward" },
	},
	[15900015] = {
		designer = "凌志坚",
		notes = "榫卯",
		wanfa_types = {},
		has_reward = true,
		save_type = 1,
		space = "s501",
		reasons = { "has_reward" },
	},
	[15900016] = {
		designer = "凌志坚",
		notes = "设计图",
		wanfa_types = {},
		has_reward = true,
		save_type = 1,
		space = "s501",
		reasons = { "has_reward" },
	},
	[15900101] = {
		designer = "凌志坚",
		notes = "恩义宝箱形态1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900102] = {
		designer = "凌志坚",
		notes = "恩义宝箱形态2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[15900104] = {
		designer = "凌志坚",
		notes = "传送宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900105] = {
		designer = "凌志坚",
		notes = "套娃一品宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900106] = {
		designer = "凌志坚",
		notes = "套娃二品宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900107] = {
		designer = "凌志坚",
		notes = "套娃三品宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900108] = {
		designer = "凌志坚",
		notes = "套娃四品宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900109] = {
		designer = "凌志坚",
		notes = "套娃珍宝匣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900110] = {
		designer = "凌志坚",
		notes = "爆炸宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[15900114] = {
		designer = "凌志坚",
		notes = "龟壳（常驻交互）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000000] = {
		designer = "袁闵鸿皓",
		notes = "慈心镇周齐岩等立析产分书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[16000001] = {
		designer = "袁闵鸿皓",
		notes = "高庆诉李二窃玉镯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[16000002] = {
		designer = "袁闵鸿皓",
		notes = "无名公",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[16000003] = {
		designer = "袁闵鸿皓",
		notes = "祭阿兄文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[16000004] = {
		designer = "袁闵鸿皓",
		notes = "无羞头陀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000005] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀（窃听-善妙）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000006] = {
		designer = "袁闵鸿皓",
		notes = "愚力头陀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000007] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀甲（窃听-佛光玉1）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000008] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀乙（窃听-佛光玉1）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000009] = {
		designer = "袁闵鸿皓",
		notes = "愚力头陀丙（窃听-苦海）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000010] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀丁（窃听-苦海）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000011] = {
		designer = "袁闵鸿皓",
		notes = "愚力头陀戊（窃听-别馆）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000012] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀己（窃听-别馆）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000013] = {
		designer = "袁闵鸿皓",
		notes = "愚力头陀庚（窃听-掌院）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000014] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀辛（窃听-掌院）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000015] = {
		designer = "袁闵鸿皓",
		notes = "愚力头陀壬（窃听-佛光玉2）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000016] = {
		designer = "袁闵鸿皓",
		notes = "破戒头陀癸（窃听-佛光玉2）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[16000034] = {
		designer = "袁闵鸿皓",
		notes = "荒魂村乌鸦尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[16001065] = {
		designer = "王震宇",
		notes = "荒魂村-婚礼清单",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[18000008] = {
		designer = "任众",
		notes = "武庙-大宋官兵-突火枪1（直接进战，支援）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[18000015] = {
		designer = "袁权炜",
		notes = "【施工中】世界等级-大宋官兵-偃月刀(刀拿手偷袭)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19001118] = {
		designer = "仇金翰",
		notes = "600161-藤蔓墙1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19001119] = {
		designer = "",
		notes = "羽绒草-藤蔓墙2-挡路",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19001127] = {
		designer = "仇金翰",
		notes = "羽绒草-藤蔓墙8",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002000] = {
		designer = "仇金翰",
		notes = "【常平仓地下】巨型双层货梯-可动框架",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002001] = {
		designer = "仇金翰",
		notes = "【常平仓地下】巨型双层货梯-厢体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002002] = {
		designer = "仇金翰",
		notes = "【常平仓地下】水力吊机-吊机本体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002003] = {
		designer = "仇金翰",
		notes = "【常平仓地下】电梯吊的木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002004] = {
		designer = "仇金翰",
		notes = "【常平仓地下】关卡大门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002005] = {
		designer = "田野",
		notes = "【常平仓地下】闸门操控台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002007] = {
		designer = "仇金翰",
		notes = "【常平仓地下】水力侧门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002015] = {
		designer = "仇金翰",
		notes = "【常平仓地下】通道机关门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002021] = {
		designer = "仇金翰",
		notes = "【常平仓堡】粮仓门卫-陌刀卫（左）(改成枪了)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002022] = {
		designer = "仇金翰",
		notes = "【常平仓堡】大宋官兵-枪兵-常平仓守卫-绕塔巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002023] = {
		designer = "仇金翰",
		notes = "【常平仓堡】修缮区-中央塔楼入口守军（精英大刀）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002025] = {
		designer = "仇金翰",
		notes = "大宋官兵-枪兵-常平仓守卫-绕塔巡逻",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[19002041] = {
		designer = "张益豪",
		notes = "【常平仓堡】城堡弩车兵-正门大桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[20000004] = {
		designer = "李子晨",
		notes = "熔炉-结束-赵大哥椅子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[21000234] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-飞天实验-飞天实验残页",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000235] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-三兄妹的梦-断翅木鸢的身体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000236] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-三兄妹的梦-断翅木鸢右翅膀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000238] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-桃源何处-老舵工的药剂瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000239] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-桃源何处-老舵工的家书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000421] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-飞天实验-跌打药1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000423] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-飞天实验-损伤药2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[21000426] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-三兄妹的梦-三妹的鞋子结局1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[23000449] = {
		designer = "王治",
		notes = "墨城-万事知-头顶大事-钳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[23000600] = {
		designer = "欧嘉昊",
		notes = "翟晓姜-聆杏村-生姜趋辛",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000601] = {
		designer = "欧嘉昊",
		notes = "安怀微-长兴集-解忧消愁",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000603] = {
		designer = "欧嘉昊",
		notes = "程晓敏-平野原-我还能干",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000604] = {
		designer = "欧嘉昊",
		notes = "宋荞-麦香集-麸粮济灾",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000605] = {
		designer = "欧嘉昊",
		notes = "杨学佑-承恩镇-有家难回",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000606] = {
		designer = "欧嘉昊",
		notes = "艾甘敬-梓匠居-澡堂恐惧",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000607] = {
		designer = "欧嘉昊",
		notes = "林之危-武成王庙-不思进取",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000608] = {
		designer = "欧嘉昊",
		notes = "冷月-寿昌坊-坦诚相待",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000609] = {
		designer = "欧嘉昊",
		notes = "陈牧延-寿昌坊-老骥伏枥",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000610] = {
		designer = "欧嘉昊",
		notes = "宋知书-行政区-念书无用",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[23000620] = {
		designer = "欧嘉昊",
		notes = "罗少强-长兴集",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000621] = {
		designer = "欧嘉昊",
		notes = "向知恩-聆杏村",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000622] = {
		designer = "欧嘉昊",
		notes = "石小全-平原野",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000623] = {
		designer = "欧嘉昊",
		notes = "王其孝-承恩镇",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000624] = {
		designer = "欧嘉昊",
		notes = "王思孟-承恩镇",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000625] = {
		designer = "欧嘉昊",
		notes = "郭小毛-鸿沟古渠",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000626] = {
		designer = "欧嘉昊",
		notes = "魏山-望淮南崖",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000627] = {
		designer = "欧嘉昊",
		notes = "罗小河-琵琶沟",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000628] = {
		designer = "欧嘉昊",
		notes = "朱小海-寿昌坊",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000629] = {
		designer = "欧嘉昊",
		notes = "霍昆鹏-寿昌坊",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[23000630] = {
		designer = "欧嘉昊",
		notes = "王捕快-寿昌坊",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[24003065] = {
		designer = "张筱诺",
		notes = "【侠之冢-复活】沟渠入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000001] = {
		designer = "张余熙",
		notes = "铁壁谷-怪物-窃听-石块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000011] = {
		designer = "张余熙",
		notes = "铁壁谷-声翁1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000012] = {
		designer = "张余熙",
		notes = "铁壁谷-声翁2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000013] = {
		designer = "张余熙",
		notes = "铁壁谷-声翁3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000016] = {
		designer = "张余熙",
		notes = "铁壁谷-核心机关",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000017] = {
		designer = "张余熙",
		notes = "铁壁谷-声翁4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000046] = {
		designer = "张余熙",
		notes = "铁壁谷-小鸟移人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000047] = {
		designer = "张余熙",
		notes = "铁壁谷-飞天神骏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000048] = {
		designer = "张余熙",
		notes = "铁壁谷-鸦的旧笔记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000049] = {
		designer = "张余熙",
		notes = "铁壁谷-张万师的八音盒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000050] = {
		designer = "张余熙",
		notes = "铁壁谷-假宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000051] = {
		designer = "张余熙",
		notes = "铁壁谷-穷奇师信函",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000079] = {
		designer = "张余熙",
		notes = "铁壁谷-核心机关3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000085] = {
		designer = "张余熙",
		notes = "晦谷-蒲团",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[29000102] = {
		designer = "张余熙",
		notes = "铁壁谷-怪物-窃听-石块",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[31000007] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-江湖一刀·一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[31000008] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-江湖一刀·二",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[31000009] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-江湖一刀·三",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[31000010] = {
		designer = "寿焓宇",
		notes = "清河cp书籍-井下生寒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[32000066] = {
		designer = "曹雨虹",
		notes = "大鹅的宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[32000067] = {
		designer = "曹雨虹",
		notes = "大鹅的木板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[32000286] = {
		designer = "曹雨虹",
		notes = "得胜剑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[32000287] = {
		designer = "曹雨虹",
		notes = "六材弓",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[32000288] = {
		designer = "曹雨虹",
		notes = "守心玦",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[32000289] = {
		designer = "曹雨虹",
		notes = "文心护腕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[32000291] = {
		designer = "曹雨虹",
		notes = "浑铁重枪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000040] = {
		designer = "林文杰",
		notes = "一叠书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000042] = {
		designer = "林文杰",
		notes = "猫形铃铛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000054] = {
		designer = "林文杰",
		notes = "一叠情书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000055] = {
		designer = "林文杰",
		notes = "一把钥匙（盒子）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000057] = {
		designer = "林文杰",
		notes = "半只鸡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000058] = {
		designer = "林文杰",
		notes = "珍珠簪",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000066] = {
		designer = "林文杰",
		notes = "田中生金-染血金钗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000067] = {
		designer = "林文杰",
		notes = "庄稼说话-平安符",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000068] = {
		designer = "林文杰",
		notes = "偷瓜贼-一筐香瓜",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000069] = {
		designer = "林文杰",
		notes = "暗蜂传蕊-蔷薇信笺",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000070] = {
		designer = "林文杰",
		notes = "卷人不倦-石菖蒲药剂",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000101] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000102] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000103] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000104] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000105] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000106] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000107] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互7",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000108] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互8",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000109] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互9",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000110] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互10",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000111] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互11",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000112] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互12",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000113] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互13",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000114] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互14",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000115] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互15",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000116] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互16",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000117] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互17",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000118] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互18",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000119] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互19",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000120] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互20",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000121] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互21",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000122] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互22",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000123] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互23",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000124] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互24",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000125] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互25",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000126] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互26",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000127] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互27",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000128] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互28",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000129] = {
		designer = "林文杰",
		notes = "万全之厕-上厕所空交互29",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000225] = {
		designer = "林文杰",
		notes = "太一宫-压胜玉佩",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[33000241] = {
		designer = "林文杰",
		notes = "万事知-第一炉灰-丹炉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[33000274] = {
		designer = "林文杰",
		notes = "万事知-第一炉灰-装有龙头香的布囊",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000007] = {
		designer = "陈晓翰",
		notes = "文章-万事知-望子成龙",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000011] = {
		designer = "陈晓翰",
		notes = "万事知-重要之物-随身布袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000044] = {
		designer = "陈晓翰",
		notes = "被烧毁的信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000065] = {
		designer = "陈晓翰",
		notes = "成人之宴-物件-钱袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000074] = {
		designer = "何纪希",
		notes = "陈承",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000258] = {
		designer = "陈晓翰",
		notes = "爱哭鬼万事知墙体刻字",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000259] = {
		designer = "陈晓翰",
		notes = "爱哭鬼万事知模糊的全家福",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000260] = {
		designer = "陈晓翰",
		notes = "爱哭鬼万事知褪色的长命缕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000261] = {
		designer = "陈晓翰",
		notes = "爱哭鬼万事知斑驳的令牌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000342] = {
		designer = "陈晓翰",
		notes = "万华终陨-爆炸机括图纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000345] = {
		designer = "陈晓翰",
		notes = "鸢影相随-千斤坠解谜-神龛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[34000346] = {
		designer = "陈晓翰",
		notes = "书本 飞鸟与她",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000347] = {
		designer = "陈晓翰",
		notes = "书本 光与影",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000348] = {
		designer = "陈晓翰",
		notes = "书本 同道殊途",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000359] = {
		designer = "陈晓翰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000360] = {
		designer = "陈晓翰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000361] = {
		designer = "陈晓翰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000362] = {
		designer = "陈晓翰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[34000424] = {
		designer = "陈晓翰",
		notes = "被烧毁的信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000006] = {
		designer = "耿赟",
		notes = "长生鹿仙人-长生果",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000012] = {
		designer = "耿赟",
		notes = "蛇王密藏好蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000013] = {
		designer = "耿赟",
		notes = "蛇王密藏巡逻蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000014] = {
		designer = "耿赟",
		notes = "蛇王密藏紫色伤口蛇 不发光",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000017] = {
		designer = "耿赟",
		notes = "长生鹿仙人-荆棘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000018] = {
		designer = "耿赟",
		notes = "长生鹿仙人-荆棘花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000020] = {
		designer = "耿赟",
		notes = "长生鹿仙人-荆棘花2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000021] = {
		designer = "耿赟",
		notes = "长生鹿仙人-荆棘花3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000023] = {
		designer = "耿赟",
		notes = "长生鹿仙人 地面种植",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000039] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 池鱼林木万事知npc 吴兴平",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000040] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 池鱼林木万事知npc 方奈",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000041] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 池鱼林木万事知npc 王奇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000051] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc 阿狸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000052] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc 陈乐彤",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000053] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc  王守道",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000056] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室 npc 素利",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000057] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室 npc 陈述",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000058] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室 npc 承远",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000060] = {
		designer = "耿赟",
		notes = "蛇王密藏-破碎的手稿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000061] = {
		designer = "耿赟",
		notes = "明暗线配置用木门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000062] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室1 交互道具 浴桶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000063] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室1 交互道具 药瓶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000064] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室1 交互道具 地毯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000065] = {
		designer = "丁纪文",
		notes = "奇遇下-吉小鼠药包",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000067] = {
		designer = "宝箱",
		notes = "【正式】三品宝箱-珍宝匣",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[35000072] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室1 交互道具 皮鞭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000077] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 田芸娘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000078] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 王斗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000079] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 王衙内",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000081] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 商陆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000082] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 花鸟鱼虫 一封密信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000084] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 花鸟鱼虫 一封信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000085] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 花鸟鱼虫 一张纸条（陈述）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000086] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫密室4 交互道具 食材",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000088] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc  王守道",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000089] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc 任宝钰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000091] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 田淼儿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000092] = {
		designer = "耿赟",
		notes = "开封万事知 柳仙托梦NPC 闻古今",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000093] = {
		designer = "耿赟",
		notes = "开封万事知 柳仙托梦NPC 柳徵之",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000094] = {
		designer = "耿赟",
		notes = "开封万事知 柳仙托梦道具小抄",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000095] = {
		designer = "耿赟",
		notes = "书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000096] = {
		designer = "耿赟",
		notes = "书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000097] = {
		designer = "耿赟",
		notes = "明暗线大门 正确版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000098] = {
		designer = "何纪希",
		notes = "魏芷昔",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000100] = {
		designer = "耿赟",
		notes = "开封万事知 柳仙托梦NPC 闻古今",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000105] = {
		designer = "耿赟",
		notes = "开封万事知 膝下之金NPC 王老夫人",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000119] = {
		designer = "耿赟",
		notes = "十二载恩仇 祠堂空ENTITY交互-毒菌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000120] = {
		designer = "耿赟",
		notes = "十二载恩仇 祠堂空ENTITY交互-牌位1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000121] = {
		designer = "耿赟",
		notes = "十二载恩仇 祠堂空ENTITY交互-牌位2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000122] = {
		designer = "耿赟",
		notes = "十二载恩仇 祠堂空ENTITY交互-牌位3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000126] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc 任宝钰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000127] = {
		designer = "耿赟",
		notes = "开封 孤舟独影 npc 陈溪东",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000128] = {
		designer = "耿赟",
		notes = "开封 孤舟独影 npc 李总管",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000129] = {
		designer = "耿赟",
		notes = "开封 孤舟独影 npc 江小眠",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000130] = {
		designer = "耿赟",
		notes = "开封 孤舟独影 道具 破旧的小刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000131] = {
		designer = "耿赟",
		notes = "开封逆子家书 npc 石世福",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000132] = {
		designer = "耿赟",
		notes = "开封逆子家书 npc 崔弦",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000133] = {
		designer = "耿赟",
		notes = "开封逆子家书 npc 石守智",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000134] = {
		designer = "耿赟",
		notes = "梁小波<赤龙堂守卫>",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000135] = {
		designer = "耿赟",
		notes = "潘三郎<赤龙堂·堂众>",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000136] = {
		designer = "耿赟",
		notes = "江樱儿<赤龙堂·堂众>",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000138] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 花鸟鱼虫 一封密信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000141] = {
		designer = "耿赟",
		notes = "明暗线大门开启",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000143] = {
		designer = "任众",
		notes = "隔空取物-宝箱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000144] = {
		designer = "任众",
		notes = "隔空取物-宝箱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000145] = {
		designer = "任众",
		notes = "隔空取物-宝箱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000146] = {
		designer = "耿赟",
		notes = "十二载恩仇 村长遗落的道具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000149] = {
		designer = "耿赟",
		notes = "火盆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000150] = {
		designer = "耿赟",
		notes = "火盆特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000151] = {
		designer = "耿赟",
		notes = "长生鹿仙人氛围",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000152] = {
		designer = "耿赟",
		notes = "长生鹿仙人火焰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000153] = {
		designer = "耿赟",
		notes = "长生鹿仙人-长生果",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000156] = {
		designer = "耿赟",
		notes = "长生鹿仙人村长手信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000157] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 花鸟鱼虫 一封密信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000161] = {
		designer = "耿赟",
		notes = "开封 寿昌坊 池鱼林木万事知 药包",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[35000162] = {
		designer = "耿赟",
		notes = "开封 十二载恩仇 箩筐配置1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000163] = {
		designer = "耿赟",
		notes = "开封 十二载恩仇 箩筐配置2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000164] = {
		designer = "耿赟",
		notes = "开封 十二载恩仇 箩筐配置3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000188] = {
		designer = "耿赟",
		notes = "长生鹿仙人-供奉NPC：陆生",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000199] = {
		designer = "竺頔",
		notes = "隔空取物-蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000214] = {
		designer = "凌佳欣",
		notes = "认祖离宗-遗失的牌位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000217] = {
		designer = "任众",
		notes = "微解谜-隔空取物-石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[35000220] = {
		designer = "耿赟",
		notes = "开封 鱼兽鸟虫 npc 阿狸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[36000014] = {
		designer = "张益豪",
		notes = "【常平仓地下】解谜房-货物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[36000020] = {
		designer = "",
		notes = "太仓粟东郊野怪绿林B19",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[36000021] = {
		designer = "",
		notes = "太仓粟鹰愁岭野怪绿林B50",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[36000028] = {
		designer = "孙佳楠",
		notes = "承恩镇水井传送离开",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000000] = {
		designer = "梁栋",
		notes = "常平仓镇守新增-猛火油柜操作测试（1632240374）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000001] = {
		designer = "梁栋",
		notes = "飞花渡禁军营地-大宋官兵-枪兵（红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000011] = {
		designer = "梁栋",
		notes = "望淮南崖山腰营地-大宋官兵-枪兵（黑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000027] = {
		designer = "梁栋",
		notes = "飞花渡禁军营地-大宋官兵-突火枪兵（红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000029] = {
		designer = "梁栋",
		notes = "古渠营地-大宋官兵-旗帜号角（红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000030] = {
		designer = "梁栋",
		notes = "飞花渡禁军营地-大宋官兵-偃月刀兵（红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000032] = {
		designer = "梁栋",
		notes = "望淮南崖山腰营地-大宋官兵-枪兵（黑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000033] = {
		designer = "梁栋",
		notes = "旧村密道营地1-大宋官兵-旗帜号角（黑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000034] = {
		designer = "梁栋",
		notes = "旧村密道营地1-大宋官兵-偃月刀兵（黑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000038] = {
		designer = "梁栋",
		notes = "东南行营-禁军首领的日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000102] = {
		designer = "梁栋",
		notes = "阴雾林偷袭-寒菌梦傀-梿枷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000114] = {
		designer = "张益豪",
		notes = "《地下粮仓》-寒菌梦傀-铡草刀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000115] = {
		designer = "张益豪",
		notes = "《地下粮仓》-寒菌梦傀-连枷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000122] = {
		designer = "梁栋",
		notes = "【常平仓堡】中央塔楼区-塔楼顶层卫兵（弓兵）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000125] = {
		designer = "梁栋",
		notes = "【常平仓堡】账房守卫-枪兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[38000168] = {
		designer = "刘铭册",
		notes = "行政区-上朝-大宋官兵站岗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[38000169] = {
		designer = "刘铭册",
		notes = "行政区-上朝-大宋官兵首领站岗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[38000171] = {
		designer = "",
		notes = "行政区-上朝-大宋官兵站岗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[39000021] = {
		designer = "张俊杰",
		notes = "万事知粮价风波-承恩来信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000054] = {
		designer = "张俊杰",
		notes = "开门交互操控台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000055] = {
		designer = "张俊杰",
		notes = "巨石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000057] = {
		designer = "张俊杰",
		notes = "操纵杆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000058] = {
		designer = "张俊杰",
		notes = "闸门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000059] = {
		designer = "张俊杰",
		notes = "电梯绳子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000067] = {
		designer = "张俊杰",
		notes = "承恩镇农业小剧场-风车碰撞体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000105] = {
		designer = "张俊杰",
		notes = "羽绒草宝箱",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[39000106] = {
		designer = "张益豪",
		notes = "《六疾馆》毒雾陷阱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000107] = {
		designer = "张俊杰",
		notes = "嗟叹崖-木板组件-碰撞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000108] = {
		designer = "张俊杰",
		notes = "建隆观小道士",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000119] = {
		designer = "张俊杰",
		notes = "空模型-黑煞阴阳开启转转乐玩法用-南",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000120] = {
		designer = "张俊杰",
		notes = "空模型-黑煞阴阳开启转转乐玩法用-北",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000121] = {
		designer = "张俊杰",
		notes = "黑煞阴阳-义玉佩",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000122] = {
		designer = "张俊杰",
		notes = "黑煞阴阳-匡玉佩",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000124] = {
		designer = "张俊杰",
		notes = "太岳台-玄元教勾镰（近战小怪）-加窃听",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000125] = {
		designer = "张俊杰",
		notes = "太岳台-玄元教月相盘（远程）-加窃听",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000126] = {
		designer = "张俊杰",
		notes = "黑煞阴阳-信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000127] = {
		designer = "田野",
		notes = "太岳台-玄元教月相剑（精英）圆形视野-加窃听",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000128] = {
		designer = "张俊杰",
		notes = "空模型-转转乐宝箱开启玩法1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000129] = {
		designer = "张俊杰",
		notes = "空模型-转转乐宝箱开启玩法2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000133] = {
		designer = "张俊杰",
		notes = "郑鄂留下的信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000137] = {
		designer = "张俊杰",
		notes = "空模型-斗转星移光源",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000139] = {
		designer = "张俊杰",
		notes = "火盆-初始无特效",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000152] = {
		designer = "张俊杰",
		notes = "黄河鬼棺-信1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000153] = {
		designer = "张俊杰",
		notes = "黄河鬼棺-信2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000168] = {
		designer = "张俊杰",
		notes = "建隆观小道士",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000169] = {
		designer = "张俊杰",
		notes = "金玉手门锁-定制版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000170] = {
		designer = "黄乐孳",
		notes = "金玉手门-定制版",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000171] = {
		designer = "张俊杰",
		notes = "空模型-混元八阵解谜洞窟-传声中继站",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000172] = {
		designer = "张俊杰",
		notes = "妙妙喵-新供奉玩法-盘子模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000173] = {
		designer = "张俊杰",
		notes = "复合解谜黄河鬼棺-野果-交互发道具",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[39000175] = {
		designer = "模板表",
		notes = "复合解谜黄河鬼棺-世界等级-漕帮-投枪(红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000176] = {
		designer = "模板表",
		notes = "复合解谜黄河鬼棺-世界等级-漕帮-鱼叉（红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000177] = {
		designer = "模板表",
		notes = "复合解谜黄河鬼棺-世界等级-漕帮-斩骨刀（精英）红",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[39000205] = {
		designer = "张俊杰",
		notes = "【常平仓地下】水力主门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000051] = {
		designer = "张硕",
		notes = "缩骨功-传送门-石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[42000068] = {
		designer = "张硕",
		notes = "墨守之心镇守地图标",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000081] = {
		designer = "张硕",
		notes = "墨守之心三层旋浆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000082] = {
		designer = "张硕",
		notes = "墨守之心三层玻璃",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000085] = {
		designer = "张硕",
		notes = "无字牌位",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000086] = {
		designer = "张硕",
		notes = "墨守之心工作台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000100] = {
		designer = "张硕",
		notes = "墨守之心书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000101] = {
		designer = "张硕",
		notes = "墨守之心引导水流",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000107] = {
		designer = "张硕",
		notes = "墨守巳蛇·1-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000108] = {
		designer = "张硕",
		notes = "墨守巳蛇·2-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000118] = {
		designer = "张硕",
		notes = "墨守之心竖直扇叶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000121] = {
		designer = "张硕",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000122] = {
		designer = "张硕",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000123] = {
		designer = "张硕",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000124] = {
		designer = "张硕",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000127] = {
		designer = "张硕",
		notes = "墨守之心喝酒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000128] = {
		designer = "张硕",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000129] = {
		designer = "张硕",
		notes = "气泡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000130] = {
		designer = "张硕",
		notes = "装饰齿轮1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000132] = {
		designer = "张硕",
		notes = "装饰齿轮3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000135] = {
		designer = "张硕",
		notes = "普通宝箱-小-珍宝匣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000138] = {
		designer = "张硕",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000145] = {
		designer = "张硕",
		notes = "众匠人请留书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[42000146] = {
		designer = "张硕",
		notes = "书架上堆放多一些书籍",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000147] = {
		designer = "张硕",
		notes = "墨守之心信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000148] = {
		designer = "张硕",
		notes = "墨守之心信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000149] = {
		designer = "张硕",
		notes = "墨守之心信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000150] = {
		designer = "张硕",
		notes = "墨守之心信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000151] = {
		designer = "张硕",
		notes = "展柜交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000152] = {
		designer = "张硕",
		notes = "展柜交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000153] = {
		designer = "张硕",
		notes = "展柜交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000154] = {
		designer = "张硕",
		notes = "展柜交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000155] = {
		designer = "张硕",
		notes = "展柜交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000156] = {
		designer = "张硕",
		notes = "墨守之心电梯顶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000158] = {
		designer = "张硕",
		notes = "墨守之心电梯平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000159] = {
		designer = "张硕",
		notes = "墨守之心地图机关外圈",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000160] = {
		designer = "张硕",
		notes = "墨守之心栅栏",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000161] = {
		designer = "张硕",
		notes = "氧气buff",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000162] = {
		designer = "张硕",
		notes = "墨守之心boss电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000167] = {
		designer = "张硕",
		notes = "墨守之心天下均水水流",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000168] = {
		designer = "张硕",
		notes = "墨守之心天下均水水槽",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000178] = {
		designer = "张硕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[42000179] = {
		designer = "张硕",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000015] = {
		designer = "管骏涛",
		notes = "麻袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000016] = {
		designer = "管骏涛",
		notes = "木条箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000018] = {
		designer = "管骏涛",
		notes = "熔炉-合背钱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[43000019] = {
		designer = "管骏涛",
		notes = "熔炉-钱币",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000020] = {
		designer = "管骏涛",
		notes = "熔炉-垫纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000060] = {
		designer = "管骏涛",
		notes = "闻籁之声-太平钟楼顶-木箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[43000093] = {
		designer = "管骏涛",
		notes = "交互物黄色光柱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[44000033] = {
		designer = "陆俊庆",
		notes = "飞天残垣轴承转盘1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[44000034] = {
		designer = "陆俊庆",
		notes = "飞天残垣轴承转盘1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[46000016] = {
		designer = "唐懿",
		notes = "燕北盟-烈言绝笔",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[49000002] = {
		designer = "陈实",
		notes = "小李飞刀-近天匣",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[49000160] = {
		designer = "陈实",
		notes = "售货机-墨城旧址",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[49000196] = {
		designer = "陈实",
		notes = "不见山通用电梯操控台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[57000202] = {
		designer = "陈胜",
		notes = "麻将变狗酒缸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[59000001] = {
		designer = "赵昊斐",
		notes = "大相国寺-江湖留名碑文",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000121] = {
		designer = "吕佳男",
		notes = "万事知-长毋相忘-金簪采集物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000128] = {
		designer = "吕佳男",
		notes = "新手引导-将军祠祭拜空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000412] = {
		designer = "吕佳男",
		notes = "不见山平原区-万事知-前路难寻-木鸢饲养记录",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000413] = {
		designer = "吕佳男",
		notes = "不见山平原区-万事知-隐世之法-木材",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000414] = {
		designer = "吕佳男",
		notes = "不见山平原区-万事知-隐世之法-叶片",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000416] = {
		designer = "吕佳男",
		notes = "不见山千年渡-氛围-空模型交互点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000423] = {
		designer = "吕佳男",
		notes = "不见山奇遇-洞中奇谈-某人的日记",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000449] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-万事知-待办事项-木材堆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000450] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-万事知-待办事项-工匠李房间的字条1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000451] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-万事知-待办事项-工匠李房间的字条2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000452] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-万事知-待办事项-工匠李房间的字条3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000453] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-万事知-待办事项-陈林的威胁信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000464] = {
		designer = "吕佳男",
		notes = "不见山奇遇-不义之约-王守墓碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000473] = {
		designer = "张懿",
		notes = "不见山千年渡-万事知-农场遗孤-小蝶父亲尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000475] = {
		designer = "吕佳男",
		notes = "不见山千年渡-万事知-三兄妹的梦-断翅木鸢左翅膀",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000488] = {
		designer = "吕佳男",
		notes = "不见山奇遇-铸剑-天冶剑四·同心（任务完成后晚上）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000489] = {
		designer = "吕佳男",
		notes = "不见山千年渡-万事知-农场遗孤-小蝶父亲尸体交互点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000521] = {
		designer = "吕佳男",
		notes = "不见山千年渡-万事知-桃源何处-老舵工吐血血迹",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000550] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-探游-引入任务-书籍借阅登记册",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000551] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-氛围-学习组-钱为轻誊抄的信件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000564] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-探游-引入任务-木鸢检修规范",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000565] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-探游-引入任务-制鸢分番轮值簿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000566] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-探游-引入任务-洞口荆棘",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000591] = {
		designer = "吕佳男",
		notes = "不见山奇遇-洞中奇谈-纸条1提示光点",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000609] = {
		designer = "吕佳男",
		notes = "不见山栖鸟岩-氛围-青的邀请函",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000615] = {
		designer = "吕佳男",
		notes = "不见山奇遇-狸猫太子-雪奴任务后常驻",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[60000618] = {
		designer = "吕佳男",
		notes = "不见山嗟叹崖-氛围-《巨子有客老狸》",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000621] = {
		designer = "吕佳男",
		notes = "不见山嗟叹崖-氛围-《墨问-窥天》",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000629] = {
		designer = "吕佳男",
		notes = "不见山墨城旧址-氛围-一坛被封存的酒",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000630] = {
		designer = "吕佳男",
		notes = "不见山墨城旧址-氛围-鹤的人情账",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[60000631] = {
		designer = "吕佳男",
		notes = "不见山奇遇-来自心底的声音-传音器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000635] = {
		designer = "吕佳男",
		notes = "不见山墨城-氛围-警察局-笼子（不可破坏）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[60000637] = {
		designer = "吕佳男",
		notes = "不见山奇遇-不义之约-王守的信结局2坟墓上",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000002] = {
		designer = "曹涵松",
		notes = "鱼卵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000003] = {
		designer = "模板表",
		notes = "世界等级-黄河生物-怪鱼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000004] = {
		designer = "仇金翰",
		notes = "弩机AI-弩后勤兵",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000009] = {
		designer = "仇金翰",
		notes = "弩机AI-弩后勤兵-短桥",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000010] = {
		designer = "竺頔",
		notes = "万古一人殿-隔空取物-蛇-一层",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000011] = {
		designer = "竺頔",
		notes = "万古一人殿-隔空取物-蛇",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[61000012] = {
		designer = "曹涵松",
		notes = "疯龙王-尸体",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000009] = {
		designer = "任俊霖",
		notes = "开封-万世知1等价交换-王平室内氛围-书卷-氛围",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000017] = {
		designer = "任俊霖",
		notes = "开封-万世知15-茱萸有芳-坟墓按钮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000093] = {
		designer = "任俊霖",
		notes = "开封-天上来-火盆（小火）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[66000094] = {
		designer = "任俊霖",
		notes = "开封-天上来-猫咪的碗",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[66000095] = {
		designer = "任俊霖",
		notes = "开封-天上来-货物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[66000096] = {
		designer = "任俊霖",
		notes = "开封-天上来-椅子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[66000128] = {
		designer = "任俊霖",
		notes = "缩骨功-常驻-爷爷的秘宝",
		wanfa_types = {},
		has_reward = true,
		save_type = 1,
		space = "s501",
		reasons = { "has_reward" },
	},
	[66000130] = {
		designer = "任俊霖",
		notes = "缩骨功-收集物-货物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000131] = {
		designer = "任俊霖",
		notes = "缩骨功-常驻障碍物-钱袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000132] = {
		designer = "任俊霖",
		notes = "缩骨功-常驻障碍物-麻袋",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66000134] = {
		designer = "任俊霖",
		notes = "缩骨功蹊跷-老鼠",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66000135] = {
		designer = "任俊霖",
		notes = "缩骨功蹊跷-蛐蛐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100051] = {
		designer = "任俊霖",
		notes = "墨城-万事知-可我馋啊-篝火",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100052] = {
		designer = "任俊霖",
		notes = "墨城-万事知-可我馋啊-鱼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100054] = {
		designer = "任俊霖",
		notes = "墨城-万事知-故鸟于飞-泣血青鸟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100055] = {
		designer = "王治",
		notes = "墨城-万事知-头顶大事-马",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100129] = {
		designer = "任俊霖",
		notes = "小椅子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100236] = {
		designer = "",
		notes = "程龙亲友",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100237] = {
		designer = "",
		notes = "程龙亲友",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100238] = {
		designer = "",
		notes = "印刷-程龙围观2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100239] = {
		designer = "",
		notes = "印刷-程龙围观3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100315] = {
		designer = "",
		notes = "奋发实录·其一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100316] = {
		designer = "",
		notes = "奋发实录·其二",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100317] = {
		designer = "",
		notes = "奋发实录·其三",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100318] = {
		designer = "",
		notes = "学间哲思",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100319] = {
		designer = "",
		notes = "墨山道门派记事·晋之卷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100320] = {
		designer = "",
		notes = "墨山道巨子札记·鹉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100321] = {
		designer = "",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100322] = {
		designer = "",
		notes = "书本",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100323] = {
		designer = "",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[66100350] = {
		designer = "",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[66100351] = {
		designer = "",
		notes = "包袱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[69000002] = {
		designer = "韦华栋",
		notes = "蹦蹦鼓组件-测试",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[70000005] = {
		designer = "向茎格",
		notes = "小剧场-嗟来之食-鲤鱼氛围",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[70000064] = {
		designer = "向茎格",
		notes = "听泉赏宝-纸条",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[70000257] = {
		designer = "向茎格",
		notes = "斗地主桌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[70000263] = {
		designer = "王煊量",
		notes = "少东家的一天-斗地主桌",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[70000571] = {
		designer = "黄乐孳",
		notes = "斗地主桌（501联机）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[70000855] = {
		designer = "向茎格",
		notes = "通用信封-新",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[71000106] = {
		designer = "毛龙",
		notes = "猫猫·千年渡1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000107] = {
		designer = "毛龙",
		notes = "猫猫·千年渡2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000108] = {
		designer = "毛龙",
		notes = "猫猫·墨城1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000109] = {
		designer = "毛龙",
		notes = "猫猫·墨城2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000110] = {
		designer = "毛龙",
		notes = "猫猫·墨城3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000111] = {
		designer = "毛龙",
		notes = "猫猫·墨城4",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000112] = {
		designer = "毛龙",
		notes = "猫猫·墨城5",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000113] = {
		designer = "毛龙",
		notes = "猫猫·墨城旧址1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000114] = {
		designer = "毛龙",
		notes = "猫猫·嗟叹崖1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000115] = {
		designer = "毛龙",
		notes = "猫猫·嗟叹崖2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000116] = {
		designer = "毛龙",
		notes = "猫猫·碧水云涛1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000117] = {
		designer = "毛龙",
		notes = "猫猫·碧水云涛2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000118] = {
		designer = "毛龙",
		notes = "猫猫·碧水云涛3",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000119] = {
		designer = "毛龙",
		notes = "猫猫·晦谷1",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000120] = {
		designer = "毛龙",
		notes = "猫猫·晦谷2",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000130] = {
		designer = "毛龙",
		notes = "摇铃祈福-千年渡石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000131] = {
		designer = "毛龙",
		notes = "摇铃祈福-墨城石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000132] = {
		designer = "毛龙",
		notes = "摇铃祈福-墨城旧址石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000133] = {
		designer = "毛龙",
		notes = "摇铃祈福-嗟叹崖石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000135] = {
		designer = "毛龙",
		notes = "摇铃祈福-晦谷石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000150] = {
		designer = "毛龙",
		notes = "悬壶-千年渡",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000151] = {
		designer = "毛龙",
		notes = "悬壶-墨城1",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000152] = {
		designer = "毛龙",
		notes = "悬壶-墨城2",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000153] = {
		designer = "毛龙",
		notes = "悬壶-墨城旧址",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000154] = {
		designer = "毛龙",
		notes = "悬壶-嗟叹崖",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000155] = {
		designer = "毛龙",
		notes = "悬壶-碧水云涛",
		wanfa_types = { 7 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_7" },
	},
	[71000156] = {
		designer = "毛龙",
		notes = "话术-千年渡",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000157] = {
		designer = "毛龙",
		notes = "话术-墨城1",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000158] = {
		designer = "毛龙",
		notes = "话术-墨城2",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000159] = {
		designer = "毛龙",
		notes = "话术-墨城旧址",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000160] = {
		designer = "毛龙",
		notes = "话术-嗟叹崖",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000161] = {
		designer = "毛龙",
		notes = "话术-碧水云涛",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000162] = {
		designer = "毛龙",
		notes = "猫猫·公输九九",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000163] = {
		designer = "毛龙",
		notes = "与鹏书信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[71000164] = {
		designer = "毛龙",
		notes = "云梯制造图纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[71000165] = {
		designer = "毛龙",
		notes = "未完成的机关图纸",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[71000166] = {
		designer = "毛龙",
		notes = "树上的刻痕",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[71000216] = {
		designer = "毛龙",
		notes = "话术-碧水云涛-鹈鹕",
		wanfa_types = { 34 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_34" },
	},
	[71000221] = {
		designer = "毛龙",
		notes = "猫猫·阿妙",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000222] = {
		designer = "毛龙",
		notes = "猫猫·天工",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[71000223] = {
		designer = "毛龙",
		notes = "猫猫·墨球",
		wanfa_types = { 5 },
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[77000000] = {
		designer = "王凯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[88000038] = {
		designer = "张昊岳",
		notes = "氿留门断案集",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89000002] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-椅子下压力板-书房",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001000] = {
		designer = "郭宇昂",
		notes = "不见山潜水洞窟-机关交互2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001004] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001006] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-动力源齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001009] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-转盘中央-2层平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001010] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-转盘外围",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001011] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-电梯平台_新",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001013] = {
		designer = "魏子奥",
		notes = "返回关卡入口特效-空交互",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001015] = {
		designer = "魏子奥",
		notes = "不见山天工地窟01-铁链匣底座",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001016] = {
		designer = "魏子奥",
		notes = "不见山天工地窟02-3号洞青铜门_3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001017] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-传动匣底座-中央电梯转盘_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001018] = {
		designer = "魏子奥",
		notes = "不见山天工地窟02-3号洞机关-铁链_6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001019] = {
		designer = "魏子奥",
		notes = "不见山天工地窟02-中央石柱旋转齿轮-3号洞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001022] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-大门接收柱齿轮",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001024] = {
		designer = "魏子奥",
		notes = "不见山天工地窟02-传动匣支撑柱-大门入口",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001026] = {
		designer = "魏子奥",
		notes = "不见山-青铜机关门",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001027] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关墙(室外)-入口连接通道_4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001029] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-压力地板-书房_2-6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001030] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-椅子_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001033] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关拉杆-书房",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001036] = {
		designer = "竺頔",
		notes = "重物1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001038] = {
		designer = "魏子奥",
		notes = "万事知-不可留之物一-秘匣1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001039] = {
		designer = "魏子奥",
		notes = "万事知-不可留之物一-秘匣2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001040] = {
		designer = "魏子奥",
		notes = "万事知-不可留之物一-秘匣3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001041] = {
		designer = "蒙名恒",
		notes = "不见山天工地窟03-第2层机关鸟旋转平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001042] = {
		designer = "模板表",
		notes = "不见山主线-机关仓库-镖师-书房_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001043] = {
		designer = "模板表",
		notes = "不见山主线-机关仓库-镖师-书房_3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001044] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-仓库暗道入口机关鸟",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001046] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-室外弩箭石门-配件-小-室外_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001047] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-室外弩箭石门-配件-大-室外_3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001048] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-底座-内环_1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001049] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-底座-外环_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001050] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-书桌-大厅侧_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001051] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-齿轮背景板_内侧_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001052] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-大书柜_大厅侧_1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001053] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅-石墙_1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001054] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-书房-阶梯书柜_14-4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001055] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-大厅-暗道石板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001056] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-石台阶_5",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001057] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-暗道石板装饰",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001058] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-大柜子-书房拉杆房间",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001060] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-拉杆下方齿轮_1-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001061] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-拉杆下方齿轮_2-3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001062] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-仓库暗道入口石板",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001065] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-地板包边-书房_3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001066] = {
		designer = "魏子奥",
		notes = "空entity-天工地窟01追踪标",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001067] = {
		designer = "魏子奥",
		notes = "不见山天工地窟02-潜水钟铁链(无功能，装饰用)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001069] = {
		designer = "宝箱",
		notes = "不见山主线-机关仓库-二品宝箱_1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[89001070] = {
		designer = "宝箱",
		notes = "不见山主线-机关仓库-三品宝箱_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[89001071] = {
		designer = "宝箱",
		notes = "不见山主线-机关仓库-四品宝箱_2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2", "wanfa_tag" },
	},
	[89001072] = {
		designer = "魏子奥",
		notes = "不见山天工地窟03-拉杆底座_1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001073] = {
		designer = "宝箱",
		notes = "Wei不见山天工地窟01-最终宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[89001074] = {
		designer = "宝箱",
		notes = "Wei不见山天工地窟02-最终宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[89001075] = {
		designer = "宝箱",
		notes = "不见山天工地窟03-最终宝箱",
		wanfa_types = { 9 },
		has_reward = false,
		save_type = 1,
		space = "s501",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[89001076] = {
		designer = "林野",
		notes = "不见山天工地窟03-2层小平台拉杆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001081] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅2-带动画齿轮6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001082] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅1-带动画齿轮2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001083] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-机关椅1-带动画齿轮3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001084] = {
		designer = "魏子奥",
		notes = "墨城旧址-外门入门名册-卷九",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001085] = {
		designer = "魏子奥",
		notes = "墨城旧址-外门入门名册-卷四百二十一",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001098] = {
		designer = "魏子奥",
		notes = "墨城旧址-未寄出的信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001099] = {
		designer = "魏子奥",
		notes = "墨城旧址-鸿的信件-给途-可拾取",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001100] = {
		designer = "魏子奥",
		notes = "墨城旧址-家书-给途-可拾取",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001101] = {
		designer = "魏子奥",
		notes = "墨城旧址-告门中诸弟子函-可拾取",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001104] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-墨山道新生机关问答集",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001105] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-游学手札",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001106] = {
		designer = "魏子奥",
		notes = "不见山主线-机关仓库-如何识别身边的墨山道",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[89001107] = {
		designer = "魏子奥",
		notes = "长明灯-油灯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001108] = {
		designer = "魏子奥",
		notes = "不见山天工地窟1-瀑布大",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001109] = {
		designer = "魏子奥",
		notes = "不见山天工地窟1-瀑布小",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[89001110] = {
		designer = "魏子奥",
		notes = "不见山天工地窟2-大岩石",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[90000093] = {
		designer = "王蔺景",
		notes = "端午活动-红线的墓（引导对话视线)",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[94000086] = {
		designer = "刘飘扬",
		notes = "猫猫玩具-蓄水池",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[110000015] = {
		designer = "王靖博",
		notes = "商业大亨-空交互-睡觉",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[110000032] = {
		designer = "王靖博",
		notes = "秦川-我的朋友-任务结束后传送回地洞",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[120000176] = {
		designer = "生态物种",
		notes = "巴哥犬1631501061",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000197] = {
		designer = "生态物种",
		notes = "巴哥犬1234551925",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000198] = {
		designer = "生态物种",
		notes = "巴哥犬1631600769",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000201] = {
		designer = "刘铭册",
		notes = "寿昌坊-狗1632212529",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000202] = {
		designer = "刘铭册",
		notes = "寿昌坊-狗1632212530",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000204] = {
		designer = "生态物种",
		notes = "郁林犬2700437",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000206] = {
		designer = "生态物种",
		notes = "郁林犬1234551922",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000212] = {
		designer = "生态物种",
		notes = "巴哥犬",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000213] = {
		designer = "生态物种",
		notes = "承恩镇氛围-狗",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[120000237] = {
		designer = "张建楠",
		notes = "吱吱",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[126000001] = {
		designer = "傅泽宇",
		notes = "江叔生日-彩蛋-交互桌子-没做任务",
		wanfa_types = {},
		has_reward = true,
		save_type = 1,
		space = "s501",
		reasons = { "has_reward" },
	},
	[142001000] = {
		designer = "",
		notes = "墨城旧址-机关楼1动力源查看1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001001] = {
		designer = "",
		notes = "墨城旧址-机关楼1动力源查看2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001012] = {
		designer = "",
		notes = "墨城旧址-查看-残破的手稿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001013] = {
		designer = "",
		notes = "墨城旧址-查看-桌上手稿",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001034] = {
		designer = "",
		notes = "操纵杆",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001044] = {
		designer = "",
		notes = "灰狼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001052] = {
		designer = "鄢朔",
		notes = "壁画交互1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001053] = {
		designer = "鄢朔",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001054] = {
		designer = "鄢朔",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001055] = {
		designer = "鄢朔",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001056] = {
		designer = "鄢朔",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001059] = {
		designer = "鄢朔",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001060] = {
		designer = "鄢朔",
		notes = "墨城旧址-查看-温故知新刻字",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001061] = {
		designer = "鄢朔",
		notes = "墨城旧址-查看-墨经新述（书）",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[142001063] = {
		designer = "鄢朔",
		notes = "墨城旧址-与师鹳书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[142001064] = {
		designer = "鄢朔",
		notes = "外门名册",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[170000030] = {
		designer = "",
		notes = "吃饭桌椅-椅",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[180000087] = {
		designer = "曾一洪",
		notes = "兔毛箱子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
	[190000014] = {
		designer = "王浩祎",
		notes = "不见山 战斗组件炸药桶",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000015] = {
		designer = "王浩祎",
		notes = "不见山 战斗组件箱子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000021] = {
		designer = "王浩祎",
		notes = "鲁班锁组件三通01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000022] = {
		designer = "王浩祎",
		notes = "鲁班锁组件三通02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000023] = {
		designer = "王浩祎",
		notes = "鲁班锁组件三通03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000027] = {
		designer = "林野",
		notes = "墨守之心外部电梯",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000028] = {
		designer = "",
		notes = "竖直滑索底部空交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000037] = {
		designer = "王浩祎",
		notes = "墨城电梯铁链",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000041] = {
		designer = "王浩祎",
		notes = "震天雷宝箱3-墨城",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9" },
	},
	[190000042] = {
		designer = "王浩祎",
		notes = "竖直滑索站台-初始关闭",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000043] = {
		designer = "王浩祎",
		notes = "竖直滑索底部空交互物",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000044] = {
		designer = "王浩祎",
		notes = "鲁班锁实体宝箱",
		wanfa_types = { 9, 22 },
		has_reward = false,
		save_type = 0,
		space = "s1",
		reasons = { "wanfa_9", "wanfa_tag" },
	},
	[190000045] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000046] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000047] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根03",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000048] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根04",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000049] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根05",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000050] = {
		designer = "王浩祎",
		notes = "鲁班锁组件六根06",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000060] = {
		designer = "王浩祎",
		notes = "鲁班锁组件笼中取物01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000061] = {
		designer = "王浩祎",
		notes = "鲁班锁组件笼中取物02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000062] = {
		designer = "王浩祎",
		notes = "不见山飞来索移动平台",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000067] = {
		designer = "王浩祎",
		notes = "不见山鲁班锁组件E1-01",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000068] = {
		designer = "王浩祎",
		notes = "不见山鲁班锁组件E1-02",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000069] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根11",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000070] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根12",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000071] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根13",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000072] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根14",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000073] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根15",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000074] = {
		designer = "王浩祎",
		notes = "鲁班锁组件九根16",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000077] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000078] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000079] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000080] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000081] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[190000082] = {
		designer = "王浩祎",
		notes = "鲁班锁空entity三通",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000384] = {
		designer = "",
		notes = "千纸鹤",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000385] = {
		designer = "陆楚文",
		notes = "谢察微算经",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000396] = {
		designer = "陆楚文",
		notes = "墨城-从娃娃抓起-小红花",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000397] = {
		designer = "陆楚文",
		notes = "墨城-从娃娃抓起-精密零件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000398] = {
		designer = "陆楚文",
		notes = "墨城-从娃娃抓起-作坊工件",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000406] = {
		designer = "陆楚文",
		notes = "万事知-如此论战-无敌永动鸡",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000408] = {
		designer = "陆楚文",
		notes = "火焰触发器",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000411] = {
		designer = "陆楚文",
		notes = "万事知-如此论战-超绝飞天墨鸢[无交互]",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000414] = {
		designer = "",
		notes = "墨工桌子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000415] = {
		designer = "",
		notes = "木牛核心1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000416] = {
		designer = "",
		notes = "碧水云涛-见闻-停云石碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000418] = {
		designer = "",
		notes = "碧水云涛-见闻-女子画像",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000422] = {
		designer = "",
		notes = "碧水云涛-见闻-绕树三匝",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000431] = {
		designer = "",
		notes = "任老汉的摆渡船",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000432] = {
		designer = "",
		notes = "裘索的麻袋1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000433] = {
		designer = "",
		notes = "裘索的麻袋3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000434] = {
		designer = "",
		notes = "裘索的货箱1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000439] = {
		designer = "",
		notes = "阿浑的青鸟[摆件1]",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000440] = {
		designer = "",
		notes = "阿浑的青鸟[可交互7]",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000444] = {
		designer = "",
		notes = "碧水云涛-风波悼-李兰露父母墓碑",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000457] = {
		designer = "",
		notes = "碧水云涛-风波悼-李兰露的信",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000459] = {
		designer = "",
		notes = "碧水云涛-万事知-破坏的机关牛",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000500] = {
		designer = "",
		notes = "峰林区-九女峰-老翁的烤鱼",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000537] = {
		designer = "",
		notes = "不见山-嗟叹崖-日晷",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000538] = {
		designer = "陆楚文",
		notes = "不见山-猴王冠-猴王的石头",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000539] = {
		designer = "",
		notes = "不见山-嗟叹崖-妙算算的书",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000542] = {
		designer = "",
		notes = "驿站旗子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000543] = {
		designer = "",
		notes = "气氛棕马",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000544] = {
		designer = "",
		notes = "气氛黑马",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000583] = {
		designer = "陆楚文",
		notes = "不见山-绝嶂岭-醒山钟1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000584] = {
		designer = "陆楚文",
		notes = "不见山-绝嶂岭-醒山钟2",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000585] = {
		designer = "陆楚文",
		notes = "不见山-绝嶂岭-醒山钟3",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000586] = {
		designer = "陆楚文",
		notes = "不见山-绝嶂岭-醒山钟4",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000597] = {
		designer = "陆楚文",
		notes = "不见山-猴王冠-猴王Body",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000598] = {
		designer = "陆楚文",
		notes = "不见山-猴王冠-猴王宝箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000599] = {
		designer = "陆楚文",
		notes = "不见山-猴王冠-猴王的《墨经》",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s701",
		reasons = { "save_type_2" },
	},
	[220000608] = {
		designer = "陆楚文",
		notes = "不见山-绝嶂岭-醒山钟1架子1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000611] = {
		designer = "陆楚文",
		notes = "不见山-千年渡-氛围脚印2-1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000638] = {
		designer = "陆楚文",
		notes = "晦谷-矿洞-慕正宗的箩筐",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[220000639] = {
		designer = "陆楚文",
		notes = "晦谷-矿洞-慕正宗的矿球1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[250000152] = {
		designer = "张泽华",
		notes = "九流门-彩-桌子",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[270000110] = {
		designer = "李洁",
		notes = "车站1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[270000111] = {
		designer = "李洁",
		notes = "义捐箱",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[270000128] = {
		designer = "李洁",
		notes = "车站6",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[270000129] = {
		designer = "李洁",
		notes = "车站7",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[321000023] = {
		designer = "戴昊翔",
		notes = "寒大楚（正常）",
		wanfa_types = {},
		has_reward = true,
		save_type = 0,
		space = "s501",
		reasons = { "has_reward" },
	},
	[330000158] = {
		designer = "刘彦辰",
		notes = "家园奇遇-回忆10-交互药炉开启回忆任务",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[330000302] = {
		designer = "刘彦辰",
		notes = "机关墙-静态交互物-不见山愤怒小鸟玩法",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[350000043] = {
		designer = "林思静",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[700000060] = {
		designer = "李霞",
		notes = "药瓶1",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s501",
		reasons = { "save_type_2" },
	},
	[700000104] = {
		designer = "李霞",
		notes = "通用空模型",
		wanfa_types = {},
		has_reward = false,
		save_type = 2,
		space = "s1",
		reasons = { "save_type_2" },
	},
}

-- ============================================================
-- STATISTICS
-- ============================================================
LOOT_DATA.STATS = {
	total_entities = 19737,
	unique_npc_nos = 2542,
	by_wanfa = {
		[5] = 276, -- quest_item
		[7] = 141, -- fishing
		[9] = 5602, -- treasure
		[12] = 8, -- hidden
		[22] = 652, -- unknown
		[34] = 129, -- explore_e
	},
	by_space = {
		["s1"] = 2304,
		["s501"] = 8476,
		["s701"] = 8957,
	},
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

--- Check if base_tag is safe for auto-loot
---@param base_tag number Base tag ID from sys_d
---@return boolean
function LOOT_DATA.is_lootable_base_tag(base_tag)
	return LOOT_DATA.LOOTABLE_BASE_TAGS[base_tag] == true
end

--- Check if base_tag should be skipped
---@param base_tag number Base tag ID from sys_d
---@return boolean
function LOOT_DATA.should_skip_base_tag(base_tag)
	return LOOT_DATA.SKIP_BASE_TAGS[base_tag] == true
end

--- Check if base_tag should ALWAYS be skipped (signposts, etc.)
---@param base_tag number Base tag ID from sys_d
---@return boolean
function LOOT_DATA.should_always_skip_base_tag(base_tag)
	return LOOT_DATA.ALWAYS_SKIP_BASE_TAGS[base_tag] == true
end

--- Get base_tag definition
---@param base_tag number Base tag ID
---@return table|nil
function LOOT_DATA.get_base_tag_def(base_tag)
	return LOOT_DATA.BASE_TAG_DEFS[base_tag]
end

--- Check if entity_type is lootable
---@param entity_type number Entity type from sys_d
---@return boolean
function LOOT_DATA.is_lootable_entity_type(entity_type)
	return LOOT_DATA.LOOTABLE_ENTITY_TYPES[entity_type] == true
end

--- Check if npc_no is a known lootable entity config
---@param npc_no number Entity configuration ID
---@return boolean
function LOOT_DATA.is_lootable_npc(npc_no)
	return LOOT_DATA.LOOTABLE_NPC_NOS[npc_no] == true
end

--- Check if wanfa_type is a lootable category
---@param wanfa_type number Gameplay category ID
---@return boolean
function LOOT_DATA.is_lootable_wanfa(wanfa_type)
	return LOOT_DATA.LOOTABLE_WANFA[wanfa_type] == true
end

--- Check if wanfa_type should be skipped
---@param wanfa_type number Gameplay category ID
---@return boolean
function LOOT_DATA.should_skip_wanfa(wanfa_type)
	return LOOT_DATA.SKIP_WANFA[wanfa_type] == true
end

--- Check if entity tag string is safe for auto-loot
---@param tag string Tag string (e.g., 'TAG_TREASURE_BOX')
---@return boolean
function LOOT_DATA.is_safe_tag(tag)
	return LOOT_DATA.SAFE_TAGS[tag] == true
end

--- Check if entity tag string should be skipped
---@param tag string Tag string
---@return boolean
function LOOT_DATA.should_skip_tag(tag)
	return LOOT_DATA.SKIP_TAGS[tag] == true
end

--- Get detailed entity data by npc_no
---@param npc_no number Entity configuration ID
---@return table|nil
function LOOT_DATA.get_entity_data(npc_no)
	return LOOT_DATA.ENTITY_DATA[npc_no]
end

--- Get wanfa type info
---@param wanfa_type number Gameplay category ID
---@return table|nil
function LOOT_DATA.get_wanfa_info(wanfa_type)
	return LOOT_DATA.WANFA_TYPES[wanfa_type]
end

--- Check if npc_no falls in a safe range
---@param npc_no number Entity configuration ID
---@return boolean|string Returns true, false, or 'maybe'
function LOOT_DATA.check_npc_no_range(npc_no)
	for _, range_info in ipairs(LOOT_DATA.NPC_NO_RANGES) do
		if npc_no >= range_info.low and npc_no <= range_info.high then
			return range_info.safe
		end
	end
	return "maybe"
end

--- Check if interact_config is a loot-type interaction
---@param config_id number Interact config ID
---@return boolean
function LOOT_DATA.is_loot_interact_config(config_id)
	for _, range_info in ipairs(LOOT_DATA.INTERACT_CONFIG_RANGES) do
		if config_id >= range_info.low and config_id <= range_info.high then
			return range_info.type == "loot"
		end
	end
	return false
end

--- Get count of lootable entity configs
---@return number
function LOOT_DATA.get_count()
	return 2542
end

return LOOT_DATA
