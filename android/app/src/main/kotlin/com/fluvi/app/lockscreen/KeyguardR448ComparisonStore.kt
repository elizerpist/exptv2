package com.fluvi.app.lockscreen

import android.content.Context

/** Two bounded, frozen summaries only. No node content or screenshots. */
internal object KeyguardR448ComparisonStore {
    private const val PREFS = "fluvi_keyguard_r448_comparison"
    private const val MAX_BYTES = 4800
    private val prefixes = listOf(
        "build=", "buildMode=", "captureState=", "captureMode=", "processInstance=", "pid=",
        "startedAt=", "durationElapsedMs=", "r448DisplayRoute=", "r448SampleOnly=", "r448WaSource=",
        "R44_9_HU ", "R44_9_OUTCOME ", "R44_9_ADMISSION ", "R44_9_FLUVI_RECOVERY ", "R44_8_READ_BOUNDARY ", "R44_8_SYSTEM_VETO ", "R44_8_WA ", "R44_6_SAMPLE ", "attemptId=",
    )
    @Volatile private var fluviWriteFailed = false
    @Volatile private var widgetsWriteFailed = false

    private fun markWrite(route: String, failed: Boolean) {
        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM.name) fluviWriteFailed = failed
        else widgetsWriteFailed = failed
    }

    internal fun summarize(captureId: String, report: String): String {
        val header = "capture=${captureId.filter { it.isLetterOrDigit() || it == '-' }.take(64)}\n"
        val result = StringBuilder(header)
        var omitted = 0
        var truncated = 0
        report.lineSequence().filter { line -> prefixes.any { line.startsWith(it) } }.forEach { line ->
            val bounded = line.take(1500)
            if (line.length > bounded.length) truncated++
            if ((result.toString() + bounded + "\n").toByteArray(Charsets.UTF_8).size <= MAX_BYTES - 64)
                result.append(bounded).append('\n')
            else omitted++
        }
        result.append("omittedSummaryLines=").append(omitted)
            .append(" truncatedSummaryLines=").append(truncated).append('\n')
        return result.toString()
    }

    fun save(context: Context, route: String, captureId: String, report: String) {
        if (route !in KeyguardR448DisplayRoute.entries.map { it.name }) return
        markWrite(route, true)
        val written = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(route, summarize(captureId, report)).commit()
        markWrite(route, !written)
    }

    fun export(context: Context): String {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val a = prefs.getString(KeyguardR448DisplayRoute.FLUVI_STREAM.name, null)
        val b = prefs.getString(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE.name, null)
        if (a == null && b == null && !fluviWriteFailed && !widgetsWriteFailed) return ""
        return "FLUVI_R44_8_AB_SUMMARY fluviWriteFailure=$fluviWriteFailed widgetsWriteFailure=$widgetsWriteFailed\nFLUVI_STREAM\n${a ?: "UNOBSERVED\n"}" +
            "WIDGETS_ANYWHERE\n${b ?: "UNOBSERVED\n"}END_FLUVI_R44_8_AB_SUMMARY\n"
    }
}
