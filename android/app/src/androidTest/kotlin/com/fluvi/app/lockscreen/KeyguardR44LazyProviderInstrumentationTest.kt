package com.fluvi.app.lockscreen

import android.app.Activity
import android.app.UiAutomation
import android.content.Intent
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityNodeProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises Android's actual lazy-extra provider boundary on API 37. The
 * provider is Fluvi-owned test content, not SystemUI or OEM qualification. */
@RunWith(AndroidJUnit4::class)
class KeyguardR44LazyProviderInstrumentationTest {
    @Test fun advertisedTagIsFilledOnlyAfterRealExtraRequest() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val ui = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val activity = instrumentation.startActivitySync(Intent(instrumentation.targetContext,
            KeyguardMaterialTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        val calls = AtomicInteger()
        try {
            instrumentation.runOnMainSync { activity.setContentView(LazyTagView(activity, calls)) }
            instrumentation.waitForIdleSync()
            fun find(node: AccessibilityNodeInfo?, depth: Int): AccessibilityNodeInfo? {
                if (node == null || depth > 20) return null
                if (node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) return AccessibilityNodeInfo.obtain(node)
                for (i in 0 until node.childCount) {
                    val child = node.getChild(i)
                    val match = try { find(child, depth + 1) } finally { child?.recycle() }
                    if (match != null) return match
                }
                return null
            }
            val until = SystemClock.uptimeMillis() + 10_000
            var found: AccessibilityNodeInfo? = null
            while (found == null && SystemClock.uptimeMillis() < until) {
                val root = ui.rootInActiveWindow
                try { found = find(root, 0) } finally { root?.recycle() }
                if (found == null) SystemClock.sleep(50)
            }
            val node = checkNotNull(found) { "NOT REACHED: advertised synthetic provider node" }
            try {
                assertEquals(instrumentation.targetContext.packageName, node.packageName.toString())
                assertNull(node.extras.getCharSequence(KeyguardR44Markers.EXTRA))
                val beforeParent = checkNotNull(node.parent) { "NOT REACHED: provider parent" }
                val beforeIdentity = try { KeyguardR443ParentIdentity.of(beforeParent) }
                    finally { beforeParent.recycle() }
                assertNotNull("real parent must have a recheckable bounded identity", beforeIdentity)
                assertTrue(node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()))
                assertEquals("element:lockscreen", node.extras.getCharSequence(KeyguardR44Markers.EXTRA).toString())
                assertEquals(1, calls.get())
                val afterParent = checkNotNull(node.parent) { "NOT REACHED: provider parent after IPC" }
                val afterIdentity = try { KeyguardR443ParentIdentity.of(afterParent) }
                    finally { afterParent.recycle() }
                assertEquals("parent identity changed across real lazy IPC", beforeIdentity, afterIdentity)
            } finally { node.recycle() }
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    private class LazyTagView(activity: Activity, private val calls: AtomicInteger) : View(activity) {
        init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES }
        override fun onInitializeAccessibilityNodeInfo(info: AccessibilityNodeInfo) {
            super.onInitializeAccessibilityNodeInfo(info)
            info.addChild(this, 1)
        }
        override fun getAccessibilityNodeProvider(): AccessibilityNodeProvider = object : AccessibilityNodeProvider() {
            override fun createAccessibilityNodeInfo(virtualViewId: Int): AccessibilityNodeInfo? {
                if (virtualViewId == HOST_VIEW_ID) return AccessibilityNodeInfo.obtain(this@LazyTagView).apply {
                    onInitializeAccessibilityNodeInfo(this)
                }
                if (virtualViewId != 1) return null
                return AccessibilityNodeInfo.obtain().apply {
                    setSource(this@LazyTagView, 1)
                    setParent(this@LazyTagView)
                    packageName = context.packageName
                    className = View::class.java.name
                    isVisibleToUser = true
                    isEnabled = true
                    setBoundsInParent(Rect(0, 0, 200, 200))
                    availableExtraData = listOf(KeyguardR44Markers.EXTRA)
                }
            }
            override fun addExtraDataToAccessibilityNodeInfo(virtualViewId: Int, info: AccessibilityNodeInfo,
                extraDataKey: String, arguments: Bundle?) {
                if (virtualViewId == 1 && extraDataKey == KeyguardR44Markers.EXTRA && arguments != null) {
                    calls.incrementAndGet()
                    info.extras.putCharSequence(extraDataKey, "element:lockscreen")
                }
            }
        }
    }
}
