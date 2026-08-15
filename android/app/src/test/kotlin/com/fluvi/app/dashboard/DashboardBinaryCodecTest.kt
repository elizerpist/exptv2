package com.fluvi.app.dashboard

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.query.FluviDashboardLedgerRow
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviPreparedDashboardIndex
import com.fluvi.core.query.FluviPreparedDashboardIndexBuildMetrics
import com.fluvi.core.query.FluviPreparedDashboardIndexFrame
import com.fluvi.core.query.FluviPreparedDashboardGeometryDayBucket
import com.fluvi.core.query.FluviPreparedYearWindow
import com.fluvi.core.query.FluviTimelineCursor
import java.io.ByteArrayInputStream
import java.io.DataInputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DashboardBinaryCodecTest {
    @Test
    fun encodedGlobalIndexHasStableHeaderAndDeduplicatedRowTable() {
        val row = slice(
            "income|day:2026-06-15|categories:|partners:|refinements:",
            "day:2026-06-15",
            entryCount = 1L,
        ).entries.single()
        val index = FluviPreparedDashboardIndex(
            coreRevision = 3L,
            previewPageSize = 24,
            requestGeneration = 19L,
            yearWindow = FluviPreparedYearWindow(2025, 2027),
            rows = listOf(row),
            focusRows = listOf(row),
            frames = listOf(
                FluviPreparedDashboardIndexFrame(
                    queryKey = "income|all|categories:|partners:|refinements:",
                    direction = LedgerDirection.income,
                    timeScopeKey = "all",
                    totalMinor = 12_345L,
                    entryCount = 1L,
                    rowIndices = listOf(0),
                    nextCursor = null,
                ),
                FluviPreparedDashboardIndexFrame(
                    queryKey = "income|day:2026-06-15|categories:|partners:|refinements:",
                    direction = LedgerDirection.income,
                    timeScopeKey = "day:2026-06-15",
                    totalMinor = 12_345L,
                    entryCount = 1L,
                    rowIndices = listOf(0),
                    nextCursor = null,
                ),
            ),
            verticalGeometryBuckets = listOf(
                FluviPreparedDashboardGeometryDayBucket(
                    direction = LedgerDirection.income,
                    bookedLocalEpochDay = 20_000L,
                    entryCount = 1L,
                ),
            ),
            buildMetrics = FluviPreparedDashboardIndexBuildMetrics(
                sqlCallCount = 5,
                sqlDurationNanos = 500L,
                aggregateBucketCount = 1,
                scannedLedgerRowCount = 1,
                uniquePreviewRowCount = 1,
                frameCount = 2,
                queryDurationNanos = 1_000L,
                aggregationDurationNanos = 2_000L,
                mappingDurationNanos = 3_000L,
            ),
        )

        fun encodeDeterministically(): ByteArray {
            var now = 100L
            return DashboardBinaryCodec.encodePreparedIndex(index) {
                now.also { now += 5_000L }
            }
        }
        val first = encodeDeterministically()
        val second = encodeDeterministically()
        val input = DataInputStream(ByteArrayInputStream(first))

        assertArrayEquals(first, second)
        assertEquals(DashboardBinaryCodec.INDEX_MAGIC, input.readInt())
        assertEquals(DashboardBinaryCodec.INDEX_VERSION, input.readInt())
        assertEquals(19L, input.readLong())
        assertEquals(3L, input.readLong())
        assertEquals(24, input.readInt())
        assertEquals(2025, input.readInt())
        assertEquals(2027, input.readInt())
        assertEquals(5, input.readInt())
        assertEquals(1, input.readInt())
        assertEquals(1, input.readInt())
        assertEquals(1, input.readInt())
        assertEquals(2, input.readInt())
        assertEquals(500L, input.readLong())
        assertEquals(1_000L, input.readLong())
        assertEquals(2_000L, input.readLong())
        assertEquals(3_000L, input.readLong())
        assertEquals(5_000L, input.readLong())
        assertEquals(1, input.readInt())
        assertEquals("income", input.readLengthPrefixedUtf8())
        assertEquals(20_000L, input.readLong())
        assertEquals(1L, input.readLong())
        assertEquals(1, input.readInt())
        // The source-native full base membership follows the bounded preview
        // row table. It enables ephemeral focus without changing the SQL call
        // shape or making a pointer gesture read Room.
        input.skipDashboardRow()
        assertEquals(1, input.readInt())
        assertTrue(first.size < 8_192)
    }

    @Test
    fun encodedCommittedPageEchoesExactGenerationEpochRevisionAndParent() {
        val parentKey = "income|month:2026-06|categories:|partners:|refinements:"
        val childKey = "income|day:2026-06-15|categories:|partners:|refinements:"
        val payload = DashboardBinaryCodec.encodeCommittedPage(
            slice = slice(childKey, "day:2026-06-15", entryCount = 1L),
            parentQueryKey = parentKey,
            presentationEpoch = 23L,
            commitGeneration = 41L,
        )
        val input = DataInputStream(ByteArrayInputStream(payload))

        assertEquals(DashboardBinaryCodec.PAGE_MAGIC, input.readInt())
        assertEquals(DashboardBinaryCodec.VERSION, input.readInt())
        assertEquals(41L, input.readLong())
        assertEquals(23L, input.readLong())
        assertEquals(3L, input.readLong())
        assertEquals(parentKey, input.readLengthPrefixedUtf8())
        assertEquals(childKey, input.readLengthPrefixedUtf8())
        assertTrue(payload.size < 8_192)
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

    private fun DataInputStream.skipDashboardRow() {
        repeat(10) { readLengthPrefixedUtf8() }
        readLong()
        readLong()
        readInt()
        val noteBytes = readInt()
        if (noteBytes >= 0) skipBytes(noteBytes)
        readLong()
    }
}
