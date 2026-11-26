package com.fluvi.app.lockscreen

import android.content.Context

/** Missing variant metadata fails closed. The value is fixed at build time. */
internal object KeyguardR448Safety {
    fun sampleOnly(context: Context): Boolean {
        val id = context.resources.getIdentifier("fluvi_r448_sample_only", "bool", context.packageName)
        return id == 0 || runCatching { context.resources.getBoolean(id) }.getOrDefault(true)
    }
}
