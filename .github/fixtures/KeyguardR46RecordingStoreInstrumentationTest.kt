package com.fluvi.app.lockscreen

import android.content.Context
import android.content.ContextWrapper
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KeyguardR46RecordingStoreInstrumentationTest {
    @Test fun completeLongUtf8ReportIsSealedOnceAndRetriedVerbatim() {
        val target = InstrumentationRegistry.getInstrumentation().targetContext
        val suffix = UUID.randomUUID().toString()
        val isolated = object : ContextWrapper(target) {
            override fun getApplicationContext(): Context = this
            override fun getFilesDir(): File = File(target.filesDir, "r46-test-$suffix").apply { mkdirs() }
            override fun getSharedPreferences(name: String, mode: Int) = target.getSharedPreferences("$name-$suffix", mode)
        }
        val id = UUID.randomUUID().toString()
        KeyguardR46RecordingStore.begin(isolated, id, "WIDGETS_ANYWHERE", "instrumentation")
        repeat(400) { KeyguardR46RecordingStore.offer(id, "wake=$it detail=${"ár".repeat(120)}") }
        val report = KeyguardR46RecordingStore.seal(isolated, id, "summary", "USER_STOP")
        assertTrue(report.toByteArray(Charsets.UTF_8).size > 32 * 1024)
        assertTrue(report.contains("wake=0 detail="))
        assertTrue(report.contains("wake=399 detail="))
        assertTrue(report.contains("spoolDropped=0"))
        val body = report.substringBefore("bodyBytes=")
        val hash = MessageDigest.getInstance("SHA-256").digest(body.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        assertTrue(report.contains("bodyBytes=${body.toByteArray(Charsets.UTF_8).size} bodySha256=$hash"))
        assertEquals(report, KeyguardR46RecordingStore.sealedReport(isolated, id))
        assertEquals(report, KeyguardR46RecordingStore.seal(isolated, id, "different", "RETRY"))
        KeyguardR46RecordingStore.copied(isolated, id)
        assertEquals("COPIED", KeyguardR46RecordingStore.status(isolated)["state"])
    }

    @Test fun nativeCaptureCutRetainsAcceptedEventsBeyondOldRingAndExportLimit() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        KeyguardCardDiagnostics.clearCapture(context)
        val started = KeyguardCardDiagnostics.startCapture(context, "r46-test", "debug", "FULL",
            r43Enabled = true, r442ExpectedSession = 1L, r446PrintRequested = true,
            r46Request = "capture-integration", r46Route = "FLUVI_STREAM")
        val id = requireNotNull(started["captureId"] as? String)
        try {
            repeat(300) { index ->
                KeyguardCardDiagnostics.captureEvent(context, "R46_TEST", "marker_${index}_${"á".repeat(100)}")
            }
            val frozen = KeyguardCardDiagnostics.freezeR46Capture(context)
            assertEquals("FROZEN", frozen["captureState"])
            val report = KeyguardR46RecordingStore.seal(context, id, frozen["report"] as? String ?: "", "USER_STOP")
            assertTrue(report.toByteArray(Charsets.UTF_8).size > 32 * 1024)
            repeat(300) { index -> assertTrue("missing accepted marker $index", report.contains("reason=marker_${index}_")) }
            assertTrue(report.contains("spoolDropped=0"))
            KeyguardR46RecordingStore.copied(context, id)
        } finally {
            KeyguardCardDiagnostics.clearCapture(context)
        }
    }
}
