import assert from "node:assert/strict"
import test from "node:test"

import {
  adapt,
  decodePunycode,
  decodePunycodeLabel,
  encodePunycode,
  encodePunycodeLabel,
  overflowHandling,
  sampleStrings,
} from "./src/punycode.ts"

test("RFC 3492 sample strings round-trip", () => {
  for (const sample of sampleStrings) {
    assert.equal(encodePunycode(sample.unicode), sample.ascii, sample.name)
    assert.equal(decodePunycode(sample.ascii), sample.unicode, sample.name)
  }
})

test("RFC 3492 ACE label helpers round-trip", () => {
  const sample = sampleStrings[1]
  const label = encodePunycodeLabel(sample.unicode)
  assert.equal(label, `xn--${sample.ascii}`)
  assert.equal(decodePunycodeLabel(label), sample.unicode)
})

test("RFC 3492 bias adaptation and threshold remain stable", () => {
  assert.equal(adapt(0, 1, true), 0)
  assert.equal(overflowHandling.maxInt, 0x7fffffff)
  assert.equal(overflowHandling.aceMaxLength, 256)
  assert.ok(adapt(1200, 10, false) > 0)
})

test("RFC 3492 overflow guards reject oversized labels", () => {
  assert.throws(() => encodePunycode("a".repeat(64)), RangeError)
})
