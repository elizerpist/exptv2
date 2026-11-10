package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.os.Trace
import android.provider.Settings
import android.util.Log
import android.view.MotionEvent
import android.view.InputDevice
import android.view.KeyEvent
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * Disposable API-35 emulator fixture, NOT a replacement host or a phone
 * performance assertion. Android binds the production AccessibilityService;
 * its actual reader/classifier must authorize the actual accessibility window.
 * No window manager, reader, clock, GPU preparer, or commit callback is faked.
 *
 * The CI runner sets density=420 before launching this process and starts a
 * finite system trace. Only effect/Portal/mode/raster size match the known
 * phone workload: the synthetic palette/Portal controls below are NOT claimed
 * to reproduce the user's unprovided full material profile.
 */
@RunWith(AndroidJUnit4::class)
class KeyguardServiceOverlayInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation
    private lateinit var output: File
    private var deadline = 0L
    private var captureId = "not-started"
    private val evidence = StringBuilder()
    private val knownOwnWindowIds = mutableSetOf<Int>()
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private val component get() = ComponentName(context, FluviKeyguardCardService::class.java).flattenToString()

    @Test fun connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles() {
        assertEquals("This fixture is pinned to API 35", 35, Build.VERSION.SDK_INT)
        // This must be the FIRST UiAutomation request. The default flags
        // suppress the very accessibility service this test needs to exercise.
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        output = File(context.filesDir, "keyguard-service-probe").apply { mkdirs() }
        deadline = SystemClock.uptimeMillis() + 80_000L
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLockDisabled = shell("locksettings get-disabled").trim()
        val savedSettings = snapshotPreferences("fluvi_native_keyguard_card")
        val savedMaterial = snapshotPreferences("fluvi_keyguard_header_material")
        var captureStarted = false
        var testFailure: Throwable? = null
        try {
            assertFalse("Secure credentials require a different, explicit fixture", keyguard.isDeviceSecure)
            assertTrue("Cannot safely restore unknown lockscreen setting: $savedLockDisabled",
                savedLockDisabled == "true" || savedLockDisabled == "false")
            assertEquals("Runner must set density=420; do not resize the production View", 168,
                context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size))
            // Preserve unrelated services, and remove only our component while
            // constructing a genuine new service/renderer lifetime.
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, withoutOurService(savedServices))
            await("previous service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("initial unlocked state", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            instrumentation.runOnMainSync {
                val settings = FluviKeyguardCardSettings.update(context, mapOf(
                    "requested" to true,
                    "showFinancialDetails" to true,
                    "presentationMode" to "orb",
                    "animationMode" to "orbOnly",
                ))
                assertTrue("Fixture must authorize full palette while unlocked", settings.showFinancialDetails)
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                assertTrue("Production profile decoder rejected controlled Portal workload",
                    FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            val profile = requireNotNull(FluviKeyguardMaterialStore.read(context))
            assertTrue(profile.usesPortal)
            assertEquals("dualTide", profile.effectId)
            val started = KeyguardCardDiagnostics.startCapture(context,
                InstrumentationRegistry.getArguments().getString("sourceSha") ?: "instrumentation-source-unprovided",
                "debug", "LIGHT")
            captureStarted = true
            captureId = started["captureId"].toString()
            record("SETUP", "pid=${android.os.Process.myPid()} api=${Build.VERSION.SDK_INT}" +
                " densityDpi=${context.resources.displayMetrics.densityDpi} raster=168x168" +
                " effect=dualTide portal=true animationMode=orbOnly presentation=ORB" +
                " paletteAndPortalControls=SYNTHETIC_NOT_EXACT_PHONE_PROFILE")
            marked("service-connect") {
                val services = withoutOurService(savedServices).split(':').filter { it.isNotBlank() } + component
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services.joinToString(":"))
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
                await("Android-bound production service", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            }

            val cold = episode("cold")
            val firstImage = copyOrb(cold.window, "cold-orb-a.png")
            // A quiet, explicitly marked interval, not a FPS target. No
            // diagnostic polling, input, screenshots or window reads during
            // this interval; system trace owns its frame/thread attribution.
            marked("steady-live") {
                assertTrue("Insufficient fixture budget for the full quiet interval",
                    deadline - SystemClock.uptimeMillis() >= 10_000L)
                SystemClock.sleep(10_000)
            }
            val steady = snapshot("after-steady-live")
            assertEquals("LIVE must survive the quiet interval", "LIVE", steady.state)
            assertTrue("Quiet interval must produce additional actual shader output",
                steady.shader > cold.material.shader && steady.phase > cold.material.phase)
            val secondImage = copyOrb(requireOverlay(), "cold-orb-b.png")
            try {
                val motion = if (firstImage != null && secondImage != null) {
                    assertTrue("First compositor crop contains no nonempty material", hasColoredMaterial(firstImage))
                    assertTrue("Second compositor crop contains no nonempty material", hasColoredMaterial(secondImage))
                    hasOrbMotion(firstImage, secondImage).also {
                        assertTrue("Actual composited orb pixels did not change across the quiet live interval", it)
                    }
                } else null
                record("PIXEL_SAMPLE", "motion=${motion ?: "UNOBSERVED"}" +
                    " phasesBefore=${cold.material.phase} phasesAfter=${steady.phase}" +
                    " note=display-crops-not-a-physical-phone-FPS-proof")
            } finally {
                firstImage?.recycle()
                secondImage?.recycle()
            }
            // A real touch is delivered to the production accessibility root.
            marked("orb-short-tap") { tap(cold.window.bounds) }
            awaitLive("after-tap", steady, minimumAdvances = 1, expectedWindowId = cold.window.id)
            assertEquals("Short orb tap must retain its attachment", cold.window.id, requireOverlay().id)
            unlockAndAssertWithdrawn("cold-unlock")
            // Retention intentionally keeps first + latest three attempts;
            // setup/terminal signals can otherwise evict this actual cold
            // episode before the final export. Save one bounded existing
            // snapshot while detached, off main, outside timing scenarios.
            marked("cold-report-checkpoint") {
                instrumentation.runOnMainSync { }
                File(output, "cold-capture.txt").writeText(
                    KeyguardCardDiagnostics.captureSnapshot(context)["report"].toString(),
                )
            }

            val warm = episode("warm")
            unlockAndAssertWithdrawn("warm-unlock")
            // Start a real wake and revoke it promptly, without waiting for
            // acquisition/preparation. A late result must not leave a window
            // on the unlocked display. No synthetic inspection is injected.
            marked("rapid-wake-unlock") {
                screenOff()
                shell("input keyevent KEYCODE_WAKEUP")
                await("rapid display wake", 3_000) { power.isInteractive }
                shell("wm dismiss-keyguard")
                await("rapid unlock", 3_000) { !keyguard.isKeyguardLocked }
                await("rapid terminal withdrawal", 5_000) { ownOverlays().isEmpty() }
            }
            val reentry = episode("reattach-after-rapid")
            assertTrue("Warm reentry must advance actual live phases", reentry.material.phase > warm.material.phase)
            unlockAndAssertWithdrawn("final-unlock")
            record("RESULT", "OUTPUT_LIVENESS_PASS performanceAndNothingDevice=UNVERIFIED")
        } catch (failure: Throwable) {
            testFailure = failure
            record("RESULT", "FAIL ${failure.javaClass.simpleName}:${failure.message}")
            throw failure
        } finally {
            var cleanupFailure: Throwable? = null
            // Freeze before restoring settings so the report retains only the
            // controlled workload. Never block the main thread on export.
            if (captureStarted) runCatching {
                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()
                File(output, "capture.txt").writeText(report)
                report.lineSequence().filter { it.startsWith("ATTEMPT ") || it.startsWith(" EPISODE ") ||
                    it.startsWith("DRAW_") || it.startsWith("RENDER_") }.forEach { Log.i(TAG, it) }
            }.onFailure {
                cleanupFailure = it
                record("EXPORT_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, withoutOurService(savedServices))
                val end = SystemClock.uptimeMillis() + 5_000L
                while (FluviKeyguardCardServiceRegistry.connected && SystemClock.uptimeMillis() < end) SystemClock.sleep(50)
                assertFalse("Service must stop before preference restoration", FluviKeyguardCardServiceRegistry.connected)
                restorePreferences(savedSettings)
                restorePreferences(savedMaterial)
            }.onFailure {
                cleanupFailure = it
                record("RESTORE_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            runCatching {
                shell("input keyevent KEYCODE_WAKEUP")
                shell("wm dismiss-keyguard")
                if (savedLockDisabled == "true" || savedLockDisabled == "false") {
                    shell("locksettings set-disabled $savedLockDisabled")
                }
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure {
                cleanupFailure = it
                record("RESTORE_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            File(output, "fixture.txt").writeText(evidence.toString())
            cleanupFailure?.let { if (testFailure == null) throw AssertionError("Fixture cleanup/export failed", it) }
        }
    }

    private data class Material(
        val shader: Long, val phase: Long, val state: String, val hardware: Boolean,
        val effect: String?, val generatedAgslHash: String?,
    )
    private data class Overlay(val id: Int, val bounds: Rect)
    private data class Episode(val material: Material, val window: Overlay)

    private fun episode(name: String): Episode = marked(name) {
        // An unlocked KeyguardManager flag is not completion of the previous
        // remote animation. Runs42856983444 and42865721964 relocked while
        // SystemUI still finished that exit and subsequently returned to GONE.
        // Use the public UiAutomation input contract for independent episodes:
        // it synchronizes window animations/transactions before DOWN and after
        // UP. This is fixture setup, not an app delay, synthetic SHOW, or a
        // physical-presentation measurement. The rapid scenario intentionally
        // retains unsynchronized shell input and immediate exclusion assertions.
        marked("$name-synchronized-sleep") { screenOff(synchronizeInput = true) }
        shell("input keyevent KEYCODE_WAKEUP")
        await("$name keyguard eligible device gates", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
        // Material counters and last LIVE/hardware state survive detach.
        // A prior episode's snapshot can therefore be satisfied by draws
        // that happened before its removal. Observe THIS actual attachment
        // first, then require fresh output beyond its own counter baseline.
        val window = awaitOverlay(name)
        val baseline = snapshot("$name-attached-window-${window.id}")
        val material = awaitLive(name, baseline, minimumAdvances = 2, expectedWindowId = window.id)
        assertEquals("Episode must retain the observed attachment", window.id, requireOverlay().id)
        assertEquals("Production overlay width", 168, window.bounds.width())
        assertEquals("Production overlay height", 168, window.bounds.height())
        assertEquals("Actually drawn effect identity", "dualTide", material.effect)
        assertEquals("Actually retained Portal program must match the known phone program",
            EXPECTED_PORTAL_HASH, material.generatedAgslHash)
        record("EPISODE", "name=$name windowId=${window.id} type=TYPE_ACCESSIBILITY_OVERLAY bounds=${window.bounds}" +
            " shader=${material.shader} phase=${material.phase} state=${material.state} hardware=${material.hardware}" +
            " effect=${material.effect} generatedAgslHash=${material.generatedAgslHash}")
        Episode(material, window)
    }

    private fun screenOff(synchronizeInput: Boolean = false) {
        if (synchronizeInput) {
            assertTrue("Fixture budget exhausted before independent episode", SystemClock.uptimeMillis() < deadline)
            val downAt = SystemClock.uptimeMillis()
            for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
                val event = KeyEvent(downAt, SystemClock.uptimeMillis(), action, KeyEvent.KEYCODE_SLEEP,
                    0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD)
                assertTrue("Synchronized sleep input was rejected", automation.injectInputEvent(event, true))
            }
        } else {
            shell("input keyevent KEYCODE_SLEEP")
        }
        await("screen off", 3_000) { !power.isInteractive }
        await("screen-off withdrawal", 4_000) { ownOverlays().isEmpty() }
    }

    private fun unlockAndAssertWithdrawn(label: String) = marked(label) {
        shell("wm dismiss-keyguard")
        await("$label unlocked", 4_000) { !keyguard.isKeyguardLocked }
        await("$label overlay removed", 5_000) { ownOverlays().isEmpty() }
        record("WITHDRAWN", "name=$label keyguardLocked=${keyguard.isKeyguardLocked} ownOverlayCount=0")
    }

    private fun awaitLive(label: String, baseline: Material, minimumAdvances: Long, expectedWindowId: Int): Material {
        var latest = baseline
        await("$label actual live shader/phase output", 18_000, pollMs = 500) {
            assertEquals("LIVE output must belong to the current attachment", expectedWindowId, requireOverlay().id)
            latest = snapshot(label)
            val advanced = latest.state == "LIVE" && latest.hardware && latest.shader > baseline.shader &&
                latest.phase >= baseline.phase + minimumAdvances
            if (advanced) assertEquals("Attachment must still own the sampled LIVE output", expectedWindowId, requireOverlay().id)
            advanced
        }
        return latest
    }

    private fun awaitOverlay(label: String): Overlay {
        var current: Overlay? = null
        await("$label actual accessibility attachment", 18_000, pollMs = 500) {
            val overlays = ownOverlays()
            assertTrue("Never permit duplicate Fluvi accessibility overlays", overlays.size <= 1)
            current = overlays.singleOrNull()
            current != null
        }
        return checkNotNull(current)
    }

    private fun snapshot(label: String): Material {
        lateinit var material: Material
        instrumentation.runOnMainSync {
            // Explicit test-observer span: coarse waiting/boundary samples,
            // never a production/per-frame poll or an unlabelled Main delay.
            Trace.beginSection("KGProbe.snapshot")
            try {
                val values = FluviKeyguardCardServiceRegistry.materialDiagnostics()
                material = Material((values["shaderDrawCount"] as? Number)?.toLong() ?: 0L,
                    (values["phaseAdvanceCount"] as? Number)?.toLong() ?: 0L,
                    values["coldPresentationState"].toString(), values["hardwareAccelerated"] == true,
                    values["effectId"] as? String, values["generatedAgslHash"] as? String)
            } finally { Trace.endSection() }
        }
        record("BOUNDARY", "name=$label shader=${material.shader} phase=${material.phase} state=${material.state}")
        return material
    }

    private fun ownOverlays(): List<Overlay> {
        val windows = automation.windows
        return try {
            windows.filter { it.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY }.mapNotNull { window ->
                // Once known, window metadata is enough to observe removal.
                // A temporarily unavailable root must NOT become a false
                // assertion that this still-listed overlay disappeared.
                val known = window.id in knownOwnWindowIds || window.title?.toString() == "FluviKeyguardCard"
                val root = if (known) null else window.root
                val own = try { known || root?.packageName?.toString() == context.packageName }
                    finally { root?.recycle() }
                if (!own) null else {
                    knownOwnWindowIds += window.id
                    Overlay(window.id, Rect().also(window::getBoundsInScreen))
                }
            }
        } finally { windows.forEach { it.recycle() } }
    }

    private fun requireOverlay(): Overlay {
        val overlays = ownOverlays()
        assertEquals("Exactly one actual Fluvi accessibility overlay", 1, overlays.size)
        return overlays.single()
    }

    private fun copyOrb(window: Overlay, name: String): Bitmap? {
        val screen = automation.takeScreenshot() ?: run {
            record("SCREENSHOT_UNOBSERVED", "reason=UiAutomationReturnedNull")
            return null
        }
        return try {
            val bounds = Rect(window.bounds)
            if (!bounds.intersect(0, 0, screen.width, screen.height) || bounds.width() != 168 || bounds.height() != 168) {
                record("SCREENSHOT_UNOBSERVED", "reason=unexpectedBounds")
                null
            } else Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height()).also { crop ->
                File(output, name).outputStream().use { crop.compress(Bitmap.CompressFormat.PNG, 100, it) }
            }
        } finally { screen.recycle() }
    }

    /** Ignore the transparent corners: changing wallpaper/SystemUI pixels
     * outside the orb are not evidence that the material animated. */
    private fun hasOrbMotion(first: Bitmap, second: Bitmap): Boolean {
        for (y in 0 until first.height) for (x in 0 until first.width) {
            if (insideOrb(x, y, first.width) && first.getPixel(x, y) != second.getPixel(x, y)) return true
        }
        return false
    }

    private fun hasColoredMaterial(bitmap: Bitmap): Boolean {
        var firstColor: Int? = null
        for (y in 0 until bitmap.height) for (x in 0 until bitmap.width) {
            if (!insideOrb(x, y, bitmap.width)) continue
            val color = bitmap.getPixel(x, y)
            if ((color ushr 24) == 0 || (color and 0x00ffffff) == 0) continue
            if (firstColor == null) firstColor = color
            else if (color != firstColor) return true
        }
        return false
    }

    private fun insideOrb(x: Int, y: Int, size: Int): Boolean {
        val dx = x + .5f - size / 2f
        val dy = y + .5f - size / 2f
        val radius = size * .42f
        return dx * dx + dy * dy < radius * radius
    }

    private fun tap(bounds: Rect) {
        val downAt = SystemClock.uptimeMillis()
        val down = MotionEvent.obtain(downAt, downAt, MotionEvent.ACTION_DOWN, bounds.exactCenterX(), bounds.exactCenterY(), 0)
        val up = MotionEvent.obtain(downAt, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, bounds.exactCenterX(), bounds.exactCenterY(), 0)
        down.source = InputDevice.SOURCE_TOUCHSCREEN
        up.source = InputDevice.SOURCE_TOUCHSCREEN
        try {
            assertTrue(automation.injectInputEvent(down, true))
            assertTrue(automation.injectInputEvent(up, true))
        } finally { down.recycle(); up.recycle() }
    }

    private fun await(label: String, timeoutMs: Long, pollMs: Long = 100, condition: () -> Boolean) {
        val end = minOf(deadline, SystemClock.uptimeMillis() + timeoutMs)
        while (SystemClock.uptimeMillis() < end) {
            if (condition()) return
            SystemClock.sleep(pollMs)
        }
        record("TIMEOUT", "$label reason=${KeyguardCardDiagnostics.lastReason(context)}")
        throw AssertionError("$label timed out; no classifier or callback bypass is permitted")
    }

    private inline fun <T> marked(label: String, action: () -> T): T {
        Trace.beginSection("KGProbe.$label")
        record("SCENARIO_BEGIN", label)
        return try { action() } finally {
            record("SCENARIO_END", label)
            Trace.endSection()
        }
    }

    private fun record(stage: String, detail: String) {
        val line = "$stage capture=$captureId up=${SystemClock.uptimeMillis()} monoNs=${System.nanoTime()}" +
            " bootNs=${SystemClock.elapsedRealtimeNanos()} tid=${android.os.Process.myTid()} $detail"
        evidence.appendLine(line)
        Log.i(TAG, line)
    }

    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command),
    ).bufferedReader().use { it.readText() }

    private fun setSecure(key: String, value: String?) {
        // UiAutomation executes commands through Runtime.exec(String), not a
        // shell: shell-style quotes would become part of the stored component
        // or numeric value. Write exact nullable values through the public
        // provider API under this short-lived instrumentation-only identity.
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try {
            assertTrue("Secure setting write failed: $key", Settings.Secure.putString(context.contentResolver, key, value))
            assertEquals("Secure setting must round-trip without command quoting: $key",
                value, Settings.Secure.getString(context.contentResolver, key))
        } finally {
            automation.dropShellPermissionIdentity()
        }
    }

    private fun withoutOurService(value: String?): String = value.orEmpty().split(':').filter {
        it.isNotBlank() && ComponentName.unflattenFromString(it) != ComponentName(context, FluviKeyguardCardService::class.java)
    }.joinToString(":")

    private fun snapshotPreferences(name: String): Pair<SharedPreferences, Map<String, *>> {
        val prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE)
        return prefs to HashMap(prefs.all)
    }

    private fun restorePreferences(saved: Pair<SharedPreferences, Map<String, *>>) {
        val edit = saved.first.edit().clear()
        saved.second.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value)
            is Int -> edit.putInt(key, value)
            is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value)
            is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        assertTrue("Restore exact fixture-owned preferences", edit.commit())
    }

    private fun materialProfile(): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6,
        "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "connected-service-fixture", "publisherRevision" to 1L,
        "sceneIdentity" to "fixture|balance|month", "effectId" to "dualTide", "effectShaderId" to 1,
        "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
        "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 }, "background" to portal(true), "interior" to portal(false),
        "referenceWidth" to 390.0, "referenceHeight" to 220.0,
    )

    private fun portal(enabled: Boolean): Map<String, Any> = mapOf(
        "enabled" to enabled, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to .2,
        "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 },
    )

    companion object {
        private const val TAG = "FluviServiceProbe"
        private const val EXPECTED_PORTAL_HASH = "24f2d163e2cf8ad536f4f2c6314cc9839ae711bdef9920dbfd94465f175808df"
    }
}
