# Package

version       = "1.0.0"
author        = "Antigravity AI"
description   = "DUNGEON ZERO - Terminal Roguelike Dungeon Crawler"
license       = "MIT"
srcDir        = "src"
bin = @["main"]

# Dependencies

requires "nim >= 2.4.0"

task test, "Runs unit tests":
  exec "nim c -r tests/test_m1_skeleton.nim"
  exec "nim c -r tests/test_mapgen.nim"
  exec "nim c -r tests/test_fov.nim"
  exec "nim c -r tests/test_pathfinding.nim"
  exec "nim c -r tests/test_combat.nim"
  exec "nim c -r tests/test_inventory.nim"
  exec "nim c -r tests/test_game.nim"
  exec "nim c -r tests/test_input.nim"
  exec "nim c -r tests/test_renderer.nim"
  exec "nim c -r tests/test_progression.nim"
  exec "nim c -r tests/test_benchmark.nim"
