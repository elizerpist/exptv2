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
import com.fluvi.core.query.FluviPreparedBudgetDirectionBank
import com.fluvi.core.query.FluviPreparedBudgetLimitSnapshot
import com.fluvi.core.query.FluviPreparedBudgetRhythmDirectionBank
import com.fluvi.core.query.FluviPreparedBudgetRhythmPoint
import com.fluvi.core.query.FluviPreparedBudgetRhythmSnapshot
import com.fluvi.core.query.FluviPreparedBudgetPartnerDistributionCell
import com.fluvi.core.query.FluviPreparedBudgetPartnerCategoryContribution
import com.fluvi.core.query.FluviPreparedBudgetPartnerDayCell
import com.fluvi.core.query.FluviPreparedBudgetPartnerDistributionDirectionBank
import com.fluvi.core.query.FluviPreparedBudgetPartnerDistributionSnapshot
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
    fun encodedPartnerDistributionPreservesTwoDirectionDenseBanks() {
        val cells = List(14) { index ->
            FluviPreparedBudgetPartnerDistributionCell(
                actualScaled100 = if (index == 2) 600L else 0L,
                dominantCategoryId = if (index == 2) "food" else "",
            )
        }
        val snapshot = FluviPreparedBudgetPartnerDistributionSnapshot(
            coreRevision = 9L,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            incomeBank = FluviPreparedBudgetPartnerDistributionDirectionBank(
                orderedPartnerIds = listOf("employer"),
                orderedPartnerTitles = listOf("Employer"),
                cells = cells,
                orderedCategoryIds = listOf("food"),
                categoryContributionOffsets = contributionOffsets(),
                categoryContributions = listOf(
                    FluviPreparedBudgetPartnerCategoryContribution(0, 600L),
                ),
                dayEpochDays = longArrayOf(20_000L),
                dayAggregateOffsets = intArrayOf(0, 1),
                dayAggregateCells = listOf(
                    FluviPreparedBudgetPartnerDayCell(0, 600L, "food"),
                ),
                dayCategoryContributionOffsets = intArrayOf(0, 1),
                dayCategoryContributions = listOf(
                    FluviPreparedBudgetPartnerCategoryContribution(0, 600L),
                ),
            ),
            expenseBank = FluviPreparedBudgetPartnerDistributionDirectionBank(
                orderedPartnerIds = listOf("shop"),
                orderedPartnerTitles = listOf("Bolt"),
                cells = cells,
                orderedCategoryIds = listOf("food"),
                categoryContributionOffsets = contributionOffsets(),
                categoryContributions = listOf(
                    FluviPreparedBudgetPartnerCategoryContribution(0, 600L),
                ),
                dayEpochDays = longArrayOf(20_000L),
                dayAggregateOffsets = intArrayOf(0, 1),
                dayAggregateCells = listOf(
                    FluviPreparedBudgetPartnerDayCell(0, 600L, "food"),
                ),
                dayCategoryContributionOffsets = intArrayOf(0, 1),
                dayCategoryContributions = listOf(
                    FluviPreparedBudgetPartnerCategoryContribution(0, 600L),
                ),
            ),
            sqlCallCount = 4,
            sqlDurationNanos = 2_000L,
        )

        val input = DataInputStream(
            ByteArrayInputStream(
                DashboardBinaryCodec.encodePreparedBudgetPartnerDistributionSnapshot(snapshot),
            ),
        )

        assertEquals(DashboardBinaryCodec.BUDGET_PARTNER_MAGIC, input.readInt())
        assertEquals(DashboardBinaryCodec.BUDGET_PARTNER_VERSION, input.readInt())
        assertEquals(9L, input.readLong())
        assertEquals(2026, input.readInt())
        assertEquals(2026, input.readInt())
        assertEquals(4, input.readInt())
        assertEquals(2_000L, input.readLong())
        assertPartnerBank(input, "employer", "Employer")
        assertPartnerBank(input, "shop", "Bolt")
        assertEquals(0, input.available())
    }

    @Test
    fun encodedBudgetSnapshotPreservesTwoDirectionLocalTargetBanks() {
        val snapshot = FluviPreparedBudgetLimitSnapshot(
            coreRevision = 9L,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            incomeBank = budgetBank("salary", actual = 20L, limit = 100L),
            expenseBank = budgetBank("rent", actual = 80L, limit = 100L),
            rhythmSnapshot = FluviPreparedBudgetRhythmSnapshot(
                coreRevision = 9L,
                incomeBank = rhythmBank(20L),
                expenseBank = rhythmBank(80L),
            ),
            sqlCallCount = 4,
            sqlDurationNanos = 2_000L,
        )
        val input = DataInputStream(
            ByteArrayInputStream(DashboardBinaryCodec.encodePreparedBudgetLimitSnapshot(snapshot)),
        )

        assertEquals(DashboardBinaryCodec.BUDGET_LIMIT_MAGIC, input.readInt())
        assertEquals(3, input.readInt())
        assertEquals(9L, input.readLong())
        assertEquals(2026, input.readInt())
        assertEquals(2026, input.readInt())
        assertEquals(4, input.readInt())
        assertEquals(2_000L, input.readLong())
        assertBudgetBank(input, "salary", 20L, 100L)
        assertBudgetBank(input, "rent", 80L, 100L)
        assertRhythmBank(input, 20L)
        assertRhythmBank(input, 80L)
        assertEquals(0, input.available())
    }

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

    private fun budgetBank(
        categoryId: String,
        actual: Long,
        limit: Long,
    ): FluviPreparedBudgetDirectionBank {
        val cells = LongArray(28)
        val limits = LongArray(28) { -1L }
        // 14 period slices * (aggregate + one category); month January is
        // slice 2 and category handle 1, proving the dense bank layout.
        cells[5] = actual
        limits[5] = limit
        return FluviPreparedBudgetDirectionBank(
            orderedCategoryIds = listOf(categoryId),
            actualScaled100 = cells,
            limitScaled100 = limits,
        )
    }

    private fun assertBudgetBank(
        input: DataInputStream,
        categoryId: String,
        actual: Long,
        limit: Long,
    ) {
        assertEquals(1, input.readInt())
        assertEquals(categoryId, input.readLengthPrefixedUtf8())
        assertEquals(28, input.readInt())
        val actuals = LongArray(28) { input.readLong() }
        assertEquals(actual, actuals[5])
        assertEquals(28, input.readInt())
        val limits = LongArray(28) { input.readLong() }
        assertEquals(limit, limits[5])
    }

    private fun rhythmBank(value: Long): FluviPreparedBudgetRhythmDirectionBank =
        FluviPreparedBudgetRhythmDirectionBank(
            targetCount = 2,
            targetOffsets = intArrayOf(0, 1, 1),
            points = listOf(FluviPreparedBudgetRhythmPoint(20_000L, value)),
        )

    private fun assertRhythmBank(input: DataInputStream, value: Long) {
        assertEquals(2, input.readInt())
        assertEquals(3, input.readInt())
        assertArrayEquals(intArrayOf(0, 1, 1), IntArray(3) { input.readInt() })
        assertEquals(1, input.readInt())
        assertEquals(20_000L, input.readLong())
        assertEquals(value, input.readLong())
    }

    private fun contributionOffsets(): IntArray = IntArray(15) { index ->
        if (index >= 3) 1 else 0
    }

    private fun assertPartnerBank(
        input: DataInputStream,
        partnerId: String,
        title: String,
    ) {
        assertEquals(1, input.readInt())
        assertEquals(partnerId, input.readLengthPrefixedUtf8())
        assertEquals(title, input.readLengthPrefixedUtf8())
        assertEquals(14, input.readInt())
        val amounts = LongArray(14) { input.readLong() }
        assertEquals(600L, amounts[2])
        assertEquals(14, input.readInt())
        val dominant = List(14) { input.readLengthPrefixedUtf8() }
        assertEquals("food", dominant[2])
        assertEquals(1, input.readInt())
        assertEquals("food", input.readLengthPrefixedUtf8())
        assertEquals(15, input.readInt())
        val offsets = IntArray(15) { input.readInt() }
        assertEquals(0, offsets[0])
        assertEquals(1, offsets[3])
        assertEquals(1, input.readInt())
        assertEquals(0, input.readInt())
        assertEquals(600L, input.readLong())
        assertEquals(1, input.readInt())
        assertEquals(20_000L, input.readLong())
        assertEquals(2, input.readInt())
        assertArrayEquals(intArrayOf(0, 1), IntArray(2) { input.readInt() })
        assertEquals(1, input.readInt())
        assertEquals(0, input.readInt())
        assertEquals(600L, input.readLong())
        assertEquals("food", input.readLengthPrefixedUtf8())
        assertEquals(2, input.readInt())
        assertArrayEquals(intArrayOf(0, 1), IntArray(2) { input.readInt() })
        assertEquals(1, input.readInt())
        assertEquals(0, input.readInt())
        assertEquals(600L, input.readLong())
    }

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
