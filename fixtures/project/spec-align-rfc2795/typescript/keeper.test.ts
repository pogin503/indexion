import assert from "node:assert/strict"
import test from "node:test"

import {
  protocolNumbers,
  keeperRequestCodes,
  keeperResponseCodes,
  decodeITag,
  decodeImpsPacket,
  decodeKeeperMessage,
  encodeITag,
  encodeImpsPacket,
  encodeKeeperMessage,
  encodeChimpCommand,
  parseChimpCommand,
  encodeIambPentCommand,
  parseIambPentCommand,
  encodePanCommand,
  parsePanCommand,
  validKeeperResponsesFor,
  criticRejectCodes,
} from "./src/keeper.ts"

const keeperExchangeExample = [
  { from: "SanDiego", command: "STATUS", response: "ALIVE" },
  { from: "SanDiego", command: "WAKEUP", response: "ACCEPT" },
  { from: "SanDiego", command: "TRANSCRIPT", response: "ACCEPT" },
]

const chimpSessionExample = [
  "HELO CHIMP version 1.0 4/1/2000",
  "REPLACE PAPER",
  "ACCEPT",
  "TRANSCRIPT 87",
  "ACCEPT",
  "RECEIVED",
  "SEND FOOD",
  "ACCEPT",
  "SEND MEDICINE",
  "DELAY",
  "SEND VETERINARIAN",
  "REFUSE",
  "NOTIFY NORESPONSE",
  "ACCEPT",
  "NOTIFY DEAD",
  "ACCEPT",
  "REPLACE MONKEY",
  "ACCEPT",
]

const iambPentSessionExample = [
  "HARK now, what light through yonder window breaks?",
  "RECEIVETH TRANSCRIPT SanDiego.BoBo.17",
  "PRITHEE thy monkey's wisdom poureth forth!",
  "ANON 96",
  "REGRETTETH none hath writ thy words before",
  "ABORTETH Fate may one day bless my zone",
]

const panSessionExample = [
  "SIGH Abandon hope all who enter here",
  "COMPLIMENT We love your work.  Your words are like",
  "COMPLIMENT jewels and you are always correct.",
  "TRANSCRIPT RomeoAndJuliet.BoBo.763 251",
  "IMPRESS_ME",
  "REJECT 2 This will never, ever sell.",
  "THANKS",
  "DONT_CALL_US_WE'LL_CALL_YOU",
]

test("RFC 2795 I-TAG round-trip", () => {
  for (const value of [0n, 1n, 255n, 256n, 65535n, 2n ** 80n + 7n]) {
    const encoded = encodeITag(value)
    const decoded = decodeITag(encoded)
    assert.equal(decoded.value, value)
    assert.equal(decoded.bytesRead, encoded.length)
  }
})

test("RFC 2795 IMPS packet round-trip", () => {
  const keeper = encodeKeeperMessage({
    version: 1,
    type: 0,
    messageId: 7,
    messageCode: keeperRequestCodes.STATUS,
  })
  const encoded = encodeImpsPacket({
    version: protocolNumbers.impsVersion,
    sequenceNumber: 3,
    protocolNumber: protocolNumbers.keeper,
    reserved: 0,
    source: 0x10n,
    destination: 0x20n,
    data: keeper,
  })
  const packet = decodeImpsPacket(encoded)
  assert.equal(packet.version, protocolNumbers.impsVersion)
  assert.equal(packet.protocolNumber, protocolNumbers.keeper)
  assert.equal(packet.source, 0x10n)
  assert.equal(packet.destination, 0x20n)
  assert.deepEqual(Array.from(packet.data), Array.from(keeper))
})

test("RFC 2795 KEEPER response tables are enforced", () => {
  assert.deepEqual(validKeeperResponsesFor(keeperRequestCodes.STATUS), [
    keeperResponseCodes.ALIVE,
    keeperResponseCodes.DEAD,
    1,
    2,
    3,
    4,
  ])
  assert.deepEqual(validKeeperResponsesFor(keeperRequestCodes.TRANSCRIPT), [keeperResponseCodes.ACCEPT])
  const decoded = decodeKeeperMessage(
    encodeKeeperMessage({
      version: 1,
      type: 1,
      messageId: 99,
      messageCode: keeperResponseCodes.ACCEPT,
    }),
  )
  assert.equal(decoded.messageId, 99)
  assert.equal(decoded.messageCode, keeperResponseCodes.ACCEPT)
})

test("RFC 2795 textual protocol examples parse and re-encode", () => {
  for (const line of chimpSessionExample) {
    assert.equal(encodeChimpCommand(parseChimpCommand(line)), line.trim())
  }
  for (const line of iambPentSessionExample) {
    assert.equal(encodeIambPentCommand(parseIambPentCommand(line)), line.trim())
  }
  for (const line of panSessionExample) {
    assert.equal(encodePanCommand(parsePanCommand(line)), line.trim())
  }
})

test("RFC 2795 example data stays visible", () => {
  assert.equal(keeperExchangeExample.length, 3)
  assert.equal(criticRejectCodes.get(2), "This will never, ever sell.")
  assert.equal(protocolNumbers.pan, 10)
})
