package com.fluvi.app.lockscreen.material

import android.annotation.SuppressLint
import android.graphics.Color
import android.graphics.ColorSpace
import android.graphics.HardwareBufferRenderer
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.RenderNode
import android.hardware.HardwareBuffer
import android.hardware.SyncFence
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.AttachedSurfaceControl
import android.view.Choreographer
import android.view.SurfaceControl
import android.view.View
import android.view.ViewTreeObserver
import androidx.annotation.RequiresApi
import java.time.Duration
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.Executor
import java.util.function.Consumer
import kotlin.math.min

/**
 * A lease is deliberately more precise than a View attachment.  A completed
 * renderer request can outlive an accessibility/window transition, therefore
 * a buffer is allowed to reach the compositor only while this exact lease is
 * still current on the Main-owned layer.
 */
internal data class KeyguardOrbBufferLease(
    val attachment: Long,
    val generation: Long,
    val visualKey: String,
    val programKey: String,
    val width: Int,
    val height: Int,
)

/** Main-owned first submission identity. The child is compared by object
 * identity, never by the logging hash; no buffer or fence is retained here. */
internal class KeyguardOrbFirstPublicationToken(
    val lease: KeyguardOrbBufferLease,
    val slotId: Long,
    val useGeneration: Long,
    val child: SurfaceControl,
)

internal data class KeyguardOrbFirstPublicationTimes(
    val readyAtUptimeMs: Long,
    val postedAtUptimeMs: Long,
    val mainEntryAtUptimeMs: Long,
    val applyBeginAtUptimeMs: Long,
    val applyEndAtUptimeMs: Long,
)

/** Instrumentation may defer delivery of real boundaries or inject an
 * exception. Production captures the no-op instance at construction. */
internal interface KeyguardOrbFirstPublicationTestHook {
    fun dispatchReady(frame: KeyguardOrbBufferProducerFrame, deliver: () -> Unit) = deliver()
    fun beforeApply(token: KeyguardOrbFirstPublicationToken) = Unit
    fun afterSubmitted(token: KeyguardOrbFirstPublicationToken) = Unit
    fun dispatchCommit(token: KeyguardOrbFirstPublicationToken, receivedAtUptimeMs: Long, deliver: () -> Unit) = deliver()
}

internal object NoopKeyguardOrbFirstPublicationTestHook : KeyguardOrbFirstPublicationTestHook

/** Instrumentation may defer only a real platform receipt or a real offered
 * ticket. Production never installs this hook. It must not block a thread. */
internal interface KeyguardOrbRecoveryTestHook {
    fun allowRender(lease: KeyguardOrbBufferLease): Boolean = true
    fun dispatchRelease(lease: KeyguardOrbBufferLease, slotId: Long, use: Long,
                        fence: SyncFence?, deliver: () -> Unit) = deliver()
    fun dispatchTicket(ticket: KeyguardOrbPressureTicket, deliver: () -> Unit) = deliver()
    fun onRetirementEvent(lease: KeyguardOrbBufferLease, childIdentity: Int, event: String, uptimeMs: Long) = Unit
    fun onPlacement(lease: KeyguardOrbBufferLease, childIdentity: Int, submitted: Boolean) = Unit
}
internal object NoopKeyguardOrbRecoveryTestHook : KeyguardOrbRecoveryTestHook

/**
 * The Main-owned submission boundary for removing an isolated child layer.
 * This is not a presentation callback and must never be used to release a
 * producer buffer: the worker still owns that through its fence path.
 */
internal data class KeyguardOrbLayerHideSubmission(
    val lease: KeyguardOrbBufferLease,
    val submittedAtUptimeMs: Long,
    val transactionApplied: Boolean,
    val applyReturnedAtUptimeMs: Long?,
)

/** Immutable cross-thread input. RuntimeShader, Paint, RenderNode and every
 * fence remain renderer-thread-owned. */
internal data class KeyguardOrbBufferRenderSpec(
    val lease: KeyguardOrbBufferLease,
    val artifact: KeyguardShaderArtifact,
    val scene: KeyguardMaterialScene,
    /** The bounded semantic transition used by the legacy material route.
     * The old artifact can be absent while it is loading; in that case the
     * current program remains the compatibility transition base. */
    val previousScene: KeyguardMaterialScene? = null,
    val previousArtifact: KeyguardShaderArtifact? = null,
    val transitionStartedNanos: Long = 0L,
)

internal data class KeyguardOrbFirstWorkSnapshot(
    val attachment: Long, val generation: Long, val requestedAt: Long,
    val startedAt: Long?, val resultAt: Long?, val resultStatus: Int?, val captureOwner: Any,
    val firstAt: Long?, val firstSlot: Long?, val firstUse: Long?,
    val secondAt: Long?, val secondSlot: Long?, val secondUse: Long?,
)

internal data class KeyguardOrbBufferRendererSnapshot(
    val enabled: Boolean,
    val attached: Boolean,
    val layerVisible: Boolean,
    val framesProduced: Int,
    val framesPublished: Int,
    val framesDropped: Int,
    val failures: Int,
    val inFlight: Int,
    val ready: Int,
    val compositorOwned: Int,
    /** Advisory worker-control state for bounded lifecycle diagnostics. */
    val workerRunning: Boolean,
    val workerDesiredAttachment: Long,
    val workerDesiredGeneration: Long,
    val workerAttachedAttachment: Long,
    val workerAttachedGeneration: Long,
    /** Worker completion cadence, not display/compositor presentation. */
    val completionGapMaxMs: Long,
    val workerSampleAtUptimeMs: Long,
    val workerSampleSequence: Long,
    val workerBlockReason: Int,
    val workerGrantAttachment: Long,
    val workerGrantGeneration: Long,
    val workerGrantIdentity: Int,
    val workerGrantActive: Boolean,
    val workerLastCompletionAtUptimeMs: Long,
    val positionSubmissions: Int = 0,
    val positionSuppressions: Int = 0,
    val firstWork: KeyguardOrbFirstWorkSnapshot? = null,
)

private data class KeyguardOrbBufferAttachment(
    val root: View,
    val orb: View,
    val attachment: Long,
)

/** Test-only gate at the real worker submission boundary.  It is intentionally
 * not a visibility gate: Main can hide/revoke while a renderer thread waits. */
internal fun interface KeyguardOrbRenderBarrier {
    fun beforeRender(lease: KeyguardOrbBufferLease)
}

internal object NoopKeyguardOrbRenderBarrier : KeyguardOrbRenderBarrier {
    override fun beforeRender(lease: KeyguardOrbBufferLease) = Unit
}

/**
 * Test-only observation of an already-completed producer request.  It is
 * deliberately invoked on the renderer owner, never on Main, and production
 * installs the no-op implementation.  The observer must not retain or close
 * the supplied HardwareBuffer or SyncFence: the renderer and SurfaceControl
 * remain their owners.
 *
 * This is narrower than a presentation callback.  It answers whether the
 * exact buffer about to be submitted contains distinct canonical phases; it
 * makes no claim that SurfaceFlinger has composed those pixels.
 */
internal data class KeyguardOrbBufferProducerFrame(
    val lease: KeyguardOrbBufferLease,
    val slotId: Long,
    val useGeneration: Long,
    val frameTimeNanos: Long,
    val materialTime: KeyguardMaterialTime,
    /**
     * Test-only identity captured with the immutable material-time sample
     * used for this submission. Production time sources return null, so this
     * is neither a user setting nor a per-frame bridge payload.
     */
    val testRequestId: Long? = null,
)

internal fun interface KeyguardOrbBufferFrameObserver {
    fun onProduced(
        frame: KeyguardOrbBufferProducerFrame,
        buffer: HardwareBuffer,
        completionFence: SyncFence?,
    )
}

internal object NoopKeyguardOrbBufferFrameObserver : KeyguardOrbBufferFrameObserver {
    override fun onProduced(
        frame: KeyguardOrbBufferProducerFrame,
        buffer: HardwareBuffer,
        completionFence: SyncFence?,
    ) = Unit
}

/**
 * Test-only acknowledgement that Main submitted this exact producer frame to
 * the current SurfaceControl layer. It is deliberately a submission boundary,
 * not a claim that SurfaceFlinger has presented the pixels physically.
 */
internal fun interface KeyguardOrbBufferPublicationObserver {
    fun onSubmitted(frame: KeyguardOrbBufferProducerFrame)
}

internal object NoopKeyguardOrbBufferPublicationObserver : KeyguardOrbBufferPublicationObserver {
    override fun onSubmitted(frame: KeyguardOrbBufferProducerFrame) = Unit
}

/** Holds an already accepted steady publication only in instrumentation. Main
 * retains its immediate revocation/visibility authority while this runs. */
internal fun interface KeyguardOrbSteadyPublicationBarrier {
    fun afterGrantValidated(frame: KeyguardOrbBufferProducerFrame)
}

internal object NoopKeyguardOrbSteadyPublicationBarrier : KeyguardOrbSteadyPublicationBarrier {
    override fun afterGrantValidated(frame: KeyguardOrbBufferProducerFrame) = Unit
}

internal data class KeyguardOrbOwnershipSlotSnapshot(
    val slotId: Long,
    val useGeneration: Long,
    val lease: KeyguardOrbBufferLease?,
    val state: String,
    val retired: Boolean,
    val childIdentity: Int?,
    val publicationPath: String?,
    val callbackReceived: Boolean,
    val fencePending: Boolean,
    val earlyReceiptRetained: Boolean,
)

/** One Worker observation, never a merger of independently sampled Main
 * diagnostics. The atomic grant is read once; Main can revoke it afterwards.
 * This immutable copy has no buffer, fence or visibility authority. */
internal data class KeyguardOrbOwnershipEvent(
    val event: String,
    val rendererId: Long,
    val uptimeMs: Long,
    val thread: String,
    val lease: KeyguardOrbBufferLease?,
    val childIdentity: Int?,
    val grantIdentity: Int?,
    val slotId: Long?,
    val useGeneration: Long?,
    val desiredLease: KeyguardOrbBufferLease?,
    val attachedLease: KeyguardOrbBufferLease?,
    val currentGrantLease: KeyguardOrbBufferLease?,
    val currentGrantChildIdentity: Int?,
    val currentGrantIdentity: Int?,
    val currentGrantActive: Boolean,
    val slots: List<KeyguardOrbOwnershipSlotSnapshot>,
    val detail: String,
)

internal fun interface KeyguardOrbOwnershipObserver {
    fun onEvent(event: KeyguardOrbOwnershipEvent)
}

internal object NoopKeyguardOrbOwnershipObserver : KeyguardOrbOwnershipObserver {
    override fun onEvent(event: KeyguardOrbOwnershipEvent) = Unit
}

private val nextOrbRendererId = AtomicLong()

/**
 * The isolated producer owns its frame clock.  Instrumentation may inject a
 * deterministic material-time source, but the dependency is captured when a
 * window/controller is constructed; production continues to use the scene's
 * monotonic clock and no per-frame Flutter transport is introduced.
 */
internal fun interface KeyguardOrbMaterialTimeSource {
    fun timeAt(scene: KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime

    /**
     * Associates an already captured test time with its submission request.
     * The default keeps the production renderer free of test metadata.
     */
    fun testRequestIdFor(materialTime: KeyguardMaterialTime): Long? = null
}

internal object SystemKeyguardOrbMaterialTimeSource : KeyguardOrbMaterialTimeSource {
    override fun timeAt(scene: KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime =
        scene.timeAt(frameTimeNanos)
}

/** Exact-object grants are safe to revoke after a newer attachment installs
 * its own grant. Equality is intentionally not used for retirement. */
internal class KeyguardOrbPublicationGrantStore<T : Any> {
    private val value = AtomicReference<T?>(null)

    fun install(next: T): T? = value.getAndSet(next)
    fun current(): T? = value.get()
    fun revokeExact(expected: T): Boolean = value.compareAndSet(expected, null)
    fun revokeCurrent(): T? = value.getAndSet(null)
}

internal enum class KeyguardOrbPressureReason { ALL_OLD_UNRELEASED, NO_SUCCESSOR, WRONG_SIZE_OLD }

/** A pending offer can be consumed once or cancelled once, never both. */
internal class KeyguardOrbPressureClaim {
    private val state = AtomicInteger(0)
    fun claim(): Boolean = state.compareAndSet(0, 1)
    fun cancel(): Boolean = state.compareAndSet(0, 2)
    fun isPending(): Boolean = state.get() == 0
    fun isClaimed(): Boolean = state.get() == 1
}

/** A single bounded Worker observation. Object identity of grant/child is
 * authority; numeric identities in [slots] are diagnostic only. */
internal class KeyguardOrbPressureTicket(
    val rendererId: Long,
    val lease: KeyguardOrbBufferLease,
    val sceneKey: String,
    val sceneFull: Boolean,
    val effectId: String,
    val usesPortal: Boolean,
    val child: SurfaceControl,
    internal val grant: Any,
    val reason: KeyguardOrbPressureReason,
    val startedAt: Long,
    val offeredAt: Long,
    val opportunities: Int,
    val slots: List<KeyguardOrbOwnershipSlotSnapshot>,
) {
    internal val claim = KeyguardOrbPressureClaim()
}

/** Worker-owned transient filter. Arguments are one coherent observation of
 * the actual pool. It conveys no permission to reuse a slot. */
internal class KeyguardOrbPressurePolicy {
    private var grant: Any? = null
    private var reason: KeyguardOrbPressureReason? = null
    private var progress = 0
    var startedAt = 0L
        private set
    var opportunities = 0
        private set

    fun reset() {
        grant = null
        reason = null
        startedAt = 0L
        opportunities = 0
    }

    fun observe(
        grant: Any?, eligible: Boolean, slotCount: Int, oldUnreleased: Int,
        oldOwned: Int, free: Int, currentInFlight: Boolean, wrongSizeOld: Boolean,
        currentCompatible: Boolean, progress: Int, now: Long, opportunity: Boolean,
    ): KeyguardOrbPressureReason? {
        // FREE storage can be resized, and unallocated capacity can be
        // constructed without touching an old compositor-owned buffer.
        val productiveCapacity = free + (3 - slotCount).coerceAtLeast(0)
        val candidate = when {
            !eligible || grant == null -> null
            slotCount == 3 && oldUnreleased == 3 -> KeyguardOrbPressureReason.ALL_OLD_UNRELEASED
            productiveCapacity == 0 && oldOwned >= 2 && !currentInFlight -> KeyguardOrbPressureReason.NO_SUCCESSOR
            wrongSizeOld && productiveCapacity == 0 && !currentInFlight -> KeyguardOrbPressureReason.WRONG_SIZE_OLD
            else -> null
        }
        if (candidate == null) {
            reset()
            return null
        }
        if (this.grant !== grant || reason != candidate || this.progress != progress) {
            this.grant = grant
            reason = candidate
            this.progress = progress
            startedAt = now
            opportunities = 0
        }
        if (opportunity && opportunities < Int.MAX_VALUE) opportunities++
        return candidate.takeIf {
            it == KeyguardOrbPressureReason.ALL_OLD_UNRELEASED ||
                (opportunities >= 3 && now - startedAt >= 50L)
        }
    }
}

/** Last successfully submitted geometry, owned exclusively by Main. */
internal class KeyguardOrbPlacementCache {
    private var child: Any? = null
    private var root: Any? = null
    private var lease: KeyguardOrbBufferLease? = null
    private var x = 0
    private var y = 0

    fun needsSubmission(child: Any, root: Any, lease: KeyguardOrbBufferLease, x: Int, y: Int): Boolean =
        this.child !== child || this.root !== root || this.lease != lease || this.x != x || this.y != y
    fun submitted(child: Any, root: Any, lease: KeyguardOrbBufferLease, x: Int, y: Int) {
        this.child = child; this.root = root; this.lease = lease; this.x = x; this.y = y
    }
    fun invalidate() { child = null; root = null; lease = null }
}

/** Main-owned join for an exact child's retirement. Transaction commitment
 * permits only child unlink; it never releases or reuses a producer slot. */
internal class KeyguardOrbRetirementBarrier {
    private var mainFinished = false
    private var finalFinished = false
    private var finalApplied = false
    private var committed = false
    private var drained = false
    private var failed = false
    private var drainRetryUsed = false
    private var unlinked = false

    fun mainHideCompleted() { mainFinished = true }
    fun finalClearCompleted(applied: Boolean) { finalFinished = true; finalApplied = applied }
    fun commitObserved() { committed = true }
    fun leaseDrained() { drained = true }
    fun isDrained(): Boolean = drained
    fun shouldUnlink(): Boolean = !unlinked && mainFinished && finalFinished &&
        ((finalApplied && committed) || drained) && (!failed || (drained && !drainRetryUsed))
    fun unlinkAttempted(success: Boolean) {
        if (failed) drainRetryUsed = true
        if (success) unlinked = true else failed = true
    }
}

internal data class KeyguardOrbRetirementEvent(
    val lease: KeyguardOrbBufferLease,
    val childIdentity: Int,
    val reason: String,
    val stage: String,
    val observedAtUptimeMs: Long,
    val slotId: Long? = null,
    val useGeneration: Long? = null,
)

private class KeyguardOrbRetiringLayer(
    val lease: KeyguardOrbBufferLease,
    val id: Long,
    var child: SurfaceControl?,
    val childIdentity: Int,
    val reason: String,
    val observer: ((KeyguardOrbRetirementEvent) -> Unit)?,
    val barrier: KeyguardOrbRetirementBarrier = KeyguardOrbRetirementBarrier(),
)

/** Presence is distinct from the nullable platform fence carried by a
 * release receipt. A receipt is consumed exactly once by its slot/use key. */
internal data class KeyguardOrbReleaseReceipt<T>(val value: T?)

internal class KeyguardOrbEarlyReleaseReceiptStore<T> {
    private val values = mutableMapOf<Pair<Long, Long>, KeyguardOrbReleaseReceipt<T>>()

    fun record(key: Pair<Long, Long>, value: T?): Boolean {
        if (values.containsKey(key)) return false
        values[key] = KeyguardOrbReleaseReceipt(value)
        return true
    }

    fun take(key: Pair<Long, Long>): KeyguardOrbReleaseReceipt<T>? = values.remove(key)
    fun discard(key: Pair<Long, Long>): KeyguardOrbReleaseReceipt<T>? = values.remove(key)
}

/** The service is constructed by Android, so instrumentation installs this
 * seam before binding it.  Controllers snapshot the observer at construction;
 * changing it cannot affect an existing renderer. */
internal object KeyguardOrbBufferRendererTestHooks {
    @Volatile var frameObserver: KeyguardOrbBufferFrameObserver = NoopKeyguardOrbBufferFrameObserver
    @Volatile var publicationObserver: KeyguardOrbBufferPublicationObserver =
        NoopKeyguardOrbBufferPublicationObserver
    @Volatile var materialTimeSource: KeyguardOrbMaterialTimeSource = SystemKeyguardOrbMaterialTimeSource
    @Volatile var steadyPublicationBarrier: KeyguardOrbSteadyPublicationBarrier =
        NoopKeyguardOrbSteadyPublicationBarrier
    @Volatile var ownershipObserver: KeyguardOrbOwnershipObserver = NoopKeyguardOrbOwnershipObserver
    @Volatile var firstPublicationHook: KeyguardOrbFirstPublicationTestHook = NoopKeyguardOrbFirstPublicationTestHook
    @Volatile var recoveryHook: KeyguardOrbRecoveryTestHook = NoopKeyguardOrbRecoveryTestHook
}

/**
 * API-34 isolated standalone-orb producer.  The public wrapper has no
 * platform side effects below API 34.  Main owns all SurfaceControl lifecycle
 * operations; the HandlerThread owns the actual HardwareBufferRenderer work.
 *
 * This intentionally does not create a second WindowManager window or input
 * surface.  The child layer is reparented below the existing accessibility
 * overlay's root surface and is retired before that root is removed.
 */
internal class KeyguardOrbBufferRenderer(
    private val onFirstPublished: (KeyguardOrbFirstPublicationToken, KeyguardOrbFirstPublicationTimes) -> Unit,
    private val onFirstCommitReceived: (KeyguardOrbFirstPublicationToken, Long, Long) -> Unit,
    private val onFirstCommitted: (KeyguardOrbFirstPublicationToken) -> Unit,
    private val onFailure: (KeyguardOrbBufferLease, Throwable) -> Unit,
    private val onPressure: (KeyguardOrbPressureTicket) -> Unit = {},
    private val onCapacityRestored: (KeyguardOrbPressureTicket, Long) -> Unit = { _, _ -> },
    /** Called on Main when the View's measured buffer target differs from the
     * immutable lease. The controller creates a new generation; this class
     * never stretches a completed buffer. */
    private val onSizeChanged: () -> Unit,
    private val barrier: KeyguardOrbRenderBarrier = NoopKeyguardOrbRenderBarrier,
    private val frameObserver: KeyguardOrbBufferFrameObserver = NoopKeyguardOrbBufferFrameObserver,
    private val publicationObserver: KeyguardOrbBufferPublicationObserver =
        NoopKeyguardOrbBufferPublicationObserver,
    private val materialTimeSource: KeyguardOrbMaterialTimeSource = SystemKeyguardOrbMaterialTimeSource,
    private val timingOwner: () -> Any? = { null },
    /** Observes only the exact Main transaction submission. It carries no
     * visibility or buffer-lifetime authority. */
    private val onLayerHideSubmitted: (KeyguardOrbLayerHideSubmission) -> Unit = {},
    /** A detached frame has completed through the same bounded buffer owner
     * used after attachment.  This is observational only: a detached frame
     * remains without a parent layer and is never a visibility grant. */
    private val onDetachedBackendPrepared: (KeyguardOrbBufferLease, Long) -> Unit = { _, _ -> },
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
    private val steadyPublicationBarrier: KeyguardOrbSteadyPublicationBarrier =
        KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier,
    private val ownershipObserver: KeyguardOrbOwnershipObserver =
        KeyguardOrbBufferRendererTestHooks.ownershipObserver,
    private val firstPublicationHook: KeyguardOrbFirstPublicationTestHook =
        KeyguardOrbBufferRendererTestHooks.firstPublicationHook,
    private val recoveryHook: KeyguardOrbRecoveryTestHook = KeyguardOrbBufferRendererTestHooks.recoveryHook,
) {
    private val rendererId = nextOrbRendererId.incrementAndGet()
    private var api34: Api34? = null

    fun isSupported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE

    fun configure(spec: KeyguardOrbBufferRenderSpec) {
        if (!isSupported()) return
        requireMainThread()
        delegate().configure(spec)
    }

    fun attach(root: View, orb: View, attachment: Long) {
        if (!isSupported()) return
        requireMainThread()
        delegate().attach(root, orb, attachment)
    }

    /** Hides and unparents synchronously on Main before the caller removes its
     * WindowManager root.  Worker cleanup is intentionally asynchronous. */
    fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
               onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? = null) {
        if (!isSupported()) return
        requireMainThread()
        api34?.retire(reason, onLayerHideCommitted, onRetirementEvent)
    }

    fun dispose() {
        if (!isSupported()) return
        requireMainThread()
        api34?.dispose()
        api34 = null
    }

    fun snapshot(): KeyguardOrbBufferRendererSnapshot = api34?.snapshot()
        ?: KeyguardOrbBufferRendererSnapshot(
            enabled = false,
            attached = false,
            layerVisible = false,
            framesProduced = 0,
            framesPublished = 0,
            framesDropped = 0,
            failures = 0,
            inFlight = 0,
            ready = 0,
            compositorOwned = 0,
            workerRunning = false,
            workerDesiredAttachment = -1L,
            workerDesiredGeneration = -1L,
            workerAttachedAttachment = -1L,
            workerAttachedGeneration = -1L,
            completionGapMaxMs = 0L,
            workerSampleAtUptimeMs = 0L,
            workerSampleSequence = 0L,
            workerBlockReason = 0,
            workerGrantAttachment = -1L,
            workerGrantGeneration = -1L,
            workerGrantIdentity = 0,
            workerGrantActive = false,
            workerLastCompletionAtUptimeMs = 0L,
        )

    fun ownsFirstPublication(token: KeyguardOrbFirstPublicationToken): Boolean {
        if (!isSupported()) return false
        requireMainThread()
        return api34?.ownsFirstPublication(token) == true
    }

    /** Main verifies its root and scene before claiming; this checks the
     * renderer's exact live child/grant and races cancellation atomically. */
    fun claimPressure(ticket: KeyguardOrbPressureTicket): Boolean {
        if (!isSupported()) return false
        requireMainThread()
        return api34?.claimPressure(ticket) == true
    }

    /** Queue only after Main has retired the accepted exact layer. */
    fun acceptPressure(ticket: KeyguardOrbPressureTicket) {
        if (!isSupported()) return
        requireMainThread()
        api34?.acceptPressure(ticket)
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun delegate(): Api34 = api34 ?: Api34().also { api34 = it }

    private fun requireMainThread() {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "KeyguardOrbBufferRenderer layer ownership is Main-only"
        }
    }

    @SuppressLint("NewApi")
    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private inner class Api34 {
        private var desired: KeyguardOrbBufferRenderSpec? = null
        private var attachment: KeyguardOrbBufferAttachment? = null
        private var layer: SurfaceControl? = null
        private var layerLease: KeyguardOrbBufferLease? = null
        // Main owns child lifetime independently of the Worker's slot uses.
        // Each callback must match this exact immutable lease and record id.
        private val retiringLayers = mutableMapOf<Pair<KeyguardOrbBufferLease, Long>, KeyguardOrbRetiringLayer>()
        private var nextRetirementId = 0L
        private val placement = KeyguardOrbPlacementCache()
        private var positionSubmissions = 0
        private var positionSuppressions = 0
        private var firstPublishedLease: KeyguardOrbBufferLease? = null
        private var firstPublishedToken: KeyguardOrbFirstPublicationToken? = null
        private var attachListener: View.OnAttachStateChangeListener? = null
        private var layoutListener: View.OnLayoutChangeListener? = null
        /**
         * `attach()` can run after WindowManager accepted the root but before
         * its first usable layout.  The root attachment callback covers the
         * former race, while this one-shot traversal callback covers the
         * latter without introducing a timed retry or a second visibility
         * authority.
         */
        private var pendingLayerTraversal: ViewTreeObserver.OnPreDrawListener? = null
        private var disposed = false
        private var framesPublished = 0
        private var failures = 0
        private val worker = Worker(
            onFrameReady = ::onFrameReady,
            onFailure = ::onWorkerFailure,
            onLeaseDrained = ::onLeaseDrained,
            onFinalClearFinished = { lease, id, applied, observedAt ->
                mainHandler.post { onFinalClearFinished(lease, id, applied, observedAt) }
            },
            onFinalClearCommitted = ::onFinalClearCommitted,
            onRetiredUseEvent = { lease, id, stage, slot, use, at ->
                mainHandler.post { onRetiredUseEvent(lease, id, stage, slot, use, at) }
            },
            mainHandler = mainHandler,
            onPressure = { ticket -> mainHandler.post {
                if (recoveryHook === NoopKeyguardOrbRecoveryTestHook) deliverPressure(ticket)
                else recoveryHook.dispatchTicket(ticket) { deliverPressure(ticket) }
            } },
            onCapacityRestored = { ticket, observedAt ->
                mainHandler.post { if (!disposed) onCapacityRestored(ticket, observedAt) }
            },
            barrier = barrier,
            frameObserver = frameObserver,
            publicationObserver = publicationObserver,
            materialTimeSource = materialTimeSource,
            timingOwner = timingOwner,
            steadyPublicationBarrier = steadyPublicationBarrier,
            ownershipObserver = ownershipObserver,
            recoveryHook = recoveryHook,
            rendererId = rendererId,
        )

        private fun deliverPressure(ticket: KeyguardOrbPressureTicket) {
            if (disposed || desired?.lease != ticket.lease || desired?.scene?.visualKey != ticket.sceneKey ||
                layerLease != ticket.lease || layer !== ticket.child || !ticket.child.isValid ||
                attachment?.attachment != ticket.lease.attachment ||
                attachment?.root?.isAttachedToWindow != true
            ) {
                ticket.claim.cancel()
                return
            }
            onPressure(ticket)
        }

        fun claimPressure(ticket: KeyguardOrbPressureTicket): Boolean {
            if (disposed || ticket.rendererId != rendererId || desired?.lease != ticket.lease ||
                desired?.scene?.visualKey != ticket.sceneKey || layerLease != ticket.lease ||
                layer !== ticket.child || !ticket.child.isValid ||
                attachment?.attachment != ticket.lease.attachment ||
                attachment?.root?.isAttachedToWindow != true
            ) return false
            return worker.claimPressure(ticket)
        }

        fun acceptPressure(ticket: KeyguardOrbPressureTicket) = worker.acceptPressure(ticket)

        fun configure(spec: KeyguardOrbBufferRenderSpec) {
            if (disposed) return
            val old = desired
            desired = spec
            if (old?.lease != spec.lease) {
                if (layerLease != null && layerLease != spec.lease) hideLayer()
            }
            // A full -> neutral transition must revoke an already presented
            // full-colour buffer before the renderer is allowed to produce
            // the replacement. The caller's View bootstrap is the safe local
            // temporary content.
            if (old != null && old.scene.full && !spec.scene.full) hideLayer()
            val current = attachment
            if (current != null && current.attachment == spec.lease.attachment) {
                ensureLayer(current)
            }
            worker.configure(spec)
        }

        fun attach(root: View, orb: View, attachGeneration: Long) {
            if (disposed) return
            val spec = desired ?: return
            if (spec.lease.attachment != attachGeneration) return
            val next = KeyguardOrbBufferAttachment(root, orb, attachGeneration)
            if (attachment != null &&
                (attachment?.root !== root || attachment?.attachment != attachGeneration)
            ) {
                retire("attachment-replaced")
                // Re-post the current immutable spec after retiring the old
                // attachment. The worker's lease-scoped retirement rejects
                // old output without clearing a newer desired spec.
                desired = spec
                worker.configure(spec)
            }
            if (attachment == null) {
                attachment = next
                installAttachmentListeners(next)
            }
            ensureLayer(next)
        }

        fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
                   onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? = null) {
            // Capture the exact lease while Main still owns the old
            // attachment/layer. hideLayer() revokes that lease immediately,
            // and a replacement may install its own publication target before
            // this worker command is eventually drained.
            val retiredLease = layerLease ?: desired?.lease
            val oldAttachment = attachment
            removeAttachmentListeners(oldAttachment)
            attachment = null
            hideLayer(onLayerHideCommitted, reason, onRetirementEvent)
            firstPublishedLease = null
            worker.retire(retiredLease, reason)
        }

        fun dispose() {
            if (disposed) return
            retire("dispose")
            disposed = true
            worker.dispose()
        }

        fun snapshot(): KeyguardOrbBufferRendererSnapshot {
            val workerSnapshot = worker.snapshot()
            return KeyguardOrbBufferRendererSnapshot(
                enabled = !disposed,
                attached = attachment != null,
                layerVisible = layer != null && firstPublishedLease == layerLease,
                framesProduced = workerSnapshot.produced,
                framesPublished = workerSnapshot.published,
                framesDropped = workerSnapshot.dropped,
                failures = failures + workerSnapshot.failures,
                inFlight = workerSnapshot.inFlight,
                ready = workerSnapshot.ready,
                compositorOwned = workerSnapshot.compositorOwned,
                workerRunning = workerSnapshot.running,
                workerDesiredAttachment = workerSnapshot.desiredAttachment,
                workerDesiredGeneration = workerSnapshot.desiredGeneration,
                workerAttachedAttachment = workerSnapshot.attachedAttachment,
                workerAttachedGeneration = workerSnapshot.attachedGeneration,
                completionGapMaxMs = workerSnapshot.completionGapMaxMs,
                workerSampleAtUptimeMs = workerSnapshot.sampleAt,
                workerSampleSequence = workerSnapshot.sampleSequence,
                workerBlockReason = workerSnapshot.blockReason,
                workerGrantAttachment = workerSnapshot.grantAttachment,
                workerGrantGeneration = workerSnapshot.grantGeneration,
                workerGrantIdentity = workerSnapshot.grantIdentity,
                workerGrantActive = workerSnapshot.grantActive,
                workerLastCompletionAtUptimeMs = workerSnapshot.lastCompletionAt,
                positionSubmissions = positionSubmissions,
                positionSuppressions = positionSuppressions,
                firstWork = workerSnapshot.firstWork,
            )
        }

        fun ownsFirstPublication(token: KeyguardOrbFirstPublicationToken): Boolean =
            !disposed && firstPublishedToken === token && layer === token.child &&
                layerLease == token.lease && desired?.lease == token.lease &&
                attachment?.attachment == token.lease.attachment && attachment?.root?.isAttachedToWindow == true

        private fun installAttachmentListeners(value: KeyguardOrbBufferAttachment) {
            val attach = object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    if (attachment?.root === value.root && attachment?.attachment == value.attachment) {
                        ensureLayer(value)
                    }
                }

                override fun onViewDetachedFromWindow(v: View) {
                    if (attachment?.root === value.root && attachment?.attachment == value.attachment) {
                        retire("root-detached")
                    }
                }
            }
            val layout = View.OnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
                if (attachment?.root === value.root && attachment?.attachment == value.attachment) {
                    ensureLayer(value)
                }
            }
            attachListener = attach
            layoutListener = layout
            value.root.addOnAttachStateChangeListener(attach)
            value.orb.addOnLayoutChangeListener(layout)
        }

        private fun removeAttachmentListeners(value: KeyguardOrbBufferAttachment?) {
            val attach = attachListener
            val layout = layoutListener
            val traversal = pendingLayerTraversal
            if (value != null) {
                if (attach != null) value.root.removeOnAttachStateChangeListener(attach)
                if (layout != null) value.orb.removeOnLayoutChangeListener(layout)
                if (traversal != null && value.root.viewTreeObserver.isAlive) {
                    value.root.viewTreeObserver.removeOnPreDrawListener(traversal)
                }
            }
            attachListener = null
            layoutListener = null
            pendingLayerTraversal = null
        }

        private fun ensureLayer(value: KeyguardOrbBufferAttachment) {
            val spec = desired ?: return
            if (!value.root.isAttachedToWindow || value.orb.width <= 0 || value.orb.height <= 0) {
                scheduleLayerTraversal(value)
                return
            }
            if (spec.lease.attachment != value.attachment) return
            if (spec.lease.width != value.orb.width || spec.lease.height != value.orb.height) {
                // Dimensions are part of the lease. Do not stretch a stale
                // render target; establish a new controller-owned lease.
                // Do not recursively reconfigure while Api34.configure is
                // still handing its immutable spec to the worker.
                mainHandler.post(onSizeChanged)
                return
            }
            val existing = layer
            val location = IntArray(2)
            value.orb.getLocationInSurface(location)
            if (existing == null) {
                val parent: AttachedSurfaceControl = value.root.rootSurfaceControl ?: run {
                    scheduleLayerTraversal(value)
                    return
                }
                val child = SurfaceControl.Builder()
                    .setName("FluviKeyguardStandaloneOrb")
                    .setBufferSize(spec.lease.width, spec.lease.height)
                    .setFormat(PixelFormat.RGBA_8888)
                    .setOpaque(false)
                    .setHidden(true)
                    .build()
                val reparent = parent.buildReparentTransaction(child) ?: run {
                    child.release()
                    placement.invalidate()
                    scheduleLayerTraversal(value)
                    return
                }
                val result = runCatching {
                    try {
                        reparent.setPosition(child, location[0].toFloat(), location[1].toFloat())
                            .setLayer(child, Int.MAX_VALUE)
                            .setVisibility(child, false)
                            .apply()
                    } finally {
                        runCatching { reparent.close() }
                    }
                }
                if (result.isFailure) {
                    placement.invalidate()
                    runCatching { child.release() }
                    failures += 1
                    onFailure(spec.lease, requireNotNull(result.exceptionOrNull()))
                    return
                }
                layer = child
                layerLease = spec.lease
                firstPublishedLease = null
                firstPublishedToken = null
                placement.submitted(child, value.root, spec.lease, location[0], location[1])
                positionSubmissions += 1
                if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook) {
                    runCatching { recoveryHook.onPlacement(spec.lease, System.identityHashCode(child), true) }
                }
            } else if (placement.needsSubmission(existing, value.root, spec.lease, location[0], location[1])) {
                val result = runCatching {
                    val transaction = SurfaceControl.Transaction()
                    try {
                        transaction.setPosition(existing, location[0].toFloat(), location[1].toFloat()).apply()
                    } finally {
                        runCatching { transaction.close() }
                    }
                }
                if (result.isFailure) {
                    placement.invalidate()
                    failures += 1
                    onFailure(spec.lease, requireNotNull(result.exceptionOrNull()))
                    return
                }
                placement.submitted(existing, value.root, spec.lease, location[0], location[1])
                positionSubmissions += 1
                if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook) {
                    runCatching { recoveryHook.onPlacement(spec.lease, System.identityHashCode(existing), true) }
                }
            } else {
                positionSuppressions += 1
                if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook) {
                    runCatching { recoveryHook.onPlacement(spec.lease, System.identityHashCode(existing), false) }
                }
            }
            worker.setAttachment(spec.lease, requireNotNull(layer))
        }

        /**
         * A single next-traversal recheck closes the WindowManager/layout
         * ordering gap.  It is only armed while this exact Main-owned
         * attachment remains current; an old callback cannot attach or reveal
         * a replacement lease.
         */
        private fun scheduleLayerTraversal(value: KeyguardOrbBufferAttachment) {
            if (pendingLayerTraversal != null || !value.root.isAttachedToWindow) return
            val observer = value.root.viewTreeObserver
            if (!observer.isAlive) return
            lateinit var listener: ViewTreeObserver.OnPreDrawListener
            listener = ViewTreeObserver.OnPreDrawListener {
                if (value.root.viewTreeObserver.isAlive) {
                    value.root.viewTreeObserver.removeOnPreDrawListener(listener)
                }
                if (pendingLayerTraversal === listener) pendingLayerTraversal = null
                if (!disposed && attachment?.root === value.root &&
                    attachment?.attachment == value.attachment &&
                    desired?.lease?.attachment == value.attachment
                ) {
                    ensureLayer(value)
                }
                true
            }
            pendingLayerTraversal = listener
            observer.addOnPreDrawListener(listener)
        }

        private fun hideLayer(onCommitted: ((Long) -> Unit)? = null, reason: String = "reconfigure",
                              observer: ((KeyguardOrbRetirementEvent) -> Unit)? = null) {
            val child = layer ?: return
            val lease = layerLease
            val retirement = lease?.let {
                KeyguardOrbRetiringLayer(it, ++nextRetirementId, child, System.identityHashCode(child), reason, observer).also { record ->
                    // Publish the exact child before making its grant inactive.
                    retiringLayers[it to record.id] = record
                    worker.revokePublicationAuthority(it, child)
                }
            }
            val submittedAtUptimeMs = SystemClock.uptimeMillis()
            var applyReturnedAtUptimeMs: Long? = null
            val transactionApplied = runCatching {
                val transaction = SurfaceControl.Transaction()
                try {
                    transaction
                    // SurfaceControl's null-buffer form releases the last
                    // displayed buffer and invokes its release callback.  A
                    // visibility transaction alone may leave that
                    // compositor-owned slot stranded. Commit this release
                    // before unparenting the layer: destroying the child in
                    // the same transaction can discard the callback needed
                    // to retire the worker-owned HardwareBuffer safely.
                    .setBuffer(child, null as HardwareBuffer?)
                    .setVisibility(child, false)
                    if (onCommitted != null) {
                        // Listener registration and later diagnostic delivery
                        // are observational; neither can suppress the hide.
                        runCatching {
                            val receiptAt = AtomicLong(0L)
                            val executor = Executor { command ->
                                receiptAt.compareAndSet(0L, SystemClock.uptimeMillis())
                                mainHandler.post(command)
                            }
                            transaction.addTransactionCommittedListener(executor) {
                                runCatching { onCommitted(receiptAt.get()) }
                                    .onFailure { Log.w("FluviOrbFirstHandoff", "hide commit observation failed", it) }
                            }
                        }.onFailure { Log.w("FluviOrbFirstHandoff", "hide commit listener registration failed", it) }
                    }
                    transaction.apply()
                    applyReturnedAtUptimeMs = SystemClock.uptimeMillis()
                } finally {
                    runCatching { transaction.close() }
                }
                true
            }.getOrDefault(false)
            firstPublishedLease = null
            firstPublishedToken = null
            layer = null
            layerLease = null
            placement.invalidate()
            retirement?.let { record ->
                record.barrier.mainHideCompleted()
                notifyRetirement(record, "main-hide-attempt-finished")
                // This post is strictly after the Main hide attempt. The
                // Worker handler orders the last clear after accepted steady
                // publication without making Main wait for either operation.
                worker.enqueueFinalClear(record.lease, record.id, child)
            }
            lease?.let {
                runCatching {
                    onLayerHideSubmitted(KeyguardOrbLayerHideSubmission(
                        it, submittedAtUptimeMs, transactionApplied, applyReturnedAtUptimeMs,
                    ))
                }.onFailure { error -> Log.w("FluviOrbFirstHandoff", "hide submission observation failed", error) }
            }
        }

        private fun notifyRetirement(record: KeyguardOrbRetiringLayer, event: String, at: Long = SystemClock.uptimeMillis(),
                                     slot: Long? = null, use: Long? = null) {
            if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook) {
                runCatching { recoveryHook.onRetirementEvent(record.lease, record.childIdentity, event, at) }
            }
            record.observer?.let { observer ->
                runCatching { observer(KeyguardOrbRetirementEvent(record.lease, record.childIdentity, record.reason,
                    event, at, slot, use)) }
            }
        }

        private fun onRetiredUseEvent(lease: KeyguardOrbBufferLease, id: Long, stage: String,
                                      slot: Long?, use: Long?, at: Long) {
            val record = retiringLayers[lease to id] ?: return
            notifyRetirement(record, stage, at, slot, use)
        }

        private fun onFinalClearFinished(lease: KeyguardOrbBufferLease, id: Long, applied: Boolean, at: Long) {
            val record = retiringLayers[lease to id] ?: return
            record.barrier.finalClearCompleted(applied)
            notifyRetirement(record, if (applied) "final-clear-applied" else "final-clear-failed", at)
            tryUnlink(record)
        }

        private fun onFinalClearCommitted(lease: KeyguardOrbBufferLease, id: Long, at: Long) {
            val record = retiringLayers[lease to id] ?: return
            record.barrier.commitObserved()
            notifyRetirement(record, "final-clear-committed", at)
            tryUnlink(record)
        }

        private fun onLeaseDrained(lease: KeyguardOrbBufferLease, id: Long) {
            mainHandler.post {
                val record = retiringLayers[lease to id] ?: return@post
                record.barrier.leaseDrained()
                notifyRetirement(record, "actual-lease-drained")
                tryUnlink(record)
                if (record.child == null) retiringLayers.remove(record.lease to record.id)
            }
        }

        private fun tryUnlink(record: KeyguardOrbRetiringLayer) {
            if (retiringLayers[record.lease to record.id] !== record || !record.barrier.shouldUnlink()) return
            val child = record.child ?: return
            if (layer === child) return // never unlink the current child
            val result = runCatching {
                val transaction = SurfaceControl.Transaction()
                try { transaction.reparent(child, null).apply() }
                finally { runCatching { transaction.close() } }
            }
            record.barrier.unlinkAttempted(result.isSuccess)
            if (result.isSuccess) {
                // Keep only the immutable token/observer until real drain;
                // late use callbacks must not dereference a released child.
                record.child = null
                notifyRetirement(record, "child-unlinked")
                runCatching { child.release() }
                if (record.barrier.isDrained()) retiringLayers.remove(record.lease to record.id)
            } else {
                notifyRetirement(record, "child-unlink-failed")
                Log.w("FluviOrbRetirement", "exact child unlink failed", result.exceptionOrNull())
            }
        }

        private fun onFrameReady(frame: ReadyFrame) {
            val postedAt = SystemClock.uptimeMillis()
            mainHandler.post publish@{
                if (!disposed && attachment == null && desired?.lease == frame.lease) {
                    // This completion has allocated the actual fixed pool,
                    // configured its slot-local shader and rendered a real
                    // buffer. It is deliberately reported before its render
                    // result is drained: detached output has no legal
                    // publication target, and retaining READY_FOR_MAIN would
                    // strand one of the fixed pool's three handoff slots.
                    // The renderer, HardwareBuffer allocation and slot-local
                    // shader stay retained; only this unauthorised use is
                    // returned fence-safely to FREE.
                    onDetachedBackendPrepared(frame.lease, android.os.SystemClock.uptimeMillis())
                    worker.dropReady(frame)
                    return@publish
                }
                val enteredAt = SystemClock.uptimeMillis()
                if (firstPublicationHook === NoopKeyguardOrbFirstPublicationTestHook) {
                    publishReady(frame, postedAt, enteredAt)
                } else {
                    runCatching {
                        firstPublicationHook.dispatchReady(frame.producerFrame) { publishReady(frame, postedAt, enteredAt) }
                    }.onFailure { error ->
                        // A test dispatcher can throw after it has delivered
                        // the runnable. It cannot decide buffer ownership.
                        Log.w("FluviOrbFirstHandoff", "ready test dispatcher failed", error)
                    }
                }
            }
        }

        private fun publishReady(frame: ReadyFrame, postedAt: Long, enteredAt: Long) {
            val active = attachment
            val child = layer
            if (disposed || active == null || child == null ||
                layerLease != frame.lease || desired?.lease != frame.lease ||
                active.attachment != frame.lease.attachment || !active.root.isAttachedToWindow
            ) {
                worker.dropReady(frame)
                return
            }
            val token = KeyguardOrbFirstPublicationToken(frame.lease, frame.slotId, frame.useGeneration, child)
            val childIdentity = System.identityHashCode(child)
            val slotId = frame.slotId
            val useGeneration = frame.useGeneration
            val receiptAt = AtomicLong(0L)
            var transaction: SurfaceControl.Transaction? = null
            var applyStarted = false
            var applyEnd = 0L
            var applyBegin = 0L
            try {
                transaction = SurfaceControl.Transaction()
                firstPublicationHook.beforeApply(token)
                val lease = frame.lease
                val release = Consumer<SyncFence> { fence -> worker.release(lease, slotId, useGeneration, fence, childIdentity) }
                val executor = Executor { command ->
                    receiptAt.compareAndSet(0L, SystemClock.uptimeMillis())
                    mainHandler.post(command)
                }
                transaction.setBuffer(child, frame.buffer, frame.fence, release)
                    .setVisibility(child, true)
                    .addTransactionCommittedListener(executor) {
                        val received = receiptAt.get()
                        val mainAt = SystemClock.uptimeMillis()
                        runCatching { onFirstCommitReceived(token, received, mainAt) }
                            .onFailure { Log.w("FluviOrbFirstHandoff", "first commit observation failed", it) }
                        val deliver = {
                            if (ownsFirstPublication(token)) {
                                runCatching { onFirstCommitted(token) }
                                    .onFailure { Log.w("FluviOrbFirstHandoff", "first commit delivery failed", it) }
                            }
                        }
                        runCatching { firstPublicationHook.dispatchCommit(token, received, deliver) }
                            .onFailure { Log.w("FluviOrbFirstHandoff", "first commit test hook failed", it) }
                    }
                applyBegin = SystemClock.uptimeMillis()
                applyStarted = true
                transaction.apply()
                applyEnd = SystemClock.uptimeMillis()
            } catch (error: Throwable) {
                if (!applyStarted) {
                    worker.dropReady(frame)
                } else {
                    // A throwing apply does not prove that ownership remained
                    // local. Keep the exact use until a real receipt/fence.
                    worker.markFirstPublished(frame, childIdentity, "first/apply-unknown")
                }
                failures += 1
                onFailure(frame.lease, error)
                return
            } finally {
                runCatching { transaction?.close() }
            }
            // Main orders this acknowledgement before a following hide can
            // queue retirement. A fast real release is replayed by Worker.
            firstPublishedLease = frame.lease
            firstPublishedToken = token
            framesPublished += 1
            worker.markFirstPublished(frame, childIdentity)
            val times = KeyguardOrbFirstPublicationTimes(frame.readyAtUptimeMs, postedAt, enteredAt, applyBegin, applyEnd)
            runCatching { onFirstPublished(token, times) }
                .onFailure { Log.w("FluviOrbFirstHandoff", "first output observer failed after transfer", it) }
            if (publicationObserver !== NoopKeyguardOrbBufferPublicationObserver) {
                runCatching { publicationObserver.onSubmitted(frame.producerFrame) }
                    .onFailure { Log.w("FluviOrbFirstHandoff", "submission observer failed after transfer", it) }
            }
            runCatching { firstPublicationHook.afterSubmitted(token) }
                .onFailure { Log.w("FluviOrbFirstHandoff", "first test observer failed after transfer", it) }
        }

        private fun onWorkerFailure(lease: KeyguardOrbBufferLease, error: Throwable) {
            mainHandler.post {
                if (!disposed && desired?.lease == lease) {
                    failures += 1
                    onFailure(lease, error)
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private class Worker(
        private val onFrameReady: (ReadyFrame) -> Unit,
        private val onFailure: (KeyguardOrbBufferLease, Throwable) -> Unit,
        private val onLeaseDrained: (KeyguardOrbBufferLease, Long) -> Unit,
        private val onFinalClearFinished: (KeyguardOrbBufferLease, Long, Boolean, Long) -> Unit,
        private val onFinalClearCommitted: (KeyguardOrbBufferLease, Long, Long) -> Unit,
        private val onRetiredUseEvent: (KeyguardOrbBufferLease, Long, String, Long?, Long?, Long) -> Unit,
        private val mainHandler: Handler,
        private val onPressure: (KeyguardOrbPressureTicket) -> Unit,
        private val onCapacityRestored: (KeyguardOrbPressureTicket, Long) -> Unit,
        private val barrier: KeyguardOrbRenderBarrier,
        private val frameObserver: KeyguardOrbBufferFrameObserver,
        private val publicationObserver: KeyguardOrbBufferPublicationObserver,
        private val materialTimeSource: KeyguardOrbMaterialTimeSource,
        private val timingOwner: () -> Any?,
        private val steadyPublicationBarrier: KeyguardOrbSteadyPublicationBarrier,
        private val ownershipObserver: KeyguardOrbOwnershipObserver,
        private val recoveryHook: KeyguardOrbRecoveryTestHook,
        private val rendererId: Long,
    ) : Choreographer.FrameCallback {
        /**
         * `READY_FOR_MAIN` is deliberately distinct from compositor ownership.
         * The renderer thread has completed the buffer, but the posted Main
         * publication has not yet either submitted it to SurfaceControl or
         * rejected it.  Retirement must retain that slot until the Main
         * hand-off resolves; otherwise a late release/drop callback can target
         * a dead worker and close a buffer the compositor still references.
         */
        private enum class SlotState {
            FREE,
            RENDERING,
            WAIT_RENDER_FENCE,
            READY_FOR_MAIN,
            PUBLISHED,
            WAIT_RELEASE_FENCE,
        }
        private data class Slot(
            val id: Long,
            val buffer: HardwareBuffer,
            val renderer: HardwareBufferRenderer,
            var node: RenderNode,
            /**
             * A RuntimeShader is mutable.  A HardwareBufferRenderer callback
             * only means its RenderNode was submitted; its fence still owns
             * GPU work. Therefore shaders and paints belong to one physical
             * buffer slot and are not reconfigured until that slot has
             * returned to FREE after its release fence.
             */
            var shader: KeyguardHeaderShader? = null,
            var shaderProgramKey: String? = null,
            var previousShader: KeyguardHeaderShader? = null,
            var previousShaderProgramKey: String? = null,
            val currentPaint: Paint = Paint(Paint.ANTI_ALIAS_FLAG),
            val previousPaint: Paint = Paint(Paint.ANTI_ALIAS_FLAG),
            var state: SlotState = SlotState.FREE,
            /** Retirement revokes a lease; it is not an ownership state. */
            var retired: Boolean = false,
            var useGeneration: Long = 0L,
            var lease: KeyguardOrbBufferLease? = null,
            // Passive evidence, reset only when a FREE slot begins a new use.
            var childIdentity: Int? = null,
            var publicationPath: String? = null,
            var callbackReceived: Boolean = false,
            var fencePending: Boolean = false,
            var earlyReceiptRetained: Boolean = false,
        )

        private data class PublicationTarget(
            val lease: KeyguardOrbBufferLease,
            val child: SurfaceControl,
            @Volatile var active: Boolean = true,
        )

        private val thread = HandlerThread("fluvi-keyguard-orb-render").apply { start() }
        private val handler = Handler(thread.looper)
        /** The renderer-control handler must remain able to retire/reconfigure
         * while a release fence is outstanding. At most three fence records
         * exist because the pool is globally fixed at three slots. */
        private val fenceThread = HandlerThread("fluvi-keyguard-orb-fence").apply { start() }
        private val fenceHandler = Handler(fenceThread.looper)
        private val executor = Executor { command -> handler.post(command) }
        private var choreographer: Choreographer? = null
        private var callbackPosted = false
        private var desired: KeyguardOrbBufferRenderSpec? = null
        private var attachedLease: KeyguardOrbBufferLease? = null
        /**
         * Main installs an immutable grant before posting worker bookkeeping.
         * A retirement captures/revokes only the grant it observed; a queued
         * A-retirement must never clear a subsequently installed B grant.
         */
        private val publicationTarget = KeyguardOrbPublicationGrantStore<PublicationTarget>()
        private var firstLeaseSubmitted: KeyguardOrbBufferLease? = null
        private var firstLeaseAwaitingMain: KeyguardOrbBufferLease? = null
        private val retiringLeases = mutableSetOf<KeyguardOrbBufferLease>()
        private val retiringLeaseIds = mutableMapOf<KeyguardOrbBufferLease, MutableSet<Long>>()
        private val earlyReleaseReceipts = KeyguardOrbEarlyReleaseReceiptStore<SyncFence>()
        private var slots: MutableList<Slot> = mutableListOf()
        private var nextSlotId = 0L
        private var running = false
        private var disposed = false
        private val pressurePolicy = KeyguardOrbPressurePolicy()
        private var lastPressureFrameNanos = Long.MIN_VALUE
        private var offeredPressure: KeyguardOrbPressureTicket? = null
        private var restoringPressure: KeyguardOrbPressureTicket? = null
        @Volatile private var produced = 0
        @Volatile private var published = 0
        @Volatile private var dropped = 0
        @Volatile private var failures = 0
        @Volatile private var snapshotInFlight = 0
        @Volatile private var snapshotReady = 0
        @Volatile private var snapshotCompositorOwned = 0
        @Volatile private var snapshotRunning = false
        @Volatile private var snapshotDesiredAttachment = -1L
        @Volatile private var snapshotDesiredGeneration = -1L
        @Volatile private var snapshotAttachedAttachment = -1L
        @Volatile private var snapshotAttachedGeneration = -1L
        @Volatile private var completionGapMaxMs = 0L
        @Volatile private var snapshotAt = 0L
        @Volatile private var snapshotSequence = 0L
        /** 0 unknown, 1 no grant, 2 awaiting Main, 3 no free,
         * 4 incompatible size, 5 active work/capacity. */
        @Volatile private var snapshotBlockReason = 0
        @Volatile private var snapshotGrantAttachment = -1L
        @Volatile private var snapshotGrantGeneration = -1L
        @Volatile private var snapshotGrantIdentity = 0
        @Volatile private var snapshotGrantActive = false
        @Volatile private var snapshotLastCompletionAt = 0L
        private var currentBlockReason = 0
        private var previousCompletionAtUptimeMs = 0L
        private var firstWorkAttachment = -1L
        private var firstWorkGeneration = -1L
        private var firstWorkRequestedAt = 0L
        private var firstWorkStartedAt = 0L
        private var firstWorkResultAt = 0L
        private var firstWorkResultStatus = -1
        private var firstWorkOwner: Any? = null
        private var firstFrameAt = 0L
        private var firstFrameSlot = -1L
        private var firstFrameUse = -1L
        private var secondFrameAt = 0L
        private var secondFrameSlot = -1L
        private var secondFrameUse = -1L
        @Volatile private var snapshotFirstWorkAttachment = -1L
        @Volatile private var snapshotFirstWorkGeneration = -1L
        @Volatile private var snapshotFirstWorkRequested = 0L
        @Volatile private var snapshotFirstWorkStarted = 0L
        @Volatile private var snapshotFirstWorkResult = 0L
        @Volatile private var snapshotFirstWorkStatus = -1
        @Volatile private var snapshotFirstWorkOwner: Any? = null
        @Volatile private var snapshotFirstFrameAt = 0L
        @Volatile private var snapshotFirstFrameSlot = -1L
        @Volatile private var snapshotFirstFrameUse = -1L
        @Volatile private var snapshotSecondFrameAt = 0L
        @Volatile private var snapshotSecondFrameSlot = -1L
        @Volatile private var snapshotSecondFrameUse = -1L
        private var starvationStartedAt = 0L
        private var starvationReported = false
        private var logWindowStartedAt = 0L
        private var logRecords = 0
        private var suppressedRecords = 0L

        data class Snapshot(
            val produced: Int,
            val published: Int,
            val dropped: Int,
            val failures: Int,
            val inFlight: Int,
            val ready: Int,
            val compositorOwned: Int,
            val running: Boolean,
            val desiredAttachment: Long,
            val desiredGeneration: Long,
            val attachedAttachment: Long,
            val attachedGeneration: Long,
            val completionGapMaxMs: Long,
            val sampleAt: Long,
            val sampleSequence: Long,
            val blockReason: Int,
            val grantAttachment: Long,
            val grantGeneration: Long,
            val grantIdentity: Int,
            val grantActive: Boolean,
            val lastCompletionAt: Long,
            val firstWork: KeyguardOrbFirstWorkSnapshot? = null,
        )

        init {
            handler.post { choreographer = Choreographer.getInstance() }
        }

        fun post(command: Runnable) { handler.post(command) }

        fun configure(value: KeyguardOrbBufferRenderSpec) {
            handler.post {
                if (disposed) return@post
                if (desired?.lease != value.lease || desired?.scene?.visualKey != value.scene.visualKey) {
                    if (desired?.lease != value.lease) resetStarvation("lease-changed")
                    resetPressure()
                }
                desired = value
                val captureOwner = timingOwner()
                if (value.lease.attachment > 0 && captureOwner != null &&
                    (firstWorkAttachment != value.lease.attachment || firstWorkOwner !== captureOwner)
                ) {
                    firstWorkOwner = captureOwner
                    firstWorkAttachment = value.lease.attachment
                    firstWorkGeneration = value.lease.generation
                    firstWorkRequestedAt = SystemClock.uptimeMillis()
                    firstWorkStartedAt = 0L
                    firstWorkResultAt = 0L
                    firstWorkResultStatus = -1
                    firstFrameAt = 0L
                    firstFrameSlot = -1L
                    firstFrameUse = -1L
                    secondFrameAt = 0L
                    secondFrameSlot = -1L
                    secondFrameUse = -1L
                }
                // Layer setup may synchronously install a grant before this
                // configure command reaches Worker. Reconcile either order.
                val grant = publicationTarget.current()
                if (grant?.active == true && grant.lease == value.lease && value.lease.attachment > 0) {
                    attachedLease = value.lease
                    running = true
                    evaluatePressure(value, false)
                }
                if (!ensureResources(value)) {
                    publishSlotSnapshot()
                    if (running) requestFrame()
                    return@post
                }
                // Detached preparation renders one real frame into a
                // READY_FOR_MAIN
                // slot. It does not start a continuous animation loop.
                requestFrame()
                publishSlotSnapshot()
            }
        }

        fun setAttachment(lease: KeyguardOrbBufferLease, child: SurfaceControl) {
            // Main grants this exact existing child once. Subsequent worker
            // transactions may only replace its buffer; they never change
            // visibility or parenting.
            val current = publicationTarget.current()
            if (current == null || !current.active || current.lease != lease || current.child !== child) {
                publicationTarget.install(PublicationTarget(lease, child))?.active = false
            }
            handler.post {
                if (disposed || desired?.lease != lease) return@post
                if (attachedLease != lease) {
                    previousCompletionAtUptimeMs = 0L
                    completionGapMaxMs = 0L
                }
                attachedLease = lease
                running = true
                desired?.let { evaluatePressure(it, false) }
                requestFrame()
                publishSlotSnapshot()
            }
        }

        fun revokePublicationAuthority(lease: KeyguardOrbBufferLease, child: SurfaceControl) {
            val target = publicationTarget.current()
            if (target?.lease == lease && target.child === child) {
                target.active = false
                publicationTarget.revokeExact(target)
            }
        }

        fun enqueueFinalClear(lease: KeyguardOrbBufferLease, retirementId: Long, child: SurfaceControl) {
            val revokedAtUptimeMs = SystemClock.uptimeMillis()
            val childIdentity = System.identityHashCode(child)
            handler.post {
                if (desired?.lease == lease || offeredPressure?.lease == lease) resetPressure()
                retiringLeases += lease
                retiringLeaseIds.getOrPut(lease) { mutableSetOf() }.add(retirementId)
                if (attachedLease == lease) attachedLease = null
                slots.filter { it.lease == lease && it.state != SlotState.FREE }.forEach { it.retired = true }
                observeOwnership("revocation-processed", lease = lease, childIdentity = childIdentity,
                    detail = "requestedAtUptimeMs=$revokedAtUptimeMs")
                observeOwnership("retirement-clear-started", lease = lease, childIdentity = childIdentity, log = false)
                onRetiredUseEvent(lease, retirementId, "final-clear-started", null, null, SystemClock.uptimeMillis())
                var applied = false
                val result = runCatching {
                    SurfaceControl.Transaction().use { transaction ->
                        transaction.setBuffer(child, null as HardwareBuffer?)
                        // The listener carries only immutable lease/id, never
                        // the child or a buffer. Registration failure cannot
                        // suppress the required final clear.
                        runCatching {
                            val receiptAt = AtomicLong(0L)
                            val executor = Executor { command ->
                                receiptAt.compareAndSet(0L, SystemClock.uptimeMillis())
                                mainHandler.post(command)
                            }
                            transaction.addTransactionCommittedListener(executor) {
                                onFinalClearCommitted(lease, retirementId, receiptAt.get())
                            }
                        }.onFailure {
                            onRetiredUseEvent(lease, retirementId, "final-listener-failed", null, null, SystemClock.uptimeMillis())
                            Log.w("FluviOrbRetirement", "final clear listener registration failed", it)
                        }
                        transaction.apply()
                        applied = true
                    }
                }
                if (applied) {
                    observeOwnership("retirement-clear-applied", lease = lease, childIdentity = childIdentity)
                } else {
                    observeOwnership("retirement-clear-failed", lease = lease, childIdentity = childIdentity,
                        detail = result.exceptionOrNull()?.javaClass?.simpleName ?: "unknown")
                    failures += 1
                    result.exceptionOrNull()?.let { onFailure(lease, it) }
                }
                onFinalClearFinished(lease, retirementId, applied, SystemClock.uptimeMillis())
                // The transaction never makes a slot reusable. Only real
                // receipt/fence completion can trigger this drain path.
                maybeNotifyLeaseDrained(lease, childIdentity)
                publishSlotSnapshot()
            }
        }

        fun retire(retiredLease: KeyguardOrbBufferLease?, reason: String) {
            // Capture/revoke only the Main-owned lease that requested
            // retirement. A replacement attachment installs its publication
            // target synchronously on Main, while this command waits behind a
            // blocked worker render. Revoking "current" here would therefore
            // revoke B while draining A's queued retirement.
            publicationTarget.current()?.takeIf { it.lease == retiredLease }?.let { target ->
                target.active = false
                publicationTarget.revokeExact(target)
            }
            handler.post {
                if (desired?.lease == retiredLease || offeredPressure?.lease == retiredLease) resetPressure()
                if (attachedLease == retiredLease) attachedLease = null
                if (desired?.lease == retiredLease) desired = null
                if (firstLeaseSubmitted == retiredLease) firstLeaseSubmitted = null
                if (firstLeaseAwaitingMain == retiredLease) firstLeaseAwaitingMain = null
                // Stop the render loop only if this retirement actually left
                // no desired work. A queued A-retirement must leave B's
                // configured/attached loop intact.
                if (desired == null) {
                    resetStarvation("retired")
                    running = false
                    if (callbackPosted) choreographer?.removeFrameCallback(this)
                    callbackPosted = false
                }
                // A RenderRequest or the compositor may still own some
                // targets; retain those until their callback/fence returns.
                // Keep already-free targets alive, too: they are the fixed
                // pool's only safe recovery capacity when a new authorized
                // attachment arrives before an old compositor release.  A
                // free HardwareBuffer has no lease-specific contents or
                // ownership and can be rendered only after the new lease has
                // become current.  Closing it here strands the replacement
                // behind a stale release even though the three-slot bound has
                // usable capacity.
                slots.filter {
                    it.lease == retiredLease && it.state != SlotState.FREE
                }.forEach { slot ->
                    slot.retired = true
                }
                retiredLease?.let { lease ->
                    retiringLeases += lease
                    maybeNotifyLeaseDrained(lease)
                }
                publishSlotSnapshot()
            }
        }

        fun dispose() {
            publicationTarget.revokeCurrent()?.active = false
            handler.post {
                resetPressure()
                restoringPressure = null
                disposed = true
                running = false
                resetStarvation("disposed")
                if (callbackPosted) choreographer?.removeFrameCallback(this)
                callbackPosted = false
                slots.filter { it.state == SlotState.FREE }.toList().forEach { slot ->
                    closeSlot(slot)
                    slots.remove(slot)
                }
                slots.filter { it.state != SlotState.FREE }.forEach { slot ->
                    slot.retired = true
                    slot.lease?.let(retiringLeases::add)
                }
                publishSlotSnapshot()
                finishDisposeIfReleased()
            }
        }

        fun markFirstPublished(frame: ReadyFrame, childIdentity: Int, path: String = "first/direct") {
            handler.post {
                val slot = slots.firstOrNull { it.id == frame.slotId }
                if (slot == null || slot.useGeneration != frame.useGeneration ||
                    slot.state != SlotState.READY_FOR_MAIN || slot.lease != frame.lease
                ) return@post
                slot.childIdentity = childIdentity
                slot.publicationPath = path
                slot.state = SlotState.PUBLISHED
                firstLeaseAwaitingMain = null
                firstLeaseSubmitted = frame.lease
                published += 1
                recordCurrentFrame(slot)
                resetPressure()
                observeOwnership("first-submitted", slot = slot, log = false)
                earlyReleaseReceipts.take(frame.slotId to frame.useGeneration)?.let { receipt ->
                    slot.earlyReceiptRetained = false
                    consumeRelease(frame.slotId, frame.useGeneration, receipt.value, replayed = true)
                }
                publishSlotSnapshot()
                if (running) requestFrame()
            }
        }

        fun release(lease: KeyguardOrbBufferLease, slotId: Long, useGeneration: Long,
                    releaseFence: SyncFence?, childIdentity: Int, postAlways: Boolean = true) {
            val receiptAt = SystemClock.uptimeMillis()
            if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook) {
                recoveryHook.dispatchRelease(lease, slotId, useGeneration, releaseFence) {
                    releaseActual(slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
                }
                return
            }
            releaseActual(slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
        }

        private fun releaseActual(slotId: Long, useGeneration: Long, releaseFence: SyncFence?,
                                  childIdentity: Int, postAlways: Boolean, receiptAt: Long) {
            // Preserve the steady path's original direct Worker receipt; a
            // first publication still posts its acknowledgement as before.
            if (!postAlways && Looper.myLooper() == thread.looper) {
                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt)
                return
            }
            handler.post {
                val slot = slots.firstOrNull { it.id == slotId } ?: run {
                    releaseFence?.close()
                    return@post
                }
                // The real receipt may precede Main's acknowledgement, or
                // apply may have thrown after transfer. Preserve the path
                // selected by that acknowledgement rather than inventing a
                // successful direct return in the release callback.
                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt)
            }
        }

        private fun consumeRelease(
            slotId: Long,
            useGeneration: Long,
            releaseFence: SyncFence?,
            childIdentity: Int? = null,
            publicationPath: String? = null,
            replayed: Boolean = false,
            receiptAt: Long? = null,
        ) {
            if (Looper.myLooper() != thread.looper) {
                handler.post {
                    consumeRelease(slotId, useGeneration, releaseFence, childIdentity, publicationPath, replayed, receiptAt)
                }
                return
            }
            val slot = slots.firstOrNull { it.id == slotId }
            if (slot != null && slot.useGeneration == useGeneration &&
                slot.state == SlotState.READY_FOR_MAIN
            ) {
                // SurfaceFlinger may release a transaction before the Main
                // acknowledgement runnable reaches the renderer handler.
                // Retain this exact fence rather than treating READY as FREE.
                val key = slotId to useGeneration
                val recorded = earlyReleaseReceipts.record(key, releaseFence)
                if (recorded) {
                    if (childIdentity != null) slot.childIdentity = childIdentity
                    if (publicationPath != null) slot.publicationPath = publicationPath
                    else if (slot.publicationPath == "first/ready") slot.publicationPath = "first/release-before-ack"
                    slot.callbackReceived = true
                    slot.fencePending = releaseFence?.isValid == true
                    slot.earlyReceiptRetained = true
                    observeOwnership("release-received", slot = slot, log = false)
                    if (slot.retired) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
                    desired?.let { evaluatePressure(it, false) }
                } else {
                    // Duplicate callbacks cannot replace the first exact
                    // receipt or consume a later use generation.
                    releaseFence?.close()
                }
                observeOwnership("early-release-received", slot = slot,
                    detail = if (recorded) "retained" else "duplicate")
                return
            }
            if (slot == null || slot.useGeneration != useGeneration || slot.state != SlotState.PUBLISHED) {
                releaseFence?.close()
                return
            }
            if (childIdentity != null) slot.childIdentity = childIdentity
            if (publicationPath != null) slot.publicationPath = publicationPath
            slot.callbackReceived = true
            slot.fencePending = releaseFence?.isValid == true
            slot.state = SlotState.WAIT_RELEASE_FENCE
            if (!replayed) observeOwnership("release-received", slot = slot, log = slot.retired)
            if (slot.retired && !replayed) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
            desired?.let { evaluatePressure(it, false) }
            awaitFence(slotId, useGeneration, SlotState.WAIT_RELEASE_FENCE, releaseFence)
            publishSlotSnapshot()
        }

        fun dropReady(frame: ReadyFrame) {
            handler.post {
                val slot = slots.firstOrNull { it.id == frame.slotId }
                if (slot != null && slot.useGeneration == frame.useGeneration &&
                    slot.state == SlotState.READY_FOR_MAIN
                ) discardRenderResult(slot, frame.fence)
                else frame.fence?.close()
                if (firstLeaseAwaitingMain == frame.lease) firstLeaseAwaitingMain = null
                dropped += 1
                publishSlotSnapshot()
            }
        }

        fun snapshot(): Snapshot {
            // Bounded seqlock read, never a Main/Worker join. A contended
            // sample is explicitly unavailable, never guessed from a mix.
            repeat(3) {
                val before = snapshotSequence
                if (before % 2L == 0L) {
                    val value = Snapshot(produced, published, dropped, failures,
                        snapshotInFlight, snapshotReady, snapshotCompositorOwned,
                        snapshotRunning, snapshotDesiredAttachment, snapshotDesiredGeneration,
                        snapshotAttachedAttachment, snapshotAttachedGeneration,
                        completionGapMaxMs, snapshotAt, before, snapshotBlockReason,
                        snapshotGrantAttachment, snapshotGrantGeneration, snapshotGrantIdentity,
                        snapshotGrantActive, snapshotLastCompletionAt,
                        snapshotFirstWorkOwner?.takeIf { snapshotFirstWorkRequested > 0L }?.let { owner ->
                            KeyguardOrbFirstWorkSnapshot(snapshotFirstWorkAttachment, snapshotFirstWorkGeneration,
                                snapshotFirstWorkRequested, snapshotFirstWorkStarted.takeIf { it > 0L },
                                snapshotFirstWorkResult.takeIf { it > 0L }, snapshotFirstWorkStatus.takeIf { it >= 0 }, owner,
                                snapshotFirstFrameAt.takeIf { it > 0L }, snapshotFirstFrameSlot.takeIf { it >= 0L },
                                snapshotFirstFrameUse.takeIf { it >= 0L }, snapshotSecondFrameAt.takeIf { it > 0L },
                                snapshotSecondFrameSlot.takeIf { it >= 0L }, snapshotSecondFrameUse.takeIf { it >= 0L })
                        })
                    if (before == snapshotSequence) return value
                }
            }
            return Snapshot(produced, published, dropped, failures, 0, 0, 0, false,
                -1, -1, -1, -1, completionGapMaxMs, 0, 0, 0, -1, -1, 0, false, 0)
        }

        override fun doFrame(frameTimeNanos: Long) {
            callbackPosted = false
            if (disposed) return
            render(frameTimeNanos)
            if (running) requestFrame()
        }

        fun claimPressure(ticket: KeyguardOrbPressureTicket): Boolean {
            val grant = publicationTarget.current()
            return grant === ticket.grant && grant?.active == true &&
                grant.lease == ticket.lease && grant.child === ticket.child && ticket.claim.claim()
        }

        fun acceptPressure(ticket: KeyguardOrbPressureTicket) {
            handler.post {
                if (disposed || !ticket.claim.isClaimed()) return@post
                if (offeredPressure === ticket) offeredPressure = null
                restoringPressure = ticket
                notifyCapacityIfDrained()
            }
        }

        private fun notifyCapacityIfDrained() {
            val ticket = restoringPressure ?: return
            if (slots.any { it.state != SlotState.FREE }) return
            restoringPressure = null
            onCapacityRestored(ticket, SystemClock.uptimeMillis())
        }

        private fun resetPressure() {
            pressurePolicy.reset()
            lastPressureFrameNanos = Long.MIN_VALUE
            val offer = offeredPressure ?: return
            if (offer.claim.cancel() || !offer.claim.isClaimed()) offeredPressure = null
        }

        /** No allocations on ordinary frame opportunities. The snapshot is
         * constructed once, only when a qualifying transition is offered. */
        private fun evaluatePressure(spec: KeyguardOrbBufferRenderSpec, opportunity: Boolean) {
            val grant = publicationTarget.current()
            val eligible = running && !disposed && attachedLease == spec.lease &&
                spec.lease.attachment > 0 && grant?.active == true && grant.lease == spec.lease
            var oldUnreleased = 0
            var oldOwned = 0
            var free = 0
            var currentInFlight = false
            var currentCompatible = false
            var wrongSizeOld = false
            for (slot in slots) {
                if (slot.state == SlotState.FREE) { free++; continue }
                val retiredOld = slot.retired && slot.lease != spec.lease
                if (retiredOld) {
                    if (slot.state == SlotState.PUBLISHED && !slot.callbackReceived) oldUnreleased++
                    if (slot.state == SlotState.PUBLISHED || slot.state == SlotState.WAIT_RELEASE_FENCE) oldOwned++
                    if (slot.buffer.width != spec.lease.width || slot.buffer.height != spec.lease.height) wrongSizeOld = true
                } else if (slot.lease == spec.lease) {
                    if (slot.state == SlotState.RENDERING || slot.state == SlotState.READY_FOR_MAIN) currentInFlight = true
                    if (slot.buffer.width == spec.lease.width && slot.buffer.height == spec.lease.height) currentCompatible = true
                }
            }
            val now = SystemClock.uptimeMillis()
            val blockReason = when {
                !eligible -> 1
                slots.any { it.lease == spec.lease && it.state == SlotState.READY_FOR_MAIN } -> 2
                wrongSizeOld && free + (3 - slots.size).coerceAtLeast(0) == 0 && !currentInFlight -> 4
                free + (3 - slots.size).coerceAtLeast(0) == 0 -> 3
                else -> 5
            }
            if (currentBlockReason != blockReason) {
                currentBlockReason = blockReason
                publishSlotSnapshot()
            }
            val reason = pressurePolicy.observe(grant, eligible, slots.size, oldUnreleased, oldOwned, free,
                currentInFlight, wrongSizeOld, currentCompatible, published, now, opportunity)
            if (reason == null) {
                val offer = offeredPressure
                if (offer != null && (offer.claim.cancel() || !offer.claim.isClaimed())) offeredPressure = null
                return
            }
            if (offeredPressure?.claim?.isPending() == false && offeredPressure?.claim?.isClaimed() == false) {
                offeredPressure = null
            }
            if (offeredPressure != null || grant == null) return
            val ticket = KeyguardOrbPressureTicket(rendererId, spec.lease, spec.scene.visualKey,
                spec.scene.full, spec.scene.profile.effectId, spec.scene.profile.usesPortal,
                grant.child, grant, reason,
                pressurePolicy.startedAt, now, pressurePolicy.opportunities, slots.map { slot ->
                    KeyguardOrbOwnershipSlotSnapshot(slot.id, slot.useGeneration, slot.lease,
                        slot.state.name, slot.retired, slot.childIdentity, slot.publicationPath,
                        slot.callbackReceived, slot.fencePending, slot.earlyReceiptRetained)
                })
            offeredPressure = ticket
            observeOwnership("pressure-offered", lease = spec.lease, target = grant,
                detail = "reason=$reason start=${pressurePolicy.startedAt} opportunities=${pressurePolicy.opportunities}")
            onPressure(ticket)
        }

        private fun requestFrame() {
            if (callbackPosted || disposed) return
            val c = choreographer
            if (c == null) {
                handler.post { requestFrame() }
                return
            }
            callbackPosted = true
            c.postFrameCallback(this)
        }

        private fun ensureResources(spec: KeyguardOrbBufferRenderSpec): Boolean {
            return try {
                // Never touch an outstanding old-size use. FREE storage is
                // independently replaceable within the existing global cap.
                var index = slots.lastIndex
                while (index >= 0) {
                    val slot = slots[index]
                    if (slot.state == SlotState.FREE &&
                        (slot.buffer.width != spec.lease.width || slot.buffer.height != spec.lease.height)
                    ) {
                        closeSlot(slot)
                        slots.removeAt(index)
                    }
                    index--
                }
                val usage = HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or
                    HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or HardwareBuffer.USAGE_COMPOSER_OVERLAY
                check(HardwareBuffer.isSupported(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)) {
                    "hardware-buffer-unsupported"
                }
                while (slots.size < 3) {
                    val buffer = HardwareBuffer.create(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)
                    var renderer: HardwareBufferRenderer? = null
                    try {
                        renderer = HardwareBufferRenderer(buffer)
                        val node = RenderNode("fluvi-keyguard-orb-buffer-${slots.size}").apply {
                            setPosition(0, 0, spec.lease.width, spec.lease.height)
                        }
                        slots += Slot(++nextSlotId, buffer, renderer, node)
                    } catch (error: Throwable) {
                        runCatching { renderer?.close() }
                        runCatching { buffer.close() }
                        throw error
                    }
                }
                true
            } catch (error: Throwable) {
                failures += 1
                onFailure(spec.lease, error)
                false
            }
        }

        private fun render(frameTimeNanos: Long) {
            val spec = desired ?: return
            observeStarvation()
            val distinctOpportunity = frameTimeNanos > lastPressureFrameNanos
            if (distinctOpportunity) lastPressureFrameNanos = frameTimeNanos
            evaluatePressure(spec, distinctOpportunity)
            if (!ensureResources(spec)) return
            // A stale RenderRequest owns only its own slot while its render
            // fence drains. Do not make an otherwise FREE slot unavailable
            // during lease revocation/re-attachment; READY and RENDERING still
            // cap the active hand-off to one current frame.
            if (slots.any {
                    it.state == SlotState.READY_FOR_MAIN ||
                        it.state == SlotState.RENDERING
                }) return
            val index = slots.indexOfFirst { it.state == SlotState.FREE &&
                it.buffer.width == spec.lease.width && it.buffer.height == spec.lease.height }
            if (index < 0) {
                dropped += 1
                return
            }
            val target = publicationTarget.current()
            if (recoveryHook !== NoopKeyguardOrbRecoveryTestHook && spec.lease.attachment > 0L) {
                // A configured positive lease may render before Main installs
                // its grant. The test's one-use setup must not let that
                // pre-grant render bypass its first-use counter. The gate is
                // inactive in the production no-hook path.
                if (target?.active != true || target.lease != spec.lease) return
                if (!recoveryHook.allowRender(spec.lease)) return
            }
            val slot = slots[index]
            prepareSlotShaders(slot, spec)
            val currentShader = slot.shader ?: return
            slot.state = SlotState.RENDERING
            if (firstWorkAttachment == spec.lease.attachment && firstWorkGeneration == spec.lease.generation &&
                firstWorkStartedAt == 0L && firstWorkRequestedAt > 0L) {
                firstWorkStartedAt = SystemClock.uptimeMillis()
            }
            slot.retired = false
            slot.lease = spec.lease
            slot.useGeneration += 1L
            slot.childIdentity = null
            slot.publicationPath = null
            slot.callbackReceived = false
            slot.fencePending = false
            slot.earlyReceiptRetained = false
            val useGeneration = slot.useGeneration
            publishSlotSnapshot()
            try {
                val old = spec.previousScene
                val progress = if (old == null || spec.transitionStartedNanos <= 0L) 1f else {
                    ((frameTimeNanos - spec.transitionStartedNanos) / 180_000_000f).coerceIn(0f, 1f)
                }
                // HardwareBufferRenderer records uniform state at the start
                // of its RenderNode display list on API 35. Bind the phase
                // before beginRecording(), rather than during Canvas draws,
                // so each fresh root receives this frame's material state.
                val materialTime = materialTimeSource.timeAt(spec.scene, frameTimeNanos)
                // Read this immediately from the same immutable time sample;
                // a later renderer completion must never guess the newest
                // instrumentation request id.
                val testRequestId = materialTimeSource.testRequestIdFor(materialTime)
                currentShader.configure(
                    spec.scene.profile,
                    spec.lease.width,
                    spec.lease.height,
                    materialTime,
                )
                val previousShader = slot.previousShader ?: currentShader
                if (old != null && progress < 1f) {
                    previousShader.configure(
                        old.profile,
                        spec.lease.width,
                        spec.lease.height,
                        materialTimeSource.timeAt(old, frameTimeNanos),
                    )
                }
                barrier.beforeRender(spec.lease)
                // HardwareBufferRenderer retains its content root. On API 35,
                // re-recording the same root can retain the first
                // RuntimeShader uniform snapshot even though its display list
                // has been ended again. A slot is FREE only after its prior
                // release fence, so replacing its root here is safe and makes
                // the current RuntimeShader state part of this render request.
                slot.node = RenderNode("fluvi-keyguard-orb-buffer-${slot.id}-$useGeneration").apply {
                    setPosition(0, 0, spec.lease.width, spec.lease.height)
                }
                val canvas = slot.node.beginRecording(spec.lease.width, spec.lease.height)
                try {
                    // HardwareBufferRenderer keeps prior contents. A clear is
                    // required for transparent antialiased circle edges.
                    canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
                    if (old != null && progress < 1f) {
                        drawScene(canvas, previousShader, slot.previousPaint, 1f, spec.lease)
                    }
                    drawScene(canvas, currentShader, slot.currentPaint, progress, spec.lease)
                } finally {
                    slot.node.endRecording()
                }
                slot.renderer.setContentRoot(slot.node)
                // HardwareBufferRenderer's request owns the output colour
                // space independently of the Window/View renderer.  Bind the
                // same sRGB target used by Android's HardwareBufferRenderer
                // CTS coverage before each synchronized RenderNode draw so
                // rendering and HardwareBuffer readback use one target.
                slot.renderer.obtainRenderRequest()
                    .setColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
                    .draw(executor, Consumer { result ->
                    if (firstWorkAttachment == spec.lease.attachment && firstWorkGeneration == spec.lease.generation &&
                        firstWorkResultAt == 0L && firstWorkStartedAt > 0L) {
                        firstWorkResultAt = SystemClock.uptimeMillis()
                        firstWorkResultStatus = result.status
                    }
                    if (disposed || desired?.lease != spec.lease || slot.useGeneration != useGeneration ||
                        result.status != HardwareBufferRenderer.RenderResult.SUCCESS || slot.retired
                    ) {
                        discardRenderResult(slot, result.fence)
                        dropped += 1
                        publishSlotSnapshot()
                        if (running) requestFrame()
                        return@Consumer
                    }
                    // The first buffer has one Main-owned binding so that the
                    // layer can become visible and the View bootstrap can be
                    // retired. Every later current buffer is published by the
                    // renderer as a buffer-only transaction.
                    slot.state = SlotState.READY_FOR_MAIN
                    produced += 1
                    val completedAt = android.os.SystemClock.uptimeMillis()
                    if (previousCompletionAtUptimeMs > 0L) {
                        completionGapMaxMs = maxOf(
                            completionGapMaxMs,
                            completedAt - previousCompletionAtUptimeMs,
                        )
                    }
                    previousCompletionAtUptimeMs = completedAt
                    publishSlotSnapshot()
                    // This hook is intentionally test-only and executes on
                    // the renderer handler after a SUCCESS result. It lets
                    // instrumentation read the producer buffer after the
                    // completion fence without putting readback or waits on
                    // the production/Main frame path.
                    val producerFrame = KeyguardOrbBufferProducerFrame(
                        lease = spec.lease,
                        slotId = slot.id,
                        useGeneration = useGeneration,
                        frameTimeNanos = frameTimeNanos,
                        materialTime = materialTime,
                        testRequestId = testRequestId,
                    )
                    if (frameObserver !== NoopKeyguardOrbBufferFrameObserver) {
                        runCatching {
                            frameObserver.onProduced(producerFrame, slot.buffer, result.fence)
                        }
                    }
                    val ready = ReadyFrame(
                        producerFrame = producerFrame,
                        buffer = slot.buffer,
                        fence = result.fence,
                        readyAtUptimeMs = completedAt,
                    )
                    if (firstLeaseSubmitted == spec.lease) {
                        publishSteady(slot, ready)
                    } else if (firstLeaseAwaitingMain != spec.lease) {
                        slot.publicationPath = "first/ready"
                        firstLeaseAwaitingMain = spec.lease
                        onFrameReady(ready)
                    } else {
                        discardRenderResult(slot, result.fence)
                        dropped += 1
                    }
                    })
            } catch (error: Throwable) {
                discardRenderResult(slot, null)
                failures += 1
                publishSlotSnapshot()
                onFailure(spec.lease, error)
            }
        }

        private fun closeSlot(slot: Slot) {
            runCatching { slot.renderer.close() }
            runCatching { slot.buffer.close() }
            slot.shader = null
            slot.shaderProgramKey = null
            slot.previousShader = null
            slot.previousShaderProgramKey = null
            slot.currentPaint.shader = null
            slot.currentPaint.alpha = 255
            slot.previousPaint.shader = null
            slot.previousPaint.alpha = 255
            slot.state = SlotState.FREE
            slot.lease = null
        }

        /**
         * Configure the RuntimeShader ownership for a FREE slot.  Renderer
         * submission is asynchronous, so sharing a mutable RuntimeShader
         * between triple-buffer slots lets a later uniform update race a
         * previous slot's in-flight RenderNode.  Keeping the artifact shared
         * but the shader instance slot-local preserves compilation input and
         * makes every submitted display list immutable until its fence ends.
         */
        private fun prepareSlotShaders(slot: Slot, spec: KeyguardOrbBufferRenderSpec) {
            if (slot.shaderProgramKey != spec.artifact.programKey) {
                slot.shader = KeyguardHeaderShader(spec.artifact)
                slot.shaderProgramKey = spec.artifact.programKey
            }
            val oldArtifact = spec.previousArtifact ?: spec.artifact
            if (spec.previousScene == null) {
                slot.previousShader = null
                slot.previousShaderProgramKey = null
            } else if (slot.previousShaderProgramKey != oldArtifact.programKey) {
                slot.previousShader = KeyguardHeaderShader(oldArtifact)
                slot.previousShaderProgramKey = oldArtifact.programKey
            }
        }

        /** Steady state has no Main callback. This operation has no authority
         * to show, hide or reparent: it updates only a still-authorized child
         * that Main made visible during first publication. */
        private fun publishSteady(slot: Slot, frame: ReadyFrame) {
            val target = publicationTarget.current()
            if (target == null || !target.active || target.lease != frame.lease ||
                slot.useGeneration != frame.useGeneration || slot.retired
            ) {
                discardRenderResult(slot, frame.fence)
                dropped += 1
                return
            }
            slot.childIdentity = System.identityHashCode(target.child)
            slot.publicationPath = "steady"
            observeOwnership("steady-accepted", slot = slot, target = target, log = false)
            val submittedLease = frame.lease
            val submittedSlot = frame.slotId
            val submittedUse = frame.useGeneration
            val childIdentity = System.identityHashCode(target.child)
            runCatching {
                steadyPublicationBarrier.afterGrantValidated(frame.producerFrame)
                SurfaceControl.Transaction()
                    .setBuffer(
                        target.child,
                        frame.buffer,
                        frame.fence,
                        Consumer { releaseFence -> release(submittedLease, submittedSlot, submittedUse,
                            releaseFence, childIdentity, postAlways = false) },
                    )
                    .apply()
                if (publicationObserver !== NoopKeyguardOrbBufferPublicationObserver) {
                    runCatching { publicationObserver.onSubmitted(frame.producerFrame) }
                }
                // SurfaceControl owns the submitted acquire fence. Slot
                // reuse still waits for its later release callback/fence,
                // never for transaction commitment.
                slot.state = SlotState.PUBLISHED
                published += 1
                recordCurrentFrame(slot)
                resetPressure()
                observeOwnership("steady-submitted", slot = slot, target = target, log = false)
            }.onFailure { error ->
                discardRenderResult(slot, frame.fence)
                failures += 1
                onFailure(frame.lease, error)
            }
            publishSlotSnapshot()
        }

        /** Capture only the first two acknowledged app submissions for the original
         * attachment/generation; these are not physical presentation times. */
        private fun recordCurrentFrame(slot: Slot) {
            val lease = slot.lease ?: return
            if (firstWorkOwner == null || lease.attachment != firstWorkAttachment ||
                lease.generation != firstWorkGeneration || secondFrameAt != 0L) return
            if (firstFrameAt == 0L) {
                firstFrameAt = SystemClock.uptimeMillis()
                firstFrameSlot = slot.id
                firstFrameUse = slot.useGeneration
            } else {
                secondFrameAt = SystemClock.uptimeMillis()
                secondFrameSlot = slot.id
                secondFrameUse = slot.useGeneration
            }
        }

        /** A stale/failed producer completion still owns its render fence.
         * It cannot become FREE simply because its visual lease was revoked. */
        private fun discardRenderResult(slot: Slot, fence: SyncFence?) {
            // A READY frame can be revoked before Main acknowledges it. Its
            // receipt is no longer eligible for a future use of this slot.
            earlyReleaseReceipts.discard(slot.id to slot.useGeneration)?.value?.close()
            slot.earlyReceiptRetained = false
            slot.state = SlotState.WAIT_RENDER_FENCE
            awaitFence(slot.id, slot.useGeneration, SlotState.WAIT_RENDER_FENCE, fence)
        }

        private fun awaitFence(
            slotId: Long,
            useGeneration: Long,
            expected: SlotState,
            fence: SyncFence?,
        ) {
            slots.firstOrNull { it.id == slotId && it.useGeneration == useGeneration }
                ?.fencePending = fence?.isValid == true
            if (fence?.isValid != true) {
                fence?.close()
                finishFence(slotId, useGeneration, expected)
                return
            }
            val poll = object : Runnable {
                override fun run() {
                    val signaled = runCatching { fence.await(Duration.ofMillis(16)) }.getOrDefault(false)
                    if (signaled) {
                        fence.close()
                        handler.post { finishFence(slotId, useGeneration, expected) }
                    } else {
                        // A timeout is a diagnostic/failure observation, never
                        // permission to reuse or close the buffer. The only
                        // repeating work is this fixed bounded fence record.
                        fenceHandler.postDelayed(this, 16L)
                    }
                }
            }
            fenceHandler.post(poll)
        }

        private fun notifyRetiredUse(slot: Slot, stage: String, at: Long = SystemClock.uptimeMillis()) {
            val lease = slot.lease ?: return
            retiringLeaseIds[lease]?.forEach { id -> onRetiredUseEvent(lease, id, stage, slot.id, slot.useGeneration, at) }
        }

        private fun finishFence(slotId: Long, useGeneration: Long, expected: SlotState) {
            val slot = slots.firstOrNull { it.id == slotId } ?: return
            if (slot.useGeneration != useGeneration || slot.state != expected) return
            val completedLease = slot.lease
            val completedChildIdentity = slot.childIdentity
            slot.fencePending = false
            if (expected == SlotState.WAIT_RELEASE_FENCE) {
                observeOwnership("release-fence-complete", slot = slot, log = slot.retired)
                if (slot.retired) notifyRetiredUse(slot, "release-fence-complete")
            }
            if (disposed) {
                closeSlot(slot)
                slots.remove(slot)
            } else {
                slot.state = SlotState.FREE
                slot.retired = false
                slot.lease = null
            }
            completedLease?.let { maybeNotifyLeaseDrained(it, completedChildIdentity) }
            retiringLeases.toList().forEach { maybeNotifyLeaseDrained(it) }
            if (slots.any { it.state == SlotState.FREE }) resetStarvation("capacity-released")
            desired?.let { evaluatePressure(it, false) }
            notifyCapacityIfDrained()
            publishSlotSnapshot()
            finishDisposeIfReleased()
            if (running && !disposed) requestFrame()
        }

        private fun maybeNotifyLeaseDrained(lease: KeyguardOrbBufferLease, childIdentity: Int? = null) {
            if (!retiringLeases.contains(lease)) return
            if (slots.none { it.lease == lease && it.state != SlotState.FREE }) {
                retiringLeases.remove(lease)
                observeOwnership("lease-drained", lease = lease, childIdentity = childIdentity)
                retiringLeaseIds.remove(lease)?.forEach { id -> onLeaseDrained(lease, id) }
            }
        }

        /** Sample only from the existing frame/control callbacks. The 200ms
         * threshold is evidence, never a recovery timer or reuse permission. */
        private fun observeStarvation() {
            if (slots.size < 3 || slots.any { it.state == SlotState.FREE }) {
                resetStarvation("capacity-available")
                return
            }
            val now = SystemClock.uptimeMillis()
            if (starvationStartedAt == 0L) starvationStartedAt = now
            if (!starvationReported && now - starvationStartedAt >= 200L) {
                starvationReported = true
                observeOwnership("starvation-entered", lease = desired?.lease,
                    detail = "durationMs=${now - starvationStartedAt}")
            }
        }

        private fun resetStarvation(reason: String) {
            if (starvationReported) {
                observeOwnership("starvation-ended", lease = desired?.lease,
                    detail = "$reason durationMs=${SystemClock.uptimeMillis() - starvationStartedAt}")
            }
            starvationStartedAt = 0L
            starvationReported = false
        }

        /** Production builds create no per-frame snapshots or collections.
         * Lifecycle/exception records share a Worker-owned 64-record/60s cap.
         * Record 64 announces suppression; the next admitted record reports
         * the exact accumulated count. No watchdog is added just to log it. */
        private fun observeOwnership(
            event: String,
            slot: Slot? = null,
            lease: KeyguardOrbBufferLease? = slot?.lease,
            childIdentity: Int? = slot?.childIdentity,
            target: PublicationTarget? = null,
            detail: String = "",
            log: Boolean = true,
        ) {
            val observing = ownershipObserver !== NoopKeyguardOrbOwnershipObserver
            if (!log && !observing) return
            val now = SystemClock.uptimeMillis()
            var writeLog = false
            var suppressed = 0L
            if (log) {
                if (now - logWindowStartedAt >= 60_000L) {
                    logWindowStartedAt = now
                    logRecords = 0
                }
                if (logRecords < 63) {
                    logRecords += 1
                    writeLog = true
                    suppressed = suppressedRecords
                    suppressedRecords = 0L
                } else {
                    suppressedRecords += 1L
                    if (logRecords == 63) {
                        logRecords += 1
                        Log.i("FluviOrbOwnership", "renderer=$rendererId uptimeMs=$now " +
                            "thread=${Thread.currentThread().name} event=log-cap-reached " +
                            "suppressed=$suppressedRecords furtherRecordsCountedUntilNextWindow=true")
                    }
                }
            }
            if (!writeLog && !observing) return
            val grant = publicationTarget.current()
            val grantActive = grant?.active == true
            val sample = KeyguardOrbOwnershipEvent(
                event = event,
                rendererId = rendererId,
                uptimeMs = now,
                thread = Thread.currentThread().name,
                lease = lease,
                childIdentity = childIdentity,
                grantIdentity = target?.let(System::identityHashCode),
                slotId = slot?.id,
                useGeneration = slot?.useGeneration,
                desiredLease = desired?.lease,
                attachedLease = attachedLease,
                currentGrantLease = grant?.lease,
                currentGrantChildIdentity = grant?.child?.let(System::identityHashCode),
                currentGrantIdentity = grant?.let(System::identityHashCode),
                currentGrantActive = grantActive,
                slots = java.util.Collections.unmodifiableList(slots.map {
                    KeyguardOrbOwnershipSlotSnapshot(
                        slotId = it.id, useGeneration = it.useGeneration, lease = it.lease,
                        state = it.state.name, retired = it.retired, childIdentity = it.childIdentity,
                        publicationPath = it.publicationPath, callbackReceived = it.callbackReceived,
                        fencePending = it.fencePending, earlyReceiptRetained = it.earlyReceiptRetained,
                    )
                }),
                detail = detail,
            )
            if (observing) runCatching { ownershipObserver.onEvent(sample) }
            if (writeLog) {
                Log.i("FluviOrbOwnership", buildString {
                    append("renderer=$rendererId uptimeMs=$now thread=${sample.thread} event=$event")
                    append(" lease=${lease.identity()} child=$childIdentity slot=${slot?.id}/${slot?.useGeneration}")
                    append(" desired=${sample.desiredLease.identity()} attached=${attachedLease.identity()}")
                    append(" grant=${sample.currentGrantIdentity}/${sample.currentGrantLease.identity()}")
                    append(" grantChild=${sample.currentGrantChildIdentity} grantActive=$grantActive")
                    append(" suppressed=$suppressed detail=$detail slots=[")
                    sample.slots.forEachIndexed { index, s ->
                        if (index > 0) append(';')
                        append("${s.slotId}/${s.useGeneration} lease=${s.lease.identity()} child=${s.childIdentity}")
                        append(" state=${s.state} retired=${s.retired} path=${s.publicationPath}")
                        append(" callbackReceived=${s.callbackReceived} fencePending=${s.fencePending}")
                        append(" earlyReceiptRetained=${s.earlyReceiptRetained}")
                    }
                    append(']')
                })
            }
        }

        private fun KeyguardOrbBufferLease?.identity(): String =
            if (this == null) "none" else "$attachment/$generation"

        private fun drawScene(
            canvas: android.graphics.Canvas,
            source: KeyguardHeaderShader,
            targetPaint: Paint,
            alpha: Float,
            lease: KeyguardOrbBufferLease,
        ) {
            targetPaint.shader = source.runtimeShader
            targetPaint.alpha = (alpha * 255f).toInt().coerceIn(0, 255)
            canvas.drawCircle(lease.width / 2f, lease.height / 2f,
                min(lease.width, lease.height) / 2f, targetPaint)
            // RecordingCanvas can retain draw objects until endRecording().
            // This slot remains fenced until its output is released, so do
            // not mutate either the paint or RuntimeShader after this draw.
        }

        /** The service can dispose on Main while a RenderRequest or
         * compositor fence still owns a buffer. Leave this short-lived worker
         * alive only until the platform callback releases that resource; do
         * not close a live HardwareBuffer from Main or quit before that
         * owner-side cleanup can run. */
        private fun finishDisposeIfReleased() {
            if (disposed && slots.isEmpty()) {
                fenceThread.quitSafely()
                thread.quitSafely()
            }
        }

        /** Called only on the renderer handler. Main samples these volatile
         * scalars without joining the renderer or inspecting mutable slots. */
        private fun publishSlotSnapshot() {
            snapshotSequence++ // odd: publication in progress
            snapshotInFlight = slots.count {
                it.state == SlotState.RENDERING || it.state == SlotState.WAIT_RENDER_FENCE
            }
            snapshotReady = slots.count { it.state == SlotState.READY_FOR_MAIN }
            snapshotCompositorOwned = slots.count {
                it.state == SlotState.PUBLISHED || it.state == SlotState.WAIT_RELEASE_FENCE
            }
            snapshotRunning = running
            snapshotDesiredAttachment = desired?.lease?.attachment ?: -1L
            snapshotDesiredGeneration = desired?.lease?.generation ?: -1L
            snapshotAttachedAttachment = attachedLease?.attachment ?: -1L
            snapshotAttachedGeneration = attachedLease?.generation ?: -1L
            val grant = publicationTarget.current()
            snapshotGrantAttachment = grant?.lease?.attachment ?: -1L
            snapshotGrantGeneration = grant?.lease?.generation ?: -1L
            snapshotGrantIdentity = grant?.let(System::identityHashCode) ?: 0
            snapshotGrantActive = grant?.active == true
            snapshotLastCompletionAt = previousCompletionAtUptimeMs
            snapshotFirstWorkAttachment = firstWorkAttachment
            snapshotFirstWorkGeneration = firstWorkGeneration
            snapshotFirstWorkRequested = firstWorkRequestedAt
            snapshotFirstWorkStarted = firstWorkStartedAt
            snapshotFirstWorkResult = firstWorkResultAt
            snapshotFirstWorkStatus = firstWorkResultStatus
            snapshotFirstWorkOwner = firstWorkOwner
            snapshotFirstFrameAt = firstFrameAt
            snapshotFirstFrameSlot = firstFrameSlot
            snapshotFirstFrameUse = firstFrameUse
            snapshotSecondFrameAt = secondFrameAt
            snapshotSecondFrameSlot = secondFrameSlot
            snapshotSecondFrameUse = secondFrameUse
            snapshotBlockReason = currentBlockReason
            snapshotAt = SystemClock.uptimeMillis()
            snapshotSequence++ // even: coherent sample available
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private data class ReadyFrame(
        val producerFrame: KeyguardOrbBufferProducerFrame,
        val lease: KeyguardOrbBufferLease = producerFrame.lease,
        /** Stable across retirement filtering; never use a mutable-list index
         * in a cross-thread release callback. */
        val slotId: Long = producerFrame.slotId,
        /** Every async producer/release callback is additionally bound to a
         * particular use of this stable allocation. */
        val useGeneration: Long = producerFrame.useGeneration,
        val buffer: HardwareBuffer,
        val fence: SyncFence?,
        val readyAtUptimeMs: Long,
    )
}
