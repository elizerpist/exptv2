package com.fluvi.core.sync

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import java.util.Calendar
import java.util.GregorianCalendar
import java.util.TimeZone

internal data class LedgerSheetRow(
    val entryId: String,
    val bookedLocalEpochDay: Long,
    val bookingYear: Int,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val note: String?,
    val partnerId: String,
    val partnerDisplayName: String,
    val categoryId: String,
    val categoryName: String,
    val categoryAssignmentMode: CategoryAssignmentMode,
    val originKind: LedgerOriginKind,
    val revision: Long,
) {
    fun toPayloadJson(): String = buildString {
        append('{')
        appendJsonString("entryId", entryId)
        append(',')
        appendJsonNumber("bookedLocalEpochDay", bookedLocalEpochDay)
        append(',')
        appendJsonNumber("bookingYear", bookingYear.toLong())
        append(',')
        appendJsonNumber("bookedLocalTimeMinutes", bookedLocalTimeMinutes.toLong())
        append(',')
        appendJsonNumber("occurredAtUtcMs", occurredAtUtcMs)
        append(',')
        appendJsonString("direction", direction.name)
        append(',')
        appendJsonNumber("amountScaled100", amountScaled100)
        append(',')
        appendJsonNullableString("note", note)
        append(',')
        appendJsonString("partnerId", partnerId)
        append(',')
        appendJsonString("partnerDisplayName", partnerDisplayName)
        append(',')
        appendJsonString("categoryId", categoryId)
        append(',')
        appendJsonString("categoryName", categoryName)
        append(',')
        appendJsonString("categoryAssignmentMode", categoryAssignmentMode.name)
        append(',')
        appendJsonString("originKind", originKind.name)
        append(',')
        appendJsonNumber("revision", revision)
        append('}')
    }

    private fun StringBuilder.appendJsonString(
        name: String,
        value: String,
    ) {
        append('"')
        append(name)
        append("\":\"")
        append(value.jsonEscaped())
        append('"')
    }

    private fun StringBuilder.appendJsonNullableString(
        name: String,
        value: String?,
    ) {
        append('"')
        append(name)
        append("\":")
        if (value == null) {
            append("null")
        } else {
            append('"')
            append(value.jsonEscaped())
            append('"')
        }
    }

    private fun StringBuilder.appendJsonNumber(
        name: String,
        value: Long,
    ) {
        append('"')
        append(name)
        append("\":")
        append(value)
    }

    private fun String.jsonEscaped(): String = buildString {
        this@jsonEscaped.forEach { character ->
            when (character) {
                '\\' -> append("\\\\")
                '"' -> append("\\\"")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> append(character)
            }
        }
    }

    companion object {
        fun bookingYearFor(localEpochDay: Long): Int {
            val utcCalendar = GregorianCalendar(TimeZone.getTimeZone("UTC"))
            utcCalendar.timeInMillis = localEpochDay * MILLIS_PER_DAY
            return utcCalendar.get(Calendar.YEAR)
        }

        private const val MILLIS_PER_DAY = 86_400_000L
    }
}
