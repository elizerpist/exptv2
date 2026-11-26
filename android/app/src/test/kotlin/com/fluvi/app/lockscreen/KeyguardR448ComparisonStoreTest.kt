package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR448ComparisonStoreTest {
    @Test fun summaryKeepsOnlyAllowlistedEvidence() {
        val text = KeyguardR448ComparisonStore.summarize("capture-a",
            "R44_8_SYSTEM_VETO request=9\nPRIVATE_SCREEN_TEXT\nR44_6_SAMPLE wake=1\n")
        assertTrue(text.contains("capture=capture-a"))
        assertTrue(text.contains("R44_8_SYSTEM_VETO request=9"))
        assertTrue(text.contains("R44_6_SAMPLE wake=1"))
        assertFalse(text.contains("PRIVATE_SCREEN_TEXT"))
    }

    @Test fun longReportsRemainBoundedAndCountOmittedLines() {
        val text = KeyguardR448ComparisonStore.summarize("capture-b",
            (1..100).joinToString("\n") { "R44_6_SAMPLE wake=$it value=" + "x".repeat(500) })
        assertTrue(text.toByteArray(Charsets.UTF_8).size <= 4800)
        assertTrue(text.contains("omittedSummaryLines="))
        assertFalse(text.contains("omittedSummaryLines=0 "))
    }
}
