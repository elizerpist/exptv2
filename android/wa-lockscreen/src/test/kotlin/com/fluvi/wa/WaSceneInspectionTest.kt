package com.fluvi.wa

import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.mockito.Mockito.*

@Suppress("DEPRECATION")
class WaSceneInspectionTest {
    private fun window(type: Int) = mock(AccessibilityWindowInfo::class.java).also {
        `when`(it.type).thenReturn(type)
    }

    @Test fun applicationInEitherOrderNeverTouchesRootsAndReleasesTheWholeList() = runBlocking {
        for (appFirst in listOf(false, true)) {
            val overlay = window(AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY)
            val system = window(AccessibilityWindowInfo.TYPE_SYSTEM)
            val app = window(AccessibilityWindowInfo.TYPE_APPLICATION)
            `when`(system.root).thenThrow(IllegalStateException("unavailable root"))
            val windows = if (appFirst) listOf(app, system, overlay) else listOf(overlay, system, app)
            val metadata = mutableListOf<Boolean>()
            assertEquals(WaSceneReading.APP_WINDOW_PRESENT, WaLockscreenScene.inspect(windows, null, metadata::add))
            assertEquals(listOf(true), metadata)
            windows.forEach {
                verify(it, never()).root
                verify(it).recycle()
            }
        }
    }

    @Test fun noApplicationKeepsNodeClassifiersAndReleasesEveryAcquiredNode() = runBlocking {
        for (shade in listOf(false, true)) {
            val system = window(AccessibilityWindowInfo.TYPE_SYSTEM)
            val root = mock(AccessibilityNodeInfo::class.java)
            val copy = mock(AccessibilityNodeInfo::class.java)
            val child = mock(AccessibilityNodeInfo::class.java)
            `when`(system.root).thenReturn(root)
            `when`(root.packageName).thenReturn("com.android.systemui")
            `when`(copy.isVisibleToUser).thenReturn(true)
            `when`(copy.childCount).thenReturn(1)
            `when`(copy.getChild(0)).thenReturn(child)
            `when`(child.isVisibleToUser).thenReturn(true)
            if (shade) `when`(child.viewIdResourceName).thenReturn("com.android.systemui:id/quick_settings_panel")
            mockStatic(AccessibilityNodeInfo::class.java).use { nodes ->
                nodes.`when`<AccessibilityNodeInfo> { AccessibilityNodeInfo.obtain(root) }.thenReturn(copy)
                val metadata = mutableListOf<Boolean>()
                assertEquals(if (shade) WaSceneReading.NODE_RESTRICTION else WaSceneReading.MAIN,
                    WaLockscreenScene.inspect(listOf(system), null, metadata::add))
                assertEquals(listOf(false), metadata)
            }
            verify(system).root
            verify(copy).getChild(0)
            listOf(copy, root, child).forEach { verify(it).recycle() }
            verify(system).recycle()
        }
    }

    @Test fun missingListIsUnknownAndAnEmptyObservedListHasACompletedNegative() = runBlocking {
        val metadata = mutableListOf<Boolean>()
        assertEquals(WaSceneReading.UNKNOWN, WaLockscreenScene.inspect(null, null, metadata::add))
        assertTrue(metadata.isEmpty())
        assertEquals(WaSceneReading.UNKNOWN, WaLockscreenScene.inspect(emptyList(), null, metadata::add))
        val overlay = window(AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY)
        assertEquals(WaSceneReading.UNKNOWN, WaLockscreenScene.inspect(listOf(overlay), null, metadata::add))
        assertEquals(listOf(false, false), metadata)
        verify(overlay, never()).root
        verify(overlay).recycle()
    }

    @Test fun canceledMetadataIsUnknownAndThrowingNodeReleasesTheQueueAndAllWindows() = runBlocking {
        val before = window(AccessibilityWindowInfo.TYPE_SYSTEM)
        val after = window(AccessibilityWindowInfo.TYPE_APPLICATION)
        val metadata = mutableListOf<Boolean>()
        val job = launch {
            val current = coroutineContext[Job]!!
            `when`(before.type).thenAnswer { current.cancel(CancellationException("superseded")); AccessibilityWindowInfo.TYPE_SYSTEM }
            WaLockscreenScene.inspect(listOf(before, after), null, metadata::add)
        }
        job.join()
        assertTrue(job.isCancelled)
        assertTrue(metadata.isEmpty())
        listOf(before, after).forEach { verify(it, never()).root; verify(it).recycle() }

        val system = window(AccessibilityWindowInfo.TYPE_SYSTEM)
        val root = mock(AccessibilityNodeInfo::class.java)
        val copy = mock(AccessibilityNodeInfo::class.java)
        val queued = mock(AccessibilityNodeInfo::class.java)
        `when`(system.root).thenReturn(root)
        `when`(root.packageName).thenReturn("com.android.systemui")
        `when`(copy.isVisibleToUser).thenReturn(true)
        `when`(copy.childCount).thenReturn(2)
        `when`(copy.getChild(0)).thenReturn(queued)
        `when`(copy.getChild(1)).thenThrow(IllegalStateException("detached"))
        mockStatic(AccessibilityNodeInfo::class.java).use { nodes ->
            nodes.`when`<AccessibilityNodeInfo> { AccessibilityNodeInfo.obtain(root) }.thenReturn(copy)
            try {
                WaLockscreenScene.inspect(listOf(system), null, metadata::add)
                fail("A throwing node must reach the service's UNKNOWN fallback")
            } catch (_: IllegalStateException) {
                assertEquals(listOf(false), metadata)
            }
        }
        listOf(root, copy, queued).forEach { verify(it).recycle() }
        verify(system).recycle()
    }
}
