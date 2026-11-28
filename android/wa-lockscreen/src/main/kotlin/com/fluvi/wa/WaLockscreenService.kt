package com.fluvi.wa

import android.accessibilityservice.AccessibilityService
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
    private val platform by lazy { WaSystemReader(this) }
    private val episode = WaWakeEpisode()
    private var lastState = WaSystemState.UNKNOWN
    private var scan: Job? = null
    private var scene = WaLockscreenScene.UNKNOWN
    private var connected = false
    private var scanId = 0L
    private val tracking get() = WaLastUnlock.tracking
    private val expireUnlockObservation = Runnable { tracking.hasPending(session, SystemClock.elapsedRealtimeNanos()) }
    private var powerMenuSource: AccessibilityNodeInfo? = null
    protected var session: Long = 0
        private set

    protected abstract fun contentAvailable(): Boolean
    protected abstract fun showOrb(episode: Long, animate: Boolean): Boolean
    protected abstract fun hideOrb(reason: WaHideReason, unlock: WaUnlockTrigger? = null): Long
    protected abstract fun orbOwner(): WaAttachment?
    protected abstract fun hasOrbAttachment(): Boolean
    protected abstract fun ownsOrbEvent(windowId: Int): Boolean
    protected open fun geometryChanged() = Unit

    private val screenEvents = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val received = WaLockscreenCapture.callbackTime()
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    markCallback(WaSource.SCREEN_OFF, received)
                    terminalSignal(WaSource.SCREEN_OFF, WaHideReason.SCREEN_OFF, received)
                }
                Intent.ACTION_USER_PRESENT -> {
                    markCallback(WaSource.USER_PRESENT, received)
                    val callback = received.takeIf { it != 0L } ?: SystemClock.uptimeMillis()
                    terminalSignal(WaSource.USER_PRESENT, WaHideReason.USER_PRESENT, callback)
                }
                Intent.ACTION_SCREEN_ON -> {
                    markCallback(WaSource.SCREEN_ON, received)
                    episode.wakeSignal()
                    refreshScene(WaSource.SCREEN_ON, received)
                }
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (connected) return
        connected = true
        session = SystemClock.elapsedRealtimeNanos()
        episode.connect()
        WaLastUnlock.connected(session)
        WaLockscreenCapture.serviceConnected(
            applicationContext, session,
            WaCaptureTimeout(
                readTimeout = { serviceInfo?.notificationTimeout },
                writeTimeout = { value ->
                    val info = checkNotNull(serviceInfo)
                    info.notificationTimeout = value
                    serviceInfo = info
                },
            ),
            hasWindow = ::hasOrbAttachment,
        )
        displays.registerDisplayListener(this, main)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenEvents, filter, RECEIVER_NOT_EXPORTED)
        else registerReceiver(screenEvents, filter)
        refreshScene(WaSource.CONNECT)
    }

    final override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val received = WaLockscreenCapture.callbackTime()
        val receivedElapsed = if (received != 0L) SystemClock.elapsedRealtimeNanos() else 0L
        val type = event.eventType
        val callback = if (received != 0L || (orbOwner() == null && !tracking.awaiting(session)))
            received else SystemClock.uptimeMillis()
        val eventTime = event.eventTime.takeIf { it in 1..callback } ?: 0L
        val otherDisplay = Build.VERSION.SDK_INT >= 33 && event.displayId >= 0 && event.displayId != Display.DEFAULT_DISPLAY
        if (received != 0L) {
            WaLockscreenCapture.ingress(
                if (otherDisplay) WaSource.OTHER_DISPLAY else WaSource.ACCESSIBILITY,
                session, episode.id, orbOwner(), received, receivedElapsed, event, eventTime,
            )
        }
        if (otherDisplay) {
            record(WaStage.FILTERED, WaSource.OTHER_DISPLAY, received, type, eventTime)
            return
        }
        // Check for a definite negative before even a normally filtered content event.
        if (!checkState(WaSource.ACCESSIBILITY, callback, type, eventTime)) return
        if (ownsOrbEvent(event.windowId) ||
            (type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
                event.packageName != null && event.packageName.toString() !in WaLockscreenScene.systemUiPackages)
        ) {
            record(WaStage.FILTERED, WaSource.ACCESSIBILITY, received, type, eventTime)
            return
        }
        if (type == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.packageName == "android" && event.className == "com.android.internal.policy.DecorView"
        ) {
            val source = event.source
            if (source != null && isPowerMenuHint(event, source)) {
                withdraw(WaHideReason.POWER_MENU, WaSource.ACCESSIBILITY, received, type, eventTime)
                powerMenuSource?.recycle()
                powerMenuSource = source
                return
            }
            source?.recycle()
        }
        offerScan(WaSource.ACCESSIBILITY, type, callback, eventTime)
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

    protected fun orbContentChanged(readinessChanged: Boolean) {
        if (!checkState(WaSource.CONTENT, WaLockscreenCapture.callbackTime())) return
        if (readinessChanged) offerScan(WaSource.CONTENT)
        else geometryChanged()
    }

    protected fun entranceAllowed(expectedEpisode: Long): Boolean =
        episode.owns(expectedEpisode) && scene == WaLockscreenScene.MAIN && checkState(WaSource.ENTRANCE)

    private fun refreshScene(source: WaSource, received: Long = WaLockscreenCapture.callbackTime(), geometry: Boolean = false) {
        if (!checkState(source, received)) return
        if (geometry) geometryChanged()
        offerScan(source, received = received)
    }

    private fun checkState(
        source: WaSource, received: Long = WaLockscreenCapture.callbackTime(), type: Int = 0, eventTime: Long = 0,
    ): Boolean {
        if (!connected) return false
        val tracked = tracking.history(orbOwner())
        val observeRead = received != 0L || tracked != null || tracking.awaiting(session)
        val readUp = if (observeRead) SystemClock.uptimeMillis() else 0L
        val readBegin = if (observeRead) SystemClock.elapsedRealtimeNanos() else 0L
        lastState = platform.read()
        val negative = lastState.terminal
        val recording = WaLockscreenCapture.captureId() != null
        val readEnd = if (observeRead && (tracked != null || recording || negative == WaHideReason.UNLOCKED)) {
            SystemClock.elapsedRealtimeNanos()
        } else 0L
        val gate = if (readEnd != 0L && (tracked != null || negative == WaHideReason.UNLOCKED)) {
            WaGateRead(WaTime(readUp, readBegin), WaTime(SystemClock.uptimeMillis(), readEnd), lastState)
        } else null
        if (recording && readEnd != 0L) {
            WaLockscreenCapture.record(
                WaStage.STATE_READ, source, session, episode.id, orbOwner(),
                received = received, type = type, eventTime = eventTime, state = lastState,
                detail = readBegin, detailEnd = readEnd, atElapsed = readEnd,
            )
        }
        if (tracked != null && gate != null) tracked.previousRead = gate
        if (negative != null) {
            terminalSignal(source, negative, received, observed = true, type = type, eventTime = eventTime,
                read = gate)
            return false
        }
        val previous = episode.id
        val admitted = episode.admit(lastState)
        if (episode.id != previous) {
            tracking.invalidate(session)
            record(WaStage.EPISODE_OPEN, source)
        }
        if (!admitted || !contentAvailable()) {
            val reason = if (admitted) WaHideReason.CONTENT else WaHideReason.UNKNOWN
            withdraw(reason, source, received, type, eventTime)
            return false
        }
        record(WaStage.INGRESS, source, received, type, eventTime)
        return true
    }

    private fun offerScan(source: WaSource, type: Int = 0, received: Long = 0, eventTime: Long = 0) {
        val id = ++scanId
        val owner = episode.id
        scan?.cancel()
        val powerNode = powerMenuSource?.let(AccessibilityNodeInfo::obtain)
        record(WaStage.SCAN_OFFER, source, type = type, scan = id)
        scan = scope.launch {
            val start = SystemClock.uptimeMillis()
            val sessionId = session
            val window = orbOwner()
            val generation = tracking.generation
            val history = tracking.history(window)
            var attempt = history?.begin(id)
            fun finish(disposition: WaScanDisposition, atNs: Long = SystemClock.elapsedRealtimeNanos()) {
                val current = attempt ?: return
                attempt = null
                history?.finish(current.finish(disposition, atNs))
            }
            val capture = WaLockscreenCapture.captureId()
            record(WaStage.SCAN_START, source, type = type, scan = id)
            try {
                val result = withContext(reader) {
                    val begin = SystemClock.uptimeMillis()
                    val observation = attempt
                    val observed = try {
                        if (observation != null) observation.fetchBeginNs = SystemClock.elapsedRealtimeNanos()
                        val windows = if (Build.VERSION.SDK_INT >= 30) {
                            windowsOnAllDisplays[Display.DEFAULT_DISPLAY]
                        } else this@WaLockscreenService.windows
                        if (observation != null) observation.fetchEndNs = SystemClock.elapsedRealtimeNanos()
                        WaLockscreenScene.inspect(windows, powerNode, observation?.let { row ->
                            { app ->
                                row.metadata(app, SystemClock.elapsedRealtimeNanos())
                            }
                        })
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (error: RuntimeException) {
                        Log.w(TAG, "scan failed: ${error.javaClass.simpleName}")
                        WaSceneReading.UNKNOWN
                    }
                    ScanResult(observed, begin, SystemClock.uptimeMillis())
                }
                if (capture != null && capture == WaLockscreenCapture.captureId()) {
                    WaLockscreenCapture.record(
                        WaStage.SCAN_RESULT, source, sessionId, owner, window, id,
                        type = type, scene = result.scene, detail = result.begin, detailEnd = result.end,
                    )
                }
                if (id != scanId || !episode.owns(owner) || sessionId != session ||
                    generation != tracking.generation || window != orbOwner()) {
                    finish(WaScanDisposition.STALE)
                    if (capture != null && capture == WaLockscreenCapture.captureId()) {
                        WaLockscreenCapture.record(WaStage.STALE, source, sessionId, owner, window, id)
                    }
                    return@launch
                }
                if (result.scene == WaLockscreenScene.RESTRICTED) {
                    scene = result.scene
                    val appWindow = result.reading == WaSceneReading.APP_WINDOW_PRESENT
                    val decision = if (appWindow && window != null) WaTime.now() else null
                    finish(WaScanDisposition.APPLIED, decision?.elapsedNs ?: SystemClock.elapsedRealtimeNanos())
                    val trigger = if (decision != null && window != null) WaUnlockTrigger(
                        window, WaHideReason.RESTRICTED, source, type, eventTime, received, decision, null,
                        WaWithdrawalCause.APP_WINDOW_PRESENT,
                    ) else null
                    if (!appWindow) tracking.discardPending(session)
                    hideOrb(WaHideReason.RESTRICTED, trigger)
                    // Only discard an expired diagnostic draft. The view has already been withdrawn.
                    if (trigger != null) {
                        main.removeCallbacks(expireUnlockObservation)
                        main.postDelayed(expireUnlockObservation, WaUnlockTracking.CONFIRM_NS / 1_000_000L + 1)
                    }
                    record(WaStage.SCAN_APPLY, source, type = type, scan = id)
                    return@launch
                }
                if (!checkState(WaSource.SCAN_APPLY)) {
                    finish(WaScanDisposition.GATE_DENIED)
                    return@launch
                }
                finish(WaScanDisposition.APPLIED)
                scene = result.scene
                record(WaStage.SCAN_APPLY, source, type = type, scan = id)
                if (scene != WaLockscreenScene.MAIN) {
                    hideOrb(WaHideReason.UNKNOWN)
                    return@launch
                }
                Log.i(TAG, "eligible session=$session scan=$id reason=$source begin=$start end=${SystemClock.uptimeMillis()}")
                if (orbOwner() == null) {
                    record(WaStage.ADD_WAIT, source, scan = id)
                    delay(50)
                }
                if (id == scanId && episode.owns(owner) && generation == tracking.generation &&
                    window == orbOwner() && scene == WaLockscreenScene.MAIN &&
                    checkState(WaSource.ADD_RECHECK) && episode.owns(owner)) {
                    if (showOrb(owner, !episode.entranceAdmitted)) episode.attached(owner)
                }
            } catch (cancelled: CancellationException) {
                finish(WaScanDisposition.CANCELED)
                if (capture != null && capture == WaLockscreenCapture.captureId()) {
                    WaLockscreenCapture.record(WaStage.SCAN_CANCEL, source, sessionId, owner, window, id, type = type)
                }
                throw cancelled
            } finally {
                WaLockscreenCapture.scanEnded(capture)
                powerNode?.recycle()
            }
        }
    }

    private data class ScanResult(val reading: WaSceneReading, val begin: Long, val end: Long) {
        val scene get() = reading.scene
    }

    private fun terminalSignal(
        source: WaSource, reason: WaHideReason, received: Long, observed: Boolean = false,
        type: Int = 0, eventTime: Long = 0, read: WaGateRead? = null,
    ) {
        if (!connected) return
        val barrier = when (reason) {
            WaHideReason.USER_PRESENT, WaHideReason.UNLOCKED -> WaBarrier.UNLOCKED
            WaHideReason.DISCONNECT -> WaBarrier.DISCONNECTED
            else -> WaBarrier.SLEEP
        }
        if (reason == WaHideReason.USER_PRESENT || reason == WaHideReason.UNLOCKED) {
            if (tracking.awaiting(session)) {
                tracking.confirm(session, episode.id, orbOwner(), reason, source, WaTime.now(), read)
            }
        }
        episode.close(barrier, observed, newSleepSignal = reason == WaHideReason.SCREEN_OFF)
        withdraw(reason, source, received, type, eventTime, terminal = true,
            state = lastState.takeIf { observed }, read = read)
        tracking.invalidate(session)
        powerMenuSource?.recycle()
        powerMenuSource = null
    }

    private fun withdraw(
        reason: WaHideReason, source: WaSource, received: Long = 0,
        type: Int = 0, eventTime: Long = 0, terminal: Boolean = false,
        state: WaSystemState? = lastState,
        read: WaGateRead? = null,
    ) {
        if (reason == WaHideReason.POWER_MENU) tracking.discardPending(session)
        val revokedScan = scanId++
        val revoked = scan
        val owner = orbOwner()
        val previousScene = scene
        val unlock = if (owner != null && terminal &&
            (reason == WaHideReason.UNLOCKED || reason == WaHideReason.USER_PRESENT)
        ) WaUnlockTrigger(owner, reason, source, type, eventTime, received, WaTime.now(), read) else null
        val decided = unlock?.decision?.uptimeMs ?: WaLockscreenCapture.callbackTime()
        val decidedElapsed = unlock?.decision?.elapsedNs ?: if (decided != 0L) SystemClock.elapsedRealtimeNanos() else 0
        scan = null
        scene = WaLockscreenScene.UNKNOWN
        if (owner != null && decided != 0L) {
            WaLockscreenCapture.record(
                WaStage.DECISION, source, session, episode.id, owner, revokedScan,
                reason = reason, received = received, type = type, eventTime = eventTime,
                state = state, scene = previousScene, barrier = episode.barrier,
                atUp = decided, atElapsed = decidedElapsed,
            )
        }
        val hide = hideOrb(reason, unlock)
        revoked?.cancel()
        WaLockscreenCapture.record(
            if (terminal) WaStage.TERMINAL else WaStage.DENIED, source,
            session, episode.id, owner, revokedScan, hide = hide, reason = reason, received = received,
            type = type, eventTime = eventTime, state = state, scene = previousScene,
            barrier = episode.barrier, detail = decided, detailEnd = decidedElapsed,
        )
    }

    private fun record(
        stage: WaStage, source: WaSource, received: Long = 0, type: Int = 0, eventTime: Long = 0,
        scan: Long = scanId,
    ) = WaLockscreenCapture.record(
        stage, source, session, episode.id, orbOwner(), scan,
        received = received, type = type, eventTime = eventTime,
        state = lastState, scene = scene, barrier = episode.barrier,
    )

    private fun markCallback(source: WaSource, received: Long) {
        if (received == 0L) return
        WaLockscreenCapture.ingress(
            source, session, episode.id, orbOwner(), received, SystemClock.elapsedRealtimeNanos(),
        )
    }

    override fun onDisplayAdded(displayId: Int) = onDisplayChanged(displayId)

    override fun onDisplayRemoved(displayId: Int) {
        if (displayId == Display.DEFAULT_DISPLAY) {
            val received = WaLockscreenCapture.callbackTime()
            markCallback(WaSource.DISPLAY, received)
            lastState = WaSystemState(WaSystemState.DISPLAY_MISSING)
            terminalSignal(WaSource.DISPLAY, WaHideReason.DISPLAY, received, observed = true)
        }
    }

    override fun onDisplayChanged(displayId: Int) {
        if (displayId != Display.DEFAULT_DISPLAY) return
        val received = WaLockscreenCapture.callbackTime()
        markCallback(WaSource.DISPLAY, received)
        refreshScene(WaSource.DISPLAY, received, geometry = true)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        refreshScene(WaSource.CONFIGURATION, geometry = true)
    }

    override fun onInterrupt() = withdraw(WaHideReason.INTERRUPT, WaSource.INTERRUPT)

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
        terminalSignal(WaSource.DISCONNECT, WaHideReason.DISCONNECT, WaLockscreenCapture.callbackTime())
        connected = false
        main.removeCallbacks(expireUnlockObservation)
        WaLastUnlock.disconnected(session)
        WaLockscreenCapture.serviceDisconnected(session)
        scope.coroutineContext.cancelChildren()
        displays.unregisterDisplayListener(this)
        unregisterReceiver(screenEvents)
    }

    private companion object {
        const val TAG = "FluviBalanceOrb"
    }
}

internal enum class WaSceneReading(val scene: WaLockscreenScene) {
    UNKNOWN(WaLockscreenScene.UNKNOWN),
    MAIN(WaLockscreenScene.MAIN),
    NODE_RESTRICTION(WaLockscreenScene.RESTRICTED),
    APP_WINDOW_PRESENT(WaLockscreenScene.RESTRICTED),
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
        suspend fun inspect(
            windows: List<AccessibilityWindowInfo>?, powerNode: AccessibilityNodeInfo?,
            metadataComplete: ((Boolean) -> Unit)? = null,
        ): WaSceneReading {
            if (windows == null) return WaSceneReading.UNKNOWN
            var systemUiSeen = false
            try {
                for (window in windows) {
                    coroutineContext.ensureActive()
                    if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) {
                        metadataComplete?.invoke(true)
                        return WaSceneReading.APP_WINDOW_PRESENT
                    }
                }
                coroutineContext.ensureActive()
                metadataComplete?.invoke(false)
                for (window in windows) {
                    coroutineContext.ensureActive()
                    if (window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY) continue
                    val root = window.root ?: continue
                    try {
                        val pkg = root.packageName?.toString()
                        if (window.type == -1 && pkg == "com.google.android.googlequicksearchbox") return WaSceneReading.NODE_RESTRICTION
                        if (root.isVisibleToUser && (pkg == "com.samsung.android.app.cocktailbarservice" ||
                                pkg == "com.samsung.android.app.notes")) return WaSceneReading.NODE_RESTRICTION
                        if (pkg in systemUiPackages) {
                            systemUiSeen = true
                            if (restricted(root, powerNode)) return WaSceneReading.NODE_RESTRICTION
                        }
                    } finally {
                        root.recycle()
                    }
                }
            } finally {
                windows.forEach { it.recycle() }
            }
            return if (systemUiSeen) WaSceneReading.MAIN else WaSceneReading.UNKNOWN
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
