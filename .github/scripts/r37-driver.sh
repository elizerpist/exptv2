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
    fixture="$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt"
    test -f "$fixture"
    test "$(git -C "$GITHUB_WORKSPACE/harness" rev-parse HEAD)" = "$HARNESS_SHA"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt
    git diff -- android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt > "$out/fixture.patch"
    sha256sum "$fixture" > "$out/fixture.sha256"
  fi
  flutter pub get > "$out/pub-get.log" 2>&1
  rc=0
  (cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build.log" 2>&1 || rc=$?
  if (( rc != 0 )); then tail -100 "$out/build.log"; exit "$rc"; fi
  sha256sum build/app/outputs/apk/debug/app-debug.apk build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/pair.sha256"
  # This is a disposable hosted runner. Keep the APK pair and evidence.
  rm -rf -- "$root/build/app/intermediates" "$root/build/app/tmp" "$HOME/.gradle/caches"
  sha256sum -c "$out/pair.sha256"
  ;;
 run)
  collect() {
    adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
    adb shell dumpsys window > "$out/final-window.txt" 2>&1 || true
    for uuid in ${r37_uuids:-}; do
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r39/$uuid" > "$out/r39-$uuid.tar" 2> "$out/r39-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$out/visual-$uuid.tar" 2> "$out/visual-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r26/$uuid" > "$out/r26-$uuid.tar" 2> "$out/r26-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r41/$uuid" > "$out/r41-$uuid.tar" 2> "$out/r41-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r15/$uuid" > "$out/r15-$uuid.tar" 2> "$out/r15-$uuid.stderr" || true
    done
  }
  trap collect EXIT
  { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
  test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard || true
  adb install -r build/app/outputs/apk/debug/app-debug.apk > "$out/install-app.txt" 2>&1
  adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/install-test.txt" 2>&1
  bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
  failed=0
  r37_uuids=""
  case "$TEST_SCOPE" in
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
    report)
      class=com.fluvi.app.lockscreen.KeyguardR26DirectOrderingInstrumentationTest
      methods=(readyWorkDoesNotWaitForDiagnosticPublication)
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
    r21_controls)
      class=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
      methods=(r21SubmittedDirectOrbSurvivesBenignIngressBeforeMainAck r21ExclusionRetiresSubmittedOrbWithMainAckHeld)
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
    capacity_pressure)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(twentyFiveRequestWakeSurvivesLightExport twentyFiveRequestWakeSurvivesFullExport allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners burstOfPendingOffersPreservesWinningOwnerAndReportsLoss)
      ;;
    export_priority)
      class=com.fluvi.app.lockscreen.KeyguardR41DiagnosticsInstrumentationTest
      methods=(directAndWithdrawalEvidenceSurvivesR41LightPressure directAndWithdrawalEvidenceSurvivesR41FullPressure twentyFiveRequestWakeSurvivesLightExport twentyFiveRequestWakeSurvivesFullExport allAttemptsSurviveVerboseLightPressure allAttemptsSurviveVerboseFullPressure rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners burstOfPendingOffersPreservesWinningOwnerAndReportsLoss)
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
  done
  cat "$out/results.txt"
  exit "$failed"
  ;;
 *) exit 2;;
esac
