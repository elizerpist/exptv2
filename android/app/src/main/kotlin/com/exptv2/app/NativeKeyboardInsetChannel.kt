package com.exptv2.app

import android.app.Activity
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.plugin.common.EventChannel
import kotlin.math.roundToLong

class NativeKeyboardInsetChannel(private val activity: Activity) {
    private var sink: EventChannel.EventSink? = null
    private var installed = false
    private var sequence = 0L
    private var activeLowerImePx = 0
    private var activeUpperImePx = 0
    private var activeDurationMs = defaultDurationMs
    private var activeSessionStarted = false
    private var activeSessionStartImePx = 0
    private var activeSessionEndImePx = 0

    private val density: Float
        get() = activity.resources.displayMetrics.density
    private val rootView: View
        get() = activity.window.decorView

    fun attach(channel: EventChannel) {
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sink = events
                installCallbacks()
                val currentImePx = currentImePx()
                emitSession(
                    phase = "listen",
                    currentImePx = currentImePx,
                    startImePx = currentImePx,
                    endImePx = currentImePx,
                    durationMs = 0L,
                    fraction = null,
                )
            }

            override fun onCancel(arguments: Any?) {
                sink = null
                resetActiveSession()
            }
        })
    }

    private fun installCallbacks() {
        if (installed) return
        installed = true
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { _, insets ->
            insets
        }
        ViewCompat.setWindowInsetsAnimationCallback(
            rootView,
            object : WindowInsetsAnimationCompat.Callback(
                WindowInsetsAnimationCompat.Callback.DISPATCH_MODE_CONTINUE_ON_SUBTREE,
            ) {
                override fun onStart(
                    animation: WindowInsetsAnimationCompat,
                    bounds: WindowInsetsAnimationCompat.BoundsCompat,
                ): WindowInsetsAnimationCompat.BoundsCompat {
                    if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
                        activeLowerImePx = bounds.lowerBound.bottom
                        activeUpperImePx = bounds.upperBound.bottom
                        activeDurationMs = animation.durationMillis
                            .takeIf { it > 0L }
                            ?: defaultDurationMs
                        activeSessionStarted = false
                        activeSessionStartImePx = 0
                        activeSessionEndImePx = 0
                    }
                    return bounds
                }

                override fun onProgress(
                    insets: WindowInsetsCompat,
                    runningAnimations: MutableList<WindowInsetsAnimationCompat>,
                ): WindowInsetsCompat {
                    val imeAnimation = runningAnimations.firstOrNull {
                        it.typeMask and WindowInsetsCompat.Type.ime() != 0
                    }
                    if (imeAnimation != null && !activeSessionStarted) {
                        val currentImePx =
                            insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
                        beginSessionFromProgress(
                            currentImePx = currentImePx,
                            fraction = imeAnimation.interpolatedFraction,
                        )
                    }
                    return insets
                }

                override fun onEnd(animation: WindowInsetsAnimationCompat) {
                    if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
                        val finalImePx = currentImePx().takeIf {
                            it == activeSessionEndImePx || it > 0
                        } ?: activeSessionEndImePx
                        emitSession(
                            phase = "end",
                            currentImePx = finalImePx,
                            startImePx = activeSessionStartImePx,
                            endImePx = finalImePx,
                            durationMs = activeDurationMs,
                            fraction = animation.interpolatedFraction,
                        )
                        resetActiveSession()
                    }
                }
            },
        )
    }

    private fun beginSessionFromProgress(currentImePx: Int, fraction: Float) {
        val lower = activeLowerImePx
        val upper = activeUpperImePx.coerceAtLeast(lower)
        val midpoint = lower + ((upper - lower) / 2.0)
        val opening = currentImePx <= midpoint
        val startImePx = if (opening) lower else upper
        val endImePx = if (opening) upper else lower
        activeSessionStarted = true
        activeSessionStartImePx = startImePx
        activeSessionEndImePx = endImePx
        emitSession(
            phase = "start",
            currentImePx = currentImePx,
            startImePx = startImePx,
            endImePx = endImePx,
            durationMs = activeDurationMs,
            fraction = fraction,
        )
    }

    private fun resetActiveSession() {
        activeLowerImePx = 0
        activeUpperImePx = 0
        activeDurationMs = defaultDurationMs
        activeSessionStarted = false
        activeSessionStartImePx = 0
        activeSessionEndImePx = 0
    }

    private fun currentImePx(): Int {
        val insets = ViewCompat.getRootWindowInsets(rootView) ?: return 0
        return insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
    }

    private fun emitSession(
        phase: String,
        currentImePx: Int,
        startImePx: Int,
        endImePx: Int,
        durationMs: Long,
        fraction: Float?,
    ) {
        val eventSink = sink ?: return
        val eventEpochMs = System.currentTimeMillis()
        val normalizedFraction = fraction?.coerceIn(0f, 1f)
        val startedAtEpochMs = if (durationMs > 0L && normalizedFraction != null) {
            eventEpochMs - (durationMs * normalizedFraction).roundToLong()
        } else {
            eventEpochMs
        }
        val event = mapOf(
            "kind" to "session",
            "source" to "native-ime",
            "nativeSource" to "WindowInsetsAnimation",
            "phase" to phase,
            "seq" to ++sequence,
            "imePx" to currentImePx,
            "imeDp" to currentImePx / density,
            "startImePx" to startImePx,
            "startImeDp" to startImePx / density,
            "endImePx" to endImePx,
            "endImeDp" to endImePx / density,
            "durationMs" to durationMs,
            "fraction" to fraction,
            "eventEpochMs" to eventEpochMs,
            "startedAtEpochMs" to startedAtEpochMs,
            "eventNanos" to System.nanoTime(),
        )
        eventSink.success(event)
    }

    private companion object {
        const val defaultDurationMs = 180L
    }
}
