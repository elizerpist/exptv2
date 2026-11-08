package com.fluvi.app.lockscreen

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.FrameLayout

/** Small Android-free gesture state machine. It deliberately knows nothing
 * about WindowManager, settings or financial content, so a drag cannot
 * accidentally restart any of those lanes. */
internal enum class KeyguardCardGestureState { IDLE, PRESS_PENDING, DRAGGING, CANCELLED_UNTIL_UP }

internal enum class KeyguardCardGestureResult { NONE, START_DRAG, CANCEL_CHILDREN, CLICK, COMMIT, CANCEL }

internal class KeyguardCardGestureStateMachine(private val touchSlop: Float) {
    var state: KeyguardCardGestureState = KeyguardCardGestureState.IDLE
        private set
    private var pointerId = MotionEvent.INVALID_POINTER_ID
    private var startRawX = 0f
    private var startRawY = 0f

    fun down(id: Int, rawX: Float, rawY: Float): KeyguardCardGestureResult {
        pointerId = id
        startRawX = rawX
        startRawY = rawY
        state = KeyguardCardGestureState.PRESS_PENDING
        return KeyguardCardGestureResult.NONE
    }

    fun longPress(): KeyguardCardGestureResult = if (state == KeyguardCardGestureState.PRESS_PENDING) {
        state = KeyguardCardGestureState.DRAGGING
        KeyguardCardGestureResult.START_DRAG
    } else KeyguardCardGestureResult.NONE

    fun move(id: Int, rawX: Float, rawY: Float): KeyguardCardGestureResult {
        if (id != pointerId) return cancel()
        if (state != KeyguardCardGestureState.PRESS_PENDING) return KeyguardCardGestureResult.NONE
        val dx = rawX - startRawX
        val dy = rawY - startRawY
        return if (dx * dx + dy * dy > touchSlop * touchSlop) {
            state = KeyguardCardGestureState.CANCELLED_UNTIL_UP
            KeyguardCardGestureResult.CANCEL_CHILDREN
        } else KeyguardCardGestureResult.NONE
    }

    fun up(id: Int): KeyguardCardGestureResult {
        if (id != pointerId) return cancel()
        val result = when (state) {
            KeyguardCardGestureState.PRESS_PENDING -> KeyguardCardGestureResult.CLICK
            KeyguardCardGestureState.DRAGGING -> KeyguardCardGestureResult.COMMIT
            KeyguardCardGestureState.CANCELLED_UNTIL_UP -> KeyguardCardGestureResult.CANCEL
            KeyguardCardGestureState.IDLE -> KeyguardCardGestureResult.NONE
        }
        reset()
        return result
    }

    fun cancel(): KeyguardCardGestureResult {
        val hadGesture = state != KeyguardCardGestureState.IDLE
        reset()
        return if (hadGesture) KeyguardCardGestureResult.CANCEL else KeyguardCardGestureResult.NONE
    }

    fun startRawX(): Float = startRawX
    fun startRawY(): Float = startRawY

    private fun reset() {
        state = KeyguardCardGestureState.IDLE
        pointerId = MotionEvent.INVALID_POINTER_ID
    }
}

/** Observes the root stream before children. Before long press it preserves
 * normal child/root click dispatch. After long press it sends one CANCEL down
 * the normal child path and owns the remaining stream, suppressing every
 * possible delayed click. */
internal class KeyguardCardInteractionLayout(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {
    interface Listener {
        fun onPointerDown()
        fun onLongPress()
        fun onDrag(deltaRawX: Float, deltaRawY: Float)
        fun onDragEnd()
        fun onDragCancel(reason: String)
        fun onInteractionFinished()
    }

    var listener: Listener? = null
    private val handler = Handler(Looper.getMainLooper())
    private val machine = KeyguardCardGestureStateMachine(ViewConfiguration.get(context).scaledTouchSlop.toFloat())
    private val longPressTimeout = ViewConfiguration.getLongPressTimeout().toLong()
    private var lastLocalX = 0f
    private var lastLocalY = 0f
    private var longPressPosted = false
    private val longPress = Runnable {
        longPressPosted = false
        if (machine.longPress() != KeyguardCardGestureResult.START_DRAG) return@Runnable
        dispatchChildCancel()
        performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        listener?.onLongPress()
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        lastLocalX = event.x
        lastLocalY = event.y
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                machine.down(event.getPointerId(0), event.rawX, event.rawY)
                listener?.onPointerDown()
                postLongPress()
                return super.dispatchTouchEvent(event)
            }
            MotionEvent.ACTION_POINTER_DOWN -> {
                cancelPendingLongPress()
                if (machine.cancel() != KeyguardCardGestureResult.NONE) {
                    dispatchChildCancel()
                    listener?.onDragCancel("multiPointer")
                    listener?.onInteractionFinished()
                }
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (machine.state == KeyguardCardGestureState.DRAGGING) {
                    listener?.onDrag(event.rawX - machine.startRawX(), event.rawY - machine.startRawY())
                    return true
                }
                when (machine.move(event.getPointerId(0), event.rawX, event.rawY)) {
                    KeyguardCardGestureResult.CANCEL_CHILDREN -> {
                        cancelPendingLongPress()
                        dispatchChildCancel()
                        listener?.onDragCancel("slopBeforeLongPress")
                        // Keep the root visible; consume the rest so neither
                        // the root nor a child can click on a later UP.
                        return true
                    }
                    KeyguardCardGestureResult.CANCEL -> {
                        cancelPendingLongPress()
                        dispatchChildCancel()
                        listener?.onDragCancel("pointerChanged")
                        listener?.onInteractionFinished()
                        return true
                    }
                    else -> return if (machine.state == KeyguardCardGestureState.CANCELLED_UNTIL_UP) true else super.dispatchTouchEvent(event)
                }
            }
            MotionEvent.ACTION_UP -> {
                cancelPendingLongPress()
                return when (machine.up(event.getPointerId(0))) {
                    KeyguardCardGestureResult.CLICK -> {
                        val handled = super.dispatchTouchEvent(event)
                        listener?.onInteractionFinished()
                        handled
                    }
                    KeyguardCardGestureResult.COMMIT -> {
                        listener?.onDragEnd()
                        listener?.onInteractionFinished()
                        true
                    }
                    KeyguardCardGestureResult.CANCEL -> {
                        listener?.onDragCancel("upAfterCancelled")
                        listener?.onInteractionFinished()
                        true
                    }
                    else -> true
                }
            }
            MotionEvent.ACTION_CANCEL -> {
                cancelPendingLongPress()
                if (machine.cancel() != KeyguardCardGestureResult.NONE) {
                    dispatchChildCancel()
                    listener?.onDragCancel("systemCancel")
                    listener?.onInteractionFinished()
                }
                return true
            }
        }
        return super.dispatchTouchEvent(event)
    }

    fun cancelInteraction(reason: String) {
        cancelPendingLongPress()
        if (machine.cancel() != KeyguardCardGestureResult.NONE) {
            dispatchChildCancel()
            listener?.onDragCancel(reason)
            listener?.onInteractionFinished()
        }
    }

    private fun postLongPress() {
        cancelPendingLongPress()
        handler.postDelayed(longPress, longPressTimeout)
        longPressPosted = true
    }

    private fun cancelPendingLongPress() {
        if (longPressPosted) handler.removeCallbacks(longPress)
        longPressPosted = false
    }

    private fun dispatchChildCancel() {
        val cancel = MotionEvent.obtain(
            System.currentTimeMillis(),
            System.currentTimeMillis(),
            MotionEvent.ACTION_CANCEL,
            lastLocalX,
            lastLocalY,
            0,
        )
        try {
            super.dispatchTouchEvent(cancel)
        } finally {
            cancel.recycle()
        }
    }
}
