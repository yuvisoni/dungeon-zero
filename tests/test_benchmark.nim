## DUNGEON ZERO - Benchmark Simulation Unit Tests
## Module: tests/test_benchmark

import std/[unittest, strutils, json]
import ../src/dungeon_zero/benchmark

suite "Headless Benchmark Suite":

  test "Deterministic simulation produces identical results for identical seed":
    let res1 = runDeterministicBenchmark(seed = 1337, maxTurns = 100)
    let res2 = runDeterministicBenchmark(seed = 1337, maxTurns = 100)

    check res1.seed == res2.seed
    check res1.requestedTurns == res2.requestedTurns
    check res1.executedTurns == res2.executedTurns
    check res1.floorsReached == res2.floorsReached
    check res1.floorsCompleted == res2.floorsCompleted
    check res1.enemiesDefeated == res2.enemiesDefeated
    check res1.goblinsDefeated == res2.goblinsDefeated
    check res1.skeletonsDefeated == res2.skeletonsDefeated
    check res1.orcsDefeated == res2.orcsDefeated
    check res1.damageDealt == res2.damageDealt
    check res1.damageReceived == res2.damageReceived
    check res1.goldCollected == res2.goldCollected
    check res1.potionsUsed == res2.potionsUsed
    check res1.finalHp == res2.finalHp
    check res1.finalScore == res2.finalScore
    check res1.finalStatus == res2.finalStatus

  test "Benchmark respects requested maximum turn limit":
    let res50 = runDeterministicBenchmark(seed = 2024, maxTurns = 50)
    check res50.executedTurns <= 50

    let res200 = runDeterministicBenchmark(seed = 2024, maxTurns = 200)
    check res200.executedTurns <= 200

  test "Benchmark JSON serialization produces valid and parseable JSON":
    let res = runDeterministicBenchmark(seed = 42, maxTurns = 75)
    let jsonStr = res.toJson()

    # Must parse successfully with std/json
    let parsed = parseJson(jsonStr)
    check parsed["seed"].getInt() == 42
    check parsed["requested_turns"].getInt() == 75
    check parsed.hasKey("final_score")
    check parsed.hasKey("final_status")
    check parsed.hasKey("floors_reached")
    check parsed.hasKey("enemies_defeated")
    check parsed.hasKey("damage_dealt")
    check parsed.hasKey("gold_collected")
    check parsed.hasKey("duration_ms")

  test "Text formatting contains all critical summary indicators":
    let res = runDeterministicBenchmark(seed = 888, maxTurns = 60)
    let text = res.formatText()

    check "DUNGEON ZERO" in text
    check "Seed:" in text
    check "Executed Turns:" in text
    check "Final Score:" in text
    check "Player HP:" in text
