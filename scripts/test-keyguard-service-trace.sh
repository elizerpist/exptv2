#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
evidence_dir=android/keyguard-service-evidence
mkdir -p "$evidence_dir"
adb shell atrace --list_categories > "$evidence_dir/atrace-categories.txt"
adb shell perfetto --query > "$evidence_dir/perfetto-producers.txt"
adb shell getprop > "$evidence_dir/emulator-properties.txt"
adb shell wm size > "$evidence_dir/display.txt"
adb shell wm density >> "$evidence_dir/display.txt"
# Production64dp orb at the supplied phone's observed168px. The emulator is
# disposable; this does not alter an application dimension or shipped flag.
adb shell wm density 420
# Only this finite fixture is traced. Reinstall the exact precompiled APKs in
# case the preceding Gradle runner cleaned its installation; preserve its XML.
adb install -r build/app/outputs/apk/debug/app-debug.apk
adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am force-stop com.fluvi.app
# The disposable emulator in run42856983444 already had a Launcher ANR
# dialog before this service experiment. Preserve that precondition, then
# close only that identified pre-existing system dialog (never app data).
# This is experiment setup, not a Fluvi visibility/performance workaround.
adb shell dumpsys window > "$evidence_dir/window-before-service.txt"
if grep -Eq 'mCurrentFocus=.*Application Not Responding: com.android.launcher3' \
    "$evidence_dir/window-before-service.txt"; then
  # The ANR window is owned by system_server/package android, not the
  # launcher. Force-stopping the launcher left that exact window focused in
  # run42861703743. Android15 BaseErrorDialog receives CLOSE_SYSTEM_DIALOGS;
  # AppNotRespondingDialog.closeDialog closes/kills its recorded ANR owner.
  # Target only android, before enabling Fluvi/starting this experiment.
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS -p android \
    > "$evidence_dir/launcher-reset.txt"
  for ((i=0; i<20; i++)); do
    adb shell dumpsys window > "$evidence_dir/window-after-launcher-reset.txt"
    if ! grep -Eq 'mCurrentFocus=.*Application Not Responding: com.android.launcher3' \
        "$evidence_dir/window-after-launcher-reset.txt"; then
      break
    fi
    sleep 0.25
  done
  timeout 20s adb shell am start -W -a android.intent.action.MAIN \
    -c android.intent.category.HOME >> "$evidence_dir/launcher-reset.txt"
  adb shell dumpsys window > "$evidence_dir/window-after-launcher-reset.txt"
  if grep -Eq 'mCurrentFocus=.*Application Not Responding: com.android.launcher3' \
      "$evidence_dir/window-after-launcher-reset.txt"; then
    printf 'Launcher ANR still owns focus; service experiment precondition failed\n' >&2
    exit 1
  fi
fi
# API35 CI reported Permission denied opening the pushed /data/local/tmp
# config. The documented stdin route avoids that file-access boundary
# without changing device permissions.
trace_pid=$(adb shell perfetto --background-wait --txt -c - \
  -o /data/misc/perfetto-traces/fluvi-keyguard-service.perfetto-trace \
  < scripts/keyguard-service-trace.pbtxt | tr -d '\r')
if [[ ! "$trace_pid" =~ ^[0-9]+$ ]]; then
  printf 'Perfetto did not return a recorder PID: %s\n' "$trace_pid" >&2
  exit 1
fi
test_result=0
timeout -k 5s 110s adb shell am instrument -w -r \
  -e sourceSha "$(git rev-parse HEAD)" \
  -e class com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
  | tee "$evidence_dir/instrumentation.txt" || test_result=$?
# am instrument may exit 0 on a JUnit failure; require the actual runner result.
grep -Eq '^OK \(1 test\)' "$evidence_dir/instrumentation.txt" || test_result=1
timeout -k 2s 10s adb shell kill -INT "$trace_pid" || test_result=1
# API35 SELinux permits SIGINT but denied signull (kill -0) in run
# 42853507857. Permission denial is NOT process exit: it caused an empty
# trace to be pulled while Perfetto was still flushing. Inspect the process
# table instead, require a successful query, and retain the last table.
recorder_stopped=false
for ((i=0; i<60; i++)); do
  # Run42920244421 completed the exact lost-successor RED at23:22:18,
  # then remained at this empty process-table read until the30m job limit.
  # Bound the host ADB command too; a missing completion remains a FAILURE,
  # never permission to claim the recorder stopped or bypass runtime gates.
  if ! timeout -k 2s 5s adb shell ps -A -o PID,NAME > "$evidence_dir/recorder-processes.txt"; then
    break
  fi
  if ! awk -v pid="$trace_pid" '$1 == pid { found=1 } END { exit !found }' \
      "$evidence_dir/recorder-processes.txt"; then
    recorder_stopped=true
    break
  fi
  sleep 0.25
done
if [[ "$recorder_stopped" != true ]]; then
  printf 'INCOMPLETE: recorder exit was not established within the bounded flush wait\n' \
    > "$evidence_dir/recorder-status.txt"
  test_result=1
else
  printf 'STOPPED: recorder exited before trace pull\n' > "$evidence_dir/recorder-status.txt"
fi
timeout -k 2s 30s adb pull /data/misc/perfetto-traces/fluvi-keyguard-service.perfetto-trace "$evidence_dir/" || test_result=1
test -s "$evidence_dir/fluvi-keyguard-service.perfetto-trace" || test_result=1
timeout -k 2s 10s adb logcat -d -v monotonic > "$evidence_dir/logcat.txt" || test_result=1
timeout -k 2s 10s adb shell dumpsys accessibility > "$evidence_dir/accessibility-final.txt" || test_result=1
timeout -k 2s 10s adb shell dumpsys window > "$evidence_dir/window-final.txt" || test_result=1
timeout -k 2s 10s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
  > "$evidence_dir/probe.tar" || true
sha256sum "$evidence_dir/fluvi-keyguard-service.perfetto-trace" > "$evidence_dir/trace.sha256"
exit "$test_result"
