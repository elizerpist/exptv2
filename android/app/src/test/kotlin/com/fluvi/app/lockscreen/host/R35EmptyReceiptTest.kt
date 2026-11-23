package com.fluvi.app.lockscreen.host

import org.junit.Assert.*
import org.junit.Test

class R35EmptyReceiptTest {
    private val nonce = "0123456789abcdef0123456789abcdef"

    @Test fun onlyTheOutstandingSessionSequenceAndEpochMatch() {
        val receipt = R35EmptyReceipt()
        assertTrue(receipt.begin(nonce, 14, 7))
        assertFalse(receipt.begin(nonce, 15, 7))
        assertFalse(receipt.matches("fedcba9876543210fedcba9876543210", 14, 7))
        assertFalse(receipt.matches(nonce, 13, 7))
        assertFalse(receipt.matches(nonce, 14, 8))
        assertTrue(receipt.matches(nonce, 14, 7))
        receipt.clear()
        assertFalse(receipt.matches(nonce, 14, 7))
    }

    @Test fun invalidOrReplayedRequestsCannotBeArmed() {
        val receipt = R35EmptyReceipt()
        assertFalse(receipt.begin("invalid", 1, 1))
        assertFalse(receipt.begin(nonce, 0, 1))
        assertFalse(receipt.begin(nonce, 1, 0))
        assertTrue(receipt.begin(nonce, 1, 1))
        receipt.clear()
        assertTrue(receipt.begin(nonce, 2, 1))
        assertFalse(receipt.matches(nonce, 1, 1))
    }
}
