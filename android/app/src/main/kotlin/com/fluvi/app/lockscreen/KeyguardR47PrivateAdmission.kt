package com.fluvi.app.lockscreen

/** A sample ALLOW, a record action or a cached image is never sufficient to
 * show a data-derived header. The supplied signals must come from the current
 * complete inventory and the current system acquisition for this owner. */
internal object KeyguardR47PrivateAdmission {
    fun allows(signals: KeyguardCardSignals, complete: Boolean, materialCurrent: Boolean): Boolean =
        complete && materialCurrent && KeyguardCardVisibilityPolicy.decide(signals) == KeyguardCardVisibility.SHOW_FULL
}
