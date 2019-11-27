#[
Copyright (C) 2017 Xiao-Yong Jin

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]#

##[
This module implements the Sitmo parallel random number generator
in Nim.

Here is the description of the original C++ implementation from
Sitmo:

  The implementation is based on a paper by John Salmon and Mark
  Moraes and described in their paper “Parallel Random Numbers:
  As Easy as 1, 2, 3”. (Proceedings of 2011 International
  Conference for High Performance Computing, Networking, Storage
  and Analysis). The algorithm is based on the Threefish
  cryptographic cipher.

This RNG engine is usable for large scale parallel processing:
1. O(1) and neglect-able skip ahead cost for block and
   leap-frogging parallelism.
2. 32 bit seed offers 2^32 (4 billion) parallel random streams of
   length 2^256.
3. Streams are guaranteed to be non-overlapping.
]##

template mix2(x0,x1:var uint64; rx:SomeInteger;
              z0,z1:var uint64; rz:SomeInteger):auto =
  const
    x = 64 - rx
    z = 64 - rz
  x0 += x1
  z0 += z1
  x1 = (x1 shl rx) or (x1 shr x)
  z1 = (z1 shl rz) or (z1 shr z)
  x1 = x1 xor x0
  z1 = z1 xor z0
template mixk(x0,x1:var uint64; rx:SomeInteger;
              z0,z1:var uint64; rz:SomeInteger;
              k0,k1,l0,l1:uint64):auto =
  const
    x = 64 - rx
    z = 64 - rz
  x1 += k1
  z1 += l1
  x0 += x1+k0
  z0 += z1+l0
  x1 = (x1 shl rx) or (x1 shr x)
  z1 = (z1 shl rz) or (z1 shr z)
  x1 = x1 xor x0
  z1 = z1 xor z0

type sitmo* = object
  ## The `sitmo` object contains the state of the RNG.
  s*,k*,o*: array[4,uint64]
  oCounter*: uint16

proc encryptCounter(r:var sitmo) =
  var
    b0 = r.s[0]
    b1 = r.s[1]
    b2 = r.s[2]
    b3 = r.s[3]
  let
    k0 = r.k[0]
    k1 = r.k[1]
    k2 = r.k[2]
    k3 = r.k[3]
    k4 = 0x1BD11BDAA9FC1A22u64 xor k0 xor k1 xor k2 xor k3
  mixk(b0, b1, 14,   b2, b3, 16,   k0, k1, k2, k3)
  mix2(b0, b3, 52,   b2, b1, 57)
  mix2(b0, b1, 23,   b2, b3, 40)
  mix2(b0, b3,  5,   b2, b1, 37)
  mixk(b0, b1, 25,   b2, b3, 33,   k1, k2, k3, k4+1)
  mix2(b0, b3, 46,   b2, b1, 12)
  mix2(b0, b1, 58,   b2, b3, 22)
  mix2(b0, b3, 32,   b2, b1, 32)

  mixk(b0, b1, 14,   b2, b3, 16,   k2, k3, k4, k0+2)
  mix2(b0, b3, 52,   b2, b1, 57)
  mix2(b0, b1, 23,   b2, b3, 40)
  mix2(b0, b3,  5,   b2, b1, 37)
  mixk(b0, b1, 25,   b2, b3, 33,   k3, k4, k0, k1+3)

  mix2(b0, b3, 46,   b2, b1, 12)
  mix2(b0, b1, 58,   b2, b3, 22)
  mix2(b0, b3, 32,   b2, b1, 32)

  mixk(b0, b1, 14,   b2, b3, 16,   k4, k0, k1, k2+4)
  mix2(b0, b3, 52,   b2, b1, 57)
  mix2(b0, b1, 23,   b2, b3, 40)
  mix2(b0, b3,  5,   b2, b1, 37)
  r.o[0] = b0 + k0
  r.o[1] = b1 + k1
  r.o[2] = b2 + k2
  r.o[3] = b3 + k3 + 5
proc incCounter(r:var sitmo) =
  r.s[0].inc
  if r.s[0] != 0: return
  r.s[1].inc
  if r.s[1] != 0: return
  r.s[2].inc
  if r.s[2] != 0: return
  r.s[3].inc
proc incCounter(r:var sitmo, z:uint64) =
  if z > not r.s[0]:
    r.s[1].inc
    if r.s[1] == 0:
      r.s[2].inc
      if r.s[2] == 0:
        r.s[3].inc
  r.s[0] += z

proc seed*(r:var sitmo) =
  ## Seed the RNG `r` with the default seed.
  for i in 0..3:
    r.k[i] = 0
    r.s[i] = 0
  r.oCounter = 0
  r.o[0] = 0x09218ebde6c85537u64;
  r.o[1] = 0x55941f5266d86105u64;
  r.o[2] = 0x4bd25e16282434dcu64;
  r.o[3] = 0xee29ec846bd2e40bu64;
proc seed*(r:var sitmo, s:uint32) =
  ## Seed the RNG `r` with seed `s`.
  for i in 0..3:
    r.k[i] = 0
    r.s[i] = 0
  r.k[0] = s
  r.oCounter = 0
  r.encryptCounter
proc newsitmo*:sitmo =
  ## Creates an pseudo RNG engine with default seed
  result.seed
proc newsitmo*(s:uint32):sitmo =
  ## Creates an pseudo RNG engine with seed `s`
  result.seed(s)
proc newsitmo*(r:sitmo):sitmo =
  ## Creates an pseudo RNG engine that is a replica of `r`
  for i in 0..3:
    result.s[i] = r.s[i]
    result.k[i] = r.k[i]
    result.o[i] = r.o[i]
  result.oCounter = r.oCounter
proc random*(r:var sitmo):uint32 =
  ## Advanced the state of the RNG, `r`, and return a random `uint32`.
  # Can we return a value from the current block?
  if r.oCounter < 8:
    let i:uint16 = r.oCounter shr 1
    r.oCounter.inc
    if (r.oCounter and 1) > 0u16: return uint32(r.o[i] and 0xFFFFFFFFu64)
    else: return uint32(r.o[i] shr 32)
  # Generate a new block and return the first 32 bits.
  r.incCounter
  r.encryptCounter
  r.oCounter = 1
  return uint32(r.o[0] and 0xFFFFFFFFu64)
proc skip*(r:var sitmo, z:uint64) =
  ## Advance the state of the RNG, `r`, equivalent to `z` consecutive calls of `random`.
  var z = z
  let c = 8u16 - r.oCounter # Left over of the current block (No underflow for oCounter <= 8)
  # Check if we stay in the current block
  if z < c:
    r.oCounter += z.uint16
    return
  # We will have to generate a new block
  z -= c                       # Discard the remainder of the current block
  r.oCounter = uint16(z and 7) # Set the pointer in the correct element in the new block
  z -= r.oCounter              # Update z
  z = z shr 3                  # The number of buffers is elements/8
  inc z                        # and one more because we crossed the buffer line
  r.incCounter z
  r.encryptCounter
proc `==`*(x,y:sitmo):bool =
  ## Compare the state of RNGs, `x` and `y`.  Return true if they are the same.
  if x.oCounter != y.oCounter: return false
  for i in 0..3:
    if x.s[i] != y.s[i]: return false
    if x.k[i] != y.k[i]: return false
    if x.o[i] != y.o[i]: return false
  return true
template `!=`*(x,y:sitmo):bool =
  ## Compare the state of RNGs, `x` and `y`.  Return true if they are different.
  not x==y
proc setKey*(r:var sitmo, k0,k1,k2,k3:uint64 = 0) =
  ## Set the key of the sitmo RNG, `r`.
  r.k[0] = k0
  r.k[1] = k1
  r.k[2] = k2
  r.k[3] = k3
  r.encryptCounter
proc setCounter*(r:var sitmo, s0,s1,s2,s3:uint64 = 0; oCounter:uint16 = 0) =
  ## Set the counter of the sitmo RNG, `r`.
  r.s[0] = s0
  r.s[1] = s1
  r.s[2] = s2
  r.s[3] = s3
  r.oCounter = oCounter and 7
  r.encryptCounter
