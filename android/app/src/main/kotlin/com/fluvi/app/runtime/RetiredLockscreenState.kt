package com.fluvi.app.runtime

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.util.Log
import com.fluvi.app.widget.orb.HeaderOrbBinding
import java.io.File

/** Runs in the application process, including a service-first or provider-first start. */
class FluviWidgetStartupProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        val application = requireNotNull(context)
        runCatching { RetiredLockscreenState.remove(application) }
            .onFailure { Log.w("FluviMigration", "Lockscreen cleanup will retry on next start") }
        // Establish the fixed host authority on Main before the frame queue
        // restores the last valid packet, including a service-first restart.
        runCatching { HeaderOrbBinding.get(application) }
            .onFailure { Log.w("FluviMigration", "Balance ORB initialization will retry") }
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?,
        selectionArgs: Array<out String>?): Int = 0
}

internal object RetiredLockscreenState {
    private val preferences = listOf(
        "fluvi_lock_screen_card",
        "fluvi_lock_screen_card_content",
        "fluvi_native_keyguard_card",
        "fluvi_native_keyguard_card_diagnostics",
        "fluvi_keyguard_header_material",
        "fluvi_keyguard_r448_display_route",
        "fluvi_keyguard_r448_comparison",
        "fluvi_keyguard_orb_diagnostic_route",
        "fluvi_r38_reference_admission",
        "fluvi_r444_flag_recovery",
        "fluvi_r29_reference_ownership",
        "fluvi_r46_recording",
    )
    private val unfinishedRecording = Regex("[0-9a-f-]{36}\\.(events|tmp)")

    fun remove(context: Context) {
        val completed = File(context.noBackupFilesDir, "fluvi-retired-lockscreen-v1")
        if (completed.isFile) return

        val oldCard = context.getSharedPreferences("fluvi_lock_screen_card", Context.MODE_PRIVATE)
        if (oldCard.all["enabled"] == true) {
            // The retired card shared notification 4052. Reconcile using the
            // independent FG/BG preferences before discarding the old flag.
            FluviRuntimeNotificationController.reconcileVisible(context, FluviRuntimeCoordinator.status(context))
        }
        preferences.forEach { name ->
            check(context.deleteSharedPreferences(name))
        }
        File(context.filesDir, "r46-recordings").listFiles().orEmpty()
            .filter { it.isFile && unfinishedRecording.matches(it.name) }
            .forEach { check(it.delete()) }
        check(completed.createNewFile() || completed.isFile)
    }
}
