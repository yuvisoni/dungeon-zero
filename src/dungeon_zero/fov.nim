## DUNGEON ZERO - Field of View (FOV) & Fog of War
## Module: dungeon_zero/fov

import types

type
  VisibilityState* = enum
    VisUnexplored
    VisExplored
    VisVisible

proc isVisible*(dungeon: DungeonMap, c: Coord): bool {.inline.} =
  ## Returns true if coordinate `c` is within bounds and currently visible.
  if c.x < 0 or c.x >= dungeon.width or c.y < 0 or c.y >= dungeon.height:
    return false
  dungeon.visible[c.y][c.x]

proc isExplored*(dungeon: DungeonMap, c: Coord): bool {.inline.} =
  ## Returns true if coordinate `c` is within bounds and has been explored.
  if c.x < 0 or c.x >= dungeon.width or c.y < 0 or c.y >= dungeon.height:
    return false
  dungeon.explored[c.y][c.x]

proc getVisibilityState*(dungeon: DungeonMap, c: Coord): VisibilityState {.inline.} =
  ## Returns the 3-state visibility: VisVisible, VisExplored, or VisUnexplored.
  if dungeon.isVisible(c):
    VisVisible
  elif dungeon.isExplored(c):
    VisExplored
  else:
    VisUnexplored

proc hasLineOfSight*(dungeon: DungeonMap, x0, y0, x1, y1: int): bool =
  ## Fast exact 2D grid traversal (Amanatides & Woo) checking line-of-sight.
  ## Returns true if the straight ray from (x0, y0) to (x1, y1) is unobstructed
  ## by walls before reaching (x1, y1). The target tile (x1, y1) itself is visible.
  if x0 == x1 and y0 == y1:
    return true

  let dx = x1 - x0
  let dy = y1 - y0

  let stepX = if dx > 0: 1 elif dx < 0: -1 else: 0
  let stepY = if dy > 0: 1 elif dy < 0: -1 else: 0

  let absDx = abs(dx)
  let absDy = abs(dy)

  var cx = x0
  var cy = y0

  var tMaxX = if stepX != 0: absDy else: int.high
  var tMaxY = if stepY != 0: absDx else: int.high
  let tDeltaX = 2 * absDy
  let tDeltaY = 2 * absDx

  while cx != x1 or cy != y1:
    # If an intermediate tile (between origin and target) is a wall, sight is occluded
    if (cx != x0 or cy != y0):
      if cx < 0 or cx >= dungeon.width or cy < 0 or cy >= dungeon.height:
        return false
      if dungeon.tiles[cy][cx] == TileWall:
        return false

    if tMaxX < tMaxY:
      tMaxX += tDeltaX
      cx += stepX
    elif tMaxY < tMaxX:
      tMaxY += tDeltaY
      cy += stepY
    else:
      # Simultaneous intersection at diagonal corner: check both adjacent tiles to prevent diagonal leaking
      if dungeon.tiles[cy][cx + stepX] == TileWall and dungeon.tiles[cy + stepY][cx] == TileWall:
        return false
      tMaxX += tDeltaX
      tMaxY += tDeltaY
      cx += stepX
      cy += stepY

  return true

proc computeFov*(dungeon: var DungeonMap, playerPos: Coord, radius: int = DefaultFovRadius) =
  ## Recalculates field-of-view for the player.
  ## Resets the current `visible` matrix, keeps `explored` memory intact,
  ## and casts visibility outwards across all 8 directions up to `radius`.
  for y in 0 ..< dungeon.height:
    for x in 0 ..< dungeon.width:
      dungeon.visible[y][x] = false

  # Player can always see their own tile if inside map boundaries
  if playerPos.x < 0 or playerPos.x >= dungeon.width or
     playerPos.y < 0 or playerPos.y >= dungeon.height:
    return

  dungeon.visible[playerPos.y][playerPos.x] = true
  dungeon.explored[playerPos.y][playerPos.x] = true

  let minX = max(0, playerPos.x - radius)
  let maxX = min(dungeon.width - 1, playerPos.x + radius)
  let minY = max(0, playerPos.y - radius)
  let maxY = min(dungeon.height - 1, playerPos.y + radius)
  let radiusSq = radius * radius

  for ty in minY .. maxY:
    for tx in minX .. maxX:
      let dx = tx - playerPos.x
      let dy = ty - playerPos.y
      if (dx * dx + dy * dy) <= radiusSq:
        if dungeon.hasLineOfSight(playerPos.x, playerPos.y, tx, ty):
          dungeon.visible[ty][tx] = true
          dungeon.explored[ty][tx] = true
