package com.fluvi.app.lockscreen.material

/** Debug instrumentation can hold a real already-entered holder operation.
 * This does not create visibility authority or synthesize a platform event. */
internal object KeyguardOrbSurfaceWorkerTestHooks {
    const val ENABLED = true
    @Volatile var beforeDirectArtifactLoad: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var afterDirectProgramWarm: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var onDirectProgramConstructor: ((KeyguardOrbSurfaceTarget, String) -> Unit)? = null
    @Volatile var fixedMaterialTime: KeyguardMaterialTime? = null
    @Volatile var postedMaterialTime: ((KeyguardOrbSurfaceTarget, KeyguardMaterialTime, Long) -> Unit)? = null
    @Volatile var beforeRevealCross: ((KeyguardOrbDirectOutput) -> Unit)? = null
    @Volatile var afterRevealCross: ((KeyguardOrbDirectOutput) -> Unit)? = null
    @Volatile var beforeRevealApply: ((KeyguardOrbDirectOutput) -> Unit)? = null
    @Volatile var dispatchRevealDone: ((Runnable) -> Unit)? = null
    @Volatile var afterCanvasLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var afterCanvasPost: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var afterCurrentFirstPosted: ((KeyguardOrbSurfaceTarget, Long) -> Unit)? = null
    @Volatile var afterPosterCreated: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var afterWarmPosterCreated: ((Boolean) -> Unit)? = null
    @Volatile var afterFirstFrameDraw: ((KeyguardOrbSurfaceTarget, String) -> Unit)? = null
    @Volatile var beforeFirstLock: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
    @Volatile var beforeFirstPost: ((KeyguardOrbSurfaceTarget) -> Unit)? = null
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
