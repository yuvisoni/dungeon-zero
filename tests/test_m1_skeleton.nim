## DUNGEON ZERO - Milestone 1 Verification Test Suite
## Tests: Types, Coordinate Math, Entity Factories, Seed Determinism

import std/[unittest, strformat]
import ../src/dungeon_zero/[types, rng]

suite "Milestone 1: Core Types & Coordinate System":
  test "Coordinate arithmetic and equality":
    let c1 = Coord(x: 5, y: 10)
    let c2 = Coord(x: 2, y: -3)
    
    check(c1 + c2 == Coord(x: 7, y: 7))
    check(c1 - c2 == Coord(x: 3, y: 13))
    check(c1 == Coord(x: 5, y: 10))
    check(c1 != c2)

  test "Distance calculations":
    let a = Coord(x: 2, y: 3)
    let b = Coord(x: 6, y: 8)
    
    # Manhattan: |2-6| + |3-8| = 4 + 5 = 9
    check(manhattanDist(a, b) == 9)
    # Chebyshev: max(|2-6|, |3-8|) = max(4, 5) = 5
    check(chebyshevDist(a, b) == 5)

  test "Player entity initialization":
    let start = Coord(x: 12, y: 24)
    let player = initPlayer(start)
    
    check(player.pos == start)
    check(player.hp == PlayerInitialHp)
    check(player.maxHp == PlayerInitialMaxHp)
    check(player.attack == PlayerInitialAttack)
    check(player.defense == PlayerInitialDefense)
    check(player.gold == 0)
    check(player.potions == PlayerInitialPotions)
    check(player.isAlive == true)

  test "Enemy archetypes and floor scaling":
    let goblinF1 = initEnemy(1, Coord(x: 1, y: 1), EkGoblin, floorLevel = 1)
    let goblinF3 = initEnemy(2, Coord(x: 1, y: 1), EkGoblin, floorLevel = 3)
    let orcF1 = initEnemy(3, Coord(x: 2, y: 2), EkOrc, floorLevel = 1)
    let skeletonF1 = initEnemy(4, Coord(x: 3, y: 3), EkSkeleton, floorLevel = 1)

    # Goblin: Fast, low HP
    check(goblinF1.speed == 2)
    check(goblinF1.hp == GoblinHp)
    # Scaling on Floor 3: hp > f1 hp
    check(goblinF3.hp > goblinF1.hp)
    check(goblinF3.attack > goblinF1.attack)

    # Skeleton: Balanced
    check(skeletonF1.speed == 1)
    check(skeletonF1.hp == SkeletonHp)

    # Orc: Heavy hitter
    check(orcF1.speed == 1)
    check(orcF1.hp == OrcHp)
    check(orcF1.attack == OrcAttack)

  test "Item initialization":
    let gold = initItem(1, Coord(x: 4, y: 4), IkGold, 25)
    let potion = initItem(2, Coord(x: 5, y: 5), IkHealthPotion, 15)

    check(gold.kind == IkGold)
    check(gold.value == 25)
    check(potion.kind == IkHealthPotion)
    check(potion.value == 15)

suite "Milestone 1: Deterministic RNG":
  test "Identical seed produces identical sequence across 10,000 samples":
    const seed = 987654321'i64
    var rng1 = initGameRng(seed)
    var rng2 = initGameRng(seed)

    var matchCount = 0
    for _ in 0 ..< 10_000:
      let v1 = rng1.nextRange(1, 100)
      let v2 = rng2.nextRange(1, 100)
      if v1 == v2:
        inc matchCount

    check(matchCount == 10_000)

  test "Dice rolling within valid bounds":
    var rng = initGameRng(42)
    for _ in 0 ..< 1_000:
      let roll = rng.rollDice(2, 6) # 2d6 -> 2 to 12
      check(roll >= 2 and roll <= 12)

  test "Shuffle preserves elements":
    var rng = initGameRng(777)
    var original = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    var shuffled = original
    rng.shuffle(shuffled)
    
    check(shuffled.len == original.len)
    for item in original:
      check(shuffled.contains(item))
