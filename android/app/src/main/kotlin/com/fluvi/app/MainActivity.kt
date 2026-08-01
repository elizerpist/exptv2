package com.fluvi.app

import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryRefinements
import com.fluvi.core.query.FluviQueryScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var core: FluviCore? = null
    private var categoryChannel: MethodChannel? = null
    private var queryChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val fluviCore = FluviCoreFactory.create(applicationContext)
        core = fluviCore
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
    }

    override fun onDestroy() {
        categoryChannel?.setMethodCallHandler(null)
        categoryChannel = null
        queryChannel?.setMethodCallHandler(null)
        queryChannel = null
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
            val queryScope = queryScopeFrom(call)
            val total = fluviCore.query.total(queryScope)
            val timeline = fluviCore.query.timeline(queryScope)
            val coreRevision = fluviCore.query.currentCoreRevision()
            mapOf(
                "scopeKey" to requireQueryArgument<String>(call, "scopeKey"),
                "totalMinor" to total.amountScaled100,
                "entryCount" to total.entryCount,
                "coreRevision" to coreRevision,
                "entries" to timeline.entries.map(::ledgerEntryMap),
                "nextCursor" to timeline.nextCursor?.let { cursor ->
                    mapOf(
                        "bookedLocalEpochDay" to cursor.bookedLocalEpochDay,
                        "bookedLocalTimeMinutes" to cursor.bookedLocalTimeMinutes,
                        "entryId" to cursor.entryId,
                    )
                },
            )
        }
        else -> throw IllegalArgumentException("Unknown query method: ${call.method}")
    }

    private fun queryScopeFrom(call: MethodCall): FluviQueryScope {
        val arguments = requireQueryMap(call)
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

    private fun ledgerEntryMap(entry: FluviLedgerEntryEntity): Map<String, Any?> = mapOf(
        "id" to entry.id,
        "partnerId" to entry.partnerId,
        "categoryId" to entry.categoryId,
        "direction" to entry.direction.name,
        "amountMinor" to entry.amountScaled100,
        "bookedLocalEpochDay" to entry.bookedLocalEpochDay,
        "bookedLocalTimeMinutes" to entry.bookedLocalTimeMinutes,
        "note" to entry.note,
        "occurredAtUtcMs" to entry.occurredAtUtcMs,
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

    @Suppress("UNCHECKED_CAST")
    private fun <T> requireQueryValue(arguments: Map<*, *>, key: String): T =
        requireNotNull(arguments[key]) { "Missing query argument: $key" } as T

    private inline fun <reified T> requireQueryArgument(
        call: MethodCall,
        key: String,
    ): T = requireNotNull(call.argument<T>(key)) { "Missing query argument: $key" }

    private inline fun <reified T> requireArgument(call: MethodCall, key: String): T =
        requireNotNull(call.argument<T>(key)) { "Missing category argument: $key" }

    companion object {
        const val CATEGORY_CHANNEL = "com.fluvi/category_repository"
        const val QUERY_CHANNEL = "com.fluvi/dashboard_query"
    }
}
