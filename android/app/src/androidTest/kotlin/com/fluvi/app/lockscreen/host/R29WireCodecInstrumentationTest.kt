package com.fluvi.app.lockscreen.host

import android.os.BadParcelableException
import android.os.Parcel
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.fluvi.r29.contract.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class R29WireCodecInstrumentationTest {
    private val now = 1_700_000_000_000L
    private val portal = R29Portal(false, 0, 0f, 0f, 50f, 68f, false, 0f, List(12) { 0f })
    private val material = R29Material("dualTide", 1, .3f, 1f, 1f,
        listOf(0xff123456.toInt(), 0xffabcdef.toInt()), listOf(0f, 1f), 1f, 50f,
        List(40) { 0f }, portal, portal, 1080f, 2400f)
    private val descriptor = R29Descriptor("0123456789abcdef0123456789abcdef", 1, 1, 7, 3, 4, 5,
        now - 1_000, now + 60_000, 0, 0, 1080, 2400, 420, 168, .5f, .8f,
        R29Disclosure.FULL, true, material, R29Motion.STATIC, R29Period.MONTH, "Europe/Budapest")

    private fun assertBadParcel(block: () -> Unit) {
        try {
            block()
            fail("expected BadParcelableException")
        } catch (_: BadParcelableException) {
            // Expected: malformed or oversized wire input never becomes a descriptor.
        }
    }

    @Test fun typedRoundTripPreservesTheCompleteBoundedDescriptor() {
        val parcel = Parcel.obtain()
        try {
            R29WireCodec.writeDescriptor(parcel, descriptor)
            assertTrue(parcel.dataSize() < R29Protocol.MAX_PARCEL_BYTES)
            parcel.setDataPosition(0)
            val decoded = R29WireCodec.readDescriptor(parcel)
            assertEquals(descriptor, decoded)
            assertNull(R29Protocol.invalidReason(decoded, now, parcel.dataSize()))
        } finally { parcel.recycle() }
    }

    @Test fun trailingAndOversizeParcelsAreRejected() {
        val trailing = Parcel.obtain()
        val oversized = Parcel.obtain()
        try {
            R29WireCodec.writeDescriptor(trailing, descriptor)
            trailing.writeInt(42)
            trailing.setDataPosition(0)
            assertBadParcel { R29WireCodec.readDescriptor(trailing) }
            oversized.writeByteArray(ByteArray(R29Protocol.MAX_PARCEL_BYTES + 1))
            oversized.setDataPosition(0)
            assertBadParcel { R29WireCodec.readDescriptor(oversized) }
        } finally { trailing.recycle(); oversized.recycle() }
    }

    @Test fun invalidArrayCountIsRejectedBeforeAllocating() {
        val bad = Parcel.obtain()
        try {
            // The malformed palette count follows the fixed prefix.
            val position = Parcel.obtain()
            try {
                R29WireCodec.writeDescriptor(position, descriptor)
                val raw = position.marshall()
                bad.unmarshall(raw, 0, raw.size)
            } finally { position.recycle() }
            bad.setDataPosition(0)
            bad.readInt(); bad.readString()
            repeat(8) { bad.readLong() }
            repeat(6) { bad.readInt() }
            repeat(2) { bad.readFloat() }
            repeat(4) { bad.readInt() }
            bad.readString(); bad.readInt(); bad.readInt(); bad.readString(); bad.readString(); bad.readInt()
            repeat(3) { bad.readFloat() }
            val paletteCountOffset = bad.dataPosition()
            bad.writeInt(Int.MAX_VALUE)
            bad.setDataPosition(0)
            assertBadParcel { R29WireCodec.readDescriptor(bad) }
            assertTrue(paletteCountOffset > 0)
        } finally { bad.recycle() }
    }
}
