#!/usr/bin/env bash
set -euo pipefail

# Fixed disposable-API35 experiment. No arbitrary refs/commands. The R09
# baseline uses only an observation-only test-file overlay from this harness.
root=$(git rev-parse --show-toplevel)
scope=${FLUVI_R11_SCOPE:-}
case "$scope" in
  r11_cold_baseline) target="$root/r11-baseline"; expected=8a91bf2d79f25780bb420c1a4d14abe846eac333; overlay=service-instrumentation-only ;;
  r11_cold_candidate) target="$root"; expected=${GITHUB_SHA:?missing candidate SHA}; overlay=none ;;
  *) printf 'unsupported scope: %s\n' "$scope" >&2; exit 64 ;;
esac
actual=$(git -C "$target" rev-parse HEAD)
harness=$(git -C "$root" rev-parse HEAD)
[[ "$actual" == "$expected" ]] || { printf 'source mismatch %s %s\n' "$actual" "$expected" >&2; exit 1; }
# Production must remain the actual pinned application even with the labelled
# test-only baseline overlay; the overlay does not alter the production tree.
git -C "$target" diff --exit-code "$expected" -- android/app/src/main lib pubspec.yaml pubspec.lock > /dev/null
if [[ "$overlay" == none ]]; then
  [[ -z $(git -C "$target" status --porcelain --untracked-files=no) ]] || { echo 'tracked candidate changes' >&2; exit 1; }
else
  git -C "$target" diff --name-only -- | grep -Fx 'android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt' > /dev/null
  git -C "$target" diff --name-only -- | grep -Fx 'android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt' > /dev/null
  unexpected=$(git -C "$target" diff --name-only -- | grep -v -F -x \
    -e 'android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt' \
    -e 'android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt' || true)
  [[ -z "$unexpected" ]] || { printf 'unexpected baseline overlay: %s\n' "$unexpected" >&2; exit 1; }
fi
evidence="$root/android/keyguard-r11-cold"
[[ ! -e "$evidence" ]] || { echo 'refusing to overwrite cold evidence' >&2; exit 1; }
mkdir -p "$evidence"
app="$target/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$target/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app"
test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks-before.sha256"
api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
{
 printf 'scope=%s\nharness_sha=%s\napplication_sha=%s\noverlay=%s\n' "$scope" "$harness" "$actual" "$overlay"
 printf 'device_api=%s\ndevice_abi=%s\n' "$api" "$abi"
 printf 'device_fingerprint='; adb shell getprop ro.build.fingerprint | tr -d '\r'
 adb shell wm size
 adb shell wm density
 adb shell dumpsys display | head -200 || true
} > "$evidence/manifest.txt"
[[ "$api" == 35 && "$abi" == x86_64 ]] || { echo 'wrong device' >> "$evidence/status.txt"; exit 1; }
adb shell wm density 420
active_trace_pid=''
cleanup() {
  if [[ "$active_trace_pid" =~ ^[0-9]+$ ]]; then
    timeout -k 2s 10s adb shell kill -INT "$active_trace_pid" >/dev/null 2>&1 || true
  fi
  adb shell wm density reset >/dev/null 2>&1 || true
}
trap cleanup EXIT
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
result=0
for repetition in 1 2; do
  rep="$evidence/repetition-$repetition"
  mkdir -p "$rep"
  adb shell am force-stop com.fluvi.app > "$rep/force-stop.txt" 2>&1 || result=1
  adb shell dumpsys window > "$rep/window-before.txt" 2>&1 || result=1
  if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$rep/preflight"; then
    echo 'FAIL preflight; product boundary not reached' > "$rep/status.txt"
    result=1
    continue
  fi
  adb shell atrace --list_categories > "$rep/atrace-categories.txt" 2>&1 || true
  adb shell perfetto --query > "$rep/perfetto-producers.txt" 2>&1 || true
  trace_pid=$(adb shell perfetto --background-wait --txt -c - -o "/data/misc/perfetto-traces/fluvi-r11-$repetition.trace" < "$root/scripts/keyguard-service-trace.pbtxt" | tr -d '\r' || true)
  if [[ ! "$trace_pid" =~ ^[0-9]+$ ]]; then
    printf 'FAIL trace start pid=%s; product boundary not reached\n' "$trace_pid" > "$rep/status.txt"
    result=1
    continue
  fi
  active_trace_pid=$trace_pid
  set +e
  timeout -k 5s 190s adb shell am instrument -w -r -e sourceSha "$actual" \
    -e class 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r11ColdAndWarmTimingOnly' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$rep/instrumentation.txt" 2>&1
  test_rc=$?
  set -e
  grep -Eq '^OK \(1 test\)' "$rep/instrumentation.txt" || test_rc=1
  grep -Fqx 'INSTRUMENTATION_STATUS: test=r11ColdAndWarmTimingOnly' "$rep/instrumentation.txt" || test_rc=1
  if grep -Eq '^INSTRUMENTATION_STATUS_CODE: -3' "$rep/instrumentation.txt"; then test_rc=1; fi
  python3 - "$rep/instrumentation.txt" "$rep/result.xml" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
raw = pathlib.Path(sys.argv[1]).read_text(errors='replace')
method = 'r11ColdAndWarmTimingOnly'
reached = 'INSTRUMENTATION_STATUS: test=' + method in raw
passed = reached and 'OK (1 test)' in raw and 'INSTRUMENTATION_STATUS_CODE: -3' not in raw
suite = ET.Element('testsuite', name='r10-cold-service', tests='1',
                   failures=str(int(reached and not passed)), skipped=str(int(not reached)))
case = ET.SubElement(suite, 'testcase', classname='com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest', name=method)
if not reached:
    ET.SubElement(case, 'skipped', message='instrumentation method not reached')
elif not passed:
    ET.SubElement(case, 'failure', message='instrumentation failed; see full raw transcript').text = raw[-16000:]
ET.ElementTree(suite).write(sys.argv[2], encoding='utf-8', xml_declaration=True)
PY
  timeout -k 2s 10s adb shell kill -INT "$trace_pid" > "$rep/stop-trace.txt" 2>&1 || result=1
  stopped=false
  for ((i=0; i<60; i++)); do
    if ! timeout -k 2s 5s adb shell ps -A -o PID,NAME > "$rep/recorder-processes.txt"; then break; fi
    if ! awk -v pid="$trace_pid" '$1 == pid {found=1} END {exit !found}' "$rep/recorder-processes.txt"; then stopped=true; break; fi
    sleep .25
  done
  [[ "$stopped" == true ]] || result=1
  if [[ "$stopped" == true ]]; then active_trace_pid=''; fi
  timeout -k 2s 30s adb pull "/data/misc/perfetto-traces/fluvi-r11-$repetition.trace" "$rep/trace.perfetto" > "$rep/pull-trace.txt" 2>&1 || result=1
  if [[ -s "$rep/trace.perfetto" ]]; then sha256sum "$rep/trace.perfetto" > "$rep/trace.sha256"; else result=1; fi
  timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$rep/logcat.txt" 2>&1 || result=1
  timeout -k 2s 10s adb shell dumpsys window > "$rep/window-after.txt" 2>&1 || result=1
  timeout -k 2s 10s adb exec-out screencap -p > "$rep/screen-after.png" 2> "$rep/screen-after.stderr" || result=1
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe/r11-timing > "$rep/probe.tar" 2> "$rep/probe.stderr" || result=1
  printf 'instrumentation=%s recorder_stopped=%s\n' "$test_rc" "$stopped" > "$rep/status.txt"
  (( test_rc == 0 )) || result=1
  sha256sum --check "$evidence/apks-before.sha256" > "$rep/apks-after-check.txt" 2>&1 || result=1
done
# Resolve both independent process identities from the preserved files; never
# treat an absent PID or repeated process as a cold measurement.
for repetition in 1 2; do
  rep="$evidence/repetition-$repetition"
  mkdir -p "$rep/probe"
  tar -xf "$rep/probe.tar" -C "$rep/probe" 2> "$rep/untar.stderr" || result=1
  fixture="$rep/probe/files/keyguard-service-probe/r11-timing/fixture.txt"
  if [[ -f "$fixture" ]]; then sed -n 's/.*R11_PROCESS.* pid=\([0-9]*\).*/\1/p' "$fixture" | head -1 > "$rep/pid.txt"; else result=1; fi
done
pid1=$(cat "$evidence/repetition-1/pid.txt" 2>/dev/null || true)
pid2=$(cat "$evidence/repetition-2/pid.txt" 2>/dev/null || true)
if [[ -z "$pid1" || -z "$pid2" || "$pid1" == "$pid2" ]]; then echo 'FAIL distinct process identity' >> "$evidence/status.txt"; result=1; fi
# A third, fresh process runs the bounded compositor control separately from
# both timing-only episodes. Preserve failure and continue to the baseline RED.
rep="$evidence/visual"
mkdir -p "$rep"
adb shell am force-stop com.fluvi.app > "$rep/force-stop.txt" 2>&1 || result=1
if timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$rep/preflight"; then
  set +e
  timeout -k 5s 190s adb shell am instrument -w -r -e sourceSha "$actual" \
    -e class 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r11ColdAndWarmVisualControl' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$rep/instrumentation.txt" 2>&1
  visual_rc=$?
  set -e
  grep -Eq '^OK \(1 test\)' "$rep/instrumentation.txt" || visual_rc=1
  grep -Fqx 'INSTRUMENTATION_STATUS: test=r11ColdAndWarmVisualControl' "$rep/instrumentation.txt" || visual_rc=1
  if grep -Eq '^INSTRUMENTATION_STATUS_CODE: -3' "$rep/instrumentation.txt"; then visual_rc=1; fi
  (( visual_rc == 0 )) || result=1
else
  visual_rc=1
  result=1
fi
timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$rep/logcat.txt" 2>&1 || result=1
timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe/r11-visual > "$rep/probe.tar" 2> "$rep/probe.stderr" || result=1
mkdir -p "$rep/probe"
tar -xf "$rep/probe.tar" -C "$rep/probe" 2> "$rep/untar.stderr" || result=1
fixture="$rep/probe/files/keyguard-service-probe/r11-visual/fixture.txt"
visual_pid=''
if [[ -f "$fixture" ]]; then visual_pid=$(sed -n 's/.*R10_PROCESS.* pid=\([0-9]*\).*/\1/p' "$fixture" | head -1); fi
if [[ -z "$visual_pid" || "$visual_pid" == "$pid1" || "$visual_pid" == "$pid2" ]]; then
  echo 'FAIL independent visual process identity' >> "$rep/status.txt"; result=1
fi
printf 'instrumentation=%s visual_pid=%s\n' "$visual_rc" "$visual_pid" >> "$rep/status.txt"
sha256sum --check "$evidence/apks-before.sha256" > "$rep/apks-after-check.txt" 2>&1 || result=1
# The baseline-compatible RED runs only after both cold observations, so its
# test Activity and detached work cannot warm the measured service process.
# An expected assertion failure is evidence, not a failed cold experiment.
if [[ "$scope" == r11_cold_baseline ]]; then
  adb shell am force-stop com.fluvi.app > "$evidence/red-force-stop.txt" 2>&1 || true
  set +e
  timeout -k 5s 90s adb shell am instrument -w -r \
    -e class 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r11PositiveReadyBeforeGrantSurvivesEarlyNudge' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$evidence/baseline-red.txt" 2>&1
  red_rc=$?
  set -e
  if grep -Fq 'positive lease was incorrectly classified as detached' "$evidence/baseline-red.txt" &&
      grep -Fq 'FAILURES!!!' "$evidence/baseline-red.txt"; then
    printf 'RED_EXPECTED actual_baseline_assertion=true command_exit=%s\n' "$red_rc" > "$evidence/baseline-red.status"
  else
    printf 'RED_NOT_ESTABLISHED command_exit=%s\n' "$red_rc" > "$evidence/baseline-red.status"
  fi
  # Keep the original panel sample even when the RED assertion failed.
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke \
    > "$evidence/baseline-red-material.tar" 2> "$evidence/baseline-red-material.stderr" || result=1
fi
# Preserve trace processor/coverage even if either correctness assertion failed.
if curl --fail --location --silent --show-error --retry 2 https://get.perfetto.dev/trace_processor -o "$evidence/trace_processor"; then
 chmod +x "$evidence/trace_processor"
 "$evidence/trace_processor" --version > "$evidence/processor-version.txt" 2>&1 || result=1
 sha256sum "$evidence/trace_processor" > "$evidence/processor.sha256"
 for repetition in 1 2; do
  rep="$evidence/repetition-$repetition"
  if [[ -s "$rep/trace.perfetto" ]]; then
   "$evidence/trace_processor" "$rep/trace.perfetto" -q "$root/scripts/keyguard-r10-cold-trace.sql" > "$rep/trace-analysis.txt" 2> "$rep/trace-analysis.stderr" || result=1
  fi
 done
else
 echo 'FAIL trace processor unavailable' >> "$evidence/status.txt"
 result=1
fi
printf 'pid1=%s pid2=%s aggregate=%s\n' "$pid1" "$pid2" "$result" >> "$evidence/status.txt"
exit "$result"
