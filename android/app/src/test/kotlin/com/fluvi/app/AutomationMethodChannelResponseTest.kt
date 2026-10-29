package com.fluvi.app

import io.flutter.plugin.common.StandardMethodCodec
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AutomationMethodChannelResponseTest {
    @Test
    fun `successful void automation command encodes as a null codec result`() {
        val response = automationMethodChannelResponse(Unit)

        assertNull(response)
        assertNull(
            StandardMethodCodec.INSTANCE.decodeEnvelope(
                StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(response),
            ),
        )
    }

    @Test
    fun `payload automation responses retain their standard codec map`() {
        val response = automationMethodChannelResponse(
            mapOf("occurrenceId" to "occurrence-1", "skipped" to true),
        )

        assertEquals(
            mapOf("occurrenceId" to "occurrence-1", "skipped" to true),
            StandardMethodCodec.INSTANCE.decodeEnvelope(
                StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(response),
            ),
        )
    }
}
