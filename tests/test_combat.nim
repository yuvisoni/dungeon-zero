## DUNGEON ZERO - Milestone 4 Test Suite: Combat System & Player Progression
## Tests: Damage calculations, Defense mitigation, Non-negative damage, Death detection, XP & Level-up, Archetypes, Determinism

import std/[unittest]
import ../src/dungeon_zero/[types, combat]

suite "Milestone 4: Combat System & Level Progression":
  test "1, 2 & 3. Damage calculation: Player attacks, defense mitigates, damage never negative":
    # Base attack vs base defense
    check(calculateDamage(15, 5) == 10)
    # Higher defense reduces damage
    check(calculateDamage(15, 10) == 5)
    # Defense >= attack results in 0 (never negative)
    check(calculateDamage(15, 15) == 0)
    check(calculateDamage(15, 25) == 0)
    check(calculateDamage(0, 10) == 0)

  test "4 & 5. Player attack damages enemy, detects death, and awards XP":
    var player = initPlayer(Coord(x: 5, y: 5), attack = 20)
    var enemy = initEnemy(1, Coord(x: 5, y: 6), EkGoblin) # Goblin HP = 25, Def = 2
    
    # Hit 1: 20 - 2 = 18 damage -> Goblin HP becomes 25 - 18 = 7
    let (dmg1, def1, xp1, lvl1) = playerAttackEnemy(player, enemy)
    check(dmg1 == 18)
    check(not def1)
    check(enemy.isAlive)
    check(enemy.hp == 7)
    check(xp1 == 0)

    # Hit 2: 20 - 2 = 18 damage -> Goblin HP becomes 0 (slain)
    let (dmg2, def2, xp2, lvl2) = playerAttackEnemy(player, enemy)
    check(dmg2 == 18)
    check(def2)
    check(not enemy.isAlive)
    check(enemy.hp == 0)
    check(xp2 == GoblinXp)
    check(player.xp == GoblinXp)

  test "6. Level-up progression increases stats and scales next requirement":
    var player = initPlayer(Coord(x: 1, y: 1))
    check(player.level == 1)
    check(player.xp == 0)
    check(player.xpToNextLevel == XpPerLevelBase) # 50
    let initialAtk = player.attack
    let initialDef = player.defense
    let initialMaxHp = player.maxHp

    # Award 55 XP -> triggers level up from 1 to 2 with 5 carryover XP
    let didLevelUp = player.addXp(55)
    check(didLevelUp)
    check(player.level == 2)
    check(player.xp == 5)
    check(player.xpToNextLevel == 2 * XpPerLevelBase) # 100
    check(player.attack == initialAtk + LevelUpAtkGain)
    check(player.defense == initialDef + LevelUpDefGain)
    check(player.maxHp == initialMaxHp + LevelUpHpGain)

  test "7 & 8. Enemy attacks reduce player HP, dead enemies cannot attack":
    var player = initPlayer(Coord(x: 1, y: 1), defense = 4)
    let initialHp = player.hp
    var orc = initEnemy(1, Coord(x: 1, y: 2), EkOrc) # Orc ATK = 18

    # Alive orc attacks: 18 - 4 = 14 damage
    let (dmg, died) = enemyAttackPlayer(orc, player)
    check(dmg == 14)
    check(not died)
    check(player.hp == initialHp - 14)

    # Slain orc cannot attack
    orc.isAlive = false
    let (dmgDead, diedDead) = enemyAttackPlayer(orc, player)
    check(dmgDead == 0)
    check(not diedDead)
    check(player.hp == initialHp - 14) # Unchanged

  test "9. Different enemy archetypes have distinct attributes":
    let goblin = initEnemy(1, Coord(x: 0, y: 0), EkGoblin)
    let skeleton = initEnemy(2, Coord(x: 0, y: 0), EkSkeleton)
    let orc = initEnemy(3, Coord(x: 0, y: 0), EkOrc)

    # Goblin: fast, lower HP & attack
    check(goblin.speed == 2)
    check(goblin.hp == GoblinHp)
    check(goblin.attack == GoblinAttack)

    # Skeleton: balanced stats
    check(skeleton.speed == 1)
    check(skeleton.hp == SkeletonHp)
    check(skeleton.attack == SkeletonAttack)
    check(skeleton.hp > goblin.hp)
    check(skeleton.attack > goblin.attack)

    # Orc: heavy hitter, slower
    check(orc.speed == 1)
    check(orc.hp == OrcHp)
    check(orc.attack == OrcAttack)
    check(orc.defense == OrcDefense)
    check(orc.hp > skeleton.hp)
    check(orc.attack > skeleton.attack)

  test "10. Combat calculations are 100% deterministic":
    for _ in 0 ..< 100:
      let d1 = calculateDamage(17, 6)
      let d2 = calculateDamage(17, 6)
      check(d1 == 11 and d2 == 11)
