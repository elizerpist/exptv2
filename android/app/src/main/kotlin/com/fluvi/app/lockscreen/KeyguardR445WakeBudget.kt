package com.fluvi.app.lockscreen

/** The caller holds the inspection queue lock. A replacement request in the
 * same wake cannot start a second batch, including after a failed IPC. */
internal class KeyguardR445WakeBudget {
    private var session = -1L
    private var wake = -1L

    fun claim(currentSession: Long, currentWake: Long, screenAt: Long): Long? {
        if (screenAt <= 0L || (session == currentSession && wake == currentWake)) return null
        session = currentSession
        wake = currentWake
        return screenAt
    }
}
