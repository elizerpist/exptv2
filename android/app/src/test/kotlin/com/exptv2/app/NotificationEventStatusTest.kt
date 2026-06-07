package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationEventStatusTest {
    @Test
    fun mapsFinalStatusTexts() {
        assertEquals("Van tranzakció", NotificationEventStatus.displayText(NotificationEventStatus.LINKED))
        assertEquals("Nincs hozzárendelt log", NotificationEventStatus.displayText(NotificationEventStatus.MISSING))
        assertEquals("Rendszer", NotificationEventStatus.displayText(NotificationEventStatus.SYSTEM))
    }

    @Test
    fun missingFilterExcludesSystemEvents() {
        assertTrue(NotificationEventStatus.matchesFilter(NotificationEventStatus.MISSING, NotificationEventStatus.MISSING))
        assertFalse(NotificationEventStatus.matchesFilter(NotificationEventStatus.MISSING, NotificationEventStatus.SYSTEM))
        assertTrue(NotificationEventStatus.matchesFilter(NotificationEventStatus.ALL, NotificationEventStatus.SYSTEM))
    }
}
