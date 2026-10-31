## DUNGEON ZERO - Milestone 3 Test Suite: Field of View (FOV) & Fog of War
## Tests: Self-visibility, Radius bounds, Wall occlusion, Move updates, Exploration memory, Bounds, Determinism

import std/[unittest, sequtils]
import ../src/dungeon_zero/[types, fov, mapgen]

proc createMockDungeon(width, height: int, defaultTile: TileType = TileFloor): DungeonMap =
  DungeonMap(
    width: width,
    height: height,
    tiles: newSeqWith(height, newSeqWith(width, defaultTile)),
    explored: newSeqWith(height, newSeqWith(width, false)),
    visible: newSeqWith(height, newSeqWith(width, false)),
    playerStart: Coord(x: width div 2, y: height div 2),
    stairsPos: Coord(x: 1, y: 1),
    rooms: @[]
  )

suite "Milestone 3: Field of View & Fog of War":
  test "1. Player can always see their own tile":
    var dungeon = createMockDungeon(30, 20)
    let p = Coord(x: 10, y: 10)
    computeFov(dungeon, p, radius = 8)

    check(dungeon.isVisible(p))
    check(dungeon.isExplored(p))
    check(dungeon.getVisibilityState(p) == VisVisible)

  test "2. Visibility radius is strictly respected":
    var dungeon = createMockDungeon(40, 40)
    let p = Coord(x: 20, y: 20)
    const rad = 6
    computeFov(dungeon, p, radius = rad)

    # Within radius: should be visible
    check(dungeon.isVisible(Coord(x: 20, y: 20 + rad)))
    check(dungeon.isVisible(Coord(x: 20 + rad, y: 20)))

    # Outside radius: must NOT be visible
    check(not dungeon.isVisible(Coord(x: 20, y: 20 + rad + 1)))
    check(not dungeon.isVisible(Coord(x: 20 + rad + 2, y: 20)))
    check(not dungeon.isVisible(Coord(x: 20 + rad, y: 20 + rad))) # diagonal distance > rad

  test "3 & 4. Walls block visibility behind them (occlusion)":
    var dungeon = createMockDungeon(30, 20)
    let p = Coord(x: 5, y: 10)
    
    # Place a vertical wall segment between x=8 and player
    for y in 7 .. 13:
      dungeon.tiles[y][8] = TileWall

    computeFov(dungeon, p, radius = 8)

    # The front of the wall itself is visible
    check(dungeon.isVisible(Coord(x: 8, y: 10)))

    # The tiles immediately behind the wall are occluded / NOT visible
    check(not dungeon.isVisible(Coord(x: 9, y: 10)))
    check(not dungeon.isVisible(Coord(x: 10, y: 10)))
    check(not dungeon.isVisible(Coord(x: 11, y: 10)))

  test "5 & 6. Previously explored areas remain remembered when player moves":
    var dungeon = createMockDungeon(40, 20)
    let posA = Coord(x: 5, y: 10)
    let posB = Coord(x: 30, y: 10)

    # Step 1: Compute FOV at posA
    computeFov(dungeon, posA, radius = 6)
    check(dungeon.isVisible(posA))
    check(dungeon.isExplored(posA))
    check(dungeon.getVisibilityState(posA) == VisVisible)

    # Step 2: Move player to posB far away
    computeFov(dungeon, posB, radius = 6)

    # posA is now out of sight (not currently visible), but REMEMBERED (explored)
    check(not dungeon.isVisible(posA))
    check(dungeon.isExplored(posA))
    check(dungeon.getVisibilityState(posA) == VisExplored)

    # posB is currently visible
    check(dungeon.isVisible(posB))
    check(dungeon.getVisibilityState(posB) == VisVisible)

    # An area never visited remains unexplored
    let posNeverVisited = Coord(x: 38, y: 1)
    check(dungeon.getVisibilityState(posNeverVisited) == VisUnexplored)

  test "7. Map boundary safety and corner clamping":
    var dungeon = createMockDungeon(20, 20)
    
    # Near top-left corner
    let corner = Coord(x: 0, y: 0)
    computeFov(dungeon, corner, radius = 8)
    check(dungeon.isVisible(corner))
    check(not dungeon.isVisible(Coord(x: -1, y: 0))) # out of bounds helper safe
    check(not dungeon.isVisible(Coord(x: 0, y: -1)))

    # Near bottom-right corner
    let cornerBR = Coord(x: 19, y: 19)
    computeFov(dungeon, cornerBR, radius = 8)
    check(dungeon.isVisible(cornerBR))
    check(not dungeon.isVisible(Coord(x: 20, y: 19)))

  test "8. Determinism: Identical maps and positions produce identical FOV grids":
    let gen = generateDungeon(3333'i64)
    var d1 = gen.dungeon
    var d2 = gen.dungeon
    let p = d1.playerStart

    computeFov(d1, p, radius = 8)
    computeFov(d2, p, radius = 8)

    for y in 0 ..< d1.height:
      for x in 0 ..< d1.width:
        check(d1.visible[y][x] == d2.visible[y][x])
        check(d1.explored[y][x] == d2.explored[y][x])
