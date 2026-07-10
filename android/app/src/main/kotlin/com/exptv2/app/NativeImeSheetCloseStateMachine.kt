package com.exptv2.app

class NativeImeSheetCloseStateMachine {
    enum class Phase {
        CLOSED,
        OPEN,
        CLOSING,
    }

    data class Action(
        val token: Long,
        val hideKeyboard: Boolean = false,
        val scheduleTimeout: Boolean = false,
        val finish: Boolean = false,
        val notifyMain: Boolean = false,
        val reason: String = "",
    )

    var phase = Phase.CLOSED
        private set

    private var token = 0L
    private var pendingNotifyMain = false

    fun markOpened(): Action {
        token += 1
        pendingNotifyMain = false
        phase = Phase.OPEN
        return Action(token = token)
    }

    fun requestClose(visible: Boolean, imeBottomPx: Int, notifyMain: Boolean): Action {
        if (!visible || phase == Phase.CLOSED) return Action(token = token)
        if (phase == Phase.CLOSING) {
            return if (imeBottomPx <= 0) finish("ime_zero") else Action(token = token)
        }

        pendingNotifyMain = notifyMain
        if (imeBottomPx <= 0) {
            return finish("ime_already_zero")
        }

        token += 1
        phase = Phase.CLOSING
        return Action(
            token = token,
            hideKeyboard = true,
            scheduleTimeout = true,
        )
    }

    fun onImeProgress(imeBottomPx: Int): Action {
        if (phase == Phase.CLOSING && imeBottomPx <= 0) {
            return finish("ime_zero")
        }
        return Action(token = token)
    }

    fun onImeEnd(imeBottomPx: Int): Action {
        if (phase == Phase.CLOSING && imeBottomPx <= 0) {
            return finish("ime_end_zero")
        }
        return Action(token = token)
    }

    fun onTimeout(actionToken: Long): Action {
        if (phase == Phase.CLOSING && actionToken == token) {
            return finish("timeout")
        }
        return Action(token = token)
    }

    fun forceClosed(): Action {
        pendingNotifyMain = false
        phase = Phase.CLOSED
        token += 1
        return Action(token = token)
    }

    private fun finish(reason: String): Action {
        val notifyMain = pendingNotifyMain
        pendingNotifyMain = false
        phase = Phase.CLOSED
        token += 1
        return Action(
            token = token,
            finish = true,
            notifyMain = notifyMain,
            reason = reason,
        )
    }
}
