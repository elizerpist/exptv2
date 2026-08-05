package com.fluvi.app.dashboard

import com.fluvi.core.query.FluviDashboardLedgerRow
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviPreparedDeck
import com.fluvi.core.query.FluviTimelineCursor
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.nio.charset.StandardCharsets

/** Versioned bounded binary transport for complete prepared dashboard decks. */
object DashboardBinaryCodec {
    const val MAGIC: Int = 0x464C444B // FLDK
    const val FRAME_MAGIC: Int = 0x464C534C // FLSL
    const val VERSION: Int = 1

    fun encodeDeck(deck: FluviPreparedDeck): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(MAGIC)
            output.writeInt(VERSION)
            output.writeLong(deck.requestGeneration)
            output.writeLong(deck.coreRevision)
            output.writeUtf8(deck.parentQueryKey)
            output.writeUtf8(deck.direction.name)
            output.writeUtf8(deck.childPeriodKind.name)
            output.writeInt(deck.previewPageSize)
            output.writeInt(deck.buildMetrics.sqlCallCount)
            output.writeInt(deck.buildMetrics.aggregateBucketCount)
            output.writeInt(deck.buildMetrics.scannedLedgerRowCount)
            output.writeInt(deck.buildMetrics.materializedPreviewRowCount)
            output.writeLong(deck.buildMetrics.queryDurationNanos)
            output.writeLong(deck.buildMetrics.mappingDurationNanos)
            output.writeSlice(deck.parentSlice)
            output.writeInt(deck.children.size)
            deck.children.forEach { child ->
                output.writeUtf8(child.childPeriodValue)
                output.writeSlice(child.slice)
            }
        }
        return bytes.toByteArray()
    }

    fun encodeFrame(
        slice: FluviDashboardLedgerSlice,
        parentQueryKey: String,
        presentationEpoch: Long,
        leaseGeneration: Long,
    ): ByteArray {
        require(slice.coreRevision > 0L) { "A live frame requires a seeded revision." }
        require(parentQueryKey.isNotBlank()) { "A live frame requires a parent key." }
        require(presentationEpoch >= 0L)
        require(leaseGeneration > 0L)
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { output ->
            output.writeInt(FRAME_MAGIC)
            output.writeInt(VERSION)
            output.writeLong(leaseGeneration)
            output.writeLong(presentationEpoch)
            output.writeLong(slice.coreRevision)
            output.writeUtf8(parentQueryKey)
            output.writeSlice(slice)
        }
        return bytes.toByteArray()
    }

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
}
