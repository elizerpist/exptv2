package com.fluvi.core.pulse

import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.abs

/** Locale-safe Hungarian rendering kept separate from financial calculation. */
object PulseHungarianFormatter {
    private val symbols = DecimalFormatSymbols(Locale("hu", "HU")).apply {
        groupingSeparator = ' '
        decimalSeparator = ','
    }
    private val money = DecimalFormat("#,##0", symbols)
    private val decimal = DecimalFormat("#,##0.#", symbols)
    private val date = DateTimeFormatter.ofPattern("yyyy. MMMM d.", Locale("hu", "HU"))

    fun money(minor: Long): String {
        val sign = if (minor < 0) "−" else ""
        return "$sign${money.format(abs(minor) / 100L)} Ft"
    }

    fun percent(value: Double): String = "${decimal.format(value)}%"
    fun ratio(value: Double): String = "${decimal.format(value)}×"

    fun relativeDate(epochDay: Long, nowUtcMs: Long, zoneId: String): String {
        val today = Instant.ofEpochMilli(nowUtcMs).atZone(ZoneId.of(zoneId)).toLocalDate()
        val value = LocalDate.ofEpochDay(epochDay)
        return when (value.toEpochDay() - today.toEpochDay()) {
            0L -> "ma"
            1L -> "holnap"
            2L -> "két nap múlva"
            -1L -> "tegnap"
            else -> date.format(value)
        }
    }

    fun days(value: Int): String = when (value) {
        0 -> "ma"
        1 -> "1 nap"
        else -> "$value nap"
    }
}
