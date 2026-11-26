package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.os.Binder
import android.os.Looper
import android.os.SystemClock
import android.view.Choreographer
import android.view.Display
import android.view.SurfaceControl
import android.view.SurfaceControlViewHost
import android.view.View
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.SystemKeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardShaderArtifact

/** Main-owned, host-window-bound surface for the explicitly armed public
 * sample. No private profile, financial resolver or display overlay is used. */
internal class KeyguardR446WindowPresenter(private val service: AccessibilityService,
    private val timeSource: KeyguardMaterialTimeSource = SystemKeyguardMaterialTimeSource) {
    data class Receipt(val status: String, val attachedAt: Long? = null, val submittedAt: Long? = null,
                       val errorClass: String? = null)
    private var host: SurfaceControlViewHost? = null
    private var surface: SurfaceControlViewHost.SurfacePackage? = null
    private var view: KeyguardHeaderMaterialView? = null
    private var owner: Any? = null
    private var frameCallback: Choreographer.FrameCallback? = null
    private var firstDraw: Long? = null

    /** Invoked unlocked, after private state has been retired. */
    fun prepare(display: Display, profile: KeyguardMaterialProfile, artifact: KeyguardShaderArtifact): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        dispose()
        return runCatching {
            val size = service.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            require(size > 0)
            val sample = profile.neutralized()
            val material = KeyguardHeaderMaterialView(service, materialTimeSource = timeSource).apply {
                isClickable = false
                isFocusable = false
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                setScene(KeyguardMaterialScene(sample, false, System.nanoTime()), enabled = true)
                setBootstrapActive(false)
                check(installPreparedShader(artifact) in setOf(
                    KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED,
                    KeyguardHeaderMaterialView.ProgramPreparationResult.REUSED))
                onFirstShaderDraw = { at -> if (owner != null && firstDraw == null) firstDraw = at }
            }
            val embedded = SurfaceControlViewHost(service, display, Binder())
            host = embedded
            // The public SDK only exposes the size overload. Touch-through is
            // a separately required platform control, not inferred from View.
            embedded.setView(material, size, size)
            view = material
            val childPackage = requireNotNull(embedded.surfacePackage)
            surface = childPackage
            SurfaceControl.Transaction().use { it.setVisibility(childPackage.surfaceControl, false).apply() }
            true
        }.getOrElse { dispose(); false }
    }

    /** Checks are repeated around the platform attach; a failed check never
     * reveals the child. The caller owns the ticket and deadline. */
    fun show(token: Any, target: KeyguardR446Target, geometry: KeyguardOverlayGeometry,
             valid: () -> Boolean, stillOwned: () -> Boolean, onFirstDraw: (Long) -> Unit = {}): Receipt {
        check(Looper.myLooper() == Looper.getMainLooper())
        val child = surface?.surfaceControl ?: return Receipt("NOT_PREPARED")
        val material = view ?: return Receipt("NOT_PREPARED")
        if (owner != null || !valid()) return Receipt("PREATTACH_REVOKED")
        val localX = geometry.left - target.bounds.left
        val localY = geometry.top - target.bounds.top
        val crop = Rect((-localX).coerceAtLeast(0), (-localY).coerceAtLeast(0),
            (target.bounds.width - localX).coerceAtMost(geometry.width),
            (target.bounds.height - localY).coerceAtMost(geometry.height))
        if (crop.isEmpty) return Receipt("EMPTY_CROP")
        var phase = "ATTACH"
        var attachedAt: Long? = null
        return try {
            SurfaceControl.Transaction().use { it.setVisibility(child, false).apply() }
            if (!valid()) return Receipt("PREATTACH_REVOKED")
            service.attachAccessibilityOverlayToWindow(target.windowId, child)
            val attached = SystemClock.uptimeMillis()
            attachedAt = attached
            if (!valid()) { dispose(); return Receipt("POSTATTACH_REVOKED", attached) }
            owner = token
            material.onNextShaderDrawForDiagnostic = { at ->
                if (owner === token && stillOwned()) { firstDraw = at; onFirstDraw(at) }
            }
            phase = "SUBMIT"
            SurfaceControl.Transaction().use {
                it.setPosition(child, localX.toFloat(), localY.toFloat())
                    .setCrop(child, crop).setVisibility(child, true).apply()
            }
            val submitted = SystemClock.uptimeMillis()
            if (!valid()) { dispose(); return Receipt("POSTSUBMIT_REVOKED", attached, submitted) }
            val callback = object : Choreographer.FrameCallback {
                override fun doFrame(frameTimeNanos: Long) {
                    if (owner !== token || !stillOwned()) { dispose(); return }
                    material.frame(frameTimeNanos)
                    Choreographer.getInstance().postFrameCallback(this)
                }
            }
            frameCallback = callback
            material.frame(System.nanoTime())
            Choreographer.getInstance().postFrameCallback(callback)
            Receipt("SUBMITTED", attached, submitted)
        } catch (failure: Exception) {
            dispose()
            Receipt("${phase}_FAILED", attachedAt, errorClass = failure.javaClass.simpleName.take(48))
        }
    }

    fun firstDrawAt(): Long? = firstDraw
    internal fun shaderDrawCountForInstrumentation(): Int = view?.diagnostics()?.shaderDrawCount ?: 0
    internal fun frameForInstrumentation() { view?.frame(System.nanoTime()) }

    /** Hide/detach this exact child before releasing its host. */
    fun dispose() {
        check(Looper.myLooper() == Looper.getMainLooper())
        owner = null
        frameCallback?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frameCallback = null
        val oldSurface = surface
        surface = null
        if (oldSurface != null) runCatching {
            SurfaceControl.Transaction().use {
                it.setVisibility(oldSurface.surfaceControl, false).reparent(oldSurface.surfaceControl, null).apply()
            }
        }
        view?.onFirstShaderDraw = null
        view?.onNextShaderDrawForDiagnostic = null
        view = null
        runCatching { oldSurface?.release() }
        runCatching { host?.release() }
        host = null
        firstDraw = null
    }
}
