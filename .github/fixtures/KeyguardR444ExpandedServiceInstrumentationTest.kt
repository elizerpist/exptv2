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
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceTarget
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
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
class KeyguardR444ExpandedServiceInstrumentationTest {
    @Test fun syntheticPairUsesRealServiceWithCaptureOff() = exercise(false)
    @Test fun syntheticPairUsesRealServiceWithCaptureOn() = exercise(true)
    @Test fun supersededSyntheticReadCannotGrantAfterRestriction() = exercise(false, staleControl = true)

    private fun exercise(capture: Boolean, staleControl: Boolean = false) {
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
        val positiveRequest = AtomicReference<KeyguardCardInspectionRequest?>()
        val realPosts = ConcurrentHashMap<KeyguardOrbSurfaceTarget, Long>()
        val currentFirst = AtomicReference<KeyguardOrbSurfaceTarget?>()
        val postedPhase = AtomicReference<Pair<KeyguardOrbSurfaceTarget, KeyguardMaterialTime>?>()
        val oldPostHook = KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost
        val oldFirstHook = KeyguardOrbSurfaceWorkerTestHooks.afterCurrentFirstPosted
        val oldPhaseHook = KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime
        val oldFixedPhase = KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime
        val held = CountDownLatch(1)
        val release = CountDownLatch(1)
        var service: FluviKeyguardCardService? = null
        var pinSet = false
        var calibration: KeyguardR22VisualCalibration? = null
        var underlay: Bitmap? = null
        val evidence = StringBuilder("scope=injected_clock_snapshot profile=expanded service=real renderer=real capture=$capture physical=UNOBSERVED\n")
        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
        val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.CLOCK_SWITCH, KeyguardR44Markers.Carrier.VIEW_ID, 2)
        val proof = KeyguardR44WindowEvidence(true, true, host, entry, true, true, false, r444ClockResourceVerified = true)
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
            assertTrue("NOT REACHED: unlocked synthetic trial", main { owner.setR44SyntheticTrial(true, expanded = true) })
            assertTrue(KeyguardR44Trial.active)
            if (!staleControl) {
                calibration = KeyguardR22VisualCalibration(ins, out, ui,
                    checkNotNull(KeyguardR44Trial.profile(null)), discloseFull = false).also { it.calibrate() }
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
                KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { target ->
                    if (target.attachment > 0 && target.holder != null && realPosts.size < 8 &&
                        realPosts.putIfAbsent(target, SystemClock.uptimeMillis()) == null) {
                        android.util.Log.i("FluviR441Probe", "POST capture=$capture run=$uuid attach=${target.attachment} gen=${target.generation} holder=${System.identityHashCode(target.holder)} target=${System.identityHashCode(target)} revoked=${target.revoked}")
                    }
                }
                KeyguardOrbSurfaceWorkerTestHooks.afterCurrentFirstPosted = { target, at ->
                    if (realPosts.containsKey(target)) {
                        currentFirst.set(target)
                        android.util.Log.i("FluviR441Probe", "CURRENT_FIRST capture=$capture run=$uuid attach=${target.attachment} gen=${target.generation} holder=${System.identityHashCode(target.holder)} target=${System.identityHashCode(target)} at=$at")
                    }
                }
                KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = { target, time, _ ->
                    postedPhase.set(target to time)
                }
                // Capture the actual background before allowing the synthetic positive read.
                restrict.set(true)
            }
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
                    if (decision == KeyguardCardVisibility.SHOW_DISCREET && owner.inspectionStateForTest().attached)
                        positiveRequest.compareAndSet(null, request)
                    if (applyCount.incrementAndGet() <= 100) {
                        val attached = owner.inspectionStateForTest().attached
                        val submissions = owner.surfaceMetricsForInstrumentation()?.submissions?.toString() ?: "UNOBSERVED"
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
            waitFor("initial restricted scene has no overlay") { main { !owner.inspectionStateForTest().attached } }
            var backgroundSamples = 0
            waitFor("non-protected visible lockscreen underlay") {
                val candidate = checkNotNull(ui.takeScreenshot())
                // A black protected/pre-render screenshot is not an underlay
                // reference. Use a sparse screen-wide check away from navbar.
                var visible = 0
                for (y in candidate.height / 10 until candidate.height * 9 / 10 step candidate.height / 10)
                    for (x in candidate.width / 10 until candidate.width * 9 / 10 step candidate.width / 10) {
                        val color = candidate.getPixel(x, y)
                        if ((color shr 16 and 255) + (color shr 8 and 255) + (color and 255) > 8) visible++
                    }
                if (backgroundSamples < 8) out.resolve("underlay-probe-${backgroundSamples}.png").outputStream().use {
                    check(candidate.compress(Bitmap.CompressFormat.PNG, 100, it))
                }
                backgroundSamples++
                if (visible >= 16 && main { !owner.inspectionStateForTest().attached }) {
                    underlay = candidate
                    true
                } else { candidate.recycle(); false }
            }
            out.resolve("r44-underlay-full.png").outputStream().use {
                check(underlay!!.compress(Bitmap.CompressFormat.PNG, 100, it))
            }
            restrict.set(false)
            main { schedule(owner, "r44-controlled-positive") }
            waitFor("controlled pair admitted and real ORB posted") {
                sawPositive.get() && positiveRequest.get() != null && currentFirst.get() != null && main {
                    val state = owner.inspectionStateForTest()
                    val field = FluviKeyguardCardService::class.java.getDeclaredField("overlay").apply { isAccessible = true }
                    val window = field.get(owner) as KeyguardCardWindow
                    val target = currentFirst.get()
                    val request = positiveRequest.get()
                    state.attached && target != null && request != null && !target.revoked &&
                        target.attachment == window.currentAttachGeneration &&
                        target.holder === window.surfaceForTest()?.holder &&
                        request.session == state.authority.serviceSession && request.wakeGeneration == state.authority.wakeGeneration
                }
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
            val rect = checkNotNull(bounds)
            val target = checkNotNull(currentFirst.get())
            val request = checkNotNull(positiveRequest.get())
            if (!capture) assertNull("capture OFF must not infer zero from absent metrics", target.metrics)
            val screen = checkNotNull(underlay)
            assertTrue("NOT REACHED: valid screen-space bounds", rect.left >= 0 && rect.top >= 0 &&
                rect.right <= screen.width && rect.bottom <= screen.height)
            val background = Bitmap.createBitmap(screen, rect.left, rect.top, rect.width(), rect.height())
            val references = checkNotNull(calibration)
            try {
                fun sample(label: String, phase: KeyguardMaterialTime, reference: Bitmap): Bitmap {
                    KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = phase
                    waitFor("matching current $label producer post") {
                        val post = postedPhase.get()
                        post != null && post.first === target && post.second == phase && !target.revoked
                    }
                    return references.awaitServiceMatch("service-$label", rect, reference, background)
                }
                val a = sample("a", KeyguardR22VisualCalibration.timeA, references.a)
                val b = sample("b", KeyguardR22VisualCalibration.timeB, references.b)
                val again = sample("return-a", KeyguardR22VisualCalibration.timeA, references.a)
                assertTrue("calibrated A and B do not differ", KeyguardR22VisualCalibration.compare(a, b).meaningful())
                assertTrue("return A differs", KeyguardR22VisualCalibration.compare(a, again).nearlyEqual())
                evidence.append("request=${request.id} session=${request.session} wake=${request.wakeGeneration} " +
                    "attachment=${target.attachment} generation=${target.generation} holder=${System.identityHashCode(target.holder)} " +
                    "post=${realPosts[target]} firstCurrent=true bounds=$rect optical=A/B/A\n")
            } finally { background.recycle() }
            restrict.set(true)
            main { schedule(owner, "r44-controlled-shade") }
            waitFor("controlled restriction withdrawn") { sawRestriction.get() && main { !owner.inspectionStateForTest().attached } }
            evidence.append("controlledShade=withdrawn\n")
            if (capture) {
                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                out.resolve("r44-report.txt").writeText(report)
                assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            }
        } finally {
            release.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = oldPostHook
            KeyguardOrbSurfaceWorkerTestHooks.afterCurrentFirstPosted = oldFirstHook
            KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = oldPhaseHook
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = oldFixedPhase
            calibration?.close()
            underlay?.recycle()
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
