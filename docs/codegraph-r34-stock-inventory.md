# R34 exact-source stock inventory

Application source: `b63a829dd8f926b8298be2165ce90252dce1120d`

The SCIP graph covers Dart only. Kotlin lines below are direct source navigation, not generated edges or proof of runtime behavior. Native submission and transaction receipts are not physical pixels.

```text
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:451:    @Test fun r34CoreSurvivesLightPressureAndFreeze() = r34CoreEvidence("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:452:    @Test fun r34CoreSurvivesFullPressureAndFreeze() = r34CoreEvidence("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:454:    private fun r34CoreEvidence(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:470:                        "r34AssetGeneration" to 80 + wake, "r34PrepareStart" to base - 20, "r34Ready" to base - 10))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:474:                            "r34Request" to request, "r34Next" to next, "r34Reservation" to reservation,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:475:                            "r34Host" to 10 + wake, "r34Output" to 20 + wake, "r34Scene" to 10,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:476:                            "r34Inventory" to base + 1, "r34Start" to base, "r34End" to at,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:477:                            "r34Outcome" to outcome, "r34ReaderHigh" to 1))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:491:                val row = report.lineSequence().single { it.startsWith(" R34_CORE ") && it.contains("attempt=$wake ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:500:                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r34Request" to 4001, "r34Reservation" to 704))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:505:                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r34Request" to 4001, "r34Reservation" to 704))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:51:    @Test fun r34RealIngressesReplaceObsoleteOpeningOnOneReader() = KeyguardR22FirstInspectionFixture().run("r34_latest")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:94:    @Test fun r34RetainedWindowPreparesConfiguredPosterBeforeWake() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:114:                target.prepareRetainedView(KeyguardCardSettings(requested = true, showFinancialDetails = true,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:133:    @Test fun r34UiHiddenKeepsConfiguredPosterForAuthorizedWindow() = r34WindowPoster("SHOW")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:134:    @Test fun r34PressureInvalidatesLeasedPosterBeforeSubmit() = r34WindowPoster("PRESSURE")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:135:    @Test fun r34RestrictionBeforeSubmitCannotRevealPoster() = r34WindowPoster("RESTRICT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:136:    @Test fun r34RestrictionAfterGrantBeforeNativeApplyCannotRevealPoster() = r34WindowPoster("RESTRICT_AFTER_CROSS")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:140:    private fun r34WindowPoster(scenario: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:236:                checkNotNull(window).prepareRetainedView(settings, selected)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:48:        require(scenario in setOf("positive", "negative", "stable", "natural", "automation", "r31_system", "r31_ambiguous", "r31_negative", "r32_overlap", "r34_latest"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:49:        val r34 = scenario == "r34_latest"
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:96:        val r34RealOffers = CountDownLatch(2)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:97:        val r34ObservedOffer = AtomicLong(0L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:378:                            request.r34SceneSerial != null && request.r32FrameworkIngressId == request.r14Ingress?.id &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:380:                            meta.displayId == Display.DEFAULT_DISPLAY && request.id > r34ObservedOffer.get()) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:381:                            r34ObservedOffer.set(request.id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:382:                            records.add("R34_REAL_PENDING id=${request.id} scene=${request.r34SceneSerial} previous=${previous?.id} at=${SystemClock.uptimeMillis()}")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:383:                            r34RealOffers.countDown()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:588:                assertTrue("NOT REACHED: fewer than two real SystemUI offers", r34RealOffers.await(10, TimeUnit.SECONDS))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:592:                assertEquals("NOT REACHED: latest offer changed before selection", r34ObservedOffer.get(), latest.id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:593:                assertNotNull("NOT REACHED: request has no actual scene identity", latest.r34SceneSerial)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:595:                records.add("R34_EXPECTED_LATEST A=${original.id} latest=${latest.id} scene=${latest.r34SceneSerial}")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:146:                target.prepareRetainedView(settings, profile)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:223:                target.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:445:                window.prepareRetainedView(settings, profile)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:977:                window!!.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:1046:                window!!.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:1090:                window!!.prepareRetainedView(settings, profileA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:1156:                window.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:1728:                window.prepareRetainedView(settings, profile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:3792:                window.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:4269:                window.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:4476:                window.prepareRetainedView(settings, calibratedOrbProfile())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:4628:        fun retirementSnapshot(): List<RetirementBoundary> = retirements.toList()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:4936:                window.prepareRetainedView(settings, initialProfile)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:5302:                window.prepareRetainedView(settings, profile())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:114:            overlay.prepareRetainedView(lastSettings ?: FluviKeyguardCardSettings.read(applicationContext), lastMaterialProfile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:405:        r32MainSnapshot = KeyguardR34SnapshotIdentity.publish(r32MainSnapshot, proposed) { old, next ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1013:                    "r34AssetGeneration" to (observation.r34AssetGeneration ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1014:                    "r34PrepareStart" to (observation.r34PrepareStartUptimeMs ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1015:                    "r34Ready" to (observation.r34ReadyUptimeMs ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1645:        overlay.prepareRetainedView(settings, profile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1778:    override fun onTrimMemory(level: Int) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1779:        super.onTrimMemory(level)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2294:            r34SceneSerial = externalScene?.takeIf { frameworkEvent && meta != null && ingress != null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2500:            recordR34Read(request, result.partial.r34ReadOwner, "TRANSFER", started, finished,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2501:                result.partial.r34InventoryAt, result.sceneAtRead, result.successor.id, "SAFE_CHILD")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2512:        recordR34Read(request, inspection.r34ReadOwner, "READ_END", started, finished,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2513:            inspection.r34InventoryAt, inspection.r19ReadSceneSerial, outcome = when {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2514:                inspection.r34PausedForOffer -> "PAUSED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2785:    private fun r34EmptyDirectLocked(request: KeyguardCardInspectionRequest): R32DirectSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2809:    private fun r34SameEmptyOwnerLocked(request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2811:        val now = r34EmptyDirectLocked(request) ?: return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2816:    private fun r34ActualLatestLocked(request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2821:            inspectionAuthority.matches(next) && next.r34SceneSerial == scene &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2831:    private fun r34SupersedeCompletedLocked(read: CompletedInspection): R34Superseded? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2833:        val owner = result.r34ReadOwner ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2834:        if (!r34SameEmptyOwnerLocked(read.request, owner)) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2835:        val partialPause = result.r34PausedForOffer && result.abortedStale
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2845:        return when (KeyguardR34LatestScenePolicy.decide(result.r19ReadSceneSerial, current,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2847:            pendingScene = pending?.r34SceneSerial,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2848:            genuineCompatiblePending = r34ActualLatestLocked(read.request, pending, current))) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2849:            KeyguardR34LatestScenePolicy.Action.TRANSFER -> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2854:            KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER -> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2855:                if (!inspectionQueue.parkObsoleteAfterRead(read.request)) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2859:            KeyguardR34LatestScenePolicy.Action.KEEP_READING -> null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2873:                mapOf("r34Request" to request.id, "r34Next" to (successor ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2874:                    "r34Reservation" to exactOwner.reservation.id, "r34Host" to (exactOwner.route.hostGeneration ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2875:                    "r34Output" to (exactOwner.route.outputGeneration ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2876:                    "r34Scene" to (scene ?: "UNOBSERVED"), "r34Inventory" to (inventory ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2877:                    "r34Start" to started, "r34End" to finished, "r34Outcome" to (outcome ?: "UNOBSERVED"),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2878:                    "r34ReaderHigh" to maximumConcurrentInspections.get())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2883:        recordR34Read(read.request, read.result.r34ReadOwner, if (result.waiting) "WAIT_OFFER" else "TRANSFER",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2884:            read.startedAt, read.finishedAt, read.result.r34InventoryAt, read.result.r19ReadSceneSerial,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2885:            result.successor?.id, if (read.result.r34PausedForOffer) "PARTIAL" else "STALE_POSITIVE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2886:        traceKeyguard("INSPECTION_REJECTED", if (result.waiting) "r34WaitForOffer" else "r34LatestOffered",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2888:            fields = mapOf("rejectionReason" to if (result.waiting) "r34WaitForOffer" else "r34LatestOffered",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3109:            val superseded = synchronized(queueLock) { r34SupersedeCompletedLocked(read) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3117:            if (read.result.r34PausedForOffer) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3121:                    r34PausedForOffer = false))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3151:                val r32 = if (successor == null && r34EmptyDirectLocked(active) == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3201:                    val latest = synchronized(queueLock) { r34SupersedeCompletedLocked(read) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3446:        val r34ReadOwner: R32DirectSnapshot? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3447:        val r34InventoryAt: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3448:        val r34PausedForOffer: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3477:        val r34ReadOwner: R32DirectSnapshot? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3478:        val r34InventoryAt: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3479:        val r34PausedForOffer: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3583:                r34ReadOwner = read.r34ReadOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3584:                r34InventoryAt = read.r34InventoryAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3585:                r34PausedForOffer = read.r34PausedForOffer,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3611:            r34ReadOwner = read.r34ReadOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3612:            r34InventoryAt = read.r34InventoryAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3665:        val r34Eligible = synchronized(queueLock) { r34EmptyDirectLocked(request) != null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3666:        var r34ReadOwner: R32DirectSnapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3667:        var r34ReadScene: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3668:        var r34InventoryAt: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3669:        var r34PausedForOffer = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3670:        val yieldHandle = if (!r34Eligible && openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3673:        val followHandle = if (!r34Eligible && openingHandoff.claimedRequestId == request.id) synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3687:                    r34Eligible -> { { r34ReadOwner != null && r34ReadScene?.let { firstAuthorizedOrb.sceneHint() > it } == true } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3693:                r34ExactSystemRoot = r34Eligible,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3694:                beforeWindowsAcquisition = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3698:                        if (r34Eligible) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3699:                            r34ReadOwner = r34EmptyDirectLocked(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3700:                            r34ReadScene = scene
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3701:                            if (r34ReadOwner != null) r34InventoryAt = SystemClock.uptimeMillis()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3709:                openingChildBefore = if (((yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3723:                openingChildReturned = if ((yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3730:                    (yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3737:                claimOpeningYield = if (r34Eligible || yieldHandle != null || followHandle != null) { { checkpoint, yieldReason, physicalBoundary, safeInventory, visited, roots, children ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3740:                        if (r34Eligible) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3741:                            val owner = r34ReadOwner ?: return@synchronized null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3744:                            val action = KeyguardR34LatestScenePolicy.decide(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3745:                                r34ReadScene, scene, r34SameEmptyOwnerLocked(request, owner),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3747:                                restrictiveEvidence = false, pendingScene = pending?.r34SceneSerial,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3748:                                genuineCompatiblePending = r34ActualLatestLocked(request, pending, scene))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3749:                            if (action == KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3751:                                r34PausedForOffer = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3754:                            if (action != KeyguardR34LatestScenePolicy.Action.TRANSFER) return@synchronized null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3755:                            val successor = inspectionQueue.handoffOpening(request, requireNotNull(pending))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3819:                pauseOpeningAfterYieldAttempt = if (r34Eligible) { { r34PausedForOffer } } else null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3847:            r34ReadOwner = r34ReadOwner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3848:            r34InventoryAt = r34InventoryAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3849:            r34PausedForOffer = r34PausedForOffer && result.abortedStale,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4835:                        }, stillAuthorized = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4839:                                currentProof && r18Coordinator.isCrossedCurrent(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:47:    val r34SceneSerial: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:68:            r34SceneSerial = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:258:    fun parkObsoleteAfterRead(request: KeyguardCardInspectionRequest): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:283:    fun handoffOpening(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:804:        val r34Opening: LinkedHashMap<String, String> = linkedMapOf(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1037:            "r18AlignUncertaintyNs", "r19Intent", "r19Poster", "r34AssetGeneration", "r34PrepareStart", "r34Ready").forEach { retainField(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1096:    private fun reduceR34(attempt: TimingAttempt, event: TimingEvent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1098:        val reservation = fields["r34Reservation"] ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1099:        val values = attempt.r34Opening
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1102:        listOf("r34Host", "r34Output", "r34Request", "r34Scene", "r34Inventory", "r34Start", "r34End")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1104:        fields["r34ReaderHigh"]?.let { values["readerHigh"] = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1109:                values["lastRequest"] = fields["r34Request"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1110:                values["lastNext"] = fields["r34Next"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1111:                values["lastOutcome"] = fields["r34Outcome"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1115:                val outcome = fields["r34Outcome"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1116:                values["lastRead"] = fields["r34Request"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1119:                    values.putIfAbsent("firstFull", fields["r34Request"] ?: "UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2172:                "R34_OPENING" -> reduceR34(attempt, event)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2398:        r34Opening = LinkedHashMap(attempt.r34Opening),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2592:        attemptsForCausalEvidence.filter { it.r34Opening.isNotEmpty() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2594:            .forEach { attempt -> select("a${attempt.id}:r34Core", r34CoreRecord(attempt), attempt.id) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2901:    private fun r34CoreRecord(attempt: TimingAttempt): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2902:        val values = attempt.r34Opening
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2909:        val ready = direct?.values?.get("r34Ready")?.toLongOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2913:        append(" R34_CORE v=1 attempt=${attempt.id} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2914:        append(" reservation=${v("reservation")} host=${v("r34Host")} output=${v("r34Output")} asset=${d("r34AssetGeneration")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2915:        append(" route=${d("r19Poster")} prepare=${d("r34PrepareStart")}/${d("r34Ready")} readyBeforeWake=${ready?.let { it <= attempt.startedUptimeMs } ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2916:        append(" firstRead=${v("r34Request")}@${v("r34Start")}/${v("r34Inventory")}/${v("r34End")} scene=${v("r34Scene")}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:428:    fun prepareRetainedView(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:588:                  stillAuthorized: () -> Boolean = { true }, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:591:        surfacePresenter?.revealR18(preparation.attachment, preparation.outputGeneration, boundary, nativeApplied, stillAuthorized, done) ?: done(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:352:        val successor = queue.handoffOpening(opening, requireNotNull(next))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:527:        val promoted = queue.handoffOpening(handle.successor, requireNotNull(pending))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:272:    fun isCrossedCurrent(reveal: Reveal): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:369:    fun retired(token: Reservation): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicy.kt:4:internal object KeyguardR34LatestScenePolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR34SnapshotIdentity.kt:5:internal object KeyguardR34SnapshotIdentity {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:203:        val r34ExactSystemRoot: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:204:        val beforeWindowsAcquisition: (() -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:463:        request.beforeWindowsAcquisition?.invoke()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:684:                            val exactSystemRoot = if (request.followOnOpening || request.r34ExactSystemRoot ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:982:        promoteLiveIfReady()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1296:            promoteLiveIfReady()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1321:                    promoteLiveIfReady()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardCardMaterialController.kt:1720:    private fun promoteLiveIfReady() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:607:    fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:816:        fun retire(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbBufferRenderer.kt:1832:        fun retire(retiredLease: KeyguardOrbBufferLease?, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:101:    private class PosterUse(val lease: KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:168:               posterLease: KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:170:               stillAuthorized: () -> Boolean = { true }, completed: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:193:                        transaction.setBuffer(poster, buffer, null, Consumer { fence -> releasePoster(use, fence) })
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:200:                    if (output.isSealed() || !runCatching { stillAuthorized() }.getOrDefault(false)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:228:    fun promoteLive(output: KeyguardOrbDirectOutput, stillCurrent: () -> Boolean, completed: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:242:            } catch (_: Throwable) { fail(output, "r34LivePromotionFailed") }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:248:    private fun releasePoster(use: PosterUse, fence: SyncFence?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectOutput.kt:274:    fun retire(output: KeyguardOrbDirectOutput, completed: (Boolean) -> Unit = {}) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:102:    private fun retireActive(entry: Active) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbDirectProgramWarmup.kt:117:    fun retire(target: KeyguardOrbSurfaceTarget) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbOwnedOutput.kt:63:    fun retire(metrics: KeyguardOrbSurfaceMetrics?): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:29:        KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>? = { _, _, _ -> null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:30:    private val privatePosterIsCurrent: (KeyguardR34PrivatePoster.Image) -> Boolean = { false },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:41:        val posterLease: AtomicReference<KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>?> = AtomicReference(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:87:            lane.promoteLive(output, stillCurrent = { owner.get() === captured && !target.revoked }) { success ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:91:                } else if (owner.get() === captured && !target.revoked) onWorkerFailure(target, "r34LivePromotion")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:179:    fun authorizeFirst(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:195:            current.target.r34StartPhase = lease.value.phase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:198:                r34AssetGeneration = lease.value.ticket.generation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:199:                r34PrepareStartUptimeMs = lease.value.prepareStartedAtUptimeMs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:200:                r34ReadyUptimeMs = lease.value.readyAtUptimeMs)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:282:               nativeApplied: () -> Boolean, stillAuthorized: () -> Boolean = { true }, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:296:                (poster == null || privatePosterIsCurrent(poster.value)) && crossGrantBoundary()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:299:        }, stillAuthorized = {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:301:                (poster == null || privatePosterIsCurrent(poster.value)) && stillAuthorized()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:312:                            onWorkerFailure(current.target, "r34LiveContinuation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:317:                                privatePosterIsCurrent(poster.value)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbR18Presenter.kt:320:                            onWorkerFailure(current.target, "r34CanvasFallback")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:49:    @Volatile private var privatePoster: KeyguardR34PrivatePoster? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:69:        if (!allowed || profile == null) { privatePoster?.clear(); return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:70:        val owner = privatePoster ?: KeyguardR34PrivatePoster(context.applicationContext).also { privatePoster = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:75:    fun clearPrivatePoster() { checkMain(); privatePoster?.clear() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:84:                privatePoster?.acquire(profile, target.width, target.height, target.densityDpi, ticket.dataRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:85:            }, privatePosterIsCurrent = { image -> privatePoster?.isCurrent(image) == true }).also { direct = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:108:        direct?.authorizeFirst(attachment, generation, profile, ticket) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:124:                  stillAuthorized: () -> Boolean = { true }, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:127:        presenter.reveal(attachment, generation, crossGrantBoundary, nativeApplied, stillAuthorized, done)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:316:        privatePoster?.dispose()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:317:        privatePoster = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:58:    @Volatile var r34StartPhase: KeyguardMaterialTime? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:94:    val r34AssetGeneration: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:95:    val r34PrepareStartUptimeMs: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:96:    val r34ReadyUptimeMs: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:328:        lease: KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:350:                    if (!target.revoked && currentTarget === target) fail(target, "r34CacheInvalidated")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:398:                if (!target.revoked && currentTarget === target) fail(target, "r34Blit:${error.javaClass.simpleName}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:440:        val phase = if (firstTicket != null && target.r34StartPhase != null) checkNotNull(target.r34StartPhase)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorker.kt:459:            val cached = if (firstTicket != null && target.r34StartPhase != null) null else posters[key]
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCache.kt:7:internal class KeyguardR34PrivateAssetCache<K : Any, V : Any>(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCache.kt:87:    private fun retire(close: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivatePoster.kt:23:internal class KeyguardR34PrivatePoster(private val context: Context) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivatePoster.kt:32:    data class Image(val identity: Identity, val ticket: KeyguardR34PrivateAssetCache.Ticket<Identity>,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivatePoster.kt:36:        val ticket: KeyguardR34PrivateAssetCache.Ticket<Identity>,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivatePoster.kt:43:    private val cache = KeyguardR34PrivateAssetCache<Identity, Image> { image ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivatePoster.kt:95:                focusGeneration: Long): KeyguardR34PrivateAssetCache.Lease<Image>? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt:117:    fun retireWhenSettled(onSettled: () -> Unit) {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:119:        assertTrue(queue.parkObsoleteAfterRead(active))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:122:        assertFalse(queue.parkObsoleteAfterRead(active))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:406:        assertNull(queue.handoffOpening(request(9, "wrong"), b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:407:        assertNull(queue.handoffOpening(a, request(3, "wrong")))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:410:        assertEquals(b, queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:413:        assertNull(queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:423:        assertNull(queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:424:        assertEquals(c, queue.handoffOpening(a, c))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:440:        assertNull(queue.handoffOpening(b, c))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:451:        assertEquals(b, queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:464:        assertEquals(b, queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:479:        assertEquals(b, queue.handoffOpening(a, b))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:6:class KeyguardR34LatestScenePolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:10:        KeyguardR34LatestScenePolicy.decide(scene, current, owner, safe, restrictive, pending, genuine)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:13:        assertEquals(KeyguardR34LatestScenePolicy.Action.TRANSFER, decide())
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:14:        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(pending = null, genuine = false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:15:        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(pending = 10))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:16:        assertEquals(KeyguardR34LatestScenePolicy.Action.KEEP_READING, decide(pending = 12))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:17:        assertEquals(KeyguardR34LatestScenePolicy.Action.KEEP_READING, decide(genuine = false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:21:        val keep = KeyguardR34LatestScenePolicy.Action.KEEP_READING
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:30:        assertEquals(KeyguardR34LatestScenePolicy.Action.TRANSFER, decide(scene = 10, current = 12, pending = 12))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34LatestScenePolicyTest.kt:31:        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(scene = 10, current = 12, pending = 11))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34SnapshotIdentityTest.kt:6:class KeyguardR34SnapshotIdentityTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR34SnapshotIdentityTest.kt:8:    private fun publish(old: Snapshot?, next: Snapshot?) = KeyguardR34SnapshotIdentity.publish(old, next) { a, b ->
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbLayerRetirementTest.kt:8:    @Test fun retiredOwnerRejectsNewBorrowsUntilTheEnteredOperationActuallyDrains() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbWarmupOwnershipTest.kt:33:    @Test fun retirementClosesTheStoreAndReportsOnlyAfterItsRealReadSettles() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCacheTest.kt:6:class KeyguardR34PrivateAssetCacheTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCacheTest.kt:9:        val cache = KeyguardR34PrivateAssetCache<String, String> { released += it }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCacheTest.kt:28:        val cache = KeyguardR34PrivateAssetCache<Int, String> { released += it }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCacheTest.kt:41:        val cache = KeyguardR34PrivateAssetCache<Int, String> { released += it }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR34PrivateAssetCacheTest.kt:55:        val cache = KeyguardR34PrivateAssetCache<String, String> { released += it }

```
