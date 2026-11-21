#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r224-overhead/precondition"; mkdir -p "$out"
app="$GITHUB_WORKSPACE/app/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$GITHUB_WORKSPACE/app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
adb shell wm density 420
(cd "$GITHUB_WORKSPACE/app" && timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/environment")
adb shell am force-stop com.fluvi.app || true
adb uninstall com.fluvi.app > "$out/uninstall.txt" 2>&1 || true
adb install -r "$app" > "$out/install-app.txt" 2>&1
adb install -r "$test_apk" > "$out/install-test.txt" 2>&1
(cd "$GITHUB_WORKSPACE/app" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$out" app)
(cd "$GITHUB_WORKSPACE/app" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$out" test)
run=$(python3 -c 'import uuid; print(uuid.uuid4())'); printf '%s\n' "$run" > "$out/uuid.txt"
adb logcat -c || true
rc=0
timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" \
 -e class 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r21PhoneShapeProtectsDirectAndFinalWithdrawalCore' \
 com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/instrumentation.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/exit.txt"
adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r21/$run" > "$out/evidence.tar" 2> "$out/evidence.stderr" || true
cat "$out/instrumentation.txt"
if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$out/instrumentation.txt"; then
 printf 'NOT_ESTABLISHED: compact wake callback pressure proof failed; unheld OFF/LIGHT not started.\n' > "$out/status.txt"
 exit 1
fi
printf 'PASS: compact wake callback pressure proof\n' > "$out/status.txt"
