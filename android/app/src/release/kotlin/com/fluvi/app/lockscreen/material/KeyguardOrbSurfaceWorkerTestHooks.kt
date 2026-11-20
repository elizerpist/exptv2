package com.fluvi.app.lockscreen.material

/** Release artifacts have no installed instrumentation barrier. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = false
    val afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    val holderBoundary: ((KeyguardOrbSurfaceTarget, String, Long) -> Unit)? = null
    fun redrawCompletion(target: KeyguardOrbSurfaceTarget, finished: Runnable) =
        KeyguardOrbSurfaceRedrawCompletion { finished.run() }
}
