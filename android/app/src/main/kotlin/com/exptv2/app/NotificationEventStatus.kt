package com.exptv2.app

object NotificationEventStatus {
    const val ALL = "all"
    const val LINKED = "linked"
    const val MISSING = "missing"
    const val SYSTEM = "system"

    fun normalizeFilter(value: Any?): String = when (value?.toString()?.trim()?.lowercase()) {
        LINKED -> LINKED
        MISSING -> MISSING
        SYSTEM -> SYSTEM
        else -> ALL
    }

    fun forEvent(manualStatus: String, linkedTransactionId: Int?): String {
        return when {
            manualStatus == SYSTEM -> SYSTEM
            linkedTransactionId != null -> LINKED
            else -> MISSING
        }
    }

    fun matchesFilter(filter: String, status: String): Boolean = when (filter) {
        LINKED -> status == LINKED
        MISSING -> status == MISSING
        SYSTEM -> status == SYSTEM
        else -> true
    }

    fun displayText(status: String): String = when (status) {
        LINKED -> "Van tranzakció"
        SYSTEM -> "Rendszer"
        else -> "Nincs hozzárendelt log"
    }
}
