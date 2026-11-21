#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r22-3-parent"
mkdir -p "$out"
app=build/app/outputs/apk/debug/app-debug.apk
test_apk=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
test "$(git rev-parse HEAD)" = "$APP_SHA"
sha256sum "$app" "$test_apk" > "$out/apk-sha256.txt"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
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
timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
failed=0
run_case() {
  local class=$1 method=$2 category=$3 seconds=$4 run rc
  run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$run" > "$out/$method-uuid.txt"
  adb shell am force-stop com.fluvi.app || true
  adb logcat -c || true
  if [[ "$category" == panel ]]; then
    adb shell run-as com.fluvi.app rm -rf files/keyguard-material-smoke || true
  fi
  rc=0
  timeout -k 5s "${seconds}s" adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e class "$class#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$out/$method.exit"
  adb logcat -b all -d -v monotonic > "$out/$method-logcat.txt" 2>&1 || true
  if [[ "$category" == panel ]]; then
    adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/$method-evidence.tar" 2> "$out/$method-evidence.stderr" || true
  else
    adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r22/$run" > "$out/$method-evidence.tar" 2> "$out/$method-evidence.stderr" || true
  fi
  cat "$out/$method.txt"
  if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then failed=1; fi
}
service=com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest
panel=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest
for method in r22CalibrationPreservesNonSuppressingAutomation r22SupersededOpeningWalkYieldsToFreshInspection r22YieldedWalkCannotGrantAfterExclusion r22StableOpeningReadIsNotYielded r22UnstagedOpeningObservation; do
  run_case "$service" "$method" service 180
done
for method in isolatedOpaqueOrbHasNeutralParentAtRetire stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges isolatedStandbyPreservesAuthorizedComposition isolatedStandbyBlackReturnAndHide isolatedNeutralRecoveryAtCommittedResizedBounds; do
  seconds=180
  if [[ "$method" == stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges ]]; then seconds=240; fi
  run_case "$panel" "$method" panel "$seconds"
done
exit "$failed"
