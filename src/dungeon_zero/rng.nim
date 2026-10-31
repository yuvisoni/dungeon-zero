## DUNGEON ZERO - Deterministic Seeded Random Number Generator
## Module: dungeon_zero/rng

import std/[random]

type
  GameRng* = object
    seed*: int64
    inner*: Rand

proc initGameRng*(seed: int64): GameRng =
  ## Initializes a deterministic PRNG using the given 64-bit seed.
  result = GameRng(
    seed: seed,
    inner: initRand(seed)
  )

proc nextInt*(rng: var GameRng, maxVal: int): int {.inline.} =
  ## Returns an integer in range [0, maxVal]
  rng.inner.rand(maxVal)

proc nextRange*(rng: var GameRng, minVal, maxVal: int): int {.inline.} =
  ## Returns an integer in range [minVal, maxVal]
  if minVal >= maxVal:
    return minVal
  minVal + rng.inner.rand(maxVal - minVal)

proc nextFloat*(rng: var GameRng): float {.inline.} =
  ## Returns a float in range [0.0, 1.0)
  rng.inner.rand(1.0)

proc nextBool*(rng: var GameRng, probability: float = 0.5): bool {.inline.} =
  ## Returns true with given probability
  rng.nextFloat() < probability

proc rollDice*(rng: var GameRng, count, sides: int): int =
  ## Simulates rolling NdX dice (e.g., 2d6)
  result = 0
  for _ in 0 ..< count:
    result += rng.nextRange(1, sides)

proc choice*[T](rng: var GameRng, items: openArray[T]): T =
  ## Selects a random element from non-empty items
  assert items.len > 0, "Cannot choose from an empty array"
  let idx = rng.nextRange(0, items.len - 1)
  items[idx]

proc shuffle*[T](rng: var GameRng, items: var seq[T]) =
  ## Fisher-Yates in-place shuffle
  for i in countdown(items.high, 1):
    let j = rng.nextRange(0, i)
    swap(items[i], items[j])
