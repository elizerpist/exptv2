package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import java.util.IdentityHashMap
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.annotation.RealObject
import org.robolectric.shadow.api.Shadow

/** Structural replay through the production reader and classifier. It does
 * not represent an Android compositor, a device timing, or a service PASS. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, shadows = [
    KeyguardR22ReaderHandoffTest.ServiceShadow::class,
    KeyguardR22ReaderHandoffTest.WindowShadow::class,
    KeyguardR22ReaderHandoffTest.NodeShadow::class,
])
class KeyguardR22ReaderHandoffTest {
    class FakeService : AccessibilityService() {
        override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
        override fun onInterrupt() {}
    }

    private data class Node(val id: String?, val windowId: Int, val pkg: String = "com.android.systemui",
        val children: MutableList<AccessibilityNodeInfo> = mutableListOf(), var recycled: Int = 0,
        val extras: Bundle = Bundle(), var advertised: Boolean = false, var lazyTag: String? = null,
        var refreshSucceeds: Boolean = true)
    private data class Window(val id: Int, val layer: Int, val active: Boolean, val root: AccessibilityNodeInfo)
    private object Platform {
        val nodes = IdentityHashMap<AccessibilityNodeInfo, Node>()
        val windows = IdentityHashMap<AccessibilityWindowInfo, Window>()
        var inventory = emptyList<AccessibilityWindowInfo>()
        var activeRoot: AccessibilityNodeInfo? = null
        var childCalls = mutableListOf<Int>()
        var afterChild: ((Int) -> Unit)? = null
        var missingChild = false
        var nullIndices = emptySet<Int>()
        var exceptionIndices = emptySet<Int>()
        var extraCalls = 0
        var onExtra: (() -> Unit)? = null
        fun reset() {
            nodes.clear(); windows.clear(); inventory = emptyList(); activeRoot = null
            childCalls = mutableListOf(); afterChild = null; missingChild = false
            nullIndices = emptySet(); exceptionIndices = emptySet()
            extraCalls = 0; onExtra = null
        }
        fun node(id: String?, window: Int = 10, pkg: String = "com.android.systemui"): AccessibilityNodeInfo =
            Shadow.newInstanceOf(AccessibilityNodeInfo::class.java).also { nodes[it] = Node(id, window, pkg) }
        fun window(id: Int, layer: Int, active: Boolean, root: AccessibilityNodeInfo): AccessibilityWindowInfo =
            Shadow.newInstanceOf(AccessibilityWindowInfo::class.java).also { windows[it] = Window(id, layer, active, root) }
    }

    @Implements(AccessibilityService::class)
    class ServiceShadow {
        @Implementation fun getWindows(): List<AccessibilityWindowInfo> = Platform.inventory
        @Implementation fun getRootInActiveWindow(flags: Int): AccessibilityNodeInfo? = Platform.activeRoot
        @Implementation fun isCacheEnabled(): Boolean = true
        @Implementation fun clearCache(): Boolean = true
    }
    @Implements(AccessibilityWindowInfo::class)
    class WindowShadow {
        @RealObject lateinit var real: AccessibilityWindowInfo
        @Implementation fun getId(): Int = checkNotNull(Platform.windows[real]).id
        @Implementation fun getLayer(): Int = checkNotNull(Platform.windows[real]).layer
        @Implementation fun getType(): Int = AccessibilityWindowInfo.TYPE_SYSTEM
        @Implementation fun getDisplayId(): Int = 0
        @Implementation fun isActive(): Boolean = checkNotNull(Platform.windows[real]).active
        @Implementation fun getRoot(): AccessibilityNodeInfo = checkNotNull(Platform.windows[real]).root
        @Implementation fun recycle() {}
    }
    @Implements(AccessibilityNodeInfo::class)
    class NodeShadow {
        @RealObject lateinit var real: AccessibilityNodeInfo
        @Implementation fun getWindowId(): Int = checkNotNull(Platform.nodes[real]).windowId
        @Implementation fun getPackageName(): CharSequence = checkNotNull(Platform.nodes[real]).pkg
        @Implementation fun getClassName(): CharSequence = "android.view.View"
        @Implementation fun isVisibleToUser(): Boolean = true
        @Implementation fun getViewIdResourceName(): String? = checkNotNull(Platform.nodes[real]).id
        @Implementation fun getExtras(): Bundle = checkNotNull(Platform.nodes[real]).extras
        @Implementation fun getAvailableExtraData(): List<String> =
            if (checkNotNull(Platform.nodes[real]).advertised) listOf(KeyguardR44Markers.EXTRA) else emptyList()
        @Implementation fun getParent(): AccessibilityNodeInfo? =
            Platform.nodes.entries.firstOrNull { it.value.children.contains(real) }?.key
        @Implementation fun refreshWithExtraData(key: String, arguments: Bundle?): Boolean {
            Platform.extraCalls += 1
            Platform.onExtra?.invoke()
            val node = checkNotNull(Platform.nodes[real])
            if (!node.refreshSucceeds || key != KeyguardR44Markers.EXTRA || arguments == null) return false
            node.lazyTag?.let { node.extras.putCharSequence(key, it) }
            return true
        }
        @Implementation fun getChildCount(): Int = checkNotNull(Platform.nodes[real]).children.size
        @Implementation fun getChild(index: Int): AccessibilityNodeInfo? = child(index)
        @Implementation fun getChild(index: Int, flags: Int): AccessibilityNodeInfo? = child(index)
        private fun child(index: Int): AccessibilityNodeInfo? {
            Platform.childCalls += index
            val child = if (Platform.missingChild || index in Platform.nullIndices) null
                else checkNotNull(Platform.nodes[real]).children[index]
            Platform.afterChild?.invoke(index)
            if (index in Platform.exceptionIndices) throw IllegalStateException("injected child acquisition failure")
            return child
        }
        @Implementation fun recycle() { checkNotNull(Platform.nodes[real]).recycled += 1 }
    }

    private lateinit var reader: KeyguardWindowSnapshotReader
    private val mainMarker = "com.android.systemui:id/keyguard_status_view"
    private val shadeMarker = "com.android.systemui:id/quick_settings_panel"
    @Before fun setup() {
        Platform.reset()
        val service = Robolectric.buildService(FakeService::class.java).create().get()
        reader = KeyguardWindowSnapshotReader(service, "com.fluvi.app")
    }

    private fun tree(first: String = mainMarker, second: String = mainMarker): Triple<AccessibilityNodeInfo, AccessibilityNodeInfo, AccessibilityNodeInfo> {
        val root = Platform.node(null)
        val childA = Platform.node(first)
        val childB = Platform.node(second)
        checkNotNull(Platform.nodes[root]).children.addAll(listOf(childA, childB))
        Platform.activeRoot = root
        Platform.inventory = listOf(Platform.window(10, 1, true, root))
        return Triple(root, childA, childB)
    }

    @Test fun r43CaptureObservesTheSameWalkWithoutChangingClassification() {
        tree(first = mainMarker, second = shadeMarker)
        val baseline = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
        val originalCalls = Platform.childCalls.toList()
        val originalClass = KeyguardSurfaceClassifier.classifyDetailed(baseline.snapshots)
        Platform.childCalls.clear()
        tree(first = mainMarker, second = shadeMarker)
        val evidence = KeyguardR43SurfaceEvidence()
        val observed = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r43Evidence = evidence), { true })
        assertEquals(originalCalls, Platform.childCalls)
        assertEquals(baseline.visitedNodeCount, observed.visitedNodeCount)
        assertEquals(originalClass, KeyguardSurfaceClassifier.classifyDetailed(observed.snapshots))
        assertEquals(KeyguardSurface.SHADE, originalClass.surface)
        val window = evidence.windows().single()
        assertTrue(window.verified)
        assertEquals(3, window.visited)
        assertEquals(1, window.nullId)
        assertEquals(2, window.systemId)
    }

    @Test fun r44ExplicitLockscreenAndDeviceEntryNeedAnOrdinarySurfaceDecision() {
        // Controlled structural replay of the API-37 source shape.  This is
        // not evidence that an OEM exposes either marker on a real handset.
        val root = Platform.node("element:lockscreen")
        val entry = Platform.node("com.android.systemui:id/device_entry_icon_view")
        checkNotNull(Platform.nodes[root]).children.add(entry)
        Platform.activeRoot = root
        Platform.inventory = listOf(Platform.window(10, 1, true, root))
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
        assertFalse("the real walker must complete", read.rootUnavailable)
        assertFalse("the real walker must not truncate", read.walkTruncated)
        assertEquals(2, read.visitedNodeCount)
        assertEquals(10, read.snapshots.single().windowId)
        val decision = KeyguardR44SurfaceClassifier.classify(read.snapshots,
            unavailableRoot = read.rootUnavailable, walkTruncated = read.walkTruncated,
            strictOwnAttribution = false, syntheticTrial = true)
        assertEquals("a qualified R44 path must recognise this distinct pair",
            KeyguardSurface.MAIN_KEYGUARD, decision.surface)
    }

    @Test fun r44EagerAndLazyTagsTraverseTheActualReader() {
        for (lazy in listOf(false, true)) {
            Platform.reset()
            val root = Platform.node(null)
            val child = Platform.node("com.android.systemui:id/device_entry_icon_view")
            val rootData = checkNotNull(Platform.nodes[root])
            rootData.children.add(child)
            if (lazy) { rootData.advertised = true; rootData.lazyTag = "element:lockscreen" }
            else rootData.extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
            Platform.activeRoot = root
            Platform.inventory = listOf(Platform.window(10, 1, true, root))
            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
            assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
                read.snapshots, read.rootUnavailable, read.walkTruncated, false, true).surface)
            assertEquals(if (lazy) 1 else 0, Platform.extraCalls)
            assertEquals(if (lazy) KeyguardR44Markers.Carrier.EXTRA_LAZY else KeyguardR44Markers.Carrier.EXTRA_EAGER,
                read.snapshots.single().r44?.host?.carrier)
        }
    }

    @Test fun r44BudgetOrStaleExtraNeverCreatesAuthority() {
        val root = Platform.node("element:lockscreen")
        checkNotNull(Platform.nodes[root]).children.add(Platform.node("com.android.systemui:id/device_entry_icon_view"))
        repeat(5) {
            val node = Platform.node(null)
            checkNotNull(Platform.nodes[node]).apply { advertised = true; lazyTag = "unrecognised" }
            checkNotNull(Platform.nodes[root]).children.add(node)
        }
        Platform.activeRoot = root
        Platform.inventory = listOf(Platform.window(10, 1, true, root))
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
        assertEquals(4, Platform.extraCalls)
        assertEquals(true, read.snapshots.single().r44?.budgetHit)
        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
            read.snapshots, read.rootUnavailable, read.walkTruncated, false, true).surface)

        Platform.reset()
        val lazyRoot = Platform.node(null)
        checkNotNull(Platform.nodes[lazyRoot]).apply { advertised = true; lazyTag = "element:lockscreen" }
        Platform.activeRoot = lazyRoot
        Platform.inventory = listOf(Platform.window(10, 1, true, lazyRoot))
        var current = true
        Platform.onExtra = { current = false }
        val stale = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            r44Enabled = true, r44DeviceEntryResourceVerified = true), { current })
        assertTrue(stale.abortedStale)
    }

    @Test fun r44ReaderRejectsSpoofedSiblingAndSameNodePairs() {
        fun run(root: AccessibilityNodeInfo): KeyguardSurface {
            Platform.activeRoot = root
            Platform.inventory = listOf(Platform.window(10, 1, true, root))
            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
            return KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable,
                read.walkTruncated, false, true).surface
        }
        val same = Platform.node("element:lockscreen")
        checkNotNull(Platform.nodes[same]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:LargeClock")
        assertEquals(KeyguardSurface.UNKNOWN, run(same))
        Platform.reset()
        val root = Platform.node(null)
        checkNotNull(Platform.nodes[root]).children.addAll(listOf(Platform.node("element:lockscreen"),
            Platform.node("com.android.systemui:id/device_entry_icon_view")))
        assertEquals(KeyguardSurface.UNKNOWN, run(root))
        Platform.reset()
        val host = Platform.node("element:lockscreen")
        checkNotNull(Platform.nodes[host]).children.add(
            Platform.node("com.android.systemui:id/device_entry_icon_view", pkg = "foreign.app"))
        assertEquals(KeyguardSurface.UNKNOWN, run(host))
    }

    @Test fun r44ReaderDeniesShadeAfterAnOtherwiseValidPair() {
        val host = Platform.node("element:lockscreen")
        val entry = Platform.node("com.android.systemui:id/device_entry_icon_view")
        val shade = Platform.node("scene:shade")
        checkNotNull(Platform.nodes[host]).children.addAll(listOf(entry, shade))
        Platform.activeRoot = host
        Platform.inventory = listOf(Platform.window(10, 1, true, host))
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
        assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
            read.snapshots, read.rootUnavailable, read.walkTruncated, false, true).surface)
    }

    @Test fun r44UnsupportedOrFailedAdvertisedExtraFailsClosed() {
        for (failure in listOf(false, true)) {
            Platform.reset()
            val host = Platform.node("element:lockscreen")
            val entry = Platform.node("com.android.systemui:id/device_entry_icon_view")
            val unknown = Platform.node(null)
            checkNotNull(Platform.nodes[unknown]).apply {
                advertised = true
                lazyTag = "unrecognised"
                refreshSucceeds = !failure
            }
            checkNotNull(Platform.nodes[host]).children.addAll(listOf(entry, unknown))
            Platform.activeRoot = host
            Platform.inventory = listOf(Platform.window(10, 1, true, host))
            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
                read.snapshots, read.rootUnavailable, read.walkTruncated, false, true).surface)
            val facts = checkNotNull(read.snapshots.single().r44)
            assertFalse(facts.complete)
            assertEquals(if (failure) 1 else 0, facts.failed)
            assertEquals(if (failure) 0 else 1, facts.unsupported)
        }
    }

    private class Handoff {
        val safe = KeyguardOpeningInspectionHandoff.Conditions(
            true, true, true, true, true, true, true, true, true, true)
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val token = Any()
        val queue = KeyguardCardInspectionQueue()
        val gate = KeyguardOpeningInspectionHandoff()
        val a = request(1, false)
        val b = request(2, true)
        var scene = 10L
        var claims = 0
        fun request(id: Long, external: Boolean) = KeyguardCardInspectionRequest(
            id, if (external) "window" else "wake", 1, 2, 4, 5, 3, id,
            r14Ingress = if (external) KeyguardR14Ingress(id, true, 10, 0, 32, id, id,
                KeyguardR14Origin.SYSTEM_UI) else null)
        init {
            queue.offer(a)
            assertTrue(gate.arm(token, 7, a, authority, 9))
            gate.readStarted(a, scene, 10)
        }
        fun offerB() {
            scene = 11
            gate.externalInvalidation(scene, 20)
            queue.offer(b)
            gate.offered(b, queue.pendingRequest(), scene, scene, true)
        }
        fun request(wrongToken: Boolean = false): KeyguardWindowSnapshotReader.Request =
            KeyguardWindowSnapshotReader.Request(null, 5,
                openingYieldHint = { gate.hasHint },
                claimOpeningYield = { checkpoint, reason, boundary, inventory, visited, roots, children ->
                    gate.claim(queue, a, if (wrongToken) Any() else token, 9, scene,
                        safe.copy(freshnessEstablished = boundary, noObservedDisqualifier = inventory,
                            virginDirect = true, noRetainedProof = true),
                        checkpoint, 21, visited, roots, children, yieldReason = reason)?.also { claims += 1 }
                })
    }

    @Test fun returnedMainIsConsumedBeforeYieldAndBPerformsFreshCompleteRead() {
        val nodes = tree()
        val h = Handoff()
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val result = reader.read(h.request(), { true })
        assertEquals(h.b, result.yieldedTo)
        assertTrue("partial A must not be handed to classifier", result.snapshots.isEmpty())
        assertEquals(listOf(0), Platform.childCalls)
        assertEquals(1, h.claims)
        assertEquals(h.b, h.queue.activeRequest())
        assertEquals(1, checkNotNull(Platform.nodes[nodes.first]).recycled)
        assertEquals(1, checkNotNull(Platform.nodes[nodes.second]).recycled)
        assertEquals(0, checkNotNull(Platform.nodes[nodes.third]).recycled)
        Platform.childCalls.clear()
        tree()
        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
        assertNull(fresh.yieldedTo)
        assertFalse(fresh.rootUnavailable)
        assertFalse(fresh.walkTruncated)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
        assertEquals(listOf(0, 1), Platform.childCalls)
    }

    @Test fun cleanOriginalOffersAtPostMarkerCheckpointAndExportsItsExactBoundary() {
        tree()
        val h = Handoff()
        var checkpointCalls = 0
        val request = h.request().copy(captureOriginalOpeningEvidence = true,
            openingEligibleCheckpoint = { window, index ->
                assertEquals(10, window)
                assertEquals(1, index)
                checkpointCalls++
                h.offerB()
            })
        val result = reader.read(request, { true })
        assertEquals(h.b, result.yieldedTo)
        assertEquals(1, checkpointCalls)
        assertEquals(listOf(0), Platform.childCalls)
        val evidence = requireNotNull(result.timing.originalOpening)
        assertEquals(10, evidence.rootWindow)
        assertEquals(1, evidence.firstOrdinal)
        assertEquals(1, evidence.firstDepth)
        assertEquals(1, evidence.firstParentOrdinal)
        assertEquals(0, evidence.firstIndex)
        assertEquals("PRESENT", evidence.firstResult)
        assertNull(evidence.invalidKind)
        assertTrue(evidence.checkpointInstalled)
        assertEquals("CALLED", evidence.checkpointState)
        assertFalse(evidence.decisiveMarker)
    }

    @Test fun decisiveExclusionIsConsumedBeforeAnyPossibleYield() {
        tree(first = shadeMarker)
        val h = Handoff()
        var decisive = 0
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val request = h.request().copy(onDecisiveSystemMarker = { decisive += 1 })
        val result = reader.read(request, { true })
        assertNull(result.yieldedTo)
        assertEquals(0, h.claims)
        assertEquals(1, decisive)
        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(result.snapshots))
    }

    @Test fun wrongTokenAndAmbiguousInventoryCannotClaim() {
        tree()
        val h = Handoff()
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val wrong = reader.read(h.request(wrongToken = true), { true })
        assertNull(wrong.yieldedTo)
        assertEquals(h.a, h.queue.activeRequest())
        assertNull(checkNotNull(h.gate.snapshot(h.a.id)).lastCheckpoint)
        Platform.reset()
        tree()
        val extraRoot = Platform.node(null, 11, "foreign.example")
        Platform.inventory = Platform.inventory + Platform.window(11, 2, false, extraRoot)
        val second = Handoff()
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; second.offerB() } }
        val ambiguous = reader.read(second.request(), { true })
        assertNull(ambiguous.yieldedTo)
        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(ambiguous.snapshots))
        assertEquals(0, second.claims)
    }

    @Test fun incompleteOriginalWithoutClaimCapabilityCannotYieldOrAuthorizeDespitePendingNewerRequest() {
        tree()
        val h = Handoff()
        Platform.missingChild = true
        // Offer while the real production reader is acquiring child zero. Its
        // null return must be consumed before any later eligible checkpoint.
        Platform.afterChild = { index ->
            if (index == 0) { Platform.afterChild = null; h.offerB() }
        }
        var eligible = 0
        val request = h.request().copy(captureOriginalOpeningEvidence = true,
            claimOpeningYield = null, openingEligibleCheckpoint = { _, _ -> eligible++ })
        val result = reader.read(request, { true })
        assertEquals("incomplete walk cannot expose an eligible checkpoint", 0, eligible)
        val evidence = requireNotNull(result.timing.originalOpening)
        assertEquals("NULL", evidence.firstResult)
        assertEquals("NULL_CHILD", evidence.invalidKind)
        assertEquals(1, evidence.invalidOrdinal)
        assertEquals(0, evidence.invalidIndex)
        assertEquals("NOT_INSTALLED", evidence.checkpointState)
        assertTrue("a missing advertised edge must remain incomplete", result.walkTruncated)
        assertTrue(result.timing.walkTruncationReasons.contains("NULL_CHILD"))
        assertNull("an incomplete original walk cannot claim B", result.yieldedTo)
        assertEquals(0, h.claims)
        assertEquals(h.a, h.queue.activeRequest())
        assertEquals(h.b, h.queue.pendingRequest())
        assertEquals(KeyguardSurface.UNKNOWN,
            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
                unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated).surface)
        assertEquals(listOf(0, 1), Platform.childCalls)
    }

    @Test fun incompleteOriginalWithoutCapabilityStillReadsRemainingChild() {
        val nodes = tree(); val h = Handoff()
        Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val result = reader.read(h.request().copy(openingYieldHint = null, claimOpeningYield = null,
            captureOriginalOpeningEvidence = false), { true })
        assertNull(result.yieldedTo)
        assertTrue(result.walkTruncated)
        assertEquals(listOf(0, 1), Platform.childCalls)
        assertEquals(1, checkNotNull(Platform.nodes[nodes.first]).recycled)
        assertEquals(h.a, h.queue.activeRequest()); assertEquals(h.b, h.queue.pendingRequest())
        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
            unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated).surface)
    }

    @Test fun throwingClaimCannotPromoteOrLoseIncompleteObservation() {
        val nodes = tree(); val h = Handoff()
        Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val request = h.request().copy(claimOpeningYield = { _, _, _, _, _, _, _ ->
            throw IllegalStateException("injected callback failure")
        })
        val result = reader.read(request, { true })
        assertNull(result.yieldedTo)
        assertTrue(result.walkTruncated)
        assertEquals(listOf(0, 1), Platform.childCalls)
        assertEquals(1, checkNotNull(Platform.nodes[nodes.first]).recycled)
        assertEquals(h.a, h.queue.activeRequest())
        assertEquals(h.b, h.queue.pendingRequest())
        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
            unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated).surface)
    }

    @Test fun incompleteWithoutNewerRequestOrRemainingWorkCannotYield() {
        tree(); val h = Handoff(); Platform.missingChild = true
        val noSuccessor = reader.read(h.request(), { true })
        assertNull(noSuccessor.yieldedTo)
        assertTrue(noSuccessor.walkTruncated)
        assertEquals(listOf(0, 1), Platform.childCalls)
        Platform.reset(); val nodes = tree(); checkNotNull(Platform.nodes[nodes.first]).children.removeAt(1)
        val single = Handoff(); Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; single.offerB() } }
        val noWork = reader.read(single.request(), { true })
        assertNull(noWork.yieldedTo)
        assertTrue(noWork.walkTruncated)
        assertEquals(listOf(0), Platform.childCalls)
        assertEquals(single.b, single.queue.pendingRequest())
    }

    @Test fun incompleteWrongSystemRootAndChangedAuthorityCannotYield() {
        val nodes = tree(); val original = checkNotNull(Platform.nodes[nodes.first])
        Platform.nodes[nodes.first] = original.copy(pkg = "com.android.keyguard")
        val wrongRoot = Handoff(); Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; wrongRoot.offerB() } }
        val wrong = reader.read(wrongRoot.request(), { true })
        assertNull(wrong.yieldedTo); assertTrue(wrong.walkTruncated)
        assertEquals(wrongRoot.a, wrongRoot.queue.activeRequest())
        Platform.reset(); val nextNodes = tree(); val stale = Handoff(); var current = true
        Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; stale.offerB(); current = false } }
        val aborted = reader.read(stale.request(), { current })
        assertNull(aborted.yieldedTo); assertTrue(aborted.abortedStale)
        assertEquals(1, checkNotNull(Platform.nodes[nextNodes.first]).recycled)
        assertEquals(stale.a, stale.queue.activeRequest())
    }

    @Test fun incompleteExceptionOrMixedTruncationCannotBecomeNullChildTransfer() {
        val nodes = tree(); checkNotNull(Platform.nodes[nodes.first]).children.add(Platform.node(mainMarker))
        val h = Handoff(); Platform.missingChild = true; Platform.exceptionIndices = setOf(0)
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val result = reader.read(h.request(), { true })
        assertNull(result.yieldedTo); assertTrue(result.walkTruncated)
        assertEquals(KeyguardWalkIncompleteReason.CHILD_ACQUISITION_EXCEPTION, result.firstIncompleteReason)
        assertEquals(listOf(0, 1, 2), Platform.childCalls)
        assertEquals(h.b, h.queue.pendingRequest())
        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
            unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated).surface)
    }

    @Test fun decisiveMarkerBeforeMissingChildAlwaysPreventsIncompleteTransfer() {
        val nodes = tree(first = shadeMarker); checkNotNull(Platform.nodes[nodes.first]).children.add(Platform.node(mainMarker))
        val h = Handoff(); Platform.nullIndices = setOf(1)
        Platform.afterChild = { if (it == 1) { Platform.afterChild = null; h.offerB() } }
        var decisive = 0
        val result = reader.read(h.request().copy(onDecisiveSystemMarker = { decisive++ }), { true })
        assertEquals(1, decisive); assertNull(result.yieldedTo); assertTrue(result.walkTruncated)
        assertEquals(h.b, h.queue.pendingRequest()); assertEquals(listOf(0, 1, 2), Platform.childCalls)
    }

    @Test fun incompleteOriginalCanYieldOnlyToGenuineSuccessorBeforeNextChildWithoutCapture() {
        val nodes = tree(); val h = Handoff()
        Platform.missingChild = true
        Platform.afterChild = { if (it == 0) { Platform.afterChild = null; h.offerB() } }
        val result = reader.read(h.request().copy(captureOriginalOpeningEvidence = false), { true })
        assertEquals("the pending real B must take over the one physical reader", h.b, result.yieldedTo)
        assertTrue("the original partial walk remains incomplete", result.walkTruncated)
        assertEquals(KeyguardWalkIncompleteReason.NULL_ADVERTISED_CHILD, result.firstIncompleteReason)
        assertEquals(KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD, result.yieldReason)
        assertTrue("partial A is never classified", result.snapshots.isEmpty())
        assertEquals(listOf(0), Platform.childCalls)
        assertEquals(1, checkNotNull(Platform.nodes[nodes.first]).recycled)
        assertEquals(h.b, h.queue.activeRequest())
        Platform.missingChild = false; Platform.childCalls.clear(); tree()
        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
        assertNull(fresh.yieldedTo); assertFalse(fresh.rootUnavailable); assertFalse(fresh.walkTruncated)
        assertEquals(listOf(0, 1), Platform.childCalls)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
    }

    @Test fun r31ObsoleteSuccessorTransfersOnlyAtConsumedChildBoundary() {
        tree()
        val h = Handoff()
        h.offerB()
        assertEquals(h.b, h.gate.claim(h.queue, h.a, h.token, 9, h.scene, h.safe,
            "afterChild", 21))
        h.gate.followReadStarted(h.queue, h.b, h.scene, 22)
        val handle = requireNotNull(h.gate.followHandle(h.b))
        val c = h.request(3, true)
        var boundaries = 0
        Platform.afterChild = { index ->
            if (index == 0) {
                Platform.afterChild = null
                h.scene = 12
                h.gate.externalInvalidation(h.scene, 30)
                assertFalse(h.queue.offer(c))
                h.gate.offered(c, h.queue.pendingRequest(), h.scene, h.scene, true)
            }
        }
        val readingB = KeyguardWindowSnapshotReader.Request(null, 5,
            openingYieldHint = { h.gate.hasFollowHint(handle) },
            followOnOpening = true,
            claimOpeningYield = { checkpoint, reason, boundary, inventory, _, _, children ->
                boundaries++
                if (reason != KeyguardOpeningYieldReason.CLEAN_OPENING) null else
                    h.gate.claimFollow(h.queue, handle, h.token, 9, h.scene,
                        h.safe.copy(freshnessEstablished = boundary, noObservedDisqualifier = inventory,
                            virginDirect = true, noRetainedProof = true), checkpoint, 31, children)
            })
        val result = reader.read(readingB, { true })
        assertTrue("B reached a clean post-child boundary with remaining work", boundaries > 0)
        assertEquals("the current pending C must own the only reader", c, result.yieldedTo)
        assertTrue("partial B cannot be classified", result.snapshots.isEmpty())
        assertEquals(listOf(0), Platform.childCalls)
        assertEquals(c, h.queue.activeRequest())
    }

    @Test fun r31ReturnedShadeMarkerPreventsTransfer() {
        tree(first = shadeMarker)
        val h = Handoff(); h.offerB()
        assertEquals(h.b, h.gate.claim(h.queue, h.a, h.token, 9, h.scene, h.safe, "afterChild", 21))
        h.gate.followReadStarted(h.queue, h.b, h.scene, 22)
        val handle = requireNotNull(h.gate.followHandle(h.b))
        val c = h.request(3, true)
        Platform.afterChild = { index -> if (index == 0) {
            Platform.afterChild = null; h.scene = 12; h.gate.externalInvalidation(h.scene, 30)
            h.queue.offer(c); h.gate.offered(c, h.queue.pendingRequest(), h.scene, h.scene, true)
        } }
        var decisive = 0
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            openingYieldHint = { h.gate.hasFollowHint(handle) }, followOnOpening = true,
            onDecisiveSystemMarker = { decisive++ },
            claimOpeningYield = { checkpoint, reason, boundary, inventory, _, _, children ->
                if (reason != KeyguardOpeningYieldReason.CLEAN_OPENING) null else
                    h.gate.claimFollow(h.queue, handle, h.token, 9, h.scene,
                        h.safe.copy(freshnessEstablished = boundary, noObservedDisqualifier = inventory,
                            virginDirect = true, noRetainedProof = true), checkpoint, 31, children)
            }), { true })
        assertEquals(1, decisive); assertNull(read.yieldedTo)
        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(read.snapshots))
        assertEquals(h.b, h.queue.activeRequest()); assertEquals(c, h.queue.pendingRequest())
    }

    @Test fun r31NullChildCannotUseTheOriginalIncompleteOpeningException() {
        tree(); val h = Handoff(); h.offerB()
        assertEquals(h.b, h.gate.claim(h.queue, h.a, h.token, 9, h.scene, h.safe, "afterChild", 21))
        h.gate.followReadStarted(h.queue, h.b, h.scene, 22)
        val handle = requireNotNull(h.gate.followHandle(h.b)); val c = h.request(3, true)
        Platform.nullIndices = setOf(0)
        Platform.afterChild = { index -> if (index == 0) {
            Platform.afterChild = null; h.scene = 12; h.gate.externalInvalidation(h.scene, 30)
            h.queue.offer(c); h.gate.offered(c, h.queue.pendingRequest(), h.scene, h.scene, true)
        } }
        var claims = 0
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            openingYieldHint = { h.gate.hasFollowHint(handle) }, followOnOpening = true,
            claimOpeningYield = { _, _, _, _, _, _, _ -> claims++; c }), { true })
        assertNull(read.yieldedTo); assertTrue(read.walkTruncated); assertEquals(0, claims)
        assertEquals(h.b, h.queue.activeRequest()); assertEquals(c, h.queue.pendingRequest())
        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(read.snapshots,
            unavailableRoot = read.rootUnavailable, walkTruncated = read.walkTruncated).surface)
    }

    @Test fun r31DifferentSystemPackageIsNotAnAcceptedSystemUiRoot() {
        val nodes = tree(); val root = checkNotNull(Platform.nodes[nodes.first])
        Platform.nodes[nodes.first] = root.copy(pkg = "com.android.keyguard")
        val h = Handoff(); h.offerB()
        assertEquals(h.b, h.gate.claim(h.queue, h.a, h.token, 9, h.scene, h.safe, "afterChild", 21))
        h.gate.followReadStarted(h.queue, h.b, h.scene, 22)
        val handle = requireNotNull(h.gate.followHandle(h.b)); val c = h.request(3, true)
        Platform.afterChild = { index -> if (index == 0) {
            Platform.afterChild = null; h.scene = 12; h.gate.externalInvalidation(h.scene, 30)
            h.queue.offer(c); h.gate.offered(c, h.queue.pendingRequest(), h.scene, h.scene, true)
        } }
        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
            openingYieldHint = { h.gate.hasFollowHint(handle) }, followOnOpening = true,
            claimOpeningYield = { checkpoint, _, boundary, inventory, _, _, children ->
                h.gate.claimFollow(h.queue, handle, h.token, 9, h.scene,
                    h.safe.copy(freshnessEstablished = boundary, noObservedDisqualifier = inventory,
                        virginDirect = true, noRetainedProof = true), checkpoint, 31, children)
            }), { true })
        assertNull(read.yieldedTo); assertEquals(h.b, h.queue.activeRequest()); assertEquals(c, h.queue.pendingRequest())
    }

    @Test fun missingChildCannotProduceACompletePositive() {
        tree()
        Platform.missingChild = true
        val result = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
        assertTrue(result.walkTruncated)
        assertEquals(KeyguardSurface.UNKNOWN,
            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
                unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated).surface)
    }
}
