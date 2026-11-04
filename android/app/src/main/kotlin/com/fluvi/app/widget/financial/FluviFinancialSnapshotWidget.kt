package com.fluvi.app.widget.financial

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.fluvi.app.MainActivity
import com.fluvi.app.R
import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import com.fluvi.app.runtime.FluviLockScreenCardContent
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.app.runtime.FluviFinancialCardPresentation
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.lockscreen.FluviKeyguardCardServiceRegistry
import com.fluvi.core.FluviCoreFactory
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * This is deliberately a real AppWidget boundary.  It never posts a
 * notification, requests POST_NOTIFICATIONS, or starts a service: a selected
 * AppWidget host owns placement and lifecycle, including a lock-screen host.
 */
internal data class FluviFinancialSnapshotWidgetConfiguration(
    val mode: FluviLockScreenCardConfiguration.Mode = FluviLockScreenCardConfiguration.Mode.budget,
    val timeAxis: FluviLockScreenCardConfiguration.TimeAxis = FluviLockScreenCardConfiguration.TimeAxis.month,
    val direction: FluviLockScreenCardConfiguration.Direction = FluviLockScreenCardConfiguration.Direction.expense,
    val categoryId: String? = null,
    val eventLine: FluviLockScreenCardConfiguration.EventLine = FluviLockScreenCardConfiguration.EventLine.related,
    // A widget host receives all rendered RemoteViews fields.  Never inherit
    // notification privacy here: new widget configuration is always discreet.
    val privacy: FluviLockScreenCardConfiguration.Privacy = FluviLockScreenCardConfiguration.Privacy.discreet,
    val generation: Long = 0L,
) {
    val isValid: Boolean get() = mode != FluviLockScreenCardConfiguration.Mode.budget || !categoryId.isNullOrBlank()

    fun asFinancialFocus() = FluviLockScreenCardConfiguration(
        enabled = true,
        mode = mode,
        timeAxis = timeAxis,
        direction = direction,
        categoryId = categoryId,
        eventLine = eventLine,
        privacy = privacy,
        generation = generation,
    )
}

internal class FluviFinancialSnapshotWidgetStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_financial_snapshot_widget",
        Context.MODE_PRIVATE,
    )

    fun read(): FluviFinancialSnapshotWidgetConfiguration = runCatching {
        FluviFinancialSnapshotWidgetConfiguration(
            mode = enum("mode", FluviLockScreenCardConfiguration.Mode.budget),
            timeAxis = enum("axis", FluviLockScreenCardConfiguration.TimeAxis.month),
            direction = enum("direction", FluviLockScreenCardConfiguration.Direction.expense),
            categoryId = preferences.getString("categoryId", null),
            eventLine = enum("eventLine", FluviLockScreenCardConfiguration.EventLine.related),
            privacy = enum("privacy", FluviLockScreenCardConfiguration.Privacy.discreet),
            generation = preferences.getLong("generation", 0L),
        )
    }.getOrDefault(FluviFinancialSnapshotWidgetConfiguration())

    fun saveFromMap(values: Map<*, *>): FluviFinancialSnapshotWidgetConfiguration {
        val previous = read()
        fun text(name: String, fallback: String) = (values[name] as? String) ?: fallback
        val next = previous.copy(
            mode = enumValue(text("mode", previous.mode.name), previous.mode),
            timeAxis = enumValue(text("timeAxis", previous.timeAxis.name), previous.timeAxis),
            direction = enumValue(text("direction", previous.direction.name), previous.direction),
            categoryId = if (values.containsKey("categoryId")) values["categoryId"] as? String else previous.categoryId,
            eventLine = enumValue(text("eventLine", previous.eventLine.name), previous.eventLine),
            privacy = enumValue(text("privacy", previous.privacy.name), previous.privacy),
        ).copy(generation = previous.generation + 1L)
        preferences.edit()
            .putString("mode", next.mode.name)
            .putString("axis", next.timeAxis.name)
            .putString("direction", next.direction.name)
            .putString("categoryId", next.categoryId)
            .putString("eventLine", next.eventLine.name)
            .putString("privacy", next.privacy.name)
            .putLong("generation", next.generation)
            .apply()
        return next
    }

    fun toMap(configuration: FluviFinancialSnapshotWidgetConfiguration): Map<String, Any?> = mapOf(
        "mode" to configuration.mode.name,
        "timeAxis" to configuration.timeAxis.name,
        "direction" to configuration.direction.name,
        "categoryId" to configuration.categoryId,
        "eventLine" to configuration.eventLine.name,
        "privacy" to configuration.privacy.name,
        "generation" to configuration.generation,
        "valid" to configuration.isValid,
    )

    private inline fun <reified T : Enum<T>> enum(name: String, fallback: T): T =
        enumValue(preferences.getString(name, null), fallback)

    private inline fun <reified T : Enum<T>> enumValue(value: String?, fallback: T): T =
        enumValues<T>().firstOrNull { it.name == value } ?: fallback
}

/** Keeps full content separate from the notification cache and version-binds
 * it to the widget configuration so an older async lookup cannot republish
 * values after Full → Diszkrét or a focus change. */
internal class FluviFinancialSnapshotWidgetContentStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_financial_snapshot_widget_content",
        Context.MODE_PRIVATE,
    )

    data class Cached(val content: FluviLockScreenCardContent, val generation: Long)

    fun read(expectedGeneration: Long): FluviLockScreenCardContent? {
        if (!preferences.getBoolean("available", false) ||
            preferences.getLong("generation", -1L) != expectedGeneration
        ) return null
        return FluviLockScreenCardContent(
            focus = preferences.getString("focus", "Fluvi") ?: "Fluvi",
            primary = preferences.getString("primary", "") ?: "",
            secondary = preferences.getString("secondary", "") ?: "",
            event = preferences.getString("event", null),
            eventLabel = preferences.getString("eventLabel", null),
            accentColor = preferences.getInt("accent", Color.rgb(70, 105, 157)),
            available = true,
        )
    }

    fun write(content: FluviLockScreenCardContent, generation: Long) {
        preferences.edit()
            .putBoolean("available", content.available)
            .putLong("generation", generation)
            .putString("focus", content.focus)
            .putString("primary", content.primary)
            .putString("secondary", content.secondary)
            .putString("event", content.event)
            .putString("eventLabel", content.eventLabel)
            .putInt("accent", content.accentColor)
            .apply()
    }
}

/** Per-instance view choice only. It contains no financial data and has a
 * unique PendingIntent URI for each AppWidget id. */
private class FluviFinancialSnapshotWidgetViewStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_financial_snapshot_widget_view",
        Context.MODE_PRIVATE,
    )

    fun showEvent(id: Int): Boolean = preferences.getBoolean("$id.showEvent", false)
    fun toggle(id: Int): Boolean {
        val next = !showEvent(id)
        preferences.edit().putBoolean("$id.showEvent", next).apply()
        return next
    }
    fun delete(ids: IntArray) = preferences.edit().also { editor ->
        ids.forEach { editor.remove("$it.showEvent") }
    }.apply()
}

internal object FluviFinancialSnapshotWidgetCoordinator {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var observation: Job? = null
    private val observing = AtomicBoolean(false)

    fun configuration(context: Context): FluviFinancialSnapshotWidgetConfiguration =
        FluviFinancialSnapshotWidgetStore(context).read()

    fun update(context: Context, values: Map<*, *>): FluviFinancialSnapshotWidgetConfiguration {
        val application = context.applicationContext
        val next = FluviFinancialSnapshotWidgetStore(application).saveFromMap(values)
        // Tightening privacy must replace every host payload before any slow
        // Core query runs. The renderer itself contains no full fields then.
        FluviFinancialSnapshotWidgetProvider.renderCached(application)
        refreshAsync(application, "widgetConfiguration", next.generation)
        reconcileCoreObserver(application)
        // The native keyguard card shares this focus even when no AppWidget
        // host exists; its own privacy setting remains independent.
        FluviKeyguardCardServiceRegistry.notifyFocusChanged()
        return next
    }

    fun refreshAsync(context: Context, reason: String, expectedGeneration: Long? = null) {
        val application = context.applicationContext
        val expected = expectedGeneration ?: configuration(application).generation
        if (!hasWidgets(application)) return
        scope.launch {
            val current = configuration(application)
            if (current.generation != expected) return@launch
            val content = if (current.isValid) {
                runCatching { FluviLockScreenCardCoordinator.resolve(application, current.asFinancialFocus()) }.getOrNull()
            } else {
                null
            }
            if (configuration(application).generation != expected) return@launch
            if (content != null) {
                FluviFinancialSnapshotWidgetContentStore(application).write(content, expected)
            }
            FluviFinancialSnapshotWidgetProvider.renderCached(application)
        }
    }

    fun reconcileCoreObserver(context: Context) {
        val application = context.applicationContext
        if (!hasWidgets(application)) {
            observation?.cancel()
            observation = null
            observing.set(false)
            return
        }
        if (!observing.compareAndSet(false, true)) return
        observation = scope.launch {
            val core = FluviCoreFactory.create(application)
            try {
                core.query.observeCoreRevision().collectLatest {
                    refreshAsync(application, "coreRevision")
                }
            } finally {
                core.close()
                observing.set(false)
            }
        }
    }

    fun onWidgetsChanged(context: Context) {
        val application = context.applicationContext
        reconcileCoreObserver(application)
        FluviFinancialSnapshotWidgetProvider.renderCached(application)
        refreshAsync(application, "widgetHost")
    }

    fun hasWidgets(context: Context): Boolean = ids(context).isNotEmpty()

    fun ids(context: Context): IntArray = AppWidgetManager.getInstance(context.applicationContext)
        .getAppWidgetIds(ComponentName(context.applicationContext, FluviFinancialSnapshotWidgetProvider::class.java))

    fun statusMap(context: Context): Map<String, Any?> {
        val configuration = configuration(context)
        return mapOf(
            "configuration" to FluviFinancialSnapshotWidgetStore(context).toMap(configuration),
            "hostWidgetCount" to ids(context).size,
            // A provider can identify an instance, never whether a third-party
            // host put it on a keyguard. Keep that distinction explicit.
            "lockscreenPlacementVerified" to false,
        )
    }

    suspend fun preview(context: Context): Map<String, Any?> {
        val application = context.applicationContext
        val current = configuration(application)
        val categories = FluviLockScreenCardCoordinator.categories(application, current.direction)
        val content = if (current.isValid) {
            runCatching { FluviLockScreenCardCoordinator.resolve(application, current.asFinancialFocus()) }
                .getOrNull()
        } else {
            null
        }
        if (content != null && configuration(application).generation == current.generation) {
            FluviFinancialSnapshotWidgetContentStore(application).write(content, current.generation)
        }
        return statusMap(application) + mapOf(
            "categories" to categories,
            "content" to (content?.toMap() ?: mapOf(
                "focus" to "Fluvi · Pénzügyi pillanatkép",
                "primary" to "Mintaadat",
                "secondary" to "A valós adatok betöltése után frissül",
                "event" to null,
                "eventLabel" to null,
                "available" to false,
            )),
        )
    }
}

class FluviFinancialSnapshotWidgetProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        renderCached(context, manager, ids)
        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        renderCached(context, manager, intArrayOf(appWidgetId))
        FluviFinancialSnapshotWidgetCoordinator.refreshAsync(context, "optionsChanged")
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        FluviFinancialSnapshotWidgetViewStore(context).delete(appWidgetIds)
        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
    }

    override fun onDisabled(context: Context) {
        FluviFinancialSnapshotWidgetCoordinator.onWidgetsChanged(context)
        super.onDisabled(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE) {
            val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            val configuration = FluviFinancialSnapshotWidgetCoordinator.configuration(context)
            if (id != AppWidgetManager.INVALID_APPWIDGET_ID &&
                configuration.privacy == FluviLockScreenCardConfiguration.Privacy.full
            ) {
                FluviFinancialSnapshotWidgetViewStore(context).toggle(id)
                renderCached(context, AppWidgetManager.getInstance(context), intArrayOf(id))
            }
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        private const val ACTION_TOGGLE = "com.fluvi.app.widget.financial.TOGGLE_VIEW"
        private const val EXTRA_MODE = "com.fluvi.app.widget.financial.MODE"
        private const val EXTRA_AXIS = "com.fluvi.app.widget.financial.AXIS"
        private const val EXTRA_CATEGORY = "com.fluvi.app.widget.financial.CATEGORY"

        internal fun renderCached(context: Context) {
            val manager = AppWidgetManager.getInstance(context.applicationContext)
            renderCached(context, manager, FluviFinancialSnapshotWidgetCoordinator.ids(context))
        }

        internal fun renderCached(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val application = context.applicationContext
            val configuration = FluviFinancialSnapshotWidgetCoordinator.configuration(application)
            val content = FluviFinancialSnapshotWidgetContentStore(application).read(configuration.generation)
            val viewStore = FluviFinancialSnapshotWidgetViewStore(application)
            ids.forEach { id ->
                manager.updateAppWidget(id, remoteViews(application, id, configuration, content, viewStore.showEvent(id)))
            }
        }

        private fun remoteViews(
            context: Context,
            id: Int,
            configuration: FluviFinancialSnapshotWidgetConfiguration,
            content: FluviLockScreenCardContent?,
            showEvent: Boolean,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.fluvi_financial_snapshot_widget)
            val narrow = AppWidgetManager.getInstance(context).getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 220) < 180
            val actual = if (configuration.isValid) content else null
            val presentation = when {
                configuration.privacy == FluviLockScreenCardConfiguration.Privacy.discreet -> FluviFinancialCardPresenter.discreet()
                actual == null -> FluviFinancialCardPresenter.loading()
                else -> FluviFinancialCardPresenter.full(actual, showEvent)
            }
            applyPresentation(views, presentation, narrow)
            if (presentation.showToggle) {
                views.setOnClickPendingIntent(R.id.fluvi_financial_snapshot_toggle, toggleIntent(context, id))
            }
            views.setOnClickPendingIntent(R.id.fluvi_financial_snapshot_root, openIntent(context, id, configuration))
            return views
        }

        private fun applyPresentation(
            views: RemoteViews,
            presentation: FluviFinancialCardPresentation,
            narrow: Boolean,
        ) {
            views.setTextViewText(R.id.fluvi_financial_snapshot_focus, presentation.focus)
            views.setTextViewText(R.id.fluvi_financial_snapshot_primary, presentation.primary)
            views.setTextViewText(R.id.fluvi_financial_snapshot_secondary, presentation.secondary)
            views.setViewVisibility(
                R.id.fluvi_financial_snapshot_secondary,
                if (narrow) View.GONE else View.VISIBLE,
            )
            val event = presentation.event?.let { "${presentation.eventLabel ?: "Utolsó tétel"}: $it" }
            views.setTextViewText(R.id.fluvi_financial_snapshot_event, event ?: "")
            views.setViewVisibility(
                R.id.fluvi_financial_snapshot_event,
                if (!narrow && event != null) View.VISIBLE else View.GONE,
            )
            views.setTextViewText(R.id.fluvi_financial_snapshot_toggle, presentation.toggleLabel)
            views.setViewVisibility(
                R.id.fluvi_financial_snapshot_toggle,
                if (presentation.showToggle) View.VISIBLE else View.GONE,
            )
            views.setImageViewBitmap(R.id.fluvi_financial_snapshot_orb, presentation.orb)
            views.setContentDescription(R.id.fluvi_financial_snapshot_root, presentation.contentDescription)
        }

        private fun openIntent(
            context: Context,
            id: Int,
            configuration: FluviFinancialSnapshotWidgetConfiguration,
        ): PendingIntent = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java).apply {
                action = "com.fluvi.app.widget.financial.OPEN"
                data = Uri.parse("fluvi://financial-snapshot/open/$id")
                putExtra(EXTRA_MODE, configuration.mode.name)
                putExtra(EXTRA_AXIS, configuration.timeAxis.name)
                putExtra(EXTRA_CATEGORY, configuration.categoryId)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun toggleIntent(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, FluviFinancialSnapshotWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE
                data = Uri.parse("fluvi://financial-snapshot/toggle/$id")
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
