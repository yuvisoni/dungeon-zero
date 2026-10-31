## DUNGEON ZERO - Milestone 5 Test Suite: Keyboard Input & ANSI Parsing
## Tests: WASD mappings, Arrow extended keys, ANSI sequences, Unknown key handling, Action translation

import std/[unittest]
import ../src/dungeon_zero/[types, input]

suite "Milestone 5: Keyboard Input & Command Parsing":
  test "1. WASD keys map to directional move commands (case-insensitive)":
    check(parseKey('w') == CmdMoveNorth)
    check(parseKey('W') == CmdMoveNorth)
    check(parseKey('s') == CmdMoveSouth)
    check(parseKey('S') == CmdMoveSouth)
    check(parseKey('a') == CmdMoveWest)
    check(parseKey('A') == CmdMoveWest)
    check(parseKey('d') == CmdMoveEast)
    check(parseKey('D') == CmdMoveEast)

  test "2. Arrow keys (extended scancodes) map to move commands":
    check(parseKey('\0', isExtended = true, extCode = 72) == CmdMoveNorth) # Up
    check(parseKey('\0', isExtended = true, extCode = 80) == CmdMoveSouth) # Down
    check(parseKey('\0', isExtended = true, extCode = 75) == CmdMoveWest)  # Left
    check(parseKey('\0', isExtended = true, extCode = 77) == CmdMoveEast)  # Right

  test "3. ANSI escape sequences map to arrow keys":
    check(parseAnsiSequence("\e[A") == CmdMoveNorth)
    check(parseAnsiSequence("\e[B") == CmdMoveSouth)
    check(parseAnsiSequence("\e[C") == CmdMoveEast)
    check(parseAnsiSequence("\e[D") == CmdMoveWest)
    check(parseAnsiSequence("invalid") == CmdNone)

  test "4. Special action keys (Wait, Potion, Quit, Restart)":
    check(parseKey(' ') == CmdWait)
    check(parseKey('p') == CmdUsePotion)
    check(parseKey('P') == CmdUsePotion)
    check(parseKey('q') == CmdQuit)
    check(parseKey('Q') == CmdQuit)
    check(parseKey('r') == CmdRestart)
    check(parseKey('R') == CmdRestart)

  test "5. Unknown characters and extended keys are safely ignored":
    check(parseKey('z') == CmdNone)
    check(parseKey('1') == CmdNone)
    check(parseKey('\n') == CmdNone)
    check(parseKey('\0', isExtended = true, extCode = 999) == CmdNone)

  test "6. Translation to engine PlayerAction":
    let (isNorth, actNorth) = commandToAction(CmdMoveNorth)
    check(isNorth and actNorth == ActionMoveNorth)

    let (isSouth, actSouth) = commandToAction(CmdMoveSouth)
    check(isSouth and actSouth == ActionMoveSouth)

    let (isWest, actWest) = commandToAction(CmdMoveWest)
    check(isWest and actWest == ActionMoveWest)

    let (isEast, actEast) = commandToAction(CmdMoveEast)
    check(isEast and actEast == ActionMoveEast)

    let (isWait, actWait) = commandToAction(CmdWait)
    check(isWait and actWait == ActionWait)

    let (isPot, actPot) = commandToAction(CmdUsePotion)
    check(isPot and actPot == ActionUsePotion)

    # Non-gameplay commands do not produce PlayerActions
    let (isQuit, _) = commandToAction(CmdQuit)
    check(not isQuit)

    let (isRestart, _) = commandToAction(CmdRestart)
    check(not isRestart)
