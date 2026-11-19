#!/usr/bin/env bash
set -euo pipefail

# R12's service-order baseline: pinned R11 application with a test-only probe.
# This script is a fixed diagnostic, not a delivery gate or an arbitrary runner.
root=$(git rev-parse --show-toplevel)
source_sha=$(git rev-parse HEAD)
baseline=1d19624751169e3af0270b151378cdfcdf1a1129
git diff --exit-code "$baseline" HEAD -- android/app/src/main lib pubspec.yaml pubspec.lock > /dev/null
[[ -z $(git status --porcelain --untracked-files=no) ]] || { echo 'tracked source is not clean' >&2; exit 1; }
evidence="$root/android/keyguard-r12-admission-baseline"
[[ ! -e "$evidence" ]] || { echo 'refusing to overwrite evidence' >&2; exit 1; }
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app"
test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks-before.sha256"
api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
{
  printf 'harness=%s\napplication_baseline=%s\nproduction_diff=none\ntest_overlay=androidTest-only\n' "$source_sha" "$baseline"
  printf 'api=%s\nabi=%s\n' "$api" "$abi"
  adb shell wm size
  adb shell wm density
} > "$evidence/manifest.txt"
[[ "$api" == 35 && "$abi" == x86_64 ]] || { echo 'device mismatch' >> "$evidence/status.txt"; exit 1; }
adb shell wm density 420
cleanup() { adb shell wm density reset >/dev/null 2>&1 || true; }
trap cleanup EXIT
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
  echo 'FAIL fixture preflight; admission boundary not reached' > "$evidence/status.txt"
  exit 1
fi
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
adb shell am force-stop com.fluvi.app > "$evidence/force-stop.txt" 2>&1
set +e
timeout -k 5s 110s adb shell am instrument -w -r -e sourceSha "$baseline" \
  -e class 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply' \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$evidence/instrumentation.txt" 2>&1
instrument_rc=$?
timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$evidence/logcat.txt" 2>&1
log_rc=$?
timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe/r12-admission > "$evidence/probe.tar" 2> "$evidence/probe.stderr"
probe_rc=$?
timeout -k 2s 10s adb shell dumpsys window > "$evidence/window-after.txt" 2>&1
window_rc=$?
sha256sum --check "$evidence/apks-before.sha256" > "$evidence/apks-after-check.txt" 2>&1
identity_rc=$?
set -e
mkdir -p "$evidence/probe"
tar -xf "$evidence/probe.tar" -C "$evidence/probe" 2> "$evidence/untar.stderr" || true
fixture="$evidence/probe/files/keyguard-service-probe/r12-admission/fixture.txt"
capture="$evidence/probe/files/keyguard-service-probe/r12-admission/capture.txt"
if [[ "$log_rc" == 0 && "$probe_rc" == 0 && "$window_rc" == 0 && "$identity_rc" == 0 ]] &&
   grep -Fqx 'INSTRUMENTATION_STATUS: test=r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply' "$evidence/instrumentation.txt" &&
   grep -Fq 'compatible B did not start before the held ordered A application' "$evidence/instrumentation.txt" &&
   grep -Fq 'FAILURES!!!' "$evidence/instrumentation.txt" &&
   [[ -s "$fixture" && -s "$capture" ]] && grep -Fq 'bStartedBeforeAApply=false' "$fixture" &&
   grep -Fq 'R12_ADMISSION_CLEANUP' "$fixture" && grep -Fq 'status=PASS' "$fixture" &&
   grep -Fq 'NO_MAIN_MARKER' "$capture"; then
  printf 'RED_EXPECTED=actual_service_serial_order instrument_rc=%s\n' "$instrument_rc" > "$evidence/status.txt"
  exit 0
fi
printf 'FAIL=baseline_control_not_proven instrument_rc=%s log=%s probe=%s window=%s identity=%s\n' \
  "$instrument_rc" "$log_rc" "$probe_rc" "$window_rc" "$identity_rc" > "$evidence/status.txt"
exit 1
