## DUNGEON ZERO - Milestone 3 Test Suite: BFS Pathfinding & Enemy Movement Logic
## Tests: Shortest path, Wall navigation, Unreachable, Start=Goal, Boundaries, No diagonals, Determinism, Aggro, Collisions

import std/[unittest, sequtils, sets]
import ../src/dungeon_zero/[types, pathfinding, mapgen]

proc createGridDungeon(width, height: int): DungeonMap =
  DungeonMap(
    width: width,
    height: height,
    tiles: newSeqWith(height, newSeqWith(width, TileFloor)),
    explored: newSeqWith(height, newSeqWith(width, false)),
    visible: newSeqWith(height, newSeqWith(width, false)),
    playerStart: Coord(x: 1, y: 1),
    stairsPos: Coord(x: width - 2, y: height - 2),
    rooms: @[]
  )

suite "Milestone 3: BFS Pathfinding & Enemy Movement":
  test "1. Direct shortest path":
    let dungeon = createGridDungeon(20, 20)
    let start = Coord(x: 2, y: 5)
    let goal = Coord(x: 7, y: 5)

    let path = dungeon.findPath(start, goal)
    # Expected distance: 5 steps along x-axis
    check(path.len == 5)
    check(path[^1] == goal)
    check(dungeon.getNextStep(start, goal) == Coord(x: 3, y: 5))

  test "2 & 7. Path navigates around walls without passing through them":
    var dungeon = createGridDungeon(20, 20)
    let start = Coord(x: 2, y: 5)
    let goal = Coord(x: 6, y: 5)

    # Place a vertical wall between start and goal at x=4 from y=3 to y=7
    for y in 3 .. 7:
      dungeon.tiles[y][4] = TileWall

    let path = dungeon.findPath(start, goal)
    check(path.len > 0)
    check(path[^1] == goal)

    # Invariant: No step in the path can be a wall tile
    for step in path:
      check(dungeon.tiles[step.y][step.x] != TileWall)

  test "3. Unreachable destination returns empty path":
    var dungeon = createGridDungeon(20, 20)
    let start = Coord(x: 2, y: 2)
    let goal = Coord(x: 10, y: 10)

    # Completely seal goal in an impassable box of walls
    for x in 9 .. 11:
      for y in 9 .. 11:
        if x != 10 or y != 10:
          dungeon.tiles[y][x] = TileWall

    let path = dungeon.findPath(start, goal)
    check(path.len == 0)
    check(not dungeon.isReachable(start, goal))
    check(dungeon.getNextStep(start, goal) == start)

  test "4. Start equals destination":
    let dungeon = createGridDungeon(20, 20)
    let pos = Coord(x: 5, y: 5)

    check(dungeon.findPath(pos, pos).len == 0)
    check(dungeon.getNextStep(pos, pos) == pos)
    check(dungeon.isReachable(pos, pos) == true)

  test "5. Map boundaries safety":
    let dungeon = createGridDungeon(20, 20)
    let start = Coord(x: 0, y: 0)
    let outOfBounds = Coord(x: -1, y: 0)
    let outOfBounds2 = Coord(x: 25, y: 25)

    check(dungeon.findPath(start, outOfBounds).len == 0)
    check(dungeon.findPath(outOfBounds, start).len == 0)
    check(dungeon.findPath(start, outOfBounds2).len == 0)
    check(not dungeon.isReachable(start, outOfBounds))

  test "6. Strictly 4-directional movement (No diagonals)":
    let dungeon = createGridDungeon(20, 20)
    let start = Coord(x: 2, y: 2)
    let goal = Coord(x: 6, y: 6)

    let path = dungeon.findPath(start, goal)
    check(path.len > 0)

    # Verify each step moves exactly 1 unit in either dx or dy, never both
    var prev = start
    for step in path:
      let dx = abs(step.x - prev.x)
      let dy = abs(step.y - prev.y)
      check((dx == 1 and dy == 0) or (dx == 0 and dy == 1))
      prev = step

  test "8. Deterministic path selection":
    let dungeon = createGridDungeon(30, 30)
    let start = Coord(x: 5, y: 5)
    let goal = Coord(x: 15, y: 15)

    let path1 = dungeon.findPath(start, goal)
    let path2 = dungeon.findPath(start, goal)

    check(path1.len == path2.len)
    for i in 0 ..< path1.len:
      check(path1[i] == path2[i])

  test "9. Enemy aggro radius behavior":
    let dungeon = createGridDungeon(30, 30)
    let playerPos = Coord(x: 10, y: 10)

    # Skeleton has aggroRadius = 6
    var skeletonClose = initEnemy(1, Coord(x: 13, y: 10), EkSkeleton) # dist = 3 <= 6 (in range)
    var skeletonFar = initEnemy(2, Coord(x: 20, y: 10), EkSkeleton)   # dist = 10 > 6 (out of range)

    var enemies = @[skeletonClose, skeletonFar]
    updateEnemyMovements(dungeon, playerPos, enemies, turnCount = 1)

    # skeletonClose should advance towards player (from (13,10) to (12,10))
    check(enemies[0].pos == Coord(x: 12, y: 10))

    # skeletonFar should NOT move because it is outside aggro radius
    check(enemies[1].pos == Coord(x: 20, y: 10))

  test "10. Enemy collision prevention and no moving onto player tile":
    let dungeon = createGridDungeon(30, 30)
    let playerPos = Coord(x: 10, y: 10)

    # Place enemy A adjacent to player (at (10, 11))
    var enemyA = initEnemy(1, Coord(x: 10, y: 11), EkSkeleton)
    # Place enemy B behind enemy A (at (10, 12))
    var enemyB = initEnemy(2, Coord(x: 10, y: 12), EkSkeleton)

    var enemies = @[enemyA, enemyB]
    updateEnemyMovements(dungeon, playerPos, enemies, turnCount = 1)

    # Enemy A is already adjacent to player and must NOT move onto (10,10)
    check(enemies[0].pos == Coord(x: 10, y: 11))

    # Enemy B is behind enemy A and cannot move onto (10,11) because enemy A is there
    # It cannot advance directly through enemy A
    check(enemies[1].pos != enemies[0].pos)

    # Archetype speed verification: Orc only moves on even turns
    var orc = initEnemy(3, Coord(x: 10, y: 7), EkOrc) # dist = 3 <= 5
    var orcList = @[orc]

    # Odd turn (turn 1): Orc should rest / not move
    updateEnemyMovements(dungeon, playerPos, orcList, turnCount = 1)
    check(orcList[0].pos == Coord(x: 10, y: 7))

    # Even turn (turn 2): Orc moves 1 step towards player
    updateEnemyMovements(dungeon, playerPos, orcList, turnCount = 2)
    check(orcList[0].pos == Coord(x: 10, y: 8))

    # Goblin (speed 2): moves up to 2 steps in 1 turn
    var goblin = initEnemy(4, Coord(x: 10, y: 5), EkGoblin) # dist = 5 <= 8
    var goblinList = @[goblin]
    updateEnemyMovements(dungeon, playerPos, goblinList, turnCount = 1)
    # Goblin takes 2 steps from (10,5) -> (10,6) -> (10,7)
    check(goblinList[0].pos == Coord(x: 10, y: 7))
