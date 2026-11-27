package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Choreographer
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardShaderArtifact
import com.fluvi.app.lockscreen.material.SystemKeyguardMaterialTimeSource

/**
 * One accessibility-window frame adapted from Widgets Anywhere 4.7.5,
 * WidgetFrameDelegate.kt (window params, add/remove and 50 ms second check)
 * and SafeWindowManager.kt, commit 9c7fed25ec833197656dec57427be4c26fc66138.
 * Copyright 2020, 2023 Zachary Wander; see the packaged MIT notices.
 *
 * This class does not grant permission to show. Its caller must supply a
 * current, independently qualified owner and invalidate it on every relevant
 * restriction. The single Fluvi material View is not an AppWidgetHost.
 */
internal class KeyguardR448WidgetsAnywhereFrame(
    private val service: AccessibilityService,
    private val timeSource: KeyguardMaterialTimeSource = SystemKeyguardMaterialTimeSource,
) {
    internal data class Owner(val route: Long, val wake: Long, val material: Long)
    internal data class Event(val owner: Owner, val stage: String, val at: Long, val detail: String? = null)

    private val main = Handler(Looper.getMainLooper())
    private val wm = service.getSystemService(WindowManager::class.java)
    private var view: KeyguardHeaderMaterialView? = null
    private var viewOwner: Owner? = null
    private var pending: Runnable? = null
    private var frame: Choreographer.FrameCallback? = null
    private var attached = false
    private var removalFailed = false
    private var leaseLive = false
    private var validating = false
    private var showSequence = 0L
    private var r46PublicTelemetry = false
    private var r47Telemetry: String? = null
    private var r47Animated: Boolean? = null
    private var r47FramePlayback = false
    private val openingDelay = KeyguardR46OpeningDelay()
    private var event: ((Event) -> Unit)? = null

    fun isAttached(): Boolean = attached && leaseLive && view?.isAttachedToWindow == true
    fun hasOwnedWindow(): Boolean = attached && leaseLive
    fun isRetired(): Boolean = view == null && !attached && !removalFailed
    internal fun shaderDrawCountForInstrumentation(): Int = view?.diagnostics()?.shaderDrawCount ?: 0

    /** The inventory may exempt only the exact current overlay, never every
     * window with our package name. An unavailable ID remains unavailable. */
    fun ownIdentity(owner: Owner): KeyguardOwnOverlayIdentity? {
        check(Looper.myLooper() == Looper.getMainLooper())
        val current = view?.takeIf { viewOwner == owner && leaseLive && attached && it.isAttachedToWindow } ?: return null
        val display = current.display?.displayId ?: return null
        val node = current.createAccessibilityNodeInfo() ?: return null
        return try {
            node.windowId.takeIf { it >= 0 }?.let { KeyguardOwnOverlayIdentity(it, display, owner.material) }
        } finally { @Suppress("DEPRECATION") node.recycle() }
    }

    private fun emit(owner: Owner, stage: String, detail: String? = null) {
        runCatching { event?.invoke(Event(owner, stage, SystemClock.uptimeMillis(), detail)) }
    }

    internal fun measuredBoundsForInstrumentation(): Rect? {
        check(Looper.myLooper() == Looper.getMainLooper())
        val current = view?.takeIf { attached && it.isAttachedToWindow && it.width > 0 && it.height > 0 } ?: return null
        val point = IntArray(2)
        current.getLocationOnScreen(point)
        return Rect(point[0], point[1], point[0] + current.width, point[1] + current.height)
    }

    /** Changes only a detached prepared view's wake identity. It never carries
     * an old admission or transfers an attached surface to a new wake. */
    fun bindWake(prepared: Owner, next: Owner): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (view == null || !leaseLive || attached || removalFailed || pending != null || validating ||
            viewOwner != prepared || prepared.wake != 0L || next.wake <= 0 ||
            prepared.route != next.route || prepared.material != next.material) return false
        viewOwner = next
        openingDelay.reset()
        return true
    }

    /** Exact current View identity only; an unknown window remains unknown. */
    fun isOwnWindow(window: Int, display: Int): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        val current = view?.takeIf { leaseLive && attached && it.isAttachedToWindow } ?: return false
        if (window < 0 || current.display?.displayId != display) return false
        val node = current.createAccessibilityNodeInfo() ?: return false
        return try { node.windowId == window } finally { @Suppress("DEPRECATION") node.recycle() }
    }

    /** Preparation cannot display a frame or replace an unretired window. */
    fun preparePublic(owner: Owner, sample: KeyguardR46PublicMaterial,
                      artifact: KeyguardShaderArtifact, diagnosticCircle: Boolean,
                      observer: (Event) -> Unit): Boolean {
        val prepared = prepareScene(owner, sample.sceneProfile(), false, artifact, diagnosticCircle, observer)
        r46PublicTelemetry = prepared
        return prepared
    }

    /** Private header data does not pass through the public sample API. */
    fun prepareActiveHeader(owner: Owner, material: FluviActiveHeaderMaterialStore.Snapshot,
                            artifact: KeyguardShaderArtifact, observer: (Event) -> Unit): Boolean {
        val prepared = prepareScene(owner, material.profile, true, artifact, false, observer, material.receivedAtNanos,
            freezeClock = !material.motionEnabled)
        if (prepared) {
            r47Animated = material.motionEnabled && material.profile.animated
            r47FramePlayback = view?.setActiveHeaderFrames(material) == true
            val origin = if (r47FramePlayback) "active_header_frame_package" else "active_header_semantic"
            val playback = if (r47FramePlayback) "verified_frames" else "shader"
            val interval = material.preparedFrames?.takeIf { r47FramePlayback }?.intervalMs
            r47Telemetry = "origin=$origin token=${material.correlation} " +
                "sourceRevision=${material.profile.publisherRevision} animated=$r47Animated playback=$playback " +
                "frameStatus=${material.frameStatus} intervalMs=${interval ?: "UNOBSERVED"}"
        }
        return prepared
    }

    internal fun prepareForInstrumentation(owner: Owner, profile: KeyguardMaterialProfile, full: Boolean,
                artifact: KeyguardShaderArtifact, observer: (Event) -> Unit): Boolean =
        prepareScene(owner, profile, full, artifact, false, observer)

    private fun prepareScene(owner: Owner, profile: KeyguardMaterialProfile, full: Boolean,
                artifact: KeyguardShaderArtifact, diagnosticCircle: Boolean,
                observer: (Event) -> Unit, anchorNanos: Long = System.nanoTime(), freezeClock: Boolean = false): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (view != null || attached || removalFailed) return false
        return runCatching {
            val source = if (freezeClock) KeyguardMaterialTimeSource { scene, _ -> scene.timeAt(scene.appliedAtNanos) }
                else timeSource
            val material = KeyguardHeaderMaterialView(service, materialTimeSource = source).apply {
                isClickable = false
                isFocusable = false
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                alpha = 1f
                setScene(KeyguardMaterialScene(profile, full, anchorNanos), enabled = true)
                setBootstrapActive(false)
                setR45DiagnosticCircle(diagnosticCircle)
                check(installPreparedShader(artifact) in setOf(
                    KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED,
                    KeyguardHeaderMaterialView.ProgramPreparationResult.REUSED))
            }
            view = material
            viewOwner = owner
            leaseLive = true
            event = observer
            emit(owner, "PREPARED")
            true
        }.getOrElse { view = null; viewOwner = null; leaseLive = false; event = null; false }
    }

    /** Equivalent eligible requests do not restart upstream's 50 ms delay. */
    fun requestShow(owner: Owner, geometry: KeyguardOverlayGeometry,
                    valid: () -> Boolean): Boolean = requestShowChecked(owner, geometry, valid, null)

    fun requestShowChecked(owner: Owner, geometry: KeyguardOverlayGeometry,
                           valid: () -> Boolean,
                           validateAsync: (((Boolean) -> Unit) -> Unit)?): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        val material = view ?: return false
        if (viewOwner != owner || !leaseLive || attached || removalFailed || wm == null ||
            geometry.width <= 0 || geometry.height <= 0) return false
        if (pending != null || validating) { emit(owner, "COALESCED"); return true }
        if (!runCatching(valid).getOrDefault(false)) { emit(owner, "DENIED_FIRST_CHECK"); return false }
        emit(owner, "FIRST_CHECK_ALLOWED")
        val delay = openingDelay.allow(SystemClock.uptimeMillis())
        val sequence = ++showSequence
        val task = Runnable {
            pending = null
            emit(owner, "DEBOUNCE_FIRED")
            if (view !== material || viewOwner != owner || !leaseLive || attached || removalFailed ||
                (validateAsync == null && !runCatching(valid).getOrDefault(false))) {
                emit(owner, "DENIED_SECOND_CHECK")
                return@Runnable
            }
            fun beginAdd(confirmed: Boolean) {
            if (view !== material || viewOwner != owner || showSequence != sequence) return
            validating = false
            if (!confirmed || !runCatching(valid).getOrDefault(false)) {
                conceal(owner, "PRE_ADD_UNVERIFIED")
                emit(owner, "PRE_ADD_UNVERIFIED")
                return
            }
            if (view !== material || viewOwner != owner || !leaseLive || attached || removalFailed) {
                emit(owner, "DENIED_SECOND_CHECK")
                return
            }
            emit(owner, "SECOND_CHECK_ALLOWED")
            @Suppress("DEPRECATION")
            val params = WindowManager.LayoutParams(
                geometry.width, geometry.height,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.RGBA_8888,
            ).apply { gravity = Gravity.TOP or Gravity.START; x = geometry.left; y = geometry.top }
            // For asynchronous revalidation the newly added view stays
            // hidden until the current post-add system check completes.
            material.visibility = if (validateAsync == null) View.VISIBLE else View.INVISIBLE
            material.alpha = if (validateAsync == null) 1f else 0f
            val contentDraw: (Long) -> Unit = { at ->
                if (view === material && viewOwner == owner && leaseLive && attached) {
                    runCatching { event?.invoke(Event(owner,
                        if (r47FramePlayback) "FIRST_FRAME_DRAW" else "FIRST_SHADER_DRAW", at)) }
                }
            }
            if (r47FramePlayback) material.onNextPreparedFrameDrawForDiagnostic = contentDraw
            else material.onNextShaderDrawForDiagnostic = contentDraw
            material.onNextDrawForDiagnostic = { at ->
                if (view === material && viewOwner == owner && leaseLive && attached && material.visibility == View.VISIBLE)
                    runCatching { event?.invoke(Event(owner, "FIRST_DRAW", at)) }
            }
            material.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    if (view === material && viewOwner == owner && leaseLive)
                        emit(owner, "ATTACHED", "visibility=${v.visibility},alpha=${v.alpha}")
                }
                override fun onViewDetachedFromWindow(v: View) {
                    v.removeOnAttachStateChangeListener(this)
                    emit(owner, "DETACHED")
                }
            })
            emit(owner, "ADD_BEGIN", "type=${params.type},flags=${params.flags},bounds=${geometry.left},${geometry.top},${geometry.width},${geometry.height}")
            try {
                // Treat an in-flight add as potentially transferred until
                // exact-view removal proves otherwise.
                attached = true
                wm.addView(material, params)
                emit(owner, "ADD_RETURN")
                // A concurrent ingress may already have concealed this exact
                // owner and started a fresh read. The old add callback must
                // not retire that suspended owner or reveal it.
                if (showSequence != sequence) return
                if (viewOwner != owner || !runCatching(valid).getOrDefault(false)) {
                    retire(owner, "POST_ADD_REVOKED")
                    return
                }
                fun beginFrames(confirmedAfterAdd: Boolean) {
                if (view !== material || viewOwner != owner || showSequence != sequence) return
                validating = false
                emit(owner, "POST_ADD_CHECK_RESULT", confirmedAfterAdd.toString())
                if (!confirmedAfterAdd || view !== material || viewOwner != owner || !leaseLive || !attached ||
                    !runCatching(valid).getOrDefault(false)) {
                    if (view === material && viewOwner == owner && leaseLive) {
                        conceal(owner, "POST_ADD_UNVERIFIED")
                        emit(owner, "POST_ADD_UNVERIFIED")
                    }
                    return
                }
                reveal(owner, material, valid)
                }
                if (validateAsync == null) beginFrames(true) else {
                    validating = true
                    emit(owner, "POST_ADD_CHECK_BEGIN")
                    try { validateAsync { allowed -> main.post { beginFrames(allowed) } } }
                    catch (_: Exception) { beginFrames(false) }
                }
            } catch (failure: Exception) {
                // An exception cannot imply that WindowManager did not retain
                // the view. Attempt exact-view cleanup and block reuse on error.
                emit(owner, "ADD_FAILED", failure.javaClass.simpleName.take(48))
                retire(owner, "ADD_FAILED")
            }
            }
            if (validateAsync == null) beginAdd(true) else {
                validating = true
                try { validateAsync { allowed -> main.post { beginAdd(allowed) } } }
                catch (_: Exception) { beginAdd(false) }
            }
        }
        pending = task
        emit(owner, "DEBOUNCE_SCHEDULED", "due=${openingDelay.dueAt},delay=$delay")
        if (!main.postDelayed(task, delay)) {
            pending = null
            emit(owner, "DEBOUNCE_POST_FAILED")
            return false
        }
        return true
    }

    private fun reveal(owner: Owner, material: KeyguardHeaderMaterialView, valid: () -> Boolean) {
        if (r46PublicTelemetry) material.beginR46SampleInterval()
        else r47Telemetry?.let { material.beginR46SampleInterval(it) }
        material.visibility = View.VISIBLE
        material.alpha = 1f
        emit(owner, "REVEAL", "visibility=${material.visibility},alpha=${material.alpha}")
        if (r47Animated == false) {
            material.frame(System.nanoTime())
            return
        }
        val callback = object : Choreographer.FrameCallback {
            override fun doFrame(frameTimeNanos: Long) {
                if (view !== material || viewOwner != owner || !leaseLive || !attached ||
                    material.visibility != View.VISIBLE) return
                if (!runCatching(valid).getOrDefault(false)) {
                    conceal(owner, "OWNER_REVOKED")
                    return
                }
                material.frame(frameTimeNanos)
                Choreographer.getInstance().postFrameCallback(this)
            }
        }
        frame = callback
        material.frame(System.nanoTime())
        Choreographer.getInstance().postFrameCallback(callback)
    }

    /** Conceal synchronously on an ambiguous change, while retaining this
     * exact attached owner for a bounded, fresh revalidation. */
    fun conceal(owner: Owner, reason: String): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        val material = view ?: return false
        if (viewOwner != owner || !leaseLive || removalFailed) return false
        // Already-hidden duplicate notifications do not alter the retained
        // first deadline. They still leave the view without display authority.
        if (pending == null && !validating && frame == null &&
            (!attached || (material.visibility == View.INVISIBLE && material.alpha == 0f))) return true
        showSequence++
        pending?.let { main.removeCallbacks(it); emit(owner, "DEBOUNCE_CANCELED") }
        pending = null
        validating = false
        frame?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frame = null
        material.visibility = View.INVISIBLE
        material.alpha = 0f
        material.endR46SampleInterval()?.let { emit(owner, "MOTION", it) }
        emit(owner, "CONCEAL", reason)
        return true
    }

    /** A concealed attached view can be exposed only after a fresh, current
     * system check; a late completion cannot revive a replaced owner. */
    fun resumeChecked(owner: Owner, valid: () -> Boolean,
                      validateAsync: (((Boolean) -> Unit) -> Unit)): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        val material = view ?: return false
        if (viewOwner != owner || !leaseLive || !attached || removalFailed || validating) return false
        val sequence = ++showSequence
        validating = true
        emit(owner, "RESUME_CHECK_BEGIN")
        try {
            validateAsync { allowed -> main.post {
                if (view !== material || viewOwner != owner || showSequence != sequence) return@post
                validating = false
                emit(owner, "RESUME_CHECK_RESULT", allowed.toString())
                if (allowed && leaseLive && attached && !removalFailed && runCatching(valid).getOrDefault(false))
                    reveal(owner, material, valid)
                else emit(owner, "RESUME_UNVERIFIED")
            } }
        } catch (_: Exception) {
            validating = false
            emit(owner, "RESUME_CHECK_RESULT", "exception")
            emit(owner, "RESUME_UNVERIFIED")
        }
        return true
    }

    /** A new restriction revision may require a fresh read before an add.
     * Keep the detached prepared material, but revoke every old callback. */
    fun cancelPending(owner: Owner): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (viewOwner != owner || attached || removalFailed || !leaseLive) return false
        showSequence++
        pending?.let { main.removeCallbacks(it); emit(owner, "DEBOUNCE_CANCELED") }
        pending = null
        validating = false
        return true
    }

    /** Invalidates callbacks first, then hides and removes the captured View.
     * A failed removal retains ownership and blocks a successor. */
    fun retire(owner: Owner, reason: String): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (viewOwner != owner) return false
        leaseLive = false
        openingDelay.reset()
        showSequence++
        validating = false
        pending?.let { main.removeCallbacks(it); emit(owner, "DEBOUNCE_CANCELED") }
        pending = null
        frame?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frame = null
        val old = view ?: return false
        old.onNextShaderDrawForDiagnostic = null
        old.onNextPreparedFrameDrawForDiagnostic = null
        old.onNextDrawForDiagnostic = null
        old.visibility = View.INVISIBLE
        old.alpha = 0f
        old.endR46SampleInterval()?.let { emit(owner, "MOTION", it) }
        emit(owner, "HIDE", reason)
        if (attached || old.isAttachedToWindow || removalFailed) {
            try {
                wm?.removeViewImmediate(old) ?: error("WindowManager unavailable")
                attached = false
                removalFailed = false
                emit(owner, "REMOVE_RETURN", reason)
            } catch (failure: Exception) {
                removalFailed = true
                emit(owner, "REMOVE_FAILED", failure.javaClass.simpleName.take(48))
                return false
            }
        }
        view = null
        r46PublicTelemetry = false
        r47Telemetry = null
        r47Animated = null
        r47FramePlayback = false
        viewOwner = null
        event = null
        return true
    }
}
