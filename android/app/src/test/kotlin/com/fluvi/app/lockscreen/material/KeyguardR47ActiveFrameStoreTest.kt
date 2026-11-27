package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE)
class KeyguardR47ActiveFrameStoreTest {
    private val context get() = RuntimeEnvironment.getApplication()
    private val epoch = System.nanoTime().coerceAtLeast(1L)
    private val session = "r47-frame-store-$epoch"

    @Before fun prepare() {
        context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE).edit()
            .clear().putBoolean("requested", true).putBoolean("details", true)
            .putBoolean("focusMigrated", true).putLong("generation", 7).commit()
        assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, session))
    }

    @After fun cleanup() {
        FluviActiveHeaderMaterialStore.invalidate()
        context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @Test fun olderDecodeCannotInstallIntoANewerHeader() {
        val first = publish(1)
        val bytes = byteArrayOf(1, 2, 3)
        val admitted = FluviActiveHeaderMaterialStore.admitFrames(context, payload(first, 1, listOf(bytes, bytes, bytes)), epoch)
        val request = requireNotNull(admitted.request)
        bytes[0] = 9
        assertEquals("the asynchronous decoder owns its bytes", 1, request.encoded.first()[0].toInt())
        val oldOwner = request.owner
        val next = publish(2)
        assertNotEquals(first, next)
        val bitmaps = List(3) { Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888) }
        assertFalse(FluviActiveHeaderMaterialStore.commitFrames(context, request, bitmaps))
        assertTrue(bitmaps.all { it.isRecycled })
        assertNull(oldOwner.preparedFrames)
        assertNull(FluviActiveHeaderMaterialStore.applicable(context)?.preparedFrames)
        assertEquals("staleSource", FluviActiveHeaderMaterialStore.admitFrames(context,
            payload(first, 1, listOf(byteArrayOf(1), byteArrayOf(2), byteArrayOf(3))), epoch).reason)
    }

    @Test fun animatedStarterInvalidPngAndRevokedDetailsStayUnavailable() {
        val token = publish(1)
        val starter = FluviActiveHeaderMaterialStore.admitFrames(context, payload(token, 1, listOf(byteArrayOf(1))), epoch)
        assertEquals("incompleteSequence", starter.reason)
        val admitted = FluviActiveHeaderMaterialStore.admitFrames(context,
            payload(token, 1, listOf(byteArrayOf(1), byteArrayOf(2), byteArrayOf(3))), epoch)
        assertNull(FluviActiveHeaderMaterialStore.decodeFrames(requireNotNull(admitted.request)))
        context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE).edit()
            .putBoolean("details", false).commit()
        assertEquals("sourceUnavailable", FluviActiveHeaderMaterialStore.admitFrames(context,
            payload(token, 1, listOf(byteArrayOf(1), byteArrayOf(2), byteArrayOf(3))), epoch).reason)
    }

    private fun payload(token: String, revision: Long, frames: List<ByteArray>) = mapOf<String, Any>(
        "token" to token, "publisherSession" to session, "publisherInstance" to 1L,
        "publisherRevision" to revision, "animated" to true, "intervalMs" to 32,
        "frameSizePx" to 32, "loopStatus" to "accepted", "frames" to frames,
    )

    private fun publish(revision: Long): String {
        val portal = mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0,
            "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
            "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
        val values = mapOf<String, Any>("schemaVersion" to 1, "shaderAbiVersion" to 6,
            "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
            "publisherSession" to session, "publisherRevision" to revision,
            "publisherInstance" to 1L, "activeMode" to "balance", "modeEpoch" to 0L,
            "motionEnabled" to true, "sourceAnimated" to true,
            "sceneIdentity" to "active-header:balance:0", "effectId" to "dualTide", "effectShaderId" to 1,
            "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
            "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt()), "stops" to listOf(0.0, 1.0),
            "opacity" to 1.0, "paletteSplitPercent" to 50.0, "commonSettings" to List(40) { .2 },
            "background" to portal, "interior" to portal, "referenceWidth" to 390.0, "referenceHeight" to 220.0)
        val receipt = FluviActiveHeaderMaterialStore.publish(context, values, epoch, true)
        assertTrue(receipt.reason, receipt.accepted)
        return requireNotNull(receipt.token)
    }
}
