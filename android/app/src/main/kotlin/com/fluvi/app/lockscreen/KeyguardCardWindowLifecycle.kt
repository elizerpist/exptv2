package com.fluvi.app.lockscreen

/** Small production state owner behind [KeyguardCardWindow]. Keeping it pure
 * makes duplicate attach/remove and failed-token recovery testable without a
 * device WindowManager. */
internal class KeyguardCardWindowLifecycle {
    private var attached = false
    fun isAttached(): Boolean = attached
    fun showOperation(): Operation = if (attached) Operation.UPDATE else Operation.ATTACH
    fun renderOperation(contentChanged: Boolean, geometryChanged: Boolean): Operation = when {
        !attached -> Operation.ATTACH
        contentChanged -> Operation.CONTENT_UPDATE
        geometryChanged -> Operation.LAYOUT_UPDATE
        else -> Operation.NONE
    }
    fun onAttachSucceeded() { attached = true }
    fun onAttachFailed() { attached = false }
    /** An update failure does not prove removal; callers reconcile the real
     * View attachment before changing this state. */
    fun onUpdateFailed(stillAttached: Boolean) { attached = stillAttached }
    fun hideOperation(): Operation = if (attached) Operation.DETACH else Operation.NONE
    fun onDetached() { attached = false }

    enum class Operation { ATTACH, UPDATE, CONTENT_UPDATE, LAYOUT_UPDATE, DETACH, NONE }
}
