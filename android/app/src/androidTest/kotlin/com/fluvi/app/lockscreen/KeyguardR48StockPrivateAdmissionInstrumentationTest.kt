package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** One bounded sequence per route, on a disposable stock emulator. Service
 * and recorder are unmodified. The separate UI observer emits labels and
 * uptime boundaries only. It neither classifies for the service nor reads text. */
@RunWith(AndroidJUnit4::class)
class KeyguardR48StockPrivateAdmissionInstrumentationTest {
    @Test fun directStockPrivateAdmission() = exercise(KeyguardR448DisplayRoute.FLUVI_STREAM)
    @Test fun waStockPrivateAdmission() = exercise(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)

    private fun json(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { json(value.get(it)) }
        is JSONArray -> (0 until value.length()).map { json(value.get(it)) }
        else -> value
    }

    private fun exercise(route: KeyguardR448DisplayRoute) {
        val ins = InstrumentationRegistry.getInstrumentation()
        val args = InstrumentationRegistry.getArguments()
        assertEquals(37, Build.VERSION.SDK_INT)
        assertEquals("af20365a5ec96ff92b35321a03c0a2679ee7d2fd", args.getString("sourceSha"))
        val out = File(ins.targetContext.filesDir, "keyguard-service-probe/r43/${UUID.fromString(args.getString("runUuid"))}")
        check(out.mkdirs())
        val ledger = File(out, "scene-bookmarks.txt")
        val app = ins.targetContext
        val power = app.getSystemService(PowerManager::class.java)
        val keyguard = app.getSystemService(KeyguardManager::class.java)
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val pins = setOf("pinEntry", "password_entry", "lockPatternView", "keyguard_security_container")
        val clocks = setOf("keyguard_status_view", "keyguard_clock_switch", "lockscreen_clock_view",
            "lockscreen_clock_view_large", "keyguard_carrier_text", "keyguard_indication_text_bottom")
        val shade = setOf("quick_settings_panel", "quick_qs_panel", "qs_frame", "split_shade_status_bar")
        val serviceComponent = ComponentName(app, FluviKeyguardCardService::class.java)
        val testPackage = ins.context.packageName
        val cover = "$testPackage/${KeyguardR48StockCoverActivity::class.java.name}"
        val prefs = app.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
        val savedSettings = prefs.all
        val savedServices = Settings.Secure.getString(app.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(app.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val channel = MethodChannel(object : BinaryMessenger {
            override fun send(channel: String, message: ByteBuffer?) {}
            override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}
            override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {}
        }, "fluvi/keyguard_material")
        val missing = mutableListOf<String>()
        var installedPin = false
        var owner: FluviKeyguardCardService? = null
        var capture: String? = null

        fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(app.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun <T> main(block: () -> T): T {
            val answer = AtomicReference<T>()
            ins.runOnMainSync { answer.set(block()) }
            return answer.get()
        }
        fun start(service: FluviKeyguardCardService): Map<String, Any?> {
            val result = AtomicReference<Result<Map<String, Any?>>>()
            val ready = CountDownLatch(1)
            ins.runOnMainSync {
                CoroutineScope(Dispatchers.Main.immediate).launch {
                    try { result.set(runCatching {
                        service.startR46Recording(args.getString("sourceSha"), "debug", "r48-${route.name}", route.name)
                    }) } finally { ready.countDown() }
                }
            }
            check(ready.await(30, TimeUnit.SECONDS)) { "NOT REACHED: recording owner" }
            return result.get().getOrThrow()
        }
        fun waitForState(condition: () -> Boolean): Boolean {
            val deadline = SystemClock.uptimeMillis() + 5_000
            do {
                if (condition()) return true
                SystemClock.sleep(100)
            } while (SystemClock.uptimeMillis() < deadline)
            return false
        }
        fun scene(): String {
            if (!power.isInteractive) return "OFF"
            val locked = keyguard.isKeyguardLocked
            val windows = ui.windows
            var sawPin = false
            var sawClock = false
            var sawShade = false
            var sawCover = false
            var scanBudget = 180
            fun visit(node: AccessibilityNodeInfo) {
                try {
                    if (!node.isVisibleToUser || scanBudget-- <= 0) return
                    val id = node.viewIdResourceName?.removePrefix("com.android.systemui:id/")
                    sawPin = sawPin || id in pins
                    sawClock = sawClock || id in clocks
                    sawShade = sawShade || id in shade
                    for (index in 0 until node.childCount) {
                        if (scanBudget <= 0) break
                        node.getChild(index)?.let(::visit)
                    }
                } finally { node.recycle() }
            }
            for (window in windows) try {
                val root = window.root ?: continue
                if (root.packageName == "com.android.systemui") visit(root)
                else {
                    if (root.packageName == testPackage && root.isVisibleToUser &&
                        (window.isActive || window.isFocused)) sawCover = true
                    root.recycle()
                }
            } finally { window.recycle() }
            return when {
                sawCover && locked -> "FOREIGN"
                sawPin && locked -> "PIN"
                sawShade && locked -> "SHADE"
                sawClock && locked && scanBudget > 0 -> "MAIN"
                !locked && !keyguard.isDeviceLocked && !sawCover -> "UNLOCKED"
                else -> "UNLABELLED"
            }
        }
        fun hold(expected: String) {
            val entered = waitForState { scene() == expected }
            val begin = SystemClock.uptimeMillis()
            SystemClock.sleep(8_000)
            val end = SystemClock.uptimeMillis()
            val last = scene()
            val status = if (entered && last == expected) "OBSERVED_ENDPOINTS" else "NOT_REACHED_OR_UNSTABLE"
            ledger.appendText("scene=$expected endScene=$last startConfirmed=$entered begin=$begin end=$end status=$status clock=uptimeMs\n")
            if (status != "OBSERVED_ENDPOINTS") missing += "$expected:$last"
        }

        val savedLock = shell("locksettings get-disabled").trim()
        val savedTimeout = shell("settings get system screen_off_timeout").trim()
        val savedStay = shell("settings get global stay_on_while_plugged_in").trim()
        val observer = checkNotNull(ui.serviceInfo)
        val observerFlags = observer.flags
        val display = checkNotNull(app.getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY))
        val width = display.mode.physicalWidth
        val height = display.mode.physicalHeight
        var coverStarted = false
        fun closeCover() {
            if (coverStarted) {
                shell("am start -W -n $cover --ez finish true")
                coverStarted = false
            }
        }
        try {
            check(!keyguard.isDeviceSecure) { "NOT REACHED: disposable stock device" }
            shell("settings put system screen_off_timeout 90000")
            // A stock lockscreen window supplies its own 10 s timeout.
            // Keep this plugged-in fixture on, except for the explicit OFF interval.
            shell("svc power stayon true")
            observer.flags = observerFlags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            ui.serviceInfo = observer
            ledger.appendText("observerFlags=${ui.serviceInfo.flags} injectedWindowInfo=false display=${width}x$height\n")
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            check(waitForState { power.isInteractive && !keyguard.isKeyguardLocked })
            shell("locksettings set-disabled false")
            shell("locksettings set-pin 2468")
            installedPin = keyguard.isDeviceSecure
            check(installedPin) { "NOT REACHED: disposable credential" }

            main { FluviKeyguardCardSettings.update(app, mapOf("requested" to true, "showFinancialDetails" to true,
                "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val otherServices = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != serviceComponent
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                (otherServices + serviceComponent.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            check(waitForState { FluviKeyguardCardServiceRegistry.connected }) { "NOT REACHED: bound service" }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()).also { owner = it }
            assertTrue(main { service.setR448DisplayRoute(route) })
            assertEquals(false, main { service.r448DisplayRouteStatus()["sampleOnly"] })

            val epoch = main { FluviKeyguardMaterialBridgeRegistry.connect(channel) }
            val variant = ins.context.assets.open("r47_reference/tide.json").bufferedReader().use { it.readText() }
            val profile = json(JSONObject(variant)) as Map<*, *>
            val input = profile.toMutableMap().apply { put("publisherInstance", 1L); put("activeMode", "balance"); put("modeEpoch", 0L) }
            assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, input["publisherSession"] as String))
            val accepted = FluviActiveHeaderMaterialStore.publish(app, input, epoch, true)
            assertTrue(accepted.reason, accepted.accepted)
            val receipt = start(service)
            capture = receipt["captureId"] as? String
            assertEquals(receipt.toString(), true, receipt["active"])
            assertEquals(receipt.toString(), "activeHeader", receipt["printPurpose"])
            assertEquals(route.name, receipt["routeConfirmed"])
            val observerStatus = ledger.readText()
            ledger.writeText("captureId=$capture route=${route.name} source=independent_ui_automation_boundaries fixture=stock\n" +
                observerStatus)
            shell("input keyevent KEYCODE_SLEEP")
            hold("OFF")
            shell("input keyevent KEYCODE_WAKEUP")
            hold("MAIN")
            shell("cmd statusbar expand-notifications")
            hold("SHADE")
            shell("cmd statusbar collapse")
            coverStarted = true
            shell("am start -W -n $cover")
            hold("FOREIGN")
            closeCover()
            if (!waitForState { scene() != "FOREIGN" }) missing += "FOREIGN_CLEANUP"
            shell("input swipe ${width / 2} ${height * 9 / 10} ${width / 2} ${height / 5} 350")
            hold("PIN")
            shell("input text 2468")
            shell("input keyevent KEYCODE_ENTER")
            hold("UNLOCKED")
        } finally {
            try {
                val id = capture
                if (id != null) {
                    check(main { checkNotNull(owner).stopR46Owner(id) })
                    val frozen = KeyguardCardDiagnostics.freezeR46Capture(app)
                    val report = KeyguardR46RecordingStore.seal(app, id, frozen["report"] as String, "USER_STOP")
                    File(out, "recording.txt").writeText(report)
                    KeyguardR46RecordingStore.copied(app, id)
                }
            } finally {
                KeyguardCardDiagnostics.clearCapture(app)
                FluviActiveHeaderMaterialStore.invalidate()
                main { FluviKeyguardMaterialBridgeRegistry.disconnect(channel) }
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
                closeCover()
                shell("cmd statusbar collapse")
                observer.flags = observerFlags
                ui.serviceInfo = observer
                if (installedPin) shell("locksettings clear --old 2468")
                shell("input keyevent KEYCODE_WAKEUP")
                shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                for ((scope, name, value) in listOf(Triple("system", "screen_off_timeout", savedTimeout),
                    Triple("global", "stay_on_while_plugged_in", savedStay))) {
                    if (value.toLongOrNull() != null) shell("settings put $scope $name $value")
                    else shell("settings delete $scope $name")
                }
                val edit = prefs.edit().clear()
                for ((key, value) in savedSettings) when (value) {
                    is Boolean -> edit.putBoolean(key, value)
                    is String -> edit.putString(key, value)
                    is Long -> edit.putLong(key, value)
                    is Int -> edit.putInt(key, value)
                    is Float -> edit.putFloat(key, value)
                    is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
                }
                check(edit.commit())
            }
        }
        assertTrue("Stock witness preconditions incomplete $missing", missing.isEmpty())
    }
}

/** Separate fixture-package window with explicit, test-only task teardown. */
class KeyguardR48StockCoverActivity : Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        setShowWhenLocked(true)
        setContentView(View(this).apply {
            setBackgroundColor(0xff124d31.toInt())
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
            isFocusable = true
            contentDescription = "R48 test cover"
        })
        if (intent.getBooleanExtra("finish", false)) finishAndRemoveTask()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra("finish", false)) finishAndRemoveTask()
    }
}
