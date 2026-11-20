package com.fluvi.app.lockscreen.material

/** Debug instrumentation can hold a real already-entered holder operation.
 * This does not create visibility authority or synthesize a platform event. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = true
    @Volatile var afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
}
