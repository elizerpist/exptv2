package com.fluvi.app.dashboard

import com.fluvi.core.query.FluviDashboardLedgerRow
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviPreparedDashboardIndex
import com.fluvi.core.query.FluviTimelineCursor
import com.fluvi.core.query.FluviPreparedBudgetLimitSnapshot
import com.fluvi.core.query.FluviPreparedBudgetRhythmDirectionBank
import com.fluvi.core.query.FluviPreparedBudgetPartnerDistributionSnapshot
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.StandardCharsets

/** Versioned bounded binary transport for the global index and explicit pages. */
object DashboardBinaryCodec {
    const val PAGE_MAGIC: Int = 0x464C534C // FLSL
    const val INDEX_MAGIC: Int = 0x464C4449 // FLDI
    const val BUDGET_LIMIT_MAGIC: Int = 0x464C424C // FLBL
    const val BUDGET_LIMIT_VERSION: Int = 3
    const val BUDGET_PARTNER_MAGIC: Int = 0x464C4250 // FLBP
    const val BUDGET_PARTNER_VERSION: Int = 2
    const val INDEX_VERSION: Int = 5
    const val VERSION: Int = 1

    /**
     * Encodes the one session-wide sparse dashboard index. Rows are written
     * once and frames reference them by integer index, so a row shared by its
     * all/year/month/day scopes does not cross the bridge four times.
     */
    fun encodePreparedIndex(
        index: FluviPreparedDashboardIndex,
        nanoTime: () -> Long = { System.nanoTime() },
    ): ByteArray {
        val serializationStartedAtNanos = nanoTime()
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(INDEX_MAGIC)
            output.writeInt(INDEX_VERSION)
            output.writeLong(index.requestGeneration)
            output.writeLong(index.coreRevision)
            output.writeInt(index.previewPageSize)
            output.writeInt(index.yearWindow.startYear)
            output.writeInt(index.yearWindow.endYearInclusive)
            output.writeInt(index.buildMetrics.sqlCallCount)
            output.writeInt(index.buildMetrics.aggregateBucketCount)
            output.writeInt(index.buildMetrics.scannedLedgerRowCount)
            output.writeInt(index.buildMetrics.uniquePreviewRowCount)
            output.writeInt(index.buildMetrics.frameCount)
            output.writeLong(index.buildMetrics.sqlDurationNanos)
            output.writeLong(index.buildMetrics.queryDurationNanos)
            output.writeLong(index.buildMetrics.aggregationDurationNanos)
            output.writeLong(index.buildMetrics.mappingDurationNanos)
            output.writeLong(0L)
            output.writeInt(index.verticalGeometryBuckets.size)
            index.verticalGeometryBuckets.forEach { bucket ->
                output.writeUtf8(bucket.direction.name)
                output.writeLong(bucket.bookedLocalEpochDay)
                output.writeLong(bucket.entryCount)
            }
            output.writeInt(index.rows.size)
            index.rows.forEach { row -> output.writeRow(row) }
            output.writeInt(index.focusRows.size)
            index.focusRows.forEach { row -> output.writeRow(row) }
            output.writeInt(index.frames.size)
            index.frames.forEach { frame ->
                output.writeUtf8(frame.queryKey)
                output.writeUtf8(frame.timeScopeKey)
                output.writeUtf8(frame.direction.name)
                output.writeLong(frame.totalMinor)
                output.writeLong(frame.entryCount)
                output.writeInt(frame.rowIndices.size)
                frame.rowIndices.forEach { rowIndex -> output.writeInt(rowIndex) }
                output.writeCursor(frame.nextCursor)
            }
        }
        val payload = bytes.toByteArray()
        val durationNanos = (nanoTime() - serializationStartedAtNanos).coerceAtLeast(0L)
        ByteBuffer.wrap(payload)
            .order(ByteOrder.BIG_ENDIAN)
            .putLong(INDEX_SERIALIZATION_DURATION_OFFSET, durationNanos)
        return payload
    }

    /** Dense, query-independent exact-revision Budget actual/limit bank. */
    fun encodePreparedBudgetLimitSnapshot(
        snapshot: FluviPreparedBudgetLimitSnapshot,
    ): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(BUDGET_LIMIT_MAGIC)
            output.writeInt(BUDGET_LIMIT_VERSION)
            output.writeLong(snapshot.coreRevision)
            output.writeInt(snapshot.yearWindow.startYear)
            output.writeInt(snapshot.yearWindow.endYearInclusive)
            output.writeInt(snapshot.sqlCallCount)
            output.writeLong(snapshot.sqlDurationNanos)
            output.writeBudgetDirectionBank(snapshot.incomeBank)
            output.writeBudgetDirectionBank(snapshot.expenseBank)
            output.writeBudgetRhythmDirectionBank(snapshot.rhythmSnapshot.incomeBank)
            output.writeBudgetRhythmDirectionBank(snapshot.rhythmSnapshot.expenseBank)
        }
        return bytes.toByteArray()
    }

    private fun DataOutputStream.writeBudgetDirectionBank(
        bank: com.fluvi.core.query.FluviPreparedBudgetDirectionBank,
    ) {
        writeInt(bank.orderedCategoryIds.size)
        bank.orderedCategoryIds.forEach { categoryId -> writeUtf8(categoryId) }
        writeInt(bank.actualScaled100.size)
        bank.actualScaled100.forEach(::writeLong)
        writeInt(bank.limitScaled100.size)
        bank.limitScaled100.forEach(::writeLong)
    }

    private fun DataOutputStream.writeBudgetRhythmDirectionBank(
        bank: FluviPreparedBudgetRhythmDirectionBank,
    ) {
        writeInt(bank.targetCount)
        writeInt(bank.targetOffsets.size)
        bank.targetOffsets.forEach(::writeInt)
        writeInt(bank.points.size)
        bank.points.forEach { point ->
            writeLong(point.epochDay)
            writeLong(point.actualScaled100)
        }
    }

    /** Dense, query-independent exact-revision partner distribution bank. */
    fun encodePreparedBudgetPartnerDistributionSnapshot(
        snapshot: FluviPreparedBudgetPartnerDistributionSnapshot,
    ): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(BUDGET_PARTNER_MAGIC)
            output.writeInt(BUDGET_PARTNER_VERSION)
            output.writeLong(snapshot.coreRevision)
            output.writeInt(snapshot.yearWindow.startYear)
            output.writeInt(snapshot.yearWindow.endYearInclusive)
            output.writeInt(snapshot.sqlCallCount)
            output.writeLong(snapshot.sqlDurationNanos)
            output.writeBudgetPartnerDirectionBank(snapshot.incomeBank)
            output.writeBudgetPartnerDirectionBank(snapshot.expenseBank)
        }
        return bytes.toByteArray()
    }

    private fun DataOutputStream.writeBudgetPartnerDirectionBank(
        bank: com.fluvi.core.query.FluviPreparedBudgetPartnerDistributionDirectionBank,
    ) {
        writeInt(bank.orderedPartnerIds.size)
        bank.orderedPartnerIds.forEach { partnerId -> writeUtf8(partnerId) }
        bank.orderedPartnerTitles.forEach { partnerTitle -> writeUtf8(partnerTitle) }
        writeInt(bank.cells.size)
        bank.cells.forEach { cell -> writeLong(cell.actualScaled100) }
        writeInt(bank.cells.size)
        bank.cells.forEach { cell -> writeUtf8(cell.dominantCategoryId) }
        writeInt(bank.orderedCategoryIds.size)
        bank.orderedCategoryIds.forEach { categoryId -> writeUtf8(categoryId) }
        writeInt(bank.categoryContributionOffsets.size)
        bank.categoryContributionOffsets.forEach(::writeInt)
        writeInt(bank.categoryContributions.size)
        bank.categoryContributions.forEach { contribution ->
            writeInt(contribution.partnerHandle)
            writeLong(contribution.actualScaled100)
        }
    }

    private fun encodePageEnvelope(
        slice: FluviDashboardLedgerSlice,
        parentQueryKey: String,
        presentationEpoch: Long,
        commitGeneration: Long,
    ): ByteArray {
        require(slice.coreRevision > 0L) { "A page requires a seeded revision." }
        require(parentQueryKey.isNotBlank()) { "A page requires a parent key." }
        require(presentationEpoch >= 0L)
        require(commitGeneration > 0L)
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(PAGE_MAGIC)
            output.writeInt(VERSION)
            output.writeLong(commitGeneration)
            output.writeLong(presentationEpoch)
            output.writeLong(slice.coreRevision)
            output.writeUtf8(parentQueryKey)
            output.writeSlice(slice)
        }
        return bytes.toByteArray()
    }

    fun encodeCommittedPage(
        slice: FluviDashboardLedgerSlice,
        parentQueryKey: String,
        presentationEpoch: Long,
        commitGeneration: Long,
    ): ByteArray = encodePageEnvelope(
        slice = slice,
        parentQueryKey = parentQueryKey,
        presentationEpoch = presentationEpoch,
        commitGeneration = commitGeneration,
    )

    private fun DataOutputStream.writeSlice(slice: FluviDashboardLedgerSlice) {
        writeUtf8(slice.queryKey)
        writeUtf8(slice.timeScopeKey)
        writeUtf8(slice.direction.name)
        writeLong(slice.totalMinor)
        writeLong(slice.entryCount)
        writeInt(slice.entries.size)
        slice.entries.forEach { row -> writeRow(row) }
        writeCursor(slice.nextCursor)
    }

    private fun DataOutputStream.writeRow(row: FluviDashboardLedgerRow) {
        writeUtf8(row.entryId)
        writeUtf8(row.partnerId)
        writeUtf8(row.partnerDisplayName)
        writeUtf8(row.categoryId)
        writeUtf8(row.categoryDisplayName)
        writeUtf8(row.categoryColorId)
        writeUtf8(row.categoryIconId)
        writeUtf8(row.assignmentMode.name)
        writeUtf8(row.originKind.name)
        writeUtf8(row.direction.name)
        writeLong(row.amountMinor)
        writeLong(row.bookedLocalEpochDay)
        writeInt(row.bookedLocalTimeMinutes)
        writeNullableUtf8(row.note)
        writeLong(row.occurredAtUtcMs)
    }

    private fun DataOutputStream.writeCursor(cursor: FluviTimelineCursor?) {
        writeBoolean(cursor != null)
        if (cursor == null) return
        writeLong(cursor.bookedLocalEpochDay)
        writeInt(cursor.bookedLocalTimeMinutes)
        writeUtf8(cursor.entryId)
    }

    private fun DataOutputStream.writeUtf8(value: String) {
        val encoded = value.toByteArray(StandardCharsets.UTF_8)
        require(encoded.size <= MAX_STRING_BYTES) { "Dashboard string is too large." }
        writeInt(encoded.size)
        write(encoded)
    }

    private fun DataOutputStream.writeNullableUtf8(value: String?) {
        if (value == null) {
            writeInt(-1)
        } else {
            writeUtf8(value)
        }
    }

    private const val MAX_STRING_BYTES = 1 shl 20
    private const val INDEX_SERIALIZATION_DURATION_OFFSET = 88
}
