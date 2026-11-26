package com.fluvi.app.lockscreen

import android.Manifest
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Rect
import android.graphics.PixelFormat
import android.os.Binder
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.SurfaceControl
import android.view.SurfaceControlViewHost
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.abs
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** A real public-API composition control on two app-owned test windows.
 * It is not an OEM clock result or authorization to enable a backend. */
@RunWith(AndroidJUnit4::class)
class KeyguardR446WindowLifecycleInstrumentationTest {
    @Test fun sameHostTransitionRevokesActualPresenter() = exercise(capture = false, parentLifecycle = false)
    @Test fun sameHostTransitionWithCaptureRevokesActualPresenter() = exercise(capture = true, parentLifecycle = false)

    private fun exercise(capture: Boolean, parentLifecycle: Boolean) {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, predicate: () -> Boolean) {
            val until = SystemClock.uptimeMillis() + 12_000
            while (SystemClock.uptimeMillis() < until) { if (predicate()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val value = AtomicReference<T>()
            ins.runOnMainSync { value.set(block()) }
            return value.get()
        }
        fun save(name: String, bitmap: Bitmap) = File(out, "$name.png").outputStream().use {
            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it))
        }
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val touches = AtomicInteger()
        val lowerTouches = AtomicInteger()
        var activity: KeyguardMaterialTestActivity? = null
        var upperManager: WindowManager? = null
        var upperPatch: View? = null
        var presenter: KeyguardR446WindowPresenter? = null
        var calibration: KeyguardR22VisualCalibration? = null
        var underlay: Bitmap? = null
        val evidence = StringBuilder("fixture=two-app-windows service=real controlledOwner=fixture source=sample-clock backend=experimental capture=$capture parentLifecycle=$parentLifecycle\n")
        try {
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("real accessibility service") { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            KeyguardR44Trial.set(true, true)
            if (capture) KeyguardCardDiagnostics.startCapture(context, "r446-lifecycle-composition", "debug", "FULL")
            val profile = checkNotNull(KeyguardR44Trial.profile(null))
            calibration = KeyguardR22VisualCalibration(ins, out, ui, profile, discloseFull = false).also { it.calibrate() }
            val reference = checkNotNull(calibration)
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            activity = ins.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val windowActivity = checkNotNull(activity)
            main { windowActivity.setContentView(FrameLayout(windowActivity).apply {
                setBackgroundColor(Color.rgb(11, 177, 67))
                setOnTouchListener { _, event -> if (event.action == MotionEvent.ACTION_UP) lowerTouches.incrementAndGet(); true }
            }) }
            ins.waitForIdleSync()
            var hostId = -1
            val hostBounds = Rect()
            waitFor("actual active lower application window") {
                val windows = service.windows
                try {
                    val found = windows.firstOrNull { w ->
                        val root = w.root
                        try { w.isActive && root?.packageName?.toString() == context.packageName }
                        finally { root?.recycle() }
                    }
                    if (found != null) { hostId = found.id; found.getBoundsInScreen(hostBounds); true } else false
                } finally { windows.forEach { it.recycle() } }
            }
            assertTrue(hostBounds.width() > size + 40 && hostBounds.height() > size + 100)
            val x = (hostBounds.width() - size) / 2
            val y = (hostBounds.height() - size) / 2
            val patchSize = (size / 3).coerceAtLeast(32)
            lateinit var patch: View
            lateinit var upperParams: WindowManager.LayoutParams
            main {
                patch = View(windowActivity).apply {
                    setBackgroundColor(Color.rgb(9, 31, 241))
                    setOnTouchListener { _, event -> if (event.action == MotionEvent.ACTION_UP) touches.incrementAndGet(); true }
                }
                upperParams = WindowManager.LayoutParams(patchSize, patchSize,
                    WindowManager.LayoutParams.TYPE_APPLICATION_PANEL,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    PixelFormat.TRANSLUCENT).apply {
                    token = windowActivity.window.decorView.windowToken
                    gravity = Gravity.TOP or Gravity.LEFT
                    this.x = hostBounds.left + x + size / 2 - patchSize / 2
                    this.y = hostBounds.top + y + size / 2 - patchSize / 2
                }
                upperManager = windowActivity.getSystemService(WindowManager::class.java)
                checkNotNull(upperManager).addView(patch, upperParams)
                upperPatch = patch
            }
            ins.waitForIdleSync()
            val orbBounds = Rect(hostBounds.left + x, hostBounds.top + y, hostBounds.left + x + size, hostBounds.top + y + size)
            val patchBounds = Rect()
            var geometryProbes = 0
            waitFor("independent patch overlaps the measured orb bounds") {
                main {
                    val location = IntArray(2)
                    patch.getLocationOnScreen(location)
                    patchBounds.set(location[0], location[1], location[0] + patch.width, location[1] + patch.height)
                    if (geometryProbes++ < 4) evidence.append("geometry host=$hostBounds orb=$orbBounds patch=$patchBounds\n")
                    if (patch.width > 0 && patch.height > 0 && !Rect.intersects(patchBounds, orbBounds)) {
                        // Dialog insets and gravity differ across Android builds.
                        // Correct from the measured pixels, then re-observe.
                        upperParams.apply {
                            this.x += orbBounds.centerX() - patchBounds.centerX()
                            this.y += orbBounds.centerY() - patchBounds.centerY()
                        }
                        checkNotNull(upperManager).updateViewLayout(patch, upperParams)
                    }
                }
                patchBounds.width() > 0 && patchBounds.height() > 0 && Rect.intersects(patchBounds, orbBounds)
            }
            waitFor("two actual independently layered application windows") {
                val windows = service.windows
                try {
                    val lower = windows.firstOrNull { it.id == hostId }
                    lower != null && windows.any { w ->
                        if (w.id == hostId || w.layer <= lower.layer) false else {
                            val root = w.root
                            try { root?.packageName?.toString() == context.packageName } finally { root?.recycle() }
                        }
                    }
                } finally { windows.forEach { it.recycle() } }
            }
            underlay = checkNotNull(ui.takeScreenshot()).also { save("r446-lifecycle-before", it) }
            val blue = checkNotNull(underlay).getPixel(patchBounds.centerX(), patchBounds.centerY())
            assertTrue("NOT REACHED: upper blue control pixels", Color.blue(blue) > 180 && Color.red(blue) < 60)
            shell("input tap ${patchBounds.centerX()} ${patchBounds.centerY()}")
            waitFor("upper-window touch before attach") { touches.get() >= 1 }
            val phase = AtomicReference<KeyguardMaterialTime>(KeyguardR22VisualCalibration.timeA)
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            val ownerField = FluviKeyguardCardService::class.java.getDeclaredField("r446Owner").apply { isAccessible = true }
            val owner = ownerField.get(service) as KeyguardR446PrintOwner
            val target = KeyguardR446Target(hostId, 0,
                KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
            val geometry = KeyguardOverlayGeometry(size, size, hostBounds.left + x, hostBounds.top + y,
                KeyguardUsableBounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom),
                KeyguardCardCardPosition(.5f), KeyguardCardOrbPosition(.5f, .5f))
            val ticket = main {
                owner.arm(1, "fixture-capture")
                owner.screenOff()
                check(owner.wake(1, "fixture-capture"))
                checkNotNull(owner.issue(1, "fixture-capture", 1, 1, 1, target, SystemClock.uptimeMillis()))
            }
            val testToken = ticket
            val touchX = orbBounds.left + size / 8
            val touchY = orbBounds.centerY()
            shell("input tap $touchX $touchY")
            waitFor("lower-window input before attachment") { lowerTouches.get() >= 1 }
            val draws = AtomicInteger()
            main {
                val actual = service.r446PreparePresenterForInstrumentation(KeyguardMaterialTimeSource { _, _ -> phase.get() })
                presenter = actual
                check(actual.prepare(checkNotNull(windowActivity.display), profile, artifact))
            }
            waitFor("embedded input region was prepared") { main { checkNotNull(presenter).inputReadyForInstrumentation() } }
            main {
                val actual = checkNotNull(presenter)
                assertEquals("NOT REACHED: controlled owner was revoked before show",
                    KeyguardR446PrintOwner.State.ISSUED, owner.state)
                assertEquals("actual production presenter attached and submitted", "SUBMITTED", actual.show(testToken, target, geometry,
                    valid = { owner.state == KeyguardR446PrintOwner.State.ISSUED },
                    stillOwned = { owner.state == KeyguardR446PrintOwner.State.ISSUED }, onFirstDraw = { draws.incrementAndGet() }).status)
            }
            waitFor("lower host retains window focus") {
                val windows = service.windows
                try { windows.any { it.id == hostId && it.isFocused } } finally { windows.forEach { it.recycle() } }
            }
            waitFor("actual production presenter shader draw") { draws.get() > 0 }
            fun matches(expected: Bitmap, label: String): Boolean {
                val shot = checkNotNull(ui.takeScreenshot())
                try {
                    save("r446-lifecycle-$label", shot)
                    var matching = 0; var changed = 0
                    for (yy in 0 until size step 2) for (xx in 0 until size step 2) {
                        val sx = orbBounds.left + xx; val sy = orbBounds.top + yy
                        if (sx !in 0 until shot.width || sy !in 0 until shot.height || patchBounds.contains(sx, sy)) continue
                        val a = expected.getPixel(xx, yy); val b = shot.getPixel(sx, sy)
                        val prior = checkNotNull(underlay).getPixel(sx, sy)
                        fun delta(p: Int, q: Int) = maxOf(abs(Color.red(p) - Color.red(q)),
                            abs(Color.green(p) - Color.green(q)), abs(Color.blue(p) - Color.blue(q)))
                        if (delta(a, prior) >= 20) { if (delta(a, b) <= 8) matching++; if (delta(b, prior) >= 20) changed++ }
                    }
                    val top = shot.getPixel(patchBounds.centerX(), patchBounds.centerY())
                    evidence.append("sample=$label matching=$matching changed=$changed top=$top\n")
                    return matching >= 64 && changed >= 64 && Color.blue(top) > 180 && Color.red(top) < 60
                } finally { shot.recycle() }
            }
            var attempt = 0
            waitFor("reference A pixels outside opaque upper window") { matches(reference.a, "a-${attempt++}") }
            main { phase.set(KeyguardR22VisualCalibration.timeB); checkNotNull(presenter).frameForInstrumentation() }
            attempt = 0
            waitFor("reference B live pixels outside opaque upper window") { matches(reference.b, "b-${attempt++}") }
            shell("input tap ${patchBounds.centerX()} ${patchBounds.centerY()}")
            waitFor("upper-window touch after attach") { touches.get() >= 2 }
            shell("input tap $touchX $touchY")
            waitFor("lower-window input through the orb") { lowerTouches.get() >= 2 }
            shell("input tap ${hostBounds.left + 12} ${hostBounds.top + 12}")
            waitFor("lower-window input outside the orb") { lowerTouches.get() >= 3 }
            val transitionAt = SystemClock.uptimeMillis()
            main {
                service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, hostId, 0, 0, "com.android.systemui", transitionAt))
            }
            assertEquals("service must revoke its exact owner on a same-window scene change",
                KeyguardR446PrintOwner.State.CONSUMED, main { owner.state })
            main {
                // A stale producer callback cannot reacquire the released child.
                checkNotNull(presenter).frameForInstrumentation()
                assertNotEquals("SUBMITTED", checkNotNull(presenter).show(testToken, target, geometry,
                    valid = { false }, stillOwned = { false }).status)
            }
            evidence.append("sameHostTransition=REVOKED latePost=REJECTED\n")
            attempt = 0
            waitFor("withdrawn surface underlay") {
                val shot = checkNotNull(ui.takeScreenshot())
                try {
                    save("r446-lifecycle-hidden-${attempt++}", shot)
                    var differences = 0
                    for (yy in 0 until size step 4) for (xx in 0 until size step 4) {
                        val sx = orbBounds.left + xx; val sy = orbBounds.top + yy
                        if (sx in 0 until shot.width && sy in 0 until shot.height &&
                            shot.getPixel(sx, sy) != checkNotNull(underlay).getPixel(sx, sy)) differences++
                    }
                    evidence.append("hiddenDiff=$differences\n")
                    differences < 10
                } finally { shot.recycle() }
            }
            evidence.append("initialStack=PASS motion=PASS touch=PASS hide=PASS parentMutation=NOT_RUN\n")
        } finally {
            runCatching { ui.takeScreenshot()?.let { save("r446-lifecycle-final-before-cleanup", it); it.recycle() } }
            File(out, "r446-lifecycle-composition.txt").writeText(evidence.toString())
            main {
                presenter?.dispose()
                upperPatch?.let { runCatching { upperManager?.removeViewImmediate(it) } }
                activity?.finish()
            }
            underlay?.recycle(); calibration?.close()
            KeyguardR44Trial.set(false, false)
            if (capture) KeyguardCardDiagnostics.clearCapture(context)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
        }
    }
}
