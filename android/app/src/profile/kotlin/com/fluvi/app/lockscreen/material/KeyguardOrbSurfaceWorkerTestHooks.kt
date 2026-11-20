package com.fluvi.app.lockscreen.material

/** Profile artifacts have no installed instrumentation barrier. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = false
    val afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
}
