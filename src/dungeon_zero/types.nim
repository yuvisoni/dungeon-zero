## DUNGEON ZERO - Core Type Definitions
## Module: dungeon_zero/types

import std/[strformat]

const
  DefaultMapWidth* = 70
  DefaultMapHeight* = 22
  MinRoomWidth* = 6
  MaxRoomWidth* = 14
  MinRoomHeight* = 4
  MaxRoomHeight* = 8
  MinRoomsCount* = 4
  MaxRoomAttempts* = 25
  MaxMapgenRetries* = 20

  DefaultFovRadius* = 8
  GoblinAggroRadius* = 8
  SkeletonAggroRadius* = 6
  OrcAggroRadius* = 5

  # Configurable Player Stats (Milestone 4)
  PlayerInitialHp* = 100
  PlayerInitialMaxHp* = 100
  PlayerInitialAttack* = 15
  PlayerInitialDefense* = 5
  PlayerInitialPotions* = 2
  PlayerMaxPotions* = 5
  PotionHealAmount* = 35
  LevelUpHpGain* = 20
  LevelUpAtkGain* = 3
  LevelUpDefGain* = 1
  XpPerLevelBase* = 50

  # Configurable Enemy Archetype Stats
  GoblinHp* = 25
  GoblinAttack* = 8
  GoblinDefense* = 2
  GoblinXp* = 20

  SkeletonHp* = 40
  SkeletonAttack* = 12
  SkeletonDefense* = 4
  SkeletonXp* = 35

  OrcHp* = 60
  OrcAttack* = 18
  OrcDefense* = 6
  OrcXp* = 60

  # Multi-Floor & Centralized Scoring Constants (Milestone 6)
  MaxDungeonFloors* = 5
  FloorClearBonusBase* = 500
  VictoryBonus* = 2000
  GoblinScoreVal* = 50
  SkeletonScoreVal* = 100
  OrcScoreVal* = 200
  GoldScoreMultiplier* = 5

type
  Coord* = object
    x*: int
    y*: int

  Rect* = object
    x1*, y1*, x2*, y2*: int

  TileType* = enum
    TileWall = "#"
    TileFloor = "."
    TileStairsDown = ">"

  EnemyKind* = enum
    EkGoblin = "Goblin"
    EkSkeleton = "Skeleton"
    EkOrc = "Orc"

  ItemKind* = enum
    IkGold = "Treasure ($)"
    IkHealthPotion = "Health Potion (!)"

  Item* = object
    id*: int
    pos*: Coord
    kind*: ItemKind
    value*: int # gold amount or heal amount

  Enemy* = object
    id*: int
    pos*: Coord
    kind*: EnemyKind
    name*: string
    glyph*: char
    hp*: int
    maxHp*: int
    attack*: int
    defense*: int
    xpValue*: int
    speed*: int # 1 = normal, 2 = fast
    aggroRadius*: int
    isAlive*: bool

  Player* = object
    pos*: Coord
    hp*: int
    maxHp*: int
    attack*: int
    defense*: int
    level*: int
    xp*: int
    xpToNextLevel*: int
    gold*: int
    potions*: int
    maxPotions*: int
    floor*: int
    score*: int
    turns*: int
    isAlive*: bool

  PlayerAction* = enum
    ActionMoveNorth
    ActionMoveSouth
    ActionMoveEast
    ActionMoveWest
    ActionWait
    ActionUsePotion

  LogMessage* = object
    text*: string
    color*: string

  GameStatus* = enum
    StatusPlaying
    StatusPlayerDied
    StatusFloorComplete
    StatusGameWon
    StatusVictory
    StatusQuit

  DungeonMap* = object
    width*: int
    height*: int
    tiles*: seq[seq[TileType]]
    explored*: seq[seq[bool]]
    visible*: seq[seq[bool]]
    playerStart*: Coord
    stairsPos*: Coord
    rooms*: seq[Rect]

  GeneratedDungeon* = object
    dungeon*: DungeonMap
    enemies*: seq[Enemy]
    items*: seq[Item]

  GameStats* = object
    enemiesDefeated*: int
    goblinsDefeated*: int
    skeletonsDefeated*: int
    orcsDefeated*: int
    floorsCompleted*: int
    goldCollected*: int
    potionsUsed*: int
    damageDealt*: int
    damageReceived*: int

  GameState* = object
    seed*: int64
    dungeon*: DungeonMap
    player*: Player
    enemies*: seq[Enemy]
    items*: seq[Item]
    messageLog*: seq[LogMessage]
    status*: GameStatus
    turnCount*: int
    stats*: GameStats

# --- Coordinate Utilities ---

proc `+`*(a, b: Coord): Coord {.inline.} =
  Coord(x: a.x + b.x, y: a.y + b.y)

proc `-`*(a, b: Coord): Coord {.inline.} =
  Coord(x: a.x - b.x, y: a.y - b.y)

proc `==`*(a, b: Coord): bool {.inline.} =
  a.x == b.x and a.y == b.y

proc manhattanDist*(a, b: Coord): int {.inline.} =
  abs(a.x - b.x) + abs(a.y - b.y)

proc chebyshevDist*(a, b: Coord): int {.inline.} =
  max(abs(a.x - b.x), abs(a.y - b.y))

proc `$`*(c: Coord): string =
  fmt"({c.x}, {c.y})"

# --- Rect Utilities ---

proc initRect*(x, y, w, h: int): Rect {.inline.} =
  Rect(x1: x, y1: y, x2: x + w - 1, y2: y + h - 1)

proc width*(r: Rect): int {.inline.} =
  r.x2 - r.x1 + 1

proc height*(r: Rect): int {.inline.} =
  r.y2 - r.y1 + 1

proc center*(r: Rect): Coord {.inline.} =
  Coord(x: (r.x1 + r.x2) div 2, y: (r.y1 + r.y2) div 2)

proc intersects*(a, b: Rect, padding: int = 1): bool {.inline.} =
  a.x1 - padding <= b.x2 and a.x2 + padding >= b.x1 and
  a.y1 - padding <= b.y2 and a.y2 + padding >= b.y1

proc contains*(r: Rect, c: Coord): bool {.inline.} =
  c.x >= r.x1 and c.x <= r.x2 and c.y >= r.y1 and c.y <= r.y2

# --- Entity Factory Helpers ---

proc initPlayer*(startPos: Coord, hp: int = PlayerInitialHp, maxHp: int = PlayerInitialMaxHp,
                attack: int = PlayerInitialAttack, defense: int = PlayerInitialDefense): Player =
  Player(
    pos: startPos,
    hp: hp,
    maxHp: maxHp,
    attack: attack,
    defense: defense,
    level: 1,
    xp: 0,
    xpToNextLevel: XpPerLevelBase,
    gold: 0,
    potions: PlayerInitialPotions,
    maxPotions: PlayerMaxPotions,
    floor: 1,
    score: 0,
    turns: 0,
    isAlive: true
  )

proc initEnemy*(id: int, pos: Coord, kind: EnemyKind, floorLevel: int = 1): Enemy =
  case kind
  of EkGoblin:
    let scaledHp = GoblinHp + (floorLevel - 1) * 5
    Enemy(
      id: id,
      pos: pos,
      kind: kind,
      name: "Goblin",
      glyph: 'E',
      hp: scaledHp,
      maxHp: scaledHp,
      attack: GoblinAttack + (floorLevel - 1) * 2,
      defense: GoblinDefense + (floorLevel - 1),
      xpValue: GoblinXp,
      speed: 2,
      aggroRadius: GoblinAggroRadius,
      isAlive: true
    )
  of EkSkeleton:
    let scaledHp = SkeletonHp + (floorLevel - 1) * 8
    Enemy(
      id: id,
      pos: pos,
      kind: kind,
      name: "Skeleton",
      glyph: 'E',
      hp: scaledHp,
      maxHp: scaledHp,
      attack: SkeletonAttack + (floorLevel - 1) * 3,
      defense: SkeletonDefense + (floorLevel - 1) * 2,
      xpValue: SkeletonXp,
      speed: 1,
      aggroRadius: SkeletonAggroRadius,
      isAlive: true
    )
  of EkOrc:
    let scaledHp = OrcHp + (floorLevel - 1) * 12
    Enemy(
      id: id,
      pos: pos,
      kind: kind,
      name: "Orc",
      glyph: 'E',
      hp: scaledHp,
      maxHp: scaledHp,
      attack: OrcAttack + (floorLevel - 1) * 4,
      defense: OrcDefense + (floorLevel - 1) * 2,
      xpValue: OrcXp,
      speed: 1,
      aggroRadius: OrcAggroRadius,
      isAlive: true
    )

proc initItem*(id: int, pos: Coord, kind: ItemKind, value: int): Item =
  Item(id: id, pos: pos, kind: kind, value: value)
