package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.InputDevice
import android.view.KeyEvent
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inspector.WindowInspector
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceTarget
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/** A bounded real-service holder control. Screen samples are archived raw;
 * without independent calibrated references they remain UNCLASSIFIED and do
 * not qualify compositor privacy or physical presentation. */
@RunWith(AndroidJUnit4::class)
class KeyguardR15HeldCanvasInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private lateinit var automation: UiAutomation
    private val evidence = StringBuilder()

    @Test fun r15EnteredCanvasSurvivesActualServiceWithdrawal() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val arguments = InstrumentationRegistry.getArguments()
        val source = requireNotNull(arguments.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val harness = requireNotNull(arguments.getString("harnessSha"))
        require(harness.matches(Regex("[0-9a-f]{40}")))
        assertEquals("SURFACE_LIVE", arguments.getString("r12Mode"))
        val runId = UUID.fromString(requireNotNull(arguments.getString("runUuid"))).toString()
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        val output = File(context.filesDir, "keyguard-service-probe/r15-held/$runId")
        check(!output.exists() && output.mkdirs()) { "specimen directory was reused" }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        fun otherServices(): String = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val claimed = AtomicBoolean(false)
        val targetRef = AtomicReference<KeyguardOrbSurfaceTarget?>()
        val barrierFailure = AtomicReference<Throwable?>()
        var captureStarted = false
        var captureId = "UNOBSERVED"
        var background: Bitmap? = null
        var before: Bitmap? = null
        var during: Bitmap? = null
        var after: Bitmap? = null
        var fixtureFailure: Throwable? = null
        var unlockThread: Thread? = null
        try {
            assertFalse("test needs a fresh production service", FluviKeyguardCardServiceRegistry.connected)
            assertFalse("test requires an insecure disposable keyguard", keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("initial unlocked state", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                    "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
            captureStarted = true
            captureId = capture["captureId"].toString()
            record("PROCESS", "source=$source harness=$harness run=$runId capture=$captureId " +
                "pid=${android.os.Process.myPid()} route=SURFACE_LIVE physical=UNOBSERVED")
            synchronizedKey(KeyEvent.KEYCODE_SLEEP)
            await("locked sleep", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            synchronizedKey(KeyEvent.KEYCODE_WAKEUP)
            await("locked wake before service", 8_000) { power.isInteractive && keyguard.isKeyguardLocked }
            background = screen(output, "background-before-service")
            val services = listOf(otherServices(), component.flattenToString()).filter { it.isNotBlank() }.joinToString(":")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("production service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            await("actual LIVE target and completed producer post", 25_000) {
                var ready = false
                instrumentation.runOnMainSync {
                    val service = FluviKeyguardCardServiceRegistry.serviceForInstrumentation()
                    val status = service?.renderModeStatus()
                    ready = status?.visible == true && status.effective == KeyguardOrbRenderMode.SURFACE_LIVE &&
                        (service.surfaceMetricsForInstrumentation()?.submissions ?: 0) > 0
                }
                ready
            }
            lateinit var bounds: Rect
            var attachment = 0L
            instrumentation.runOnMainSync {
                val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
                attachment = service.inspectionStateForTest().authority.attachGeneration
                val roots = WindowInspector.getGlobalWindowViews().filter {
                    (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                }
                fun surfaces(view: View): List<SurfaceView> =
                    (if (view is SurfaceView && view.holder.surface.isValid) listOf(view) else emptyList()) +
                        (if (view is ViewGroup) (0 until view.childCount).flatMap { surfaces(view.getChildAt(it)) } else emptyList())
                val surface = roots.flatMap(::surfaces).single()
                check(surface.isAttachedToWindow && surface.display?.displayId == Display.DEFAULT_DISPLAY)
                val position = IntArray(2)
                surface.getLocationOnScreen(position)
                bounds = Rect(position[0], position[1], position[0] + surface.width, position[1] + surface.height)
                check(attachment > 0 && bounds.width() > 0 && bounds.height() > 0)
            }
            before = screen(output, "visible-before-hold")
            checkBounds(bounds, requireNotNull(before))
            crop(output, "visible-before-hold-crop", requireNotNull(before), bounds)
            crop(output, "background-before-service-crop", requireNotNull(background), bounds)
            record("TARGET", "attachment=$attachment display=0 bounds=${bounds.flattenToString()} " +
                "before=visible-before-hold.png background=background-before-service.png pixelClassification=UNCLASSIFIED")
            KeyguardR14ForensicProbe.arm(attachment)
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.attachment == attachment && target.live && target.full && claimed.compareAndSet(false, true)) {
                    targetRef.set(target)
                    entered.countDown()
                    try {
                        check(release.await(25, TimeUnit.SECONDS)) { "test did not release Canvas barrier" }
                    } catch (error: Throwable) { barrierFailure.set(error) }
                }
            }
            check(entered.await(15, TimeUnit.SECONDS)) { "real authorized holder did not reach lock boundary" }
            val target = checkNotNull(targetRef.get())
            val held = checkNotNull(target.metrics).holderSnapshot()
            check(held.coherent && held.lockReturn != null && held.postEnter == null)
            record("HELD", "attachment=${target.attachment} generation=${target.generation} " +
                "holder=${System.identityHashCode(target.holder)} op=${held.id} lock=${held.lockEnter}/${held.lockReturn}")
            val unlockFailure = AtomicReference<Throwable?>()
            val unlock = Thread({ runCatching { shell("wm dismiss-keyguard") }.onFailure(unlockFailure::set) }, "r15-unlock")
            unlockThread = unlock
            unlock.start()
            await("real local hide while worker held", 12_000) {
                val stages = KeyguardR14ForensicProbe.snapshot().map { it.stage }.toSet()
                KeyguardR14ForensicProbe.INVISIBLE in stages && KeyguardR14ForensicProbe.REMOVE_BEGIN in stages
            }
            val marksBeforeRelease = KeyguardR14ForensicProbe.snapshot()
            val local = marksBeforeRelease.single { it.stage == KeyguardR14ForensicProbe.INVISIBLE }
            val removeBegin = marksBeforeRelease.single { it.stage == KeyguardR14ForensicProbe.REMOVE_BEGIN }
            check(local.attachment == attachment && removeBegin.attachment == attachment)
            during = screen(output, "screen-after-local-hide-worker-held")
            checkBounds(bounds, requireNotNull(during))
            crop(output, "screen-after-local-hide-worker-held-crop", requireNotNull(during), bounds)
            val releaseAt = SystemClock.uptimeMillis()
            release.countDown()
            unlock.join(10_000)
            check(!unlock.isAlive) { "unlock command did not finish" }
            unlockFailure.get()?.let { throw AssertionError("unlock command failed", it) }
            await("actual remove returned", 15_000) {
                KeyguardR14ForensicProbe.snapshot().any { it.stage == KeyguardR14ForensicProbe.REMOVE_RETURN }
            }
            await("old holder post returned and was recorded", 15_000) {
                target.metrics?.holderSnapshot()?.let { it.postReturn != null && it.recordAt != null } == true
            }
            barrierFailure.get()?.let { throw AssertionError("worker barrier failed", it) }
            val final = checkNotNull(target.metrics).holderSnapshot()
            val remove = KeyguardR14ForensicProbe.snapshot().single { it.stage == KeyguardR14ForensicProbe.REMOVE_RETURN }
            check(final.coherent && final.id == held.id && final.revokeBegin != null && final.revokeReturn != null &&
                final.postEnter != null && final.postReturn != null && final.recordAt != null)
            check(held.lockReturn!! <= final.revokeBegin!! && final.revokeReturn!! <= final.postReturn!! &&
                local.uptimeMs <= releaseAt && releaseAt <= final.postReturn!!)
            check(remove.attachment == attachment && remove.extra == 1)
            await("keyguard unlocked", 8_000) { !keyguard.isKeyguardLocked }
            after = screen(output, "screen-after-remove")
            checkBounds(bounds, requireNotNull(after))
            crop(output, "screen-after-remove-crop", requireNotNull(after), bounds)
            record("HOLDER", "attachment=${target.attachment} generation=${target.generation} " +
                "holder=${System.identityHashCode(target.holder)} op=${final.id} lock=${final.lockEnter}/${final.lockReturn} " +
                "draw=${final.drawReturn} post=${final.postEnter}/${final.postReturn} record=${final.recordAt} " +
                "revoke=${final.revokeBegin}/${final.revokeReturn} local=${local.uptimeMs} " +
                "remove=${removeBegin.uptimeMs}/${remove.uptimeMs} released=$releaseAt")
            record("RESULT", "PASS holder_boundary_only pixelClassification=UNCLASSIFIED physicalPresentation=UNOBSERVED")
        } catch (error: Throwable) {
            fixtureFailure = error
            record("RESULT", "FAIL ${error.javaClass.simpleName}:${error.message}")
            throw error
        } finally {
            release.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            KeyguardR14ForensicProbe.disarm()
            runCatching {
                unlockThread?.let { it.join(5_000); check(!it.isAlive) { "unlock thread survived cleanup" } }
            }.onFailure { if (fixtureFailure == null) fixtureFailure = it }
            listOfNotNull(background, before, during, after).forEach(Bitmap::recycle)
            if (captureStarted) runCatching {
                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
            }.onFailure { if (fixtureFailure == null) fixtureFailure = it }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
                await("service disconnect", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP")
                shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { if (fixtureFailure == null) fixtureFailure = it }
            File(output, "fixture.txt").writeText(evidence.toString())
            if (fixtureFailure != null && fixtureFailure !is AssertionError) throw AssertionError("held Canvas fixture failed", fixtureFailure)
        }
    }

    private fun record(stage: String, detail: String) { evidence.appendLine("R15 stage=$stage up=${SystemClock.uptimeMillis()} $detail") }
    private fun screen(output: File, label: String): Bitmap {
        val start = SystemClock.uptimeMillis()
        val image = checkNotNull(automation.takeScreenshot()) { "$label screenshot unavailable" }
        val end = SystemClock.uptimeMillis()
        check(File(output, "$label.png").outputStream().use { image.compress(Bitmap.CompressFormat.PNG, 100, it) })
        record("SCREEN", "name=$label start=$start end=$end width=${image.width} height=${image.height} display=0 classification=UNCLASSIFIED")
        return image
    }
    private fun checkBounds(bounds: Rect, screen: Bitmap) {
        check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= screen.width && bounds.bottom <= screen.height)
    }
    private fun crop(output: File, label: String, screen: Bitmap, bounds: Rect) {
        Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height()).let { bitmap ->
            try { check(File(output, "$label.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }) }
            finally { bitmap.recycle() }
        }
    }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun synchronizedKey(keyCode: Int) {
        val downAt = SystemClock.uptimeMillis()
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            val event = KeyEvent(downAt, SystemClock.uptimeMillis(), action, keyCode, 0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD)
            check(automation.injectInputEvent(event, true))
        }
    }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) } finally { automation.dropShellPermissionIdentity() }
    }
    private fun await(label: String, timeout: Long, condition: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
        error("$label timed out")
    }
    private fun preferences(name: String): Pair<SharedPreferences, Map<String, *>> =
        context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
    private fun restore(saved: Pair<SharedPreferences, Map<String, *>>) {
        val edit = saved.first.edit().clear()
        saved.second.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value); is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value); is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        check(edit.commit())
    }
    private fun materialProfile(): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "r15-holder-control", "publisherRevision" to 1L, "sceneIdentity" to "fixture|balance|month",
        "effectId" to "dualTide", "effectShaderId" to 1, "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
        "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 }, "background" to portal(true), "interior" to portal(false),
        "referenceWidth" to 390.0, "referenceHeight" to 220.0,
    )
    private fun portal(enabled: Boolean): Map<String, Any> = mapOf("enabled" to enabled, "effectIndex" to 0,
        "phase" to 0.0, "phaseSpeed" to .2, "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
}
