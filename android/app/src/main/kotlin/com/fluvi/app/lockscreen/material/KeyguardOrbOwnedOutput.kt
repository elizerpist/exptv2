package com.fluvi.app.lockscreen.material

import android.annotation.TargetApi
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Surface
import android.view.SurfaceControl
import java.util.concurrent.Executor

/** Bounded native borrows for one generation. Sealing never waits for a draw
 * or PixelCopy; only the final borrower can make a retired owner disposable. */
internal class KeyguardOrbOutputLifetime {
    private var sealed = false
    private var borrowers = 0

    @Synchronized fun acquire(): Boolean {
        if (sealed) return false
        borrowers += 1
        return true
    }

    @Synchronized fun release(): Boolean {
        check(borrowers > 0)
        borrowers -= 1
        return sealed && borrowers == 0
    }

    @Synchronized fun seal(): Boolean {
        if (sealed) return false
        sealed = true
        return true
    }

    @Synchronized fun readyToDispose(): Boolean = sealed && borrowers == 0
    @Synchronized fun isSealed(): Boolean = sealed
}

/** One app-owned buffer layer below the framework SurfaceView control. The
 * borrowed parent is never changed or released. Main owns transactions and
 * disposal; worker draws and PixelCopy retain explicit native borrows. */
@TargetApi(35)
internal class KeyguardOrbOwnedOutput private constructor(
    private val child: SurfaceControl,
    private val surface: Surface,
    private val main: Handler,
    private val onReadyToDispose: (KeyguardOrbOwnedOutput) -> Unit,
) {
    private val lifetime = KeyguardOrbOutputLifetime()
    private var disposed = false
    private var retireResult: Boolean? = null
    val childId: Int = System.identityHashCode(child) // evidence only, never authority

    fun borrow(): Surface? = if (lifetime.acquire()) surface else null

    fun releaseBorrow() {
        if (lifetime.release()) main.post { onReadyToDispose(this) }
    }

    /** Called on Main after the target's worker admission is revoked. */
    fun retire(metrics: KeyguardOrbSurfaceMetrics?): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (!lifetime.seal()) return retireResult ?: false
        val begin = SystemClock.uptimeMillis()
        metrics?.r16RetireStarted(begin)
        var applied = false
        try {
            if (!child.isValid) return false
            val transaction = SurfaceControl.Transaction()
            try {
                transaction.setVisibility(child, false)
                if (metrics != null) runCatching {
                    var receipt = 0L
                    val executor = Executor { callback ->
                        receipt = SystemClock.uptimeMillis()
                        main.post(callback)
                    }
                    transaction.addTransactionCommittedListener(executor) {
                        metrics.r16RetireCommitted(receipt, SystemClock.uptimeMillis())
                    }
                }
                transaction.apply()
                applied = true
                return true
            } finally {
                runCatching { transaction.close() }
            }
        } finally {
            retireResult = applied
            metrics?.r16RetireReturned(SystemClock.uptimeMillis(), applied)
            if (lifetime.readyToDispose()) main.post { onReadyToDispose(this) }
        }
    }

    /** The caller holds the sole Main ownership slot until this succeeds. */
    fun disposeIfReady(): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (disposed) return true
        if (!lifetime.readyToDispose()) return false
        disposed = true
        runCatching { surface.release() }
        runCatching {
            val transaction = SurfaceControl.Transaction()
            try {
                if (child.isValid) transaction.reparent(child, null).apply()
            } finally {
                transaction.close()
            }
        }
        runCatching { child.release() }
        return true
    }

    fun isRetired(): Boolean = lifetime.isSealed()

    companion object {
        fun create(parent: SurfaceControl, width: Int, height: Int, generation: Long,
                   main: Handler, onReadyToDispose: (KeyguardOrbOwnedOutput) -> Unit): KeyguardOrbOwnedOutput {
            check(Looper.myLooper() == Looper.getMainLooper())
            require(parent.isValid && width > 0 && height > 0)
            val child = SurfaceControl.Builder().setName("FluviOrb-$generation")
                .setParent(parent).setBufferSize(width, height).setFormat(PixelFormat.RGBA_8888)
                .setOpaque(false).setHidden(true).build()
            var surface: Surface? = null
            try {
                val createdSurface = Surface(child)
                surface = createdSurface
                check(createdSurface.isValid)
                val transaction = SurfaceControl.Transaction()
                try {
                    transaction.setPosition(child, 0f, 0f).setCrop(child, Rect(0, 0, width, height))
                        .setLayer(child, 0).setVisibility(child, true).apply()
                } finally {
                    transaction.close()
                }
                return KeyguardOrbOwnedOutput(child, createdSurface, main, onReadyToDispose)
            } catch (error: Throwable) {
                runCatching { surface?.release() }
                runCatching { child.release() }
                throw error
            }
        }
    }
}
