package com.fluvi.app.lockscreen

/** Small production state owner behind [KeyguardCardWindow]. Keeping it pure
 * makes duplicate attach/remove and failed-token recovery testable without a
 * device WindowManager. */
internal class KeyguardCardWindowLifecycle {
    private var attached = false
    fun isAttached(): Boolean = attached
    fun showOperation(): Operation = if (attached) Operation.UPDATE else Operation.ATTACH
    fun onAttachSucceeded() { attached = true }
    fun onAttachFailed() { attached = false }
    fun hideOperation(): Operation = if (attached) Operation.DETACH else Operation.NONE
    fun onDetached() { attached = false }

    enum class Operation { ATTACH, UPDATE, DETACH, NONE }
}
