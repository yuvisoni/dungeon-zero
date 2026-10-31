## DUNGEON ZERO - Headless Deterministic Benchmark Engine
## Module: dungeon_zero/benchmark

import std/[strformat, strutils, times, monotimes]
import types, game, pathfinding

type
  BenchmarkResult* = object
    seed*: int64
    requestedTurns*: int
    executedTurns*: int
    floorsReached*: int
    floorsCompleted*: int
    enemiesDefeated*: int
    goblinsDefeated*: int
    skeletonsDefeated*: int
    orcsDefeated*: int
    goldCollected*: int
    potionsUsed*: int
    damageDealt*: int
    damageReceived*: int
    finalHp*: int
    finalMaxHp*: int
    finalLevel*: int
    finalXp*: int
    finalScore*: int
    finalStatus*: string
    durationMs*: float

proc choosePolicyAction(state: GameState): PlayerAction =
  ## Deterministic rule-based benchmark bot policy:
  ## 1. If HP is critically low (<= 40) and has potions -> Drink potion.
  ## 2. If an enemy is adjacent -> Strike adjacent enemy (bump-to-attack).
  ## 3. If an item is on current floor -> Pathfind towards closest item.
  ## 4. Pathfind towards exit stairs.
  ## 5. Fallback -> Wait.

  # 1. Survival instinct
  if state.player.hp <= 40 and state.player.potions > 0:
    return ActionUsePotion

  let pPos = state.player.pos

  # 2. Adjacent enemy engagement
  for d in CardinalNeighbors:
    let nPos = pPos + d
    for e in state.enemies:
      if e.isAlive and e.pos == nPos:
        if d.x == 0 and d.y == -1: return ActionMoveNorth
        elif d.x == 0 and d.y == 1: return ActionMoveSouth
        elif d.x == 1 and d.y == 0: return ActionMoveEast
        elif d.x == -1 and d.y == 0: return ActionMoveWest

  # 3. Pathfind to nearest item if available
  if state.items.len > 0:
    var bestPath: seq[Coord] = @[]
    var minDist = 9999
    for item in state.items:
      let path = state.dungeon.findPath(pPos, item.pos)
      if path.len > 0 and path.len < minDist:
        minDist = path.len
        bestPath = path

    if bestPath.len > 0:
      let nextStep = bestPath[0]
      let diff = nextStep - pPos
      if diff.x == 0 and diff.y == -1: return ActionMoveNorth
      elif diff.x == 0 and diff.y == 1: return ActionMoveSouth
      elif diff.x == 1 and diff.y == 0: return ActionMoveEast
      elif diff.x == -1 and diff.y == 0: return ActionMoveWest

  # 4. Pathfind to exit stairs
  let pathToExit = state.dungeon.findPath(pPos, state.dungeon.stairsPos)
  if pathToExit.len > 0:
    let nextStep = pathToExit[0]
    let diff = nextStep - pPos
    if diff.x == 0 and diff.y == -1: return ActionMoveNorth
    elif diff.x == 0 and diff.y == 1: return ActionMoveSouth
    elif diff.x == 1 and diff.y == 0: return ActionMoveEast
    elif diff.x == -1 and diff.y == 0: return ActionMoveWest

  # 5. Fallback
  return ActionWait

proc runDeterministicBenchmark*(seed: int64, maxTurns: int): BenchmarkResult =
  ## Runs a headless simulation using the deterministic bot policy.
  ## Measures execution performance, game events, and final state.
  let startMono = getMonoTime()
  var state = initGame(seed)

  var executed = 0
  for _ in 0 ..< maxTurns:
    if state.status != StatusPlaying or not state.player.isAlive:
      break

    let action = choosePolicyAction(state)
    let (_, turn, _) = state.stepGame(action)
    if turn:
      inc executed

  let elapsedMs = (getMonoTime() - startMono).inMicroseconds.float / 1000.0

  let statusStr = case state.status
                  of StatusPlaying: "Playing"
                  of StatusPlayerDied: "PlayerDied"
                  of StatusVictory, StatusGameWon: "Victory"
                  else: "Finished"

  BenchmarkResult(
    seed: seed,
    requestedTurns: maxTurns,
    executedTurns: executed,
    floorsReached: state.player.floor,
    floorsCompleted: state.stats.floorsCompleted,
    enemiesDefeated: state.stats.enemiesDefeated,
    goblinsDefeated: state.stats.goblinsDefeated,
    skeletonsDefeated: state.stats.skeletonsDefeated,
    orcsDefeated: state.stats.orcsDefeated,
    goldCollected: state.stats.goldCollected,
    potionsUsed: state.stats.potionsUsed,
    damageDealt: state.stats.damageDealt,
    damageReceived: state.stats.damageReceived,
    finalHp: state.player.hp,
    finalMaxHp: state.player.maxHp,
    finalLevel: state.player.level,
    finalXp: state.player.xp,
    finalScore: state.player.score,
    finalStatus: statusStr,
    durationMs: elapsedMs
  )

proc formatText*(res: BenchmarkResult): string =
  var lines: seq[string] = @[]
  lines.add("==========================================================================")
  lines.add(" DUNGEON ZERO — DETERMINISTIC HEADLESS SIMULATION BENCHMARK")
  lines.add("==========================================================================")
  lines.add(fmt"Seed:                 {res.seed}")
  lines.add(fmt"Requested Turns:      {res.requestedTurns}")
  lines.add(fmt"Executed Turns:       {res.executedTurns}")
  lines.add(fmt"Final Status:         {res.finalStatus}")
  lines.add(fmt"Floors Reached:       {res.floorsReached}")
  lines.add(fmt"Floors Completed:     {res.floorsCompleted}")
  lines.add("--------------------------------------------------------------------------")
  lines.add(fmt"Enemies Defeated:     {res.enemiesDefeated} (Goblins: {res.goblinsDefeated}, Skeletons: {res.skeletonsDefeated}, Orcs: {res.orcsDefeated})")
  lines.add(fmt"Damage Dealt:         {res.damageDealt}")
  lines.add(fmt"Damage Received:      {res.damageReceived}")
  lines.add(fmt"Gold Collected:       {res.goldCollected}")
  lines.add(fmt"Potions Consumed:     {res.potionsUsed}")
  lines.add("--------------------------------------------------------------------------")
  lines.add(fmt"Player HP:            {res.finalHp}/{res.finalMaxHp}")
  lines.add(fmt"Player Level:         {res.finalLevel} (XP: {res.finalXp})")
  lines.add(fmt"Final Score:          {res.finalScore}")
  lines.add(fmt"Execution Runtime:    {res.durationMs:.2f} ms")
  lines.add("==========================================================================")
  lines.join("\n")

proc toJson*(res: BenchmarkResult): string =
  fmt"""{{
  "seed": {res.seed},
  "requested_turns": {res.requestedTurns},
  "executed_turns": {res.executedTurns},
  "final_status": "{res.finalStatus}",
  "floors_reached": {res.floorsReached},
  "floors_completed": {res.floorsCompleted},
  "enemies_defeated": {res.enemiesDefeated},
  "goblins_defeated": {res.goblinsDefeated},
  "skeletons_defeated": {res.skeletonsDefeated},
  "orcs_defeated": {res.orcsDefeated},
  "damage_dealt": {res.damageDealt},
  "damage_received": {res.damageReceived},
  "gold_collected": {res.goldCollected},
  "potions_used": {res.potionsUsed},
  "final_hp": {res.finalHp},
  "final_max_hp": {res.finalMaxHp},
  "final_level": {res.finalLevel},
  "final_xp": {res.finalXp},
  "final_score": {res.finalScore},
  "duration_ms": {res.durationMs:.2f}
}}"""
