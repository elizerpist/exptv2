package com.fluvi.app.lockscreen

import android.os.Bundle
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo

/** One budget is shared by every window in a physical inspection. */
internal class KeyguardR44ExtraBudget {
    var fetched = 0
    var budgetHit = false
    var elapsedMs = 0L
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

    data class NodeResult(val hostAncestor: Int?, val excluded: Boolean, val exclusions: List<String>)

    fun readNode(
        node: AccessibilityNodeInfo,
        expectedParent: AccessibilityNodeInfo?,
        ordinal: Int,
        ancestor: Int?,
        excludedAncestor: Boolean,
        viewId: String?,
        authorityIsCurrent: () -> Boolean,
    ): NodeResult {
        if (!verifiedRoot || !authorityIsCurrent()) {
            complete = false
            return NodeResult(ancestor, true, emptyList())
        }
        val owned = runCatching {
            node.packageName?.toString() == "com.android.systemui" && node.windowId == windowId && node.isVisibleToUser
        }.getOrDefault(false)
        if (!owned) {
            foreign = true
            complete = false
            return NodeResult(ancestor, true, emptyList())
        }
        val markers = ArrayList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>(2)
        KeyguardR44Markers.exact(viewId)?.let { markers += it to KeyguardR44Markers.Carrier.VIEW_ID }
        try {
            val eager = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
            val eagerMarker = KeyguardR44Markers.exact(eager)
            eagerMarker?.let { markers += it to KeyguardR44Markers.Carrier.EXTRA_EAGER }
            if (eager != null && eagerMarker == null) {
                unsupported += 1
                if (KeyguardR44Markers.unknownMayRestrict(eager)) complete = false
            }
            val hasDirectTag = markers.any { it.second == KeyguardR44Markers.Carrier.VIEW_ID &&
                it.first != KeyguardR44Markers.Marker.DEVICE_ENTRY }
            val hasEagerTag = eager != null
            if (!hasDirectTag && !hasEagerTag && node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) {
                advertised += 1
                if (budget.fetched >= 4) {
                    complete = false
                    budgetHit = true
                    budget.budgetHit = true
                } else if (authorityIsCurrent()) {
                    budget.fetched += 1
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
                                if (KeyguardR44Markers.unknownMayRestrict(value)) complete = false
                            }
                            else markers += marker to KeyguardR44Markers.Carrier.EXTRA_LAZY
                        }
                    }
                } else complete = false
            }
        } catch (_: Exception) {
            complete = false
            failed += 1
        }
        val exclusions = markers.mapNotNull { KeyguardR44Markers.exclusion(it.first) }
        val excluded = excludedAncestor || exclusions.isNotEmpty() ||
            viewId == "com.android.systemui:id/notification_stack_scroller" ||
            viewId == "com.android.systemui:id/notificationShelf"
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
    )
}
