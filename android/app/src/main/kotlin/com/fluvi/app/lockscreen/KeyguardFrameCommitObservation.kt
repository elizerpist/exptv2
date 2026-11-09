package com.fluvi.app.lockscreen

import android.os.Build
import android.os.SystemClock
import android.view.View

/**
 * A one-shot observation of Android's frame-commit callback for an already
 * attached overlay.  It is deliberately not a presentation claim: the
 * callback is delivered after renderer commit through ViewRoot's handler and
 * does not say when a physical panel displayed the frame.
 *
 * Registration happens from the current-material shader draw stack, so the
 * requested commit belongs to that draw.  Android exposes no unregister API;
 * cancellation only revokes publication ownership for a detached/replaced
 * root.
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

    /** Must be called while the current material is being drawn for this
     * attachment.  Older Android versions intentionally leave the endpoint
     * unobserved rather than inventing an equivalent timestamp. */
    fun registerFromCurrentMaterialDraw() {
        if (registered || cancelled || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val observer = root.viewTreeObserver
        if (!observer.isAlive || !root.isAttachedToWindow) return
        registered = true
        observer.registerFrameCommitCallback callback@{
            if (cancelled || !root.isAttachedToWindow) return@callback
            onCommitted(
                KeyguardFrameCommitEvent(
                    attachGeneration = attachGeneration,
                    observedAtUptimeMs = nowUptimeMs(),
                ),
            )
        }
    }

    fun cancel() {
        cancelled = true
    }
}
