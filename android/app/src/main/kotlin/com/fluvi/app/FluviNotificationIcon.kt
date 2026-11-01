package com.fluvi.app

import android.content.Context
import androidx.annotation.DrawableRes
import com.fluvi.app.runtime.FluviRuntimeNotificationController

/**
 * The Android small-icon choice is intentionally native and durable: local
 * notifications may be posted while Flutter and every Activity are absent.
 * Persisting a stable name instead of an Android resource id also keeps the
 * choice valid across resource recompilation.
 */
internal enum class FluviNotificationSmallIconStyle(val persistedValue: String) {
    outline("outline"),
    filled("filled");

    companion object {
        fun fromPersisted(value: String?): FluviNotificationSmallIconStyle =
            entries.firstOrNull { it.persistedValue == value } ?: outline
    }
}

internal object FluviNotificationIconResolver {
    private const val PREFERENCES = "fluvi_notification_appearance"
    private const val SMALL_ICON_STYLE = "notificationSmallIconStyle"

    fun style(context: Context): FluviNotificationSmallIconStyle =
        FluviNotificationSmallIconStyle.fromPersisted(
            context.applicationContext
                .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .getString(SMALL_ICON_STYLE, null),
        )

    fun setStyle(
        context: Context,
        style: FluviNotificationSmallIconStyle,
    ): FluviNotificationSmallIconStyle {
        context.applicationContext
            .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(SMALL_ICON_STYLE, style.persistedValue)
            .apply()

        // Only update notifications that are still visible. This deliberately
        // does not post a test notification, revive a dismissed status card,
        // restart the service, or create a second listener/probe event.
        FluviRuntimeNotificationController.refreshVisibleIcon(context)
        FluviAutomationPlatform.refreshVisibleTestNotificationIcon(context)
        return style(context)
    }

    @DrawableRes
    fun smallIconRes(context: Context): Int = smallIconRes(style(context))

    @DrawableRes
    internal fun smallIconRes(style: FluviNotificationSmallIconStyle): Int = when (style) {
        FluviNotificationSmallIconStyle.outline -> R.drawable.ic_stat_fluvi
        FluviNotificationSmallIconStyle.filled -> R.drawable.ic_stat_fluvi_filled
    }
}
