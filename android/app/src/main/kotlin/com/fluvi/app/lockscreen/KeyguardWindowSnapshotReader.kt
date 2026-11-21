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

/** The historical R15 zero-flag experiment remains test-only; normal R18
 * uses interruptible hybrid prefetch on a single eligible API-35 root. */
internal enum class KeyguardActiveRootStrategy { STOCK, R18_INITIAL_HYBRID, R15_HISTORICAL_ZERO }

internal object KeyguardWindowSnapshotReaderPolicy {
    /** Restore the measured 47002e5 batching configuration. A root may wait
     * for its batch; the tradeoff is fewer subsequent remote child waits.
     * Flags specify acquisition, not a performance guarantee. */
    fun batchedPrefetchFlags(apiLevel: Int = Build.VERSION.SDK_INT): Int =
        if (apiLevel >= Build.VERSION_CODES.TIRAMISU) {
            AccessibilityNodeInfo.FLAG_PREFETCH_DESCENDANTS_HYBRID or
                AccessibilityNodeInfo.FLAG_PREFETCH_UNINTERRUPTIBLE
        } else 0

    /** Only the separately authorized initial active-root call changes.
     * Child traversal and per-window fallback keep their existing strategy. */
    fun activeRootPrefetchFlags(initialRootOnly: Boolean, apiLevel: Int = Build.VERSION.SDK_INT): Int =
        activeRootPrefetchFlags(if (initialRootOnly) KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO
            else KeyguardActiveRootStrategy.STOCK, apiLevel)

    fun activeRootPrefetchFlags(strategy: KeyguardActiveRootStrategy, apiLevel: Int = Build.VERSION.SDK_INT): Int =
        when {
            strategy == KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO && apiLevel >= Build.VERSION_CODES.TIRAMISU -> 0
            strategy == KeyguardActiveRootStrategy.R18_INITIAL_HYBRID && apiLevel == 35 ->
                AccessibilityNodeInfo.FLAG_PREFETCH_DESCENDANTS_HYBRID
            else -> batchedPrefetchFlags(apiLevel)
        }

    fun shouldClearCache(freshness: KeyguardWindowFreshness): Boolean =
        freshness.requiresCacheClear

    /** Shared production/test boundary. The acknowledgement is evidence of
     * clearing (or disabled caching), never of merely scheduling a retry. */
    fun establishFreshness(
        freshness: KeyguardWindowFreshness,
        apiLevel: Int,
        cacheEnabled: Boolean?,
        authorityIsCurrent: () -> Boolean,
        clearCache: () -> Boolean,
        onEstablished: () -> Unit,
    ): String {
        val result = when {
            apiLevel < 33 -> "apiBelow33"
            cacheEnabled == false -> "cacheDisabled"
            cacheEnabled == null -> "cacheUnavailable"
            !authorityIsCurrent() -> "authorityStaleBeforeCacheClear"
            !shouldClearCache(freshness) -> "notRequiredFrameworkManaged"
            else -> runCatching {
                if (clearCache()) "cleared:${freshness.name}" else "clearReturnedFalse"
            }.getOrElse { "clearFailed:${it.javaClass.simpleName}" }
        }
        if (authorityIsCurrent() && (result.startsWith("cleared:") || result == "cacheDisabled")) {
            onEstablished()
        }
        return result
    }

    /** Strategy selection intentionally has no cache-clear-result input. */
    fun canUseBatchedActiveRoot(
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

    fun canUseCandidateWithStrictOwnAttribution(strict: Boolean, candidate: KeyguardWindowReaderWindowMetadata?): Boolean =
        !strict || candidate?.type != AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY

    /** Conservative pre-root check: an unknown overlay or any additional
     * non-own window remains on the full normal inspection path. */
    fun cleanOpeningInventory(
        canBatch: Boolean,
        windows: List<KeyguardWindowReaderWindowMetadata>,
        knownOwn: KeyguardOwnOverlayIdentity?,
        attachment: Long,
        candidate: KeyguardWindowReaderWindowMetadata?,
    ): Boolean {
        if (!canBatch || candidate == null) return false
        val other = windows.filterNot { isExactKnownOwn(it, knownOwn, attachment) }
        return other.size == 1 && other.single() == candidate &&
            candidate.type == AccessibilityWindowInfo.TYPE_SYSTEM
    }

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

/** Tiny inlined acquisition boundary: test callbacks can record the same
 * arguments and ordering as the framework calls without replacing any
 * classifier, cache or visibility policy. */
internal object KeyguardWindowAcquisitionCalls {
    inline fun <T> activeRoot(initialRootOnly: Boolean, apiLevel: Int, call: (Int) -> T): T =
        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(initialRootOnly, apiLevel))

    inline fun <T> activeRoot(strategy: KeyguardActiveRootStrategy, apiLevel: Int, call: (Int) -> T): T =
        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(strategy, apiLevel))

    inline fun <T> child(prefetchFlags: Int?, apiLevel: Int, batched: (Int) -> T, legacy: () -> T): T =
        if (prefetchFlags != null && apiLevel >= Build.VERSION_CODES.TIRAMISU) batched(prefetchFlags) else legacy()
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
        val initialRootOnly: Boolean = false,
        /** Invoked only at an eligible physical active-root call, after the
         * cache/freshness/window checks; no View or Binder call under its lock. */
        val activeRootStrategyAtCall: (() -> KeyguardActiveRootStrategy)? = null,
        val knownOwnAtInventory: (() -> KeyguardOwnOverlayIdentity?)? = null,
        val strictOwnAttribution: Boolean = false,
        val onDecisiveSystemMarker: (() -> Unit)? = null,
        /** Both callbacks are absent on every non-opening route. The first is
         * a volatile scalar hint; the second claims a real successor only at
         * a useful, fully inspected acquisition boundary. */
        val openingYieldHint: (() -> Boolean)? = null,
        val openingFirstIngressUptime: (() -> Long)? = null,
        val openingChildBefore: ((Int, Int) -> Unit)? = null,
        val openingChildReturned: ((Int, Int, Boolean) -> Unit)? = null,
        val claimOpeningYield: ((String, Boolean, Boolean, Int, Int, Int) -> KeyguardCardInspectionRequest?)? = null,
    )

    data class Timing(
        val readerStrategy: String = "LEGACY_PER_WINDOW",
        val prefetchFlags: Int = 0,
        /** Actual active-root argument; null means that API was not called. */
        val activeRootPrefetchFlags: Int? = null,
        /** Child argument selected after active-root acceptance, not proof a child existed. */
        val acceptedChildPrefetchFlags: Int? = null,
        val cacheEnabled: Boolean? = null,
        val freshnessPolicy: String = KeyguardWindowFreshness.FRAMEWORK_EVENT.name,
        val cacheClearResult: String = "notAttempted",
        val activeCandidateWindowId: Int? = null,
        val returnedRootWindowId: Int? = null,
        val activeRootAccepted: Boolean = false,
        val fallbackReason: String? = null,
        val ownAttributionAmbiguous: Boolean = false,
        val getWindowsMs: Long = 0L,
        val relevantWindowCount: Int = 0,
        val activeRootCallCount: Int = 0,
        val activeRootTotalMs: Long = 0L,
        val rootAcquisitionCount: Int = 0,
        val rootAcquisitionTotalMs: Long = 0L,
        val rootAcquisitionMaxMs: Long = 0L,
        val childAcquisitionCount: Int = 0,
        val childAcquisitionTotalMs: Long = 0L,
        val firstChildAcquisitionMs: Long? = null,
        val childAcquisitionMaxMs: Long = 0L,
        val firstNullRootId: Int? = null,
        val firstNullRootType: Int? = null,
        val firstNullRootDisplay: Int? = null,
        val firstNullRootRelativeLayer: Long? = null,
        val firstNullRootSource: String? = null,
        val localProcessingMs: Long = 0L,
        val slowCalls: List<String> = emptyList(),
        val walkTruncationReasons: Set<String> = emptySet(),
        val ingressCallKind: String? = null,
        val ingressCallBegin: Long? = null,
        val ingressCallEnd: Long? = null,
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
        val yieldedTo: KeyguardCardInspectionRequest? = null,
    )

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
        val visited: Int,
        val aborted: Boolean,
        val readsAfterInvalidation: Int,
        val yieldedTo: KeyguardCardInspectionRequest?,
    )

    private class Accumulator(private val getWindowsMs: Long) {
        var strategy = "LEGACY_PER_WINDOW"
        var prefetchFlags = 0
        var activeRootPrefetchFlags: Int? = null
        var acceptedChildPrefetchFlags: Int? = null
        var cacheEnabled: Boolean? = null
        var freshnessPolicy = KeyguardWindowFreshness.FRAMEWORK_EVENT.name
        var cacheClearResult = "notAttempted"
        var activeCandidateWindowId: Int? = null
        var returnedRootWindowId: Int? = null
        var activeRootAccepted = false
        var fallbackReason: String? = null
        var ownAttributionAmbiguous = false
        var relevantWindows = 0
        var activeRootCount = 0
        var activeRootTotal = 0L
        var rootCount = 0
        var rootTotal = 0L
        var rootMax = 0L
        var childCount = 0
        var childTotal = 0L
        var firstChildMs: Long? = null
        var childMax = 0L
        var firstNullRootId: Int? = null
        var firstNullRootType: Int? = null
        var firstNullRootDisplay: Int? = null
        var firstNullRootRelativeLayer: Long? = null
        var firstNullRootSource: String? = null
        val truncationReasons = linkedSetOf<String>()
        var ingressCallKind: String? = null
        var ingressCallBegin: Long? = null
        var ingressCallEnd: Long? = null
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
            if (firstChildMs == null) firstChildMs = elapsed
            childTotal += elapsed
            childMax = maxOf(childMax, elapsed)
            slow += elapsed to "child:w=$windowId,i=$index,$elapsed"
        }

        fun nullRoot(id: Int, type: Int, display: Int, relativeLayer: Long?, source: String) {
            if (firstNullRootId != null) return
            firstNullRootId = id
            firstNullRootType = type
            firstNullRootDisplay = display
            firstNullRootRelativeLayer = relativeLayer
            firstNullRootSource = source
        }

        fun snapshot(treeElapsed: Long) = Timing(
            readerStrategy = strategy,
            prefetchFlags = prefetchFlags,
            activeRootPrefetchFlags = activeRootPrefetchFlags,
            acceptedChildPrefetchFlags = acceptedChildPrefetchFlags,
            cacheEnabled = cacheEnabled,
            freshnessPolicy = freshnessPolicy,
            cacheClearResult = cacheClearResult,
            activeCandidateWindowId = activeCandidateWindowId,
            returnedRootWindowId = returnedRootWindowId,
            activeRootAccepted = activeRootAccepted,
            fallbackReason = fallbackReason,
            ownAttributionAmbiguous = ownAttributionAmbiguous,
            getWindowsMs = getWindowsMs,
            relevantWindowCount = relevantWindows,
            activeRootCallCount = activeRootCount,
            activeRootTotalMs = activeRootTotal,
            rootAcquisitionCount = rootCount,
            rootAcquisitionTotalMs = rootTotal,
            rootAcquisitionMaxMs = rootMax,
            childAcquisitionCount = childCount,
            childAcquisitionTotalMs = childTotal,
            firstChildAcquisitionMs = firstChildMs,
            childAcquisitionMaxMs = childMax,
            firstNullRootId = firstNullRootId,
            firstNullRootType = firstNullRootType,
            firstNullRootDisplay = firstNullRootDisplay,
            firstNullRootRelativeLayer = firstNullRootRelativeLayer,
            firstNullRootSource = firstNullRootSource,
            localProcessingMs = (treeElapsed - activeRootTotal - rootTotal - childTotal).coerceAtLeast(0L),
            slowCalls = slow.sortedByDescending { it.first }.take(3).map { it.second },
            walkTruncationReasons = truncationReasons.toSet(),
            ingressCallKind = ingressCallKind,
            ingressCallBegin = ingressCallBegin,
            ingressCallEnd = ingressCallEnd,
        )
    }

    /** The caller owns all lifecycle generations.  This reader never samples
     * mutable View state; it merely stops requesting nodes after authority has
     * become stale. */
    fun read(
        request: Request,
        authorityIsCurrent: () -> Boolean,
        onFreshnessEstablished: () -> Unit = {},
    ): Result {
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
        val cacheClearResult = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
            request.freshness, Build.VERSION.SDK_INT, cacheEnabled, authorityIsCurrent,
            clearCache = { service.clearCache() }, onEstablished = onFreshnessEstablished,
        )
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
        fun observeIngressCall(kind: String, begin: Long, end: Long) {
            if (timing.ingressCallKind != null) return
            val ingress = request.openingFirstIngressUptime?.invoke() ?: return
            if (ingress > 0L && ingress in begin..end) {
                timing.ingressCallKind = kind
                timing.ingressCallBegin = begin
                timing.ingressCallEnd = end
            }
        }
        observeIngressCall("windows", windowsStartedAt, windowsStartedAt + windowsReadMs)
        timing.cacheEnabled = cacheEnabled
        timing.freshnessPolicy = request.freshness.name
        timing.cacheClearResult = cacheClearResult
        val prefetch = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags()
        timing.prefetchFlags = prefetch
        timing.strategy = "LEGACY_PER_WINDOW"

        if (!authorityIsCurrent()) return Result(
            emptyList(), false, false, windowsReadMs,
            SystemClock.uptimeMillis() - treeStartedAt, 0, timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt),
            abortedStale = true,
        )

        val primary = currentWindows.filter { displayId(it) == Display.DEFAULT_DISPLAY }
        val metadata = primary.map(::metadata)
        val observedOwn = request.knownOwnAtInventory?.invoke() ?: request.knownOwn
        val scopedRequest = request.copy(knownOwn = observedOwn)
        val activeCandidate = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
            metadata, observedOwn, request.attachGeneration,
        )
        val activeLayer = primary.firstOrNull { it.id == activeCandidate?.id }?.layer
        // The active-root route is an acquisition strategy, not a reward for
        // having just cleared the whole cache. A connected enabled cache and
        // a validated candidate are sufficient; explicit invalidation above
        // remains available when evidence requires it.
        val freshnessBoundaryEstablished = !KeyguardWindowSnapshotReaderPolicy.shouldClearCache(request.freshness) ||
            cacheClearResult.startsWith("cleared:")
        val canBatch = KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
            apiLevel = Build.VERSION.SDK_INT,
            cacheEnabled = cacheEnabled,
            hasUnambiguousCandidate = activeCandidate != null,
            freshnessBoundaryEstablished = freshnessBoundaryEstablished,
        ) && KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
            request.strictOwnAttribution, activeCandidate,
        )
        var activeRoot: AccessibilityNodeInfo? = null
        var activeWindowId: Int? = null
        // An unresolved overlay, other foreign window, missing candidate or
        // incomplete inventory prevents the early path. Do not classify the
        // inventory as MAIN; this only decides whether a walk can be yielded.
        var openingInventory: Boolean? = null
        fun cleanOpeningInventory(): Boolean {
            val cached = openingInventory
            if (cached != null) return cached
            return KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
                canBatch, metadata, observedOwn, request.attachGeneration, activeCandidate,
            ).also { openingInventory = it }
        }
        fun maybeYield(checkpoint: String, safe: Boolean, visited: Int): KeyguardCardInspectionRequest? {
            if (request.openingYieldHint?.invoke() != true) return null
            return request.claimOpeningYield?.invoke(checkpoint, freshnessBoundaryEstablished, safe, visited,
                timing.rootCount + timing.activeRootCount, timing.childCount)
        }
        // A TYPE_SYSTEM inventory entry does not identify its package. Before
        // the root is returned, a foreign system window is still unresolved;
        // report the checkpoint but keep the ordinary read in that case.
        val beforeRoot = if (request.openingYieldHint?.invoke() == true)
            maybeYield("beforeActiveRoot", false, 0) else null
        if (beforeRoot != null) return Result(emptyList(), false, false, windowsReadMs,
            SystemClock.uptimeMillis() - treeStartedAt, 0,
            timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), yieldedTo = beforeRoot)

        if (canBatch && authorityIsCurrent()) {
            val candidate = requireNotNull(activeCandidate)
            timing.activeCandidateWindowId = candidate.id
            val startedAt = SystemClock.uptimeMillis()
            activeRoot = runCatching {
                val strategy = request.activeRootStrategyAtCall?.invoke()
                    ?: if (request.initialRootOnly) KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO
                    else KeyguardActiveRootStrategy.STOCK
                if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.candidate(candidate)
                KeyguardWindowAcquisitionCalls.activeRoot(strategy, Build.VERSION.SDK_INT) { flags ->
                    timing.activeRootPrefetchFlags = flags
                    service.getRootInActiveWindow(flags)
                }
            }.getOrNull()
            val rootReturnedAt = SystemClock.uptimeMillis()
            timing.activeRoot(candidate.id, rootReturnedAt - startedAt)
            observeIngressCall("activeRoot", startedAt, rootReturnedAt)
            val returned = activeRoot
            if (returned == null) timing.nullRoot(candidate.id, candidate.type, candidate.displayId,
                activeLayer?.let { 0L }, "active")
            timing.returnedRootWindowId = returned?.windowId
            val accepted = authorityIsCurrent() && KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
                candidate, returned?.windowId, returned?.packageName, metadata,
            )
            if (accepted) {
                timing.strategy = "ACTIVE_ROOT_BATCHED_PLUS_PER_WINDOW"
                timing.activeRootAccepted = true
                timing.acceptedChildPrefetchFlags = prefetch
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
                activeCandidate == null && metadata.none { it.active && !KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(it, observedOwn, request.attachGeneration) } -> "noActiveCandidate"
                activeCandidate == null -> "ambiguousActiveCandidates"
                !KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
                    request.strictOwnAttribution, activeCandidate) -> "unattributedActiveOverlay"
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
            if (isExactKnownOwn(window, scopedRequest)) {
                if (request.strictOwnAttribution && request.knownOwnAtInventory?.invoke() != observedOwn) {
                    activeRoot?.recycle()
                    return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                        SystemClock.uptimeMillis() - treeStartedAt, visited,
                        timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), true, readsAfterInvalidation)
                }
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
                // Match the 47002e5 fallback. Android's per-window root route
                // bypasses the cache and strips descendant prefetch flags.
                runCatching { window.root }.getOrNull().also {
                    val rootReturnedAt = SystemClock.uptimeMillis()
                    timing.root(window, displayId(window), rootReturnedAt - rootStarted)
                    observeIngressCall("windowRoot", rootStarted, rootReturnedAt)
                }
            }
            if (!authorityIsCurrent()) {
                root?.recycle()
                readsAfterInvalidation += 1
                return Result(snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visited,
                    timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), true, readsAfterInvalidation)
            }
            if (root == null) {
                unavailableRoot = true
                timing.nullRoot(window.id, window.type, displayId(window),
                    activeLayer?.let { window.layer.toLong() - it.toLong() }, "perWindow")
            }
            val rootPackage = root?.packageName?.toString()
            val potentialOwn = window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY &&
                (rootPackage == ownPackageName || root == null)
            if (request.strictOwnAttribution && potentialOwn) {
                // An unresolved or same-package window is never proof of our
                // exact host. A complete positive is refused until fallback.
                unavailableRoot = true
                timing.ownAttributionAmbiguous = true
            }
            val own = !request.strictOwnAttribution && rootPackage == ownPackageName &&
                window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val visible = if (rootPackage in SYSTEM_PACKAGES && root != null) {
                visibleIds(root, window.id, prefetch.takeIf { timing.activeRootAccepted }, authorityIsCurrent, timing,
                    request.onDecisiveSystemMarker,
                    if (request.openingFirstIngressUptime != null) ::observeIngressCall else null,
                    request.openingChildBefore,
                    request.openingChildReturned,
                    if (request.openingYieldHint != null && request.claimOpeningYield != null &&
                        canBatch && timing.activeRootAccepted && !unavailableRoot && !walkTruncated &&
                        !timing.ownAttributionAmbiguous) { kind, count ->
                        if (request.openingYieldHint?.invoke() == true)
                            maybeYield(kind, cleanOpeningInventory(), visited + count) else null
                    } else null).also {
                    walkTruncated = walkTruncated || it.truncated
                    visited += it.visited
                    readsAfterInvalidation += it.readsAfterInvalidation
                }
            } else null
            root?.recycle()
            if (visible?.yieldedTo != null) {
                activeRoot?.recycle()
                return Result(emptyList(), unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visited,
                    timing.snapshot(SystemClock.uptimeMillis() - treeStartedAt), yieldedTo = visible.yieldedTo)
            }
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
        onDecisiveSystemMarker: (() -> Unit)?,
        observeIngressCall: ((String, Long, Long) -> Unit)?,
        openingChildBefore: ((Int, Int) -> Unit)?,
        openingChildReturned: ((Int, Int, Boolean) -> Unit)?,
        tryOpeningYield: ((String, Int) -> KeyguardCardInspectionRequest?)?,
    ): VisibleIds {
        val ids = linkedSetOf<String>()
        var decisiveReported = false
        fun recordId(id: String) {
            ids.add(id)
            if (!decisiveReported && KeyguardSurfaceClassifier.isDecisiveExclusionMarker(id) && authorityIsCurrent()) {
                decisiveReported = true
                if (onDecisiveSystemMarker != null) runCatching { onDecisiveSystemMarker() }
            }
        }
        var visited = 0
        var truncated = false
        var aborted = false
        var yieldedTo: KeyguardCardInspectionRequest? = null
        var readsAfterInvalidation = 0
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null || aborted || yieldedTo != null) return
            if (!authorityIsCurrent()) { aborted = true; return }
            if (visited >= MAX_VISITED_NODES) {
                truncated = true
                timing.truncationReasons += "NODE_LIMIT"
                return
            }
            visited += 1
            try {
                if (!node.isVisibleToUser) return
                node.viewIdResourceName?.let(::recordId)
                node.className?.toString()?.takeIf { it.contains("BouncerContent") }?.let { recordId("element:BouncerContent") }
                for (index in 0 until node.childCount) {
                    if (!authorityIsCurrent()) { aborted = true; return }
                    // The returned node and its exclusion markers were
                    // consumed above. No callback runs while holding a node
                    // owner lock; unwinding below recycles each owned child.
                    if (!truncated && !decisiveReported && tryOpeningYield != null) {
                        yieldedTo = tryOpeningYield("beforeChild", visited)
                        if (yieldedTo != null) return
                    }
                    if (openingChildBefore != null) runCatching { openingChildBefore(windowId, index) }
                    val startedAt = SystemClock.uptimeMillis()
                    val acquisition = runCatching {
                        KeyguardWindowAcquisitionCalls.child(prefetchFlags, Build.VERSION.SDK_INT,
                            batched = { flags ->
                                if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.child(windowId, index, flags)
                                node.getChild(index, flags)
                            },
                            legacy = {
                                if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.child(windowId, index, null)
                                node.getChild(index)
                            })
                    }
                    val child = acquisition.getOrNull()
                    val childReturnedAt = SystemClock.uptimeMillis()
                    timing.child(windowId, index, childReturnedAt - startedAt)
                    observeIngressCall?.invoke("child", startedAt, childReturnedAt)
                    if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.returnedChild(windowId, index, child != null)
                    if (openingChildReturned != null) runCatching { openingChildReturned(windowId, index, child != null) }
                    if (!authorityIsCurrent()) {
                        child?.recycle()
                        readsAfterInvalidation += 1
                        aborted = true
                        return
                    }
                    // A advertised child which disappeared/failed is an
                    // incomplete observation, never a complete MAIN proof.
                    if (child == null) {
                        truncated = true
                        timing.truncationReasons += if (acquisition.isFailure) "CHILD_ACQUISITION_EXCEPTION" else "NULL_CHILD"
                    }
                    visit(child)
                    child?.recycle()
                    if (aborted || yieldedTo != null) return
                }
            } catch (_: Exception) {
                // An incomplete SystemUI tree must remain UNKNOWN, never a
                // partial positive proof of the keyguard.
                truncated = true
                timing.truncationReasons += "NODE_ACCESS_EXCEPTION"
            }
        }
        visit(root)
        return VisibleIds(ids, truncated, visited, aborted, readsAfterInvalidation, yieldedTo)
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
