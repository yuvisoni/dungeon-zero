## DUNGEON ZERO - Milestone 4 Test Suite: Game State Machine & Turn Orchestration
## Tests: Player moves, Wall collision, Bump-to-attack, Item pickup, Enemy turns, Victory & Defeat, Restart, Determinism

import std/[unittest, sequtils]
import ../src/dungeon_zero/[types, rng, mapgen, fov, pathfinding, combat, inventory, game]

proc createMockGame(): GameState =
  ## Creates a clean 10x10 mock game state for precise deterministic testing
  var tiles = newSeqWith(10, newSeqWith(10, TileFloor))
  # Enclose in perimeter walls
  for x in 0 ..< 10:
    tiles[0][x] = TileWall
    tiles[9][x] = TileWall
  for y in 0 ..< 10:
    tiles[y][0] = TileWall
    tiles[y][9] = TileWall

  # Internal wall at (3, 3)
  tiles[3][3] = TileWall
  # Stairs at (8, 8)
  tiles[8][8] = TileStairsDown

  let player = initPlayer(Coord(x: 2, y: 2))
  var dungeon = DungeonMap(
    width: 10,
    height: 10,
    tiles: tiles,
    explored: newSeqWith(10, newSeqWith(10, false)),
    visible: newSeqWith(10, newSeqWith(10, false)),
    playerStart: Coord(x: 2, y: 2),
    stairsPos: Coord(x: 8, y: 8),
    rooms: @[]
  )
  computeFov(dungeon, player.pos, radius = 5)

  GameState(
    seed: 42,
    dungeon: dungeon,
    player: player,
    enemies: @[],
    items: @[],
    messageLog: @[],
    status: StatusPlaying,
    turnCount: 0
  )

suite "Milestone 4: Turn Loop & Game State Machine":
  test "1. Valid player movement updates coordinates and advances turn count":
    var g = createMockGame()
    check(g.player.pos == Coord(x: 2, y: 2))
    check(g.turnCount == 0)

    # Move East to (3, 2)
    let (valid, turn, msg) = g.stepGame(ActionMoveEast)
    check(valid)
    check(turn)
    check(g.player.pos == Coord(x: 3, y: 2))
    check(g.turnCount == 1)

  test "2 & 6. Invalid movement into walls does NOT trigger an enemy turn":
    var g = createMockGame()
    # At (2,2), moving North hits outer wall at y=0 or West hits wall at x=0
    # Let's move West to (1,2)
    discard g.stepGame(ActionMoveWest)
    check(g.player.pos == Coord(x: 1, y: 2))
    check(g.turnCount == 1)

    # Now attempt moving West into wall at (0,2)
    let (valid, turn, msg) = g.stepGame(ActionMoveWest)
    check(not valid)
    check(not turn) # Enemy turn did NOT execute
    check(g.player.pos == Coord(x: 1, y: 2)) # Player did not move
    check(g.turnCount == 1) # Turn count unchanged

  test "3. Bump-to-attack damages enemy without moving player onto its tile":
    var g = createMockGame()
    # Place goblin at (3, 2)
    var goblin = initEnemy(1, Coord(x: 3, y: 2), EkGoblin) # HP = 25
    g.enemies.add(goblin)

    # Player at (2, 2) moves East towards goblin -> Bump to attack
    let (valid, turn, msg) = g.stepGame(ActionMoveEast)
    check(valid)
    check(turn)
    # Player stays at (2, 2)
    check(g.player.pos == Coord(x: 2, y: 2))
    # Goblin takes damage: 15 atk - 2 def = 13 dmg -> 25 - 13 = 12 HP
    check(g.enemies[0].hp == 12)
    check(g.turnCount == 1)

  test "4. Item collection on entering floor tile":
    var g = createMockGame()
    # Place gold at (2, 3)
    g.items.add(initItem(1, Coord(x: 2, y: 3), IkGold, 50))
    check(g.player.gold == 0)

    # Move South to (2, 3)
    let (valid, turn, msg) = g.stepGame(ActionMoveSouth)
    check(valid)
    check(turn)
    check(g.player.pos == Coord(x: 2, y: 3))
    check(g.player.gold == 50)
    # Gold item removed from map
    check(g.items.len == 0)

  test "5 & 7. Enemy movement and adjacent attack resolution":
    var g = createMockGame()
    # Place Skeleton at (2, 4) - 2 tiles away from player at (2, 2)
    g.enemies.add(initEnemy(1, Coord(x: 2, y: 4), EkSkeleton))
    let startHp = g.player.hp

    # Turn 1: Player waits. Skeleton moves from (2,4) to (2,3) (adjacent) and attacks in step 6
    discard g.stepGame(ActionWait)
    check(g.enemies[0].pos == Coord(x: 2, y: 3))
    # Skeleton ATK = 12 vs Player DEF = 5 -> 7 damage dealt
    check(g.player.hp == startHp - 7)

    # Turn 2: Player waits again. Skeleton attacks again from adjacent tile
    discard g.stepGame(ActionWait)
    check(g.player.hp == startHp - 14)

  test "8. Game-over defeat detection when player HP reaches zero":
    var g = createMockGame()
    g.player.hp = 5 # Lethal damage imminent
    var orc = initEnemy(1, Coord(x: 2, y: 3), EkOrc) # Orc ATK = 18 vs Def 5 = 13 dmg
    g.enemies.add(orc)

    # Player waits; Orc attacks dealing 13 damage > 5 HP
    discard g.stepGame(ActionWait)
    check(g.player.hp == 0)
    check(not g.player.isAlive)
    check(g.status == StatusPlayerDied)

  test "9. Victory achieved upon reaching exit stairs":
    var g = createMockGame()
    g.player.floor = MaxDungeonFloors
    g.player.pos = Coord(x: 8, y: 7) # 1 step North of exit (8, 8)

    # Move South onto exit stairs
    discard g.stepGame(ActionMoveSouth)
    check(g.player.pos == Coord(x: 8, y: 8))
    check(g.status == StatusVictory)

  test "10. No actions permitted after game over":
    var g = createMockGame()
    g.status = StatusPlayerDied

    let (valid, turn, msg) = g.stepGame(ActionMoveEast)
    check(not valid)
    check(not turn)

  test "11. Clean restart mechanism using seed produces fresh playable state":
    let g1 = initGame(999'i64)
    check(g1.status == StatusPlaying)
    check(g1.player.isAlive)
    check(g1.turnCount == 0)
    check(g1.enemies.len > 0)
    check(g1.items.len > 0)

  test "12. Turn sequence is 100% deterministic for identical seeds and actions":
    var gA = initGame(777'i64)
    var gB = initGame(777'i64)

    const actions = [ActionWait, ActionWait, ActionUsePotion, ActionWait]
    for act in actions:
      discard gA.stepGame(act)
      discard gB.stepGame(act)

    check(gA.turnCount == gB.turnCount)
    check(gA.player.hp == gB.player.hp)
    check(gA.player.pos == gB.player.pos)
    check(gA.status == gB.status)
