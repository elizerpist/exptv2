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
    private var event: ((Event) -> Unit)? = null

    fun isAttached(): Boolean = attached && leaseLive && view?.isAttachedToWindow == true
    fun isRetired(): Boolean = view == null && !attached && !removalFailed

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
    fun prepare(owner: Owner, profile: KeyguardMaterialProfile, full: Boolean,
                artifact: KeyguardShaderArtifact, observer: (Event) -> Unit): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (view != null || attached || removalFailed) return false
        return runCatching {
            val material = KeyguardHeaderMaterialView(service, materialTimeSource = timeSource).apply {
                isClickable = false
                isFocusable = false
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                alpha = 1f
                setScene(KeyguardMaterialScene(profile, full, System.nanoTime()), enabled = true)
                setBootstrapActive(false)
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
        val sequence = ++showSequence
        val task = Runnable {
            pending = null
            emit(owner, "DEBOUNCE_FIRED")
            if (view !== material || viewOwner != owner || !leaseLive || attached || removalFailed ||
                !runCatching(valid).getOrDefault(false)) {
                emit(owner, "DENIED_SECOND_CHECK")
                return@Runnable
            }
            fun beginAdd(confirmed: Boolean) {
            if (view !== material || viewOwner != owner || showSequence != sequence) return
            validating = false
            if (!confirmed || view !== material || viewOwner != owner || !leaseLive || attached || removalFailed ||
                !runCatching(valid).getOrDefault(false)) {
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
            material.onNextShaderDrawForDiagnostic = { at ->
                if (view === material && viewOwner == owner && leaseLive && attached) {
                    runCatching { event?.invoke(Event(owner, "FIRST_SHADER_DRAW", at)) }
                }
            }
            material.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    if (view === material && viewOwner == owner && leaseLive) emit(owner, "ATTACHED")
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
                if (viewOwner != owner || !runCatching(valid).getOrDefault(false)) {
                    retire(owner, "POST_ADD_REVOKED")
                    return
                }
                fun beginFrames(confirmedAfterAdd: Boolean) {
                if (view !== material || viewOwner != owner || showSequence != sequence) return
                validating = false
                if (!confirmedAfterAdd || view !== material || viewOwner != owner || !leaseLive || !attached ||
                    !runCatching(valid).getOrDefault(false)) {
                    if (view === material && viewOwner == owner) retire(owner, "POST_ADD_REVOKED")
                    return
                }
                material.visibility = View.VISIBLE
                material.alpha = 1f
                val callback = object : Choreographer.FrameCallback {
                    override fun doFrame(frameTimeNanos: Long) {
                        if (view !== material || viewOwner != owner || !leaseLive || !attached) return
                        material.frame(frameTimeNanos)
                        Choreographer.getInstance().postFrameCallback(this)
                    }
                }
                frame = callback
                material.frame(System.nanoTime())
                Choreographer.getInstance().postFrameCallback(callback)
                }
                if (validateAsync == null) beginFrames(true) else {
                    validating = true
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
        emit(owner, "DEBOUNCE_SCHEDULED", "50")
        if (!main.postDelayed(task, 50)) {
            pending = null
            emit(owner, "DEBOUNCE_POST_FAILED")
            return false
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
        showSequence++
        validating = false
        pending?.let { main.removeCallbacks(it); emit(owner, "DEBOUNCE_CANCELED") }
        pending = null
        frame?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frame = null
        val old = view ?: return false
        old.onNextShaderDrawForDiagnostic = null
        old.visibility = View.INVISIBLE
        old.alpha = 0f
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
        viewOwner = null
        event = null
        return true
    }
}
