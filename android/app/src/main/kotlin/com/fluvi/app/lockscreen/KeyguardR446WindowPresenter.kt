package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.graphics.Region
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
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.SystemKeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardShaderArtifact
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.withTimeoutOrNull

/** Main-owned, host-window-bound surface for the explicitly armed public
 * sample. No private profile, financial resolver or display overlay is used. */
internal class KeyguardR446WindowPresenter(private val service: AccessibilityService,
    private val timeSource: KeyguardMaterialTimeSource = SystemKeyguardMaterialTimeSource) {
    data class Receipt(val status: String, val attachedAt: Long? = null, val submittedAt: Long? = null,
                       val errorClass: String? = null)
    data class Retirement(val hideReturn: Long?, val releaseReturn: Long?, val errorClass: String?)
    private var host: SurfaceControlViewHost? = null
    private var surface: SurfaceControlViewHost.SurfacePackage? = null
    private var view: KeyguardHeaderMaterialView? = null
    private var owner: Any? = null
    private var frameCallback: Choreographer.FrameCallback? = null
    private var firstDraw: Long? = null
    private var r46PublicTelemetry = false
    private var r47Telemetry: String? = null
    internal var onR46Interval: ((String) -> Unit)? = null
    private var inputReady = false
    private var inputReadySignal = CompletableDeferred<Boolean>()

    /** Invoked unlocked, after private state has been retired. */
    fun preparePublic(display: Display, sample: KeyguardR46PublicMaterial, artifact: KeyguardShaderArtifact,
                      diagnosticCircle: Boolean = false): Boolean {
        val prepared = prepareScene(display, sample.sceneProfile(), artifact, diagnosticCircle)
        r46PublicTelemetry = prepared
        return prepared
    }

    /** Private input is a distinct, already captured source. Its caller must
     * still hold and revalidate the exact generation and display authority. */
    fun prepareActiveHeader(display: Display, material: FluviActiveHeaderMaterialStore.Snapshot,
                            artifact: KeyguardShaderArtifact): Boolean {
        val prepared = prepareScene(display, material.profile, artifact, false, true, material.receivedAtNanos)
        if (prepared) r47Telemetry = "origin=active_header_semantic token=${material.correlation} " +
            "sourceRevision=${material.profile.publisherRevision} animated=${material.profile.animated} playback=shader"
        return prepared
    }

    /** Existing neutral/private fixture stays explicit and cannot be used to
     * supply material to the public production entrypoint. */
    internal fun prepareForInstrumentation(display: Display, profile: KeyguardMaterialProfile,
                artifact: KeyguardShaderArtifact, diagnosticCircle: Boolean = false): Boolean =
        prepareScene(display, profile.neutralized(), artifact, diagnosticCircle)

    private fun prepareScene(display: Display, sample: KeyguardMaterialProfile, artifact: KeyguardShaderArtifact,
                             diagnosticCircle: Boolean, full: Boolean = false,
                             anchorNanos: Long = System.nanoTime()): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (dispose().errorClass != null) return false
        inputReadySignal = CompletableDeferred()
        val signal = inputReadySignal
        return runCatching {
            val size = service.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            require(size > 0)
            val material = KeyguardHeaderMaterialView(service, materialTimeSource = timeSource).apply {
                isClickable = false
                isFocusable = false
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
                setScene(KeyguardMaterialScene(sample, full, anchorNanos), enabled = true)
                setBootstrapActive(false)
                setR45DiagnosticCircle(diagnosticCircle)
                check(installPreparedShader(artifact) in setOf(
                    KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED,
                    KeyguardHeaderMaterialView.ProgramPreparationResult.REUSED))
                onFirstShaderDraw = { at -> if (owner != null && firstDraw == null) firstDraw = at }
            }
            val embedded = SurfaceControlViewHost(service, display, Binder())
            host = embedded
            view = material
            material.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    val root = v.rootSurfaceControl
                    if (root == null) { signal.complete(false); return }
                    try {
                        // Public AttachedSurfaceControl API. Null would mean
                        // the entire layer; an empty Region means no input.
                        root.setTouchableRegion(Region())
                        val tree = v.viewTreeObserver
                        tree.addOnDrawListener(object : android.view.ViewTreeObserver.OnDrawListener {
                            override fun onDraw() {
                                v.post {
                                    if (tree.isAlive) tree.removeOnDrawListener(this)
                                    val ready = inputReadySignal === signal && view === v &&
                                        v.isAttachedToWindow && v.rootSurfaceControl === root
                                    if (inputReadySignal === signal) inputReady = ready
                                    signal.complete(ready)
                                }
                            }
                        })
                    } catch (_: Exception) { signal.complete(false) }
                }
                override fun onViewDetachedFromWindow(v: View) {
                    v.removeOnAttachStateChangeListener(this)
                    if (inputReadySignal === signal) inputReady = false
                    signal.complete(false)
                }
            })
            embedded.setView(material, size, size)
            val childPackage = requireNotNull(embedded.surfacePackage)
            surface = childPackage
            SurfaceControl.Transaction().use { it.setVisibility(childPackage.surfaceControl, false).apply() }
            true
        }.getOrElse { dispose(); false }
    }

    /** Waits unlocked, never on a wake callback. The draw traversal follows
     * the framework's touch-region update before the receipt is issued. */
    suspend fun awaitInputReady(): Boolean = withTimeoutOrNull(5_000) { inputReadySignal.await() } == true
    internal fun inputReadyForInstrumentation(): Boolean = inputReady

    /** Checks are repeated around the platform attach; a failed check never
     * reveals the child. The caller owns the ticket and deadline. */
    fun show(token: Any, target: KeyguardR446Target, geometry: KeyguardOverlayGeometry,
             valid: () -> Boolean, stillOwned: () -> Boolean, onInvalidated: () -> Unit = { dispose() },
             onFirstTraversal: (Long) -> Unit = {},
             onFirstDraw: (Long) -> Unit = {}): Receipt {
        check(Looper.myLooper() == Looper.getMainLooper())
        val child = surface?.surfaceControl ?: return Receipt("NOT_PREPARED")
        val material = view ?: return Receipt("NOT_PREPARED")
        if (!inputReady || !material.isAttachedToWindow) return Receipt("INPUT_UNQUALIFIED")
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
            material.onNextDrawForDiagnostic = { at -> if (owner === token && stillOwned()) onFirstTraversal(at) }
            startFrames(token, material, stillOwned, onInvalidated)
            Receipt("SUBMITTED", attached, submitted)
        } catch (failure: Exception) {
            dispose()
            Receipt("${phase}_FAILED", attachedAt, errorClass = failure.javaClass.simpleName.take(48))
        }
    }

    fun firstDrawAt(): Long? = firstDraw
    internal fun shaderDrawCountForInstrumentation(): Int = view?.diagnostics()?.shaderDrawCount ?: 0
    internal fun frameForInstrumentation() { view?.frame(System.nanoTime()) }

    private fun startFrames(token: Any, material: KeyguardHeaderMaterialView,
                            stillOwned: () -> Boolean, onInvalidated: () -> Unit) {
        if (r46PublicTelemetry) material.beginR46SampleInterval()
        else r47Telemetry?.let { material.beginR46SampleInterval(it) }
        val callback = object : Choreographer.FrameCallback {
            override fun doFrame(frameTimeNanos: Long) {
                if (owner !== token) return
                if (!stillOwned()) { onInvalidated(); return }
                material.frame(frameTimeNanos)
                Choreographer.getInstance().postFrameCallback(this)
            }
        }
        frameCallback = callback
        material.frame(System.nanoTime())
        Choreographer.getInstance().postFrameCallback(callback)
    }

    /** Hide the exact child immediately without releasing its host. */
    fun conceal(token: Any): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (owner !== token) return false
        frameCallback?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frameCallback = null
        val child = surface?.surfaceControl ?: return false
        val hidden = runCatching { SurfaceControl.Transaction().use { it.setVisibility(child, false).apply() }; true }
            .getOrDefault(false)
        view?.endR46SampleInterval()?.let { detail -> runCatching { onR46Interval?.invoke(detail) } }
        return hidden
    }

    /** The service supplies freshly qualified authority for this same target. */
    fun resume(token: Any, valid: () -> Boolean, stillOwned: () -> Boolean,
               onInvalidated: () -> Unit): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (owner !== token || !runCatching(valid).getOrDefault(false)) return false
        val child = surface?.surfaceControl ?: return false
        val material = view ?: return false
        return runCatching {
            SurfaceControl.Transaction().use { it.setVisibility(child, true).apply() }
            if (!valid()) { conceal(token); false }
            else { startFrames(token, material, stillOwned, onInvalidated); true }
        }.getOrDefault(false)
    }

    /** Hide/detach this exact child before releasing its host. */
    fun dispose(): Retirement {
        check(Looper.myLooper() == Looper.getMainLooper())
        owner = null
        inputReady = false
        inputReadySignal.complete(false)
        frameCallback?.let { Choreographer.getInstance().removeFrameCallback(it) }
        frameCallback = null
        val oldSurface = surface
        var hideReturn: Long? = null
        var errorClass: String? = null
        if (oldSurface != null) runCatching {
            SurfaceControl.Transaction().use {
                it.setVisibility(oldSurface.surfaceControl, false).reparent(oldSurface.surfaceControl, null).apply()
            }
        }.onSuccess { hideReturn = SystemClock.uptimeMillis() }
            .onFailure { errorClass = it.javaClass.simpleName.take(48) }
        if (errorClass != null) return Retirement(hideReturn, null, errorClass)
        view?.endR46SampleInterval()?.let { detail -> runCatching { onR46Interval?.invoke(detail) } }
        view?.onFirstShaderDraw = null
        view?.onNextShaderDrawForDiagnostic = null
        view?.onNextDrawForDiagnostic = null
        runCatching { oldSurface?.release() }.onFailure { if (errorClass == null) errorClass = it.javaClass.simpleName.take(48) }
        val oldHost = host
        var releaseReturn: Long? = null
        if (oldHost != null) runCatching { oldHost.release() }
            .onSuccess { releaseReturn = SystemClock.uptimeMillis() }
            .onFailure { if (errorClass == null) errorClass = it.javaClass.simpleName.take(48) }
        if (errorClass != null) return Retirement(hideReturn, releaseReturn, errorClass)
        surface = null
        view = null
        r46PublicTelemetry = false
        r47Telemetry = null
        host = null
        firstDraw = null
        return Retirement(hideReturn, releaseReturn, errorClass)
    }
}
