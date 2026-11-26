#!/usr/bin/env bash
set -euo pipefail
root="$GITHUB_WORKSPACE/app"
out="$RUNNER_TEMP/r37-evidence"
mkdir -p "$out"
cd "$root"
printf 'app=%s\nharness=%s\nfixture=%s\n' "$APP_SHA" "$HARNESS_SHA" "$BASELINE" > "$out/source.txt"
case "${1:-}" in
 build)
  test "$(git rev-parse HEAD)" = "$APP_SHA"
  test -z "$(git status --porcelain --untracked-files=no)"
  if [[ "$BASELINE" = true ]]; then
    test "$(git -C "$GITHUB_WORKSPACE/harness" rev-parse HEAD)" = "$HARNESS_SHA"
    if [[ "$TEST_SCOPE" == r44_1_holder_* ]]; then
      fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR441HolderReproInstrumentationTest.kt"
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR441HolderReproInstrumentationTest.kt
      sha256sum "$fixture" > "$out/fixture.sha256"
    elif [[ "$TEST_SCOPE" == r44_1_capture_* ]]; then
      for fixture in \
        android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt \
        android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22VisualCalibration.kt \
        android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt \
        android/app/src/debug/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorkerTestHooks.kt \
        android/app/src/profile/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorkerTestHooks.kt \
        android/app/src/release/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceWorkerTestHooks.kt; do
        cp "$GITHUB_WORKSPACE/harness/$fixture" "$fixture"
        sha256sum "$fixture" >> "$out/fixture.sha256"
      done
      git diff > "$out/fixture.patch"
    elif [[ "$TEST_SCOPE" == r44_2_race ]]; then
      fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442ReceiptRaceInstrumentationTest.kt"
      test -f "$fixture"
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442ReceiptRaceInstrumentationTest.kt
      sha256sum "$fixture" > "$out/fixture.sha256"
    elif [[ "$TEST_SCOPE" == r44_2_actual ]]; then
      fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442SystemUiObservationTest.kt"
      test -f "$fixture"
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442SystemUiObservationTest.kt
      sha256sum "$fixture" > "$out/fixture.sha256"
    elif [[ "$TEST_SCOPE" == r44_2_yield ]]; then
      fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442ServiceYieldInstrumentationTest.kt"
      test -f "$fixture"
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442ServiceYieldInstrumentationTest.kt
      sha256sum "$fixture" > "$out/fixture.sha256"
    elif [[ "$TEST_SCOPE" == r44_service || "$TEST_SCOPE" == r44_systemui ]]; then
      fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt"
      test -f "$fixture"
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt
      git diff -- android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt > "$out/fixture.patch"
      sha256sum "$fixture" > "$out/fixture.sha256"
    else
    fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt"
    test -f "$fixture"
    if [[ "$TEST_SCOPE" != isolated_ready_witness ]]; then
      cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt
    fi
    case "$TEST_SCOPE" in
      r42_raw_pressure|r42_late_winner)
        second="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt"
        test -f "$second"
        cp "$second" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt
        sha256sum "$second" > "$out/fixture-r41-diagnostics.sha256"
        ;;
      r42_prestart|r42_stale|r42_stale_after_read|system_warm_report|system_warm_ordered|system_warm_latest_report|system_warm_latest_ordered|system_warm_target_report|system_warm_target_ordered)
        second="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt"
        test -f "$second"
        cp "$second" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt
        sha256sum "$second" > "$out/fixture-r26.sha256"
        ;;
      isolated_ready_witness)
        second="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt"
        test -f "$second"
        cp "$second" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt
        sha256sum "$second" > "$out/fixture-material.sha256"
        ;;
    esac
    git diff -- android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt > "$out/fixture.patch"
    sha256sum "$fixture" > "$out/fixture.sha256"
    fi
  fi
  if [[ "$TEST_SCOPE" == r42_profile_motion_fixture ]]; then
    fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR42SignedProfileProbeTest.kt"
    test -f "$fixture"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR42SignedProfileProbeTest.kt
    sha256sum "$fixture" > "$out/fixture-r42-profile.sha256"
  fi
  if [[ "$TEST_SCOPE" == r43_api37 ]]; then
    fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR43Api37BaselineTest.kt"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43Api37BaselineTest.kt
    sha256sum "$fixture" > "$out/fixture-r43.sha256"
  fi
  if [[ "$TEST_SCOPE" == r43_live ]]; then
    fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR43Api37LiveProbeTest.kt"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43Api37LiveProbeTest.kt
    sha256sum "$fixture" > "$out/fixture-r43-live.sha256"
  fi
  if [[ "$TEST_SCOPE" == r43_busy_red ]]; then
    fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR43DiagnosticsInstrumentationTest.kt"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt
    sha256sum "$fixture" > "$out/fixture-r43-busy-red.sha256"
  fi
  if [[ "$TEST_SCOPE" == r42_stale_verbose ]]; then
    fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR26DirectOrderingInstrumentationTest.kt"
    test -f "$fixture"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt
    sha256sum "$fixture" > "$out/fixture-r42-stale-verbose.sha256"
  fi
  flutter pub get > "$out/pub-get.log" 2>&1
  rc=0
  (cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build.log" 2>&1 || rc=$?
  if (( rc != 0 )); then tail -100 "$out/build.log"; exit "$rc"; fi
  sha256sum build/app/outputs/apk/debug/app-debug.apk build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/pair.sha256"
  if [[ "$TEST_SCOPE" == r42_profile_motion_fixture ]]; then
    cp build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk "$out/r42-profile-test-input.apk"
  fi
  # This is a disposable hosted runner. Keep the APK pair and evidence.
  rm -rf -- "$root/build/app/intermediates" "$root/build/app/tmp" "$HOME/.gradle/caches"
  sha256sum -c "$out/pair.sha256"
  ;;
 run)
  collect() {
    adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
    adb logcat -b crash -d -v monotonic > "$out/crash.txt" 2>&1 || true
    adb shell dumpsys activity exit-info com.fluvi.app > "$out/exit-info.txt" 2>&1 || true
    adb shell dumpsys SurfaceFlinger > "$out/surfaceflinger.txt" 2>&1 || true
    adb shell getprop ro.hardware.egl > "$out/egl-property.txt" 2>&1 || true
    adb shell dumpsys window > "$out/final-window.txt" 2>&1 || true
    for uuid in ${r37_uuids:-}; do
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r39/$uuid" > "$out/r39-$uuid.tar" 2> "$out/r39-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$out/visual-$uuid.tar" 2> "$out/visual-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r26/$uuid" > "$out/r26-$uuid.tar" 2> "$out/r26-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r41/$uuid" > "$out/r41-$uuid.tar" 2> "$out/r41-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r42-profile/$uuid" > "$out/r42-profile-$uuid.tar" 2> "$out/r42-profile-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r15/$uuid" > "$out/r15-$uuid.tar" 2> "$out/r15-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r43/$uuid" > "$out/r43-$uuid.tar" 2> "$out/r43-$uuid.stderr" || true
    done
  }
  trap collect EXIT
  { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
  test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 37
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard || true
  adb install -r build/app/outputs/apk/debug/app-debug.apk > "$out/install-app.txt" 2>&1
  adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/install-test.txt" 2>&1
  bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
  failed=0
  r37_uuids=""
  case "$TEST_SCOPE" in
    r44_2_yield)
      class=com.fluvi.app.lockscreen.KeyguardR442ServiceYieldInstrumentationTest
      methods=(heldPreScreenReaderHandsOffToLatestPendingRequest)
      ;;
    r44_2_actual)
      class=com.fluvi.app.lockscreen.KeyguardR442SystemUiObservationTest
      methods=(actualSystemUiSampleClockAndRestrictionObservations)
      ;;
    r44_2_race)
      class=com.fluvi.app.lockscreen.KeyguardR442ReceiptRaceInstrumentationTest
      methods=(captureCreationRaceRejectsDoubleStartAndChangedMaterial)
      ;;
    r44_2_owner)
      class=com.fluvi.app.lockscreen.KeyguardR442OwnerInstrumentationTest
      methods=(serviceOwnsSampleCaptureReceiptAndInvalidatesIt)
      ;;
    r44_1_holder_post)
      class=com.fluvi.app.lockscreen.KeyguardR441HolderReproInstrumentationTest
      methods=(realHolderPostThenDetach)
      ;;
    r44_1_holder_locked)
      class=com.fluvi.app.lockscreen.KeyguardR441HolderReproInstrumentationTest
      methods=(realHolderDetachWhileCanvasIsLocked)
      ;;
    r44_1_capture_off)
      class=com.fluvi.app.lockscreen.KeyguardR44ServiceInstrumentationTest
      methods=(syntheticPairUsesRealServiceWithCaptureOff)
      ;;
    r44_1_capture_on)
      class=com.fluvi.app.lockscreen.KeyguardR44ServiceInstrumentationTest
      methods=(syntheticPairUsesRealServiceWithCaptureOn)
      ;;
    r44_1_stale)
      class=com.fluvi.app.lockscreen.KeyguardR44ServiceInstrumentationTest
      methods=(supersededSyntheticReadCannotGrantAfterRestriction)
      ;;
    r44_pressure)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r44PerWakeEvidenceSurvivesLightPressure r44PerWakeEvidenceSurvivesFullPressure r442FirstIncompleteReadAndMissingSuccessorRemainExplicit)
      ;;
    r44_service)
      class=com.fluvi.app.lockscreen.KeyguardR44ServiceInstrumentationTest
      methods=(syntheticPairUsesRealServiceWithCaptureOff syntheticPairUsesRealServiceWithCaptureOn supersededSyntheticReadCannotGrantAfterRestriction)
      ;;
    r44_systemui)
      class=com.fluvi.app.lockscreen.KeyguardR44ServiceInstrumentationTest
      methods=(actualSystemUiRestrictiveTransitions)
      ;;
    r44_widget)
      class=com.fluvi.app.lockscreen.KeyguardFinancialSnapshotRemoteViewsInstrumentationTest
      methods=(remoteViewsAndNotificationDelegateKeepRealPixelsAndText)
      ;;
    r44_provider)
      class=com.fluvi.app.lockscreen.KeyguardR44LazyProviderInstrumentationTest
      methods=(advertisedTagIsFilledOnlyAfterRealExtraRequest)
      ;;
    r43_api37)
      class=com.fluvi.app.lockscreen.KeyguardR43Api37BaselineTest
      methods=(ordinaryFirstAndLaterWake)
      ;;
    r43_live)
      class=com.fluvi.app.lockscreen.KeyguardR43Api37LiveProbeTest
      methods=(timedHoldsRetainActualServiceEvidence)
      ;;
    r43_diagnostics)
      class=com.fluvi.app.lockscreen.KeyguardR43DiagnosticsInstrumentationTest
      methods=(namedHoldsSurvivePressureWithoutUnverifiedOrForeignIds frozenOrReplacedCaptureCannotReceiveAnOldObservation laterCompletePassiveHoldReplacesBusyObserverAndRetainsItsCause)
      ;;
    r43_busy_red)
      class=com.fluvi.app.lockscreen.KeyguardR43DiagnosticsInstrumentationTest
      methods=(laterCompletePassiveHoldReplacesBusyObserverAndRetainsItsCause)
      ;;
    ordered)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(orderedDirectSkipsInapplicableR25Evaluation)
      ;;
    warm)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(warmOrderedDirectSkipsInapplicableR25Evaluation)
      ;;
    h2_fixture)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(r41FixtureFifoControlWaitsForOriginalMain r41FixtureRealIngressReconcilesBeforeSuccessor)
      ;;
    isolated_dispose_original)
      class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest
      methods=(isolatedOrbFirstDirectDisposeDoesNotWaitForWorkerOrOldCommit)
      ;;
    report)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(readyWorkDoesNotWaitForDiagnosticPublication)
      ;;
    system_warm_report)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmReadyWorkDoesNotWaitForDiagnosticPublication)
      ;;
    system_warm_ordered)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmOrderedDirectSkipsInapplicableR25Evaluation)
      ;;
    system_warm_latest_report)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmLatestReadyWorkDoesNotWaitForDiagnosticPublication)
      ;;
    system_warm_latest_ordered)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmLatestDirectPreservesOrdering)
      ;;
    system_warm_target_report)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmOrderedCandidateReadyWorkPrecedesReport)
      ;;
    system_warm_target_ordered)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(systemWarmOrderedCandidateLatestPreservesOrdering)
      ;;
    r40_safety)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r40HeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock)
      ;;
    r41_warm_safety)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41WarmHeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock)
      ;;
    r41_prepared_safety)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41PreparedRouteHeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock)
      ;;
    r41_system_warm_safety)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmFreshServiceKeepsVisualAndUnlockControls)
      ;;
    r41_system_warm_motion)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmLiveOrbShowsTwoCalibratedFramesThenWithdraws)
      ;;
    r41_system_warm_prepared_motion)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPreparedLiveOrbShowsCalibratedFramesThenWithdraws)
      ;;
    r42_profile_motion_fixture)
      class=com.fluvi.app.lockscreen.KeyguardR42SignedProfileProbeTest
      methods=(signedProfileShowsCurrentGrantedOrbAndNaturalMotion)
      ;;
    r41_system_warm_arrival_motion)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPreparedLiveOrbRecordsArrivalAndMotionThenWithdraws)
      ;;
    r21_controls)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r21SubmittedDirectOrbSurvivesBenignIngressBeforeMainAck r21ExclusionRetiresSubmittedOrbWithMainAckHeld)
      ;;
    r21_system_warm_controls)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmBenignIngressBeforeRealMainAck r41SystemWarmExclusionBeforeRealMainAck)
      ;;
    r21_system_warm_swipe)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmSwipeShadeBeforeRealMainAck)
      ;;
    r21_system_warm_pin)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPinBeforeRealMainAck)
      ;;
    r21_system_warm_pin_menu)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPinMenuBeforeRealMainAck)
      ;;
    r21_system_warm_prepared_pin_menu)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPreparedPinMenuBeforeRealMainAck)
      ;;
    r21_system_warm_prepared_shade_settings)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41SystemWarmPreparedSettingsShadeBeforeRealMainAck)
      ;;
    isolated_ready_witness)
      class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest
      methods=(r41RetiredReadyUsesExactAttachmentWitness)
      ;;
    fallback)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41ActualFallbackRetainsCandidateAndPostReceipt)
      ;;
    warm_fallback)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41ActualWarmFallbackRetainsCandidateAndPostReceipt)
      ;;
    natural_20)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41TwentyUnheldWakeAttempts)
      ;;
    natural_h2_20)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r41TwentyUnheldWakeAttemptsWithH2Fixture)
      ;;
    pressure)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners burstOfPendingOffersPreservesWinningOwnerAndReportsLoss)
      ;;
    r42_raw_pressure)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(r42LateCriticalWakeSurvivesRawLightPressure r42LateCriticalWakeSurvivesRawFullPressure)
      ;;
    r42_late_winner)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(r42LateWinnerOfferAndReadSurviveRawPressure)
      ;;
    r42_prestart)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(r42PreStartSelectsActualLatestRequest)
      ;;
    r42_stale)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(r42StalePositiveExitsAfterOrderedRestrictions)
      ;;
    r42_stale_after_read)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(r42StalePositiveAfterRealReadExitsBeforePositivePath)
      ;;
    r42_stale_verbose)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(r42StalePositiveAfterRealReadExitsBeforePositivePath)
      ;;
    capacity_pressure)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(twentyFiveRequestWakeSurvivesLightExport twentyFiveRequestWakeSurvivesFullExport allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners burstOfPendingOffersPreservesWinningOwnerAndReportsLoss)
      ;;
    export_priority)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(absentR22BoundariesRemainExplicitlyUnknown duplicateFirstCauseReferencesOnlyTheExactSelectedShowingCause directAndWithdrawalEvidenceSurvivesR41LightPressure directAndWithdrawalEvidenceSurvivesR41FullPressure twentyFiveRequestWakeSurvivesLightExport twentyFiveRequestWakeSurvivesFullExport allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners burstOfPendingOffersPreservesWinningOwnerAndReportsLoss)
      ;;
    old_export)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r13FinancialWorkSurvivesPressureAndRemainsCaptureBounded r18PipelineEvidenceRemainsBoundedAndOwnedInLight r18PipelineEvidenceRemainsBoundedAndOwnedInFull r19FirstAndMotionEvidenceSurvivesLightPressure r19FirstAndMotionEvidenceSurvivesFullPressure r26ExactDirectEvidenceSurvivesLightAndFullPressure)
      ;;
    old_export_wide)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r15PhoneShapeKeepsFinancialAndActualWithdrawalFull r15PhoneShapeKeepsFinancialAndActualWithdrawalLight lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget r14FullPressureRetainsEverySelectedEpisode r14LightPressureRetainsEverySelectedEpisode)
      ;;
    old_r18_evidence)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r18PipelineEvidenceRemainsBoundedAndOwnedInLight r18PipelineEvidenceRemainsBoundedAndOwnedInFull)
      ;;
    old_r15_evidence)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r15PhoneShapeKeepsFinancialAndActualWithdrawalFull r15PhoneShapeKeepsFinancialAndActualWithdrawalLight)
      ;;
    r22_regression)
      class=com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest
      methods=(r22PostClaimQueueEvidenceSurvivesLightPressureAndFreeze r22PostClaimQueueEvidenceSurvivesFullPressureAndFreeze r22CoreJoinsOnlyTheExactReservationWithinAnAttempt r22PassiveStandbySummarySurvivesLightExport r22PassiveStandbySummarySurvivesFullExport r21PhoneShapeProtectsDirectAndFinalWithdrawalCore)
      ;;
    all)
      class=""
      methods=(orderedDirectSkipsInapplicableR25Evaluation allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners)
      ;;
    *) printf 'Unknown test scope: %s\n' "$TEST_SCOPE" >&2; exit 2;;
  esac
  for method in "${methods[@]}"; do
    if [[ "$TEST_SCOPE" = all ]]; then
      case "$method" in
        ordered*) class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest;;
        *) class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest;;
      esac
    fi
    uuid=$(cat /proc/sys/kernel/random/uuid)
    r37_uuids="$r37_uuids $uuid"
    printf '%s %s\n' "$method" "$uuid" >> "$out/trials.txt"
    rc=0
    timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e harnessSha "$HARNESS_SHA" -e runUuid "$uuid" -e class "$class#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
    if (( rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then
      printf '%s FAIL exit=%s\n' "$method" "$rc" >> "$out/results.txt"; failed=1
    else printf '%s PASS\n' "$method" >> "$out/results.txt"; fi
    if [[ "$TEST_SCOPE" == r44_service || "$TEST_SCOPE" == r44_systemui || "$TEST_SCOPE" == r44_1_* || "$TEST_SCOPE" == r44_2_actual || "$TEST_SCOPE" == r44_2_yield ]]; then
      # A native process crash bypasses the fixture's finally block. This is
      # the disposable fixture PIN only; clear it so the following declared
      # method can independently establish its own secure-lock precondition.
      { adb shell locksettings clear --old 2468 || true
        adb shell input keyevent KEYCODE_WAKEUP || true
        adb shell wm dismiss-keyguard || true
        adb shell locksettings get-disabled || true
      } > "$out/$method-cleanup.txt" 2>&1
    fi
  done
  cat "$out/results.txt"
  exit "$failed"
  ;;
 *) exit 2;;
esac
