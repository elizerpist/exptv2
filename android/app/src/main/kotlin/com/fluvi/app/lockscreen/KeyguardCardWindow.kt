package com.fluvi.app.lockscreen

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.TextView
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardCardMaterialController
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialDiagnostics
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.runtime.FluviFinancialCardPresentation

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

    private val manager: WindowManager = serviceContext.getSystemService(WindowManager::class.java)
    private var root: View? = null
    private val lifecycle = KeyguardCardWindowLifecycle()
    private var appliedPresentation: FluviFinancialCardPresentation? = null
    private var appliedGeometry: KeyguardCardGeometry? = null
    private var accessibilityWindowId: Int? = null
    private var materialController: KeyguardCardMaterialController? = null
    private var materialProfile: KeyguardMaterialProfile? = null
    private var materialSettings = KeyguardCardSettings()

    val isAttached: Boolean get() = lifecycle.isAttached()

    /** Returns true only for a positively matched service-owned window. A
     * package-less event in the short post-add race remains unknown; the
     * service will inspect it rather than treating it as safe. */
    fun isOwnAccessibilityWindow(windowId: Int): Boolean {
        checkMainThread()
        return lifecycle.isAttached() && accessibilityWindowId == windowId
    }

    /** The service learns this from public AccessibilityWindowInfo.id while
     * inspecting its own overlay; View has no public window-id accessor. */
    fun recordAccessibilityWindowId(windowId: Int) {
        checkMainThread()
        if (lifecycle.isAttached() && windowId >= 0) accessibilityWindowId = windowId
    }

    fun showOrUpdate(presentation: FluviFinancialCardPresentation, verticalOffsetDp: Int): Result {
        checkMainThread()
        val geometry = geometry(verticalOffsetDp)
        val current = root ?: LayoutInflater.from(serviceContext)
            .inflate(R.layout.fluvi_keyguard_card, null, false)
            .also { created ->
                created.setOnClickListener { onOpen() }
                created.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).setOnClickListener {
                    onToggle()
                }
                materialController = KeyguardCardMaterialController(
                    orb = created.findViewById(R.id.fluvi_financial_snapshot_orb),
                    background = created.findViewById(R.id.fluvi_keyguard_material_background),
                    backgroundVeil = created.findViewById(R.id.fluvi_keyguard_material_veil),
                )
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
                        updateMaterialForPresentation(presentation)
                        materialController?.onAttached()
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
        updateMaterialForPresentation(presentation)
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
        materialController?.stop("hide")
        val removed = runCatching { manager.removeViewImmediate(current) }
        val stillAttached = current.isAttachedToWindow
        if (removed.isSuccess || !stillAttached) {
            lifecycle.onDetached()
            appliedPresentation = null
            appliedGeometry = null
            accessibilityWindowId = null
        } else {
            lifecycle.onUpdateFailed(stillAttached = true)
        }
        return removed.isSuccess
    }

    fun dispose() {
        materialController?.stop("dispose")
        hide()
        root = null
        materialController = null
    }

    /** A material profile change is content-only. It must never issue a
     * WindowManager operation or reset the financial presentation. */
    fun updateMaterial(profile: KeyguardMaterialProfile?, settings: KeyguardCardSettings) {
        checkMainThread()
        materialProfile = profile
        materialSettings = settings
        appliedPresentation?.let(::updateMaterialForPresentation)
    }

    fun materialDiagnostics(): KeyguardMaterialDiagnostics? {
        checkMainThread()
        return materialController?.diagnostics()
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
            root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                .setStaticBitmap(presentation.orb)
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
        // This runs only after a semantic content update. It never changes
        // WindowManager geometry or the retained material renderer.
        root.post {
            if (!root.isAttachedToWindow || !KeyguardCardContentOverflow.fit(root)) return@post
            root.viewTreeObserver.addOnPreDrawListener(object : ViewTreeObserver.OnPreDrawListener {
                override fun onPreDraw(): Boolean {
                    if (root.viewTreeObserver.isAlive) {
                        root.viewTreeObserver.removeOnPreDrawListener(this)
                    }
                    KeyguardCardContentOverflow.fit(root)
                    return true
                }
            })
        }
    }

    private fun geometry(verticalOffsetDp: Int): KeyguardCardGeometry {
        val metrics = serviceContext.resources.displayMetrics
        return resolveKeyguardCardGeometry(
            displayWidthPx = metrics.widthPixels,
            density = metrics.density,
            heightPx = serviceContext.resources.getDimensionPixelSize(
                R.dimen.fluvi_keyguard_card_height,
            ),
            verticalOffsetDp = verticalOffsetDp,
        )
    }

    private fun parameters(geometry: KeyguardCardGeometry): WindowManager.LayoutParams =
        keyguardCardWindowParameters(geometry)

    private fun updateMaterialForPresentation(presentation: FluviFinancialCardPresentation) {
        materialController?.update(
            profile = materialProfile,
            animationMode = materialSettings.animationMode,
            isFull = presentation.full,
            staticOrb = presentation.orb,
        )
    }

    private fun checkMainThread() {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            "KeyguardCardWindow must be called on the main thread"
        }
    }
}
