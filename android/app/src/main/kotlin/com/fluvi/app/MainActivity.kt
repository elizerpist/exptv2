package com.fluvi.app

import android.content.pm.ApplicationInfo
import android.util.Log
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviDashboardDayGroupPage
import com.fluvi.core.query.FluviDashboardTimeChildSummaryIndex
import com.fluvi.app.dashboard.DashboardObservationSession
import com.fluvi.app.dashboard.DashboardQueryArguments
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var core: FluviCore? = null
    private var categoryChannel: MethodChannel? = null
    private var queryChannel: MethodChannel? = null
    private var demoChannel: MethodChannel? = null
    private var dashboardEventChannel: EventChannel? = null
    private var diagnosticEventChannel: EventChannel? = null
    private var diagnosticEventSink: EventChannel.EventSink? = null
    private val dashboardObservationSession = DashboardObservationSession<Job> {
        observation -> observation.cancel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val fluviCore = FluviCoreFactory.create(applicationContext)
        core = fluviCore
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
                    runCatching { handleCategoryCall(call, fluviCore) }
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
        queryChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QUERY_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                scope.launch {
                    runCatching { handleQueryCall(call, fluviCore) }
                        .onSuccess(result::success)
                        .onFailure { error ->
                            result.error(
                                if (error is IllegalArgumentException) {
                                    "validation"
                                } else {
                                    "query_error"
                                },
                                error.message ?: "Dashboard query failed.",
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
                                    emitDiagnostic(
                                        stage = "D0",
                                        message = "SEED_STARTED " +
                                            "forceReset=${call.argument<Boolean>("forceReset") ?: false}",
                                        scope = "dbPath=${applicationContext.getDatabasePath(DATABASE_FILE_NAME).absolutePath}",
                                    )
                                    seedUseCase
                                        .seed(call.argument<Boolean>("forceReset") ?: false)
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
        dashboardEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DASHBOARD_STREAM_CHANNEL,
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val rawArguments = arguments as? Map<*, *>
                    val rawSubscriptionId = rawArguments
                        ?.get("subscriptionId")
                        ?.toString()
                    val rawFlowId = rawArguments?.get("debugFlowId")?.toString()
                    val rawQueryKey = rawArguments?.get("scopeKey")?.toString()
                    emitDiagnostic(
                        stage = "D8C",
                        message = "NATIVE_WATCH_SUBSCRIBED",
                        flowId = rawFlowId,
                        queryKey = rawQueryKey,
                        scope = "subscriptionId=${rawSubscriptionId ?: "missing"}",
                    )
                    runCatching {
                        val queryArguments = DashboardQueryArguments.requireMap(
                            arguments,
                            "dashboard stream arguments",
                        )
                        val subscriptionId = DashboardQueryArguments.requireValue<String>(
                            queryArguments,
                            "subscriptionId",
                        )
                        val queryScope = DashboardQueryArguments.scopeFrom(queryArguments)
                        val maxDayGroups = DashboardQueryArguments.maxDayGroups(queryArguments)
                        val queryKey = queryArguments["scopeKey"]?.toString()
                        val flowId = queryArguments["debugFlowId"]?.toString()
                        emitDiagnostic(
                            stage = "D3",
                            message = "ACTIVE_QUERY_SCOPE",
                            flowId = flowId,
                            queryKey = queryKey,
                            direction = queryScope.direction.name,
                            scope = queryScopeSummary(queryScope),
                        )
                        dashboardObservationSession.replace(
                            subscriptionId = subscriptionId,
                            observation = scope.launch {
                                var lastCoreRevision: Long? = null
                                val observationStartedAtNanos = System.nanoTime()
                                try {
                                    emitDiagnostic(
                                        stage = "D8D",
                                        message = "READ_SERVICE_INVOKED",
                                        flowId = flowId,
                                        queryKey = queryKey,
                                        direction = queryScope.direction.name,
                                        scope = queryScopeSummary(queryScope),
                                    )
                                    fluviCore.query.observeDashboardDayGroupPage(
                                        queryScope,
                                        maxDayGroups = maxDayGroups,
                                    ).collectLatest { page ->
                                        if (!dashboardObservationSession.isActive(subscriptionId)) {
                                            return@collectLatest
                                        }
                                        if (lastCoreRevision != page.coreRevision) {
                                            lastCoreRevision = page.coreRevision
                                            emitDiagnostic(
                                                stage = "REV",
                                                message = "CORE_REVISION_CHANGED",
                                                flowId = flowId,
                                                queryKey = page.queryKey,
                                                direction = page.direction.name,
                                                scope = page.timeScopeKey,
                                                coreRevision = page.coreRevision,
                                            )
                                        }
                                        emitDiagnostic(
                                            stage = "D4",
                                            message = if (page.totalMinor == 0L) {
                                                "ROOM_OBSERVER_EMIT QUERY_ZERO_RESULT"
                                            } else {
                                                "ROOM_OBSERVER_EMIT"
                                            },
                                            flowId = flowId,
                                            queryKey = page.queryKey,
                                            direction = page.direction.name,
                                            scope = page.timeScopeKey,
                                            coreRevision = page.coreRevision,
                                            totalMinor = page.totalMinor,
                                            entryCount = page.entryCount,
                                        )
                                        emitDiagnostic(
                                            stage = "D5",
                                            message = if (page.totalMinor == 0L) {
                                                "READ_SERVICE_RESULT QUERY_ZERO_RESULT"
                                            } else {
                                                "READ_SERVICE_RESULT"
                                            },
                                            flowId = flowId,
                                            queryKey = page.queryKey,
                                            direction = page.direction.name,
                                            scope = page.timeScopeKey,
                                            coreRevision = page.coreRevision,
                                            totalMinor = page.totalMinor,
                                            entryCount = page.entryCount,
                                            durationMs =
                                                (System.nanoTime() - observationStartedAtNanos) /
                                                    1_000_000L,
                                        )
                                        events.success(dashboardDayGroupPageMap(page, flowId))
                                        emitDiagnostic(
                                            stage = "D6",
                                            message = "NATIVE_BRIDGE_SEND",
                                            flowId = flowId,
                                            queryKey = page.queryKey,
                                            direction = page.direction.name,
                                            scope = page.timeScopeKey,
                                            coreRevision = page.coreRevision,
                                            totalMinor = page.totalMinor,
                                            entryCount = page.entryCount,
                                        )
                                    }
                                } catch (error: Throwable) {
                                    if (error is CancellationException) throw error
                                    emitDiagnostic(
                                        stage = "D-ERROR",
                                        message = "NATIVE_WATCH_FAILED",
                                        flowId = flowId,
                                        queryKey = queryKey,
                                        direction = queryScope.direction.name,
                                        scope = queryScopeSummary(queryScope),
                                        error = error.message ?: error.toString(),
                                    )
                                    if (dashboardObservationSession.isActive(subscriptionId)) {
                                        events.error(
                                            "dashboard_observer_error",
                                            error.message ?: "Dashboard observer failed.",
                                            null,
                                        )
                                    }
                                }
                            },
                        )
                    }.onFailure { error ->
                        emitDiagnostic(
                            stage = "D-ERROR",
                            message = "NATIVE_WATCH_SUBSCRIBE_FAILED",
                            flowId = rawFlowId,
                            queryKey = rawQueryKey,
                            scope = "subscriptionId=${rawSubscriptionId ?: "missing"}",
                            error = error.message ?: error.toString(),
                        )
                        events.error(
                            "dashboard_observer_error",
                            error.message ?: "Dashboard observer subscription failed.",
                            null,
                        )
                    }
                }

                override fun onCancel(arguments: Any?) {
                    val cancellationId = (arguments as? Map<*, *>)
                        ?.get("subscriptionId")
                        ?.toString()
                    val cancelled = cancellationId != null &&
                        dashboardObservationSession.cancelIfActive(cancellationId)
                    emitDiagnostic(
                        stage = "D8C",
                        message = if (cancelled) {
                            "NATIVE_WATCH_CANCELLED"
                        } else {
                            "NATIVE_WATCH_CANCEL_IGNORED_STALE"
                        },
                        flowId = (arguments as? Map<*, *>)?.get("debugFlowId")?.toString(),
                        queryKey = (arguments as? Map<*, *>)?.get("scopeKey")?.toString(),
                        scope = "subscriptionId=${cancellationId ?: "missing"} " +
                            "active=${dashboardObservationSession.activeSubscriptionId ?: "none"}",
                    )
                }
            })
        }
    }

    override fun onDestroy() {
        categoryChannel?.setMethodCallHandler(null)
        categoryChannel = null
        queryChannel?.setMethodCallHandler(null)
        queryChannel = null
        demoChannel?.setMethodCallHandler(null)
        demoChannel = null
        dashboardObservationSession.cancelActive()
        dashboardEventChannel?.setStreamHandler(null)
        dashboardEventChannel = null
        diagnosticEventSink = null
        diagnosticEventChannel?.setStreamHandler(null)
        diagnosticEventChannel = null
        core?.close()
        core = null
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
    ): Any? = when (call.method) {
        "readDashboard" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "query arguments",
            )
            val queryScope = DashboardQueryArguments.scopeFrom(arguments)
            fluviCore.query.readSlice(
                queryScope,
                pageSize = DashboardQueryArguments.pageSize(arguments),
                after = DashboardQueryArguments.cursor(arguments),
            ).also { slice ->
                val flowId = arguments["debugFlowId"]?.toString()
                emitDiagnostic(
                    stage = "D5",
                    message = if (slice.totalMinor == 0L) {
                        "READ_SERVICE_RESULT QUERY_ZERO_RESULT"
                    } else {
                        "READ_SERVICE_RESULT"
                    },
                    flowId = flowId,
                    queryKey = slice.queryKey,
                    direction = slice.direction.name,
                    scope = slice.timeScopeKey,
                    coreRevision = slice.coreRevision,
                    totalMinor = slice.totalMinor,
                    entryCount = slice.entryCount,
                )
            }.let { slice ->
                dashboardSliceMap(slice, arguments["debugFlowId"]?.toString())
            }
        }
        "readDashboardChildSummaries" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "child summary arguments",
            )
            val queryScope = DashboardQueryArguments.scopeFrom(arguments)
            fluviCore.query.timeChildSummaryIndex(
                scope = queryScope,
                childPeriodKind = DashboardQueryArguments.childPeriodKind(arguments),
            ).let(::dashboardChildSummaryIndexMap)
        }
        "readDashboardLogPage" -> {
            val arguments = DashboardQueryArguments.requireMap(
                call.arguments,
                "dashboard LogBox page arguments",
            )
            val queryScope = DashboardQueryArguments.scopeFrom(arguments)
            fluviCore.query.dashboardDayGroupPage(
                scope = queryScope,
                beforeLocalEpochDayExclusive =
                    DashboardQueryArguments.beforeLocalEpochDayExclusive(arguments),
                maxDayGroups = DashboardQueryArguments.maxDayGroups(arguments),
            ).let { page ->
                dashboardDayGroupPageMap(page, arguments["debugFlowId"]?.toString())
            }
        }
        else -> throw IllegalArgumentException("Unknown query method: ${call.method}")
    }

    private fun dashboardChildSummaryIndexMap(
        index: FluviDashboardTimeChildSummaryIndex,
    ): Map<String, Any?> = mapOf(
        "parentQueryKey" to index.parentQueryKey,
        "direction" to index.direction.name,
        "childPeriod" to index.childPeriodKind.name,
        "coreRevision" to index.coreRevision,
        "isComplete" to index.isComplete,
        "values" to index.values.map { value ->
            mapOf(
                "childPeriodValue" to value.childPeriodValue,
                "childQueryKey" to value.childQueryKey,
                "totalMinor" to value.totalMinor,
                "entryCount" to value.entryCount,
            )
        },
    )

    private fun dashboardSliceMap(
        slice: FluviDashboardLedgerSlice,
        flowId: String? = null,
    ): Map<String, Any?> = mapOf(
        "scopeKey" to slice.queryKey,
        "timeScopeKey" to slice.timeScopeKey,
        "direction" to slice.direction.name,
        "totalMinor" to slice.totalMinor,
        "entryCount" to slice.entryCount,
        "coreRevision" to slice.coreRevision,
        "flowId" to flowId,
        "entries" to slice.entries.map { entry ->
            mapOf(
                "id" to entry.entryId,
                "partnerId" to entry.partnerId,
                "partnerDisplayName" to entry.partnerDisplayName,
                "categoryId" to entry.categoryId,
                "categoryDisplayName" to entry.categoryDisplayName,
                "categoryColorId" to entry.categoryColorId,
                "categoryIconId" to entry.categoryIconId,
                "assignmentMode" to entry.assignmentMode.name,
                "originKind" to entry.originKind.name,
                "direction" to entry.direction.name,
                "amountMinor" to entry.amountMinor,
                "bookedLocalEpochDay" to entry.bookedLocalEpochDay,
                "bookedLocalTimeMinutes" to entry.bookedLocalTimeMinutes,
                "note" to entry.note,
                "occurredAtUtcMs" to entry.occurredAtUtcMs,
            )
        },
        "nextCursor" to slice.nextCursor?.let { cursor ->
            mapOf(
                "bookedLocalEpochDay" to cursor.bookedLocalEpochDay,
                "bookedLocalTimeMinutes" to cursor.bookedLocalTimeMinutes,
                "entryId" to cursor.entryId,
            )
        },
    )

    private fun dashboardDayGroupPageMap(
        page: FluviDashboardDayGroupPage,
        flowId: String? = null,
    ): Map<String, Any?> = mapOf(
        "scopeKey" to page.queryKey,
        "timeScopeKey" to page.timeScopeKey,
        "direction" to page.direction.name,
        "totalMinor" to page.totalMinor,
        "entryCount" to page.entryCount,
        "coreRevision" to page.coreRevision,
        "flowId" to flowId,
        "entries" to page.groups.flatMap { group -> group.rows }.map(::dashboardEntryMap),
        "dayGroups" to page.groups.map { group ->
            mapOf(
                "bookedLocalEpochDay" to group.bookedLocalEpochDay,
                "entries" to group.rows.map(::dashboardEntryMap),
            )
        },
        "nextDayCursor" to page.nextBeforeLocalEpochDayExclusive?.let { date ->
            mapOf("beforeLocalEpochDayExclusive" to date)
        },
    )

    private fun dashboardEntryMap(entry: com.fluvi.core.query.FluviDashboardLedgerRow): Map<String, Any?> =
        mapOf(
            "id" to entry.entryId,
            "partnerId" to entry.partnerId,
            "partnerDisplayName" to entry.partnerDisplayName,
            "categoryId" to entry.categoryId,
            "categoryDisplayName" to entry.categoryDisplayName,
            "categoryColorId" to entry.categoryColorId,
            "categoryIconId" to entry.categoryIconId,
            "assignmentMode" to entry.assignmentMode.name,
            "originKind" to entry.originKind.name,
            "direction" to entry.direction.name,
            "amountMinor" to entry.amountMinor,
            "bookedLocalEpochDay" to entry.bookedLocalEpochDay,
            "bookedLocalTimeMinutes" to entry.bookedLocalTimeMinutes,
            "note" to entry.note,
            "occurredAtUtcMs" to entry.occurredAtUtcMs,
        )

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

    private fun queryScopeSummary(scope: FluviQueryScope): String =
        "direction=${scope.direction.name} " +
            "periods=${scope.periodGroups.joinToString { group ->
                group.selections.joinToString { selection ->
                    "${selection.kind.name}:${selection.value}"
                }
            }}"

    private fun sliceSummary(slice: FluviDashboardLedgerSlice): String =
        "queryKey=${slice.queryKey} revision=${slice.coreRevision} " +
            "direction=${slice.direction.name} scope=${slice.timeScopeKey} " +
            "totalMinor=${slice.totalMinor} entryCount=${slice.entryCount}"

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
        diagnosticEventSink?.success(event)
        debugLog(
            "[FLOW][$stage] $message " +
                "flowId=${flowId ?: "-"} queryKey=${queryKey ?: "-"} " +
                "direction=${direction ?: "-"} scope=${scope ?: "-"} " +
                "revision=${coreRevision ?: "-"} totalMinor=${totalMinor ?: "-"} " +
                "entryCount=${entryCount ?: "-"}",
        )
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
        const val QUERY_CHANNEL = "com.fluvi/dashboard_query"
        const val DEMO_CHANNEL = "com.fluvi/demo_data"
        const val DASHBOARD_STREAM_CHANNEL = "com.fluvi/dashboard_query_stream"
        const val DIAGNOSTIC_CHANNEL = "com.fluvi/diagnostics"
        const val DATABASE_FILE_NAME = "fluvi_core.db"
        const val DEBUG_TAG = "FluviDashboard"
    }
}
