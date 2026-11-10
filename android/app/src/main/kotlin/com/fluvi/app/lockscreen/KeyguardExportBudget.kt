package com.fluvi.app.lockscreen

/** Whole-record UTF-8 admission used by the native report formatter. */
internal object KeyguardExportBudget {
    fun canAppend(currentBytes: Int, addedBytes: Int, limitBytes: Int): Boolean =
        currentBytes >= 0 && addedBytes >= 0 &&
            currentBytes.toLong() + addedBytes <= limitBytes.toLong()
}
