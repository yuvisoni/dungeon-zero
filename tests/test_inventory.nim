## DUNGEON ZERO - Milestone 4 Test Suite: Inventory System
## Tests: Gold collection, Potion pickup & capacity, Healing bounds, Full HP usage guard, Empty inventory guard, Consistency

import std/[unittest]
import ../src/dungeon_zero/[types, inventory]

suite "Milestone 4: Inventory System":
  test "1 & 9. Gold collection and non-negative gold validation":
    var player = initPlayer(Coord(x: 0, y: 0))
    check(player.gold == 0)

    # Collect valid gold
    let collected = collectGold(player, 50)
    check(collected == 50)
    check(player.gold == 50)
    check(player.score == 250)

    # Zero or negative gold attempts are ignored / cannot reduce gold
    let invalidCollect = collectGold(player, -20)
    check(invalidCollect == 0)
    check(player.gold == 50)

  test "2 & 3. Health potion pickup and inventory capacity limit":
    var player = initPlayer(Coord(x: 0, y: 0))
    # Initial potions is 2, maxPotions is 5
    check(player.potions == PlayerInitialPotions) # 2
    check(player.maxPotions == PlayerMaxPotions) # 5

    # Pick up until full
    check(collectPotion(player)) # 3
    check(collectPotion(player)) # 4
    check(collectPotion(player)) # 5 (full)

    check(player.potions == 5)

    # Exceeding capacity is blocked
    check(not collectPotion(player))
    check(player.potions == 5)

  test "4, 5 & 8. Potion restores HP without exceeding maxHp and removes item":
    var player = initPlayer(Coord(x: 0, y: 0))
    player.potions = 2
    player.hp = 60 # Damaged from 100 maxHp

    # Drink potion (heals up to PotionHealAmount = 35)
    # 60 + 35 = 95 <= 100
    let (s1, h1, r1) = usePotion(player)
    check(s1)
    check(h1 == 35)
    check(player.hp == 95)
    check(player.potions == 1)

    # Drink second potion (heals up to maxHp = 100)
    # 95 + 35 would be 130, capped at 100 (heals 5)
    let (s2, h2, r2) = usePotion(player)
    check(s2)
    check(h2 == 5)
    check(player.hp == 100)
    check(player.potions == 0)

  test "6. Potion cannot be used when HP is already full":
    var player = initPlayer(Coord(x: 0, y: 0))
    player.hp = player.maxHp
    player.potions = 3

    let (success, healed, reason) = usePotion(player)
    check(not success)
    check(healed == 0)
    check(player.potions == 3) # Potion was not wasted
    check(player.hp == player.maxHp)

  test "7. Missing items cannot be consumed (empty inventory guard)":
    var player = initPlayer(Coord(x: 0, y: 0))
    player.hp = 50
    player.potions = 0

    let (success, healed, reason) = usePotion(player)
    check(not success)
    check(healed == 0)
    check(player.hp == 50)
    check(player.potions == 0)

  test "10. Inventory state integrity remains strictly consistent":
    var player = initPlayer(Coord(x: 0, y: 0))
    check(checkInventoryIntegrity(player))

    # Stress testing transitions
    discard collectGold(player, 1000)
    player.hp = 10
    discard collectPotion(player)
    discard usePotion(player)
    check(checkInventoryIntegrity(player))
