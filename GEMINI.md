# CLAUDE.md

## Project Purpose

This is a **Lua-based game modding/support tool** for the game "Where Winds Meet" (WWM) for development and testing purposes. It provides:

- **Debug/Support Features**: God mode, infinite stamina, speed hacks, one-hit kill, invisibility
- **Combat Automation**: Auto-parry system with skill timing data
- **World Modifications**: Auto-loot, NPC behavior control, crime reset
- **Buff System**: PVE, gathering, fishing, crafting buff presets
- **Module Dumping**: Extract and analyze game Lua modules from memory
- **Skin Changer**: Character appearance modification
- **Tracing Tools**: Function call tracing for reverse engineering

## Tech Stack

- **Primary Language**: Lua 5.x (embedded in game's custom VM)
- **UI Framework**: Cocos2d-x (accessed via `cc` and `ccui` globals)
- **Game Engine**: Custom game engine with Lua bindings
- **Supporting Tools**: Python scripts for data processing/ lua injecting/ lua dumping
- **Target Platform**: Windows (the game runs on Windows)

## Key Dependencies

- `cc` - Cocos2d-x core module
- `ccui` - Cocos2d-x UI widgets
- `G` - Game global object (contains `main_player`, etc.)
- `portable.import` - Game's custom module import system
- `package.loaded` / `package.preload` - Standard Lua module system

## Source of Truth (Authoritative Only)
- Code: `Scripts/source_decompiled/`
- Data: `Scripts/data/DirObject/`
- Traces (only if mentioned): `Scripts/traces/`


## Workflows

This project uses dedicated workflow documents. **You MUST read and follow the appropriate workflow** before starting work:

| Task Type | Workflow | When to Use |
|-----------|----------|-------------|
| **Research / Analysis / Debug** | [`RESEARCH.md`](RESEARCH.md) | Investigating game behavior, analyzing traces, locating functions/data, debugging issues, mapping config-to-code, reverse engineering |
| **Implementation / Fix / Extend** | [`IMPLEMENT.md`](IMPLEMENT.md) | Adding features, fixing bugs, extending scripts, writing probe tests, any code changes |

**Rules:**
- For **research/analysis/debug** tasks → read and follow `RESEARCH.md` (evidence-based investigation with scoped search, anti-overflow rules, evidence scoring, and runtime probe verification)
- For **implementation/fix/extend** tasks → read and follow `IMPLEMENT.md` (TDD-first workflow with red-green-refactor cycle, probe-driven API discovery, and mandatory runtime verification)
- Many tasks require **both**: research first (RESEARCH.md) to understand the system, then implement (IMPLEMENT.md) to make changes
- Do **not** skip the workflows or inline your own ad-hoc process
