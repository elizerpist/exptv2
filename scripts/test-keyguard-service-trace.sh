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
adb push scripts/keyguard-service-trace.pbtxt /data/local/tmp/fluvi-keyguard-service.pbtxt
# Only this finite fixture is traced. Reinstall the exact precompiled APKs in
# case the preceding Gradle runner cleaned its installation; preserve its XML.
adb install -r build/app/outputs/apk/debug/app-debug.apk
adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am force-stop com.fluvi.app
trace_pid=$(adb shell perfetto --background-wait --txt \
  -c /data/local/tmp/fluvi-keyguard-service.pbtxt \
  -o /data/misc/perfetto-traces/fluvi-keyguard-service.perfetto-trace | tr -d '\r')
if [[ ! "$trace_pid" =~ ^[0-9]+$ ]]; then
  printf 'Perfetto did not return a recorder PID: %s\n' "$trace_pid" >&2
  exit 1
fi
test_result=0
timeout 110s adb shell am instrument -w -r \
  -e sourceSha "$(git rev-parse HEAD)" \
  -e class com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
  | tee "$evidence_dir/instrumentation.txt" || test_result=$?
# am instrument may exit 0 on a JUnit failure; require the actual runner result.
grep -Eq '^OK \(1 test\)' "$evidence_dir/instrumentation.txt" || test_result=1
adb shell kill -INT "$trace_pid" || true
for ((i=0; i<20; i++)); do
  if ! adb shell kill -0 "$trace_pid" 2>/dev/null; then break; fi
  sleep 0.25
done
adb pull /data/misc/perfetto-traces/fluvi-keyguard-service.perfetto-trace "$evidence_dir/"
adb logcat -d -v monotonic > "$evidence_dir/logcat.txt"
adb shell dumpsys accessibility > "$evidence_dir/accessibility-final.txt"
adb shell dumpsys window > "$evidence_dir/window-final.txt"
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
  > "$evidence_dir/probe.tar" || true
sha256sum "$evidence_dir/fluvi-keyguard-service.perfetto-trace" > "$evidence_dir/trace.sha256"
exit "$test_result"
