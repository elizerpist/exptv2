# R19 first-authorized ORB source graph and native inventory

Application source: `bc41ec11b293923f664b50cd79ed36b5f6fad53b`

The Dart SCIP manifest is `docs/codegraph/manifest.json`; Kotlin has no SCIP coverage and the following is source navigation, not a generated call graph. The output/host lifecycle is Main-owned and visual presentation remains an independently measured outcome.

```text
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:28:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:89:        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:111:        reserveBeforeMain = ::reserveR18WakeBeforeMain,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:177:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:387:            sealR18(sample.authority, Long.MAX_VALUE, "systemSample")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:436:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:448:     * later than withdrawal or another wake. The reducer applies its capture
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:455:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:460:        val currentScene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:464:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:484:    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:520:    private fun invalidateR19Scene(reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:521:        val previous = firstAuthorizedOrb.current()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:522:        firstAuthorizedOrb.externalIngress()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:525:            recordR18(owner, "R19_EXPIRED_$reason", proof = previous.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:526:                r19ReadScene = previous.sceneSerial, r19Freshness = previous.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:537:        recordR18(owner, "R19_ALLOCATED", at)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:568:            overlay.r19AllocatedAt(prep)?.let { recordR18(owner, "R19_ALLOCATED", it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:586:                if (prep.emptyAwaitingDisclosure) advanceR19First(owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:590:        if (prep.emptyAwaitingDisclosure) advanceR19First(owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:597:                r18Active?.let(::advanceR19First)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:604:    private fun advanceR19First(owner: R18Active) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:608:        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:611:                recordR18(owner, "R19_PROOF_EXPIRED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:612:                    r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:617:                val scene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:636:            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:651:            invalidateR19Scene("SYSTEM")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:656:            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:667:                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:674:                    KeyguardR19FirstPaintTicket(prep.attachment, prep.outputGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:675:                        proof.requestId, proof.sceneSerial, proof.dataRevision, prep.visualKey)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:678:            recordR18(owner, "R19_PAINT_REQUEST", proof = proof.requestId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:690:                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:693:        recordR18(owner, "R19_PROOF_CONSUMED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:694:            r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:739:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:740:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:749:     * original exact output, even after replacement or withdrawal. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:751:        if (observation.stage != "R19_PAINT_ENTER" && observation.stage != "POSTER") return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:756:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:757:        val phase = if (observation.stage == "POSTER") "R19_POSTER" else observation.stage
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:758:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:774:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:775:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:827:            recordR18(owner, "R19_FIRST_POSITIVE", readFinishedAt, proof = request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:830:            val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:835:                recordR18(owner, "R19_PROOF_EXPIRED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:839:                recordR18(owner, "R19_PROOF_ACCEPTED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:841:                advanceR19First(owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:882:        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:900:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String): R18Active? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:905:        firstAuthorizedOrb.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:909:        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1078:        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1109:    /** The service state that owned the currently attached root's first-draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1110:     * diagnostics. Deferred draw work must match this original identity, not
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1147:            invalidateR19Scene("DISPLAY")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1179:                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1237:                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1243:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1278:                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1281:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1382:            invalidateR19Scene("INGRESS")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1452:            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1507:            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1547:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1570:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1699:            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1769:            invalidateR19Scene("SYSTEM")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1933:            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1963:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2039:        firstAuthorizedOrb.readCompleted(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2047:            sealR18(current, request.id, result.surfaceReason.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2087:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2424:        val sceneAtRead = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2425:        val read = readSystemWindows(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2491:    private fun readSystemWindows(request: KeyguardCardInspectionRequest): SystemWindowsRead {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2526:                    if (authorityIsCurrent(request)) sealR18(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2557:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2708:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2756:            // exclusion. The surface policy below withdraws it nonterminally.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2971:     * work. Real withdrawal revokes the old answer, then reacquires the intent.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2984:        // fallback fires, independently of local withdrawal and tree work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2991:        // Withdrawing a currently visible presentation is contradictory
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3007:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3020:                awaitingSurfaceWithdrawal = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3050:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3051:            // Withdrawal changed authority. Record the obligation under the
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3059:                    // The queued request was captured under the withdrawn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3064:                        "withdrawalAuthorityChanged",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3305:        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3318:                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3363:                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3410:                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation))) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3480:                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3481:                        if (finalSystem.eligible) r18Coordinator.queueReveal(directToken,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3496:                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3497:                                currentProof && r18Coordinator.crossSubmitBoundary(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3517:                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3611:        awaitingSurfaceWithdrawal: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3618:        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3621:        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3651:        // only its own listener after the framework draw traversal ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3653:        wakeTiming?.draws?.detach()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3736:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3783:                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3811:                        "drawGapCount" to summary.orb.gaps,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3812:                        "drawGapTotalMs" to summary.orb.gapTotalMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3813:                        "drawGapMaxMs" to summary.orb.gapMaxMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3814:                        "drawInvalidOrder" to summary.orb.invalidOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3820:                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3821:                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3822:                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3823:                        "drawObservedFrames" to summary.orbGaps.observedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3824:                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3825:                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3826:                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3827:                        "drawEvidenceRejected" to summary.orbGaps.rejected,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3861:                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3873:                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3888:                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3892:        // Window visibility is already withdrawn; only now cancel potentially
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3923:    /** Both callbacks arrive after their draw stacks have unwound. The event
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3941:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3958:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4054:        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4055:        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4062:                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4110:            "drawCount" to (values?.frameCallbackCount ?: 0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:33:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:73:    private val drawEvidenceEnabled: () -> Boolean = { KeyguardCardDiagnostics.wantsEvent("DRAW_GAP") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:418:    fun authorizeR19First(preparation: R18Preparation, ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:426:    fun r19AllocatedAt(preparation: R18Preparation): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:428:        return if (r18Preparation == preparation) surfacePresenter?.r19AllocatedAt(preparation.attachment, preparation.outputGeneration) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:444:    fun stageR18Host(generation: Long, settings: KeyguardCardSettings): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:471:    fun stagedR18Host(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:510:    fun revealR18(preparation: R18Preparation, boundary: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:517:    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:518:        surfacePresenter?.sealR18(attachment, outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:535:            surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:568:            // complete before WindowManager.addView and cannot tax first draw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:578:            // the attach callback and installs pre-draw on the real observer.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:620:                        // root draw has completed; it is not needed to render
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:712:        surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:762:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:868:            drawEvidenceEnabled = drawEvidenceEnabled,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:870:            drawEvidenceOwner = KeyguardCardDiagnostics::drawEvidenceOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:917:                    // The material View invokes this while Canvas draw is in
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:932:                // make LIVE look later than it actually became drawable.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:947:                // KeyguardHeaderMaterialView invokes this while Canvas draw is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1062:        root.setBackgroundResource(if (card) R.drawable.fluvi_financial_snapshot_background else android.R.color.transparent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1204:                // shader draw. Animated bootstrap waits until that live draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1227:    /** Registration occurs from root pre-draw before bootstrap Canvas work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1229:     * owner check mirrors the first-draw observation rather than treating a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:754:        var firstPhysicalRequestId: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:755:        var firstPhysicalStartedAtUptimeMs: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:770:        var visibleWithdrawalCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:914:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:945:        "drawGapCount", "drawGapTotalMs", "drawGapMaxMs", "animationStarts", "animationStops",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:946:        "clockRunning", "liveState", "backgroundFrames", "firstShaderTraversalAt", "lastShaderTraversalAt", "drawInvalidOrder",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:947:        "drawEvidenceMode", "drawEvidenceOmitted", "drawObserverNs", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:948:        "drawUnpairedFrames", "drawCoalescedCallbacks", "drawEvidenceBreaks", "drawEvidenceRejected", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:971:        if (stage == "ATTACHMENT_RENDER_SUMMARY") result["drawGapCaptureOmitted"] = gapRecordsOmitted.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:997:            "R19_ALLOCATED", "R19_FIRST_POSITIVE", "R19_PROOF_ACCEPTED", "R19_PROOF_EXPIRED", "R19_EXPIRED_SYSTEM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:998:            "R19_EXPIRED_INGRESS", "R19_EXPIRED_DISPLAY",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:999:            "R19_PAINT_REQUEST", "R19_PAINT_ENTER", "R19_POSTER", "R19_PROOF_CONSUMED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1014:        if (event.reason == "R19_FIRST_POSITIVE") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1019:        if (event.reason == "R19_PROOF_CONSUMED") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1243:    fun drawEvidenceOwner(): Any? = ingress
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1410:                // never evict a wake/attach/draw/withdrawal milestone.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1436:                        it != attempt.firstInspectionRequestId && it != attempt.firstPhysicalRequestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1605:                    if (requestId != null && (attempt.firstPhysicalStartedAtUptimeMs == null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1606:                            event.uptimeMs < attempt.firstPhysicalStartedAtUptimeMs!!)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1607:                        attempt.firstPhysicalRequestId = requestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1608:                        attempt.firstPhysicalStartedAtUptimeMs = event.uptimeMs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1738:                            // newest add. A later no-draw reattach cannot erase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1803:                "R18_PIPELINE" -> reduceR18(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1841:                        // Eight retained shows can each own a withdrawal;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1846:                            // withdrawal ahead of detached cleanup noise.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1889:                    if (attached == true && fields["awaitingSurfaceWithdrawal"] == "true") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1890:                        attempt.visibleWithdrawalCount += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2133:            appendLine("drawObservationMeaning=NO_DRAW_OBSERVED_is_not_proof_of_no_rendering")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2134:            appendLine("drawGapClock=System.nanoTime frameNs=Choreographer cpuNs=threadCPU cbOut=ownedCallbackWorkEndBeforeProbe submit=CPUCanvasCall")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2136:            appendLine("workKinds=1:systemGate,2:inspectionApply,3:diagnosticProducer nestedWorkNotAdditive=true workCoverage=ownedScopesOnly drawObserverNs=bookkeepingOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2232:                    val firstPhysical = attempt.firstPhysicalRequestId?.let(attempt.inspections::get)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2234:                        append(" R18_PIPELINE attempt=${attempt.id} attach=${row.attachment ?: "UNOBSERVED"} host=${row.host} output=${row.output} child=${row.child} privacy=${row.privacy}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2242:                        append(" r19Intent=${value("r19Intent")} alloc=${value("R19_ALLOCATED")} reservedReq=${value("r19ReservedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2243:                        append(" firstRead=${attempt.firstPhysicalRequestId ?: "UNOBSERVED"}@${attempt.firstPhysicalStartedAtUptimeMs ?: "UNOBSERVED"}/${firstPhysical?.finishedAtUptimeMs ?: "UNOBSERVED"}:${firstPhysical?.surfaceClassification ?: "UNOBSERVED"}/${firstPhysical?.surfaceReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2244:                        append(" firstReadQueued=${firstPhysical?.queuedAtUptimeMs ?: "UNOBSERVED"} firstReadAuthority=${firstPhysical?.authorityCurrentAtStart ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2245:                        append(" firstReadRootMs=${firstPhysical?.activeRootTotalMs ?: "UNOBSERVED"} firstReadChildMs=${firstPhysical?.childAcquisitionTotalMs ?: "UNOBSERVED"} firstReadFlags=${firstPhysical?.activeRootFlags ?: "UNOBSERVED"}/${firstPhysical?.acceptedChildFlags ?: "UNOBSERVED"} firstReadIncomplete=${firstPhysical?.rootUnavailable ?: "UNOBSERVED"}/${firstPhysical?.walkTruncated ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2246:                        append(" firstPositive=${value("r19PositiveRequest")}@${value("R19_FIRST_POSITIVE")} readStart=${value("r19ReadStart")} rootMs=${value("r19RootMs")} flags=${value("r19RootFlags")}/${value("r19ChildFlags")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2247:                        append(" scene=${value("r19SceneRead")}/${value("r19SceneConsume")} freshness=${value("r19Freshness")} proofAccepted=${value("R19_PROOF_ACCEPTED")} proofExpired=${value("R19_PROOF_EXPIRED")} systemExpired=${value("R19_EXPIRED_SYSTEM")} ingressExpired=${value("R19_EXPIRED_INGRESS")} displayExpired=${value("R19_EXPIRED_DISPLAY")} consumed=${value("R19_PROOF_CONSUMED")} consumedReq=${value("r19ConsumedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2248:                        append(" paint=${value("R19_PAINT_REQUEST")}/${value("R19_PAINT_ENTER")} poster=${value("r19Poster")}@${value("R19_POSTER")} activeStart=${motion?.activeStartedAtUptimeMs ?: "UNOBSERVED"} firstMotion=${motion?.firstDistinctUptimeMs ?: "UNOBSERVED"} activePosts=${motion?.activeSubmissions ?: "UNOBSERVED"} gaps=${motion?.retainedGaps ?: "UNOBSERVED"}/${motion?.p95GapNs ?: "UNOBSERVED"}/${motion?.worstGapNs ?: "UNOBSERVED"}/${motion?.gapsOver50Ms ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2277:        // show/withdrawal, financial core and recovery records had a chance
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2370:        // occurs here on the diagnostic consumer, never in a draw callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2381:                        val id = "$episodeId:drawGap:$surface:$index"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2441:            val criticalOmissions = omittedRecords.filterNot { it.endsWith(":raw") || it.endsWith(":spineRows") || it.endsWith(":detail") || ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2442:            val omittedGaps = omittedRecords.filter { ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2444:            appendLine("drawGapEvidenceExported=${selected.keys.count { ":drawGap:" in it }} drawGapEvidenceOmitted=${omittedGaps.size}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2459:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2461:            selected.filterKeys { ":drawGap:" in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2488:    private fun actualWithdrawal(attempt: TimingAttempt, show: ShowEpisode): HideEpisode? =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2496:     * evidence. Missing/omitted episodes never overwrite the earliest draw. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2502:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2508:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2518:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2526:        appendLine(" awaiting=unknownWhileHidden:${attempt.unknownWhileHiddenCount},unknownWhileHiddenEpochChanges:${attempt.unknownWhileHiddenEpochChanges},pendingPreservedAfterUnknown:${attempt.pendingPreservedAfterUnknown},pendingRejectedAfterUnknown:${attempt.pendingRejectedAfterUnknown},visibleWithdrawalCount:${attempt.visibleWithdrawalCount},retrySuppressedForPendingWork:${attempt.retrySuppressedForPendingWork},retryBudgetExhaustedWhileAwaiting:${attempt.retryBudgetExhaustedWhileAwaiting}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2531:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideDecisionToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.decisionAtUptimeMs)} localHideToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.localHideAppliedAtUptimeMs)} layerHideSubmitToRemoveBeginMs=${delta(withdrawal?.removeBeginAtUptimeMs, withdrawal?.isolatedLayerHideSubmittedAtUptimeMs)} removeViewCallMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.removeBeginAtUptimeMs)} hideSignalToDecisionMs=${delta(withdrawal?.decisionAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideSignalToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2572:        return " WITHDRAWAL hideOp=${hide.operationId} attach=${hide.attachGeneration ?: "NA"} req=${hide.requestId ?: "NA"} attachedBefore=${hide.attachedBefore ?: "NA"} trigger=${hide.triggerReceivedAtUptimeMs ?: "NA(missingTrigger)"} decision=${hide.decisionAtUptimeMs} local=${hide.localHideAppliedAtUptimeMs ?: "NA"} layerSubmit=${hide.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${hide.isolatedLayerTransactionApplied ?: "NA"} layerApplyReturn=${hide.isolatedLayerApplyReturnedAtUptimeMs ?: "UNOBSERVED"} layerCommit=${hide.isolatedLayerCommitReceivedAtUptimeMs ?: "UNOBSERVED"} remove=${hide.removeBeginAtUptimeMs ?: "NA"}/${hide.removeReturnAtUptimeMs ?: "NA"} detachFailed=${hide.detachFailed} holderTarget=${hide.r15TargetAttachment ?: "UNOBSERVED"}/${hide.r15Generation ?: "UNOBSERVED"} holderAtRevoke=${hide.r15AtRevoke ?: "UNOBSERVED"} holderClock=uptimeMs holderCoherent=${op?.coherent ?: "UNOBSERVED"} holderOp=${op?.id ?: "UNOBSERVED"} lock=${op?.lockEnter ?: "UNOBSERVED"}/${op?.lockReturn ?: "UNOBSERVED"} drawReturn=${op?.drawReturn ?: "UNOBSERVED"} post=${op?.postEnter ?: "UNOBSERVED"}/${op?.postReturn ?: "UNOBSERVED"} record=${op?.recordAt ?: "UNOBSERVED"} revoke=${op?.revokeBegin ?: "UNOBSERVED"}/${op?.revokeReturn ?: "UNOBSERVED"} physical=UNOBSERVED\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2579:        "shaderFrames", "shaderCalls", "phaseAdvances", "drawGapCount", "drawGapTotalMs", "drawGapMaxMs",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2580:        "clockRunning", "liveState", "drawEvidenceMode", "drawEvidenceOmitted", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2581:        "drawObserverNs", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2590:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2591:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2593:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2595:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2596:                    append(compactHideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2597:                    append(compactInspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2617:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2618:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2620:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} postAdd=${episode.postAddSetupAtUptimeMs ?: "UNOBSERVED"} attachState=${episode.attachStateAtObservation ?: "UNOBSERVED"} preDraw=${episode.firstPreDrawAtUptimeMs ?: "UNOBSERVED"} rootSize=${episode.preDrawRootSize ?: "UNOBSERVED"} targetSize=${episode.preDrawTargetSize ?: "UNOBSERVED"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2622:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2623:                    append(hideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2624:                    append(inspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2642:        val needHolderRow = includeHolderDetail || actualWithdrawal(attempt, episode) == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2646:            appendLine(" R15_HOLDER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which clock=uptimeMs coherent=${op.coherent} op=${op.id} lock=${op.lockEnter ?: "UNOBSERVED"}/${op.lockReturn ?: "UNOBSERVED"} drawReturn=${op.drawReturn ?: "UNOBSERVED"} post=${op.postEnter ?: "UNOBSERVED"}/${op.postReturn ?: "UNOBSERVED"} record=${op.recordAt ?: "UNOBSERVED"} revoke=${op.revokeBegin ?: "UNOBSERVED"}/${op.revokeReturn ?: "UNOBSERVED"} screenPresentation=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2963:            "drawCount" to 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:63:    private val reserveBeforeMain: (KeyguardSystemGateRequest, KeyguardSystemState) -> (() -> Unit)? = { _, _ -> null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:97:    fun dispose() { disposed = true; clearPending() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:113:                runCatching { reserveBeforeMain(request, state) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:12:        val sceneSerial: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:28:    fun sceneSerial(): Long = synchronized(lock) { scene }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:42:    fun requireRead(requestId: Long) = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:87:        retained == proof && proof.sceneSerial == scene && proof.requestId >= newestRead &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:94:        if (retained != proof || proof.sceneSerial != scene || proof.requestId < newestRead ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:17:internal class KeyguardOrbInertHost(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:37:    fun stage(generation: Long, geometry: KeyguardOverlayGeometry): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:115:        // A pre-draw callback can be inside ViewRoot traversal. The host is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:125:    fun stagedView(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:28:internal class KeyguardOrbPresentationCoordinator(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:35:    class Withdrawal internal constructor(val reservation: Reservation, val output: Any?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:207:    fun queueReveal(token: Reservation, authority: KeyguardInspectionAuthority,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:251:    fun crossSubmitBoundary(reveal: Reveal): Boolean = synchronized(lock) {
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:95:        worker.prepareHiddenDirect(attachment, generation, width, height, densityDpi,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:133:    fun allocatedAt(attachment: Long, generation: Long): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:142:                       ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:150:        return worker.authorizeDirectFirst(current.target, profile, ticket)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:204:    fun reveal(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:229:    fun sealMatching(attachment: Long, generation: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:242:    fun seal(expectedSerial: Long? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:260:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:85:    fun r19AllocatedAt(attachment: Long, generation: Long): Long? = direct?.allocatedAt(attachment, generation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:91:                          ticket: KeyguardR19FirstPaintTicket): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:107:    fun revealR18(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:115:    fun sealR18() { direct?.seal() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:116:    fun sealR18(attachment: Long, generation: Long) { direct?.sealMatching(attachment, generation) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:136:        sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:213:                worker.surfaceReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:231:            override fun surfaceRedrawNeeded(holder: SurfaceHolder) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:232:                worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion {})
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:235:            override fun surfaceRedrawNeededAsync(holder: SurfaceHolder, drawingFinished: Runnable) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:237:                    worker.requestRedraw(target, KeyguardOrbSurfaceWorkerTestHooks.redrawCompletion(target, drawingFinished))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:239:                    worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion { drawingFinished.run() })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:285:        sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:294:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:394:        override fun onDraw(canvas: Canvas) = drawKeyguardOrbCircle(canvas, paint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:23:internal data class KeyguardR19FirstPaintTicket(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:25:    val sceneSerial: Long, val dataRevision: Long, val visualKey: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:44:    @Volatile var surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:56:    val firstDirectAuthorization = AtomicReference<KeyguardR19FirstPaintTicket?>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:57:    // Worker-owned: transparent host submission happens only on create/redraw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:121:    private var pendingRedraw: KeyguardOrbSurfaceRedrawCompletion? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:133:        if (target != null && !target.revoked && target.surfaceReady) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:134:            draw(target, frameNanos)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:142:            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:171:    fun prepareHiddenDirect(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:197:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:205:            target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:217:    fun authorizeDirectFirst(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:218:                             ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:233:     * for its real SurfaceHolder callback and verifies size before drawing. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:241:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:254:            if (target.directOutput != null) observe(target, "R19_PAINT_ENTER", "worker")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:270:                drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:319:    fun surfaceReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:320:        target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:322:            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:351:            target.metrics?.beginDirectPresentation(SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:360:    fun requestRedraw(target: KeyguardOrbSurfaceTarget, completion: KeyguardOrbSurfaceRedrawCompletion) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:366:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:367:            pendingRedraw = completion
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:369:            if (target.surfaceReady) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:391:                cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:415:        target.surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:418:        // A draw on the separately owned child must not block this callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:422:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:429:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:469:    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:470:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:473:        if (!firstPosted) draw(target, System.nanoTime())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:490:    private fun cancelRedraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:491:        val completion = pendingRedraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:492:        pendingRedraw = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:502:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:517:    private fun draw(target: KeyguardOrbSurfaceTarget, frameNanos: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:521:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:554:        if (currentTarget !== target || target.revoked || !target.surfaceReady || !target.access.tryEnter()) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:572:        var lockEnd = 0L; var drawEnd = 0L; var postEnd = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:580:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:582:                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:584:                previousForFrame?.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:585:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:587:            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:599:            fail(target, "draw:${error.javaClass.simpleName}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:612:                (lockEnd - lockStart).coerceAtLeast(0L), (drawEnd - lockEnd).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:613:                (postEnd - drawEnd).coerceAtLeast(0L), (cpuLockEnd - cpuStart).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:648:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:663:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:31:    private var drawReturn = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:57:        val drawReturn: Long?, val postEnter: Long?, val postReturn: Long?, val recordAt: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:86:        lockEnter = at; lockReturn = 0L; drawReturn = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:92:    fun holderDrawReturned(at: Long) { operationVersion += 1L; drawReturn = at; operationVersion += 1L }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:116:            val a = lockEnter; val b = lockReturn; val c = drawReturn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:130:    fun beginDirectPresentation(at: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:144:               lockWallNs: Long, drawWallNs: Long, postWallNs: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:145:               lockCpuNs: Long, drawCpuNs: Long, postCpuNs: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:162:        maxDrawWall = maxOf(maxDrawWall, drawWallNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:165:        maxDrawCpu = maxOf(maxDrawCpu, drawCpuNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:184:            val lockWall = maxLockWall; val drawWall = maxDrawWall; val postWall = maxPostWall
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:185:            val lockCpu = maxLockCpu; val drawCpu = maxDrawCpu; val postCpu = maxPostCpu
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMetrics.kt:188:                lockWall, drawWall, postWall, lockCpu, drawCpu, postCpu, holderSnapshot(), ownedLayer(),

```
