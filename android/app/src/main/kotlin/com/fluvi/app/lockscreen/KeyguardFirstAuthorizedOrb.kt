package com.fluvi.app.lockscreen

/** Scalar, non-displaying continuation for the initial direct ORB. This does
 * not own a View, accessibility object, image, payload, or visibility grant.
 * The service supplies the same lock as its reader queue/coordinator. */
internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
    enum class Intent { DISCREET_PREPOSTED, EMPTY_AWAITING_DISCLOSURE }

    data class Proof(
        val requestId: Long,
        val authority: KeyguardInspectionAuthority,
        val sceneSerial: Long,
        val freshnessRevision: Long,
        val hostGeneration: Long,
        val outputGeneration: Long,
        val selectionRevision: Long,
        val materialRevision: Long,
        val dataRevision: Long,
        val full: Boolean,
    )

    private var scene = 0L
    private var newestRead = 0L
    private var newestRequiredRead = 0L
    private var retained: Proof? = null
    private var consumed = false

    fun sceneSerial(): Long = synchronized(lock) { scene }
    fun current(): Proof? = synchronized(lock) { retained }

    /** Call before an accepted potentially scene-changing event can be
     * sampled, enqueued, or coalesced. Exact own-window events do not call it. */
    fun externalIngress(): Long = synchronized(lock) {
        scene += 1
        retained = null
        consumed = false
        scene
    }

    /** Register an ordered read obligation before its queue offer. A new
     * request invalidates an older continuation even before its read starts. */
    fun requireRead(requestId: Long) = synchronized(lock) {
        if (requestId > newestRequiredRead) {
            newestRequiredRead = requestId
            if (retained?.requestId?.let { it < requestId } == true) {
                retained = null
                consumed = false
            }
        }
    }

    /** Actual read completion orders evidence, not permission. A delayed older
     * read-ahead predecessor cannot overwrite a newer physical answer. */
    fun readCompleted(requestId: Long) = synchronized(lock) {
        if (requestId > newestRead) {
            newestRead = requestId
            if (retained?.requestId?.let { it < requestId } == true) {
                retained = null
                consumed = false
            }
        }
    }

    fun invalidate() = synchronized(lock) {
        retained = null
        consumed = false
    }

    fun offer(requestId: Long, authority: KeyguardInspectionAuthority, readSceneSerial: Long,
              freshnessRevision: Long, hostGeneration: Long, outputGeneration: Long,
              selectionRevision: Long, materialRevision: Long, dataRevision: Long, full: Boolean,
              completeMain: Boolean, freshSystemEligible: Boolean): Proof? = synchronized(lock) {
        if (!completeMain || !freshSystemEligible || requestId <= 0 || requestId < newestRead ||
            requestId < newestRequiredRead ||
            readSceneSerial != scene || freshnessRevision < 0 || hostGeneration <= 0 || outputGeneration <= 0)
            return@synchronized null
        val next = Proof(requestId, authority, readSceneSerial, freshnessRevision, hostGeneration,
            outputGeneration, selectionRevision, materialRevision, dataRevision, full)
        if (retained != next) {
            retained = next
            consumed = false
        }
        next
    }

    /** Read-only check for a Main continuation; it grants no visual authority. */
    fun isUnclaimedReadCurrent(requestId: Long, readSceneSerial: Long?): Boolean = synchronized(lock) {
        readSceneSerial != null && requestId > 0 && requestId >= newestRead &&
            requestId >= newestRequiredRead && readSceneSerial == scene
    }

    /** Diagnostic-only explanation at the same scalar comparison boundary.
     * The caller may hold the shared lock across offer and this observation. */
    fun offerRejection(requestId: Long, readSceneSerial: Long?, freshnessRevision: Long?,
                       hostGeneration: Long, outputGeneration: Long): String = synchronized(lock) {
        when {
            readSceneSerial == null || freshnessRevision == null -> "MISSING_ENDPOINT"
            readSceneSerial != scene -> "SCENE_CHANGED"
            requestId < newestRead -> "NEWER_READ_FINISHED"
            requestId < newestRequiredRead -> "NEWER_READ_REQUIRED"
            requestId <= 0 || freshnessRevision < 0 || hostGeneration <= 0 || outputGeneration <= 0 -> "INVALID_IDENTITY"
            else -> "UNOBSERVED"
        }
    }

    fun isCurrent(proof: Proof): Boolean = synchronized(lock) {
        retained == proof && proof.sceneSerial == scene && proof.requestId >= newestRead &&
            proof.requestId >= newestRequiredRead
    }

    /** Only one Main continuation may initiate the final show. The proof
     * remains comparable at the compositor submit boundary until invalidated. */
    fun consume(proof: Proof): Boolean = synchronized(lock) {
        if (retained != proof || proof.sceneSerial != scene || proof.requestId < newestRead ||
            proof.requestId < newestRequiredRead || consumed)
            return@synchronized false
        consumed = true
        true
    }

    companion object {
        fun intent(showFinancialDetails: Boolean): Intent = if (showFinancialDetails)
            Intent.EMPTY_AWAITING_DISCLOSURE else Intent.DISCREET_PREPOSTED
    }
}
