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
for case in stock stable negative; do
  case "$case" in
    stock) method='com.fluvi.app.lockscreen.KeyguardR22StockFirstInspectionInstrumentationTest#r22StockOpeningContinuesAfterRealSuccessorOffered'; evidence=r22 ;;
    stable) method='com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#stableInitialFullUsesOneVirginOutputWithoutReadinessRead'; evidence=r19 ;;
    negative) method='com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#r21ExclusionRetiresSubmittedOrbWithMainAckHeld'; evidence=r19 ;;
  esac
  run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$run" > "$out/$case-uuid.txt"
  adb shell am force-stop com.fluvi.app || true
  adb logcat -c || true
  rc=0
  timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e class "$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$case.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$out/$case.exit"
  adb logcat -b all -d -v monotonic > "$out/$case-logcat.txt" 2>&1 || true
  adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/$evidence/$run" > "$out/$case-evidence.tar" 2> "$out/$case-evidence.stderr" || true
  cat "$out/$case.txt"
  if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$case.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$case.txt"; then failed=1; fi
done
exit "$failed"
