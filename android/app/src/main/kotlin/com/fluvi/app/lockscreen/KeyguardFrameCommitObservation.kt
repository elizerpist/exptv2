package com.fluvi.app.lockscreen

import android.os.Build
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver
import com.fluvi.app.lockscreen.material.KeyguardBootstrapFrameToken

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
    val bootstrapToken: KeyguardBootstrapFrameToken,
    val observedAtUptimeMs: Long,
)

internal class KeyguardFrameCommitObservation(
    private val root: View,
    private val attachGeneration: Long,
    private val bootstrapToken: KeyguardBootstrapFrameToken,
    private val nowUptimeMs: () -> Long = SystemClock::uptimeMillis,
    private val onCommitted: (KeyguardFrameCommitEvent) -> Unit,
) {
    /** `armed` survives the short interval between addView() and Android's
     * attach dispatch.  In particular, addView returning does not guarantee
     * that root.isAttachedToWindow is already true on every overlay host. */
    private var armed = false
    private var frameCallbackRegistered = false
    private var frameCommitReceived = false
    private var committed = false
    private var cancelled = false
    private var expectedDrawObserved = false
    private var preDrawListener: ViewTreeObserver.OnPreDrawListener? = null
    private var preDrawObserver: ViewTreeObserver? = null
    private var attachStateListener: View.OnAttachStateChangeListener? = null

    /**
     * Arms the matching bootstrap frame before an addView traversal.  A
     * detached root retains this request and installs the real pre-draw
     * listener from its attach callback.  There is no timer or later
     * accessibility event involved in this handoff.
     */
    fun startBeforeNextDraw() {
        if (cancelled || committed || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        armed = true
        ensureAttachListener()
        if (root.isAttachedToWindow) installPreDrawListener()
    }

    fun matches(
        expectedRoot: View,
        expectedAttachGeneration: Long,
        expectedBootstrapToken: KeyguardBootstrapFrameToken,
    ): Boolean =
        root === expectedRoot &&
            attachGeneration == expectedAttachGeneration &&
            bootstrapToken == expectedBootstrapToken &&
            !cancelled

    /** Called from the matching bootstrap View draw after non-empty geometry
     * was issued.  It is deliberately independent of the one-shot diagnostic
     * first-bootstrap callback: an early diagnostic milestone must not consume
     * the functional acknowledgement needed for LIVE promotion. */
    fun markExpectedDrawObserved(
        expectedAttachGeneration: Long,
        expectedBootstrapToken: KeyguardBootstrapFrameToken,
    ) {
        if (cancelled || committed ||
            attachGeneration != expectedAttachGeneration ||
            bootstrapToken != expectedBootstrapToken
        ) return
        expectedDrawObserved = true
        publishIfReady()
    }

    fun cancel() {
        if (cancelled) return
        cancelled = true
        attachStateListener?.let(root::removeOnAttachStateChangeListener)
        attachStateListener = null
        preDrawListener?.let(::removePreDrawListener)
        preDrawListener = null
        preDrawObserver = null
    }

    private fun ensureAttachListener() {
        if (attachStateListener != null || cancelled) return
        attachStateListener = object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(view: View) {
                if (view !== root || cancelled || !armed) return
                installPreDrawListener()
                // If addView's first invalidation was coalesced before the
                // listener was installed, request the bootstrap traversal
                // explicitly. This leaves layout, geometry and visibility
                // untouched.
                root.invalidate()
            }

            override fun onViewDetachedFromWindow(view: View) {
                if (view === root) cancel()
            }
        }.also(root::addOnAttachStateChangeListener)
    }

    /** Register from pre-draw, before Canvas.onDraw for the intended bootstrap
     * traversal. The listener removal is posted so no listener collection is
     * modified during that traversal. */
    private fun installPreDrawListener() {
        if (!armed || cancelled || committed || frameCallbackRegistered || preDrawListener != null ||
            !root.isAttachedToWindow
        ) return
        val observer = root.viewTreeObserver
        if (!observer.isAlive) return
        lateinit var listener: ViewTreeObserver.OnPreDrawListener
        listener = object : ViewTreeObserver.OnPreDrawListener {
            override fun onPreDraw(): Boolean {
                if (cancelled || committed || frameCallbackRegistered || !root.isAttachedToWindow) return true
                frameCallbackRegistered = true
                val active = root.viewTreeObserver
                if (active.isAlive) {
                    active.registerFrameCommitCallback callback@{
                        if (cancelled || committed || !root.isAttachedToWindow) return@callback
                        frameCommitReceived = true
                        publishIfReady()
                    }
                }
                // Unlike OnDraw removal, pre-draw cleanup is posted so it
                // cannot perturb this traversal's listener collection.
                root.post { removePreDrawListener(listener) }
                return true
            }
        }
        preDrawListener = listener
        preDrawObserver = observer
        observer.addOnPreDrawListener(listener)
    }

    /** A renderer commit and a functional bootstrap draw acknowledgement may
     * arrive in either order. Hold the first until both are true instead of
     * silently losing the one-shot acknowledgement. */
    private fun publishIfReady() {
        if (cancelled || committed || !frameCommitReceived || !expectedDrawObserved ||
            !root.isAttachedToWindow
        ) return
        committed = true
        attachStateListener?.let(root::removeOnAttachStateChangeListener)
        attachStateListener = null
        preDrawListener?.let(::removePreDrawListener)
        preDrawListener = null
        preDrawObserver = null
        onCommitted(
            KeyguardFrameCommitEvent(
                attachGeneration = attachGeneration,
                bootstrapToken = bootstrapToken,
                observedAtUptimeMs = nowUptimeMs(),
            ),
        )
    }

    private fun removePreDrawListener(listener: ViewTreeObserver.OnPreDrawListener) {
        val observer = preDrawObserver
        if (observer?.isAlive == true) observer.removeOnPreDrawListener(listener)
        else {
            val currentObserver = root.viewTreeObserver
            if (currentObserver.isAlive) currentObserver.removeOnPreDrawListener(listener)
        }
        if (preDrawListener === listener) preDrawListener = null
        if (preDrawObserver === observer) preDrawObserver = null
    }
}
