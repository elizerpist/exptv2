package com.fluvi.app.lockscreen.material

import android.annotation.TargetApi
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.SyncFence
import android.hardware.HardwareBuffer
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.view.Surface
import android.view.SurfaceControl
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.ConcurrentHashMap
import java.util.function.Consumer

/** A single hidden, unparented buffer producer. Borrowers retain this exact
 * surface until they return; neither elapsed time nor a transaction callback
 * is a buffer-release receipt. */
@TargetApi(35)
internal class KeyguardOrbDirectOutput private constructor(
    val attachment: Long,
    val generation: Long,
    val child: SurfaceControl,
    val posterChild: SurfaceControl?,
    private val surface: Surface,
    private val lifetime: KeyguardOrbOutputLifetime,
    private val scheduleDrain: (KeyguardOrbDirectOutput) -> Unit,
) {
    @Volatile internal var hideSettled = false
    @Volatile internal var disposed = false
    @Volatile internal var posterBound = false
    val childId: Int = System.identityHashCode(child) // diagnostics only

    fun borrow(): Surface? = if (lifetime.acquire()) surface else null
    fun releaseBorrow() { if (lifetime.release()) scheduleDrain(this) }
    fun isSealed(): Boolean = lifetime.isSealed()
    internal fun seal(): Boolean = lifetime.seal()
    internal fun canDispose(): Boolean = hideSettled && lifetime.readyToDispose()
    internal fun disposeOnLane(): Boolean {
        if (disposed) return false
        if (!canDispose()) return false
        disposed = true
        runCatching { surface.release() }
        runCatching { posterChild?.release() }
        runCatching { child.release() }
        return true
    }

    companion object {
        fun create(attachment: Long, width: Int, height: Int, generation: Long,
                   scheduleDrain: (KeyguardOrbDirectOutput) -> Unit): KeyguardOrbDirectOutput {
            require(width > 0 && height > 0 && generation > 0)
            val child = SurfaceControl.Builder().setName("FluviR18-$generation")
                .setBufferSize(width, height).setFormat(PixelFormat.RGBA_8888)
                .setOpaque(false).setHidden(true).build()
            var surface: Surface? = null
            try {
                val created = Surface(child)
                surface = created
                check(child.isValid && created.isValid)
                val poster = runCatching {
                    SurfaceControl.Builder().setName("FluviR34Poster-$generation")
                        .setBufferSize(width, height).setFormat(PixelFormat.RGBA_8888)
                        .setOpaque(false).setHidden(true).build()
                }.getOrNull()
                return KeyguardOrbDirectOutput(attachment, generation, child, poster, created, KeyguardOrbOutputLifetime(), scheduleDrain)
            } catch (failure: Throwable) {
                runCatching { surface?.release() }
                runCatching { child.release() }
                throw failure
            }
        }
    }
}

/** One short-task owner for binding, reveal and hide transactions. A queued
 * reveal rechecks its grant just before submission. A synchronous seal prevents
 * new borrows/actions and puts the exact owner's hide ahead of queued work. */
@TargetApi(35)
internal class KeyguardOrbPresentationLane(
    private val captureActive: () -> Boolean,
    private val onFailure: (KeyguardOrbDirectOutput, String) -> Unit,
    private val onReceipt: (KeyguardOrbDirectOutput, Receipt) -> Unit = { _, _ -> },
    private val onDrained: (KeyguardOrbDirectOutput) -> Unit = {},
) {
    data class Receipt(val operation: String, val submitStartUptimeMs: Long,
        val applyReturnUptimeMs: Long?, val committedUptimeMs: Long? = null,
        val latchNanos: Long? = null, val presentSignalNanos: Long? = null,
        val presentState: String = "UNOBSERVED")

    private val thread = HandlerThread("Fluvi-r18-compositor").apply { start() }
    private val handler = Handler(thread.looper)
    private val diagnostics = Executors.newSingleThreadExecutor { task -> Thread(task, "Fluvi-r18-txn-evidence") }
    private val releaseWorker = Executors.newSingleThreadExecutor { task ->
        Thread(task, "Fluvi-r34-release-fence").apply { isDaemon = true }
    }
    private class PosterUse(val lease: KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>) {
        val receipt = AtomicBoolean(false)
        @Volatile var unresolvedFence: SyncFence? = null
    }
    // A use remains here until a real release receipt and its fence complete.
    private val posterUses = ConcurrentHashMap.newKeySet<PosterUse>()
    private val liveOutputs = AtomicInteger(0)
    private val closeRequested = AtomicBoolean(false)
    private val diagnosticExecutor = Executor { command -> runCatching { diagnostics.execute(command) } }
    private fun capturing(): Boolean = runCatching { captureActive() }.getOrDefault(false)
    private fun report(output: KeyguardOrbDirectOutput, receipt: Receipt) { runCatching { onReceipt(output, receipt) } }
    private fun fail(output: KeyguardOrbDirectOutput, reason: String) { runCatching { onFailure(output, reason) } }

    fun createDetached(attachment: Long, width: Int, height: Int, generation: Long): KeyguardOrbDirectOutput? {
        if (closeRequested.get()) return null
        while (true) {
            val old = liveOutputs.get()
            if (old >= 2 || closeRequested.get()) return null
            if (liveOutputs.compareAndSet(old, old + 1)) break
        }
        return try {
            KeyguardOrbDirectOutput.create(attachment, width, height, generation) { output ->
                handler.post { drain(output) }
            }
        } catch (failure: Throwable) {
            liveOutputs.decrementAndGet()
            throw failure
        }
    }

    /** The caller built this reparent transaction on Main for the exact live
     * attached root. Ownership transfers to this lane even if it is discarded. */
    fun bind(output: KeyguardOrbDirectOutput, transaction: SurfaceControl.Transaction,
             x: Float, y: Float, width: Int, height: Int, posterIncluded: Boolean,
             stillCurrent: () -> Boolean, completed: (Boolean) -> Unit) {
        val accepted = handler.post {
            var applied = false
            try {
                if (!output.isSealed() && output.child.isValid && stillCurrent()) {
                    transaction.setPosition(output.child, x, y)
                        .setCrop(output.child, Rect(0, 0, width, height))
                        .setLayer(output.child, Int.MAX_VALUE)
                        .setVisibility(output.child, false)
                    val poster = output.posterChild
                    if (posterIncluded && poster != null && poster.isValid) {
                        transaction.setPosition(poster, x, y).setCrop(poster, Rect(0, 0, width, height))
                            .setLayer(poster, Int.MAX_VALUE).setVisibility(poster, false)
                    }
                    transaction.apply()
                    output.posterBound = posterIncluded && poster != null && poster.isValid
                    applied = true
                }
            } catch (_: Throwable) {
                fail(output, "r18HiddenBindFailed")
            } finally {
                runCatching { transaction.close() }
                runCatching { completed(applied) }
            }
        }
        if (!accepted) {
            runCatching { transaction.close() }
            runCatching { completed(false) }
        }
    }

    /** This operation is never submitted by a worker frame callback. */
    fun reveal(output: KeyguardOrbDirectOutput,
               posterLease: KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>? = null,
               crossGrantBoundary: () -> Boolean, nativeApplied: () -> Boolean,
               stillAuthorized: () -> Boolean = { true }, completed: (Boolean) -> Unit) {
        val accepted = handler.post {
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.beforeRevealCross?.invoke(output)
            if (output.isSealed() || !output.child.isValid || !runCatching { crossGrantBoundary() }.getOrDefault(false)) {
                posterLease?.close()
                runCatching { completed(false) }
                return@post
            }
            val begin = SystemClock.uptimeMillis()
            var applied = false
            var acceptedApply = false
            var applyEntered = false
            var posterUse: PosterUse? = null
            try {
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross?.invoke(output)
                val transaction = SurfaceControl.Transaction()
                try {
                    if (posterLease == null) transaction.setVisibility(output.child, true)
                    else {
                        val poster = checkNotNull(output.posterChild)
                        val buffer = checkNotNull(posterLease.value.buffer)
                        check(output.posterBound && poster.isValid)
                        val use = PosterUse(posterLease).also { posterUse = it; posterUses.add(it) }
                        transaction.setBuffer(poster, buffer, null, Consumer { fence -> releasePoster(use, fence) })
                            .setVisibility(output.child, false).setVisibility(poster, true)
                    }
                    attachReceipt(transaction, output, if (posterLease == null) "REVEAL" else "POSTER_REVEAL", begin)
                    if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.beforeRevealApply?.invoke(output)
                    if (output.isSealed() || !runCatching { stillAuthorized() }.getOrDefault(false)) {
                        val local = posterUse
                        if (local != null) finishPoster(local) else posterLease?.close()
                        runCatching { completed(false) }
                        return@post
                    }
                    applyEntered = true
                    transaction.apply()
                    applied = true
                    acceptedApply = runCatching { nativeApplied() }.getOrDefault(false)
                    if (capturing()) report(output, Receipt("REVEAL", begin, SystemClock.uptimeMillis()))
                } finally { runCatching { transaction.close() } }
            } catch (_: Throwable) {
                // A throwing apply has unknown transfer status. Keep the use
                // until the actual platform release; before apply it is local.
                if (!applyEntered) {
                    val local = posterUse
                    if (local != null) finishPoster(local) else posterLease?.close()
                }
                fail(output, "r18RevealFailed")
            }
            runCatching { completed(applied && acceptedApply) }
        }
        if (!accepted) { posterLease?.close(); runCatching { completed(false) } }
    }

    /** Swap the two siblings in one compositor transaction after the live
     * producer's first correctly phased frame has actually been posted. */
    fun promoteLive(output: KeyguardOrbDirectOutput, stillCurrent: () -> Boolean, completed: (Boolean) -> Unit) {
        val accepted = handler.post {
            var applied = false
            try {
                val poster = output.posterChild
                if (!output.isSealed() && output.child.isValid && poster != null && poster.isValid &&
                    output.posterBound && stillCurrent()) {
                    val transaction = SurfaceControl.Transaction()
                    try {
                        transaction.setVisibility(poster, false).setBuffer(poster, null as HardwareBuffer?)
                            .setVisibility(output.child, true).apply()
                        applied = true
                    } finally { transaction.close() }
                }
            } catch (_: Throwable) { fail(output, "r34LivePromotionFailed") }
            runCatching { completed(applied) }
        }
        if (!accepted) runCatching { completed(false) }
    }

    private fun releasePoster(use: PosterUse, fence: SyncFence?) {
        if (!use.receipt.compareAndSet(false, true)) { runCatching { fence?.close() }; return }
        if (fence == null || !fence.isValid) {
            runCatching { fence?.close() }
            finishPoster(use)
            return
        }
        use.unresolvedFence = fence
        runCatching {
            releaseWorker.execute {
                if (runCatching { fence.awaitForever() }.getOrDefault(false)) {
                    runCatching { fence.close() }
                    use.unresolvedFence = null
                    finishPoster(use)
                }
            }
        }
    }

    private fun finishPoster(use: PosterUse) {
        if (posterUses.remove(use)) use.lease.close()
        handler.post { maybeClose() }
    }

    /** Seal runs synchronously, before any post to Main, the render lane, or
     * this lane. The next task is the captured child's hide and unparent. */
    fun retire(output: KeyguardOrbDirectOutput, completed: (Boolean) -> Unit = {}) {
        if (!output.seal()) return
        val accepted = handler.postAtFrontOfQueue {
            val begin = SystemClock.uptimeMillis()
            var applied = false
            try {
                if (output.child.isValid || output.posterChild?.isValid == true) {
                    val transaction = SurfaceControl.Transaction()
                    try {
                        if (output.child.isValid) transaction.setVisibility(output.child, false).reparent(output.child, null)
                        output.posterChild?.takeIf { it.isValid }?.let { poster ->
                            transaction.setVisibility(poster, false).setBuffer(poster, null as HardwareBuffer?).reparent(poster, null)
                        }
                        attachReceipt(transaction, output, "RETIRE", begin)
                        transaction.apply()
                        applied = true
                        if (capturing()) report(output, Receipt("RETIRE", begin, SystemClock.uptimeMillis()))
                    } finally { runCatching { transaction.close() } }
                }
            } catch (_: Throwable) { /* failure is handled below */ }
            if (applied) {
                output.hideSettled = true
                drain(output)
            } else fail(output, "r18RetireFailedRemoveHost")
            runCatching { completed(applied) }
        }
        if (!accepted) fail(output, "r18RetireLaneClosedRemoveHost")
    }

    /** Invoke only after a failed native hide's original WMS host is gone. */
    fun hostRemovedAfterFailedHide(output: KeyguardOrbDirectOutput) {
        if (!output.isSealed()) return
        handler.post {
            output.hideSettled = true
            drain(output)
        }
    }

    private fun drain(output: KeyguardOrbDirectOutput) {
        if (output.disposeOnLane()) {
            liveOutputs.decrementAndGet()
            runCatching { onDrained(output) }
            maybeClose()
        }
    }

    private fun attachReceipt(transaction: SurfaceControl.Transaction, output: KeyguardOrbDirectOutput,
                              operation: String, begin: Long) {
        if (!capturing()) return
        // Diagnostic registration cannot prevent the real transaction.
        runCatching {
            transaction.addTransactionCommittedListener(diagnosticExecutor) {
                report(output, Receipt(operation, begin, null, committedUptimeMs = SystemClock.uptimeMillis()))
            }
        }
        runCatching {
            transaction.addTransactionCompletedListener(diagnosticExecutor) { stats ->
                var state = "UNOBSERVED"
                var signal: Long? = null
                val latch = runCatching { stats.latchTimeNanos }.getOrNull()?.takeIf { it > 0L }
                runCatching {
                    val fence = stats.presentFence
                    try {
                        if (fence.isValid) {
                            val time = fence.signalTime
                            when (time) {
                                SyncFence.SIGNAL_TIME_PENDING -> state = "PENDING"
                                SyncFence.SIGNAL_TIME_INVALID -> state = "INVALID"
                                else -> { state = "SIGNALED"; signal = time }
                            }
                        } else state = "INVALID"
                    } finally { fence.close() }
                }
                report(output, Receipt(operation, begin, null, latchNanos = latch,
                    presentSignalNanos = signal, presentState = state))
            }
        }
    }

    fun hasLiveOutputs(): Boolean = liveOutputs.get() > 0

    fun closeWhenDrained() {
        closeRequested.set(true)
        handler.post { maybeClose() }
    }

    private fun maybeClose() {
        if (closeRequested.get() && liveOutputs.get() == 0 && posterUses.isEmpty()) {
            thread.quitSafely()
            diagnostics.shutdown()
            releaseWorker.shutdown()
        }
    }
}
