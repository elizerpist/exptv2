package com.fluvi.app.lockscreen

import android.Manifest
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Rect
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.provider.Settings
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.abs
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Synthetic Flutter-authored references and actual compositor pixels. This
 * independently exercises the two production presenters, but an app-owned
 * host is not stock-keyguard admission or physical-phone qualification. */
@RunWith(AndroidJUnit4::class)
class KeyguardR47VisualInstrumentationTest {
    @Test fun directPresenterMatchesFlutterAndWithdraws() = exercise(direct = true)
    @Test fun waPresenterMatchesFlutterAndWithdraws() = exercise(direct = false)

    private data class Delta(val count: Int, val mean: Double, val within16: Double, val changed: Int)

    private fun compare(expected: Bitmap, actual: Bitmap): Delta {
        check(expected.width == actual.width && expected.height == actual.height)
        val size = actual.width
        var count = 0; var sum = 0L; var close = 0; var changed = 0
        for (y in 0 until size) for (x in 0 until size) {
            val dx = x + .5 - size / 2.0; val dy = y + .5 - size / 2.0
            if (dx * dx + dy * dy >= size * size * .1764) continue
            val a = expected.getPixel(x, y); val b = actual.getPixel(x, y)
            val dr = abs(Color.red(a) - Color.red(b)); val dg = abs(Color.green(a) - Color.green(b))
            val db = abs(Color.blue(a) - Color.blue(b)); val peak = maxOf(dr, dg, db)
            count++; sum += dr + dg + db
            if (peak <= 16) close++
            if (peak >= 7) changed++
        }
        check(count > 200)
        return Delta(count, sum.toDouble() / (count * 3), close.toDouble() / count, changed)
    }

    private fun exercise(direct: Boolean) {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val app = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val id = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(app.filesDir, "keyguard-service-probe/r43/$id").apply { check(mkdirs()) }
        val log = StringBuilder("route=${if (direct) "DIRECT" else "WA"} host=app-owned source=synthetic_flutter\n")
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd)).bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(app.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, predicate: () -> Boolean) {
            val until = SystemClock.uptimeMillis() + 12_000
            while (SystemClock.uptimeMillis() < until) { if (predicate()) return; SystemClock.sleep(25) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val result = AtomicReference<T>(); ins.runOnMainSync { result.set(block()) }; return result.get()
        }
        fun save(name: String, bitmap: Bitmap) = File(out, "$name.png").outputStream().use {
            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it))
        }
        fun crop(name: String, bounds: Rect): Bitmap {
            val before = SystemClock.uptimeMillis()
            val full = checkNotNull(ui.takeScreenshot())
            try {
                check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= full.width && bounds.bottom <= full.height)
                val result = Bitmap.createBitmap(full, bounds.left, bounds.top, bounds.width(), bounds.height())
                save(name, result)
                log.append("sample=$name before=$before after=${SystemClock.uptimeMillis()} bounds=$bounds\n")
                return result
            } finally { full.recycle() }
        }
        fun asset(name: String, size: Int): Bitmap {
            val input = ins.context.assets.open("r47_reference/$name.png")
            val original = input.use { checkNotNull(BitmapFactory.decodeStream(it)) }
            return Bitmap.createScaledBitmap(original, size, size, true).also { if (it !== original) original.recycle() }
        }
        fun exteriorMatches(underlay: Bitmap, candidate: Bitmap): Boolean {
            val size = candidate.width
            return listOf(2 to 2, size - 3 to 2, 2 to size - 3, size - 3 to size - 3).all { (x, y) ->
                val a = underlay.getPixel(x, y); val b = candidate.getPixel(x, y)
                maxOf(abs(Color.red(a) - Color.red(b)), abs(Color.green(a) - Color.green(b)),
                    abs(Color.blue(a) - Color.blue(b))) <= 8
            }
        }
        val services = Settings.Secure.getString(app.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val enabled = Settings.Secure.getString(app.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val component = ComponentName(app, FluviKeyguardCardService::class.java)
        var activity: KeyguardMaterialTestActivity? = null
        var presenter: KeyguardR446WindowPresenter? = null
        var frame: KeyguardR448WidgetsAnywhereFrame? = null
        var frameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
        val heldBitmaps = mutableListOf<Bitmap>()
        val failures = mutableListOf<String>()
        try {
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            val others = services.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("actual accessibility service") { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            activity = ins.startActivitySync(Intent(app, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val host = checkNotNull(activity)
            main { host.setContentView(FrameLayout(host).apply { setBackgroundColor(Color.rgb(11, 177, 67)) }) }
            ins.waitForIdleSync()
            var hostId = -1
            val hostBounds = Rect()
            waitFor("measured active host") {
                val windows = service.windows
                try {
                    val found = windows.firstOrNull { w ->
                        val root = w.root
                        try { w.isActive && root?.packageName?.toString() == app.packageName }
                        finally { root?.recycle() }
                    }
                    if (found == null) false else { hostId = found.id; found.getBoundsInScreen(hostBounds); true }
                } finally { windows.forEach { it.recycle() } }
            }
            val size = app.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val left = hostBounds.left + (hostBounds.width() - size) / 2
            val top = hostBounds.top + (hostBounds.height() - size) / 2
            val bounds = Rect(left, top, left + size, top + size)
            val geometry = KeyguardOverlayGeometry(size, size, left, top,
                KeyguardUsableBounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom),
                KeyguardCardCardPosition(.5f), KeyguardCardOrbPosition(.5f, .5f))
            var stableUnderlay: Bitmap? = null
            var underlayAttempt = 0
            waitFor("stable green underlay at all measured points") {
                val candidate = crop("underlay-attempt${underlayAttempt++}", bounds).also(heldBitmaps::add)
                val points = listOf(2 to 2, size - 3 to 2, 2 to size - 3, size - 3 to size - 3,
                    size / 2 to size / 2)
                val isGreen = points.all { (x, y) ->
                    val pixel = candidate.getPixel(x, y)
                    abs(Color.red(pixel) - 11) <= 5 && abs(Color.green(pixel) - 177) <= 5 &&
                        abs(Color.blue(pixel) - 67) <= 5
                }
                log.append("underlayPrecondition attempt=${underlayAttempt - 1} green=$isGreen\n")
                if (isGreen) stableUnderlay = candidate
                isGreen
            }
            val underlay = checkNotNull(stableUnderlay)
            val times = listOf(0, 200, 500, 1000, 1900, 6000)
            for ((index, name) in listOf("tide", "braided", "static").withIndex()) {
                val json = ins.context.assets.open("r47_reference/$name.json").bufferedReader().use { it.readText() }
                val profile = checkNotNull(KeyguardMaterialProfile.fromJson(json))
                val snapshot = FluviActiveHeaderMaterialStore.Snapshot.create(profile, 1, "balance", 0, true)
                val artifact = AndroidKeyguardShaderArtifactReader.load(app, profile.effectId, profile.usesPortal)
                val elapsedMs = AtomicLong(0)
                val liveStartNs = AtomicLong(0)
                val live = AtomicBoolean(false)
                val lastTime = AtomicReference<KeyguardMaterialTime>()
                val lastFrameNs = AtomicLong(0)
                val source = KeyguardMaterialTimeSource { _, frameNs ->
                    val seconds = if (live.get()) (frameNs - liveStartNs.get()).coerceAtLeast(0) / 1_000_000_000f
                        else elapsedMs.get() / 1000f
                    KeyguardMaterialTime(profile.elapsedSeconds + seconds, profile.phase + profile.phaseSpeed * seconds,
                        profile.background.phase + profile.background.phaseSpeed * seconds,
                        profile.interior.phase + profile.interior.phaseSpeed * seconds).also {
                            lastTime.set(it); lastFrameNs.set(frameNs)
                        }
                }
                val allowed = AtomicBoolean(true)
                val draws = AtomicInteger()
                val token = Any()
                if (direct) {
                    main {
                        presenter = KeyguardR446WindowPresenter(service, source)
                        assertTrue(checkNotNull(presenter).prepareActiveHeader(checkNotNull(host.display), snapshot, artifact))
                    }
                    waitFor("direct input region") { main { checkNotNull(presenter).inputReadyForInstrumentation() } }
                    val target = KeyguardR446Target(hostId, 0,
                        KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
                    main {
                        assertEquals("SUBMITTED", checkNotNull(presenter).show(token, target, geometry,
                            valid = { allowed.get() }, stillOwned = { allowed.get() },
                            onFirstTraversal = { draws.incrementAndGet() }, onFirstDraw = {}).status)
                    }
                } else {
                    val owner = KeyguardR448WidgetsAnywhereFrame.Owner(100L + index, 1, 200L + index)
                    frameOwner = owner
                    main {
                        frame = KeyguardR448WidgetsAnywhereFrame(service, source)
                        assertTrue(checkNotNull(frame).prepareActiveHeader(owner, snapshot, artifact) {
                            if (it.stage == "FIRST_DRAW") draws.incrementAndGet()
                        })
                        assertTrue(checkNotNull(frame).requestShow(owner, geometry) { allowed.get() })
                    }
                }
                waitFor("$name actual draw") { draws.get() > 0 }
                val observed = mutableListOf<Bitmap>()
                for (time in times) {
                    elapsedMs.set(time.toLong())
                    val reference = asset("$name-$time", size).also(heldBitmaps::add)
                    var accepted: Bitmap? = null
                    repeat(8) { attempt ->
                        if (accepted == null) {
                            SystemClock.sleep(75)
                            val image = crop("$name-$time-attempt$attempt", bounds).also(heldBitmaps::add)
                            val delta = compare(reference, image)
                            val exterior = exteriorMatches(underlay, image)
                            log.append("match=$name/$time/$attempt delta=$delta exterior=$exterior\n")
                            val matches = if (name == "static") delta.mean <= 5.0 && delta.within16 >= .97
                                else delta.mean <= 1.0 && delta.within16 >= .99
                            if (matches && exterior) accepted = image
                        }
                    }
                    if (accepted == null) failures += "$name $time did not match Flutter interior reference"
                    observed += accepted ?: heldBitmaps.last()
                }
                val change = compare(observed[0], observed[4])
                if (name == "static" && change.mean > 2.0) failures += "static negative changed: $change"
                if (name != "static" && (change.changed < 64 || change.mean < 1.0))
                    failures += "moving reference produced no visible interior change: $change"
                if (name != "static") {
                    liveStartNs.set(System.nanoTime()); live.set(true)
                    SystemClock.sleep(150)
                    val first = crop("$name-natural-start", bounds).also(heldBitmaps::add)
                    val firstTime = lastTime.get(); val firstFrame = lastFrameNs.get()
                    val firstDraws = main { if (direct) presenter?.shaderDrawCountForInstrumentation() ?: 0
                        else frame?.shaderDrawCountForInstrumentation() ?: 0 }
                    SystemClock.sleep(6_000)
                    val later = crop("$name-natural-6s", bounds).also(heldBitmaps::add)
                    val laterTime = lastTime.get(); val laterFrame = lastFrameNs.get()
                    val laterDraws = main { if (direct) presenter?.shaderDrawCountForInstrumentation() ?: 0
                        else frame?.shaderDrawCountForInstrumentation() ?: 0 }
                    val changeNatural = compare(first, later)
                    log.append("natural=$name delta=$changeNatural sourceStart=$firstTime sourceEnd=$laterTime " +
                        "frameNs=$firstFrame/$laterFrame shaderDraws=$firstDraws/$laterDraws\n")
                    if (firstTime == null || laterTime == null || laterTime.phase - firstTime.phase < 1f || laterDraws <= firstDraws)
                        failures += "six-second source clock or shader draw did not advance"
                    if (changeNatural.changed < 64 || changeNatural.mean < 1.0)
                        failures += "six-second live interior did not move: $changeNatural"
                }
                allowed.set(false)
                main {
                    if (direct) checkNotNull(presenter).conceal(token)
                    else assertTrue(checkNotNull(frame).conceal(checkNotNull(frameOwner), "CONTROL_RESTRICTED"))
                }
                val after = crop("$name-after-hide-first", bounds).also(heldBitmaps::add)
                val withdrawal = compare(underlay, after)
                log.append("firstAfterHide=$name delta=$withdrawal\n")
                if (withdrawal.mean > 2.0) failures += "first sample after hide differs from underlay: $withdrawal"
                for (laterIndex in 1..3) {
                    SystemClock.sleep(50)
                    val later = crop("$name-after-hide-$laterIndex", bounds).also(heldBitmaps::add)
                    log.append("laterAfterHide=$name/$laterIndex delta=${compare(underlay, later)}\n")
                }
                main {
                    presenter?.dispose(); presenter = null
                    frame?.retire(checkNotNull(frameOwner), "CONTROL_DONE"); frame = null; frameOwner = null
                }
            }
            assertTrue(failures.joinToString("\n"), failures.isEmpty())
        } finally {
            main {
                presenter?.dispose()
                frameOwner?.let { frame?.retire(it, "CLEANUP") }
                activity?.finish()
            }
            heldBitmaps.forEach { if (!it.isRecycled) it.recycle() }
            File(out, "r47-visual.txt").writeText(log.toString() + failures.joinToString("\n", prefix = "failures=\n", postfix = "\n"))
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, enabled)
        }
    }
}
