# DUNGEON ZERO (v1.0.0)

> **A high-performance, deterministic terminal roguelike dungeon crawler and AI coding-agent benchmark harness implemented strictly in pure Nim 2.4.0.**

[![Nim](https://img.shields.io/badge/Nim-2.4.0-yellow.svg)](https://nim-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-11%20Suites%20Passing-brightgreen.svg)]()
[![Pure Stdlib](https://img.shields.io/badge/Dependencies-Standard%20Library%20Only-success.svg)]()

---

## 1. Project Overview

**DUNGEON ZERO** is a classic ASCII roguelike dungeon crawler built from scratch for a coding-agent hackathon experiment. It features rich procedural level generation, dynamic raycasted field of view (FOV), BFS-guided enemy pursuit, responsive bump-to-attack turn combat, multi-floor dungeon progression, and an integrated headless simulation benchmark engine.

The codebase is engineered with strict decoupling between game state mechanics, procedural generation algorithms, terminal I/O, and ANSI rendering. It relies **exclusively on the Nim 2.4.0 standard library** with zero external packages or C wrapper dependencies.

---

## 2. Core Features

- **Multi-Floor Dungeon Progression**:
  - 5 escalating dungeon floors.
  - Reaching the descent stairs (`>`) advances the dungeon level.
  - Player stats (HP, Level, XP, Gold, Attack, Defense, Potions) persist across floors.
  - Dynamic enemy stat scaling (+HP and +Attack per floor level).
  - Epic Victory condition upon clearing Floor 5.
- **Deterministic Procedural Generation**:
  - Deterministic PRNG world generation using a 64-bit Xoroshiro-inspired linear congruential generator.
  - Rectangular room placement with collision prevention and padding.
  - L-shaped orthogonal corridor carving with loop induction.
  - Breadth-First Search (BFS) flood-fill reachability validation guaranteeing 100% connected maps.
- **Raycasted Field of View & Fog of War**:
  - Amanatides & Woo 2D Digital Differential Analyzer (DDA) raycasting.
  - 3-tier visibility model:
    - **Never Explored**: Pitch black (` `).
    - **Explored / Fog of War**: Dim gray (`\e[90m`), remembered map layout.
    - **Currently Visible**: Bright full ANSI color with live entity updates.
  - Strict line-of-sight occlusion: solid walls block visibility behind them.
- **Enemy Archetypes & AI**:
  - **Goblin (`E`)**: Fast, agile, aggressive scout (25 HP, 8 ATK, 2 DEF).
  - **Skeleton (`E`)**: Balanced undead warrior (40 HP, 12 ATK, 4 DEF).
  - **Orc (`E`)**: Brutal armored juggernaut (60 HP, 18 ATK, 6 DEF).
  - Shortest-path BFS navigation towards player when within archetype aggro radius.
- **Combat & Character Progression**:
  - Intuitive bump-to-attack mechanic.
  - Armor mitigation formula: $\text{Damage} = \max(1, \text{ATK} - \text{DEF})$.
  - Experience points (XP) and leveling curve ($50 \times \text{Level}$).
  - Level-up stat bonuses (+20 Max HP, +3 ATK, +1 DEF).
- **Items & Inventory Management**:
  - Gold treasures (`$`) incrementing wealth and final score.
  - Health Potions (`!`) restoring 35 HP (capacity limit of 5).
  - Centralized score tracking based on enemies defeated, gold collected, and floor clear bonuses.
- **Cross-Platform ANSI Terminal UI**:
  - Windows Virtual Terminal processing enabled via Win32 Console API.
  - Standard 100 columns $\times$ 30 rows terminal layout.
  - 70 $\times$ 22 dungeon viewport, real-time side HUD with dynamic health bars, and bottom message combat log.

---

## 3. Architecture & Modular Design

The project is structured under `src/dungeon_zero/` following clean architecture principles:

```
dungeon_zero/
├── src/
│   ├── main.nim                   # CLI entrypoint & interactive game loop
│   └── dungeon_zero/
│       ├── types.nim              # Domain types, coordinates, constants & entity records
│       ├── rng.nim                # Seeded deterministic 64-bit PRNG
│       ├── mapgen.nim             # Procedural room/corridor generator with BFS validator
│       ├── fov.nim                # 2D DDA raycasting field-of-view & fog-of-war
│       ├── pathfinding.nim        # 4-directional BFS pathfinding & enemy movement AI
│       ├── combat.nim             # Turn combat formulas, damage mitigation & leveling
│       ├── inventory.nim          # Inventory management, potion healing & gold tally
│       ├── game.nim               # Game state machine, turn orchestration & progression
│       ├── terminal.nim           # Win32 VT console configuration & cursor management
│       ├── input.nim              # Non-blocking immediate keyboard reader & ANSI parser
│       ├── renderer.nim           # 100x30 ANSI frame buffer & HUD renderer
│       └── benchmark.nim          # Headless deterministic simulation & JSON exporter
├── tests/
│   ├── test_all.nim               # Master test runner executing all 11 test suites
│   ├── test_m1_skeleton.nim       # Core coordinate, entity & RNG tests
│   ├── test_mapgen.nim            # Procedural generation & 100-seed batch tests
│   ├── test_fov.nim               # 3-tier FOV & occlusion tests
│   ├── test_pathfinding.nim       # Shortest path & enemy avoidance tests
│   ├── test_combat.nim            # Combat mechanics, defense & XP progression tests
│   ├── test_inventory.nim         # Gold & potion consumption tests
│   ├── test_game.nim              # Turn loop, state transitions & deterministic replay tests
│   ├── test_input.nim             # Keyboard mapping & ANSI sequence tests
│   ├── test_renderer.nim          # Framebuffer dimensions & HUD rendering tests
│   ├── test_progression.nim       # Multi-floor progression, scaling & victory tests
│   └── test_benchmark.nim         # Deterministic headless simulation & JSON validation tests
└── benchmark/
    ├── README.md                  # Coding-agent benchmark harness overview
    ├── methodology.md             # Standardized evaluation protocol & rubric
    ├── tasks/                     # Agent programming challenges
    │   ├── task_01.md             # Feature: Vault & Special Room Generation
    │   ├── task_02.md             # Debugging: Diagonal Corner Occlusion
    │   └── task_03.md             # AI: Cowardly Goblin Flee Mechanic
    └── results/
        ├── results_template.json  # Machine-readable output schema
        └── results_template.csv   # Tabular summary schema
```

---

## 4. Controls & Visual Glyph Legend

### Controls
| Key | Action |
|---|---|
| **W** / **Up Arrow** | Move North |
| **S** / **Down Arrow** | Move South |
| **A** / **Left Arrow** | Move West |
| **D** / **Right Arrow** | Move East |
| **SPACE** | Wait a turn (Hold position) |
| **P** | Consume Health Potion (+35 HP) |
| **R** | Restart game with fresh seed |
| **Q** | Quit to terminal |

### Glyph Legend
| Glyph | Color | Entity | Description |
|:---:|:---:|---|---|
| `@` | Bright Yellow | **Player** | The heroic dungeon crawler |
| `#` | Gray / White | **Wall** | Impassable granite wall blocking line of sight |
| `.` | Dark Gray / Light Gray | **Floor** | Walkable stone dungeon floor |
| `E` | Green / Red / Bold Red | **Enemy** | Goblin (Green), Skeleton (Red), Orc (Bold Red) |
| `$` | Bright Yellow | **Treasure** | Gold coins boosting character score |
| `!` | Magenta | **Potion** | Restorative healing draught |
| `>` | Bright Cyan | **Stairs** | Portal descending to next dungeon floor |

---

## 5. Building & Running

### Requirements
- **Nim 2.4.0** or newer.
- **GCC / MinGW-w64** C compiler backend.
- Windows 10/11 or modern Linux terminal supporting ANSI escape sequences.

### Compilation
To compile the release binary:
```powershell
nim c -d:release src/main.nim
```

### Interactive Gameplay
Launch the game with default or custom seed:
```powershell
# Launch with default seed (1337)
.\src\main.exe

# Launch with custom deterministic seed
.\src\main.exe --seed:98765
```

### Headless AI Simulation Benchmark
Run the automated deterministic bot policy without terminal UI:
```powershell
# Human-readable summary
.\src\main.exe --benchmark --seed 1337 --turns 500

# Machine-readable JSON output
.\src\main.exe --benchmark --seed 1337 --turns 500 --json
```

---

## 6. Automated Testing

DUNGEON ZERO includes 11 dedicated automated unit test suites covering 100% of the game engine:

```powershell
# Execute unified master test runner
nim c -r tests/test_all.nim
```

Sample output:
```text
==========================================================================
 DUNGEON ZERO — EXECUTING ALL 11 AUTOMATED TEST SUITES
==========================================================================
>> Running test suite: tests/test_m1_skeleton.nim    -> [PASS]
>> Running test suite: tests/test_mapgen.nim         -> [PASS] (100-seed batch verified)
>> Running test suite: tests/test_fov.nim            -> [PASS]
>> Running test suite: tests/test_pathfinding.nim    -> [PASS]
>> Running test suite: tests/test_combat.nim         -> [PASS]
>> Running test suite: tests/test_inventory.nim      -> [PASS]
>> Running test suite: tests/test_game.nim           -> [PASS]
>> Running test suite: tests/test_input.nim          -> [PASS]
>> Running test suite: tests/test_renderer.nim       -> [PASS]
>> Running test suite: tests/test_progression.nim    -> [PASS]
>> Running test suite: tests/test_benchmark.nim      -> [PASS]
==========================================================================
 AGGREGATE TEST SUMMARY:
 Passed Suites: 11 / 11 (100% SUCCESS)
 Failed Suites: 0 / 11
==========================================================================
```

---

## 7. AI Coding Agent Benchmark Harness

DUNGEON ZERO serves as a production-grade benchmark harness for autonomous AI software engineers. Refer to `benchmark/README.md` and `benchmark/methodology.md` for full instructions.

### Standard Tasks
- **Task 01**: Procedural Generation Feature — Vault & Special Room Generation (`benchmark/tasks/task_01.md`).
- **Task 02**: Systems Debugging Challenge — Diagonal Corner Visibility Occlusion (`benchmark/tasks/task_02.md`).
- **Task 03**: Enemy AI Behavior — Cowardly Goblin Flee State Machine (`benchmark/tasks/task_03.md`).

---

## 8. License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
