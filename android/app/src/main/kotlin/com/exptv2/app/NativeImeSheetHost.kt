package com.exptv2.app

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class NativeImeSheetHost(private val activity: Activity) {
    private var overlay: FrameLayout? = null
    private var sheetContainer: FrameLayout? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var previousSoftInputMode: Int? = null
    private var frameSeq = 0L
    private var lastLoggedImePx = Int.MIN_VALUE

    fun attachMainChannel(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openProbe" -> {
                    openProbe()
                    result.success(null)
                }
                "closeProbe" -> {
                    closeProbe()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun openProbe() {
        val root = ensureOverlay()
        ensureFlutterContent()
        if (previousSoftInputMode == null) {
            previousSoftInputMode = activity.window.attributes.softInputMode
        }
        activity.window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
        root.visibility = View.VISIBLE
        root.bringToFront()
        ViewCompat.requestApplyInsets(root)
        publish("[NativeImeSheet] probe open host=android-native-motion")
    }

    fun closeProbe() {
        hideKeyboard()
        sheetContainer?.translationY = 0f
        overlay?.visibility = View.GONE
        restoreSoftInputMode()
        publish("[NativeImeSheet] probe close")
    }

    fun dispose() {
        closeProbe()
        flutterView?.detachFromFlutterEngine()
        flutterView = null
        flutterEngine?.destroy()
        flutterEngine = null
        val root = overlay
        if (root?.parent is ViewGroup) {
            (root.parent as ViewGroup).removeView(root)
        }
        overlay = null
        sheetContainer = null
    }

    private fun ensureOverlay(): FrameLayout {
        val existing = overlay
        if (existing != null) return existing

        val root = FrameLayout(activity).apply {
            visibility = View.GONE
            isClickable = false
            fitsSystemWindows = false
        }
        val backdrop = View(activity).apply {
            setBackgroundColor(Color.argb(82, 15, 23, 42))
            isClickable = true
            setOnClickListener { closeProbe() }
        }
        val sheet = FrameLayout(activity).apply {
            isClickable = true
            isFocusable = false
        }
        root.addView(
            backdrop,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        root.addView(
            sheet,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                probeHeightPx(),
                Gravity.BOTTOM,
            ),
        )
        ViewCompat.setWindowInsetsAnimationCallback(
            root,
            object : WindowInsetsAnimationCompat.Callback(
                WindowInsetsAnimationCompat.Callback.DISPATCH_MODE_CONTINUE_ON_SUBTREE,
            ) {
                override fun onStart(
                    animation: WindowInsetsAnimationCompat,
                    bounds: WindowInsetsAnimationCompat.BoundsCompat,
                ): WindowInsetsAnimationCompat.BoundsCompat {
                    if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
                        publish(
                            "[NativeImeSheet] ime start lower=${bounds.lowerBound.bottom} " +
                                "upper=${bounds.upperBound.bottom} duration=${animation.durationMillis}ms",
                        )
                    }
                    return bounds
                }

                override fun onProgress(
                    insets: WindowInsetsCompat,
                    runningAnimations: MutableList<WindowInsetsAnimationCompat>,
                ): WindowInsetsCompat {
                    val imeBottomPx = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
                    val translation = NativeImeSheetMotion.translationYForIme(imeBottomPx)
                    sheet.translationY = translation
                    logProgress(imeBottomPx, translation)
                    return insets
                }

                override fun onEnd(animation: WindowInsetsAnimationCompat) {
                    if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
                        val imeBottomPx = currentImeBottomPx()
                        val translation = NativeImeSheetMotion.translationYForIme(imeBottomPx)
                        sheet.translationY = translation
                        publish(
                            "[NativeImeSheet] ime end ime=$imeBottomPx translation=$translation",
                        )
                    }
                }
            },
        )
        activity.findViewById<ViewGroup>(android.R.id.content).addView(
            root,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        overlay = root
        sheetContainer = sheet
        return root
    }

    private fun ensureFlutterContent() {
        val sheet = sheetContainer ?: return
        if (flutterView != null) return
        val engine = ensureFlutterEngine()
        val view = FlutterView(activity).apply {
            attachToFlutterEngine(engine)
        }
        sheet.addView(
            view,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        flutterView = view
    }

    private fun ensureFlutterEngine(): FlutterEngine {
        val existing = flutterEngine
        if (existing != null) return existing
        val engine = FlutterEngine(activity)
        attachSheetChannel(engine)
        val loader = FlutterInjector.instance().flutterLoader()
        val entrypoint = DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(),
            "nativeImeSheetMain",
        )
        engine.dartExecutor.executeDartEntrypoint(entrypoint)
        flutterEngine = engine
        return engine
    }

    private fun attachSheetChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "closeProbe" -> {
                        closeProbe()
                        result.success(null)
                    }
                    "openProbe" -> {
                        openProbe()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun logProgress(imeBottomPx: Int, translation: Float) {
        frameSeq += 1
        if (frameSeq == 1L || imeBottomPx == 0 || abs(imeBottomPx - lastLoggedImePx) >= logStepPx()) {
            lastLoggedImePx = imeBottomPx
            publish(
                "[NativeImeSheet] ime progress seq=$frameSeq ime=$imeBottomPx " +
                    "translation=$translation source=native-onProgress",
            )
        }
    }

    private fun currentImeBottomPx(): Int {
        val insets = ViewCompat.getRootWindowInsets(overlay ?: activity.window.decorView)
            ?: return 0
        return insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
    }

    private fun restoreSoftInputMode() {
        val previous = previousSoftInputMode ?: return
        activity.window.setSoftInputMode(previous)
        previousSoftInputMode = null
    }

    private fun hideKeyboard() {
        val token = overlay?.windowToken ?: activity.window.decorView.windowToken
        val inputMethodManager = activity.getSystemService(
            Context.INPUT_METHOD_SERVICE,
        ) as InputMethodManager
        inputMethodManager.hideSoftInputFromWindow(token, 0)
    }

    private fun probeHeightPx(): Int {
        return (360f * activity.resources.displayMetrics.density).toInt()
    }

    private fun logStepPx(): Int {
        return (32f * activity.resources.displayMetrics.density).toInt().coerceAtLeast(1)
    }

    private fun publish(message: String) {
        Log.d(logTag, message)
        EventBroadcaster.publishDebugLog(message)
    }

    private companion object {
        const val channelName = "exptv2/native_ime_sheet"
        const val logTag = "NativeImeSheet"
    }
}
