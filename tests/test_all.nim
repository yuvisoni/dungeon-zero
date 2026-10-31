## DUNGEON ZERO - Unified Master Test Suite Runner
## Runs all 11 test suites sequentially and reports aggregate test metrics

import std/os

const TestFiles = [
  "tests/test_m1_skeleton.nim",
  "tests/test_mapgen.nim",
  "tests/test_fov.nim",
  "tests/test_pathfinding.nim",
  "tests/test_combat.nim",
  "tests/test_inventory.nim",
  "tests/test_game.nim",
  "tests/test_input.nim",
  "tests/test_renderer.nim",
  "tests/test_progression.nim",
  "tests/test_benchmark.nim"
]

proc main() =
  echo "=========================================================================="
  echo " DUNGEON ZERO — EXECUTING ALL 11 AUTOMATED TEST SUITES"
  echo "=========================================================================="
  var passedSuites = 0
  var failedSuites = 0

  for testFile in TestFiles:
    echo ">> Running test suite: " & testFile
    let suiteName = extractFilename(testFile).changeFileExt("")
    let cmd = "nim c -r --hints:off --warnings:off --nimcache:build/nimcache/" & suiteName & " " & testFile
    let exitCode = execShellCmd(cmd)
    if exitCode == 0:
      inc passedSuites
      echo ">> [PASS] " & testFile & "\n"
    else:
      inc failedSuites
      echo ">> [FAIL] " & testFile & " (Exit Code: " & $exitCode & ")\n"

  echo "=========================================================================="
  echo " AGGREGATE TEST SUMMARY:"
  echo " Passed Suites: " & $passedSuites & " / " & $(TestFiles.len)
  echo " Failed Suites: " & $failedSuites & " / " & $(TestFiles.len)
  echo "=========================================================================="
  if failedSuites > 0:
    quit(1)
  else:
    echo " ALL TEST SUITES PASSED CLEANLY (100% SUCCESS)!"

when isMainModule:
  main()
