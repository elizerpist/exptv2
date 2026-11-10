package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.os.SystemClock
import android.view.Display
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo

/** Scalar-only window facts used by the active-root decision and its JVM
 * regression tests. They intentionally carry neither a node nor package
 * content. */
internal data class KeyguardWindowReaderWindowMetadata(
    val id: Int,
    val type: Int,
    val displayId: Int,
    val active: Boolean,
)

/**
 * The accessibility framework normally invalidates its cache as it delivers
 * window/content events.  Clearing that cache is consequently an exceptional
 * freshness boundary, not a prerequisite for every event-driven read.
 *
 * This is captured with the request so a worker never decides freshness from
 * a later wake or a later surface result.  It is deliberately not a cached
 * surface decision: every SHOW still requires a complete current read.
 */
internal enum class KeyguardWindowFreshness {
    /** A normal accessibility/display event; use framework cache invalidation. */
    FRAMEWORK_EVENT,
    /** A service/wake lifecycle boundary has no equivalent prior event. */
    LIFECYCLE_BOUNDARY,
    /** The last current observation contradicted the visible surface. */
    CONTRADICTORY_OBSERVATION,
    /** A root/traversal was unavailable or incomplete, so evidence is missing. */
    MISSING_FRESHNESS_EVIDENCE;

    val requiresCacheClear: Boolean
        get() = this != FRAMEWORK_EVENT
}

internal object KeyguardWindowSnapshotReaderPolicy {
    /** API-33's overloads keep descendant prefetch interruptible.  In
     * particular, do not add FLAG_PREFETCH_UNINTERRUPTIBLE to the wake path:
     * that can make the root call wait for a whole prefetch batch. */
    fun interruptiblePrefetchFlags(apiLevel: Int = Build.VERSION.SDK_INT): Int =
        if (apiLevel >= Build.VERSION_CODES.TIRAMISU) {
            AccessibilityNodeInfo.FLAG_PREFETCH_DESCENDANTS_HYBRID
        } else 0

    fun shouldClearCache(freshness: KeyguardWindowFreshness): Boolean =
        freshness.requiresCacheClear

    /** Strategy selection intentionally has no cache-clear-result input. */
    fun canUseInterruptibleActiveRoot(
        apiLevel: Int,
        cacheEnabled: Boolean?,
        hasUnambiguousCandidate: Boolean,
        freshnessBoundaryEstablished: Boolean,
    ): Boolean = apiLevel >= Build.VERSION_CODES.TIRAMISU &&
        cacheEnabled == true && hasUnambiguousCandidate && freshnessBoundaryEstablished

    fun activeCandidate(
        windows: List<KeyguardWindowReaderWindowMetadata>,
        knownOwn: KeyguardOwnOverlayIdentity?,
        attachGeneration: Long,
    ): KeyguardWindowReaderWindowMetadata? = windows
        .filter { window ->
            window.displayId == Display.DEFAULT_DISPLAY && window.active &&
                !isExactKnownOwn(window, knownOwn, attachGeneration)
        }
        .singleOrNull()

    fun acceptsActiveRoot(
        candidate: KeyguardWindowReaderWindowMetadata,
        returnedWindowId: Int?,
        returnedPackageName: CharSequence?,
        currentWindows: List<KeyguardWindowReaderWindowMetadata>,
    ): Boolean = returnedWindowId == candidate.id && returnedPackageName != null &&
        currentWindows.any { it.id == candidate.id && it.displayId == Display.DEFAULT_DISPLAY }

    fun isExactKnownOwn(
        window: KeyguardWindowReaderWindowMetadata,
        knownOwn: KeyguardOwnOverlayIdentity?,
        attachGeneration: Long,
    ): Boolean {
        val known = knownOwn ?: return false
        return known.windowId == window.id && known.displayId == window.displayId &&
            known.attachGeneration == attachGeneration &&
            window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
    }
}

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
        val freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    )

    data class Timing(
        val readerStrategy: String = "LEGACY_PER_WINDOW",
        val prefetchFlags: Int = 0,
        val cacheEnabled: Boolean? = null,
        val freshnessPolicy: String = KeyguardWindowFreshness.FRAMEWORK_EVENT.name,
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
        var freshnessPolicy = KeyguardWindowFreshness.FRAMEWORK_EVENT.name
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
            freshnessPolicy = freshnessPolicy,
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
        // Framework-managed invalidation is the normal event-driven path.
        // Explicit cache clearing is reserved for a lifecycle boundary,
        // contradictory observation, or missing freshness evidence. Nothing
        // here carries a prior MAIN result forward as show authority.
        val cacheEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            runCatching { service.isCacheEnabled }.getOrNull()
        } else null
        val cacheClearResult = when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU -> "apiBelow33"
            cacheEnabled == false -> "cacheDisabled"
            cacheEnabled == null -> "cacheUnavailable"
            !authorityIsCurrent() -> "authorityStaleBeforeCacheClear"
            !KeyguardWindowSnapshotReaderPolicy.shouldClearCache(request.freshness) -> "notRequiredFrameworkManaged"
            else -> runCatching {
                if (service.clearCache()) "cleared:${request.freshness.name}" else "clearReturnedFalse"
            }.getOrElse { "clearFailed:${it.javaClass.simpleName}" }
        }
        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, 0L, 0L, 0,
            Timing(
                cacheEnabled = cacheEnabled,
                freshnessPolicy = request.freshness.name,
                cacheClearResult = cacheClearResult,
            ), abortedStale = true,
        )
        val windowsStartedAt = SystemClock.uptimeMillis()
        val currentWindows = runCatching { service.windows }.getOrElse { emptyList() }
        val windowsReadMs = SystemClock.uptimeMillis() - windowsStartedAt
        val treeStartedAt = SystemClock.uptimeMillis()
        val timing = Accumulator(windowsReadMs)
        timing.cacheEnabled = cacheEnabled
        timing.freshnessPolicy = request.freshness.name
        timing.cacheClearResult = cacheClearResult
        val prefetch = KeyguardWindowSnapshotReaderPolicy.interruptiblePrefetchFlags()
        timing.prefetchFlags = prefetch
        timing.strategy = if (prefetch != 0) "PER_WINDOW_INTERRUPTIBLE" else "LEGACY_PER_WINDOW"

        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, windowsReadMs,
            SystemClock.uptimeMillis() - treeStartedAt, 0, timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt),
            abortedStale = true,
        )

        val primary = currentWindows.filter { displayId(it) == Display.DEFAULT_DISPLAY }
        val metadata = primary.map(::metadata)
        val activeCandidate = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
            metadata, request.knownOwn, request.attachGeneration,
        )
        // The active-root route is an acquisition strategy, not a reward for
        // having just cleared the whole cache. A connected enabled cache and
        // a validated candidate are sufficient; explicit invalidation above
        // remains available when evidence requires it.
        val freshnessBoundaryEstablished = !KeyguardWindowSnapshotReaderPolicy.shouldClearCache(request.freshness) ||
            cacheClearResult.startsWith("cleared:")
        val canBatch = KeyguardWindowSnapshotReaderPolicy.canUseInterruptibleActiveRoot(
            apiLevel = Build.VERSION.SDK_INT,
            cacheEnabled = cacheEnabled,
            hasUnambiguousCandidate = activeCandidate != null,
            freshnessBoundaryEstablished = freshnessBoundaryEstablished,
        )
        var activeRoot: AccessibilityNodeInfo? = null
        var activeWindowId: Int? = null

        if (canBatch && authorityIsCurrent()) {
            val candidate = requireNotNull(activeCandidate)
            timing.activeCandidateWindowId = candidate.id
            val startedAt = SystemClock.uptimeMillis()
            activeRoot = runCatching { service.getRootInActiveWindow(prefetch) }.getOrNull()
            timing.activeRoot(candidate.id, SystemClock.uptimeMillis() - startedAt)
            val returned = activeRoot
            timing.returnedRootWindowId = returned?.windowId
            val accepted = authorityIsCurrent() && KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
                candidate, returned?.windowId, returned?.packageName, metadata,
            )
            if (accepted) {
                timing.strategy = "ACTIVE_ROOT_INTERRUPTIBLE_PLUS_PER_WINDOW"
                timing.activeRootAccepted = true
                activeWindowId = candidate.id
            } else {
                timing.fallbackReason = when {
                    !authorityIsCurrent() -> "authorityStaleAfterActiveRoot"
                    returned == null -> "activeRootNull"
                    returned.windowId != candidate.id -> "activeRootWindowMismatch"
                    metadata.none { it.id == candidate.id && it.displayId == Display.DEFAULT_DISPLAY } -> "activeCandidateNotPrimary"
                    else -> "activeRootPackageMissing"
                }
                returned?.recycle()
                activeRoot = null
            }
        } else if (timing.fallbackReason == null) {
            timing.fallbackReason = when {
                Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU -> "apiBelow33"
                activeCandidate == null && metadata.none { it.active && !KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(it, request.knownOwn, request.attachGeneration) } -> "noActiveCandidate"
                activeCandidate == null -> "ambiguousActiveCandidates"
                cacheEnabled == false -> "cacheDisabled"
                cacheEnabled == null -> "cacheUnavailable"
                !freshnessBoundaryEstablished -> "freshnessBoundary:$cacheClearResult"
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
                runCatching {
                    if (prefetch != 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        window.getRoot(prefetch)
                    } else {
                        window.root
                    }
                }.getOrNull().also {
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
                visibleIds(root, window.id, prefetch.takeIf { it != 0 }, authorityIsCurrent, timing).also {
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
                truncated = true
            }
        }
        visit(root)
        return VisibleIds(ids, truncated, visited, aborted, readsAfterInvalidation)
    }

    private fun isExactKnownOwn(window: AccessibilityWindowInfo, request: Request): Boolean {
        return KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(
            metadata(window), request.knownOwn, request.attachGeneration,
        )
    }

    private fun metadata(window: AccessibilityWindowInfo) = KeyguardWindowReaderWindowMetadata(
        id = window.id,
        type = window.type,
        displayId = displayId(window),
        active = window.isActive,
    )

    private fun displayId(window: AccessibilityWindowInfo): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY

    private companion object {
        const val MAX_VISITED_NODES = 96
        val SYSTEM_PACKAGES = setOf("com.android.systemui", "com.android.keyguard", "android")
    }
}
