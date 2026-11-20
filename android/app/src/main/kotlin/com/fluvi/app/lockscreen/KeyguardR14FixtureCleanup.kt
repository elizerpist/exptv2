package com.fluvi.app.lockscreen

/** Test-only teardown coordinator: every independently restorable boundary is
 * attempted and cleanup cannot replace the initiating exception. */
internal class KeyguardR14FixtureCleanup(
    private val primary: Throwable?,
    private val observed: (String, Throwable?) -> Unit,
) {
    private val failures = mutableListOf<Throwable>()
    fun attempt(label: String, action: () -> Unit) {
        try {
            action()
            observed(label, null)
        } catch (error: Throwable) {
            failures += error
            observed(label, error)
        }
    }
    fun finish() {
        if (primary != null) failures.forEach(primary::addSuppressed)
        else if (failures.isNotEmpty()) throw AssertionError("R14 cleanup failed", failures.first()).also { result ->
            failures.drop(1).forEach(result::addSuppressed)
        }
    }
}
