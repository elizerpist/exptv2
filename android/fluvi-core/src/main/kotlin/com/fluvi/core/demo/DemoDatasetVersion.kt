package com.fluvi.core.demo

import java.nio.ByteBuffer
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.Random

object DemoDatasetVersion {
    // Version 2 adds the deterministic 2025 high-density diagnostic year.
    // The manifest version deliberately forces a complete deterministic reset
    // instead of mixing the old seven-month fixture with new entries.
    const val current = 2
    const val prngSeed = 2_026_010_7L
    const val localZoneId = "Europe/Budapest"
    val startInclusive: LocalDate = LocalDate.of(2025, 1, 1)
    val endExclusive: LocalDate = LocalDate.of(2026, 8, 1)
    // Preserve all pre-existing 2026 deterministic IDs while the data window
    // grows backwards for the high-density physical diagnostic fixture.
    val idTimestampEpoch: LocalDate = LocalDate.of(2026, 1, 1)
}
/** Small deterministic ULID producer for the immutable demo manifest. */
internal object DemoDeterministicUlid {
    private const val TIMESTAMP_CHARACTERS = 10
    private const val RANDOMNESS_CHARACTERS = 16
    private const val BITS_PER_BYTE = 8
    private const val BITS_PER_BASE32_CHARACTER = 5
    private const val BYTE_MASK = 0xff
    private const val BASE32_MASK = 31
    private const val RANDOMNESS_BYTES = 10
    private const val MAX_TIMESTAMP_MS = (1L shl 48) - 1L
    private const val CROCKFORD_BASE32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    fun id(namespace: Int, ordinal: Int): String {
        val baseTimestamp = DemoDatasetVersion.idTimestampEpoch
            .atStartOfDay()
            .toInstant(ZoneOffset.UTC)
            .toEpochMilli()
        val timestamp = baseTimestamp + namespace * 100_000L + ordinal
        require(timestamp in 0L..MAX_TIMESTAMP_MS)

        val random = Random(
            DemoDatasetVersion.prngSeed xor
                (namespace.toLong() shl 32) xor
                ordinal.toLong(),
        )
        val randomness = ByteArray(RANDOMNESS_BYTES)
        random.nextBytes(randomness)
        return encodeTimestamp(timestamp) + encodeRandomness(randomness)
    }

    private fun encodeTimestamp(timestamp: Long): String {
        val characters = CharArray(TIMESTAMP_CHARACTERS)
        var remainder = timestamp
        for (index in characters.lastIndex downTo 0) {
            characters[index] = CROCKFORD_BASE32[
                (remainder and BASE32_MASK.toLong()).toInt(),
            ]
            remainder = remainder ushr BITS_PER_BASE32_CHARACTER
        }
        return characters.concatToString()
    }

    private fun encodeRandomness(randomness: ByteArray): String {
        val encoded = StringBuilder(RANDOMNESS_CHARACTERS)
        var buffer = 0
        var bufferedBits = 0

        randomness.forEach { byte ->
            buffer = (buffer shl BITS_PER_BYTE) or (byte.toInt() and BYTE_MASK)
            bufferedBits += BITS_PER_BYTE
            while (bufferedBits >= BITS_PER_BASE32_CHARACTER) {
                bufferedBits -= BITS_PER_BASE32_CHARACTER
                encoded.append(
                    CROCKFORD_BASE32[(buffer ushr bufferedBits) and BASE32_MASK],
                )
                buffer = buffer and ((1 shl bufferedBits) - 1)
            }
        }

        check(bufferedBits == 0)
        return encoded.toString()
    }
}
