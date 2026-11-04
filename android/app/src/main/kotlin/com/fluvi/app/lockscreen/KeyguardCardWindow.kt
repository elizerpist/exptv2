package com.fluvi.app.lockscreen

import android.content.Context
import android.graphics.PixelFormat
import android.os.SystemClock
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import com.fluvi.app.R
import com.fluvi.app.runtime.FluviFinancialCardPresentation
import kotlin.math.min

/** Main-thread-only owner of exactly one accessibility overlay root.
 *
 * The result is deliberately an operation, rather than a Boolean: callers
 * must be able to distinguish a genuine add/remove from a content update or
 * an idempotent re-evaluation. */
internal class KeyguardCardWindow(
    private val serviceContext: Context,
    private val onOpen: () -> Unit,
    private val onToggle: () -> Unit,
) {
    enum class Result {
        ATTACHED,
        CONTENT_UPDATED,
        LAYOUT_UPDATED,
        REDACTED,
        NO_OP,
        FAILED,
    }

    private data class Geometry(val width: Int, val y: Int)

    private val manager: WindowManager = serviceContext.getSystemService(WindowManager::class.java)
    private var root: View? = null
    private val lifecycle = KeyguardCardWindowLifecycle()
    private var appliedPresentation: FluviFinancialCardPresentation? = null
    private var appliedGeometry: Geometry? = null
    private var accessibilityWindowId: Int? = null
    private var attachedAtElapsedMs = Long.MIN_VALUE

    val isAttached: Boolean get() = lifecycle.isAttached()

    /** Returns true only for a positively matched service-owned window. A
     * package-less event in the short post-add race remains unknown; the
     * service will inspect it rather than treating it as safe. */
    fun isOwnAccessibilityWindow(windowId: Int): Boolean {
        checkMainThread()
        refreshAccessibilityWindowId()
        return lifecycle.isAttached() && accessibilityWindowId == windowId
    }

    fun attachedAgeMs(): Long = if (lifecycle.isAttached()) {
        (SystemClock.elapsedRealtime() - attachedAtElapsedMs).coerceAtLeast(0L)
    } else {
        Long.MAX_VALUE
    }

    fun showOrUpdate(presentation: FluviFinancialCardPresentation, verticalOffsetDp: Int): Result {
        checkMainThread()
        val geometry = geometry(verticalOffsetDp)
        val current = root ?: LayoutInflater.from(serviceContext)
            .inflate(R.layout.fluvi_financial_snapshot_widget, null, false)
            .also { created ->
                created.setOnClickListener { onOpen() }
                created.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).setOnClickListener {
                    onToggle()
                }
                root = created
            }

        if (!lifecycle.isAttached()) {
            apply(current, presentation, force = true)
            return runCatching { manager.addView(current, parameters(geometry)) }
                .fold(
                    onSuccess = {
                        lifecycle.onAttachSucceeded()
                        appliedPresentation = presentation
                        appliedGeometry = geometry
                        attachedAtElapsedMs = SystemClock.elapsedRealtime()
                        refreshAccessibilityWindowId()
                        Result.ATTACHED
                    },
                    onFailure = {
                        lifecycle.onAttachFailed()
                        appliedPresentation = null
                        appliedGeometry = null
                        accessibilityWindowId = null
                        Result.FAILED
                    },
                )
        }

        val contentChanged = appliedPresentation?.visualKey != presentation.visualKey
        val geometryChanged = appliedGeometry != geometry
        if (lifecycle.renderOperation(contentChanged, geometryChanged) == KeyguardCardWindowLifecycle.Operation.NONE) {
            return Result.NO_OP
        }

        if (contentChanged) apply(current, presentation, force = false)
        if (geometryChanged) {
            val updated = runCatching { manager.updateViewLayout(current, parameters(geometry)) }
            if (updated.isFailure) {
                // updateViewLayout may fail after a service-side detach. Do
                // not issue a second add while this root might still exist.
                val stillAttached = current.isAttachedToWindow
                lifecycle.onUpdateFailed(stillAttached)
                if (!stillAttached) {
                    appliedPresentation = null
                    appliedGeometry = null
                    accessibilityWindowId = null
                }
                return Result.FAILED
            }
            appliedGeometry = geometry
        }
        val wasFull = appliedPresentation?.full == true
        appliedPresentation = presentation
        return when {
            contentChanged && wasFull && !presentation.full -> Result.REDACTED
            contentChanged -> Result.CONTENT_UPDATED
            else -> Result.LAYOUT_UPDATED
        }
    }

    fun hide(): Boolean {
        checkMainThread()
        val current = root ?: return false
        if (lifecycle.hideOperation() == KeyguardCardWindowLifecycle.Operation.NONE) return false
        val removed = runCatching { manager.removeViewImmediate(current) }
        val stillAttached = current.isAttachedToWindow
        if (removed.isSuccess || !stillAttached) {
            lifecycle.onDetached()
            appliedPresentation = null
            appliedGeometry = null
            accessibilityWindowId = null
            attachedAtElapsedMs = Long.MIN_VALUE
        } else {
            lifecycle.onUpdateFailed(stillAttached = true)
        }
        return removed.isSuccess
    }

    fun dispose() {
        hide()
        root = null
    }

    private fun apply(root: View, presentation: FluviFinancialCardPresentation, force: Boolean) {
        val previous = appliedPresentation
        fun changed(selector: (FluviFinancialCardPresentation) -> Any?): Boolean =
            force || previous == null || selector(previous) != selector(presentation)

        if (changed { it.focus }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_focus).text = presentation.focus
        if (changed { it.primary }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text = presentation.primary
        if (changed { it.secondary }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_secondary).text = presentation.secondary
        if (changed { it.contentDescription }) root.contentDescription = presentation.contentDescription
        if (force || previous?.visualKey != presentation.visualKey) {
            root.findViewById<ImageView>(R.id.fluvi_financial_snapshot_orb).setImageBitmap(presentation.orb)
        }
        val eventText = presentation.event?.let { "${presentation.eventLabel ?: "Utolsó tétel"}: $it" } ?: ""
        if (changed { it.event } || changed { it.eventLabel }) {
            root.findViewById<TextView>(R.id.fluvi_financial_snapshot_event).apply {
                text = eventText
                visibility = if (presentation.event == null) View.GONE else View.VISIBLE
            }
        }
        if (changed { it.showToggle } || changed { it.toggleLabel }) {
            root.findViewById<TextView>(R.id.fluvi_financial_snapshot_toggle).apply {
                text = presentation.toggleLabel
                visibility = if (presentation.showToggle) View.VISIBLE else View.GONE
                contentDescription = if (presentation.showToggle) presentation.toggleLabel else null
            }
        }
    }

    private fun refreshAccessibilityWindowId() {
        val candidate = root?.accessibilityWindowId ?: return
        if (candidate >= 0) accessibilityWindowId = candidate
    }

    private fun geometry(verticalOffsetDp: Int): Geometry {
        val metrics = serviceContext.resources.displayMetrics
        val margin = dp(16)
        return Geometry(
            width = min(dp(360), metrics.widthPixels - margin * 2).coerceAtLeast(dp(180)),
            y = dp(148 + verticalOffsetDp.coerceIn(-96, 96)),
        )
    }

    private fun parameters(geometry: Geometry): WindowManager.LayoutParams = WindowManager.LayoutParams(
        geometry.width,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
        y = geometry.y
        title = "FluviKeyguardCard"
    }

    private fun dp(value: Int): Int = (value * serviceContext.resources.displayMetrics.density).toInt()

    private fun checkMainThread() {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            "KeyguardCardWindow must be called on the main thread"
        }
    }
}
