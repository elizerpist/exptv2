package com.fluvi.app.lockscreen

import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import kotlin.math.abs
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Observation-only probe for the installed update-signed PROFILE app.
 * It deliberately uses no debug-only renderer hook or synthetic permission. */
@RunWith(AndroidJUnit4::class)
class KeyguardR42SignedProfileProbeTest {
    @Test fun signedProfileShowsCurrentGrantedOrbAndNaturalMotion() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        val run = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r42-profile/$run")
        check(dir.mkdirs())
        val automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command))
            .bufferedReader().use { it.readText() }
        fun await(label: String, timeoutMs: Long = 20_000, condition: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + timeoutMs
            while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun singleton(name: String): Any = checkNotNull(Class.forName(name).getDeclaredField("INSTANCE").get(null))
        fun call(owner: Any, prefix: String, vararg values: Any?): Any? {
            val method = owner.javaClass.declaredMethods.single {
                it.name.substringBefore('$') == prefix && it.parameterCount == values.size
            }
            method.isAccessible = true
            return method.invoke(owner, *values)
        }
        val registry = singleton("com.fluvi.app.lockscreen.FluviKeyguardCardServiceRegistry")
        val diagnostics = singleton("com.fluvi.app.lockscreen.KeyguardCardDiagnostics")
        fun service(): Any? = call(registry, "serviceForInstrumentation")
        fun report(): String = ((call(diagnostics, "captureSnapshot", context) as Map<*, *>)["report"] as String)
        fun identityOf(obj: Any): List<Long>? {
            val fields = listOf("ReservationId", "Attachment", "OutputGeneration", "WinningRequestId")
            return fields.map { (call(obj, "get$it") as? Number)?.toLong() ?: return null }
        }
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedServices = shell("settings get secure enabled_accessibility_services").trim()
        val savedEnabled = shell("settings get secure accessibility_enabled").trim()
        val prefs = context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
        val savedPrefs = HashMap(prefs.all)
        var enabledByProbe = false
        val notes = mutableListOf<String>()
        var capture = false
        var failure: Throwable? = null
        try {
            check(!keyguard.isDeviceSecure && (savedLock == "true" || savedLock == "false"))
            if (service() == null) {
                enabledByProbe = true
                check(prefs.edit().putBoolean("requested", true).putBoolean("details", true)
                    .putString("presentationMode", "orb").putString("animationMode", "orbOnly").commit())
                shell("am start -n com.fluvi.app/.MainActivity")
                shell("settings put secure enabled_accessibility_services com.fluvi.app/.lockscreen.FluviKeyguardCardService")
                shell("settings put secure accessibility_enabled 1")
            }
            await("updated service connected") { service() != null }
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked start") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            call(diagnostics, "startCapture", context, source, "profile", "LIGHT")
            capture = true
            shell("input keyevent KEYCODE_SLEEP")
            await("locked sleeping device") { !power.isInteractive && keyguard.isKeyguardLocked }
            val wakeNs = System.nanoTime()
            shell("input keyevent KEYCODE_WAKEUP")
            var owner: Any? = null
            await("current DIRECT owner and matching grant", 30_000) {
                instrumentation.runOnMainSync { owner = service()?.let { call(it, "r22VisualIdentityForTest") } }
                val id = owner?.let(::identityOf)
                val expected = id?.let { "${it[0]}/${it[2]}/${it[3]}" }
                expected != null && report().lineSequence().any {
                    it.startsWith(" R41_CORE ") && it.contains("outcome=SUCCESS") &&
                        it.contains(" owner=$expected ")
                }
            }
            val firstOwner = requireNotNull(owner)
            val identity = requireNotNull(identityOf(firstOwner))
            val bounds = Rect(call(firstOwner, "getBounds") as Rect)
            assertTrue("NOT REACHED: empty ORB bounds", bounds.width() > 8 && bounds.height() > 8)
            notes.add("source=$source wakeNs=$wakeNs owner=$identity bounds=$bounds physical=UNOBSERVED")
            val frames = mutableListOf<Bitmap>()
            repeat(10) { index ->
                if (index > 0) SystemClock.sleep(150)
                var current: Any? = null
                instrumentation.runOnMainSync { current = service()?.let { call(it, "r22VisualIdentityForTest") } }
                val now = checkNotNull(current) { "NOT REACHED: ORB owner detached while sampling" }
                assertEquals(identity, identityOf(now))
                val acquireStartNs = System.nanoTime()
                val screen = checkNotNull(automation.takeScreenshot())
                val acquireEndNs = System.nanoTime()
                assertTrue("NOT REACHED: bounds outside compositor image", bounds.left >= 0 && bounds.top >= 0 &&
                    bounds.right <= screen.width && bounds.bottom <= screen.height)
                val crop = Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
                File(dir, "sample-$index.png").outputStream().use { crop.compress(Bitmap.CompressFormat.PNG, 100, it) }
                notes.add("sample=$index acquireStartNs=$acquireStartNs acquireEndNs=$acquireEndNs width=${crop.width} height=${crop.height}")
                frames.add(crop); screen.recycle()
            }
            fun changed(a: Bitmap, b: Bitmap): Int {
                var count = 0
                val cx = a.width / 2.0; val cy = a.height / 2.0
                val radius = minOf(a.width, a.height) * 0.42
                for (y in 0 until a.height) for (x in 0 until a.width) {
                    if ((x-cx)*(x-cx)+(y-cy)*(y-cy) > radius*radius) continue
                    val p=a.getPixel(x,y); val q=b.getPixel(x,y)
                    if (abs(((p shr 16) and 255)-((q shr 16) and 255)) +
                        abs(((p shr 8) and 255)-((q shr 8) and 255)) + abs((p and 255)-(q and 255)) >= 24) count++
                }
                return count
            }
            val diffs = frames.zipWithNext { a,b -> changed(a,b) }
            frames.forEach(Bitmap::recycle)
            notes.add("adjacentChangedInteriorPixels=$diffs")
            assertTrue("NOT REACHED: distinct natural compositor samples $diffs", diffs.count { it >= 100 } >= 2)
            File(dir, "capture.txt").writeText(report())
        } catch (t: Throwable) {
            failure = t; notes.add("FAIL_OR_NOT_REACHED ${t.javaClass.simpleName}:${t.message}")
        } finally {
            if (capture) runCatching {
                val frozen = (call(diagnostics, "freezeCapture", context) as Map<*, *>)["report"] as String
                File(dir, "capture-frozen.txt").writeText(frozen)
            }
            runCatching { shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard"); shell("locksettings set-disabled $savedLock") }
                .onFailure { if (failure == null) failure = it else notes.add("CLEANUP_FAIL ${it.message}") }
            if (enabledByProbe) runCatching {
                shell("settings put secure enabled_accessibility_services ${if (savedServices == "null") "''" else savedServices}")
                shell("settings put secure accessibility_enabled ${if (savedEnabled == "null") "0" else savedEnabled}")
                val edit=prefs.edit().clear()
                savedPrefs.forEach { (key,value) -> when(value) {
                    is Boolean -> edit.putBoolean(key,value); is Int -> edit.putInt(key,value); is Long -> edit.putLong(key,value)
                    is Float -> edit.putFloat(key,value); is String -> edit.putString(key,value)
                    is Set<*> -> edit.putStringSet(key,value.filterIsInstance<String>().toSet())
                } }
                check(edit.commit())
            }.onFailure { if (failure == null) failure = it else notes.add("CLEANUP_FAIL ${it.message}") }
            File(dir, "sequence.txt").writeText(notes.joinToString("\n", postfix="\n"))
        }
        failure?.let { throw it }
    }
}
