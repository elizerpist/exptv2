package com.fluvi.app.lockscreen

import android.content.Intent
import android.content.Context
import android.graphics.Canvas
import android.view.View
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.SdkSuppress
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardBootstrapFrameToken
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Uses the production observer against Android's real ViewTreeObserver draw
 * traversal. A direct removeOnDrawListener from onDraw would make this
 * dispatch throw on current Android releases. */
@RunWith(AndroidJUnit4::class)
class KeyguardFirstDrawObservationInstrumentationTest {
    @Test
    @SdkSuppress(minSdkVersion = 29)
    fun frameCommitPublishesOnceForAnAttachedFrame() {
        val fixture = fixture()
        try {
            val committed = AtomicInteger()
            val event = AtomicReference<KeyguardFrameCommitEvent>()
            val callback = CountDownLatch(1)
            lateinit var observation: KeyguardFrameCommitObservation
            val token = KeyguardBootstrapFrameToken(1L, "test-bootstrap")
            fixture.instrumentation.runOnMainSync {
                observation = KeyguardFrameCommitObservation(
                    root = fixture.root,
                    attachGeneration = 8L,
                    bootstrapToken = token,
                    nowUptimeMs = { 888L },
                ) { value ->
                    committed.incrementAndGet()
                    event.set(value)
                    callback.countDown()
                }
                // Production installs the callback in pre-draw, then the
                // material View marks the matching bootstrap geometry from
                // its draw. This test follows the same ordering rather than
                // registering manually before invalidate.
                fixture.root.viewTreeObserver.addOnDrawListener {
                    observation.markExpectedDrawObserved(8L, token)
                }
                observation.startBeforeNextDraw()
                fixture.root.invalidate()
            }

            assertTrue("frame-commit callback was not observed", callback.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.waitForIdleSync()
            assertEquals(1, committed.get())
            assertEquals(8L, requireNotNull(event.get()).attachGeneration)
            assertEquals(token, requireNotNull(event.get()).bootstrapToken)
            assertEquals(888L, requireNotNull(event.get()).observedAtUptimeMs)

            fixture.instrumentation.runOnMainSync { fixture.root.invalidate() }
            fixture.instrumentation.waitForIdleSync()
            assertEquals("one observation must not register a second callback", 1, committed.get())
        } finally {
            fixture.close()
        }
    }

    @Test
    @SdkSuppress(minSdkVersion = 29)
    fun frameCommitArmSurvivesDetachedRootAndReattachWithoutDuplicatePublication() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val committed = AtomicInteger()
        val callback = CountDownLatch(1)
        val token = KeyguardBootstrapFrameToken(3L, "reattached-bootstrap")
        lateinit var root: BootstrapDrawView
        lateinit var first: KeyguardFrameCommitObservation
        lateinit var second: KeyguardFrameCommitObservation
        try {
            instrumentation.runOnMainSync {
                root = BootstrapDrawView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(240, 160)
                }
                first = KeyguardFrameCommitObservation(
                    root = root,
                    attachGeneration = 10L,
                    bootstrapToken = token,
                ) { committed.incrementAndGet() }
                root.onBootstrapDraw = { first.markExpectedDrawObserved(10L, token) }
                // Cancellation while detached must remove the retained arm;
                // the later physical attachment cannot publish it.
                first.startBeforeNextDraw()
                first.cancel()
                activity.setContentView(root)
                root.invalidate()
            }
            instrumentation.waitForIdleSync()
            assertEquals("cancelled pre-attach arm published", 0, committed.get())

            instrumentation.runOnMainSync {
                // Real detach gives the root a replacement ViewTreeObserver.
                activity.setContentView(FrameLayout(activity))
                second = KeyguardFrameCommitObservation(
                    root = root,
                    attachGeneration = 11L,
                    bootstrapToken = token,
                ) {
                    committed.incrementAndGet()
                    callback.countDown()
                }
                root.onBootstrapDraw = { second.markExpectedDrawObserved(11L, token) }
                second.startBeforeNextDraw()
                activity.setContentView(root)
                root.invalidate()
            }
            assertTrue("reattached root never committed", callback.await(8, TimeUnit.SECONDS))
            instrumentation.waitForIdleSync()
            assertEquals("only the replacement attachment may publish", 1, committed.get())
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test
    @SdkSuppress(minSdkVersion = 29)
    fun detachAfterBootstrapDrawRejectsQueuedFrameCommit() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val committed = AtomicInteger()
        val detached = CountDownLatch(1)
        val token = KeyguardBootstrapFrameToken(4L, "detached-before-commit")
        lateinit var root: BootstrapDrawView
        try {
            instrumentation.runOnMainSync {
                root = BootstrapDrawView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(240, 160)
                    onDetached = { detached.countDown() }
                }
                lateinit var observation: KeyguardFrameCommitObservation
                observation = KeyguardFrameCommitObservation(
                    root = root,
                    attachGeneration = 12L,
                    bootstrapToken = token,
                ) { committed.incrementAndGet() }
                root.onBootstrapDraw = {
                    observation.markExpectedDrawObserved(12L, token)
                    // Detach after the matching draw but before a stale frame
                    // callback is allowed to affect a replacement root.
                    root.post { activity.setContentView(FrameLayout(activity)) }
                }
                observation.startBeforeNextDraw()
                activity.setContentView(root)
                root.invalidate()
            }
            assertTrue("test root did not detach after bootstrap draw", detached.await(8, TimeUnit.SECONDS))
            instrumentation.waitForIdleSync()
            assertEquals("detached root published a stale frame commit", 0, committed.get())
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test fun firstDrawPublishesOnceAfterFrameworkDrawDispatch() {
        val fixture = fixture()
        try {
            val published = AtomicInteger()
            val event = AtomicReference<KeyguardFirstDrawEvent>()
            val posted = CountDownLatch(1)
            val pending = mutableListOf<Runnable>()
            lateinit var observation: KeyguardFirstDrawObservation
            fixture.instrumentation.runOnMainSync {
                observation = KeyguardFirstDrawObservation(
                    root = fixture.root,
                    attachGeneration = 5L,
                    nowUptimeMs = { 321L },
                    postToMain = { runnable ->
                        synchronized(pending) { pending += runnable }
                        posted.countDown()
                    },
                ) { draw ->
                    published.incrementAndGet()
                    event.set(draw)
                }
                observation.start()
                fixture.root.invalidate()
            }

            assertTrue("real ViewTreeObserver draw never reached observer", posted.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.runOnMainSync { takePending(pending).run() }
            fixture.instrumentation.waitForIdleSync()
            assertEquals(1, published.get())
            assertEquals(5L, requireNotNull(event.get()).attachGeneration)
            assertEquals(321L, requireNotNull(event.get()).observedAtUptimeMs)

            fixture.instrumentation.runOnMainSync { fixture.root.invalidate() }
            fixture.instrumentation.waitForIdleSync()
            assertEquals("additional draws must not publish again", 1, published.get())
        } finally {
            fixture.close()
        }
    }

    @Test fun cancellationAfterDrawBeforeDeferredPublicationCleansWithoutPublishing() {
        val fixture = fixture()
        try {
            val published = AtomicInteger()
            val posted = CountDownLatch(1)
            val pending = mutableListOf<Runnable>()
            lateinit var observation: KeyguardFirstDrawObservation
            fixture.instrumentation.runOnMainSync {
                observation = observation(
                    root = fixture.root,
                    attach = 9L,
                    pending = pending,
                    posted = posted,
                ) { published.incrementAndGet() }
                observation.start()
                fixture.root.invalidate()
            }
            assertTrue(posted.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.runOnMainSync {
                observation.cancel()
                takePending(pending).run()
            }
            fixture.instrumentation.waitForIdleSync()
            assertEquals("hide/detach may clean up but cannot publish stale draw", 0, published.get())
        } finally {
            fixture.close()
        }
    }

    @Test fun oldRetainedRootAttachCannotPublishIntoReplacementAttach() {
        val fixture = fixture()
        try {
            val published = mutableListOf<KeyguardFirstDrawEvent>()
            val firstPosted = CountDownLatch(1)
            val secondPosted = CountDownLatch(1)
            val firstPending = mutableListOf<Runnable>()
            val secondPending = mutableListOf<Runnable>()
            lateinit var first: KeyguardFirstDrawObservation
            lateinit var second: KeyguardFirstDrawObservation

            fixture.instrumentation.runOnMainSync {
                first = observation(fixture.root, 20L, firstPending, firstPosted) { published += it }
                first.start()
                fixture.root.invalidate()
            }
            assertTrue(firstPosted.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.runOnMainSync {
                // Same retained View, but Android gives it a new observer on
                // detach/reattach. The queued A cleanup must not publish.
                fixture.activity.setContentView(FrameLayout(fixture.activity))
                fixture.activity.setContentView(fixture.root)
                first.cancel()
                takePending(firstPending).run()
                second = observation(fixture.root, 21L, secondPending, secondPosted) { published += it }
                second.start()
                fixture.root.invalidate()
            }
            assertTrue(secondPosted.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.runOnMainSync { takePending(secondPending).run() }
            fixture.instrumentation.waitForIdleSync()

            assertEquals(1, published.size)
            assertEquals(21L, published.single().attachGeneration)
        } finally {
            fixture.close()
        }
    }

    @Test fun cancellationBeforeFirstDrawLeavesNoDeferredPublication() {
        val fixture = fixture()
        try {
            val published = AtomicInteger()
            val posted = CountDownLatch(1)
            val pending = mutableListOf<Runnable>()
            fixture.instrumentation.runOnMainSync {
                observation(fixture.root, 34L, pending, posted) { published.incrementAndGet() }.apply {
                    start()
                    cancel()
                }
                fixture.root.invalidate()
            }
            assertTrue("cancel cleanup was not posted", posted.await(8, TimeUnit.SECONDS))
            fixture.instrumentation.runOnMainSync { takePending(pending).run() }
            fixture.instrumentation.waitForIdleSync()
            assertEquals("cancel before draw must not publish", 0, published.get())
        } finally {
            fixture.close()
        }
    }

    private fun fixture(): Fixture {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var root: FrameLayout
        instrumentation.runOnMainSync {
            root = FrameLayout(activity).apply {
                layoutParams = FrameLayout.LayoutParams(240, 160)
            }
            activity.setContentView(root)
        }
        return Fixture(instrumentation, activity, root)
    }

    private fun observation(
        root: View,
        attach: Long,
        pending: MutableList<Runnable>,
        posted: CountDownLatch,
        onPublished: (KeyguardFirstDrawEvent) -> Unit,
    ) = KeyguardFirstDrawObservation(
        root = root,
        attachGeneration = attach,
        nowUptimeMs = { 777L },
        postToMain = { runnable ->
            synchronized(pending) { pending += runnable }
            posted.countDown()
        },
        onFirstDraw = onPublished,
    )

    private fun takePending(pending: MutableList<Runnable>): Runnable = synchronized(pending) {
        assertFalse("expected a deferred cleanup/publication", pending.isEmpty())
        pending.removeAt(0)
    }

    private class Fixture(
        val instrumentation: android.app.Instrumentation,
        val activity: KeyguardMaterialTestActivity,
        val root: FrameLayout,
    ) {
        fun close() {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    private class BootstrapDrawView(context: Context) : View(context) {
        var onBootstrapDraw: (() -> Unit)? = null
        var onDetached: (() -> Unit)? = null

        init {
            setWillNotDraw(false)
            setBackgroundColor(0xff557799.toInt())
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            onBootstrapDraw?.invoke()
        }

        override fun onDetachedFromWindow() {
            onDetached?.invoke()
            super.onDetachedFromWindow()
        }
    }
}
