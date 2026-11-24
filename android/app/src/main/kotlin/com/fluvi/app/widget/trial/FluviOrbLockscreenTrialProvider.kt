package com.fluvi.app.widget.trial

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.ComponentName
import android.os.Bundle
import android.widget.RemoteViews
import com.fluvi.app.R

/** Static, synthetic host trial; never reads financial data or starts a service. */
class FluviOrbLockscreenTrialProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { publish(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        publish(context, manager, appWidgetId)
    }

    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        onUpdate(context, AppWidgetManager.getInstance(context), newWidgetIds)
    }

    private fun publish(context: Context, manager: AppWidgetManager, id: Int) {
        // An exported provider can receive a forged broadcast; never replace
        // another Fluvi provider's widget even if a caller guesses its ID.
        val provider = ComponentName(context, FluviOrbLockscreenTrialProvider::class.java)
        if (!manager.getAppWidgetIds(provider).contains(id)) return
        val views = RemoteViews(context.packageName, R.layout.fluvi_orb_lockscreen_trial)
        views.setImageViewResource(R.id.fluvi_orb_lockscreen_trial_image, R.drawable.fluvi_orb_lockscreen_trial)
        manager.updateAppWidget(id, views)
    }
}
