# Task 02: Debugging Challenge — Diagonal Corner Visibility Occlusion

## Category
Systems Debugging & Algorithmic Edge Case Handling

## Difficulty
Medium (Estimated completion time: 8–10 minutes)

## Background
In grid-based roguelikes, raycasting field-of-view algorithms can exhibit "corner peeking" bugs where a ray slips diagonally between two orthogonally adjacent wall tiles, e.g.:
```
.#.
#@#
.#.
```
If two walls meet diagonally at a corner (e.g., $(x+1, y)$ and $(x, y+1)$), a diagonal sightline passing through $(x+1, y+1)$ should not pierce through an infinitesimally thin crease unless strict orthogonal line-of-sight is maintained.

## Bug Scenario
In `src/dungeon_zero/fov.nim`, certain diagonal DDA ray intersections permit visibility through a diagonal wall pinch point when both adjacent cardinal neighbor tiles are solid blocking walls.

## Objective
Detect, reproduce with an automated test, and fix diagonal corner leakage in `src/dungeon_zero/fov.nim`.

## Requirements
1. **Automated Reproduction**:
   - Create a failing unit test in `tests/test_corner_occlusion.nim` depicting a diagonal corner pinch:
     - Player at $(5, 5)$.
     - Walls at $(6, 5)$ and $(5, 6)$.
     - Target floor at $(6, 6)$.
     - Assert that $(6, 6)$ is NOT visible from $(5, 5)$ due to the pinch corner occlusion.
2. **Implementation Fix**:
   - Update `calculateFov` in `src/dungeon_zero/fov.nim` to verify that diagonal steps check both adjacent cardinal tiles, preventing ray slippage across solid corners.
3. **Regression Guarantee**:
   - All 8 tests in `tests/test_fov.nim` must continue passing.
   - Symmetrical visibility and player self-tile visibility must remain intact.
