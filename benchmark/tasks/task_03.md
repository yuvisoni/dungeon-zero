# Task 03: Enemy AI — Cowardly Goblin Flee Mechanic

## Category
Enemy AI & Pathfinding State Machine

## Difficulty
Hard (Estimated completion time: 12–15 minutes)

## Background
Currently, all enemies (Goblins, Skeletons, Orcs) in `src/dungeon_zero/pathfinding.nim` pursue the player aggressively whenever the player enters their tracking radius.

## Objective
Implement a cowardly flee behavior for Goblins when their health drops to 5 HP or lower.

## Requirements
1. **AI State Extension**:
   - In `src/dungeon_zero/types.nim`, add or use enemy AI states (e.g., `AiPursuing`, `AiFleeing`).
2. **Behavioral Logic**:
   - Goblins have 20 base HP.
   - When a Goblin's `hp <= 5`, its behavior changes from **Pursuit** to **Flee**:
     - It seeks a walkable adjacent tile that *maximizes* Manhattan distance from the player.
     - If all adjacent moves decrease distance or are blocked by walls/enemies, it attempts to hold ground or move laterally.
   - Skeletons and Orcs never flee regardless of HP.
3. **Turn Integration**:
   - The flee step must execute during the normal enemy turn phase in `src/dungeon_zero/game.nim`.
   - Fleeing Goblins do not attack the player unless cornered with no legal flee moves.
4. **Automated Testing**:
   - Create `tests/test_goblin_flee.nim`:
     - Test that a healthy Goblin ($HP > 5$) reduces distance to player.
     - Test that an injured Goblin ($HP \le 5$) increases distance from player.
     - Test that Skeletons and Orcs continue attacking even at low HP.
     - Test that fleeing does not step onto wall tiles or out of bounds.
