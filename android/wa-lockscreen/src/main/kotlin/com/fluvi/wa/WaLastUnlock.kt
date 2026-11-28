package com.fluvi.wa

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.util.concurrent.Executors

internal data class WaTime(val uptimeMs: Long, val elapsedNs: Long) {
    companion object {
        fun now() = WaTime(SystemClock.uptimeMillis(), SystemClock.elapsedRealtimeNanos())
    }
}

/** The service's existing terminal decision for this exact attachment. */
class WaUnlockTrigger internal constructor(
    internal val owner: WaAttachment,
    internal val reason: WaHideReason,
    internal val source: WaSource,
    internal val type: Int,
    internal val eventUptimeMs: Long,
    internal val callbackUptimeMs: Long,
    internal val decision: WaTime,
    internal val read: WaGateRead?,
)

internal data class WaGateRead(val begin: WaTime, val end: WaTime, val state: WaSystemState)

internal data class WaUnlockProduct(
    val packageName: String,
    val sourceCommit: String,
    val version: String,
    val versionCode: Long,
    val model: String,
    val sdk: Int,
) {
    companion object {
        @Suppress("DEPRECATION")
        fun read(context: Context): WaUnlockProduct {
            val info = context.packageManager.getPackageInfo(context.packageName, 0)
            return WaUnlockProduct(
                context.packageName, context.getString(R.string.fluvi_wa_source_commit),
                info.versionName.orEmpty(),
                if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong(),
                Build.MODEL, Build.VERSION.SDK_INT,
            )
        }
    }
}

internal data class WaChildHide(
    val status: String,
    val request: WaTime? = null,
    val returned: WaTime? = null,
    val commitListener: String = "UNOBSERVED",
    val error: String? = null,
)

internal data class WaRemoval(
    val begin: WaTime,
    val end: WaTime,
    val detached: Boolean,
    val error: String?,
)

internal enum class WaPresenter { SURFACE_CHILD, LEGACY_API, LEGACY_FALLBACK }

/** Copies of these scalars go to disk. Only the exact window draft is mutable on Main. */
internal data class WaUnlockRecord(
    val product: WaUnlockProduct,
    val trigger: WaUnlockTrigger,
    val display: Int,
    val presenter: WaPresenter,
    val presenterFailure: String?,
    val sizeDp: Int,
    val style: WaOrbStyle,
    val hideId: Long,
    val attached: WaTime?,
    val child: WaChildHide,
    val childCommit: WaTime? = null,
    val localHide: WaTime? = null,
    val detached: WaTime? = null,
    val firstRemove: WaRemoval? = null,
    val retry: WaRemoval? = null,
    val hostStop: WaTime? = null,
    val hostStopStatus: String = "UNOBSERVED",
) {
    fun text(): String {
        val body = buildString {
            appendLine(WaLastUnlock.MAGIC)
            appendLine("package=${product.packageName} build=${product.sourceCommit} version=${field(product.version)} code=${product.versionCode}")
            appendLine("model=${field(product.model)} api=${product.sdk} presenter=$presenter presenterError=${field(presenterFailure)}")
            val owner = trigger.owner
            appendLine("display=$display serviceElapsedNs=${owner.service} episode=${owner.episode} window=${owner.window} attachment=${owner.service}/${owner.window} widget=${owner.widget} sizeDp=$sizeDp style=$style hide=$hideId")
            appendLine("source=${trigger.source} reason=${trigger.reason} eventType=${trigger.type} eventUptimeMs=${time(trigger.eventUptimeMs)} callbackUptimeMs=${time(trigger.callbackUptimeMs)}")
            val state = trigger.read?.state
            appendLine("gateDisplay=${state?.displayState ?: MISSING} interactive=${state?.interactive ?: MISSING} locked=${state?.locked ?: MISSING}")
            stamp("gateReadBegin", trigger.read?.begin)
            stamp("gateReadEnd", trigger.read?.end)
            stamp("decision", trigger.decision)
            stamp("attach", attached)
            appendLine("childHide=${child.status} childError=${field(child.error)} childCommitListener=${if (childCommit == null) child.commitListener else "OBSERVED"}")
            stamp("childHideRequest", child.request)
            stamp("childApplyReturn", child.returned)
            stamp("childCommitMainReceipt", childCommit)
            stamp("localHide", localHide)
            stamp("detach", detached)
            removal("remove", firstRemove)
            removal("retry", retry)
            stamp("hostStop", hostStop)
            appendLine("hostStopStatus=$hostStopStatus")
            appendLine("physicalLastOrbPixel=UNOBSERVED physicalFirstRestrictedFrame=UNOBSERVED")
        }
        return "${body}bodySha256=${waCaptureDigest(body)}\n"
    }

    private fun StringBuilder.stamp(label: String, value: WaTime?) {
        appendLine("${label}UptimeMs=${time(value?.uptimeMs)} ${label}ElapsedNs=${time(value?.elapsedNs)}")
    }

    private fun StringBuilder.removal(label: String, value: WaRemoval?) {
        stamp("${label}Begin", value?.begin)
        stamp("${label}Return", value?.end)
        appendLine("${label}Detached=${value?.detached ?: MISSING} ${label}Error=${if (value == null) MISSING else field(value.error ?: "NONE")}")
    }

    private companion object {
        const val MISSING = "UNOBSERVED"
        fun time(value: Long?) = value?.takeIf { it > 0 }?.toString() ?: MISSING
        fun field(value: String?) = value?.take(64)?.replace(Regex("[^a-zA-Z0-9._()-]"), "_") ?: MISSING
    }
}

/** Main owns admission order. A receipt can update only the latest accepted window. */
internal class WaUnlockHead {
    private var latest: WaUnlockRecord? = null

    fun accept(record: WaUnlockRecord): Boolean {
        val before = latest
        if (record.firstRemove == null || before == record ||
            (before != null && record.trigger.decision.elapsedNs <= before.trigger.decision.elapsedNs &&
                record.trigger !== before.trigger)
        ) return false
        latest = record
        return true
    }
}

/** Receipt delivery can outlive the view. Keep only the report and application context. */
internal class WaUnlockDraft(private val app: Context) {
    var record: WaUnlockRecord? = null

    fun update(change: (WaUnlockRecord) -> WaUnlockRecord) {
        val next = change(record ?: return)
        record = next
        WaLastUnlock.publish(app, next)
    }

    fun committed(at: WaTime) = update { it.copy(childCommit = it.childCommit ?: at) }
}

/** Latest ordinary unlock, independently of the opt-in V1/V2 recorder. */
object WaLastUnlock {
    internal const val MAGIC = "FLUVI_WA_LAST_UNLOCK_V1"
    internal const val LIMIT = 4096
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor { task -> Thread(task, "FluviLastUnlock") }
    private val head = WaUnlockHead()
    private var connected = 0L
    // Accessed only on the serial IO thread. A failed write leaves the old file intact.
    private var pendingWrite: WaUnlockRecord? = null

    internal fun connected(session: Long) { connected = session }

    internal fun disconnected(session: Long) {
        if (connected == session) connected = 0
    }

    internal fun publish(context: Context, record: WaUnlockRecord) {
        if (!head.accept(record)) return
        val app = context.applicationContext
        io.execute {
            pendingWrite = record
            save(app)
        }
    }

    fun request(context: Context, reply: (Map<String, String>) -> Unit) {
        val app = context.applicationContext
        val empty = if (connected != 0L) "EMPTY" else "INACTIVE"
        io.execute {
            val response = try {
                if (!save(app)) throw IOException("Last unlock write failed")
                val text = read(app)
                if (text == null) mapOf("status" to empty)
                else mapOf("status" to "READY", "text" to text)
            } catch (_: IOException) {
                mapOf("status" to "STORAGE_ERROR")
            } catch (_: RuntimeException) {
                mapOf("status" to "STORAGE_ERROR")
            }
            main.post { reply(response) }
        }
    }

    private fun file(context: Context) = AtomicFile(File(context.noBackupFilesDir, "wa-last-unlock.txt"))

    private fun save(context: Context): Boolean {
        val record = pendingWrite ?: return true
        return try {
            val bytes = record.text().toByteArray(Charsets.UTF_8)
            check(bytes.size <= LIMIT)
            val storage = file(context)
            val stream = storage.startWrite()
            try {
                stream.write(bytes)
                stream.fd.sync()
                storage.finishWrite(stream)
            } catch (error: Exception) {
                storage.failWrite(stream)
                throw error
            }
            check(read(context)?.toByteArray(Charsets.UTF_8)?.contentEquals(bytes) == true)
            pendingWrite = null
            true
        } catch (_: IOException) {
            false
        } catch (_: RuntimeException) {
            false
        }
    }

    private fun read(context: Context): String? {
        val storage = file(context)
        val text = try {
            storage.openRead().buffered().use { input ->
                val bytes = ByteArray(LIMIT + 1)
                var size = 0
                while (size < bytes.size) {
                    val count = input.read(bytes, size, bytes.size - size)
                    if (count < 0) break
                    size += count
                }
                if (size > LIMIT) throw IOException("Last unlock size")
                String(bytes, 0, size, Charsets.UTF_8)
            }
        } catch (error: FileNotFoundException) {
            if (storage.baseFile.exists()) throw error
            return null
        }
        val bodyEnd = text.lastIndexOf("bodySha256=")
        if (!text.startsWith("$MAGIC\n") || bodyEnd < 0 ||
            text.substring(bodyEnd) != "bodySha256=${waCaptureDigest(text.substring(0, bodyEnd))}\n"
        ) throw IOException("Last unlock digest")
        return text
    }
}
