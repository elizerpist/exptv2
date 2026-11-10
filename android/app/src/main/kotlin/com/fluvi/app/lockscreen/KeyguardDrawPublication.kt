package com.fluvi.app.lockscreen

/** Main-thread diagnostic ownership only. It never grants visibility. */
internal data class KeyguardDrawIdentity(val session: Long, val wake: Long, val attach: Long)

internal class KeyguardDrawPublication {
    enum class Stage { ROOT, SHADER }

    private var current: KeyguardDrawIdentity? = null
    private var rootPublished = false
    private var shaderPublished = false
    var firstRootAt: Long? = null
        private set
    var firstShaderAt: Long? = null
        private set

    fun attach(identity: KeyguardDrawIdentity) {
        if (current == identity) return
        current = identity
        rootPublished = false
        shaderPublished = false
    }
    fun detach() { current = null }

    fun record(identity: KeyguardDrawIdentity, stage: Stage, observedAt: Long, publish: () -> Unit): Boolean {
        if (current != identity) return false
        if (stage == Stage.ROOT) {
            if (rootPublished) return false
            rootPublished = true
            if (firstRootAt == null) firstRootAt = observedAt
        } else {
            if (shaderPublished) return false
            shaderPublished = true
            if (firstShaderAt == null) firstShaderAt = observedAt
        }
        publish()
        return true
    }
}
