## DUNGEON ZERO - Inventory System & Item Consumption
## Module: dungeon_zero/inventory

import std/[strformat]
import types

proc collectGold*(player: var Player, amount: int): int =
  ## Collects gold, preventing negative values and boosting score.
  if amount <= 0:
    return 0
  player.gold += amount
  player.score += amount * GoldScoreMultiplier
  return amount

proc collectGold*(player: var Player, amount: int, stats: var GameStats): int =
  ## Overload tracking statistics.
  result = collectGold(player, amount)
  stats.goldCollected += result

proc collectPotion*(player: var Player): bool =
  ## Attempts to store a potion in the player's inventory.
  ## Returns false if inventory is at maximum capacity.
  if player.potions >= player.maxPotions:
    return false
  player.potions += 1
  return true

proc usePotion*(player: var Player): tuple[success: bool, amountHealed: int, reason: string] =
  ## Consumes a health potion from inventory, restoring HP up to maxHp.
  if player.potions <= 0:
    return (false, 0, "No potions remaining in inventory!")

  if player.hp >= player.maxHp:
    return (false, 0, "Health is already at maximum!")

  let healPossible = min(PotionHealAmount, player.maxHp - player.hp)
  player.hp += healPossible
  player.potions -= 1
  return (true, healPossible, fmt"Restored {healPossible} HP")

proc usePotion*(player: var Player, stats: var GameStats): tuple[success: bool, amountHealed: int, reason: string] =
  ## Overload tracking statistics.
  result = usePotion(player)
  if result.success:
    stats.potionsUsed += 1

proc checkInventoryIntegrity*(player: Player): bool =
  ## Invariant validator: ensures gold >= 0, potions in [0, maxPotions], hp in [0, maxHp].
  player.gold >= 0 and
  player.potions >= 0 and player.potions <= player.maxPotions and
  player.hp >= 0 and player.hp <= player.maxHp
