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
import com.fluvi.core.query.FluviQueryRefinements
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviDashboardLedgerSlice
import com.fluvi.core.query.FluviTimelineCursor
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
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
    private var dashboardObservationJob: Job? = null
    private var lastDashboardCoreRevision: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val fluviCore = FluviCoreFactory.create(applicationContext)
        core = fluviCore
        debugLog(
            "coreCreated instance=${System.identityHashCode(fluviCore)} " +
                "dbPath=${applicationContext.getDatabasePath(DATABASE_FILE_NAME).absolutePath}",
        )
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
                                    debugLog(
                                        "D0 demoSeedStarted " +
                                            "core=${System.identityHashCode(fluviCore)}",
                                    )
                                    seedUseCase
                                        .seed(call.argument<Boolean>("forceReset") ?: false)
                                        .also { report ->
                                            debugLog(
                                                "D1 demoSeedCommitted " +
                                                    "entries=${report.createdEntryCount} " +
                                                    "alreadySeeded=${report.alreadySeeded} " +
                                                    "earliest=${report.earliestEntryAtUtcMs} " +
                                                    "latest=${report.latestEntryAtUtcMs}",
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
                    val queryArguments = requireQueryMap(arguments, "dashboard stream arguments")
                    val queryScope = queryScopeFrom(queryArguments)
                    val pageSize = queryPageSize(queryArguments)
                    debugLog(
                        "queryStreamListen core=${System.identityHashCode(fluviCore)} " +
                            "${queryScopeSummary(queryScope)}",
                    )
                    lastDashboardCoreRevision = null
                    dashboardObservationJob?.cancel()
                    dashboardObservationJob = scope.launch {
                        fluviCore.query.observeSlice(
                            queryScope,
                            pageSize = pageSize,
                        ).collectLatest { slice ->
                            if (lastDashboardCoreRevision != slice.coreRevision) {
                                lastDashboardCoreRevision = slice.coreRevision
                                debugLog(
                                    "D3 coreRevisionChanged " +
                                        "revision=${slice.coreRevision}",
                                )
                            }
                            debugLog(
                                "D4 roomObserverEmitted " +
                                    "${sliceSummary(slice)}",
                            )
                            events.success(dashboardSliceMap(slice))
                            debugLog("D6 bridgeSent ${sliceSummary(slice)}")
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    dashboardObservationJob?.cancel()
                    dashboardObservationJob = null
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
        dashboardObservationJob?.cancel()
        dashboardObservationJob = null
        dashboardEventChannel?.setStreamHandler(null)
        dashboardEventChannel = null
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
            val arguments = requireQueryMap(call)
            val queryScope = queryScopeFrom(arguments)
            fluviCore.query.readSlice(
                queryScope,
                pageSize = queryPageSize(arguments),
                after = queryCursor(arguments),
            ).also { slice ->
                debugLog("D5 nativeReadReturned ${sliceSummary(slice)}")
            }.let(::dashboardSliceMap)
        }
        else -> throw IllegalArgumentException("Unknown query method: ${call.method}")
    }

    private fun queryScopeFrom(arguments: Map<*, *>): FluviQueryScope {
        val direction = LedgerDirection.valueOf(
            requireQueryValue<String>(arguments, "direction"),
        )
        val periodGroups = queryList(arguments, "periodGroups").map { rawGroup ->
            val group = requireQueryMap(rawGroup, "period group")
            val selections = queryList(group, "selections").map { rawSelection ->
                val selection = requireQueryMap(rawSelection, "period selection")
                FluviPeriodSelection(
                    kind = QueryPeriodKind.valueOf(
                        requireQueryValue<String>(selection, "kind"),
                    ),
                    value = requireQueryValue(selection, "value"),
                )
            }.toSet()
            FluviPeriodGroup(
                key = requireQueryValue(group, "key"),
                selections = selections,
            )
        }
        val refinements = requireQueryMap(arguments, "refinements")
        val supportedRefinements = setOf(
            "minimumAmountScaled100",
            "maximumAmountScaled100",
            "noteContains",
        )
        require(refinements.keys.all { it.toString() in supportedRefinements }) {
            "Unsupported query refinements: " +
                refinements.keys.filterNot { it.toString() in supportedRefinements }
        }

        return FluviQueryScope(
            direction = direction,
            periodGroups = periodGroups,
            categoryIds = queryStringSet(arguments, "categoryIds"),
            partnerIds = queryStringSet(arguments, "partnerIds"),
            refinements = FluviQueryRefinements(
                minimumAmountScaled100 = queryNumber(
                    refinements,
                    "minimumAmountScaled100",
                )?.toLong(),
                maximumAmountScaled100 = queryNumber(
                    refinements,
                    "maximumAmountScaled100",
                )?.toLong(),
                noteContains = refinements["noteContains"] as String?,
            ),
        )
    }

    private fun dashboardSliceMap(slice: FluviDashboardLedgerSlice): Map<String, Any?> = mapOf(
        "scopeKey" to slice.queryKey,
        "timeScopeKey" to slice.timeScopeKey,
        "direction" to slice.direction.name,
        "totalMinor" to slice.totalMinor,
        "entryCount" to slice.entryCount,
        "coreRevision" to slice.coreRevision,
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
        debugLog(
            "D2 directDbSnapshot " +
                "allIncome=${income.amountScaled100}/${income.entryCount} " +
                "allExpense=${expense.amountScaled100}/${expense.entryCount} " +
                "julyIncome=${julyIncome.amountScaled100}/${julyIncome.entryCount} " +
                "julyExpense=${julyExpense.amountScaled100}/${julyExpense.entryCount}",
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

    private fun requireQueryMap(call: MethodCall): Map<*, *> =
        requireQueryMap(call.arguments, "query arguments")

    private fun requireQueryMap(raw: Any?, label: String): Map<*, *> {
        require(raw is Map<*, *>) { "$label must be a map." }
        return raw
    }

    private fun queryList(arguments: Map<*, *>, key: String): List<Any?> {
        val raw = arguments[key]
        require(raw is List<*>) { "$key must be a list." }
        return raw
    }

    private fun queryStringSet(arguments: Map<*, *>, key: String): Set<String> =
        queryList(arguments, key).map { value ->
            require(value is String) { "$key must contain strings." }
            value
        }.toSet()

    private fun queryNumber(arguments: Map<*, *>, key: String): Number? {
        val raw = arguments[key] ?: return null
        require(raw is Number) { "$key must be numeric." }
        return raw
    }

    private fun queryPageSize(arguments: Map<*, *>): Int {
        val raw = queryNumber(arguments, "pageSize")?.toInt() ?: 50
        require(raw in 1..200) { "pageSize must be between 1 and 200." }
        return raw
    }

    private fun queryCursor(arguments: Map<*, *>): FluviTimelineCursor? {
        val raw = arguments["after"] ?: return null
        val cursor = requireQueryMap(raw, "dashboard cursor")
        return FluviTimelineCursor(
            bookedLocalEpochDay = requireNotNull(
                queryNumber(cursor, "bookedLocalEpochDay"),
            ).toLong(),
            bookedLocalTimeMinutes = requireNotNull(
                queryNumber(cursor, "bookedLocalTimeMinutes"),
            ).toInt(),
            entryId = requireQueryValue(cursor, "entryId"),
        )
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> requireQueryValue(arguments: Map<*, *>, key: String): T =
        requireNotNull(arguments[key]) { "Missing query argument: $key" } as T

    private inline fun <reified T> requireArgument(call: MethodCall, key: String): T =
        requireNotNull(call.argument<T>(key)) { "Missing category argument: $key" }

    companion object {
        const val CATEGORY_CHANNEL = "com.fluvi/category_repository"
        const val QUERY_CHANNEL = "com.fluvi/dashboard_query"
        const val DEMO_CHANNEL = "com.fluvi/demo_data"
        const val DASHBOARD_STREAM_CHANNEL = "com.fluvi/dashboard_query_stream"
        const val DATABASE_FILE_NAME = "fluvi_core.db"
        const val DEBUG_TAG = "FluviDashboard"
    }
}
