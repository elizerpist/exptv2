package com.fluvi.app.lockscreen

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Color
import android.os.Looper
import android.view.Display
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.FrameLayout

/** Main-owned ordinary accessibility-overlay host. Its empty stage has no
 * content, touch target or accessibility subtree; it is never a show grant. */
@TargetApi(35)
internal class KeyguardOrbInertHost(
    private val context: Context,
    private val manager: WindowManager,
    private val onReady: (Long, View, Int) -> Unit,
    private val onFailure: (Long, String) -> Unit,
    private val onAttached: (Long, Long) -> Unit = { _, _ -> },
) {
    private class Entry(val generation: Long, val view: FrameLayout, var geometry: KeyguardOverlayGeometry) {
        var addReturned = false
        var frameworkDetached = false
        var ready = false
        var failurePending = false
        var promoted = false
        var windowId: Int? = null
        var preDraw: ViewTreeObserver.OnPreDrawListener? = null
        var attachListener: View.OnAttachStateChangeListener? = null
        var timeout: Runnable? = null
    }
    private var current: Entry? = null

    fun stage(generation: Long, geometry: KeyguardOverlayGeometry): Boolean {
        checkMain()
        if (generation <= 0 || current != null) return false
        val host = FrameLayout(context).apply {
            setBackgroundColor(Color.TRANSPARENT)
            isClickable = false
            isFocusable = false
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        }
        val entry = Entry(generation, host, geometry)
        current = entry
        val attach = object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(view: View) {
                if (current === entry) onAttached(entry.generation, android.os.SystemClock.uptimeMillis())
                inspect(entry)
            }
            override fun onViewDetachedFromWindow(view: View) {
                entry.frameworkDetached = true
                if (current === entry) onFailure(entry.generation, "hostDetached")
            }
        }
        entry.attachListener = attach
        host.addOnAttachStateChangeListener(attach)
        val stagedParams = keyguardCardWindowParameters(geometry).apply {
            flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        }
        val added = runCatching { manager.addView(host, stagedParams) }
        if (added.isFailure) {
            removeListeners(entry)
            current = null
            onFailure(generation, "hostAdd:${added.exceptionOrNull()?.javaClass?.simpleName ?: "unknown"}")
            return false
        }
        entry.addReturned = true
        inspect(entry)
        if (!entry.ready && current === entry) {
            val timeout = Runnable {
                if (current === entry && !entry.ready) {
                    remove(entry.generation)
                    onFailure(entry.generation, "hostReadinessTimeout")
                }
            }
            entry.timeout = timeout
            host.postDelayed(timeout, 500L)
            val listener = ViewTreeObserver.OnPreDrawListener {
                inspect(entry)
                true
            }
            entry.preDraw = listener
            if (host.viewTreeObserver.isAlive) host.viewTreeObserver.addOnPreDrawListener(listener)
        }
        return current === entry
    }

    private fun inspect(entry: Entry) {
        checkMain()
        val host = entry.view
        if (current !== entry || !entry.addReturned || entry.ready || entry.failurePending || !host.isAttachedToWindow ||
            host.display?.displayId != Display.DEFAULT_DISPLAY || host.width != entry.geometry.width ||
            host.height != entry.geometry.height || host.rootSurfaceControl == null) return
        // This is the ID supplied by the actual attached host node, never a
        // guessed package/title. If unavailable, the caller must fail closed.
        val node = runCatching { host.createAccessibilityNodeInfo() }.getOrNull()
        val id = node?.let { try { it.windowId } finally { it.recycle() } }
        if (id == null || id < 0 || id == Int.MAX_VALUE) {
            failAfterTraversal(entry, "hostIdentityUnavailable")
            return
        }
        entry.windowId = id
        entry.ready = true
        removeListeners(entry, keepAttach = true)
        if (runCatching { onReady(entry.generation, host, id) }.isFailure)
            failAfterTraversal(entry, "hostReadyObserver")
    }

    private fun failAfterTraversal(entry: Entry, reason: String) {
        if (current !== entry || entry.failurePending) return
        entry.failurePending = true
        // A pre-draw callback can be inside ViewRoot traversal. The host is
        // still inert; remove it immediately after that callback returns.
        entry.view.post {
            if (current === entry) {
                remove(entry.generation)
                onFailure(entry.generation, reason)
            }
        }
    }

    fun stagedView(generation: Long): View? {
        checkMain()
        return current?.takeIf { it.generation == generation }?.view
    }

    fun updateGeometry(generation: Long, geometry: KeyguardOverlayGeometry): Boolean {
        checkMain()
        val entry = current ?: return false
        if (entry.generation != generation || !entry.promoted || !entry.view.isAttachedToWindow) return false
        if (runCatching { manager.updateViewLayout(entry.view, keyguardCardWindowParameters(geometry)) }.isFailure)
            return false
        entry.geometry = geometry
        return true
    }

    fun readyView(generation: Long): View? {
        checkMain()
        return current?.takeIf { it.generation == generation && it.ready && it.view.isAttachedToWindow }?.view
    }

    fun windowId(generation: Long): Int? {
        checkMain()
        return current?.takeIf { it.generation == generation && it.ready && it.view.isAttachedToWindow }?.windowId
    }

    /** The caller has already obtained a complete MAIN and a fresh final
     * system proof. The actual input root is enabled before a native reveal. */
    fun promote(generation: Long, content: View, geometry: KeyguardOverlayGeometry): Boolean {
        checkMain()
        val entry = current ?: return false
        val host = entry.view
        if (entry.generation != generation || !entry.ready || entry.promoted || entry.geometry != geometry ||
            !host.isAttachedToWindow || content.parent != null) return false
        content.visibility = View.INVISIBLE
        val success = runCatching {
            host.addView(content, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
            host.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
            manager.updateViewLayout(host, keyguardCardWindowParameters(geometry))
            content.visibility = View.VISIBLE
        }.isSuccess
        if (!success) {
            content.visibility = View.INVISIBLE
            host.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            runCatching { host.removeView(content) }
            remove(generation)
            onFailure(generation, "hostInputArmFailed")
            return false
        }
        entry.promoted = true
        return true
    }

    /** The caller supplies the captured generation, so an old teardown can
     * never remove the successor window. */
    fun remove(generation: Long): Boolean {
        checkMain()
        val entry = current ?: return false
        if (entry.generation != generation) return false
        current = null
        removeListeners(entry)
        entry.view.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        entry.view.visibility = View.INVISIBLE
        runCatching {
            manager.updateViewLayout(entry.view, keyguardCardWindowParameters(entry.geometry).apply {
                flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
            })
        }
        // A not-yet-attached View can still have a pending WMS add. Only a
        // successful exact remove settles this owner's lifecycle.
        val removed = runCatching { manager.removeViewImmediate(entry.view) }.isSuccess || entry.frameworkDetached
        if (!removed) {
            // The same still-attached owner remains available for a later
            // exact removal; never turn it back into an interactive host.
            current = entry
        }
        return removed
    }

    private fun removeListeners(entry: Entry, keepAttach: Boolean = false) {
        entry.timeout?.let(entry.view::removeCallbacks)
        entry.timeout = null
        entry.preDraw?.let { listener ->
            if (entry.view.viewTreeObserver.isAlive) entry.view.viewTreeObserver.removeOnPreDrawListener(listener)
        }
        entry.preDraw = null
        if (!keepAttach) {
            entry.attachListener?.let(entry.view::removeOnAttachStateChangeListener)
            entry.attachListener = null
        }
    }

    private fun checkMain() = check(Looper.myLooper() == Looper.getMainLooper())
}
