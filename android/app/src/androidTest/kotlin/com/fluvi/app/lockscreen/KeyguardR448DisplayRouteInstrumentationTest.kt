package com.fluvi.app.lockscreen

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Real Android preferences; service reconnect and update-install are
 * separate end-to-end controls. */
@RunWith(AndroidJUnit4::class)
class KeyguardR448DisplayRouteInstrumentationTest {
    @Test fun selectionPersistsWithoutChangingExistingRenderMode() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val prefs = context.getSharedPreferences("fluvi_keyguard_r448_display_route", Context.MODE_PRIVATE)
        val oldPresent = prefs.contains("route")
        val old = prefs.getString("route", null)
        val oldRenderMode = KeyguardOrbRenderModeStore.read(context)
        try {
            assertTrue(prefs.edit().remove("route").commit())
            assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRouteStore.read(context))
            assertTrue(KeyguardR448DisplayRouteStore.write(context, KeyguardR448DisplayRoute.WIDGETS_ANYWHERE))
            assertEquals(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE, KeyguardR448DisplayRouteStore.read(context))
            assertEquals(oldRenderMode, KeyguardOrbRenderModeStore.read(context))
            assertTrue(KeyguardR448DisplayRouteStore.write(context, KeyguardR448DisplayRoute.FLUVI_STREAM))
            assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRouteStore.read(context))
        } finally {
            val edit = prefs.edit()
            if (oldPresent) edit.putString("route", old) else edit.remove("route")
            assertTrue(edit.commit())
        }
    }
}
