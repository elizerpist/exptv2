package com.fluvi.app.lockscreen.material

/** Instrumentation chooses the old holder only before service connection. */
internal object KeyguardR16LayerTestHooks {
    const val ENABLED = true
    @Volatile var stockHolder = false
}
