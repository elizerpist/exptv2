from pathlib import Path
p=Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt')
s=p.read_text()
old='''            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
            captureStarted = true
            captureId = capture["captureId"].toString()'''
new='''            val requestedCapture = args.getString("r224CaptureMode") ?: "FULL"
            require(requestedCapture in setOf("OFF", "LIGHT", "FULL"))
            if (requestedCapture != "OFF") {
                val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", requestedCapture)
                captureStarted = true
                captureId = capture["captureId"].toString()
            } else captureId = "UNOBSERVED_OFF"'''
assert s.count(old)==1;s=s.replace(old,new)
marker='''    @Test fun fourRealWakeCyclesUseRequestedRoute() {'''
test='''    /** Same test-only observer and natural, unheld workload in OFF and LIGHT.
     * These are service/acquisition timings, not physical presentation. */
    @Test fun r22_4CaptureOverheadArm() {
        val requested = requireNotNull(InstrumentationRegistry.getArguments().getString("r224CaptureMode"))
        require(requested == "OFF" || requested == "LIGHT")
        val rows = java.util.Collections.synchronizedList(mutableListOf<String>())
        val omitted = java.util.concurrent.atomic.AtomicInteger()
        fun append(row: String) = synchronized(rows) {
            if (rows.size < 512) rows.add(row) else omitted.incrementAndGet()
        }
        serviceConnectedControl = { service ->
            service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun started(request: KeyguardCardInspectionRequest) {
                    append(org.json.JSONObject().put("kind", "start").put("mode", requested)
                        .put("request", request.id).put("session", request.session).put("wake", request.wakeGeneration)
                        .put("event", request.eventTimeUptimeMs ?: org.json.JSONObject.NULL)
                        .put("callback", request.triggerReceivedUptimeMs).put("queued", request.queuedAtUptimeMs)
                        .put("observed", SystemClock.uptimeMillis()).toString())
                }
                override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                    abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                    append(org.json.JSONObject().put("kind", "finish").put("mode", requested)
                        .put("request", request.id).put("session", request.session).put("wake", request.wakeGeneration)
                        .put("start", startedAt).put("finish", finishedAt).put("decision", decision.name)
                        .put("reason", reason.name).put("rootUnavailable", rootUnavailable)
                        .put("truncated", walkTruncated).put("aborted", abortedStale).toString())
                }
            }
        }
        naturalComparison = true
        try { fourRealWakeCyclesUseRequestedRoute() } finally {
            FluviKeyguardCardServiceRegistry.serviceForInstrumentation()?.inspectionProbeForTest = null
            serviceConnectedControl = null
            naturalComparison = false
            if (::output.isInitialized) {
                val data = synchronized(rows) { rows.toList() }
                File(output, "r22-4-overhead.jsonl").writeText(data.joinToString("\\n", postfix = if (data.isEmpty()) "" else "\\n"))
                File(output, "r22-4-overhead-meta.txt").writeText("mode=$requested omitted=${omitted.get()} rows=${data.size} observer=identical_bounded_test_only physical=UNOBSERVED\\n")
            }
        }
        assertEquals("observer overflow", 0, omitted.get())
    }

'''
assert s.count(marker)==1;s=s.replace(marker,test+marker)
p.write_text(s)
