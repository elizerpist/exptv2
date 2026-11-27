package com.fluvi.wa

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException
import java.util.UUID
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/** Process-owned native capture. The probe has no reference to the display authority. */
object WaLockscreenCapture {
    private const val MAX_MS = 90_000L
    private const val STEP_MS = 32L
    private const val NS_PER_MS = 1_000_000L
    private val processStart = SystemClock.elapsedRealtimeNanos()
    private val main by lazy { Handler(Looper.getMainLooper()) }
    private val scope by lazy { CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate) }
    private val commands = Mutex()
    private val probes by lazy {
        ScheduledThreadPoolExecutor(1) { run -> Thread(run, "FluviWaStateProbe") }.apply {
            removeOnCancelPolicy = true
            setKeepAliveTime(1, TimeUnit.SECONDS)
            allowCoreThreadTimeOut(true)
        }
    }
    @Volatile private var active: Session? = null
    @Volatile private var visible: WaAttachment? = null
    private var service = 0L
    private var frozen: Frozen? = null
    private var interruption: String? = null
    private var loaded = false
    private var pendingWrite = false

    internal fun serviceConnected(session: Long) { service = session }

    internal fun serviceDisconnected(session: Long) {
        if (service == session) service = 0
    }

    internal fun visible(owner: WaAttachment) { visible = owner }

    internal fun hidden(owner: WaAttachment) {
        if (visible === owner) visible = null
    }

    internal fun callbackTime(): Long = if (active != null) SystemClock.uptimeMillis() else 0

    internal fun record(
        stage: WaStage, source: WaSource, service: Long, episode: Long, owner: WaAttachment?,
        scan: Long = 0, hide: Long = 0, reason: WaHideReason = WaHideReason.NONE,
        received: Long = 0, type: Int = 0, eventTime: Long = 0, state: WaSystemState? = null,
        scene: WaLockscreenScene? = null, barrier: WaBarrier? = null, detail: Long = 0, detailEnd: Long = 0,
    ) {
        val current = active ?: return
        val elapsed = SystemClock.elapsedRealtimeNanos()
        if (elapsed >= current.deadline) return
        val ring = if (stage.terminal) current.terminal else current.events
        ring.add(
            stage, source, service, episode, owner, scan, hide, reason, state, scene, barrier,
            SystemClock.uptimeMillis(), elapsed, received, type, eventTime, detail, detailEnd,
            allowMerge = stage.coalescible && (owner == null || !stage.terminal),
        )
    }

    fun request(
        context: Context, command: String, source: String?, purpose: String?, sizeDp: () -> Int,
        reply: (Map<String, Any?>) -> Unit, error: () -> Unit,
    ) {
        val app = context.applicationContext
        scope.launch {
            try {
                val response = commands.withLock {
                    load(app)
                    if (active?.expired() == true) freeze(app, Stop.LIMIT)
                    when (command) {
                        "start" -> if (active == null) start(app, source, purpose, sizeDp())
                        "stop" -> freeze(app, Stop.STOP)
                        "getFrozen" -> {
                            freeze(app, Stop.COPY)
                            persist(app)
                        }
                    }
                    status(app).also {
                        if (command == "getFrozen") it["text"] = frozen?.text
                    }
                }
                reply(response)
            } catch (_: Exception) {
                error()
            }
        }
    }

    private suspend fun start(context: Context, source: String?, purpose: String?, sizeDp: Int) {
        val identity = withContext(Dispatchers.IO) {
            val pkg = context.packageManager.getPackageInfo(context.packageName, 0)
            @Suppress("DEPRECATION")
            val code = if (Build.VERSION.SDK_INT >= 28) pkg.longVersionCode else pkg.versionCode.toLong()
            BuildIdentity(
                source?.takeIf { it.length == 40 && it.all { c -> c in '0'..'9' || c in 'a'..'f' } } ?: "UNOBSERVED",
                purpose?.takeIf { it in listOf("HUMAN_DIAGNOSTIC", "AUTOMATED_PROFILE_TEST", "NORMAL_APP") } ?: "UNOBSERVED",
                safeToken(pkg.versionName.orEmpty()), code,
            )
        }
        val id = UUID.randomUUID().toString()
        withContext(Dispatchers.IO) { write(marker(context), id) }
        val session = Session(id, identity, sizeDp, service, WaSystemReader(context))
        interruption = null
        session.limit = Runnable {
            scope.launch {
                commands.withLock { if (active === session) freeze(context, Stop.LIMIT) }
            }
        }
        active = session
        session.probe = probes.scheduleWithFixedDelay(session::sample, 0, STEP_MS, TimeUnit.MILLISECONDS)
        main.postDelayed(session.limit, MAX_MS)
    }

    private suspend fun freeze(context: Context, stop: Stop) {
        val current = active ?: return
        val up = SystemClock.uptimeMillis()
        val elapsed = SystemClock.elapsedRealtimeNanos()
        active = null
        main.removeCallbacks(current.limit)
        current.probe?.cancel(false)
        frozen = withContext(Dispatchers.Default) { current.snapshot(up, elapsed, stop) }
        pendingWrite = true
        persist(context)
    }

    private suspend fun persist(context: Context) {
        if (!pendingWrite) return
        val snapshot = frozen ?: return
        val saved = withContext(Dispatchers.IO) {
            try {
                write(file(context), snapshot.text)
                marker(context).delete()
                true
            } catch (_: Exception) {
                false
            }
        }
        pendingWrite = !saved
    }

    private suspend fun load(context: Context) {
        if (loaded) return
        val (snapshot, marker) = withContext(Dispatchers.IO) {
            val snapshot = read(file(context))?.let(Frozen::parse)
            val running = read(marker(context), 64)?.takeIf { it != snapshot?.id }
            snapshot to running
        }
        frozen = snapshot
        interruption = marker
        loaded = true
    }

    private suspend fun status(context: Context): MutableMap<String, Any?> {
        val current = active
        val last = frozen
        val serviceStatus = if (service != 0L) "CONNECTED" else withContext(Dispatchers.IO) {
            val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                .orEmpty().split(':').mapNotNull(ComponentName::unflattenFromString)
            if (enabled.contains(ComponentName(context.packageName, "tk.zwander.lockscreenwidgets.services.Accessibility"))) {
                "DISCONNECTED"
            } else "DISABLED"
        }
        return mutableMapOf(
            "state" to when {
                current != null -> "RECORDING"
                interruption != null -> "INTERRUPTED"
                last != null -> "FROZEN"
                else -> "IDLE"
            },
            "id" to (current?.id ?: interruption ?: last?.id),
            "elapsedMs" to (current?.duration(SystemClock.elapsedRealtimeNanos()) ?: last?.elapsedMs ?: 0L),
            "drops" to (current?.drops() ?: last?.drops ?: 0),
            "service" to serviceStatus,
            "hasCapture" to (current != null || last != null),
            "storageError" to pendingWrite,
        )
    }

    private fun file(context: Context) = AtomicFile(File(context.noBackupFilesDir, "wa-lockscreen-frozen.txt"))
    private fun marker(context: Context) = AtomicFile(File(context.noBackupFilesDir, "wa-lockscreen-running"))

    private fun write(file: AtomicFile, text: String) {
        val output = file.startWrite()
        try {
            output.write(text.toByteArray(Charsets.UTF_8))
            file.finishWrite(output)
        } catch (failure: Exception) {
            file.failWrite(output)
            throw failure
        }
    }

    private fun read(file: AtomicFile, max: Int = WA_CAPTURE_BYTES): String? = try {
        file.openRead().use { handle ->
            val bytes = ByteArray(max + 1)
            var count = 0
            while (count < bytes.size) {
                val read = handle.read(bytes, count, bytes.size - count)
                if (read < 0) break
                count += read
            }
            if (count <= max) String(bytes, 0, count, Charsets.UTF_8) else null
        }
    } catch (_: FileNotFoundException) {
        null
    }

    private fun safeToken(value: String): String = value.take(64).map { if (it in '!'..'~') it else '_' }.joinToString("")

    private enum class Stop { LIMIT, STOP, COPY }

    private data class BuildIdentity(val sha: String, val purpose: String, val version: String, val code: Long)

    private data class Frozen(val id: String, val elapsedMs: Long, val drops: Int, val text: String) {
        companion object {
            fun parse(text: String): Frozen? {
                if (!text.startsWith("$WA_CAPTURE_MAGIC\n")) return null
                val start = text.lastIndexOf("\nsha256=") + 1
                if (start == 0 || text.substring(start) != "sha256=${waCaptureDigest(text.substring(0, start))}\n") return null
                val fields = text.lineSequence().take(9).drop(1).flatMap { it.split(' ').asSequence() }
                    .mapNotNull { field -> field.indexOf('=').takeIf { it > 0 }?.let { field.take(it) to field.substring(it + 1) } }
                    .toMap()
                return Frozen(
                    fields["capture"] ?: return null,
                    fields["durationMs"]?.toLongOrNull() ?: return null,
                    (fields["ringDrops"]?.toIntOrNull() ?: return null) + (fields["textDropped"]?.toIntOrNull() ?: 0),
                    text,
                )
            }
        }
    }

    private class Session(
        val id: String, private val identity: BuildIdentity, private val sizeDp: Int,
        private val initialService: Long, private val reader: WaSystemReader,
    ) {
        private val startUp = SystemClock.uptimeMillis()
        private val startElapsed = SystemClock.elapsedRealtimeNanos()
        val deadline = startElapsed + MAX_MS * NS_PER_MS
        private val sequence = AtomicLong()
        val events = WaTraceRing(408, sequence)
        val terminal = WaTraceRing(112, sequence)
        private val samples = WaTraceRing(76, sequence)
        private val windows = ArrayList<ProbeEpisode>(3)
        @Volatile private var probeDrops = 0
        private var skipped = 0
        private var busy = 0
        private var lastCheck = 0L
        var probe: ScheduledFuture<*>? = null
        // The command layer supplies the app context below. The visible owner
        // stays independent of Flutter, including while the Activity is gone.
        lateinit var limit: Runnable

        fun expired() = SystemClock.elapsedRealtimeNanos() >= deadline
        fun duration(elapsed: Long) = ((elapsed - startElapsed) / NS_PER_MS).coerceIn(0, MAX_MS)
        fun drops() = events.dropped + terminal.dropped + probeDrops

        fun sample() {
            val began = SystemClock.elapsedRealtimeNanos()
            if (active !== this || began >= deadline) return
            val owner = visible
            if (owner == null) {
                synchronized(samples) { skipped++ }
                return
            }
            val span = windows.firstOrNull { it.service == owner.service && it.episode == owner.episode }
                ?: if (windows.size < 3) {
                    ProbeEpisode(owner.service, owner.episode, began).also(windows::add)
                } else null
            if (span == null || began - span.began >= 10_000L * NS_PER_MS) {
                synchronized(samples) { skipped++ }
                return
            }
            val up = SystemClock.uptimeMillis()
            val state = reader.read(complete = true)
            val end = SystemClock.elapsedRealtimeNanos()
            synchronized(samples) {
                if (active !== this || end >= deadline) return
                if (end - began >= STEP_MS * NS_PER_MS) busy++
                val contiguous = lastCheck != 0L && began - lastCheck <= 2 * STEP_MS * NS_PER_MS
                lastCheck = end
                val changedOwner = visible !== owner
                samples.add(
                    WaStage.PROBE, WaSource.PROBE, owner.service, owner.episode, owner, 0, 0,
                    WaHideReason.NONE, state, null, null, up, began, 0, if (changedOwner) 1 else 0,
                    0, 0, end, allowMerge = contiguous && !changedOwner,
                )
                probeDrops = samples.dropped
            }
        }

        fun snapshot(up: Long, elapsed: Long, stop: Stop): Frozen = synchronized(samples) {
            val elapsedMs = duration(elapsed)
            val ringDrops = drops()
            val header = buildString {
                append("$WA_CAPTURE_MAGIC\n")
                append("build=${identity.sha} purpose=${identity.purpose} version=${identity.version} code=${identity.code} api=${Build.VERSION.SDK_INT} model=${safeToken(Build.MODEL)}\n")
                append("capture=$id state=FROZEN stop=$stop route=WA_BALANCE process=${Process.myPid()}-$processStart initialService=$initialService sizeDp=$sizeDp\n")
                append("startUp=$startUp startEl=$startElapsed endUp=$up endEl=$elapsed durationMs=$elapsedMs\n")
                append("physicalFirstOrb=UNOBSERVED firstForbiddenFrame=UNOBSERVED physicalLastOrb=UNOBSERVED\n")
                append("up=uptimeMillis el=elapsedRealtimeNanos eventUp=accessibilityEventTime receipts=software_only\n")
                append("observed=${events.observed + terminal.observed + samples.observed} coalesced=${events.coalesced + terminal.coalesced + samples.coalesced} ringDrops=$ringDrops ringTruncated=${ringDrops > 0} probeRead=${samples.observed} probeSkipped=$skipped probeBusy=$busy\n")
            }
            val (text, textDrops) = waCaptureText(header, events.rows() + terminal.rows() + samples.rows())
            Frozen(id, elapsedMs, ringDrops + textDrops, text)
        }
    }

    private data class ProbeEpisode(val service: Long, val episode: Long, val began: Long)
}
