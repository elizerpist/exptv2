# R22.2 opening and isolated ORB source graph and native inventory

Application source: `fe8931a69c96e964f78561a3100e3d776dfe5dfc`

The Dart SCIP manifest is `docs/codegraph/manifest.json`; Kotlin has no SCIP coverage and the following is source navigation, not a generated call graph. The output/host lifecycle is Main-owned and visual presentation remains an independently measured outcome.

Source navigation: FluviKeyguardCardService.reserveR18WakeBeforeMain arms the original opportunity; external scene ingress and the ordinary queue offer qualify a successor. inspectSurface/readSystemWindows supply the physical reader checkpoint; KeyguardOpeningInspectionHandoff.claim validates the current token and freshness and KeyguardCardInspectionQueue.handoffOpening transfers the exact pending request. processInspectionQueue resumes the single physical reader; completed fresh inspection still reaches the existing first-authorized proof and presentation path. KeyguardCardDiagnostics reduces R22_ACQUISITION into each retained R22_CORE beside R21_CORE. The grep inventory below gives exact source locations, not proof of runtime execution.

```text
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:28:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:106:        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:128:        reserveBeforeMain = ::reserveR18WakeBeforeMain,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:146:    private val openingHandoff = KeyguardOpeningInspectionHandoff()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:203:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:310:                    openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:343:                openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:415:            synchronized(queueLock) { openingHandoff.invalidate() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:416:            sealR18(sample.authority, Long.MAX_VALUE, "systemSample")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:465:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:471:                openingHandoff.arm(early.token, early.token.id, request, authority, early.routeRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:480:            if (offer.first) inspectionScope.launch { processInspectionQueue(request) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:485:     * later than withdrawal or another wake. The reducer applies its capture
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:492:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:497:        val currentScene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:501:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:521:    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:570:            previous = firstAuthorizedOrb.current()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:            scene = firstAuthorizedOrb.externalIngress()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:573:                openingHandoff.externalInvalidation(scene, observedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:579:                r18Coordinator.arbitrateIngress(identity.token, owner.host, owner.output, ordinaryRecheck && binding != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:587:            recordR18(owner, "R19_EXPIRED_$reason", proof = previous.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:588:                r19ReadScene = previous.sceneSerial, r19Freshness = previous.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:590:            runCatching { recordR21(binding, "INGRESS", callbackAt ?: SystemClock.uptimeMillis(), decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:600:    private fun recordR21(binding: R21Binding, stage: String, at: Long, ordinal: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:605:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:608:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R21_$stage",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:626:        recordR18(owner, "R19_ALLOCATED", at)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:657:            overlay.r19AllocatedAt(prep)?.let { recordR18(owner, "R19_ALLOCATED", it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:694:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:695:        runCatching { traceKeyguard("R22_ACQUISITION", "WAIT", requestId = proof, diagnosticContext = context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:707:        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:711:                recordR18(owner, "R19_PROOF_EXPIRED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:712:                    r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:717:                val scene = firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:736:            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:763:            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:774:                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:781:                    openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:782:                    KeyguardR19FirstPaintTicket(prep.attachment, prep.outputGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:783:                        proof.requestId, proof.sceneSerial, proof.dataRevision, prep.visualKey)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:786:            recordR18(owner, "R19_PAINT_REQUEST", proof = proof.requestId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:801:                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:804:        recordR18(owner, "R19_PROOF_CONSUMED", proof = proof.requestId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:805:            r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:850:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:851:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:860:     * original exact output, even after replacement or withdrawal. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:862:        if (observation.stage != "R19_PAINT_ENTER" && observation.stage != "POSTER" &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:863:            observation.stage != "R20_FIRST_FRAME") return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:868:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:869:        val phase = if (observation.stage == "POSTER") "R19_POSTER" else observation.stage
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:871:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:883:                    "r20LockReturnNs" to ns(first?.lockReturnNs), "r20DrawEndNs" to ns(first?.drawEndNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:894:        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:895:        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:947:            recordR18(owner, "R19_FIRST_POSITIVE", readFinishedAt, proof = request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:951:                val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:955:                proof to if (proof == null) firstAuthorizedOrb.offerRejection(request.id, scene, revision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:961:                    traceKeyguard("R22_ACQUISITION", "PROOF_REJECTED", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:965:                recordR18(owner, "R19_PROOF_EXPIRED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:969:                    traceKeyguard("R22_ACQUISITION", "PROOF_ACCEPTED", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:974:                recordR18(owner, "R19_PROOF_ACCEPTED", proof = request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1017:        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1025:            recordR21(binding, "FALLBACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(binding.reveal),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1039:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String): R18Active? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1045:            if (accepted) openingHandoff.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1049:        firstAuthorizedOrb.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1053:        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1055:            recordR21(binding, "SEAL", sealedAt, r18Coordinator.revealOrdinal(binding.reveal), "CANCELLED", reason, offered = requestId.takeUnless { it == Long.MAX_VALUE })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1225:        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1256:    /** The service state that owned the currently attached root's first-draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1257:     * diagnostics. Deferred draw work must match this original identity, not
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1326:                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1384:                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1390:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1425:                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1428:                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1565:                        runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1587:                    runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1614:    internal fun cutR22DiagnosticCapture(cut: () -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1623:            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1678:            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1718:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1741:            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1870:            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2105:            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2133:        var postClaimForTest: KeyguardOpeningInspectionHandoff.PostClaimSnapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2136:            firstAuthorizedOrb.requireRead(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2141:            openingHandoff.offered(request, actualPending, externalScene, firstAuthorizedOrb.sceneSerial(), frameworkEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2142:            openingHandoff.observePostClaimOffer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2146:                KeyguardCardDiagnostics.recordR22PostClaim(it)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2180:        if (queueOffer.first) inspectionScope.launch { processInspectionQueue(request) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2224:        val claimedOpening = if (openingHandoff.claimedRequestId == request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2226:                openingHandoff.successorStarted(request, started)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2227:                openingHandoff.snapshotForSuccessor(request)?.takeIf { it.claimedId == request.id }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2229:        if (claimedOpening != null) recordOpeningAcquisition("B_START", request, claimedOpening, started)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2237:            inspectSurface(request, started)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2241:                openingHandoff.successorFinished(request, cancelledAt, "CANCELLED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2242:                    ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2247:        val opening = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2248:            openingHandoff.readFinished(request, finished)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2249:            openingHandoff.snapshot(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2260:            recordOpeningAcquisition(phase, request, opening, finished, timing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2271:                openingHandoff.successorFinished(request, finished)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2272:                openingHandoff.snapshotForSuccessor(request)?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2277:            if (closed != null) recordOpeningAcquisition("B_FINISHED", request, closed, finished,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2282:        firstAuthorizedOrb.readCompleted(request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2290:            sealR18(current, request.id, inspection.surfaceReason.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2330:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2375:    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2483:                if (owner != null) inspectionQueue.abandonSessionIfActive(owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2484:                else request?.let { inspectionQueue.abandonOpeningTransferIfActive(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2491:    private fun recordOpeningAcquisition(phase: String, request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2492:        opening: KeyguardOpeningInspectionHandoff.Snapshot, at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2497:            !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2498:        runCatching { traceKeyguard("R22_ACQUISITION", phase, request, observedUptimeMs = at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2723:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long): InspectionOutcome {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2744:        val sceneAtRead = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2745:            firstAuthorizedOrb.sceneSerial().also { openingHandoff.readStarted(request, it, startedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2746:        } else firstAuthorizedOrb.sceneSerial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2747:        val read = readSystemWindows(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2814:    private fun readSystemWindows(request: KeyguardCardInspectionRequest): SystemWindowsRead {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2841:        val yieldHandle = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2842:            openingHandoff.yieldHandle(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2844:        val ingressReader = if (captureOpening) synchronized(queueLock) { openingHandoff.ingressReader(request) } else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2854:                openingYieldHint = yieldHandle?.let { handle -> { openingHandoff.hasHint(handle) } },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2868:                claimOpeningYield = yieldHandle?.let { handle -> { checkpoint, physicalBoundary, safeInventory, visited, roots, children ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2871:                        if (!openingHandoff.isCurrent(handle)) return@synchronized null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2878:                        val successor = openingHandoff.claim(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2880:                            firstAuthorizedOrb.sceneSerial(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2881:                            KeyguardOpeningInspectionHandoff.Conditions(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2899:                        if (successor != null) openingHandoff.snapshot(request.id)?.postClaim?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2900:                            KeyguardCardDiagnostics.recordR22PostClaim(it)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2906:                    if (authorityIsCurrent(request)) sealR18(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2938:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3089:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3137:            // exclusion. The surface policy below withdraws it nonterminally.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3352:     * work. Real withdrawal revokes the old answer, then reacquires the intent.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3365:        // fallback fires, independently of local withdrawal and tree work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3372:        // Withdrawing a currently visible presentation is contradictory
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3388:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3401:                awaitingSurfaceWithdrawal = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3431:        if (transition.withdrawVisibleOverlay) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3432:            // Withdrawal changed authority. Record the obligation under the
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3440:                    // The queued request was captured under the withdrawn
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3445:                        "withdrawalAuthorityChanged",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3686:        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3699:                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3744:                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3791:                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation))) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3861:                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3862:                        if (finalSystem.eligible) r18Coordinator.queueReveal(directToken,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3884:                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3885:                                crossed = currentProof && r18Coordinator.crossSubmitBoundary(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3888:                            if (crossed) runCatching { recordR21(binding, "CROSS", SystemClock.uptimeMillis(), ordinal, "CROSSED", "ACCEPTED") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3890:                        }, nativeApplied = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3892:                            val ordinal = r18Coordinator.markNativeApplyReturned(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3893:                            runCatching { recordR21(binding, "NATIVE_APPLY", at, ordinal, "APPLIED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3898:                            if (success && r18Coordinator.revealSubmitted(permit)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3900:                                runCatching { recordR21(binding, "ACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(permit), "ACKNOWLEDGED", "ACCEPTED") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3915:                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4009:        awaitingSurfaceWithdrawal: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4016:        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4019:        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4049:        // only its own listener after the framework draw traversal ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4051:        wakeTiming?.draws?.detach()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4134:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4177:                            "backend:${it.backend},eligible:${it.eligibility},lease:${it.attachment}/${it.generation},draw:${it.firstDrawAtUptimeMs ?: "UNOBSERVED"},exit:${it.lastExitReason}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4178:                        } ?: "backend:UNAVAILABLE,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4184:                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4212:                        "drawGapCount" to summary.orb.gaps,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4213:                        "drawGapTotalMs" to summary.orb.gapTotalMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4214:                        "drawGapMaxMs" to summary.orb.gapMaxMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4215:                        "drawInvalidOrder" to summary.orb.invalidOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4221:                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4222:                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4223:                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4224:                        "drawObservedFrames" to summary.orbGaps.observedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4225:                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4226:                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4227:                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4228:                        "drawEvidenceRejected" to summary.orbGaps.rejected,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4233:                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4237:                    fields = mapOf("r22Passive" to "backend:DIRECT,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4268:                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4280:                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4295:                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4299:        // Window visibility is already withdrawn; only now cancel potentially
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4330:    /** Both callbacks arrive after their draw stacks have unwound. The event
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4348:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4365:        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4461:        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4462:        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4469:                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4517:            "drawCount" to (values?.frameCallbackCount ?: 0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:33:import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:73:    private val drawEvidenceEnabled: () -> Boolean = { KeyguardCardDiagnostics.wantsEvent("DRAW_GAP") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:421:    fun authorizeR19First(preparation: R18Preparation, ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:447:    fun stageR18Host(generation: Long, settings: KeyguardCardSettings): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:474:    fun stagedR18Host(generation: Long): View? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:513:    fun revealR18(preparation: R18Preparation, boundary: () -> Boolean, nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:516:        surfacePresenter?.revealR18(preparation.attachment, preparation.outputGeneration, boundary, nativeApplied, done) ?: done(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:520:    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:521:        surfacePresenter?.sealR18(attachment, outputGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:538:            surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:571:            // complete before WindowManager.addView and cannot tax first draw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:581:            // the attach callback and installs pre-draw on the real observer.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:623:                        // root draw has completed; it is not needed to render
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:715:        surfacePresenter?.sealR18()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:765:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:871:            drawEvidenceEnabled = drawEvidenceEnabled,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:873:            drawEvidenceOwner = KeyguardCardDiagnostics::drawEvidenceOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:920:                    // The material View invokes this while Canvas draw is in
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:935:                // make LIVE look later than it actually became drawable.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:950:                // KeyguardHeaderMaterialView invokes this while Canvas draw is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1065:        root.setBackgroundResource(if (card) R.drawable.fluvi_financial_snapshot_background else android.R.color.transparent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1207:                // shader draw. Animated bootstrap waits until that live draw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1230:    /** Registration occurs from root pre-draw before bootstrap Canvas work.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1232:     * owner check mirrors the first-draw observation rather than treating a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:481:        val r22PostClaim = AtomicReferenceArray<KeyguardOpeningInspectionHandoff.PostClaimSnapshot?>(MAX_ATTEMPTS + 1)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:758:        var firstPhysicalRequestId: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:759:        var firstPhysicalStartedAtUptimeMs: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:774:        var visibleWithdrawalCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:920:        "R10_ROOT_REGISTRATION", "R10_ROOT_ATTACH_DISPATCH", "R10_ROOT_FIRST_LAYOUT", "R10_MAIN_ASYNC_READY", "R11_FIRST", "R12_SURFACE", "R14_RECOVERY", "R18_PIPELINE", "R22_ACQUISITION",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:951:        "drawGapCount", "drawGapTotalMs", "drawGapMaxMs", "animationStarts", "animationStops",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:952:        "clockRunning", "liveState", "backgroundFrames", "firstShaderTraversalAt", "lastShaderTraversalAt", "drawInvalidOrder",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:953:        "drawEvidenceMode", "drawEvidenceOmitted", "drawObserverNs", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:954:        "drawUnpairedFrames", "drawCoalescedCallbacks", "drawEvidenceBreaks", "drawEvidenceRejected", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:977:        if (stage == "ATTACHMENT_RENDER_SUMMARY") result["drawGapCaptureOmitted"] = gapRecordsOmitted.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1003:            "R19_ALLOCATED", "R19_FIRST_POSITIVE", "R19_PROOF_ACCEPTED", "R19_PROOF_EXPIRED", "R19_EXPIRED_SYSTEM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1004:            "R19_EXPIRED_INGRESS", "R19_EXPIRED_DISPLAY",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1005:            "R19_PAINT_REQUEST", "R19_PAINT_ENTER", "R19_POSTER", "R19_PROOF_CONSUMED", "R20_FIRST_FRAME")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1020:        if (event.reason == "R19_FIRST_POSITIVE") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1025:        if (event.reason == "R20_FIRST_FRAME") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1031:        if (event.reason.startsWith("R21_")) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1033:            val kind = event.reason.removePrefix("R21_")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1053:        if (event.reason == "R19_PROOF_CONSUMED") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1219:            if (service != null) service.cutR22DiagnosticCapture {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1227:                flushR22PostClaim(active, token)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1246:                flushR22PostClaim(active, ingress)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1353:    fun drawEvidenceOwner(): Any? = ingress
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1361:    fun recordR22PostClaim(observation: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1386:    private fun flushR22PostClaim(active: TimingCapture, token: CaptureIngress?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1401:            fun fact(value: KeyguardOpeningInspectionHandoff.PendingObservation?): String = if (value == null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1587:                // never evict a wake/attach/draw/withdrawal milestone.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1613:                        it != attempt.firstInspectionRequestId && it != attempt.firstPhysicalRequestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1782:                    if (requestId != null && (attempt.firstPhysicalStartedAtUptimeMs == null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1783:                            event.uptimeMs < attempt.firstPhysicalStartedAtUptimeMs!!)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1784:                        attempt.firstPhysicalRequestId = requestId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1785:                        attempt.firstPhysicalStartedAtUptimeMs = event.uptimeMs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1915:                            // newest add. A later no-draw reattach cannot erase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1980:                "R18_PIPELINE" -> reduceR18(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1981:                "R22_ACQUISITION" -> reduceR22(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2019:                        // Eight retained shows can each own a withdrawal;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2024:                            // withdrawal ahead of detached cleanup noise.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2067:                    if (attached == true && fields["awaitingSurfaceWithdrawal"] == "true") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2068:                        attempt.visibleWithdrawalCount += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2124:        flushR22PostClaim(active, ingress)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2141:        flushR22PostClaim(active, ingress ?: lastIngress?.takeIf { it.id == active.id })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2314:            appendLine("drawObservationMeaning=NO_DRAW_OBSERVED_is_not_proof_of_no_rendering")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2315:            appendLine("drawGapClock=System.nanoTime frameNs=Choreographer cpuNs=threadCPU cbOut=ownedCallbackWorkEndBeforeProbe submit=CPUCanvasCall")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2317:            appendLine("workKinds=1:systemGate,2:inspectionApply,3:diagnosticProducer nestedWorkNotAdditive=true workCoverage=ownedScopesOnly drawObserverNs=bookkeepingOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2379:        // A short direct/withdrawal core for every selected ORB wake is
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2383:                select("a${attempt.id}:r21Core", r21CoreRecord(attempt), attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2420:                    val firstPhysical = attempt.firstPhysicalRequestId?.let(attempt.inspections::get)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2422:                        append(" R18_PIPELINE attempt=${attempt.id} attach=${row.attachment ?: "UNOBSERVED"} host=${row.host} output=${row.output} child=${row.child} privacy=${row.privacy}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2430:                        append(" r19Intent=${value("r19Intent")} alloc=${value("R19_ALLOCATED")} reservedReq=${value("r19ReservedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2431:                        append(" firstRead=${attempt.firstPhysicalRequestId ?: "UNOBSERVED"}@${attempt.firstPhysicalStartedAtUptimeMs ?: "UNOBSERVED"}/${firstPhysical?.finishedAtUptimeMs ?: "UNOBSERVED"}:${firstPhysical?.surfaceClassification ?: "UNOBSERVED"}/${firstPhysical?.surfaceReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2432:                        append(" firstReadQueued=${firstPhysical?.queuedAtUptimeMs ?: "UNOBSERVED"} firstReadAuthority=${firstPhysical?.authorityCurrentAtStart ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2433:                        append(" firstReadRootMs=${firstPhysical?.activeRootTotalMs ?: "UNOBSERVED"} firstReadChildMs=${firstPhysical?.childAcquisitionTotalMs ?: "UNOBSERVED"} firstReadFlags=${firstPhysical?.activeRootFlags ?: "UNOBSERVED"}/${firstPhysical?.acceptedChildFlags ?: "UNOBSERVED"} firstReadIncomplete=${firstPhysical?.rootUnavailable ?: "UNOBSERVED"}/${firstPhysical?.walkTruncated ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2434:                        append(" firstPositive=${value("r19PositiveRequest")}@${value("R19_FIRST_POSITIVE")} readStart=${value("r19ReadStart")} rootMs=${value("r19RootMs")} flags=${value("r19RootFlags")}/${value("r19ChildFlags")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2435:                        append(" scene=${value("r19SceneRead")}/${value("r19SceneConsume")} freshness=${value("r19Freshness")} proofAccepted=${value("R19_PROOF_ACCEPTED")} proofExpired=${value("R19_PROOF_EXPIRED")} systemExpired=${value("R19_EXPIRED_SYSTEM")} ingressExpired=${value("R19_EXPIRED_INGRESS")} displayExpired=${value("R19_EXPIRED_DISPLAY")} consumed=${value("R19_PROOF_CONSUMED")} consumedReq=${value("r19ConsumedRequest")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2438:                        append(" paint=${value("R19_PAINT_REQUEST")}/${value("R19_PAINT_ENTER")} poster=${value("r19Poster")}@${value("R19_POSTER")} activeStart=${motion?.activeStartedAtUptimeMs ?: "UNOBSERVED"} firstMotion=${motion?.firstDistinctUptimeMs ?: "UNOBSERVED"} activePosts=${motion?.activeSubmissions ?: "UNOBSERVED"} gaps=${motion?.retainedGaps ?: "UNOBSERVED"}/${motion?.p95GapNs ?: "UNOBSERVED"}/${motion?.worstGapNs ?: "UNOBSERVED"}/${motion?.gapsOver50Ms ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2467:        // show/withdrawal, financial core and recovery records had a chance
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2560:        // occurs here on the diagnostic consumer, never in a draw callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2571:                        val id = "$episodeId:drawGap:$surface:$index"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2631:            val criticalOmissions = omittedRecords.filterNot { it.endsWith(":raw") || it.endsWith(":spineRows") || it.endsWith(":detail") || ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2632:            val omittedGaps = omittedRecords.filter { ":drawGap:" in it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2638:            appendLine("drawGapEvidenceExported=${selected.keys.count { ":drawGap:" in it }} drawGapEvidenceOmitted=${omittedGaps.size}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2653:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2655:            selected.filterKeys { ":drawGap:" in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2668:     * close times. Show/withdrawal joins use their exact attachment identity. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2669:    private fun r21CoreRecord(attempt: TimingAttempt): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2675:        val initialHide = initial?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2682:        val firstRead = attempt.firstPhysicalRequestId?.let(attempt.inspections::get)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2689:        append(" R21_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2691:        append(" reservation=${value("r21Reservation")} reservedReq=${value("r19ReservedRequest")} consumedReq=${value("r19ConsumedRequest")} proof=${value("r21Proof")} reveal=${value("r21Reveal")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2695:        append(" firstRead=${v(attempt.firstPhysicalRequestId)}/${v(attempt.firstPhysicalStartedAtUptimeMs)}/${v(firstRead?.finishedAtUptimeMs)}/${v(firstRead?.surfaceClassification)}/${v(firstRead?.surfaceReason)}/${v(firstRead?.activeRootTotalMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2723:        append(" R22_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch} wakeAt=${attempt.startedUptimeMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2756:    private fun actualWithdrawal(attempt: TimingAttempt, show: ShowEpisode): HideEpisode? =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2764:     * evidence. Missing/omitted episodes never overwrite the earliest draw. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2770:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2776:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2786:        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2794:        appendLine(" awaiting=unknownWhileHidden:${attempt.unknownWhileHiddenCount},unknownWhileHiddenEpochChanges:${attempt.unknownWhileHiddenEpochChanges},pendingPreservedAfterUnknown:${attempt.pendingPreservedAfterUnknown},pendingRejectedAfterUnknown:${attempt.pendingRejectedAfterUnknown},visibleWithdrawalCount:${attempt.visibleWithdrawalCount},retrySuppressedForPendingWork:${attempt.retrySuppressedForPendingWork},retryBudgetExhaustedWhileAwaiting:${attempt.retryBudgetExhaustedWhileAwaiting}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2799:        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideDecisionToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.decisionAtUptimeMs)} localHideToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.localHideAppliedAtUptimeMs)} layerHideSubmitToRemoveBeginMs=${delta(withdrawal?.removeBeginAtUptimeMs, withdrawal?.isolatedLayerHideSubmittedAtUptimeMs)} removeViewCallMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.removeBeginAtUptimeMs)} hideSignalToDecisionMs=${delta(withdrawal?.decisionAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideSignalToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2840:        return " WITHDRAWAL hideOp=${hide.operationId} attach=${hide.attachGeneration ?: "NA"} req=${hide.requestId ?: "NA"} attachedBefore=${hide.attachedBefore ?: "NA"} trigger=${hide.triggerReceivedAtUptimeMs ?: "NA(missingTrigger)"} decision=${hide.decisionAtUptimeMs} local=${hide.localHideAppliedAtUptimeMs ?: "NA"} layerSubmit=${hide.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${hide.isolatedLayerTransactionApplied ?: "NA"} layerApplyReturn=${hide.isolatedLayerApplyReturnedAtUptimeMs ?: "UNOBSERVED"} layerCommit=${hide.isolatedLayerCommitReceivedAtUptimeMs ?: "UNOBSERVED"} remove=${hide.removeBeginAtUptimeMs ?: "NA"}/${hide.removeReturnAtUptimeMs ?: "NA"} detachFailed=${hide.detachFailed} holderTarget=${hide.r15TargetAttachment ?: "UNOBSERVED"}/${hide.r15Generation ?: "UNOBSERVED"} holderAtRevoke=${hide.r15AtRevoke ?: "UNOBSERVED"} holderClock=uptimeMs holderCoherent=${op?.coherent ?: "UNOBSERVED"} holderOp=${op?.id ?: "UNOBSERVED"} lock=${op?.lockEnter ?: "UNOBSERVED"}/${op?.lockReturn ?: "UNOBSERVED"} drawReturn=${op?.drawReturn ?: "UNOBSERVED"} post=${op?.postEnter ?: "UNOBSERVED"}/${op?.postReturn ?: "UNOBSERVED"} record=${op?.recordAt ?: "UNOBSERVED"} revoke=${op?.revokeBegin ?: "UNOBSERVED"}/${op?.revokeReturn ?: "UNOBSERVED"} physical=UNOBSERVED\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2847:        "shaderFrames", "shaderCalls", "phaseAdvances", "drawGapCount", "drawGapTotalMs", "drawGapMaxMs",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2848:        "clockRunning", "liveState", "drawEvidenceMode", "drawEvidenceOmitted", "drawObservedFrames",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2849:        "drawObserverNs", "drawGapCaptureOmitted",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2858:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2859:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2861:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2863:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2864:                    append(compactHideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2865:                    append(compactInspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2885:            val withdrawal = actualWithdrawal(attempt, episode)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2886:            withdrawal?.let { pairedHides += it.operationId }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2888:                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} postAdd=${episode.postAddSetupAtUptimeMs ?: "UNOBSERVED"} attachState=${episode.attachStateAtObservation ?: "UNOBSERVED"} preDraw=${episode.firstPreDrawAtUptimeMs ?: "UNOBSERVED"} rootSize=${episode.preDrawRootSize ?: "UNOBSERVED"} targetSize=${episode.preDrawTargetSize ?: "UNOBSERVED"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2890:                if (withdrawal != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2891:                    append(hideRecord(withdrawal))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2892:                    append(inspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2910:        val needHolderRow = includeHolderDetail || actualWithdrawal(attempt, episode) == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2914:            appendLine(" R15_HOLDER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which clock=uptimeMs coherent=${op.coherent} op=${op.id} lock=${op.lockEnter ?: "UNOBSERVED"}/${op.lockReturn ?: "UNOBSERVED"} drawReturn=${op.drawReturn ?: "UNOBSERVED"} post=${op.postEnter ?: "UNOBSERVED"}/${op.postReturn ?: "UNOBSERVED"} record=${op.recordAt ?: "UNOBSERVED"} revoke=${op.revokeBegin ?: "UNOBSERVED"}/${op.revokeReturn ?: "UNOBSERVED"} screenPresentation=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3231:            "drawCount" to 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:63:    private val reserveBeforeMain: (KeyguardSystemGateRequest, KeyguardSystemState) -> (() -> Unit)? = { _, _ -> null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:97:    fun dispose() { disposed = true; clearPending() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:113:                runCatching { reserveBeforeMain(request, state) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:196:        val openingYieldHint: (() -> Boolean)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:200:        val claimOpeningYield: ((String, Boolean, Boolean, Int, Int, Int) -> KeyguardCardInspectionRequest?)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:460:            if (request.openingYieldHint?.invoke() != true) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:461:            return request.claimOpeningYield?.invoke(checkpoint, freshnessBoundaryEstablished, safe, visited,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:467:        val beforeRoot = if (request.openingYieldHint?.invoke() == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:589:                visibleIds(root, window.id, prefetch.takeIf { timing.activeRootAccepted }, authorityIsCurrent, timing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:594:                    if (request.openingYieldHint != null && request.claimOpeningYield != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:597:                        if (request.openingYieldHint?.invoke() == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:625:    private fun visibleIds(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:46:     * withdrawal in the SAME service/wake. The new request must reacquire
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:48:    fun reacquireAfterWithdrawal(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:99:    fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {}
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:247:    fun handoffOpening(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:260:    fun abandonSessionIfActive(owner: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:272:    fun abandonOpeningTransferIfActive(opening: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:275:        return abandonSessionIfActive(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:373:        return if (!transition.withdrawVisibleOverlay && !transition.invalidatesVisibleAuthority &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:426:    val withdrawVisibleOverlay: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:443:        val withdrawing = overlayAttached
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:444:        val next = if (withdrawing) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:458:            withdrawVisibleOverlay = withdrawing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:459:            invalidatesVisibleAuthority = withdrawing,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:7:internal class KeyguardOpeningInspectionHandoff {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:17:    data class PostClaimSnapshot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:56:        val postClaim: PostClaimSnapshot?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:244:        val successor = queue.handoffOpening(opening, requireNotNull(next))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:264:    fun observePostClaimOffer(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:271:    ): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:296:    fun successorStarted(request: KeyguardCardInspectionRequest, at: Long): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:309:                          reason: String = "FINISHED"): PostClaimSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:320:    private fun postClaimSnapshot(op: Opportunity): PostClaimSnapshot? = op.postClaim?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:321:        PostClaimSnapshot(it.context, op.opening.id, op.reservationId, op.authority, it.claimedId,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:12:        val sceneSerial: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:28:    fun sceneSerial(): Long = synchronized(lock) { scene }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:42:    fun requireRead(requestId: Long) = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:88:    fun offerRejection(requestId: Long, readSceneSerial: Long?, freshnessRevision: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:101:        retained == proof && proof.sceneSerial == scene && proof.requestId >= newestRead &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:108:        if (retained != proof || proof.sceneSerial != scene || proof.requestId < newestRead ||
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:17:internal class KeyguardOrbR18Presenter(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:95:        worker.prepareHiddenDirect(attachment, generation, width, height, densityDpi,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:133:    fun allocatedAt(attachment: Long, generation: Long): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:142:                       ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:150:        return worker.authorizeDirectFirst(current.target, profile, ticket)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:204:    fun reveal(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:205:               nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:215:        }, nativeApplied = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:216:            owner.get() === current && !current.target.revoked && nativeApplied()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:233:    fun sealMatching(attachment: Long, generation: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:246:    fun seal(expectedSerial: Long? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:264:    fun dispose() {
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:23:internal data class KeyguardR19FirstPaintTicket(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:25:    val sceneSerial: Long, val dataRevision: Long, val visualKey: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:44:    @Volatile var surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:56:    val firstDirectAuthorization = AtomicReference<KeyguardR19FirstPaintTicket?>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:57:    // Worker-owned: transparent host submission happens only on create/redraw.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:66:    val lockBeginNs: Long, val lockReturnNs: Long, val drawEndNs: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:117:        val ticket: KeyguardR19FirstPaintTicket,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:124:        val ticket: KeyguardR19FirstPaintTicket,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:129:        var lockBeginNs = 0L; var lockReturnNs = 0L; var drawEndNs = 0L; var postReturnNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:152:    private var pendingRedraw: KeyguardOrbSurfaceRedrawCompletion? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:164:        if (target != null && !target.revoked && target.surfaceReady) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:165:            draw(target, frameNanos)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:173:            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:202:    fun prepareHiddenDirect(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:228:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:239:            target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:251:    fun authorizeDirectFirst(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:252:                             ticket: KeyguardR19FirstPaintTicket): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:267:     * for its real SurfaceHolder callback and verifies size before drawing. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:275:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:291:                                  firstTicket: KeyguardR19FirstPaintTicket? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:293:        if (target.directOutput != null) observe(target, "R19_PAINT_ENTER", "worker")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:333:            drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:361:                    drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:387:                if (replacingFirst && !firstPosted) drawIfReady(target) else scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:396:    fun surfaceReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:397:        target.surfaceReady = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:399:            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:428:            target.metrics?.beginDirectPresentation(SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:437:    fun requestRedraw(target: KeyguardOrbSurfaceTarget, completion: KeyguardOrbSurfaceRedrawCompletion) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:443:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:444:            pendingRedraw = completion
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:446:            if (target.surfaceReady) scheduleFrame()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:470:                cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:494:        target.surfaceReady = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:497:        // A draw on the separately owned child must not block this callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:501:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:509:            cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:561:    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:562:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:565:        if (!firstPosted) draw(target, System.nanoTime())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:582:    private fun cancelRedraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:583:        val completion = pendingRedraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:584:        pendingRedraw = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:594:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:609:    private fun draw(target: KeyguardOrbSurfaceTarget, frameNanos: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:613:        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:685:        if (currentTarget !== target || target.revoked || !target.surfaceReady ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:714:        var lockEnd = 0L; var drawEnd = 0L; var postEnd = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:728:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:730:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:732:                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:734:                previousForFrame?.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:735:                painter.drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:737:            if (firstTiming != null) firstTiming.drawEndNs = System.nanoTime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:741:            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:763:            fail(target, "draw:${error.javaClass.simpleName}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:776:                (lockEnd - lockStart).coerceAtLeast(0L), (drawEnd - lockEnd).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:777:                (postEnd - drawEnd).coerceAtLeast(0L), (cpuLockEnd - cpuStart).coerceAtLeast(0L),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:820:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:830:                    item.drawEndNs, item.postReturnNs, failure)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:832:                    "R20_FIRST_FRAME", SystemClock.uptimeMillis(), "first", target.full, target.metrics, snapshot))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:849:        cancelRedraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:35:internal fun drawKeyguardOrbCircle(canvas: Canvas, paint: Paint, width: Int, height: Int) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:36:    canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:57: * used to record the first picture and to draw subsequent hardware frames. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:76:    fun draw(canvas: Canvas, time: KeyguardMaterialTime, blend: Float = 1f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:78:        drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:81:    fun draw(canvas: Canvas, time: KeyguardOrbSurfaceFrameTime, blend: Float = 1f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:83:        drawPrepared(canvas)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:96:    fun drawPrepared(canvas: Canvas) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:97:        drawKeyguardOrbCircle(canvas, paint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:104:            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt:105:            draw(canvas, time)
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
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:326:    @Test fun r21SubmittedPanelSurvivesBenignRecheckAndSealsBeforeLateAck() = calibratedFirstFrame(true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:327:    @Test fun r21PanelCancelsBeforeNativeCross() = calibratedFirstFrame(true, "PRE_CROSS")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:328:    @Test fun r21PanelRetiresInFlightRevealInNativeLaneOrder() = calibratedFirstFrame(true, "IN_FLIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:666:    @Test fun r20ExactAuthorizedPosterHitAvoidsAnotherBuild() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:717:    @Test fun r20FailedFirstLockOrPostNeverPublishesReady() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:765:    @Test fun r20HeldFirstWriteCannotReadyRetiredOwnerOrHideSuccessor() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:47:    @Test fun r21SubmittedDirectOrbSurvivesBenignIngressBeforeMainAck() = runService(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:48:    @Test fun r21ExclusionRetiresSubmittedOrbWithMainAckHeld() = runService(false, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:51:    @Test fun r22SupersededOpeningWalkYieldsToFreshInspection() = KeyguardR22FirstInspectionFixture().run("positive")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:52:    @Test fun r22YieldedWalkCannotGrantAfterExclusion() = KeyguardR22FirstInspectionFixture().run("negative")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:53:    @Test fun r22StableOpeningReadIsNotYielded() = KeyguardR22FirstInspectionFixture().run("stable")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:54:    @Test fun r22UnstagedOpeningObservation() = KeyguardR22FirstInspectionFixture().run("natural")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:54:    @Test fun r22PostClaimQueueEvidenceSurvivesLightPressureAndFreeze() = r22PostClaimQueueEvidence("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:55:    @Test fun r22PostClaimQueueEvidenceSurvivesFullPressureAndFreeze() = r22PostClaimQueueEvidence("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:59:    private fun r22PostClaimQueueEvidence(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:322:    @Test fun r21PhoneShapeProtectsDirectAndFinalWithdrawalCore() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:504:    @Test fun r20FirstFrameBreakdownSurvivesFreezeAndReplacement() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:226:                    override fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:284:            fun verifyExclusionPixels(visual: KeyguardR22VisualCalibration,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:293:                    shadeWindow, independentShadeWindow())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:337:                    independent = independentOpeningScene(service)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:353:                independent = independentOpeningScene(service)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:406:                        shadeWindow = independentShadeWindow()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:426:                    verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "negative")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:492:                visual.awaitServiceMatch("service-phase-A", identity.bounds, visual.a, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:495:                visual.awaitServiceMatch("service-phase-B", identity.bounds, visual.b, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:498:                visual.awaitServiceMatch("service-phase-A-return", identity.bounds, visual.a, underlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:504:                    shadeWindow = independentShadeWindow()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:515:                verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "withdrawal")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:570:    private fun independentOpeningScene(service: FluviKeyguardCardService): String {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:621:    private fun independentShadeWindow(): Int? = listOf(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:196:    fun awaitServiceMatch(label: String, bounds: Rect, reference: Bitmap, underlay: Bitmap): Bitmap {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:298:    @Test fun r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2313:        stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2747:    @Test fun stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22PostClaimEvidenceTest.kt:47:    @Test fun pendingAfterClaimIsReportedWithoutChangingActiveSuccessor() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:148:    @Test fun returnedMainIsConsumedBeforeYieldAndBPerformsFreshCompleteRead() {

# R22.2 source-derived ownership and framework callbacks
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:247:                it.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:267:            current.clearPassiveStandby()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:283:                onR18Failure = { attachment, generation, reason, releaseAfterRemoval ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:288:                    if (removed) releaseAfterRemoval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:304:            surfacePresenter?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:750:            lifecycle.onDetached()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:765:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:775:        root?.cancelInteraction("dispose", restorePosition = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:777:        materialController?.stop("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:779:        materialController?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:780:        surfacePresenter?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3992:        "slot:${it.slotId},use:${it.useGeneration},lease:${it.lease?.attachment ?: "NA"}/${it.lease?.generation ?: "NA"},state:${it.state},retired:${it.retired},receipt:${it.callbackReceived},fence:${it.fencePending}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4002:            else -> "result:${sample.resultAt ?: "UNOBSERVED"},status:${sample.resultStatus ?: "UNOBSERVED"},fence:${sample.fenceValid ?: "UNOBSERVED"},state:${sample.disposition}"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4176:                        "r22Passive" to (summary.passiveStandby?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4611:        systemSampler.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4613:        // disposed result cannot mutate this service's root or authority.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4623:        if (::overlay.isInitialized) overlay.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2637:            appendLine("omittedPassiveStandbyRecordIds=${compactRecordIds(omittedPassive, 128)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2920:            appendLine(" R16_LAYER attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "UNOBSERVED"} generation=$generation owner=$which host=${layer.hostId} child=${layer.childId} clock=uptimeMs created=${layer.createdAt ?: "UNOBSERVED"} retire=${layer.retireBegin ?: "UNOBSERVED"}/${layer.retireEnd ?: "UNOBSERVED"}/${layer.retireSucceeded} commitReceipt=${layer.commitReceipt ?: "UNOBSERVED"} commitMain=${layer.commitMain ?: "UNOBSERVED"} disposed=${layer.disposedAt ?: "UNOBSERVED"} lateOp=${late?.id ?: "UNOBSERVED"} latePost=${late?.postEnter ?: "UNOBSERVED"}/${late?.postReturn ?: "UNOBSERVED"} physical=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3147:     * caller has already released [legacyLock], and no event causes a second
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:28: * release authority and contains no scene, buffer, fence or child object. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:70:internal data class KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:207:    private var passiveSummary: KeyguardPassiveStandbySummary? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:214:    private var passiveClearGate: PassiveClearGate? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:228:            onFirstCommitted = ::onIsolatedOrbFirstCommitted,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:229:            onFailure = ::onIsolatedOrbFailure,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:242:            onDetachedBackendPrepared = { lease, observedAtUptimeMs ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:288:            if (!next) disarmPassiveStandby("motion-disabled")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:292:                if (lease != null && scene != null) reconcilePassiveStandby(attachedRoot, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:302:     * worker/fence ownership. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:335:            reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:401:        if (passiveClearGate?.configuration != configuration) passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:480:            disarmPassiveStandby("configuration")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:481:            if (!restrictiveTransition && attached && isolatedOrbRequested && passiveRoot.passiveBackingMayExist()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:485:                if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.retire("passive-ineligible")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:486:                gatePassiveReplacement(passiveRoot, configuration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:497:            isolatedOrbRenderer.retire("privacy-tightening")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:508:                isolatedOrbRenderer.retire("legacy-route")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:581:        reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:589:                    reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:597:                        runCatching { isolatedOrbRenderer.retire("privacy-transition-failure") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:644:            passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:648:            passiveSummary = if (passiveEvidenceOwner != null) KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:722:            reconcileIsolatedOrbTarget(root)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:727:    fun onDetached(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:735:        disarmPassiveStandby(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:736:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:771:            isolatedOrbRenderer.retire(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:786:        onDetached(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:826:        passiveStandby = passiveSummary?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:836:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:838:        stop("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:847:        artifacts.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:848:        gpuPreparer.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:852:            isolatedOrbRenderer.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1104:        reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1158:                    reconcileIsolatedOrbTarget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1275:                                observation: KeyguardCardInteractionLayout.PassiveStandbyObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1286:        passiveSummary = KeyguardPassiveStandbySummary(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1294:    private fun disarmPassiveStandby(reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1298:        val observed = (attachedRoot as? KeyguardCardInteractionLayout)?.clearPassiveStandby(capture)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1304:    private fun gatePassiveReplacement(root: KeyguardCardInteractionLayout, configuration: MaterialConfiguration) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1307:        passiveClearGate = gate
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1312:                        if (passiveClearGate === gate && attached && attachedRoot === root &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1315:                            root.confirmPassiveBackingCleared(gate.epoch)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1316:                            if (!root.passiveBackingMayExist()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1317:                                passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1318:                                reconcileIsolatedOrbTarget(root)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1329:    private fun reconcilePassiveStandby(root: View?, lease: KeyguardOrbBufferLease, scene: KeyguardMaterialScene) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1341:            disarmPassiveStandby(reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1348:            disarmPassiveStandby("BLENDING")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1354:                    latestOrbScene === scene && passiveClearGate == null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1355:                    reconcilePassiveStandby(currentRoot, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1363:        val status = targetRoot.configurePassiveStandby(orb, lease.attachment, lease.generation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1365:        if (status != "ELIGIBLE") disarmPassiveStandby(status)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1367:            rememberPassive(status, targetRoot.passiveStandbyObservation())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1387:    private fun reconcileIsolatedOrbTarget(rootOverride: View? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1393:        if (passiveClearGate != null) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1404:            disarmPassiveStandby("size-change")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1406:            if (container != null && container.passiveBackingMayExist() && configuration != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1410:                if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.retire("passive-size-change")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1411:                gatePassiveReplacement(container, configuration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1433:        if (attached) reconcilePassiveStandby(root, lease, scene)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1496:    private fun onIsolatedOrbFirstCommitted(token: KeyguardOrbFirstPublicationToken) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1503:        latestOrbScene?.let { reconcilePassiveStandby(attachedRoot, lease, it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1519:        reconcileIsolatedOrbTarget(attachedRoot)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1522:    private fun onIsolatedOrbFailure(lease: KeyguardOrbBufferLease, error: Throwable) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1524:        disarmPassiveStandby("producer-failure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1525:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1538:        isolatedOrbRenderer.retire("producer-failure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1573:        disarmPassiveStandby("pressure-view")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1574:        passiveClearGate = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1595:        // Revocation/clear stay asynchronous with respect to buffer release;
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1596:        // Main never waits for Worker, GPU, a commit, or a fence here.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1597:        isolatedOrbRenderer.retire("retired-use-pressure")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1669:    val passiveStandby: KeyguardPassiveStandbySummary? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:52: * identity, never by the logging hash; no buffer or fence is retained here. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:68:/** Bounded numeric evidence for one first-use lifetime. No buffer, fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:104:                        fence: SyncFence?, deliver: () -> Unit) = deliver()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:113: * This is not a presentation callback and must never be used to release a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:114: * producer buffer: the worker still owns that through its fence path.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:124: * fence remain renderer-thread-owned. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:153:    val resultAt: Long?, val resultStatus: Int?, val fenceValid: Boolean?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:279:    val fencePending: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:285: * This immutable copy has no buffer, fence or visibility authority. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:398:        grant: Any?, eligible: Boolean, slotCount: Int, oldUnreleased: Int,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:407:            slotCount == 3 && oldUnreleased == 3 -> KeyguardOrbPressureReason.ALL_OLD_UNRELEASED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:448: * permits only child unlink; it never releases or reuses a producer slot. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:492:/** Presence is distinct from the nullable platform fence carried by a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:493: * release receipt. A receipt is consumed exactly once by its slot/use key. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:560:    private val onDetachedBackendPrepared: (KeyguardOrbBufferLease, Long) -> Unit = { _, _ -> },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:596:    fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:600:        api34?.retire(reason, onLayerHideCommitted, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:603:    fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:606:        api34?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:695:        private var disposed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:715:                mainHandler.post { if (!disposed) onCapacityRestored(ticket, observedAt) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:729:            if (disposed || desired?.lease != ticket.lease || desired?.scene?.visualKey != ticket.sceneKey ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:741:            if (disposed || ticket.rendererId != rendererId || desired?.lease != ticket.lease ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:755:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:762:                if (layerLease != null && layerLease != spec.lease) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:768:            if (old != null && old.scene.full && !spec.scene.full) hideLayer()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:780:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:791:                retire("attachment-replaced", preserveOffer = preserve)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:805:        fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:809:            // attachment/layer. hideLayer() revokes that lease immediately,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:819:            hideLayer(onLayerHideCommitted, reason, onRetirementEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:821:            worker.retire(retiredLease, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:824:        fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:825:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:826:            retire("dispose")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:827:            disposed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:828:            worker.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:834:                enabled = !disposed,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:866:            !disposed && firstPublishedToken === token && layer === token.child &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:880:                        retire("root-detached")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:943:                    child.release()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:960:                    runCatching { child.release() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1033:                if (!disposed && attachment?.root === value.root &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1045:        private fun hideLayer(onCommitted: ((Long) -> Unit)? = null, reason: String = "reconfigure",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1062:                    // SurfaceControl's null-buffer form releases the last
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1063:                    // displayed buffer and invokes its release callback.  A
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1065:                    // compositor-owned slot stranded. Commit this release
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1168:                // late use callbacks must not dereference a released child.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1171:                runCatching { child.release() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1194:                        if (!disposed && attachment == null && desired?.lease == frame.lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1195:                            onDetachedBackendPrepared(frame.lease, SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1235:            if (disposed || firstOfferToken !== token) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1269:            if (disposed || firstOfferToken !== offer || active == null || child == null || !child.isValid ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1306:                val release = Consumer<SyncFence> { fence -> worker.release(lease, slotId, useGeneration, fence, childIdentity) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1311:                transaction.setBuffer(child, frame.buffer, frame.fence, release)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1340:                    // local. Keep the exact use until a real receipt/fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1352:            // queue retirement. A fast real release is replayed by Worker.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1375:                if (!disposed && desired?.lease == lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1409:         * hand-off resolves; otherwise a late release/drop callback can target
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1427:             * only means its RenderNode was submitted; its fence still owns
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1430:             * returned to FREE after its release fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1447:            var fencePending: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1460:         * while a release fence is outstanding. At most three fence records
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1462:        private val fenceThread = HandlerThread("fluvi-keyguard-orb-fence").apply { start() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1463:        private val fenceHandler = Handler(fenceThread.looper)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1528:        private var disposed = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1631:                if (disposed) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1729:                if (disposed || desired?.lease != lease) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1808:                // receipt/fence completion can trigger this drain path.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1814:        fun retire(retiredLease: KeyguardOrbBufferLease?, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1843:                // targets; retain those until their callback/fence returns.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1846:                // attachment arrives before an old compositor release.  A
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1850:                // behind a stale release even though the three-slot bound has
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1865:        fun dispose() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1870:                disposed = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1872:                resetStarvation("disposed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1913:        fun release(lease: KeyguardOrbBufferLease, slotId: Long, useGeneration: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1914:                    releaseFence: SyncFence?, childIdentity: Int, postAlways: Boolean = true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1917:                recoveryHook.dispatchRelease(lease, slotId, useGeneration, releaseFence) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1918:                    releaseActual(slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1922:            releaseActual(slotId, useGeneration, releaseFence, childIdentity, postAlways, receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1925:        private fun releaseActual(slotId: Long, useGeneration: Long, releaseFence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1930:                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1935:                    releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1941:                // successful direct return in the release callback.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1942:                consumeRelease(slotId, useGeneration, releaseFence, childIdentity, receiptAt = receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1949:            releaseFence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1957:                    consumeRelease(slotId, useGeneration, releaseFence, childIdentity, publicationPath, replayed, receiptAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1965:                // SurfaceFlinger may release a transaction before the Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1967:                // Retain this exact fence rather than treating READY as FREE.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1969:                val recorded = earlyReleaseReceipts.record(key, releaseFence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1973:                    else if (slot.publicationPath == "first/ready") slot.publicationPath = "first/release-before-ack"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1975:                    slot.fencePending = releaseFence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1977:                    observeOwnership("release-received", slot = slot, log = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1978:                    if (slot.retired) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1983:                    releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1985:                observeOwnership("early-release-received", slot = slot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1990:                releaseFence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1996:            slot.fencePending = releaseFence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1998:            if (!replayed) observeOwnership("release-received", slot = slot, log = slot.retired)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1999:            if (slot.retired && !replayed) notifyRetiredUse(slot, "release-received", receiptAt ?: SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2001:            awaitFence(slotId, useGeneration, SlotState.WAIT_RELEASE_FENCE, releaseFence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2010:                ) discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2011:                else frame.fence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2048:            if (disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2069:                if (disposed || !ticket.claim.isClaimed()) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2094:            val eligible = running && !disposed && attachedLease == spec.lease &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2096:            var oldUnreleased = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2106:                    if (slot.state == SlotState.PUBLISHED && !slot.callbackReceived) oldUnreleased++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2126:            val reason = pressurePolicy.observe(grant, eligible, slots.size, oldUnreleased, oldOwned, free,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2143:                        slot.callbackReceived, slot.fencePending, slot.earlyReceiptRetained)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2152:            if (callbackPosted || disposed) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2226:            // fence drains. Do not make an otherwise FREE slot unavailable
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2275:            slot.fencePending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2330:                // release fence, so replacing its root here is safe and makes
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2371:                            fenceValid = result.fence?.isValid == true, disposition = "result"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2383:                    if (disposed || desired?.lease != spec.lease ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2388:                        discardRenderResult(slot, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2412:                    // completion fence without putting readback or waits on
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2424:                            frameObserver.onProduced(producerFrame, slot.buffer, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2430:                        fence = result.fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2445:                        discardRenderResult(slot, result.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2487:         * makes every submitted display list immutable until its fence ends.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2512:                discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2529:                        frame.fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2530:                        Consumer { releaseFence -> release(submittedLease, submittedSlot, submittedUse,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2531:                            releaseFence, childIdentity, postAlways = false) },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2537:                // SurfaceControl owns the submitted acquire fence. Slot
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2538:                // reuse still waits for its later release callback/fence,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2551:                discardRenderResult(slot, frame.fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2575:        /** A stale/failed producer completion still owns its render fence.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2577:        private fun discardRenderResult(slot: Slot, fence: SyncFence?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2583:            awaitFence(slot.id, slot.useGeneration, SlotState.WAIT_RENDER_FENCE, fence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2590:            fence: SyncFence?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2593:                ?.fencePending = fence?.isValid == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2594:            if (fence?.isValid != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2595:                fence?.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2601:                    val signaled = runCatching { fence.await(Duration.ofMillis(16)) }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2603:                        fence.close()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2608:                        // repeating work is this fixed bounded fence record.
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2609:                        fenceHandler.postDelayed(this, 16L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2613:            fenceHandler.post(poll)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2626:            slot.fencePending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2628:                observeOwnership("release-fence-complete", slot = slot, log = slot.retired)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2629:                if (slot.retired) notifyRetiredUse(slot, "release-fence-complete")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2631:            if (disposed) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2641:            if (slots.any { it.state == SlotState.FREE }) resetStarvation("capacity-released")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2646:            if (!disposed && (running ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2747:                        fencePending = it.fencePending, earlyReceiptRetained = it.earlyReceiptRetained,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2765:                        append(" callbackReceived=${s.callbackReceived} fencePending=${s.fencePending}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2788:            // This slot remains fenced until its output is released, so do
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2792:        /** The service can dispose on Main while a RenderRequest or
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2793:         * compositor fence still owns a buffer. Leave this short-lived worker
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2794:         * alive only until the platform callback releases that resource; do
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2798:            if (disposed && slots.isEmpty()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2799:                fenceThread.quitSafely()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2850:         * in a cross-thread release callback. */
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2852:        /** Every async producer/release callback is additionally bound to a
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:2856:        val fence: SyncFence?,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:56:        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:96:        var calibration: KeyguardR22VisualCalibration? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:142:                calibration = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:145:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:284:            fun verifyExclusionPixels(visual: KeyguardR22VisualCalibration,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:296:                    KeyguardR22VisualCalibration.compare(beforeDisconnect, independentUnderlay).nearlyEqual())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:324:                automation.takeScreenshot()?.let { image ->
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:491:                waitPosted(KeyguardR22VisualCalibration.timeA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:493:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeB
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:494:                waitPosted(KeyguardR22VisualCalibration.timeB)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:496:                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:497:                waitPosted(KeyguardR22VisualCalibration.timeA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:518:            val screenshot = automation.takeScreenshot()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:633:        val header = "stage=$stage requestedFlags=${UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES} " +
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:28:internal class KeyguardR22VisualCalibration(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt:73:    private fun screenshot(): Bitmap = checkNotNull(automation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:50:    @Test fun r22CalibrationPreservesNonSuppressingAutomation() = KeyguardR22FirstInspectionFixture().run("automation")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:68:        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:313:        val image = checkNotNull(automation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:28:    @Test fun r22PassiveStandbySummarySurvivesLightExport() = passiveStandbyExport("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:29:    @Test fun r22PassiveStandbySummarySurvivesFullExport() = passiveStandbyExport("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:31:    private fun passiveStandbyExport(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:466:                val screen = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2228:                val fullReference = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2313:        stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2424:    @Test fun isolatedOpaqueOrbHasNeutralParentAtRetire() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2445:                val fullScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2480:                    val afterScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2517:    @Test fun isolatedStandbyPreservesAuthorizedComposition() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2671:                val terminalScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2747:    @Test fun stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:2817:                            val screen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5090:        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5107:        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5220:        val screen = instrumentation.uiAutomation.takeScreenshot()

```
