package com.fluvi.app.lockscreen

import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import com.fluvi.app.R
import com.fluvi.app.runtime.FluviFinancialCardPresentation
import kotlin.math.min

/** Main-thread-only owner of exactly one accessibility overlay root. */
internal class KeyguardCardWindow(
    private val serviceContext: Context,
    private val onOpen: () -> Unit,
    private val onToggle: () -> Unit,
) {
    private val manager: WindowManager = serviceContext.getSystemService(WindowManager::class.java)
    private var root: View? = null
    private val lifecycle = KeyguardCardWindowLifecycle()

    val isAttached: Boolean get() = lifecycle.isAttached()

    fun showOrUpdate(presentation: FluviFinancialCardPresentation, verticalOffsetDp: Int): Boolean {
        checkMainThread()
        val current = root ?: LayoutInflater.from(serviceContext)
            .inflate(R.layout.fluvi_financial_snapshot_widget, null, false)
            .also { created ->
                created.setOnClickListener { onOpen() }
                created.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).setOnClickListener {
                    onToggle()
                }
                root = created
            }
        apply(current, presentation)
        val params = parameters(verticalOffsetDp)
        return if (lifecycle.showOperation() == KeyguardCardWindowLifecycle.Operation.UPDATE) {
            runCatching { manager.updateViewLayout(current, params) }
                .onFailure { lifecycle.onAttachFailed() }
                .isSuccess
        } else {
            runCatching { manager.addView(current, params) }
                .onSuccess { lifecycle.onAttachSucceeded() }
                .onFailure { lifecycle.onAttachFailed() }
                .isSuccess
        }
    }

    fun hide(): Boolean {
        checkMainThread()
        val current = root ?: return false
        if (lifecycle.hideOperation() == KeyguardCardWindowLifecycle.Operation.NONE) return false
        return runCatching { manager.removeViewImmediate(current) }
            .onSuccess { lifecycle.onDetached() }
            .onFailure { lifecycle.onDetached() }
            .isSuccess
    }

    fun dispose() {
        hide()
        root = null
    }

    private fun apply(root: View, presentation: FluviFinancialCardPresentation) {
        root.findViewById<TextView>(R.id.fluvi_financial_snapshot_focus).text = presentation.focus
        root.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text = presentation.primary
        root.findViewById<TextView>(R.id.fluvi_financial_snapshot_secondary).text = presentation.secondary
        root.findViewById<ImageView>(R.id.fluvi_financial_snapshot_orb).setImageBitmap(presentation.orb)
        root.contentDescription = presentation.contentDescription
        root.findViewById<TextView>(R.id.fluvi_financial_snapshot_event).apply {
            text = presentation.event?.let { "${presentation.eventLabel ?: "Utolsó tétel"}: $it" } ?: ""
            visibility = if (presentation.event == null) View.GONE else View.VISIBLE
        }
        root.findViewById<TextView>(R.id.fluvi_financial_snapshot_toggle).apply {
            text = presentation.toggleLabel
            visibility = if (presentation.showToggle) View.VISIBLE else View.GONE
            contentDescription = if (presentation.showToggle) presentation.toggleLabel else null
        }
    }

    private fun parameters(verticalOffsetDp: Int): WindowManager.LayoutParams {
        val metrics = serviceContext.resources.displayMetrics
        val margin = dp(16)
        val maxWidth = dp(360)
        val width = min(maxWidth, metrics.widthPixels - margin * 2).coerceAtLeast(dp(180))
        return WindowManager.LayoutParams(
            width,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
            // The value is deliberately modest and user-correctable; a full
            // screen touch layer is never created.
            y = dp(148 + verticalOffsetDp.coerceIn(-96, 96))
            title = "FluviKeyguardCard"
        }
    }

    private fun dp(value: Int): Int = (value * serviceContext.resources.displayMetrics.density).toInt()

    private fun checkMainThread() {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            "KeyguardCardWindow must be called on the main thread"
        }
    }
}
