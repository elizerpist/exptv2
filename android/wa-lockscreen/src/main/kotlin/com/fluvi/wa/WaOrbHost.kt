package com.fluvi.wa

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.os.Bundle
import android.appwidget.AppWidgetManager

/** The single retained WA host. Its ID is part of the R49 migration contract. */
class WaOrbHost private constructor(context: Context) : AppWidgetHost(context, HOST_ID) {
    override fun onCreateView(context: Context, id: Int, info: AppWidgetProviderInfo): AppWidgetHostView =
        CompactOrbHostView(context)

    fun stopOrbListening() {
        try {
            stopListening()
        } finally {
            clearViews()
        }
    }

    private class CompactOrbHostView(context: Context) : AppWidgetHostView(context) {
        override fun setAppWidget(appWidgetId: Int, info: AppWidgetProviderInfo?) {
            super.setAppWidget(appWidgetId, info)
            // The artwork includes its own transparent corners. The host adds no inset.
            setPadding(0, 0, 0, 0)
        }
    }

    companion object {
        const val HOST_ID = 1003
        private var instance: WaOrbHost? = null

        fun get(context: Context): WaOrbHost =
            instance ?: WaOrbHost(context.applicationContext).also { instance = it }

        fun options(sizeDp: Int) = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, sizeDp)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, sizeDp)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, sizeDp)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, sizeDp)
            putInt(AppWidgetManager.OPTION_APPWIDGET_HOST_CATEGORY, AppWidgetProviderInfo.WIDGET_CATEGORY_KEYGUARD)
        }
    }
}
