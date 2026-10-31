## DUNGEON ZERO - Terminal ANSI Renderer & UI
## Module: dungeon_zero/renderer

import std/[strformat, strutils, sequtils, syncio, unicode]
import types, fov

# ANSI Escape Codes
const
  AnsiReset* = "\e[0m"
  AnsiBold* = "\e[1m"
  AnsiDim* = "\e[2m"
  AnsiCursorHome* = "\e[H"

  # Colors
  AnsiCyan* = "\e[1;36m"
  AnsiDarkGray* = "\e[90m"
  AnsiMutedGray* = "\e[37m"
  AnsiDimGray* = "\e[2;37m"
  AnsiGreen* = "\e[1;32m"
  AnsiBrightGreen* = "\e[1;92m"
  AnsiWhite* = "\e[1;37m"
  AnsiRed* = "\e[1;31m"
  AnsiYellow* = "\e[1;33m"
  AnsiMagenta* = "\e[1;35m"

proc renderHealthBar*(current, maxVal: int, width: int = 10): string =
  ## Renders a visual health bar: [████████░░]
  if maxVal <= 0: return "[" & repeat("░", width) & "]"
  let filled = clamp((current * width) div maxVal, 0, width)
  let empty = width - filled
  "[" & repeat("█", filled) & repeat("░", empty) & "]"

proc renderXpBar*(current, maxVal: int, width: int = 10): string =
  ## Renders an XP bar: [====------]
  if maxVal <= 0: return "[" & repeat("-", width) & "]"
  let filled = clamp((current * width) div maxVal, 0, width)
  let empty = width - filled
  "[" & repeat("=", filled) & repeat("-", empty) & "]"

proc renderPotionSlots*(current, maxVal: int): string =
  ## Renders potion icons: [!!...]
  var s = "["
  for i in 1 .. maxVal:
    if i <= current: s.add("!")
    else: s.add(".")
  s.add("]")
  s

proc getColoredGlyph(glyph: char, kind: string, vis: VisibilityState): tuple[ch: char, ansi: string] =
  case vis
  of VisVisible:
    case kind
    of "player": (glyph, AnsiCyan)
    of "wall": (glyph, AnsiDarkGray)
    of "floor": (glyph, AnsiMutedGray)
    of "stairs": (glyph, AnsiBrightGreen)
    of "goblin": (glyph, AnsiGreen)
    of "skeleton": (glyph, AnsiWhite)
    of "orc": (glyph, AnsiRed)
    of "gold": (glyph, AnsiYellow)
    of "potion": (glyph, AnsiMagenta)
    else: (glyph, AnsiWhite)
  of VisExplored:
    case kind
    of "wall": (glyph, AnsiDarkGray)
    of "floor": (glyph, AnsiDimGray)
    of "stairs": (glyph, AnsiDimGray)
    else: (' ', "") # Enemies and items do NOT render in explored fog!
  of VisUnexplored:
    (' ', "")

proc renderToString*(state: GameState, includeAnsi: bool = false): string =
  ## Renders the complete 100x30 game UI (Header, Viewport, HUD, Event Log)
  ## into a string buffer. Supports plain text (for tests) or full ANSI styling.
  var lines: seq[string] = @[]
  let d = state.dungeon
  let p = state.player

  # 1. Header (Line 1)
  let titleStr = " DUNGEON ZERO "
  let statsHeader = fmt" Floor: {p.floor}  |  Turn: {state.turnCount}  |  Score: {p.score}  |  Seed: {state.seed} "
  var header = "┌─" & titleStr
  let padLen = max(0, 100 - 2 - titleStr.len - statsHeader.len - 1)
  header.add(repeat("─", padLen) & statsHeader & "┐")
  if includeAnsi:
    lines.add(AnsiBold & AnsiCyan & header & AnsiReset)
  else:
    lines.add(header)

  # Prepare 2D grid for viewport characters and colors
  var viewChars = newSeqWith(d.height, newSeq[char](d.width))
  var viewAnsi = newSeqWith(d.height, newSeq[string](d.width))

  for y in 0 ..< d.height:
    for x in 0 ..< d.width:
      let c = Coord(x: x, y: y)
      let vis = d.getVisibilityState(c)
      let tile = d.tiles[y][x]
      var kind = if tile == TileWall: "wall" elif tile == TileStairsDown: "stairs" else: "floor"
      let glyph = if tile == TileWall: '#' elif tile == TileStairsDown: '>' else: '.'
      let (ch, color) = getColoredGlyph(glyph, kind, vis)
      viewChars[y][x] = ch
      viewAnsi[y][x] = color

  # Render items if currently visible
  for item in state.items:
    if d.isVisible(item.pos):
      let kind = if item.kind == IkGold: "gold" else: "potion"
      let glyph = if item.kind == IkGold: '$' else: '!'
      let (ch, color) = getColoredGlyph(glyph, kind, VisVisible)
      viewChars[item.pos.y][item.pos.x] = ch
      viewAnsi[item.pos.y][item.pos.x] = color

  # Render enemies if currently visible and alive
  for enemy in state.enemies:
    if enemy.isAlive and d.isVisible(enemy.pos):
      let kind = case enemy.kind
                 of EkGoblin: "goblin"
                 of EkSkeleton: "skeleton"
                 of EkOrc: "orc"
      let (ch, color) = getColoredGlyph(enemy.glyph, kind, VisVisible)
      viewChars[enemy.pos.y][enemy.pos.x] = ch
      viewAnsi[enemy.pos.y][enemy.pos.x] = color

  # Render player if alive
  if p.isAlive and p.pos.y >= 0 and p.pos.y < d.height and p.pos.x >= 0 and p.pos.x < d.width:
    let (ch, color) = getColoredGlyph('@', "player", VisVisible)
    viewChars[p.pos.y][p.pos.x] = ch
    viewAnsi[p.pos.y][p.pos.x] = color

  # Overlay Banner on Game Over or Victory
  if state.status == StatusPlayerDied:
    let banner = [
      "#######################################",
      "#              GAME OVER              #",
      "#       You have been defeated!       #",
      "#                                     #",
      fmt"#     Final Score: {p.score:<18} #",
      fmt"#     Turns Survived: {state.turnCount:<15} #",
      "#                                     #",
      "#     Press [R] to Restart            #",
      "#     Press [Q] to Quit               #",
      "#######################################"
    ]
    let startY = 6
    let startX = (d.width - 39) div 2
    for by in 0 ..< banner.len:
      let vy = startY + by
      if vy >= 0 and vy < d.height:
        for bx in 0 ..< banner[by].len:
          let vx = startX + bx
          if vx >= 0 and vx < d.width:
            viewChars[vy][vx] = banner[by][bx]
            viewAnsi[vy][vx] = AnsiRed

  elif state.status == StatusVictory:
    let banner = [
      "#######################################",
      "#              VICTORY!               #",
      "#     You escaped DUNGEON ZERO!       #",
      "#                                     #",
      fmt"#     Final Score: {p.score:<18} #",
      fmt"#     Turns Taken: {state.turnCount:<18} #",
      "#                                     #",
      "#     Press [R] to Play Again         #",
      "#     Press [Q] to Quit               #",
      "#######################################"
    ]
    let startY = 6
    let startX = (d.width - 39) div 2
    for by in 0 ..< banner.len:
      let vy = startY + by
      if vy >= 0 and vy < d.height:
        for bx in 0 ..< banner[by].len:
          let vx = startX + bx
          if vx >= 0 and vx < d.width:
            viewChars[vy][vx] = banner[by][bx]
            viewAnsi[vy][vx] = AnsiBrightGreen

  # Prepare HUD lines (22 lines for lines 2 to 23)
  var hud: seq[string] = @[]
  hud.add(fmt" PLAYER STATUS")
  hud.add(fmt" HP:    {renderHealthBar(p.hp, p.maxHp, 10)} {p.hp}/{p.maxHp}")
  hud.add(fmt" XP:    {renderXpBar(p.xp, p.xpToNextLevel, 10)} {p.xp}/{p.xpToNextLevel}")
  hud.add(fmt" Level:  {p.level}")
  hud.add(fmt" Attack: {p.attack}")
  hud.add(fmt" Def:    {p.defense}")
  hud.add(" ──────────────────────────")
  hud.add(" INVENTORY")
  hud.add(fmt" Gold:    $ {p.gold}")
  hud.add(fmt" Potions: ! {renderPotionSlots(p.potions, p.maxPotions)} ({p.potions}/{p.maxPotions})")
  hud.add(" ──────────────────────────")
  hud.add(" DUNGEON INFO")
  hud.add(fmt" Floor:   {p.floor}")
  hud.add(fmt" Turns:   {state.turnCount}")
  hud.add(fmt" Score:   {p.score}")
  hud.add(" ──────────────────────────")
  hud.add(" CONTROLS")
  hud.add(" WASD / Arrows : Move")
  hud.add(" SPACE         : Wait")
  hud.add(" P             : Potion")
  hud.add(" R             : Restart")
  hud.add(" Q             : Quit")
  hud.add("")

  # Combine Viewport (70 cols) + Separator (1 col) + HUD (28 cols)
  for y in 0 ..< d.height:
    var rowStr = ""
    if includeAnsi:
      for x in 0 ..< d.width:
        rowStr.add(viewAnsi[y][x] & viewChars[y][x])
      rowStr.add(AnsiReset & AnsiDarkGray & "│" & AnsiReset)
    else:
      for x in 0 ..< d.width:
        rowStr.add(viewChars[y][x])
      rowStr.add("│")

    let hudText = if y < hud.len: hud[y] else: ""
    let paddedHud = hudText & repeat(" ", max(0, 28 - hudText.runeLen))
    rowStr.add(paddedHud)

    lines.add(rowStr)

  # Separator between Viewport and Event Log (Line 24)
  var midSep = "├" & repeat("─", 70) & "┴" & repeat("─", 28) & "┤"
  if includeAnsi:
    lines.add(AnsiDarkGray & midSep & AnsiReset)
  else:
    lines.add(midSep)

  # Event & Combat Log (5 lines: Lines 25 to 29)
  const logCapacity = 5
  var recentLogs: seq[LogMessage] = @[]
  if state.messageLog.len > logCapacity:
    recentLogs = state.messageLog[(state.messageLog.len - logCapacity) .. ^1]
  else:
    recentLogs = state.messageLog

  for i in 0 ..< logCapacity:
    var logText = ""
    var logColor = AnsiWhite
    if i < recentLogs.len:
      logText = recentLogs[i].text
      case recentLogs[i].color
      of "green": logColor = AnsiGreen
      of "red": logColor = AnsiRed
      of "yellow": logColor = AnsiYellow
      of "cyan": logColor = AnsiCyan
      of "magenta": logColor = AnsiMagenta
      of "gray": logColor = AnsiDarkGray
      else: logColor = AnsiWhite

    let clipped = if logText.len > 96: logText[0 .. 93] & "..." else: logText
    let padded = clipped & repeat(" ", max(0, 96 - clipped.len))
    if includeAnsi:
      lines.add(AnsiDarkGray & "│ " & logColor & padded & AnsiDarkGray & " │" & AnsiReset)
    else:
      lines.add("│ " & padded & " │")

  # Bottom border (Line 30)
  var botSep = "└" & repeat("─", 98) & "┘"
  if includeAnsi:
    lines.add(AnsiDarkGray & botSep & AnsiReset)
  else:
    lines.add(botSep)

  result = lines.join("\n")

proc renderFrame*(state: GameState) =
  ## Renders the frame to the active terminal screen using flicker-free cursor home.
  let rendered = AnsiCursorHome & renderToString(state, includeAnsi = true)
  stdout.write(rendered)
  stdout.flushFile()
