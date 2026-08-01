package com.fluvi.app

import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviCategory
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
    }

    override fun onDestroy() {
        categoryChannel?.setMethodCallHandler(null)
        categoryChannel = null
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

    private inline fun <reified T> requireArgument(call: MethodCall, key: String): T =
        requireNotNull(call.argument<T>(key)) { "Missing category argument: $key" }

    companion object {
        const val CATEGORY_CHANNEL = "com.fluvi/category_repository"
    }
}
