package com.exptv2.app.expense

object RecurringTriggerType {
    const val DATE = "date"
    const val PUSH = "push"

    fun normalize(value: String?): String = when (value?.trim()?.lowercase()) {
        PUSH -> PUSH
        else -> DATE
    }
}
