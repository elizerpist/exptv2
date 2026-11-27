#!/usr/bin/env bash
# Synthetic test-only collection: preserve every sample even after assertion failure.
set -uo pipefail
root="$GITHUB_WORKSPACE/app"
out="$RUNNER_TEMP/r37-evidence"
fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/KeyguardR47FrameCorrelationInstrumentationTest.kt"
mkdir -p "$out/correlation"
cd "$root" || exit 1
source_sha=af20365a5ec96ff92b35321a03c0a2679ee7d2fd
[[ $(git rev-parse HEAD) == "$source_sha" ]] || exit 1
[[ -z $(git status --porcelain --untracked-files=no) ]] || exit 1
{
 printf 'application=%s\nharness=%s\n' "$source_sha" "$GITHUB_SHA"
 sha256sum "$fixture" build/app/outputs/apk/debug/app-debug.apk build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
 adb devices -l
 adb shell getprop ro.build.version.sdk
 adb shell getprop ro.build.fingerprint
 adb shell cat /proc/sys/kernel/random/boot_id
 adb shell wm size
 adb shell wm density
} > "$out/correlation/identity.txt" 2>&1
[[ $(adb shell getprop ro.build.version.sdk | tr -d '\r') == 37 ]] || exit 1
[[ $(adb shell getprop ro.product.cpu.abi | tr -d '\r') == x86_64 ]] || exit 1
adb shell input keyevent KEYCODE_WAKEUP || exit 1
adb shell wm dismiss-keyguard || true
adb install -r build/app/outputs/apk/debug/app-debug.apk > "$out/correlation/install-app.txt" 2>&1 || exit 1
adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/correlation/install-test.txt" 2>&1 || exit 1
if ! timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/correlation/preflight" > "$out/correlation/preflight.log" 2>&1; then
 printf 'PREFLIGHT_FAILED: no runtime trial performed\n' > "$out/correlation/status.txt"
 exit 1
fi
python3 -B "$GITHUB_WORKSPACE/orchestrator/.github/scripts/test-r47-frame-verdict.py" > "$out/correlation/verdict-selftest.txt" 2>&1 || exit 1
python3 -B "$GITHUB_WORKSPACE/orchestrator/.github/scripts/test-r47-frame-extract.py" > "$out/correlation/extract-selftest.txt" 2>&1 || exit 1
trace_processor="$out/correlation/trace_processor"
if curl -fsSL --retry 2 https://get.perfetto.dev/trace_processor -o "$trace_processor"; then
 chmod +x "$trace_processor"
else
 printf 'trace_processor=UNAVAILABLE\n' > "$out/correlation/trace-processor-status.txt"
fi
cat > "$out/correlation/frame-timeline.sql" <<'SQL'
SELECT ts,dur,surface_frame_token,display_frame_token,present_type,layer_name
FROM actual_frame_timeline_slice ORDER BY ts;
SQL
result=0
for method in controlClean controlOneFrame directFirstSample waFirstSample directPendingDraw waPendingDraw directRapidRelock waRapidRelock; do
 uuid=$(cat /proc/sys/kernel/random/uuid)
 [[ $uuid =~ ^[0-9a-f-]{36}$ ]] || exit 1
 dir="$out/correlation/$method"
 mkdir -p "$dir"
 printf 'method=%s\nuuid=%s\nsource=%s\n' "$method" "$uuid" "$source_sha" > "$dir/identity.txt"
 adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || true
 adb logcat -c || true
 adb shell dumpsys window > "$dir/windows-before.txt" 2>&1 || true
 adb shell cat /proc/uptime > "$dir/clock-before.txt" 2>&1 || true
 remote_video="/sdcard/fluvi-r47-$uuid.mp4"
 remote_pid="/data/local/tmp/fluvi-r47-$uuid.pid"
 remote_trace="/data/misc/perfetto-traces/fluvi-r47-$uuid.perfetto-trace"
 trace_pid=$(adb shell perfetto --background-wait --txt -c - -o "$remote_trace" < scripts/keyguard-service-trace.pbtxt 2>"$dir/perfetto-start.stderr" | tr -d '\r')
 printf 'pid=%s\n' "$trace_pid" > "$dir/perfetto-start.txt"
 adb shell "sh -c 'echo \$\$ > $remote_pid; exec screenrecord --verbose --time-limit 0 $remote_video'" > "$dir/recorder.txt" 2>&1 &
 host_pid=$!
 ready=0
 for _ in {1..20}; do
   if adb shell "test -s '$remote_pid' && test -s '$remote_video'" >/dev/null 2>&1; then ready=1; break; fi
   kill -0 "$host_pid" 2>/dev/null || break
   sleep 0.25
 done
 printf 'started=%s\n' "$ready" > "$dir/recorder-status.txt"
 sleep 1
 rc=0
 timeout -k 5s 150s adb shell am instrument -w -r -e runUuid "$uuid" \
   -e class "com.fluvi.app.lockscreen.KeyguardR47FrameCorrelationInstrumentationTest#$method" \
   com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
 printf '%s\n' "$rc" > "$dir/instrumentation.exit"
 if [[ $rc != 0 ]] || ! grep -Fqx "INSTRUMENTATION_STATUS: test=$method" "$dir/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then
   printf 'FAIL_OR_NOT_REACHED: preserve instrumentation transcript\n' > "$dir/instrumentation-verdict.txt"
   result=1
 else
   printf 'PASS: method completed; compositor verdict is separate\n' > "$dir/instrumentation-verdict.txt"
 fi
 sleep 1
 signal_rc=0
 adb shell "p=\$(cat '$remote_pid' 2>/dev/null); case \"\$(cat /proc/\$p/cmdline 2>/dev/null | tr '\\0' ' ')\" in *fluvi-r47-*) kill -INT \$p ;; *) exit 1 ;; esac" > "$dir/recorder-signal.txt" 2>&1 || signal_rc=$?
 for _ in {1..20}; do kill -0 "$host_pid" 2>/dev/null || break; sleep 0.5; done
 if kill -0 "$host_pid" 2>/dev/null; then kill "$host_pid" 2>/dev/null || true; printf 'forced=1\n' >> "$dir/recorder-status.txt"; result=1; fi
 wait "$host_pid" 2>/dev/null || true
 printf 'signal_exit=%s\n' "$signal_rc" >> "$dir/recorder-status.txt"
 if [[ $trace_pid =~ ^[0-9]+$ ]]; then
   timeout -k 2s 10s adb shell kill -INT "$trace_pid" > "$dir/perfetto-signal.txt" 2>&1 || true
   for _ in {1..30}; do
     timeout -k 2s 5s adb shell ps -A -o PID,NAME > "$dir/perfetto-processes.txt" 2>&1 || break
     awk -v pid="$trace_pid" '$1 == pid { found=1 } END { exit !found }' "$dir/perfetto-processes.txt" || break
     sleep 0.5
   done
   adb pull "$remote_trace" "$dir/frames.perfetto-trace" > "$dir/perfetto-pull.txt" 2>&1 || true
   if [[ -s $dir/frames.perfetto-trace && -x $trace_processor ]]; then
     timeout -k 5s 120s "$trace_processor" -q "$out/correlation/frame-timeline.sql" "$dir/frames.perfetto-trace" > "$dir/frame-timeline.csv" 2> "$dir/frame-timeline.stderr" || true
   fi
 fi
 adb pull "$remote_video" "$dir/recording.mp4" > "$dir/video-pull.txt" 2>&1 || true
 adb shell cat /proc/uptime > "$dir/clock-after.txt" 2>&1 || true
 adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
 adb shell dumpsys window > "$dir/windows-after.txt" 2>&1 || true
 adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r43/$uuid" > "$dir/probe.tar" 2> "$dir/probe.stderr" || true
 mkdir -p "$dir/probe"
 tar -xf "$dir/probe.tar" -C "$dir/probe" > "$dir/untar.txt" 2>&1 || true
 if [[ -s $dir/recording.mp4 ]]; then
   sha256sum "$dir/recording.mp4" > "$dir/recording.sha256"
   python3 scripts/keyguard-r15-video.py --video "$dir/recording.mp4" --out "$dir/video-validated" > "$dir/video-validation.txt" 2>&1 || true
   if [[ ! -d $dir/video-validated/frames ]]; then
     mkdir -p "$dir/video-fallback-frames"
     ffmpeg -v error -i "$dir/recording.mp4" -map 0:v:0 -fps_mode passthrough -start_number 0 "$dir/video-fallback-frames/%08d.png" > "$dir/video-extract.txt" 2>&1 || true
   fi
 else
   printf 'video=UNOBSERVED\n' >> "$dir/recorder-status.txt"
   result=1
 fi
 python3 -B "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r47-frame-extract.py" "$dir" > "$dir/frame-extract.log" 2>&1 || true
 adb shell rm -f "$remote_video" "$remote_pid" "$remote_trace" >/dev/null 2>&1 || true
done
python3 -B "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r47-frame-summary.py" "$out/correlation" > "$out/correlation/summary.log" 2>&1 || result=1
if ! python3 -B - "$out/correlation/frame-correlation-verdict.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f: result=json.load(f)
controls=result['control_status']
cases=result['cases']
if controls.get('clean')!='PASS' or controls.get('one_frame')!='PASS': sys.exit(1)
if any(case['verdict']['status']!='ORB_ABSENT' for case in cases.values()): sys.exit(1)
PY
then
  printf 'correlated_frame_gate=FAIL_OR_NOT_DECIDABLE\n' > "$out/correlation/frame-gate.txt"
  result=1
else
  printf 'correlated_frame_gate=PASS; prior_original_first_sample_failure_remains\n' > "$out/correlation/frame-gate.txt"
fi
printf 'aggregate_exit=%s\nframes_are_not_physical_presentation=true\n' "$result" > "$out/correlation/status.txt"
exit "$result"
