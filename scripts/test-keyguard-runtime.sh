#!/usr/bin/env bash
set -euo pipefail

# The emulator action executes each input line in a separate shell. Keep the
# test exit status and post-test evidence capture in this single owned script.
cd "$(dirname "$0")/../android"
test_result=0
lower_environment_root=keyguard-lower-environment
preflight_result=0
lower_result=NOT_RUN
lower_started=false
lower_environment_available=true

if [[ -e "$lower_environment_root" ]]; then
  printf 'Refusing to overwrite lower environment evidence: %s\n' "$lower_environment_root" >&2
  preflight_result=1
  lower_environment_available=false
else
  mkdir -p "$lower_environment_root"
  set +e
  timeout -k 2s 60s bash ../scripts/prepare-keyguard-lower-environment.sh "$lower_environment_root/preflight"
  preflight_result=$?
  set -e
fi
if [[ "$lower_environment_available" == true ]]; then
  printf 'preflight_result=%s\n' "$preflight_result" > "$lower_environment_root/runtime-status.txt"
fi
if (( preflight_result != 0 )); then
  if [[ "$lower_environment_available" == true ]]; then
    printf 'lower_result=NOT_RUN preflight_failed\n' >> "$lower_environment_root/runtime-status.txt"
  fi
  test_result=1
else
  lower_started=true
  set +e
  ./gradlew :app:connectedDebugAndroidTest --no-daemon \
    -Pandroid.injected.androidTest.leaveApksInstalledAfterRun=true \
    -Pandroid.testInstrumentationRunnerArguments.class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest,com.fluvi.app.lockscreen.KeyguardFirstDrawObservationInstrumentationTest,com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest,com.fluvi.app.lockscreen.KeyguardProducerSampleRequestBookInstrumentationTest
  lower_result=$?
  set -e
  printf 'lower_result=%s\n' "$lower_result" >> "$lower_environment_root/runtime-status.txt"
  if (( lower_result != 0 )); then test_result=1; fi
fi

# This is an observation, not a recovery action.  It deliberately runs before
# the lower test installation boundary is removed and cannot retry the suite.
post_result=0
if [[ "$lower_environment_available" == true ]]; then
  post_dir="$lower_environment_root/post-lower"
  mkdir -p "$post_dir"
  set +e
  timeout -k 2s 5s adb shell dumpsys window > "$post_dir/window.txt" 2> "$post_dir/window.stderr"
  post_window_rc=$?
  timeout -k 2s 5s adb exec-out screencap -p > "$post_dir/screen.png" 2> "$post_dir/screen.stderr"
  post_screen_rc=$?
  timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$post_dir/logcat.txt" 2> "$post_dir/logcat.stderr"
  post_logcat_rc=$?
  set -e
  printf '%s\n' "$post_window_rc" > "$post_dir/window.exit"
  printf '%s\n' "$post_screen_rc" > "$post_dir/screen.exit"
  printf '%s\n' "$post_logcat_rc" > "$post_dir/logcat.exit"
  if (( post_window_rc != 0 || post_screen_rc != 0 || post_logcat_rc != 0 )) ||
    [[ ! -s "$post_dir/window.txt" || ! -s "$post_dir/screen.png" ]] ||
    ! grep -q 'mCurrentFocus' "$post_dir/window.txt" ||
    grep -m1 'mCurrentFocus' "$post_dir/window.txt" | grep -q 'Application Not Responding'; then
    post_result=1
    test_result=1
  fi
  printf 'post_observation_result=%s\n' "$post_result" >> "$lower_environment_root/runtime-status.txt"
else
  post_result=1
  test_result=1
fi
adb logcat -d -s FluviDrawProbe:I '*:S' > keyguard-draw-probe.log || true
# AGP otherwise uninstalls the target before this pull (run42926044104
# retained only "run-as: unknown package"). Keep the installation just long
# enough to collect the existing bounded failure images, then restore the
# same clean installation boundary before the independent service fixture.
# No assertion or sampling deadline changes; a passing smoke creates no PNG.
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke \
  > keyguard-material-smoke.tar 2> keyguard-material-smoke-pull.log || true
if [[ "$lower_started" == true ]]; then
  adb uninstall com.fluvi.app.test || test_result=1
  adb uninstall com.fluvi.app || test_result=1
fi
service_result=0
bash ../scripts/test-keyguard-service-trace.sh || service_result=$?
if (( service_result != 0 )); then test_result=$service_result; fi
if [[ "$lower_environment_available" == true ]]; then
  printf 'service_result=%s\naggregate_result=%s\n' "$service_result" "$test_result" >> "$lower_environment_root/runtime-status.txt"
fi
exit "$test_result"
