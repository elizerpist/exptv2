package com.fluvi.app.lockscreen

import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import kotlin.math.min
import kotlin.math.roundToInt

/** Legacy compact-card contract retained for the existing physical-window
 * instrumentation test. New overlay placement uses [KeyguardOverlayGeometry]
 * below, whose coordinates are always screen left/top values. */
internal data class KeyguardCardGeometry(
    val width: Int,
    val height: Int,
    val y: Int,
)

internal fun resolveKeyguardCardGeometry(
    displayWidthPx: Int,
    density: Float,
    heightPx: Int,
    verticalOffsetDp: Int,
): KeyguardCardGeometry {
    fun dp(value: Int): Int = (value * density).roundToInt()
    val margin = dp(16)
    return KeyguardCardGeometry(
        width = min(dp(360), (displayWidthPx - margin * 2).coerceAtLeast(1)),
        height = heightPx,
        // Historical BOTTOM-gravity distance. It is converted exactly once
        // into a normalized card position when a real overlay is attached.
        y = dp(148 + verticalOffsetDp.coerceIn(-96, 96)),
    )
}

/** A single coordinate model for both forms. safeLeft/safeTop are inclusive,
 * safeRight/safeBottom exclusive, and left/top always describe the physical
 * screen coordinate passed to WindowManager with START|TOP gravity. */
internal data class KeyguardUsableBounds(
    val safeLeft: Int,
    val safeTop: Int,
    val safeRight: Int,
    val safeBottom: Int,
) {
    val width: Int get() = (safeRight - safeLeft).coerceAtLeast(1)
    val height: Int get() = (safeBottom - safeTop).coerceAtLeast(1)
}

internal data class KeyguardOverlayGeometry(
    val width: Int,
    val height: Int,
    val left: Int,
    val top: Int,
    val bounds: KeyguardUsableBounds,
    val cardPosition: KeyguardCardCardPosition,
    val orbPosition: KeyguardCardOrbPosition,
)

internal fun resolveKeyguardOverlayGeometry(
    bounds: KeyguardUsableBounds,
    density: Float,
    cardHeightPx: Int,
    presentationMode: KeyguardCardPresentationMode,
    cardPosition: KeyguardCardCardPosition?,
    orbPosition: KeyguardCardOrbPosition?,
    legacyVerticalOffsetDp: Int,
    orbSizePx: Int? = null,
): KeyguardOverlayGeometry {
    fun dp(value: Int): Int = (value * density).roundToInt()
    val cardWidth = min(dp(360), (bounds.width - dp(32)).coerceAtLeast(1))
    // The production caller supplies the dedicated 64dp dimen resource. The
    // fallback keeps this pure helper convenient for JVM geometry tests.
    val orbSize = (orbSizePx ?: dp(64)).coerceAtLeast(1)
    val cardTravelY = (bounds.height - cardHeightPx).coerceAtLeast(0)
    // Old placement used CENTER_HORIZONTAL|BOTTOM with y=148dp+offset.
    // Convert it in this one pure location; a caller can persist the returned
    // fraction once an attached overlay has supplied trustworthy insets.
    val migratedCard = cardPosition ?: KeyguardCardCardPosition(
        ((bounds.height - cardHeightPx - dp(148 + legacyVerticalOffsetDp.coerceIn(-96, 96))).toFloat() /
            cardTravelY.coerceAtLeast(1)).finiteFraction(),
    )
    val cardTop = bounds.safeTop + (migratedCard.yFraction * cardTravelY).roundToInt()
    val cardLeft = bounds.safeLeft + ((bounds.width - cardWidth) / 2)
    val orbTravelX = (bounds.width - orbSize).coerceAtLeast(0)
    val orbTravelY = (bounds.height - orbSize).coerceAtLeast(0)
    val defaultOrb = KeyguardCardOrbPosition(
        xFraction = .5f,
        yFraction = ((cardTop + cardHeightPx / 2 - orbSize / 2 - bounds.safeTop).toFloat() /
            orbTravelY.coerceAtLeast(1)).finiteFraction(),
    )
    val resolvedOrb = (orbPosition ?: defaultOrb).normalized()
    val cardMaxTop = (bounds.safeBottom - cardHeightPx).coerceAtLeast(bounds.safeTop)
    val orbMaxLeft = (bounds.safeRight - orbSize).coerceAtLeast(bounds.safeLeft)
    val orbMaxTop = (bounds.safeBottom - orbSize).coerceAtLeast(bounds.safeTop)
    return when (presentationMode) {
        KeyguardCardPresentationMode.CARD -> KeyguardOverlayGeometry(
            width = cardWidth,
            height = cardHeightPx,
            left = cardLeft,
            top = cardTop.coerceIn(bounds.safeTop, cardMaxTop),
            bounds = bounds,
            cardPosition = migratedCard.normalized(),
            orbPosition = resolvedOrb,
        )
        KeyguardCardPresentationMode.ORB -> KeyguardOverlayGeometry(
            width = orbSize,
            height = orbSize,
            left = (bounds.safeLeft + (resolvedOrb.xFraction * orbTravelX).roundToInt())
                .coerceIn(bounds.safeLeft, orbMaxLeft),
            top = (bounds.safeTop + (resolvedOrb.yFraction * orbTravelY).roundToInt())
                .coerceIn(bounds.safeTop, orbMaxTop),
            bounds = bounds,
            cardPosition = migratedCard.normalized(),
            orbPosition = resolvedOrb,
        )
    }
}

internal fun previewKeyguardOverlayGeometry(
    start: KeyguardOverlayGeometry,
    presentationMode: KeyguardCardPresentationMode,
    deltaRawX: Float,
    deltaRawY: Float,
): KeyguardOverlayGeometry {
    val maxLeft = (start.bounds.safeRight - start.width).coerceAtLeast(start.bounds.safeLeft)
    val maxTop = (start.bounds.safeBottom - start.height).coerceAtLeast(start.bounds.safeTop)
    val left = if (presentationMode == KeyguardCardPresentationMode.CARD) start.left else {
        (start.left + deltaRawX.roundToInt()).coerceIn(start.bounds.safeLeft, maxLeft)
    }
    val top = (start.top + deltaRawY.roundToInt()).coerceIn(start.bounds.safeTop, maxTop)
    val travelX = (start.bounds.width - start.width).coerceAtLeast(0)
    val travelY = (start.bounds.height - start.height).coerceAtLeast(0)
    val card = KeyguardCardCardPosition(
        ((top - start.bounds.safeTop).toFloat() / travelY.coerceAtLeast(1)).finiteFraction(),
    )
    val orb = KeyguardCardOrbPosition(
        ((left - start.bounds.safeLeft).toFloat() / travelX.coerceAtLeast(1)).finiteFraction(),
        ((top - start.bounds.safeTop).toFloat() / travelY.coerceAtLeast(1)).finiteFraction(),
    )
    return start.copy(left = left, top = top, cardPosition = card, orbPosition = orb)
}

internal fun keyguardCardWindowParameters(geometry: KeyguardCardGeometry): WindowManager.LayoutParams =
    WindowManager.LayoutParams(
        geometry.width,
        geometry.height,
        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
        y = geometry.y
        title = "FluviKeyguardCard"
    }

internal fun keyguardCardWindowParameters(geometry: KeyguardOverlayGeometry): WindowManager.LayoutParams =
    WindowManager.LayoutParams(
        geometry.width,
        geometry.height,
        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.START or Gravity.TOP
        x = geometry.left
        y = geometry.top
        title = "FluviKeyguardCard"
    }
