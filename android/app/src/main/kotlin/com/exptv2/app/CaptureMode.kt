package com.exptv2.app

enum class CaptureMode(val value: String) {
    NOTIFICATION_LISTENER("notification_listener"),
    ACCESSIBILITY("accessibility"),
    BOTH("both");

    fun allowsNotificationListener(): Boolean = this == NOTIFICATION_LISTENER || this == BOTH

    fun allowsAccessibility(): Boolean = this == ACCESSIBILITY || this == BOTH

    companion object {
        fun fromValue(value: String?): CaptureMode {
            return values().firstOrNull { it.value == value } ?: BOTH
        }
    }
}
