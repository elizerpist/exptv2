package com.fluvi.app.lockscreen

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.view.ViewTreeObserver

/** The immutable identity of one draw observation.  It lets the service reject
 * a late diagnostic from an older retained-root attach without treating the
 * current wake timing as its owner. */
internal data class KeyguardFirstDrawEvent(
    val attachGeneration: Long,
    val observedAtUptimeMs: Long,
)

/**
 * Observes exactly one ViewTreeObserver draw without mutating its listener
 * collection during draw dispatch.  Android forbids removeOnDrawListener from
 * OnDrawListener.onDraw(), so onDraw only captures the monotonic timestamp and
 * posts cleanup/publication to the main queue.
 *
 * This is deliberately a small window-owned object rather than a global draw
 * framework.  Each attachment creates one instance; cancellation only ever
 * removes this instance's listener.
 */
internal class KeyguardFirstDrawObservation(
    private val root: View,
    private val attachGeneration: Long,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
    private val nowUptimeMs: () -> Long = SystemClock::uptimeMillis,
    private val postToMain: ((Runnable) -> Unit)? = null,
    private val onFirstDraw: (KeyguardFirstDrawEvent) -> Unit,
) {
    private var registrationObserver: ViewTreeObserver? = null
    private var listener: ViewTreeObserver.OnDrawListener? = null
    private var fired = false
    private var cancelled = false
    private var cleanupPosted = false
    private var closed = false

    /** Register while the retained root is attached. No draw observation is
     * valid when the current observer is already dead. */
    fun start() {
        checkMainThread()
        if (closed || listener != null) return
        val observer = root.viewTreeObserver
        if (!observer.isAlive) {
            closed = true
            return
        }
        val registeredListener = object : ViewTreeObserver.OnDrawListener {
            override fun onDraw() {
                // Do not remove or add a listener here. ViewTreeObserver
                // rejects listener-list mutations while dispatchOnDraw runs.
                if (closed || cancelled || fired) return
                fired = true
                postCleanupAndPublication(
                    KeyguardFirstDrawEvent(
                        attachGeneration = attachGeneration,
                        observedAtUptimeMs = nowUptimeMs(),
                    ),
                )
            }
        }
        registrationObserver = observer
        listener = registeredListener
        observer.addOnDrawListener(registeredListener)
    }

    /** Invalidates publication immediately. Actual listener cleanup remains
     * posted so it is safe even when a terminal lifecycle signal is delivered
     * adjacent to a framework draw traversal. */
    fun cancel() {
        checkMainThread()
        if (closed && listener == null) return
        cancelled = true
        postCleanupAndPublication(null)
    }

    private fun postCleanupAndPublication(event: KeyguardFirstDrawEvent?) {
        if (cleanupPosted) return
        cleanupPosted = true
        val cleanup = Runnable {
            cleanupPosted = false
            // Cleanup must precede the stale/publication decision. A late
            // observation still owns a listener that has to be removed.
            removeOwnListener()
            closed = true
            if (!cancelled && event != null) onFirstDraw(event)
        }
        val post = postToMain
        if (post != null) post(cleanup) else mainHandler.post(cleanup)
    }

    /** The root may have received a new ViewTreeObserver after a detach and
     * reattach. The old observer owns the registration, but checking the
     * replacement too safely covers framework observer hand-off behavior. */
    private fun removeOwnListener() {
        val ownListener = listener ?: return
        val registered = registrationObserver
        if (registered?.isAlive == true) registered.removeOnDrawListener(ownListener)
        val current = root.viewTreeObserver
        if (current !== registered && current.isAlive) current.removeOnDrawListener(ownListener)
        listener = null
        registrationObserver = null
    }

    private fun checkMainThread() {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "KeyguardFirstDrawObservation must run on the main thread"
        }
    }
}

/** Captures the service state that owned an attach, rather than looking only
 * at whichever wake happens to be current when deferred draw work runs. */
internal data class KeyguardFirstDrawOwner(
    val session: Long,
    val wakeGeneration: Long,
    val attachGeneration: Long,
    val diagnosticOperation: KeyguardDiagnosticOperation? = null,
) {
    fun accepts(
        event: KeyguardFirstDrawEvent,
        currentSession: Long,
        currentWakeGeneration: Long,
        currentAttachGeneration: Long,
    ): Boolean =
        event.attachGeneration == attachGeneration &&
            session == currentSession &&
            wakeGeneration == currentWakeGeneration &&
            attachGeneration == currentAttachGeneration
}
