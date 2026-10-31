## DUNGEON ZERO - Keyboard Input & Command Parsing
## Module: dungeon_zero/input

import types

type
  InputCommand* = enum
    CmdNone
    CmdMoveNorth
    CmdMoveSouth
    CmdMoveWest
    CmdMoveEast
    CmdWait
    CmdUsePotion
    CmdQuit
    CmdRestart

when defined(windows):
  proc conio_getch(): cint {.header: "<conio.h>", importc: "_getch".}
  proc conio_kbhit(): cint {.header: "<conio.h>", importc: "_kbhit".}
else:
  import std/terminal

proc parseKey*(c: char, isExtended: bool = false, extCode: int = 0): InputCommand =
  ## Pure function mapping characters and extended scan codes to GameCommands.
  if isExtended:
    case extCode
    of 72: return CmdMoveNorth # Up Arrow
    of 80: return CmdMoveSouth # Down Arrow
    of 75: return CmdMoveWest  # Left Arrow
    of 77: return CmdMoveEast  # Right Arrow
    else: return CmdNone

  case c
  of 'w', 'W': CmdMoveNorth
  of 's', 'S': CmdMoveSouth
  of 'a', 'A': CmdMoveWest
  of 'd', 'D': CmdMoveEast
  of ' ':      CmdWait
  of 'p', 'P': CmdUsePotion
  of 'q', 'Q': CmdQuit
  of 'r', 'R': CmdRestart
  else:        CmdNone

proc parseAnsiSequence*(seqStr: string): InputCommand =
  ## Parses standard ANSI escape sequences (e.g. "\e[A" for Up Arrow).
  if seqStr == "\e[A" or seqStr == "[A": CmdMoveNorth
  elif seqStr == "\e[B" or seqStr == "[B": CmdMoveSouth
  elif seqStr == "\e[C" or seqStr == "[C": CmdMoveEast
  elif seqStr == "\e[D" or seqStr == "[D": CmdMoveWest
  else: CmdNone

proc commandToAction*(cmd: InputCommand): tuple[isAction: bool, action: PlayerAction] =
  ## Translates input command into a game engine PlayerAction.
  case cmd
  of CmdMoveNorth: (true, ActionMoveNorth)
  of CmdMoveSouth: (true, ActionMoveSouth)
  of CmdMoveWest:  (true, ActionMoveWest)
  of CmdMoveEast:  (true, ActionMoveEast)
  of CmdWait:      (true, ActionWait)
  of CmdUsePotion: (true, ActionUsePotion)
  else:            (false, ActionWait)

proc readCommand*(blocking: bool = true): InputCommand =
  ## Reads an immediate keypress from the console without waiting for Enter.
  when defined(windows):
    if not blocking and conio_kbhit() == 0:
      return CmdNone

    let ch = conio_getch()
    if ch == 0 or ch == 224: # Extended key prefix on Windows
      let ext = conio_getch()
      return parseKey('\0', isExtended = true, extCode = ext.int)
    elif ch == 27: # ESC or ANSI sequence
      if conio_kbhit() != 0:
        let c2 = conio_getch()
        if c2 == ord('['):
          let c3 = conio_getch()
          case chr(c3)
          of 'A': return CmdMoveNorth
          of 'B': return CmdMoveSouth
          of 'C': return CmdMoveEast
          of 'D': return CmdMoveWest
          else: discard
      return CmdQuit
    else:
      return parseKey(chr(ch))
  else:
    let ch = getch()
    return parseKey(ch)
