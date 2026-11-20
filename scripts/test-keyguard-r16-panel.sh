#!/usr/bin/env bash
set -uo pipefail
root=$(git rev-parse --show-toplevel)
app_sha=7c49a22386296ed0285552384c519da87d0bd468
harness_sha=$(git rev-parse HEAD)
evidence="$root/android/keyguard-r16-panel"
[[ ! -e "$evidence" ]] || { printf 'FAIL evidence directory already exists\n' >&2; exit 1; }
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk" || { printf 'FAIL installed APK inputs absent\n'; exit 1; }
printf 'app_source=%s\nharness_source=%s\n' "$app_sha" "$harness_sha" > "$evidence/source.txt"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
adb shell getprop ro.build.fingerprint > "$evidence/device.txt"
adb shell getprop ro.build.version.sdk >> "$evidence/device.txt"
adb shell wm size >> "$evidence/device.txt"
adb shell wm density >> "$evidence/device.txt"
[[ $(adb shell getprop ro.build.version.sdk | tr -d '\r') == 35 ]] || exit 1
adb install -r "$app" > "$evidence/install-app.txt" 2>&1 || exit 1
adb install -r "$test_apk" > "$evidence/install-test.txt" 2>&1 || exit 1
adb shell pm list instrumentation > "$evidence/runner.txt"
grep -Fq 'com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$evidence/runner.txt" || exit 1
if ! bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight" > "$evidence/preflight.log" 2>&1; then
 printf 'PANEL_PREFLIGHT=FAIL\n' > "$evidence/status.txt"; exit 1
fi
result=0
for spec in 'stock:KeyguardR16OrbLayerRetirementInstrumentationTest:stockHolderRetainsItsOldFrameWhileWorkerIsHeld' 'candidate:KeyguardR16OrbLayerRetirementInstrumentationTest:ownedLayerRetiresWhileWorkerIsHeld' 'diagnostics:KeyguardR16DiagnosticInstrumentationTest:lightAndFullKeepOwnedRetirementAndFreezeItsOwner'; do
 IFS=: read -r label class method <<< "$spec"
 dir="$evidence/$label"; mkdir -p "$dir"
 uuid=$(cat /proc/sys/kernel/random/uuid)
 printf 'uuid=%s\nmethod=%s\napp_source=%s\nharness_source=%s\n' "$uuid" "$method" "$app_sha" "$harness_sha" > "$dir/identity.txt"
 for item in "com.fluvi.app:$app:app-before" "com.fluvi.app.test:$test_apk:test-before"; do
  IFS=: read -r package binary receipt <<< "$item"
  bash "$root/scripts/verify-keyguard-installed-apk.sh" "$package" "$binary" "$dir" "$receipt" > "$dir/$receipt-verdict.txt" 2>&1 || result=1
 done
 adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || result=1
 rc=0
 timeout -k 5s 150s adb shell am instrument -w -r -e sourceSha "$app_sha" -e harnessSha "$harness_sha" -e runUuid "$uuid" -e r12Mode SURFACE_LIVE -e class "com.fluvi.app.lockscreen.$class#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
 printf '%s\n' "$rc" > "$dir/instrumentation.exit"
 if [[ $rc != 0 ]] || ! grep -Fxq "INSTRUMENTATION_STATUS: test=$method" "$dir/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then result=1; fi
 adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r16/$uuid" > "$dir/probe.tar" 2> "$dir/probe.stderr" || result=1
 if ! tar -tf "$dir/probe.tar" > "$dir/probe-index.txt" 2>&1; then result=1; fi
 adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
 for item in "com.fluvi.app:$app:app-after" "com.fluvi.app.test:$test_apk:test-after"; do
  IFS=: read -r package binary receipt <<< "$item"
  bash "$root/scripts/verify-keyguard-installed-apk.sh" "$package" "$binary" "$dir" "$receipt" > "$dir/$receipt-verdict.txt" 2>&1 || result=1
 done
done
printf 'PANEL_RESULT=%s\nphysical=UNOBSERVED\n' "$([[ $result == 0 ]] && printf PASS || printf FAIL_INCOMPLETE)" > "$evidence/status.txt"
exit "$result"
