# R42 exact-source authorization inventory

Application source: `1584ccb020a8500efd5f9c67eac8ebd4830b1271`

The SCIP graph covers Dart only. Kotlin lines below are direct source navigation, not generated edges or proof of runtime behavior. Native submission and transaction receipts are not physical pixels.

```text
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:40:class KeyguardFirstAuthorizedOrbInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:824:                producer.revealR18(21, 34, crossGrantBoundary = { !r21 || coordinator.crossSubmitBoundary(permit) },
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:44:    @Test fun r42PreStartSelectsActualLatestRequest() = exercise(true, preStart = true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:45:    @Test fun r42StalePositiveExitsAfterOrderedRestrictions() = exercise(true, duringRead = true, platformWarm = true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:46:    @Test fun r42StalePositiveAfterRealReadExitsBeforePositivePath() = exercise(true, afterRead = true, platformWarm = true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:145:            val emptyDirect=actual.javaClass.getDeclaredMethod("r34EmptyDirectLocked",KeyguardCardInspectionRequest::class.java).also { it.isAccessible=true }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:251:                        val proof=(gateField.get(actual) as KeyguardFirstAuthorizedOrb).current()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:32:    @Test fun r42LateCriticalWakeSurvivesRawLightPressure() = r42LateCriticalWakeSurvivesRawPressure("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:33:    @Test fun r42LateCriticalWakeSurvivesRawFullPressure() = r42LateCriticalWakeSurvivesRawPressure("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:34:    @Test fun r42LateWinnerOfferAndReadSurviveRawPressure() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:39:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, first, 10_000L + index, atNs = 1_000_000L + index)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:41:        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 943, 2000, 2_000_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:43:        KeyguardCardDiagnostics.r41Bind(owner, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:44:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, 201, atNs = 2_000_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:45:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WORKER, owner, 201, atNs = 2_000_002L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:46:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 201, atNs = 2_000_003L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:47:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 201, atNs = 2_000_004L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:48:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, owner, 201, 102, 202, atNs = 2_000_005L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:49:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER, owner, 201, 102, 202, atNs = 2_000_006L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:64:    private fun r42LateCriticalWakeSurvivesRawPressure(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:70:            val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 942, attempt * 1000, base)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:73:            KeyguardCardDiagnostics.r41Bind(owner, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:75:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = base + 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:76:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, request, atNs = base + 2)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:77:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, request, atNs = base + 3)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:78:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, owner, request, 100 + attempt, 200 + attempt, atNs = base + 4)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:79:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER, owner, request, 100 + attempt, 200 + attempt, atNs = base + 5)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:81:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, 10_000L + index, atNs = base + 100 + index)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:146:                for (request in 1L..29L) KeyguardCardDiagnostics.r41Mark(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:147:                    KeyguardR41RawLedger.OFFER, owner, 10_000L * (index + 1) + request,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:153:                listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:154:                    KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:155:                    KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:156:                    KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:180:        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 10, 10_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:182:        KeyguardCardDiagnostics.r41Bind(owner, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:203:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 10_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:204:        for (id in 1L..29L) KeyguardCardDiagnostics.r41Mark(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:205:            KeyguardR41RawLedger.OFFER, owner, id, atNs = 1_234_567_890_000_000L + id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:210:            listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:211:                KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:212:                KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:213:                KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:231:        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 1, 1_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:233:        KeyguardCardDiagnostics.r41Bind(owner, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:234:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 1_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:236:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, id, atNs = 2_000L + id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:238:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 1, atNs = 3_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:239:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 1, atNs = 4_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:240:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 25, atNs = 5_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:241:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 25, atNs = 6_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:257:        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 10, 10_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:260:        KeyguardCardDiagnostics.r41Bind(old, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:261:        KeyguardCardDiagnostics.r41Bind(old, receipt, screen = true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:265:        listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:266:            KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:267:            KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:268:            KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:269:            KeyguardCardDiagnostics.r41SamplerMark(it, sample, if (it == KeyguardR41RawLedger.SAMPLE_READ_END) 5 else 0)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:271:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, old, atNs = 10_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:273:            KeyguardCardDiagnostics.r41Mark(phase, old, request, reservation, output, atNs = at)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:275:        mark(KeyguardR41RawLedger.OFFER, 101, 11_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:276:        mark(KeyguardR41RawLedger.ORDERED_SHADOW_OFFER, 101, 11_500L, 102, 15)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:277:        mark(KeyguardR41RawLedger.GRANT, 101, 12_000L, 1001, 2001)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:278:        mark(KeyguardR41RawLedger.CANCEL, 101, 13_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:279:        mark(KeyguardR41RawLedger.OFFER, 102, 14_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:280:        mark(KeyguardR41RawLedger.WORKER, 102, 15_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:281:        mark(KeyguardR41RawLedger.READ_START, 102, 16_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:282:        mark(KeyguardR41RawLedger.READ_END, 102, 17_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:283:        mark(KeyguardR41RawLedger.DISPATCH, 102, 18_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:284:        mark(KeyguardR41RawLedger.MAIN, 102, 19_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:285:        mark(KeyguardR41RawLedger.GRANT, 102, 20_000L, 1002, 2002)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:286:        mark(KeyguardR41RawLedger.WINNER, 102, 21_000L, 1002, 2002)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:287:        mark(KeyguardR41RawLedger.FALLBACK_CANDIDATE, 103, 22_000L, 1003, 3003)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:288:        mark(KeyguardR41RawLedger.FALLBACK_POST_RECEIPT, 103, 23_000L, 1003, 4003)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:310:        val newReceipt = KeyguardCardDiagnostics.r41Provisional(newCapture, 1, 941, 30, 30_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:312:        KeyguardCardDiagnostics.r41Bind(current, newReceipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:313:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, old, 101, 1001, 2001, atNs = 99_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:324:        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 1, 1_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:326:        KeyguardCardDiagnostics.r41Bind(owner, receipt)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:327:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 1_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:329:            KeyguardCardDiagnostics.r41Mark(phase, owner, request, reservation, output, atNs = at)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:331:        mark(KeyguardR41RawLedger.OFFER, 1, 2_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:332:        mark(KeyguardR41RawLedger.WORKER, 1, 2_001L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:333:        for (id in 2L..75L) mark(KeyguardR41RawLedger.OFFER, id, 2_001L + id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:334:        mark(KeyguardR41RawLedger.WORKER, 75, 3_000L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:335:        mark(KeyguardR41RawLedger.READ_START, 75, 3_100L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:336:        mark(KeyguardR41RawLedger.READ_END, 75, 3_200L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:337:        mark(KeyguardR41RawLedger.DISPATCH, 75, 3_300L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:338:        mark(KeyguardR41RawLedger.MAIN, 75, 3_400L)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:339:        mark(KeyguardR41RawLedger.GRANT, 75, 3_500L, 4, 5)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:340:        mark(KeyguardR41RawLedger.WINNER, 75, 3_600L, 4, 5)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:221:                            .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:250:                        .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:34:import com.fluvi.app.lockscreen.KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:124:            KeyguardInspectionFreshness.Ticket(owner, 1, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:323:        var firstProof: KeyguardFirstAuthorizedOrb.Proof? = null // Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:352:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:416:    private val inspectionFreshness = KeyguardInspectionFreshness()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:680:            KeyguardCardDiagnostics.r41Bind(early.diagnosticContext, sample.r41WakeOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:681:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, early.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:723:            if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:825:        val previous: KeyguardFirstAuthorizedOrb.Proof?
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:944:    private fun scheduleR19Join() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1021:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1185:    private fun prepareR18Decision(owner: R18Active, request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1241:                scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1345:            if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1601:                KeyguardCardDiagnostics.r41Provisional(r41Capture, 1, session.get(), receivedAt, r41AtNs) else 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1633:            val r41Ordinal = KeyguardCardDiagnostics.r41Provisional(r41Capture, 2, session.get(), receivedAt, r41AtNs)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1784:                            if (request != null && show != null) KeyguardCardDiagnostics.r41Mark(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1785:                                KeyguardR41RawLedger.FALLBACK_POST_RECEIPT, operation.context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1854:            KeyguardCardDiagnostics.r41Provisional(r41Capture, 3, session.get(), callbackReceivedAt, r41AtNs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2202:                KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, ordinal, screen = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2283:        KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, wakeOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2284:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, currentDiagnosticAttempt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2288:            KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, screenOrdinal, screen = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2368:            if (r18Active?.preparation?.emptyAwaitingDisclosure == true) scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2551:            r42SceneSerial = externalScene?.takeIf { meta != null && ingress != null },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2552:            r42FrameworkEvent = frameworkEvent && meta != null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2631:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_SHADOW_OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2634:        if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2671:        val r42ReadOwner: R32DirectSnapshot?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2675:        var r42SuppressedPositive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2763:    private fun readInspection(request: KeyguardCardInspectionRequest): PhysicalReadOutcome {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2764:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WORKER, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2781:        var r42ReadOwner: R32DirectSnapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2783:            r42ReadOwner = r34EmptyDirectLocked(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2784:            r42ReadOwner != null || r37EarlyStampLocked(request) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2807:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2809:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, request.diagnosticContext, request.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2901:            r38MilestoneOrdered, r42ReadOwner))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3055:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3084:        applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3095:            r42Read = read,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3119:    private fun r34EmptyDirectLocked(request: KeyguardCardInspectionRequest): R32DirectSnapshot? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3172:        val owner = r34EmptyDirectLocked(request) ?: return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3182:        val now = r34EmptyDirectLocked(request) ?: return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3192:    private fun r42SelectBeforeReadLocked(scheduled: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3194:        val owner = r34EmptyDirectLocked(scheduled) ?: run { trace?.reason = 1; return null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3202:        if (!r42ActualLatestLocked(scheduled, latest, scene)) { trace?.reason = 5; return null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3205:            !openingHandoff.canRetireUnstartedForR42(scheduled, owner.reservation)) { trace?.reason = 7; return null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3206:        val selected = inspectionQueue.selectUnstartedLatest(scheduled, latest, ticket.reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3208:        openingHandoff.retireUnstartedForR42(scheduled, owner.reservation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3213:    private fun r42ActualLatestLocked(request: KeyguardCardInspectionRequest,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3218:            inspectionAuthority.matches(next) && next.r42SceneSerial == scene &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3421:            val successorOutcome = readInspection(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3514:            val r42Trace = if (scheduled.diagnosticContext?.captureId?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3517:            val selected = synchronized(queueLock) { r42SelectBeforeReadLocked(scheduled, r42Trace) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3523:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_PRESTART,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3526:                        (if (selected.r42FrameworkEvent) 16L else 0L) +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3529:            if (r42Trace != null) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_PRECHECK,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3530:                scheduled.diagnosticContext, scheduled.id, r42Trace.pending, r42Trace.reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3532:            val physical = readInspection(active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3582:                val r32 = if (!read.r38MilestoneOrdered && successor == null && r34EmptyDirectLocked(active) == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3600:                scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3636:                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_BYPASS,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3658:                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.DISPATCH, active.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3660:                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.MAIN, active.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3685:                if (read.r42SuppressedPositive && request == null && serviceJob.isActive) mainHandler.post {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3687:                        requestSystemCheck("r42SuccessorLost", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3689:                scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3717:                    successorOutcome = readInspection(successor)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3751:            scheduleR19Join()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4197:            val adopted = !r38MilestoneOrdered && r34EmptyDirectLocked(request) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4269:                            r34ReadOwner = if (r34Eligible) r34EmptyDirectLocked(request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4585:    private fun applyInspection(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4596:        r42Read: CompletedInspection? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4717:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, request.diagnosticContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4740:        val r42OldOwner = r42Read?.r42ReadOwner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4741:        val r42OldScene = inspection.r19ReadSceneSerial
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4742:        var r42PostReason = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4743:        var r42PostPending = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4744:        val r42Stale = when {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4745:            disposition != CompletedDisposition.NORMAL -> { r42PostReason = 1; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4746:            r42Read?.r38MilestoneOrdered != true -> { r42PostReason = 2; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4747:            r42OldOwner == null -> { r42PostReason = 3; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4748:            r42OldScene == null -> { r42PostReason = 4; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4749:            inspection.freshnessRevision == null -> { r42PostReason = 5; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4750:            !completeMain || decision != KeyguardCardVisibility.SHOW_FULL || !signals.systemStateAvailable -> { r42PostReason = 6; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4753:                r42PostPending = pending?.id ?: 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4757:                    !r34SameEmptyOwnerLocked(request, r42OldOwner) -> { r42PostReason = 7; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4758:                    pending == null -> { r42PostReason = 8; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4759:                    freshness == null -> { r42PostReason = 9; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4760:                    !r42ActualLatestLocked(request, pending, scene) -> { r42PostReason = 10; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4761:                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, r42OldScene) -> { r42PostReason = 11; null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4762:                    else -> { r42PostReason = 12; R42StaleSuccessor(pending.id, r42OldScene, scene, if (r42OldScene != scene) 1L else 2L) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4766:        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_POSTCHECK,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4767:            request.diagnosticContext, request.id, r42PostPending, r42PostReason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4768:        if (r42Stale != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4769:            r42Read?.r42SuppressedPositive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4770:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_STALE_POSITIVE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4771:                request.diagnosticContext, request.id, r42Stale.requestId, r42Stale.currentScene + 1L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4772:            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_STALE_DETAIL,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4773:                request.diagnosticContext, request.id, r42Stale.oldScene + 1L, r42Stale.cause)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4805:            if (!prepareR18Decision(staged, request, inspection, decision, settings,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5321:                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, directOwner.diagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5351:                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.FALLBACK_CANDIDATE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5369:                    if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5480:                                crossed = localPresentationAllowed() && currentProof && r18Coordinator.crossSubmitBoundary(permit)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5504:                                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:50:    val r42SceneSerial: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:51:    val r42FrameworkEvent: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:73:            r42SceneSerial = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:74:            r42FrameworkEvent = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:298:    fun selectUnstartedLatest(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:497:        val r41 = KeyguardR41RawLedger()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:498:        val r42Core = KeyguardR41RawLedger(8192)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:499:        val r42OfferTail = KeyguardR42OfferTail()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:501:        var r42CoreFlushed = 0 // diagnostic consumer only
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:502:        val r42TailSeen = LongArray(KeyguardR42OfferTail.SLOTS) // diagnostic consumer only
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:505:            r41PendingAtCut = r41.cut() + r42Core.cut() + r42OfferTail.cut()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:837:        val r41: KeyguardR41AttemptLedger = KeyguardR41AttemptLedger(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:954:        var r41Provisional: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:955:        var r41Bindings: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:958:        var r42CoreOverflow: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:959:        var r42TailContention: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:960:        var r42TailOverwritten: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:961:        var r42TailLate: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:966:        var r41ProvisionalEvicted: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1732:    fun r41Provisional(captureId: String?, source: Int, serviceSession: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1736:        return token.r42Core.offer(KeyguardR41RawLedger.PROVISIONAL, 0, serviceSession, 0, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1740:    fun r41Bind(owner: KeyguardDiagnosticContext?, ordinal: Long, screen: Boolean = false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1743:        token.r42Core.offer(if (screen) KeyguardR41RawLedger.BIND_SCREEN else KeyguardR41RawLedger.BIND_WAKE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1748:    fun r41Mark(phase: Int, owner: KeyguardDiagnosticContext?, request: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1754:        val verbose = phase == KeyguardR41RawLedger.OFFER || phase == KeyguardR41RawLedger.ORDERED_SHADOW_OFFER
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1755:        val ledger = if (verbose) token.r41 else token.r42Core
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1758:        if (phase == KeyguardR41RawLedger.OFFER && offered == 0L)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1759:            token.r42OfferTail.offer(owner.attemptId, owner.serviceSession, owner.originWakeEpoch, request, whenNs, thread)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2591:    private fun flushR41Raw(active: TimingCapture, token: CaptureIngress?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2594:        fun drain(raw: KeyguardR41RawLedger, core: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2595:            var cursor = if (core) token.r42CoreFlushed else token.r41Flushed
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2605:                if (record.phase == KeyguardR41RawLedger.PROVISIONAL) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2606:                    active.r41Provisional += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2609:                        active.r41ProvisionalEvicted += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2616:                if (record.phase in KeyguardR41RawLedger.SAMPLE_OFFER..KeyguardR41RawLedger.SAMPLE_REJECT) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2630:                        val index = record.phase - KeyguardR41RawLedger.SAMPLE_OFFER
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2656:                if (record.phase == KeyguardR41RawLedger.BIND_WAKE || record.phase == KeyguardR41RawLedger.BIND_SCREEN) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2659:                    if (source == null || source.phase != KeyguardR41RawLedger.PROVISIONAL || source.session != record.session ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2660:                        (record.phase == KeyguardR41RawLedger.BIND_SCREEN && source.extra1 != 1L)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2668:                            val kind = if (record.phase == KeyguardR41RawLedger.BIND_SCREEN) "SCREEN" else "WAKE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2671:                        attempt.r41.record(if (record.phase == KeyguardR41RawLedger.BIND_SCREEN) "SCREEN" else "WAKE", null, source.atNs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2674:                        active.r41Bindings += 1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2678:                        KeyguardR41RawLedger.OFFER -> "OFFER"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2679:                        KeyguardR41RawLedger.WORKER -> "WORKER_START"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2680:                        KeyguardR41RawLedger.READ_START -> "READ_START"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2681:                        KeyguardR41RawLedger.READ_END -> "READ_END"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2682:                        KeyguardR41RawLedger.DISPATCH -> "DISPATCH"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2683:                        KeyguardR41RawLedger.MAIN -> "MAIN"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2684:                        KeyguardR41RawLedger.GRANT -> "GRANT"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2685:                        KeyguardR41RawLedger.WINNER -> "WINNER"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2686:                        KeyguardR41RawLedger.CANCEL -> "CANCEL"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2687:                        KeyguardR41RawLedger.ELIGIBLE -> "ELIGIBLE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2688:                        KeyguardR41RawLedger.DENIED -> "DENIED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2689:                        KeyguardR41RawLedger.ORDERED_BYPASS -> "ORDERED_BYPASS"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2690:                        KeyguardR41RawLedger.ORDERED_SHADOW_OFFER -> "ORDERED_SHADOW_OFFER"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2691:                        KeyguardR41RawLedger.SYSTEM_ELIGIBLE -> "SYSTEM_ELIGIBLE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2692:                        KeyguardR41RawLedger.FALLBACK_CANDIDATE -> "FALLBACK_CANDIDATE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2693:                        KeyguardR41RawLedger.FALLBACK_POST_RECEIPT -> "FALLBACK_POST_RECEIPT"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2694:                    KeyguardR41RawLedger.R42_PRESTART -> "R42_PRESTART"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2695:                    KeyguardR41RawLedger.R42_STALE_POSITIVE -> "R42_STALE_POSITIVE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2696:                    KeyguardR41RawLedger.R42_STALE_DETAIL -> "R42_STALE_DETAIL"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2697:                    KeyguardR41RawLedger.R42_PRECHECK -> "R42_PRECHECK"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2698:                    KeyguardR41RawLedger.R42_POSTCHECK -> "R42_POSTCHECK"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2709:            if (core) token.r42CoreFlushed = cursor else token.r41Flushed = cursor
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2714:        drain(token.r42Core, true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2715:        for (slot in 0 until KeyguardR42OfferTail.SLOTS) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2716:            val record = token.r42OfferTail.read(slot) ?: continue
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2717:            if (token.r42TailSeen[slot] == record.version) continue
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2721:                if (isFinal) { active.r41RawUnmatched += 1; token.r42TailSeen[slot] = record.version }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2729:            token.r42TailSeen[slot] = record.version
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2735:        flushR41Raw(active, r41Token)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2740:        r42CoreOverflow = r41Token?.r42Core?.overflow?.get() ?: active.r42CoreOverflow,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2741:        r42TailContention = r41Token?.r42OfferTail?.contention?.get() ?: active.r42TailContention,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2742:        r42TailOverwritten = r41Token?.r42OfferTail?.overwritten?.get() ?: active.r42TailOverwritten,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2743:        r42TailLate = r41Token?.r42OfferTail?.late?.get() ?: active.r42TailLate,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2745:            it.r41.inFlight() + it.r42Core.inFlight() + it.r42OfferTail.inFlight()) } ?: active.r41RawPending,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2746:        r41RawLate = r41Token?.let { it.r41.late.get() + it.r42Core.late.get() } ?: active.r41RawLate,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2750:        r41MailboxWallNs = r41Token?.let { it.r41.offerWallNs.get() + it.r42Core.offerWallNs.get() + it.r42OfferTail.offerWallNs.get() } ?: active.r41MailboxWallNs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2751:        r41MailboxMaxWallNs = r41Token?.let { maxOf(it.r41.offerMaxWallNs.get(), it.r42Core.offerMaxWallNs.get(), it.r42OfferTail.offerMaxWallNs.get()) } ?: active.r41MailboxMaxWallNs,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2752:        r41MailboxTimingInvalid = r41Token?.let { it.r41.offerTimingInvalid.get() + it.r42Core.offerTimingInvalid.get() + it.r42OfferTail.offerTimingInvalid.get() } ?: active.r41MailboxTimingInvalid,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2950:                "provisional=${active.r41Provisional} bindings=${active.r41Bindings} rawOverflow=${active.r41RawOverflow} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2951:                "receiptEvicted=${active.r41ProvisionalEvicted} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2957:            appendLine("R42_DIAGNOSTIC_CAPACITY coreOverflow=${active.r42CoreOverflow} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2958:                "offerTailContention=${active.r42TailContention} offerTailOverwritten=${active.r42TailOverwritten} offerTailLate=${active.r42TailLate} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2960:            appendLine("R42_CHECK_CODES pre=1owner,2active,3adoption,4noPending,5latest,6freshness,7opening,8queue,9selected " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2962:            appendLine("R42_CHECK_FIELDS=count/firstRequest/firstReason/firstPending/lastRequest/lastReason/lastPending")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3002:            active.diagnosticConsumerFailures + active.r41RawOverflow + active.r42CoreOverflow + active.r41RawUnmatched + active.r41RawPending +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3003:            active.r41RawLate + active.r41ReportsPending + active.r41ReportsDropped + active.r41ProvisionalEvicted +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:457:        val intent = KeyguardFirstAuthorizedOrb.intent(materialSettings.showFinancialDetails)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:458:        val wantsFull = full ?: (intent == KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAcquisition.kt:24:        ticket: KeyguardInspectionFreshness.Ticket?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshness.kt:8:internal class KeyguardInspectionFreshness {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:211:    fun canRetireUnstartedForR42(request: KeyguardCardInspectionRequest, token: Any): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:219:    fun retireUnstartedForR42(request: KeyguardCardInspectionRequest, token: Any) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoff.kt:223:        op.lastReason = "r42PreStartReplaced"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:258:    fun crossSubmitBoundary(reveal: Reveal): Boolean = synchronized(lock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:5:internal class KeyguardR41AttemptLedger {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:34:    private var r42PreCount = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:35:    private var r42PreFirstRequest = MISSING; private var r42PreFirstNext = MISSING; private var r42PreFirstNs = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:36:    private var r42PreLastRequest = MISSING; private var r42PreLastNext = MISSING; private var r42PreLastNs = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:37:    private var r42PreFreshness = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:38:    private var r42StaleCount = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:39:    private var r42StaleFirstRequest = MISSING; private var r42StaleFirstNext = MISSING; private var r42StaleFirstNs = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:40:    private var r42StaleLastRequest = MISSING; private var r42StaleLastNext = MISSING; private var r42StaleLastNs = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:41:    private var r42StaleScene = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:42:    private var r42StaleOldScene = MISSING; private var r42StaleCause = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:43:    private var r42PreChecks = 0L; private var r42PreFirstCheck = MISSING; private var r42PreFirstReason = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:44:    private var r42PreFirstPending = MISSING; private var r42PreLastCheck = MISSING; private var r42PreLastReason = MISSING; private var r42PreLastPending = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:45:    private var r42PostChecks = 0L; private var r42PostFirstCheck = MISSING; private var r42PostFirstReason = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:46:    private var r42PostFirstPending = MISSING; private var r42PostLastCheck = MISSING; private var r42PostLastReason = MISSING; private var r42PostLastPending = MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:51:        if (phase == "R42_PRECHECK" || phase == "R42_POSTCHECK") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:53:            if (phase == "R42_PRECHECK") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:54:                if (r42PreChecks++ == 0L) { r42PreFirstCheck = request; r42PreFirstReason = output; r42PreFirstPending = reservation ?: MISSING }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:55:                r42PreLastCheck = request; r42PreLastReason = output; r42PreLastPending = reservation ?: MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:57:                if (r42PostChecks++ == 0L) { r42PostFirstCheck = request; r42PostFirstReason = output; r42PostFirstPending = reservation ?: MISSING }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:58:                r42PostLastCheck = request; r42PostLastReason = output; r42PostLastPending = reservation ?: MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:62:        if (phase == "R42_STALE_DETAIL") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:63:            if (request == null || request <= 0 || request != r42StaleLastRequest ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:67:                r42StaleOldScene = reservation - 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:68:                r42StaleCause = output
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:72:        if (phase == "R42_PRESTART" || phase == "R42_STALE_POSITIVE") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:74:            if (phase == "R42_PRESTART") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:75:                if (r42PreCount++ == 0L) { r42PreFirstRequest = request; r42PreFirstNext = reservation; r42PreFirstNs = atNs }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:76:                r42PreLastRequest = request; r42PreLastNext = reservation; r42PreLastNs = atNs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:77:                r42PreFreshness = output ?: MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:79:                if (r42StaleCount++ == 0L) { r42StaleFirstRequest = request; r42StaleFirstNext = reservation; r42StaleFirstNs = atNs }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:80:                r42StaleLastRequest = request; r42StaleLastNext = reservation; r42StaleLastNs = atNs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:81:                r42StaleScene = output ?: MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:201:            systemEligible == -1 && shadowOffers == 0L && orderedBypasses == 0L && r42PreCount == 0L &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:202:            r42StaleCount == 0L && r42PreChecks == 0L && r42PostChecks == 0L) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:238:            " r42Pre=$r42PreCount/${value(r42PreFirstRequest)}/${value(r42PreFirstNext)}/${value(r42PreFirstNs)}/${value(r42PreLastRequest)}/${value(r42PreLastNext)}/${value(r42PreLastNs)}/${value(r42PreFreshness)}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:239:            " r42PreMeta=freshnessPlusOne_framework16_origin32" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:240:            " r42PreCheck=$r42PreChecks/${value(r42PreFirstCheck)}/${value(r42PreFirstReason)}/${value(r42PreFirstPending)}/${value(r42PreLastCheck)}/${value(r42PreLastReason)}/${value(r42PreLastPending)}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:241:            " r42Stale=$r42StaleCount/${value(r42StaleFirstRequest)}/${value(r42StaleFirstNext)}/${value(r42StaleFirstNs)}/${value(r42StaleLastRequest)}/${value(r42StaleLastNext)}/${value(r42StaleLastNs)}/${value(r42StaleScene)}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:242:            " r42StaleOldScene=${value(r42StaleOldScene)} r42StaleCause=${value(r42StaleCause)} r42StaleSceneEncoding=currentPlusOne_causes1Scene2NewerRequest" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:243:            " r42PostCheck=$r42PostChecks/${value(r42PostFirstCheck)}/${value(r42PostFirstReason)}/${value(r42PostFirstPending)}/${value(r42PostLastCheck)}/${value(r42PostLastReason)}/${value(r42PostLastPending)}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:258:    fun snapshot(): KeyguardR41AttemptLedger = KeyguardR41AttemptLedger().also { copy ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:271:        copy.r42PreCount = r42PreCount; copy.r42PreFirstRequest = r42PreFirstRequest; copy.r42PreFirstNext = r42PreFirstNext
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:272:        copy.r42PreFirstNs = r42PreFirstNs; copy.r42PreLastRequest = r42PreLastRequest; copy.r42PreLastNext = r42PreLastNext
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:273:        copy.r42PreLastNs = r42PreLastNs; copy.r42PreFreshness = r42PreFreshness
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:274:        copy.r42StaleCount = r42StaleCount; copy.r42StaleFirstRequest = r42StaleFirstRequest; copy.r42StaleFirstNext = r42StaleFirstNext
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:275:        copy.r42StaleFirstNs = r42StaleFirstNs; copy.r42StaleLastRequest = r42StaleLastRequest; copy.r42StaleLastNext = r42StaleLastNext
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:276:        copy.r42StaleLastNs = r42StaleLastNs; copy.r42StaleScene = r42StaleScene
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:277:        copy.r42StaleOldScene = r42StaleOldScene; copy.r42StaleCause = r42StaleCause
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:278:        copy.r42PreChecks = r42PreChecks; copy.r42PreFirstCheck = r42PreFirstCheck; copy.r42PreFirstReason = r42PreFirstReason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:279:        copy.r42PreFirstPending = r42PreFirstPending; copy.r42PreLastCheck = r42PreLastCheck; copy.r42PreLastReason = r42PreLastReason; copy.r42PreLastPending = r42PreLastPending
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:280:        copy.r42PostChecks = r42PostChecks; copy.r42PostFirstCheck = r42PostFirstCheck; copy.r42PostFirstReason = r42PostFirstReason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedger.kt:281:        copy.r42PostFirstPending = r42PostFirstPending; copy.r42PostLastCheck = r42PostLastCheck; copy.r42PostLastReason = r42PostLastReason; copy.r42PostLastPending = r42PostLastPending
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:9:internal class KeyguardR41RawLedger(private val capacity: Int = 2048) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:116:        const val R42_PRESTART = 34
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:117:        const val R42_STALE_POSITIVE = 35
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:118:        const val R42_STALE_DETAIL = 36
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:119:        const val R42_PRECHECK = 37
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedger.kt:120:        const val R42_POSTCHECK = 38
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTail.kt:10:internal class KeyguardR42OfferTail {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:93:        observe(KeyguardR41RawLedger.SAMPLE_OFFER, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:95:            observe(KeyguardR41RawLedger.SAMPLE_REJECT, request, 1)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:120:            previous?.let { observe(KeyguardR41RawLedger.SAMPLE_REPLACED, it, request.id) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:126:        pending?.let { observe(KeyguardR41RawLedger.SAMPLE_REJECT, it, 4) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:142:        observe(KeyguardR41RawLedger.SAMPLE_SUBMIT, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:144:            observe(KeyguardR41RawLedger.SAMPLE_WORKER, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:145:            observe(KeyguardR41RawLedger.SAMPLE_READ_START, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:148:            observe(KeyguardR41RawLedger.SAMPLE_READ_END, request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:153:            observe(KeyguardR41RawLedger.SAMPLE_DISPATCH, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:155:                observe(KeyguardR41RawLedger.SAMPLE_MAIN, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:159:                        observe(KeyguardR41RawLedger.SAMPLE_DELIVER, request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:162:                        observe(KeyguardR41RawLedger.SAMPLE_REJECT, request, 2)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:175:                            observe(KeyguardR41RawLedger.SAMPLE_REJECT, next, 3)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:17:        val freshness = KeyguardInspectionFreshness().also {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:22:        val selected = requireNotNull(queue.selectUnstartedLatest(a, c, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:40:        assertNull(queue.selectUnstartedLatest(a.copy(), b, KeyguardWindowFreshness.FRAMEWORK_EVENT))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:41:        assertNull(queue.selectUnstartedLatest(a, b.copy(), KeyguardWindowFreshness.FRAMEWORK_EVENT))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:44:        assertNull(queue.selectUnstartedLatest(b, c, KeyguardWindowFreshness.FRAMEWORK_EVENT))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:52:        assertNull(newerWake.selectUnstartedLatest(a, other, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAcquisitionTest.kt:13:        KeyguardInspectionFreshness.Ticket(authority, 1L, reason)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:8:class KeyguardFirstAuthorizedOrbTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:10:    private fun proof(gate: KeyguardFirstAuthorizedOrb, request: Long = 10,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:16:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:29:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:45:        assertEquals(KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:46:            KeyguardFirstAuthorizedOrb.intent(true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:47:        assertEquals(KeyguardFirstAuthorizedOrb.Intent.DISCREET_PREPOSTED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:48:            KeyguardFirstAuthorizedOrb.intent(false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:49:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:59:        val gate = KeyguardFirstAuthorizedOrb(); val readScene = gate.sceneSerial()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:74:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:86:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:99:        val gate = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:118:        assertTrue(synchronized(lock) { gate.isCurrent(proof) && coordinator.crossSubmitBoundary(reveal) })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:124:        val gate = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:141:        assertFalse(synchronized(lock) { gate.isCurrent(proof) && coordinator.crossSubmitBoundary(reveal) })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:147:        val lock = Any(); val gate = KeyguardFirstAuthorizedOrb(lock); val coordinator = KeyguardOrbPresentationCoordinator(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:159:        assertTrue(coordinator.crossSubmitBoundary(reveal)); assertNotNull(coordinator.markNativeApplyReturned(reveal))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:167:        val gate = KeyguardFirstAuthorizedOrb(); val first = requireNotNull(proof(gate))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:6:class KeyguardInspectionFreshnessTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:14:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:26:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:68:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:88:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:112:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:127:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:136:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:147:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoffTest.kt:24:        assertFalse(gate.canRetireUnstartedForR42(a, Any()))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoffTest.kt:25:        assertTrue(gate.canRetireUnstartedForR42(a, token))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoffTest.kt:26:        gate.retireUnstartedForR42(a, token)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoffTest.kt:27:        assertEquals("r42PreStartReplaced", gate.snapshot(a.id)?.lastReason)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOpeningInspectionHandoffTest.kt:34:        assertFalse(started.canRetireUnstartedForR42(a, token))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:33:        val lock = Any(); val c = KeyguardOrbPresentationCoordinator(lock); val proof = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:38:        assertTrue(c.crossSubmitBoundary(permit)); val applied = requireNotNull(c.markNativeApplyReturned(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:53:            if (cross) assertTrue(c.crossSubmitBoundary(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:56:            assertFalse(c.crossSubmitBoundary(permit)); assertNull(c.markNativeApplyReturned(permit)); assertFalse(c.revealSubmitted(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:67:        assertTrue(c.armInput(a, host)); val permit = requireNotNull(reveal(c, a)); assertTrue(c.crossSubmitBoundary(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:79:        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:106:        val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:107:        assertFalse(c.crossSubmitBoundary(permit)); assertFalse(c.revealSubmitted(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:128:        assertFalse(withdrawal.crossedSubmitBoundary); assertFalse(c.crossSubmitBoundary(permit)); assertFalse(c.mayAct(token, host))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:137:        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:167:        assertTrue(c.crossSubmitBoundary(permit)); assertNotNull(c.markNativeApplyReturned(permit)); assertTrue(c.revealSubmitted(permit))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:208:        assertFalse(c.crossSubmitBoundary(pending))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:14:        KeyguardInspectionFreshness.Ticket(authority, 1L, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGateTest.kt:36:        assertTrue(coordinator.crossSubmitBoundary(reveal))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGateTest.kt:46:        val reveal = reveal(); assertTrue(coordinator.crossSubmitBoundary(reveal))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGateTest.kt:65:        val reveal = reveal(); assertTrue(coordinator.crossSubmitBoundary(reveal))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:6:class KeyguardR41AttemptLedgerTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:7:    @Test fun r42ChecksAndTransitionsKeepFirstLastAndFrozenOwnership() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:8:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:9:        ledger.record("R42_PRECHECK", 1, 100, 3, 9)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:10:        ledger.record("R42_PRESTART", 1, 101, 3, 2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:11:        ledger.record("R42_PRECHECK", 3, 102, null, 4)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:12:        ledger.record("R42_POSTCHECK", 3, 200, 8, 12)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:13:        ledger.record("R42_STALE_POSITIVE", 3, 201, 8, 13)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:14:        ledger.record("R42_STALE_DETAIL", 3, 202, 11, 1)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:16:        ledger.record("R42_PRECHECK", 8, 300, null, 4)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:18:        assertTrue(row, row.contains("r42PreCheck=2/1/9/3/3/4/UNOBSERVED"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:19:        assertTrue(row, row.contains("r42PostCheck=1/3/12/8/3/12/8"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:20:        assertTrue(row, row.contains("r42StaleOldScene=10 r42StaleCause=1"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:25:        val row = KeyguardR41AttemptLedger().core(8, 9, 10, 3)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:36:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:53:        val different = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:57:        val cancelled = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:65:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:79:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:96:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:109:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:132:        val ledger = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:141:        val same = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:148:        val different = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41AttemptLedgerTest.kt:154:        val receiptOnly = KeyguardR41AttemptLedger()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:9:class KeyguardR41RawLedgerTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:11:        val ledger = KeyguardR41RawLedger(2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:12:        assertEquals(1L, ledger.offer(KeyguardR41RawLedger.PROVISIONAL, 0, 3, 4, 0, 100, 9, 2, 7, 11))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:13:        assertEquals(2L, ledger.offer(KeyguardR41RawLedger.OFFER, 1, 3, 4, 12, 110, 10))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:14:        assertEquals(0L, ledger.offer(KeyguardR41RawLedger.MAIN, 1, 3, 4, 12, 120, 11))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:23:        assertEquals(0L, ledger.offer(KeyguardR41RawLedger.MAIN, 1, 3, 4, 12, 120, 11))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:29:        val ledger = KeyguardR41RawLedger(512)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR41RawLedgerTest.kt:37:                    check(ledger.offer(KeyguardR41RawLedger.READ_START, id, 8, 9, id, id + 1, thread.toLong()) > 0)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:7:class KeyguardR42OfferTailTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:9:        val tail = KeyguardR42OfferTail()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:12:        val rows = (0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:19:        assertFalse((0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read).any { it.request == 201L })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:23:        val tail = KeyguardR42OfferTail()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR42OfferTailTest.kt:37:        val rows = (0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:40:        assertTrue(f.traced.contains(Triple(KeyguardR41RawLedger.SAMPLE_REPLACED, 2L, 3L)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:43:            assertEquals(listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:44:                KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:45:                KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:46:                KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER), stages)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:47:            assertTrue(f.traced.contains(Triple(KeyguardR41RawLedger.SAMPLE_READ_END, id, 5L)))

```
