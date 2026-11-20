#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r18-api35"
app=build/app/outputs/apk/debug/app-debug.apk
test_apk=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
test "$(git rev-parse HEAD)" = "$APP_SHA"
test "$(git diff --name-only)" = android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt
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
adb logcat -c || true
rc=0
timeout -k 5s 420s adb shell am instrument -w -r -e class com.fluvi.app.lockscreen.KeyguardOrbPresentationPipelineInstrumentationTest,com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/instrumentation.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$out/instrumentation.exit"
adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
adb shell dumpsys window > "$out/window-after.txt" 2>&1 || true
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe/r18 > "$out/panel-images.tar" 2> "$out/panel-images.stderr" || true
cat "$out/instrumentation.txt"
[[ "$rc" == 0 ]]
! grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/instrumentation.txt"
grep -Eq '^OK \([0-9]+ tests?\)' "$out/instrumentation.txt"
