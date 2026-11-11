package com.fluvi.app.lockscreen.material

import android.annotation.SuppressLint
import android.graphics.Color
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
            barrier = barrier,
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
            layer?.release()
            layer = null
            layerLease = null
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
                framesPublished = framesPublished,
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
                    .setLayer(child, 1)
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
            worker.setAttachment(spec.lease)
            deferredReady?.let { frame ->
                if (frame.lease == spec.lease) {
                    deferredReady = null
                    publishReady(frame)
                }
            }
        }

        private fun hideLayer() {
            val child = layer ?: return
            runCatching {
                SurfaceControl.Transaction()
                    .setVisibility(child, false)
                    .reparent(child, null)
                    .apply()
            }
            firstPublishedLease = null
            layer?.release()
            layer = null
            layerLease = null
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
                    SurfaceControl.Transaction()
                        .setBuffer(child, frame.buffer, frame.fence) { releaseFence ->
                            // The compositor callback can arrive on an
                            // arbitrary thread.  Fence waiting and slot reuse
                            // remain renderer-thread-owned; Main never waits
                            // for a released buffer.
                            worker.release(frame.slot, releaseFence)
                        }
                        .setVisibility(child, true)
                        .apply()
                    // The transaction copied the acquisition fence. Close the
                    // application handle only after submission, never before.
                    frame.fence?.close()
                    worker.markCompositorOwned(frame.slot)
                    framesPublished += 1
                    if (firstPublishedLease != frame.lease) {
                        firstPublishedLease = frame.lease
                    // Transaction submission is observed here, after Main has
                    // applied the matching layer update. It is not claimed to
                    // be physical panel presentation.
                    onFirstPublished(frame.lease, android.os.SystemClock.uptimeMillis())
                    }
            }.onFailure { error ->
                frame.fence?.close()
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
        private val barrier: KeyguardOrbRenderBarrier,
    ) : Choreographer.FrameCallback {
        /**
         * `READY_FOR_MAIN` is deliberately distinct from compositor ownership.
         * The renderer thread has completed the buffer, but the posted Main
         * publication has not yet either submitted it to SurfaceControl or
         * rejected it.  Retirement must retain that slot until the Main
         * hand-off resolves; otherwise a late release/drop callback can target
         * a dead worker and close a buffer the compositor still references.
         */
        private enum class SlotState { FREE, RENDERING, READY_FOR_MAIN, COMPOSITOR_OWNED, RETIRED }
        private data class Slot(
            val buffer: HardwareBuffer,
            val renderer: HardwareBufferRenderer,
            val node: RenderNode,
            var state: SlotState = SlotState.FREE,
        )

        private val thread = HandlerThread("fluvi-keyguard-orb-render").apply { start() }
        private val handler = Handler(thread.looper)
        private val executor = Executor { command -> handler.post(command) }
        private var choreographer: Choreographer? = null
        private var callbackPosted = false
        private var desired: KeyguardOrbBufferRenderSpec? = null
        private var attachedLease: KeyguardOrbBufferLease? = null
        private var shader: KeyguardHeaderShader? = null
        private var shaderProgramKey: String? = null
        private var previousShader: KeyguardHeaderShader? = null
        private var previousShaderProgramKey: String? = null
        /** Renderer-thread confined; never allocate a Paint for each frame. */
        private var paint: Paint? = null
        private var slots: MutableList<Slot> = mutableListOf()
        private var running = false
        private var disposed = false
        @Volatile private var produced = 0
        @Volatile private var dropped = 0
        @Volatile private var failures = 0
        @Volatile private var snapshotInFlight = 0
        @Volatile private var snapshotReady = 0
        @Volatile private var snapshotCompositorOwned = 0
        @Volatile private var completionGapMaxMs = 0L
        private var previousCompletionAtUptimeMs = 0L

        data class Snapshot(
            val produced: Int,
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

        fun setAttachment(lease: KeyguardOrbBufferLease) {
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

        fun retire(reason: String) {
            handler.post {
                running = false
                attachedLease = null
                desired = null
                if (callbackPosted) choreographer?.removeFrameCallback(this)
                callbackPosted = false
                // Only an already-free/ready target can be closed now.  A
                // RenderRequest or the compositor may still own the others;
                // retain just those two states until their callback/fence
                // returns.  In particular, do not keep closed slots in the
                // next pool or reuse an in-flight HardwareBuffer.
                val awaitingRelease = slots.filter {
                    it.state == SlotState.RENDERING ||
                        it.state == SlotState.READY_FOR_MAIN ||
                        it.state == SlotState.COMPOSITOR_OWNED
                }.toMutableList()
                slots.filter { it !in awaitingRelease }.forEach(::closeSlot)
                awaitingRelease.forEach { it.state = SlotState.RETIRED }
                slots = awaitingRelease
                publishSlotSnapshot()
            }
        }

        fun dispose() {
            handler.post {
                disposed = true
                running = false
                if (callbackPosted) choreographer?.removeFrameCallback(this)
                callbackPosted = false
                val awaitingRelease = slots.filter {
                    it.state == SlotState.RENDERING ||
                        it.state == SlotState.READY_FOR_MAIN ||
                        it.state == SlotState.COMPOSITOR_OWNED
                }.toMutableList()
                slots.filter { it !in awaitingRelease }.forEach(::closeSlot)
                awaitingRelease.forEach { it.state = SlotState.RETIRED }
                slots = awaitingRelease
                shader = null
                previousShader = null
                paint = null
                publishSlotSnapshot()
                finishDisposeIfReleased()
            }
        }

        fun markCompositorOwned(index: Int) {
            handler.post {
                slots.getOrNull(index)?.takeIf {
                    it.state == SlotState.READY_FOR_MAIN
                }?.state = SlotState.COMPOSITOR_OWNED
                publishSlotSnapshot()
            }
        }

        fun release(index: Int, releaseFence: SyncFence?) {
            handler.post {
                try {
                    // SurfaceControl documents that the release fence must
                    // signal before the HardwareBuffer is reused. Waiting
                    // here may delay only the dedicated producer, never the
                    // accessibility-service Main/control owner.
                    if (releaseFence?.isValid == true) releaseFence.awaitForever()
                } finally {
                    releaseFence?.close()
                    val slot = slots.getOrNull(index)
                    if (slot != null) {
                        if (slot.state == SlotState.RETIRED) {
                            closeSlot(slot)
                            slots.remove(slot)
                        } else {
                            slot.state = SlotState.FREE
                            if (running) requestFrame()
                        }
                    }
                    publishSlotSnapshot()
                    finishDisposeIfReleased()
                }
            }
        }

        fun dropReady(frame: ReadyFrame) {
            handler.post {
                frame.fence?.close()
                val slot = slots.getOrNull(frame.slot)
                when (slot?.state) {
                    SlotState.READY_FOR_MAIN -> {
                        slot.state = SlotState.FREE
                        if (running) requestFrame()
                    }
                    SlotState.RETIRED -> {
                        closeSlot(slot)
                        slots.remove(slot)
                    }
                    else -> Unit
                }
                dropped += 1
                publishSlotSnapshot()
                finishDisposeIfReleased()
            }
        }

        fun snapshot(): Snapshot {
            // Snapshot is advisory diagnostics. It must not block Main behind
            // rendering; worker-published volatile scalars deliberately avoid
            // exposing the mutable slot list across thread ownership.
            return Snapshot(
                produced, dropped, failures, snapshotInFlight, snapshotReady,
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
            if (shaderProgramKey != spec.artifact.programKey) {
                shader = KeyguardHeaderShader(spec.artifact)
                shaderProgramKey = spec.artifact.programKey
            }
            val oldArtifact = spec.previousArtifact
            if (spec.previousScene == null) {
                previousShader = null
                previousShaderProgramKey = null
            } else if (oldArtifact == null || oldArtifact.programKey == spec.artifact.programKey) {
                // Same generated source: one confined RuntimeShader can
                // configure and draw both scenes serially in this frame.
                previousShader = shader
                previousShaderProgramKey = spec.artifact.programKey
            } else if (previousShaderProgramKey != oldArtifact.programKey) {
                previousShader = KeyguardHeaderShader(oldArtifact)
                previousShaderProgramKey = oldArtifact.programKey
            }
            if (paint == null) paint = Paint(Paint.ANTI_ALIAS_FLAG)
            if (slots.isNotEmpty() && slots.all {
                    it.buffer.width == spec.lease.width && it.buffer.height == spec.lease.height &&
                        it.state != SlotState.RETIRED
                }
            ) return true
            // A previous layer can retain a compositor-owned buffer after its
            // Main-side lease was revoked. Never resize/reuse that buffer for
            // a new scene; wait for the release callback instead of growing a
            // pool or publishing an incorrectly sized image.
            if (slots.any { it.state == SlotState.COMPOSITOR_OWNED || it.state == SlotState.RETIRED }) return false
            slots.forEach(::closeSlot)
            slots.clear()
            val usage = HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or
                HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or HardwareBuffer.USAGE_COMPOSER_OVERLAY
            check(HardwareBuffer.isSupported(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)) {
                "hardware-buffer-unsupported"
            }
            repeat(3) { index ->
                val buffer = HardwareBuffer.create(spec.lease.width, spec.lease.height, HardwareBuffer.RGBA_8888, 1, usage)
                slots += Slot(buffer, HardwareBufferRenderer(buffer), RenderNode("fluvi-keyguard-orb-buffer-$index").apply {
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
                    it.state == SlotState.READY_FOR_MAIN || it.state == SlotState.RENDERING
                }) return
            val index = slots.indexOfFirst { it.state == SlotState.FREE }
            if (index < 0) {
                dropped += 1
                return
            }
            val slot = slots[index]
            val currentShader = shader ?: return
            val currentPaint = paint ?: return
            slot.state = SlotState.RENDERING
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
                        drawScene(canvas, previousShader ?: currentShader, old, currentPaint,
                            frameTimeNanos, 1f, spec.lease)
                    }
                    drawScene(canvas, currentShader, spec.scene, currentPaint,
                        frameTimeNanos, progress, spec.lease)
                } finally {
                    slot.node.endRecording()
                }
                slot.renderer.setContentRoot(slot.node)
                slot.renderer.obtainRenderRequest().draw(executor, Consumer { result ->
                    if (disposed || desired?.lease != spec.lease || result.status != HardwareBufferRenderer.RenderResult.SUCCESS) {
                        result.fence?.close()
                        if (slot.state == SlotState.RETIRED) {
                            closeSlot(slot)
                            slots.remove(slot)
                            finishDisposeIfReleased()
                        } else {
                            slot.state = SlotState.FREE
                        }
                        dropped += 1
                        publishSlotSnapshot()
                        if (running) requestFrame()
                        return@Consumer
                    }
                    // Ownership moves to the Main publication hand-off before
                    // the callback is posted. Retirement will retain this
                    // slot until that hand-off explicitly drops or submits it.
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
                    onFrameReady(ReadyFrame(spec.lease, index, slot.buffer, result.fence))
                })
            } catch (error: Throwable) {
                slot.state = SlotState.FREE
                failures += 1
                publishSlotSnapshot()
                onFailure(spec.lease, error)
            }
        }

        private fun closeSlot(slot: Slot) {
            runCatching { slot.renderer.close() }
            runCatching { slot.buffer.close() }
            slot.state = SlotState.RETIRED
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
            if (disposed && slots.isEmpty()) thread.quitSafely()
        }

        /** Called only on the renderer handler. Main samples these volatile
         * scalars without joining the renderer or inspecting mutable slots. */
        private fun publishSlotSnapshot() {
            snapshotInFlight = slots.count { it.state == SlotState.RENDERING }
            snapshotReady = slots.count { it.state == SlotState.READY_FOR_MAIN }
            snapshotCompositorOwned = slots.count { it.state == SlotState.COMPOSITOR_OWNED }
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private data class ReadyFrame(
        val lease: KeyguardOrbBufferLease,
        val slot: Int,
        val buffer: HardwareBuffer,
        val fence: SyncFence?,
    )
}
