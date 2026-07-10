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
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class NativeImeSheetHost(
    private val activity: Activity,
    private val configureFlutterEngine: (FlutterEngine) -> Unit = {},
) {
    private enum class SheetMode(val channelValue: String) {
        PROBE("probe"),
        ADD_TRANSACTION("addTransaction"),
    }

    private var mainChannel: MethodChannel? = null
    private var overlay: FrameLayout? = null
    private var sheetContainer: FrameLayout? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var engineMode: SheetMode? = null
    private var sheetMode = SheetMode.PROBE
    private var activeTransactionType = "expense"
    private var previousSoftInputMode: Int? = null
    private var frameSeq = 0L
    private var lastLoggedImePx = Int.MIN_VALUE

    fun attachMainChannel(channel: MethodChannel) {
        mainChannel = channel
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
                "openAddTransaction" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    result.success(true)
                    activity.window.decorView.post {
                        openAddTransaction(args["type"]?.toString())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun openProbe() {
        openSheet(
            mode = SheetMode.PROBE,
            transactionType = activeTransactionType,
            logMessage = "[NativeImeSheet] probe open host=android-native-motion",
        )
    }

    fun openAddTransaction(transactionType: String?) {
        openSheet(
            mode = SheetMode.ADD_TRANSACTION,
            transactionType = sanitizeTransactionType(transactionType),
            logMessage = "[NativeImeSheet] AddTransaction open " +
                "host=android-native-motion type=${sanitizeTransactionType(transactionType)}",
        )
    }

    private fun openSheet(
        mode: SheetMode,
        transactionType: String,
        logMessage: String,
    ) {
        val contentStale = sheetMode != mode || activeTransactionType != transactionType
        sheetMode = mode
        activeTransactionType = transactionType
        val root = ensureOverlay()
        updateSheetHeight()
        if (contentStale) destroyFlutterContent()
        if (previousSoftInputMode == null) {
            previousSoftInputMode = activity.window.attributes.softInputMode
        }
        activity.window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
        frameSeq = 0L
        lastLoggedImePx = Int.MIN_VALUE
        root.visibility = View.VISIBLE
        root.bringToFront()
        ViewCompat.requestApplyInsets(root)
        publish(logMessage)
        if (flutterView == null || engineMode != sheetMode) {
            root.postDelayed({ ensureFlutterContent() }, 16L)
        }
    }

    fun closeProbe() {
        closeSheet("[NativeImeSheet] probe close")
    }

    fun closeSheet() {
        closeSheet("[NativeImeSheet] sheet close")
    }

    private fun closeSheet(logMessage: String) {
        val shouldNotifyMain =
            sheetMode == SheetMode.ADD_TRANSACTION && overlay?.visibility == View.VISIBLE
        hideKeyboard()
        sheetContainer?.translationY = 0f
        overlay?.visibility = View.GONE
        restoreSoftInputMode()
        if (shouldNotifyMain) {
            mainChannel?.invokeMethod(
                "sheetClosed",
                mapOf("mode" to sheetMode.channelValue, "type" to activeTransactionType),
            )
        }
        publish(logMessage)
    }

    fun dispose() {
        closeSheet("[NativeImeSheet] dispose")
        destroyFlutterContent()
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
            setOnClickListener { closeSheet() }
        }
        val sheet = FrameLayout(activity).apply {
            isClickable = true
            isFocusable = false
            setBackgroundColor(Color.WHITE)
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
                sheetHeightPx(),
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
        if (flutterView != null && engineMode == sheetMode) return
        destroyFlutterContent()
        val engine = ensureFlutterEngine()
        val view = FlutterView(activity, FlutterTextureView(activity)).apply {
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
        if (existing != null && engineMode == sheetMode) return existing
        val engine = FlutterEngine(activity)
        configureFlutterEngine(engine)
        attachSheetChannel(engine)
        val loader = FlutterInjector.instance().flutterLoader()
        val entrypoint = DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(),
            "nativeImeSheetMain",
        )
        engine.dartExecutor.executeDartEntrypoint(entrypoint)
        flutterEngine = engine
        engineMode = sheetMode
        return engine
    }

    private fun attachSheetChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialState" -> {
                        result.success(
                            mapOf(
                                "mode" to sheetMode.channelValue,
                                "type" to activeTransactionType,
                            ),
                        )
                    }
                    "closeProbe" -> {
                        result.success(null)
                        closeProbe()
                    }
                    "closeSheet" -> {
                        result.success(null)
                        closeSheet()
                    }
                    "openProbe" -> {
                        openProbe()
                        result.success(null)
                    }
                    "transactionCommitted" -> {
                        publish(
                            "[NativeImeSheet] AddTransaction committed " +
                                "source=sheet type=$activeTransactionType",
                        )
                        result.success(null)
                        closeSheet("[NativeImeSheet] AddTransaction close after commit")
                        mainChannel?.invokeMethod(
                            "transactionCommitted",
                            mapOf("type" to activeTransactionType),
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun destroyFlutterContent() {
        flutterView?.detachFromFlutterEngine()
        flutterView = null
        sheetContainer?.removeAllViews()
        flutterEngine?.destroy()
        flutterEngine = null
        engineMode = null
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

    private fun updateSheetHeight() {
        val sheet = sheetContainer ?: return
        val params = sheet.layoutParams as? FrameLayout.LayoutParams ?: return
        params.height = sheetHeightPx()
        sheet.layoutParams = params
    }

    private fun sheetHeightPx(): Int {
        val dp = when (sheetMode) {
            SheetMode.PROBE -> 360f
            SheetMode.ADD_TRANSACTION -> 401f
        }
        return (dp * activity.resources.displayMetrics.density).toInt()
    }

    private fun sanitizeTransactionType(value: String?): String {
        return if (value == "income") "income" else "expense"
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
