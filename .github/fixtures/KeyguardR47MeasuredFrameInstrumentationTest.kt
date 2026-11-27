package com.fluvi.app.lockscreen

import android.Manifest
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
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
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.abs
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Real presenters and compositor over an app-owned host. The Flutter PNGs
 * are synthetic reference inputs, not the owner's on-phone header. This forces
 * a package through the native player; separate Dart tests verify loop admission. */
@RunWith(AndroidJUnit4::class)
class KeyguardR47MeasuredFrameInstrumentationTest {
    @Test fun directMeasuredPreparedFrameAndWithdrawal() = exercise(true)
    @Test fun waMeasuredPreparedFrameAndWithdrawal() = exercise(false)

    private fun value(item: Any?): Any? = when (item) {
        JSONObject.NULL, null -> null
        is JSONObject -> item.keys().asSequence().associateWith { value(item.get(it)) }
        is JSONArray -> (0 until item.length()).map { value(item.get(it)) }
        else -> item
    }

    private fun restore(prefs: SharedPreferences, original: Map<String, *>) {
        val edit = prefs.edit().clear()
        for ((key, v) in original) when (v) {
            is Boolean -> edit.putBoolean(key, v)
            is String -> edit.putString(key, v)
            is Int -> edit.putInt(key, v)
            is Long -> edit.putLong(key, v)
            is Float -> edit.putFloat(key, v)
            is Set<*> -> edit.putStringSet(key, v.filterIsInstance<String>().toSet())
        }
        check(edit.commit())
    }

    private fun exercise(direct: Boolean) {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val app = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val id = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(app.filesDir, "keyguard-service-probe/r43/$id").apply { check(mkdirs()) }
        val log = StringBuilder("route=${if (direct) "DIRECT" else "WA"} host=app-owned " +
            "source=synthetic_flutter preparedPackage=forced_player_control fixture=measured_bounds\n")
        val failures = mutableListOf<String>()
        val held = mutableListOf<Bitmap>()
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd)).bufferedReader().use { it.readText() }
        fun secure(key: String, v: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(app.contentResolver, key, v)) }
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
        fun bytes(name: String): ByteArray = ins.context.assets.open("r47_reference/$name.png").use { it.readBytes() }
        fun image(name: String, size: Int): Bitmap {
            val data = bytes(name); val raw = checkNotNull(BitmapFactory.decodeByteArray(data, 0, data.size))
            return Bitmap.createScaledBitmap(raw, size, size, true).also { if (it !== raw) raw.recycle(); held.add(it) }
        }
        fun crop(name: String, bounds: Rect): Bitmap {
            val before = SystemClock.uptimeMillis(); val screen = checkNotNull(ui.takeScreenshot())
            try {
                check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= screen.width && bounds.bottom <= screen.height)
                val result = Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
                File(out, "$name.png").outputStream().use { check(result.compress(Bitmap.CompressFormat.PNG, 100, it)) }
                log.append("sample=$name before=$before after=${SystemClock.uptimeMillis()} bounds=$bounds\n")
                held.add(result); return result
            } finally { screen.recycle() }
        }
        fun difference(a: Bitmap, b: Bitmap): Pair<Double, Int> {
            check(a.width == b.width && a.height == b.height)
            val size = a.width; var count = 0; var sum = 0L; var changed = 0
            for (y in 0 until size) for (x in 0 until size) {
                val dx = x + .5 - size / 2.0; val dy = y + .5 - size / 2.0
                if (dx * dx + dy * dy >= size * size * .1764) continue
                val c = a.getPixel(x, y); val d = b.getPixel(x, y)
                val dr = abs(Color.red(c) - Color.red(d)); val dg = abs(Color.green(c) - Color.green(d))
                val db = abs(Color.blue(c) - Color.blue(d)); sum += dr + dg + db; count++
                if (maxOf(dr, dg, db) >= 7) changed++
            }
            check(count > 200); return sum.toDouble() / (count * 3) to changed
        }
        fun exteriorMatches(a: Bitmap, b: Bitmap): Boolean {
            val size = a.width
            return listOf(2 to 2, size - 3 to 2, 2 to size - 3, size - 3 to size - 3).all { (x, y) ->
                val c = a.getPixel(x, y); val d = b.getPixel(x, y)
                maxOf(abs(Color.red(c) - Color.red(d)), abs(Color.green(c) - Color.green(d)),
                    abs(Color.blue(c) - Color.blue(d))) <= 8
            }
        }
        val messenger = object : BinaryMessenger {
            override fun send(channel: String, message: ByteBuffer?) = Unit
            override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit
            override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) = Unit
        }
        val channel = MethodChannel(messenger, "r47-prepared-control")
        val prefs = app.getSharedPreferences("fluvi_native_keyguard_card", 0)
        val originalPrefs = prefs.all.toMap()
        val services = Settings.Secure.getString(app.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val enabled = Settings.Secure.getString(app.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val component = ComponentName(app, FluviKeyguardCardService::class.java)
        var activity: KeyguardMaterialTestActivity? = null
        var presenter: KeyguardR446WindowPresenter? = null
        var frame: KeyguardR448WidgetsAnywhereFrame? = null
        var frameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
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
            var hostId = -1; val hostBounds = Rect()
            waitFor("measured active host") {
                val windows = service.windows
                try {
                    val found = windows.firstOrNull { w ->
                        val root = w.root
                        try { w.isActive && root?.packageName?.toString() == app.packageName } finally { root?.recycle() }
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
            var underlay: Bitmap? = null; var attempt = 0
            waitFor("stable green host underlay") {
                val sample = crop("underlay-${attempt++}", bounds)
                val points = listOf(2 to 2, size - 3 to 2, 2 to size - 3, size - 3 to size - 3,
                    size / 2 to size / 2)
                val ok = points.all { (x, y) ->
                    val c = sample.getPixel(x, y)
                    abs(Color.red(c) - 11) <= 5 && abs(Color.green(c) - 177) <= 5 && abs(Color.blue(c) - 67) <= 5
                }
                if (ok) underlay = sample
                ok
            }
            val nominalBounds = Rect(bounds)
            val calibration = checkNotNull(ui.takeScreenshot()).also { held.add(it) }
            val search = Rect((bounds.left - size / 2).coerceAtLeast(0), (bounds.top - size / 2).coerceAtLeast(0),
                (bounds.right + size / 2).coerceAtMost(calibration.width), (bounds.bottom + size / 2).coerceAtMost(calibration.height))
            for (y in search.top until search.bottom step 8) for (x in search.left until search.right step 8) {
                val color = calibration.getPixel(x, y)
                check(abs(Color.red(color) - 11) <= 5 && abs(Color.green(color) - 177) <= 5 &&
                    abs(Color.blue(color) - 67) <= 5) { "NOT REACHED: expanded green witness contains a foreign pixel at $x,$y" }
            }
            File(out, "calibration-full.png").outputStream().use { check(calibration.compress(Bitmap.CompressFormat.PNG, 100, it)) }
            check(prefs.edit().putBoolean("requested", true).putBoolean("details", true)
                .putBoolean("focusMigrated", true).putLong("generation", 42).commit())
            val epoch = FluviKeyguardMaterialBridgeRegistry.connect(channel)
            val profile = value(JSONObject(ins.context.assets.open("r47_reference/tide.json").bufferedReader().use { it.readText() }))
                as Map<*, *>
            val input = profile.toMutableMap().apply { put("publisherInstance", 1L); put("activeMode", "balance"); put("modeEpoch", 0L) }
            val session = input["publisherSession"] as String
            assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, session))
            val receipt = FluviActiveHeaderMaterialStore.publish(app, input, epoch, true)
            assertTrue(receipt.reason, receipt.accepted)
            val frameInput = mapOf("token" to requireNotNull(receipt.token), "publisherSession" to session,
                "publisherInstance" to 1L, "publisherRevision" to 1L, "animated" to true, "loopStatus" to "accepted",
                "intervalMs" to 3_000, "frameSizePx" to 120,
                "frames" to listOf(bytes("tide-0"), bytes("tide-1900"), bytes("tide-0")))
            val admission = FluviActiveHeaderMaterialStore.admitFrames(app, frameInput, epoch)
            val request = requireNotNull(admission.request) { admission.reason }
            val decoded = requireNotNull(FluviActiveHeaderMaterialStore.decodeFrames(request))
            assertTrue(FluviActiveHeaderMaterialStore.commitFrames(app, request, decoded))
            val snapshot = checkNotNull(FluviActiveHeaderMaterialStore.applicable(app))
            val artifact = AndroidKeyguardShaderArtifactReader.load(app, snapshot.profile.effectId, snapshot.profile.usesPortal)
            val allowed = AtomicBoolean(true); val draws = AtomicInteger(); val frameDraws = AtomicInteger()
            val token = Any()
            if (direct) {
                main { presenter = KeyguardR446WindowPresenter(service)
                    assertTrue(checkNotNull(presenter).prepareActiveHeader(checkNotNull(host.display), snapshot, artifact))
                    assertTrue("package route selected", checkNotNull(presenter).usesPreparedFrames())
                    assertTrue(checkNotNull(presenter).activeHeaderTelemetry()?.contains("origin=active_header_frame_package") == true) }
                waitFor("direct input region") { main { checkNotNull(presenter).inputReadyForInstrumentation() } }
                val target = KeyguardR446Target(hostId, 0,
                    KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
                main { assertEquals("SUBMITTED", checkNotNull(presenter).show(token, target, geometry,
                    valid = { allowed.get() }, stillOwned = { allowed.get() },
                    onFirstTraversal = { draws.incrementAndGet() }, onFirstDraw = { frameDraws.incrementAndGet() }).status) }
            } else {
                val owner = KeyguardR448WidgetsAnywhereFrame.Owner(1, 1, 1); frameOwner = owner
                main { frame = KeyguardR448WidgetsAnywhereFrame(service)
                    assertTrue(checkNotNull(frame).prepareActiveHeader(owner, snapshot, artifact) {
                        if (it.stage == "FIRST_DRAW") draws.incrementAndGet()
                        if (it.stage == "FIRST_FRAME_DRAW") frameDraws.incrementAndGet()
                        if (it.stage == "FIRST_SHADER_DRAW") failures += "package mislabeled as shader"
                    })
                    assertTrue(checkNotNull(frame).activeHeaderTelemetry()?.contains("origin=active_header_frame_package") == true)
                    assertTrue(checkNotNull(frame).requestShow(owner, geometry) { allowed.get() }) }
            }
            waitFor("current prepared frame draw") { draws.get() > 0 && frameDraws.get() > 0 }
            val discoveryBefore = SystemClock.uptimeMillis()
            val discovery = checkNotNull(ui.takeScreenshot()).also { held.add(it) }
            val discoveryAfter = SystemClock.uptimeMillis()
            File(out, "discovery-full.png").outputStream().use { check(discovery.compress(Bitmap.CompressFormat.PNG, 100, it)) }
            var minX = search.right; var minY = search.bottom; var maxX = -1; var maxY = -1
            for (y in search.top until search.bottom) for (x in search.left until search.right) {
                val c = discovery.getPixel(x, y)
                if (maxOf(abs(Color.red(c) - 11), abs(Color.green(c) - 177), abs(Color.blue(c) - 67)) > 20) {
                    minX = minOf(minX, x); maxX = maxOf(maxX, x); minY = minOf(minY, y); maxY = maxOf(maxY, y)
                }
            }
            val foundWidth = maxX - minX + 1; val foundHeight = maxY - minY + 1
            check(foundWidth in size - 4..size + 4 && foundHeight in size - 4..size + 4) {
                "NOT REACHED: full orb bounds invalid $minX/$minY/$maxX/$maxY expected=$size"
            }
            val actualLeft = (minX + maxX + 1 - size) / 2; val actualTop = (minY + maxY + 1 - size) / 2
            val measured = Rect(actualLeft, actualTop, actualLeft + size, actualTop + size)
            log.append("geometry requested=$nominalBounds measured=$measured discovery=$discoveryBefore/$discoveryAfter\n")
            if (measured != nominalBounds) failures += "requested geometry $nominalBounds differs from measured $measured"
            bounds.set(measured)
            underlay = Bitmap.createBitmap(calibration, measured.left, measured.top, size, size).also { held.add(it) }
            File(out, "underlay-measured.png").outputStream().use {
                check(checkNotNull(underlay).compress(Bitmap.CompressFormat.PNG, 100, it))
            }
            val referenceA = image("tide-0", size); val referenceB = image("tide-1900", size)
            val referenceChange = difference(referenceA, referenceB)
            check(referenceChange.second >= 64) { "invalid fixture: reference frames indistinguishable" }
            var observedA: Bitmap? = null; var observedB: Bitmap? = null
            repeat(12) { index ->
                if (observedA == null || observedB == null) {
                    SystemClock.sleep(200)
                    val sample = crop("frame-$index", bounds)
                    val a = difference(referenceA, sample); val b = difference(referenceB, sample)
                    val exterior = exteriorMatches(checkNotNull(underlay), sample)
                    log.append("compare=$index referenceA=$a referenceB=$b exterior=$exterior\n")
                    if (a.first <= 5.0 && exterior) observedA = sample
                    if (b.first <= 5.0 && exterior) observedB = sample
                }
            }
            if (observedA == null || observedB == null) failures += "two distinct prepared Flutter frames not both observed"
            if (observedA != null && observedB != null) {
                val movement = difference(checkNotNull(observedA), checkNotNull(observedB))
                log.append("observedMovement=$movement\n")
                if (movement.second < 64 || movement.first < 1.0) failures += "compositor image did not move"
            }
            allowed.set(false)
            main { if (direct) checkNotNull(presenter).conceal(token)
                else assertTrue(checkNotNull(frame).conceal(checkNotNull(frameOwner), "CONTROL_RESTRICTED")) }
            val first = crop("after-hide-first", bounds); val delta = difference(checkNotNull(underlay), first)
            log.append("firstAfterHide=$delta\n")
            if (delta.first > 2.0) failures += "first sample after hide differs from underlay: $delta"
            repeat(2) { i -> SystemClock.sleep(50); val later = crop("after-hide-${i + 1}", bounds)
                log.append("laterAfterHide=${i + 1} delta=${difference(checkNotNull(underlay), later)}\n") }
            assertTrue(failures.joinToString("\n"), failures.isEmpty())
        } finally {
            main { presenter?.dispose(); frameOwner?.let { frame?.retire(it, "CLEANUP") }; activity?.finish() }
            FluviActiveHeaderMaterialStore.invalidate()
            FluviKeyguardMaterialBridgeRegistry.disconnect(channel)
            restore(prefs, originalPrefs)
            held.forEach { if (!it.isRecycled) it.recycle() }
            File(out, "r47-prepared-visual.txt").writeText(log.toString() + failures.joinToString("\n", prefix = "failures=\n", postfix = "\n"))
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, enabled)
        }
    }
}
