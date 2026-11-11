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
import android.view.AttachedSurfaceControl
import android.view.Choreographer
import android.view.SurfaceControl
import android.view.View
import androidx.annotation.RequiresApi
import java.time.Duration
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
    /** Worker completion cadence, not display/compositor presentation. */
    val completionGapMaxMs: Long,
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

/** The service is constructed by Android, so instrumentation installs this
 * seam before binding it.  Controllers snapshot the observer at construction;
 * changing it cannot affect an existing renderer. */
internal object KeyguardOrbBufferRendererTestHooks {
    @Volatile var frameObserver: KeyguardOrbBufferFrameObserver = NoopKeyguardOrbBufferFrameObserver
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
    private val onFirstPublished: (KeyguardOrbBufferLease, Long) -> Unit,
    private val onFailure: (KeyguardOrbBufferLease, Throwable) -> Unit,
    /** Called on Main when the View's measured buffer target differs from the
     * immutable lease. The controller creates a new generation; this class
     * never stretches a completed buffer. */
    private val onSizeChanged: () -> Unit,
    private val barrier: KeyguardOrbRenderBarrier = NoopKeyguardOrbRenderBarrier,
    private val frameObserver: KeyguardOrbBufferFrameObserver = NoopKeyguardOrbBufferFrameObserver,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
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
    fun retire(reason: String) {
        if (!isSupported()) return
        requireMainThread()
        api34?.retire(reason)
    }

    fun dispose() {
        if (!isSupported()) return
        requireMainThread()
        api34?.dispose()
        api34 = null
    }

    fun snapshot(): KeyguardOrbBufferRendererSnapshot = api34?.snapshot()
        ?: KeyguardOrbBufferRendererSnapshot(false, false, false, 0, 0, 0, 0, 0, 0, 0, 0)

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
        /** A hidden child is not released until the worker has observed every
         * exact old use become fence-safe. Transaction commit is explicitly
         * not that signal. */
        private val retiringLayers = mutableMapOf<KeyguardOrbBufferLease, SurfaceControl>()
        private var firstPublishedLease: KeyguardOrbBufferLease? = null
        /** A detached prewarm has real GPU output but no legal parent layer
         * yet. Retain at most one such frame; it is never a visibility grant. */
        private var deferredReady: ReadyFrame? = null
        private var attachListener: View.OnAttachStateChangeListener? = null
        private var layoutListener: View.OnLayoutChangeListener? = null
        private var disposed = false
        private var framesPublished = 0
        private var failures = 0
        private val worker = Worker(
            onFrameReady = ::onFrameReady,
            onFailure = ::onWorkerFailure,
            onLeaseDrained = ::onLeaseDrained,
            barrier = barrier,
            frameObserver = frameObserver,
        )

        fun configure(spec: KeyguardOrbBufferRenderSpec) {
            if (disposed) return
            val old = desired
            desired = spec
            if (old?.lease != spec.lease) {
                // A prepared detached frame is bound to its exact lease. It
                // cannot be stretched into a new attach, profile or program.
                deferredReady?.let(worker::dropReady)
                deferredReady = null
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
                // retire clears the worker's desired lease so a late old
                // result cannot publish. Restore only this current immutable
                // spec before installing the replacement attachment.
                desired = spec
                worker.configure(spec)
            }
            if (attachment == null) {
                attachment = next
                installAttachmentListeners(next)
            }
            ensureLayer(next)
        }

        fun retire(reason: String) {
            val oldAttachment = attachment
            removeAttachmentListeners(oldAttachment)
            attachment = null
            hideLayer()
            firstPublishedLease = null
            deferredReady?.let(worker::dropReady)
            deferredReady = null
            worker.retire(reason)
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
                completionGapMaxMs = workerSnapshot.completionGapMaxMs,
            )
        }

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
            if (value != null) {
                if (attach != null) value.root.removeOnAttachStateChangeListener(attach)
                if (layout != null) value.orb.removeOnLayoutChangeListener(layout)
            }
            attachListener = null
            layoutListener = null
        }

        private fun ensureLayer(value: KeyguardOrbBufferAttachment) {
            val spec = desired ?: return
            if (!value.root.isAttachedToWindow || value.orb.width <= 0 || value.orb.height <= 0) return
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
            if (existing == null) {
                val parent: AttachedSurfaceControl = value.root.rootSurfaceControl ?: return
                val child = SurfaceControl.Builder()
                    .setName("FluviKeyguardStandaloneOrb")
                    .setBufferSize(spec.lease.width, spec.lease.height)
                    .setFormat(PixelFormat.RGBA_8888)
                    .setOpaque(false)
                    .setHidden(true)
                    .build()
                val location = IntArray(2)
                value.orb.getLocationInSurface(location)
                val reparent = parent.buildReparentTransaction(child)
                    ?: run {
                        child.release()
                        return
                    }
                reparent
                    .setPosition(child, location[0].toFloat(), location[1].toFloat())
                    // `rootSurfaceControl` also owns the ViewRoot's BLAST
                    // buffer.  The isolated ORB is a sibling of that buffer,
                    // not a child of the placeholder View, so a small sibling
                    // Z value can leave a successfully published buffer below
                    // a later ViewRoot submission.  Keep this non-input child
                    // at the top of *this root only*; reparenting constrains it
                    // to the existing accessibility-overlay root and cannot
                    // raise it above another application or SystemUI surface.
                    .setLayer(child, Int.MAX_VALUE)
                    .setVisibility(child, false)
                    .apply()
                layer = child
                layerLease = spec.lease
                firstPublishedLease = null
            } else {
                val location = IntArray(2)
                value.orb.getLocationInSurface(location)
                SurfaceControl.Transaction()
                    .setPosition(existing, location[0].toFloat(), location[1].toFloat())
                    .apply()
            }
            worker.setAttachment(spec.lease, requireNotNull(layer))
            deferredReady?.let { frame ->
                if (frame.lease == spec.lease) {
                    deferredReady = null
                    publishReady(frame)
                } else {
                    // A detached prewarm can finish between configure() and
                    // attach(). It is not a candidate for this attachment.
                    // Leaving that READY slot behind would prevent the sole
                    // producer from making a current frame indefinitely.
                    deferredReady = null
                    worker.dropReady(frame)
                }
            }
        }

        private fun hideLayer() {
            val child = layer ?: return
            val lease = layerLease
            if (lease != null) {
                // This volatile revocation happens before the Main transaction
                // so a worker that has just completed a buffer cannot obtain
                // fresh show/reparent authority from an old lease.
                worker.revokePublication(lease)
                retiringLayers[lease] = child
            }
            runCatching {
                SurfaceControl.Transaction()
                    // SurfaceControl's null-buffer form releases the last
                    // displayed buffer and invokes its release callback.  A
                    // visibility transaction alone may leave that
                    // compositor-owned slot stranded. Commit this release
                    // before unparenting the layer: destroying the child in
                    // the same transaction can discard the callback needed
                    // to retire the worker-owned HardwareBuffer safely.
                    .setBuffer(child, null as HardwareBuffer?)
                    .setVisibility(child, false)
                    .apply()
            }
            // A transaction-committed callback would only establish that this
            // transaction is ready to present. It is not permission to close
            // a HardwareBuffer or this child. onLeaseDrained performs the
            // eventual reparent/release after actual producer/release fences.
            firstPublishedLease = null
            layer = null
            layerLease = null
        }

        private fun onLeaseDrained(lease: KeyguardOrbBufferLease) {
            mainHandler.post {
                // A current layer can never be removed by an old callback:
                // layers are indexed by the exact immutable lease.
                retiringLayers.remove(lease)?.let { child ->
                    runCatching { SurfaceControl.Transaction().reparent(child, null).apply() }
                    runCatching { child.release() }
                }
            }
        }

        private fun onFrameReady(frame: ReadyFrame) {
            mainHandler.post publish@{
                if (!disposed && attachment == null && desired?.lease == frame.lease) {
                    val replaced = deferredReady
                    deferredReady = frame
                    if (replaced != null) worker.dropReady(replaced)
                    return@publish
                }
                publishReady(frame)
            }
        }

        private fun publishReady(frame: ReadyFrame) {
            val active = attachment
            val child = layer
            if (disposed || active == null || child == null ||
                layerLease != frame.lease || desired?.lease != frame.lease ||
                active.attachment != frame.lease.attachment || !active.root.isAttachedToWindow
            ) {
                worker.dropReady(frame)
                return
            }
            runCatching {
                    val release = Consumer<SyncFence> { releaseFence ->
                        // The compositor callback can arrive on an arbitrary
                        // thread. Fence waiting and slot reuse remain
                        // renderer-thread-owned; Main never waits for a
                        // released buffer.
                        worker.release(frame.slotId, frame.useGeneration, releaseFence)
                    }
                    val transaction = SurfaceControl.Transaction()
                        .setBuffer(child, frame.buffer, frame.fence, release)
                        .setVisibility(child, true)
                    val firstCurrentPublication = firstPublishedLease != frame.lease
                    if (firstCurrentPublication) {
                        // The first live buffer replaces the View bootstrap.
                        // Merge exactly this one transaction with an explicit
                        // root traversal so the old View content cannot win a
                        // later unsynchronised parent-buffer submission.
                        // Continuous buffer updates below remain independent
                        // of ViewRoot traversal and Main invalidation.
                        val merged = active.root.rootSurfaceControl
                            ?.applyTransactionOnDraw(transaction) == true
                        if (merged) {
                            active.root.invalidate()
                        } else {
                            transaction.apply()
                        }
                    } else {
                        transaction.apply()
                    }
                    // A successful setBuffer transaction takes ownership of
                    // its acquire fence. Closing it here can invalidate the
                    // compositor's wait before the buffer is displayed. The
                    // error/drop path remains responsible for a fence that
                    // was never submitted.
                    worker.markFirstPublished(frame)
                    if (firstCurrentPublication) {
                        firstPublishedLease = frame.lease
                        framesPublished += 1
                        // This reports queue/submission ownership only. It is
                        // not a physical presentation or release-fence event.
                        onFirstPublished(frame.lease, android.os.SystemClock.uptimeMillis())
                    }
            }.onFailure { error ->
                // A failed first transaction did not submit this producer
                // fence. dropReady keeps it owned until its render work is
                // actually safe, rather than closing/reusing early.
                worker.dropReady(frame)
                failures += 1
                onFailure(frame.lease, error)
            }
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
        private val onLeaseDrained: (KeyguardOrbBufferLease) -> Unit,
        private val barrier: KeyguardOrbRenderBarrier,
        private val frameObserver: KeyguardOrbBufferFrameObserver,
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
            val node: RenderNode,
            /**
             * A RuntimeShader is mutable.  A HardwareBufferRenderer callback
             * only means its RenderNode was submitted; its fence still owns
             * GPU work.  Therefore one shader/paint pair belongs to one
             * physical buffer slot and is not reconfigured until that slot
             * has returned to FREE after its release fence.
             */
            var shader: KeyguardHeaderShader? = null,
            var shaderProgramKey: String? = null,
            var previousShader: KeyguardHeaderShader? = null,
            var previousShaderProgramKey: String? = null,
            val paint: Paint = Paint(Paint.ANTI_ALIAS_FLAG),
            var state: SlotState = SlotState.FREE,
            /** Retirement revokes a lease; it is not an ownership state. */
            var retired: Boolean = false,
            var useGeneration: Long = 0L,
            var lease: KeyguardOrbBufferLease? = null,
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
        @Volatile private var publicationTarget: PublicationTarget? = null
        private var firstLeaseSubmitted: KeyguardOrbBufferLease? = null
        private var firstLeaseAwaitingMain: KeyguardOrbBufferLease? = null
        private val retiringLeases = mutableSetOf<KeyguardOrbBufferLease>()
        private val earlyReleaseFences = mutableMapOf<Pair<Long, Long>, SyncFence?>()
        private var slots: MutableList<Slot> = mutableListOf()
        private var nextSlotId = 0L
        private var running = false
        private var disposed = false
        @Volatile private var produced = 0
        @Volatile private var published = 0
        @Volatile private var dropped = 0
        @Volatile private var failures = 0
        @Volatile private var snapshotInFlight = 0
        @Volatile private var snapshotReady = 0
        @Volatile private var snapshotCompositorOwned = 0
        @Volatile private var completionGapMaxMs = 0L
        private var previousCompletionAtUptimeMs = 0L

        data class Snapshot(
            val produced: Int,
            val published: Int,
            val dropped: Int,
            val failures: Int,
            val inFlight: Int,
            val ready: Int,
            val compositorOwned: Int,
            val completionGapMaxMs: Long,
        )

        init {
            handler.post { choreographer = Choreographer.getInstance() }
        }

        fun post(command: Runnable) { handler.post(command) }

        fun configure(value: KeyguardOrbBufferRenderSpec) {
            handler.post {
                if (disposed) return@post
                desired = value
                if (!ensureResources(value)) return@post
                publishSlotSnapshot()
                // Detached preparation renders one real frame into a
                // READY_FOR_MAIN
                // slot. It does not start a continuous animation loop.
                requestFrame()
            }
        }

        fun setAttachment(lease: KeyguardOrbBufferLease, child: SurfaceControl) {
            // Main grants this exact existing child once. Subsequent worker
            // transactions may only replace its buffer; they never change
            // visibility or parenting.
            publicationTarget = PublicationTarget(lease, child)
            handler.post {
                if (disposed || desired?.lease != lease) return@post
                if (attachedLease != lease) {
                    previousCompletionAtUptimeMs = 0L
                    completionGapMaxMs = 0L
                }
                attachedLease = lease
                running = true
                requestFrame()
            }
        }

        fun revokePublication(lease: KeyguardOrbBufferLease) {
            // Make the revocation visible to a renderer callback before its
            // queued control-lane bookkeeping runs.
            publicationTarget?.takeIf { it.lease == lease }?.active = false
            handler.post {
                retiringLeases += lease
                if (attachedLease == lease) attachedLease = null
                slots.filter { it.lease == lease && it.state != SlotState.FREE }.forEach {
                    it.retired = true
                }
                maybeNotifyLeaseDrained(lease)
                publishSlotSnapshot()
            }
        }

        fun retire(reason: String) {
            handler.post {
                running = false
                attachedLease = null
                desired = null
                publicationTarget?.active = false
                publicationTarget = null
                if (callbackPosted) choreographer?.removeFrameCallback(this)
                callbackPosted = false
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
                firstLeaseAwaitingMain = null
                slots.filter { it.state != SlotState.FREE }.forEach { slot ->
                    slot.retired = true
                    slot.lease?.let(retiringLeases::add)
                }
                retiringLeases.toList().forEach(::maybeNotifyLeaseDrained)
                publishSlotSnapshot()
            }
        }

        fun dispose() {
            handler.post {
                disposed = true
                running = false
                publicationTarget?.active = false
                publicationTarget = null
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

        fun markFirstPublished(frame: ReadyFrame) {
            handler.post {
                val slot = slots.firstOrNull { it.id == frame.slotId }
                if (slot == null || slot.useGeneration != frame.useGeneration ||
                    slot.state != SlotState.READY_FOR_MAIN || slot.lease != frame.lease
                ) return@post
                slot.state = SlotState.PUBLISHED
                firstLeaseAwaitingMain = null
                firstLeaseSubmitted = frame.lease
                published += 1
                earlyReleaseFences.remove(frame.slotId to frame.useGeneration)?.let { fence ->
                    consumeRelease(frame.slotId, frame.useGeneration, fence)
                }
                publishSlotSnapshot()
                if (running) requestFrame()
            }
        }

        fun release(slotId: Long, useGeneration: Long, releaseFence: SyncFence?) {
            handler.post {
                val slot = slots.firstOrNull { it.id == slotId } ?: run {
                    releaseFence?.close()
                    return@post
                }
                consumeRelease(slotId, useGeneration, releaseFence)
            }
        }

        private fun consumeRelease(slotId: Long, useGeneration: Long, releaseFence: SyncFence?) {
            if (Looper.myLooper() != thread.looper) {
                handler.post { consumeRelease(slotId, useGeneration, releaseFence) }
                return
            }
            val slot = slots.firstOrNull { it.id == slotId }
            if (slot != null && slot.useGeneration == useGeneration &&
                slot.state == SlotState.READY_FOR_MAIN
            ) {
                // SurfaceFlinger may release a transaction before the Main
                // acknowledgement runnable reaches the renderer handler.
                // Retain this exact fence rather than treating READY as FREE.
                earlyReleaseFences[slotId to useGeneration]?.close()
                earlyReleaseFences[slotId to useGeneration] = releaseFence
                return
            }
            if (slot == null || slot.useGeneration != useGeneration || slot.state != SlotState.PUBLISHED) {
                releaseFence?.close()
                return
            }
            slot.state = SlotState.WAIT_RELEASE_FENCE
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
            // Snapshot is advisory diagnostics. It must not block Main behind
            // rendering; worker-published volatile scalars deliberately avoid
            // exposing the mutable slot list across thread ownership.
            return Snapshot(
                produced, published, dropped, failures, snapshotInFlight, snapshotReady,
                snapshotCompositorOwned, completionGapMaxMs,
            )
        }

        override fun doFrame(frameTimeNanos: Long) {
            callbackPosted = false
            if (disposed) return
            render(frameTimeNanos)
            if (running) requestFrame()
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
            // A different size cannot recycle a target while any producer or
            // compositor owner remains. Wait rather than allocating another
            // generation outside the global three-slot limit.
            if (slots.any { it.state != SlotState.FREE &&
                    (it.buffer.width != spec.lease.width || it.buffer.height != spec.lease.height) }) {
                return false
            }
            slots.filter { it.state == SlotState.FREE &&
                (it.buffer.width != spec.lease.width || it.buffer.height != spec.lease.height) }
                .toList().forEach { slot ->
                    closeSlot(slot)
                    slots.remove(slot)
                }
            val usage = HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or
                HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or HardwareBuffer.USAGE_COMPOSER_OVERLAY
            check(HardwareBuffer.isSupported(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)) {
                "hardware-buffer-unsupported"
            }
            // Refill a safely depleted same-size pool. "One slot exists" is
            // not a healthy triple-buffer pool: that last slot may be the
            // compositor's current content and cannot produce its successor.
            while (slots.size < 3) {
                val index = slots.size
                val buffer = HardwareBuffer.create(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)
                slots += Slot(++nextSlotId, buffer, HardwareBufferRenderer(buffer), RenderNode("fluvi-keyguard-orb-buffer-$index").apply {
                    setPosition(0, 0, spec.lease.width, spec.lease.height)
                })
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
            if (!ensureResources(spec)) return
            if (slots.any {
                    it.state == SlotState.READY_FOR_MAIN ||
                        it.state == SlotState.RENDERING ||
                        it.state == SlotState.WAIT_RENDER_FENCE
                }) return
            val index = slots.indexOfFirst { it.state == SlotState.FREE }
            if (index < 0) {
                dropped += 1
                return
            }
            val slot = slots[index]
            prepareSlotShaders(slot, spec)
            val currentShader = slot.shader ?: return
            slot.state = SlotState.RENDERING
            slot.retired = false
            slot.lease = spec.lease
            slot.useGeneration += 1L
            val useGeneration = slot.useGeneration
            publishSlotSnapshot()
            try {
                barrier.beforeRender(spec.lease)
                val canvas = slot.node.beginRecording(spec.lease.width, spec.lease.height)
                try {
                    // HardwareBufferRenderer keeps prior contents. A clear is
                    // required for transparent antialiased circle edges.
                    canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
                    val old = spec.previousScene
                    val progress = if (old == null || spec.transitionStartedNanos <= 0L) 1f else {
                        ((frameTimeNanos - spec.transitionStartedNanos) / 180_000_000f).coerceIn(0f, 1f)
                    }
                    if (old != null && progress < 1f) {
                        drawScene(canvas, slot.previousShader ?: currentShader, old, slot.paint,
                            frameTimeNanos, 1f, spec.lease)
                    }
                    drawScene(canvas, currentShader, spec.scene, slot.paint,
                        frameTimeNanos, progress, spec.lease)
                } finally {
                    slot.node.endRecording()
                }
                slot.renderer.setContentRoot(slot.node)
                // HardwareBufferRenderer's request owns the output colour
                // space independently of the Window/View renderer.  Bind the
                // same sRGB target used by Android's HardwareBufferRenderer
                // CTS coverage before each synchronized RenderNode draw; an
                // unspecified target left the retained RuntimeShader output
                // frozen across otherwise distinct phase records on API 35.
                slot.renderer.obtainRenderRequest()
                    .setColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
                    .draw(executor, Consumer { result ->
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
                    val materialTime = spec.scene.timeAt(frameTimeNanos)
                    // This hook is intentionally test-only and executes on
                    // the renderer handler after a SUCCESS result.  It lets
                    // instrumentation read the producer buffer after the
                    // completion fence without putting readback or waits on
                    // the production/Main frame path.
                    if (frameObserver !== NoopKeyguardOrbBufferFrameObserver) {
                        runCatching {
                            frameObserver.onProduced(
                                KeyguardOrbBufferProducerFrame(
                                    lease = spec.lease,
                                    slotId = slot.id,
                                    useGeneration = useGeneration,
                                    frameTimeNanos = frameTimeNanos,
                                    materialTime = materialTime,
                                ),
                                slot.buffer,
                                result.fence,
                            )
                        }
                    }
                    val ready = ReadyFrame(
                        spec.lease, slot.id, useGeneration, slot.buffer, result.fence,
                    )
                    if (firstLeaseSubmitted == spec.lease) {
                        publishSteady(slot, ready)
                    } else if (firstLeaseAwaitingMain != spec.lease) {
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
            val oldArtifact = spec.previousArtifact
            if (spec.previousScene == null) {
                slot.previousShader = null
                slot.previousShaderProgramKey = null
            } else if (oldArtifact == null || oldArtifact.programKey == spec.artifact.programKey) {
                // Both transition scenes have the same source, but this
                // slot owns the instance and configures the two recordings
                // serially before one RenderRequest is submitted.
                slot.previousShader = slot.shader
                slot.previousShaderProgramKey = spec.artifact.programKey
            } else if (slot.previousShaderProgramKey != oldArtifact.programKey) {
                slot.previousShader = KeyguardHeaderShader(oldArtifact)
                slot.previousShaderProgramKey = oldArtifact.programKey
            }
        }

        /** Steady state has no Main callback. This operation has no authority
         * to show, hide or reparent: it updates only a still-authorized child
         * that Main made visible during first publication. */
        private fun publishSteady(slot: Slot, frame: ReadyFrame) {
            val target = publicationTarget
            if (target == null || !target.active || target.lease != frame.lease ||
                slot.useGeneration != frame.useGeneration || slot.retired
            ) {
                discardRenderResult(slot, frame.fence)
                dropped += 1
                return
            }
            runCatching {
                SurfaceControl.Transaction()
                    .setBuffer(
                        target.child,
                        frame.buffer,
                        frame.fence,
                        Consumer { releaseFence -> consumeRelease(frame.slotId, frame.useGeneration, releaseFence) },
                    )
                    .apply()
                // SurfaceControl owns the submitted acquire fence. Slot
                // reuse still waits for its later release callback/fence,
                // never for transaction commitment.
                slot.state = SlotState.PUBLISHED
                published += 1
            }.onFailure { error ->
                discardRenderResult(slot, frame.fence)
                failures += 1
                onFailure(frame.lease, error)
            }
            publishSlotSnapshot()
        }

        /** A stale/failed producer completion still owns its render fence.
         * It cannot become FREE simply because its visual lease was revoked. */
        private fun discardRenderResult(slot: Slot, fence: SyncFence?) {
            slot.state = SlotState.WAIT_RENDER_FENCE
            awaitFence(slot.id, slot.useGeneration, SlotState.WAIT_RENDER_FENCE, fence)
        }

        private fun awaitFence(
            slotId: Long,
            useGeneration: Long,
            expected: SlotState,
            fence: SyncFence?,
        ) {
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

        private fun finishFence(slotId: Long, useGeneration: Long, expected: SlotState) {
            val slot = slots.firstOrNull { it.id == slotId } ?: return
            if (slot.useGeneration != useGeneration || slot.state != expected) return
            val completedLease = slot.lease
            if (disposed) {
                closeSlot(slot)
                slots.remove(slot)
            } else {
                slot.state = SlotState.FREE
                slot.retired = false
                slot.lease = null
            }
            completedLease?.let(::maybeNotifyLeaseDrained)
            retiringLeases.toList().forEach(::maybeNotifyLeaseDrained)
            publishSlotSnapshot()
            finishDisposeIfReleased()
            if (running && !disposed) requestFrame()
        }

        private fun maybeNotifyLeaseDrained(lease: KeyguardOrbBufferLease) {
            if (!retiringLeases.contains(lease)) return
            if (slots.none { it.lease == lease && it.state != SlotState.FREE }) {
                retiringLeases.remove(lease)
                onLeaseDrained(lease)
            }
        }

        private fun drawScene(
            canvas: android.graphics.Canvas,
            source: KeyguardHeaderShader,
            scene: KeyguardMaterialScene,
            targetPaint: Paint,
            frameTimeNanos: Long,
            alpha: Float,
            lease: KeyguardOrbBufferLease,
        ) {
            source.configure(scene.profile, lease.width, lease.height, scene.timeAt(frameTimeNanos))
            targetPaint.shader = source.runtimeShader
            targetPaint.alpha = (alpha * 255f).toInt().coerceIn(0, 255)
            canvas.drawCircle(lease.width / 2f, lease.height / 2f,
                min(lease.width, lease.height) / 2f, targetPaint)
            targetPaint.shader = null
            targetPaint.alpha = 255
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
            snapshotInFlight = slots.count {
                it.state == SlotState.RENDERING || it.state == SlotState.WAIT_RENDER_FENCE
            }
            snapshotReady = slots.count { it.state == SlotState.READY_FOR_MAIN }
            snapshotCompositorOwned = slots.count {
                it.state == SlotState.PUBLISHED || it.state == SlotState.WAIT_RELEASE_FENCE
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private data class ReadyFrame(
        val lease: KeyguardOrbBufferLease,
        /** Stable across retirement filtering; never use a mutable-list index
         * in a cross-thread release callback. */
        val slotId: Long,
        /** Every async producer/release callback is additionally bound to a
         * particular use of this stable allocation. */
        val useGeneration: Long,
        val buffer: HardwareBuffer,
        val fence: SyncFence?,
    )
}
