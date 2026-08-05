package com.fluvi.app.dashboard

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviDashboardLedgerRow
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviPreparedChildFrame
import com.fluvi.core.query.FluviPreparedDeck
import com.fluvi.core.query.FluviPreparedDeckBuildMetrics
import com.fluvi.core.query.FluviTimelineCursor
import java.io.ByteArrayInputStream
import java.io.DataInputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DashboardBinaryCodecTest {
    @Test
    fun encodedDeckHasStableMagicVersionAndDeterministicBytes() {
        val deck = fixture()
        val first = DashboardBinaryCodec.encodeDeck(deck)
        val second = DashboardBinaryCodec.encodeDeck(deck)
        val input = DataInputStream(ByteArrayInputStream(first))

        assertArrayEquals(first, second)
        assertEquals(DashboardBinaryCodec.MAGIC, input.readInt())
        assertEquals(DashboardBinaryCodec.VERSION, input.readInt())
        assertEquals(17L, input.readLong())
        assertEquals(3L, input.readLong())
        assertEquals(deck.parentQueryKey, input.readLengthPrefixedUtf8())
        assertEquals("income", input.readLengthPrefixedUtf8())
        assertEquals("day", input.readLengthPrefixedUtf8())
        assertEquals(24, input.readInt())
        assertTrue(first.size < 8_192)
    }

    @Test
    fun encodedFrameEchoesExactLeaseEpochRevisionAndParent() {
        val parentKey = "income|month:2026-06|categories:|partners:|refinements:"
        val childKey = "income|day:2026-06-15|categories:|partners:|refinements:"
        val payload = DashboardBinaryCodec.encodeFrame(
            slice = slice(childKey, "day:2026-06-15", entryCount = 1L),
            parentQueryKey = parentKey,
            presentationEpoch = 23L,
            leaseGeneration = 41L,
        )
        val input = DataInputStream(ByteArrayInputStream(payload))

        assertEquals(DashboardBinaryCodec.FRAME_MAGIC, input.readInt())
        assertEquals(DashboardBinaryCodec.VERSION, input.readInt())
        assertEquals(41L, input.readLong())
        assertEquals(23L, input.readLong())
        assertEquals(3L, input.readLong())
        assertEquals(parentKey, input.readLengthPrefixedUtf8())
        assertEquals(childKey, input.readLengthPrefixedUtf8())
        assertTrue(payload.size < 8_192)
    }

    private fun fixture(): FluviPreparedDeck {
        val parentKey = "income|month:2026-06|categories:|partners:|refinements:"
        val parent = slice(parentKey, "month:2026-06", entryCount = 1L)
        val childKey = "income|day:2026-06-15|categories:|partners:|refinements:"
        return FluviPreparedDeck(
            parentQueryKey = parentKey,
            direction = LedgerDirection.income,
            childPeriodKind = QueryPeriodKind.day,
            coreRevision = 3L,
            previewPageSize = 24,
            requestGeneration = 17L,
            parentSlice = parent,
            children = listOf(
                FluviPreparedChildFrame(
                    childPeriodValue = "2026-06-15",
                    slice = slice(childKey, "day:2026-06-15", entryCount = 1L),
                ),
            ),
            buildMetrics = FluviPreparedDeckBuildMetrics(
                sqlCallCount = 6,
                aggregateBucketCount = 1,
                scannedLedgerRowCount = 1,
                materializedPreviewRowCount = 2,
                queryDurationNanos = 10L,
                mappingDurationNanos = 20L,
            ),
        )
    }

    private fun slice(
        key: String,
        timeKey: String,
        entryCount: Long,
    ) = FluviDashboardLedgerSlice(
        queryKey = key,
        coreRevision = 3L,
        direction = LedgerDirection.income,
        timeScopeKey = timeKey,
        totalMinor = 12_345L,
        entryCount = entryCount,
        entries = listOf(
            FluviDashboardLedgerRow(
                entryId = "entry-1",
                direction = LedgerDirection.income,
                amountMinor = 12_345L,
                bookedLocalEpochDay = 20_000L,
                bookedLocalTimeMinutes = 600,
                occurredAtUtcMs = 1_700_000_000_000L,
                partnerId = "partner-1",
                partnerDisplayName = "Árvíztűrő Partner",
                categoryId = "category-1",
                categoryDisplayName = "Kategória",
                categoryColorId = "color_02",
                categoryIconId = "icon_02",
                assignmentMode = CategoryAssignmentMode.partnerDefault,
                originKind = LedgerOriginKind.manual,
                note = "tükörfúrógép",
            ),
        ),
        nextCursor = FluviTimelineCursor(20_000L, 600, "entry-1"),
    )

    private fun DataInputStream.readLengthPrefixedUtf8(): String {
        val length = readInt()
        val bytes = ByteArray(length)
        readFully(bytes)
        return bytes.toString(Charsets.UTF_8)
    }
}
