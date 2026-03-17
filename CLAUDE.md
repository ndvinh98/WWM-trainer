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


## Data-Driven Development Workflow

The project follows a data-driven approach for implementing new features:

1.  **Identify Interest Point**: Start with a specific feature requirement or keyword provided by the user.
2.  **Trace Analysis**: Search for relevant function calls and identifiers in the `Scripts/traces/` folder to understand execution flow if user specified.
3.  **Code Lookup**: Locate and analyze the corresponding dumped game code in the `Source of Truth` folder based on the trace results.
4.  **Implementation Plan**: Create a detailed plan for the feature, including hooks, logic, and UI integration.
5.  **User Review**: Present the plan to the user for validation before proceeding with the implementation.

