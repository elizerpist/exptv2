package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Test

class NotificationEventEntityTest {
    @Test
    fun eventMapIncludesManualStatus() {
        val row = NotificationEventEntity(
            id = 10L,
            timestamp = 1780858800000L,
            source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
            packageName = "hu.bank.app",
            appLabel = "Bank",
            title = "Vásárlás",
            text = "Kártyás vásárlás: Tesco - 12 345 HUF",
            bigText = "",
            subText = "",
            category = "",
            notificationKey = "n-10",
            accessibilityEventType = "",
            hash = "abc",
            isDuplicate = false,
            manualStatus = NotificationEventStatus.SYSTEM,
        )

        val map = row.toMap()

        assertEquals(NotificationEventStatus.SYSTEM, map["manualStatus"])
    }
}
