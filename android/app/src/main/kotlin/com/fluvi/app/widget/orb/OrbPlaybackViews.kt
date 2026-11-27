package com.fluvi.app.widget.orb

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import com.fluvi.app.R

/** Complete local playback shared by both ordinary AppWidget providers. */
internal fun orbPlaybackViews(
    context: Context,
    plan: OrbFramePlan,
    frames: List<Bitmap>,
    displaySizePx: Int,
): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.fluvi_orb_widget)
    val flipper = R.id.fluvi_orb_frame_flipper
    views.removeAllViews(flipper)
    views.setInt(flipper, "setFlipInterval", plan.intervalMs)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val size = displaySizePx.toFloat()
        val circle = R.id.fluvi_orb_circle_container
        views.setViewLayoutWidth(circle, size, TypedValue.COMPLEX_UNIT_PX)
        views.setViewLayoutHeight(circle, size, TypedValue.COMPLEX_UNIT_PX)
        views.setViewOutlinePreferredRadius(circle, size / 2, TypedValue.COMPLEX_UNIT_PX)
    }
    for (frame in frames) {
        val child = RemoteViews(context.packageName, R.layout.fluvi_orb_widget_frame)
        child.setImageViewBitmap(R.id.fluvi_orb_frame_image, frame)
        views.addView(flipper, child)
    }
    views.setInt(flipper, "setDisplayedChild", plan.initialFrameIndex())
    return views
}
