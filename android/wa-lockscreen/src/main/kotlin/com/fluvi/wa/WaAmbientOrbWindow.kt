package com.fluvi.wa

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.view.View
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView

/** One static, non-interactive presentation. Every callback is qualified by its Main-owned ticket. */
internal class WaAmbientOrbWindow(
    private val context: Context,
    private val main: Handler,
    val session: Long,
    private val layout: (WaAmbientMaterial) -> WindowManager.LayoutParams?,
    private val mask: () -> Bitmap,
    private val canDraw: (WaAmbientIdentity) -> Boolean,
) {
    private class Frame(
        val ticket: WaAmbientAuthority.Ticket, val root: FrameLayout, val visual: FrameLayout,
    ) {
        var child: WaSurfaceChild? = null
        var clearDraw: (() -> Unit)? = null
        var revoked = false
    }

    private val manager = context.getSystemService(WindowManager::class.java)
    private val authority = WaAmbientAuthority()
    private var current: Frame? = null
    private var failed: WaAmbientIdentity? = null
    val hasWindow get() = current != null

    fun observe(gate: WaAmbientGate, key: WaAmbientIdentity?) {
        val frame = current
        if (frame != null && !authority.retains(frame.ticket, gate, key)) {
            revoke(gate.name)
        }
        if (gate != WaAmbientGate.DOZE && gate != WaAmbientGate.DOZE_SUSPEND) failed = null
    }

    fun show(material: WaAmbientMaterial) {
        val key = material.identity
        if (current != null || failed == key || !canDraw(key)) return
        val params = try {
            layout(material)
        } catch (error: RuntimeException) {
            failed = key
            WaAmbientCapture.edge(session, "SKIPPED", "LAYOUT_ERROR", detail = error.javaClass.simpleName)
            return
        }
        if (params == null) {
            failed = key
            WaAmbientCapture.edge(session, "SKIPPED", "NO_FIT")
            return
        }
        val frame = Frame(authority.begin(key), FrameLayout(context), FrameLayout(context))
        current = frame
        try {
            frame.root.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            frame.root.setBackgroundColor(Color.TRANSPARENT)
            frame.visual.alpha = 0f
            frame.visual.addView(image(material.frame.bitmap), FrameLayout.LayoutParams(-1, -1))
            if (material.style == WaOrbStyle.FLUVI_MASK) {
                frame.visual.addView(image(mask()), FrameLayout.LayoutParams(-1, -1))
            }
            if (Build.VERSION.SDK_INT >= 34) {
                val child = WaSurfaceChild(context, main, { bind(frame, it, params.width) }, {
                    if (isCurrent(frame) && frame.child === it) fail(frame, "SURFACE_LOST")
                })
                frame.child = child
                frame.root.addView(child.surface, FrameLayout.LayoutParams(-1, -1))
            } else {
                frame.root.addView(frame.visual, FrameLayout.LayoutParams(-1, -1))
                awaitDraw(frame)
            }
            if (!canDraw(key)) {
                revoke("ADD_RECHECK_DENIED")
                return
            }
            manager.addView(frame.root, params)
            if (isCurrent(frame)) WaAmbientCapture.edge(session, "ATTACHED", "WINDOW_MANAGER", frame.ticket)
        } catch (error: RuntimeException) {
            fail(frame, error.javaClass.simpleName)
        }
    }

    private fun image(bitmap: Bitmap) = ImageView(context).apply {
        scaleType = ImageView.ScaleType.FIT_XY
        setImageBitmap(bitmap)
    }

    private fun isCurrent(frame: Frame) = current === frame && !frame.revoked

    private fun bind(frame: Frame, child: WaSurfaceChild, diameter: Int) {
        if (!isCurrent(frame) || frame.child !== child) return
        if (!canDraw(frame.ticket.identity)) {
            revoke("SURFACE_RECHECK_DENIED")
            return
        }
        try {
            child.attach(frame.visual, diameter)
            check(child.ready)
            awaitDraw(frame)
        } catch (error: RuntimeException) {
            fail(frame, error.javaClass.simpleName)
        }
    }

    private fun awaitDraw(frame: Frame) {
        val visual = frame.visual
        val observer = visual.viewTreeObserver
        val callback = ViewTreeObserver.OnPreDrawListener {
            frame.clearDraw?.invoke()
            if (isCurrent(frame)) {
                val key = frame.ticket.identity
                if (frame.root.isAttachedToWindow && visual.isAttachedToWindow &&
                    frame.child?.ready != false && canDraw(key) &&
                    authority.publish(frame.ticket, WaAmbientGate.DOZE, key)
                ) {
                    visual.alpha = 1f
                    WaAmbientCapture.edge(session, "APP_SUBMITTED", "VISUAL_ALPHA", frame.ticket)
                } else {
                    revoke("DRAW_RECHECK_DENIED")
                }
            }
            true
        }
        frame.clearDraw = {
            frame.clearDraw = null
            if (observer.isAlive) observer.removeOnPreDrawListener(callback)
            else visual.viewTreeObserver.removeOnPreDrawListener(callback)
        }
        observer.addOnPreDrawListener(callback)
    }

    private fun fail(frame: Frame, detail: String) {
        if (!isCurrent(frame)) return
        failed = frame.ticket.identity
        revoke("PRESENTER_ERROR", detail)
    }

    fun revoke(reason: String, error: String? = null) {
        val frame = current?.takeUnless { it.revoked } ?: return
        frame.revoked = true
        authority.revoke()
        val childHide = frame.child?.withdraw(null)
        frame.visual.alpha = 0f
        frame.root.visibility = View.INVISIBLE
        frame.clearDraw?.invoke()
        WaAmbientCapture.edge(session, "REVOKED", reason, frame.ticket,
            error ?: childHide?.let { it.error ?: it.status })
        remove(frame, retry = false)
    }

    private fun remove(frame: Frame, retry: Boolean) {
        if (current !== frame) return
        var error: String? = null
        try {
            if (frame.root.parent != null) manager.removeViewImmediate(frame.root)
        } catch (failure: RuntimeException) {
            error = failure.javaClass.simpleName
        }
        val child = frame.child
        frame.child = null
        try {
            child?.dispose()
        } catch (failure: RuntimeException) {
            error = failure.javaClass.simpleName
        }
        val removed = frame.root.parent == null && !frame.root.isAttachedToWindow
        WaAmbientCapture.edge(session, "REMOVE_RETURN", if (removed) "DETACHED" else "PENDING", frame.ticket, error)
        if (removed) current = null
        else if (!retry) main.post { remove(frame, retry = true) }
    }
}
