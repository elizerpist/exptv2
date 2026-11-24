package com.android.systemui.keyguard.fluvi

import android.view.Display
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalView
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.android.compose.animation.scene.ObservableTransitionState
import com.android.systemui.keyguard.domain.interactor.KeyguardInteractor
import com.android.systemui.keyguard.domain.interactor.KeyguardTransitionInteractor
import com.android.systemui.keyguard.shared.model.KeyguardState
import com.android.systemui.keyguard.shared.model.TransitionState
import com.android.systemui.scene.domain.interactor.SceneInteractor
import com.android.systemui.scene.shared.flag.SceneContainerFlag
import com.android.systemui.scene.shared.model.Scenes
import com.android.systemui.settings.UserTracker
import com.android.systemui.shade.domain.interactor.ShadeInteractor
import com.fluvi.r29.contract.R29Disclosure
import com.fluvi.r29.contract.R29FrameInputs
import com.fluvi.r29.contract.R29FramePolicy
import com.fluvi.r29.contract.R29Motion
import javax.inject.Inject
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.isActive

/**
 * Passive clock-root drawing for the separately enrolled AOSP reference host.
 * This modifier does not add a measurable, input window, or Binder call. An
 * absent runtime, uncertain scene, stale asset or unknown geometry draws only
 * the clock. It is not a claim that SystemUI frames have reached the panel.
 */
class R38ClockScene @Inject constructor(
    private val keyguard: KeyguardInteractor,
    private val transitions: KeyguardTransitionInteractor,
    private val scenes: SceneInteractor,
    private val shade: ShadeInteractor,
    private val userTracker: UserTracker,
) {
    private var lastVisible: R29PreparedOrb? = null

    @Composable
    fun modifier(bypass: Boolean): Modifier {
        // The runtime is created only by an already-enrolled pre-wake host
        // service; normal clock drawing never binds or initializes it.
        val runtime = R29HostRuntime.peek() ?: return Modifier
        val view = LocalView.current
        var revision by remember(runtime) { mutableIntStateOf(0) }
        var origin by remember(view) { mutableStateOf<Offset?>(null) }
        val frame = remember(runtime) { mutableLongStateOf(0L) }
        val location = remember(view) { IntArray(2) }
        DisposableEffect(runtime, view) {
            val changed: () -> Unit = { revision++ }
            runtime.addClockObserver(view, changed)
            onDispose { runtime.removeClockObserver(view, changed) }
        }
        // Observe the same SystemUI state used by the active clock. Actual
        // values are checked again at draw, not trusted from an older frame.
        val step by transitions.transitionState.collectAsStateWithLifecycle()
        val scene by scenes.transitionState.collectAsStateWithLifecycle()
        val overlays by scenes.currentOverlays.collectAsStateWithLifecycle()
        val shadeExpanded by shade.isAnyExpanded.collectAsStateWithLifecycle()
        val shadeInput by shade.isUserInteracting.collectAsStateWithLifecycle()
        val dozing by keyguard.isDozing.collectAsStateWithLifecycle()
        val dreaming by keyguard.isDreaming.collectAsStateWithLifecycle()
        @Suppress("DEPRECATION")
        val showing by keyguard.isKeyguardShowing.collectAsStateWithLifecycle()
        @Suppress("DEPRECATION")
        val occluded by keyguard.isKeyguardOccluded.collectAsStateWithLifecycle()
        @Suppress("DEPRECATION")
        val goingAway by keyguard.isKeyguardGoingAway.collectAsStateWithLifecycle()
        val observed = remember(step, scene, overlays, shadeExpanded, shadeInput, dozing, dreaming,
            showing, occluded, goingAway, revision, bypass) {
            currentStateAllows(bypass)
        }
        val ready = remember(revision) { runtime.store.current(System.currentTimeMillis()) }
        LaunchedEffect(ready, observed) {
            if (ready != null && ready.descriptor.motion == R29Motion.LIVE && observed) {
                while (currentCoroutineContext().isActive) withFrameNanos { frame.longValue = it }
            }
        }
        return Modifier.onGloballyPositioned { origin = it.positionInRoot() }.drawWithContent {
            drawContent()
            val prepared = runtime.store.current(System.currentTimeMillis())
            val descriptor = prepared?.descriptor
            val offset = origin
            val root = view.rootView
            val geometryKnown = offset != null && descriptor != null &&
                view.display?.displayId == Display.DEFAULT_DISPLAY &&
                root.width == descriptor.displayWidth && root.height == descriptor.displayHeight
            val canDraw = prepared != null && descriptor != null && geometryKnown &&
                descriptor.userId == 0 && descriptor.displayId == Display.DEFAULT_DISPLAY &&
                descriptor.disclosure == R29Disclosure.FULL && descriptor.projectionCurrent &&
                currentStateAllows(bypass)
            var drew = false
            if (canDraw && descriptor != null && offset != null && prepared != null) {
                view.getLocationOnScreen(location)
                val left = (descriptor.displayWidth - descriptor.orbSizePx) * descriptor.xFraction - location[0] - offset.x
                val top = (descriptor.displayHeight - descriptor.orbSizePx) * descriptor.yFraction - location[1] - offset.y
                if (left >= 0f && top >= 0f && left + descriptor.orbSizePx <= size.width &&
                    top + descriptor.orbSizePx <= size.height) {
                    if (lastVisible !== prepared) lastVisible?.resetVisiblePhase()
                    lastVisible = prepared
                    // Reading frame state invalidates this draw on the next
                    // compositor frame. Anchor a new phase to the current
                    // clock, not a tick retained from a previous wake.
                    frame.longValue
                    val now = System.nanoTime()
                    drawIntoCanvas { prepared.draw(it.nativeCanvas, left, top, now) }
                    drew = true
                }
            }
            if (!drew) {
                lastVisible?.resetVisiblePhase()
                lastVisible = null
                val transition = transitions.transitionState.value
                val noOutgoingScene = transition.transitionState == TransitionState.FINISHED &&
                    (!SceneContainerFlag.isEnabled || scenes.transitionState.value is ObservableTransitionState.Idle)
                runtime.onEmptyClockDraw(view, noOutgoingScene)
            }
        }
    }

    /** All input sources must be local SystemUI state; no app query on wake. */
    @Suppress("DEPRECATION")
    private fun currentStateAllows(bypass: Boolean): Boolean {
        val step = transitions.transitionState.value
        val scene = scenes.transitionState.value
        val sceneAllows = if (!SceneContainerFlag.isEnabled) true else when (scene) {
            is ObservableTransitionState.Idle -> scene.currentScene == Scenes.Lockscreen && scene.currentOverlays.isEmpty()
            is ObservableTransitionState.Transition -> scene.toContent == Scenes.Lockscreen &&
                scenes.currentOverlays.value.isEmpty()
        }
        val fromAllowed = step.transitionState == TransitionState.FINISHED ||
            step.from == KeyguardState.LOCKSCREEN || step.from == KeyguardState.OFF ||
            step.from == KeyguardState.DOZING || step.from == KeyguardState.AOD
        return R29FramePolicy.allow(R29FrameInputs(
            inputsKnown = true,
            ordinaryLockscreen = sceneAllows && step.to == KeyguardState.LOCKSCREEN && fromAllowed && !bypass,
            primaryUser = userTracker.userId == 0,
            defaultDisplay = true, defaultBlueprint = true, geometryValid = true,
            policyAllowsFull = keyguard.isKeyguardShowing.value,
            currentReadyRevision = true,
            dozing = keyguard.isDozing.value, dreaming = keyguard.isDreaming.value,
            occluded = keyguard.isKeyguardOccluded.value, goingAway = keyguard.isKeyguardGoingAway.value,
            credential = step.to == KeyguardState.PRIMARY_BOUNCER || step.to == KeyguardState.ALTERNATE_BOUNCER,
            shadeOrQs = shade.isAnyExpanded.value || shade.isUserInteracting.value,
            restrictiveTransition = step.to != KeyguardState.LOCKSCREEN || !sceneAllows || !fromAllowed,
        ))
    }
}
