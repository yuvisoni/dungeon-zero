## DUNGEON ZERO - BFS Pathfinding & Enemy Movement Logic
## Module: dungeon_zero/pathfinding

import std/[deques, sets, algorithm, sequtils]
import types

const CardinalNeighbors* = [
  Coord(x: 0, y: -1), # North (Up)
  Coord(x: 1, y: 0),  # East (Right)
  Coord(x: 0, y: 1),  # South (Down)
  Coord(x: -1, y: 0)  # West (Left)
]

proc isWalkable*(dungeon: DungeonMap, c: Coord): bool {.inline.} =
  ## Returns true if coordinate c is within bounds and not a wall.
  c.x >= 0 and c.x < dungeon.width and
  c.y >= 0 and c.y < dungeon.height and
  dungeon.tiles[c.y][c.x] != TileWall

proc isReachable*(dungeon: DungeonMap, startPos, goalPos: Coord): bool =
  ## Fast BFS check to determine if goalPos is reachable from startPos.
  if startPos == goalPos:
    return true
  if not dungeon.isWalkable(startPos) or not dungeon.isWalkable(goalPos):
    return false

  var visited = newSeqWith(dungeon.height, newSeq[bool](dungeon.width))
  var queue = initDeque[Coord]()

  visited[startPos.y][startPos.x] = true
  queue.addLast(startPos)

  while queue.len > 0:
    let curr = queue.popFirst()
    if curr == goalPos:
      return true

    for d in CardinalNeighbors:
      let nextPos = curr + d
      if dungeon.isWalkable(nextPos) and not visited[nextPos.y][nextPos.x]:
        visited[nextPos.y][nextPos.x] = true
        queue.addLast(nextPos)

  return false

proc findPath*(dungeon: DungeonMap, startPos, goalPos: Coord,
               impassableEntities: openArray[Coord] = []): seq[Coord] =
  ## Finds the shortest 4-directional path between startPos and goalPos using BFS.
  ## Returns an empty seq if startPos == goalPos or if no path exists.
  ## Excludes startPos from the returned path; includes goalPos as the final element.
  if startPos == goalPos:
    return @[]
  if not dungeon.isWalkable(startPos) or not dungeon.isWalkable(goalPos):
    return @[]

  # Build set of obstacle coordinates (excluding start and goal)
  var blocked = initHashSet[Coord]()
  for e in impassableEntities:
    if e != startPos and e != goalPos:
      blocked.incl(e)

  var cameFrom = newSeqWith(dungeon.height, newSeq[Coord](dungeon.width))
  var visited = newSeqWith(dungeon.height, newSeq[bool](dungeon.width))
  var queue = initDeque[Coord]()

  visited[startPos.y][startPos.x] = true
  queue.addLast(startPos)

  var found = false

  while queue.len > 0:
    let curr = queue.popFirst()
    if curr == goalPos:
      found = true
      break

    for d in CardinalNeighbors:
      let nextPos = curr + d
      if dungeon.isWalkable(nextPos) and not visited[nextPos.y][nextPos.x]:
        if nextPos notin blocked or nextPos == goalPos:
          visited[nextPos.y][nextPos.x] = true
          cameFrom[nextPos.y][nextPos.x] = curr
          queue.addLast(nextPos)

  if not found:
    return @[]

  # Reconstruct path backwards from goalPos to startPos
  var path: seq[Coord] = @[]
  var curr = goalPos
  while curr != startPos:
    path.add(curr)
    curr = cameFrom[curr.y][curr.x]

  reverse(path)
  return path

proc getNextStep*(dungeon: DungeonMap, startPos, goalPos: Coord,
                  impassableEntities: openArray[Coord] = []): Coord =
  ## Returns the immediate next coordinate to move towards goalPos.
  ## Returns startPos if already at goal or if no valid path exists.
  let path = dungeon.findPath(startPos, goalPos, impassableEntities)
  if path.len > 0:
    return path[0]
  return startPos

# --- Part C: Enemy Movement Logic ---

proc updateEnemyMovements*(dungeon: DungeonMap, playerPos: Coord,
                           enemies: var seq[Enemy], turnCount: int) =
  ## Updates positions of all active enemies based on their archetype movement rules:
  ## - Goblin: Fast (speed 2). Moves up to 2 tiles per turn towards player if in aggro.
  ## - Skeleton: Balanced (speed 1). Moves 1 tile per turn towards player if in aggro.
  ## - Orc: Slow (speed 1). Moves 1 tile every 2 turns (even turns) towards player if in aggro.
  ## Invariants enforced:
  ## - Cannot walk through walls.
  ## - Cannot step on other enemies (collision avoidance).
  ## - Cannot step directly onto the player's tile (stops adjacent to player).
  
  # Collect positions of all alive enemies to prevent collisions
  var occupied = initHashSet[Coord]()
  for e in enemies:
    if e.isAlive:
      occupied.incl(e.pos)

  for i in 0 ..< enemies.len:
    if not enemies[i].isAlive:
      continue

    # Determine movement steps for this enemy archetype on this turn
    var maxSteps = 0
    case enemies[i].kind
    of EkGoblin:
      maxSteps = 2 # High movement frequency: up to 2 steps
    of EkSkeleton:
      maxSteps = 1 # Balanced pursuit: 1 step every turn
    of EkOrc:
      if turnCount mod 2 == 0:
        maxSteps = 1 # Slow pursuit: 1 step every other turn
      else:
        maxSteps = 0

    if maxSteps == 0:
      continue

    # Check aggro radius
    let distToPlayer = chebyshevDist(enemies[i].pos, playerPos)
    if distToPlayer > enemies[i].aggroRadius:
      continue # Player outside aggro range: do not pursue

    # Execute movement steps
    for _ in 0 ..< maxSteps:
      # If already adjacent to player, do not move onto player's tile
      if manhattanDist(enemies[i].pos, playerPos) <= 1:
        break

      # Convert current occupied set (excluding self) to obstacle sequence
      var obstacles: seq[Coord] = @[]
      for pos in occupied:
        if pos != enemies[i].pos:
          obstacles.add(pos)
      # Player is also an impassable obstacle for movement
      obstacles.add(playerPos)

      let nextStep = dungeon.getNextStep(enemies[i].pos, playerPos, obstacles)
      if nextStep != enemies[i].pos and nextStep != playerPos and nextStep notin occupied:
        occupied.excl(enemies[i].pos)
        enemies[i].pos = nextStep
        occupied.incl(enemies[i].pos)
      else:
        # Blocked: cannot advance further this turn
        break
