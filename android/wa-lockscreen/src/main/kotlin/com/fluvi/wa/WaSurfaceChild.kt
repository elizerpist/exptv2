package com.fluvi.wa

import android.annotation.TargetApi
import android.content.Context
import android.graphics.PixelFormat
import android.os.Handler
import android.util.Log
import android.view.Display
import android.view.SurfaceControl
import android.view.SurfaceControlViewHost
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import java.util.concurrent.Executor

/** One windowless visual and one independently owned handle, both Main-owned. */
@TargetApi(34)
internal class WaSurfaceChild(
    context: Context,
    private val main: Handler,
    private val available: (WaSurfaceChild) -> Unit,
    private val lost: (WaSurfaceChild) -> Unit,
) : SurfaceHolder.Callback {
    val surface = SurfaceView(context).apply {
        holder.setFormat(PixelFormat.TRANSLUCENT)
        setZOrderOnTop(true)
        holder.addCallback(this@WaSurfaceChild)
    }
    private var host: SurfaceControlViewHost? = null
    private var owned: SurfaceControlViewHost.SurfacePackage? = null
    private var closed = false
    val ready get() = owned?.surfaceControl?.isValid == true && surface.holder.surface.isValid

    @Suppress("DEPRECATION")
    fun attach(visual: View, diameter: Int) {
        check(!closed && host == null && surface.holder.surface.isValid)
        val display = checkNotNull(surface.display)
        check(display.displayId == Display.DEFAULT_DISPLAY)
        val token = checkNotNull(surface.hostToken)
        val viewHost = SurfaceControlViewHost(visual.context, display, token)
        host = viewHost
        viewHost.setView(visual, diameter, diameter)
        val supplied = checkNotNull(viewHost.surfacePackage)
        var transferred = false
        try {
            owned = SurfaceControlViewHost.SurfacePackage(supplied)
            check(owned?.surfaceControl?.isValid == true)
            surface.setChildSurfacePackage(supplied)
            transferred = true
        } finally {
            if (!transferred) supplied.release()
        }
    }

    fun resize(diameter: Int) {
        host?.relayout(diameter, diameter)
    }

    /** Never wait for a receipt. A pending framework reparent/show cannot reset alpha. */
    fun withdraw(receipt: ((WaTime) -> Unit)?): WaChildHide {
        val request = WaTime.now()
        val child = owned?.surfaceControl
        if (child == null || !child.isValid) return WaChildHide(
            if (host == null) "NOT_READY" else "INVALID_HANDLE", request,
        )
        var returned: WaTime? = null
        var listener = "UNOBSERVED"
        return try {
            SurfaceControl.Transaction().use { transaction ->
                transaction.setVisibility(child, false).setAlpha(child, 0f)
                if (receipt != null) {
                    try {
                        transaction.addTransactionCommittedListener(Executor { main.post(it) }) {
                            receipt(WaTime.now())
                        }
                        listener = "PENDING"
                    } catch (error: RuntimeException) {
                        listener = "REGISTRATION_ERROR"
                        Log.w(TAG, "hide listener: ${error.javaClass.simpleName}")
                    }
                }
                transaction.apply()
                returned = WaTime.now()
            }
            WaChildHide("APPLIED", request, returned, listener)
        } catch (error: RuntimeException) {
            WaChildHide(if (returned == null) "ERROR" else "APPLIED", request, returned,
                if (returned == null) "UNOBSERVED" else listener, error.javaClass.simpleName)
        }
    }

    fun dispose() {
        if (closed) return
        closed = true
        surface.holder.removeCallback(this)
        val viewHost = host
        val handle = owned
        host = null
        owned = null
        try {
            viewHost?.release()
        } finally {
            handle?.release()
        }
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        if (!closed) available(this)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        if (!closed) lost(this)
    }

    private companion object {
        const val TAG = "FluviBalanceOrb"
    }
}
