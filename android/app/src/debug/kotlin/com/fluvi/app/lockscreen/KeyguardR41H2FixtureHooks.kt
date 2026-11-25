package com.fluvi.app.lockscreen

/** Disposable instrumentation only. Never enabled by a phone profile build. */
internal object KeyguardR41H2FixtureHooks {
    const val ENABLED = true
    @Volatile var enableIntervention = false
}
