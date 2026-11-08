package com.fluvi.app.lockscreen.material

import android.graphics.Bitmap
import android.os.Build
import android.provider.Settings
import android.view.View
import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardPresentationMode

/** Owns scene application and one Choreographer clock for both retained
 * decorative views. It deliberately has no WindowManager or financial API. */
internal class KeyguardCardMaterialController(
    private val orb: KeyguardHeaderMaterialView,
    private val background: KeyguardHeaderMaterialView,
    private val backgroundVeil: View,
) {
    private val clock = KeyguardMaterialClock { nanos ->
        orb.frame(nanos)
        background.frame(nanos)
    }
    private var attached = false
    private var profile: KeyguardMaterialProfile? = null
    private var mode = KeyguardCardAnimationMode.ORB_ONLY
    private var presentationMode = KeyguardCardPresentationMode.CARD
    var onFirstOrbShaderDraw: (() -> Unit)? = null

    init {
        orb.shape = KeyguardHeaderMaterialView.Shape.ORB
        background.shape = KeyguardHeaderMaterialView.Shape.CARD_BACKGROUND
        // addView() returning is not proof that a hardware Canvas exists.
        // The retained child views publish attach/size/first-draw readiness;
        // all notifications stay within this controller and never touch the
        // WindowManager or the financial resolver.
        orb.onRendererStateChanged = { reconcileClock() }
        background.onRendererStateChanged = { reconcileClock() }
        orb.onFirstShaderDraw = { onFirstOrbShaderDraw?.invoke() }
    }

    fun update(
        profile: KeyguardMaterialProfile?,
        animationMode: KeyguardCardAnimationMode,
        presentationMode: KeyguardCardPresentationMode = KeyguardCardPresentationMode.CARD,
        isFull: Boolean,
        staticOrb: Bitmap?,
    ) {
        this.profile = profile
        this.mode = animationMode
        this.presentationMode = presentationMode
        val scene = profile?.let {
            KeyguardMaterialScene(
                profile = if (isFull) it else it.neutralized(),
                full = isFull,
                appliedAtNanos = System.nanoTime(),
            )
        }
        val canAnimate = scene != null && animationMode != KeyguardCardAnimationMode.OFF && animationsEnabled()
        orb.setStaticBitmap(staticOrb)
        orb.setScene(scene, enabled = canAnimate)
        val backgroundVisible = presentationMode == KeyguardCardPresentationMode.CARD &&
            animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND && scene != null
        background.setScene(scene, enabled = canAnimate && backgroundVisible)
        background.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        // OFF and orb-only retain the precise, already validated static-card
        // appearance. The readability veil only belongs above an animated
        // material background.
        backgroundVeil.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        reconcileClock(canAnimate)
    }

    fun onAttached() {
        attached = true
        // Invalidate once so the first Canvas draw can prove whether this
        // actual overlay is hardware accelerated.  No animation callback is
        // required for this traversal.
        orb.invalidate()
        background.invalidate()
        reconcileClock()
    }

    fun onDetached(reason: String) {
        attached = false
        orb.pause()
        background.pause()
        clock.stop()
    }

    fun stop(reason: String) = onDetached(reason)

    fun diagnostics(): KeyguardMaterialDiagnostics = KeyguardMaterialDiagnostics(
        requestedRenderer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) "RuntimeShader/AGSL" else "static-fallback",
        activeRenderer = when {
            mode == KeyguardCardAnimationMode.OFF -> "STATIC_BY_SETTING"
            orb.rendererFailure() != null -> "COMPILE_OR_UNIFORM_FAILED"
            orb.isRendererReady() -> "RuntimeShader/AGSL"
            else -> "WAITING_FOR_ATTACH_OR_DRAW"
        },
        hardwareAccelerated = orb.lastCanvasHardwareAcceleratedForDiagnostics(),
        shaderCreationCount = orb.shaderCreationCount() + background.shaderCreationCount(),
        animationStartCount = clock.startCount,
        animationStopCount = clock.stopCount,
        frameCallbackCount = clock.callbackCount,
        frameIntervalP50 = clock.framePercentile(.5),
        frameIntervalP95 = clock.framePercentile(.95),
        largeFrameGapCount = clock.largeGapCount,
        rendererFailure = orb.rendererFailure() ?: background.rendererFailure(),
        orb = orb.diagnostics(),
        background = background.diagnostics(),
    )

    private fun reconcileClock(forceCanAnimate: Boolean? = null) {
        val canAnimate = forceCanAnimate ?: (profile != null && mode != KeyguardCardAnimationMode.OFF && animationsEnabled())
        // A genuinely static Header scene is rendered once; the selected
        // visual mode alone must not leave a 60 Hz callback running.
        if (!attached || !canAnimate || profile?.animated != true) {
            orb.pause()
            background.pause()
            clock.stop()
            return
        }
        // Do not use View.isHardwareAccelerated as an eager attach-time gate:
        // it is false until the first actual Canvas draw for some overlays.
        val rendererReady = orb.canAnimateMaterial() &&
            (presentationMode != KeyguardCardPresentationMode.CARD ||
                mode != KeyguardCardAnimationMode.ORB_AND_BACKGROUND || background.canAnimateMaterial())
        if (rendererReady) {
            orb.resume()
            background.resume()
            clock.start()
        } else {
            orb.pause()
            background.pause()
            clock.stop()
        }
    }

    private fun animationsEnabled(): Boolean = Settings.Global.getFloat(
        orb.context.contentResolver,
        Settings.Global.ANIMATOR_DURATION_SCALE,
        1f,
    ) > 0f
}

internal data class KeyguardMaterialDiagnostics(
    val requestedRenderer: String,
    val activeRenderer: String,
    val hardwareAccelerated: Boolean,
    val shaderCreationCount: Int,
    val animationStartCount: Int,
    val animationStopCount: Int,
    val frameCallbackCount: Int,
    val frameIntervalP50: Long,
    val frameIntervalP95: Long,
    val largeFrameGapCount: Int,
    val rendererFailure: String?,
    val orb: KeyguardHeaderMaterialViewDiagnostics,
    val background: KeyguardHeaderMaterialViewDiagnostics,
)
