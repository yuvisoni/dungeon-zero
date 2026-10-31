## DUNGEON ZERO - Milestone 5 Test Suite: ANSI Renderer & UI
## Tests: Screen dimensions, Unexplored hiding, Explored fog, Enemy visibility filtering, HUD formatting, Banner overlays

import std/[unittest, strutils, sequtils, unicode]
import ../src/dungeon_zero/[types, game, fov, renderer]

proc createTestGameState(): GameState =
  var g = initGame(1337'i64)
  g.player.gold = 75
  g.player.score = 500
  g.messageLog.add(LogMessage(text: "Test log message 1", color: "green"))
  g.messageLog.add(LogMessage(text: "Test log message 2", color: "red"))
  g

suite "Milestone 5: ANSI Renderer & Terminal UI":
  test "1. Frame dimensions respect 100x30 standard layout":
    let g = createTestGameState()
    let text = renderToString(g, includeAnsi = false)
    let lines = text.split("\n")

    # Height must be exactly 30 rows
    check(lines.len == 30)

    # All lines must be 100 characters wide (or 99-100 formatted)
    for i, line in lines:
      check(runeLen(line) >= 98 and runeLen(line) <= 101)

  test "2 & 3. Unexplored tiles are hidden, explored tiles are visible without entities":
    let g = createTestGameState()
    let text = renderToString(g, includeAnsi = false)
    let lines = text.split("\n")

    # In unexplored corners far from player start, viewport chars should be spaces
    let cornerY = 1 # Top-left viewport row (line index 1)
    let cornerChar = lines[cornerY][1] # (x=1)
    # The corner should be a space ' ' if unexplored
    check(cornerChar == ' ')

    # Around player start, player '@' must be visible
    var playerFound = false
    for y in 1 .. 22:
      let viewportRow = lines[y][0 .. 69]
      if '@' in viewportRow:
        playerFound = true
        break
    check(playerFound)

  test "4 & 5. Visible enemies are rendered; hidden enemies outside FOV are suppressed":
    var g = createTestGameState()
    
    # Place Enemy A right next to player (at player.pos + (1, 0)) -> inside FOV
    let visiblePos = g.player.pos + Coord(x: 1, y: 0)
    g.enemies.add(initEnemy(99, visiblePos, EkGoblin))

    # Place Enemy B in far corner (1, 1) -> outside FOV
    let hiddenPos = Coord(x: 1, y: 1)
    g.enemies.add(initEnemy(100, hiddenPos, EkOrc))

    computeFov(g.dungeon, g.player.pos, radius = 8)
    check(g.dungeon.isVisible(visiblePos))
    check(not g.dungeon.isVisible(hiddenPos))

    let text = renderToString(g, includeAnsi = false)
    let lines = text.split("\n")

    # Enemy at visiblePos must be rendered as 'E'
    let visibleLine = lines[visiblePos.y + 1] # +1 offset for header line
    check(visibleLine[visiblePos.x] == 'E')

    # Enemy at hiddenPos must NOT be rendered (must remain ' ' space)
    let hiddenLine = lines[hiddenPos.y + 1]
    check(hiddenLine[hiddenPos.x] != 'E')

  test "6. HUD panel accurately reflects game state values":
    let g = createTestGameState()
    let text = renderToString(g, includeAnsi = false)

    check("HP:" in text)
    check("100/100" in text)
    check("Gold:    $ 75" in text)
    check("Score:   500" in text)
    check("Floor:   1" in text)
    check("WASD / Arrows : Move" in text)

  test "7. Event log renders recent messages":
    let g = createTestGameState()
    let text = renderToString(g, includeAnsi = false)

    check("Test log message 1" in text)
    check("Test log message 2" in text)

  test "8. Game Over screen overlays banner":
    var g = createTestGameState()
    g.status = StatusPlayerDied

    let text = renderToString(g, includeAnsi = false)
    check("GAME OVER" in text)
    check("You have been defeated!" in text)
    check("Press [R] to Restart" in text)

  test "9. Victory screen overlays banner":
    var g = createTestGameState()
    g.status = StatusVictory

    let text = renderToString(g, includeAnsi = false)
    check("VICTORY!" in text)
    check("You escaped DUNGEON ZERO!" in text)
    check("Press [R] to Play Again" in text)
