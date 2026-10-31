## DUNGEON ZERO - Progression & Multi-Floor Unit Tests
## Module: tests/test_progression

import std/[unittest, strutils]
import ../src/dungeon_zero/[types, game]

suite "Multi-Floor Progression Suite":

  test "Floor advancement preserves player character stats":
    var state = initGame(1337)
    check state.player.floor == 1

    # Modify player stats mid-floor
    state.player.hp = 85
    state.player.maxHp = 110
    state.player.attack = 18
    state.player.defense = 7
    state.player.level = 2
    state.player.xp = 35
    state.player.gold = 150
    state.player.potions = 4

    let advanced = state.advanceFloor()
    check advanced == true
    check state.player.floor == 2
    check state.stats.floorsCompleted == 1

    # Stats must be preserved
    check state.player.hp == 85
    check state.player.maxHp == 110
    check state.player.attack == 18
    check state.player.defense == 7
    check state.player.level == 2
    check state.player.xp == 35
    check state.player.gold == 150
    check state.player.potions == 4

  test "Floor advancement resets floor map, enemies, and items":
    var state = initGame(1337)

    discard state.advanceFloor()
    check state.player.floor == 2

    # Map, enemies, items must be refreshed
    check state.enemies.len > 0
    # Player position should be at new floor spawn
    check state.player.pos == state.dungeon.playerStart
    # FOV must be recalculated for new floor
    check state.dungeon.visible[state.player.pos.y][state.player.pos.x] == true

  test "Floor progression scales enemy stats and difficulty":
    let stateF1 = initGame(42)
    var stateF3 = initGame(42)
    discard stateF3.advanceFloor() # to floor 2
    discard stateF3.advanceFloor() # to floor 3
    check stateF3.player.floor == 3

    # On floor 3, enemy bonus attack is +2, bonus HP is +8
    # Check goblin on floor 3 vs floor 1
    var f1GoblinHp = 0
    var f3GoblinHp = 0
    for e in stateF1.enemies:
      if e.kind == EkGoblin:
        f1GoblinHp = e.maxHp
        break
    for e in stateF3.enemies:
      if e.kind == EkGoblin:
        f3GoblinHp = e.maxHp
        break

    check f1GoblinHp == GoblinHp
    check f3GoblinHp == GoblinHp + 2 * 5 # 25 + 10 = 35

  test "Deterministic floor generation given identical seeds":
    var stateA = initGame(999)
    discard stateA.advanceFloor()

    var stateB = initGame(999)
    discard stateB.advanceFloor()

    check stateA.player.floor == 2
    check stateB.player.floor == 2
    check stateA.dungeon.playerStart == stateB.dungeon.playerStart
    check stateA.dungeon.stairsPos == stateB.dungeon.stairsPos
    check stateA.enemies.len == stateB.enemies.len
    for i in 0 ..< stateA.enemies.len:
      check stateA.enemies[i].kind == stateB.enemies[i].kind
      check stateA.enemies[i].pos == stateB.enemies[i].pos

  test "Step game advances floor when stepping onto exit stairs":
    var state = initGame(777)
    check state.player.floor == 1

    # Place player adjacent to stairs
    let stairs = state.dungeon.stairsPos
    state.player.pos = Coord(x: stairs.x - 1, y: stairs.y)

    # Step east onto stairs
    let (valid, turn, msg) = state.stepGame(ActionMoveEast)
    check valid == true
    check turn == true
    check state.player.floor == 2
    check "descended" in msg.toLowerAscii or "floor 2" in msg.toLowerAscii

  test "Victory is triggered upon descending the final floor":
    var state = initGame(555)
    # Advance to floor 5
    for _ in 1 .. 4:
      discard state.advanceFloor()
    check state.player.floor == 5

    # Move player to stairs
    let stairs = state.dungeon.stairsPos
    state.player.pos = Coord(x: stairs.x, y: stairs.y - 1)

    # Step south onto stairs
    let (valid, turn, msg) = state.stepGame(ActionMoveSouth)
    check valid == true
    check turn == true
    check state.status == StatusVictory
    check state.stats.floorsCompleted == 5
    check "victory" in msg.toLowerAscii or "conquered" in msg.toLowerAscii

  test "Dead player cannot advance floor":
    var state = initGame(123)
    state.player.hp = 0
    state.player.isAlive = false
    state.status = StatusPlayerDied

    let advanced = state.advanceFloor()
    check advanced == false
    check state.player.floor == 1
