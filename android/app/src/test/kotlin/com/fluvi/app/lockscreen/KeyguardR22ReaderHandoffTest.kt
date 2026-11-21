package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
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
        val children: MutableList<AccessibilityNodeInfo> = mutableListOf(), var recycled: Int = 0)
    private data class Window(val id: Int, val layer: Int, val active: Boolean, val root: AccessibilityNodeInfo)
    private object Platform {
        val nodes = IdentityHashMap<AccessibilityNodeInfo, Node>()
        val windows = IdentityHashMap<AccessibilityWindowInfo, Window>()
        var inventory = emptyList<AccessibilityWindowInfo>()
        var activeRoot: AccessibilityNodeInfo? = null
        var childCalls = mutableListOf<Int>()
        var afterChild: ((Int) -> Unit)? = null
        var missingChild = false
        fun reset() {
            nodes.clear(); windows.clear(); inventory = emptyList(); activeRoot = null
            childCalls = mutableListOf(); afterChild = null; missingChild = false
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
        @Implementation fun getChildCount(): Int = checkNotNull(Platform.nodes[real]).children.size
        @Implementation fun getChild(index: Int): AccessibilityNodeInfo? = child(index)
        @Implementation fun getChild(index: Int, flags: Int): AccessibilityNodeInfo? = child(index)
        private fun child(index: Int): AccessibilityNodeInfo? {
            Platform.childCalls += index
            val child = if (Platform.missingChild) null else checkNotNull(Platform.nodes[real]).children[index]
            Platform.afterChild?.invoke(index)
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
                claimOpeningYield = { checkpoint, boundary, inventory, visited, roots, children ->
                    gate.claim(queue, a, if (wrongToken) Any() else token, 9, scene,
                        safe.copy(freshnessEstablished = boundary, noObservedDisqualifier = inventory),
                        checkpoint, 21, visited, roots, children)?.also { claims += 1 }
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
