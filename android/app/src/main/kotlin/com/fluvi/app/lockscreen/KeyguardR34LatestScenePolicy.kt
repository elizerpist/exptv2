package com.fluvi.app.lockscreen

/** Scheduling only: none of these outcomes is a display or privacy grant. */
internal object KeyguardR34LatestScenePolicy {
    enum class Action { KEEP_READING, TRANSFER, WAIT_FOR_OFFER }

    fun decide(readScene: Long?, currentScene: Long, emptyOwner: Boolean,
               safeBoundary: Boolean, restrictiveEvidence: Boolean,
               pendingScene: Long?, genuineCompatiblePending: Boolean): Action {
        if (readScene == null || currentScene <= readScene || !emptyOwner ||
            !safeBoundary || restrictiveEvidence) return Action.KEEP_READING
        if (pendingScene == currentScene && genuineCompatiblePending) return Action.TRANSFER
        if (pendingScene == null || pendingScene < currentScene) return Action.WAIT_FOR_OFFER
        return Action.KEEP_READING
    }
}
