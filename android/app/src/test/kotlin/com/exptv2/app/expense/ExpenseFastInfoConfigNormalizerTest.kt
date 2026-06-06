package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Test

class ExpenseFastInfoConfigNormalizerTest {
    @Test
    fun preservesRowPresentationsWhenSavingFastInfoConfig() {
        val normalized = ExpenseFastInfoConfigNormalizer.normalize(
            mapOf(
                "layoutMode" to "mixed",
                "upperRowPresentation" to "pill",
                "lowerRowPresentation" to "pill",
                "pills" to listOf(mapOf("id" to "mai_koltes", "type" to "pill")),
                "boxes" to listOf(mapOf("id" to "havi_koltes", "type" to "box")),
            ),
        )

        assertEquals("mixed", normalized["layoutMode"])
        assertEquals("pill", normalized["upperRowPresentation"])
        assertEquals("pill", normalized["lowerRowPresentation"])
        assertEquals(3, (normalized["pills"] as List<*>).size)
        assertEquals(3, (normalized["boxes"] as List<*>).size)
    }
}
