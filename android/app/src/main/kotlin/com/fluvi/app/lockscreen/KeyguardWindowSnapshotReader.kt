package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.os.SystemClock
import android.view.Display
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo

/**
 * One bounded, data-minimising boundary for reading the accessibility window
 * tree.  The API 33 active-root route is an optimisation only: every result is
 * checked against the window metadata captured for this inspection and falls
 * back to the established per-window path when that proof is unavailable.
 */
internal class KeyguardWindowSnapshotReader(
    private val service: AccessibilityService,
    private val ownPackageName: String,
) {
    data class Request(
        val knownOwn: KeyguardOwnOverlayIdentity?,
        val attachGeneration: Long,
    )

    data class Timing(
        val readerStrategy: String = "LEGACY_PER_WINDOW",
        val prefetchFlags: Int = 0,
        val cacheEnabled: Boolean? = null,
        val cacheClearResult: String = "notAttempted",
        val activeCandidateWindowId: Int? = null,
        val returnedRootWindowId: Int? = null,
        val activeRootAccepted: Boolean = false,
        val fallbackReason: String? = null,
        val getWindowsMs: Long = 0L,
        val relevantWindowCount: Int = 0,
        val activeRootCallCount: Int = 0,
        val activeRootTotalMs: Long = 0L,
        val rootAcquisitionCount: Int = 0,
        val rootAcquisitionTotalMs: Long = 0L,
        val rootAcquisitionMaxMs: Long = 0L,
        val childAcquisitionCount: Int = 0,
        val childAcquisitionTotalMs: Long = 0L,
        val childAcquisitionMaxMs: Long = 0L,
        val localProcessingMs: Long = 0L,
        val slowCalls: List<String> = emptyList(),
    )

    data class Result(
        val snapshots: List<KeyguardWindowSnapshot>,
        val rootUnavailable: Boolean,
        val walkTruncated: Boolean,
        val windowsReadMs: Long,
        val treeScanMs: Long,
        val visitedNodeCount: Int,
        val timing: Timing,
        val abortedStale: Boolean = false,
        val nodeReadsAfterInvalidation: Int = 0,
    )

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
        val visited: Int,
        val aborted: Boolean,
        val readsAfterInvalidation: Int,
    )

    private class Accumulator(private val getWindowsMs: Long) {
        var strategy = "LEGACY_PER_WINDOW"
        var prefetchFlags = 0
        var cacheEnabled: Boolean? = null
        var cacheClearResult = "notAttempted"
        var activeCandidateWindowId: Int? = null
        var returnedRootWindowId: Int? = null
        var activeRootAccepted = false
        var fallbackReason: String? = null
        var relevantWindows = 0
        var activeRootCount = 0
        var activeRootTotal = 0L
        var rootCount = 0
        var rootTotal = 0L
        var rootMax = 0L
        var childCount = 0
        var childTotal = 0L
        var childMax = 0L
        private val slow = mutableListOf<Pair<Long, String>>()

        fun activeRoot(windowId: Int, elapsed: Long) {
            activeRootCount += 1
            activeRootTotal += elapsed
            slow += elapsed to "activeRoot:w=$windowId,$elapsed"
        }

        fun root(window: AccessibilityWindowInfo, displayId: Int, elapsed: Long) {
            rootCount += 1
            rootTotal += elapsed
            rootMax = maxOf(rootMax, elapsed)
            slow += elapsed to "root:w=${window.id},t=${window.type},d=$displayId,$elapsed"
        }

        fun child(windowId: Int, index: Int, elapsed: Long) {
            childCount += 1
            childTotal += elapsed
            childMax = maxOf(childMax, elapsed)
            slow += elapsed to "child:w=$windowId,i=$index,$elapsed"
        }

        fun snapshot(treeElapsed: Long) = Timing(
            readerStrategy = strategy,
            prefetchFlags = prefetchFlags,
            cacheEnabled = cacheEnabled,
            cacheClearResult = cacheClearResult,
            activeCandidateWindowId = activeCandidateWindowId,
            returnedRootWindowId = returnedRootWindowId,
            activeRootAccepted = activeRootAccepted,
            fallbackReason = fallbackReason,
            getWindowsMs = getWindowsMs,
            relevantWindowCount = relevantWindows,
            activeRootCallCount = activeRootCount,
            activeRootTotalMs = activeRootTotal,
            rootAcquisitionCount = rootCount,
            rootAcquisitionTotalMs = rootTotal,
            rootAcquisitionMaxMs = rootMax,
            childAcquisitionCount = childCount,
            childAcquisitionTotalMs = childTotal,
            childAcquisitionMaxMs = childMax,
            localProcessingMs = (treeElapsed - activeRootTotal - rootTotal - childTotal).coerceAtLeast(0L),
            slowCalls = slow.sortedByDescending { it.first }.take(3).map { it.second },
        )
    }

    /** The caller owns all lifecycle generations.  This reader never samples
     * mutable View state; it merely stops requesting nodes after authority has
     * become stale. */
    fun read(request: Request, authorityIsCurrent: () -> Boolean): Result {
        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, 0L, 0L, 0, Timing(), abortedStale = true,
        )
        // Establish the API-33 freshness boundary before obtaining window
        // metadata. Prefetched descendants can then be reused *within* this
        // one inspection; no node is retained across inspections.
        val cacheEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            runCatching { service.isCacheEnabled }.getOrNull()
        } else null
        val cacheClearResult = when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU -> "apiBelow33"
            cacheEnabled == false -> "cacheDisabled"
            cacheEnabled == null -> "cacheUnavailable"
            !authorityIsCurrent() -> "authorityStaleBeforeCacheClear"
            else -> runCatching {
                if (service.clearCache()) "cleared" else "clearReturnedFalse"
            }.getOrElse { "clearFailed:${it.javaClass.simpleName}" }
        }
        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, 0L, 0L, 0,
            Timing(cacheEnabled = cacheEnabled, cacheClearResult = cacheClearResult), abortedStale = true,
        )
        val windowsStartedAt = SystemClock.uptimeMillis()
        val currentWindows = runCatching { service.windows }.getOrElse { emptyList() }
        val windowsReadMs = SystemClock.uptimeMillis() - windowsStartedAt
        val treeStartedAt = SystemClock.uptimeMillis()
        val timing = Accumulator(windowsReadMs)
        timing.cacheEnabled = cacheEnabled
        timing.cacheClearResult = cacheClearResult
        val prefetch = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            AccessibilityNodeInfo.FLAG_PREFETCH_DESCENDANTS_HYBRID or
                AccessibilityNodeInfo.FLAG_PREFETCH_UNINTERRUPTIBLE
        } else 0
        timing.prefetchFlags = prefetch

        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, windowsReadMs,
            SystemClock.uptimeMillis() - treeStartedAt, 0, timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt),
            abortedStale = true,
        )

        val primary = currentWindows.filter { displayId(it) == Display.DEFAULT_DISPLAY }
        val activeCandidates = primary.filter { window ->
            window.isActive && !isExactKnownOwn(window, request)
        }
        val canBatch = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activeCandidates.size == 1
        var activeRoot: AccessibilityNodeInfo? = null
        var activeWindowId: Int? = null

        if (canBatch && timing.cacheClearResult == "cleared" && authorityIsCurrent()) {
            val candidate = activeCandidates.single()
            timing.activeCandidateWindowId = candidate.id
            val startedAt = SystemClock.uptimeMillis()
            activeRoot = runCatching { service.getRootInActiveWindow(prefetch) }.getOrNull()
            timing.activeRoot(candidate.id, SystemClock.uptimeMillis() - startedAt)
            val returned = activeRoot
            timing.returnedRootWindowId = returned?.windowId
            val candidateStillPrimary = primary.any { it.id == candidate.id && displayId(it) == Display.DEFAULT_DISPLAY }
            val accepted = authorityIsCurrent() && returned != null &&
                returned.windowId == candidate.id && candidateStillPrimary && returned.packageName != null
            if (accepted) {
                timing.strategy = "ACTIVE_ROOT_BATCHED_PLUS_PER_WINDOW"
                timing.activeRootAccepted = true
                activeWindowId = candidate.id
            } else {
                timing.fallbackReason = when {
                    !authorityIsCurrent() -> "authorityStaleAfterActiveRoot"
                    returned == null -> "activeRootNull"
                    returned.windowId != candidate.id -> "activeRootWindowMismatch"
                    !candidateStillPrimary -> "activeCandidateNotPrimary"
                    else -> "activeRootPackageMissing"
                }
                returned?.recycle()
                activeRoot = null
            }
        } else if (timing.fallbackReason == null) {
            timing.fallbackReason = when {
                Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU -> "apiBelow33"
                activeCandidates.isEmpty() -> "noActiveCandidate"
                activeCandidates.size > 1 -> "ambiguousActiveCandidates"
                timing.cacheClearResult != "cleared" -> timing.cacheClearResult
                else -> "authorityStaleBeforeActiveRoot"
            }
        }

        var unavailableRoot = false
        var walkTruncated = false
        var visited = 0
        var readsAfterInvalidation = 0
        val snapshots = mutableListOf<KeyguardWindowSnapshot>()
        for (window in primary) {
            if (!authorityIsCurrent()) {
                activeRoot?.recycle()
                return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visited,
                    timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), true, readsAfterInvalidation)
            }
            timing.relevantWindows += 1
            if (isExactKnownOwn(window, request)) {
                snapshots += KeyguardWindowSnapshot(
                    windowId = window.id, packageName = ownPackageName, type = window.type,
                    layer = window.layer, displayId = displayId(window), ownOverlay = true,
                )
                continue
            }
            val root = if (window.id == activeWindowId) {
                activeRoot.also { activeRoot = null }
            } else {
                val rootStarted = SystemClock.uptimeMillis()
                runCatching { window.root }.getOrNull().also {
                    timing.root(window, displayId(window), SystemClock.uptimeMillis() - rootStarted)
                }
            }
            if (!authorityIsCurrent()) {
                root?.recycle()
                readsAfterInvalidation += 1
                return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visited,
                    timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), true, readsAfterInvalidation)
            }
            if (root == null) unavailableRoot = true
            val rootPackage = root?.packageName?.toString()
            val own = rootPackage == ownPackageName && window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val visible = if (rootPackage in SYSTEM_PACKAGES && root != null) {
                visibleIds(root, window.id, prefetch.takeIf { timing.activeRootAccepted }, authorityIsCurrent, timing).also {
                    walkTruncated = walkTruncated || it.truncated
                    visited += it.visited
                    readsAfterInvalidation += it.readsAfterInvalidation
                }
            } else null
            root?.recycle()
            if (visible?.aborted == true) return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                SystemClock.uptimeMillis() - treeStartedAt, visited,
                timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), true, readsAfterInvalidation)
            snapshots += KeyguardWindowSnapshot(
                windowId = window.id, packageName = rootPackage, type = window.type, layer = window.layer,
                displayId = displayId(window), ownOverlay = own, visibleViewIds = visible?.ids.orEmpty(),
            )
        }
        activeRoot?.recycle()
        val treeElapsed = SystemClock.uptimeMillis() - treeStartedAt
        return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs, treeElapsed, visited, timing.snapshot(treeElapsed), false, readsAfterInvalidation)
    }

    private fun visibleIds(
        root: AccessibilityNodeInfo,
        windowId: Int,
        prefetchFlags: Int?,
        authorityIsCurrent: () -> Boolean,
        timing: Accumulator,
    ): VisibleIds {
        val ids = linkedSetOf<String>()
        var visited = 0
        var truncated = false
        var aborted = false
        var readsAfterInvalidation = 0
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null || aborted) return
            if (!authorityIsCurrent()) { aborted = true; return }
            if (visited >= MAX_VISITED_NODES) { truncated = true; return }
            visited += 1
            try {
                if (!node.isVisibleToUser) return
                node.viewIdResourceName?.let(ids::add)
                node.className?.toString()?.takeIf { it.contains("BouncerContent") }?.let { ids.add("element:BouncerContent") }
                for (index in 0 until node.childCount) {
                    if (!authorityIsCurrent()) { aborted = true; return }
                    val startedAt = SystemClock.uptimeMillis()
                    val child = runCatching {
                        if (prefetchFlags != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            node.getChild(index, prefetchFlags)
                        } else node.getChild(index)
                    }.getOrNull()
                    timing.child(windowId, index, SystemClock.uptimeMillis() - startedAt)
                    if (!authorityIsCurrent()) {
                        child?.recycle()
                        readsAfterInvalidation += 1
                        aborted = true
                        return
                    }
                    visit(child)
                    child?.recycle()
                    if (aborted) return
                }
            } catch (_: Exception) {
                // An incomplete SystemUI tree must remain UNKNOWN, never a
                // partial positive proof of the keyguard.
            }
        }
        visit(root)
        return VisibleIds(ids, truncated, visited, aborted, readsAfterInvalidation)
    }

    private fun isExactKnownOwn(window: AccessibilityWindowInfo, request: Request): Boolean {
        val known = request.knownOwn ?: return false
        return known.windowId == window.id && known.displayId == displayId(window) &&
            known.attachGeneration == request.attachGeneration &&
            window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
    }

    private fun displayId(window: AccessibilityWindowInfo): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY

    private companion object {
        const val MAX_VISITED_NODES = 96
        val SYSTEM_PACKAGES = setOf("com.android.systemui", "com.android.keyguard", "android")
    }
}
