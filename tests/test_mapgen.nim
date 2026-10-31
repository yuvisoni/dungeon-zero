## DUNGEON ZERO - Milestone 2 Test Suite: Procedural Dungeon Generation & Validation
## Tests: Dimensions, Bounds, Overlap, Connectivity, Entity Placement, Determinism, 100-Seed Batch

import std/[unittest, sets, deques, strformat, sequtils]
import ../src/dungeon_zero/[types, rng, mapgen]

proc bfsReachable(dungeon: DungeonMap, startPos, targetPos: Coord): bool =
  ## Verifies target is reachable from startPos through non-wall tiles
  if dungeon.tiles[startPos.y][startPos.x] == TileWall or dungeon.tiles[targetPos.y][targetPos.x] == TileWall:
    return false

  var visited = newSeqWith(dungeon.height, newSeq[bool](dungeon.width))
  var queue = initDeque[Coord]()

  visited[startPos.y][startPos.x] = true
  queue.addLast(startPos)

  const deltas = [Coord(x: 1, y: 0), Coord(x: -1, y: 0), Coord(x: 0, y: 1), Coord(x: 0, y: -1)]

  while queue.len > 0:
    let curr = queue.popFirst()
    if curr == targetPos:
      return true

    for d in deltas:
      let nx = curr.x + d.x
      let ny = curr.y + d.y
      if nx >= 0 and nx < dungeon.width and ny >= 0 and ny < dungeon.height:
        if not visited[ny][nx] and dungeon.tiles[ny][nx] != TileWall:
          visited[ny][nx] = true
          queue.addLast(Coord(x: nx, y: ny))

  return false

suite "Milestone 2: Procedural Dungeon Generator":
  test "1. Map dimensions and outer wall perimeter":
    let gen = generateDungeon(12345'i64, DefaultMapWidth, DefaultMapHeight)
    let d = gen.dungeon
    check(d.width == DefaultMapWidth)
    check(d.height == DefaultMapHeight)
    check(d.tiles.len == DefaultMapHeight)
    check(d.tiles[0].len == DefaultMapWidth)

    # Perimeter must be entirely walls
    for x in 0 ..< d.width:
      check(d.tiles[0][x] == TileWall)
      check(d.tiles[d.height - 1][x] == TileWall)
    for y in 0 ..< d.height:
      check(d.tiles[y][0] == TileWall)
      check(d.tiles[y][d.width - 1] == TileWall)

  test "2 & 3. Room bounds and non-overlap":
    let gen = generateDungeon(777'i64)
    let d = gen.dungeon
    check(d.rooms.len >= MinRoomsCount)

    for i in 0 ..< d.rooms.len:
      let r = d.rooms[i]
      # In-bounds with margin for walls
      check(r.x1 >= 1 and r.x2 < d.width - 1)
      check(r.y1 >= 1 and r.y2 < d.height - 1)
      check(r.width >= MinRoomWidth)
      check(r.height >= MinRoomHeight)

      # Non-overlapping with all other rooms (with padding)
      for j in (i + 1) ..< d.rooms.len:
        check(not intersects(r, d.rooms[j], padding = 1))

  test "4 & 5. Valid player spawn and exit placement":
    let gen = generateDungeon(999'i64)
    let d = gen.dungeon

    # Player start must be a floor tile
    check(d.tiles[d.playerStart.y][d.playerStart.x] == TileFloor)

    # Exit must be a stairs tile
    check(d.tiles[d.stairsPos.y][d.stairsPos.x] == TileStairsDown)

    # Exit must not be on top of player start
    check(d.playerStart != d.stairsPos)

    # Minimum separation distance
    check(manhattanDist(d.playerStart, d.stairsPos) >= 12)

  test "6 & 7. Connectivity: Exit and all rooms reachable from player spawn":
    let gen = generateDungeon(2024'i64)
    let d = gen.dungeon

    # Exit reachable
    check(bfsReachable(d, d.playerStart, d.stairsPos))

    # All room centers reachable
    for r in d.rooms:
      check(bfsReachable(d, d.playerStart, r.center))

  test "8 & 9. Enemies and items placed on valid walkable tiles without overlaps":
    let gen = generateDungeon(4242'i64)
    let d = gen.dungeon

    check(gen.enemies.len > 0)
    check(gen.items.len > 0)

    var occupied = initHashSet[Coord]()
    occupied.incl(d.playerStart)
    occupied.incl(d.stairsPos)

    for enemy in gen.enemies:
      # Must be on a floor tile
      check(d.tiles[enemy.pos.y][enemy.pos.x] == TileFloor)
      # Must not overlap with player, stairs, or another enemy/item
      check(enemy.pos notin occupied)
      occupied.incl(enemy.pos)

    for item in gen.items:
      # Must be on a floor tile
      check(d.tiles[item.pos.y][item.pos.x] == TileFloor)
      # Must not overlap with player, stairs, enemy, or another item
      check(item.pos notin occupied)
      occupied.incl(item.pos)

  test "10. Determinism: Same seed produces byte-for-byte identical dungeons":
    const testSeed = 54321'i64
    let gen1 = generateDungeon(testSeed)
    let gen2 = generateDungeon(testSeed)

    check(gen1.dungeon.width == gen2.dungeon.width)
    check(gen1.dungeon.height == gen2.dungeon.height)
    check(gen1.dungeon.playerStart == gen2.dungeon.playerStart)
    check(gen1.dungeon.stairsPos == gen2.dungeon.stairsPos)
    check(gen1.dungeon.rooms.len == gen2.dungeon.rooms.len)

    for i in 0 ..< gen1.dungeon.rooms.len:
      check(gen1.dungeon.rooms[i] == gen2.dungeon.rooms[i])

    for y in 0 ..< gen1.dungeon.height:
      for x in 0 ..< gen1.dungeon.width:
        check(gen1.dungeon.tiles[y][x] == gen2.dungeon.tiles[y][x])

    check(gen1.enemies.len == gen2.enemies.len)
    for i in 0 ..< gen1.enemies.len:
      check(gen1.enemies[i].pos == gen2.enemies[i].pos)
      check(gen1.enemies[i].kind == gen2.enemies[i].kind)
      check(gen1.enemies[i].hp == gen2.enemies[i].hp)

    check(gen1.items.len == gen2.items.len)
    for i in 0 ..< gen1.items.len:
      check(gen1.items[i].pos == gen2.items[i].pos)
      check(gen1.items[i].kind == gen2.items[i].kind)
      check(gen1.items[i].value == gen2.items[i].value)

  test "11. Diversity: Different seeds produce distinct dungeon layouts":
    let gA = generateDungeon(101'i64)
    let gB = generateDungeon(202'i64)
    let gC = generateDungeon(303'i64)

    # Different seeds should vary in player spawn or room layouts
    var differenceFound = false
    if gA.dungeon.playerStart != gB.dungeon.playerStart or
       gA.dungeon.stairsPos != gB.dungeon.stairsPos or
       gA.dungeon.rooms.len != gB.dungeon.rooms.len or
       gA.dungeon.rooms[0] != gB.dungeon.rooms[0]:
      differenceFound = true
    check(differenceFound)

  test "12. Comprehensive 100-Seed Batch: Generates valid connected maps without hanging or exceeding retries":
    var passedCount = 0
    for s in 1 .. 100:
      let gen = generateDungeon(s.int64)
      let d = gen.dungeon

      # Invariants verification
      let dimOk = d.width == DefaultMapWidth and d.height == DefaultMapHeight
      let roomsOk = d.rooms.len >= MinRoomsCount
      let playerOk = d.tiles[d.playerStart.y][d.playerStart.x] == TileFloor
      let stairsOk = d.tiles[d.stairsPos.y][d.stairsPos.x] == TileStairsDown
      let exitReachable = bfsReachable(d, d.playerStart, d.stairsPos)

      var allRoomsReachable = true
      for r in d.rooms:
        if not bfsReachable(d, d.playerStart, r.center):
          allRoomsReachable = false
          break

      var entitiesOk = true
      var occ = initHashSet[Coord]()
      occ.incl(d.playerStart)
      occ.incl(d.stairsPos)

      for enemy in gen.enemies:
        if d.tiles[enemy.pos.y][enemy.pos.x] != TileFloor or enemy.pos in occ:
          entitiesOk = false
          break
        occ.incl(enemy.pos)

      for item in gen.items:
        if d.tiles[item.pos.y][item.pos.x] != TileFloor or item.pos in occ:
          entitiesOk = false
          break
        occ.incl(item.pos)

      if dimOk and roomsOk and playerOk and stairsOk and exitReachable and allRoomsReachable and entitiesOk:
        inc passedCount

    check(passedCount == 100)
