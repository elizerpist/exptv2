package com.fluvi.app.lockscreen.material

/** Debug instrumentation can hold a real already-entered holder operation.
 * This does not create visibility authority or synthesize a platform event. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = true
    @Volatile var afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var holderBoundary: ((KeyguardOrbSurfaceTarget, String, Long) -> Unit)? = null
    private val nextRedraw = java.util.concurrent.atomic.AtomicLong()
    fun redrawCompletion(target: KeyguardOrbSurfaceTarget, finished: Runnable): KeyguardOrbSurfaceRedrawCompletion {
        val redraw = nextRedraw.incrementAndGet()
        holderBoundary?.invoke(target, "REDRAW_REQUEST", redraw)
        return KeyguardOrbSurfaceRedrawCompletion {
            finished.run()
            holderBoundary?.invoke(target, "REDRAW_COMPLETE", redraw)
        }
    }
}
