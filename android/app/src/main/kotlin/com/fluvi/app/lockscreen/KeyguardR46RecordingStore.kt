package com.fluvi.app.lockscreen

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

/** App-private, ordered technical evidence for the owner-initiated run.
 * Producers never do filesystem I/O. Overflow and writer errors are explicit;
 * the bounded legacy snapshot is included as a summary, not used as the
 * source of the detailed event stream. */
internal object KeyguardR46RecordingStore {
    private const val PREFS = "fluvi_r46_recording"
    private val writer = Executors.newSingleThreadExecutor { r -> Thread(r, "fluvi-r46-spool").apply { isDaemon = true } }
    private class Run(val id: String, val route: String, val request: String, val file: File) {
        val queue = ArrayBlockingQueue<String>(4096)
        val scheduled = AtomicBoolean(false)
        val accepted = AtomicLong()
        val written = AtomicLong()
        val dropped = AtomicLong()
        @Volatile var accepting = true
        @Volatile var failure: String? = null
    }
    @Volatile private var active: Run? = null

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private fun dir(context: Context) = File(context.applicationContext.filesDir, "r46-recordings")

    /** Called off Main before the new capture is exposed to producers. */
    @Synchronized fun begin(context: Context, id: String, route: String, request: String) {
        require(id.matches(Regex("[a-f0-9-]{36}")))
        require(route == "FLUVI_STREAM" || route == "WIDGETS_ANYWHERE")
        require(request.isNotBlank() && request.length <= 120)
        check(active == null && prefs(context).getString("state", "READY") in setOf("READY", "COPIED", "ABORTED"))
        val folder = dir(context)
        check(folder.exists() || folder.mkdirs())
        val file = File(folder, "$id.events")
        check(file.createNewFile())
        val run = Run(id, route, request, file)
        check(prefs(context).edit().putString("state", "RECORDING").putString("id", id)
            .putString("route", route).putString("request", request).commit())
        active = run
    }

    /** Called only on the existing diagnostic consumer, after identity checks. */
    fun offer(id: String, line: String) {
        val run = active ?: return
        if (run.id != id || !run.accepting) return
        val record = line.replace('\n', ' ').replace('\r', ' ') + "\n"
        if (!run.queue.offer(record)) { run.dropped.incrementAndGet(); return }
        run.accepted.incrementAndGet()
        schedule(run)
    }

    private fun schedule(run: Run) {
        if (run.scheduled.compareAndSet(false, true)) writer.execute {
            try { drain(run) } finally {
                run.scheduled.set(false)
                if (run.queue.isNotEmpty()) schedule(run)
            }
        }
    }

    private fun drain(run: Run) {
        var batch = 0L
        try {
            FileOutputStream(run.file, true).bufferedWriter(Charsets.UTF_8).use { out ->
                while (true) {
                    val line = run.queue.poll() ?: break
                    out.write(line)
                    batch++
                }
            }
            run.written.addAndGet(batch)
        } catch (failure: Exception) {
            run.failure = failure.javaClass.simpleName
            // Records not written because of an I/O failure remain visible as
            // losses, rather than masquerading as a complete report.
            run.dropped.addAndGet(batch)
            while (run.queue.poll() != null) run.dropped.incrementAndGet()
        }
    }

    /** Called after the diagnostic reducer's freeze barrier, on an IO thread. */
    @Synchronized fun seal(context: Context, id: String, summary: String, end: String): String {
        val p = prefs(context)
        check(p.getString("id", null) == id)
        val finalFile = File(dir(context), "$id.txt")
        if (p.getString("state", "") in setOf("SEALED", "COPIED") && finalFile.isFile)
            return finalFile.readText(Charsets.UTF_8)
        val run = active?.takeIf { it.id == id }
        run?.accepting = false
        // A FIFO barrier follows all scheduled batches; the second drain
        // covers an offer racing the original scheduling flag.
        writer.submit { if (run != null) drain(run) }.get()
        val source = run?.file ?: File(dir(context), "$id.events")
        val tmp = File(dir(context), "$id.tmp")
        val digest = MessageDigest.getInstance("SHA-256")
        var bodyBytes = 0L
        FileOutputStream(tmp).use { output ->
            fun append(bytes: ByteArray) { output.write(bytes); digest.update(bytes); bodyBytes += bytes.size }
            fun line(value: String) = append((value + "\n").toByteArray(Charsets.UTF_8))
            line("FLUVI_R46_RECORDING_V1")
            line("A rögzített mintaorb fizikai láthatósága külön ellenőrizendő.")
            line("captureId=$id route=${p.getString("route", "UNOBSERVED")} end=$end")
            line("clock=uptimeMs source=app_private_spool")
            line("SUMMARY_BEGIN")
            append(summary.toByteArray(Charsets.UTF_8))
            line("\nSUMMARY_END")
            line("DETAILED_RECORDS_BEGIN")
            if (source.isFile) source.inputStream().use { input ->
                val buffer = ByteArray(16 * 1024)
                while (true) { val n = input.read(buffer); if (n < 0) break; append(buffer.copyOf(n)) }
            }
            line("DETAILED_RECORDS_END")
            line("spoolAccepted=${run?.accepted?.get() ?: "UNOBSERVED"} spoolWritten=${run?.written?.get() ?: "UNOBSERVED"} spoolDropped=${run?.dropped?.get() ?: "UNOBSERVED"} spoolFailure=${run?.failure ?: if (run == null) "PROCESS_INTERRUPTED" else "none"}")
            if (run == null) line("interruptionLoss=UNKNOWN reason=process_or_service_interrupted")
            val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
            output.write("bodyBytes=$bodyBytes bodySha256=$hash\nEND_FLUVI_R46_RECORDING_V1\n".toByteArray(Charsets.UTF_8))
            output.fd.sync()
        }
        check(tmp.renameTo(finalFile)) { "reportRenameFailed" }
        check(p.edit().putString("state", "SEALED").commit())
        if (active === run) active = null
        return finalFile.readText(Charsets.UTF_8)
    }

    @Synchronized fun copied(context: Context, id: String) {
        val p = prefs(context)
        check(p.getString("id", null) == id && p.getString("state", "") == "SEALED")
        check(p.edit().putString("state", "COPIED").commit())
    }

    fun sealedReport(context: Context, id: String): String {
        val p = prefs(context)
        check(p.getString("id", null) == id && p.getString("state", "") in setOf("SEALED", "COPIED"))
        return File(dir(context), "$id.txt").readText(Charsets.UTF_8)
    }

    @Synchronized fun abort(context: Context, id: String) {
        val run = active?.takeIf { it.id == id }
        run?.accepting = false
        if (active === run) active = null
        if (prefs(context).getString("id", null) == id)
            prefs(context).edit().putString("state", "ABORTED").commit()
    }

    fun status(context: Context): Map<String, Any?> {
        val p = prefs(context)
        val id = p.getString("id", null)
        val state = p.getString("state", "READY") ?: "READY"
        val alive = active?.id == id && active?.accepting == true
        return mapOf("state" to if (state == "RECORDING" && !alive) "INTERRUPTED" else state,
            "captureId" to id, "route" to p.getString("route", null),
            "requestId" to p.getString("request", null))
    }
}
