# Task 01: Procedural Feature — Treasure Vault & Special Room Generation

## Category
Procedural World Generation & Algorithmic Design

## Difficulty
Medium (Estimated completion time: 10–12 minutes)

## Background
Currently, `src/dungeon_zero/mapgen.nim` creates rectangular rooms of standard dimensions ($6 \times 4$ to $12 \times 8$) and connects them via corridors. All rooms share the same default spawning rules.

## Objective
Extend `mapgen.nim` and `types.nim` to introduce a deterministic **Treasure Vault Room** on Floors 2 through 5.

## Requirements
1. **Room Classification**:
   - Extend `Room` object in `src/dungeon_zero/types.nim` with `isVault: bool` (default `false`).
2. **Deterministic Placement**:
   - Exactly one room per generated dungeon on Floors $\ge 2$ must be designated as a `Vault` room.
   - The Vault room cannot be the starting room containing the player spawn (`@`).
   - The Vault room cannot be the room containing the stairs down (`>`).
3. **Special Spawning Rules**:
   - A Vault room must contain at least 2 Gold items and 1 Health Potion.
   - A Vault room must be guarded by at least 1 Orc enemy inside the room bounds.
4. **Architectural Guardrails**:
   - Maintain full connectivity: the Vault must remain reachable via corridors.
   - Seed determinism: Given the same seed and floor, the exact same room must be selected as the Vault.
5. **Testing**:
   - Implement tests in `tests/test_vault.nim` verifying:
     - No vaults on Floor 1.
     - Exactly 1 vault on Floors 2–5.
     - Vault contains no player spawn and no exit stairs.
     - Vault contains expected items and enemy guard.
     - 100-seed batch run has 100% reachable vaults.
