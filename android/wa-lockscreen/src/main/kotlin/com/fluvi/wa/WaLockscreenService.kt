package com.fluvi.wa

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.coroutines.coroutineContext

/** Default-display, ordinary lockscreen branch from WA 4.7.5. */
@Suppress("DEPRECATION")
abstract class WaLockscreenService : AccessibilityService(), DisplayManager.DisplayListener {
    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val reader = Dispatchers.Default.limitedParallelism(1)
    private val displays by lazy { getSystemService(DisplayManager::class.java) }
    private val keyguard by lazy { getSystemService(KeyguardManager::class.java) }
    private var scan: Job? = null
    private var scene = WaLockscreenScene.UNKNOWN
    private var connected = false
    private var scanId = 0L
    private var powerMenuSource: AccessibilityNodeInfo? = null
    protected val defaultDisplay: Display?
        get() = displays.getDisplay(Display.DEFAULT_DISPLAY)
    protected var session: Long = 0
        private set

    protected abstract fun contentAvailable(): Boolean
    protected abstract fun showOrb()
    protected abstract fun hideOrb(reason: String)
    protected open fun geometryChanged() = Unit

    private val screenEvents = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_USER_PRESENT -> {
                    powerMenuSource?.recycle()
                    powerMenuSource = null
                    invalidateScene(intent.action.orEmpty())
                }
                Intent.ACTION_SCREEN_ON -> refreshScene("screenOn")
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (connected) return
        connected = true
        session = SystemClock.elapsedRealtimeNanos()
        displays.registerDisplayListener(this, main)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenEvents, filter, RECEIVER_NOT_EXPORTED)
        else registerReceiver(screenEvents, filter)
        refreshScene("connect")
    }

    final override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
            event.packageName != null && event.packageName.toString() !in WaLockscreenScene.systemUiPackages
        ) return
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.packageName == "android" && event.className == "com.android.internal.policy.DecorView"
        ) {
            val source = event.source
            if (source != null && isPowerMenuHint(event, source)) {
                powerMenuSource?.recycle()
                powerMenuSource = source
                invalidateScene("powerMenu")
                return
            }
            source?.recycle()
        }
        refreshScene("event:${event.eventType}")
    }

    private fun isPowerMenuHint(event: AccessibilityEvent, source: AccessibilityNodeInfo): Boolean {
        val texts = listOf("global_action_power_off", "power_dialog").mapNotNull { name ->
            resources.getIdentifier(name, "string", "android").takeIf { it != 0 }?.let(resources::getString)
        }
        return event.text.any { it.toString() in texts } || source.window?.let { window ->
            try {
                window.title?.toString() in texts
            } finally {
                window.recycle()
            }
        } == true
    }

    protected fun refreshScene(reason: String) {
        scan?.cancel()
        val id = ++scanId
        if (!eligibleNow()) {
            scene = WaLockscreenScene.UNKNOWN
            hideOrb(reason)
            return
        }
        // WA checks the current system state before reading the accessibility tree.
        // A neutral content event alone does not withdraw a proven eligible scene.
        if (scene == WaLockscreenScene.RESTRICTED) hideOrb(reason)
        val powerNode = powerMenuSource?.let(AccessibilityNodeInfo::obtain)
        scan = scope.launch {
            val start = SystemClock.uptimeMillis()
            try {
                scene = withContext(reader) {
                    try {
                        val windows = if (Build.VERSION.SDK_INT >= 30) {
                            windowsOnAllDisplays[Display.DEFAULT_DISPLAY]
                        } else this@WaLockscreenService.windows
                        WaLockscreenScene.inspect(windows.orEmpty(), powerNode)
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (error: Exception) {
                        Log.w(TAG, "scan failed: ${error.javaClass.simpleName}")
                        WaLockscreenScene.UNKNOWN
                    }
                }
                if (id != scanId || !eligibleNow() || scene != WaLockscreenScene.MAIN) {
                    hideOrb("scene:$scene")
                    return@launch
                }
                Log.i(TAG, "eligible session=$session scan=$id reason=$reason begin=$start end=${SystemClock.uptimeMillis()}")
                addAfterRecheck(id)
            } finally {
                powerNode?.recycle()
            }
        }
    }

    protected abstract fun hasOrb(): Boolean

    private suspend fun addAfterRecheck(id: Long) {
        if (!hasOrb()) delay(50)
        if (id == scanId && eligibleNow() && scene == WaLockscreenScene.MAIN) showOrb()
    }

    private fun eligibleNow(): Boolean =
        connected && defaultDisplay?.state == Display.STATE_ON && keyguard.isKeyguardLocked && contentAvailable()

    private fun invalidateScene(reason: String) {
        scanId++
        scan?.cancel()
        scene = WaLockscreenScene.UNKNOWN
        hideOrb(reason)
    }

    override fun onDisplayAdded(displayId: Int) = onDisplayChanged(displayId)
    override fun onDisplayRemoved(displayId: Int) = onDisplayChanged(displayId)
    override fun onDisplayChanged(displayId: Int) {
        if (displayId != Display.DEFAULT_DISPLAY) return
        if (defaultDisplay?.state == Display.STATE_ON) geometryChanged()
        refreshScene("display")
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        geometryChanged()
        refreshScene("configuration")
    }

    override fun onInterrupt() = invalidateScene("interrupt")

    override fun onUnbind(intent: Intent?): Boolean {
        disconnect()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    private fun disconnect() {
        if (!connected) return
        connected = false
        invalidateScene("disconnect")
        scope.coroutineContext.cancelChildren()
        displays.unregisterDisplayListener(this)
        unregisterReceiver(screenEvents)
        powerMenuSource?.recycle()
        powerMenuSource = null
    }

    private companion object {
        const val TAG = "FluviBalanceOrb"
    }
}

internal enum class WaLockscreenScene {
    UNKNOWN, RESTRICTED, MAIN;

    companion object {
        val systemUiPackages = setOf(
            "com.android.systemui", "miui.systemui.plugin", "com.sec.android.app.launcher",
            "com.android.keyguard", "android",
        )
        private val restrictedIds = setOfNotNull(
            "com.android.systemui:id/keyguard_host_view",
            "com.android.systemui:id/keyguard_security_container",
            "element:BouncerContent",
            "com.android.systemui:id/quick_settings_panel",
            "com.android.systemui:id/settings_button",
            "com.android.systemui:id/tile_label",
            "com.android.systemui:id/header_label",
            "com.android.systemui:id/split_shade_status_bar",
            "com.android.systemui:id/notification_shade_shortcut",
            "com.android.systemui:id/qs_footer".takeIf { Build.VERSION.SDK_INT <= 28 },
            "com.android.systemui:id/quick_qs_panel".takeIf { Build.VERSION.SDK_INT in 33..35 },
            "miui.systemui.plugin:id/main_panel_container",
            "com.android.systemui:id/sec_global_actions_icon",
            "com.android.systemui:id/global_actions_container",
            "com.samsung.android.app.cocktailbarservice:id/panel_rootview",
            "com.samsung.android.app.cocktailbarservice:id/panel_root_view",
        )

        @Suppress("DEPRECATION")
        suspend fun inspect(windows: List<AccessibilityWindowInfo>, powerNode: AccessibilityNodeInfo?): WaLockscreenScene {
            var systemUiSeen = false
            try {
                for (window in windows) {
                    coroutineContext.ensureActive()
                    if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) return RESTRICTED
                    if (window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY) continue
                    val root = window.root ?: continue
                    try {
                        val pkg = root.packageName?.toString()
                        if (window.type == -1 && pkg == "com.google.android.googlequicksearchbox") return RESTRICTED
                        if (root.isVisibleToUser && (pkg == "com.samsung.android.app.cocktailbarservice" ||
                                pkg == "com.samsung.android.app.notes")) return RESTRICTED
                        if (pkg in systemUiPackages) {
                            systemUiSeen = true
                            if (restricted(root, powerNode)) return RESTRICTED
                        }
                    } finally {
                        root.recycle()
                    }
                }
            } finally {
                windows.forEach { it.recycle() }
            }
            return if (systemUiSeen) MAIN else UNKNOWN
        }

        @Suppress("DEPRECATION")
        private suspend fun restricted(root: AccessibilityNodeInfo, powerNode: AccessibilityNodeInfo?): Boolean {
            val pending = ArrayDeque<AccessibilityNodeInfo>()
            pending.add(AccessibilityNodeInfo.obtain(root))
            try {
                while (pending.isNotEmpty()) {
                    coroutineContext.ensureActive()
                    val node = pending.removeFirst()
                    try {
                        if (node.isVisibleToUser) {
                            if (node.viewIdResourceName in restrictedIds) return true
                            if (powerNode != null && node.childCount > 0 && node == powerNode) return true
                        } else if (node != root) continue
                        repeat(node.childCount) { index ->
                            coroutineContext.ensureActive()
                            node.getChild(index)?.let(pending::addLast)
                        }
                    } finally {
                        node.recycle()
                    }
                }
                return false
            } finally {
                pending.forEach { it.recycle() }
            }
        }
    }
}
