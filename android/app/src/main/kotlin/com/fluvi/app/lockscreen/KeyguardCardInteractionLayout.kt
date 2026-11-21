package com.fluvi.app.lockscreen

import android.content.Context
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.os.SystemClock
import android.view.View
import kotlin.math.min
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
        /** [restorePosition] is false for a terminal hide. In that case a
         * rollback updateViewLayout would delay removal for no user benefit. */
        fun onDragCancel(reason: String, restorePosition: Boolean)
        fun onInteractionFinished()
    }

    /** Root-local, nonfinancial paint owned by one attached isolated lease.
     * It is always underneath the normal children and never participates in
     * input, accessibility, display authority or buffer release. */
    internal data class PassiveStandbyObservation(
        val attachment: Long,
        val generation: Long,
        val firstDrawAtUptimeMs: Long?,
        val hasDrawn: Boolean,
    )

    private class PassiveStandby(
        val target: View,
        val attachment: Long,
        val generation: Long,
        val left: Int,
        val top: Int,
        val width: Int,
        val height: Int,
        val paint: Paint,
        val recordDraw: Boolean,
    ) {
        var hasDrawn = false
        var firstDrawAtUptimeMs: Long? = null
        fun observation() = PassiveStandbyObservation(attachment, generation, firstDrawAtUptimeMs, hasDrawn)
    }

    private var passiveStandby: PassiveStandby? = null
    // A previous parent submission can outlive the in-memory paint state.
    private var passiveBackingMayExist = false
    private var passiveStateEpoch = 0L

    /** Main-owned configuration. No material profile or scene is retained. */
    internal fun configurePassiveStandby(target: View, attachment: Long, generation: Long,
                                        width: Int, height: Int, recordDraw: Boolean): String {
        if (!isAttachedToWindow || !isShown || target.parent !== this || !target.isAttachedToWindow ||
            attachment <= 0L || generation <= 0L) return "OWNER_UNAVAILABLE"
        if (width <= 4 || height <= 4 || target.width != width || target.height != height ||
            this.width <= 0 || this.height <= 0) return "LAYOUT_PENDING"
        if (!validPassiveGeometry(target, target.left, target.top, width, height)) return "GEOMETRY_INELIGIBLE"
        val rootLocation = IntArray(2)
        val targetLocation = IntArray(2)
        getLocationInSurface(rootLocation)
        target.getLocationInSurface(targetLocation)
        if (targetLocation[0] != rootLocation[0] + target.left ||
            targetLocation[1] != rootLocation[1] + target.top) return "SURFACE_MISMATCH"
        val old = passiveStandby
        if (old != null && old.target === target && old.attachment == attachment && old.generation == generation &&
            old.left == target.left && old.top == target.top && old.width == width && old.height == height &&
            old.recordDraw == recordDraw) return "ELIGIBLE"
        val colors = intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt())
        val stops = floatArrayOf(0f, .5f, 1f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(target.left.toFloat(), (target.top + height).toFloat(),
                (target.left + width).toFloat(), target.top.toFloat(), colors, stops, Shader.TileMode.CLAMP)
            alpha = 255
        }
        passiveStateEpoch += 1L
        passiveStandby = PassiveStandby(target, attachment, generation, target.left, target.top,
            width, height, paint, recordDraw)
        invalidate()
        return "ELIGIBLE"
    }

    internal fun passiveStandbyObservation(): PassiveStandbyObservation? = passiveStandby?.observation()
    internal fun passiveBackingMayExist(): Boolean = passiveBackingMayExist
    internal fun passiveStateEpoch(): Long = passiveStateEpoch
    internal fun confirmPassiveBackingCleared(epoch: Long) {
        if (passiveStandby == null && passiveStateEpoch == epoch) passiveBackingMayExist = false
    }

    /** The last submitted parent buffer remains intact until the next real
     * root traversal; clearing this state never delays child revocation. */
    internal fun clearPassiveStandby(recordObservation: Boolean = false): PassiveStandbyObservation? {
        val old = passiveStandby ?: return null
        passiveStandby = null
        passiveStateEpoch += 1L
        invalidate()
        return if (recordObservation) old.observation() else null
    }

    private fun validPassiveGeometry(target: View, left: Int, top: Int, width: Int, height: Int): Boolean =
        target.parent === this && target.visibility != View.GONE && target.width == width && target.height == height &&
            target.left == left && target.top == top && left >= 0 && top >= 0 &&
            left + width <= this.width && top + height <= this.height &&
            alpha == 1f && target.alpha == 1f && matrix.isIdentity && target.matrix.isIdentity &&
            translationX == 0f && translationY == 0f && target.translationX == 0f && target.translationY == 0f &&
            passiveAncestorsUntransformed()

    private fun passiveAncestorsUntransformed(): Boolean {
        var ancestor = parent
        while (ancestor is View) {
            if (ancestor.alpha != 1f || !ancestor.matrix.isIdentity ||
                ancestor.translationX != 0f || ancestor.translationY != 0f) return false
            ancestor = ancestor.parent
        }
        return true
    }

    override fun dispatchDraw(canvas: Canvas) {
        val state = passiveStandby
        if (state != null) {
            if (isAttachedToWindow && isShown && state.target.isAttachedToWindow &&
                validPassiveGeometry(state.target, state.left, state.top, state.width, state.height)) {
                canvas.drawCircle(state.left + state.width / 2f, state.top + state.height / 2f,
                    (min(state.width, state.height) / 2f - 2f).coerceAtLeast(0f), state.paint)
                state.hasDrawn = true
                passiveBackingMayExist = true
                if (state.recordDraw && state.firstDrawAtUptimeMs == null) {
                    state.firstDrawAtUptimeMs = SystemClock.uptimeMillis()
                }
            } else {
                // A new owner/layout must explicitly qualify a fresh paint.
                passiveStandby = null
                passiveStateEpoch += 1L
            }
        }
        super.dispatchDraw(canvas)
    }

    override fun onDetachedFromWindow() {
        passiveStandby = null
        passiveBackingMayExist = false
        passiveStateEpoch += 1L
        super.onDetachedFromWindow()
    }

    var listener: Listener? = null
    val isDragging: Boolean get() = machine.state == KeyguardCardGestureState.DRAGGING
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
                    listener?.onDragCancel("multiPointer", restorePosition = true)
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
                        listener?.onDragCancel("slopBeforeLongPress", restorePosition = true)
                        // Keep the root visible; consume the rest so neither
                        // the root nor a child can click on a later UP.
                        return true
                    }
                    KeyguardCardGestureResult.CANCEL -> {
                        cancelPendingLongPress()
                        dispatchChildCancel()
                        listener?.onDragCancel("pointerChanged", restorePosition = true)
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
                        listener?.onDragCancel("upAfterCancelled", restorePosition = true)
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
                    listener?.onDragCancel("systemCancel", restorePosition = true)
                    listener?.onInteractionFinished()
                }
                return true
            }
        }
        return super.dispatchTouchEvent(event)
    }

    fun cancelInteraction(reason: String, restorePosition: Boolean = true) {
        cancelPendingLongPress()
        if (machine.cancel() != KeyguardCardGestureResult.NONE) {
            dispatchChildCancel()
            listener?.onDragCancel(reason, restorePosition)
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
