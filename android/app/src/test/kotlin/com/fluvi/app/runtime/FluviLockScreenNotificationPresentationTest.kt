package com.fluvi.app.runtime

import android.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FluviLockScreenNotificationPresentationTest {
    private val balance = FluviLockScreenCardContent(
        focus = "Balance · Hónap",
        primary = "−11 000 Ft",
        secondary = "Hónap nettó",
        event = "−9 800 Ft · Lidl · 14:32",
        eventLabel = "Utolsó kapcsolódó tétel",
        accentColor = Color.rgb(180, 83, 83),
        available = true,
    )

    @Test
    fun `full Balance preserves the primary net in collapsed and expanded fields`() {
        val presentation = FluviLockScreenNotificationPresentation.create(
            configuration = FluviLockScreenCardConfiguration(
                enabled = true,
                mode = FluviLockScreenCardConfiguration.Mode.balance,
                privacy = FluviLockScreenCardConfiguration.Privacy.full,
            ),
            content = balance,
            monitoring = null,
        )

        assertTrue(presentation.isFull)
        assertEquals("Balance · Hónap", presentation.title)
        assertEquals("−11 000 Ft", presentation.text)
        assertEquals(
            "−11 000 Ft\nHónap nettó\nUtolsó kapcsolódó tétel: −9 800 Ft · Lidl · 14:32",
            presentation.expanded,
        )
    }

    @Test
    fun `discreet presentation does not leak financial fields`() {
        val presentation = FluviLockScreenNotificationPresentation.create(
            configuration = FluviLockScreenCardConfiguration(
                enabled = true,
                mode = FluviLockScreenCardConfiguration.Mode.balance,
                privacy = FluviLockScreenCardConfiguration.Privacy.discreet,
            ),
            content = balance,
            monitoring = null,
        )

        assertFalse(presentation.isFull)
        assertEquals("Fluvi · Pénzügyi pillanatkép", presentation.title)
        assertEquals("Új tranzakció könyvelve · 14:32", presentation.text)
        assertFalse(presentation.expanded.contains("11 000"))
        assertFalse(presentation.expanded.contains("Lidl"))
        assertFalse(presentation.expanded.contains("Balance"))
    }
}
