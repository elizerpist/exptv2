# R29 WIP exact-source graph and native inventory

Application source: `4f89734c4f8dae1ae0cdb645e34ee7e5302f6942`

The Dart SCIP manifest is `docs/codegraph/manifest.json`; Kotlin has no SCIP coverage and the following is source navigation, not a generated call graph. The output/host lifecycle is Main-owned and visual presentation remains an independently measured outcome.

R27 source navigation covers ordered DIRECT admission and terminal withdrawal, the one-reader null-child handoff, owner-scoped public-program warmup and bounded R22/R26/R27 export. STOCK remains separately governed by its existing publication policy. The line inventory is source navigation, not runtime or physical-pixel proof.

```text
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:28:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:106:        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:128:        reserveBeforeMain = ::reserveR18WakeBeforeMain,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:154:    private val openingHandoff = KeyguardOpeningInspectionHandoff()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:226:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:337:                    openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:353:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:378:                openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:392:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:417:            r14Recovery != null || firstAuthorizedOrb.current() != null) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:499:            synchronized(queueLock) { openingHandoff.invalidate() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:500:            sealR18(sample.authority, Long.MAX_VALUE, "systemSample", sample, state)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:549:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:555:                openingHandoff.arm(early.token, early.token.id, request, authority, early.routeRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:            offer.first?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:576:     * later than withdrawal or another wake. The reducer applies its capture
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:584:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:592:        val currentScene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:596:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:616:    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:666:            previous = firstAuthorizedOrb.current()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:667:            scene = firstAuthorizedOrb.externalIngress()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:669:                openingHandoff.externalInvalidation(scene, observedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:675:                r18Coordinator.arbitrateIngress(identity.token, owner.host, owner.output, ordinaryRecheck && binding != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:683:            recordR18(owner, "R19_EXPIRED_$reason", proof = previous.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:684:                r19ReadScene = previous.sceneSerial, r19Freshness = previous.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:686:            runCatching { recordR21(binding, "INGRESS", callbackAt ?: SystemClock.uptimeMillis(), decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:696:    private fun recordR21(binding: R21Binding, stage: String, at: Long, ordinal: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:701:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:704:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R21_$stage",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:722:        recordR18(owner, "R19_ALLOCATED", at)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:753:            overlay.r19AllocatedAt(prep)?.let { recordR18(owner, "R19_ALLOCATED", it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:790:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:791:        runCatching { traceKeyguard("R22_ACQUISITION", "WAIT", requestId = proof, diagnosticContext = context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:803:        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:807:                recordR18(owner, "R19_PROOF_EXPIRED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:808:                    r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:813:                val scene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:832:            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:859:            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:870:                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:877:                    openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:878:                    KeyguardR19FirstPaintTicket(prep.attachment, prep.outputGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:879:                        proof.requestId, proof.sceneSerial, proof.dataRevision, prep.visualKey)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:882:            recordR18(owner, "R19_PAINT_REQUEST", proof = proof.requestId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:897:                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:900:        recordR18(owner, "R19_PROOF_CONSUMED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:901:            r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:946:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:947:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:956:     * original exact output, even after replacement or withdrawal. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:958:        if (observation.stage != "R19_PAINT_ENTER" && observation.stage != "POSTER" &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:959:            observation.stage != "R20_FIRST_FRAME") return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:964:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:965:        val phase = if (observation.stage == "POSTER") "R19_POSTER" else observation.stage
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:967:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:979:                    "r20LockReturnNs" to ns(first?.lockReturnNs), "r20DrawEndNs" to ns(first?.drawEndNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:995:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:996:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1048:            recordR18(owner, "R19_FIRST_POSITIVE", readFinishedAt, proof = request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1052:                val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1057:                proof to if (proof == null) firstAuthorizedOrb.offerRejection(request.id, scene, revision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1063:                    traceKeyguard("R22_ACQUISITION", "PROOF_REJECTED", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1067:                recordR18(owner, "R19_PROOF_EXPIRED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1071:                    traceKeyguard("R22_ACQUISITION", "PROOF_ACCEPTED", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1075:                recordR18(owner, "R19_PROOF_ACCEPTED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1118:        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1126:            recordR21(binding, "FALLBACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(binding.reveal),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1140:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1148:            if (accepted) openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1152:        firstAuthorizedOrb.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1156:        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1158:            recordR21(binding, "SEAL", sealedAt, r18Coordinator.revealOrdinal(binding.reveal), "CANCELLED", reason, offered = requestId.takeUnless { it == Long.MAX_VALUE })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1167:            KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1169:            runCatching { KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R26_SYSTEM_SEAL",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1346:        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1377:    /** The service state that owned the currently attached root's first-draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1378:     * diagnostics. Deferred draw work must match this original identity, not
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1447:                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1507:                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1513:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1548:                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1551:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1688:                        runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1710:                    runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1737:    internal fun cutR22DiagnosticCapture(cut: () -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1746:            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1801:            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1841:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1864:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1993:            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2228:            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2256:        var postClaimForTest: KeyguardOpeningInspectionHandoff.PostClaimSnapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2259:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2264:            openingHandoff.offered(request, actualPending, externalScene, firstAuthorizedOrb.sceneSerial(), frameworkEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2265:            openingHandoff.observePostClaimOffer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2269:                KeyguardCardDiagnostics.recordR22PostClaim(it)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2319:        queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2387:        val claimedOpening = if (openingHandoff.claimedRequestId == request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2389:                openingHandoff.successorStarted(request, started)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2390:                openingHandoff.snapshotForSuccessor(request)?.takeIf { it.claimedId == request.id }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2392:        if (claimedOpening != null) recordOpeningAcquisition("B_START", request, claimedOpening, started)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2400:            inspectSurface(request, started)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2404:                openingHandoff.successorFinished(request, cancelledAt, "CANCELLED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2405:                    ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2410:        val opening = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2411:            openingHandoff.readFinished(request, finished)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2412:            openingHandoff.snapshot(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2423:            recordOpeningAcquisition(phase, request, opening, finished, timing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2434:                openingHandoff.successorFinished(request, finished)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2435:                openingHandoff.snapshotForSuccessor(request)?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2440:            if (closed != null) recordOpeningAcquisition("B_FINISHED", request, closed, finished,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2445:        firstAuthorizedOrb.readCompleted(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2453:            sealR18(current, request.id, inspection.surfaceReason.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2520:     * sampler check can withdraw but never schedules a positive inspection. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2589:            inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2600:                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, completed.read.result.r19ReadSceneSerial)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2613:            if (next != null && serviceJob.isActive) inspectionScope.launch { processInspectionQueue(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2641:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2686:    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2820:                if (owner != null) inspectionQueue.abandonSessionIfActive(owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2821:                else request?.let { inspectionQueue.abandonOpeningTransferIfActive(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2828:    private fun recordOpeningAcquisition(phase: String, request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2829:        opening: KeyguardOpeningInspectionHandoff.Snapshot, at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2834:            !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2835:        runCatching { traceKeyguard("R22_ACQUISITION", phase, request, observedUptimeMs = at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3080:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long): InspectionOutcome {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3101:        val sceneAtRead = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3102:            firstAuthorizedOrb.sceneSerial().also { openingHandoff.readStarted(request, it, startedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3103:        } else firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3104:        val read = readSystemWindows(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3172:    private fun readSystemWindows(request: KeyguardCardInspectionRequest): SystemWindowsRead {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3199:        val yieldHandle = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3200:            openingHandoff.yieldHandle(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3202:        val ingressReader = if (captureOpening) synchronized(queueLock) { openingHandoff.ingressReader(request) } else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3212:                openingYieldHint = yieldHandle?.let { handle -> { openingHandoff.hasHint(handle) } },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3234:                claimOpeningYield = yieldHandle?.let { handle -> { checkpoint, yieldReason, physicalBoundary, safeInventory, visited, roots, children ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3237:                        if (!openingHandoff.isCurrent(handle)) return@synchronized null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3257:                        val successor = openingHandoff.claim(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3259:                            firstAuthorizedOrb.sceneSerial(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3260:                            KeyguardOpeningInspectionHandoff.Conditions(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3275:                                noRetainedProof = firstAuthorizedOrb.current() == null && activeOwner?.firstProof == null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3282:                            openingHandoff.snapshot(request.id)?.postClaim?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3283:                                KeyguardCardDiagnostics.recordR22PostClaim(it)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3290:                    if (authorityIsCurrent(request)) sealR18(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3324:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3475:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3523:            // exclusion. The surface policy below withdraws it nonterminally.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3738:     * work. Real withdrawal revokes the old answer, then reacquires the intent.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3751:        // fallback fires, independently of local withdrawal and tree work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3758:        // Withdrawing a currently visible presentation is contradictory
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3774:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3787:                awaitingSurfaceWithdrawal = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3817:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3818:            // Withdrawal changed authority. Record the obligation under the
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3826:                    // The queued request was captured under the withdrawn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3831:                        "withdrawalAuthorityChanged",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4072:        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4085:                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4130:                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4177:                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation))) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4247:                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4248:                        if (finalSystem.eligible) r18Coordinator.queueReveal(directToken,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4270:                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4271:                                crossed = currentProof && r18Coordinator.crossSubmitBoundary(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4274:                            if (crossed) runCatching { recordR21(binding, "CROSS", SystemClock.uptimeMillis(), ordinal, "CROSSED", "ACCEPTED") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4276:                        }, nativeApplied = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4278:                            val ordinal = r18Coordinator.markNativeApplyReturned(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4279:                            runCatching { recordR21(binding, "NATIVE_APPLY", at, ordinal, "APPLIED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4284:                            if (success && r18Coordinator.revealSubmitted(permit)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4286:                                runCatching { recordR21(binding, "ACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(permit), "ACKNOWLEDGED", "ACCEPTED") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4301:                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4395:        awaitingSurfaceWithdrawal: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4402:        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4405:        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4435:        // only its own listener after the framework draw traversal ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4437:        wakeTiming?.draws?.detach()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4520:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4564:                            "backend:${it.backend},eligible:${it.eligibility},lease:${it.attachment}/${it.generation},draw:${it.firstDrawAtUptimeMs ?: "UNOBSERVED"},exit:${it.lastExitReason}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4565:                        } ?: "backend:UNAVAILABLE,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4571:                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4599:                        "drawGapCount" to summary.orb.gaps,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4600:                        "drawGapTotalMs" to summary.orb.gapTotalMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4601:                        "drawGapMaxMs" to summary.orb.gapMaxMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4602:                        "drawInvalidOrder" to summary.orb.invalidOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4608:                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4609:                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4610:                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4611:                        "drawObservedFrames" to summary.orbGaps.observedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4612:                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4613:                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4614:                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4615:                        "drawEvidenceRejected" to summary.orbGaps.rejected,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4620:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4624:                    fields = mapOf("r22Passive" to "backend:DIRECT,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4655:                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4667:                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4682:                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4686:        // Window visibility is already withdrawn; only now cancel potentially
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4717:    /** Both callbacks arrive after their draw stacks have unwound. The event
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4735:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4752:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4848:        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4849:        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4856:                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4904:            "drawCount" to (values?.frameCallbackCount ?: 0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:33:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:73:    private val drawEvidenceEnabled: () -> Boolean = { KeyguardCardDiagnostics.wantsEvent("DRAW_GAP") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:474:    fun authorizeR19First(preparation: R18Preparation, ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:500:    fun stageR18Host(generation: Long, settings: KeyguardCardSettings): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:527:    fun stagedR18Host(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:566:    fun revealR18(preparation: R18Preparation, boundary: () -> Boolean, nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:569:        surfacePresenter?.revealR18(preparation.attachment, preparation.outputGeneration, boundary, nativeApplied, done) ?: done(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:573:    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:574:        surfacePresenter?.sealR18(attachment, outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:614:            surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:647:            // complete before WindowManager.addView and cannot tax first draw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:657:            // the attach callback and installs pre-draw on the real observer.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:699:                        // root draw has completed; it is not needed to render
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:902:        surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:960:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1068:            drawEvidenceEnabled = drawEvidenceEnabled,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1070:            drawEvidenceOwner = KeyguardCardDiagnostics::drawEvidenceOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1125:                    // The material View invokes this while Canvas draw is in
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1140:                // make LIVE look later than it actually became drawable.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1155:                // KeyguardHeaderMaterialView invokes this while Canvas draw is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1270:        root.setBackgroundResource(if (card) R.drawable.fluvi_financial_snapshot_background else android.R.color.transparent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1412:                // shader draw. Animated bootstrap waits until that live draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1435:    /** Registration occurs from root pre-draw before bootstrap Canvas work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1437:     * owner check mirrors the first-draw observation rather than treating a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:481:        val r22PostClaim = AtomicReferenceArray<KeyguardOpeningInspectionHandoff.PostClaimSnapshot?>(MAX_ATTEMPTS + 1)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:758:        var firstPhysicalRequestId: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:759:        var firstPhysicalStartedAtUptimeMs: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:774:        var visibleWithdrawalCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:925:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE", "R22_ACQUISITION", "R22_4_TRANSITION", "R25_OPENING",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:956:        "drawGapCount", "drawGapTotalMs", "drawGapMaxMs", "animationStarts", "animationStops",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:957:        "clockRunning", "liveState", "backgroundFrames", "firstShaderTraversalAt", "lastShaderTraversalAt", "drawInvalidOrder",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:958:        "drawEvidenceMode", "drawEvidenceOmitted", "drawObserverNs", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:959:        "drawUnpairedFrames", "drawCoalescedCallbacks", "drawEvidenceBreaks", "drawEvidenceRejected", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:982:        if (stage == "ATTACHMENT_RENDER_SUMMARY") result["drawGapCaptureOmitted"] = gapRecordsOmitted.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1020:            "R19_ALLOCATED", "R19_FIRST_POSITIVE", "R19_PROOF_ACCEPTED", "R19_PROOF_EXPIRED", "R19_EXPIRED_SYSTEM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1021:            "R19_EXPIRED_INGRESS", "R19_EXPIRED_DISPLAY",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1022:            "R19_PAINT_REQUEST", "R19_PAINT_ENTER", "R19_POSTER", "R19_PROOF_CONSUMED", "R20_FIRST_FRAME")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1037:        if (event.reason == "R19_PROOF_ACCEPTED") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1044:        if (event.reason == "R19_FIRST_POSITIVE") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1049:        if (event.reason == "R20_FIRST_FRAME") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1057:        if (event.reason.startsWith("R21_")) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1059:            val kind = event.reason.removePrefix("R21_")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1079:        if (event.reason == "R19_PROOF_CONSUMED") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1317:            if (service != null) service.cutR22DiagnosticCapture {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1325:                flushR22PostClaim(active, token)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1344:                flushR22PostClaim(active, ingress)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1451:    fun drawEvidenceOwner(): Any? = ingress
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1459:    fun recordR22PostClaim(observation: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1484:    private fun flushR22PostClaim(active: TimingCapture, token: CaptureIngress?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1499:            fun fact(value: KeyguardOpeningInspectionHandoff.PendingObservation?): String = if (value == null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1685:                // never evict a wake/attach/draw/withdrawal milestone.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1711:                        it != attempt.firstInspectionRequestId && it != attempt.firstPhysicalRequestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1882:                    if (requestId != null && (attempt.firstPhysicalStartedAtUptimeMs == null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1883:                            event.uptimeMs < attempt.firstPhysicalStartedAtUptimeMs!!)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1884:                        attempt.firstPhysicalRequestId = requestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1885:                        attempt.firstPhysicalStartedAtUptimeMs = event.uptimeMs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2022:                            // newest add. A later no-draw reattach cannot erase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2087:                "R18_PIPELINE" -> reduceR18(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2088:                "R22_ACQUISITION" -> reduceR22(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2127:                        // Eight retained shows can each own a withdrawal;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2132:                            // withdrawal ahead of detached cleanup noise.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2175:                    if (attached == true && fields["awaitingSurfaceWithdrawal"] == "true") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2176:                        attempt.visibleWithdrawalCount += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2232:        flushR22PostClaim(active, ingress)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2249:        flushR22PostClaim(active, ingress ?: lastIngress?.takeIf { it.id == active.id })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2423:            appendLine("drawObservationMeaning=NO_DRAW_OBSERVED_is_not_proof_of_no_rendering")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2424:            appendLine("drawGapClock=System.nanoTime frameNs=Choreographer cpuNs=threadCPU cbOut=ownedCallbackWorkEndBeforeProbe submit=CPUCanvasCall")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2426:            appendLine("workKinds=1:systemGate,2:inspectionApply,3:diagnosticProducer nestedWorkNotAdditive=true workCoverage=ownedScopesOnly drawObserverNs=bookkeepingOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2499:        // A short direct/withdrawal core for every selected ORB wake is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2503:                select("a${attempt.id}:r21Core", r21CoreRecord(attempt), attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2563:                    val firstPhysical = attempt.firstPhysicalRequestId?.let(attempt.inspections::get)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2565:                        append(" R18_PIPELINE attempt=${attempt.id} attach=${row.attachment ?: "UNOBSERVED"} host=${row.host} output=${row.output} child=${row.child} privacy=${row.privacy}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2573:                        append(" r19Intent=${value("r19Intent")} alloc=${value("R19_ALLOCATED")} reservedReq=${value("r19ReservedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2574:                        append(" firstRead=${attempt.firstPhysicalRequestId ?: "UNOBSERVED"}@${attempt.firstPhysicalStartedAtUptimeMs ?: "UNOBSERVED"}/${firstPhysical?.finishedAtUptimeMs ?: "UNOBSERVED"}:${firstPhysical?.surfaceClassification ?: "UNOBSERVED"}/${firstPhysical?.surfaceReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2575:                        append(" firstReadQueued=${firstPhysical?.queuedAtUptimeMs ?: "UNOBSERVED"} firstReadAuthority=${firstPhysical?.authorityCurrentAtStart ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2576:                        append(" firstReadRootMs=${firstPhysical?.activeRootTotalMs ?: "UNOBSERVED"} firstReadChildMs=${firstPhysical?.childAcquisitionTotalMs ?: "UNOBSERVED"} firstReadFlags=${firstPhysical?.activeRootFlags ?: "UNOBSERVED"}/${firstPhysical?.acceptedChildFlags ?: "UNOBSERVED"} firstReadIncomplete=${firstPhysical?.rootUnavailable ?: "UNOBSERVED"}/${firstPhysical?.walkTruncated ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2577:                        append(" firstPositive=${value("r19PositiveRequest")}@${value("R19_FIRST_POSITIVE")} readStart=${value("r19ReadStart")} rootMs=${value("r19RootMs")} flags=${value("r19RootFlags")}/${value("r19ChildFlags")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2578:                        append(" scene=${value("r19SceneRead")}/${value("r19SceneConsume")} freshness=${value("r19Freshness")} proofAccepted=${value("R19_PROOF_ACCEPTED")} proofExpired=${value("R19_PROOF_EXPIRED")} systemExpired=${value("R19_EXPIRED_SYSTEM")} ingressExpired=${value("R19_EXPIRED_INGRESS")} displayExpired=${value("R19_EXPIRED_DISPLAY")} consumed=${value("R19_PROOF_CONSUMED")} consumedReq=${value("r19ConsumedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2581:                        append(" paint=${value("R19_PAINT_REQUEST")}/${value("R19_PAINT_ENTER")} poster=${value("r19Poster")}@${value("R19_POSTER")} activeStart=${motion?.activeStartedAtUptimeMs ?: "UNOBSERVED"} firstMotion=${motion?.firstDistinctUptimeMs ?: "UNOBSERVED"} activePosts=${motion?.activeSubmissions ?: "UNOBSERVED"} gaps=${motion?.retainedGaps ?: "UNOBSERVED"}/${motion?.p95GapNs ?: "UNOBSERVED"}/${motion?.worstGapNs ?: "UNOBSERVED"}/${motion?.gapsOver50Ms ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2610:        // show/withdrawal, financial core and recovery records had a chance
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2703:        // occurs here on the diagnostic consumer, never in a draw callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2714:                        val id = "$episodeId:drawGap:$surface:$index"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2774:            val criticalOmissions = omittedRecords.filterNot { it.endsWith(":raw") || it.endsWith(":spineRows") || it.endsWith(":detail") || ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2775:            val omittedGaps = omittedRecords.filter { ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2781:            appendLine("drawGapEvidenceExported=${selected.keys.count { ":drawGap:" in it }} drawGapEvidenceOmitted=${omittedGaps.size}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2796:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2798:            selected.filterKeys { ":drawGap:" in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2823:        val hide = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2849:        // with the show and withdrawal explicitly missing.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2856:        val hide = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2861:        append(" accepted=${d("r26AcceptedRequest")}@${d("R19_PROOF_ACCEPTED")} paintTicket=${d("r20Ticket")}/${d("r20Method")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2864:        append(" consumed=${d("r19ConsumedRequest")}@${d("R19_PROOF_CONSUMED")} showing=${v(showing)}/${v(show?.operationId)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2874:     * close times. Show/withdrawal joins use their exact attachment identity. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2875:    private fun r21CoreRecord(attempt: TimingAttempt): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2881:        val initialHide = initial?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2888:        val firstRead = attempt.firstPhysicalRequestId?.let(attempt.inspections::get)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2895:        append(" R21_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2897:        append(" reservation=${value("r21Reservation")} reservedReq=${value("r19ReservedRequest")} consumedReq=${value("r19ConsumedRequest")} proof=${value("r21Proof")} reveal=${value("r21Reveal")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2901:        append(" firstRead=${v(attempt.firstPhysicalRequestId)}/${v(attempt.firstPhysicalStartedAtUptimeMs)}/${v(firstRead?.finishedAtUptimeMs)}/${v(firstRead?.surfaceClassification)}/${v(firstRead?.surfaceReason)}/${v(firstRead?.activeRootTotalMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2930:        append(" R22_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch} wakeAt=${attempt.startedUptimeMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2967:    private fun actualWithdrawal(attempt: TimingAttempt, show: ShowEpisode): HideEpisode? =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2975:     * evidence. Missing/omitted episodes never overwrite the earliest draw. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2981:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2987:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2997:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3005:        appendLine(" awaiting=unknownWhileHidden:${attempt.unknownWhileHiddenCount},unknownWhileHiddenEpochChanges:${attempt.unknownWhileHiddenEpochChanges},pendingPreservedAfterUnknown:${attempt.pendingPreservedAfterUnknown},pendingRejectedAfterUnknown:${attempt.pendingRejectedAfterUnknown},visibleWithdrawalCount:${attempt.visibleWithdrawalCount},retrySuppressedForPendingWork:${attempt.retrySuppressedForPendingWork},retryBudgetExhaustedWhileAwaiting:${attempt.retryBudgetExhaustedWhileAwaiting}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3010:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideDecisionToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.decisionAtUptimeMs)} localHideToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.localHideAppliedAtUptimeMs)} layerHideSubmitToRemoveBeginMs=${delta(withdrawal?.removeBeginAtUptimeMs, withdrawal?.isolatedLayerHideSubmittedAtUptimeMs)} removeViewCallMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.removeBeginAtUptimeMs)} hideSignalToDecisionMs=${delta(withdrawal?.decisionAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideSignalToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3051:        return " WITHDRAWAL hideOp=${hide.operationId} attach=${hide.attachGeneration ?: "NA"} req=${hide.requestId ?: "NA"} attachedBefore=${hide.attachedBefore ?: "NA"} trigger=${hide.triggerReceivedAtUptimeMs ?: "NA(missingTrigger)"} decision=${hide.decisionAtUptimeMs} local=${hide.localHideAppliedAtUptimeMs ?: "NA"} layerSubmit=${hide.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${hide.isolatedLayerTransactionApplied ?: "NA"} layerApplyReturn=${hide.isolatedLayerApplyReturnedAtUptimeMs ?: "UNOBSERVED"} layerCommit=${hide.isolatedLayerCommitReceivedAtUptimeMs ?: "UNOBSERVED"} remove=${hide.removeBeginAtUptimeMs ?: "NA"}/${hide.removeReturnAtUptimeMs ?: "NA"} detachFailed=${hide.detachFailed} holderTarget=${hide.r15TargetAttachment ?: "UNOBSERVED"}/${hide.r15Generation ?: "UNOBSERVED"} holderAtRevoke=${hide.r15AtRevoke ?: "UNOBSERVED"} holderClock=uptimeMs holderCoherent=${op?.coherent ?: "UNOBSERVED"} holderOp=${op?.id ?: "UNOBSERVED"} lock=${op?.lockEnter ?: "UNOBSERVED"}/${op?.lockReturn ?: "UNOBSERVED"} drawReturn=${op?.drawReturn ?: "UNOBSERVED"} post=${op?.postEnter ?: "UNOBSERVED"}/${op?.postReturn ?: "UNOBSERVED"} record=${op?.recordAt ?: "UNOBSERVED"} revoke=${op?.revokeBegin ?: "UNOBSERVED"}/${op?.revokeReturn ?: "UNOBSERVED"} physical=UNOBSERVED\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3058:        "shaderFrames", "shaderCalls", "phaseAdvances", "drawGapCount", "drawGapTotalMs", "drawGapMaxMs",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3059:        "clockRunning", "liveState", "drawEvidenceMode", "drawEvidenceOmitted", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3060:        "drawObserverNs", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3069:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3070:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3072:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3074:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3075:                    append(compactHideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3076:                    append(compactInspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3096:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3097:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3099:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} postAdd=${episode.postAddSetupAtUptimeMs ?: "UNOBSERVED"} attachState=${episode.attachStateAtObservation ?: "UNOBSERVED"} preDraw=${episode.firstPreDrawAtUptimeMs ?: "UNOBSERVED"} rootSize=${episode.preDrawRootSize ?: "UNOBSERVED"} targetSize=${episode.preDrawTargetSize ?: "UNOBSERVED"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3101:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3102:                    append(hideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3103:                    append(inspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3121:        val needHolderRow = includeHolderDetail || actualWithdrawal(attempt, episode) == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3125:            appendLine(" R15_HOLDER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which clock=uptimeMs coherent=${op.coherent} op=${op.id} lock=${op.lockEnter ?: "UNOBSERVED"}/${op.lockReturn ?: "UNOBSERVED"} drawReturn=${op.drawReturn ?: "UNOBSERVED"} post=${op.postEnter ?: "UNOBSERVED"}/${op.postReturn ?: "UNOBSERVED"} record=${op.recordAt ?: "UNOBSERVED"} revoke=${op.revokeBegin ?: "UNOBSERVED"}/${op.revokeReturn ?: "UNOBSERVED"} screenPresentation=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3442:            "drawCount" to 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:63:    private val reserveBeforeMain: (KeyguardSystemGateRequest, KeyguardSystemState) -> (() -> Unit)? = { _, _ -> null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:97:    fun dispose() { disposed = true; clearPending() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:113:                runCatching { reserveBeforeMain(request, state) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:199:        val openingYieldHint: (() -> Boolean)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:206:        val claimOpeningYield: ((String, KeyguardOpeningYieldReason, Boolean, Boolean, Int, Int, Int) -> KeyguardCardInspectionRequest?)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:520:            if (request.openingYieldHint?.invoke() != true) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:522:                request.claimOpeningYield?.invoke(checkpoint, reason, freshnessBoundaryEstablished, safe, visited,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:529:        val beforeRoot = if (request.openingYieldHint?.invoke() == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:652:                val installed = request.openingYieldHint != null && request.claimOpeningYield != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:669:                visibleIds(root, window.id, prefetch.takeIf { timing.activeRootAccepted }, authorityIsCurrent, timing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:673:                    request.openingEligibleCheckpoint, request.openingYieldHint,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:675:                        if (request.openingYieldHint?.invoke() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:712:    private fun visibleIds(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:723:        openingYieldHint: (() -> Boolean)?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:780:                        if (timing.captureOpening && timing.checkpointState == null && openingYieldHint?.invoke() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:787:                    } else if (timing.captureOpening && timing.checkpointState == null && openingYieldHint?.invoke() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:853:        if (timing.captureOpening && timing.checkpointState == null && openingYieldHint?.invoke() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:46:     * withdrawal in the SAME service/wake. The new request must reacquire
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:48:    fun reacquireAfterWithdrawal(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:100:    fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {}
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:264:    fun handoffOpening(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:277:    fun abandonSessionIfActive(owner: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:289:    fun abandonOpeningTransferIfActive(opening: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:292:        return abandonSessionIfActive(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:390:        return if (!transition.withdrawVisibleOverlay && !transition.invalidatesVisibleAuthority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:443:    val withdrawVisibleOverlay: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:460:        val withdrawing = overlayAttached
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:461:        val next = if (withdrawing) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:475:            withdrawVisibleOverlay = withdrawing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:476:            invalidatesVisibleAuthority = withdrawing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:7:internal class KeyguardOpeningInspectionHandoff {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:17:    data class PostClaimSnapshot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:56:        val postClaim: PostClaimSnapshot?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:266:        val successor = queue.handoffOpening(opening, requireNotNull(next))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:294:    fun observePostClaimOffer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:301:    ): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:326:    fun successorStarted(request: KeyguardCardInspectionRequest, at: Long): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:339:                          reason: String = "FINISHED"): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:350:    private fun postClaimSnapshot(op: Opportunity): PostClaimSnapshot? = op.postClaim?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:351:        PostClaimSnapshot(it.context, op.opening.id, op.reservationId, op.authority, it.claimedId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:12:        val sceneSerial: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:28:    fun sceneSerial(): Long = synchronized(lock) { scene }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:42:    fun requireRead(requestId: Long) = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:94:    fun offerRejection(requestId: Long, readSceneSerial: Long?, freshnessRevision: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:107:        retained == proof && proof.sceneSerial == scene && proof.requestId >= newestRead &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:114:        if (retained != proof || proof.sceneSerial != scene || proof.requestId < newestRead ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:17:internal class KeyguardOrbInertHost(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:37:    fun stage(generation: Long, geometry: KeyguardOverlayGeometry): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:115:        // A pre-draw callback can be inside ViewRoot traversal. The host is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbInertHost.kt:125:    fun stagedView(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:28:internal class KeyguardOrbPresentationCoordinator(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:38:    class Withdrawal internal constructor(val reservation: Reservation, val output: Any?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:212:    fun queueReveal(token: Reservation, authority: KeyguardInspectionAuthority,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:258:    fun crossSubmitBoundary(reveal: Reveal): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:273:    fun markNativeApplyReturned(reveal: Reveal): Long? = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:285:    fun arbitrateIngress(token: Reservation, host: Any?, output: Any?, retainApplied: Boolean): IngressDecision = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:299:    fun revealOrdinal(reveal: Reveal): Long? = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:313:    fun revealSubmitted(reveal: Reveal): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:328:    fun seal(token: Reservation, authority: KeyguardInspectionAuthority, requestId: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:329:             authoritativeExclusion: Boolean): Withdrawal? = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:339:        Withdrawal(token, entry.output, entry.host, entry.crossedSubmitBoundary)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:359:    fun retired(token: Reservation): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:21:internal class KeyguardOrbDirectOutput private constructor(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:33:    fun borrow(): Surface? = if (lifetime.acquire()) surface else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:34:    fun releaseBorrow() { if (lifetime.release()) scheduleDrain(this) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:36:    internal fun seal(): Boolean = lifetime.seal()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:38:    internal fun disposeOnLane(): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:140:    fun reveal(output: KeyguardOrbDirectOutput,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:141:               crossGrantBoundary: () -> Boolean, nativeApplied: () -> Boolean, completed: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:160:                    acceptedApply = runCatching { nativeApplied() }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:173:    fun retire(output: KeyguardOrbDirectOutput, completed: (Boolean) -> Unit = {}) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:226:            transaction.addTransactionCompletedListener(diagnosticExecutor) { stats ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:231:                    val fence = stats.presentFence
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:18:internal class KeyguardOrbR18Presenter(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:100:        worker.prepareHiddenDirect(attachment, generation, width, height, densityDpi,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:145:    fun allocatedAt(attachment: Long, generation: Long): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:154:                       ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:162:        return worker.authorizeDirectFirst(current.target, profile, ticket)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:218:    fun reveal(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:219:               nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:229:        }, nativeApplied = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:230:            owner.get() === current && !current.target.revoked && nativeApplied()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:247:    fun sealMatching(attachment: Long, generation: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:260:    fun seal(expectedSerial: Long? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:279:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:85:    fun r19AllocatedAt(attachment: Long, generation: Long): Long? = direct?.allocatedAt(attachment, generation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:91:                          ticket: KeyguardR19FirstPaintTicket): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:107:    fun revealR18(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean, nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:110:        presenter.reveal(attachment, generation, crossGrantBoundary, nativeApplied, done)
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:24:internal data class KeyguardR19FirstPaintTicket(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:26:    val sceneSerial: Long, val dataRevision: Long, val visualKey: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:45:    @Volatile var surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:57:    val firstDirectAuthorization = AtomicReference<KeyguardR19FirstPaintTicket?>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:66:    // Worker-owned: transparent host submission happens only on create/redraw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:75:    val lockBeginNs: Long, val lockReturnNs: Long, val drawEndNs: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:129:        val ticket: KeyguardR19FirstPaintTicket,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:136:        val ticket: KeyguardR19FirstPaintTicket,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:141:        var lockBeginNs = 0L; var lockReturnNs = 0L; var drawEndNs = 0L; var postReturnNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:168:    private var pendingRedraw: KeyguardOrbSurfaceRedrawCompletion? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:180:        if (target != null && !target.revoked && target.surfaceReady) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:181:            draw(target, frameNanos)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:189:            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:218:    fun prepareHiddenDirect(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:244:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:255:            target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:302:    fun authorizeDirectFirst(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:303:                             ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:318:     * for its real SurfaceHolder callback and verifies size before drawing. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:326:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:342:                                  firstTicket: KeyguardR19FirstPaintTicket? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:344:        if (target.directOutput != null) observe(target, "R19_PAINT_ENTER", "worker")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:396:            drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:424:                    drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:450:                if (replacingFirst && !firstPosted) drawIfReady(target) else scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:459:    fun surfaceReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:460:        target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:462:            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:491:            target.metrics?.beginDirectPresentation(SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:500:    fun requestRedraw(target: KeyguardOrbSurfaceTarget, completion: KeyguardOrbSurfaceRedrawCompletion) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:506:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:507:            pendingRedraw = completion
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:509:            if (target.surfaceReady) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:534:                cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:558:        target.surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:561:        // A draw on the separately owned child must not block this callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:565:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:573:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:626:    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:627:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:630:        if (!firstPosted) draw(target, System.nanoTime())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:647:    private fun cancelRedraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:648:        val completion = pendingRedraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:649:        pendingRedraw = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:659:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:674:    private fun draw(target: KeyguardOrbSurfaceTarget, frameNanos: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:678:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:750:        if (currentTarget !== target || target.revoked || !target.surfaceReady ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:779:        var lockEnd = 0L; var drawEnd = 0L; var postEnd = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:793:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:795:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:797:                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:799:                previousForFrame?.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:800:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:802:            if (firstTiming != null) firstTiming.drawEndNs = System.nanoTime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:806:            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:828:            fail(target, "draw:${error.javaClass.simpleName}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:841:                (lockEnd - lockStart).coerceAtLeast(0L), (drawEnd - lockEnd).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:842:                (postEnd - drawEnd).coerceAtLeast(0L), (cpuLockEnd - cpuStart).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:885:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:895:                    item.drawEndNs, item.postReturnNs, failure, target.r27WarmStatus, target.r27WarmSelector,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:898:                    "R20_FIRST_FRAME", SystemClock.uptimeMillis(), "first", target.full, target.metrics, snapshot))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:915:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:35:internal fun drawKeyguardOrbCircle(canvas: Canvas, paint: Paint, width: Int, height: Int) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:36:    canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:60: * used to record the first picture and to draw subsequent hardware frames. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:80:    fun draw(canvas: Canvas, time: KeyguardMaterialTime, blend: Float = 1f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:82:        drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:85:    fun draw(canvas: Canvas, time: KeyguardOrbSurfaceFrameTime, blend: Float = 1f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:87:        drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:100:    fun drawPrepared(canvas: Canvas) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:101:        drawKeyguardOrbCircle(canvas, paint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:108:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:109:            draw(canvas, time)
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
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:324:    @Test fun r20AuthorizedFullFirstMissDrawsCanonicalPhaseOnExistingChild() = calibratedFirstFrame(false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:330:    @Test fun r21SubmittedPanelSurvivesBenignRecheckAndSealsBeforeLateAck() = calibratedFirstFrame(true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:331:    @Test fun r21PanelCancelsBeforeNativeCross() = calibratedFirstFrame(true, "PRE_CROSS")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:332:    @Test fun r21PanelRetiresInFlightRevealInNativeLaneOrder() = calibratedFirstFrame(true, "IN_FLIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:713:    @Test fun r20ExactAuthorizedPosterHitAvoidsAnotherBuild() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:764:    @Test fun r20FailedFirstLockOrPostNeverPublishesReady() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:812:    @Test fun r20HeldFirstWriteCannotReadyRetiredOwnerOrHideSuccessor() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:47:    @Test fun r21SubmittedDirectOrbSurvivesBenignIngressBeforeMainAck() = runService(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:48:    @Test fun r21ExclusionRetiresSubmittedOrbWithMainAckHeld() = runService(false, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:51:    @Test fun r22SupersededOpeningWalkYieldsToFreshInspection() = KeyguardR22FirstInspectionFixture().run("positive")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:52:    @Test fun r22YieldedWalkCannotGrantAfterExclusion() = KeyguardR22FirstInspectionFixture().run("negative")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:53:    @Test fun r22StableOpeningReadIsNotYielded() = KeyguardR22FirstInspectionFixture().run("stable")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:54:    @Test fun r22UnstagedOpeningObservation() = KeyguardR22FirstInspectionFixture().run("natural")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:230:    @Test fun r22PostClaimQueueEvidenceSurvivesLightPressureAndFreeze() = r22PostClaimQueueEvidence("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:231:    @Test fun r22PostClaimQueueEvidenceSurvivesFullPressureAndFreeze() = r22PostClaimQueueEvidence("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:235:    private fun r22PostClaimQueueEvidence(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:500:    @Test fun r21PhoneShapeProtectsDirectAndFinalWithdrawalCore() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:692:    @Test fun r20FirstFrameBreakdownSurvivesFreezeAndReplacement() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:249:                    override fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:307:            fun verifyExclusionPixels(visual: KeyguardR22VisualCalibration,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:316:                    shadeWindow, independentShadeWindow())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:360:                    independent = independentOpeningScene(service)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:376:                independent = independentOpeningScene(service, requireComplete = true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:446:                        shadeWindow = independentShadeWindow()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:466:                    verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "negative")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:532:                visual.awaitServiceMatch("service-phase-A", identity.bounds, visual.a, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:535:                visual.awaitServiceMatch("service-phase-B", identity.bounds, visual.b, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:538:                visual.awaitServiceMatch("service-phase-A-return", identity.bounds, visual.a, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:544:                    shadeWindow = independentShadeWindow()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:555:                verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "withdrawal")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:630:    private fun independentOpeningScene(service: FluviKeyguardCardService, requireComplete: Boolean = false): String {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:727:    private fun independentShadeWindow(): Int? = listOf(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:196:    fun awaitServiceMatch(label: String, bounds: Rect, reference: Bitmap, underlay: Bitmap): Bitmap {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:299:    @Test fun r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2314:        stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2856:    @Test fun stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22PostClaimEvidenceTest.kt:47:    @Test fun pendingAfterClaimIsReportedWithoutChangingActiveSuccessor() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:154:    @Test fun returnedMainIsConsumedBeforeYieldAndBPerformsFreshCompleteRead() {

# R22.4 source-derived ownership and framework callbacks
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:105:     * input, accessibility, display authority or buffer release. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:106:    internal data class PassiveStandbyObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:113:    private class PassiveStandby(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:126:        fun observation() = PassiveStandbyObservation(attachment, generation, firstDrawAtUptimeMs, hasDrawn)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:129:    private var passiveStandby: PassiveStandby? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:131:    private var passiveBackingMayExist = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:135:    internal fun configurePassiveStandby(target: View, attachment: Long, generation: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:148:        val old = passiveStandby
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:160:        passiveStandby = PassiveStandby(target, attachment, generation, target.left, target.top,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:166:    internal fun passiveStandbyObservation(): PassiveStandbyObservation? = passiveStandby?.observation()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:167:    internal fun passiveBackingMayExist(): Boolean = passiveBackingMayExist
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:169:    internal fun confirmPassiveBackingCleared(epoch: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:170:        if (passiveStandby == null && passiveStateEpoch == epoch) passiveBackingMayExist = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:175:    internal fun clearPassiveStandby(recordObservation: Boolean = false): PassiveStandbyObservation? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:176:        val old = passiveStandby ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:177:        passiveStandby = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:201:    override fun dispatchDraw(canvas: Canvas) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:202:        val state = passiveStandby
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:209:                passiveBackingMayExist = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:215:                passiveStandby = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:219:        super.dispatchDraw(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:222:    override fun onDetachedFromWindow() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:223:        passiveStandby = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:224:        passiveBackingMayExist = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInteractionLayout.kt:226:        super.onDetachedFromWindow()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:300:                it.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:320:            current.clearPassiveStandby()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:336:                onR18Failure = { attachment, generation, reason, releaseAfterRemoval ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:341:                    if (removed) releaseAfterRemoval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:357:            surfacePresenter?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:939:            lifecycle.onDetached()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:960:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:970:        root?.cancelInteraction("dispose", restorePosition = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:972:        materialController?.stop("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:974:        materialController?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:975:        surfacePresenter?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2875:                "r22AFirstRoot" to (timing?.originalOpening?.let { e ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2878:                "r22AFirstChild" to (timing?.originalOpening?.let { e ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2881:                "r22AInvalid" to (timing?.originalOpening?.let { e ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2884:                "r22ACheckpoint" to (timing?.originalOpening?.let { e ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3226:                openingEligibleCheckpoint = if (KeyguardR15AcquisitionTestHooks.ENABLED &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3229:                        runCatching { inspectionProbeForTest?.openingEligibleCheckpoint(request, window, index) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3233:                captureOriginalOpeningEvidence = captureOpening && yieldHandle != null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4378:        "slot:${it.slotId},use:${it.useGeneration},lease:${it.lease?.attachment ?: "NA"}/${it.lease?.generation ?: "NA"},state:${it.state},retired:${it.retired},receipt:${it.callbackReceived},fence:${it.fencePending}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4388:            else -> "result:${sample.resultAt ?: "UNOBSERVED"},status:${sample.resultStatus ?: "UNOBSERVED"},fence:${sample.fenceValid ?: "UNOBSERVED"},state:${sample.disposition}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4563:                        "r22Passive" to (summary.passiveStandby?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4998:        systemSampler.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5000:        // disposed result cannot mutate this service's root or authority.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5010:        if (::overlay.isInitialized) overlay.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1212:                listOf("r22Decision", "r22Reason", "r22Incomplete", "r22AFirstRoot", "r22AFirstChild",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1213:                    "r22AInvalid", "r22ACheckpoint", "r22ADecisive").forEach { key ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2780:            appendLine("omittedPassiveStandbyRecordIds=${compactRecordIds(omittedPassive, 128)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2940:        append(" aRoot=${e("a:r22AFirstRoot")} aFirst=${e("a:r22AFirstChild")} aInvalid=${e("a:r22AInvalid")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2941:        append(" aCheckpoint=${e("a:r22ACheckpoint")} aDecisive=${e("a:r22ADecisive")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3131:            appendLine(" R16_LAYER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which host=${layer.hostId} child=${layer.childId} clock=uptimeMs created=${layer.createdAt ?: "UNOBSERVED"} retire=${layer.retireBegin ?: "UNOBSERVED"}/${layer.retireEnd ?: "UNOBSERVED"}/${layer.retireSucceeded} commitReceipt=${layer.commitReceipt ?: "UNOBSERVED"} commitMain=${layer.commitMain ?: "UNOBSERVED"} disposed=${layer.disposedAt ?: "UNOBSERVED"} lateOp=${late?.id ?: "UNOBSERVED"} latePost=${late?.postEnter ?: "UNOBSERVED"}/${late?.postReturn ?: "UNOBSERVED"} physical=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3358:     * caller has already released [legacyLock], and no event causes a second
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:28: * release authority and contains no scene, buffer, fence or child object. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:70:internal data class KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:208:    private var passiveSummary: KeyguardPassiveStandbySummary? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:215:    private var passiveClearGate: PassiveClearGate? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:222:     * outer finish cannot release a later attachment's guard. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:236:            onFirstCommitted = ::onIsolatedOrbFirstCommitted,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:237:            onFailure = ::onIsolatedOrbFailure,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:251:            onDetachedBackendPrepared = { lease, observedAtUptimeMs ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:297:            if (!next) disarmPassiveStandby("motion-disabled")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:301:                if (lease != null && scene != null) reconcilePassiveStandby(attachedRoot, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:311:     * worker/fence ownership. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:344:            reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:426:            passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:427:            disarmPassiveStandby("privacy-tightening")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:430:                isolatedOrbRenderer.retire("privacy-tightening")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:460:                reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:473:                runCatching { isolatedOrbRenderer.retire("privacy-transition-failure") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:514:        if (passiveClearGate?.configuration != configuration) passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:590:            disarmPassiveStandby("configuration")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:591:            if (!restrictiveTransitionActive && attached && isolatedOrbRequested && passiveRoot.passiveBackingMayExist()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:595:                if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.retire("passive-ineligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:596:                gatePassiveReplacement(passiveRoot, configuration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:608:                isolatedOrbRenderer.retire("legacy-route")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:680:        reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:723:            passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:727:            passiveSummary = if (passiveEvidenceOwner != null) KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:744:            attachmentTranslucentSkippedStart = buffer?.translucentSteadySkipped ?: 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:802:            reconcileIsolatedOrbTarget(root)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:807:    fun onDetached(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:820:        disarmPassiveStandby(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:821:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:856:            isolatedOrbRenderer.retire(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:871:        onDetached(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:893:        isolatedTranslucentSteadySkipped = ((withdrawalWorkerSnapshot ?: buffer)?.translucentSteadySkipped
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:913:        passiveStandby = passiveSummary?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:923:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:925:        stop("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:934:        artifacts.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:935:        gpuPreparer.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:939:            isolatedOrbRenderer.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1191:        reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1245:                    reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1362:                                observation: KeyguardCardInteractionLayout.PassiveStandbyObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1373:        passiveSummary = KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1381:    private fun disarmPassiveStandby(reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1385:        val observed = (attachedRoot as? KeyguardCardInteractionLayout)?.clearPassiveStandby(capture)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1391:    private fun gatePassiveReplacement(root: KeyguardCardInteractionLayout, configuration: MaterialConfiguration) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1394:        passiveClearGate = gate
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1399:                        if (passiveClearGate === gate && attached && attachedRoot === root &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1402:                            root.confirmPassiveBackingCleared(gate.epoch)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1403:                            if (!root.passiveBackingMayExist()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1404:                                passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1405:                                reconcileIsolatedOrbTarget(root)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1416:    private fun reconcilePassiveStandby(root: View?, lease: KeyguardOrbBufferLease, scene: KeyguardMaterialScene) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1428:            disarmPassiveStandby(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1435:            disarmPassiveStandby("BLENDING")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1441:                    latestOrbScene === scene && passiveClearGate == null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1442:                    reconcilePassiveStandby(currentRoot, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1450:        val status = targetRoot.configurePassiveStandby(orb, lease.attachment, lease.generation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1452:        if (status != "ELIGIBLE") disarmPassiveStandby(status)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1454:            rememberPassive(status, targetRoot.passiveStandbyObservation())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1474:    private fun reconcileIsolatedOrbTarget(rootOverride: View? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1480:        if (passiveClearGate != null) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1491:            disarmPassiveStandby("size-change")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1493:            if (container != null && container.passiveBackingMayExist() && configuration != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1497:                if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.retire("passive-size-change")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1498:                gatePassiveReplacement(container, configuration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1520:        if (attached) reconcilePassiveStandby(root, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1583:    private fun onIsolatedOrbFirstCommitted(token: KeyguardOrbFirstPublicationToken) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1590:        latestOrbScene?.let { reconcilePassiveStandby(attachedRoot, lease, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1606:        reconcileIsolatedOrbTarget(attachedRoot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1609:    private fun onIsolatedOrbFailure(lease: KeyguardOrbBufferLease, error: Throwable) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1611:        disarmPassiveStandby("producer-failure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1612:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1625:        isolatedOrbRenderer.retire("producer-failure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1660:        disarmPassiveStandby("pressure-view")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1661:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1682:        // Revocation/clear stay asynchronous with respect to buffer release;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1683:        // Main never waits for Worker, GPU, a commit, or a fence here.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1684:        isolatedOrbRenderer.retire("retired-use-pressure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1756:    val passiveStandby: KeyguardPassiveStandbySummary? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:52: * identity, never by the logging hash; no buffer or fence is retained here. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:68:/** Bounded numeric evidence for one first-use lifetime. No buffer, fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:104:                        fence: SyncFence?, deliver: () -> Unit) = deliver()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:106:    fun onReleaseBoundary(lease: KeyguardOrbBufferLease, slot: Long, use: Long, childIdentity: Int,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:115: * This is not a presentation callback and must never be used to release a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:116: * producer buffer: the worker still owns that through its fence path.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:127: * fence remain renderer-thread-owned. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:156:    val resultAt: Long?, val resultStatus: Int?, val fenceValid: Boolean?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:192:    val translucentSteadySkipped: Long = 0L,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:284:    val fencePending: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:290: * This immutable copy has no buffer, fence or visibility authority. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:403:        grant: Any?, eligible: Boolean, slotCount: Int, oldUnreleased: Int,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:412:            slotCount == 3 && oldUnreleased == 3 -> KeyguardOrbPressureReason.ALL_OLD_UNRELEASED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:453: * permits only child unlink; it never releases or reuses a producer slot. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:497:/** Presence is distinct from the nullable platform fence carried by a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:498: * release receipt. A receipt is consumed exactly once by its slot/use key. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:571:    private val onDetachedBackendPrepared: (KeyguardOrbBufferLease, Long) -> Unit = { _, _ -> },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:607:    fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:611:        api34?.retire(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:614:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:617:        api34?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:706:        private var disposed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:726:                mainHandler.post { if (!disposed) onCapacityRestored(ticket, observedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:740:            if (disposed || desired?.lease != ticket.lease || desired?.scene?.visualKey != ticket.sceneKey ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:752:            if (disposed || ticket.rendererId != rendererId || desired?.lease != ticket.lease ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:766:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:773:                if (layerLease != null && layerLease != spec.lease) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:779:            if (old != null && old.scene.full && !spec.scene.full) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:791:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:802:                retire("attachment-replaced", preserveOffer = preserve)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:816:        fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:820:            // attachment/layer. hideLayer() revokes that lease immediately,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:830:            hideLayer(onLayerHideCommitted, reason, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:832:            worker.retire(retiredLease, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:835:        fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:836:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:837:            retire("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:838:            disposed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:839:            worker.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:845:                enabled = !disposed,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:873:                translucentSteadySkipped = workerSnapshot.translucentSteadySkipped,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:878:            !disposed && firstPublishedToken === token && layer === token.child &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:892:                        retire("root-detached")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:955:                    child.release()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:972:                    runCatching { child.release() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1045:                if (!disposed && attachment?.root === value.root &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1057:        private fun hideLayer(onCommitted: ((Long) -> Unit)? = null, reason: String = "reconfigure",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1074:                    // SurfaceControl's null-buffer form releases the last
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1075:                    // displayed buffer and invokes its release callback.  A
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1077:                    // compositor-owned slot stranded. Commit this release
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1181:                // late use callbacks must not dereference a released child.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1184:                runCatching { child.release() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1207:                        if (!disposed && attachment == null && desired?.lease == frame.lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1208:                            onDetachedBackendPrepared(frame.lease, SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1248:            if (disposed || firstOfferToken !== token) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1282:            if (disposed || firstOfferToken !== offer || active == null || child == null || !child.isValid ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1319:                val release = Consumer<SyncFence> { fence -> worker.release(lease, slotId, useGeneration, fence, childIdentity) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1324:                transaction.setBuffer(child, frame.buffer, frame.fence, release)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1353:                    // local. Keep the exact use until a real receipt/fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1365:            // queue retirement. A fast real release is replayed by Worker.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1388:                if (!disposed && desired?.lease == lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1422:         * hand-off resolves; otherwise a late release/drop callback can target
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1440:             * only means its RenderNode was submitted; its fence still owns
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1443:             * returned to FREE after its release fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1460:            var fencePending: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1473:         * while a release fence is outstanding. At most three fence records
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1475:        private val fenceThread = HandlerThread("fluvi-keyguard-orb-fence").apply { start() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1476:        private val fenceHandler = Handler(fenceThread.looper)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1541:        private var disposed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1545:        private var pressureProgress = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1552:        @Volatile private var translucentSteadySkipped = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1631:            val translucentSteadySkipped: Long = 0L,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1649:                if (disposed) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1722:                    evaluatePressure(value, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1747:                if (disposed || desired?.lease != lease) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1754:                desired?.let { evaluatePressure(it, false) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1826:                // receipt/fence completion can trigger this drain path.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1832:        fun retire(retiredLease: KeyguardOrbBufferLease?, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1861:                // targets; retain those until their callback/fence returns.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1864:                // attachment arrives before an old compositor release.  A
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1868:                // behind a stale release even though the three-slot bound has
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1883:        fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1888:                disposed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1890:                resetStarvation("disposed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1923:                replayEarlyRelease(slot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1929:        fun release(lease: KeyguardOrbBufferLease, slotId: Long, useGeneration: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1930:                    releaseFence: SyncFence?, childIdentity: Int, postAlways: Boolean = true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1933:                runCatching { recoveryHook.onReleaseBoundary(lease, slotId, useGeneration, childIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1935:                recoveryHook.dispatchRelease(lease, slotId, useGeneration, releaseFence) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1936:                    runCatching { recoveryHook.onReleaseBoundary(lease, slotId, useGeneration, childIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1938:                    releaseActual(lease, slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1942:            releaseActual(lease, slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1945:        private fun releaseActual(lease: KeyguardOrbBufferLease, slotId: Long, useGeneration: Long, releaseFence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1950:                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt, expectedLease = lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1955:                    releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1961:                // successful direct return in the release callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1962:                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt, expectedLease = lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1966:        private fun consumeRelease(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1969:            releaseFence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1978:                    consumeRelease(slotId, useGeneration, releaseFence, childIdentity, publicationPath, replayed, receiptAt, expectedLease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1986:                // SurfaceFlinger may release a transaction before the Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1988:                // Retain this exact fence rather than treating READY as FREE.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1990:                val recorded = earlyReleaseReceipts.record(key, releaseFence, receiptAt, childIdentity, expectedLease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1994:                    else if (slot.publicationPath == "first/ready") slot.publicationPath = "first/release-before-ack"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1995:                    noteAcceptedReleaseProgress(slot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1997:                    slot.fencePending = releaseFence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2000:                        observeOwnership("release-received", slot = slot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2004:                    if (slot.retired) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2005:                    desired?.let { evaluatePressure(it, false) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2009:                    releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2011:                observeOwnership("early-release-received", slot = slot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2017:                releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2022:            if (!slot.callbackReceived) noteAcceptedReleaseProgress(slot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2024:            slot.fencePending = releaseFence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2027:                observeOwnership("release-received", slot = slot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2031:            if (slot.retired && !replayed) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2032:            desired?.let { evaluatePressure(it, false) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2033:            awaitFence(slotId, useGeneration, SlotState.WAIT_RELEASE_FENCE, releaseFence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2039:         * feed it once into the same real-fence path after acknowledgement. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2040:        private fun replayEarlyRelease(slot: Slot) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2045:                observeOwnership("release-replayed", slot = slot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2049:            consumeRelease(slot.id, slot.useGeneration, receipt.value, receipt.childIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2058:                ) discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2059:                else frame.fence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2086:                        }, coldSnapshot, translucentSteadySkipped)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2092:                translucentSteadySkipped = translucentSteadySkipped)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2097:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2118:                if (disposed || !ticket.claim.isClaimed()) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2143:            if (running && !disposed && attachedLease == lease && desired?.lease == lease &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2144:                grant?.active == true && grant.lease == lease) pressureProgress += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2148:         * until its actual release fence completes. Retired generations and
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2150:        private fun noteAcceptedReleaseProgress(slot: Slot) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2153:            if (running && !disposed && attachedLease == spec.lease && slot.lease == spec.lease &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2156:                pressureProgress += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2160:        private fun evaluatePressure(spec: KeyguardOrbBufferRenderSpec, opportunity: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2162:            val eligible = running && !disposed && attachedLease == spec.lease &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2164:            var oldUnreleased = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2174:                    if (slot.state == SlotState.PUBLISHED && !slot.callbackReceived) oldUnreleased++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2194:            val reason = pressurePolicy.observe(grant, eligible, slots.size, oldUnreleased, oldOwned, free,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2195:                currentInFlight, wrongSizeOld, currentCompatible, pressureProgress, now, opportunity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2211:                        slot.callbackReceived, slot.fencePending, slot.earlyReceiptRetained)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2220:            if (callbackPosted || disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2287:            evaluatePressure(spec, distinctOpportunity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2292:            // fence drains. READY and RENDERING still cap the active hand-off
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2299:            if (spec.lease.attachment > 0L && running && !disposed && attachedLease == spec.lease &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2316:                    translucentSteadySkipped += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2363:            slot.fencePending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2418:                // release fence, so replacing its root here is safe and makes
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2459:                            fenceValid = result.fence?.isValid == true, disposition = "result"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2471:                    if (disposed || desired?.lease != spec.lease ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2476:                        discardRenderResult(slot, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2500:                    // completion fence without putting readback or waits on
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2512:                            frameObserver.onProduced(producerFrame, slot.buffer, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2518:                        fence = result.fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2527:                        publishSteady(slot, ready)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2533:                        discardRenderResult(slot, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2575:         * makes every submitted display list immutable until its fence ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2595:        private fun publishSteady(slot: Slot, frame: ReadyFrame) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2600:                discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2621:                    frame.fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2622:                    Consumer { releaseFence -> release(submittedLease, submittedSlot, submittedUse,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2623:                        releaseFence, childIdentity, postAlways = false) },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2631:                // Closing the transaction wrapper is never a release receipt.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2638:                    // producer-fence cleanup for this unsubmitted use.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2639:                    discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2642:                    // use; only a real receipt/fence may make it writable.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2647:                        replayEarlyRelease(slot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2655:            // SurfaceControl owns the transferred fence. Acknowledge the
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2666:                replayEarlyRelease(slot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2701:        /** A stale/failed producer completion still owns its render fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2703:        private fun discardRenderResult(slot: Slot, fence: SyncFence?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2709:            awaitFence(slot.id, slot.useGeneration, SlotState.WAIT_RENDER_FENCE, fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2712:        private fun awaitFence(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2716:            fence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2719:                ?.fencePending = fence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2720:            if (fence?.isValid != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2721:                fence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2722:                finishFence(slotId, useGeneration, expected)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2727:                    val signaled = runCatching { fence.await(Duration.ofMillis(16)) }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2729:                        fence.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2730:                        handler.post { finishFence(slotId, useGeneration, expected) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2734:                        // repeating work is this fixed bounded fence record.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2735:                        fenceHandler.postDelayed(this, 16L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2739:            fenceHandler.post(poll)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2747:        private fun finishFence(slotId: Long, useGeneration: Long, expected: SlotState) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2752:            slot.fencePending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2754:                observeOwnership("release-fence-complete", slot = slot, log = slot.retired)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2755:                if (slot.retired) notifyRetiredUse(slot, "release-fence-complete")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2757:            if (disposed) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2767:            if (slots.any { it.state == SlotState.FREE }) resetStarvation("capacity-released")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2768:            desired?.let { evaluatePressure(it, false) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2772:            if (!disposed && (running ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2873:                        fencePending = it.fencePending, earlyReceiptRetained = it.earlyReceiptRetained,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2891:                        append(" callbackReceived=${s.callbackReceived} fencePending=${s.fencePending}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2914:            // This slot remains fenced until its output is released, so do
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2918:        /** The service can dispose on Main while a RenderRequest or
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2919:         * compositor fence still owns a buffer. Leave this short-lived worker
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2920:         * alive only until the platform callback releases that resource; do
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2924:            if (disposed && slots.isEmpty()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2925:                fenceThread.quitSafely()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2976:         * in a cross-thread release callback. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2978:        /** Every async producer/release callback is additionally bound to a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2982:        val fence: SyncFence?,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:56:        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:98:        var calibration: KeyguardR22VisualCalibration? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:149:                calibration = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:152:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:307:            fun verifyExclusionPixels(visual: KeyguardR22VisualCalibration,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:319:                    KeyguardR22VisualCalibration.compare(beforeDisconnect, independentUnderlay).nearlyEqual())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:347:                automation.takeScreenshot()?.let { image ->
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:394:            visualUnderlayFull = checkNotNull(automation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:531:                waitPosted(KeyguardR22VisualCalibration.timeA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:533:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeB
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:534:                waitPosted(KeyguardR22VisualCalibration.timeB)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:536:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:537:                waitPosted(KeyguardR22VisualCalibration.timeA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:558:            val screenshot = automation.takeScreenshot()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:664:                        val result = independentlyWalkActiveTree(root)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:680:    private fun independentlyWalkActiveTree(root: android.view.accessibility.AccessibilityNodeInfo): Pair<Boolean, String> {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:739:        val header = "stage=$stage requestedFlags=${UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES} " +
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:28:internal class KeyguardR22VisualCalibration(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:73:    private fun screenshot(): Bitmap = checkNotNull(automation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:50:    @Test fun r22CalibrationPreservesNonSuppressingAutomation() = KeyguardR22FirstInspectionFixture().run("automation")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:68:        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:324:        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:343:        var visual: KeyguardR22VisualCalibration? = null; var collector: Thread? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:361:            visual = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:362:            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:386:                    if (KeyguardR22VisualCalibration.compare(checkNotNull(visual).a, crop).nearlyEqual()) positiveFile = "$label-full.png"
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:453:                    if(KeyguardR22VisualCalibration.compare(sourceVisual.a,crop).nearlyEqual()) freshPositive="$label-full.png"
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:461:            assertFalse("NOT REACHED: underlay matches old full content",KeyguardR22VisualCalibration.compare(sourceVisual.a,underlay).nearlyEqual())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:505:        val image = checkNotNull(automation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:202:    @Test fun r22PassiveStandbySummarySurvivesLightExport() = passiveStandbyExport("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:203:    @Test fun r22PassiveStandbySummarySurvivesFullExport() = passiveStandbyExport("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:205:    private fun passiveStandbyExport(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:467:                val screen = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2229:                val fullReference = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2314:        stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2459:    @Test fun isolatedOpaqueOrbHasNeutralParentAtRetire() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2480:                val fullScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2515:                    val afterScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2606:    @Test fun isolatedStandbyPreservesAuthorizedComposition() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2613:    @Test fun isolatedStandbyBlackReturnAndHide() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2781:                val terminalScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2856:    @Test fun stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2945:                            val screen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3370:                    val screen = requireNotNull(f.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3417:                        val screen = requireNotNull(f.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3513:    @Test fun isolatedNeutralRecoveryAtCommittedResizedBounds() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3571:            val before = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3583:                    val screen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:4869:                underlay = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5104:                    val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5881:        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5898:        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:6011:        val screen = instrumentation.uiAutomation.takeScreenshot()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:270:    @Test fun translucentSteadyLeavesTheThirdSlotForAnAuthorizedSuccessor() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:316:    @Test fun twoSlotLimitDoesNotApplyToOpaqueNeutralOrUnacknowledgedFirstFrames() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:341:    @Test fun earlyValidFenceKeepsTheExactUseOwnedUntilItSignals() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:361:    @Test fun wrongLeaseSlotOrUseAndDuplicateCannotDrainAnotherUse() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:377:    @Test fun firstDirectPathAlsoReplaysAnEarlyReceiptOnce() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:388:    @Test fun priorAcceptedUseMayDrainWithoutChangingTheReplacementUse() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:403:    @Test fun failureBeforeApplyDrainsProducerButAmbiguousApplyStaysOwned() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:420:    @Test fun throwingObserverAfterTransferCannotDropThePublishedUse() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSteadyCapacityTest.kt:431:    @Test fun synchronousSteadyReceiptIsReplayedAfterPublicationAcknowledgement() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbPressurePolicyTest.kt:102:    @Test fun actualWorkerMixedSizeReceiptRestartsThePressureObservation() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:177:    @Test fun cleanOriginalOffersAtPostMarkerCheckpointAndExportsItsExactBoundary() {

# R22.4 source-derived restriction, evidence and safety controls
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:130:    private class TransitionTrace(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:143:    private var terminalTransitionTrace: TransitionTrace? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:144:    private class WindowRestriction(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:148:        val trace: TransitionTrace?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:154:    private var windowRestriction: WindowRestriction? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:157:    private var secureRebindRequired = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:204:    private fun newTransitionTrace(kind: String, current: View,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:205:                                   controller: KeyguardCardMaterialController?): TransitionTrace? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:206:        if (controller == null || !KeyguardCardDiagnostics.wantsEvent("R22_4_TRANSITION")) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:208:            val evidence = controller.restrictionEvidence()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:209:            TransitionTrace(kind, System.identityHashCode(current), attachGeneration, SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:214:    private fun reportTransitionTrace(trace: TransitionTrace?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:217:            reportWindowDiagnostic("R22_4_TRANSITION", trace.kind, trace.attachment, trace.ingress,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:577:    fun showOrUpdate(presentation: FluviFinancialCardPresentation, settings: KeyguardCardSettings,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:590:            WindowRestriction(current, attachGeneration, previousController,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:591:                newTransitionTrace("DOWNGRADE", current, previousController)).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:602:            restriction.token = restriction.controller.enterRestrictiveTransition()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:735:        if (secureRebindRequired) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:745:                secureRebindRequired = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:812:                failRestrictedUpdate(restriction, presentation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:820:                    restriction.controller.finishRestrictiveTransition(restriction.token, coherentRestriction && sameOwner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:822:                    failRestrictedUpdate(restriction, presentation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:825:                    reportTransitionTrace(restriction.trace)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:836:                        restriction.pendingLayout?.let(::updateLayoutSettings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:838:                        failRestrictedUpdate(restriction, presentation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:840:                        reportTransitionTrace(restriction.trace)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:844:                reportTransitionTrace(restriction.trace)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:849:    private fun failRestrictedUpdate(owner: WindowRestriction, permitted: FluviFinancialCardPresentation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:852:        secureRebindRequired = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:863:            secureRebindRequired = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:869:    fun updateLayoutSettings(settings: KeyguardCardSettings) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:896:            newTransitionTrace("HIDE", current, materialController) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:897:        val priorTrace = terminalTransitionTrace
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:898:        terminalTransitionTrace = trace
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:939:            lifecycle.onDetached()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:940:            secureRebindRequired = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:955:            terminalTransitionTrace = priorTrace
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:956:            reportTransitionTrace(trace)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:982:        secureRebindRequired = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1085:                val trace = terminalTransitionTrace ?: windowRestriction?.trace
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:802:        val r224Transitions: ArrayDeque<TimingEvent> = ArrayDeque(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:803:        var r224TransitionsOmitted: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:925:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE", "R22_ACQUISITION", "R22_4_TRANSITION", "R25_OPENING",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1979:                "R22_4_TRANSITION" -> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1980:                    if (attempt.r224Transitions.size >= 8) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1981:                        attempt.r224Transitions.removeFirst()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1982:                        attempt.r224TransitionsOmitted += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1984:                    attempt.r224Transitions.addLast(event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2514:            attempt.r224Transitions.forEachIndexed { index, event ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2517:                val row = " R22_4_TRANSITION attempt=${attempt.id} req=${event.requestId ?: "UNOBSERVED"}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2525:                    " omitted=${attempt.r224TransitionsOmitted} clock=uptimeMs physical=UNOBSERVED\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1473:                if (stage != "R22_4_TRANSITION" || capturedOperation?.context?.captureId != null) mainHandler.post {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1785:            if (::overlay.isInitialized) overlay.updateLayoutSettings(settings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1832:            overlay.updateLayoutSettings(settings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4141:        // `showOrUpdate` applies material only after a real content/layout
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4157:            overlay.showOrUpdate(presentation, settings, directToken?.stamp?.hostGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4188:        // processing follows WindowManager.addView/showOrUpdate.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:220:    private var restrictiveHideFailed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:236:            onFirstCommitted = ::onIsolatedOrbFirstCommitted,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:238:            onPressure = ::onIsolatedOrbPressure,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:247:            onLayerHideSubmitted = { submission ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:248:                if (restrictiveTransitionActive && !submission.transactionApplied) restrictiveHideFailed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:251:            onDetachedBackendPrepared = { lease, observedAtUptimeMs ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:395:    internal fun restrictionEvidence(): RestrictionEvidence {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:404:    internal fun enterRestrictiveTransition(): RestrictiveTransition? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:410:        restrictiveHideFailed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:431:                check(!restrictiveHideFailed) { "Unable to hide the previous isolated child" }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:441:            finishRestrictiveTransition(owner, coherent = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:446:    internal fun finishRestrictiveTransition(owner: RestrictiveTransition?, coherent: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:450:        restrictiveHideFailed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:491:            !restrictiveTransitionActive) enterRestrictiveTransition() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:684:            finishRestrictiveTransition(ownedRestriction, coherentRestrictedView)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:807:    fun onDetached(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:813:        restrictiveHideFailed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:871:        onDetached(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1583:    private fun onIsolatedOrbFirstCommitted(token: KeyguardOrbFirstPublicationToken) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1640:    private fun onIsolatedOrbPressure(ticket: KeyguardOrbPressureTicket) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:567:    private val onLayerHideSubmitted: (KeyguardOrbLayerHideSubmission) -> Unit = {},
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:571:    private val onDetachedBackendPrepared: (KeyguardOrbBufferLease, Long) -> Unit = { _, _ -> },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:773:                if (layerLease != null && layerLease != spec.lease) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:779:            if (old != null && old.scene.full && !spec.scene.full) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:820:            // attachment/layer. hideLayer() revokes that lease immediately,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:830:            hideLayer(onLayerHideCommitted, reason, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:832:            worker.retire(retiredLease, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1057:        private fun hideLayer(onCommitted: ((Long) -> Unit)? = null, reason: String = "reconfigure",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1120:                    onLayerHideSubmitted(KeyguardOrbLayerHideSubmission(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1208:                            onDetachedBackendPrepared(frame.lease, SystemClock.uptimeMillis())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3090:    @Test fun attachedOrbRestrictionPrecedesFailedLayout() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3170:    @Test fun r22_4RepeatedRestrictionAndFreshFullKeepSameRoot() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3217:    @Test fun r22_4FailedNeutralBindCannotReviveHiddenRoot() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3272:    @Test fun r22_4DetachedDuringFailedLayoutAllowsCleanNextAttach() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3300:    @Test fun r22_4BoundedResizedPrivacyStripWhite() =
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3303:    @Test fun r22_4BoundedResizedPrivacyStripBlack() =
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3483:    @Test fun r22_4NeutralMotionUsesIndependentPhaseReferences() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3513:    @Test fun isolatedNeutralRecoveryAtCommittedResizedBounds() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:160:    @Test fun r224RestrictionEvidenceSurvivesLightPressureAndRestart() = r224RestrictionEvidence("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:161:    @Test fun r224RestrictionEvidenceSurvivesFullPressureAndRestart() = r224RestrictionEvidence("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:163:    private fun r224RestrictionEvidence(mode: String) {

# R25 exact-source ownership, tests and bounded export
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:111:        if (hadR18) hideImmediately("r18RouteChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:128:        reserveBeforeMain = ::reserveR18WakeBeforeMain,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:146:    private val r25Publication = KeyguardOpeningPublication<R25Completed>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:226:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:284:    private val inspectionFreshness = KeyguardInspectionFreshness()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:326:        var r25Retired: KeyguardOpeningPublication.Discarded<R25Completed>? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:342:            inspectionFreshness.publish(current)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:350:            recordR25("DISCARDED", old.ticket.request, old.successor, old.ticket.value.route,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:353:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:361:        val freshness = inspectionFreshness.revisionFor(inspectionAuthority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:372:        r25MainSnapshot = r25BuildSnapshotLocked()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:389:            recordR25("DISCARDED", old.ticket.request, old.successor, old.ticket.value.route,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:392:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:407:    private fun r25BuildSnapshotLocked(): R25RouteSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:417:            r14Recovery != null || firstAuthorizedOrb.current() != null) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:440:        if (!published.authority.matches(request) || r25BuildSnapshotLocked() != published) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:447:                inspectionFreshness.revisionFor(snapshot.authority) == snapshot.freshnessRevision
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:464:        if (inspectionAuthority == early.previousAuthority) inspectionFreshness.publish(inspectionAuthority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:495:    private fun reserveR18WakeBeforeMain(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:546:            inspectionFreshness.publish(authority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:547:            inspectionFreshness.require(authority, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:549:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:557:            val promoted = if (!startsWorker) r25PromoteWaitingLocked() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:563:            recordR25("SUPERSEDED", old.request, offer.first, old.value.route,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:565:            r25RequestExclusionCheck(old.request.session)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:            offer.first?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:592:        val currentScene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:666:            previous = firstAuthorizedOrb.current()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:667:            scene = firstAuthorizedOrb.externalIngress()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:803:        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:813:                val scene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:832:            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:833:                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:859:            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:860:                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:870:                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:871:                    !inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:895:                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:897:                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1052:                val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1057:                proof to if (proof == null) firstAuthorizedOrb.offerRejection(request.id, scene, revision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1130:        hideImmediately("r18Fallback:$reason", terminalWake = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1152:        firstAuthorizedOrb.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1390:                    hideImmediately("screenOff", triggerReceivedUptimeMs = receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1396:                    hideImmediately("userPresent", triggerReceivedUptimeMs = receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1449:                        hideImmediately("r18MotionIneligible", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1572:            onSurfaceFailure = { reason -> hideImmediately("r12SurfaceFailure:$reason") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1722:        hideImmediately("interrupt")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1752:            if (r18Active != null && previous != settings) hideImmediately("r18SettingsChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1754:                hideImmediately("settings")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1802:            hideImmediately("r18InteractionAuthority", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1846:            if (r18Active != null) hideImmediately("r18FocusChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1870:            if (hadR18) hideImmediately("r18MaterialChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2059:            hideImmediately("systemGate:${request.reason}", triggerReceivedUptimeMs = request.receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2207:        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2215:        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2219:    private fun scheduleEvaluationCommon(trigger: String, eventTimeUptimeMs: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2258:            inspectionFreshness.require(authority, request.windowFreshness)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2259:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2264:            openingHandoff.offered(request, actualPending, externalScene, firstAuthorizedOrb.sceneSerial(), frameworkEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2275:            val promoted = if (!startsWorker) r25PromoteWaitingLocked() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2293:            recordR25("SUPERSEDED", old.request, queueOffer.start, old.value.route,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2295:            r25RequestExclusionCheck(old.request.session)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2319:        queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2363:        val superseded: KeyguardOpeningPublication.Ticket<R25Completed>?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2370:        data class Park(val notice: KeyguardOpeningPublication.Notice?, val route: R25RouteSnapshot) : R25Completion
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2445:        firstAuthorizedOrb.readCompleted(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2481:            inspectionFreshness.isEstablished(route.authority, route.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2484:    private fun r25CompleteLocked(read: CompletedInspection, handoff: InspectionHandoff): R25Completion {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2491:        if (!inspectionQueue.canPublishCompleted(request)) return bypass("ORDER_OR_OWNER")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2500:            !inspectionFreshness.isEstablished(route.authority, route.freshnessRevision)) return bypass("FRESHNESS_OR_SCENE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2505:            return inspectionQueue.handoffCompleted(request, pending)?.let { R25Completion.Promote(it, route) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2512:    private fun r25PromoteWaitingLocked(): KeyguardOpeningPublication.Superseded<R25Completed>? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2521:    private fun r25RequestExclusionCheck(originalSession: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2530:    private fun recordR25(phase: String, request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2536:            !KeyguardCardDiagnostics.wantsEvent("R25_OPENING")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2540:            traceKeyguard("R25_OPENING", phase, request, observedUptimeMs = observed,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2550:    private fun r25PostDrain(notice: KeyguardOpeningPublication.Notice, request: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2556:                if (Looper.myLooper() == Looper.getMainLooper()) r25DrainOnMain(notice)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2557:                else if (!mainHandler.post { r25DrainOnMain(notice) }) r25FallbackDrain(notice)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2561:        if (!posted && invoked.compareAndSet(false, true)) r25FallbackDrain(notice)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2564:    private fun r25FallbackDrain(notice: KeyguardOpeningPublication.Notice) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2569:                    withContext(Dispatchers.Main.immediate) { r25DrainOnMain(notice) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2580:    private fun r25DiscardNoticeIfCurrent(notice: KeyguardOpeningPublication.Notice) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2584:        recordR25("DISCARDED", discarded.ticket.request, discarded.successor, discarded.ticket.value.route,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2589:            inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2593:    private fun r25DrainOnMain(notice: KeyguardOpeningPublication.Notice) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2600:                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, completed.read.result.r19ReadSceneSerial)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2602:            recordR25("MAIN_CLAIM", request, route = completed.route, readEnd = completed.read.finishedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2604:            if (current) applyCompletedInspection(completed.read, completed.handoff)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2609:                r25RequestExclusionCheck(request.session)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2613:            if (next != null && serviceJob.isActive) inspectionScope.launch { processInspectionQueue(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2620:    private fun applyCompletedInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2641:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2686:    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2708:                val freshness = snapshot?.let { inspectionFreshness.beforeRead(active) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2735:                when (val opening = synchronized(queueLock) { r25CompleteLocked(read, handoff) }) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2738:                        recordR25("SUPERSEDED", active, opening.successor, opening.route, readEnd = read.finishedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2740:                        r25RequestExclusionCheck(active.session)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2747:                        recordR25("PARKED", active, route = opening.route, readEnd = read.finishedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2750:                            recordR25("POST_REQUESTED", active, route = opening.route, readEnd = read.finishedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2751:                            r25PostDrain(it, active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2758:                        recordR25("BYPASS", active, opening.pending, opening.route, readEnd = read.finishedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2761:                withContext(Dispatchers.Main.immediate) { applyCompletedInspection(read, handoff) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2776:                    applyCompletedInspection(read, handoff, snapshot, successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2805:                                applyCompletedInspection(successorRead, nextHandoff, snapshot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3102:            firstAuthorizedOrb.sceneSerial().also { openingHandoff.readStarted(request, it, startedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3103:        } else firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3176:        val freshness = synchronized(queueLock) { inspectionFreshness.beforeRead(request) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3182:                val current = inspectionFreshness.beforeRead(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3239:                        val latest = inspectionFreshness.beforeRead(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3243:                                inspectionFreshness.isEstablished(freshness.authority, freshness.revision))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3256:                            inspectionFreshness.isEstablished(latest.authority, latest.revision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3259:                            firstAuthorizedOrb.sceneSerial(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3275:                                noRetainedProof = firstAuthorizedOrb.current() == null && activeOwner?.firstProof == null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3296:            onFreshnessEstablished = { freshness?.let(inspectionFreshness::boundaryEstablished) },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3475:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3542:                hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3655:                    hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3781:            val hidden = hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3821:                inspectionFreshness.require(inspectionAuthority, successorFreshness)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3855:        // Already hidden: do not call hideImmediately. A compatible pending
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3860:            inspectionFreshness.require(inspectionAuthority, successorFreshness)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4004:                    if (publicationState?.excluded == true) hideImmediately("publicationGate")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4130:                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4177:                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation))) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4247:                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4270:                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4361:        hideImmediately("open")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4392:    private fun hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4953:            hideImmediately("r18Redact:$reason", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4997:        hideImmediately(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:249:    fun handoffCompleted(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:257:    fun canPublishCompleted(request: KeyguardCardInspectionRequest): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublication.kt:12:internal class KeyguardOpeningPublication<T> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublication.kt:27:        if (waiting != null || claimed != null || !queue.canPublishCompleted(request) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublication.kt:43:        val next = queue.handoffCompleted(expected, successor) ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublication.kt:54:        if (ticket.request.session != notice.session || !queue.canPublishCompleted(ticket.request)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublication.kt:73:        if (!queue.canPublishCompleted(expected)) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:87:    fun isUnclaimedReadCurrent(requestId: Long, readSceneSerial: Long?): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:925:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE", "R22_ACQUISITION", "R22_4_TRANSITION", "R25_OPENING",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1091:    private fun reduceR25(attempt: TimingAttempt, event: TimingEvent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1147:    private fun reduceR25PhysicalRead(attempt: TimingAttempt, event: TimingEvent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1807:                reduceR25PhysicalRead(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2089:                "R25_OPENING" -> reduceR25(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2813:            appendLine(" R25_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch} outcome=UNOBSERVED physical=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2824:        append(" R25_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:9:class KeyguardOpeningPublicationTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:10:    @Test fun successorStartsWhileFirstMainNoticeIsHeld() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:35:    @Test fun pendingBeforeCompletionPromotesOnlyExactCurrentRequest() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:44:    @Test fun mainClaimMakesLaterOfferWaitAndAppliesAtMostOnce() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:115:    @Test fun oldWakeNoticeDrainsOnlyTheNewWakeTicketWithinItsSession() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningPublicationTest.kt:127:    @Test fun failedPostReleasesExactOwnerAndSuccessorPostsItsOwnNotice() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:40:class KeyguardR25ServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:41:    @Test fun heldCompletePositiveReleasesReaderToRealSuccessor() = runScenario("held")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:42:    @Test fun heldCompletePositiveUsesGenericStockOrbRoute() = runScenario("heldStock")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:43:    @Test fun pendingBeforeCompletionPromotesActualSuccessor() = runScenario("pending")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:46:    @Test fun heldPositiveCannotShowAfterRealTerminalUnlock() = runScenario("unlock")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:47:    @Test fun heldPositiveCannotShowAfterRealShadeWithCompositorSamples() = runScenario("shade")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:112:    @Test fun r25OpeningSummarySurvivesLightPressureAndCaptureRotation() = r25OpeningSummary("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:113:    @Test fun r25OpeningSummarySurvivesFullPressureAndCaptureRotation() = r25OpeningSummary("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:115:    private fun r25OpeningSummary(mode: String) {

# R27 direct ordering, incomplete transfer, shader warmup and diagnostics
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:106:        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:111:        if (hadR18) hideImmediately("r18RouteChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:226:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:353:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:392:                inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:417:            r14Recovery != null || firstAuthorizedOrb.current() != null) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:500:            sealR18(sample.authority, Long.MAX_VALUE, "systemSample", sample, state)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:549:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:            offer.first?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:592:        val currentScene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:666:            previous = firstAuthorizedOrb.current()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:667:            scene = firstAuthorizedOrb.externalIngress()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:778:    private fun scheduleR19Join() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:803:        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:813:                val scene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:832:            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:855:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:859:            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:870:                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:897:                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:981:                    "r27WarmStatus" to (first?.warmStatus ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:982:                    "r27WarmSelector" to (first?.warmSelector ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:983:                    "r27WarmLoadNs" to ns(first?.warmLoadNs), "r27WarmQueueNs" to ns(first?.warmQueueNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:984:                    "r27WarmConstructorNs" to ns(first?.warmConstructorNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:985:                    "r27WarmOverlap" to (first?.warmOverlap ?: "UNOBSERVED"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1018:                                   readStartedAt: Long, readFinishedAt: Long): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1048:            recordR18(owner, "R19_FIRST_POSITIVE", readFinishedAt, proof = request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1052:                val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1057:                proof to if (proof == null) firstAuthorizedOrb.offerRejection(request.id, scene, revision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1068:                scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1130:        hideImmediately("r18Fallback:$reason", terminalWake = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1140:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1152:        firstAuthorizedOrb.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1156:        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1390:                    hideImmediately("screenOff", triggerReceivedUptimeMs = receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1396:                    hideImmediately("userPresent", triggerReceivedUptimeMs = receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1447:                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1449:                        hideImmediately("r18MotionIneligible", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1572:            onSurfaceFailure = { reason -> hideImmediately("r12SurfaceFailure:$reason") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1722:        hideImmediately("interrupt")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1746:            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1752:            if (r18Active != null && previous != settings) hideImmediately("r18SettingsChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1754:                hideImmediately("settings")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1801:            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1802:            hideImmediately("r18InteractionAuthority", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1841:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1846:            if (r18Active != null) hideImmediately("r18FocusChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1864:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1870:            if (hadR18) hideImmediately("r18MaterialChanged", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2059:            hideImmediately("systemGate:${request.reason}", triggerReceivedUptimeMs = request.receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2064:            if (r18Active?.preparation?.emptyAwaitingDisclosure == true) scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2259:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2264:            openingHandoff.offered(request, actualPending, externalScene, firstAuthorizedOrb.sceneSerial(), frameworkEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2319:        queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2392:        if (claimedOpening != null) recordOpeningAcquisition("B_START", request, claimedOpening, started)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2411:            openingHandoff.readFinished(request, finished)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2423:            recordOpeningAcquisition(phase, request, opening, finished, timing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2440:            if (closed != null) recordOpeningAcquisition("B_FINISHED", request, closed, finished,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2445:        firstAuthorizedOrb.readCompleted(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2453:            sealR18(current, request.id, inspection.surfaceReason.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2472:    private fun r25CompatibleLocked(ticket: R25Completed, next: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2484:    private fun r25CompleteLocked(read: CompletedInspection, handoff: InspectionHandoff): R25Completion {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2501:        if (!KeyguardOpeningRoutePolicy.useCompletedHandoff(route.backend)) return bypass("DIRECT_ORDERED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2504:            if (!r25CompatibleLocked(ticket, pending)) return bypass("PENDING_INCOMPATIBLE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2515:        if (!r25CompatibleLocked(waiting.value, pending)) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2589:            inspectionScope.launch { processInspectionQueue(actual) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2600:                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, completed.read.result.r19ReadSceneSerial)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2604:            if (current) applyCompletedInspection(completed.read, completed.handoff)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2613:            if (next != null && serviceJob.isActive) inspectionScope.launch { processInspectionQueue(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2614:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2620:    private fun applyCompletedInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2686:    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2735:                when (val opening = synchronized(queueLock) { r25CompleteLocked(read, handoff) }) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2761:                withContext(Dispatchers.Main.immediate) { applyCompletedInspection(read, handoff) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2764:                scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2776:                    applyCompletedInspection(read, handoff, snapshot, successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2805:                                applyCompletedInspection(successorRead, nextHandoff, snapshot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2815:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2828:    private fun recordOpeningAcquisition(phase: String, request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2856:                "r27FirstIncomplete" to (timing?.firstIncompleteReason?.name ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2857:                "r27YieldReason" to (timing?.openingYieldReason?.name ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2858:                "r27Checks" to opening.incompleteChecks, "r27Eligible" to opening.incompleteEligible,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2859:                "r27Rejected" to opening.incompleteRejected, "r27Yielded" to opening.incompleteYielded,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2860:                "r27FirstReject" to (opening.firstIncompleteRejection ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3021:        val firstIncompleteReason: KeyguardWalkIncompleteReason? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3102:            firstAuthorizedOrb.sceneSerial().also { openingHandoff.readStarted(request, it, startedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3103:        } else firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3234:                claimOpeningYield = yieldHandle?.let { handle -> { checkpoint, yieldReason, physicalBoundary, safeInventory, visited, roots, children ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3247:                        val virginDirect = KeyguardR27VirginDirectPolicy.matches(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3259:                            firstAuthorizedOrb.sceneSerial(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3270:                                freshnessEstablished = if (yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3275:                                noRetainedProof = firstAuthorizedOrb.current() == null && activeOwner?.firstProof == null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3290:                    if (authorityIsCurrent(request)) sealR18(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3315:            firstIncompleteReason = result.firstIncompleteReason,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3542:                hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3655:                    hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3781:            val hidden = hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3855:        // Already hidden: do not call hideImmediately. A compatible pending
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4004:                    if (publicationState?.excluded == true) hideImmediately("publicationGate")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4130:                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4177:                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation))) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4247:                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4270:                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4361:        hideImmediately("open")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4392:    private fun hideImmediately(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4402:        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4953:            hideImmediately("r18Redact:$reason", terminalWake = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4997:        hideImmediately(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:178:internal enum class KeyguardOpeningYieldReason { CLEAN_OPENING, INCOMPLETE_NULL_CHILD }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:206:        val claimOpeningYield: ((String, KeyguardOpeningYieldReason, Boolean, Boolean, Int, Int, Int) -> KeyguardCardInspectionRequest?)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:256:        val firstIncompleteReason: KeyguardWalkIncompleteReason? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:272:        val firstIncompleteReason: KeyguardWalkIncompleteReason? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:283:        val firstIncompleteReason: KeyguardWalkIncompleteReason?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:287:        var firstIncompleteReason: KeyguardWalkIncompleteReason? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:421:            firstIncompleteReason = firstIncompleteReason,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:522:                request.claimOpeningYield?.invoke(checkpoint, reason, freshnessBoundaryEstablished, safe, visited,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:652:                val installed = request.openingYieldHint != null && request.claimOpeningYield != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:676:                            val exactSystemRoot = reason != KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:682:                    if (timing.firstIncompleteReason == null) timing.firstIncompleteReason = it.firstIncompleteReason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:696:                    yieldReason = visible.yieldReason, firstIncompleteReason = timing.firstIncompleteReason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:709:            timing.snapshot(treeElapsed), false, readsAfterInvalidation, firstIncompleteReason = timing.firstIncompleteReason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:741:        var firstIncompleteReason: KeyguardWalkIncompleteReason? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:744:            if (firstIncompleteReason == null) firstIncompleteReason = reason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:745:            else if (firstIncompleteReason != reason) mixedIncomplete = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:771:                        !mixedIncomplete && firstIncompleteReason == KeyguardWalkIncompleteReason.NULL_ADVERTISED_CHILD ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:772:                            KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:858:        return VisibleIds(ids, truncated, visited, aborted, readsAfterInvalidation, yieldedTo, yieldReason, firstIncompleteReason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:249:            yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:251:            yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD && op.latestFrameworkEvent != true -> "incompleteNotFramework"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:256:        val incomplete = yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:266:        val successor = queue.handoffOpening(opening, requireNotNull(next))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:283:        op.lastReason = if (yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:284:            "YIELDED_INCOMPLETE_NULL_CHILD" else "YIELDED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:356:    fun readFinished(request: KeyguardCardInspectionRequest, at: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:412:internal object KeyguardR27VirginDirectPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:264:    fun handoffOpening(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:42:    fun requireRead(requestId: Long) = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1053:                "r27WarmStatus", "r27WarmSelector", "r27WarmLoadNs", "r27WarmQueueNs",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1054:                "r27WarmConstructorNs", "r27WarmOverlap")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1205:            "r22Roots", "r22Children", "r22Why", "r22Call", "r22CallBegin", "r22CallEnd", "r27FirstIncomplete", "r27YieldReason",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1206:            "r27Checks", "r27Eligible", "r27Rejected", "r27Yielded", "r27FirstReject").forEach { key ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2466:                .mapNotNull { it.values["r27WarmStatus"]?.takeUnless { value -> value == "UNOBSERVED" } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2469:                "observedOpenings=${openingRows.count { it["r27Checks"] != null }} checks=${sumOpening("r27Checks")} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2470:                "eligible=${sumOpening("r27Eligible")} rejected=${sumOpening("r27Rejected")} yielded=${sumOpening("r27Yielded")} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2473:                "overlap=${retainedAttempts.flatMap { it.r18Generations.values }.count { it.values["r27WarmOverlap"] == "true" }}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2863:        append(" warm=${d("r27WarmStatus")}/${d("r27WarmSelector")} warmNs=${d("r27WarmLoadNs")}/${d("r27WarmQueueNs")}/${d("r27WarmConstructorNs")} overlap=${d("r27WarmOverlap")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2938:        append(" r27v=1 incomplete=${v("r27FirstIncomplete")} yield=${v("r27YieldReason")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2939:        append(" checks=${v("r27Checks")}/${v("r27Eligible")}/${v("r27Rejected")}/${v("r27Yielded")} firstReject=${v("r27FirstReject")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:9:internal data class KeyguardOrbProgramSelector(val effectId: String, val usesPortal: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:11:        fun forProfile(profile: KeyguardMaterialProfile): KeyguardOrbProgramSelector? =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:13:                KeyguardOrbProgramSelector(profile.effectId, profile.usesPortal) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:37:internal class KeyguardOrbDirectProgramWarmup(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:39:    private val submit: (KeyguardOrbSurfaceTarget, KeyguardOrbProgramSelector, KeyguardShaderArtifact, () -> Boolean) -> Unit,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:49:    private data class Request(val target: KeyguardOrbSurfaceTarget, val selector: KeyguardOrbProgramSelector,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:58:    fun request(target: KeyguardOrbSurfaceTarget, selector: KeyguardOrbProgramSelector, current: () -> Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:60:        if (closed || target.revoked || !current() || target.firstDirectAuthorization.get() != null) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:62:        target.r27WarmSelector = "${selector.effectId}|${selector.usesPortal}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:63:        target.r27WarmStatus = "LOADING"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:68:        if (closed || request.target.revoked || !request.current() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:78:                if (!closed && artifact != null && !request.target.revoked && request.current() &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:81:                } else if (request.target.r27WarmStatus == "LOADING") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:82:                    request.target.r27WarmStatus = if (artifact == null) "LOAD_FAILED" else "STALE_OR_BUSY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:86:                entry.store.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:94:            request.target.r27WarmStatus = "LOAD_FAILED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:95:            entry.store.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:105:        entry.request.target.r27WarmStatus = "STALE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:106:        entry.store.retireWhenSettled {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:124:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:18:    val metadata: KeyguardHeaderShader.Metadata,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:32:        val metadata = KeyguardHeaderShader.metadata(context, effectId, usesPortal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:77:                            check(!closed) { "store disposed" }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:117:    fun retireWhenSettled(onSettled: () -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:132:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:45:    @Volatile private var warmup: KeyguardOrbDirectProgramWarmup? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:68:        val captured = owner.get()?.takeIf { it.target === target && !target.revoked } ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:72:            if (owner.get() === captured && !target.revoked) onPrepared(captured.attachment, captured.generation, at)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:99:        val warmSelector = if (emptyAwaitingDisclosure) KeyguardOrbProgramSelector.forProfile(profile) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:100:        worker.prepareHiddenDirect(attachment, generation, width, height, densityDpi,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:106:                    worker.revoke(target, discardFull = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:110:                        if (owner.get() === next && !target.revoked) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:112:                            if (warmSelector != null && owner.get() === next && !target.revoked) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:113:                                val preparation = warmup ?: KeyguardOrbDirectProgramWarmup(context, worker::prewarmDirect).also { warmup = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:115:                                    owner.get() === next && serial.get() == ticket && !target.revoked
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:139:        return if (current.attachment == attachment && current.generation == generation && !target.revoked &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:149:            current.attachment == attachment && current.generation == generation && !current.target.revoked
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:157:        if (current.attachment != attachment || current.generation != generation || current.target.revoked ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:162:        return worker.authorizeDirectFirst(current.target, profile, ticket)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:169:            current.ready.get() && !current.target.revoked
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:184:            !target.revoked && target.full == full && target.width == width && target.height == height &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:194:            current.target.revoked || !host.isAttachedToWindow || host.display?.displayId != Display.DEFAULT_DISPLAY ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:205:        current.target.blankBindPending.set(true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:208:            stillCurrent = { owner.get() === current && !current.target.revoked },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:210:                current.target.blankBindPending.set(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:211:                if (success && owner.get() === current && !current.target.revoked) current.bound.set(true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:212:                main.post { done(success && owner.get() === current && !current.target.revoked) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:223:            current.target.revoked || !current.ready.get() || !current.bound.get()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:228:            owner.get() === current && !current.target.revoked && crossGrantBoundary()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:230:            owner.get() === current && !current.target.revoked && nativeApplied()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:232:            if (success && owner.get() === current && !current.target.revoked) worker.grantPresentation(current.target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:233:            val acknowledgement = Runnable { done(success && owner.get() === current && !current.target.revoked) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:273:            worker.revoke(current.target, discardFull = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:279:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:282:        warmup?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:138:        if (old != null && !old.revoked && old.attachment == attachment && old.full == full &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:146:        if (old != null && !revokeCurrent(privacyTightening)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:181:                if (current !== target || target.revoked) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:190:                        check(current === target && !target.revoked && child.holder === holder)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:194:                            if (output.disposeIfReady()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:204:                    if (current !== target || target.revoked) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:206:                        prepared.disposeIfReady()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:218:                val unexpected = current === target && !target.revoked
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:219:                if (unexpected) revokeCurrent(hideChild = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:251:    fun revokeCurrent(discardFull: Boolean = false, hideChild: Boolean = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:255:        worker.revoke(old, discardFull)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:262:            if (!alreadyRetired && output.disposeIfReady()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:275:            // Diagnostics must never prevent the already-revoked root from
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:286:        revokeCurrent()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:294:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:297:        direct?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:299:        worker.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:368:        current === target && !target.revoked && surface?.holder === target.holder && root.isAttachedToWindow
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:372:        revokeCurrent(discardFull = target.full, hideChild = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:44:    @Volatile var revoked = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:59:    val blankBindPending = AtomicBoolean(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:60:    @Volatile var r27WarmStatus = "NOT_REQUESTED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:61:    @Volatile var r27WarmSelector: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:120:        val painter: KeyguardOrbSurfacePainter,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:155:    private var currentPainter: KeyguardOrbSurfacePainter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:157:    private var previousPainter: KeyguardOrbSurfacePainter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:162:    private data class WarmProgram(val target: KeyguardOrbSurfaceTarget,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:163:        val selector: KeyguardOrbProgramSelector, val shader: KeyguardHeaderShader)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:165:    private var warmProgram: WarmProgram? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:175:    private var disposed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:180:        if (target != null && !target.revoked && target.surfaceReady) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:182:            if (target.live && target.motionAllowed && currentTarget === target && !target.revoked) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:189:            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:201:            if (disposed || request != preparationGeneration.get() || authorizedTarget.get() != null) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:218:    fun prepareHiddenDirect(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:230:            if (disposed || request != preparationGeneration.get() || authorizedTarget.get() != null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:238:            if (disposed || request != preparationGeneration.get() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:257:                revoke(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:261:            if (safe != null) prepareAuthorized(target, safe, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:267:    fun prewarmDirect(target: KeyguardOrbSurfaceTarget, selector: KeyguardOrbProgramSelector,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:272:            if (disposed || target.revoked || currentTarget !== target || authorizedTarget.get() !== target ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:273:                !ownerCurrent() || target.firstDirectAuthorization.get() != null || target.blankBindPending.get()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:274:                target.r27WarmStatus = "STALE_OR_BUSY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:277:            if (!selector.accepts(artifact)) { target.r27WarmStatus = "BAD_ARTIFACT"; return@post }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:278:            if (target.firstDirectAuthorization.get() != null || target.blankBindPending.get()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:279:                target.r27WarmStatus = "STALE_OR_BUSY"; return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:285:                KeyguardHeaderShader(artifact)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:289:            if (shader == null) { target.r27WarmStatus = "CONSTRUCTOR_FAILED"; return@post }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:290:            if (disposed || target.revoked || currentTarget !== target || authorizedTarget.get() !== target || !ownerCurrent()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:291:                target.r27WarmStatus = "STALE"; return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:293:            warmProgram = WarmProgram(target, selector, shader)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:294:            target.r27WarmStatus = "READY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:302:    fun authorizeDirectFirst(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:304:        if (target.directOutput == null || !target.full || target.revoked || ticket.attachment != target.attachment ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:310:            if (!disposed && !target.revoked && currentTarget === target && authorizedTarget.get() === target &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:312:                prepareAuthorized(target, safe, request, ticket)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:324:            if (disposed || target.revoked) return@postAtFrontOfQueue
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:337:            prepareAuthorized(target, safe, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:341:    private fun prepareAuthorized(target: KeyguardOrbSurfaceTarget, safe: KeyguardMaterialProfile, request: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:351:            !disposed && authorizedTarget.get() === target && currentTarget === target && !target.revoked &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:368:                val selector = KeyguardOrbProgramSelector.forProfile(safe)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:369:                val ready = warmProgram?.takeIf { it.target === target && it.selector == selector }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:371:                    warmProgram = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:372:                    target.r27WarmStatus = "HIT"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:374:                    if (target.r27WarmStatus == "READY") target.r27WarmStatus = "STALE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:375:                    else if (target.r27WarmStatus == "LOADING" || target.r27WarmStatus == "NOT_REQUESTED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:376:                        target.r27WarmStatus = "NO_READY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:380:                val painter = KeyguardOrbSurfacePainter(context, safe, target.width, target.height, ready?.shader)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:411:            if (disposed || currentTarget !== target || target.revoked || request != preparationGeneration.get()) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:416:                prepareAuthorized(target, safe, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:437:                    authorizedTarget.get() === target && !target.revoked && request == preparationGeneration.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:439:                if (target.revoked || currentTarget !== target || authorizedTarget.get() !== target ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:462:            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:469:            if (currentTarget !== target || target.revoked || !target.live) return@postAtFrontOfQueue
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:486:        if (target.revoked || target.directOutput == null) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:489:            if (currentTarget !== target || target.revoked || !target.presentationGranted) return@postAtFrontOfQueue
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:502:            if (disposed || currentTarget !== target || target.revoked) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:514:    fun revoke(target: KeyguardOrbSurfaceTarget, discardFull: Boolean = false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:516:        val measuredRevoke = !target.revoked && target.metrics != null && isCaptureActive()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:517:        if (measuredRevoke) target.metrics?.revokeStarted(SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:518:        target.revoked = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:519:        target.access.revoke()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:520:        if (target.ownsOutput) target.shellAccess.revoke()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:521:        if (measuredRevoke) target.metrics?.revokeReturned(SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:524:            if (warmProgram?.target === target) warmProgram = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:559:        revoke(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:565:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:567:        authorizedTarget.getAndSet(null)?.let { it.revoked = true; it.access.revoke() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:569:            disposed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:570:            currentTarget?.let { finishFirstObservation(it, "DISPOSED"); it.revoked = true; it.access.revoke() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:578:            warmProgram = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:607:        val painter = KeyguardOrbSurfacePainter(context, profile, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:627:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:631:        if (target.live && target.motionAllowed && firstPosted && !target.revoked) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:636:        if (framePending || disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:678:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:712:        var previousForFrame: KeyguardOrbSurfacePainter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:750:        if (currentTarget !== target || target.revoked || !target.surfaceReady ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:767:            if (selection != null && !target.revoked && currentTarget === target) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:845:            if (target.revoked) target.metrics?.r16PinLateOperation()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:847:        if (!posted || currentTarget !== target || target.revoked ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:895:                    item.drawEndNs, item.postReturnNs, failure, target.r27WarmStatus, target.r27WarmSelector,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:911:        if (currentTarget !== target || target.revoked) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:912:        target.revoked = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:913:        target.access.revoke()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:61:internal class KeyguardOrbSurfacePainter(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:66:    preparedShader: KeyguardHeaderShader? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:70:        KeyguardHeaderShader(context, profile.effectId, profile.usesPortal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:204:        val shader: KeyguardHeaderShader,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:205:        val metadata: KeyguardHeaderShader.Metadata,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:216:    private var shaderCurrent: KeyguardHeaderShader? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:217:    private var shaderPrevious: KeyguardHeaderShader? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:223:    private var preparedMetadata: KeyguardHeaderShader.Metadata? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:430:        return runCatching { KeyguardHeaderShader(artifact) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:677:    private fun drawShader(canvas: Canvas, shader: KeyguardHeaderShader, scene: KeyguardMaterialScene, alpha: Float) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:912:        fun compile(error: Throwable, metadata: KeyguardHeaderShader.Metadata) = KeyguardMaterialRendererFailure(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:930:internal class KeyguardHeaderShader(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:238:    @Test fun incompleteOriginalWithoutClaimCapabilityCannotYieldOrAuthorizeDespitePendingNewerRequest() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:270:    @Test fun incompleteOriginalWithoutCapabilityStillReadsRemainingChild() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:303:    @Test fun incompleteWithoutNewerRequestOrRemainingWorkCannotYield() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:319:    @Test fun incompleteWrongSystemRootAndChangedAuthorityCannotYield() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:336:    @Test fun incompleteExceptionOrMixedTruncationCannotBecomeNullChildTransfer() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:349:    @Test fun decisiveMarkerBeforeMissingChildAlwaysPreventsIncompleteTransfer() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:359:    @Test fun incompleteOriginalCanYieldOnlyToGenuineSuccessorBeforeNextChildWithoutCapture() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR27VirginDirectPolicyTest.kt:6:class KeyguardR27VirginDirectPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR27VirginDirectPolicyTest.kt:26:    @Test fun reservedBeforeMainAdoptionRetainsExactVirginTarget() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR27VirginDirectPolicyTest.kt:32:    @Test fun adoptedBeforeOwnerPublicationUsesOnlyExactRetainedRoute() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbWarmupOwnershipTest.kt:33:    @Test fun retirementClosesTheStoreAndReportsOnlyAfterItsRealReadSettles() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbWarmupOwnershipTest.kt:53:    @Test fun replacedAToBToAUsesOnlyLatestOwnerAndNeverOverlapsLoads() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:39:    @Test fun pendingDirectWaitsForOrderedMainThenStartsRealSuccessor() = exercise(true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:40:    @Test fun stableDirectUsesOrderedMainAndLaterOfferWaits() = exercise(false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:314:    @Test fun r26VisibleDirectUnlockAndRapidRelock() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:325:    @Test fun r27WarmDirectMissUsesPreparedProgramAndCanonicalPixels() =
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:327:    @Test fun r27NoReadyDirectMissFallsBackColdWithCanonicalPixels() =
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:28:    @Test fun r26ExactDirectEvidenceSurvivesLightAndFullPressure() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:54:                        "r27WarmStatus" to "HIT", "r27WarmSelector" to "dualTide_plain", "r27WarmLoadNs" to 100,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:55:                        "r27WarmQueueNs" to 200, "r27WarmConstructorNs" to 300, "r27WarmOverlap" to false))

# R29 WIP native cross-process source inventory
The client, ownership gate and snapshot builder are presently unwired. Binder entry is a SystemUI process thread, preparation runs on one host worker and adoption/notifications are posted to Main. The composition scene and restrictive-frame hook are absent; these source references do not establish runtime behavior.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:15:import com.fluvi.r29.contract.R29WireCodec
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:23:internal class R29HostClient(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:25:    private val ownership: R29Ownership,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:81:                    runCatching { service.interfaceDescriptor == R29WireCodec.INTERFACE }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:87:                if (!send(service, R29WireCodec.TRANSACTION_SESSION) { out ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:100:        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:102:                reply?.writeString(R29WireCodec.INTERFACE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:105:            if (code !in R29WireCodec.CALLBACK_SESSION..R29WireCodec.CALLBACK_EMPTY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:106:                return super.onTransact(code, data, reply, flags)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:113:                data.enforceInterface(R29WireCodec.INTERFACE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:118:                    R29WireCodec.CALLBACK_SESSION -> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:128:                    R29WireCodec.CALLBACK_READY -> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:137:                    R29WireCodec.CALLBACK_EMPTY -> Unit
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:154:            if (!send(target, R29WireCodec.TRANSACTION_PREPARE) { R29WireCodec.writeDescriptor(it, snapshot) }) unavailable()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:158:    fun invalidate(nonce: String, sequence: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:165:            if (!send(target, R29WireCodec.TRANSACTION_INVALIDATE) { out ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:174:            data.writeInterfaceToken(R29WireCodec.INTERFACE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt:184:            if (target != null && nonce != null) send(target, R29WireCodec.TRANSACTION_DETACH) { it.writeString(nonce) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29Ownership.kt:11:internal class R29Ownership(private val store: Store) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29PublisherSnapshot.kt:7:import com.fluvi.app.lockscreen.material.R29MaterialMapper
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29PublisherSnapshot.kt:43:internal object R29PublisherSnapshot {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29PublisherSnapshot.kt:97:            material = R29MaterialMapper.fromProfile(permittedProfile),
platform/aosp16/contract/src/com/fluvi/r29/contract/R29FramePolicy.kt:22:internal object R29FramePolicy {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt:29:    @Synchronized fun prepare(value: R29Descriptor, nowEpochMs: Long, parcelBytes: Int): R29Descriptor? {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt:47:    @Synchronized fun workerFinished(token: String, sequence: Long): R29Descriptor? {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt:63:    @Synchronized fun adopt(token: String, sequence: Long, nowEpochMs: Long): Boolean {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt:73:    @Synchronized fun invalidate(token: String, sequence: Long): Boolean {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt:103:    @Synchronized fun current(nowEpochMs: Long): R29Descriptor? {
platform/aosp16/contract/src/com/fluvi/r29/contract/R29WireCodec.kt:8: * Fixed, data-only Binder wire format. The receiving onTransact MUST check
platform/aosp16/contract/src/com/fluvi/r29/contract/R29WireCodec.kt:12:internal object R29WireCodec {
platform/aosp16/contract/src/com/fluvi/app/lockscreen/material/R29MaterialMapper.kt:7:internal object R29MaterialMapper {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:26:import com.fluvi.r29.contract.R29WireCodec
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:50:    private fun trustedCaller(uid: Int): Boolean = runCatching {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:84:            data.writeInterfaceToken(R29WireCodec.INTERFACE)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:92:        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:94:                reply?.writeString(R29WireCodec.INTERFACE)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:97:            if (code !in R29WireCodec.TRANSACTION_SESSION..R29WireCodec.TRANSACTION_OWNERSHIP)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:98:                return super.onTransact(code, data, reply, flags)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:102:                if (!trustedCaller(callerUid)) throw SecurityException("R29 publisher not enrolled")
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:104:                data.enforceInterface(R29WireCodec.INTERFACE)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:106:                R29WireCodec.TRANSACTION_SESSION -> {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:115:                            runCatching { sendCallback(callback, R29WireCodec.CALLBACK_READY, token, sequence) }
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:123:                    runCatching { sendCallback(callback, R29WireCodec.CALLBACK_SESSION, nonce, ownershipEpoch) }
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:126:                R29WireCodec.TRANSACTION_PREPARE -> {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:127:                    val descriptor = R29WireCodec.readDescriptor(data)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:130:                        runtime.store.invalidate(descriptor.session, descriptor.sequence)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:132:                        runtime.store.prepare(descriptor, System.currentTimeMillis(), data.dataSize())
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:135:                R29WireCodec.TRANSACTION_INVALIDATE -> {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:139:                    runtime.store.invalidate(nonce, sequence)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:141:                R29WireCodec.TRANSACTION_DETACH -> {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:146:                R29WireCodec.TRANSACTION_OWNERSHIP -> {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:153:                    runtime.store.invalidate(nonce, sequence)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29HostRenderer.kt:15:import com.fluvi.app.lockscreen.material.R29MaterialMapper
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29HostRenderer.kt:25:internal class R29PreparedOrb(
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29HostRenderer.kt:62:internal class R29HostRenderer(private val context: Context, private val worker: Executor) {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29HostRenderer.kt:68:    fun prepare(descriptor: R29Descriptor, finished: (Result<R29PreparedOrb>) -> Unit) {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29HostRenderer.kt:75:            val profile = R29MaterialMapper.toProfile(descriptor.material, descriptor.session, descriptor.sequence)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:42:    fun prepare(descriptor: R29Descriptor, nowEpochMs: Long, actualParcelBytes: Int): Boolean {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:50:            next = reducer.prepare(descriptor, nowEpochMs, actualParcelBytes)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:58:    fun invalidate(nonce: String, sequence: Long): Boolean {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:61:            if (!reducer.invalidate(nonce, sequence)) return@synchronized false
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:92:    fun current(nowEpochMs: Long): R29PreparedOrb? = synchronized(lock) {
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:94:        val eligible = reducer.current(nowEpochMs)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:105:            renderer.prepare(work) { result ->
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:109:                    next = reducer.workerFinished(work.session, work.sequence)
platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:111:                    if (output != null && reducer.adopt(work.session, work.sequence, System.currentTimeMillis())) {

```
