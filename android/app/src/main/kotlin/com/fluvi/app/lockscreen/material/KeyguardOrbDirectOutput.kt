package com.fluvi.app.lockscreen.material

import android.annotation.TargetApi
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.SyncFence
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.view.Surface
import android.view.SurfaceControl
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/** A single hidden, unparented buffer producer. Borrowers retain this exact
 * surface until they return; neither elapsed time nor a transaction callback
 * is a buffer-release receipt. */
@TargetApi(35)
internal class KeyguardOrbDirectOutput private constructor(
    val attachment: Long,
    val generation: Long,
    val child: SurfaceControl,
    private val surface: Surface,
    private val lifetime: KeyguardOrbOutputLifetime,
    private val scheduleDrain: (KeyguardOrbDirectOutput) -> Unit,
) {
    @Volatile internal var hideSettled = false
    @Volatile internal var disposed = false
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
                return KeyguardOrbDirectOutput(attachment, generation, child, created, KeyguardOrbOutputLifetime(), scheduleDrain)
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
             x: Float, y: Float, width: Int, height: Int,
             stillCurrent: () -> Boolean, completed: (Boolean) -> Unit) {
        val accepted = handler.post {
            var applied = false
            try {
                if (!output.isSealed() && output.child.isValid && stillCurrent()) {
                    transaction.setPosition(output.child, x, y)
                        .setCrop(output.child, Rect(0, 0, width, height))
                        .setLayer(output.child, Int.MAX_VALUE)
                        .setVisibility(output.child, false).apply()
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
               crossGrantBoundary: () -> Boolean, completed: (Boolean) -> Unit) {
        val accepted = handler.post {
            if (output.isSealed() || !output.child.isValid || !runCatching { crossGrantBoundary() }.getOrDefault(false)) {
                runCatching { completed(false) }
                return@post
            }
            val begin = SystemClock.uptimeMillis()
            var applied = false
            try {
                val transaction = SurfaceControl.Transaction()
                try {
                    transaction.setVisibility(output.child, true)
                    attachReceipt(transaction, output, "REVEAL", begin)
                    transaction.apply()
                    applied = true
                    if (capturing()) report(output, Receipt("REVEAL", begin, SystemClock.uptimeMillis()))
                } finally { runCatching { transaction.close() } }
            } catch (_: Throwable) {
                fail(output, "r18RevealFailed")
            }
            runCatching { completed(applied) }
        }
        if (!accepted) runCatching { completed(false) }
    }

    /** Seal runs synchronously, before any post to Main, the render lane, or
     * this lane. The next task is the captured child's hide and unparent. */
    fun retire(output: KeyguardOrbDirectOutput, completed: (Boolean) -> Unit = {}) {
        if (!output.seal()) return
        val accepted = handler.postAtFrontOfQueue {
            val begin = SystemClock.uptimeMillis()
            var applied = false
            try {
                if (output.child.isValid) {
                    val transaction = SurfaceControl.Transaction()
                    try {
                        transaction.setVisibility(output.child, false).reparent(output.child, null)
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
        if (closeRequested.get() && liveOutputs.get() == 0) {
            thread.quitSafely()
            diagnostics.shutdown()
        }
    }
}
