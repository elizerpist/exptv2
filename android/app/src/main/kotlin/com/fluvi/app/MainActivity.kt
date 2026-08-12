package com.fluvi.app

import android.content.pm.ApplicationInfo
import android.os.Looper
import android.util.Log
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.app.dashboard.DashboardBinaryCodec
import com.fluvi.app.dashboard.DashboardPreparedIndexAcquisitionReasons
import com.fluvi.app.dashboard.DashboardPreparedIndexQueryGenerationOwner
import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.app.query.QueryMenuMethodBridge
import io.flutter.plugin.common.EventChannel
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
    private var core: FluviCore? = null
    private var categoryChannel: MethodChannel? = null
    private var queryChannel: MethodChannel? = null
    private var queryMenuChannel: MethodChannel? = null
    private var demoChannel: MethodChannel? = null
    private var coreRevisionEventChannel: EventChannel? = null
    private var coreRevisionObservation: Job? = null
    private var diagnosticEventChannel: EventChannel? = null
    private var diagnosticEventSink: EventChannel.EventSink? = null
    private val preparedQueryGenerationOwner = DashboardPreparedIndexQueryGenerationOwner()

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

    override fun onDestroy() {
        categoryChannel?.setMethodCallHandler(null)
        categoryChannel = null
        queryChannel?.setMethodCallHandler(null)
        queryMenuChannel?.setMethodCallHandler(null)
        queryChannel = null
        demoChannel?.setMethodCallHandler(null)
        demoChannel = null
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

    private data class PreparedQueryRequestIdentity(
        val generation: Long,
        val direction: LedgerDirection?,
    )

    private fun dispatchQueryCall(
        call: MethodCall,
        result: MethodChannel.Result,
        fluviCore: FluviCore,
    ) {
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
        job = scope.launch(start = CoroutineStart.LAZY) {
            try {
                val value = withContext(Dispatchers.IO) {
                    handleQueryCall(call, fluviCore)
                }
                result.success(value)
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
        const val QUERY_CHANNEL = "com.fluvi/dashboard_query"
        const val QUERY_MENU_CHANNEL = "com.fluvi/query_menu"
        const val DEMO_CHANNEL = "com.fluvi/demo_data"
        const val DASHBOARD_CORE_REVISION_STREAM_CHANNEL =
            "com.fluvi/dashboard_core_revision_stream"
        const val DIAGNOSTIC_CHANNEL = "com.fluvi/diagnostics"
        const val DATABASE_FILE_NAME = "fluvi_core.db"
        const val DEBUG_TAG = "FluviDashboard"
    }
}
