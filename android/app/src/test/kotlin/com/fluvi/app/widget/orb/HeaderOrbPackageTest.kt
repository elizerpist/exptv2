package com.fluvi.app.widget.orb

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class HeaderOrbPackageTest {
    private fun packet(epoch: String = "cb86eab5-478a-48d7-a1c8-cfbfd8da6c29", count: Int = 3, motion: Boolean = count > 1) =
        HeaderOrbPackage(
            "f".repeat(64), epoch, "a089c54f-cc75-463a-ba05-e520c31ed85d",
            OrbFramePlan(48, count, 33, phaseOriginUtcMs = 1000L),
            motion,
            List(count) { byteArrayOf(it.toByte()) },
        )

    @Test
    fun balanceKeepsAuthorityOrderedFramesAndPhaseAfterRecreation() {
        val original = packet()
        val read = HeaderOrbPackage.read(original.encode())
        assertEquals(original.epoch, read.epoch)
        assertEquals(original.generation, read.generation)
        assertEquals(original.plan, read.plan)
        assertEquals(2, read.plan.initialFrameIndex(1066))
        original.pngs.zip(read.pngs).forEach { (before, after) ->
            assertArrayEquals(before, after)
        }
        assertThrows(IllegalArgumentException::class.java) { packet("mind") }
        assertThrows(IllegalArgumentException::class.java) { packet("budget") }
    }

    @Test
    fun rejectsTruncatedCorruptAndInconsistentPackages() {
        val encoded = packet().encode()
        assertThrows(IllegalArgumentException::class.java) { HeaderOrbPackage.read(encoded.copyOf(encoded.size - 1)) }
        encoded[12] = 8
        assertThrows(IllegalArgumentException::class.java) { HeaderOrbPackage.read(encoded) }
        assertThrows(IllegalArgumentException::class.java) { packet(count = 1, motion = true) }
        assertThrows(IllegalArgumentException::class.java) { packet(count = 175) }
    }

    @Test
    fun staticSelectionHasOnePersistentFrame() {
        val read = HeaderOrbPackage.read(packet(count = 1).encode())
        assertEquals(false, read.animated)
        assertEquals(0, read.plan.initialFrameIndex(88723))
    }
}
