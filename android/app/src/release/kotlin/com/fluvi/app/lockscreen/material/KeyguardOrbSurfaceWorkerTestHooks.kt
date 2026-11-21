package com.fluvi.app.lockscreen.material

/** Release artifacts have no installed instrumentation barrier. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = false
    val beforeRevealCross: ((KeyguardOrbDirectOutput) -> Unit)? = null
    val afterRevealCross: ((KeyguardOrbDirectOutput) -> Unit)? = null
    val beforeRevealApply: ((KeyguardOrbDirectOutput) -> Unit)? = null
    val dispatchRevealDone: ((Runnable) -> Unit)? = null
    val afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val afterCanvasPost: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val afterPosterCreated: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val afterWarmPosterCreated: ((Boolean) -> Unit)? = null
    val afterFirstFrameDraw: ((KeyguardOrbSurfaceTarget, String) -> Unit)? = null
    val beforeFirstLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val beforeFirstPost: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val holderBoundary: ((KeyguardOrbSurfaceTarget, String, Long) -> Unit)? = null
    fun redrawCompletion(target: KeyguardOrbSurfaceTarget, finished: Runnable) =
        KeyguardOrbSurfaceRedrawCompletion { finished.run() }
}
