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

    /** A synchronous platform IPC already in progress cannot be preempted.
     * This limits additional optional IPC after it returns. */
    fun reserve(): Boolean {
        if (restrictionObserved) return false
        if (fetched >= MAX_CALLS || elapsedMs >= MAX_ELAPSED_MS) {
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
    fun safeToYield(): Boolean = complete && !foreign && !budget.restrictionObserved

    fun readNode(
        node: AccessibilityNodeInfo,
        expectedParent: AccessibilityNodeInfo?,
        ordinal: Int,
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
        val markers = ArrayList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>(2)
        val directMarker = KeyguardR44Markers.exact(viewId)
        directMarker?.let { markers += it to KeyguardR44Markers.Carrier.VIEW_ID }
        if (viewId != null && directMarker == null &&
            KeyguardR44Markers.unknownMayRestrict(viewId, ancestor != null)) {
            unsupported += 1
            complete = false
        }
        try {
            val eager = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
            val eagerMarker = KeyguardR44Markers.exact(eager)
            eagerMarker?.let { markers += it to KeyguardR44Markers.Carrier.EXTRA_EAGER }
            if (eager != null && eagerMarker == null) {
                unsupported += 1
                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
                if (KeyguardR44Markers.unknownMayRestrict(eager, nestedInHost)) complete = false
            }
            val hasDirectTag = markers.any { it.second == KeyguardR44Markers.Carrier.VIEW_ID &&
                it.first != KeyguardR44Markers.Marker.DEVICE_ENTRY }
            val hasEagerTag = eager != null
            val knownRestriction = markers.any { KeyguardR44Markers.exclusion(it.first) != null }
            if (knownRestriction) restrictionObserved()
            if (!excludedAncestor && !budget.restrictionObserved && !hasDirectTag && !hasEagerTag &&
                node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) {
                advertised += 1
                // Consume this node's direct/eager exclusions before giving
                // the single reader to a newer request. Do not start another
                // optional framework call after a successful transfer.
                val next = if (complete && !knownRestriction) beforeOptional?.invoke() else null
                if (next != null) return NodeResult(ancestor, excludedAncestor, emptyList(), next)
                if (!authorityIsCurrent()) {
                    complete = false
                } else if (!budget.reserve()) {
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

    fun finish(): KeyguardR44WindowEvidence = KeyguardR44WindowEvidence(
        verifiedRoot, active, host, content, below, complete, foreign,
        advertised = advertised, fetched = fetched, failed = failed, unsupported = unsupported,
        budgetHit = budgetHit, extraMs = extraMs,
        rawHost = rawHost, rawEntry = rawEntry, rawClock = rawClock,
        rejectedUnverified = rejectedUnverified, rejectedAncestry = rejectedAncestry,
        rejectedExcluded = rejectedExcluded, rejectedForeign = rejectedForeign, rejectedHidden = rejectedHidden,
        firstCandidate = firstCandidate, firstCarrier = firstCarrier,
    )
}
