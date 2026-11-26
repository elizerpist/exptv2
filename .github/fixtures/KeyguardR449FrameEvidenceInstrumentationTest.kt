package com.fluvi.app.lockscreen

import android.Manifest
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Intent
import android.graphics.Color
import android.graphics.Rect
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.provider.Settings
import android.view.MotionEvent
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Controlled foreground composition only. It does not assert stock-keyguard
 * admission, the Flutter selector, privacy qualification or phone pixels. */
@RunWith(AndroidJUnit4::class)
class KeyguardR449FrameEvidenceInstrumentationTest {
    @Test fun independentAccessibilityFrameDrawsAndRevocationCancelsPendingAdd() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd)).bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, predicate: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + 12_000
            while (SystemClock.uptimeMillis() < end) { if (predicate()) return; SystemClock.sleep(25) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val result = AtomicReference<T>()
            ins.runOnMainSync { result.set(block()) }
            return result.get()
        }
        val id = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$id").apply { check(mkdirs()) }
        val services = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val events = mutableListOf<KeyguardR448WidgetsAnywhereFrame.Event>()
        val touches = AtomicInteger()
        val phase = AtomicReference<KeyguardMaterialTime>(KeyguardR22VisualCalibration.timeA)
        var calibration: KeyguardR22VisualCalibration? = null
        var activity: KeyguardMaterialTestActivity? = null
        var frame: KeyguardR448WidgetsAnywhereFrame? = null
        val owner = KeyguardR448WidgetsAnywhereFrame.Owner(1, 1, 1)
        val cancelledOwner = KeyguardR448WidgetsAnywhereFrame.Owner(2, 1, 1)
        val postAddOwner = KeyguardR448WidgetsAnywhereFrame.Owner(3, 1, 1)
        val recheckedOwner = KeyguardR448WidgetsAnywhereFrame.Owner(4, 1, 1)
        try {
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            val others = services.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("real accessibility service") { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            KeyguardR44Trial.set(true, true)
            val original = checkNotNull(KeyguardR44Trial.profile(null))
            val profile = original.neutralized()
            // The calibration derives both domains from the original profile;
            // passing an already-neutralized input makes its contrast control
            // compare the same palette to itself and cannot qualify the fixture.
            calibration = KeyguardR22VisualCalibration(ins, out, ui, original, discloseFull = false).also { it.calibrate() }
            val reference = checkNotNull(calibration)
            activity = ins.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val host = checkNotNull(activity)
            main { host.setContentView(FrameLayout(host).apply {
                setBackgroundColor(Color.rgb(11, 177, 67))
                setOnTouchListener { _, event -> if (event.action == MotionEvent.ACTION_UP) touches.incrementAndGet(); true }
            }) }
            ins.waitForIdleSync()
            val metrics = context.resources.displayMetrics
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val left = (metrics.widthPixels - size) / 2
            val top = (metrics.heightPixels - size) / 2
            val bounds = Rect(left, top, left + size, top + size)
            val geometry = KeyguardOverlayGeometry(size, size, left, top,
                KeyguardUsableBounds(0, 0, metrics.widthPixels, metrics.heightPixels),
                KeyguardCardCardPosition(.5f), KeyguardCardOrbPosition(.5f, .5f))
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            var underlay: android.graphics.Bitmap? = null
            var underlayIndex = 0
            waitFor("stable visible green foreground before frame add") {
                val sample = reference.captureCrop("r448-controlled-underlay-${underlayIndex++}", bounds)
                val points = listOf(1 to 1, size - 2 to 1, 1 to size - 2,
                    size - 2 to size - 2, size / 2 to size / 2)
                val green = points.all { (x, y) ->
                    val p = sample.getPixel(x, y)
                    kotlin.math.abs(Color.red(p) - 11) <= 5 &&
                        kotlin.math.abs(Color.green(p) - 177) <= 5 &&
                        kotlin.math.abs(Color.blue(p) - 67) <= 5
                }
                if (green) underlay = sample
                green
            }
            val stableUnderlay = checkNotNull(underlay)
            val preCheck = AtomicReference<((Boolean) -> Unit)?>(null)
            main {
                frame = KeyguardR448WidgetsAnywhereFrame(service, KeyguardMaterialTimeSource { _, _ -> phase.get() })
                assertTrue(checkNotNull(frame).prepare(cancelledOwner, profile, false, artifact) { synchronized(events) { events.add(it) } })
                assertTrue(checkNotNull(frame).requestShowChecked(cancelledOwner, geometry, { true }) {
                    preCheck.set(it)
                })
            }
            waitFor("asynchronous pre-add check") { preCheck.get() != null }
            main { assertTrue(checkNotNull(frame).cancelPending(cancelledOwner)) }
            checkNotNull(preCheck.get())(true)
            SystemClock.sleep(150)
            assertFalse("a late pre-add check cannot revive a revoked request",
                synchronized(events) { events.any { it.stage == "ADD_BEGIN" } })
            main {
                assertTrue(checkNotNull(frame).requestShow(cancelledOwner, geometry) { true })
                assertTrue(checkNotNull(frame).retire(cancelledOwner, "CONTROL_BEFORE_DEBOUNCE"))
            }
            SystemClock.sleep(150)
            assertFalse("revoked timer cannot add a frame", synchronized(events) { events.any { it.stage == "ADD_BEGIN" } })
            val postCheck = AtomicReference<((Boolean) -> Unit)?>(null)
            val checkCount = AtomicInteger()
            main {
                assertTrue(checkNotNull(frame).prepare(postAddOwner, profile, false, artifact) { synchronized(events) { events.add(it) } })
                assertTrue(checkNotNull(frame).requestShowChecked(postAddOwner, geometry, { true }) {
                    if (checkCount.incrementAndGet() == 1) it(true) else postCheck.set(it)
                })
            }
            waitFor("asynchronous post-add check") { postCheck.get() != null }
            assertTrue("real add occurred before post-add check", synchronized(events) {
                events.any { it.owner == postAddOwner && it.stage == "ADD_RETURN" }
            })
            assertFalse("unverified post-add frame cannot draw", synchronized(events) {
                events.any { it.owner == postAddOwner && it.stage == "FIRST_SHADER_DRAW" }
            })
            main { assertTrue(checkNotNull(frame).retire(postAddOwner, "CONTROL_POST_ADD_REVOKED")) }
            checkNotNull(postCheck.get())(true)
            SystemClock.sleep(150)
            assertFalse("a late post-add check cannot draw a retired view", synchronized(events) {
                events.any { it.owner == postAddOwner && it.stage == "FIRST_SHADER_DRAW" }
            })
            val revisionAllowed = AtomicBoolean(true)
            val refreshedCheck = AtomicReference<((Boolean) -> Unit)?>(null)
            val refreshedCount = AtomicInteger()
            main {
                assertTrue(checkNotNull(frame).prepare(recheckedOwner, profile, false, artifact) { synchronized(events) { events.add(it) } })
                assertTrue(checkNotNull(frame).requestShowChecked(recheckedOwner, geometry, { revisionAllowed.get() }) {
                    if (refreshedCount.incrementAndGet() == 1) refreshedCheck.set(it) else it(true)
                })
                revisionAllowed.set(false)
            }
            waitFor("original timer reaches the pending revision check") { refreshedCheck.get() != null }
            assertFalse("an unresolved new revision cannot add", synchronized(events) {
                events.any { it.owner == recheckedOwner && it.stage == "ADD_BEGIN" }
            })
            revisionAllowed.set(true)
            checkNotNull(refreshedCheck.get())(true)
            waitFor("freshly checked revision adds") { synchronized(events) {
                events.any { it.owner == recheckedOwner && it.stage == "ADD_RETURN" }
            } }
            assertEquals("revalidation did not restart the timer", 1, synchronized(events) {
                events.count { it.owner == recheckedOwner && it.stage == "DEBOUNCE_SCHEDULED" }
            })
            main { assertTrue(checkNotNull(frame).retire(recheckedOwner, "CONTROL_REVISION_COMPLETE")) }
            SystemClock.sleep(150)
            main {
                assertTrue(checkNotNull(frame).prepare(owner, profile, false, artifact) { synchronized(events) { events.add(it) } })
                assertTrue(checkNotNull(frame).requestShow(owner, geometry) { true })
                assertTrue(checkNotNull(frame).requestShow(owner, geometry) { true })
            }
            waitFor("actual accessibility window and shader draw") {
                synchronized(events) { events.any { it.owner == owner && it.stage == "ADD_RETURN" } &&
                    events.any { it.owner == owner && it.stage == "FIRST_SHADER_DRAW" } }
            }
            val observed = synchronized(events) { events.toList() }
            assertEquals("actual view bounds match the independent crop", bounds, main { checkNotNull(frame).measuredBoundsForInstrumentation() })
            assertEquals("one actual add for the active owner", 1, observed.count { it.owner == owner && it.stage == "ADD_BEGIN" })
            assertTrue("duplicate did not reset timer", observed.any { it.stage == "COALESCED" })
            reference.awaitServiceMatch("r448-controlled-A", bounds, reference.a, stableUnderlay)
            phase.set(KeyguardR22VisualCalibration.timeB)
            reference.awaitServiceMatch("r448-controlled-B", bounds, reference.b, stableUnderlay)
            shell("input tap ${bounds.centerX()} ${bounds.centerY()}")
            waitFor("input reaches foreground beneath non-touchable overlay") { touches.get() > 0 }
            main { assertTrue(checkNotNull(frame).retire(owner, "CONTROL_REMOVE")) }
            // Preserve the immediate and later compositor samples even if the
            // first one fails; a local remove return is not physical removal.
            val samples = (0 until 6).map { index ->
                if (index > 0) SystemClock.sleep(50)
                reference.captureCrop("r448-controlled-after-$index", bounds)
            }
            File(out, "r448-controlled-withdrawal.txt").writeText(samples.mapIndexed { index, sample ->
                "index=$index underlay=${KeyguardR22VisualCalibration.compare(stableUnderlay, sample)} " +
                    "referenceB=${KeyguardR22VisualCalibration.compare(reference.b, sample)}"
            }.joinToString("\n", postfix = "\n"))
            assertTrue("first removed crop returns to underlay",
                KeyguardR22VisualCalibration.compare(stableUnderlay, samples.first()).nearlyEqual())
        } finally {
            main {
                frame?.retire(owner, "CLEANUP")
                frame?.retire(postAddOwner, "CLEANUP")
                frame?.retire(recheckedOwner, "CLEANUP")
                frame?.retire(cancelledOwner, "CLEANUP")
                activity?.finish()
            }
            calibration?.close()
            File(out, "r448-controlled-events.txt").writeText(synchronized(events) { events.joinToString("\n", postfix = "\n") })
            KeyguardR44Trial.set(false, false)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, enabled)
        }
    }
}
