package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PushRecurringParserTest {
    @Test
    fun parsesAmountAndMerchantFromRulePatterns() {
        val result = PushRecurringParser.parse(
            text = "Terheles: 121 550 Ft. Partner: OTP Lakashitel.",
            amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*Ft)",
            merchantPattern = "Partner:\\s*(?<merchant>.+?)(?:\\.|$)",
            includeKeyword = "Terheles",
        )

        assertEquals(121550.0, result.amount, 0.0)
        assertEquals("OTP Lakashitel", result.merchant)
        assertNull(result.error)
    }

    @Test
    fun returnsErrorWhenKeywordMissing() {
        val result = PushRecurringParser.parse(
            text = "Kartya vasarlas 1200 Ft Bolt",
            amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*Ft)",
            merchantPattern = "(?<merchant>Bolt)",
            includeKeyword = "Terheles",
        )

        assertEquals("keyword_missing", result.error)
    }
}
