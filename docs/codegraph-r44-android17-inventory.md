# R44 exact-source authorization inventory

Application source: `ee85285017585b340864963016007025773418f0`

The SCIP graph covers Dart only. Kotlin lines below are direct source navigation, not generated edges or proof of runtime behavior. Native submission and transaction receipts are not physical pixels.

```text
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:30:    @Test fun r44PerWakeEvidenceSurvivesLightPressure() = r44EvidencePressure("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:31:    @Test fun r44PerWakeEvidenceSurvivesFullPressure() = r44EvidencePressure("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:36:    @Test fun r447LatestPreIssueDecisionSurvivesLightPressure() = r447LatestDecision("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:37:    @Test fun r447LatestPreIssueDecisionSurvivesFullPressure() = r447LatestDecision("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:41:    private fun r447LatestDecision(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:42:        KeyguardCardDiagnostics.startCapture(context, "r447-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:47:        val first = KeyguardR446Observation(owner, 990, 3, 40,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:50:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:51:        KeyguardCardDiagnostics.recordR446(first.copy(request = 43, eligibility = "SCENE_CHANGED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:52:        KeyguardCardDiagnostics.recordR446(first.copy(request = 44, eligibility = "NEWER_COMPLETED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:53:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, eligibility = "NEWER_BARRIER_REQUIRED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:56:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:57:        val row = frozen.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:62:        KeyguardCardDiagnostics.recordR446(first.copy(request = 46, eligibility = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:66:    @Test fun r447ProgressAndTerminalRemainWithTheirOriginalRequest() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:67:        KeyguardCardDiagnostics.startCapture(context, "r447-order", "profile", "FULL",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:72:        val first = KeyguardR446Observation(owner, 6990, 7, 40, "UNKNOWN/NO_MAIN_MARKER",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:74:            armGeneration = 2, decisionOrdinal = 1, handoff = KeyguardR447Disposition.NEWER_BARRIER_REQUIRED)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:75:        val issued = first.copy(request = 44, decisionOrdinal = 2, handoff = KeyguardR447Disposition.ISSUED,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:77:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:78:        KeyguardCardDiagnostics.recordR446(issued)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:79:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, decisionOrdinal = 3,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:80:            handoff = KeyguardR447Disposition.ARM_MISMATCH))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:82:        KeyguardCardDiagnostics.recordR446(laterFrame)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:83:        KeyguardCardDiagnostics.recordR446(laterFrame.retireOnce(7090, "duplicate", null, null, null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:86:        KeyguardCardDiagnostics.recordR446(first.copy(request = 99, decisionOrdinal = 99, armGeneration = 1))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:90:        KeyguardCardDiagnostics.recordR446(first.copy(context = unarmed, wake = 8, request = 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:92:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:93:        val rows = report.lineSequence().filter { it.startsWith("R44_6_SAMPLE ") }.toList()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:106:    @Test fun r447TerminalBeforeAnyWakeSurvivesFreezeAndLateCleanup() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:107:        KeyguardCardDiagnostics.startCapture(context, "r447-arm", "profile", "LIGHT",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:110:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 111, "serviceLost")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:111:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 222, "duplicateCleanup")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:112:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:113:        assertTrue(frozen, frozen.contains("R44_7_ARM generation=4 terminal=111/serviceLost"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:114:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 333, "lateCallback")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:119:        KeyguardCardDiagnostics.startCapture(context, "r446-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:121:        var first: KeyguardR446Observation? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:127:            val missing = KeyguardR446Observation(owner, base - 10, wake, base + 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:131:            KeyguardCardDiagnostics.recordR446(missing)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:137:            KeyguardCardDiagnostics.recordR446(shown)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:144:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:146:        assertEquals(6, frozen.lineSequence().count { it.startsWith("R44_6_SAMPLE ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:153:        KeyguardCardDiagnostics.recordR446(checkNotNull(first).copy(backend = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:158:        KeyguardCardDiagnostics.startCapture(context, "r444-reason", "profile", "LIGHT", r442ExpectedSession = 9444)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:164:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 20, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:167:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:170:                r443Candidates = if (failed > 0) listOf(KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:175:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:186:        KeyguardCardDiagnostics.startCapture(context, "r444-pressure", "profile", mode, r442ExpectedSession = 9445)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:196:            val candidates = (1..7).map { n -> KeyguardR443CandidateObservation(969, n, "HOST", n,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:198:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 30, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:202:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:205:                appliedGate = if (empty) KeyguardR444Gate.INCOMPLETE else KeyguardR444Gate.NO_CONTENT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:210:                    KeyguardR445IndexCall("SMALL", "EMPTY", 12, 123, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:211:                    KeyguardR445IndexCall("LARGE", "INELIGIBLE", 13, 136, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:212:                    KeyguardR445IndexCall("ENTRY", "EMPTY", 17, 150, 3)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:213:                r444Windows = listOf(KeyguardR444WindowObservation(972, 0, 3, false, false,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:216:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:218:        assertEquals(8, report.lineSequence().count { it.startsWith("R44_4_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:219:        assertEquals(3, report.lineSequence().count { it.startsWith("R44_WAKE ") && it.contains("firstPostRead=missing") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:224:        assertEquals(5, report.lineSequence().count { it.startsWith("R44_5_INDEX ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:225:        assertEquals(15, report.lineSequence().count { it.startsWith("R44_5_ID ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:230:        KeyguardCardDiagnostics.startCapture(context, "r442-fixture", "profile", "LIGHT", r442ExpectedSession = 945)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:234:        KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:237:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, id, 1, 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:243:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:246:        val handoff = report.lineSequence().single { it.startsWith("R44_2_HANDOFF ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:253:    private fun r44EvidencePressure(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:254:        KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "profile", mode, r442ExpectedSession = 944)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:263:            fun record(request: Long, start: Long, verdict: KeyguardSurface) = KeyguardCardDiagnostics.recordR44(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:264:                KeyguardR44ReadObservation(owner, request, wake, wake + 50, start, start + 5,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:268:                    KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:269:                    KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.EXTRA_EAGER, 2),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:275:                    firstCandidate = KeyguardR44Markers.Marker.DEVICE_ENTRY,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:276:                    firstCarrier = KeyguardR44Markers.Carrier.VIEW_ID, cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:277:                    r443Windows = listOf(KeyguardR443WindowObservation(10, 7, 7, 0, true)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:278:                    r443Candidates = (1..7).map { n -> KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:281:            KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:284:            KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:301:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:304:            val row = report.lineSequence().single { it.startsWith("R44_WAKE ") && it.contains("wake=$wake ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:307:            assertTrue(report, report.contains("R44_2_HANDOFF old=${wake * 1000 + 1} next=${wake * 1000 + 2} "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:308:            assertTrue(report, report.contains("R44_2_EVIDENCE req=${wake * 1000 + 2} lookup=VERIFIED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:309:            assertTrue(report, report.contains("R44_3_JEL req=${wake * 1000 + 2} window=10 ordinal=7"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:310:            assertTrue(report, report.contains("R44_3_BOUNDARY old=${wake * 1000 + 1}"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:313:        assertEquals(6, report.lineSequence().count { it.startsWith("R44_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:316:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(checkNotNull(firstOwner), 9999, 0, null,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:330:                KeyguardCardDiagnostics.startCapture(context, "r26-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:382:                val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:423:        KeyguardCardDiagnostics.startCapture(context, "r25-fixture", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:451:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:460:        KeyguardCardDiagnostics.startCapture(context, "r25-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:463:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:471:        KeyguardCardDiagnostics.startCapture(context, "r22-4", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:490:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:501:        KeyguardCardDiagnostics.startCapture(context, "r22-4-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:505:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:513:        KeyguardCardDiagnostics.startCapture(context, "r22-2", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:528:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:548:        KeyguardCardDiagnostics.startCapture(context, "r22-1", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:600:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:612:        KeyguardCardDiagnostics.startCapture(context, "new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:615:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:633:            KeyguardCardDiagnostics.startCapture(context, "r31", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:673:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:684:            KeyguardCardDiagnostics.startCapture(context, "r31-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:687:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:705:            KeyguardCardDiagnostics.startCapture(context, "r32", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:730:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:744:            KeyguardCardDiagnostics.startCapture(context, "r32-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:749:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:767:            KeyguardCardDiagnostics.startCapture(context, "r34", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:794:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:809:            KeyguardCardDiagnostics.startCapture(context, "r34-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:813:            assertFalse((KeyguardCardDiagnostics.freezeCapture(context)["report"] as String).contains("reservation=704"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:827:        KeyguardCardDiagnostics.startCapture(context, "r18-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:869:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:888:        KeyguardCardDiagnostics.startCapture(context, "r18-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:892:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:900:        KeyguardCardDiagnostics.startCapture(context, "r19-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:946:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:970:            KeyguardCardDiagnostics.startCapture(context, "r22-token-pressure", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:996:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1021:            KeyguardCardDiagnostics.startCapture(context, "r21-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1141:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1206:            KeyguardCardDiagnostics.startCapture(context, "r20-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1233:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1258:            KeyguardCardDiagnostics.startCapture(context, "r13-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1283:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1295:        KeyguardCardDiagnostics.startCapture(context, "r13-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1314:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1326:        KeyguardCardDiagnostics.startCapture(context, "r13-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1329:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1334:        KeyguardCardDiagnostics.startCapture(context, "r12-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1361:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1382:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1394:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1407:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1409:        val before = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1424:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1433:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1441:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1473:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1490:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1527:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1543:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1575:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1598:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1631:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1644:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1677:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1691:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1703:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1708:        KeyguardCardDiagnostics.startCapture(context, "old-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1712:        KeyguardCardDiagnostics.startCapture(context, "new-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1722:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1728:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1748:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1754:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1795:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1802:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1825:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1833:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1842:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1851:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1852:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1866:        KeyguardCardDiagnostics.startCapture(context, "light-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1870:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1872:        KeyguardCardDiagnostics.startCapture(context, "full-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1874:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1881:        KeyguardCardDiagnostics.startCapture(context, "async-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1906:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1938:            val captureId = KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)["captureId"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2004:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2033:        KeyguardCardDiagnostics.startCapture(context, source, "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2035:        val off = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2043:            KeyguardCardDiagnostics.startCapture(context, "r15-owner", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2054:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2067:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2135:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2164:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2186:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2203:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2206:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2212:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2265:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2288:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2291:        val rotated = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2298:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2374:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2428:            KeyguardCardDiagnostics.startCapture(context, "r07-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2482:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2508:            KeyguardCardDiagnostics.startCapture(context, "new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2511:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2520:        KeyguardCardDiagnostics.startCapture(context, "r08-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2560:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2569:        KeyguardCardDiagnostics.startCapture(context, "r08-next-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2573:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2578:        KeyguardCardDiagnostics.startCapture(context, "identity-check", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2589:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2595:        KeyguardCardDiagnostics.startCapture(context, "draw-gap-identity", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2610:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2642:        KeyguardCardDiagnostics.startCapture(context, "r11-visible-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2669:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2680:        KeyguardCardDiagnostics.startCapture(context, "r11-new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2687:        val nextReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2694:        KeyguardCardDiagnostics.startCapture(context, "r10-export-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2747:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2763:        KeyguardCardDiagnostics.startCapture(context, "r09-gap-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2791:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2802:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2805:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2807:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2813:        KeyguardCardDiagnostics.startCapture(context, "gap-bounds", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2820:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:40:class KeyguardFirstAuthorizedOrbInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:126:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:268:            report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:301:                report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:374:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:495:            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:867:                val positive = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:917:                val negative = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt:249:            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt:341:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15HeldCanvasInstrumentationTest.kt:120:            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15HeldCanvasInstrumentationTest.kt:263:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:212:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:860:                    report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22RecoveryInstrumentationTest.kt:33:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22RecoveryInstrumentationTest.kt:75:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:187:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:399:                File(dir, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:136:            KeyguardCardDiagnostics.startCapture(context,source,"debug","LIGHT"); capture=true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:251:                        val proof=(gateField.get(actual) as KeyguardFirstAuthorizedOrb).current()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:407:            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:35:        KeyguardCardDiagnostics.startCapture(context, "r42-winning-offer", "profile", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:50:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:65:        KeyguardCardDiagnostics.startCapture(context, "r42-raw-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:84:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:108:            KeyguardCardDiagnostics.startCapture(context, "r41-empty-r22", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:113:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:124:            KeyguardCardDiagnostics.startCapture(context, "r41-shared-cause", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:160:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:178:        KeyguardCardDiagnostics.startCapture(context, "r41-direct-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:217:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:229:        KeyguardCardDiagnostics.startCapture(context, "r41-25-requests", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:242:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:255:        KeyguardCardDiagnostics.startCapture(context, "r41-raw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:289:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:307:        KeyguardCardDiagnostics.startCapture(context, "r41-new-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:314:        val newReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:322:        KeyguardCardDiagnostics.startCapture(context, "r41-burst", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:341:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:350:        KeyguardCardDiagnostics.startCapture(context, "r41-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:377:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:16:        KeyguardCardDiagnostics.startCapture(context, "r43-busy", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:33:            val after = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:45:        KeyguardCardDiagnostics.startCapture(context, "r43-old", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:51:            KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:53:            KeyguardCardDiagnostics.startCapture(context, "r43-new", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:55:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:66:        KeyguardCardDiagnostics.startCapture(context, "r43-test", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:90:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR441HolderReproInstrumentationTest.kt:28:class KeyguardR441HolderReproInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:27:class KeyguardR442OwnerInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:99:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:100:            assertNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:101:            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:108:            KeyguardCardDiagnostics.startCapture(context, "other", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:114:            assertFalse(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:115:            assertTrue(main { service.setR44SyntheticTrial(false) })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:121:            assertFalse(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:45:class KeyguardR445WindowCompositionTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:97:            KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:98:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r445-composition", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:99:            val profile = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:257:            KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:31:class KeyguardR446StockServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:97:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:98:            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:112:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:114:            assertTrue("NOT REACHED: actual stock wake sample observation\n$report", report.contains("R44_6_SAMPLE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:44:class KeyguardR446WindowPresenterInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:83:        var presenter: KeyguardR446WindowPresenter? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:97:            KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:98:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r446-composition", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:99:            val profile = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:190:            val target = KeyguardR446Target(hostId, 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:191:                KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:281:            KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:35:class KeyguardR447HandoffServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:69:                try { result.set(owner.startR446PrintCapture("r447-fixture", "debug", "FULL")) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:112:                override fun r447ControlledSampleTopology() = true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:121:                override fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:122:                    eligibility: KeyguardR446Eligibility?, stale: Boolean) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:134:                override fun r447PresenterInvoked(request: Long) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:144:            waitFor("sampler idle") { main { owner.r447SamplerIdleForTest() } }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:145:            main { owner.r447ScheduleOutputReadyForTest() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:147:            val order = main { owner.r447SampleOrderForTest(first.get()) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:149:            assertEquals("NOT REACHED: proven internal offer", KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE, order.origin)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:157:                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:167:                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:172:                    File(out, "r447-controlled-sample.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:180:                runCatching { File(out, "r447-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:183:            File(out, "r447-evidence.txt").writeText(synchronized(note) { note.toString() } +
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:26:class KeyguardR44LazyProviderInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:144:                if (node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) return AccessibilityNodeInfo.obtain(node)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:162:                assertNull(node.extras.getCharSequence(KeyguardR44Markers.EXTRA))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:164:                val beforeIdentity = try { KeyguardR443ParentIdentity.of(beforeParent) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:167:                assertTrue(node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:168:                assertEquals("element:lockscreen", node.extras.getCharSequence(KeyguardR44Markers.EXTRA).toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:171:                val afterIdentity = try { KeyguardR443ParentIdentity.of(afterParent) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:200:                    availableExtraData = listOf(KeyguardR44Markers.EXTRA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:205:                if (virtualViewId == 1 && extraDataKey == KeyguardR44Markers.EXTRA && arguments != null) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:37:class KeyguardR44ServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:94:        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:95:        val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:96:        val proof = KeyguardR44WindowEvidence(true, true, host, entry, true, true, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:121:            assertTrue("NOT REACHED: unlocked synthetic trial", main { owner.setR44SyntheticTrial(true) })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:122:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:125:                    checkNotNull(KeyguardR44Trial.profile(null)), discloseFull = false).also { it.calibrate() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:146:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:281:                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:296:                out.resolve("r44-partial-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardRecoveryAdmissionInstrumentationTest.kt:291:            captureId = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")["captureId"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardRecoveryAdmissionInstrumentationTest.kt:684:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:158:        val mainIds = @Suppress("UNCHECKED_CAST") (KeyguardSurfaceClassifier::class.java
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:180:                val unmasked = KeyguardSurfaceClassifier.classifyDetailed(actual)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:184:                val synthetic = KeyguardSurfaceClassifier.classifyDetailed(masked)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:221:                            .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:250:                        .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:299:            val capture = KeyguardCardDiagnostics.startCapture(context, appSha, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:397:            if (captureStarted) runCatching { File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:592:            val startedCapture = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:702:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:814:            val started = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:838:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:920:            val started = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1141:                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1232:            val capture = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1298:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:34:import com.fluvi.app.lockscreen.KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:126:            KeyguardInspectionFreshness.Ticket(owner, 1, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:388:        KeyguardCardDiagnostics.startCapture(context, "r12-panel-control", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:972:            KeyguardCardDiagnostics.startCapture(activity, "r10-panel", "debug", "FULL")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:65:        KeyguardR444ProfileOwner(AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:84:    private val r445WakeBudget = KeyguardR445WakeBudget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:263:    internal fun r447ScheduleOutputReadyForTest() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:264:        check(KeyguardR447TestHooks.CONTROLLED_TOPOLOGY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:267:    internal fun r447SampleOrderForTest(request: Long): KeyguardFirstAuthorizedOrb.SampleOrder = synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:270:    internal fun r447SamplerIdleForTest(): Boolean = !systemSampler.hasOutstandingWork()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:303:    internal fun setR44SyntheticTrial(enabled: Boolean, expanded: Boolean = false): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:312:        if (enabled && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:313:            ((expanded && current.kind == KeyguardR444ProfileOwner.Kind.EXPANDED) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:314:                (!expanded && current.kind in setOf(KeyguardR444ProfileOwner.Kind.STANDARD,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:315:                    KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED)))) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:327:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:331:        KeyguardR44Trial.set(true, r442Lookup.verified)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:336:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:349:        val active = KeyguardR44Trial.active || r444ProfileOwner.snapshot.kind != KeyguardR444ProfileOwner.Kind.INACTIVE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:363:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:402:        if (previousReceipt != null && KeyguardR44Trial.active && !stopR444Trial("captureReplaced"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:421:            if (!setR44SyntheticTrial(true, expanded) || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:422:                KeyguardR44Trial.profile(null) == null || KeyguardR44Trial.settings(settings).showFinancialDetails ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:430:                KeyguardCardDiagnostics.startCapture(applicationContext, build, buildMode, captureMode, false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:438:                KeyguardCardDiagnostics.currentProcessInstanceId() != expectedProcess || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:455:            if (!accepted && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:472:            KeyguardR444ProfileOwner.Kind.EXPANDED, KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED -> included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:473:            KeyguardR444ProfileOwner.Kind.STANDARD -> !included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:479:                KeyguardCardDiagnostics.activeCaptureId() != receipt.capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:481:            if (KeyguardR44Trial.active) stopR444Trial("serviceOrCaptureChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:492:                KeyguardR446PrintOwner.State.WAIT_OFF, KeyguardR446PrintOwner.State.WAIT_WAKE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:493:                KeyguardR446PrintOwner.State.WAIT_READ, KeyguardR446PrintOwner.State.ISSUED)),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:500:    private val r446Owner = KeyguardR446PrintOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:501:    @Volatile private var r446ReadArm: KeyguardR446PrintOwner.Arm? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:509:    private var r447SystemBarrier = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:510:    private var r447SystemSatisfied = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:511:    private var r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:512:    private var r446Presenter: KeyguardR446WindowPresenter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:514:    private var r446Observation: KeyguardR446Observation? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:517:    internal fun r446PreparePresenterForInstrumentation(timeSource: KeyguardMaterialTimeSource): KeyguardR446WindowPresenter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:519:        return KeyguardR446WindowPresenter(this, timeSource).also { r446Presenter = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:530:            val sample = KeyguardR44Trial.profile(null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:537:                KeyguardCardDiagnostics.activeCaptureId() != capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:542:            val presenter = KeyguardR446WindowPresenter(this)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:553:                !KeyguardR44Trial.active || getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked != false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:560:            r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:586:            KeyguardCardDiagnostics.recordR447ArmTerminal(cancelledArm.capture, cancelledArm.generation, at, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:593:            KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:599:                val terminal = KeyguardR446Observation(context, r446ArmAt, context.originWakeEpoch, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:603:                KeyguardCardDiagnostics.recordR446(terminal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:608:    private fun r447RecordWakeArm() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:614:        val armed = r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && arm != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:616:        KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, if (armed) r446ArmAt else 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:623:        val disposition: KeyguardR447Disposition, val order: KeyguardFirstAuthorizedOrb.SampleOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:624:        val systemBarrier: Long, val ownerState: String, val ticket: KeyguardR446PrintOwner.Ticket?, val at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:634:        val stamp = inspection.r447Stamp
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:635:        val ordinal = ++r447DecisionOrdinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:648:                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ -> KeyguardR447Disposition.ARM_MISMATCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:649:                !authorityIsCurrent(request) || inspection.abortedStale -> KeyguardR447Disposition.STALE_AUTHORITY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:650:                disposition == CompletedDisposition.R32_RESTRICTION_ONLY -> KeyguardR447Disposition.RESTRICTION_ONLY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:652:                    KeyguardR447Disposition.RESTRICTION_OBSERVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:653:                target == null -> KeyguardR447Disposition.TARGET_MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:655:                    stamp.target != target || stamp.scene != scene -> KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:656:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED -> KeyguardR447Disposition.SCENE_CHANGED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:657:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED -> KeyguardR447Disposition.NEWER_COMPLETED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:658:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED || stamp.barrier > request.id ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:659:                    KeyguardR447Disposition.NEWER_BARRIER_REQUIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:661:                    stamp.systemBarrier != stamp.systemSatisfied || stamp.systemBarrier != r447SystemBarrier ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:662:                    r447SystemBarrier != r447SystemSatisfied || currentSystem?.eligible != true ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:663:                    KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:664:                presenter == null -> KeyguardR447Disposition.PRESENTER_UNAVAILABLE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:673:            R447Decision(reject ?: if (ticket == null) KeyguardR447Disposition.ISSUE_REJECTED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:674:                else KeyguardR447Disposition.ISSUED, order, r447SystemBarrier, state, ticket, decidedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:676:        var observation = KeyguardR446Observation(context, r446ArmAt, request.wakeGeneration, request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:686:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:691:            observation = observation.copy(handoff = KeyguardR447Disposition.SETTINGS_UNAVAILABLE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:693:            KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:702:        fun stillOwned(): Boolean = !r446RestrictionSeen && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:708:                    stamp.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:713:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:714:        runCatching { inspectionProbeForTest?.r447PresenterInvoked(request.id) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:721:                KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:727:            KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:733:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:818:                                KeyguardWindowSnapshotReader.Request(knownOwnOverlayIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:826:                            val classification = KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:959:        var firstProof: KeyguardFirstAuthorizedOrb.Proof? = null // Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:988:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1052:    private val inspectionFreshness = KeyguardInspectionFreshness()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1057:        KeyguardWindowSnapshotReader(this, packageName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1117:                r447Duplicate = null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1462:        val previous: KeyguardFirstAuthorizedOrb.Proof?
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1655:        if (KeyguardCardVisibilityPolicy.decide(signalsFromSystemState(settings, KeyguardSurface.MAIN_KEYGUARD, system)) !=
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2243:                    if (r446Owner.state == KeyguardR446PrintOwner.State.WAIT_OFF) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2273:                    r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2291:            if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) r446Cancel("displayChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2316:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2571:        if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2583:        if (KeyguardR441RestrictionIngress.mustWithdraw(Build.VERSION.SDK_INT, meta, own,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2977:        if (r442ScreenOn?.session == session.get()) r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3060:                r447SystemBarrier == r447SystemSatisfied) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3061:                KeyguardR447DuplicateProof(inspectionAuthority, scene, revision, active.id, order.required,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3062:                    order.barrier, r447SystemBarrier, arm.generation, readAheadStateRevision, r18RouteRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3064:            if (proof == null && r446CaptureId != null) r447SystemBarrier += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3065:            r447SystemBarrier to proof
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3072:            r447SystemBarrier = sampleBarrier, r447Duplicate = duplicate))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3084:            if (r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3085:                r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) r446Cancel("systemGate")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3095:            if (request.r447SystemBarrier == r447SystemBarrier && request.authority == inspectionAuthority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3096:                r447SystemSatisfied = request.r447SystemBarrier
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3115:            sampleDuplicate = request.r447Duplicate)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3247:        freshness: KeyguardWindowFreshness, sampleDuplicate: KeyguardR447DuplicateProof?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3265:        sampleDuplicate: KeyguardR447DuplicateProof? = null): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3312:                    sampleDuplicate.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3320:                KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE else KeyguardFirstAuthorizedOrb.SampleOffer.BARRIER)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3559:            inspectSurface(request, started, r38MilestoneOrdered, r40Read).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3599:                    KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3644:        runCatching { inspectionProbeForTest?.r447SampleReadCompleted(request, inspection.r446Eligibility, inspection.abortedStale) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4543:        timing: KeyguardWindowSnapshotReader.Timing? = null, result: Inspection? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4720:        val arm: KeyguardR446PrintOwner.Arm, val request: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4723:        val systemSatisfied: Long, val inventoryAt: Long, val target: KeyguardR446Target? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4738:        val windowTiming: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4746:        val r446Arm: KeyguardR446PrintOwner.Arm? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4747:        val r446Eligibility: KeyguardR446Eligibility? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4749:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4772:        val timing: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4785:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4823:        fun snapshot(treeElapsedMs: Long): KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4844:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4853:            return InspectionOutcome.Completed(Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4871:        val r44Mode = Build.VERSION.SDK_INT == 37 && settings.presentationMode == KeyguardCardPresentationMode.ORB
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4872:        val syntheticAtRead = r44Mode && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4881:        val read = readSystemWindows(request, startedAt, r38MilestoneOrdered, r40Read, lookupAtRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4888:            if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4912:        val classification = if (r44Mode) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4913:            KeyguardR44SurfaceClassifier.classify(snapshots, read.rootUnavailable, read.walkTruncated,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4915:        } else KeyguardSurfaceClassifier.classifyDetailed(snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4918:        if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, false, classification,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4922:        val controlledSample = printArm != null && KeyguardR447TestHooks.CONTROLLED_TOPOLOGY &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4923:            inspectionProbeForTest?.r447ControlledSampleTopology() == true &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4927:            KeyguardR446PrintPolicy.evaluate(if (controlledSample) snapshots else read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4930:        val printNormal = if (printArm != null) KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4935:            KeyguardCardVisibilityPolicy.decide(signals),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4954:            r447Stamp = read.r447Stamp?.copy(target = printEligibility?.target),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4958:    private fun recordR44Read(request: KeyguardCardInspectionRequest, read: SystemWindowsRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4964:                              profile: KeyguardR444ProfileOwner.Snapshot? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4971:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4974:        val shadow = if (stale) null else KeyguardR44SurfaceClassifier.classify(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4989:        fun describe(w: KeyguardWindowSnapshot): KeyguardR444WindowObservation {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4997:            return KeyguardR444WindowObservation(w.windowId, w.layer - (host?.layer ?: w.layer),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5005:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5018:            windows.mapNotNull { w -> w.r44?.let { e -> KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5051:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5057:    private fun readSystemWindows(request: KeyguardCardInspectionRequest, startedAt: Long, r38MilestoneOrdered: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5059:                                  profileAtRead: KeyguardR444ProfileOwner.Snapshot?, printAtRead: KeyguardR446PrintOwner.Arm?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5104:                KeyguardR442YieldPolicy.permits(Build.VERSION.SDK_INT, r442Enabled, screen?.uptime,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5113:        var r447Stamp: R447InventoryStamp? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5128:            request = KeyguardWindowSnapshotReader.Request(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5131:                r44Enabled = Build.VERSION.SDK_INT == 37 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5133:                r44DeviceEntryResourceVerified = lookup.verified,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5149:                            !KeyguardR44Trial.active || r444ProfileOwner.snapshot.revision != profileAtRead?.revision) null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5243:                            r447Stamp = R447InventoryStamp(printAtRead, request.id, inspectionAuthority, scene,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5244:                                freshness?.revision, order.barrier, r447SystemBarrier, r447SystemSatisfied,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5402:            if (owner != null) KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5435:            r447Stamp = r447Stamp,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5444:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5700:            if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5707:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5708:        var decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5718:            decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5723:            traceKeyguard("INSPECTION_REJECTED", "r44SceneChanged", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5724:                fields = mapOf("rejectionReason" to "r44SceneChanged"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5725:            requestSystemCheck("r44SceneChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6095:        if (!r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6143:        if (!r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6177:        if (!r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6336:        if (KeyguardR44Trial.active && presentation.full) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7284:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardEventGate.kt:45:internal object KeyguardR441RestrictionIngress {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:108:    fun r447ControlledSampleTopology(): Boolean = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:109:    fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest, eligibility: KeyguardR446Eligibility?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:111:    fun r447PresenterInvoked(request: Long) {}
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:492:        val r44Dropped = AtomicLong()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:790:        val r44Reads: ArrayDeque<KeyguardR44ReadObservation> = ArrayDeque(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:791:        var r44Last: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:792:        var r44FirstPostScreen: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:793:        var r44FirstGrant: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:794:        var r44FirstRestriction: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:795:        var r44ReadsOmitted: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:796:        var r442Handoff: KeyguardR442HandoffObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:797:        var r443Boundary: KeyguardR443BoundaryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:798:        var r446: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:799:        var r446Last: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:800:        var r447FirstEligible: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:801:        var r447Best: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:802:        var r447FirstTerminal: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:803:        var r447Arm: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:804:        var r447ArmGeneration: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:805:        var r447LatestOrdinal: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:806:        var r447DecisionCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:969:        var r44Dropped: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:970:        var r447ArmTerminal: R447ArmTerminal? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1456:    fun startCapture(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1522:    fun freezeCapture(context: Context): Map<String, Any?> = reduction.read {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1693:    internal fun recordR44(observation: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1705:                    token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1708:                if (attempt.r44Reads.any { it.request == observation.request }) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1711:                    (attempt.r44FirstPostScreen == null || observation.start < attempt.r44FirstPostScreen!!.start))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1712:                    attempt.r44FirstPostScreen = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1714:                    observation.verdict == KeyguardSurface.MAIN_KEYGUARD && attempt.r44FirstGrant == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1715:                    attempt.r44FirstGrant = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1718:                    attempt.r44FirstRestriction == null) attempt.r44FirstRestriction = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1719:                if (attempt.r44Reads.size < 12) attempt.r44Reads.addLast(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1720:                else { attempt.r44ReadsOmitted += 1; attempt.r44Last = observation }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1723:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1726:    internal fun recordR446(observation: KeyguardR446Observation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1737:                    if (observation.armGeneration > 0 && attempt.r447ArmGeneration > 0 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1738:                        observation.armGeneration != attempt.r447ArmGeneration) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1739:                    if (observation.armGeneration > 0) attempt.r447ArmGeneration = observation.armGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1741:                        if (attempt.r447Arm == null || (attempt.r447Arm?.wakeArmState != "ARMED" &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1742:                                observation.wakeArmState == "ARMED")) attempt.r447Arm = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1743:                        if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1744:                            attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1749:                    if (observation.eligibility == "ELIGIBLE_SAMPLE" && attempt.r447FirstEligible == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1750:                        attempt.r447FirstEligible = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1752:                    if (ordinal > attempt.r447LatestOrdinal) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1753:                        attempt.r447LatestOrdinal = ordinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1754:                        attempt.r447DecisionCount = (attempt.r447DecisionCount + 1).coerceAtMost(9999)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1756:                    } else if (ordinal == attempt.r447LatestOrdinal &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1758:                    fun progress(o: KeyguardR446Observation): Int = when {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1765:                    val best = attempt.r447Best
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1768:                        attempt.r447Best = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1769:                    if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1770:                        attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1774:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1779:    internal fun recordR447ArmTerminal(captureId: String, generation: Long, at: Long, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1785:                if (active.r447ArmTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1786:                    active.r447ArmTerminal = R447ArmTerminal(generation, at, technicalValue(reason).take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1789:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1792:    internal fun recordR442Handoff(observation: KeyguardR442HandoffObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1806:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1809:    internal fun recordR443Boundary(observation: KeyguardR443BoundaryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1823:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2824:            val report = formatReport(snapshot, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3024:        r44Dropped = r41Token?.r44Dropped?.get() ?: active.r44Dropped,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3033:        r44Reads = ArrayDeque(attempt.r44Reads),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3089:        val report = formatReport(active, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3133:    private fun formatReport(active: TimingCapture, recoveredFromDisk: Boolean, exportLimitBytes: Int): String {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3149:            if (Build.VERSION.SDK_INT == 37) appendLine("R44_CAPTURE dropped=${active.r44Dropped} physicalPixels=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3268:        active.r447ArmTerminal?.let { terminal ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3269:            select("r447:armTerminal", "R44_7_ARM generation=${terminal.generation} terminal=${terminal.at}/${terminal.reason} clock=uptimeMs\n")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3271:        val r44Attempts = (listOfNotNull(active.firstAttempt) + active.attempts).distinctBy { it.id }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3273:        r44Attempts.forEach { attempt ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3277:                    val armState = attempt.r447Arm?.wakeArmState ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3283:                    val terminal = attempt.r447FirstTerminal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3284:                    select("a${attempt.id}:r446", "R44_6_HU $message\nR44_6_SAMPLE wake=${attempt.wakeEpoch} arm=UNOBSERVED firstReq=UNOBSERVED firstNormal=UNOBSERVED firstEligible=UNOBSERVED firstBackend=NOT_ATTEMPTED req=UNOBSERVED normal=UNOBSERVED eligible=UNOBSERVED backend=NOT_ATTEMPTED host=UNOBSERVED scene=UNOBSERVED issue=UNOBSERVED attachBegin=UNOBSERVED attachEnd=UNOBSERVED submit=UNOBSERVED frame=UNOBSERVED withdraw=${terminal?.withdrawAt ?: "UNOBSERVED"}/${terminal?.withdrawReason ?: "UNOBSERVED"} hideReturn=${terminal?.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal?.releaseReturn ?: "UNOBSERVED"} retireError=${terminal?.retireError ?: "none"} armState=$armState physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3289:            val p = attempt.r447Best ?: o
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3290:            val terminal = attempt.r447FirstTerminal ?: p
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3298:            select("a${attempt.id}:r446", "R44_6_HU $status\nR44_6_SAMPLE wake=${o.wake} arm=${o.armAt} firstReq=${first.request} firstNormal=${first.normal} firstEligible=${first.eligibility} firstBackend=${first.backend} req=${o.request} normal=${o.normal} eligible=${o.eligibility} backend=${o.backend} host=${o.host ?: "UNOBSERVED"} scene=${o.scene ?: "UNOBSERVED"} issue=${p.issuedAt ?: "UNOBSERVED"} attachBegin=${p.attachBegin ?: "UNOBSERVED"} attachEnd=${p.attachEnd ?: "UNOBSERVED"} submit=${p.submittedAt ?: "UNOBSERVED"} frame=${p.frameAt ?: "UNOBSERVED"} withdraw=${terminal.withdrawAt ?: "UNOBSERVED"}/${terminal.withdrawReason} hideReturn=${terminal.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal.releaseReturn ?: "UNOBSERVED"} retireError=${terminal.retireError ?: "none"} firstEligibleReq=${attempt.r447FirstEligible?.request ?: "UNOBSERVED"} firstEligibleHandoff=${attempt.r447FirstEligible?.handoff ?: "UNOBSERVED"} firstHandoff=${first.handoff} progressReq=${p.request} terminalReq=${if (terminal.withdrawAt != null) terminal.request else "UNOBSERVED"} decisions=${attempt.r447DecisionCount} ordinal=${o.decisionOrdinal} handoff=${o.handoff} order=${o.order?.result ?: "UNOBSERVED"} completed=${o.order?.completed ?: "UNOBSERVED"} required=${o.order?.required ?: "UNOBSERVED"} barrier=${o.order?.barrier ?: "UNOBSERVED"} origin=${o.order?.origin ?: "UNOBSERVED"} sceneNow=${o.order?.scene ?: "UNOBSERVED"} inventory=${o.inventoryAt ?: "UNOBSERVED"} readEnd=${o.readFinishedAt ?: "UNOBSERVED"} mainEntry=${o.mainEnteredAt ?: "UNOBSERVED"} decide=${o.decisionAt ?: "UNOBSERVED"} freshness=${o.freshnessRevision ?: "UNOBSERVED"} sysAtRead=${o.systemBarrierAtRead ?: "UNOBSERVED"} sysNow=${o.systemBarrierAtDecision ?: "UNOBSERVED"} owner=${o.ownerState} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3300:        r44Attempts.filter { it.r44Reads.isNotEmpty() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3302:            select("a${attempt.id}:r44Core", r44Record(active.id, attempt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3655:            selected.filterKeys { it.endsWith(":r44Core") }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3661:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":r44Core") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3675:    private fun r44Record(captureId: String, attempt: TimingAttempt, trialRequested: Boolean): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3676:        val reads = attempt.r44Reads.toList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3678:        val post = attempt.r44FirstPostScreen ?: screen?.let { t -> reads.filter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3681:        val last = attempt.r44Last ?: reads.lastOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3686:        appendLine("R44_HU próba=${attempt.id} eredmény=$outcome első_ébredés_utáni_olvasás=${post?.request ?: "HIÁNYZIK"} fizikailag_látható=ISMERETLEN")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3687:        if (!trialRequested) appendLine("R44_2_HU A mintaorb-próba nem volt elindítva; ez csak rögzítés.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3689:            appendLine("R44_2_HU FIGYELEM: a mintaorb-próba visszaigazolása vagy üzemmódja elveszett.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3691:        appendLine("R44_2_TRIAL requested=$trialRequested receipt=${post?.receipt ?: "UNOBSERVED"} domain=$domain")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3699:            post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Az elfogadott jel mellett egy másik ablak kizárja a megjelenítést."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3700:            post.reason == KeyguardSurfaceReason.NO_MAIN_MARKER || post.appliedGate == KeyguardR444Gate.NO_CONTENT ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3708:        appendLine("R44_4_HU próba=${attempt.id} $reasonHu" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3709:            if (additionalWindow && post?.appliedGate != KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3714:                post.appliedGate == KeyguardR444Gate.RESTRICTION -> "Tiltott képernyő: rejtve."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3716:                post.appliedGate == KeyguardR444Gate.COVER_VETO && companion ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3718:                post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Jel megvan; a felső ablak nem minősíthető."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3723:            appendLine("R44_5_HU próba=${attempt.id} $status")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3727:            listOfNotNull(post, attempt.r44FirstGrant, attempt.r44FirstRestriction, last)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3730:        appendLine("R44_2_HANDOFF old=${handoff?.oldRequest ?: "UNOBSERVED"} next=${handoff?.nextRequest ?: "UNOBSERVED"} screen=${handoff?.screenAt ?: "UNOBSERVED"} offer=${handoff?.offerAt ?: "UNOBSERVED"} oldStart=${handoff?.oldStart ?: "UNOBSERVED"} boundary=${handoff?.boundaryAt ?: "UNOBSERVED"} oldReturn=${handoff?.oldReturn ?: "UNOBSERVED"} where=${handoff?.boundary ?: "UNOBSERVED"} newStart=${successorRead?.start ?: "UNOBSERVED"} newEnd=${successorRead?.end ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3732:        appendLine("R44_3_BOUNDARY old=${boundary?.oldRequest ?: "UNOBSERVED"} pending=${boundary?.pendingRequest ?: "UNOBSERVED"} screen=${boundary?.screenAt ?: "UNOBSERVED"} offer=${boundary?.offerAt ?: "UNOBSERVED"} oldStart=${boundary?.oldStart ?: "UNOBSERVED"} at=${boundary?.boundaryAt ?: "UNOBSERVED"} oldEnd=${boundary?.oldEnd ?: "UNOBSERVED"} reason=${boundary?.reason ?: "UNOBSERVED"} ingress=${boundary?.ingressKind ?: "UNOBSERVED"}/${boundary?.ingressStart ?: "UNOBSERVED"}/${boundary?.ingressEnd ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3733:        appendLine("R44_WAKE capture=$captureId session=${attempt.serviceSession} wake=${attempt.wakeEpoch} screenOn=${screen ?: "UNOBSERVED"} firstPostRead=${post?.request ?: "missing"} omitted=${attempt.r44ReadsOmitted} showRequest=${show?.requestId ?: "none"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3734:        fun line(kind: String, read: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3738:                appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} start=${read.start} end=${read.end} verdict=${read.verdict} reason=${read.reason} stale=${read.stale}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3741:            appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} epoch=${read.epoch} scene=${read.scene ?: "UNOBSERVED"} start=${read.start} end=${read.end} owner=${if (read.hostVerified) "verified" else "rejected"} hostWin=${read.hostWindow ?: "UNOBSERVED"} hostLayer=${read.hostLayer ?: "UNOBSERVED"} complete=${read.coverageComplete} legacy=${read.legacy} host=${host?.marker ?: "none"}/${host?.carrier ?: "none"} content=${content?.marker ?: "none"}/${content?.carrier ?: "none"} relation=${if (read.relation) "descendant" else "unknown"} extra=${read.advertised}/${read.fetched}/${read.failed} unsupported=${read.unsupported} budgetHit=${read.budgetHit} extraMs=${read.extraMs} stale=${read.stale} unavailable=${read.unavailable} truncated=${read.truncated}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3746:                appendLine("R44_3_ABLAK req=${read.request} window:advertised/fetched/overflow:state=$windowSummary")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3748:                    appendLine("R44_3_JEL req=${read.request} window=${c.window} ordinal=${c.ordinal} branch=${c.branch} rank=${c.rank} status=${c.status} role=${c.role} costMs=${c.costMs} remaining=${c.remaining} remainingMs=${c.remainingMs} parentChecks=${c.parentChecks} parentMs=${c.parentMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3752:                KeyguardR444Gate.COVER_VETO -> "VETO"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3753:                KeyguardR444Gate.ACCEPTED -> "CLEAR"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3756:            appendLine("R44_4_PROFILE req=${read.request} profile=${read.profile} revision=${read.profileRevision ?: "UNOBSERVED"} previousFlags=${read.previousFlags ?: "UNOBSERVED"} actualFlags=${read.actualFlags ?: "UNOBSERVED"} clockResource=${read.clockResourceVerified} hostNodes=${read.hostNodes} hostCarriers=${read.hostCarriers} hostParent=${read.hostParent ?: "UNOBSERVED"} contentParent=${read.contentParent ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3757:            appendLine("R44_4_GATE req=${read.request} applied=${read.appliedGate} coverReached=$coverReached structural=${read.cover} secondary=${read.secondaryCount} overflow=${read.secondaryOverflow}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3759:            appendLine("R44_5_INDEX req=${read.request} installedSmall=${read.r445SmallInstalled} installedLarge=${read.r445LargeInstalled} installedEntry=${read.r445EntryInstalled} status=${read.r445IndexStatus} backend=$backend pixel=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3761:                appendLine("R44_5_ID req=${read.request} role=${call.role} outcome=${call.outcome} hitsCap9=${call.rawHits} reject=${call.firstRejection} durationMs=${call.durationMs} ageMs=${call.ageMs} overrunMs=${call.overrunMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3764:                appendLine("R44_4_WINDOW req=${read.request} id=${w.id} relativeLayer=${w.relativeLayer} type=${w.type} active=${w.active ?: "UNOBSERVED"} focused=${w.focused ?: "UNOBSERVED"} owner=${w.owner} ownGen=${w.ownGeneration ?: "UNOBSERVED"} verified=${w.verifiedRoot} visited=${w.visited ?: "UNOBSERVED"} root=${w.rootRole}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3766:            appendLine("R44_DECISION wake=${attempt.wakeEpoch} req=${read.request} mode=${if (read.synthetic) "syntheticTrial" else "normal"} testProbeInjected=${read.testProbeInjected} verdict=${read.verdict} reason=${read.reason}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3767:            appendLine("R44_2_EVIDENCE req=${read.request} lookup=${read.lookupStatus} lookupIdentity=${read.lookupIdentity ?: "UNOBSERVED"} rawHost=${read.rawHost} rawEntry=${read.rawEntry} rawClock=${read.rawClock} candidate=${read.firstCandidate ?: "none"}/${read.firstCarrier ?: "none"} rejectUnverified=${read.rejectedUnverified} rejectAncestry=${read.rejectedAncestry} rejectExcluded=${read.rejectedExcluded} rejectForeign=${read.rejectedForeign} rejectHidden=${read.rejectedHidden} cover=${read.cover} shadow=${read.shadowVerdict ?: "UNOBSERVED"}/${read.shadowReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3772:        fun unique(kind: String, read: KeyguardR44ReadObservation?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3775:        unique("firstMainClassification", attempt.r44FirstGrant)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3776:        unique("firstRestrictionClassification", attempt.r44FirstRestriction)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3779:        appendLine("R44_END wake=${attempt.wakeEpoch} last=${attempt.finalState} grant=${show?.decisionAtUptimeMs ?: "UNOBSERVED"} attach=${show?.addReturnAtUptimeMs ?: "UNOBSERVED"} post=${show?.r12Evidence?.get("firstPost") ?: "UNOBSERVED"} postDelivery=${show?.r12Evidence?.get("firstPostMain") ?: "UNOBSERVED"} ack=${show?.r11Evidence?.get("ack") ?: "UNOBSERVED"} remove=${hide?.removeReturnAtUptimeMs ?: "UNOBSERVED"} physicalPixels=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:27:internal enum class KeyguardR444Gate { UNOBSERVED, RESTRICTION, INCOMPLETE, NO_HOST, NO_CONTENT, INVALID_PAIR, COVER_VETO, ACCEPTED, LEGACY }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:34:    val r444Gate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:55:    val r44: KeyguardR44WindowEvidence? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:62:    val r446Bounds: KeyguardR446Bounds? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:65:internal object KeyguardSurfaceClassifier {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:200:internal object KeyguardCardVisibilityPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:430:        val settings = KeyguardR44Trial.settings(requestedSettings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:431:        val profile = KeyguardR44Trial.profile(requestedProfile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:457:        return !isAttached && root != null && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:458:            materialProfile === KeyguardR44Trial.profile(null) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:469:        val intent = KeyguardFirstAuthorizedOrb.intent(materialSettings.showFinancialDetails)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:470:        val wantsFull = full ?: (intent == KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:616:        if (KeyguardR44Trial.active && (presentation.full || materialProfile !== KeyguardR44Trial.profile(null)))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1028:        val profile = KeyguardR44Trial.profile(requestedProfile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1029:        val settings = KeyguardR44Trial.settings(requestedSettings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAcquisition.kt:24:        ticket: KeyguardInspectionFreshness.Ticket?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshness.kt:8:internal class KeyguardInspectionFreshness {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGate.kt:86:        if (KeyguardSurfaceClassifier.isMainMarker(id)) main = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGate.kt:87:        if (KeyguardSurfaceClassifier.isClockMarker(id)) clock = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR43SurfaceEvidence.kt:78:            if (snapshot != null) window.markers = KeyguardSurfaceClassifier.classifyDetailed(listOf(snapshot)).markers
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicy.kt:4:internal object KeyguardR442YieldPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:12:internal object KeyguardR443ParentIdentity {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:32:internal class KeyguardR443Inventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:33:    private val budget: KeyguardR44ExtraBudget,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:37:        val owner: KeyguardR44TreeReader,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:49:    fun collect(owner: KeyguardR44TreeReader, node: AccessibilityNodeInfo,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:65:                else KeyguardR443ParentIdentity.of(currentParent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:87:    fun resolve(canExtend: (KeyguardR44TreeReader) -> Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwner.kt:10:internal class KeyguardR444ProfileOwner(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR445WakeBudget.kt:5:internal class KeyguardR445WakeBudget {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:7:internal data class KeyguardR446Bounds(val left: Int, val top: Int, val right: Int, val bottom: Int) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:16:internal data class KeyguardR446Target(val windowId: Int, val displayId: Int, val bounds: KeyguardR446Bounds)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:17:internal data class KeyguardR446Eligibility(val target: KeyguardR446Target?, val reason: String)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:20:internal enum class KeyguardR447Disposition {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:27:internal object KeyguardR446PrintPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:31:    ): KeyguardR446Eligibility {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:32:        fun denied(reason: String) = KeyguardR446Eligibility(null, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:34:            classification.r444Gate == KeyguardR444Gate.RESTRICTION) return denied("RESTRICTION")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:35:        if (unavailable || truncated || classification.r444Gate == KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:41:                classification.r444Gate in setOf(KeyguardR444Gate.NO_CONTENT, KeyguardR444Gate.NO_HOST,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:42:                    KeyguardR444Gate.COVER_VETO))) return denied("UNKNOWN_SCENE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:57:        return KeyguardR446Eligibility(KeyguardR446Target(host.windowId, host.displayId, bounds), "ELIGIBLE_SAMPLE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:63:internal class KeyguardR446PrintOwner {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:67:                      val target: KeyguardR446Target, val deadline: Long)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:86:              target: KeyguardR446Target, now: Long): Ticket? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:26:internal class KeyguardR446WindowPresenter(private val service: AccessibilityService,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:107:    fun show(token: Any, target: KeyguardR446Target, geometry: KeyguardOverlayGeometry,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:4:internal data class KeyguardR445IndexCall(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:12:internal data class KeyguardR446Observation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:20:    val handoff: KeyguardR447Disposition = KeyguardR447Disposition.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:21:    val order: KeyguardFirstAuthorizedOrb.SampleOrder? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:30:    fun retireOnce(at: Long, reason: String, hide: Long?, release: Long?, error: String?): KeyguardR446Observation =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:37:internal data class KeyguardR443CandidateObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:42:internal data class KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:47:internal data class KeyguardR444WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:53:internal data class KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:71:    val host: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:72:    val content: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:93:    val firstCandidate: KeyguardR44Markers.Marker? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:94:    val firstCarrier: KeyguardR44Markers.Carrier? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:97:    val r443Windows: List<KeyguardR443WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:98:    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:99:    val appliedGate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:106:    val r444Windows: List<KeyguardR444WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:109:    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:112:internal data class KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:125:internal data class KeyguardR443BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:7:internal object KeyguardR44Markers {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:41:internal data class KeyguardR44Witness(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:42:    val marker: KeyguardR44Markers.Marker,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:43:    val carrier: KeyguardR44Markers.Carrier,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:47:internal data class KeyguardR44WindowEvidence(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:50:    val host: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:51:    val content: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:71:    val firstCandidate: KeyguardR44Markers.Marker? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:72:    val firstCarrier: KeyguardR44Markers.Carrier? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:74:    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:81:    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:84:internal object KeyguardR44SurfaceClassifier {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:95:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:102:        val r44Restrictions = systemIds.mapNotNull(KeyguardR44Markers::exact).toSet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:103:        if (KeyguardR44Markers.Marker.BOUNCER in r44Restrictions) return KeyguardSurfaceClassification(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:104:            KeyguardSurface.CREDENTIAL, KeyguardSurfaceReason.CREDENTIAL_MARKER, legacy.markers, KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:105:        if (KeyguardR44Markers.Marker.SHADE in r44Restrictions ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:106:            KeyguardR44Markers.Marker.QUICK_SETTINGS in r44Restrictions) return KeyguardSurfaceClassification(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:107:            KeyguardSurface.SHADE, KeyguardSurfaceReason.SHADE_MARKER, legacy.markers, KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:111:            legacy.surface == KeyguardSurface.OCCLUDED) return legacy.copy(r444Gate = KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:112:        if (unavailableRoot || walkTruncated) return legacy.copy(r444Gate = KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:116:            KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers, KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:121:                KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers, KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:131:                    KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers, KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:133:            return legacy.copy(r444Gate = KeyguardR444Gate.LEGACY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:135:        if (!syntheticTrial) return legacy.copy(r444Gate = KeyguardR444Gate.LEGACY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:143:        if (hosts.size != 1) return fallback.copy(r444Gate = KeyguardR444Gate.NO_HOST)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:146:        val content = evidence.content ?: return fallback.copy(r444Gate = KeyguardR444Gate.NO_CONTENT)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:148:            evidence.host?.ordinal == content.ordinal) return fallback.copy(r444Gate = KeyguardR444Gate.INVALID_PAIR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:149:        if (content.marker != KeyguardR44Markers.Marker.DEVICE_ENTRY &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:150:            content.marker != KeyguardR44Markers.Marker.LARGE_CLOCK &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:151:            content.marker != KeyguardR44Markers.Marker.SMALL_CLOCK &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:153:                content.marker == KeyguardR44Markers.Marker.CLOCK_SWITCH &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:154:                content.carrier == KeyguardR44Markers.Carrier.VIEW_ID))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:155:            return fallback.copy(r444Gate = KeyguardR444Gate.INVALID_PAIR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:160:                KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers, KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:163:            KeyguardSurfaceReason.MAIN_CONFIRMED, legacy.markers.copy(main = 1), KeyguardR444Gate.ACCEPTED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:8:internal class KeyguardR44ExtraBudget {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:30:internal class KeyguardR44TreeReader(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:35:    private val budget: KeyguardR44ExtraBudget,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:36:    private val deferred: KeyguardR443Inventory? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:44:    private var host: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:45:    private var content: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:67:    private var firstCandidate: KeyguardR44Markers.Marker? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:68:    private var firstCarrier: KeyguardR44Markers.Carrier? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:73:    private val facts = arrayOfNulls<MutableList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>>(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:82:    private var indexedContent: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:84:    private var indexedCalls: List<KeyguardR445IndexCall> = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:93:    private fun verifiedContent(marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:95:        KeyguardR44Markers.Marker.DEVICE_ENTRY -> genuineDeviceEntryResource && carrier == KeyguardR44Markers.Carrier.VIEW_ID
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:96:        KeyguardR44Markers.Marker.CLOCK_SWITCH -> expanded && genuineClockResource && carrier == KeyguardR44Markers.Carrier.VIEW_ID
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:97:        KeyguardR44Markers.Marker.SMALL_CLOCK -> !actualClockId || genuineSmallClockResource
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:98:        KeyguardR44Markers.Marker.LARGE_CLOCK -> !actualClockId || genuineLargeClockResource
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:123:            remainingMs = (KeyguardR44ExtraBudget.MAX_ELAPSED_MS - budget.elapsedMs).coerceAtLeast(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:155:    private fun addFact(ordinal: Int, marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:157:            val entries = facts[ordinal] ?: mutableListOf<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>().also { facts[ordinal] = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:179:                            parent.isVisibleToUser && KeyguardR443ParentIdentity.of(parent) == parentId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:197:        val refreshed = runCatching { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:206:        val value = runCatching { node.extras.getCharSequence(KeyguardR44Markers.EXTRA) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:211:        val marker = KeyguardR44Markers.exact(value)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:213:            candidateDone(ordinal, "READ", if (KeyguardR44Markers.unknownMayRestrict(value,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:222:        observe(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:223:        addFact(ordinal, marker, KeyguardR44Markers.Carrier.EXTRA_LAZY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:224:        if (marker == KeyguardR44Markers.Marker.HOST) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:227:                host = KeyguardR44Witness(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:232:        KeyguardR44Markers.exclusion(marker)?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:243:            !hasExcludedAncestor(ordinal) && facts[ordinal]?.any { it.first == KeyguardR44Markers.Marker.HOST } == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:248:            val item = facts[hostOrdinal]!!.first { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:249:            host = KeyguardR44Witness(item.first, item.second, hostOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:262:                it.first == KeyguardR44Markers.Marker.LARGE_CLOCK || it.first == KeyguardR44Markers.Marker.SMALL_CLOCK ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:263:                    it.first == KeyguardR44Markers.Marker.DEVICE_ENTRY || it.first == KeyguardR44Markers.Marker.CLOCK_SWITCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:268:                    item.second == KeyguardR44Markers.Carrier.VIEW_ID) -> rejectedUnverified++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:271:                    content = KeyguardR44Witness(item.first, item.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:279:    private fun observe(marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier, ordinal: Int = 0) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:280:        if (marker == KeyguardR44Markers.Marker.HOST && r444HostOrdinals != null && ordinal in 1 until r444HostOrdinals.size) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:285:            KeyguardR44Markers.Marker.HOST -> rawHost = (rawHost + 1).coerceAtMost(255)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:286:            KeyguardR44Markers.Marker.DEVICE_ENTRY -> rawEntry = (rawEntry + 1).coerceAtMost(255)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:287:            KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.Marker.SMALL_CLOCK,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:288:            KeyguardR44Markers.Marker.CLOCK_SWITCH ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:292:        if (firstCandidate == null && marker != KeyguardR44Markers.Marker.HOST) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:299:        val marker = KeyguardR44Markers.exact(viewId) ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:300:        observe(marker, KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:324:        val calls = ArrayList<KeyguardR445IndexCall>(3)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:328:            if (SystemClock.uptimeMillis() - batchStart >= KeyguardR44ExtraBudget.MAX_ELAPSED_MS) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:375:                                    val tag = current.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:384:                                            viewId != null && KeyguardSurfaceClassifier.isDecisiveExclusionMarker(viewId) -> viewId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:385:                                            KeyguardR44Markers.exact(tag)?.let(KeyguardR44Markers::exclusion) != null ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:386:                                                KeyguardR44Markers.exact(tag)?.let(KeyguardR44Markers::exclusion)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:392:                                            (tag != null && KeyguardR44Markers.exact(tag) == null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:393:                                                KeyguardR44Markers.unknownMayRestrict(tag, true))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:424:            calls += KeyguardR445IndexCall(role, outcome, returned - start,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:426:                (SystemClock.uptimeMillis() - batchStart - KeyguardR44ExtraBudget.MAX_ELAPSED_MS).coerceAtLeast(0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:442:                val marker = requireNotNull(KeyguardR44Markers.exact(id))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:443:                indexedContent = KeyguardR44Witness(marker, KeyguardR44Markers.Carrier.VIEW_ID, 97)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:484:            KeyguardR44Markers.exact(viewId)?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:485:                observe(it, KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:496:        val markers = ArrayList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>(2)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:497:        val directMarker = KeyguardR44Markers.exact(viewId)?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:498:            expanded || it != KeyguardR44Markers.Marker.CLOCK_SWITCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:500:        directMarker?.let { markers += it to KeyguardR44Markers.Carrier.VIEW_ID }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:502:            KeyguardR44Markers.unknownMayRestrict(viewId, ancestor != null)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:509:            val eager = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:510:            val eagerMarker = KeyguardR44Markers.exact(eager)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:511:            eagerMarker?.let { markers += it to KeyguardR44Markers.Carrier.EXTRA_EAGER }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:514:                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:517:                else if (KeyguardR44Markers.unknownMayRestrict(eager, nestedInHost)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:522:            val hasDirectTag = markers.any { it.second == KeyguardR44Markers.Carrier.VIEW_ID &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:523:                it.first != KeyguardR44Markers.Marker.DEVICE_ENTRY }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:525:            val knownRestriction = markers.any { KeyguardR44Markers.exclusion(it.first) != null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:532:                node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:549:                    val refreshed = try { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:570:                        val value = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:573:                            val marker = KeyguardR44Markers.exact(value)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:576:                                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:577:                                if (KeyguardR44Markers.unknownMayRestrict(value, nestedInHost)) complete = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:579:                            else markers += marker to KeyguardR44Markers.Carrier.EXTRA_LAZY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:588:        val exclusions = markers.mapNotNull { KeyguardR44Markers.exclusion(it.first) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:600:            if (marker == KeyguardR44Markers.Marker.DEVICE_ENTRY ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:601:                marker == KeyguardR44Markers.Marker.LARGE_CLOCK || marker == KeyguardR44Markers.Marker.SMALL_CLOCK ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:602:                marker == KeyguardR44Markers.Marker.CLOCK_SWITCH) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:605:                    !verifiedContent(marker, carrier, actualClockId && carrier == KeyguardR44Markers.Carrier.VIEW_ID) ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:614:            val nodeHost = markers.firstOrNull { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:618:                    host = KeyguardR44Witness(nodeHost.first, nodeHost.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:625:                verifiedContent(it.first, it.second, actualClockId && it.second == KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:628:                content = KeyguardR44Witness(candidate.first, candidate.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:636:    fun finish(): KeyguardR44WindowEvidence {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:642:        return KeyguardR44WindowEvidence(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:656:        r443Candidates = candidateMetrics.orEmpty().map { metric -> KeyguardR443CandidateObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44Trial.kt:8:internal object KeyguardR44Trial {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:34:internal data class KeyguardR447DuplicateProof(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:61:    val r447SystemBarrier: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:62:    val r447Duplicate: KeyguardR447DuplicateProof? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:136:            if (previous != null) pending = pending?.copy(r447Duplicate = null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:47:internal object KeyguardWindowSnapshotReaderPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:163:        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(initialRootOnly, apiLevel))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:166:        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(strategy, apiLevel))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:181:internal class KeyguardWindowSnapshotReader(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:222:        val r44Enabled: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:223:        val r44DeviceEntryResourceVerified: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:225:        val r443Sample: Boolean = r44Enabled && KeyguardR44Trial.active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:314:        val r44: KeyguardR44WindowEvidence? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:475:        val cacheClearResult = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:493:        val r44Budget = if (request.r44Enabled) KeyguardR44ExtraBudget() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:494:        val r443Inventory = if (r44Budget != null && request.r443Sample && !request.r443Live)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:495:            KeyguardR443Inventory(r44Budget) { authorityIsCurrent() && KeyguardR44Trial.active } else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:496:        val deferredReaders = mutableMapOf<Int, KeyguardR44TreeReader>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:512:        val prefetch = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:526:        val activeCandidate = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:534:        val freshnessBoundaryEstablished = !KeyguardWindowSnapshotReaderPolicy.shouldClearCache(request.freshness) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:536:        val canBatch = KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:541:        ) && KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:553:            return KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:567:            KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:581:                    (root.viewIdResourceName?.let { KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it) } != true &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:582:                        (!request.r44Enabled || root.viewIdResourceName?.let { id ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:583:                            KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:624:            val accepted = authorityIsCurrent() && KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:634:                val next = if (!request.r44Enabled && request.r37YieldHint?.invoke() == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:658:                activeCandidate == null && metadata.none { it.active && !KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(it, observedOwn, request.attachGeneration) } -> "noActiveCandidate"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:660:                !KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:756:            val r44Window = if (r44Budget != null && root != null && rootPackage in SYSTEM_PACKAGES) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:760:                KeyguardR44TreeReader(window.id, verified, window.isActive,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:761:                    request.r44DeviceEntryResourceVerified, r44Budget, r443Inventory,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:781:            if (r443Inventory != null && root != null && r44Window?.isVerifiedActiveRoot() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:788:            val rootNext = if (!request.r44Enabled && request.r37YieldHint?.invoke() == true && root != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:837:                    } else null, r43Window, r44Window,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:873:                    KeyguardR446Bounds(rect.left, rect.top, rect.right, rect.bottom)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:891:                    authorityIsCurrent() && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:904:            val legacy = KeyguardSurfaceClassifier.classifyDetailed(snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:913:                    KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:914:                } } && authorityIsCurrent() && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:920:                    request.r44DeviceEntryResourceVerified
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:931:            if (!authorityIsCurrent() || !KeyguardR44Trial.active) return Result(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:938:                KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:939:                    (request.r44Enabled && KeyguardR44Markers.exact(it)?.let(KeyguardR44Markers::exclusion) != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:941:            val incompleteR44 = request.r44Enabled && snapshots.any { snap ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:981:        r44Window: KeyguardR44TreeReader?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:989:            val r44Restriction = r44Window != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:990:                KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:991:            if (!decisiveReported && (KeyguardSurfaceClassifier.isDecisiveExclusionMarker(id) || r44Restriction) && authorityIsCurrent()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:993:                r44Window?.restrictionObserved()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:998:        r44Window?.onDeferredRestriction(::recordId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:999:        r44Window?.onOptionalTiming(observeIngressCall)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1013:                  parent: AccessibilityNodeInfo?, r44Ancestor: Int?, r44Excluded: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1028:                    r44Window?.hiddenNode(node.viewIdResourceName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1039:                val r44Node = r44Window?.readNode(node, parent, nodeOrdinal, parentOrdinal, r44Ancestor, r44Excluded,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1043:                r44Node?.exclusions?.forEach(::recordId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1044:                if (r44Node?.yieldedTo != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1045:                    yieldedTo = r44Node.yieldedTo
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1050:                r443Boundary?.invoke(!decisiveReported && !truncated && r44Window?.safeToYield() != false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1054:                    r44Window?.safeToYield() != false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1070:                        r44Window?.safeToYield() != false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1085:                            "SKIPPED_DECISIVE" else if (r44Window?.safeToYield() == false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1086:                            "SKIPPED_R44_INCOMPLETE" else "NOT_INSTALLED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1135:                            r44Node?.hostAncestor ?: r44Ancestor, r44Node?.excluded ?: r44Excluded)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1157:            if (r44Window?.isDeferred() == true) null else r44Window?.finish())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1161:        return KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:17:        val freshness = KeyguardInspectionFreshness().also {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:410:            assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(main, foreign)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:423:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(listOf(main)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:7:class KeyguardCardVisibilityPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:23:        assertEquals(KeyguardCardVisibility.HIDDEN_OPT_OUT, KeyguardCardVisibilityPolicy.decide(signals(requested = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:24:        assertEquals(KeyguardCardVisibility.HIDDEN_DISCONNECTED, KeyguardCardVisibilityPolicy.decide(signals(connected = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:25:        assertEquals(KeyguardCardVisibility.HIDDEN_BEFORE_FIRST_UNLOCK, KeyguardCardVisibilityPolicy.decide(signals(unlockedSinceBoot = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:26:        assertEquals(KeyguardCardVisibility.HIDDEN_OTHER_DISPLAY, KeyguardCardVisibilityPolicy.decide(signals(primary = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:27:        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(interactive = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:28:        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(displayOn = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:29:        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(signals(keyguard = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:33:        assertEquals(KeyguardCardVisibility.HIDDEN_CREDENTIAL, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.CREDENTIAL, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:34:        assertEquals(KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.SHADE, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:35:        assertEquals(KeyguardCardVisibility.HIDDEN_OCCLUDED, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.OCCLUDED, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:36:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.UNKNOWN, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:40:        assertEquals(KeyguardCardVisibility.SHOW_DISCREET, KeyguardCardVisibilityPolicy.decide(signals()))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:41:        assertEquals(KeyguardCardVisibility.SHOW_FULL, KeyguardCardVisibilityPolicy.decide(signals(full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:45:        val read = KeyguardSurfaceClassifier.classifyDetailed(listOf(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:51:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = read.surface, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:52:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = read.surface, full = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:59:        assertEquals(KeyguardSurface.CREDENTIAL, KeyguardSurfaceClassifier.classify(mainAndPin))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:60:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text", "com.android.systemui:id/quick_settings_panel"))))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:61:        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.android.camera", 1, 99, 0))))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:67:            KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.fluvi.app", 2032, 100, 0, ownOverlay = true))),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:162:            KeyguardSurfaceClassifier.classifyDetailed(emptyList(), unavailableRoot = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:166:            KeyguardSurfaceClassifier.classifyDetailed(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:177:            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).surface,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:181:            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:185:            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).surface,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:189:            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:195:            KeyguardSurfaceClassifier.classifyDetailed(
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
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:124:        val gate = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:147:        val lock = Any(); val gate = KeyguardFirstAuthorizedOrb(lock); val coordinator = KeyguardOrbPresentationCoordinator(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:167:        val gate = KeyguardFirstAuthorizedOrb(); val first = requireNotNull(proof(gate))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:6:class KeyguardInspectionFreshnessTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:14:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:26:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:41:        val failed = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:52:        val cleared = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:61:        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:68:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:88:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:112:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:127:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:136:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:147:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:153:        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:33:        val lock = Any(); val c = KeyguardOrbPresentationCoordinator(lock); val proof = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:14:        KeyguardInspectionFreshness.Ticket(authority, 1L, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:37:        val empty = KeyguardWindowSnapshotReaderPolicy.activeCandidate(emptyList(), null, owner.attachGeneration)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:39:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, true, false, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:40:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, false, true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:61:        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 34))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:62:        assertEquals(4, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:63:        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.STOCK, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:64:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:70:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, overlay))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:71:        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:72:        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(false, overlay))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:79:        decisive.forEach { assertTrue(it, KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it)) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:80:        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.android.systemui:id/keyguard_clock_switch"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:81:        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.example:id/ordinary"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:89:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi)).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:91:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi), strictOwnAttribution = true).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:94:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, exactOwn), strictOwnAttribution = true).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:115:            if (checkNotNull(Platform.nodes[real]).advertised) listOf(KeyguardR44Markers.EXTRA) else emptyList()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:133:            if (!node.refreshSucceeds || key != KeyguardR44Markers.EXTRA || arguments == null) return false
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:151:    private lateinit var reader: KeyguardWindowSnapshotReader
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:157:        reader = KeyguardWindowSnapshotReader(service, "com.fluvi.app")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:172:        val baseline = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:174:        val originalClass = KeyguardSurfaceClassifier.classifyDetailed(baseline.snapshots)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:178:        val observed = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r43Evidence = evidence), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:181:        assertEquals(originalClass, KeyguardSurfaceClassifier.classifyDetailed(observed.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:190:    @Test fun r44ExplicitLockscreenAndDeviceEntryNeedAnOrdinarySurfaceDecision() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:198:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:199:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:204:        val decision = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:216:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:217:            r44Enabled = true, r44DeviceEntryResourceVerified = false), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:222:        assertEquals(KeyguardR44Markers.Marker.DEVICE_ENTRY, evidence.firstCandidate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:223:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:225:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:235:                if (restrictive) extras.putCharSequence(KeyguardR44Markers.EXTRA, "scene:shade")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:244:            val request = KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:249:                assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:262:        checkNotNull(Platform.nodes[unknown]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:unrecognised")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:269:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:273:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:287:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:298:        checkNotNull(Platform.nodes[unknown]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:unrecognised")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:306:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:336:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:338:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:339:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:340:            KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:342:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:379:        KeyguardR44Trial.set(false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:380:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:382:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:399:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:401:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:405:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:407:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:429:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:431:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:434:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:437:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:459:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:461:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:465:                assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:467:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:489:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:491:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:493:            assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:495:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:508:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:510:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:512:            assertFalse(KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:514:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:525:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:527:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:529:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:531:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:542:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:544:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:546:                val decision = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:549:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:565:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:567:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:569:                val result = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:572:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:591:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:593:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:595:                val result = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:598:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:610:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:612:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:613:            assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:615:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:618:    @Test fun r44EagerAndLazyTagsTraverseTheActualReader() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:626:            else rootData.extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:629:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:630:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:631:            assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:634:            assertEquals(if (lazy) KeyguardR44Markers.Carrier.EXTRA_LAZY else KeyguardR44Markers.Carrier.EXTRA_EAGER,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:639:    @Test fun r44BudgetOrStaleExtraNeverCreatesAuthority() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:649:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:650:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:653:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:663:        val stale = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:664:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { current })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:668:    @Test fun r44ReaderRejectsSpoofedSiblingAndSameNodePairs() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:672:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:673:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:674:            return KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:678:        checkNotNull(Platform.nodes[same]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:LargeClock")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:692:    @Test fun r44ReaderDeniesShadeAfterAnOtherwiseValidPair() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:699:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:700:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:701:        assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:705:    @Test fun r44UnsupportedOrFailedAdvertisedExtraFailsClosed() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:719:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:720:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:721:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:730:    @Test fun r44InspectedUnrelatedTagIsCountedWithoutBeingARestriction() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:734:        checkNotNull(Platform.nodes[unrelated]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "component:example")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:738:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:739:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:742:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:746:    @Test fun r44NestedClockSceneDoesNotDisqualifyTheVerifiedHost() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:750:        checkNotNull(Platform.nodes[localScene]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "scene:localClock")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:755:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:756:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:786:        fun request(wrongToken: Boolean = false): KeyguardWindowSnapshotReader.Request =
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:787:            KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:812:        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:816:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:858:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(result.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:877:        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(ambiguous.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:908:            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:924:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:942:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:988:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1016:        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1019:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1041:        val readingB = KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1071:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1081:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(read.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1096:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1101:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1116:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1126:    private fun r445EmptyOrFailedQuery(fail: Boolean): Pair<KeyguardWindowSnapshotReader.Result, Int> {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1129:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1134:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1136:            reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1139:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1171:        fun sample(kind: String): Pair<KeyguardWindowSnapshotReader.Result, Int> {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1175:            checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1204:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1206:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1209:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1215:        assertEquals(KeyguardR44Markers.Marker.SMALL_CLOCK, positive.first.snapshots.single().r44?.content?.marker)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1244:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1251:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1253:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1257:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1259:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1265:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1271:            extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:bouncer")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1280:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1282:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1288:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1290:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1296:        val result = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1299:            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:9:class KeyguardR441ExtraBudgetTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:11:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:19:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:24:        val slow = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:32:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:41:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:49:        assertTrue(KeyguardR44Markers.unknownMayRestrict("overlay:future", true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:50:        assertTrue(KeyguardR44Markers.unknownMayRestrict("scene:future", false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:51:        assertFalse(KeyguardR44Markers.unknownMayRestrict("element:clock-decoration", true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:58:            assertTrue(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:59:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(35, event, ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:60:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = true, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:61:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:62:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event.copy(displayId = 2), ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicyTest.kt:7:class KeyguardR442YieldPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicyTest.kt:21:        KeyguardR442YieldPolicy.permits(api, orb, screen, session, started, authority, active, old, next)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:6:class KeyguardR444ProfileOwnerTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:16:        val owner = KeyguardR444ProfileOwner(2, { flags }, { value ->
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:43:        assertEquals(KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED, f.owner.snapshot.kind)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:51:        assertEquals(KeyguardR444ProfileOwner.Kind.ERROR, f.owner.snapshot.kind)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:63:        val owner = KeyguardR444ProfileOwner(2,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:96:        val replacement = KeyguardR444ProfileOwner(2, { f.flags }, { f.flags = it; true },
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:8:class KeyguardR445FirstFrameTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:10:        val budget = KeyguardR445WakeBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:18:        assertEquals(KeyguardR44Markers.Marker.SMALL_CLOCK,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:19:            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:23:        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:24:            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view_large"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:28:        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:29:            KeyguardR44Markers.Carrier.EXTRA_LAZY, 2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:30:        val hostEvidence = KeyguardR44WindowEvidence(true, true, host, null, false, true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:31:        val sensorEvidence = KeyguardR44WindowEvidence(true, false, null, null, false, true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:38:            val decision = KeyguardR44SurfaceClassifier.classify(listOf(hostWindow, sensorWindow),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:41:            assertEquals(KeyguardR444Gate.NO_CONTENT, decision.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:7:class KeyguardR446PrintPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:8:    private val bounds = KeyguardR446Bounds(0, 0, 1080, 2400)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:12:            r44 = KeyguardR44WindowEvidence(verified, active, null, null, false, true, false),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:15:        KeyguardSurfaceReason.NO_MAIN_MARKER, r444Gate = KeyguardR444Gate.NO_CONTENT)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:22:                val result = KeyguardR446PrintPolicy.evaluate(windows, missingPositive, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:29:        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:30:            missingPositive.copy(r444Gate = KeyguardR444Gate.NO_HOST), false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:31:        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(88, 9, false)),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:32:            missingPositive.copy(r444Gate = KeyguardR444Gate.COVER_VETO), false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:41:            missingPositive.copy(r444Gate = KeyguardR444Gate.INCOMPLETE),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:43:        bad.forEach { assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), it, false, false).target) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:44:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, true, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:45:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, false, true).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:46:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, owner = "other")), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:47:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, verified = false)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:48:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, focused = true)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:49:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false), window(4, 9, false)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:53:        val owner = KeyguardR446PrintOwner()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:59:        val target = KeyguardR446Target(7, 0, bounds)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:9:class KeyguardR447ReadOrderTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:11:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:15:        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:17:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.REDUNDANT_OFFER_ACCEPTED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:22:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:27:        owner.requireRead(44, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:28:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:31:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:36:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:41:        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:42:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:8:class KeyguardR44SurfaceClassifierTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:9:    private val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:10:    private val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:12:        host: KeyguardR44Witness? = this.host, content: KeyguardR44Witness? = entry,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:15:    ) = KeyguardR44WindowEvidence(verified, active, host, content, below, complete, foreign, passive)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:18:                       e: KeyguardR44WindowEvidence? = evidence()) = KeyguardWindowSnapshot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:23:        KeyguardR44SurfaceClassifier.classify(windows.toList(), unavailable, truncated, false, trial).surface
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:60:        val missing = KeyguardR44SurfaceClassifier.classify(listOf(legacyOnly), false, false,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:63:        assertEquals(KeyguardR444Gate.NO_CONTENT, missing.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:64:        val covered = KeyguardR44SurfaceClassifier.classify(listOf(window(),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:68:        assertEquals(KeyguardR444Gate.COVER_VETO, covered.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:89:        assertEquals(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.exact("element:lockscreen"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:90:        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.exact("element:LargeClock"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:91:        assertEquals(null, KeyguardR44Markers.exact("element:largeclock"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:92:        assertEquals(null, KeyguardR44Markers.exact("com.fake:id/element:lockscreen"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:93:        assertEquals(null, KeyguardR44Markers.exact("com.android.systemui:id/udfps_view"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:221:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(unknown))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:223:            KeyguardCardVisibilityPolicy.decide(unknown.copy(systemStateAvailable = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:238:        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(admitted))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:11:class KeyguardWindowSnapshotReaderPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:14:        val selected = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:20:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:26:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:37:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 9L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:40:        assertEquals(own, KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 10L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:48:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(first, second), null, 1L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:49:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(secondary), null, 1L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:55:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:64:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:69:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:74:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:79:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:89:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:97:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:105:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:116:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:126:        val flags = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 35)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:133:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 32))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:137:        val childFlags = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 35)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:139:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(true, apiLevel = 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:140:        assertEquals(childFlags, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(false, apiLevel = 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:141:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(true, apiLevel = 32))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:175:        assertTrue(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:176:        assertTrue(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), identity, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:177:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(false, listOf(system), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:178:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:179:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), identity, 8, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:180:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:182:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(own), null, 7, own))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:183:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, emptyList(), null, 7, null))

```
