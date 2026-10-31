## DUNGEON ZERO - Game State Machine, Turn Orchestration & Multi-Floor Progression
## Module: dungeon_zero/game

import std/[strformat, sequtils]
import types, mapgen, fov, pathfinding, combat, inventory

proc initGame*(seed: int64, width: int = DefaultMapWidth, height: int = DefaultMapHeight,
               floorLevel: int = 1): GameState =
  ## Initializes a clean, fully validated game state using the given seed.
  let floorSeed = seed + (floorLevel - 1).int64 * 10007'i64
  let gen = generateDungeon(floorSeed, width, height, floorLevel)
  var dungeon = gen.dungeon
  var player = initPlayer(dungeon.playerStart)
  player.floor = floorLevel

  # Compute initial field of view around player
  computeFov(dungeon, player.pos, radius = DefaultFovRadius)

  result = GameState(
    seed: seed,
    dungeon: dungeon,
    player: player,
    enemies: gen.enemies,
    items: gen.items,
    messageLog: @[LogMessage(text: "Welcome to DUNGEON ZERO! Find the exit (>) to descend deeper.", color: "white")],
    status: StatusPlaying,
    turnCount: 0,
    stats: GameStats()
  )

proc addMessage*(state: var GameState, text: string, color: string = "white") =
  ## Adds a message to the in-game log buffer.
  state.messageLog.add(LogMessage(text: text, color: color))

proc advanceFloor*(state: var GameState): bool =
  ## Advances player to the next floor, preserving character stats,
  ## awarding floor clear bonuses, and resetting floor-specific map & entities.
  if state.status != StatusPlaying or not state.player.isAlive:
    return false

  if state.player.floor >= MaxDungeonFloors:
    # Final Victory: conquered all floors!
    state.status = StatusVictory
    state.player.score += VictoryBonus
    state.stats.floorsCompleted = MaxDungeonFloors
    state.addMessage(fmt"CONGRATULATIONS! You conquered Floor {MaxDungeonFloors} and escaped DUNGEON ZERO! (+{VictoryBonus} Victory Bonus)", "cyan")
    return false

  # Award floor clear bonus
  state.stats.floorsCompleted += 1
  let bonus = state.player.floor * FloorClearBonusBase
  state.player.score += bonus
  state.player.floor += 1

  # Deterministic generation for the next floor
  let genWidth = if state.dungeon.width < DefaultMapWidth: DefaultMapWidth else: state.dungeon.width
  let genHeight = if state.dungeon.height < DefaultMapHeight: DefaultMapHeight else: state.dungeon.height
  let floorSeed = state.seed + (state.player.floor - 1).int64 * 10007'i64
  let gen = generateDungeon(floorSeed, genWidth, genHeight, state.player.floor)

  # Reset floor-specific state while preserving player attributes
  state.dungeon = gen.dungeon
  state.enemies = gen.enemies
  state.items = gen.items
  state.player.pos = gen.dungeon.playerStart

  # Recalculate FOV on new map
  computeFov(state.dungeon, state.player.pos, radius = DefaultFovRadius)

  state.addMessage(fmt"You descend to Floor {state.player.floor}! Danger intensifies... (+{bonus} Floor Bonus)", "yellow")
  return true

proc actionToDirection(action: PlayerAction): tuple[isMove: bool, delta: Coord] =
  case action
  of ActionMoveNorth: (true, Coord(x: 0, y: -1))
  of ActionMoveSouth: (true, Coord(x: 0, y: 1))
  of ActionMoveEast:  (true, Coord(x: 1, y: 0))
  of ActionMoveWest:  (true, Coord(x: -1, y: 0))
  else: (false, Coord(x: 0, y: 0))

proc stepGame*(state: var GameState, action: PlayerAction): tuple[actionValid: bool, turnExecuted: bool, message: string] =
  ## Orchestrates a single discrete game turn:
  ## 1. Validates player action (rejects actions if game over).
  ## 2. Resolves player action (movement, bump-to-attack, potion, wait).
  ## 3. Invalid actions (e.g. wall collision) do NOT trigger enemy turns.
  ## 4. If turn executed, updates active enemy movement and adjacent attacks.
  ## 5. Updates FOV and checks victory / death conditions.
  
  if state.status != StatusPlaying or not state.player.isAlive:
    return (false, false, "Game is already over! No actions permitted.")

  var turnTriggered = false
  var actionMsg = ""

  let (isMove, delta) = actionToDirection(action)

  if isMove:
    let targetPos = state.player.pos + delta

    # 1. Check boundary and wall collision
    if targetPos.x < 0 or targetPos.x >= state.dungeon.width or
       targetPos.y < 0 or targetPos.y >= state.dungeon.height or
       state.dungeon.tiles[targetPos.y][targetPos.x] == TileWall:
      # Invalid action: walking into a wall must NOT trigger an enemy turn
      state.addMessage("You bump into a solid wall.", "gray")
      return (false, false, "You bump into a solid wall.")

    # 2. Check bump-to-attack against any alive enemy at targetPos
    var enemyIdx = -1
    for i in 0 ..< state.enemies.len:
      if state.enemies[i].isAlive and state.enemies[i].pos == targetPos:
        enemyIdx = i
        break

    if enemyIdx >= 0:
      # Player attacks enemy with stats tracking
      let (dmg, defeated, xp, leveledUp) = playerAttackEnemy(state.player, state.enemies[enemyIdx], state.stats)
      turnTriggered = true
      actionMsg = fmt"You hit {state.enemies[enemyIdx].name} for {dmg} damage."
      state.addMessage(actionMsg, "green")

      if defeated:
        let deathMsg = fmt"{state.enemies[enemyIdx].name} is slain! (+{xp} XP)"
        state.addMessage(deathMsg, "yellow")
        if leveledUp:
          let lvlMsg = fmt"LEVEL UP! You are now Level {state.player.level}! Stats increased."
          state.addMessage(lvlMsg, "cyan")
    else:
      # Clear floor: player moves to targetPos
      state.player.pos = targetPos
      turnTriggered = true
      actionMsg = "You move."

      # Check item pickup at new position
      var itemIdx = -1
      for i in 0 ..< state.items.len:
        if state.items[i].pos == targetPos:
          itemIdx = i
          break

      if itemIdx >= 0:
        let item = state.items[itemIdx]
        case item.kind
        of IkGold:
          let g = collectGold(state.player, item.value, state.stats)
          state.addMessage(fmt"Picked up {g} gold coins!", "yellow")
          state.items.delete(itemIdx)
        of IkHealthPotion:
          if collectPotion(state.player):
            state.addMessage("Picked up a Health Potion!", "magenta")
            state.items.delete(itemIdx)
          else:
            state.addMessage("Your potion inventory is full! Potion left on ground.", "red")

      # Check interaction with exit stairs: advance floor or achieve victory
      if state.player.pos == state.dungeon.stairsPos:
        let advanced = advanceFloor(state)
        if not advanced and state.status == StatusVictory:
          return (true, true, "Victory reached!")
        else:
          return (true, true, fmt"Entered Floor {state.player.floor}!")

  elif action == ActionWait:
    turnTriggered = true
    actionMsg = "You wait a turn."
    state.addMessage(actionMsg, "gray")

  elif action == ActionUsePotion:
    let (success, _, reason) = usePotion(state.player, state.stats)
    if success:
      turnTriggered = true
      actionMsg = fmt"You drink a potion. {reason} (HP: {state.player.hp}/{state.player.maxHp})"
      state.addMessage(actionMsg, "magenta")
    else:
      actionMsg = reason
      state.addMessage(actionMsg, "red")
      return (false, false, actionMsg)

  # --- Process Enemy Phase If Turn Was Triggered ---
  if turnTriggered and state.status == StatusPlaying:
    inc state.turnCount
    state.player.turns = state.turnCount

    # Clean up defeated enemies from active state
    state.enemies.keepItIf(it.isAlive)

    # 1. Update enemy movement (pathfinding pursuit)
    updateEnemyMovements(state.dungeon, state.player.pos, state.enemies, state.turnCount)

    # 2. Resolve adjacent enemy attacks against player
    for i in 0 ..< state.enemies.len:
      if not state.enemies[i].isAlive:
        continue

      if manhattanDist(state.enemies[i].pos, state.player.pos) == 1:
        let (dmg, died) = enemyAttackPlayer(state.enemies[i], state.player, state.stats)
        state.addMessage(fmt"{state.enemies[i].name} attacks you for {dmg} damage!", "red")

        if died:
          state.status = StatusPlayerDied
          state.addMessage("You have been defeated... GAME OVER.", "red")
          break

    # 3. Update player FOV from new position
    computeFov(state.dungeon, state.player.pos, radius = DefaultFovRadius)

  return (true, turnTriggered, actionMsg)
