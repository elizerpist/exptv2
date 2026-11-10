package com.fluvi.app.lockscreen

/** One acquisition, never a cached permission to show. Times use uptime ms. */
internal data class KeyguardSystemState(
    val startedAt: Long,
    val finishedAt: Long,
    val available: Boolean,
    val primaryDisplay: Boolean = false,
    val interactive: Boolean = false,
    val displayOn: Boolean = false,
    val displayOff: Boolean = false,
    val keyguardLocked: Boolean = false,
    val userUnlocked: Boolean = false,
) {
    val eligible: Boolean get() = available && primaryDisplay && interactive && displayOn && keyguardLocked && userUnlocked
    // DOZE/transition/unknown display state is not a definite OFF signal.
    val excluded: Boolean get() = available && (!interactive || displayOff || !keyguardLocked)
}

internal enum class KeyguardSystemReadPurpose { RECURRING, INSPECTION, ADMISSION, PUBLICATION }

internal object KeyguardSystemAdmission {
    fun requiresFreshRead(attached: Boolean, current: KeyguardCardVisibility, proposed: KeyguardCardVisibility): Boolean =
        (proposed == KeyguardCardVisibility.SHOW_FULL || proposed == KeyguardCardVisibility.SHOW_DISCREET) &&
            (!attached || (proposed == KeyguardCardVisibility.SHOW_FULL && current != KeyguardCardVisibility.SHOW_FULL))
}

internal fun interface KeyguardSystemStateReader {
    fun read(purpose: KeyguardSystemReadPurpose): KeyguardSystemState
}

internal data class KeyguardSystemGateRequest(
    val id: Long,
    val authority: KeyguardInspectionAuthority,
    val reason: String,
    val receivedAt: Long,
    val queuedAt: Long,
    val evaluate: Boolean = false,
    val wakeSource: String? = null,
    val eventTime: Long? = null,
    val retry: Boolean = false,
    val freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    val screenOnReceivedAt: Long? = if (wakeSource == "wake") receivedAt else null,
    val completedInspectionId: Long? = null,
    val evaluationReason: String = reason,
    val evaluationReceivedAt: Long = receivedAt,
)

/** Main owns this queue, including completion. The worker owns only read().
 * No lock is held during a platform call, and no replacement worker is started
 * while that call remains in flight. Cancellation revokes delivery, not IPC.
 */
internal class KeyguardSystemStateSampler(
    private val reader: () -> KeyguardSystemStateReader,
    private val worker: ((() -> Unit) -> Unit),
    private val main: ((() -> Unit) -> Unit),
    private val current: () -> KeyguardInspectionAuthority,
    private val receive: (KeyguardSystemGateRequest, KeyguardSystemState) -> Unit,
) {
    private var active: KeyguardSystemGateRequest? = null
    private var pending: KeyguardSystemGateRequest? = null
    private var disposed = false
    private var delivering = false
    private var revocation = 0L
    private var activeRevocation = 0L
    var maximumActive = 0; private set
    var maximumPending = 0; private set
    var rejected = 0L; private set

    fun offer(request: KeyguardSystemGateRequest) {
        if (disposed) return
        if (active == null) start(request) else {
            // Latest gate request wins; its check must not erase an unserved
            // real event's separate causal identity/freshness obligation.
            val previous = pending
            pending = if (!request.evaluate && previous?.evaluate == true && previous.authority == request.authority) {
                request.copy(evaluate = true, wakeSource = previous.wakeSource,
                    eventTime = previous.eventTime, retry = previous.retry, freshness = previous.freshness,
                    screenOnReceivedAt = previous.screenOnReceivedAt ?: request.screenOnReceivedAt,
                    completedInspectionId = previous.completedInspectionId,
                    evaluationReason = previous.evaluationReason, evaluationReceivedAt = previous.evaluationReceivedAt)
            } else if (previous?.authority == request.authority) request.copy(
                screenOnReceivedAt = previous.screenOnReceivedAt ?: request.screenOnReceivedAt,
                freshness = if (previous.freshness.requiresCacheClear && !request.freshness.requiresCacheClear)
                    previous.freshness else request.freshness,
            ) else request
            maximumPending = 1
        }
    }

    fun clearPending() { pending = null; revocation++ }
    fun dispose() { disposed = true; clearPending() }

    fun renewPending(renew: (KeyguardSystemGateRequest) -> KeyguardSystemGateRequest) {
        val unserved = pending ?: active?.takeIf { !delivering && activeRevocation == revocation } ?: return
        offer(renew(unserved)) // A new read under new authority, not a reused answer.
    }

    private fun start(request: KeyguardSystemGateRequest) {
        active = request
        val readRevocation = revocation
        activeRevocation = readRevocation
        maximumActive = 1
        worker {
            val state = runCatching { reader().read(KeyguardSystemReadPurpose.RECURRING) }
                .getOrElse { KeyguardSystemState(-1L, -1L, available = false) }
            main {
                try {
                    delivering = true
                    if (!disposed && readRevocation == revocation && request.authority == current()) receive(request, state)
                    else rejected++
                } finally {
                    delivering = false
                    active = null
                    val next = pending
                    pending = null
                    if (!disposed && next != null) {
                        // A pending event invalidated by attach/interaction needs
                        // a NEW acquisition, never a relabelled old result. The
                        // service supplies the renewed immutable request.
                        if (next.authority == current()) start(next) else rejected++
                    }
                }
            }
        }
    }
}
