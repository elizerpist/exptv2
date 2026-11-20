# R18 presentation-pipeline source graph and native inventory

Application source: `a4b36265ca7f168c964beac67e6ef69db4723a7a`

The Dart SCIP manifest is `docs/codegraph/manifest.json`; Kotlin has no SCIP coverage and the following is source navigation, not a generated call graph. The output/host lifecycle is Main-owned and visual presentation remains an independently measured outcome.

```text
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:86:        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:108:        reserveBeforeMain = ::reserveR18WakeBeforeMain,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:378:            sealR18(sample.authority, Long.MAX_VALUE, "systemSample")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:438:     * later than withdrawal or another wake. The reducer applies its capture
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:443:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:451:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:465:    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:570:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:585:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:586:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:668:        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:686:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String): R18Active? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:691:        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:860:        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:891:    /** The service state that owned the currently attached root's first-draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:892:     * diagnostics. Deferred draw work must match this original identity, not
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:960:                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1018:                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1024:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1059:                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1062:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1227:            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1282:            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1322:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1345:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1474:            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1703:            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1813:            sealR18(current, request.id, result.surfaceReason.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1853:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2185:        val read = readSystemWindows(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2249:    private fun readSystemWindows(request: KeyguardCardInspectionRequest): SystemWindowsRead {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2284:                    if (authorityIsCurrent(request)) sealR18(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2315:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2466:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2514:            // exclusion. The surface policy below withdraws it nonterminally.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2728:     * work. Real withdrawal revokes the old answer, then reacquires the intent.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2741:        // fallback fires, independently of local withdrawal and tree work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2748:        // Withdrawing a currently visible presentation is contradictory
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2764:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2777:                awaitingSurfaceWithdrawal = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2807:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2808:            // Withdrawal changed authority. Record the obligation under the
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2816:                    // The queued request was captured under the withdrawn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2821:                        "withdrawalAuthorityChanged",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3062:        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3075:                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3255:                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3349:        awaitingSurfaceWithdrawal: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3356:        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3359:        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3389:        // only its own listener after the framework draw traversal ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3391:        wakeTiming?.draws?.detach()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3474:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3521:                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3549:                        "drawGapCount" to summary.orb.gaps,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3550:                        "drawGapTotalMs" to summary.orb.gapTotalMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3551:                        "drawGapMaxMs" to summary.orb.gapMaxMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3552:                        "drawInvalidOrder" to summary.orb.invalidOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3558:                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3559:                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3560:                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3561:                        "drawObservedFrames" to summary.orbGaps.observedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3562:                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3563:                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3564:                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3565:                        "drawEvidenceRejected" to summary.orbGaps.rejected,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3599:                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3611:                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3626:                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3630:        // Window visibility is already withdrawn; only now cancel potentially
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3661:    /** Both callbacks arrive after their draw stacks have unwound. The event
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3679:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3696:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3792:        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3793:        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3800:                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3848:            "drawCount" to (values?.frameCallbackCount ?: 0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:72:    private val drawEvidenceEnabled: () -> Boolean = { KeyguardCardDiagnostics.wantsEvent("DRAW_GAP") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:411:    fun stageR18Host(generation: Long, settings: KeyguardCardSettings): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:438:    fun stagedR18Host(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:477:    fun revealR18(preparation: R18Preparation, boundary: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:484:    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:485:        surfacePresenter?.sealR18(attachment, outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:502:            surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:535:            // complete before WindowManager.addView and cannot tax first draw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:545:            // the attach callback and installs pre-draw on the real observer.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:587:                        // root draw has completed; it is not needed to render
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:679:        surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:729:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:835:            drawEvidenceEnabled = drawEvidenceEnabled,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:837:            drawEvidenceOwner = KeyguardCardDiagnostics::drawEvidenceOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:884:                    // The material View invokes this while Canvas draw is in
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:899:                // make LIVE look later than it actually became drawable.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:914:                // KeyguardHeaderMaterialView invokes this while Canvas draw is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1029:        root.setBackgroundResource(if (card) R.drawable.fluvi_financial_snapshot_background else android.R.color.transparent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1171:                // shader draw. Animated bootstrap waits until that live draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1194:    /** Registration occurs from root pre-draw before bootstrap Canvas work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1196:     * owner check mirrors the first-draw observation rather than treating a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:768:        var visibleWithdrawalCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:910:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:941:        "drawGapCount", "drawGapTotalMs", "drawGapMaxMs", "animationStarts", "animationStops",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:942:        "clockRunning", "liveState", "backgroundFrames", "firstShaderTraversalAt", "lastShaderTraversalAt", "drawInvalidOrder",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:943:        "drawEvidenceMode", "drawEvidenceOmitted", "drawObserverNs", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:944:        "drawUnpairedFrames", "drawCoalescedCallbacks", "drawEvidenceBreaks", "drawEvidenceRejected", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:967:        if (stage == "ATTACHMENT_RENDER_SUMMARY") result["drawGapCaptureOmitted"] = gapRecordsOmitted.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1222:    fun drawEvidenceOwner(): Any? = ingress
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1389:                // never evict a wake/attach/draw/withdrawal milestone.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1710:                            // newest add. A later no-draw reattach cannot erase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1775:                "R18_PIPELINE" -> reduceR18(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1813:                        // Eight retained shows can each own a withdrawal;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1818:                            // withdrawal ahead of detached cleanup noise.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1861:                    if (attached == true && fields["awaitingSurfaceWithdrawal"] == "true") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1862:                        attempt.visibleWithdrawalCount += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2101:            appendLine("drawObservationMeaning=NO_DRAW_OBSERVED_is_not_proof_of_no_rendering")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2102:            appendLine("drawGapClock=System.nanoTime frameNs=Choreographer cpuNs=threadCPU cbOut=ownedCallbackWorkEndBeforeProbe submit=CPUCanvasCall")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2104:            appendLine("workKinds=1:systemGate,2:inspectionApply,3:diagnosticProducer nestedWorkNotAdditive=true workCoverage=ownedScopesOnly drawObserverNs=bookkeepingOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2200:                        append(" R18_PIPELINE attempt=${attempt.id} attach=${row.attachment ?: "UNOBSERVED"} host=${row.host} output=${row.output} child=${row.child} privacy=${row.privacy}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2236:        // show/withdrawal, financial core and recovery records had a chance
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2329:        // occurs here on the diagnostic consumer, never in a draw callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2340:                        val id = "$episodeId:drawGap:$surface:$index"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2400:            val criticalOmissions = omittedRecords.filterNot { it.endsWith(":raw") || it.endsWith(":spineRows") || it.endsWith(":detail") || ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2401:            val omittedGaps = omittedRecords.filter { ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2403:            appendLine("drawGapEvidenceExported=${selected.keys.count { ":drawGap:" in it }} drawGapEvidenceOmitted=${omittedGaps.size}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2418:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2420:            selected.filterKeys { ":drawGap:" in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2447:    private fun actualWithdrawal(attempt: TimingAttempt, show: ShowEpisode): HideEpisode? =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2455:     * evidence. Missing/omitted episodes never overwrite the earliest draw. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2461:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2467:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2477:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2485:        appendLine(" awaiting=unknownWhileHidden:${attempt.unknownWhileHiddenCount},unknownWhileHiddenEpochChanges:${attempt.unknownWhileHiddenEpochChanges},pendingPreservedAfterUnknown:${attempt.pendingPreservedAfterUnknown},pendingRejectedAfterUnknown:${attempt.pendingRejectedAfterUnknown},visibleWithdrawalCount:${attempt.visibleWithdrawalCount},retrySuppressedForPendingWork:${attempt.retrySuppressedForPendingWork},retryBudgetExhaustedWhileAwaiting:${attempt.retryBudgetExhaustedWhileAwaiting}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2490:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideDecisionToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.decisionAtUptimeMs)} localHideToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.localHideAppliedAtUptimeMs)} layerHideSubmitToRemoveBeginMs=${delta(withdrawal?.removeBeginAtUptimeMs, withdrawal?.isolatedLayerHideSubmittedAtUptimeMs)} removeViewCallMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.removeBeginAtUptimeMs)} hideSignalToDecisionMs=${delta(withdrawal?.decisionAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideSignalToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2531:        return " WITHDRAWAL hideOp=${hide.operationId} attach=${hide.attachGeneration ?: "NA"} req=${hide.requestId ?: "NA"} attachedBefore=${hide.attachedBefore ?: "NA"} trigger=${hide.triggerReceivedAtUptimeMs ?: "NA(missingTrigger)"} decision=${hide.decisionAtUptimeMs} local=${hide.localHideAppliedAtUptimeMs ?: "NA"} layerSubmit=${hide.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${hide.isolatedLayerTransactionApplied ?: "NA"} layerApplyReturn=${hide.isolatedLayerApplyReturnedAtUptimeMs ?: "UNOBSERVED"} layerCommit=${hide.isolatedLayerCommitReceivedAtUptimeMs ?: "UNOBSERVED"} remove=${hide.removeBeginAtUptimeMs ?: "NA"}/${hide.removeReturnAtUptimeMs ?: "NA"} detachFailed=${hide.detachFailed} holderTarget=${hide.r15TargetAttachment ?: "UNOBSERVED"}/${hide.r15Generation ?: "UNOBSERVED"} holderAtRevoke=${hide.r15AtRevoke ?: "UNOBSERVED"} holderClock=uptimeMs holderCoherent=${op?.coherent ?: "UNOBSERVED"} holderOp=${op?.id ?: "UNOBSERVED"} lock=${op?.lockEnter ?: "UNOBSERVED"}/${op?.lockReturn ?: "UNOBSERVED"} drawReturn=${op?.drawReturn ?: "UNOBSERVED"} post=${op?.postEnter ?: "UNOBSERVED"}/${op?.postReturn ?: "UNOBSERVED"} record=${op?.recordAt ?: "UNOBSERVED"} revoke=${op?.revokeBegin ?: "UNOBSERVED"}/${op?.revokeReturn ?: "UNOBSERVED"} physical=UNOBSERVED\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2538:        "shaderFrames", "shaderCalls", "phaseAdvances", "drawGapCount", "drawGapTotalMs", "drawGapMaxMs",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2539:        "clockRunning", "liveState", "drawEvidenceMode", "drawEvidenceOmitted", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2540:        "drawObserverNs", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2549:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2550:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2552:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2554:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2555:                    append(compactHideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2556:                    append(compactInspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2576:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2577:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2579:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} postAdd=${episode.postAddSetupAtUptimeMs ?: "UNOBSERVED"} attachState=${episode.attachStateAtObservation ?: "UNOBSERVED"} preDraw=${episode.firstPreDrawAtUptimeMs ?: "UNOBSERVED"} rootSize=${episode.preDrawRootSize ?: "UNOBSERVED"} targetSize=${episode.preDrawTargetSize ?: "UNOBSERVED"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2581:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2582:                    append(hideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2583:                    append(inspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2601:        val needHolderRow = includeHolderDetail || actualWithdrawal(attempt, episode) == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2605:            appendLine(" R15_HOLDER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which clock=uptimeMs coherent=${op.coherent} op=${op.id} lock=${op.lockEnter ?: "UNOBSERVED"}/${op.lockReturn ?: "UNOBSERVED"} drawReturn=${op.drawReturn ?: "UNOBSERVED"} post=${op.postEnter ?: "UNOBSERVED"}/${op.postReturn ?: "UNOBSERVED"} record=${op.recordAt ?: "UNOBSERVED"} revoke=${op.revokeBegin ?: "UNOBSERVED"}/${op.revokeReturn ?: "UNOBSERVED"} screenPresentation=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2922:            "drawCount" to 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:63:    private val reserveBeforeMain: (KeyguardSystemGateRequest, KeyguardSystemState) -> (() -> Unit)? = { _, _ -> null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:97:    fun dispose() { disposed = true; clearPending() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:113:                runCatching { reserveBeforeMain(request, state) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:17:internal class KeyguardOrbInertHost(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:37:    fun stage(generation: Long, geometry: KeyguardOverlayGeometry): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:115:        // A pre-draw callback can be inside ViewRoot traversal. The host is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:125:    fun stagedView(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:28:internal class KeyguardOrbPresentationCoordinator(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:35:    class Withdrawal internal constructor(val reservation: Reservation, val output: Any?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:261:    fun revealSubmitted(reveal: Reveal): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:273:    fun seal(token: Reservation, authority: KeyguardInspectionAuthority, requestId: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:274:             authoritativeExclusion: Boolean): Withdrawal? = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:282:        Withdrawal(token, entry.output, entry.host, entry.crossedSubmitBoundary)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:302:    fun retired(token: Reservation): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:21:internal class KeyguardOrbDirectOutput private constructor(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:33:    fun borrow(): Surface? = if (lifetime.acquire()) surface else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:34:    fun releaseBorrow() { if (lifetime.release()) scheduleDrain(this) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:36:    internal fun seal(): Boolean = lifetime.seal()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:38:    internal fun disposeOnLane(): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:140:    fun reveal(output: KeyguardOrbDirectOutput,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:168:    fun retire(output: KeyguardOrbDirectOutput, completed: (Boolean) -> Unit = {}) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:221:            transaction.addTransactionCompletedListener(diagnosticExecutor) { stats ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:226:                    val fence = stats.presentFence
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:17:internal class KeyguardOrbR18Presenter(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:160:    fun reveal(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:185:    fun sealMatching(attachment: Long, generation: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:198:    fun seal(expectedSerial: Long? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:216:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:95:    fun revealR18(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:103:    fun sealR18() { direct?.seal() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:104:    fun sealR18(attachment: Long, generation: Long) { direct?.sealMatching(attachment, generation) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:124:        sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:201:                worker.surfaceReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:219:            override fun surfaceRedrawNeeded(holder: SurfaceHolder) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:220:                worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion {})
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:223:            override fun surfaceRedrawNeededAsync(holder: SurfaceHolder, drawingFinished: Runnable) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:225:                    worker.requestRedraw(target, KeyguardOrbSurfaceWorkerTestHooks.redrawCompletion(target, drawingFinished))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:227:                    worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion { drawingFinished.run() })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:273:        sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:282:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:382:        override fun onDraw(canvas: Canvas) = drawKeyguardOrbCircle(canvas, paint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:37:    @Volatile var surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:49:    // Worker-owned: transparent host submission happens only on create/redraw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:113:    private var pendingRedraw: KeyguardOrbSurfaceRedrawCompletion? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:125:        if (target != null && !target.revoked && target.surfaceReady) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:126:            draw(target, frameNanos)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:134:            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:186:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:194:            target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:205:     * for its real SurfaceHolder callback and verifies size before drawing. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:213:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:241:                drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:290:    fun surfaceReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:291:        target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:293:            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:330:    fun requestRedraw(target: KeyguardOrbSurfaceTarget, completion: KeyguardOrbSurfaceRedrawCompletion) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:336:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:337:            pendingRedraw = completion
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:339:            if (target.surfaceReady) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:361:                cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:385:        target.surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:388:        // A draw on the separately owned child must not block this callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:392:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:399:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:439:    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:440:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:443:        if (!firstPosted) draw(target, System.nanoTime())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:460:    private fun cancelRedraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:461:        val completion = pendingRedraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:462:        pendingRedraw = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:472:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:487:    private fun draw(target: KeyguardOrbSurfaceTarget, frameNanos: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:491:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:524:        if (currentTarget !== target || target.revoked || !target.surfaceReady || !target.access.tryEnter()) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:542:        var lockEnd = 0L; var drawEnd = 0L; var postEnd = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:550:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:552:                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:554:                previousForFrame?.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:555:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:557:            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:569:            fail(target, "draw:${error.javaClass.simpleName}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:582:                (lockEnd - lockStart).coerceAtLeast(0L), (drawEnd - lockEnd).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:583:                (postEnd - drawEnd).coerceAtLeast(0L), (cpuLockEnd - cpuStart).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:618:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:633:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:29:    private var drawReturn = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:55:        val drawReturn: Long?, val postEnter: Long?, val postReturn: Long?, val recordAt: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:82:        lockEnter = at; lockReturn = 0L; drawReturn = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:88:    fun holderDrawReturned(at: Long) { operationVersion += 1L; drawReturn = at; operationVersion += 1L }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:112:            val a = lockEnter; val b = lockReturn; val c = drawReturn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:125:               lockWallNs: Long, drawWallNs: Long, postWallNs: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:126:               lockCpuNs: Long, drawCpuNs: Long, postCpuNs: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:142:        maxDrawWall = maxOf(maxDrawWall, drawWallNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:145:        maxDrawCpu = maxOf(maxDrawCpu, drawCpuNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:162:            val lockWall = maxLockWall; val drawWall = maxDrawWall; val postWall = maxPostWall
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:163:            val lockCpu = maxLockCpu; val drawCpu = maxDrawCpu; val postCpu = maxPostCpu
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:166:                lockWall, drawWall, postWall, lockCpu, drawCpu, postCpu, holderSnapshot(), ownedLayer())

```
