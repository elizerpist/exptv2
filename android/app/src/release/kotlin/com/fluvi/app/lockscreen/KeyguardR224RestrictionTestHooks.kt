package com.fluvi.app.lockscreen

/** No instrumentation callback exists in profile or release builds. */
internal object KeyguardR224RestrictionTestHooks {
    const val ENABLED = false
    fun afterRevocation() = Unit
}
