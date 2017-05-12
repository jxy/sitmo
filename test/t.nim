import sitmo
import unittest

suite "Examples from sitmo.com, 2016.":
  const
    r4 = [3871888695u32, 153194173u32, 1725456645u32, 1435770706u32]
    r4s1 = [1931275270u32, 145858287u32, 3604276868u32, 3225543903u32]
    r4j1b = [4180604479u32, 2052014422u32, 3686059349u32, 1479291871u32]
  test "The first 4 random numbers of the default engine.":
    var r = newsitmo()
    check:
      r4[0] == r.random
      r4[1] == r.random
      r4[2] == r.random
      r4[3] == r.random
  test "Two independent streams.":
    var
      r0 = newsitmo()
      r1 = newsitmo()
    r0.seed(0)
    r1.seed(1)
    check:
      r4[0] == r0.random
      r4s1[0] == r1.random
      r4[1] == r0.random
      r4s1[1] == r1.random
      r4[2] == r0.random
      r4s1[2] == r1.random
      r4[3] == r0.random
      r4s1[3] == r1.random
  test "Jump ahead 1 billion steps.":
    var r = newsitmo()
    r.skip 1_000_000_000
    check:
      r4j1b[0] == r.random
      r4j1b[1] == r.random
      r4j1b[2] == r.random
      r4j1b[3] == r.random

suite "Example in README.":
  test "Seed and skips":
    var r = newsitmo()
    r.seed(0x7FFFFFFFu32)
    check(4101761533u32 == r.random)
    r.skip(0xFFFFFFFFFFFFFFFFu64)
    check(526043833u32 == r.random)
  test "more skips":
    const r1 = [432240764u32, 394603845u32, 1589956428u32, 2240764439u32, 4029191793u32,
                1322152998u32, 2012435544u32, 3343011544u32, 3996448858u32, 1019691118u32]
    var r = newsitmo()
    r.seed(1337)
    check(r1[0] == r.random)
    r.skip(1)
    check(r1[1] == r.random)
    r.skip(1)
    check(r1[2] == r.random)
    r.skip(1)
    check(r1[3] == r.random)
    r.skip(1)
    check(r1[4] == r.random)
    r.skip(1)
    check(r1[5] == r.random)
    r.skip(1)
    check(r1[6] == r.random)
    r.skip(1)
    check(r1[7] == r.random)
    r.skip(1)
    check(r1[8] == r.random)
    r.skip(1 shl 51)
    check(r1[9] == r.random)
