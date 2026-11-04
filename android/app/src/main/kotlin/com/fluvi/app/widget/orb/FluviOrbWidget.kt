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
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
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
import java.util.concurrent.ConcurrentHashMap
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
 * The AppWidget backend delivers a bounded Flutter-material bitmap sequence
 * once and ViewFlipper repeats it inside the launcher. A static palette
 * fallback is used only until Dashboard has exported the first source bundle.
 */
internal object OrbRendererCapabilities {
    data class State(
        val liveHeaderSupported: Boolean,
        val reason: String,
        val backend: String,
        val isShaderIdentical: Boolean,
    )

    fun current(): State = forAndroidApi(Build.VERSION.SDK_INT)

    internal fun forAndroidApi(androidApi: Int): State = if (androidApi >= 24) {
        State(
            liveHeaderSupported = true,
            reason = "Header-anyag képkockacsomag · ViewFlipper helyi lejátszással.",
            backend = "remoteviews-flutter-material-v2",
            isShaderIdentical = false,
        )
    } else {
        State(
            liveHeaderSupported = false,
            reason = "Az orb Android 7.0 vagy újabb rendszert igényel.",
            backend = "unsupported",
            isShaderIdentical = false,
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
        FluviOrbWidgetProvider.renderAsync(context, manager, ids, reason)
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
    override fun onEnabled(context: Context) {
        FluviOrbRevisionObserver.reconcile(context)
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // After the final provider instance disappears, reconcile cancels the
        // Core revision collector instead of retaining a widget-only resource.
        FluviOrbRevisionObserver.reconcile(context)
        super.onDisabled(context)
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        FluviOrbRevisionObserver.reconcile(context)
        val pending = goAsync()
        renderAsync(context, manager, ids, reason = "systemUpdate") { pending.finish() }
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        FluviOrbConfigurationStore(context).delete(ids)
        OrbMaterialFrameStore.delete(context, ids)
        FluviOrbRevisionObserver.reconcile(context)
        super.onDeleted(context, ids)
    }

    override fun onRestored(context: Context, oldIds: IntArray, newIds: IntArray) {
        FluviOrbConfigurationStore(context).remap(oldIds, newIds)
        FluviOrbRevisionObserver.reconcile(context)
        val pending = goAsync()
        renderAsync(
            context,
            AppWidgetManager.getInstance(context),
            newIds,
            reason = "restored",
        ) { pending.finish() }
        super.onRestored(context, oldIds, newIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        val pending = goAsync()
        renderAsync(context, manager, intArrayOf(appWidgetId), reason = "optionsChanged") {
            pending.finish()
        }
    }

    companion object {
        private val renderScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        private val renderGenerations = ConcurrentHashMap<Int, AtomicLong>()

        fun renderAsync(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
            reason: String,
            onFinished: () -> Unit = {},
        ) {
            val application = context.applicationContext
            val requestedGenerations = ids.associateWith { id ->
                renderGenerations.getOrPut(id) { AtomicLong(0) }.incrementAndGet()
            }
            renderScope.launch {
                try {
                    render(application, manager, ids, reason) { id ->
                        renderGenerations[id]?.get() == requestedGenerations[id]
                    }
                } finally {
                    onFinished()
                }
            }
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
            reason: String,
            isCurrentGeneration: (Int) -> Boolean,
        ) {
            val store = FluviOrbConfigurationStore(context)
            val capability = OrbRendererCapabilities.current()
            ids.forEach { id ->
                runCatching {
                    if (!isCurrentGeneration(id)) return@runCatching
                    // Android launches the configure Activity before a newly
                    // added widget is committed.  Keep its XML shell empty
                    // until that Activity returns RESULT_OK instead of
                    // briefly publishing an arbitrary default target.
                    val configuration = store.get(id) ?: return@runCatching
                    val profile = OrbCompatibilityVisualProfileResolver.resolve(context, configuration)
                    val sequence = OrbMaterialFrameStore.sequenceFor(context, configuration)
                        ?: OrbCompatibilityFrameRenderer.sequenceFor(
                            profile,
                            framePlanFor(context, manager, id),
                        )
                    val view = android.widget.RemoteViews(context.packageName, R.layout.fluvi_orb_widget)
                    view.removeAllViews(R.id.fluvi_orb_frame_flipper)
                    view.setInt(
                        R.id.fluvi_orb_frame_flipper,
                        "setFlipInterval",
                        sequence.plan.intervalMs,
                    )
                    sequence.frames.forEach { frame ->
                        val child = android.widget.RemoteViews(
                            context.packageName,
                            R.layout.fluvi_orb_widget_frame,
                        )
                        child.setImageViewBitmap(R.id.fluvi_orb_frame_image, frame)
                        view.addView(R.id.fluvi_orb_frame_flipper, child)
                    }
                    view.setContentDescription(
                        R.id.fluvi_orb_root,
                        "Fluvi élő orb · ${configuration.mode.name} · ${capability.backend}",
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
                    if (!isCurrentGeneration(id)) return@runCatching
                    manager.updateAppWidget(id, view)
                    OrbFrameRenderDiagnostics.published(context, id, profile, sequence)
                }.onFailure { failure ->
                    // Do not replace a previous good orb with a text/error
                    // placeholder while a transient frame build fails.
                    OrbFrameRenderDiagnostics.failed(context, id, failure)
                }
            }
        }

        private fun framePlanFor(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ): OrbFramePlan {
            val options = manager.getAppWidgetOptions(widgetId)
            val widthDp = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 56),
            )
            val heightDp = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 56),
            )
            val shortSidePx = (minOf(widthDp, heightDp).coerceAtLeast(1) *
                context.resources.displayMetrics.density).toInt()
            return OrbCompatibilityFrameRenderer.planFor(shortSidePx)
        }
    }
}

/**
 * Deliberately light native configure Activity: it neither starts Flutter nor
 * mounts the dashboard. Its still preview is the first frame of the exact
 * bounded sequence delivered to the launcher; the installed widget itself is
 * where the ViewFlipper owns playback.
 */
class FluviOrbConfigurationActivity : Activity() {
    private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var mode: Spinner
    private lateinit var axis: Spinner
    private lateinit var direction: RadioGroup
    private lateinit var category: Spinner
    private lateinit var categoryHint: TextView
    private lateinit var preview: ImageView
    private lateinit var baselineConfiguration: FluviOrbConfiguration
    private val configurationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var categoryOptions: List<OrbCategoryOption> = emptyList()
    private val categoryLoadGeneration = AtomicLong(0)

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
        baselineConfiguration = existing
        setContentView(buildContent(existing))
        updatePreview()
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
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            addView(TextView(context).apply {
                text = "Orb beállításai"
                textSize = 26f
                setTextColor(0xff19264d.toInt())
            })
            addView(TextView(context).apply {
                text = capability.reason
                setPadding(0, padding / 2, 0, padding / 2)
            })
            preview = ImageView(context).apply {
                contentDescription = "Az orb animációjának első képkockája"
                adjustViewBounds = true
                layoutParams = LinearLayout.LayoutParams(
                    (128 * resources.displayMetrics.density).toInt(),
                    (128 * resources.displayMetrics.density).toInt(),
                ).apply { gravity = Gravity.CENTER_HORIZONTAL }
            }
            addView(preview)
            addView(TextView(context).apply { text = "Mód" })
            mode = spinner(modeLabels, modeLabels[existing.mode.ordinal])
            addView(mode)
            addView(TextView(context).apply { text = "Időtengely" })
            axis = spinner(axisLabels, axisLabels[existing.timeAxis.ordinal])
            addView(axis)
            axis.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) =
                    updatePreview()

                override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            }
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
                    if (position == FluviOrbConfiguration.Mode.budget.ordinal) {
                        val selected = if (direction.checkedRadioButtonId == R.id.fluvi_orb_income) {
                            FluviOrbConfiguration.Direction.income
                        } else {
                            FluviOrbConfiguration.Direction.expense
                        }
                        loadBudgetCategories(null, selected)
                    }
                    updatePreview()
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
                updatePreview()
            }
            category.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) =
                    updatePreview()

                override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            }
            addView(Button(context).apply {
                text = when {
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
        return ScrollView(this).apply {
            isFillViewport = true
            addView(content)
        }
    }

    private fun updatePreview() {
        if (!::preview.isInitialized || !::mode.isInitialized || !::axis.isInitialized || !::direction.isInitialized) return
        val draft = baselineConfiguration.copy(
            mode = FluviOrbConfiguration.Mode.entries[mode.selectedItemPosition],
            timeAxis = FluviOrbConfiguration.TimeAxis.entries[axis.selectedItemPosition],
            direction = if (direction.checkedRadioButtonId == R.id.fluvi_orb_income) {
                FluviOrbConfiguration.Direction.income
            } else {
                FluviOrbConfiguration.Direction.expense
            },
            categoryId = if (::category.isInitialized) {
                categoryOptions.getOrNull(category.selectedItemPosition)?.id
            } else {
                null
            },
        )
        val firstFrame = runCatching {
            OrbCompatibilityFrameRenderer.sequenceFor(
                OrbCompatibilityVisualProfileResolver.resolve(this, draft),
            ).frames.first()
        }.getOrNull()
        preview.setImageBitmap(firstFrame)
    }

    private fun save(existing: FluviOrbConfiguration) {
        if (!OrbRendererCapabilities.current().liveHeaderSupported) return
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
        // The configuration result is not reported as successful until the
        // bounded launcher frame package can actually be prepared.
        val framesPrepared = runCatching {
            OrbCompatibilityFrameRenderer.sequenceFor(
                OrbCompatibilityVisualProfileResolver.resolve(this, updated),
            )
        }.isSuccess
        if (!framesPrepared) {
            categoryHint.error = "Az orb képkockái nem készültek el. Próbáld újra."
            return
        }
        FluviOrbConfigurationStore(this).save(updated)
        FluviOrbRevisionObserver.reconcile(this)
        FluviOrbWidgetProvider.renderAsync(
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
        val generation = categoryLoadGeneration.incrementAndGet()
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
                if (generation != categoryLoadGeneration.get()) return@runOnUiThread
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
