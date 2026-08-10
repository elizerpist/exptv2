package com.fluvi.app.dashboard

/**
 * Native boundary policy for complete dashboard-index acquisition.
 *
 * The Dart [DataAcquisitionReason] equivalent has the same three legal
 * index-building reasons. Keeping the allow-list explicit prevents a future
 * transport string from accidentally gaining prepared-index access.
 */
object DashboardPreparedIndexAcquisitionReasons {
    private val allowed = setOf(
        "bootstrap",
        "databaseRevision",
        "query",
    )

    fun isAllowed(value: String): Boolean = value in allowed

    fun requireAllowed(value: String) {
        require(isAllowed(value)) {
            "Prepared index acquisition reason is not allowed: $value"
        }
    }
}
