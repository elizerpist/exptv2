package com.fluvi.app.lockscreen

import android.os.Build
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver

/**
 * A one-shot observation of Android's frame-commit callback for an already
 * attached overlay.  It is deliberately not a presentation claim: the
 * callback is delivered after renderer commit through ViewRoot's handler and
 * does not say when a physical panel displayed the frame.
 *
 * Registration happens from pre-draw, before the bootstrap traversal enters
 * Canvas.onDraw. Android exposes no frame-commit unregister API; cancellation
 * revokes publication ownership for a detached/replaced root.
 */
internal data class KeyguardFrameCommitEvent(
    val attachGeneration: Long,
    val observedAtUptimeMs: Long,
)

internal class KeyguardFrameCommitObservation(
    private val root: View,
    private val attachGeneration: Long,
    private val nowUptimeMs: () -> Long = SystemClock::uptimeMillis,
    private val onCommitted: (KeyguardFrameCommitEvent) -> Unit,
) {
    private var registered = false
    private var cancelled = false
    private var expectedDrawObserved = false
    private var preDrawListener: ViewTreeObserver.OnPreDrawListener? = null

    /** Register before the intended traversal. The one-shot pre-draw listener
     * posts its own removal so listener mutation never happens during draw. */
    fun startBeforeNextDraw() {
        if (registered || cancelled || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val observer = root.viewTreeObserver
        if (!observer.isAlive || !root.isAttachedToWindow) return
        lateinit var listener: ViewTreeObserver.OnPreDrawListener
        listener = object : ViewTreeObserver.OnPreDrawListener {
            override fun onPreDraw(): Boolean {
                if (cancelled || registered || !root.isAttachedToWindow) return true
                registered = true
                val active = root.viewTreeObserver
                if (active.isAlive) {
                    active.registerFrameCommitCallback callback@{
                        if (cancelled || !root.isAttachedToWindow || !expectedDrawObserved) return@callback
                        onCommitted(
                            KeyguardFrameCommitEvent(
                                attachGeneration = attachGeneration,
                                observedAtUptimeMs = nowUptimeMs(),
                            ),
                        )
                    }
                }
                // Unlike OnDraw removal, pre-draw cleanup is posted so it
                // cannot perturb this traversal's listener collection.
                root.post { removePreDrawListener(listener) }
                return true
            }
        }
        preDrawListener = listener
        observer.addOnPreDrawListener(listener)
    }

    /** Called from the matching bootstrap View draw after non-empty geometry
     * was issued. It performs no listener mutation or diagnostics. */
    fun markExpectedDrawObserved() {
        if (!cancelled && registered) expectedDrawObserved = true
    }

    fun cancel() {
        cancelled = true
        preDrawListener?.let(::removePreDrawListener)
        preDrawListener = null
    }

    private fun removePreDrawListener(listener: ViewTreeObserver.OnPreDrawListener) {
        val observer = root.viewTreeObserver
        if (observer.isAlive) observer.removeOnPreDrawListener(listener)
        if (preDrawListener === listener) preDrawListener = null
    }
}
