package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
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

        assertNotNull(result.amount)
        assertEquals(121550.0, result.amount!!, 0.0)
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

    @Test
    fun parsesUserWalletMessageWithPaidAmountAndMerchant() {
        val result = PushRecurringParser.parse(
            text = "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n" +
                "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
            amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*(?:Ft|HUF))(?=\\s+összeget\\s+fizettél)",
            merchantPattern = "itt:\\s*(?<merchant>.+?)(?:\\.|$)",
            includeKeyword = "fizettél",
        )

        assertNotNull(result.amount)
        assertEquals(3085.0, result.amount!!, 0.0)
        assertEquals("nyírő", result.merchant)
        assertNull(result.error)
    }
}
