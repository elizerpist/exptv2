package com.fluvi.app.lockscreen.host

import com.fluvi.r29.contract.R29Protocol

/**
 * Correlates one outstanding ownership exit. The caller must authenticate the
 * Binder sender and check the active session before using a matching receipt.
 * Matching this token says nothing about how the remote host produced it.
 */
internal class R35EmptyReceipt {
    private data class Pending(val session: String, val sequence: Long, val epoch: Long)
    private var pending: Pending? = null

    fun begin(session: String, sequence: Long, epoch: Long): Boolean {
        if (pending != null || !R29Protocol.validSession(session) || sequence <= 0 || epoch <= 0) return false
        pending = Pending(session, sequence, epoch)
        return true
    }

    fun matches(session: String, sequence: Long, epoch: Long): Boolean =
        pending == Pending(session, sequence, epoch)

    fun clear() { pending = null }
}
