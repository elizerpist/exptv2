#!/usr/bin/env bash
set -euo pipefail

# One device, one installed APK pair, four fresh processes in reverse order.
# Raw outputs are retained even when a recorder, a process or decoding fails.
# This acquisition collector alone never declares visual or APK qualification.
root=$(git rev-parse --show-toplevel)
source_sha=$(git rev-parse HEAD)
[[ "$source_sha" == "${GITHUB_SHA:?missing immutable source SHA}" ]]
[[ -z $(git status --porcelain --untracked-files=no) ]]
evidence="$root/android/keyguard-r15-comparison"
[[ ! -e $evidence ]] || { echo 'refusing to overwrite comparison evidence' >&2; exit 1; }
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
command -v ffmpeg > "$evidence/ffmpeg-path.txt"
command -v ffprobe > "$evidence/ffprobe-path.txt"
ffmpeg -version > "$evidence/ffmpeg-version.txt"
ffprobe -version > "$evidence/ffprobe-version.txt"
python3 -c 'import PIL; print(PIL.__version__)' > "$evidence/pillow-version.txt"
python3 "$root/scripts/test-keyguard-r15-visual.py" > "$evidence/visual-host.txt" 2>&1
python3 "$root/scripts/test-keyguard-r15-comparison.py" > "$evidence/comparison-host.txt" 2>&1
adb shell screenrecord --help > "$evidence/screenrecord-help.txt" 2>&1
grep -Fq -- '--time-limit' "$evidence/screenrecord-help.txt"
{
 printf 'source=%s\n' "$source_sha"
 adb shell getprop ro.build.fingerprint
 adb shell getprop ro.product.cpu.abi
 adb shell getprop ro.build.version.sdk
 adb shell cat /proc/sys/kernel/random/boot_id
 adb shell wm size
 adb shell wm density
 adb shell pm list instrumentation
} > "$evidence/device-before.txt"
[[ $(adb shell getprop ro.build.version.sdk | tr -d '\r') == 35 ]]
[[ $(adb shell getprop ro.product.cpu.abi | tr -d '\r') == x86_64 ]]
grep -Fq 'com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$evidence/device-before.txt"
saved_auto_rotation=$(adb shell settings get system accelerometer_rotation | tr -d '\r')
saved_user_rotation=$(adb shell settings get system user_rotation | tr -d '\r')
saved_density=$(adb shell wm density | tr -d '\r' | sed -n 's/^Override density: //p')
[[ $saved_auto_rotation =~ ^(null|[01])$ && $saved_user_rotation =~ ^(null|[0-3])$ ]]
[[ -z $saved_density || $saved_density =~ ^[0-9]+$ ]]
active_pidfile=
active_shell_pid=
active_dir=
stop_recorder() {
 local signal_rc=0 wait_rc=0 forced=0
 if [[ -n $active_pidfile ]]; then
  # The path is a locally generated UUID. Only the process whose command line
  # names our own recording may receive the interrupt used to finalize MP4.
  adb shell "p=\$(cat '$active_pidfile' 2>/dev/null); case \"\$(cat /proc/\$p/cmdline 2>/dev/null | tr '\\0' ' ')\" in *fluvi-r15-*) kill -INT \$p ;; *) exit 1 ;; esac" > "${active_dir:-$evidence}/recorder-signal.txt" 2>&1 || signal_rc=$?
 fi
 if [[ -n $active_shell_pid ]]; then
  for _ in {1..30}; do kill -0 "$active_shell_pid" 2>/dev/null || break; sleep 1; done
  if kill -0 "$active_shell_pid" 2>/dev/null; then forced=1; kill "$active_shell_pid" 2>/dev/null || true; fi
  wait "$active_shell_pid" 2>/dev/null || wait_rc=$?
  printf 'signal_exit=%s\nwait_exit=%s\nforced=%s\n' "$signal_rc" "$wait_rc" "$forced" > "${active_dir:-$evidence}/recorder-exit.txt"
  if [[ $signal_rc != 0 || $forced != 0 ]]; then result=1; fi
 fi
 active_pidfile=
 active_shell_pid=
 active_dir=
}
restore_rotation() {
 local key=$1 value=$2
 if [[ $value == null ]]; then adb shell settings delete system "$key" >/dev/null 2>&1 || true
 else adb shell settings put system "$key" "$value" >/dev/null 2>&1 || true; fi
}
cleanup() {
 stop_recorder
 restore_rotation user_rotation "$saved_user_rotation"
 restore_rotation accelerometer_rotation "$saved_auto_rotation"
 if [[ -n $saved_density ]]; then adb shell wm density "$saved_density" >/dev/null 2>&1 || true
 else adb shell wm density reset >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size > "$evidence/size-after.txt"
adb shell wm density > "$evidence/density-after.txt"
[[ $(tr -d '\r' < "$evidence/size-after.txt" | tail -1) == *1080x2400 ]]
[[ $(tr -d '\r' < "$evidence/density-after.txt" | tail -1) == *420 ]]
adb install -r "$app" > "$evidence/install-app.txt" 2>&1
adb install -r "$test_apk" > "$evidence/install-test.txt" 2>&1
grep -qx 'Success' "$evidence/install-app.txt"
grep -qx 'Success' "$evidence/install-test.txt"
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
 printf 'device_preflight=FAIL\n' > "$evidence/status.txt"
 exit 1
fi
result=0
for spec in 1:stock 1:candidate 2:candidate 2:stock; do
 IFS=: read -r block arm <<< "$spec"
 case_uuid=$(cat /proc/sys/kernel/random/uuid)
 [[ $case_uuid =~ ^[0-9a-f-]{36}$ ]]
 dir="$evidence/block-$block-$arm"
 mkdir -p "$dir"
 printf 'source=%s\nrun_uuid=%s\nblock=%s\narm=%s\n' "$source_sha" "$case_uuid" "$block" "$arm" > "$dir/identity.txt"
 for item in "com.fluvi.app:$app:app-before" "com.fluvi.app.test:$test_apk:test-before"; do
  IFS=: read -r package binary label <<< "$item"
  bash "$root/scripts/verify-keyguard-installed-apk.sh" "$package" "$binary" "$dir" "$label" > "$dir/$label-verdict.txt" 2>&1 || result=1
 done
 adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || result=1
 adb shell dumpsys window > "$dir/windows-before.txt" 2>&1 || true
 adb shell dumpsys display > "$dir/display-before.txt" 2>&1 || true
 adb shell cat /proc/uptime > "$dir/clock-before.txt" 2>&1 || true
 remote_video="/sdcard/fluvi-r15-$case_uuid.mp4"
 active_pidfile="/data/local/tmp/fluvi-r15-$case_uuid.pid"
 active_dir="$dir"
 # Independent shell owner persists while instrumentation changes device state.
 adb shell "sh -c 'echo \$\$ > $active_pidfile; exec screenrecord --verbose --time-limit 0 $remote_video'" > "$dir/recorder.txt" 2>&1 &
 active_shell_pid=$!
 ready=0
 for _ in {1..20}; do
  if adb shell "test -s '$active_pidfile' && test -s '$remote_video'" >/dev/null 2>&1; then ready=1; break; fi
  kill -0 "$active_shell_pid" 2>/dev/null || break
  sleep 0.25
 done
 printf 'recorder_started=%s\n' "$ready" > "$dir/recorder-status.txt"
 [[ $ready == 1 ]] || result=1
 rc=0
 timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" \
  -e runUuid "$case_uuid" -e r12Mode SURFACE_LIVE -e r15Arm "$arm" -e r15Block "$block" \
  -e class 'com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#r15BalancedFirstAcquisition' \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
 printf '%s\n' "$rc" > "$dir/instrumentation.exit"
 if [[ $rc != 0 ]] || ! grep -Fxq 'INSTRUMENTATION_STATUS: test=r15BalancedFirstAcquisition' "$dir/instrumentation.txt" \
    || ! grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then result=1; fi
 stop_recorder
 adb shell cat /proc/uptime > "$dir/clock-after.txt" 2>&1 || true
 adb shell dumpsys window > "$dir/windows-after.txt" 2>&1 || true
 adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
 if adb pull "$remote_video" "$dir/recording.mp4" > "$dir/pull-video.txt" 2>&1 && [[ -s $dir/recording.mp4 ]]; then
  sha256sum "$dir/recording.mp4" > "$dir/recording.sha256"
 else
  printf 'video=UNOBSERVED\n' >> "$dir/recorder-status.txt"
  result=1
 fi
 adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || result=1
 for item in "com.fluvi.app:$app:app-after" "com.fluvi.app.test:$test_apk:test-after"; do
  IFS=: read -r package binary label <<< "$item"
  bash "$root/scripts/verify-keyguard-installed-apk.sh" "$package" "$binary" "$dir" "$label" > "$dir/$label-verdict.txt" 2>&1 || result=1
 done
done

# Decode only after all timed slots to avoid host decoding load contaminating
# a later arm. Missing metadata/space remains an explicit failed boundary.
for dir in "$evidence"/block-*; do
 if [[ -s $dir/recording.mp4 ]]; then
  python3 "$root/scripts/keyguard-r15-video.py" --video "$dir/recording.mp4" --out "$dir/decoded" \
   > "$dir/decode.txt" 2>&1 || result=1
 fi
done
sha256sum --check "$evidence/apks.sha256" > "$evidence/apks-after-check.txt" 2>&1 || result=1
printf 'raw_collection_exit=%s\nvisual_calibration=NOT_ESTABLISHED\ncomparison_qualification=NOT_ESTABLISHED\n' "$result" > "$evidence/status.txt"
# Until independent references, all slot manifests and their collector are
# available, a video/producer timing observation is not an admission pass.
exit 1
