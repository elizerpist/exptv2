package com.fluvi.app.lockscreen

/** Instrumentation seam at one privacy boundary; it does not grant a scene. */
internal object KeyguardR224RestrictionTestHooks {
    const val ENABLED = true
    @Volatile var afterRevocation: (() -> Unit)? = null
    fun afterRevocation() { afterRevocation?.invoke() }
}
