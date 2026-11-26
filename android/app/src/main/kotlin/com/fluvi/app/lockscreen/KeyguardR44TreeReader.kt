package com.fluvi.app.lockscreen

import android.os.Bundle
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo

/** One budget is shared by every window in a physical inspection. */
internal class KeyguardR44ExtraBudget {
    companion object { const val MAX_CALLS = 4; const val MAX_ELAPSED_MS = 50L }
    var fetched = 0
    var budgetHit = false
    var elapsedMs = 0L
    var restrictionObserved = false
    var hardFailure = false

    /** A synchronous platform IPC already in progress cannot be preempted.
     * This limits additional optional IPC after it returns. */
    fun reserve(extended: Boolean = false): Boolean {
        if (restrictionObserved || hardFailure) return false
        if (fetched >= (if (extended) 7 else MAX_CALLS) || elapsedMs >= MAX_ELAPSED_MS) {
            budgetHit = true
            return false
        }
        fetched += 1
        return true
    }
}

/** Worker-owned; finished snapshots contain only fixed enums and scalars. */
internal class KeyguardR44TreeReader(
    private val windowId: Int,
    private val verifiedRoot: Boolean,
    private val active: Boolean,
    private val genuineDeviceEntryResource: Boolean,
    private val budget: KeyguardR44ExtraBudget,
    private val deferred: KeyguardR443Inventory? = null,
    private val liveSampleExtension: Boolean = false,
    private val collectDiagnostics: Boolean = false,
) {
    private var host: KeyguardR44Witness? = null
    private var content: KeyguardR44Witness? = null
    private var below = false
    private var complete = verifiedRoot
    private var foreign = false
    private var advertised = 0
    private var fetched = 0
    private var failed = 0
    private var unsupported = 0
    private var extraMs = 0L
    private var budgetHit = false
    private var rawHost = 0
    private var rawEntry = 0
    private var rawClock = 0
    private var rejectedUnverified = 0
    private var rejectedAncestry = 0
    private var rejectedExcluded = 0
    private var rejectedForeign = 0
    private var rejectedHidden = 0
    private var firstCandidate: KeyguardR44Markers.Marker? = null
    private var firstCarrier: KeyguardR44Markers.Carrier? = null
    private val parents = IntArray(if (deferred == null) 0 else 97)
    private val excludedHere = BooleanArray(if (deferred == null) 0 else 97)
    private val unknownScenes = BooleanArray(if (deferred == null) 0 else 97)
    private val facts = arrayOfNulls<MutableList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>>(
        if (deferred == null) 0 else 97)
    private var deferredPending = 0
    private var deferredRestriction: ((String) -> Unit)? = null
    private var optionalTiming: ((String, Long, Long) -> Unit)? = null
    private data class CandidateMetric(val ordinal: Int, val parentOrdinal: Int,
        var rank: Int = 0, var status: String = "PENDING", var role: String = "UNOBSERVED",
        var costMs: Long = 0, var remaining: Int = 0, var remainingMs: Long = 0,
        var parentChecks: Int = 0, var parentMs: Long = 0)
    private val candidateMetrics = if (collectDiagnostics) ArrayList<CandidateMetric>(7) else null
    private var candidateOverflow = 0
    fun candidateSeen(ordinal: Int, parentOrdinal: Int) {
        if (candidateMetrics != null && candidateMetrics.size < 7)
            candidateMetrics += CandidateMetric(ordinal, parentOrdinal)
    }
    fun candidateOverflow() { candidateOverflow++ }
    fun diagnosticsEnabled(): Boolean = collectDiagnostics
    fun candidateParentCheck(ordinal: Int, elapsed: Long) {
        candidateMetrics?.firstOrNull { it.ordinal == ordinal }?.apply { parentChecks++; parentMs += elapsed }
    }
    fun candidateRejected(ordinal: Int, reason: String) {
        candidateMetrics?.firstOrNull { it.ordinal == ordinal }?.status = reason
    }
    private fun candidateDone(ordinal: Int, status: String, role: String, cost: Long, rank: Int) {
        candidateMetrics?.firstOrNull { it.ordinal == ordinal }?.apply {
            this.status = status; this.role = role; costMs = cost; this.rank = rank
            remaining = (7 - budget.fetched).coerceAtLeast(0)
            remainingMs = (KeyguardR44ExtraBudget.MAX_ELAPSED_MS - budget.elapsedMs).coerceAtLeast(0)
        }
    }

    fun onDeferredRestriction(callback: (String) -> Unit) { deferredRestriction = callback }
    fun onOptionalTiming(callback: ((String, Long, Long) -> Unit)?) { optionalTiming = callback }
    fun isDeferred(): Boolean = deferred != null
    fun pendingCandidate() { deferredPending++ }
    fun unresolvedCandidate() { complete = false; budget.hardFailure = true }
    fun isVerifiedActiveRoot(): Boolean = verifiedRoot && active && !foreign
    fun hasVerifiedHost(): Boolean = isVerifiedActiveRoot() && host != null && complete
    fun candidatePriority(parentOrdinal: Int): Int = if (descendsFrom(parentOrdinal, host?.ordinal)) 1 else 2
    private fun descendsFrom(start: Int, ancestor: Int?): Boolean {
        if (ancestor == null) return false
        var current = start
        var remaining = parents.size
        while (current > 0 && current < parents.size && remaining-- > 0) {
            if (current == ancestor) return true
            current = parents[current]
        }
        return false
    }
    private fun hasExcludedAncestor(ordinal: Int): Boolean {
        var current = ordinal
        var remaining = parents.size
        while (current > 0 && current < parents.size && remaining-- > 0) {
            if (excludedHere[current]) return true
            current = parents[current]
        }
        return false
    }
    private fun addFact(ordinal: Int, marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier) {
        if (ordinal in 1 until facts.size) {
            val entries = facts[ordinal] ?: mutableListOf<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>().also { facts[ordinal] = it }
            entries += marker to carrier
        } else complete = false
    }

    /** Resolve only a retained request-owned node; validate its original
     * parent before and after the synchronous optional framework call. */
    fun resolveDeferred(node: AccessibilityNodeInfo, ordinal: Int, parentOrdinal: Int,
                        parentId: String?, root: Boolean, viewId: String?,
                        authority: () -> Boolean, allowExtended: Boolean) {
        deferredPending = (deferredPending - 1).coerceAtLeast(0)
        fun valid(): Boolean {
            if (!authority()) return false
            return runCatching {
                if (node.packageName?.toString() != "com.android.systemui" || node.windowId != windowId ||
                    !node.isVisibleToUser || node.viewIdResourceName != viewId) false
                else {
                    val parentStarted = if (collectDiagnostics) SystemClock.uptimeMillis() else 0L
                    val parent = node.parent
                    try {
                        if (root) parent == null else parent != null && parentId != null &&
                            parent.windowId == windowId && parent.packageName?.toString() == "com.android.systemui" &&
                            parent.isVisibleToUser && KeyguardR443ParentIdentity.of(parent) == parentId
                    } finally {
                        parent?.recycle()
                        if (collectDiagnostics) candidateParentCheck(ordinal, SystemClock.uptimeMillis() - parentStarted)
                    }
                }
            }.getOrDefault(false)
        }
        if (!valid()) {
            candidateDone(ordinal, "REJECTED_OWNER", "UNOBSERVED", 0, 0)
            complete = false; budget.hardFailure = true; failed++; return
        }
        if (!budget.reserve(allowExtended)) {
            candidateDone(ordinal, "BUDGET", "UNOBSERVED", 0, 0)
            complete = false; budget.hardFailure = true; budgetHit = true; return
        }
        fetched++
        val begin = SystemClock.uptimeMillis()
        val refreshed = runCatching { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }.getOrDefault(false)
        val duration = SystemClock.uptimeMillis() - begin
        extraMs += duration
        budget.elapsedMs += duration
        optionalTiming?.invoke("optional", begin, begin + duration)
        if (!refreshed || !valid()) {
            candidateDone(ordinal, "FAILED_OR_STALE", "UNOBSERVED", duration, budget.fetched)
            complete = false; budget.hardFailure = true; failed++; return
        }
        val value = runCatching { node.extras.getCharSequence(KeyguardR44Markers.EXTRA) }.getOrNull()
        if (value == null) {
            candidateDone(ordinal, "EMPTY", "UNOBSERVED", duration, budget.fetched)
            complete = false; budget.hardFailure = true; failed++; return
        }
        val marker = KeyguardR44Markers.exact(value)
        if (marker == null) {
            candidateDone(ordinal, "READ", if (KeyguardR44Markers.unknownMayRestrict(value,
                descendsFrom(parentOrdinal, host?.ordinal))) "POSSIBLY_RESTRICTIVE" else "UNRELATED",
                duration, budget.fetched)
            unsupported++
            if (value.startsWith("overlay:")) { complete = false; budget.hardFailure = true }
            else if (value.startsWith("scene:") && ordinal in unknownScenes.indices) unknownScenes[ordinal] = true
            return
        }
        candidateDone(ordinal, "READ", marker.name, duration, budget.fetched)
        observe(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY)
        addFact(ordinal, marker, KeyguardR44Markers.Carrier.EXTRA_LAZY)
        if (marker == KeyguardR44Markers.Marker.HOST) {
            if (host != null && host?.ordinal != ordinal) complete = false
            else host = KeyguardR44Witness(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY, ordinal)
        }
        KeyguardR44Markers.exclusion(marker)?.let {
            excludedHere[ordinal] = true
            restrictionObserved()
            deferredRestriction?.invoke(it)
        }
    }

    private fun reconcileDeferred() {
        if (deferred == null) return
        if (deferredPending != 0) complete = false
        val foundHosts = (1 until facts.size).filter { ordinal ->
            !hasExcludedAncestor(ordinal) && facts[ordinal]?.any { it.first == KeyguardR44Markers.Marker.HOST } == true
        }
        if (foundHosts.size > 1) complete = false
        val hostOrdinal = foundHosts.singleOrNull()
        if (hostOrdinal == null) host = null else {
            val item = facts[hostOrdinal]!!.first { it.first == KeyguardR44Markers.Marker.HOST }
            host = KeyguardR44Witness(item.first, item.second, hostOrdinal)
        }
        content = null
        below = false
        rejectedUnverified = 0
        rejectedAncestry = 0
        rejectedExcluded = 0
        for (ordinal in 1 until facts.size) {
            if (unknownScenes[ordinal] && ordinal != hostOrdinal && !descendsFrom(parents[ordinal], hostOrdinal)) complete = false
            val values = facts[ordinal] ?: continue
            val item = values.firstOrNull {
                it.first == KeyguardR44Markers.Marker.LARGE_CLOCK || it.first == KeyguardR44Markers.Marker.SMALL_CLOCK ||
                    it.first == KeyguardR44Markers.Marker.DEVICE_ENTRY
            } ?: continue
            when {
                hasExcludedAncestor(ordinal) -> rejectedExcluded++
                item.first == KeyguardR44Markers.Marker.DEVICE_ENTRY &&
                    (!genuineDeviceEntryResource || item.second != KeyguardR44Markers.Carrier.VIEW_ID) -> rejectedUnverified++
                !descendsFrom(parents[ordinal], hostOrdinal) -> rejectedAncestry++
                content == null -> {
                    content = KeyguardR44Witness(item.first, item.second, ordinal)
                    below = true
                }
            }
        }
    }

    private fun observe(marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier) {
        when (marker) {
            KeyguardR44Markers.Marker.HOST -> rawHost = (rawHost + 1).coerceAtMost(255)
            KeyguardR44Markers.Marker.DEVICE_ENTRY -> rawEntry = (rawEntry + 1).coerceAtMost(255)
            KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.Marker.SMALL_CLOCK ->
                rawClock = (rawClock + 1).coerceAtMost(255)
            else -> return
        }
        if (firstCandidate == null && marker != KeyguardR44Markers.Marker.HOST) {
            firstCandidate = marker
            firstCarrier = carrier
        }
    }

    fun hiddenNode(viewId: String?) {
        val marker = KeyguardR44Markers.exact(viewId) ?: return
        observe(marker, KeyguardR44Markers.Carrier.VIEW_ID)
        rejectedHidden = (rejectedHidden + 1).coerceAtMost(255)
    }

    data class NodeResult(val hostAncestor: Int?, val excluded: Boolean, val exclusions: List<String>,
                          val yieldedTo: KeyguardCardInspectionRequest? = null)

    fun restrictionObserved() { budget.restrictionObserved = true }

    /** An unresolved or potentially restrictive observed marker remains a
     * fail-closed obligation of this read. It cannot be discarded merely
     * because a later request is waiting. */
    fun safeToYield(): Boolean = complete && !foreign && !budget.restrictionObserved &&
        !budget.hardFailure && deferredPending == 0

    fun readNode(
        node: AccessibilityNodeInfo,
        expectedParent: AccessibilityNodeInfo?,
        ordinal: Int,
        parentOrdinal: Int,
        ancestor: Int?,
        excludedAncestor: Boolean,
        viewId: String?,
        authorityIsCurrent: () -> Boolean,
        beforeOptional: (() -> KeyguardCardInspectionRequest?)? = null,
    ): NodeResult {
        if (!verifiedRoot || !authorityIsCurrent()) {
            complete = false
            return NodeResult(ancestor, true, emptyList())
        }
        val owned = runCatching {
            node.packageName?.toString() == "com.android.systemui" && node.windowId == windowId && node.isVisibleToUser
        }.getOrDefault(false)
        if (!owned) {
            KeyguardR44Markers.exact(viewId)?.let {
                observe(it, KeyguardR44Markers.Carrier.VIEW_ID)
                rejectedForeign = (rejectedForeign + 1).coerceAtMost(255)
            }
            foreign = true
            complete = false
            return NodeResult(ancestor, true, emptyList())
        }
        if (deferred != null && ordinal in parents.indices) parents[ordinal] = parentOrdinal
        val markers = ArrayList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>(2)
        val directMarker = KeyguardR44Markers.exact(viewId)
        directMarker?.let { markers += it to KeyguardR44Markers.Carrier.VIEW_ID }
        if (viewId != null && directMarker == null &&
            KeyguardR44Markers.unknownMayRestrict(viewId, ancestor != null)) {
            unsupported += 1
            if (deferred != null && viewId.startsWith("scene:") && ordinal in unknownScenes.indices)
                unknownScenes[ordinal] = true
            else { complete = false; if (deferred != null) budget.hardFailure = true }
        }
        try {
            val eager = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
            val eagerMarker = KeyguardR44Markers.exact(eager)
            eagerMarker?.let { markers += it to KeyguardR44Markers.Carrier.EXTRA_EAGER }
            if (eager != null && eagerMarker == null) {
                unsupported += 1
                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
                if (deferred != null && eager.startsWith("scene:") && ordinal in unknownScenes.indices)
                    unknownScenes[ordinal] = true
                else if (KeyguardR44Markers.unknownMayRestrict(eager, nestedInHost)) {
                    complete = false
                    if (deferred != null) budget.hardFailure = true
                }
            }
            val hasDirectTag = markers.any { it.second == KeyguardR44Markers.Carrier.VIEW_ID &&
                it.first != KeyguardR44Markers.Marker.DEVICE_ENTRY }
            val hasEagerTag = eager != null
            val knownRestriction = markers.any { KeyguardR44Markers.exclusion(it.first) != null }
            if (knownRestriction) restrictionObserved()
            val excludedHereBeforeFetch = excludedAncestor ||
                viewId == "com.android.systemui:id/notification_stack_scroller" ||
                viewId == "com.android.systemui:id/notificationShelf"
            if (!excludedHereBeforeFetch && !budget.restrictionObserved &&
                (!hasDirectTag || deferred != null || liveSampleExtension) && !hasEagerTag &&
                node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) {
                advertised += 1
                // Consume this node's direct/eager exclusions before giving
                // the single reader to a newer request. Do not start another
                // optional framework call after a successful transfer.
                val next = if (safeToYield() && !knownRestriction) beforeOptional?.invoke() else null
                if (next != null) return NodeResult(ancestor, excludedAncestor, emptyList(), next)
                if (!authorityIsCurrent()) {
                    complete = false
                } else if (deferred != null) {
                    deferred.collect(this, node, expectedParent, ordinal, parentOrdinal, viewId)
                } else if (!budget.reserve(liveSampleExtension && hasVerifiedHost())) {
                    complete = false
                    budgetHit = true
                } else {
                    fetched += 1
                    val begin = SystemClock.uptimeMillis()
                    val refreshed = try { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }
                        catch (_: Exception) { false }
                    val duration = SystemClock.uptimeMillis() - begin
                    extraMs += duration
                    budget.elapsedMs += duration
                    optionalTiming?.invoke("optional", begin, begin + duration)
                    // The parent was already held by the DFS. Reacquiring it
                    // here validates the same ancestry after the only extra
                    // synchronous framework call; no additional walk occurs.
                    val stillOwned = refreshed && authorityIsCurrent() && runCatching {
                        node.windowId == windowId && node.packageName?.toString() == "com.android.systemui" &&
                            node.isVisibleToUser && node.viewIdResourceName == viewId
                    }.getOrDefault(false)
                    val parentMatches = if (!stillOwned || !authorityIsCurrent()) false else if (expectedParent == null) true else {
                        val parent = runCatching { node.parent }.getOrNull()
                        try { parent != null && parent == expectedParent } finally { parent?.recycle() }
                    }
                    if (!refreshed || !authorityIsCurrent() || !stillOwned || !parentMatches) {
                        complete = false
                        failed += 1
                    } else {
                        val value = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
                        if (value == null) { complete = false; failed += 1 }
                        else {
                            val marker = KeyguardR44Markers.exact(value)
                            if (marker == null) {
                                unsupported += 1
                                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
                                if (KeyguardR44Markers.unknownMayRestrict(value, nestedInHost)) complete = false
                            }
                            else markers += marker to KeyguardR44Markers.Carrier.EXTRA_LAZY
                        }
                    }
                }
            }
        } catch (_: Exception) {
            complete = false
            failed += 1
        }
        val exclusions = markers.mapNotNull { KeyguardR44Markers.exclusion(it.first) }
        val excluded = excludedAncestor || exclusions.isNotEmpty() ||
            viewId == "com.android.systemui:id/notification_stack_scroller" ||
            viewId == "com.android.systemui:id/notificationShelf"
        if (deferred != null && ordinal in excludedHere.indices) {
            excludedHere[ordinal] = exclusions.isNotEmpty() ||
                viewId == "com.android.systemui:id/notification_stack_scroller" ||
                viewId == "com.android.systemui:id/notificationShelf"
            markers.forEach { (marker, carrier) -> addFact(ordinal, marker, carrier) }
        }
        markers.forEach { (marker, carrier) ->
            observe(marker, carrier)
            if (marker == KeyguardR44Markers.Marker.DEVICE_ENTRY ||
                marker == KeyguardR44Markers.Marker.LARGE_CLOCK || marker == KeyguardR44Markers.Marker.SMALL_CLOCK) {
                when {
                    excluded -> rejectedExcluded = (rejectedExcluded + 1).coerceAtMost(255)
                    marker == KeyguardR44Markers.Marker.DEVICE_ENTRY &&
                        (!genuineDeviceEntryResource || carrier != KeyguardR44Markers.Carrier.VIEW_ID) ->
                        rejectedUnverified = (rejectedUnverified + 1).coerceAtMost(255)
                    ancestor == null || ancestor != host?.ordinal || ordinal == ancestor ->
                        rejectedAncestry = (rejectedAncestry + 1).coerceAtMost(255)
                }
            }
        }
        var childAncestor = ancestor
        if (!excluded) {
            val nodeHost = markers.firstOrNull { it.first == KeyguardR44Markers.Marker.HOST }
            if (nodeHost != null) {
                if (host != null && host?.ordinal != ordinal) complete = false
                else host = KeyguardR44Witness(nodeHost.first, nodeHost.second, ordinal)
                childAncestor = ordinal
            }
            val candidate = markers.firstOrNull {
                it.first == KeyguardR44Markers.Marker.LARGE_CLOCK || it.first == KeyguardR44Markers.Marker.SMALL_CLOCK ||
                    (it.first == KeyguardR44Markers.Marker.DEVICE_ENTRY && genuineDeviceEntryResource &&
                        it.second == KeyguardR44Markers.Carrier.VIEW_ID)
            }
            if (candidate != null && ancestor != null && ancestor == host?.ordinal && ordinal != ancestor && content == null) {
                content = KeyguardR44Witness(candidate.first, candidate.second, ordinal)
                below = true
            }
        }
        return NodeResult(childAncestor, excluded, exclusions)
    }

    fun finish(): KeyguardR44WindowEvidence {
        reconcileDeferred()
        return KeyguardR44WindowEvidence(
        verifiedRoot, active, host, content, below, complete, foreign,
        advertised = advertised, fetched = fetched, failed = failed, unsupported = unsupported,
        budgetHit = budgetHit, extraMs = extraMs,
        rawHost = rawHost, rawEntry = rawEntry, rawClock = rawClock,
        rejectedUnverified = rejectedUnverified, rejectedAncestry = rejectedAncestry,
        rejectedExcluded = rejectedExcluded, rejectedForeign = rejectedForeign, rejectedHidden = rejectedHidden,
        firstCandidate = firstCandidate, firstCarrier = firstCarrier,
        r443Overflow = candidateOverflow,
        r443Candidates = candidateMetrics.orEmpty().map { metric -> KeyguardR443CandidateObservation(
            windowId, metric.ordinal,
            if (hasExcludedAncestor(metric.ordinal)) "EXCLUDED" else if (descendsFrom(metric.parentOrdinal, host?.ordinal)) "HOST" else "OTHER",
            metric.rank, metric.status, metric.role, metric.costMs, metric.remaining, metric.remainingMs,
            metric.parentChecks, metric.parentMs,
        ) },
        )
    }
}
