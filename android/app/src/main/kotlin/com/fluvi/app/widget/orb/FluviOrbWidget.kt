package com.fluvi.app.widget.orb

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.AdapterView
import android.view.Gravity
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Spinner
import android.widget.TextView
import com.fluvi.app.R
import com.fluvi.app.runtime.FluviRuntimeCoordinator
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.LedgerDirection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicLong

/**
 * Immutable per-AppWidgetId intent. A category is always identified by the
 * durable Core id, never by its current carousel position or target handle.
 */
internal data class FluviOrbConfiguration(
    val schemaVersion: Int,
    val appWidgetId: Int,
    val configurationRevision: Long,
    val mode: Mode,
    val timeAxis: TimeAxis,
    val direction: Direction,
    val ghostFilter: GhostFilter,
    val categoryId: String?,
    val periodBinding: PeriodBinding,
    val createdAtUtcMs: Long,
    val updatedAtUtcMs: Long,
) {
    enum class Mode { mind, balance, budget }
    enum class TimeAxis { sum, year, month, day }
    enum class Direction { income, expense }
    enum class GhostFilter { both, nonGhost, onlyGhost }
    enum class PeriodBinding { current }

    companion object {
        fun initial(appWidgetId: Int): FluviOrbConfiguration {
            val now = System.currentTimeMillis()
            return FluviOrbConfiguration(
                schemaVersion = 1,
                appWidgetId = appWidgetId,
                configurationRevision = 1,
                mode = Mode.balance,
                timeAxis = TimeAxis.month,
                direction = Direction.expense,
                ghostFilter = GhostFilter.both,
                categoryId = null,
                periodBinding = PeriodBinding.current,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            )
        }
    }
}

/** Native storage is deliberately usable from providers, services and config. */
internal class FluviOrbConfigurationStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_home_orb_configurations",
        Context.MODE_PRIVATE,
    )

    fun get(id: Int): FluviOrbConfiguration? {
        if (!preferences.contains("$id.mode")) return null
        return runCatching {
            FluviOrbConfiguration(
                schemaVersion = preferences.getInt("$id.schema", 1).takeIf { it == 1 } ?: 1,
                appWidgetId = id,
                configurationRevision = preferences.getLong("$id.revision", 1),
                mode = FluviOrbConfiguration.Mode.valueOf(preferences.getString("$id.mode", null)!!),
                timeAxis = FluviOrbConfiguration.TimeAxis.valueOf(preferences.getString("$id.axis", null)!!),
                direction = FluviOrbConfiguration.Direction.valueOf(preferences.getString("$id.direction", null)!!),
                ghostFilter = FluviOrbConfiguration.GhostFilter.valueOf(preferences.getString("$id.ghost", null)!!),
                categoryId = preferences.getString("$id.category", null),
                periodBinding = preferences.getString("$id.periodBinding", null)
                    ?.let(FluviOrbConfiguration.PeriodBinding::valueOf)
                    ?: FluviOrbConfiguration.PeriodBinding.current,
                createdAtUtcMs = preferences.getLong("$id.created", 0),
                updatedAtUtcMs = preferences.getLong("$id.updated", 0),
            )
        }.getOrNull()
    }

    fun save(configuration: FluviOrbConfiguration) {
        preferences.edit()
            .putInt("${configuration.appWidgetId}.schema", configuration.schemaVersion)
            .putString("${configuration.appWidgetId}.mode", configuration.mode.name)
            .putString("${configuration.appWidgetId}.axis", configuration.timeAxis.name)
            .putString("${configuration.appWidgetId}.direction", configuration.direction.name)
            .putString("${configuration.appWidgetId}.ghost", configuration.ghostFilter.name)
            .putString("${configuration.appWidgetId}.category", configuration.categoryId)
            .putString("${configuration.appWidgetId}.periodBinding", configuration.periodBinding.name)
            .putLong("${configuration.appWidgetId}.revision", configuration.configurationRevision)
            .putLong("${configuration.appWidgetId}.created", configuration.createdAtUtcMs)
            .putLong("${configuration.appWidgetId}.updated", configuration.updatedAtUtcMs)
            .apply()
    }

    fun delete(ids: IntArray) {
        preferences.edit().also { editor ->
            ids.forEach { id ->
                listOf("schema", "mode", "axis", "direction", "ghost", "category", "periodBinding", "revision", "created", "updated")
                    .forEach { suffix -> editor.remove("$id.$suffix") }
            }
        }.apply()
    }

    fun remap(oldIds: IntArray, newIds: IntArray) {
        oldIds.zip(newIds).forEach { (oldId, newId) ->
            if (oldId == newId) return@forEach
            val previous = get(oldId) ?: return@forEach
            save(
                previous.copy(
                    appWidgetId = newId,
                    configurationRevision = previous.configurationRevision + 1,
                    updatedAtUtcMs = System.currentTimeMillis(),
                ),
            )
            delete(intArrayOf(oldId))
        }
    }

    fun configuredIds(): IntArray = preferences.all.keys
        .mapNotNull { it.substringBefore('.').toIntOrNull() }
        .distinct()
        .toIntArray()
}

/**
 * This capability gate makes the Android 15 limitation explicit. It does not
 * substitute a bitmap loop or a static header for the required host-local,
 * continuous header material renderer.
 */
internal object OrbRendererCapabilities {
    data class State(val liveHeaderSupported: Boolean, val reason: String)

    fun current(): State = forAndroidApi(Build.VERSION.SDK_INT)

    /**
     * A platform level alone does not prove the launcher has a compatible
     * Remote Compose player, therefore there is intentionally no true branch
     * until a document/host prototype is added and verified on-device.
     */
    internal fun forAndroidApi(androidApi: Int): State = when {
        androidApi < 36 -> State(
            liveHeaderSupported = false,
            reason = "Ezen az Android-verzión nincs igazolt élő orb-renderer.",
        )
        else -> State(
            liveHeaderSupported = false,
            reason = "A launcher Remote Compose material-profilja nincs eszközön igazolva.",
        )
    }
}

/**
 * Event-driven AppWidget refresh boundary. It intentionally does not render
 * frames or keep an Engine alive; the future live renderer consumes the same
 * per-instance configuration through this one path.
 */
internal object FluviOrbUpdateCoordinator {
    private val updateGeneration = AtomicLong(0)

    fun requestRefresh(context: Context, reason: String) {
        val manager = AppWidgetManager.getInstance(context)
        val provider = ComponentName(context, FluviOrbWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(provider)
        if (ids.isEmpty()) return
        FluviOrbRevisionObserver.reconcile(context)
        updateGeneration.incrementAndGet()
        FluviRuntimeCoordinator.onWidgetRefreshRequested(context)
        FluviOrbWidgetProvider.render(context, manager, ids, reason)
    }
}

/**
 * Covers Core writes that do not pass through a Flutter Activity (restore,
 * service work, future native writers) while widgets exist. It owns its Core
 * instance and releases it as soon as the last provider instance disappears.
 * This is an event observer, never a rendering/timer loop.
 */
internal object FluviOrbRevisionObserver {
    private var observation: Job? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Synchronized
    fun reconcile(context: Context) {
        val application = context.applicationContext
        val ids = AppWidgetManager.getInstance(application).getAppWidgetIds(
            ComponentName(application, FluviOrbWidgetProvider::class.java),
        )
        if (ids.isEmpty()) {
            observation?.cancel()
            observation = null
            return
        }
        if (observation?.isActive == true) return
        observation = scope.launch {
            val core = FluviCoreFactory.create(application)
            try {
                core.query.observeCoreRevision().collectLatest {
                    FluviOrbUpdateCoordinator.requestRefresh(application, "coreRevision")
                }
            } finally {
                core.close()
            }
        }
    }
}

class FluviOrbWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        FluviOrbRevisionObserver.reconcile(context)
        render(context, manager, ids, reason = "systemUpdate")
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        FluviOrbConfigurationStore(context).delete(ids)
        FluviOrbRevisionObserver.reconcile(context)
        super.onDeleted(context, ids)
    }

    override fun onRestored(context: Context, oldIds: IntArray, newIds: IntArray) {
        FluviOrbConfigurationStore(context).remap(oldIds, newIds)
        FluviOrbRevisionObserver.reconcile(context)
        render(
            context,
            AppWidgetManager.getInstance(context),
            newIds,
            reason = "restored",
        )
        super.onRestored(context, oldIds, newIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        render(context, manager, intArrayOf(appWidgetId), reason = "optionsChanged")
    }

    companion object {
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray, reason: String) {
            val store = FluviOrbConfigurationStore(context)
            val capability = OrbRendererCapabilities.current()
            ids.forEach { id ->
                val configuration = store.get(id)
                val view = android.widget.RemoteViews(context.packageName, R.layout.fluvi_orb_widget)
                val accessibilityLabel = if (configuration == null) {
                    "Fluvi élő orb: beállítás szükséges"
                } else if (!capability.liveHeaderSupported) {
                    "Fluvi élő orb: ${capability.reason}"
                } else {
                    "Fluvi élő orb"
                }
                view.setContentDescription(R.id.fluvi_orb_root, accessibilityLabel)
                view.setViewVisibility(
                    R.id.fluvi_orb_renderer_unavailable,
                    if (capability.liveHeaderSupported) View.GONE else View.VISIBLE,
                )
                view.setOnClickPendingIntent(
                    R.id.fluvi_orb_root,
                    android.app.PendingIntent.getActivity(
                        context,
                        id,
                        Intent(context, FluviOrbConfigurationActivity::class.java).apply {
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                            data = android.net.Uri.parse("fluvi-orb://configure/$id/$reason")
                        },
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
                manager.updateAppWidget(id, view)
            }
        }
    }
}

/**
 * Deliberately light native configure Activity: it neither starts Flutter nor
 * mounts the dashboard. Its preview is a configuration identity, not a false
 * claim that a static bitmap is the animated header material.
 */
class FluviOrbConfigurationActivity : Activity() {
    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var mode: Spinner
    private lateinit var axis: Spinner
    private lateinit var direction: RadioGroup
    private lateinit var category: Spinner
    private lateinit var categoryHint: TextView
    private val configurationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var categoryOptions: List<OrbCategoryOption> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        val existing = FluviOrbConfigurationStore(this).get(appWidgetId)
            ?: FluviOrbConfiguration.initial(appWidgetId)
        setContentView(buildContent(existing))
        loadBudgetCategories(existing.categoryId, existing.direction)
    }

    private fun buildContent(existing: FluviOrbConfiguration): View {
        fun spinner(values: List<String>, selected: String): Spinner = Spinner(this).apply {
            adapter = ArrayAdapter(this@FluviOrbConfigurationActivity, android.R.layout.simple_spinner_dropdown_item, values)
            setSelection(values.indexOf(selected).coerceAtLeast(0))
        }
        val modeLabels = listOf("Mind", "Balance", "Budget")
        val axisLabels = listOf("SUM", "Év", "Hónap", "Nap")
        val capability = OrbRendererCapabilities.current()
        val padding = (24 * resources.displayMetrics.density).toInt()
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            addView(TextView(context).apply {
                text = "Orb beállításai"
                textSize = 26f
                setTextColor(0xff19264d.toInt())
            })
            addView(TextView(context).apply {
                text = if (capability.liveHeaderSupported) {
                    "A kiválasztott headeranyag élő előnézete."
                } else {
                    capability.reason
                }
                setPadding(0, padding / 2, 0, padding / 2)
            })
            addView(TextView(context).apply { text = "Mód" })
            mode = spinner(modeLabels, modeLabels[existing.mode.ordinal])
            addView(mode)
            addView(TextView(context).apply { text = "Időtengely" })
            axis = spinner(axisLabels, axisLabels[existing.timeAxis.ordinal])
            addView(axis)
            addView(TextView(context).apply { text = "További beállítások · irány" })
            direction = RadioGroup(context).apply {
                orientation = RadioGroup.HORIZONTAL
                addView(RadioButton(context).apply {
                    id = R.id.fluvi_orb_income
                    text = "Bevétel"
                })
                addView(RadioButton(context).apply {
                    id = R.id.fluvi_orb_expense
                    text = "Kiadás"
                })
                check(if (existing.direction == FluviOrbConfiguration.Direction.income) R.id.fluvi_orb_income else R.id.fluvi_orb_expense)
            }
            addView(direction)
            categoryHint = TextView(context).apply {
                text = "Budget kategória"
                setPadding(0, padding / 2, 0, 0)
            }
            addView(categoryHint)
            category = spinner(listOf("Kategóriák betöltése…"), "Kategóriák betöltése…")
            category.isEnabled = false
            addView(category)
            fun updateBudgetCategoryVisibility() {
                val visible = mode.selectedItemPosition == FluviOrbConfiguration.Mode.budget.ordinal
                categoryHint.visibility = if (visible) View.VISIBLE else View.GONE
                category.visibility = if (visible) View.VISIBLE else View.GONE
            }
            mode.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                    updateBudgetCategoryVisibility()
                }

                override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            }
            updateBudgetCategoryVisibility()
            direction.setOnCheckedChangeListener { _, checkedId ->
                val selected = if (checkedId == R.id.fluvi_orb_income) {
                    FluviOrbConfiguration.Direction.income
                } else {
                    FluviOrbConfiguration.Direction.expense
                }
                loadBudgetCategories(null, selected)
            }
            addView(Button(context).apply {
                text = when {
                    !capability.liveHeaderSupported -> "Élő orb nem támogatott"
                    FluviOrbConfigurationStore(this@FluviOrbConfigurationActivity).get(appWidgetId) == null -> "Orb hozzáadása"
                    else -> "Mentés"
                }
                isEnabled = capability.liveHeaderSupported
                if (capability.liveHeaderSupported) setOnClickListener { save(existing) }
            })
            addView(Button(context).apply {
                text = "Mégse"
                setOnClickListener { finish() }
            })
        }
    }

    private fun save(existing: FluviOrbConfiguration) {
        val capability = OrbRendererCapabilities.current()
        if (!capability.liveHeaderSupported) {
            categoryHint.error = capability.reason
            return
        }
        val selectedMode = FluviOrbConfiguration.Mode.entries[mode.selectedItemPosition]
        val categoryId = categoryOptions.getOrNull(category.selectedItemPosition)?.id
        if (selectedMode == FluviOrbConfiguration.Mode.budget && categoryId == null) {
            categoryHint.error = "Ehhez a nézethez még nincs beállított kategóriakeret."
            return
        }
        val updated = existing.copy(
            configurationRevision = existing.configurationRevision + 1,
            mode = selectedMode,
            timeAxis = FluviOrbConfiguration.TimeAxis.entries[axis.selectedItemPosition],
            direction = if (direction.checkedRadioButtonId == R.id.fluvi_orb_income) {
                FluviOrbConfiguration.Direction.income
            } else {
                FluviOrbConfiguration.Direction.expense
            },
            categoryId = categoryId,
            updatedAtUtcMs = System.currentTimeMillis(),
        )
        FluviOrbConfigurationStore(this).save(updated)
        FluviOrbRevisionObserver.reconcile(this)
        FluviOrbWidgetProvider.render(
            this,
            AppWidgetManager.getInstance(this),
            intArrayOf(appWidgetId),
            reason = "configurationSaved",
        )
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
        finish()
    }

    private fun loadBudgetCategories(
        selectedCategoryId: String?,
        selectedDirection: FluviOrbConfiguration.Direction,
    ) {
        category.isEnabled = false
        categoryHint.text = "Budget kategória · betöltés…"
        configurationScope.launch {
            val options = runCatching {
                val core = FluviCoreFactory.create(applicationContext)
                try {
                    val direction = if (selectedDirection == FluviOrbConfiguration.Direction.income) {
                        LedgerDirection.income
                    } else {
                        LedgerDirection.expense
                    }
                    val allowedIds = core.financialLimits.list()
                        .asSequence()
                        .filter { it.key.direction == direction }
                        .mapNotNull { it.key.categoryId }
                        .toSet()
                    core.categories.list()
                        .asSequence()
                        .filter { it.id in allowedIds }
                        .map { OrbCategoryOption(it.id, it.name) }
                        .sortedBy { it.label.lowercase() }
                        .toList()
                } finally {
                    core.close()
                }
            }.getOrDefault(emptyList())
            runOnUiThread {
                if (isFinishing || isDestroyed) return@runOnUiThread
                categoryOptions = options
                val labels = if (options.isEmpty()) {
                    listOf("Nincs beállított kategóriakeret")
                } else {
                    options.map { it.label }
                }
                category.adapter = ArrayAdapter(
                    this@FluviOrbConfigurationActivity,
                    android.R.layout.simple_spinner_dropdown_item,
                    labels,
                )
                category.isEnabled = options.isNotEmpty()
                category.setSelection(
                    options.indexOfFirst { it.id == selectedCategoryId }
                        .takeIf { it >= 0 } ?: 0,
                )
                categoryHint.text = if (options.isEmpty()) {
                    "Ehhez a nézethez még nincs beállított kategóriakeret."
                } else {
                    "Budget kategória"
                }
            }
        }
    }

    override fun onDestroy() {
        configurationScope.cancel()
        super.onDestroy()
    }

    private data class OrbCategoryOption(val id: String, val label: String)
}
