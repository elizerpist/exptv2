package com.fluvi.app

import android.content.pm.ApplicationInfo
import android.os.Looper
import android.util.Log
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.CreateManualTransactionCommand
import com.fluvi.core.model.FluviLedgerEntryDetail
import com.fluvi.core.model.FluviPartnerDirectoryEntry
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.ManualTransactionPartnerSelection
import com.fluvi.core.model.UpdateLedgerEntryCommand
import com.fluvi.core.model.UpdatePartnerCommand
import com.fluvi.core.model.CreatePushProfileCommand
import com.fluvi.core.model.UpdatePushProfileCommand
import com.fluvi.core.model.CreatePushRuleCommand
import com.fluvi.core.model.PushFieldSpan
import com.fluvi.core.model.PushFieldRole
import com.fluvi.core.model.PushProfileState
import com.fluvi.core.model.PushSampleKind
import com.fluvi.core.model.PushTransactionDirection
import com.fluvi.core.model.ApprovePushReviewCommand
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.model.CreateRecurrenceRuleCommand
import com.fluvi.core.model.UpdateOccurrenceOverrideCommand
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.pulse.PulseDashboardSnapshot
import com.fluvi.core.pulse.PulseIndicatorSnapshot
import com.fluvi.core.pulse.PulseSignalInspectionSnapshot
import com.fluvi.core.pulse.PulseSituationInspectionSnapshot
import com.fluvi.core.pulse.PulseSituationSnapshot
import com.fluvi.core.pulse.PulseTriageDashboardSnapshot
import com.fluvi.core.pulse.PulsePriorityDashboardSnapshot
import com.fluvi.core.pulse.PulsePriorityInspectionSnapshot
import com.fluvi.core.pulse.PulsePriorityFrame
import com.fluvi.core.pulse.PulsePriorityCandidate
import com.fluvi.core.pulse.PulseStoryInspectionSnapshot
import com.fluvi.app.dashboard.DashboardBinaryCodec
import com.fluvi.app.dashboard.DashboardPreparedIndexAcquisitionReasons
import com.fluvi.app.dashboard.DashboardPreparedIndexQueryGenerationOwner
import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.app.query.QueryMenuMethodBridge
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    // Dashboard query work may be received and replied to off the Android UI
    // thread. Prepared-query latest-generation ownership remains explicit.
    private val queryScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var core: FluviCore? = null
    private var categoryChannel: MethodChannel? = null
    private var manualTransactionChannel: MethodChannel? = null
    private var automationChannel: MethodChannel? = null
    private var automationPermissionChannel: MethodChannel? = null
    private var financialLimitChannel: MethodChannel? = null
    private var pulseChannel: MethodChannel? = null
    private var queryChannel: MethodChannel? = null
    private var queryTaskQueue: BinaryMessenger.TaskQueue? = null
    private var queryMenuChannel: MethodChannel? = null
    private var demoChannel: MethodChannel? = null
    private var dashboardPresentationChannel: MethodChannel? = null
    private var coreRevisionEventChannel: EventChannel? = null
    private var coreRevisionObservation: Job? = null
    private var diagnosticEventChannel: EventChannel? = null
    private var diagnosticEventSink: EventChannel.EventSink? = null
    private val preparedQueryGenerationOwner = DashboardPreparedIndexQueryGenerationOwner()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val fluviCore = FluviCoreFactory.create(applicationContext)
        core = fluviCore
        // Reconcile a delayed one-shot alarm whenever the app becomes usable.
        // This is independent from Flutter route construction and never runs on
        // the UI thread.
        scope.launch(Dispatchers.IO) {
            FluviRecurrenceScheduler.scheduleNext(applicationContext, fluviCore)
        }
        debugLog(
            "coreCreated instance=${System.identityHashCode(fluviCore)} " +
                "dbPath=${applicationContext.getDatabasePath(DATABASE_FILE_NAME).absolutePath}",
        )
        if (isDebuggable()) {
            diagnosticEventChannel = EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                DIAGNOSTIC_CHANNEL,
            ).also { channel ->
                channel.setStreamHandler(object : EventChannel.StreamHandler {
                    override fun onListen(
                        arguments: Any?,
                        events: EventChannel.EventSink,
                    ) {
                        diagnosticEventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        diagnosticEventSink = null
                    }
                })
            }
        }
        categoryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CATEGORY_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    // The root category snapshot is the first real database
                    // access on a cold dashboard launch. Keep Room open and a
                    // possible migration off Main just like the financial
                    // limit and prepared-query bridges; MethodChannel replies
                    // still return on the activity scope below.
                    runCatching {
                        withContext(Dispatchers.IO) {
                            handleCategoryCall(call, fluviCore)
                        }
                    }
                        .onSuccess(result::success)
                        .onFailure { error ->
                            result.error(
                                if (error is IllegalArgumentException) {
                                    "validation"
                                } else {
                                    "category_error"
                                },
                                error.message ?: "Category operation failed.",
                                null,
                            )
                        }
                }
            }
        }
        manualTransactionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MANUAL_TRANSACTION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching {
                        withContext(Dispatchers.IO) {
                            handleManualTransactionCall(call, fluviCore)
                        }
                    }.onSuccess(result::success).onFailure { error ->
                        result.error(
                            when (error) {
                                is com.fluvi.core.model.LedgerRevisionConflictException -> "revision_conflict"
                                is IllegalArgumentException -> "validation"
                                else -> "manual_transaction_error"
                            },
                            error.message ?: "Manual transaction operation failed.",
                            null,
                        )
                    }
                }
            }
        }
        automationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUTOMATION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching { withContext(Dispatchers.IO) { handleAutomationCall(call, fluviCore) } }
                        .onSuccess(result::success)
                        .onFailure { error ->
                            result.error(
                                if (error is IllegalArgumentException) "validation" else "automation_error",
                                error.message ?: "Automation operation failed.",
                                null,
                            )
                        }
                }
            }
        }
        automationPermissionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUTOMATION_PERMISSION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val platform = FluviAutomationPlatform(this)
                val value = when (call.method) {
                    "getPermissionStatus" -> platform.permissionStatus()
                    "openNotificationAccessSettings" -> platform.openNotificationAccessSettings()
                    "openAppNotificationSettings" -> platform.openAppNotificationSettings()
                    "openAppInfoSettings" -> platform.openAppInfoSettings()
                    "requestPostNotifications" -> platform.requestPostNotifications()
                    "sendTestNotification" -> platform.sendTestNotification()
                    "listInstalledApps" -> {
                        scope.launch {
                            runCatching { withContext(Dispatchers.IO) { platform.listInstalledApps() } }
                                .onSuccess(result::success)
                                .onFailure { result.error("installed_apps_error", it.message, null) }
                        }
                        null
                    }
                    else -> return@setMethodCallHandler result.notImplemented()
                }
                if (call.method != "listInstalledApps") result.success(value)
            }
        }
        financialLimitChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FINANCIAL_LIMIT_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching {
                        withContext(Dispatchers.IO) { handleFinancialLimitCall(call, fluviCore) }
                    }.onSuccess(result::success).onFailure { error ->
                        result.error(
                            if (error is IllegalArgumentException) "validation" else "financial_limit_error",
                            error.message ?: "Financial limit operation failed.",
                            null,
                        )
                    }
                }
            }
        }
        pulseChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PULSE_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching {
                        withContext(Dispatchers.IO) { handlePulseCall(call, fluviCore) }
                    }.onSuccess(result::success).onFailure { error ->
                        result.error(
                            if (error is IllegalArgumentException) "validation" else "pulse_error",
                            error.message ?: "Pulse operation failed.",
                            null,
                        )
                    }
                }
            }
        }
        val queryMessenger = flutterEngine.dartExecutor.binaryMessenger
        val queryQueue = queryMessenger.makeBackgroundTaskQueue()
        queryTaskQueue = queryQueue
        queryChannel = MethodChannel(
            queryMessenger,
            QUERY_CHANNEL,
            StandardMethodCodec.INSTANCE,
            queryQueue,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                dispatchQueryCall(call, result, fluviCore)
            }
        }
        queryMenuChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QUERY_MENU_CHANNEL,
        ).also { channel ->
            val bridge = QueryMenuMethodBridge()
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching {
                        withContext(Dispatchers.IO) { bridge.handle(call, fluviCore) }
                    }
                        .onSuccess(result::success)
                        .onFailure { error ->
                            result.error(
                                if (error is IllegalArgumentException) {
                                    "validation"
                                } else {
                                    "query_menu_error"
                                },
                                error.message ?: "Query Menu operation failed.",
                                null,
                            )
                        }
                }
            }
        }
        demoChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEMO_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching {
                        require(
                            applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0,
                        ) {
                            "Demo dataset bridge is available only in debug builds."
                        }
                        when (call.method) {
                            "seedDemoDataset" -> fluviCore.demoSeed
                                .let { seedUseCase ->
                                    val financialLimitStart =
                                        call.argument<Number>("financialLimitYearWindowStart")?.toInt()
                                    val financialLimitEnd =
                                        call.argument<Number>("financialLimitYearWindowEndInclusive")?.toInt()
                                    require((financialLimitStart == null) == (financialLimitEnd == null)) {
                                        "Financial-limit demo seed bounds must be supplied together."
                                    }
                                    emitDiagnostic(
                                        stage = "D0",
                                        message = "SEED_STARTED " +
                                            "forceReset=${call.argument<Boolean>("forceReset") ?: false}",
                                        scope = "dbPath=${applicationContext.getDatabasePath(DATABASE_FILE_NAME).absolutePath}",
                                    )
                                    seedUseCase
                                        .seed(
                                            forceReset = call.argument<Boolean>("forceReset") ?: false,
                                            financialLimitYearWindow =
                                                if (financialLimitStart == null) {
                                                    com.fluvi.core.demo.DemoDatasetVersion
                                                        .defaultFinancialLimitYearWindow
                                                } else {
                                                    financialLimitStart..requireNotNull(financialLimitEnd)
                                                },
                                        )
                                        .also { report ->
                                            emitDiagnostic(
                                                stage = "D1",
                                                message = "SEED_COMMITTED " +
                                                    "seedVersion=${report.seedVersion} " +
                                                    "createdEntries=${report.createdEntryCount} " +
                                                    "createdCategories=${report.createdCategoryCount} " +
                                                    "createdPartners=${report.createdPartnerCount} " +
                                                    "alreadySeeded=${report.alreadySeeded}",
                                                durationMs = report.durationMs,
                                            )
                                            debugSeedSnapshot(fluviCore)
                                        }
                                        .let(::demoSeedMap)
                                }
                            else -> throw IllegalArgumentException(
                                "Unknown demo method: ${call.method}",
                            )
                        }
                    }.onSuccess(result::success).onFailure { error ->
                        result.error(
                            if (error is IllegalArgumentException) "validation" else "demo_error",
                            error.message ?: "Demo dataset operation failed.",
                            null,
                        )
                    }
                }
            }
        }
        dashboardPresentationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DASHBOARD_PRESENTATION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences(
                    DASHBOARD_PRESENTATION_PREFERENCES,
                    MODE_PRIVATE,
                )
                when (call.method) {
                    "readDashboardPresentationSettings" -> result.success(
                        mapOf(
                            // SUM-A is the fresh-install presentation default. Only
                            // an absent SharedPreferences key gets this fallback;
                            // an explicit saved Current/SUM-A/SUM-B/Micro-day choice
                            // remains an authoritative user preference.
                            "sumVisualStyle" to preferences.getInt("sumVisualStyle", 1),
                            "showSumLayoutChooser" to preferences.getBoolean("showSumLayoutChooser", true),
                            "yearGridLayout" to preferences.getInt("yearGridLayout", 1),
                            "yearMonthlyAmountPresentation" to if (preferences.contains("yearMonthlyAmountPresentation")) preferences.getInt("yearMonthlyAmountPresentation", 1) else if (preferences.getBoolean("showYearFourByThreeScopeAmounts", true)) 1 else 0,
                            "showDayContentViewChooser" to preferences.getBoolean("showDayContentViewChooser", false),
                            "balanceUsesChildCards" to preferences.getBoolean("balanceUsesChildCards", true),
                            "balanceHeaderGraphPresentation" to preferences.getInt("balanceHeaderGraphPresentation", 1),
                            "balanceDayLayoutPresentation" to preferences.getInt("balanceDayLayoutPresentation", 0),
                            "balanceDayPerformanceVisualPresentation" to ((preferences.all["balanceDayPerformanceVisualPresentation"] as? Number)?.toInt()?.takeIf { it in 0..1 } ?: 0),
                            "balanceDayRatioViewPresentation" to ((preferences.all["balanceDayRatioViewPresentation"] as? Number)?.toInt()?.takeIf { it in 0..1 } ?: 0),
                            "balanceDayRatioPresentation" to ((preferences.all["balanceDayRatioPresentation"] as? Number)?.toInt()?.takeIf { it in 0..1 } ?: 0),
                            "balanceDayFocusedPresentation" to ((preferences.all["balanceDayFocusedPresentation"] as? Number)?.toInt()?.takeIf { it in 0..3 } ?: 0),
                            "balanceShowFocusedDayImpact" to preferences.getBoolean("balanceShowFocusedDayImpact", true),
                            "balanceSumLayoutPresentation" to preferences.getInt("balanceSumLayoutPresentation", 0),
                            "balanceSumFocusedPresentation" to preferences.getInt("balanceSumFocusedPresentation", 0),
                            "balanceShowSumFocusedSupplementaryStats" to preferences.getBoolean("balanceShowSumFocusedSupplementaryStats", true),
                            "balanceMonthLayoutPresentation" to preferences.getInt("balanceMonthLayoutPresentation", 0),
                            "balanceYearLayoutPresentation" to preferences.getInt("balanceYearLayoutPresentation", 0),
                            "balanceDailyCalculationMode" to preferences.getInt("balanceDailyCalculationMode", 0),
                            "balanceMonthlySpendingChartPresentation" to preferences.getInt("balanceMonthlySpendingChartPresentation", 0),
                            "balanceHeaderPartitionHeightPercent" to preferences.getInt("balanceHeaderPartitionHeightPercent", 50),
                            "balanceMonthCombinedCardPresentation" to preferences.getInt("balanceMonthCombinedCardPresentation", 0),
                            "balanceHeaderGlassConfigurationJson" to preferences.getString("balanceHeaderGlassConfigurationJson", ""),
                        ),
                    )
                    "writeDashboardPresentationSettings" -> {
                        val values = call.arguments as? Map<*, *>
                            ?: throw IllegalArgumentException("Dashboard presentation settings must be a map.")
                        val sumStyle = (values["sumVisualStyle"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing SUM visual style.")
                        require(sumStyle in 0..3) { "Invalid SUM visual style." }
                        val sumChooser = values["showSumLayoutChooser"] as? Boolean
                            ?: throw IllegalArgumentException("Missing SUM layout chooser visibility.")
                        val yearGridLayout = (values["yearGridLayout"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Year grid layout.")
                        require(yearGridLayout in 0..2) { "Invalid Year grid layout." }
                        val yearMonthlyAmountPresentation = (values["yearMonthlyAmountPresentation"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Year monthly amount presentation.")
                        require(yearMonthlyAmountPresentation in 0..3) { "Invalid Year monthly amount presentation." }
                        val showDayContentViewChooser = values["showDayContentViewChooser"] as? Boolean
                            ?: throw IllegalArgumentException("Missing Day view chooser visibility.")
                        val balanceChildren = values["balanceUsesChildCards"] as? Boolean
                            ?: throw IllegalArgumentException("Missing Balance child-card visibility.")
                        val balanceDayLayoutPresentation = (values["balanceDayLayoutPresentation"] as? Number)?.toInt() ?: 0
                        require(balanceDayLayoutPresentation in 0..1) { "Invalid Balance day presentation." }
                        val balanceDayPerformanceVisualPresentation = ((values["balanceDayPerformanceVisualPresentation"] as? Number)?.toInt() ?: 0).takeIf { it in 0..1 } ?: 0
                        val balanceDayRatioViewPresentation = ((values["balanceDayRatioViewPresentation"] as? Number)?.toInt() ?: 0).takeIf { it in 0..1 } ?: 0
                        val balanceDayRatioPresentation = ((values["balanceDayRatioPresentation"] as? Number)?.toInt() ?: 0).takeIf { it in 0..1 } ?: 0
                        val balanceDayFocusedPresentation = ((values["balanceDayFocusedPresentation"] as? Number)?.toInt() ?: 0).takeIf { it in 0..3 } ?: 0
                        val balanceShowFocusedDayImpact = values["balanceShowFocusedDayImpact"] as? Boolean ?: true
                        val balanceSumLayoutPresentation = (values["balanceSumLayoutPresentation"] as? Number)?.toInt() ?: 0
                        require(balanceSumLayoutPresentation in 0..1) { "Invalid Balance SUM presentation." }
                        val balanceSumFocusedPresentation = (values["balanceSumFocusedPresentation"] as? Number)?.toInt() ?: 0
                        require(balanceSumFocusedPresentation in 0..2) { "Invalid Balance SUM presentation." }
                        val balanceShowSumFocusedSupplementaryStats = values["balanceShowSumFocusedSupplementaryStats"] as? Boolean ?: true
                        val balanceMonthLayoutPresentation = (values["balanceMonthLayoutPresentation"] as? Number)?.toInt() ?: 0
                        val balanceYearLayoutPresentation = (values["balanceYearLayoutPresentation"] as? Number)?.toInt() ?: 0
                        require(balanceMonthLayoutPresentation in 0..1) { "Invalid Balance month layout presentation." }
                        require(balanceYearLayoutPresentation in 0..1) { "Invalid Balance year layout presentation." }
                        val balanceDailyCalculationMode = (values["balanceDailyCalculationMode"] as? Number)?.toInt() ?: 0
                        require(balanceDailyCalculationMode in 0..1) { "Invalid Balance daily calculation mode." }
                        val balanceHeaderGraphPresentation = (values["balanceHeaderGraphPresentation"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Balance Header graph presentation.")
                        require(balanceHeaderGraphPresentation in 0..2) { "Invalid Balance Header graph presentation." }
                        val balanceMonthlySpendingChartPresentation = (values["balanceMonthlySpendingChartPresentation"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Balance monthly spending chart presentation.")
                        require(balanceMonthlySpendingChartPresentation in 0..3) { "Invalid Balance monthly spending chart presentation." }
                        val balanceHeaderPartitionHeightPercent = (values["balanceHeaderPartitionHeightPercent"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Balance Header partition height.")
                        require(balanceHeaderPartitionHeightPercent in 0..100) { "Invalid Balance Header partition height." }
                        val balanceMonthCombinedCardPresentation = (values["balanceMonthCombinedCardPresentation"] as? Number)?.toInt()
                            ?: throw IllegalArgumentException("Missing Balance Month combined card presentation.")
                        require(balanceMonthCombinedCardPresentation in 0..1) { "Invalid Balance Month combined card presentation." }
                        val balanceHeaderGlassConfigurationJson = values["balanceHeaderGlassConfigurationJson"] as? String
                            ?: throw IllegalArgumentException("Missing Balance Header glass configuration.")
                        require(balanceHeaderGlassConfigurationJson.length <= 32768) { "Balance Header glass configuration is too large." }
                        preferences.edit()
                            .putInt("sumVisualStyle", sumStyle)
                            .putBoolean("showSumLayoutChooser", sumChooser)
                            .putInt("yearGridLayout", yearGridLayout)
                            .putInt("yearMonthlyAmountPresentation", yearMonthlyAmountPresentation)
                            .putBoolean("showDayContentViewChooser", showDayContentViewChooser)
                            .putBoolean("balanceUsesChildCards", balanceChildren)
                            .putInt("balanceDayLayoutPresentation", balanceDayLayoutPresentation)
                            .putInt("balanceDayPerformanceVisualPresentation", balanceDayPerformanceVisualPresentation)
                            .putInt("balanceDayRatioViewPresentation", balanceDayRatioViewPresentation)
                            .putInt("balanceDayRatioPresentation", balanceDayRatioPresentation)
                            .putInt("balanceDayFocusedPresentation", balanceDayFocusedPresentation)
                            .putBoolean("balanceShowFocusedDayImpact", balanceShowFocusedDayImpact)
                            .putInt("balanceSumLayoutPresentation", balanceSumLayoutPresentation)
                            .putInt("balanceSumFocusedPresentation", balanceSumFocusedPresentation)
                            .putBoolean("balanceShowSumFocusedSupplementaryStats", balanceShowSumFocusedSupplementaryStats)
                            .putInt("balanceMonthLayoutPresentation", balanceMonthLayoutPresentation)
                            .putInt("balanceYearLayoutPresentation", balanceYearLayoutPresentation)
                            .putInt("balanceDailyCalculationMode", balanceDailyCalculationMode)
                            .putInt("balanceHeaderGraphPresentation", balanceHeaderGraphPresentation)
                            .putInt("balanceMonthlySpendingChartPresentation", balanceMonthlySpendingChartPresentation)
                            .putInt("balanceHeaderPartitionHeightPercent", balanceHeaderPartitionHeightPercent)
                            .putInt("balanceMonthCombinedCardPresentation", balanceMonthCombinedCardPresentation)
                            .putString("balanceHeaderGlassConfigurationJson", balanceHeaderGlassConfigurationJson)
                            .apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        coreRevisionEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DASHBOARD_CORE_REVISION_STREAM_CHANNEL,
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    coreRevisionObservation?.cancel()
                    coreRevisionObservation = scope.launch {
                        try {
                            fluviCore.query
                                .observeCoreRevision()
                                .flowOn(Dispatchers.IO)
                                .collectLatest { revision ->
                                    events.success(mapOf("coreRevision" to revision))
                                }
                        } catch (error: Throwable) {
                            if (error is CancellationException) throw error
                            events.error(
                                "dashboard_revision_observer_error",
                                error.message ?: "Dashboard revision observer failed.",
                                null,
                            )
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    coreRevisionObservation?.cancel()
                    coreRevisionObservation = null
                }
            })
        }
    }

    override fun onResume() {
        super.onResume()
        // Signal and triage state are diagnostic data. Re-evaluate after a
        // lifecycle return without changing the financial Core revision.
        core?.let { fluviCore ->
            scope.launch(Dispatchers.IO) {
                runCatching { fluviCore.pulsePriority.reevaluateCurrent() }
            }
        }
    }

    override fun onDestroy() {
        categoryChannel?.setMethodCallHandler(null)
        manualTransactionChannel?.setMethodCallHandler(null)
        automationChannel?.setMethodCallHandler(null)
        automationPermissionChannel?.setMethodCallHandler(null)
        automationChannel = null
        automationPermissionChannel = null
        categoryChannel = null
        financialLimitChannel?.setMethodCallHandler(null)
        financialLimitChannel = null
        pulseChannel?.setMethodCallHandler(null)
        pulseChannel = null
        queryChannel?.setMethodCallHandler(null)
        queryMenuChannel?.setMethodCallHandler(null)
        queryChannel = null
        queryTaskQueue = null
        demoChannel?.setMethodCallHandler(null)
        demoChannel = null
        dashboardPresentationChannel?.setMethodCallHandler(null)
        dashboardPresentationChannel = null
        coreRevisionObservation?.cancel()
        coreRevisionObservation = null
        coreRevisionEventChannel?.setStreamHandler(null)
        coreRevisionEventChannel = null
        diagnosticEventSink = null
        diagnosticEventChannel?.setStreamHandler(null)
        diagnosticEventChannel = null
        core?.close()
        core = null
        preparedQueryGenerationOwner.clear()
        queryScope.cancel()
        scope.cancel()
        super.onDestroy()
    }

    private suspend fun handleCategoryCall(
        call: MethodCall,
        fluviCore: FluviCore,
    ): Any? = when (call.method) {
        "getCategories" -> fluviCore.categories.list().map(::categoryMap)
        "getCategoryById" -> fluviCore.categories
            .getById(requireArgument(call, "id"))
            ?.let(::categoryMap)
        "createCategory" -> {
            val id = fluviCore.categories.create(
                name = requireArgument(call, "name"),
                colorId = requireArgument(call, "colorId"),
                iconId = requireArgument(call, "iconId"),
            )
            categoryMap(requireNotNull(fluviCore.categories.getById(id)))
        }
        "updateCategory" -> {
            val id = requireArgument<String>(call, "id")
            fluviCore.categories.update(
                categoryId = id,
                name = requireArgument(call, "name"),
                colorId = requireArgument(call, "colorId"),
                iconId = requireArgument(call, "iconId"),
            )
            categoryMap(requireNotNull(fluviCore.categories.getById(id)))
        }
        "deleteCategory" -> {
            fluviCore.categories.delete(requireArgument(call, "id"))
            null
        }
        else -> throw IllegalArgumentException("Unknown category method: ${call.method}")
    }

    private suspend fun handleManualTransactionCall(
        call: MethodCall,
        fluviCore: FluviCore,
    ): Any? = when (call.method) {
        "listPartners" -> fluviCore.partners.listPartners().map(::partnerDirectoryMap)
        "getPartnerById" -> fluviCore.partners
            .getPartnerById(requireArgument(call, "partnerId"))
            ?.let(::partnerDirectoryMap)
        "getLedgerEntryById" -> ledgerEntryDetailMap(
            fluviCore.ledger.getLedgerEntryById(requireArgument(call, "entryId")),
        )
        "createManualTransaction" -> ledgerEntryDetailMap(
            fluviCore.ledger.createManual(
                CreateManualTransactionCommand(
                    partner = manualPartnerSelection(requireArguments(call)),
                    categorySelection = categorySelection(requireArguments(call)),
                    direction = LedgerDirection.valueOf(requireArgument(call, "direction")),
                    amountScaled100 = requireLong(call, "amountScaled100"),
                    bookedLocalEpochDay = requireLong(call, "bookedLocalEpochDay"),
                    bookedLocalTimeMinutes = requireInt(call, "bookedLocalTimeMinutes"),
                    occurredAtUtcMs = requireLong(call, "occurredAtUtcMs"),
                    note = call.argument<String>("note"),
                ),
            ).let { created -> fluviCore.ledger.getLedgerEntryById(created.id) },
        )
        "updateTransaction" -> ledgerEntryDetailMap(
            fluviCore.ledger.updateEntry(
                UpdateLedgerEntryCommand(
                    entryId = requireArgument(call, "entryId"),
                    expectedRevision = requireLong(call, "expectedRevision"),
                    partner = manualPartnerSelection(requireArguments(call)),
                    categorySelection = categorySelection(requireArguments(call)),
                    amountScaled100 = requireLong(call, "amountScaled100"),
                    bookedLocalEpochDay = requireLong(call, "bookedLocalEpochDay"),
                    bookedLocalTimeMinutes = requireInt(call, "bookedLocalTimeMinutes"),
                    occurredAtUtcMs = requireLong(call, "occurredAtUtcMs"),
                    note = call.argument<String>("note"),
                ),
            ).let { updated -> fluviCore.ledger.getLedgerEntryById(updated.id) },
        )
        "updatePartner" -> partnerDirectoryMap(
            fluviCore.partners.updatePartner(
                UpdatePartnerCommand(
                    partnerId = requireArgument(call, "partnerId"),
                    displayNameOverride = call.argument<String>("displayNameOverride"),
                    defaultCategoryId = requireArgument(call, "defaultCategoryId"),
                ),
            ),
        )
        "resolvePartner" -> fluviCore.partners
            .getPartnerById(requireArgument(call, "partnerId"))
            ?.let(::partnerDirectoryMap)
        else -> throw IllegalArgumentException("Unknown manual transaction method: ${call.method}")
    }

    private suspend fun handleAutomationCall(
        call: MethodCall,
        fluviCore: FluviCore,
    ): Any? = when (call.method) {
        "getDashboard" -> automationDashboardMap(fluviCore.automation.dashboard())
        "listProfiles" -> fluviCore.automation.listProfiles().map(::pushProfileMap)
        "getProfile" -> pushProfileMap(fluviCore.automation.profile(requireArgument(call, "profileId")))
        "listRules" -> fluviCore.automation.rules(requireArgument(call, "profileId")).map(::pushRuleMap)
        "listInbox" -> fluviCore.automation.inbox(
            call.argument<String>("profileId"), requireInt(call, "limit"), requireInt(call, "offset"),
        ).map(::pushInboxMap)
        "createProfile" -> pushProfileMap(fluviCore.automation.createProfile(
            CreatePushProfileCommand(
                packageName = requireArgument(call, "packageName"), appLabel = requireArgument(call, "appLabel"),
                displayName = requireArgument(call, "displayName"),
                defaultDirection = PushTransactionDirection.valueOf(requireArgument(call, "defaultDirection")),
                monitoringRequested = call.argument<Boolean>("monitoringRequested") ?: true,
                notificationAccessGranted = call.argument<Boolean>("notificationAccessGranted") ?: false,
            ),
        ))
        "updateProfile" -> pushProfileMap(fluviCore.automation.updateProfile(
            UpdatePushProfileCommand(
                profileId = requireArgument(call, "profileId"), displayName = requireArgument(call, "displayName"),
                defaultDirection = PushTransactionDirection.valueOf(requireArgument(call, "defaultDirection")),
                state = PushProfileState.valueOf(requireArgument(call, "state")),
            ),
        ))
        "deleteProfile" -> fluviCore.automation.deleteProfile(requireArgument(call, "profileId"))
        "addTrainingSample" -> fluviCore.automation.addTrainingSample(
            requireArgument(call, "profileId"), requireArgument(call, "notificationId"),
            PushSampleKind.valueOf(requireArgument(call, "sampleKind")), requireArgument(call, "spansJson"),
        )
        "createRule" -> pushRuleMap(fluviCore.automation.createRule(
            CreatePushRuleCommand(
                profileId = requireArgument(call, "profileId"), notificationId = requireArgument(call, "notificationId"),
                name = requireArgument(call, "name"), direction = LedgerDirection.valueOf(requireArgument(call, "direction")),
                priority = call.argument<Number>("priority")?.toInt() ?: 100,
                autoAcceptThreshold = call.argument<Number>("autoAcceptThreshold")?.toDouble() ?: .90,
                spans = requireArgument<List<Map<String, Any?>>>(call, "spans").map { span ->
                    PushFieldSpan(
                        start = (span["start"] as? Number)?.toInt() ?: throw IllegalArgumentException("Missing span start."),
                        endExclusive = (span["endExclusive"] as? Number)?.toInt() ?: throw IllegalArgumentException("Missing span end."),
                        role = PushFieldRole.valueOf(span["role"] as? String ?: throw IllegalArgumentException("Missing span role.")),
                    )
                },
            ),
        ))
        "backtestRule" -> pushRuleTestMap(fluviCore.automation.backtest(requireArgument(call, "ruleId")))
        "activateRule" -> pushRuleMap(fluviCore.automation.activateRule(requireArgument(call, "ruleId")))
        "approveReview" -> mapOf("ledgerEntryId" to fluviCore.automation.approveReview(
            ApprovePushReviewCommand(
                notificationId = requireArgument(call, "notificationId"), merchantName = requireArgument(call, "merchantName"),
                direction = LedgerDirection.valueOf(requireArgument(call, "direction")), amountScaled100 = requireLong(call, "amountScaled100"),
                bookedLocalEpochDay = requireLong(call, "bookedLocalEpochDay"), bookedLocalTimeMinutes = requireInt(call, "bookedLocalTimeMinutes"),
                occurredAtUtcMs = requireLong(call, "occurredAtUtcMs"), note = call.argument<String>("note"),
                trainingCorrectionJson = call.argument<String>("trainingCorrectionJson"),
            ),
        ))
        "ignoreReview" -> fluviCore.automation.ignoreReview(requireArgument(call, "notificationId"))
        "getRecurrenceDashboard" -> recurrenceDashboardMap(fluviCore.recurrences.dashboard())
        "listRecurringRules" -> fluviCore.recurrences.rules().map(::recurrenceRuleMap)
        "listRecurrenceOccurrences" -> fluviCore.recurrences.occurrences(
            call.argument<String>("status")?.let(RecurrenceOccurrenceStatus::valueOf),
            call.argument<Number>("limit")?.toInt() ?: 100,
            call.argument<Number>("offset")?.toInt() ?: 0,
        ).map(::recurrenceOccurrenceMap)
        "getRealizedRecurrenceLedgerEntryId" -> mapOf(
            "ledgerEntryId" to fluviCore.recurrences.realizedLedgerEntryId(
                requireArgument(call, "occurrenceId"),
            ),
        )
        "createRecurringRule" -> recurrenceRuleMap(fluviCore.recurrences.create(
            CreateRecurrenceRuleCommand(
                name = requireArgument(call, "name"), partnerId = requireArgument(call, "partnerId"),
                categorySelection = categorySelection(requireArguments(call)),
                direction = LedgerDirection.valueOf(requireArgument(call, "direction")),
                note = call.argument<String>("note"),
                triggerKind = RecurrenceTriggerKind.valueOf(requireArgument(call, "triggerKind")),
                amountPolicy = RecurrenceAmountPolicy.valueOf(requireArgument(call, "amountPolicy")),
                amountScaled100 = call.argument<Number>("amountScaled100")?.toLong(),
                dayOfMonth = requireInt(call, "dayOfMonth"), localTimeMinutes = requireInt(call, "localTimeMinutes"),
                startLocalEpochDay = requireLong(call, "startLocalEpochDay"), endLocalEpochDay = call.argument<Number>("endLocalEpochDay")?.toLong(),
                timezoneId = requireArgument(call, "timezoneId"), pushProfileId = call.argument<String>("pushProfileId"),
                pushRuleId = call.argument<String>("pushRuleId"),
                amountToleranceScaled100 = call.argument<Number>("amountToleranceScaled100")?.toLong() ?: 0L,
                dayWindow = call.argument<Number>("dayWindow")?.toInt() ?: 2,
            ),
        ).also { FluviRecurrenceScheduler.scheduleNext(applicationContext, fluviCore) })
        "setRecurringRuleActive" -> fluviCore.recurrences.setRuleActive(requireArgument(call, "ruleId"), requireArgument(call, "isActive")).also {
            FluviRecurrenceScheduler.scheduleNext(applicationContext, fluviCore)
        }
        "archiveRecurringRule" -> fluviCore.recurrences.archiveRule(requireArgument(call, "ruleId")).also {
            FluviRecurrenceScheduler.scheduleNext(applicationContext, fluviCore)
        }
        "setShowPendingGhosts" -> fluviCore.recurrences.setShowPendingGhostsInLedger(requireArgument(call, "show"))
        "skipRecurrenceOccurrence" -> fluviCore.recurrences.skip(requireArgument(call, "occurrenceId"))
        "updateRecurrenceOccurrence" -> recurrenceOccurrenceMap(fluviCore.recurrences.updateOccurrence(
            UpdateOccurrenceOverrideCommand(
                occurrenceId = requireArgument(call, "occurrenceId"),
                expectedAmountScaled100 = call.argument<Number>("expectedAmountScaled100")?.toLong(),
                expectedLocalEpochDay = call.argument<Number>("expectedLocalEpochDay")?.toLong(),
                expectedLocalTimeMinutes = call.argument<Number>("expectedLocalTimeMinutes")?.toInt(),
                partnerId = call.argument<String>("partnerId"),
                categorySelection = (call.argument<Map<String, Any?>>("categorySelection"))?.let { raw ->
                    categorySelection(mapOf("categorySelection" to raw))
                },
                noteChanged = call.argument<Boolean>("noteChanged") ?: false,
                note = call.argument<String>("note"),
            ),
        ))
        "realizeDueRecurrences" -> fluviCore.recurrences.realizeDueTimeOccurrences().also {
            FluviRecurrenceScheduler.scheduleNext(applicationContext, fluviCore)
        }
        else -> throw IllegalArgumentException("Unknown automation method: ${call.method}")
    }

    private fun pushProfileMap(profile: com.fluvi.core.model.FluviPushProfile): Map<String, Any?> = mapOf(
        "profileId" to profile.profileId, "packageName" to profile.packageName, "appLabel" to profile.appLabel,
        "displayName" to profile.displayName, "defaultDirection" to profile.defaultDirection.name,
        "state" to profile.state.name, "ruleCount" to profile.ruleCount, "inboxCount" to profile.inboxCount,
        "revision" to profile.revision,
    )

    private fun pushRuleMap(rule: com.fluvi.core.model.FluviPushRule): Map<String, Any?> = mapOf(
        "ruleId" to rule.ruleId, "profileId" to rule.profileId, "name" to rule.name, "direction" to rule.direction.name,
        "state" to rule.state.name, "version" to rule.version, "priority" to rule.priority,
        "autoAcceptThreshold" to rule.autoAcceptThreshold,
    )

    private fun pushInboxMap(item: com.fluvi.core.model.FluviNotificationInboxItem): Map<String, Any?> = mapOf(
        "notificationId" to item.notificationId, "profileId" to item.profileId, "sourcePackageName" to item.sourcePackageName,
        "sourceAppLabel" to item.sourceAppLabel, "title" to item.title, "rawText" to item.rawText,
        "receivedAtUtcMs" to item.receivedAtUtcMs, "parseStatus" to item.parseStatus.name,
        "processingStatus" to item.processingStatus.name, "trainingStatus" to item.trainingStatus.name,
        "reviewStatus" to item.reviewStatus.name, "confidence" to item.confidence,
        "suggestedPayloadJson" to item.suggestedPayloadJson, "diagnosticsJson" to item.diagnosticsJson,
        "ledgerEntryId" to item.ledgerEntryId,
    )

    private fun pushRuleTestMap(report: com.fluvi.core.model.PushRuleTestReport): Map<String, Any?> = mapOf(
        "ruleId" to report.ruleId, "matchedCount" to report.matchedCount, "reviewCount" to report.reviewCount,
        "rejectedCount" to report.rejectedCount, "conflictedCount" to report.conflictedCount,
        "activationReady" to report.activationReady,
    )

    private fun automationDashboardMap(snapshot: com.fluvi.core.model.FluviPushDashboardSnapshot): Map<String, Any?> = mapOf(
        "profiles" to snapshot.profiles.map(::pushProfileMap), "pendingReviewCount" to snapshot.pendingReviewCount,
        "capturedLast30Days" to snapshot.capturedLast30Days, "recentInbox" to snapshot.recentInbox.map(::pushInboxMap),
    )

    private fun recurrenceRuleMap(rule: com.fluvi.core.model.FluviRecurrenceRule): Map<String, Any?> = mapOf(
        "ruleId" to rule.ruleId, "name" to rule.name, "partnerId" to rule.partnerId, "categoryId" to rule.categoryId,
        "categoryAssignmentMode" to rule.categoryAssignmentMode.name, "direction" to rule.direction.name,
        "note" to rule.note, "triggerKind" to rule.triggerKind.name, "amountPolicy" to rule.amountPolicy.name,
        "amountScaled100" to rule.amountScaled100, "dayOfMonth" to rule.dayOfMonth,
        "localTimeMinutes" to rule.localTimeMinutes, "startLocalEpochDay" to rule.startLocalEpochDay,
        "endLocalEpochDay" to rule.endLocalEpochDay, "timezoneId" to rule.timezoneId, "isActive" to rule.isActive,
        "ruleVersion" to rule.ruleVersion,
    )

    private fun recurrenceOccurrenceMap(value: com.fluvi.core.model.FluviRecurrenceOccurrence): Map<String, Any?> = mapOf(
        "occurrenceId" to value.occurrenceId, "ruleId" to value.ruleId, "occurrenceKey" to value.occurrenceKey,
        "expectedLocalEpochDay" to value.expectedLocalEpochDay, "expectedLocalTimeMinutes" to value.expectedLocalTimeMinutes,
        "expectedAtUtcMs" to value.expectedAtUtcMs, "timezoneId" to value.timezoneId, "partnerId" to value.partnerId,
        "categoryId" to value.categoryId, "categoryAssignmentMode" to value.categoryAssignmentMode.name,
        "direction" to value.direction.name, "expectedAmountScaled100" to value.expectedAmountScaled100,
        "amountPolicy" to value.amountPolicy.name, "note" to value.note, "triggerKind" to value.triggerKind.name,
        "status" to value.status.name, "realizationKind" to value.realizationKind?.name, "resolvedAtUtcMs" to value.resolvedAtUtcMs,
    )

    private fun recurrenceDashboardMap(value: com.fluvi.core.model.FluviRecurrenceDashboardSnapshot): Map<String, Any?> = mapOf(
        "rules" to value.rules.map(::recurrenceRuleMap), "pendingCount" to value.pendingCount,
        "dueCount" to value.dueCount, "realizedCount" to value.realizedCount,
        "showPendingGhostsInLedger" to value.showPendingGhostsInLedger,
    )

    private fun requireArguments(call: MethodCall): Map<String, Any?> =
        requireNotNull(call.arguments as? Map<String, Any?>) {
            "Manual transaction arguments must be a map."
        }

    private fun manualPartnerSelection(arguments: Map<String, Any?>): ManualTransactionPartnerSelection {
        val raw = requireNotNull(arguments["partner"] as? Map<*, *>) {
            "Missing manual transaction partner."
        }
        val kind = raw["kind"] as? String ?: throw IllegalArgumentException("Partner kind is required.")
        return when (kind) {
            "existing" -> ManualTransactionPartnerSelection.Existing(
                raw["partnerId"] as? String ?: throw IllegalArgumentException("Partner ID is required."),
            )
            "new" -> ManualTransactionPartnerSelection.New(
                displayName = raw["displayName"] as? String
                    ?: throw IllegalArgumentException("Partner name is required."),
                defaultCategoryId = raw["defaultCategoryId"] as? String
                    ?: throw IllegalArgumentException("Partner default category is required."),
            )
            else -> throw IllegalArgumentException("Unknown manual partner kind: $kind")
        }
    }

    private fun categorySelection(arguments: Map<String, Any?>): LedgerCategorySelection {
        val raw = requireNotNull(arguments["categorySelection"] as? Map<*, *>) {
            "Missing category selection."
        }
        return when (raw["mode"] as? String) {
            "partnerDefault" -> LedgerCategorySelection.PartnerDefault
            "entryOverride" -> LedgerCategorySelection.EntryOverride(
                raw["categoryId"] as? String
                    ?: throw IllegalArgumentException("Override category is required."),
            )
            else -> throw IllegalArgumentException("Unknown category selection mode.")
        }
    }

    private fun requireLong(call: MethodCall, key: String): Long =
        (call.argument<Number>(key) ?: throw IllegalArgumentException("Missing $key.")).toLong()

    private fun requireInt(call: MethodCall, key: String): Int =
        (call.argument<Number>(key) ?: throw IllegalArgumentException("Missing $key.")).toInt()

    private fun partnerDirectoryMap(partner: FluviPartnerDirectoryEntry): Map<String, Any?> = mapOf(
        "partnerId" to partner.partnerId,
        "displayName" to partner.displayName,
        "originalName" to partner.originalName,
        "defaultCategoryId" to partner.defaultCategoryId,
        "defaultCategoryName" to partner.defaultCategoryName,
        "categoryColorId" to partner.categoryColorId,
        "categoryIconId" to partner.categoryIconId,
        "isUncategorized" to partner.isUncategorized,
        "searchNames" to partner.searchNames,
    )

    private fun ledgerEntryDetailMap(entry: FluviLedgerEntryDetail): Map<String, Any?> = mapOf(
        "entryId" to entry.entryId,
        "partnerId" to entry.partnerId,
        "categoryId" to entry.categoryId,
        "categoryAssignmentMode" to entry.categoryAssignmentMode.name,
        "direction" to entry.direction.name,
        "amountScaled100" to entry.amountScaled100,
        "bookedLocalEpochDay" to entry.bookedLocalEpochDay,
        "bookedLocalTimeMinutes" to entry.bookedLocalTimeMinutes,
        "occurredAtUtcMs" to entry.occurredAtUtcMs,
        "note" to entry.note,
        "originKind" to entry.originKind.name,
        "notificationInboxId" to entry.notificationInboxId,
        "recurrenceOccurrenceId" to entry.recurrenceOccurrenceId,
        "revision" to entry.revision,
    )

    private suspend fun handleFinancialLimitCall(
        call: MethodCall,
        fluviCore: FluviCore,
    ): Any? = when (call.method) {
        "getFinancialLimit" -> fluviCore.financialLimits
            .get(financialLimitKey(call))
            ?.let(::financialLimitMap)
        "listFinancialLimits" -> fluviCore.financialLimits.list().map(::financialLimitMap)
        "upsertFinancialLimit" -> {
            val amount = requireAmountScaled100(call)
            fluviCore.financialLimits.upsert(financialLimitKey(call), amount)
                .let(::financialLimitMap)
        }
        "upsertFinancialLimitsBatch" -> {
            val values = requireArgument<List<Map<String, Any?>>>(call, "values")
            require(values.isNotEmpty())
            fluviCore.financialLimits.upsertBatch(values.map { value ->
                financialLimitKey(value) to requireAmountScaled100(value)
            }).map(::financialLimitMap)
        }
        "deleteFinancialLimit" -> fluviCore.financialLimits.delete(financialLimitKey(call))
        else -> throw IllegalArgumentException("Unknown financial limit method: ${call.method}")
    }

    private suspend fun handlePulseCall(
        call: MethodCall,
        fluviCore: FluviCore,
    ): Any? = when (call.method) {
        "getDashboard" -> pulsePriorityDashboardMap(
            fluviCore.pulsePriority.dashboard(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
            ),
        )
        "getSignalInspection" -> pulseSignalInspectionMap(
            fluviCore.pulseSignals.inspect(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
                indicatorId = requireArgument(call, "indicatorId"),
                historyLimit = call.argument<Number>("historyLimit")?.toInt() ?: 30,
            ),
        )
        "getSituations" -> mapOf(
            "situations" to fluviCore.pulseTriage.history(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
            ).map(::pulseSituationMap),
        )
        "getTriageInspection" -> pulseTriageInspectionMap(
            fluviCore.pulseTriage.inspection(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
                situationKey = requireArgument(call, "situationKey"),
                historyLimit = call.argument<Number>("historyLimit")?.toInt() ?: 30,
                historyOffset = call.argument<Number>("historyOffset")?.toInt() ?: 0,
            ),
        )
        "getPriorityInspection" -> pulsePriorityInspectionMap(
            fluviCore.pulsePriority.inspection(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
                historyLimit = call.argument<Number>("historyLimit")?.toInt() ?: 30,
                historyOffset = call.argument<Number>("historyOffset")?.toInt() ?: 0,
            ),
        )
        "getSelectedStoryPreview" -> pulseStoryInspectionMap(
            fluviCore.pulseStory.storyInspection(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
                situationKey = null,
            ),
        )
        "getCandidateStoryPreview", "getStoryInspection" -> pulseStoryInspectionMap(
            fluviCore.pulseStory.storyInspection(
                year = requireInt(call, "year"),
                month = requireInt(call, "month"),
                situationKey = requireArgument(call, "situationKey"),
            ),
        )
        "setThreshold" -> {
            fluviCore.pulseThresholds.set(
                indicatorId = requireArgument(call, "indicatorId"),
                targetKey = call.argument<String>("targetKey") ?: "",
                thresholdKey = requireArgument(call, "thresholdKey"),
                value = (call.argument<Number>("value")
                    ?: throw IllegalArgumentException("Missing Pulse threshold value.")).toDouble(),
            )
            null
        }
        "resetThreshold" -> {
            fluviCore.pulseThresholds.reset(
                indicatorId = requireArgument(call, "indicatorId"),
                targetKey = call.argument<String>("targetKey") ?: "",
                thresholdKey = requireArgument(call, "thresholdKey"),
            )
            null
        }
        "setSubscriptionSource" -> {
            fluviCore.pulseSources.setSubscriptionSource(
                targetKey = requireArgument(call, "targetKey"),
                selected = requireArgument<Boolean>(call, "selected"),
            )
            null
        }
        else -> throw IllegalArgumentException("Unknown Pulse method: ${call.method}")
    }

    private fun pulseDashboardMap(snapshot: PulseDashboardSnapshot): Map<String, Any?> = mapOf(
        "year" to snapshot.year,
        "month" to snapshot.month,
        "coreRevision" to snapshot.coreRevision,
        "generatedAtUtcMs" to snapshot.generatedAtUtcMs,
        "indicators" to snapshot.indicators.map(::pulseIndicatorMap),
        "subscriptionOptions" to snapshot.subscriptionOptions.map { option ->
            mapOf(
                "targetKey" to option.targetKey,
                "labelHu" to option.labelHu,
                "kind" to option.kind,
                "isSelected" to option.isSelected,
            )
        },
    )

    private fun pulseTriageDashboardMap(snapshot: PulseTriageDashboardSnapshot): Map<String, Any?> =
        pulseDashboardMap(snapshot.dashboard).toMutableMap().apply {
            this["situations"] = snapshot.situations.map(::pulseSituationMap)
            this["signalGeneration"] = snapshot.frame.signalGeneration
            this["triageHistorical"] = snapshot.frame.evaluationMode.name == "historicalInspection"
        }

    private fun pulsePriorityDashboardMap(snapshot: PulsePriorityDashboardSnapshot): Map<String, Any?> =
        pulseTriageDashboardMap(snapshot.triage).toMutableMap().apply {
            this["priority"] = pulsePriorityFrameMap(snapshot.priority)
        }

    private fun pulseIndicatorMap(snapshot: PulseIndicatorSnapshot): Map<String, Any?> = mapOf(
        "id" to snapshot.id.stableId,
        "group" to snapshot.id.group.name,
        "titleHu" to snapshot.id.titleHu,
        "descriptionHu" to snapshot.id.descriptionHu,
        "unit" to snapshot.id.unit.name,
        "chartKind" to snapshot.id.chartKind.name,
        "availability" to snapshot.availability.name,
        "value" to snapshot.value,
        "secondaryValue" to snapshot.secondaryValue,
        "summaryHu" to snapshot.summaryHu,
        "missingReasonsHu" to snapshot.missingReasonsHu,
        "sampleCount" to snapshot.sampleCount,
        "sources" to snapshot.sources,
        "signalMetricKey" to snapshot.signalMetricKey,
        "signalMetricValue" to snapshot.signalMetricValue,
        "signalSummaries" to snapshot.signalSummaries.map { summary ->
            mapOf(
                "activityState" to summary.activityState.name,
                "strength" to summary.strength?.name,
                "dataQuality" to summary.dataQuality.name,
                "activeSignalCount" to summary.activeSignalCount,
                "totalSignalCount" to summary.totalSignalCount,
            )
        },
        "thresholds" to snapshot.thresholds.map { threshold ->
            mapOf(
                "key" to threshold.key,
                "value" to threshold.value,
                "isUserDefined" to threshold.isUserDefined,
                "definition" to mapOf(
                    "key" to threshold.definition.key,
                    "unit" to threshold.definition.unit.name,
                    "defaultValue" to threshold.definition.defaultValue,
                    "minimum" to threshold.definition.minimum,
                    "maximum" to threshold.definition.maximum,
                    "step" to threshold.definition.step,
                ),
            )
        },
        "series" to snapshot.series.map { series ->
            mapOf(
                "key" to series.key,
                "labelHu" to series.labelHu,
                "points" to series.points.map { point ->
                    mapOf(
                        "x" to point.x,
                        "label" to point.label,
                        "targetKey" to point.targetKey,
                        "actual" to point.actual,
                        "baseline" to point.baseline,
                        "momentum" to point.momentum,
                        "reference" to point.reference,
                    )
                },
            )
        },
    )

    private fun pulseSignalInspectionMap(
        inspections: List<PulseSignalInspectionSnapshot>,
    ): Map<String, Any?> = mapOf(
        "signals" to inspections.map { inspection ->
            val signal = inspection.signal
            mapOf(
                "signalKey" to signal.signalKey,
                "indicatorId" to signal.indicatorId.stableId,
                "targetKey" to signal.targetKey,
                "periodKey" to signal.periodKey,
                "scenarioKey" to signal.scenarioKey,
                "measuredValue" to signal.measuredValue,
                "evaluatedMetricKey" to signal.evaluatedMetricKey,
                "thresholdValue" to signal.thresholdValue,
                "comparisonOperator" to signal.comparisonOperator.name,
                "availability" to signal.availability.name,
                "activityState" to signal.activityState.name,
                "strength" to signal.strength?.name,
                "dataQuality" to signal.dataQuality.name,
                "observedDuration" to signal.observedDuration,
                "trendDirection" to signal.trendDirection,
                "firstObservedAtUtcMs" to signal.firstObservedAtUtcMs,
                "lastEvaluatedAtUtcMs" to signal.lastEvaluatedAtUtcMs,
                "lastMaterialChangeAtUtcMs" to signal.lastMaterialChangeAtUtcMs,
                "sourceCoreRevision" to signal.sourceCoreRevision,
                "configRevision" to signal.configRevision,
                "evaluationFingerprint" to signal.evaluationFingerprint,
                "trace" to mapOf(
                    "measuredMetricKey" to signal.trace.measuredMetricKey,
                    "measuredValue" to signal.trace.measuredValue,
                    "thresholdValue" to signal.trace.thresholdValue,
                    "comparisonOperator" to signal.trace.comparisonOperator.name,
                    "thresholdConditionMet" to signal.trace.thresholdConditionMet,
                    "confirmationRequired" to signal.trace.confirmationRequired,
                    "confirmationCount" to signal.trace.confirmationCount,
                    "missingInputsHu" to signal.trace.missingInputsHu,
                    "explanationHu" to signal.trace.explanationHu,
                ),
                "evidence" to mapOf(
                    "situationKey" to signal.evidence.situationKey,
                    "evidenceFamily" to signal.evidence.evidenceFamily,
                    "dependencyIds" to signal.evidence.dependencyIds,
                    "affectedTarget" to signal.evidence.affectedTarget,
                    "actualImpactMinor" to signal.evidence.actualImpactMinor,
                    "projectedImpactMinor" to signal.evidence.projectedImpactMinor,
                    "affectedBudgetMinor" to signal.evidence.affectedBudgetMinor,
                    "affectedObligationMinor" to signal.evidence.affectedObligationMinor,
                    "impactRatio" to signal.evidence.impactRatio,
                    "provenance" to signal.evidence.provenance?.let { provenance ->
                        mapOf(
                            "evidenceKey" to provenance.evidenceKey,
                            "sourceKind" to provenance.sourceKind.name,
                            "sourceFactKeys" to provenance.sourceFactKeys.sorted(),
                            "upstreamEvidenceKeys" to provenance.upstreamEvidenceKeys.sorted(),
                            "calculationKey" to provenance.calculationKey,
                            "observationWindowKey" to provenance.observationWindowKey,
                            "scenarioKey" to provenance.scenarioKey,
                            "sourceRevision" to provenance.sourceRevision,
                        )
                    },
                ),
                "events" to inspection.events.map { event ->
                    mapOf(
                        "eventId" to event.eventId,
                        "kind" to event.kind.name,
                        "previousState" to event.previousState?.name,
                        "nextState" to event.nextState.name,
                        "previousStrength" to event.previousStrength?.name,
                        "nextStrength" to event.nextStrength?.name,
                        "measuredValue" to event.measuredValue,
                        "thresholdValue" to event.thresholdValue,
                        "timestampUtcMs" to event.timestampUtcMs,
                        "cause" to event.cause,
                    )
                },
                "lastPersistedState" to inspection.lastPersistedState?.let { state ->
                    mapOf(
                        "activityState" to state.activityState.name,
                        "strength" to state.strength?.name,
                        "lastEvaluatedAtUtcMs" to state.lastEvaluatedAtUtcMs,
                    )
                },
            )
        },
    )

    private fun pulseTriageInspectionMap(snapshot: PulseSituationInspectionSnapshot): Map<String, Any?> = mapOf(
        "situation" to pulseSituationMap(snapshot.situation),
        "events" to snapshot.events.map { event ->
            mapOf(
                "eventId" to event.eventId,
                "situationKey" to event.situationKey,
                "kind" to event.kind.name,
                "previousState" to event.previousState?.name,
                "nextState" to event.nextState.name,
                "previousFormationRule" to event.previousFormationRule,
                "nextFormationRule" to event.nextFormationRule,
                "previousEvidenceCount" to event.previousEvidenceCount,
                "nextEvidenceCount" to event.nextEvidenceCount,
                "causeCode" to event.causeCode,
                "explanationHu" to event.explanationHu,
                "sourceCoreRevision" to event.sourceCoreRevision,
                "policyVersion" to event.policyVersion,
                "transitionSequence" to event.transitionSequence,
                "createdAtUtcMs" to event.createdAtUtcMs,
            )
        },
    )

    private fun pulsePriorityInspectionMap(snapshot: PulsePriorityInspectionSnapshot): Map<String, Any?> = mapOf(
        "priority" to pulsePriorityFrameMap(snapshot.frame),
        "situations" to snapshot.situations.map(::pulseSituationMap),
        "events" to snapshot.events.map { event ->
            mapOf(
                "eventId" to event.eventId,
                "kind" to event.kind.name,
                "previousSelectedSituationKey" to event.previousSelectedSituationKey,
                "nextSelectedSituationKey" to event.nextSelectedSituationKey,
                "previousScore" to event.previousScore,
                "nextScore" to event.nextScore,
                "selectionReason" to event.selectionReason,
                "sourceCoreRevision" to event.sourceCoreRevision,
                "sourceTriageFrameId" to event.sourceTriageFrameId,
                "policyVersion" to event.policyVersion,
                "transitionSequence" to event.transitionSequence,
                "createdAtUtcMs" to event.createdAtUtcMs,
            )
        },
    )

    private fun pulseStoryInspectionMap(snapshot: PulseStoryInspectionSnapshot): Map<String, Any?> = mapOf(
        "priorityFrameId" to snapshot.priorityFrameId,
        "sourceCoreRevision" to snapshot.sourceCoreRevision,
        "facts" to (snapshot.facts?.facts?.map { fact ->
            mapOf(
                "factKey" to fact.factKey,
                "kind" to fact.kind.name,
                "sourceSignalKeys" to fact.sourceSignalKeys.sorted(),
                "sourceEvidenceKeys" to fact.sourceEvidenceKeys.sorted(),
                "sourceFactKeys" to fact.sourceFactKeys.sorted(),
                "certainty" to fact.certainty.name,
                "amountMinor" to fact.amountMinor,
                "decimalValue" to fact.decimalValue,
                "countValue" to fact.countValue,
                "dueLocalEpochDay" to fact.dueLocalEpochDay,
                "periodKey" to fact.periodKey,
                "sourceCoreRevision" to fact.sourceCoreRevision,
                "includedInForecast" to fact.includedInForecast,
            )
        } ?: emptyList<Map<String, Any?>>()),
        "result" to mapOf(
            "status" to snapshot.result.status.name,
            "reasonCode" to snapshot.result.reasonCode,
            "explanationHu" to snapshot.result.explanationHu,
            "draft" to snapshot.result.draft?.let { draft ->
                mapOf(
                    "storyKey" to draft.storyKey,
                    "situationKey" to draft.situationKey,
                    "candidateKind" to draft.candidateKind.name,
                    "claimType" to draft.claimType.name,
                    "headline" to draft.headline,
                    "detail" to draft.detail,
                    "priorityFrameId" to draft.priorityFrameId,
                    "sourceCoreRevision" to draft.sourceCoreRevision,
                    "templateVersion" to draft.templateVersion,
                    "contentFingerprint" to draft.contentFingerprint,
                    "materialFingerprint" to draft.materialFingerprint,
                    "evaluationMode" to draft.evaluationMode.name,
                    "generatedAtUtcMs" to draft.generatedAtUtcMs,
                    "fragments" to draft.fragments.map { fragment ->
                        mapOf(
                            "role" to fragment.role.name,
                            "templateId" to fragment.templateId,
                            "renderedText" to fragment.renderedText,
                            "sourceSignalKeys" to fragment.sourceSignalKeys,
                            "sourceEvidenceKeys" to fragment.sourceEvidenceKeys,
                            "sourceFactKeys" to fragment.sourceFactKeys,
                            "certainty" to fragment.certainty.name,
                        )
                    },
                    "exclusions" to draft.exclusions.map { exclusion ->
                        mapOf(
                            "factKey" to exclusion.factKey,
                            "sourceSignalKey" to exclusion.sourceSignalKey,
                            "sourceEvidenceKey" to exclusion.sourceEvidenceKey,
                            "reasonCode" to exclusion.reasonCode,
                            "explanationHu" to exclusion.explanationHu,
                        )
                    },
                )
            },
        ),
    )

    private fun pulsePriorityFrameMap(frame: PulsePriorityFrame): Map<String, Any?> = mapOf(
        "sourceCoreRevision" to frame.sourceCoreRevision,
        "sourceTriageFrameId" to frame.sourceTriageFrameId,
        "policyVersion" to frame.policyVersion,
        "evaluationMode" to frame.evaluationMode.name,
        "evaluatedAtUtcMs" to frame.evaluatedAtUtcMs,
        "selectedSituationKey" to frame.selectedSituationKey,
        "selectionReason" to frame.selectionReason?.let { reason ->
            mapOf(
                "reasonCode" to reason.reasonCode,
                "explanationHu" to reason.explanationHu,
                "tieBreakApplied" to reason.tieBreakApplied,
                "tieBreakExplanationHu" to reason.tieBreakExplanationHu,
            )
        },
        "rankedCandidates" to frame.rankedCandidates.map(::pulsePriorityCandidateMap),
    )

    private fun pulsePriorityCandidateMap(candidate: PulsePriorityCandidate): Map<String, Any?> = mapOf(
        "situationKey" to candidate.situation.situationKey,
        "kind" to candidate.kind.name,
        "leadingEvidenceKey" to candidate.leadingEvidenceKey,
        "leadingSignalKey" to candidate.leadingSignalKey,
        "leadingIndicatorId" to candidate.leadingIndicatorId,
        "basePriority" to candidate.basePriority,
        "rawTotal" to candidate.rawTotal,
        "finalScore" to candidate.finalScore,
        "rank" to candidate.rank,
        "sourceSituationVersion" to candidate.sourceSituationVersion,
        "policyVersion" to candidate.policyVersion,
        "modifiers" to candidate.modifiers.map { modifier ->
            mapOf(
                "id" to modifier.id,
                "value" to modifier.value,
                "applied" to modifier.applied,
                "reasonCode" to modifier.reasonCode,
                "explanationHu" to modifier.explanationHu,
                "observedImpactMinor" to modifier.observedImpactMinor,
            )
        },
        "tieBreakFacts" to mapOf(
            "dueLocalEpochDay" to candidate.tieBreakFacts.dueLocalEpochDay,
            "dueDistanceDays" to candidate.tieBreakFacts.dueDistanceDays,
            "severityRank" to candidate.tieBreakFacts.severityRank,
            "comparableImpactMinor" to candidate.tieBreakFacts.comparableImpactMinor,
            "lastMaterialChangeAtUtcMs" to candidate.tieBreakFacts.lastMaterialChangeAtUtcMs,
        ),
    )

    private fun pulseSituationMap(snapshot: PulseSituationSnapshot): Map<String, Any?> = mapOf(
        "situationKey" to snapshot.situationKey,
        "domain" to snapshot.domain.name,
        "titleHu" to snapshot.domain.titleHu,
        "targetKey" to snapshot.targetKey,
        "periodKey" to snapshot.periodKey,
        "state" to snapshot.state.name,
        "formationRule" to snapshot.formationRule,
        "relatedSignalKeys" to snapshot.relatedSignalKeys,
        "leadingSignalKey" to snapshot.leadingSignalKey,
        "supportingSignalKeys" to snapshot.supportingSignalKeys,
        "independentEvidenceCount" to snapshot.independentEvidenceCount,
        "sourceCoreRevision" to snapshot.sourceCoreRevision,
        "sourceSignalGeneration" to snapshot.sourceSignalGeneration,
        "policyVersion" to snapshot.policyVersion,
        "firstObservedAtUtcMs" to snapshot.firstObservedAtUtcMs,
        "lastEvaluatedAtUtcMs" to snapshot.lastEvaluatedAtUtcMs,
        "lastMaterialChangeAtUtcMs" to snapshot.lastMaterialChangeAtUtcMs,
        "historicalInspection" to snapshot.historicalInspection,
        "evidenceUnits" to snapshot.evidenceUnits.map { unit ->
            mapOf(
                "evidenceKey" to unit.evidenceKey,
                "sourceSignalKeys" to unit.sourceSignalKeys.sorted(),
                "sourceFactKeys" to unit.sourceFactKeys.sorted(),
                "evidenceFamily" to unit.evidenceFamily,
                "strength" to unit.strength?.name,
                "role" to unit.role.name,
                "independence" to unit.independence.name,
                "countableForFormation" to unit.countableForFormation,
                "standaloneEligible" to unit.standaloneEligible,
                "reasonCodes" to unit.reasonCodes,
                "indicatorId" to unit.indicatorId,
                "titleHu" to unit.titleHu,
                "measuredValue" to unit.measuredValue,
                "dataQuality" to unit.dataQuality.name,
                "actualImpactMinor" to unit.actualImpactMinor,
                "projectedImpactMinor" to unit.projectedImpactMinor,
                "affectedBudgetMinor" to unit.affectedBudgetMinor,
                "affectedObligationMinor" to unit.affectedObligationMinor,
                "impactRatio" to unit.impactRatio,
                "dueLocalEpochDay" to unit.dueLocalEpochDay,
            )
        },
        "decisionTrace" to mapOf(
            "situationKey" to snapshot.decisionTrace.situationKey,
            "matchedRule" to snapshot.decisionTrace.matchedRule,
            "relatedSignalCount" to snapshot.decisionTrace.relatedSignalCount,
            "independentEvidenceCount" to snapshot.decisionTrace.independentEvidenceCount,
            "countedEvidenceKeys" to snapshot.decisionTrace.countedEvidenceKeys,
            "supportingEvidenceKeys" to snapshot.decisionTrace.supportingEvidenceKeys,
            "missingRequirements" to snapshot.decisionTrace.missingRequirements,
            "explanationHu" to snapshot.decisionTrace.explanationHu,
            "policyVersion" to snapshot.decisionTrace.policyVersion,
            "excludedEvidence" to snapshot.decisionTrace.excludedEvidence.map { exclusion ->
                mapOf(
                    "evidenceKey" to exclusion.evidenceKey,
                    "signalKey" to exclusion.signalKey,
                    "reasonCode" to exclusion.reasonCode,
                    "explanationHu" to exclusion.explanationHu,
                )
            },
            "evaluatedRules" to snapshot.decisionTrace.evaluatedRules.map { rule ->
                mapOf(
                    "ruleId" to rule.ruleId,
                    "applicable" to rule.applicable,
                    "passed" to rule.passed,
                    "requiredEvidenceCount" to rule.requiredEvidenceCount,
                    "actualEvidenceCount" to rule.actualEvidenceCount,
                    "requiredStrength" to rule.requiredStrength?.name,
                    "dataQualityPassed" to rule.dataQualityPassed,
                    "materialImpactPassed" to rule.materialImpactPassed,
                    "reasonCodes" to rule.reasonCodes,
                )
            },
        ),
    )

    private fun financialLimitKey(call: MethodCall): FluviFinancialLimitKey {
        return financialLimitKey(requireNotNull(call.arguments as? Map<String, Any?>))
    }

    private fun financialLimitKey(arguments: Map<String, Any?>): FluviFinancialLimitKey {
        val direction = LedgerDirection.valueOf(requireMapArgument<String>(arguments, "direction"))
        val target = when (requireMapArgument<String>(arguments, "targetKind")) {
            "aggregate" -> FluviFinancialLimitTarget.Aggregate
            "category" -> FluviFinancialLimitTarget.Category(
                requireMapArgument(arguments, "categoryId"),
            )
            else -> throw IllegalArgumentException("Unknown financial-limit target kind.")
        }
        val period = when (requireMapArgument<String>(arguments, "periodKind")) {
            "base" -> FluviFinancialLimitPeriod.BaseMonthlyRevision(
                requireMapArgument(arguments, "year"),
                requireMapArgument(arguments, "month"),
            )
            "month" -> FluviFinancialLimitPeriod.MonthOverride(
                requireMapArgument(arguments, "year"),
                requireMapArgument(arguments, "month"),
            )
            else -> throw IllegalArgumentException("Unknown financial-limit period kind.")
        }
        return FluviFinancialLimitKey(direction, target, period)
    }

    private fun requireAmountScaled100(call: MethodCall): Long {
        val value = call.argument<Number>("amountScaled100")
            ?: throw IllegalArgumentException("Missing financial-limit amount.")
        return value.toLong().also { require(it >= 0L) }
    }

    private fun requireAmountScaled100(arguments: Map<String, Any?>): Long =
        (arguments["amountScaled100"] as? Number)?.toLong()
            ?.also { require(it >= 0L) }
            ?: throw IllegalArgumentException("Missing financial-limit amount.")

    @Suppress("UNCHECKED_CAST")
    private fun <T> requireMapArgument(arguments: Map<String, Any?>, key: String): T =
        arguments[key] as? T
            ?: throw IllegalArgumentException("Missing financial-limit $key.")

    private fun financialLimitMap(limit: com.fluvi.core.model.FluviFinancialLimit): Map<String, Any?> = mapOf(
        "direction" to limit.key.direction.name,
        "targetKind" to limit.key.targetKind.name,
        "categoryId" to limit.key.categoryId,
        "periodKind" to limit.key.periodKind.name,
        "year" to limit.key.year,
        "month" to limit.key.month,
        "amountScaled100" to limit.amountScaled100,
        "createdAtUtcMs" to limit.createdAtUtcMs,
        "updatedAtUtcMs" to limit.updatedAtUtcMs,
    )

    private data class PreparedQueryRequestIdentity(
        val generation: Long,
        val direction: LedgerDirection?,
    )

    private fun dispatchQueryCall(
        call: MethodCall,
        result: MethodChannel.Result,
        fluviCore: FluviCore,
    ) {
        val handlerEnteredAtNanos = System.nanoTime()
        if (call.method == "cancelDashboardPreparedIndex") {
            val generation = try {
                val arguments = DashboardQueryArguments.requireMap(
                    call.arguments,
                    "prepared Query cancellation arguments",
                )
                DashboardQueryArguments.requestGeneration(arguments)
            } catch (error: IllegalArgumentException) {
                result.error("validation", error.message ?: "Invalid Query cancellation.", null)
                return
            }
            val cancelled = preparedQueryGenerationOwner.cancel(generation)
            if (cancelled != null) {
                emitDiagnostic(
                    stage = "INDEX_PARTITION_BUILD_CANCEL_REQUESTED",
                    message = "INDEX_PARTITION_BUILD_CANCEL_REQUESTED",
                    scope = "generation=${cancelled.generation} " +
                        "direction=${cancelled.direction?.name ?: "whole"}",
                )
            }
            result.success(null)
            return
        }

        val identity = try {
            preparedQueryRequestIdentity(call)
        } catch (error: IllegalArgumentException) {
            result.error("validation", error.message ?: "Invalid dashboard query.", null)
            return
        }
        lateinit var job: Job
        job = queryScope.launch(start = CoroutineStart.LAZY) {
            try {
                val workerStartedAtNanos = System.nanoTime()
                val value = handleQueryCall(
                    call = call,
                    fluviCore = fluviCore,
                    nativeHandlerQueueMicros =
                        ((workerStartedAtNanos - handlerEnteredAtNanos).coerceAtLeast(0L) / 1_000L),
                )
                val resultSubmitStartedAtNanos = System.nanoTime()
                result.success(value)
                if (call.method == "readDashboardCommittedPage") {
                    emitDiagnostic(
                        stage = "VERTICAL_PAGE_NATIVE_RESULT_SUBMITTED",
                        message = "VERTICAL_PAGE_NATIVE_RESULT_SUBMITTED",
                        scope = "nativeHandlerQueueMicros=" +
                            ((workerStartedAtNanos - handlerEnteredAtNanos).coerceAtLeast(0L) / 1_000L) +
                            " nativeResultSubmitMicros=" +
                            ((System.nanoTime() - resultSubmitStartedAtNanos).coerceAtLeast(0L) / 1_000L),
                    )
                }
            } catch (error: CancellationException) {
                if (identity != null) {
                    emitDiagnostic(
                        stage = "INDEX_PARTITION_BUILD_CANCELLED",
                        message = "INDEX_PARTITION_BUILD_CANCELLED",
                        scope = "generation=${identity.generation} " +
                            "direction=${identity.direction?.name ?: "whole"}",
                    )
                    result.error(
                        "query_preparation_cancelled",
                        "Prepared Query generation ${identity.generation} was superseded.",
                        null,
                    )
                } else {
                    throw error
                }
            } catch (error: Throwable) {
                result.error(
                    if (error is IllegalArgumentException) {
                        "validation"
                    } else {
                        "query_error"
                    },
                    error.message ?: "Dashboard query failed.",
                    null,
                )
            } finally {
                if (identity != null) {
                    preparedQueryGenerationOwner.complete(identity.generation, job)
                }
            }
        }
        if (identity != null) {
            val superseded = preparedQueryGenerationOwner.replace(
                DashboardPreparedIndexQueryGenerationOwner.Request(
                    generation = identity.generation,
                    direction = identity.direction,
                    job = job,
                ),
            )
            if (superseded != null && superseded.generation != identity.generation) {
                emitDiagnostic(
                    stage = "INDEX_PARTITION_BUILD_CANCEL_REQUESTED",
                    message = "INDEX_PARTITION_BUILD_CANCEL_REQUESTED",
                    scope = "generation=${superseded.generation} " +
                        "direction=${superseded.direction?.name ?: "whole"} " +
                        "supersededBy=${identity.generation}",
                )
            }
        }
        job.start()
    }

    private fun preparedQueryRequestIdentity(
        call: MethodCall,
    ): PreparedQueryRequestIdentity? {
        if (
            call.method != "readDashboardPreparedIndex" &&
            call.method != "readDashboardPreparedIndexPartition"
        ) {
            return null
        }
        val arguments = DashboardQueryArguments.requireMap(
            call.arguments,
            "prepared index arguments",
        )
        if (DashboardQueryArguments.requireValue<String>(arguments, "acquisitionReason") != "query") {
            return null
        }
        val direction = if (call.method == "readDashboardPreparedIndexPartition") {
            LedgerDirection.valueOf(DashboardQueryArguments.requireValue(arguments, "direction"))
        } else {
            null
        }
        return PreparedQueryRequestIdentity(
            generation = DashboardQueryArguments.requestGeneration(arguments),
            direction = direction,
        )
    }

    private fun categoryMap(category: FluviCategory): Map<String, Any?> = mapOf(
        "id" to category.id,
        "name" to category.name,
        "colorId" to category.colorId,
        "iconId" to category.iconId,
        "isSystemUncategorized" to category.isSystemUncategorized,
        "createdAtUtcMs" to category.createdAtUtcMs,
        "updatedAtUtcMs" to category.updatedAtUtcMs,
    )

    private suspend fun handleQueryCall(
        call: MethodCall,
        fluviCore: FluviCore,
        nativeHandlerQueueMicros: Long = 0L,
    ): Any? = when (call.method) {
        "readDashboardPreparedIndex" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "prepared index arguments",
            )
            val acquisitionReason = DashboardQueryArguments.requireValue<String>(
                arguments,
                "acquisitionReason",
            )
            DashboardPreparedIndexAcquisitionReasons.requireAllowed(acquisitionReason)
            val directionalFilters = DashboardQueryArguments.directionalFiltersFrom(arguments)
            val requestIdentity = preparedIndexRequestIdentity(
                expectedRevision = DashboardQueryArguments.requireLong(arguments, "coreRevision"),
                directionalFilters = directionalFilters,
                previewPageSize = DashboardQueryArguments.pageSize(arguments),
                yearWindow = requireNotNull(DashboardQueryArguments.preparedYearWindow(arguments)) {
                    "Prepared index requires an explicit year window."
                },
            )
            val expectedRevision = DashboardQueryArguments.requireLong(
                arguments,
                "coreRevision",
            )
            val generation = DashboardQueryArguments.requestGeneration(arguments)
            val yearWindow = requireNotNull(
                DashboardQueryArguments.preparedYearWindow(arguments),
            ) { "Prepared index requires an explicit year window." }
            emitDiagnostic(
                stage = "INDEX_BUILD_STARTED",
                message = "INDEX_BUILD_STARTED",
                scope = "generation=$generation acquisitionReason=$acquisitionReason " +
                    "requestIdentity=$requestIdentity",
                coreRevision = expectedRevision,
            )
            val index = fluviCore.query.preparedDashboardIndex(
                directionalFilters = directionalFilters,
                previewPageSize = DashboardQueryArguments.pageSize(arguments),
                yearWindow = yearWindow,
                requestGeneration = generation,
            )
            require(index.coreRevision == expectedRevision) {
                "Prepared index revision changed while building."
            }
            currentCoroutineContext().ensureActive()
            val serializationStartedAtNanos = System.nanoTime()
            val payload = DashboardBinaryCodec.encodePreparedIndex(index)
            currentCoroutineContext().ensureActive()
            val serializationDurationNanos =
                System.nanoTime() - serializationStartedAtNanos
            emitDiagnostic(
                stage = "INDEX_BUILD_READY",
                message = "INDEX_BUILD_READY",
                scope = "generation=$generation acquisitionReason=$acquisitionReason " +
                    "requestIdentity=$requestIdentity " +
                    "sqlCalls=${index.buildMetrics.sqlCallCount} " +
                    "sqlMicros=${index.buildMetrics.sqlDurationNanos / 1_000L} " +
                    "frames=${index.frames.size} rows=${index.rows.size} " +
                    "payloadBytes=${payload.size} " +
                    "serializationMicros=${serializationDurationNanos / 1_000L}",
                coreRevision = index.coreRevision,
                durationMs = (
                    index.buildMetrics.queryDurationNanos +
                        index.buildMetrics.mappingDurationNanos +
                        serializationDurationNanos
                    ) / 1_000_000L,
            )
            payload
        }
        "readDashboardPreparedIndexPartition" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "prepared index partition arguments",
            )
            val acquisitionReason = DashboardQueryArguments.requireValue<String>(
                arguments,
                "acquisitionReason",
            )
            DashboardPreparedIndexAcquisitionReasons.requireAllowed(acquisitionReason)
            val directionalFilters = DashboardQueryArguments.directionalFiltersFrom(arguments)
            val direction = LedgerDirection.valueOf(
                DashboardQueryArguments.requireValue(arguments, "direction"),
            )
            val expectedRevision = DashboardQueryArguments.requireLong(
                arguments,
                "coreRevision",
            )
            val generation = DashboardQueryArguments.requestGeneration(arguments)
            val yearWindow = requireNotNull(
                DashboardQueryArguments.preparedYearWindow(arguments),
            ) { "Prepared index partition requires an explicit year window." }
            val requestIdentity = preparedIndexRequestIdentity(
                expectedRevision = expectedRevision,
                directionalFilters = directionalFilters,
                previewPageSize = DashboardQueryArguments.pageSize(arguments),
                yearWindow = yearWindow,
            )
            emitDiagnostic(
                stage = "INDEX_PARTITION_BUILD_STARTED",
                message = "INDEX_PARTITION_BUILD_STARTED",
                scope = "generation=$generation direction=${direction.name} " +
                    "acquisitionReason=$acquisitionReason requestIdentity=$requestIdentity",
                coreRevision = expectedRevision,
            )
            val index = fluviCore.query.preparedDashboardIndexPartition(
                direction = direction,
                directionalFilters = directionalFilters,
                previewPageSize = DashboardQueryArguments.pageSize(arguments),
                yearWindow = yearWindow,
                requestGeneration = generation,
            )
            require(index.coreRevision == expectedRevision) {
                "Prepared index partition revision changed while building."
            }
            currentCoroutineContext().ensureActive()
            val serializationStartedAtNanos = System.nanoTime()
            val payload = DashboardBinaryCodec.encodePreparedIndex(index)
            currentCoroutineContext().ensureActive()
            val serializationDurationNanos =
                System.nanoTime() - serializationStartedAtNanos
            emitDiagnostic(
                stage = "INDEX_PARTITION_BUILD_READY",
                message = "INDEX_PARTITION_BUILD_READY",
                scope = "generation=$generation direction=${direction.name} " +
                    "requestIdentity=$requestIdentity " +
                    "sqlCalls=${index.buildMetrics.sqlCallCount} " +
                    "sqlMicros=${index.buildMetrics.sqlDurationNanos / 1_000L} " +
                    "frames=${index.frames.size} rows=${index.rows.size} " +
                    "payloadBytes=${payload.size} " +
                    "serializationMicros=${serializationDurationNanos / 1_000L}",
                coreRevision = index.coreRevision,
                durationMs = (
                    index.buildMetrics.queryDurationNanos +
                        index.buildMetrics.mappingDurationNanos +
                        serializationDurationNanos
                    ) / 1_000_000L,
            )
            payload
        }
        "readDashboardPreparedBudgetLimits" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "prepared Budget limit arguments",
            )
            val expectedRevision = DashboardQueryArguments.requireLong(
                arguments,
                "coreRevision",
            )
            val yearWindow = requireNotNull(
                DashboardQueryArguments.preparedYearWindow(arguments),
            ) { "Prepared Budget limits require an explicit year window." }
            val ghostFilterMode = DashboardQueryArguments.ghostFilterMode(arguments)
            emitDiagnostic(
                stage = "FINANCIAL_LIMIT_SNAPSHOT_PREPARE_STARTED",
                message = "FINANCIAL_LIMIT_SNAPSHOT_PREPARE_STARTED",
                coreRevision = expectedRevision,
                scope = "yearWindowStart=${yearWindow.startYear} " +
                    "yearWindowEnd=${yearWindow.endYearInclusive}",
            )
            val snapshot = fluviCore.budget.preparedLimitSnapshot(
                expectedRevision = expectedRevision,
                yearWindow = yearWindow,
                ghostFilterMode = ghostFilterMode,
            )
            currentCoroutineContext().ensureActive()
            val payload = DashboardBinaryCodec.encodePreparedBudgetLimitSnapshot(snapshot)
            emitDiagnostic(
                stage = "FINANCIAL_LIMIT_SNAPSHOT_READY",
                message = "FINANCIAL_LIMIT_SNAPSHOT_READY",
                coreRevision = snapshot.coreRevision,
                scope = "incomeTargetCount=${snapshot.incomeBank.targetCount} " +
                    "incomeCategoryCount=${snapshot.incomeBank.orderedCategoryIds.size} " +
                    "expenseTargetCount=${snapshot.expenseBank.targetCount} " +
                    "expenseCategoryCount=${snapshot.expenseBank.orderedCategoryIds.size} " +
                    "periodSliceCount=${snapshot.periodSliceCount} " +
                    "payloadBytes=${payload.size} sqlCalls=${snapshot.sqlCallCount} " +
                    "nativeSqlMicros=${snapshot.sqlDurationNanos / 1_000L}",
                durationMs = snapshot.sqlDurationNanos / 1_000_000L,
            )
            payload
        }
        "readDashboardPreparedBudgetPartnerDistribution" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "prepared Budget partner distribution arguments",
            )
            val expectedRevision = DashboardQueryArguments.requireLong(
                arguments,
                "coreRevision",
            )
            val yearWindow = requireNotNull(
                DashboardQueryArguments.preparedYearWindow(arguments),
            ) { "Prepared Budget partner distribution requires an explicit year window." }
            val ghostFilterMode = DashboardQueryArguments.ghostFilterMode(arguments)
            emitDiagnostic(
                stage = "BUDGET_PARTNER_SNAPSHOT_PREPARE_STARTED",
                message = "BUDGET_PARTNER_SNAPSHOT_PREPARE_STARTED",
                coreRevision = expectedRevision,
                scope = "yearWindowStart=${yearWindow.startYear} " +
                    "yearWindowEnd=${yearWindow.endYearInclusive}",
            )
            val snapshot = fluviCore.budget.preparedPartnerDistributionSnapshot(
                expectedRevision = expectedRevision,
                yearWindow = yearWindow,
                ghostFilterMode = ghostFilterMode,
            )
            currentCoroutineContext().ensureActive()
            val payload = DashboardBinaryCodec.encodePreparedBudgetPartnerDistributionSnapshot(snapshot)
            emitDiagnostic(
                stage = "BUDGET_PARTNER_SNAPSHOT_READY",
                message = "BUDGET_PARTNER_SNAPSHOT_READY",
                coreRevision = snapshot.coreRevision,
                scope = "incomePartnerCount=${snapshot.incomeBank.partnerCount} " +
                    "expensePartnerCount=${snapshot.expenseBank.partnerCount} " +
                    "periodSlices=${snapshot.periodSliceCount} " +
                    "payloadBytes=${payload.size} sqlCalls=${snapshot.sqlCallCount} " +
                    "nativeSqlMicros=${snapshot.sqlDurationNanos / 1_000L}",
                durationMs = snapshot.sqlDurationNanos / 1_000_000L,
            )
            payload
        }
        "readDashboardCommittedPage" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "committed page arguments",
            )
            val acquisitionReason = DashboardQueryArguments.requireValue<String>(
                arguments,
                "acquisitionReason",
            )
            require(acquisitionReason == "explicitCommittedVerticalPaging") {
                "Committed page acquisition reason is not allowed: $acquisitionReason"
            }
            val pageOrdinal = DashboardQueryArguments.requireLong(arguments, "pageOrdinal")
            require(pageOrdinal >= 1L) { "Committed page ordinal must be positive." }
            val startedAtNanos = System.nanoTime()
            val page = fluviCore.query.readCommittedPage(
                scope = DashboardQueryArguments.scopeFrom(arguments),
                pageSize = DashboardQueryArguments.pageSize(arguments),
                after = DashboardQueryArguments.cursor(arguments),
                expectedRevision = DashboardQueryArguments.requireLong(
                    arguments,
                    "coreRevision",
                ),
                authoritativeTotalMinor = DashboardQueryArguments.requireLong(
                    arguments,
                    "authoritativeTotalMinor",
                ),
                authoritativeEntryCount = DashboardQueryArguments.requireLong(
                    arguments,
                    "authoritativeEntryCount",
                ),
                authoritativePresentationEntryCount = DashboardQueryArguments.requireLong(
                    arguments,
                    "authoritativePresentationEntryCount",
                ),
            )
            val serializationStartedAtNanos = System.nanoTime()
            val payload = DashboardBinaryCodec.encodeCommittedPage(
                slice = page.slice,
                parentQueryKey = DashboardQueryArguments.requireValue(
                    arguments,
                    "parentQueryKey",
                ),
                presentationEpoch = DashboardQueryArguments.requireLong(
                    arguments,
                    "presentationEpoch",
                ),
                commitGeneration = DashboardQueryArguments.requireLong(
                    arguments,
                    "commitGeneration",
                ),
            )
            val serializationDurationNanos =
                (System.nanoTime() - serializationStartedAtNanos).coerceAtLeast(0L)
            emitDiagnostic(
                stage = "VERTICAL_PAGE_NATIVE_READY",
                message = "VERTICAL_PAGE_NATIVE_READY",
                queryKey = page.slice.queryKey,
                direction = page.slice.direction.name,
                coreRevision = page.slice.coreRevision,
                entryCount = page.slice.entries.size.toLong(),
                durationMs = (System.nanoTime() - startedAtNanos) / 1_000_000L,
                scope = "pageOrdinal=$pageOrdinal " +
                    "nativeSqlMicros=${page.sqlDurationNanos / 1_000L} " +
                    "nativeMappingMicros=${page.mappingDurationNanos / 1_000L} " +
                    "serializationMicros=${serializationDurationNanos / 1_000L} " +
                    "nativeHandlerQueueMicros=$nativeHandlerQueueMicros " +
                    "authoritativeEntryCount=${page.slice.entryCount}",
            )
            payload
        }
        else -> throw IllegalArgumentException("Unknown query method: ${call.method}")
    }

    private fun preparedIndexRequestIdentity(
        expectedRevision: Long,
        directionalFilters: com.fluvi.core.query.FluviDashboardDirectionalQuerySet,
        previewPageSize: Int,
        yearWindow: com.fluvi.core.query.FluviPreparedYearWindow,
    ): String = "rev=$expectedRevision|income=${queryFilterIdentity(directionalFilters.income)}|" +
        "expense=${queryFilterIdentity(directionalFilters.expense)}|" +
        "page=$previewPageSize|window=${yearWindow.startYear}-${yearWindow.endYearInclusive}"

    private fun queryFilterIdentity(scope: FluviQueryScope): String = buildString {
        append(scope.direction.name)
        append("|periods:")
        append(
            scope.periodGroups
                .sortedBy { it.key }
                .joinToString(";") { group ->
                    "${group.key}=" + group.selections
                        .sortedWith(compareBy({ it.kind.name }, { it.value }))
                        .joinToString(",") { "${it.kind.name}:${it.value}" }
                },
        )
        append("|categories:")
        append(scope.categoryIds.sorted().joinToString(","))
        append("|partners:")
        append(scope.partnerIds.sorted().joinToString(","))
        append("|refinements:")
        append("min=${scope.refinements.minimumAmountScaled100 ?: ""}")
        append(",max=${scope.refinements.maximumAmountScaled100 ?: ""}")
        append("|ghost=${scope.ghostFilterMode.name}")
        // Diagnostics need stable request correlation, not user-entered text.
        append(",hasNote=${scope.refinements.noteContains != null}")
    }

    private suspend fun debugSeedSnapshot(fluviCore: FluviCore) {
        if (!isDebuggable()) return
        val income = fluviCore.query.total(
            FluviQueryScope(direction = LedgerDirection.income),
        )
        val expense = fluviCore.query.total(
            FluviQueryScope(direction = LedgerDirection.expense),
        )
        val julyIncome = fluviCore.query.total(
            monthScope(LedgerDirection.income, 7),
        )
        val julyExpense = fluviCore.query.total(
            monthScope(LedgerDirection.expense, 7),
        )
        emitDiagnostic(
            stage = "D2",
            message = "DB_VERIFIED " +
                "allIncome=${income.amountScaled100}/${income.entryCount} " +
                "allExpense=${expense.amountScaled100}/${expense.entryCount} " +
                "julyIncome=${julyIncome.amountScaled100}/${julyIncome.entryCount} " +
                "julyExpense=${julyExpense.amountScaled100}/${julyExpense.entryCount}",
            scope = "dbPath=${applicationContext.getDatabasePath(DATABASE_FILE_NAME).absolutePath}",
            totalMinor = julyExpense.amountScaled100,
            entryCount = julyExpense.entryCount,
        )
    }

    private fun monthScope(direction: LedgerDirection, month: Int): FluviQueryScope =
        FluviQueryScope(
            direction = direction,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(
                        FluviPeriodSelection(
                            kind = QueryPeriodKind.month,
                            value = "2026-${month.toString().padStart(2, '0')}",
                        ),
                    ),
                ),
            ),
        )

    private fun debugLog(message: String) {
        if (isDebuggable()) Log.d(DEBUG_TAG, message)
    }

    private fun emitDiagnostic(
        stage: String,
        message: String,
        flowId: String? = null,
        queryKey: String? = null,
        direction: String? = null,
        scope: String? = null,
        coreRevision: Long? = null,
        totalMinor: Long? = null,
        entryCount: Long? = null,
        durationMs: Long? = null,
        error: String? = null,
    ) {
        if (!isDebuggable()) return
        val event = mapOf<String, Any?>(
            "stage" to stage,
            "message" to message,
            "timestampMicros" to (System.currentTimeMillis() * 1000L),
            "flowId" to flowId,
            "queryKey" to queryKey,
            "direction" to direction,
            "scope" to scope,
            "coreRevision" to coreRevision,
            "totalMinor" to totalMinor,
            "formattedTotal" to totalMinor?.let(::formatMinorForDebug),
            "entryCount" to entryCount,
            "durationMs" to durationMs,
            "error" to error,
        )
        val publish = {
            diagnosticEventSink?.success(event)
            debugLog(
                "[FLOW][$stage] $message " +
                    "flowId=${flowId ?: "-"} queryKey=${queryKey ?: "-"} " +
                    "direction=${direction ?: "-"} scope=${scope ?: "-"} " +
                    "revision=${coreRevision ?: "-"} totalMinor=${totalMinor ?: "-"} " +
                    "entryCount=${entryCount ?: "-"}",
            )
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            publish()
        } else {
            this@MainActivity.scope.launch { publish() }
        }
    }

    private fun formatMinorForDebug(value: Long): String {
        val sign = if (value < 0) "-" else ""
        val absolute = kotlin.math.abs(value)
        val major = absolute / 100L
        val minor = (absolute % 100L).toString().padStart(2, '0')
        return "$sign$major,$minor Ft"
    }

    private fun isDebuggable(): Boolean =
        applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0

    private fun demoSeedMap(report: com.fluvi.core.demo.DemoSeedReport): Map<String, Any?> = mapOf(
        "seedVersion" to report.seedVersion,
        "prngSeed" to report.prngSeed,
        "createdCategoryCount" to report.createdCategoryCount,
        "createdPartnerCount" to report.createdPartnerCount,
        "createdEntryCount" to report.createdEntryCount,
        "earliestEntryAtUtcMs" to report.earliestEntryAtUtcMs,
        "latestEntryAtUtcMs" to report.latestEntryAtUtcMs,
        "alreadySeeded" to report.alreadySeeded,
        "durationMs" to report.durationMs,
        "monthlyReports" to report.monthlyReports.map { month ->
            mapOf(
                "year" to month.year,
                "month" to month.month,
                "entryCount" to month.entryCount,
                "incomeCount" to month.incomeCount,
                "expenseCount" to month.expenseCount,
                "incomeTargetMinor" to month.incomeTargetScaled100,
                "expenseTargetMinor" to month.expenseTargetScaled100,
                "incomeTotalMinor" to month.incomeTotalScaled100,
                "expenseTotalMinor" to month.expenseTotalScaled100,
            )
        },
    )

    private inline fun <reified T> requireArgument(call: MethodCall, key: String): T =
        requireNotNull(call.argument<T>(key)) { "Missing category argument: $key" }

    companion object {
        const val CATEGORY_CHANNEL = "com.fluvi/category_repository"
        const val MANUAL_TRANSACTION_CHANNEL = "com.fluvi/manual_transactions"
        const val AUTOMATION_CHANNEL = "com.fluvi/automation"
        const val AUTOMATION_PERMISSION_CHANNEL = "com.fluvi/automation_permissions"
        const val FINANCIAL_LIMIT_CHANNEL = "com.fluvi/financial_limits"
        const val PULSE_CHANNEL = "com.fluvi/pulse"
        const val QUERY_CHANNEL = "com.fluvi/dashboard_query"
        const val QUERY_MENU_CHANNEL = "com.fluvi/query_menu"
        const val DEMO_CHANNEL = "com.fluvi/demo_data"
        const val DASHBOARD_PRESENTATION_CHANNEL = "fluvi/dashboard_presentation"
        const val DASHBOARD_PRESENTATION_PREFERENCES = "dashboard_presentation"
        const val DASHBOARD_CORE_REVISION_STREAM_CHANNEL =
            "com.fluvi/dashboard_core_revision_stream"
        const val DIAGNOSTIC_CHANNEL = "com.fluvi/diagnostics"
        const val DATABASE_FILE_NAME = "fluvi_core.db"
        const val DEBUG_TAG = "FluviDashboard"
    }
}
