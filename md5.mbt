///|
/// This package is based on the Go implementation found here:
/// https://cs.opensource.google/go/go/+/refs/tags/go1.23.0:src/crypto/md5/md5.go
/// which has the copyright notice:
/// Copyright 2009 The Go Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style
/// license that can be found in the LICENSE file.

// The size of an MD5 checksum in bytes.
let size = 16

///|
// The blocksize of MD5 in bytes.
let block_size = 64

///|
let init0 = 0x67452301U

///|
let init1 = 0xEFCDAB89U

///|
let init2 = 0x98BADCFEU

///|
let init3 = 0x10325476U

///|
/// `Digest` represents the partial evaluation of a checksum.
struct Digest {
  s : FixedArray[UInt] // 4
  x : FixedArray[Byte] // block_size
  mut nx : Int
  mut len : UInt64
  // workaround to get rid of compiler warning:
  // See: https://discord.com/channels/1135479745207869510/1272985768498958387/1275082247484997693
  name : String
}

///|
/// `Digest::new` returns a new, reset Digest, ready to sum.
pub fn Digest::new() -> Digest {
  {
    s: FixedArray::from_array([init0, init1, init2, init3]),
    x: FixedArray::make(block_size, b'\x00'),
    nx: 0,
    len: 0,
    // workaround to get rid of compiler warning:
    name: "md5",
  }
}

///|
let _trait : &HashFunc = Digest::new()

///|
pub impl HashFunc for Digest with name(self) {
  self.name
}

///|
/// `check_sum` returns the final md5sum as a hex string.
pub impl HashFunc for Digest with check_sum(self) {
  // Append 0x80 to the end of the message and then append zeros
  // until the length is a multiple of 56 bytes. Finally append
  // 8 bytes representing the message length in bits.
  //
  // 1 byte end marker :: 0-63 padding bytes :: 8 byte length
  let tmp = FixedArray::make(1 + 63 + 8, b'\x00')
  tmp[0] = b'\x80'
  let pad = ((55UL - self.len) % block_size.to_int64().reinterpret_as_uint64()).to_int() // calculate number of padding bytes
  le_put_uint64(tmp, 1 + pad, self.len << 3) // append length in bits
  for i = 0; i < 1 + pad + 8; i = i + 1 {
    self.write(tmp[i])
  }

  // The previous write ensures that a whole number of
  // blocks (i.e. a multiple of 64 bytes) have been hashed.
  if self.nx != 0 {
    panic()
  }

  // Generate digest
  let digest = FixedArray::make(size, b'\x00')
  le_put_uint32(digest, 0, self.s[0])
  le_put_uint32(digest, 4, self.s[1])
  le_put_uint32(digest, 8, self.s[2])
  le_put_uint32(digest, 12, self.s[3])
  let result = @buffer.new(size_hint=2 * size)
  for b in digest {
    result.write_char(to_hex((b.to_int() >> 4) & 0xf))
    result.write_char(to_hex(b.to_int() & 0xf))
  }
  result.contents().to_unchecked_string()
}

///|
/// `reset` resets a digest for re-use.
pub fn reset(self : Digest) -> Unit {
  self.s[0] = init0
  self.s[1] = init1
  self.s[2] = init2
  self.s[3] = init3
  self.nx = 0
  self.len = 0
}

///|
/// `write` writes a byte to the digest.
pub impl HashFunc for Digest with write(self, b) {
  self.len += 1
  self.x[self.nx] = b
  self.nx += 1
  if self.nx == block_size {
    self.block_generic()
    self.nx = 0
  }
}

///|
fn block_generic(self : Digest) -> Unit {
  // load state
  let mut a = self.s[0]
  let mut b = self.s[1]
  let mut c = self.s[2]
  let mut d = self.s[3]

  // save current state
  let q = self.x

  // load input block
  let x0 = le_uint32(q, 4 * 0x0)
  let x1 = le_uint32(q, 4 * 0x1)
  let x2 = le_uint32(q, 4 * 0x2)
  let x3 = le_uint32(q, 4 * 0x3)
  let x4 = le_uint32(q, 4 * 0x4)
  let x5 = le_uint32(q, 4 * 0x5)
  let x6 = le_uint32(q, 4 * 0x6)
  let x7 = le_uint32(q, 4 * 0x7)
  let x8 = le_uint32(q, 4 * 0x8)
  let x9 = le_uint32(q, 4 * 0x9)
  let xa = le_uint32(q, 4 * 0xa)
  let xb = le_uint32(q, 4 * 0xb)
  let xc = le_uint32(q, 4 * 0xc)
  let xd = le_uint32(q, 4 * 0xd)
  let xe = le_uint32(q, 4 * 0xe)
  let xf = le_uint32(q, 4 * 0xf)

  // round 1
  a = b + rotl((((c ^ d) & b) ^ d) + a + x0 + 0xd76aa478, 7)
  d = a + rotl((((b ^ c) & a) ^ c) + d + x1 + 0xe8c7b756, 12)
  c = d + rotl((((a ^ b) & d) ^ b) + c + x2 + 0x242070db, 17)
  b = c + rotl((((d ^ a) & c) ^ a) + b + x3 + 0xc1bdceee, 22)
  a = b + rotl((((c ^ d) & b) ^ d) + a + x4 + 0xf57c0faf, 7)
  d = a + rotl((((b ^ c) & a) ^ c) + d + x5 + 0x4787c62a, 12)
  c = d + rotl((((a ^ b) & d) ^ b) + c + x6 + 0xa8304613, 17)
  b = c + rotl((((d ^ a) & c) ^ a) + b + x7 + 0xfd469501, 22)
  a = b + rotl((((c ^ d) & b) ^ d) + a + x8 + 0x698098d8, 7)
  d = a + rotl((((b ^ c) & a) ^ c) + d + x9 + 0x8b44f7af, 12)
  c = d + rotl((((a ^ b) & d) ^ b) + c + xa + 0xffff5bb1, 17)
  b = c + rotl((((d ^ a) & c) ^ a) + b + xb + 0x895cd7be, 22)
  a = b + rotl((((c ^ d) & b) ^ d) + a + xc + 0x6b901122, 7)
  d = a + rotl((((b ^ c) & a) ^ c) + d + xd + 0xfd987193, 12)
  c = d + rotl((((a ^ b) & d) ^ b) + c + xe + 0xa679438e, 17)
  b = c + rotl((((d ^ a) & c) ^ a) + b + xf + 0x49b40821, 22)

  // round 2
  a = b + rotl((((b ^ c) & d) ^ c) + a + x1 + 0xf61e2562, 5)
  d = a + rotl((((a ^ b) & c) ^ b) + d + x6 + 0xc040b340, 9)
  c = d + rotl((((d ^ a) & b) ^ a) + c + xb + 0x265e5a51, 14)
  b = c + rotl((((c ^ d) & a) ^ d) + b + x0 + 0xe9b6c7aa, 20)
  a = b + rotl((((b ^ c) & d) ^ c) + a + x5 + 0xd62f105d, 5)
  d = a + rotl((((a ^ b) & c) ^ b) + d + xa + 0x02441453, 9)
  c = d + rotl((((d ^ a) & b) ^ a) + c + xf + 0xd8a1e681, 14)
  b = c + rotl((((c ^ d) & a) ^ d) + b + x4 + 0xe7d3fbc8, 20)
  a = b + rotl((((b ^ c) & d) ^ c) + a + x9 + 0x21e1cde6, 5)
  d = a + rotl((((a ^ b) & c) ^ b) + d + xe + 0xc33707d6, 9)
  c = d + rotl((((d ^ a) & b) ^ a) + c + x3 + 0xf4d50d87, 14)
  b = c + rotl((((c ^ d) & a) ^ d) + b + x8 + 0x455a14ed, 20)
  a = b + rotl((((b ^ c) & d) ^ c) + a + xd + 0xa9e3e905, 5)
  d = a + rotl((((a ^ b) & c) ^ b) + d + x2 + 0xfcefa3f8, 9)
  c = d + rotl((((d ^ a) & b) ^ a) + c + x7 + 0x676f02d9, 14)
  b = c + rotl((((c ^ d) & a) ^ d) + b + xc + 0x8d2a4c8a, 20)

  // round 3
  a = b + rotl((b ^ c ^ d) + a + x5 + 0xfffa3942, 4)
  d = a + rotl((a ^ b ^ c) + d + x8 + 0x8771f681, 11)
  c = d + rotl((d ^ a ^ b) + c + xb + 0x6d9d6122, 16)
  b = c + rotl((c ^ d ^ a) + b + xe + 0xfde5380c, 23)
  a = b + rotl((b ^ c ^ d) + a + x1 + 0xa4beea44, 4)
  d = a + rotl((a ^ b ^ c) + d + x4 + 0x4bdecfa9, 11)
  c = d + rotl((d ^ a ^ b) + c + x7 + 0xf6bb4b60, 16)
  b = c + rotl((c ^ d ^ a) + b + xa + 0xbebfbc70, 23)
  a = b + rotl((b ^ c ^ d) + a + xd + 0x289b7ec6, 4)
  d = a + rotl((a ^ b ^ c) + d + x0 + 0xeaa127fa, 11)
  c = d + rotl((d ^ a ^ b) + c + x3 + 0xd4ef3085, 16)
  b = c + rotl((c ^ d ^ a) + b + x6 + 0x04881d05, 23)
  a = b + rotl((b ^ c ^ d) + a + x9 + 0xd9d4d039, 4)
  d = a + rotl((a ^ b ^ c) + d + xc + 0xe6db99e5, 11)
  c = d + rotl((d ^ a ^ b) + c + xf + 0x1fa27cf8, 16)
  b = c + rotl((c ^ d ^ a) + b + x2 + 0xc4ac5665, 23)

  // round 4
  a = b + rotl((c ^ (b | d.lnot())) + a + x0 + 0xf4292244, 6)
  d = a + rotl((b ^ (a | c.lnot())) + d + x7 + 0x432aff97, 10)
  c = d + rotl((a ^ (d | b.lnot())) + c + xe + 0xab9423a7, 15)
  b = c + rotl((d ^ (c | a.lnot())) + b + x5 + 0xfc93a039, 21)
  a = b + rotl((c ^ (b | d.lnot())) + a + xc + 0x655b59c3, 6)
  d = a + rotl((b ^ (a | c.lnot())) + d + x3 + 0x8f0ccc92, 10)
  c = d + rotl((a ^ (d | b.lnot())) + c + xa + 0xffeff47d, 15)
  b = c + rotl((d ^ (c | a.lnot())) + b + x1 + 0x85845dd1, 21)
  a = b + rotl((c ^ (b | d.lnot())) + a + x8 + 0x6fa87e4f, 6)
  d = a + rotl((b ^ (a | c.lnot())) + d + xf + 0xfe2ce6e0, 10)
  c = d + rotl((a ^ (d | b.lnot())) + c + x6 + 0xa3014314, 15)
  b = c + rotl((d ^ (c | a.lnot())) + b + xd + 0x4e0811a1, 21)
  a = b + rotl((c ^ (b | d.lnot())) + a + x4 + 0xf7537e82, 6)
  d = a + rotl((b ^ (a | c.lnot())) + d + xb + 0xbd3af235, 10)
  c = d + rotl((a ^ (d | b.lnot())) + c + x2 + 0x2ad7d2bb, 15)
  b = c + rotl((d ^ (c | a.lnot())) + b + x9 + 0xeb86d391, 21)

  // save state
  self.s[0] += a
  self.s[1] += b
  self.s[2] += c
  self.s[3] += d
}

///|
fn le_uint32(b : FixedArray[Byte], offset : Int) -> UInt {
  b[offset].to_uint() |
  (b[offset + 1].to_uint() << 8) |
  (b[offset + 2].to_uint() << 16) |
  (b[offset + 3].to_uint() << 24)
}

///|
fn le_put_uint32(b : FixedArray[Byte], offset : Int, value : UInt) -> Unit {
  b[offset] = (value & 0xff).to_byte()
  b[offset + 1] = ((value >> 8) & 0xff).to_byte()
  b[offset + 2] = ((value >> 16) & 0xff).to_byte()
  b[offset + 3] = ((value >> 24) & 0xff).to_byte()
}

///|
fn le_put_uint64(b : FixedArray[Byte], offset : Int, value : UInt64) -> Unit {
  le_put_uint32(b, offset, (value & 0xffffffff).to_uint())
  le_put_uint32(b, offset + 4, ((value >> 32) & 0xffffffff).to_uint())
}

///|
fn rotl(x : UInt, r : Int) -> UInt {
  (x << r) | (x >> (32 - r))
}

///|
fn to_hex(v : Int) -> Char {
  if v < 10 {
    Int::unsafe_to_char(v + b'0'.to_int())
  } else {
    Int::unsafe_to_char(v - 10 + b'a'.to_int())
  }
}

///|
test "le_uint32 works" {
  let tests = [
    (FixedArray::from_array([b'\x00', b'\x00', b'\x00', b'\x00']), 0U),
    (FixedArray::from_array([b'\x80', b'\x00', b'\x00', b'\x00']), 128U),
    (FixedArray::from_array([b'\x00', b'\x01', b'\x00', b'\x00']), 256U),
    (FixedArray::from_array([b'\x00', b'\x00', b'\x00', b'\x01']), 16777216U),
    (FixedArray::from_array([b'\x12', b'\x34', b'\x56', b'\x78']), 0x78563412U),
  ]
  for tt in tests {
    let got = le_uint32(tt.0, 0)
    assert_eq(got, tt.1)
  }
}
