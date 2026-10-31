## DUNGEON ZERO - Combat System & XP Progression
## Module: dungeon_zero/combat

import types

proc calculateDamage*(attack, defense: int): int {.inline.} =
  ## Calculates deterministic combat damage: max(0, attack - defense).
  ## Defense directly mitigates incoming damage; damage is never negative.
  max(0, attack - defense)

proc scoreForEnemy*(kind: EnemyKind): int {.inline.} =
  ## Centralized points awarded per enemy archetype.
  case kind
  of EkGoblin: GoblinScoreVal
  of EkSkeleton: SkeletonScoreVal
  of EkOrc: OrcScoreVal

proc addXp*(player: var Player, xpGained: int): bool =
  ## Awards XP to the player and handles deterministic level-up progression.
  ## Returns true if the player leveled up at least once.
  if xpGained <= 0 or not player.isAlive:
    return false

  player.xp += xpGained
  result = false

  while player.xp >= player.xpToNextLevel:
    player.xp -= player.xpToNextLevel
    player.level += 1
    player.maxHp += LevelUpHpGain
    player.hp = min(player.maxHp, player.hp + LevelUpHpGain)
    player.attack += LevelUpAtkGain
    player.defense += LevelUpDefGain
    player.xpToNextLevel = player.level * XpPerLevelBase
    result = true

proc playerAttackEnemy*(player: var Player, enemy: var Enemy): tuple[damageDealt: int, enemyDefeated: bool, xpGained: int, leveledUp: bool] =
  ## Executes a player attack against target enemy (bump-to-attack).
  if not player.isAlive or not enemy.isAlive:
    return (0, false, 0, false)

  let damage = calculateDamage(player.attack, enemy.defense)
  enemy.hp = max(0, enemy.hp - damage)

  var defeated = false
  var xpAwarded = 0
  var leveledUp = false

  if enemy.hp <= 0:
    enemy.isAlive = false
    defeated = true
    xpAwarded = enemy.xpValue
    player.score += scoreForEnemy(enemy.kind)
    leveledUp = player.addXp(xpAwarded)

  return (damage, defeated, xpAwarded, leveledUp)

proc playerAttackEnemy*(player: var Player, enemy: var Enemy, stats: var GameStats): tuple[damageDealt: int, enemyDefeated: bool, xpGained: int, leveledUp: bool] =
  ## Overload tracking statistics.
  result = playerAttackEnemy(player, enemy)
  stats.damageDealt += result.damageDealt
  if result.enemyDefeated:
    stats.enemiesDefeated += 1
    case enemy.kind
    of EkGoblin: stats.goblinsDefeated += 1
    of EkSkeleton: stats.skeletonsDefeated += 1
    of EkOrc: stats.orcsDefeated += 1

proc enemyAttackPlayer*(enemy: Enemy, player: var Player): tuple[damageDealt: int, playerDied: bool] =
  ## Resolves an enemy attack against the player.
  if not enemy.isAlive or not player.isAlive:
    return (0, false)

  let damage = calculateDamage(enemy.attack, player.defense)
  player.hp = max(0, player.hp - damage)

  var died = false
  if player.hp <= 0:
    player.isAlive = false
    died = true

  return (damage, died)

proc enemyAttackPlayer*(enemy: Enemy, player: var Player, stats: var GameStats): tuple[damageDealt: int, playerDied: bool] =
  ## Overload tracking statistics.
  result = enemyAttackPlayer(enemy, player)
  stats.damageReceived += result.damageDealt
