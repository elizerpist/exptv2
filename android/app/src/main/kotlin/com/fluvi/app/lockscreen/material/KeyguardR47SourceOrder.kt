package com.fluvi.app.lockscreen.material

/** Native channel ownership and a revocation floor for in-flight Dart work.
 * Caller serializes access. A new engine epoch cannot be replaced by an old
 * engine, and an old result cannot cross a later semantic invalidation. */
internal class KeyguardR47SourceOrder {
    private var epoch = -1L
    private var instance = -1L
    private var session: String? = null
    private var minimumRevision = 0L
    private var acceptedRevision = -1L

    fun owns(epoch: Long, instance: Long, session: String): Boolean =
        this.epoch == epoch && this.instance == instance && this.session == session

    fun bind(epoch: Long, instance: Long, session: String): Boolean {
        if (epoch <= 0 || instance <= 0 || session.isBlank() || session.length > 96 || epoch < this.epoch ||
            (epoch == this.epoch && instance < this.instance) ||
            (epoch == this.epoch && instance == this.instance && this.session != session)) return false
        if (!owns(epoch, instance, session)) {
            this.epoch = epoch
            this.instance = instance
            this.session = session
            minimumRevision = 0L
            acceptedRevision = -1L
        }
        return true
    }

    fun invalidate(epoch: Long, instance: Long, session: String, revision: Long): Boolean {
        if (!owns(epoch, instance, session) || revision < minimumRevision || revision < 0) return false
        minimumRevision = revision
        return true
    }

    fun accept(epoch: Long, instance: Long, session: String, revision: Long): Boolean {
        if (!owns(epoch, instance, session) || revision < minimumRevision || revision <= acceptedRevision) return false
        acceptedRevision = revision
        return true
    }
}
