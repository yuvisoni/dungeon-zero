## DUNGEON ZERO - Main Executable & Interactive Game Loop
## Pure Nim 2.4.0 Terminal Roguelike Dungeon Crawler

import std/[parseopt, strutils, strformat, os]
import dungeon_zero/[types, game, terminal, input, renderer, benchmark]

const
  GameVersion = "1.0.0"
  DefaultSeed: int64 = 1337
  DefaultBenchmarkTurns = 500

proc printHelp() =
  echo "=========================================================================="
  echo fmt" DUNGEON ZERO (v{GameVersion}) - Terminal ASCII Roguelike Dungeon Crawler"
  echo " Built entirely in pure Nim (Compiler v" & NimVersion & ")"
  echo "=========================================================================="
  echo "Usage:"
  echo "  dungeon_zero [options]"
  echo ""
  echo "Options:"
  echo "  --seed:<number>    Specify deterministic world generation seed (Default: 1337)"
  echo "  --benchmark, -b    Run automated deterministic AI benchmark simulation"
  echo "  --turns:<number>   Number of simulation turns for benchmark (Default: 500)"
  echo "  --json             Output benchmark results in pure JSON schema format"
  echo "  --headless:<turns> Run simple headless simulation without terminal"
  echo "  --help, -h         Display this help message and exit"
  echo "  --version, -v      Display version information and exit"
  echo ""
  echo "Controls:"
  echo "  W / Up Arrow    : Move North"
  echo "  S / Down Arrow  : Move South"
  echo "  A / Left Arrow  : Move West"
  echo "  D / Right Arrow : Move East"
  echo "  SPACE           : Wait a turn"
  echo "  P               : Drink Health Potion"
  echo "  R               : Restart game"
  echo "  Q               : Quit to terminal"
  echo "=========================================================================="

proc runHeadless(seed: int64, turns: int) =
  echo fmt"Running headless simulation with seed {seed} for {turns} turns..."
  var state = initGame(seed)
  const actions = [ActionMoveNorth, ActionMoveEast, ActionMoveSouth, ActionMoveWest, ActionWait]

  var executed = 0
  for t in 1 .. turns:
    if state.status != StatusPlaying:
      break
    let act = actions[t mod actions.len]
    let (valid, turn, msg) = state.stepGame(act)
    if turn:
      inc executed

  echo fmt"Simulation Finished. Status: {state.status} | Turns Executed: {executed} | Final HP: {state.player.hp} | Gold: {state.player.gold} | Score: {state.player.score}"

proc runInteractive(initialSeed: int64) =
  initTerminal()
  defer: resetTerminal()

  var currentSeed = initialSeed
  var state = initGame(currentSeed)

  var running = true
  while running:
    renderFrame(state)

    let cmd = readCommand(blocking = true)
    case cmd
    of CmdQuit:
      running = false

    of CmdRestart:
      currentSeed = currentSeed + state.turnCount.int64 + 1
      state = initGame(currentSeed)

    else:
      if state.status == StatusPlaying:
        let (isAction, action) = commandToAction(cmd)
        if isAction:
          discard state.stepGame(action)
      else:
        # On Game Over or Victory, only R and Q are processed
        discard

proc main() =
  var seed = DefaultSeed
  var benchmarkMode = false
  var benchmarkTurns = DefaultBenchmarkTurns
  var jsonOutput = false
  var headlessTurns = -1

  var p = initOptParser()
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key.toLowerAscii
      of "help", "h":
        printHelp()
        return
      of "version", "v":
        echo fmt"DUNGEON ZERO v{GameVersion} (Nim {NimVersion})"
        return
      of "b", "benchmark":
        benchmarkMode = true
      of "json":
        jsonOutput = true
      of "t", "turns":
        var tVal = p.val
        if tVal.len == 0:
          p.next()
          tVal = p.key
        try:
          benchmarkTurns = parseInt(tVal)
        except ValueError:
          benchmarkTurns = DefaultBenchmarkTurns
      of "seed":
        var seedVal = p.val
        if seedVal.len == 0:
          p.next()
          seedVal = p.key
        try:
          seed = parseBiggestInt(seedVal)
        except ValueError:
          echo "Invalid seed. Using default 1337."
      of "headless":
        var hVal = p.val
        if hVal.len == 0:
          p.next()
          hVal = p.key
        try:
          headlessTurns = parseInt(hVal)
        except ValueError:
          headlessTurns = 100
    of cmdArgument:
      discard

  if benchmarkMode:
    let result = runDeterministicBenchmark(seed, benchmarkTurns)
    if jsonOutput:
      echo result.toJson()
    else:
      echo result.formatText()
    return

  if headlessTurns > 0:
    runHeadless(seed, headlessTurns)
  else:
    runInteractive(seed)

when isMainModule:
  main()
