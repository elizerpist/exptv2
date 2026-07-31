package com.fluvi.core.model

import java.security.SecureRandom

fun interface FluviClock {
    fun nowUtcMs(): Long
}

object SystemFluviClock : FluviClock {
    override fun nowUtcMs(): Long = System.currentTimeMillis()
}

interface FluviIdGenerator {
    fun next(): String
}

class MonotonicUlidGenerator(
    private val clock: FluviClock = SystemFluviClock,
    private val secureRandom: SecureRandom = SecureRandom(),
) : FluviIdGenerator {
    private var lastTimestampMs = -1L
    private var lastRandomness = ByteArray(RANDOMNESS_BYTES)

    @Synchronized
    override fun next(): String {
        val requestedTimestamp = clock.nowUtcMs()
        require(requestedTimestamp in 0L..MAX_TIMESTAMP_MS) {
            "ULID timestamp must fit in 48 bits."
        }

        when {
            requestedTimestamp > lastTimestampMs -> {
                lastTimestampMs = requestedTimestamp
                secureRandom.nextBytes(lastRandomness)
            }

            !incrementRandomness() -> {
                check(lastTimestampMs < MAX_TIMESTAMP_MS) {
                    "Cannot advance a ULID beyond its 48-bit timestamp range."
                }
                lastTimestampMs += 1L
                secureRandom.nextBytes(lastRandomness)
            }
        }

        return encodeTimestamp(lastTimestampMs) + encodeRandomness(lastRandomness)
    }

    private fun incrementRandomness(): Boolean {
        for (index in lastRandomness.lastIndex downTo 0) {
            val incremented = (lastRandomness[index].toInt() and BYTE_MASK) + 1
            lastRandomness[index] = incremented.toByte()
            if (incremented <= BYTE_MASK) {
                return true
            }
        }
        return false
    }

    private fun encodeTimestamp(timestampMs: Long): String {
        val characters = CharArray(TIMESTAMP_CHARACTERS)
        var remainder = timestampMs
        for (index in characters.lastIndex downTo 0) {
            characters[index] = CROCKFORD_BASE32[(remainder and BASE32_MASK.toLong()).toInt()]
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
                    CROCKFORD_BASE32[
                        (buffer ushr bufferedBits) and BASE32_MASK
                    ],
                )
                buffer = buffer and ((1 shl bufferedBits) - 1)
            }
        }

        check(bufferedBits == 0)
        return encoded.toString()
    }

    private companion object {
        const val RANDOMNESS_BYTES = 10
        const val TIMESTAMP_CHARACTERS = 10
        const val RANDOMNESS_CHARACTERS = 16
        const val BITS_PER_BYTE = 8
        const val BITS_PER_BASE32_CHARACTER = 5
        const val BYTE_MASK = 0xff
        const val BASE32_MASK = 31
        const val MAX_TIMESTAMP_MS = (1L shl 48) - 1L
        const val CROCKFORD_BASE32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    }
}

object FluviSystemIds {
    const val APP_SETTINGS = "00000000000000000000000000"
    const val UNCATEGORIZED_CATEGORY = "00000000000000000000000001"
}
