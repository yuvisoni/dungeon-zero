## DUNGEON ZERO - Terminal Management & ANSI Initialization
## Module: dungeon_zero/terminal

import std/[terminal, syncio, os]

when defined(windows):
  type
    HANDLE = pointer
    DWORD = uint32
    BOOL = int32

  const
    STD_OUTPUT_HANDLE: int32 = -11
    STD_INPUT_HANDLE: int32 = -10
    ENABLE_VIRTUAL_TERMINAL_PROCESSING: uint32 = 0x0004'u32
    ENABLE_PROCESSED_OUTPUT: uint32 = 0x0001'u32
    ENABLE_WRAP_AT_EOL_OUTPUT: uint32 = 0x0002'u32

  proc GetStdHandle(nStdHandle: int32): HANDLE {.stdcall, dynlib: "kernel32", importc: "GetStdHandle".}
  proc GetConsoleMode(hConsoleHandle: HANDLE, lpMode: ptr DWORD): BOOL {.stdcall, dynlib: "kernel32", importc: "GetConsoleMode".}
  proc SetConsoleMode(hConsoleHandle: HANDLE, dwMode: DWORD): BOOL {.stdcall, dynlib: "kernel32", importc: "SetConsoleMode".}

var
  origOutMode: uint32 = 0
  isTerminalInitialized = false

proc resetTerminal*() {.noconv.} =
  ## Restores cursor visibility, resets ANSI colors, and restores original console modes.
  if isTerminalInitialized:
    stdout.write "\e[?25h" # Show cursor
    stdout.write "\e[0m"    # Reset formatting
    stdout.flushFile()
    when defined(windows):
      let hOut = GetStdHandle(STD_OUTPUT_HANDLE)
      if origOutMode != 0:
        discard SetConsoleMode(hOut, origOutMode)
    isTerminalInitialized = false

proc initTerminal*() =
  ## Initializes terminal for game rendering: enables virtual terminal processing,
  ## hides cursor, and registers cleanup hooks on exit and Ctrl+C.
  if isTerminalInitialized:
    return

  when defined(windows):
    let hOut = GetStdHandle(STD_OUTPUT_HANDLE)
    var mode: DWORD = 0
    if GetConsoleMode(hOut, addr mode) != 0:
      origOutMode = mode
      let newMode = mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING or ENABLE_PROCESSED_OUTPUT or ENABLE_WRAP_AT_EOL_OUTPUT
      discard SetConsoleMode(hOut, newMode)

  # Hide cursor and move home
  stdout.write "\e[?25l"
  stdout.write "\e[2J\e[H"
  stdout.flushFile()

  isTerminalInitialized = true

  # Register exit hooks
  addQuitProc(resetTerminal)
  try:
    setControlCHook(proc() {.noconv.} =
      resetTerminal()
      quit(0)
    )
  except:
    discard

proc getTerminalDimensions*(): tuple[width, height: int] =
  ## Returns current terminal columns and rows, falling back to 100x30 or 80x24.
  var w = terminalWidth()
  var h = terminalHeight()
  if w <= 0: w = 100
  if h <= 0: h = 30
  result = (w, h)
