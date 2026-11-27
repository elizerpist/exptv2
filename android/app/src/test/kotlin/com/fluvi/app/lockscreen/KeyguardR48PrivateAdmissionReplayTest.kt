package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.annotation.RealObject
import org.robolectric.shadow.api.Shadow
import org.robolectric.shadows.ShadowAccessibilityNodeInfo
import org.robolectric.shadows.ShadowAccessibilityWindowInfo

/** The platform supplies constructed trees. The application reader, classifier
 * and two private policy boundaries are real. No SystemUI or pixels are replayed. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE, shadows = [KeyguardR48PrivateAdmissionReplayTest.ServiceShadow::class])
class KeyguardR48PrivateAdmissionReplayTest {
    class InventoryService : AccessibilityService() {
        var inventory = emptyList<AccessibilityWindowInfo>()
        var inventoryCalls = 0
        override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
        override fun onInterrupt() {}
    }

    @Implements(AccessibilityService::class)
    class ServiceShadow {
        @RealObject lateinit var service: AccessibilityService
        @Implementation fun getWindows(): List<AccessibilityWindowInfo> {
            val fixture = service as InventoryService
            fixture.inventoryCalls++
            return fixture.inventory
        }
        @Implementation fun isCacheEnabled(): Boolean = false
    }

    private data class Node(val id: String? = null, val visible: Boolean = true, val children: List<Node> = emptyList())

    private val app get() = RuntimeEnvironment.getApplication()
    private val prefs get() = app.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
    private val service = Robolectric.buildService(InventoryService::class.java).get()
    private val reader = KeyguardWindowSnapshotReader(service, app.packageName)
    private val host = Node("com.android.systemui:id/keyguard_root_view")
    private val marker = Node("com.android.systemui:id/keyguard_clock_switch")
    private val system = KeyguardSystemState(11L, 12L, available = true, primaryDisplay = true,
        interactive = true, displayOn = true, keyguardLocked = true, userUnlocked = true)
    private val stamp = KeyguardR448Admission.Stamp(1, 1, 1)

    @After fun reset() {
        FluviActiveHeaderMaterialStore.invalidate()
        assertTrue(prefs.edit().clear().commit())
    }

    private fun publishMaterial(): FluviActiveHeaderMaterialStore.Snapshot {
        assertTrue(prefs.edit().putBoolean("requested", true).putBoolean("details", true)
            .putBoolean("focusMigrated", true).putLong("generation", 7).commit())
        val epoch = System.nanoTime().coerceAtLeast(1L)
        val session = "r48-$epoch"
        val portal = mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0,
            "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
            "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
        val values = mapOf(
            "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
            "publisherSession" to session, "publisherRevision" to 2L, "publisherInstance" to 1L,
            "activeMode" to "balance", "modeEpoch" to 0L, "motionEnabled" to true, "sourceAnimated" to true,
            "sceneIdentity" to "active-header:balance:0", "effectId" to "dualTide", "effectShaderId" to 1,
            "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
            "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt()), "stops" to listOf(0.0, 1.0),
            "opacity" to 1.0, "paletteSplitPercent" to 50.0, "commonSettings" to List(40) { .2 },
            "background" to portal, "interior" to portal, "referenceWidth" to 390.0, "referenceHeight" to 220.0,
        )
        assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, session))
        val receipt = FluviActiveHeaderMaterialStore.publish(app, values, epoch, true)
        assertTrue(receipt.reason, receipt.accepted)
        return requireNotNull(FluviActiveHeaderMaterialStore.applicable(app))
    }

    private fun window(tree: Node, id: Int = 10, layer: Int = 1, pkg: String = "com.android.systemui",
                       active: Boolean = true, type: Int = AccessibilityWindowInfo.TYPE_SYSTEM): AccessibilityWindowInfo {
        val window = AccessibilityWindowInfo.obtain()
        val platform = Shadow.extract<ShadowAccessibilityWindowInfo>(window)
        platform.setId(id)
        platform.setType(type)
        platform.setLayer(layer)
        platform.setActive(active)
        platform.setFocused(active)
        platform.setDisplayId(0)
        fun node(spec: Node): AccessibilityNodeInfo = AccessibilityNodeInfo.obtain().apply {
            packageName = pkg
            className = "android.view.View"
            viewIdResourceName = spec.id
            isVisibleToUser = spec.visible
            val shadow = Shadow.extract<ShadowAccessibilityNodeInfo>(this)
            shadow.setAccessibilityWindowInfo(window)
            spec.children.forEach { shadow.addChild(node(it)) }
        }
        platform.setRoot(node(tree))
        return window
    }

    private data class Decision(
        val normal: KeyguardSurface, val reason: KeyguardSurfaceReason, val complete: Boolean, val direct: Boolean,
        val waSurface: KeyguardSurface, val exclusions: KeyguardR448Admission.Exclusions,
        val wa: KeyguardR448Admission.Decision,
    )

    private fun go(windows: List<AccessibilityWindowInfo>, material: FluviActiveHeaderMaterialStore.Snapshot? = null,
                   observe: Boolean = false, state: KeyguardSystemState = system, current: Boolean = true,
                   original: KeyguardR448Admission.Stamp = stamp, nowOwner: KeyguardR448Admission.Stamp = original): Decision? {
        service.inventory = windows
        val read = reader.read(KeyguardWindowSnapshotReader.Request(knownOwn = null, attachGeneration = 1,
            strictOwnAttribution = true, r43Evidence = if (observe) KeyguardR43SurfaceEvidence() else null,
            r44Enabled = true, r443Sample = false, r443Diagnostics = true), { current })
        if (read.abortedStale) return null
        val legacy = KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable, read.walkTruncated,
            strictOwnAttribution = true, syntheticTrial = false)
        val complete = !read.rootUnavailable && !read.walkTruncated
        val materialCurrent = material?.let(FluviActiveHeaderMaterialStore::isCurrentReference) == true
        fun privateBoundary(surface: KeyguardSurface, covered: Boolean): Boolean = KeyguardR47PrivateAdmission.allows(
            KeyguardCardSignals(true, true, state.userUnlocked, state.primaryDisplay, state.interactive,
                state.displayOn, state.keyguardLocked, surface, true, state.available, state.displayOff),
            covered, materialCurrent)
        val wa = KeyguardR449RestrictionEvidence.fromInventory(read.snapshots, 13, read.rootUnavailable, read.walkTruncated)
        val admission = KeyguardR448Admission.evaluate(KeyguardR448Admission.Inputs(
            original, 10, state, wa.exclusions, KeyguardR448Admission.Domain.PRIVATE,
            privateBoundary(wa.privateSurface, wa.reason == "CLEAR")), nowOwner, 14)
        return Decision(legacy.surface, legacy.reason, complete, privateBoundary(legacy.surface, complete),
            wa.privateSurface, wa.exclusions, admission)
    }

    @Test fun replayRetainedCompletedPrivateDecisions() {
        val material = publishMaterial()
        // Reconstructed trees are equivalent at the normal adapter boundary.
        // Numeric IDs below identify the published normalized observations only.
        val direct = mapOf(3 to listOf(36, 38, 39), 5 to listOf(74, 75, 76, 77, 100), 7 to listOf(142, 143, 144))
        for ((wake, requests) in direct) for (request in requests) {
            val decision = requireNotNull(go(listOf(window(host)), material))
            assertTrue("DIRECT wake=$wake req=$request", decision.complete)
            assertEquals(KeyguardSurface.UNKNOWN, decision.normal)
            assertEquals(KeyguardSurfaceReason.NO_MAIN_MARKER, decision.reason)
            assertFalse(decision.direct)
        }
        for ((wake, revisions) in mapOf(11 to listOf(6), 13 to listOf(39), 15 to listOf(97, 127))) for (revision in revisions) {
            val decision = requireNotNull(go(listOf(window(host)), material))
            assertEquals("WA wake=$wake revision=$revision", KeyguardSurface.UNKNOWN, decision.waSurface)
            val clear = KeyguardR448Admission.Presence.CLEAR
            assertEquals(KeyguardR448Admission.Exclusions(13, clear, clear, clear, clear), decision.exclusions)
            assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED, decision.wa)
        }
        val truncated = host.copy(children = List(320) { Node() })
        val incomplete = requireNotNull(go(listOf(window(truncated)), material))
        assertFalse(incomplete.complete)
        assertEquals(KeyguardR448Admission.Decision.EXCLUSION_UNKNOWN, incomplete.wa)
    }

    @Test fun visibleNormalMarkerAndRestrictiveTwins() {
        val material = publishMaterial()
        val positive = host.copy(children = listOf(marker))
        val allowed = requireNotNull(go(listOf(window(positive)), material))
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, allowed.normal)
        assertTrue(allowed.direct)
        assertEquals(KeyguardR448Admission.Decision.ALLOW, allowed.wa)
        val twins = listOf(
            listOf(window(host)),
            listOf(window(host.copy(children = listOf(marker.copy(visible = false))))),
            listOf(window(host.copy(children = listOf(Node(visible = false, children = listOf(marker)))))),
            listOf(window(host), window(marker, 20, 2, "fixture.foreign", false, AccessibilityWindowInfo.TYPE_APPLICATION)),
            listOf(window(positive.copy(children = positive.children + Node("com.android.systemui:id/keyguard_bouncer")))),
            listOf(window(positive.copy(children = positive.children + Node("com.android.systemui:id/quick_settings_panel")))),
            listOf(window(positive), window(Node(), 20, 2, "fixture.foreign", false, AccessibilityWindowInfo.TYPE_APPLICATION)),
        )
        for ((index, twin) in twins.withIndex()) {
            val denied = requireNotNull(go(twin, material))
            assertFalse("twin $index $denied", denied.direct)
            assertNotEquals("twin $index", KeyguardR448Admission.Decision.ALLOW, denied.wa)
        }
        for (excluded in listOf(system.copy(keyguardLocked = false),
            system.copy(interactive = false, displayOn = false, displayOff = true))) {
            val denied = requireNotNull(go(listOf(window(positive)), material, state = excluded))
            assertFalse(denied.direct)
            assertEquals(KeyguardR448Admission.Decision.SYSTEM_EXCLUDED, denied.wa)
        }
    }

    @Test fun coldRearmAndRouteReplacementKeepTheirOwnAuthority() {
        val positive = host.copy(children = listOf(marker))
        val cold = requireNotNull(go(listOf(window(positive))))
        assertFalse(cold.direct)
        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED, cold.wa)
        val material = publishMaterial()
        val nextWake = stamp.copy(wake = 2)
        val armed = requireNotNull(go(listOf(window(positive)), material, original = nextWake))
        assertTrue(armed.direct)
        assertEquals(KeyguardR448Admission.Decision.ALLOW, armed.wa)
        assertNull(go(listOf(window(positive)), material, current = false))
        val old = requireNotNull(go(listOf(window(positive)), material, original = nextWake,
            nowOwner = nextWake.copy(route = 2)))
        assertEquals(KeyguardR448Admission.Decision.OWNER_CHANGED, old.wa)
        FluviActiveHeaderMaterialStore.invalidate()
        val invalidated = requireNotNull(go(listOf(window(positive)), material, original = nextWake))
        assertFalse(invalidated.direct)
        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED, invalidated.wa)
    }

    @Test fun existingPassiveObserverDoesNotChangeDeterministicBoundaryReplay() {
        val material = publishMaterial()
        val cases = listOf(host, host.copy(children = listOf(marker)),
            host.copy(children = listOf(marker, Node("com.android.systemui:id/keyguard_bouncer"))))
        val without = cases.map { go(listOf(window(it)), material) }
        assertEquals(cases.size, service.inventoryCalls)
        val with = cases.map { go(listOf(window(it)), material, observe = true) }
        assertEquals(cases.size * 2, service.inventoryCalls)
        assertEquals(without, with)
    }
}
