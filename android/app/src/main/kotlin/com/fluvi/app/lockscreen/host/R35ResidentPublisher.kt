package com.fluvi.app.lockscreen.host

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.UserHandle
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Display
import android.view.WindowInsets
import android.view.WindowManager
import com.fluvi.app.R
import com.fluvi.app.lockscreen.FluviKeyguardCardSettings
import com.fluvi.app.lockscreen.KeyguardUsableBounds
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.resolveKeyguardOverlayGeometry
import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.core.FluviCoreFactory
import com.fluvi.r29.contract.R29Period
import java.time.LocalDate
import java.time.ZoneId
import java.util.concurrent.Executor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Staged reference-host publisher. It is deliberately not auto-started. A
 * future enrolled adapter may call [connectAfterDrain] only after app admission
 * AND final submission honor R29Ownership and the old output really drained.
 * The currently staged SystemUI service cannot meet that enrollment contract.
 */
internal class R35ResidentPublisher(
    context: Context,
    private val ownership: R29Ownership,
    main: Executor,
    private val listener: Listener,
    testHost: ComponentName? = null,
) : R29HostClient.Listener, R35MaterialPublication.Consumer {
    interface Listener {
        fun onConnected(session: String, epoch: Long) {}
        fun onReady(session: String, sequence: Long)
        fun onUnavailable()
        fun onEmpty(session: String, sequence: Long, epoch: Long)
    }

    private val application = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val client = R29HostClient(application, ownership, main, this, testHost)
    private val lock = Any()
    private var session: String? = null
    private var sequence = 0L
    private var generation = 0L
    private var lastPublishedSequence = 0L
    private var coreJob: Job? = null
    private var observersRegistered = false
    private val handler = Handler(Looper.getMainLooper())

    /** Does not perform or assert the required legacy-owner drain. */
    fun connectAfterDrain(epoch: Long) { client.connect(epoch) }

    override fun onSession(nonce: String, epoch: Long) {
        if (ownership.epoch() != epoch || !R35MaterialPublication.install(ownership, nonce, this)) {
            client.close()
            return
        }
        synchronized(lock) {
            session = nonce
            sequence = 0
            generation += 1
            lastPublishedSequence = 0
        }
        registerObservers()
        observeCoreRevisions()
        listener.onConnected(nonce, epoch)
        // The stored profile has no durable source proof. Ask the running
        // Flutter producer for a fresh profile rather than relabeling it.
        FluviKeyguardMaterialBridgeRegistry.requestSceneRefresh()
    }

    override fun onInputsChanging() {
        synchronized(lock) {
            val nonce = session ?: return
            if (sequence == Long.MAX_VALUE) return
            generation += 1
            lastPublishedSequence = 0
            client.invalidate(nonce, ++sequence)
        }
    }

    override fun onProfileAccepted(profile: KeyguardMaterialProfile, evidence: R35MaterialEvidence?) {
        if (evidence == null) return // Prior invalidation remains in force.
        val request = synchronized(lock) { (session ?: return) to generation }
        scope.launch {
            val targetSettings = FluviKeyguardCardSettings.read(application)
            val target = FluviLockScreenCardCoordinator.materialSceneTarget(
                application, targetSettings.focus.asFinancialFocus(),
            )
            val core = FluviCoreFactory.create(application)
            val currentRevision = try { core.query.currentCoreRevision() } finally { core.close() }
            if (evidence.currentCoreRevision != currentRevision ||
                FluviKeyguardCardSettings.read(application) != targetSettings ||
                !FluviKeyguardCardSettings.systemServiceEnabled(application)) return@launch
            val geometry = geometry(targetSettings) ?: return@launch
            val now = System.currentTimeMillis()
            val temporal = temporalEvidence(evidence, targetSettings.focus.timeAxis, now) ?: return@launch
            val next = synchronized(lock) {
                if (session != request.first || generation != request.second || sequence == Long.MAX_VALUE) return@launch
                ++sequence
            }
            val descriptor = R29PublisherSnapshot.create(
                request.first, next, profile, target, targetSettings, temporal, geometry, now,
            ) ?: return@launch
            // Do not send a result that lost to a setting/data invalidation
            // while the projection or geometry was being resolved.
            synchronized(lock) {
                if (session != request.first || generation != request.second ||
                    ownership.phase() != R29Ownership.Phase.HOST) return@synchronized
                lastPublishedSequence = next
                client.publish(descriptor)
            }
        }
    }

    override fun onReady(nonce: String, sequence: Long) {
        val current = synchronized(lock) { session == nonce && lastPublishedSequence == sequence }
        if (current) listener.onReady(nonce, sequence)
    }

    override fun onHostUnavailable() {
        stopObserving()
        listener.onUnavailable()
    }

    override fun onPublicationFailure() {
        // Never clear durable suppression or claim a completed empty frame.
        stopObserving()
        listener.onUnavailable()
    }

    override fun onHostEmpty(nonce: String, sequence: Long, epoch: Long) {
        stopObserving()
        listener.onEmpty(nonce, sequence, epoch)
    }

    /** True means requested, not that an EMPTY frame has been observed. */
    fun requestEmpty(): Boolean = synchronized(lock) {
        if (session == null || sequence == Long.MAX_VALUE) return false
        generation += 1
        lastPublishedSequence = 0
        client.requestEmpty(++sequence)
    }

    /** Acknowledged data can survive a normal detach; unfinished work cannot. */
    fun close() {
        stopObserving()
        client.close()
        scope.cancel()
    }

    private fun stopObserving() {
        R35MaterialPublication.remove(this)
        synchronized(lock) { session = null; generation += 1; lastPublishedSequence = 0 }
        coreJob?.cancel()
        coreJob = null
        if (observersRegistered) {
            runCatching { application.unregisterReceiver(changes) }
            application.contentResolver.unregisterContentObserver(permissionChanges)
            observersRegistered = false
        }
    }

    private fun invalidateAndRefresh() {
        onInputsChanging()
        FluviKeyguardMaterialBridgeRegistry.requestSceneRefresh()
    }

    private val changes = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) = invalidateAndRefresh()
    }
    private val permissionChanges = object : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean) = invalidateAndRefresh()
    }

    private fun registerObservers() {
        if (observersRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_DATE_CHANGED)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
            addAction(Intent.ACTION_CONFIGURATION_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) application.registerReceiver(changes, filter, Context.RECEIVER_NOT_EXPORTED)
        else @Suppress("DEPRECATION") application.registerReceiver(changes, filter)
        application.contentResolver.registerContentObserver(
            Settings.Secure.getUriFor(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES), false, permissionChanges,
        )
        observersRegistered = true
    }

    private fun observeCoreRevisions() {
        coreJob?.cancel()
        coreJob = scope.launch {
            val core = FluviCoreFactory.create(application)
            try {
                var previous: Long? = null
                core.query.observeCoreRevision().collect { revision ->
                    if (previous != null && previous != revision) invalidateAndRefresh()
                    previous = revision
                }
            } finally { core.close() }
        }
    }

    private fun geometry(settings: com.fluvi.app.lockscreen.KeyguardCardSettings): R29Geometry? {
        if (Build.VERSION.SDK_INT < 30 || Process.myUserHandle() != UserHandle.getUserHandleForUid(0)) return null
        val display = application.getSystemService(DisplayManager::class.java)
            ?.getDisplay(Display.DEFAULT_DISPLAY) ?: return null
        val displayMetrics = DisplayMetrics()
        @Suppress("DEPRECATION") display.getRealMetrics(displayMetrics)
        val window = application.getSystemService(WindowManager::class.java)?.currentWindowMetrics ?: return null
        val bounds = window.bounds
        if (bounds.left != 0 || bounds.top != 0 || bounds.width() != displayMetrics.widthPixels ||
            bounds.height() != displayMetrics.heightPixels) return null
        val insets = window.windowInsets.getInsetsIgnoringVisibility(
            WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout(),
        )
        val safe = KeyguardUsableBounds(insets.left, insets.top,
            bounds.width() - insets.right, bounds.height() - insets.bottom)
        if (safe.safeRight <= safe.safeLeft || safe.safeBottom <= safe.safeTop) return null
        val size = application.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        val resolved = resolveKeyguardOverlayGeometry(
            safe, displayMetrics.density, application.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height),
            settings.presentationMode, settings.cardPosition, settings.orbPosition, settings.verticalOffsetDp, size,
        )
        val xTravel = bounds.width() - size
        val yTravel = bounds.height() - size
        if (xTravel <= 0 || yTravel <= 0) return null
        return R29Geometry(0, Display.DEFAULT_DISPLAY, bounds.width(), bounds.height(), displayMetrics.densityDpi,
            size, resolved.left.toFloat() / xTravel, resolved.top.toFloat() / yTravel)
    }

    private fun temporalEvidence(
        source: R35MaterialEvidence,
        axis: FluviLockScreenCardConfiguration.TimeAxis,
        now: Long,
    ): R29ProjectionEvidence? = runCatching {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        val (period, start, end) = when (axis) {
            FluviLockScreenCardConfiguration.TimeAxis.day -> Triple(R29Period.DAY, today, today.plusDays(1))
            FluviLockScreenCardConfiguration.TimeAxis.month -> {
                val first = today.withDayOfMonth(1)
                Triple(R29Period.MONTH, first, first.plusMonths(1))
            }
            FluviLockScreenCardConfiguration.TimeAxis.year -> {
                val first = today.withDayOfYear(1)
                Triple(R29Period.YEAR, first, first.plusYears(1))
            }
            // All-time data is revalidated no later than the next local day.
            FluviLockScreenCardConfiguration.TimeAxis.sum -> Triple(R29Period.ALL, today, today.plusDays(1))
        }
        val from = start.atStartOfDay(zone).toInstant().toEpochMilli()
        val until = end.atStartOfDay(zone).toInstant().toEpochMilli()
        if (now < from || now >= until) return null
        R29ProjectionEvidence(source.targetCoreRevision, source.visualCoreRevision, source.currentCoreRevision,
            source.focusGeneration, source.layoutRevision, source.privacyRevision, source.visualProjectionFull,
            from, until, zone.id, period)
    }.getOrNull()
}
