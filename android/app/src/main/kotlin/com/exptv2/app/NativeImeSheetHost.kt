package com.exptv2.app

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.VelocityTracker
import android.view.ViewConfiguration
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

    private interface DragCallbacks {
        fun onDragStart()
        fun onDragMove(offsetPx: Float)
        fun onDragEnd(offsetPx: Float, velocityYPxPerSecond: Float)
        fun onDragCancel()
    }

    private var mainChannel: MethodChannel? = null
    private var overlay: FrameLayout? = null
    private var backdropView: View? = null
    private var sheetContainer: FrameLayout? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var sheetChannel: MethodChannel? = null
    private var sheetMode = SheetMode.PROBE
    private var activeTransactionType = "expense"
    private var previousSoftInputMode: Int? = null
    private var frameSeq = 0L
    private var lastLoggedImePx = Int.MIN_VALUE
    private var contentReady = false
    private var pendingReveal = false
    private var sheetVisible = false
    private var dragOffsetPx = 0f
    private val closeState = NativeImeSheetCloseStateMachine()

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
        val stateChanged = sheetMode != mode || activeTransactionType != transactionType
        val hadContent = flutterView != null
        sheetMode = mode
        activeTransactionType = transactionType
        val root = ensureOverlay()
        updateSheetHeight()
        prepareHiddenHost("open_prepare")
        if (stateChanged && hadContent) {
            contentReady = false
            sendSheetStateChanged()
        }
        ensureFlutterContent()
        pendingReveal = true
        frameSeq = 0L
        lastLoggedImePx = Int.MIN_VALUE
        root.bringToFront()
        ViewCompat.requestApplyInsets(root)
        publish(logMessage)
        if (contentReady) {
            revealSheet("content_ready_cached")
        } else {
            publish(
                "[NativeImeSheet] open delayed reason=content_not_ready " +
                    "mode=${sheetMode.channelValue} type=$activeTransactionType",
            )
        }
    }

    fun closeProbe() {
        closeSheet("[NativeImeSheet] probe close")
    }

    fun closeSheet() {
        closeSheet("[NativeImeSheet] sheet close")
    }

    private fun closeSheet(logMessage: String) {
        val imeBottomPx = currentImeBottomPx()
        val shouldNotifyMain =
            sheetMode == SheetMode.ADD_TRANSACTION && sheetVisible
        val action = closeState.requestClose(
            visible = sheetVisible,
            imeBottomPx = imeBottomPx,
            notifyMain = shouldNotifyMain,
        )
        publish(
            "$logMessage requested ime=$imeBottomPx phase=${closeState.phase} " +
                "notify=$shouldNotifyMain token=${action.token}",
        )
        if (action.hideKeyboard) {
            clearSheetFocus()
            hideKeyboard()
        }
        if (action.scheduleTimeout) {
            publish(
                "[NativeImeSheet] close waiting for ime hide " +
                    "ime=$imeBottomPx token=${action.token}",
            )
            scheduleCloseTimeout(action.token)
        }
        applyCloseAction(action)
    }

    fun dispose() {
        closeState.forceClosed()
        finishClose(reason = "dispose", notifyMain = false)
        destroyFlutterContent()
        val root = overlay
        if (root?.parent is ViewGroup) {
            (root.parent as ViewGroup).removeView(root)
        }
        overlay = null
        backdropView = null
        sheetContainer = null
    }

    private fun ensureOverlay(): FrameLayout {
        val existing = overlay
        if (existing != null) return existing

        val root = FrameLayout(activity).apply {
            visibility = View.VISIBLE
            alpha = 0f
            isClickable = false
            fitsSystemWindows = false
        }
        val backdrop = View(activity).apply {
            setBackgroundColor(Color.argb(82, 15, 23, 42))
            isClickable = false
            setOnClickListener { closeSheet() }
        }
        val sheet = DraggableSheetFrameLayout(
            activity,
            dragHandleHeightPx = dragHandleHeightPx(),
            callbacks = object : DragCallbacks {
                override fun onDragStart() = handleDragStart()
                override fun onDragMove(offsetPx: Float) = handleDragMove(offsetPx)
                override fun onDragEnd(
                    offsetPx: Float,
                    velocityYPxPerSecond: Float,
                ) = handleDragEnd(offsetPx, velocityYPxPerSecond)

                override fun onDragCancel() = handleDragCancel()
            },
        ).apply {
            isClickable = true
            isFocusable = false
            setBackgroundColor(Color.WHITE)
            translationY = sheetHeightPx().toFloat()
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
        ViewCompat.setOnApplyWindowInsetsListener(root) { _, insets ->
            val imeBottomPx = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
            if (shouldApplyImeMotion()) applySheetTranslation(imeBottomPx)
            applyCloseAction(closeState.onImeProgress(imeBottomPx))
            insets
        }
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
                    val translation = if (shouldApplyImeMotion()) {
                        applySheetTranslation(imeBottomPx)
                    } else {
                        sheet.translationY
                    }
                    logProgress(imeBottomPx, translation)
                    applyCloseAction(closeState.onImeProgress(imeBottomPx))
                    return insets
                }

                override fun onEnd(animation: WindowInsetsAnimationCompat) {
                    if (animation.typeMask and WindowInsetsCompat.Type.ime() != 0) {
                        val imeBottomPx = currentImeBottomPx()
                        val translation = if (shouldApplyImeMotion()) {
                            applySheetTranslation(imeBottomPx)
                        } else {
                            sheet.translationY
                        }
                        publish(
                            "[NativeImeSheet] ime end ime=$imeBottomPx translation=$translation",
                        )
                        applyCloseAction(closeState.onImeEnd(imeBottomPx))
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
        backdropView = backdrop
        sheetContainer = sheet
        publish("[NativeImeSheet] overlay created")
        return root
    }

    private fun ensureFlutterContent() {
        val sheet = sheetContainer ?: return
        if (flutterView != null) {
            publish(
                "[NativeImeSheet] FlutterView reused " +
                    "mode=${sheetMode.channelValue} type=$activeTransactionType ready=$contentReady",
            )
            return
        }
        contentReady = false
        val engine = ensureFlutterEngine()
        val view = FlutterView(activity, FlutterTextureView(activity)).apply {
            attachToFlutterEngine(engine)
        }
        publish("[NativeImeSheet] FlutterView attached")
        sheet.addView(
            view,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        flutterView = view
    }

    private fun handleDragStart() {
        if (!sheetVisible) return
        publish(
            "[NativeImeSheet] drag start ime=${currentImeBottomPx()} " +
                "mode=${sheetMode.channelValue}",
        )
        if (currentImeBottomPx() > 0) {
            clearSheetFocus()
            hideKeyboard()
            publish("[NativeImeSheet] drag requested ime hide")
        }
    }

    private fun handleDragMove(offsetPx: Float) {
        if (!sheetVisible) return
        dragOffsetPx = NativeImeSheetDragModel.clampOffset(
            offsetPx,
            sheetHeightPx().toFloat(),
        )
        val translation = applySheetTranslation(currentImeBottomPx())
        publish(
            "[NativeImeSheet] drag move offset=${dragOffsetPx.toInt()} " +
                "translation=$translation",
        )
    }

    private fun handleDragEnd(offsetPx: Float, velocityYPxPerSecond: Float) {
        if (!sheetVisible) return
        dragOffsetPx = NativeImeSheetDragModel.clampOffset(
            offsetPx,
            sheetHeightPx().toFloat(),
        )
        val thresholdPx = dismissThresholdPx()
        val dismiss = NativeImeSheetDragModel.shouldDismiss(
            offsetPx = dragOffsetPx,
            velocityYPxPerSecond = velocityYPxPerSecond,
            thresholdPx = thresholdPx,
            velocityThresholdPxPerSecond = dismissVelocityThresholdPx(),
        )
        publish(
            "[NativeImeSheet] drag end offset=${dragOffsetPx.toInt()} " +
                "velocity=${velocityYPxPerSecond.toInt()} threshold=${thresholdPx.toInt()} " +
                "decision=${if (dismiss) "dismiss" else "snap"}",
        )
        if (dismiss) {
            closeSheet("[NativeImeSheet] drag dismiss")
            return
        }
        dragOffsetPx = 0f
        applySheetTranslation(currentImeBottomPx())
    }

    private fun handleDragCancel() {
        if (!sheetVisible) return
        publish("[NativeImeSheet] drag cancel offset=${dragOffsetPx.toInt()}")
        dragOffsetPx = 0f
        applySheetTranslation(currentImeBottomPx())
    }

    private fun ensureFlutterEngine(): FlutterEngine {
        val existing = flutterEngine
        if (existing != null) {
            publish("[NativeImeSheet] FlutterEngine reused mode=${sheetMode.channelValue}")
            return existing
        }
        publish("[NativeImeSheet] FlutterEngine create start mode=${sheetMode.channelValue}")
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
        publish("[NativeImeSheet] Dart entrypoint started nativeImeSheetMain")
        return engine
    }

    private fun attachSheetChannel(engine: FlutterEngine) {
        sheetChannel = MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getInitialState" -> {
                            publish(
                                "[NativeImeSheet] getInitialState " +
                                    "mode=${sheetMode.channelValue} type=$activeTransactionType",
                            )
                            result.success(
                                mapOf(
                                    "mode" to sheetMode.channelValue,
                                    "type" to activeTransactionType,
                                ),
                            )
                        }
                        "contentReady" -> {
                            result.success(null)
                            handleContentReady()
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
    }

    private fun destroyFlutterContent() {
        flutterView?.detachFromFlutterEngine()
        flutterView = null
        sheetContainer?.removeAllViews()
        flutterEngine?.destroy()
        flutterEngine = null
        sheetChannel = null
        contentReady = false
    }

    private fun handleContentReady() {
        contentReady = true
        publish(
            "[NativeImeSheet] content ready " +
                "mode=${sheetMode.channelValue} type=$activeTransactionType pending=$pendingReveal",
        )
        if (pendingReveal) revealSheet("content_ready")
    }

    private fun sendSheetStateChanged() {
        val payload = mapOf(
            "mode" to sheetMode.channelValue,
            "type" to activeTransactionType,
        )
        publish(
            "[NativeImeSheet] sheet state changed dispatch " +
                "mode=${sheetMode.channelValue} type=$activeTransactionType",
        )
        sheetChannel?.invokeMethod("sheetStateChanged", payload)
    }

    private fun revealSheet(reason: String) {
        val root = overlay ?: return
        if (previousSoftInputMode == null) {
            previousSoftInputMode = activity.window.attributes.softInputMode
        }
        activity.window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
        closeState.markOpened()
        pendingReveal = false
        sheetVisible = true
        dragOffsetPx = 0f
        root.visibility = View.VISIBLE
        root.alpha = 1f
        root.isClickable = false
        backdropView?.isClickable = true
        root.bringToFront()
        val translation = applySheetTranslation(currentImeBottomPx())
        publish(
            "[NativeImeSheet] sheet revealed reason=$reason " +
                "translation=$translation mode=${sheetMode.channelValue} type=$activeTransactionType",
        )
    }

    private fun prepareHiddenHost(reason: String) {
        val root = overlay ?: return
        val sheet = sheetContainer ?: return
        sheetVisible = false
        dragOffsetPx = 0f
        root.visibility = View.VISIBLE
        root.alpha = 0f
        root.isClickable = false
        backdropView?.isClickable = false
        sheet.translationY = sheetHeightPx().toFloat()
        publish("[NativeImeSheet] host hidden reason=$reason")
    }

    private fun shouldApplyImeMotion(): Boolean {
        return sheetVisible || closeState.phase == NativeImeSheetCloseStateMachine.Phase.CLOSING
    }

    private fun applySheetTranslation(imeBottomPx: Int): Float {
        val translation = NativeImeSheetDragModel.translationY(imeBottomPx, dragOffsetPx)
        sheetContainer?.translationY = translation
        return translation
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

    private fun scheduleCloseTimeout(token: Long) {
        activity.window.decorView.postDelayed(
            {
                val action = closeState.onTimeout(token)
                if (action.finish) {
                    publish(
                        "[NativeImeSheet] close timeout fired token=$token " +
                            "ime=${currentImeBottomPx()}",
                    )
                }
                applyCloseAction(action)
            },
            closeTimeoutMs,
        )
    }

    private fun applyCloseAction(action: NativeImeSheetCloseStateMachine.Action) {
        if (!action.finish) return
        finishClose(reason = action.reason, notifyMain = action.notifyMain)
    }

    private fun finishClose(reason: String, notifyMain: Boolean) {
        val imeBottomPx = currentImeBottomPx()
        pendingReveal = false
        prepareHiddenHost(reason)
        restoreSoftInputMode()
        publish(
            "[NativeImeSheet] close complete reason=$reason ime=$imeBottomPx " +
                "notify=$notifyMain cached=${flutterEngine != null}",
        )
        if (notifyMain) {
            mainChannel?.invokeMethod(
                "sheetClosed",
                mapOf("mode" to sheetMode.channelValue, "type" to activeTransactionType),
            )
        }
    }

    private fun restoreSoftInputMode() {
        val previous = previousSoftInputMode ?: return
        activity.window.setSoftInputMode(previous)
        previousSoftInputMode = null
    }

    private fun clearSheetFocus() {
        flutterView?.clearFocus()
        sheetContainer?.clearFocus()
        overlay?.clearFocus()
        activity.currentFocus?.clearFocus()
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

    private fun dragHandleHeightPx(): Float {
        return 72f * activity.resources.displayMetrics.density
    }

    private fun dismissThresholdPx(): Float {
        return 90f * activity.resources.displayMetrics.density
    }

    private fun dismissVelocityThresholdPx(): Float {
        return 1200f * activity.resources.displayMetrics.density
    }

    private fun publish(message: String) {
        Log.d(logTag, message)
        EventBroadcaster.publishDebugLog(message)
        mainChannel?.invokeMethod("debugLog", mapOf("message" to message))
    }

    private class DraggableSheetFrameLayout(
        context: Context,
        private val dragHandleHeightPx: Float,
        private val callbacks: DragCallbacks,
    ) : FrameLayout(context) {
        private var dragging = false
        private var startRawY = 0f
        private var velocityTracker: VelocityTracker? = null
        private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop

        override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startRawY = event.rawY
                    dragging = event.y <= dragHandleHeightPx
                    if (dragging) {
                        velocityTracker = VelocityTracker.obtain().also {
                            it.addMovement(event)
                        }
                        callbacks.onDragStart()
                    }
                    return dragging
                }
                MotionEvent.ACTION_MOVE -> {
                    if (!dragging) return false
                    velocityTracker?.addMovement(event)
                    return kotlin.math.abs(event.rawY - startRawY) >= touchSlop
                }
                MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_UP -> {
                    val wasDragging = dragging
                    if (event.actionMasked == MotionEvent.ACTION_CANCEL && wasDragging) {
                        callbacks.onDragCancel()
                    }
                    recycleTracker()
                    dragging = false
                    return wasDragging
                }
            }
            return false
        }

        override fun onTouchEvent(event: MotionEvent): Boolean {
            if (!dragging) return super.onTouchEvent(event)
            velocityTracker?.addMovement(event)
            when (event.actionMasked) {
                MotionEvent.ACTION_MOVE -> {
                    callbacks.onDragMove((event.rawY - startRawY).coerceAtLeast(0f))
                }
                MotionEvent.ACTION_UP -> {
                    velocityTracker?.computeCurrentVelocity(1000)
                    callbacks.onDragEnd(
                        (event.rawY - startRawY).coerceAtLeast(0f),
                        velocityTracker?.yVelocity ?: 0f,
                    )
                    recycleTracker()
                    dragging = false
                }
                MotionEvent.ACTION_CANCEL -> {
                    callbacks.onDragCancel()
                    recycleTracker()
                    dragging = false
                }
            }
            return true
        }

        private fun recycleTracker() {
            velocityTracker?.recycle()
            velocityTracker = null
        }
    }

    private companion object {
        const val channelName = "exptv2/native_ime_sheet"
        const val logTag = "NativeImeSheet"
        const val closeTimeoutMs = 700L
    }
}
