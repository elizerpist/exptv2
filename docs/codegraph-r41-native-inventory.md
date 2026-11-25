# R41 stock-opening native source inventory

Application source: `97f9704120e2ae997185ea6e35fbc053e1d7f0ab`; R40 application parent: `11b4a67a08f402968bd55ff62f63f0494227d0a9`. Dart graph: `06c9d01c91467f74d105ec2de8f9d7f2bbb20aa6`; index SHA-256 `a779445a5593da9ea4cebe63ca41d655a2899f4983b229ad2d13efb88a6a54c3`; manifest SHA-256 `f2cd9c253e838d5828bf651cff80a43953317e1f5eeaf60fb72bf05865c8d6eb`. The generated SCIP graph covers Dart, not Kotlin. The following locations are source-navigation results, not observed execution or evidence of a physical pixel.

The direct route's capture, session, request, reservation and output identify a retained grant and reveal acknowledgement. An unpaired non-DIRECT candidate/post callback is not a verified fallback grant. H2 remains disabled for profile/release. The ledger declares its remaining critical path `INCOMPLETE`; physical A142 timing and privacy acceptance remain pending.

```text
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:177:    internal fun requestSystemCheckForTest() { requestSystemCheck("blockedReaderRegression") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:205:        if (hadR18) requestSystemCheck("r18RouteChanged", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:219:            KeyguardCardDiagnostics.r41SamplerMark(phase, request, detail)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:486:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:541:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:680:            KeyguardCardDiagnostics.r41Bind(early.diagnosticContext, sample.r41WakeOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:681:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, early.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:722:            offer.first?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:723:            if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:938:                else requestSystemCheck("r18Ready", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:986:                requestSystemCheck("r19Reconcile", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1101:                requestSystemCheck("r18DrainReady", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1308:        requestSystemCheck("r18Fallback", evaluate = true, freshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1345:            if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1595:    private val screenReceiver = object : BroadcastReceiver() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1601:                KeyguardCardDiagnostics.r41Provisional(r41Capture, 1, session.get(), receivedAt, r41AtNs) else 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1619:                Intent.ACTION_SCREEN_ON -> beginOrJoinWakeCycle("wake", receivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1633:            val r41Ordinal = KeyguardCardDiagnostics.r41Provisional(r41Capture, 2, session.get(), receivedAt, r41AtNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1637:            val cycle = beginOrJoinWakeCycle("display", receivedAt, schedule = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1672:                        requestSystemCheck("r18MotionIneligible", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1784:                            if (request != null && show != null) KeyguardCardDiagnostics.r41Mark(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1785:                                KeyguardR41RawLedger.FALLBACK_POST_RECEIPT, operation.context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1845:        beginOrJoinWakeCycle("connected")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1848:    override fun onAccessibilityEvent(event: AccessibilityEvent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1854:            KeyguardCardDiagnostics.r41Provisional(r41Capture, 3, session.get(), callbackReceivedAt, r41AtNs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1950:                requestSystemCheck("accessibilityOwn", callbackReceivedAt, eventTime = meta.eventTimeUptimeMs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1962:                val cycle = beginOrJoinWakeCycle("accessibility", callbackReceivedAt, schedule = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2046:                else requestSystemCheck("privacyTightened")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2159:            if (hadR18) requestSystemCheck("r18MaterialChanged", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2172:                registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2175:                registerReceiver(screenReceiver, filter)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2187:    private fun beginOrJoinWakeCycle(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2199:            if (freshState == null) requestSystemCheck(source, receivedAtUptimeMs, eventTime = eventTime)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2202:                KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, ordinal, screen = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2223:            requestSystemCheck(source, receivedAtUptimeMs, evaluate = true, wakeSource = source, eventTime = eventTime,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2283:        KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, wakeOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2284:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, currentDiagnosticAttempt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2288:            KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, screenOrdinal, screen = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2332:    private fun requestSystemCheck(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2373:            beginOrJoinWakeCycle(it, request.evaluationReceivedAt, schedule = false, freshState = state, sampleRequest = request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2377:            beginOrJoinWakeCycle("wake", it, schedule = false, freshState = state, sampleRequest = request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2469:            requestSystemCheck(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2513:        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2521:        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2525:    private fun scheduleEvaluationCommon(trigger: String, eventTimeUptimeMs: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2614:        queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2629:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_SHADOW_OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2632:        if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2756:    private fun readInspection(request: KeyguardCardInspectionRequest): PhysicalReadOutcome {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2757:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WORKER, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2798:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2800:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2957:                    requestSystemCheck("r25SuppressedPositive", evaluate = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2981:    private fun r25PostDrain(notice: KeyguardOpeningPublication.Notice, request: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2987:                if (Looper.myLooper() == Looper.getMainLooper()) r25DrainOnMain(notice)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2988:                else if (!mainHandler.post { r25DrainOnMain(notice) }) r25FallbackDrain(notice)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3000:                    withContext(Dispatchers.Main.immediate) { r25DrainOnMain(notice) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3020:            inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3024:    private fun r25DrainOnMain(notice: KeyguardOpeningPublication.Notice) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3035:            if (current) applyCompletedInspection(completed.read, completed.handoff)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3044:            if (next != null && serviceJob.isActive) inspectionScope.launch { processInspectionQueue(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3051:    private fun applyCompletedInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3099:            if (::overlay.isInitialized && overlay.isAttached) requestSystemCheck("abortedInspection:${read.request.id}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3364:                    applyCompletedInspection(read, handoff, disposition = CompletedDisposition.R32_RESTRICTION_ONLY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3370:            val successorOutcome = readInspection(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3412:                                applyCompletedInspection(successorRead, nextHandoff)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3446:                    if (cleanup.second != null) inspectionScope.launch { processInspectionQueue(requireNotNull(cleanup.second)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3449:                            requestSystemCheck("r32PairCancelled", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3456:    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3463:            val physical = readInspection(active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3556:                            r25PostDrain(it, active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3567:                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_BYPASS,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3589:                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.DISPATCH, active.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3591:                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.MAIN, active.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3597:                    if (latest == null) applyCompletedInspection(read, handoff)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3640:                    applyCompletedInspection(read, handoff, snapshot, successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3644:                    successorOutcome = readInspection(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3668:                                applyCompletedInspection(successorRead, nextHandoff, snapshot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3694:                    if (next != null) inspectionScope.launch { processInspectionQueue(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3697:                            requestSystemCheck("r34ReaderCancelled", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4543:                requestSystemCheck("r32PredecessorAuthorityChanged", evaluate = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4572:                requestSystemCheck("staleInspection:${request.id}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4643:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5211:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, directOwner.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5241:                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.FALLBACK_CANDIDATE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5259:                    if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5394:                                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6120:            runCatching { unregisterReceiver(screenReceiver) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:945:        var r41Provisional: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:946:        var r41Bindings: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:953:        var r41ProvisionalEvicted: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1467:    fun freezeCapture(context: Context): Map<String, Any?> = reduction.read {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1504:    fun captureSnapshot(context: Context): Map<String, Any?> = reduction.read {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1719:    fun r41Provisional(captureId: String?, source: Int, serviceSession: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1727:    fun r41Bind(owner: KeyguardDiagnosticContext?, ordinal: Long, screen: Boolean = false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1735:    fun r41Mark(phase: Int, owner: KeyguardDiagnosticContext?, request: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1746:    fun r41SamplerMark(phase: Int, request: KeyguardSystemGateRequest, detail: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2587:                active.r41Provisional += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2590:                    active.r41ProvisionalEvicted += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2655:                    active.r41Bindings += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2672:                    KeyguardR41RawLedger.SYSTEM_ELIGIBLE -> "SYSTEM_ELIGIBLE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2673:                    KeyguardR41RawLedger.FALLBACK_CANDIDATE -> "FALLBACK_CANDIDATE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2674:                    KeyguardR41RawLedger.FALLBACK_POST_RECEIPT -> "FALLBACK_POST_RECEIPT"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2899:                "provisional=${active.r41Provisional} bindings=${active.r41Bindings} rawOverflow=${active.r41RawOverflow} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2900:                "receiptEvicted=${active.r41ProvisionalEvicted} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2946:            active.r41RawLate + active.r41ReportsPending + active.r41ReportsDropped + active.r41ProvisionalEvicted +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3059:            attempt.r41.requestRows(attempt.id).forEachIndexed { index, row ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3464:                " opening=UNOBSERVED/UNOBSERVED outcome=UNOBSERVED/UNOBSERVED missing=ALL_R22_BOUNDARIES" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3551:            appendLine(" FIRST_INSPECTION req=${firstInspection?.requestId} sameAs=SHOWING_INSPECTION showOp=${show?.operationId}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:5:internal class KeyguardR41AttemptLedger {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:65:            "SYSTEM_ELIGIBLE" -> { systemEligible = 1; return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:72:            "FALLBACK_CANDIDATE" -> FALLBACK_CANDIDATE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:73:            "FALLBACK_POST_RECEIPT" -> FALLBACK_POST
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:91:                        time(candidate, CANCEL) == MISSING && time(candidate, FALLBACK_CANDIDATE) == MISSING &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:116:        if (column == FALLBACK_CANDIDATE || column == FALLBACK_POST) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:118:            else if (column == FALLBACK_CANDIDATE) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:148:    fun core(attempt: Long, session: Long, wake: Long, captureLoss: Long): String {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:156:            return " R41_CORE attempt=$attempt session=$session wake=$wake systemEligible=UNOBSERVED eligible=UNOBSERVED" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:171:            time(candidate, FALLBACK_CANDIDATE) != MISSING && time(candidate, FALLBACK_POST) != MISSING &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:172:                time(candidate, FALLBACK_POST) >= time(candidate, FALLBACK_CANDIDATE) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:178:                "${time(fallback, FALLBACK_CANDIDATE)}/${time(fallback, FALLBACK_POST)}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:179:        return " R41_CORE attempt=$attempt session=$session wake=$wake systemEligible=${if (systemEligible == 1) "true" else "UNOBSERVED"} eligible=${when (eligible) { 1 -> "true"; 0 -> "false"; else -> "UNOBSERVED" }}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:195:    fun requestRows(attempt: Long): List<String> = (0 until count).map { slot ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:199:            " fallbackCandidate=${value(time(slot, FALLBACK_CANDIDATE))}@${value(fallbackCandidateOp[slot])}/${value(fallbackAttachment[slot])}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:233:        private const val FALLBACK_CANDIDATE = 10
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:9:internal class KeyguardR41RawLedger(private val capacity: Int = 2048) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:113:        const val SYSTEM_ELIGIBLE = 31
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:114:        const val FALLBACK_CANDIDATE = 32
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:115:        const val FALLBACK_POST_RECEIPT = 33

Offline analysis: scripts/analyze-r41.py; its tests: scripts/test-r41-analyzer.py
```
