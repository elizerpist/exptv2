package com.fluvi.app.lockscreen

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.View

/** Deliberately obvious, separately owned test APK window. It is never part
 * of the installed Human application or a production display decision. */
class KeyguardR14ControlledOccluderActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        setContentView(View(this).apply { setBackgroundColor(Color.rgb(20, 180, 74)) })
    }
}
