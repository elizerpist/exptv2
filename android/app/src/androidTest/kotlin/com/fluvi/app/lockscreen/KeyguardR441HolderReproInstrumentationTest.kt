package com.fluvi.app.lockscreen

import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Minimal platform control. It is not the Fluvi renderer or an OEM result. */
@RunWith(AndroidJUnit4::class)
class KeyguardR441HolderReproInstrumentationTest {
    @Test fun realHolderPostThenDetach() = exercise(false)
    @Test fun realHolderDetachWhileCanvasIsLocked() = exercise(true)

    private fun exercise(hold: Boolean) {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid"))).toString()
        val out = File(ins.targetContext.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val activity = ins.startActivitySync(Intent(ins.targetContext, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val ready = CountDownLatch(1)
        val locked = CountDownLatch(1)
        val release = CountDownLatch(1)
        val posted = CountDownLatch(1)
        val removeEntered = CountDownLatch(1)
        val removed = CountDownLatch(1)
        val destroyed = CountDownLatch(1)
        val failure = AtomicReference<Throwable?>()
        lateinit var surface: SurfaceView
        lateinit var parent: FrameLayout
        fun stage(message: String) {
            val line = "run=$uuid hold=$hold uptime=${SystemClock.uptimeMillis()} $message"
            android.util.Log.i("FluviR441Minimal", line)
            synchronized(out) { out.resolve("minimal-stages.txt").appendText("$line\n") }
        }
        try {
            ins.runOnMainSync {
                parent = FrameLayout(activity).apply { setBackgroundColor(Color.BLACK) }
                surface = SurfaceView(activity)
                surface.holder.addCallback(object : SurfaceHolder.Callback {
                    override fun surfaceCreated(holder: SurfaceHolder) {
                        stage("CREATED holder=${System.identityHashCode(holder)}")
                    }
                    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                        stage("CHANGED holder=${System.identityHashCode(holder)} size=${width}x$height valid=${holder.surface.isValid}")
                        if (width > 0 && height > 0 && holder.surface.isValid) ready.countDown()
                    }
                    override fun surfaceDestroyed(holder: SurfaceHolder) {
                        stage("DESTROY_BEGIN holder=${System.identityHashCode(holder)}")
                        destroyed.countDown()
                        stage("DESTROY_RETURN holder=${System.identityHashCode(holder)}")
                    }
                })
                parent.addView(surface, FrameLayout.LayoutParams(168, 168))
                activity.setContentView(parent)
            }
            assertTrue("NOT REACHED: valid real SurfaceView", ready.await(15, TimeUnit.SECONDS))
            val producer = Thread {
                try {
                    stage("LOCK_BEGIN")
                    val canvas = checkNotNull(surface.holder.lockHardwareCanvas())
                    stage("LOCK_RETURN hardware=${canvas.isHardwareAccelerated}")
                    locked.countDown()
                    if (hold) check(release.await(15, TimeUnit.SECONDS))
                    canvas.drawColor(Color.RED)
                    stage("POST_BEGIN")
                    surface.holder.unlockCanvasAndPost(canvas)
                    stage("POST_RETURN")
                } catch (t: Throwable) { failure.set(t); stage("PRODUCER_ERROR ${t.javaClass.simpleName}") }
                finally { posted.countDown() }
            }.apply { name = "r441-minimal-producer"; start() }
            assertTrue("NOT REACHED: hardware canvas lock", locked.await(15, TimeUnit.SECONDS))
            if (!hold) assertTrue("NOT REACHED: real post", posted.await(15, TimeUnit.SECONDS))
            Handler(Looper.getMainLooper()).post {
                stage("REMOVE_BEGIN")
                removeEntered.countDown()
                parent.removeView(surface)
                stage("REMOVE_RETURN")
                removed.countDown()
            }
            assertTrue("NOT REACHED: real removal entered", removeEntered.await(15, TimeUnit.SECONDS))
            // Release from instrumentation, never by joining the producer on Main.
            release.countDown()
            assertTrue("NOT REACHED: producer left holder", posted.await(15, TimeUnit.SECONDS))
            assertTrue("NOT REACHED: removal returned", removed.await(15, TimeUnit.SECONDS))
            assertTrue("NOT REACHED: surfaceDestroyed", destroyed.await(15, TimeUnit.SECONDS))
            producer.join(1000)
            assertNull("real holder operation failed", failure.get())
            stage("COMPLETE")
        } finally {
            release.countDown()
            ins.runOnMainSync { activity.finish() }
        }
    }
}
