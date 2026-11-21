#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r22-2-fixture"
app=build/app/outputs/apk/debug/app-debug.apk
test_apk=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
test "$(git rev-parse HEAD)" = "$APP_SHA"
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
timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
run=$(python3 -c 'import uuid; print(uuid.uuid4())')
printf '%s\n' "$run" > "$out/control-uuid.txt"
adb shell am force-stop com.fluvi.app || true
adb logcat -c || true
rc=0
timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e class 'com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#r22CalibrationPreservesNonSuppressingAutomation' com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/control.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/control.exit"
adb logcat -b all -d -v monotonic > "$out/control-logcat.txt" 2>&1 || true
adb shell dumpsys accessibility > "$out/accessibility-after.txt" 2>&1 || true
adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r22/$run" > "$out/control-evidence.tar" 2> "$out/control-evidence.stderr" || true
cat "$out/control.txt"
grep 'UiAutomationManager: Registering UiTestAutomationService' "$out/control-logcat.txt" > "$out/platform-registrations.txt" || true
if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/control.txt" || ! grep -Eq '^OK \(1 test\)' "$out/control.txt"; then exit 1; fi
if ! grep -q 'flags=0x1' "$out/platform-registrations.txt" || grep -q 'flags=0x0' "$out/platform-registrations.txt"; then echo 'platform registration mismatch'; exit 1; fi
member=$(tar -tf "$out/control-evidence.tar" | grep '/sequence.txt$' | head -1)
tar -xOf "$out/control-evidence.tar" "$member" > "$out/control-sequence.txt"
grep -q 'AUTOMATION_CONNECTED actual=true' "$out/control-sequence.txt"
grep -q 'AUTOMATION_ORIGINAL_A' "$out/control-sequence.txt"
grep -q 'A_FIRST_CHILD_RETURN' "$out/control-sequence.txt"
grep -q 'AUTOMATION_CONTROL_REACHED' "$out/control-sequence.txt"
