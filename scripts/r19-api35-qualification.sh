#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r19-api35"
mkdir -p "$out"
app=build/app/outputs/apk/debug/app-debug.apk
test_apk=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
test "$(git rev-parse HEAD)" = "$APP_SHA"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$out/apk-sha256.txt"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; adb shell dumpsys display; } > "$out/device.txt" 2>&1
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size | tr -d '\r' | grep -Eq '(^|: )1080x2400$'
adb install -r "$app" > "$out/install-app.txt" 2>&1
adb install -r "$test_apk" > "$out/install-test.txt" 2>&1
bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$out" app
bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$out" test
adb shell pm list instrumentation > "$out/instrumentation-list.txt"
grep -F 'com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$out/instrumentation-list.txt"
timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
failed=0
for method in r22CalibrationPreservesNonSuppressingAutomation r22SupersededOpeningWalkYieldsToFreshInspection r22YieldedWalkCannotGrantAfterExclusion r22StableOpeningReadIsNotYielded r22UnstagedOpeningObservation; do
  run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$run" > "$out/$method-uuid.txt"
  adb shell am force-stop com.fluvi.app || true
  adb logcat -c || true
  rc=0
  timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e class "com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$out/$method.exit"
  adb logcat -b all -d -v monotonic > "$out/$method-logcat.txt" 2>&1 || true
  adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r22/$run" > "$out/$method-evidence.tar" 2> "$out/$method-evidence.stderr" || true
  cat "$out/$method.txt"
  if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then failed=1; fi
  member=$(tar -tf "$out/$method-evidence.tar" 2>/dev/null | grep '/result.txt$' | head -1 || true)
  if [[ -z "$member" ]]; then
    echo 'T3 result missing: NOT REACHED'
    failed=1
  else
    tar -xOf "$out/$method-evidence.tar" "$member" > "$out/$method-visual-status.txt" || true
    case "$method" in
      r22SupersededOpeningWalkYieldsToFreshInspection|r22StableOpeningReadIsNotYielded)
        grep -q 'visualCalibration=PASS ' "$out/$method-visual-status.txt" || failed=1 ;;
      r22YieldedWalkCannotGrantAfterExclusion)
        grep -q 'visualCalibration=PASS_NEGATIVE ' "$out/$method-visual-status.txt" || failed=1 ;;
      r22CalibrationPreservesNonSuppressingAutomation)
        if ! tar -xOf "$out/$method-evidence.tar" "$(tar -tf "$out/$method-evidence.tar" | grep '/sequence.txt$' | head -1)" | grep -q 'AUTOMATION_CONTROL_REACHED'; then failed=1; fi ;;
      r22UnstagedOpeningObservation) : ;;
    esac
  fi
done
# A frozen report is produced, then recovered after a real process stop.
for mode in LIGHT FULL; do
  for phase in prepareFrozenCapture verifyRecoveredCapture; do
    adb shell am force-stop com.fluvi.app || true
    rc=0
    timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e r22Mode "$mode" \
      -e class "com.fluvi.app.lockscreen.KeyguardR22RecoveryInstrumentationTest#$phase" \
      com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/recovery-$mode-$phase.txt" 2>&1 || rc=$?
    printf '%s\n' "$rc" > "$out/recovery-$mode-$phase.exit"
    cat "$out/recovery-$mode-$phase.txt"
    if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/recovery-$mode-$phase.txt" || ! grep -Eq '^OK \(1 test\)' "$out/recovery-$mode-$phase.txt"; then failed=1; fi
  done
done
# One API35 panel and reducer block; the actual-service specimens above are separate.
adb shell am force-stop com.fluvi.app || true
adb logcat -c || true
run=$(python3 -c 'import uuid; print(uuid.uuid4())')
printf '%s\n' "$run" > "$out/r21-panel-diagnostics-uuid.txt"
rc=0
timeout -k 5s 1000s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e class 'com.fluvi.app.lockscreen.KeyguardOrbPresentationPipelineInstrumentationTest,com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest' com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/r21-panel-diagnostics.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/r21-panel-diagnostics.exit"
adb logcat -b all -d -v monotonic > "$out/r21-panel-diagnostics-logcat.txt" 2>&1 || true
adb shell dumpsys window > "$out/window-after.txt" 2>&1 || true
for evidence in r18 r20 "r21/$run"; do
  label=${evidence//\//-}
  adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/$evidence" > "$out/$label-evidence.tar" 2> "$out/$label-evidence.stderr" || true
done
cat "$out/r21-panel-diagnostics.txt"
if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/r21-panel-diagnostics.txt" || ! grep -Eq '^OK \([0-9]+ tests?\)' "$out/r21-panel-diagnostics.txt"; then failed=1; fi
# Independent calibrated canonical View control.
adb shell am force-stop com.fluvi.app || true
rc=0
timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e class 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases' com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/r20-canonical.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/r20-canonical.exit"
cat "$out/r20-canonical.txt"
if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/r20-canonical.txt" || ! grep -Eq '^OK \(1 test\)' "$out/r20-canonical.txt"; then failed=1; fi
# Each additional renderer control is a separate specimen; continue after a
# failure so the distinct compositor and lifecycle evidence is retained.
for method in isolatedOpaqueOrbHasNeutralParentAtRetire isolatedStandbyPreservesAuthorizedComposition stalePressureCannotSwitchReplacement isolatedOrbStaleFirstCommitCannotUndoSameRootPrivacyOrSizeReplacement r09MixedSizeHeldOldUseLeavesCurrentSuccessorCapacity disposedWindowCannotBeRevivedByDelayedPressureTicket isolatedOrbFirstDirectDisposeDoesNotWaitForWorkerOrOldCommit isolatedOrbWithdrawalDoesNotWaitForBlockedRendererFrame; do
  run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$run" > "$out/$method-uuid.txt"
  adb shell am force-stop com.fluvi.app || true
  adb logcat -c || true
  rc=0
  timeout -k 5s 300s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" \
    -e class "com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#$method" \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$out/$method.exit"
  adb logcat -b all -d -v monotonic > "$out/$method-logcat.txt" 2>&1 || true
  adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/$method-evidence.tar" 2> "$out/$method-evidence.stderr" || true
  cat "$out/$method.txt"
  if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then failed=1; fi
done
# Focused R08 privacy discriminator, with the original six samples and
# unchanged assertion. This result remains separate from the panel suite.
adb shell am force-stop com.fluvi.app || true
adb logcat -c || true
run=$(python3 -c 'import uuid; print(uuid.uuid4())')
printf '%s\n' "$run" > "$out/r08-privacy-uuid.txt"
rc=0
timeout -k 5s 240s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" \
  -e class 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges' \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/r08-privacy.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/r08-privacy.exit"
adb logcat -b all -d -v monotonic > "$out/r08-privacy-logcat.txt" 2>&1 || true
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/r08-privacy-evidence.tar" 2> "$out/r08-privacy-evidence.stderr" || true
cat "$out/r08-privacy.txt"
if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/r08-privacy.txt" || ! grep -Eq '^OK \(1 test\)' "$out/r08-privacy.txt"; then failed=1; fi
exit "$failed"
