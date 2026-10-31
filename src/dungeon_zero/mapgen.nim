## DUNGEON ZERO - Procedural Map Generation & Validation
## Module: dungeon_zero/mapgen

import std/[deques, sets, strformat, sequtils]
import types, rng

proc hash*(c: Coord): int {.inline.} =
  ## Hash implementation for Coord to use in HashSet
  c.x * 10007 + c.y

proc carveRoom(tiles: var seq[seq[TileType]], room: Rect) =
  ## Carves a rectangular room into the tile grid
  for y in room.y1 .. room.y2:
    for x in room.x1 .. room.x2:
      tiles[y][x] = TileFloor

proc carveHCorridor(tiles: var seq[seq[TileType]], x1, x2, y: int) =
  ## Carves a horizontal corridor segment
  let minX = min(x1, x2)
  let maxX = max(x1, x2)
  for x in minX .. maxX:
    tiles[y][x] = TileFloor

proc carveVCorridor(tiles: var seq[seq[TileType]], y1, y2, x: int) =
  ## Carves a vertical corridor segment
  let minY = min(y1, y2)
  let maxY = max(y1, y2)
  for y in minY .. maxY:
    tiles[y][x] = TileFloor

proc validateConnectivity*(tiles: var seq[seq[TileType]], width, height: int, startPos: Coord): tuple[visitedCount: int, visited: seq[seq[bool]]] =
  ## BFS flood-fill from startPos across all walkable tiles.
  ## Prunes any disconnected pockets of walkable tiles by turning them into walls.
  var visited = newSeqWith(height, newSeq[bool](width))
  var queue = initDeque[Coord]()

  if tiles[startPos.y][startPos.x] != TileWall:
    visited[startPos.y][startPos.x] = true
    queue.addLast(startPos)

  const deltas = [Coord(x: 1, y: 0), Coord(x: -1, y: 0), Coord(x: 0, y: 1), Coord(x: 0, y: -1)]
  var count = 0

  while queue.len > 0:
    let curr = queue.popFirst()
    inc count

    for d in deltas:
      let nx = curr.x + d.x
      let ny = curr.y + d.y
      if nx >= 0 and nx < width and ny >= 0 and ny < height:
        if not visited[ny][nx] and tiles[ny][nx] != TileWall:
          visited[ny][nx] = true
          queue.addLast(Coord(x: nx, y: ny))

  # Prune any unreachable walkable tiles so there are zero disconnected pockets
  for y in 0 ..< height:
    for x in 0 ..< width:
      if tiles[y][x] != TileWall and not visited[y][x]:
        tiles[y][x] = TileWall

  result = (count, visited)

proc generateDungeonRaw(seed: int64, width, height, floorLevel: int): tuple[success: bool, dungeon: DungeonMap, enemies: seq[Enemy], items: seq[Item]] =
  var rng = initGameRng(seed)
  var tiles = newSeqWith(height, newSeq[TileType](width))
  for y in 0 ..< height:
    for x in 0 ..< width:
      tiles[y][x] = TileWall

  var rooms: seq[Rect] = @[]

  # Attempt placing rectangular non-overlapping rooms
  for _ in 0 ..< MaxRoomAttempts:
    let rw = rng.nextRange(MinRoomWidth, MaxRoomWidth)
    let rh = rng.nextRange(MinRoomHeight, MaxRoomHeight)
    let rx = rng.nextRange(1, width - rw - 1)
    let ry = rng.nextRange(1, height - rh - 1)
    let newRoom = initRect(rx, ry, rw, rh)

    var overlaps = false
    for existing in rooms:
      if intersects(newRoom, existing, padding = 1):
        overlaps = true
        break

    if not overlaps:
      carveRoom(tiles, newRoom)
      rooms.add(newRoom)

  if rooms.len < MinRoomsCount:
    return (false, DungeonMap(), @[], @[])

  # Connect rooms sequentially via L-shaped corridors
  for i in 1 ..< rooms.len:
    let c1 = rooms[i - 1].center
    let c2 = rooms[i].center

    if rng.nextBool(0.5):
      carveHCorridor(tiles, c1.x, c2.x, c1.y)
      carveVCorridor(tiles, c1.y, c2.y, c2.x)
    else:
      carveVCorridor(tiles, c1.y, c2.y, c1.x)
      carveHCorridor(tiles, c1.x, c2.x, c2.y)

  # Optional cycle: connect last room to first room to create natural loops
  if rooms.len >= 3 and rng.nextBool(0.7):
    let cFirst = rooms[0].center
    let cLast = rooms[^1].center
    if rng.nextBool(0.5):
      carveHCorridor(tiles, cLast.x, cFirst.x, cLast.y)
      carveVCorridor(tiles, cLast.y, cFirst.y, cFirst.x)
    else:
      carveVCorridor(tiles, cLast.y, cFirst.y, cLast.x)
      carveHCorridor(tiles, cLast.x, cFirst.x, cFirst.y)

  let playerStart = rooms[0].center
  if tiles[playerStart.y][playerStart.x] == TileWall:
    return (false, DungeonMap(), @[], @[])

  # Validate connectivity via BFS flood fill and prune any disconnected tiles
  let (visitedCount, visited) = validateConnectivity(tiles, width, height, playerStart)
  if visitedCount < 30: # Map too small or broken
    return (false, DungeonMap(), @[], @[])

  # Verify every room's center is reachable
  for r in rooms:
    let rc = r.center
    if not visited[rc.y][rc.x]:
      return (false, DungeonMap(), @[], @[])

  # Choose exit position: find the room furthest from player start
  var maxDist = -1
  var exitRoomIdx = rooms.high
  for i in 1 .. rooms.high:
    let dist = manhattanDist(playerStart, rooms[i].center)
    if dist > maxDist:
      maxDist = dist
      exitRoomIdx = i

  let exitPos = rooms[exitRoomIdx].center
  if not visited[exitPos.y][exitPos.x] or exitPos == playerStart or maxDist < 12:
    return (false, DungeonMap(), @[], @[])

  tiles[exitPos.y][exitPos.x] = TileStairsDown

  # Entity placement (Enemies and Items)
  var occupied = initHashSet[Coord]()
  occupied.incl(playerStart)
  occupied.incl(exitPos)

  var enemies: seq[Enemy] = @[]
  var items: seq[Item] = @[]
  var nextEntityId = 1

  for roomIdx in 1 ..< rooms.len:
    let room = rooms[roomIdx]

    # Spawn 1 to 3 enemies per room
    let numEnemies = rng.nextRange(1, if floorLevel >= 3: 3 else: 2)
    for _ in 0 ..< numEnemies:
      # Try 10 times to find an empty floor tile in the room
      for _ in 0 ..< 10:
        let ex = rng.nextRange(room.x1 + 1, room.x2 - 1)
        let ey = rng.nextRange(room.y1 + 1, room.y2 - 1)
        let pos = Coord(x: ex, y: ey)

        if tiles[ey][ex] == TileFloor and pos notin occupied:
          occupied.incl(pos)
          
          # Determine enemy kind based on floor level
          let roll = rng.nextRange(1, 100)
          var kind = EkGoblin
          if floorLevel == 1:
            if roll <= 60: kind = EkGoblin
            elif roll <= 90: kind = EkSkeleton
            else: kind = EkOrc
          elif floorLevel == 2:
            if roll <= 40: kind = EkGoblin
            elif roll <= 75: kind = EkSkeleton
            else: kind = EkOrc
          else:
            if roll <= 25: kind = EkGoblin
            elif roll <= 65: kind = EkSkeleton
            else: kind = EkOrc

          enemies.add(initEnemy(nextEntityId, pos, kind, floorLevel))
          inc nextEntityId
          break

    # Spawn 0 to 2 items per room
    let numItems = rng.nextRange(0, 2)
    for _ in 0 ..< numItems:
      for _ in 0 ..< 10:
        let ix = rng.nextRange(room.x1 + 1, room.x2 - 1)
        let iy = rng.nextRange(room.y1 + 1, room.y2 - 1)
        let pos = Coord(x: ix, y: iy)

        if tiles[iy][ix] == TileFloor and pos notin occupied:
          occupied.incl(pos)
          let isPotion = rng.nextBool(0.4)
          if isPotion:
            items.add(initItem(nextEntityId, pos, IkHealthPotion, value = 15))
          else:
            let goldVal = rng.nextRange(10, 40) + (floorLevel - 1) * 10
            items.add(initItem(nextEntityId, pos, IkGold, value = goldVal))
          inc nextEntityId
          break

  # Explored and visible matrices
  let explored = newSeqWith(height, newSeq[bool](width))
  let visible = newSeqWith(height, newSeq[bool](width))

  let dungeonMap = DungeonMap(
    width: width,
    height: height,
    tiles: tiles,
    explored: explored,
    visible: visible,
    playerStart: playerStart,
    stairsPos: exitPos,
    rooms: rooms
  )

  return (true, dungeonMap, enemies, items)

proc generateDungeon*(seed: int64, width: int = DefaultMapWidth, height: int = DefaultMapHeight, floorLevel: int = 1): GeneratedDungeon =
  ## Public deterministic dungeon generator with bounded retries.
  ## Guarantees a fully connected, valid dungeon with player start, exit, enemies and items.
  for attempt in 0 ..< MaxMapgenRetries:
    let attemptSeed = seed + attempt.int64 * 10007'i64
    let (success, dungeon, enemies, items) = generateDungeonRaw(attemptSeed, width, height, floorLevel)
    if success:
      return GeneratedDungeon(
        dungeon: dungeon,
        enemies: enemies,
        items: items
      )

  # Fallback: if all attempts failed (should never happen), raise a clear defect
  raise newException(ValueError, fmt"Failed to generate valid dungeon for seed {seed} after {MaxMapgenRetries} attempts")
