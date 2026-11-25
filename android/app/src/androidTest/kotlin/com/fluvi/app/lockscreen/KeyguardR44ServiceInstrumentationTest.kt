package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.accessibility.AccessibilityWindowInfo
import android.view.accessibility.AccessibilityEvent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Actual service, policy and renderer on disposable AOSP API 37. The
 * source-window facts are injected by the existing test probe: this does not
 * assert that an OEM or the actual SystemUI provider exposed the pair. */
@RunWith(AndroidJUnit4::class)
class KeyguardR44ServiceInstrumentationTest {
    @Test fun syntheticPairUsesRealServiceWithCaptureOff() = exercise(false)
    @Test fun syntheticPairUsesRealServiceWithCaptureOn() = exercise(true)
    @Test fun supersededSyntheticReadCannotGrantAfterRestriction() = exercise(false, staleControl = true)
    @Test fun actualSystemUiRestrictiveTransitions() = exercise(true, actualControls = true)

    private fun exercise(capture: Boolean, staleControl: Boolean = false, actualControls: Boolean = false) {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, condition: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val result = AtomicReference<T>()
            ins.runOnMainSync { result.set(block()) }
            return result.get()
        }
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid"))).toString()
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val preferences = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val savedSettings = HashMap(preferences.all)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val restrict = AtomicBoolean(false)
        val sawPositive = AtomicBoolean(false)
        val sawRestriction = AtomicBoolean(false)
        val positiveApply = AtomicBoolean(false)
        val applyCount = AtomicInteger()
        val held = CountDownLatch(1)
        val release = CountDownLatch(1)
        var service: FluviKeyguardCardService? = null
        var pinSet = false
        val evidence = StringBuilder("scope=controlled_snapshot service=real renderer=real capture=$capture physical=UNOBSERVED\n")
        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
        val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
        val proof = KeyguardR44WindowEvidence(true, true, host, entry, true, true, false)
        fun schedule(owner: FluviKeyguardCardService, reason: String) {
            val method = FluviKeyguardCardService::class.java.getDeclaredMethod("scheduleEvaluation",
                String::class.java, java.lang.Long::class.java, java.lang.Long::class.java,
                KeyguardWindowFreshness::class.java, KeyguardCardInspectionRequest::class.java)
                .apply { isAccessible = true }
            method.invoke(owner, reason, null, SystemClock.uptimeMillis(), KeyguardWindowFreshness.FRAMEWORK_EVENT, null)
        }
        try {
            check(!keyguard.isDeviceSecure)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            waitFor("unlocked setup") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            shell("locksettings set-pin 2468"); pinSet = keyguard.isDeviceSecure
            assertTrue("NOT REACHED: disposable PIN", pinSet)
            main { FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("real service connected") { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val owner = checkNotNull(service)
            assertTrue("NOT REACHED: unlocked synthetic trial", main { owner.setR44SyntheticTrial(true) })
            assertTrue(KeyguardR44Trial.active)
            KeyguardCardDiagnostics.clearCapture(context)
            if (capture) KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "debug", "FULL")
            owner.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> = listOf(
                    KeyguardWindowSnapshot("com.android.systemui", AccessibilityWindowInfo.TYPE_SYSTEM, 1, 0,
                        visibleViewIds = if (restrict.get()) setOf("scene:shade") else emptySet(), windowId = 10, r44 = proof))
                override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                    abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                    synchronized(evidence) { evidence.append("req=${request.id} decision=$decision reason=$reason unavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale\n") }
                    if (!rootUnavailable && !walkTruncated && !abortedStale &&
                        decision == KeyguardCardVisibility.SHOW_DISCREET && reason == KeyguardSurfaceReason.MAIN_CONFIRMED) {
                        sawPositive.set(true)
                        if (staleControl && held.count > 0) {
                            held.countDown()
                            check(release.await(20, TimeUnit.SECONDS)) { "NOT REACHED: release stale read" }
                        }
                    }
                    if (decision == KeyguardCardVisibility.HIDDEN_SHADE) sawRestriction.set(true)
                }
                override fun positiveApplyAttempt(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                    positiveApply.set(true)
                }
                override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                    if (applyCount.incrementAndGet() <= 100) {
                        val attached = owner.inspectionStateForTest().attached
                        val submissions = owner.surfaceMetricsForInstrumentation()?.submissions ?: 0L
                        synchronized(evidence) { evidence.append("apply=${request.id} decision=$decision attached=$attached submissions=$submissions\n") }
                    }
                }
            }
            shell("input keyevent KEYCODE_SLEEP")
            waitFor("screen off and locked") { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            waitFor("screen on and locked") { power.isInteractive && keyguard.isKeyguardLocked }
            if (staleControl) {
                assertTrue("NOT REACHED: complete positive on worker", held.await(20, TimeUnit.SECONDS))
                restrict.set(true)
                main { owner.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                    eventType = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, windowId = 10, displayId = 0,
                    windowChanges = 0, packageName = "com.android.systemui", eventTimeUptimeMs = SystemClock.uptimeMillis())) }
                release.countDown()
                waitFor("successor restriction") { sawRestriction.get() }
                assertFalse("stale positive reached apply", positiveApply.get())
                assertFalse("stale positive attached a root", main { owner.inspectionStateForTest().attached })
                evidence.append("heldPositive=discarded newerRestriction=observed attached=false\n")
                return
            }
            waitFor("controlled pair admitted and real ORB posted") {
                sawPositive.get() && main { owner.inspectionStateForTest().attached &&
                    (owner.surfaceMetricsForInstrumentation()?.submissions ?: 0L) > 0L }
            }
            val bounds = main {
                val field = FluviKeyguardCardService::class.java.getDeclaredField("overlay").apply { isAccessible = true }
                val orb = (field.get(owner) as KeyguardCardWindow).surfaceForTest()
                val visible = Rect()
                if (orb != null && orb.isAttachedToWindow && orb.isShown && orb.holder.surface.isValid &&
                    orb.getGlobalVisibleRect(visible)) {
                    // Accessibility overlay windows have their own origin. The
                    // global visible rect can be root-local, whereas UiAutomation
                    // screenshots use physical screen coordinates.
                    val screen = IntArray(2)
                    orb.getLocationOnScreen(screen)
                    Rect(screen[0], screen[1], screen[0] + orb.width, screen[1] + orb.height)
                } else null
            }
            assertNotNull("NOT REACHED: attached ORB bounds", bounds)
            val first = checkNotNull(ui.takeScreenshot())
            out.resolve("r44-frame-a.png").outputStream().use { first.compress(Bitmap.CompressFormat.PNG, 100, it) }
            SystemClock.sleep(350)
            val second = checkNotNull(ui.takeScreenshot())
            out.resolve("r44-frame-b.png").outputStream().use { second.compress(Bitmap.CompressFormat.PNG, 100, it) }
            val rect = checkNotNull(bounds)
            val left = rect.left.coerceIn(0, first.width - 1); val right = rect.right.coerceIn(left + 1, first.width)
            val top = rect.top.coerceIn(0, first.height - 1); val bottom = rect.bottom.coerceIn(top + 1, first.height)
            var changed = 0
            for (y in top until bottom step 2) for (x in left until right step 2)
                if (first.getPixel(x, y) != second.getPixel(x, y)) changed++
            first.recycle(); second.recycle()
            evidence.append("orbBounds=$rect changedSamples=$changed\n")
            assertTrue("NOT REACHED: distinct pixels in the controlled ORB bounds", changed > 20)
            restrict.set(true)
            main { schedule(owner, "r44-controlled-shade") }
            waitFor("controlled restriction withdrawn") { sawRestriction.get() && main { !owner.inspectionStateForTest().attached } }
            evidence.append("controlledShade=withdrawn\n")
            if (actualControls) {
                // Reacquire a visible synthetic ORB, then remove the injected
                // scene before exercising real AOSP transitions. The observer
                // below never changes snapshots or admission.
                restrict.set(false); sawPositive.set(false)
                main { schedule(owner, "r44-reopen-before-actual-controls") }
                waitFor("controlled ORB reattached before actual controls") {
                    sawPositive.get() && main { owner.inspectionStateForTest().attached &&
                        (owner.surfaceMetricsForInstrumentation()?.submissions ?: 0L) > 0L }
                }
                val actualMain = AtomicBoolean(false)
                val actualPin = AtomicBoolean(false)
                val actualShade = AtomicBoolean(false)
                owner.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        synchronized(evidence) { evidence.append("actual req=${request.id} decision=$decision reason=$reason start=$startedAt end=$finishedAt truncated=$walkTruncated stale=$abortedStale\n") }
                        if (abortedStale) return
                        when (decision) {
                            KeyguardCardVisibility.SHOW_DISCREET, KeyguardCardVisibility.SHOW_FULL -> actualMain.set(true)
                            KeyguardCardVisibility.HIDDEN_CREDENTIAL -> actualPin.set(true)
                            KeyguardCardVisibility.HIDDEN_SHADE -> actualShade.set(true)
                            else -> Unit
                        }
                    }
                }
                fun actualImage(name: String) {
                    val bitmap = ui.takeScreenshot() ?: return
                    out.resolve("$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                    bitmap.recycle()
                    out.resolve("$name-window.txt").writeText(shell("dumpsys window windows"))
                }
                main { schedule(owner, "r44-actual-initial-clock") }
                waitFor("actual AOSP clock admission before restriction") { actualMain.get() && main { owner.inspectionStateForTest().attached } }
                actualImage("actual-clock")
                val pinStart = SystemClock.uptimeMillis()
                shell("input swipe 200 2200 200 500 350")
                waitFor("actual PIN credential decision and withdrawal") { actualPin.get() && main { !owner.inspectionStateForTest().attached } }
                evidence.append("actualPinStart=$pinStart detached=${SystemClock.uptimeMillis()} physicalPixels=UNOBSERVED\n")
                actualImage("actual-pin")
                actualMain.set(false)
                shell("input keyevent KEYCODE_BACK")
                waitFor("actual clock readmission after PIN") { actualMain.get() && main { owner.inspectionStateForTest().attached } }
                actualShade.set(false)
                val shadeStart = SystemClock.uptimeMillis()
                shell("cmd statusbar expand-notifications")
                waitFor("actual notifications decision and withdrawal") { actualShade.get() && main { !owner.inspectionStateForTest().attached } }
                evidence.append("actualNotificationsStart=$shadeStart detached=${SystemClock.uptimeMillis()} physicalPixels=UNOBSERVED\n")
                actualImage("actual-notifications")
                actualMain.set(false)
                shell("cmd statusbar collapse")
                waitFor("actual clock readmission after notifications") { actualMain.get() && main { owner.inspectionStateForTest().attached } }
                actualShade.set(false)
                val qsStart = SystemClock.uptimeMillis()
                shell("cmd statusbar expand-settings")
                waitFor("actual quick settings decision and withdrawal") { actualShade.get() && main { !owner.inspectionStateForTest().attached } }
                evidence.append("actualQuickSettingsStart=$qsStart detached=${SystemClock.uptimeMillis()} physicalPixels=UNOBSERVED\n")
                actualImage("actual-quick-settings")
                shell("cmd statusbar collapse")
            }
            if (capture) {
                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                out.resolve("r44-report.txt").writeText(report)
                assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            }
        } finally {
            release.countDown()
            out.resolve("r44-results.txt").writeText(synchronized(evidence) { evidence.toString() })
            service?.inspectionProbeForTest = null
            if (capture && KeyguardCardDiagnostics.activeCaptureId() != null) runCatching {
                out.resolve("r44-partial-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
            }
            KeyguardCardDiagnostics.clearCapture(context)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            if (pinSet) shell("locksettings clear --old 2468")
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
            val edit = preferences.edit().clear()
            savedSettings.forEach { (key, value) -> when (value) {
                is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value); is Long -> edit.putLong(key, value)
                is Float -> edit.putFloat(key, value); is String -> edit.putString(key, value)
                is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            check(edit.commit())
        }
    }
}
