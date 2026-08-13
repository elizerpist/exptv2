package com.fluvi.app.dashboard

import com.fluvi.core.model.LedgerDirection
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job

/**
 * Owns only foreground Query prepared-index work on the native bridge.
 *
 * Bootstrap and database-revision work deliberately do not enter this owner.
 * A Dart result token still protects publication, while this owner stops
 * obsolete native work as soon as a newer Query generation takes authority.
 */
internal class DashboardPreparedIndexQueryGenerationOwner {
    data class Request(
        val generation: Long,
        val direction: LedgerDirection?,
        val job: Job,
    )

    private var active: Request? = null

    @Synchronized
    fun replace(next: Request): Request? {
        val previous = active
        if (previous != null && previous.generation != next.generation) {
            previous.job.cancel(
                CancellationException(
                    "Prepared Query generation ${previous.generation} was superseded.",
                ),
            )
        }
        active = next
        return previous
    }

    @Synchronized
    fun cancel(generation: Long): Request? {
        val current = active ?: return null
        if (current.generation != generation) return null
        current.job.cancel(
            CancellationException("Prepared Query generation $generation was cancelled."),
        )
        return current
    }

    @Synchronized
    fun complete(generation: Long, job: Job) {
        if (active?.generation == generation && active?.job === job) {
            active = null
        }
    }

    @Synchronized
    fun clear() {
        active?.job?.cancel(CancellationException("Native query owner disposed."))
        active = null
    }
}
