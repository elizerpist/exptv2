package com.fluvi.app.lockscreen

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.Build
import android.view.View
import android.view.ViewTreeObserver

/** One cold root observation, registered before addView. Its asynchronous
 * events retain the operation captured by the caller and never affect UI. */
internal class KeyguardColdRootObservation(
    private val root: View,
    private val publish: (String, Long, Map<String, Any?>) -> Unit,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var cancelled = false
    private var attached = false
    private var laidOut = false
    private val attachListener = object : View.OnAttachStateChangeListener {
        override fun onViewAttachedToWindow(v: View) {
            if (cancelled || attached) return
            attached = true
            val at = SystemClock.uptimeMillis()
            handler.post { publish("R10_ROOT_ATTACH_DISPATCH", at, emptyMap()) }
            root.removeOnAttachStateChangeListener(this)
        }
        override fun onViewDetachedFromWindow(v: View) = Unit
    }
    private val layoutListener = object : View.OnLayoutChangeListener {
        override fun onLayoutChange(v: View, left: Int, top: Int, right: Int, bottom: Int,
                                    oldLeft: Int, oldTop: Int, oldRight: Int, oldBottom: Int) {
            if (cancelled || laidOut || right <= left || bottom <= top) return
            laidOut = true
            val at = SystemClock.uptimeMillis()
            val width = right - left
            val height = bottom - top
            handler.post { publish("R10_ROOT_FIRST_LAYOUT", at, mapOf("r10RootSize" to "${width}x$height")) }
            root.removeOnLayoutChangeListener(this)
        }
    }

    fun start() {
        val alreadyAttached = root.isAttachedToWindow
        publish("R10_ROOT_REGISTRATION", SystemClock.uptimeMillis(),
            mapOf("r10AttachState" to if (alreadyAttached) "alreadyAttached" else "pending"))
        if (!alreadyAttached) root.addOnAttachStateChangeListener(attachListener)
        root.addOnLayoutChangeListener(layoutListener)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Handler.createAsync(Looper.getMainLooper()).post {
                if (!cancelled) publish("R10_MAIN_ASYNC_READY", SystemClock.uptimeMillis(), emptyMap())
            }
        }
    }

    fun cancel() {
        cancelled = true
        root.removeOnAttachStateChangeListener(attachListener)
        root.removeOnLayoutChangeListener(layoutListener)
    }
}

/** The immutable identity of one draw observation.  It lets the service reject
 * a late diagnostic from an older retained-root attach without treating the
 * current wake timing as its owner. */
internal data class KeyguardFirstDrawEvent(
    val attachGeneration: Long,
    val observedAtUptimeMs: Long,
    val rootWidth: Int = 0,
    val rootHeight: Int = 0,
    val targetWidth: Int = 0,
    val targetHeight: Int = 0,
    val attachStateAtRegistration: String = "UNOBSERVED",
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
    private val onPreDraw: ((KeyguardFirstDrawEvent) -> Unit)? = null,
    private val targetSize: (() -> Pair<Int, Int>)? = null,
    private val onFirstDraw: (KeyguardFirstDrawEvent) -> Unit,
) {
    private var registrationObserver: ViewTreeObserver? = null
    private var listener: ViewTreeObserver.OnDrawListener? = null
    private var preDrawListener: ViewTreeObserver.OnPreDrawListener? = null
    private var preDrawFired = false
    private var attachStateAtRegistration = "UNOBSERVED"
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
        if (onPreDraw != null) {
            attachStateAtRegistration = if (root.isAttachedToWindow) "alreadyAttached" else "pending"
            val beforeDraw = ViewTreeObserver.OnPreDrawListener {
                if (!closed && !cancelled && !preDrawFired) {
                    preDrawFired = true
                    val size = targetSize?.invoke()
                    val event = KeyguardFirstDrawEvent(attachGeneration, nowUptimeMs(), root.width, root.height,
                        size?.first ?: 0, size?.second ?: 0, attachStateAtRegistration)
                    mainHandler.post { if (!cancelled) onPreDraw.invoke(event) }
                }
                true
            }
            preDrawListener = beforeDraw
            observer.addOnPreDrawListener(beforeDraw)
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
        if (registered?.isAlive == true) {
            registered.removeOnDrawListener(ownListener)
            preDrawListener?.let(registered::removeOnPreDrawListener)
        }
        val current = root.viewTreeObserver
        if (current !== registered && current.isAlive) {
            current.removeOnDrawListener(ownListener)
            preDrawListener?.let(current::removeOnPreDrawListener)
        }
        preDrawListener = null
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
    val identity: KeyguardDrawIdentity get() = KeyguardDrawIdentity(session, wakeGeneration, attachGeneration)

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
