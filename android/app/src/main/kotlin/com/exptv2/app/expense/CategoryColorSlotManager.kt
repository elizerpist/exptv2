package com.exptv2.app.expense

object CategoryColorSlotManager {
    private const val FALLBACK_HEX = "#64748b"

    private val colors = mapOf(
        0 to "#ef4444",
        1 to "#f97316",
        2 to "#eab308",
        3 to "#84cc16",
        4 to "#22c55e",
        5 to "#10b981",
        6 to "#06b6d4",
        7 to "#0ea5e9",
        8 to "#3b82f6",
        9 to "#6366f1",
        10 to "#8b5cf6",
        11 to "#a855f7",
        12 to "#d946ef",
        13 to "#ec4899",
        14 to "#f43f5e",
        15 to "#6b7280",
        16 to "#374151",
        17 to "#1f2937",
        18 to "#064e3b",
        19 to "#7c2d12",
        20 to "#4c1d95",
    )

    fun colorForSlot(slot: Int?): String = colors[slot] ?: FALLBACK_HEX
}
