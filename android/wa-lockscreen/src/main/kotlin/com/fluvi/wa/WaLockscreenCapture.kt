package com.fluvi.wa

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import android.util.AtomicFile
import android.os.Trace
import android.view.accessibility.AccessibilityEvent
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
    private var connection: Connection? = null
    private var lastLease: WaCaptureTimeout.Lease? = null
    private var lastGeneration: Long? = null
    private var armError: WaCaptureTimeout.Error? = null
    private var frozen: Frozen? = null
    private var interruption: String? = null
    private var loaded = false
    private var pendingWrite = false

    private class Connection(
        val context: Context, val generation: Long, val timeout: WaCaptureTimeout,
        val hasWindow: () -> Boolean,
    )

    internal fun serviceConnected(
        context: Context, generation: Long, timeout: WaCaptureTimeout, hasWindow: () -> Boolean,
    ) {
        connection?.let { serviceDisconnected(it.generation) }
        timeout.normalize()
        connection = Connection(context, generation, timeout, hasWindow)
    }

    internal fun serviceDisconnected(session: Long) {
        val previous = connection?.takeIf { it.generation == session } ?: return
        connection = null
        val recording = active?.takeIf { it.connection === previous }
        if (recording == null) {
            previous.timeout.retryPendingRestoration()
            return
        }
        recording.interrupted = true
        previous.timeout.restore(recording.lease, disconnected = true)
        scope.launch {
            commands.withLock {
                if (active === recording) freeze(previous.context, Stop.SERVICE_DISCONNECTED)
            }
        }
    }

    internal fun visible(owner: WaAttachment) { visible = owner }

    internal fun hidden(owner: WaAttachment) {
        if (visible === owner) visible = null
    }

    internal fun callbackTime(): Long {
        val current = active ?: return 0
        if (current.interrupted || current.expired()) return 0
        return SystemClock.uptimeMillis()
    }

    internal fun captureId(): String? = active?.id

    internal fun scanEnded(capture: String?) {
        active?.takeIf { capture != null && it.id == capture }?.evidence?.scanEnded()
    }

    internal fun ingress(
        source: WaSource, service: Long, episode: Long, owner: WaAttachment?,
        received: Long, receivedElapsed: Long, event: AccessibilityEvent? = null, eventTime: Long = 0,
    ) {
        val current = active ?: return
        if (received == 0L) return
        val name = event?.packageName?.toString()
        val origin = when {
            name == null -> WaEventClass.UNKNOWN
            name == current.connection.context.packageName -> WaEventClass.OWN
            name == current.home -> WaEventClass.HOME
            name in WaLockscreenScene.systemUiPackages -> WaEventClass.SYSTEM_UI
            else -> WaEventClass.OTHER
        }
        val type = event?.eventType ?: 0
        val display = if (event == null) 0 else if (Build.VERSION.SDK_INT >= 33) event.displayId else -1
        record(
            WaStage.CALLBACK, source, service, episode, owner, received = received, type = type, eventTime = eventTime,
            atUp = received, atElapsed = receivedElapsed, displayId = display,
            windowAlias = current.alias(event?.windowId ?: -1), eventClass = origin,
            windowChanges = if (Build.VERSION.SDK_INT >= 28 && type == AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                event?.windowChanges ?: -1 else -1,
            contentChanges = if (type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)
                event?.contentChangeTypes ?: -1 else -1,
        )
    }

    internal fun record(
        stage: WaStage, source: WaSource, service: Long, episode: Long, owner: WaAttachment?,
        scan: Long = 0, hide: Long = 0, reason: WaHideReason = WaHideReason.NONE,
        received: Long = 0, type: Int = 0, eventTime: Long = 0, state: WaSystemState? = null,
        scene: WaLockscreenScene? = null, barrier: WaBarrier? = null, detail: Long = 0, detailEnd: Long = 0,
        atUp: Long = 0, atElapsed: Long = 0, displayId: Int = 0, windowAlias: Int = 0,
        eventClass: WaEventClass = WaEventClass.UNKNOWN, windowChanges: Int = -1, contentChanges: Int = -1,
    ) {
        val current = active ?: return
        val elapsed = if (atElapsed != 0L) atElapsed else SystemClock.elapsedRealtimeNanos()
        if (current.interrupted || service != current.connection.generation || elapsed >= current.deadline) return
        val ring = if (stage.terminal) current.terminal else current.events
        val row = ring.add(
            stage, source, service, episode, owner, scan, hide, reason, state, scene, barrier,
            if (atUp != 0L) atUp else SystemClock.uptimeMillis(), elapsed, received, type, eventTime, detail, detailEnd,
            allowMerge = stage.coalescible && (owner == null || !stage.terminal),
            displayId, windowAlias, eventClass, windowChanges, contentChanges,
        )
        current.evidence.observe(row)
        trace(current.lease.requested, row)
    }

    private fun trace(arm: Long, row: WaTraceRing.Row) {
        val owner = row.owner ?: return
        if (Build.VERSION.SDK_INT < 29) return
        val name = when (row.stage) {
            WaStage.CALLBACK -> "FluviR52.callback"
            WaStage.ATTACH -> "FluviR52.attach"
            WaStage.DECISION -> "FluviR52.decision"
            WaStage.LOCAL_HIDE -> "FluviR52.localHide"
            WaStage.DETACHED -> "FluviR52.detached"
            WaStage.REMOVE_RETURN -> "FluviR52.removeReturn"
            WaStage.REMOVE_ERROR -> "FluviR52.removeError"
            else -> return
        }
        if (!Trace.isEnabled()) return
        Trace.setCounter("fluvi.r52.armMs", arm)
        Trace.setCounter("fluvi.r52.service", row.service)
        Trace.setCounter("fluvi.r52.episode", row.episode)
        Trace.setCounter("fluvi.r52.window", owner.window)
        Trace.setCounter("fluvi.r52.widget", owner.widget.toLong())
        Trace.setCounter("fluvi.r52.hide", row.hide)
        Trace.setCounter("fluvi.r52.sequence", row.sequence)
        Trace.setCounter("fluvi.r52.upMs", row.up)
        Trace.setCounter("fluvi.r52.elapsedNs", row.elapsed)
        Trace.beginSection(name)
        Trace.endSection()
    }

    fun request(
        context: Context, command: String, source: String?, purpose: String?, arm: Int?,
        sizeDp: () -> Int, foreground: () -> Boolean,
        reply: (Map<String, Any?>) -> Unit, error: () -> Unit,
    ) {
        val app = context.applicationContext
        scope.launch {
            try {
                val response = commands.withLock {
                    load(app)
                    if (active?.interrupted == true) freeze(app, Stop.SERVICE_DISCONNECTED)
                    else if (active?.expired() == true) freeze(app, Stop.LIMIT)
                    if (command != "status") armError = null
                    when (command) {
                        "start" -> {
                            connection?.timeout?.retryPendingRestoration()
                            armError = start(app, source, purpose, arm, sizeDp, foreground)
                        }
                        "stop" -> {
                            freeze(app, Stop.STOP)
                            connection?.timeout?.retryPendingRestoration()
                        }
                        "getFrozen" -> {
                            freeze(app, Stop.COPY)
                            connection?.timeout?.retryPendingRestoration()
                            persist(app)
                        }
                    }
                    val session = active
                    if (session != null) {
                        session.connection.timeout.verify(session.lease)
                        if (session.lease.error != null) freeze(app, Stop.INVALID)
                    }
                    status(app, armAvailable = purpose == "HUMAN_DIAGNOSTIC").also {
                        if (command == "getFrozen") it["text"] = frozen?.text
                    }
                }
                reply(response)
            } catch (_: Exception) {
                error()
            }
        }
    }

    private suspend fun start(
        context: Context, source: String?, purpose: String?, arm: Int?,
        sizeDp: () -> Int, foreground: () -> Boolean,
    ): WaCaptureTimeout.Error? {
        if (active != null) return WaCaptureTimeout.Error.ALREADY_RECORDING
        if (!foreground()) return WaCaptureTimeout.Error.FOREGROUND_REQUIRED
        val owner = connection ?: return WaCaptureTimeout.Error.SERVICE_UNAVAILABLE
        if (owner.hasWindow()) return WaCaptureTimeout.Error.WINDOW_ACTIVE
        val requested = arm?.toLong() ?: WaCaptureTimeout.ORDINARY
        if (requested !in listOf(0L, WaCaptureTimeout.ORDINARY) ||
            (arm != null && purpose != "HUMAN_DIAGNOSTIC")) return WaCaptureTimeout.Error.INVALID_ARM
        val id = UUID.randomUUID().toString()
        val (identity, home) = withContext(Dispatchers.IO) {
            val pkg = context.packageManager.getPackageInfo(context.packageName, 0)
            @Suppress("DEPRECATION")
            val code = if (Build.VERSION.SDK_INT >= 28) pkg.longVersionCode else pkg.versionCode.toLong()
            val home = context.packageManager.resolveActivity(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), PackageManager.MATCH_DEFAULT_ONLY,
            )?.activityInfo?.packageName
            val identity = BuildIdentity(
                source?.takeIf { it.length == 40 && it.all { c -> c in '0'..'9' || c in 'a'..'f' } } ?: "UNOBSERVED",
                purpose?.takeIf { it in listOf("HUMAN_DIAGNOSTIC", "AUTOMATED_PROFILE_TEST", "NORMAL_APP") } ?: "UNOBSERVED",
                safeToken(pkg.versionName.orEmpty()), code,
            )
            write(marker(context), id)
            identity to home
        }
        val problem = when {
            connection !== owner -> WaCaptureTimeout.Error.SERVICE_UNAVAILABLE
            !foreground() -> WaCaptureTimeout.Error.FOREGROUND_REQUIRED
            owner.hasWindow() -> WaCaptureTimeout.Error.WINDOW_ACTIVE
            else -> null
        }
        val armResult = if (problem == null) owner.timeout.arm(id, requested)
            else WaCaptureTimeout.ArmResult(null, problem)
        val lease = armResult.lease
        if (lease != null) {
            lastLease = lease
            lastGeneration = owner.generation
        }
        if (lease == null || armResult.error != null) {
            withContext(Dispatchers.IO) { marker(context).delete() }
            return armResult.error
        }
        val session = try {
            Session(id, identity, sizeDp(), owner, lease, home, WaSystemReader(context))
        } catch (_: RuntimeException) {
            owner.timeout.restore(lease)
            withContext(Dispatchers.IO) { marker(context).delete() }
            return WaCaptureTimeout.Error.CAPTURE_SETUP_FAILED
        }
        interruption = null
        session.limit = Runnable {
            scope.launch {
                commands.withLock { if (active === session) freeze(context, Stop.LIMIT) }
            }
        }
        active = session
        try {
            session.probe = probes.scheduleWithFixedDelay(session::sample, 0, STEP_MS, TimeUnit.MILLISECONDS)
            main.postDelayed(session.limit, MAX_MS)
        } catch (_: RuntimeException) {
            lease.error = WaCaptureTimeout.Error.CAPTURE_SETUP_FAILED
            freeze(context, Stop.INVALID)
            return lease.error
        }
        return null
    }

    private suspend fun freeze(context: Context, stop: Stop) {
        val current = active ?: return
        val up = SystemClock.uptimeMillis()
        val elapsed = SystemClock.elapsedRealtimeNanos()
        active = null
        main.removeCallbacks(current.limit)
        current.probe?.cancel(false)
        current.connection.timeout.restore(current.lease)
        val outcome = when {
            current.interrupted -> Stop.SERVICE_DISCONNECTED
            current.lease.error != null -> Stop.INVALID
            else -> stop
        }
        val armReport = ArmReport(
            current.lease.requested, current.lease.baseline, current.lease.readback,
            current.lease.restoration, current.lease.restoreReadback, current.lease.error,
        )
        frozen = withContext(Dispatchers.Default) { current.snapshot(up, elapsed, outcome, armReport) }
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

    private suspend fun status(context: Context, armAvailable: Boolean): MutableMap<String, Any?> {
        val current = active
        val last = frozen
        val serviceStatus = if (connection != null) "CONNECTED" else withContext(Dispatchers.IO) {
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
                last != null -> last.state
                else -> "IDLE"
            },
            "id" to (current?.id ?: interruption ?: last?.id),
            "elapsedMs" to (current?.duration(SystemClock.elapsedRealtimeNanos()) ?: last?.elapsedMs ?: 0L),
            "drops" to (current?.drops() ?: last?.drops ?: 0),
            "service" to serviceStatus,
            "hasCapture" to (current != null || last != null),
            "storageError" to pendingWrite,
            "armAvailable" to armAvailable,
            "armMs" to (current?.lease?.requested ?: lastLease?.requested),
            "effectiveMs" to connection?.timeout?.read(),
            "restoration" to when {
                current != null -> current.lease.restoration.name
                lastLease != null && lastGeneration == connection?.generation -> lastLease?.restoration?.name
                connection != null -> connection?.timeout?.normalization?.name
                else -> lastLease?.restoration?.name
            },
            "baselineStatus" to connection?.timeout?.normalization?.name,
            "armError" to (armError ?: lastLease?.error)?.name,
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

    private enum class Stop { LIMIT, STOP, COPY, SERVICE_DISCONNECTED, INVALID }

    private data class ArmReport(
        val requested: Long, val baseline: Long, val readback: Long?, val restoration: WaCaptureTimeout.Restoration,
        val restoreReadback: Long?, val error: WaCaptureTimeout.Error?,
    )

    private data class BuildIdentity(val sha: String, val purpose: String, val version: String, val code: Long)

    internal data class Frozen(val id: String, val elapsedMs: Long, val drops: Int, val state: String, val text: String) {
        companion object {
            fun parse(text: String): Frozen? {
                if (!text.startsWith("$WA_CAPTURE_MAGIC\n") && !text.startsWith("$WA_CAPTURE_MAGIC_V2\n")) return null
                val start = text.lastIndexOf("\nsha256=") + 1
                if (start == 0 || text.substring(start) != "sha256=${waCaptureDigest(text.substring(0, start))}\n") return null
                val fields = text.lineSequence().drop(1)
                    .filter { it.startsWith("capture=") || it.startsWith("startUp=") ||
                        it.startsWith("observed=") || it.startsWith("retained=") }.flatMap { it.split(' ').asSequence() }
                    .mapNotNull { field -> field.indexOf('=').takeIf { it > 0 }?.let { field.take(it) to field.substring(it + 1) } }
                    .toMap()
                return Frozen(
                    fields["capture"] ?: return null,
                    fields["durationMs"]?.toLongOrNull() ?: return null,
                    (fields["ringDrops"]?.toIntOrNull() ?: return null) + (fields["textDropped"]?.toIntOrNull() ?: 0),
                    fields["state"]?.takeIf { it in listOf("FROZEN", "INTERRUPTED", "INVALID") } ?: return null,
                    text,
                )
            }
        }
    }

    private class Session(
        val id: String, private val identity: BuildIdentity, private val sizeDp: Int,
        val connection: Connection, val lease: WaCaptureTimeout.Lease, val home: String?,
        private val reader: WaSystemReader,
    ) {
        private val startUp = SystemClock.uptimeMillis()
        private val startElapsed = SystemClock.elapsedRealtimeNanos()
        @Volatile var interrupted = false
        val deadline = startElapsed + MAX_MS * NS_PER_MS
        private val sequence = AtomicLong()
        val events = WaTraceRing(408, sequence)
        val terminal = WaTraceRing(112, sequence)
        val evidence = WaWithdrawalEvidence()
        private val windowIds = IntArray(32) { -1 }
        private var aliasOverflows = 0
        private var expiryPosted = false

        fun alias(windowId: Int): Int {
            if (windowId < 0) return 0
            val location = windowIds.indexOf(windowId)
            if (location >= 0) return location + 1
            val free = windowIds.indexOf(-1)
            if (free < 0) {
                aliasOverflows++
                return 0
            }
            windowIds[free] = windowId
            return free + 1
        }
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
            if (active !== this || interrupted) return
            if (began >= deadline) {
                if (!expiryPosted) {
                    expiryPosted = true
                    main.post(limit)
                }
                return
            }
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
                if (active !== this || interrupted || end >= deadline) return
                if (end - began >= STEP_MS * NS_PER_MS) busy++
                val contiguous = lastCheck != 0L && began - lastCheck <= 2 * STEP_MS * NS_PER_MS
                lastCheck = end
                val changedOwner = visible !== owner
                val row = samples.add(
                    WaStage.PROBE, WaSource.PROBE, owner.service, owner.episode, owner, 0, 0,
                    WaHideReason.NONE, state, null, null, up, began, 0, if (changedOwner) 1 else 0,
                    0, 0, end, allowMerge = contiguous && !changedOwner,
                )
                evidence.probe(owner, up, began, end, state, changedOwner, row.lastSequence)
                probeDrops = samples.dropped
            }
        }

        fun snapshot(up: Long, elapsed: Long, stop: Stop, arm: ArmReport): Frozen = synchronized(samples) {
            val elapsedMs = duration(elapsed)
            val ringDrops = drops()
            val state = when (stop) {
                Stop.SERVICE_DISCONNECTED -> "INTERRUPTED"
                Stop.INVALID -> "INVALID"
                else -> "FROZEN"
            }
            val header = buildString {
                append("$WA_CAPTURE_MAGIC_V2\n")
                append("build=${identity.sha} purpose=${identity.purpose} version=${identity.version} code=${identity.code} api=${Build.VERSION.SDK_INT} model=${safeToken(Build.MODEL)}\n")
                append("capture=$id state=$state stop=$stop route=WA_BALANCE process=${Process.myPid()}-$processStart initialService=${connection.generation} sizeDp=$sizeDp\n")
                append("startUp=$startUp startEl=$startElapsed endUp=$up endEl=$elapsed deadlineEl=$deadline durationMs=$elapsedMs\n")
                append("physicalFirstOrb=UNOBSERVED firstForbiddenFrame=UNOBSERVED physicalLastOrb=UNOBSERVED\n")
                append("up=uptimeMillis el=elapsedRealtimeNanos eventUp=accessibilityEventTime receipts=software_only\n")
                append("armMs=${arm.requested} baselineMs=${arm.baseline} armReadbackMs=${arm.readback ?: "UNOBSERVED"} restore=${arm.restoration} restoreReadbackMs=${arm.restoreReadback ?: "UNOBSERVED"} armError=${arm.error ?: "NONE"} aliasOverflow=$aliasOverflows\n")
                append("summaryTuple=sequence,uptimeMs,elapsedNs stateSuffix=readStartNs,readEndNs,displayState,interactive,locked callbackSuffix=source,type,eventUptimeMs,displayId,class,windowAlias,windowChanges,contentChanges unavailable=-1_or_UNOBSERVED sceneBefore=prior_not_fresh\n")
                append("observed=${events.observed + terminal.observed + samples.observed} coalesced=${events.coalesced + terminal.coalesced + samples.coalesced} ringDrops=$ringDrops ringTruncated=${ringDrops > 0} probeRead=${samples.observed} probeSkipped=$skipped probeBusy=$busy\n")
            }
            val (text, textDrops) = waCaptureText(header + evidence.lines(), events.rows() + terminal.rows() + samples.rows())
            Frozen(id, elapsedMs, ringDrops + textDrops, state, text)
        }
    }

    private data class ProbeEpisode(val service: Long, val episode: Long, val began: Long)
}
