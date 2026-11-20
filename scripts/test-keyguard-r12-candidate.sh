#!/usr/bin/env bash
set -euo pipefail

# Bounded evidence collection for the actual R12 candidate. The known
# incomplete compositor/lifecycle contract remains a failing gate, even if
# these individual timing and panel observations pass.
root=$(git rev-parse --show-toplevel)
scope=${FLUVI_R12_SCOPE:?missing fixed R12 scope}
case "$scope" in
  r12_legacy) mode=LEGACY_R11 ;;
  r12_static) mode=SURFACE_STATIC ;;
  r12_live) mode=SURFACE_LIVE ;;
  r12_contract) mode=CONTRACT ;;
  *) printf 'unsupported scope: %s\n' "$scope" >&2; exit 64 ;;
esac
source_sha=$(git -C "$root" rev-parse HEAD)
[[ "$source_sha" == "${GITHUB_SHA:?missing immutable candidate SHA}" ]] || { echo 'source SHA mismatch' >&2; exit 1; }
[[ -z $(git -C "$root" status --porcelain --untracked-files=no) ]] || { echo 'tracked source is not clean' >&2; exit 1; }
evidence="$root/android/keyguard-r12-candidate-$scope"
[[ ! -e "$evidence" ]] || { echo 'refusing to overwrite candidate evidence' >&2; exit 1; }
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
{
  printf 'scope=%s\nsource_sha=%s\nmode=%s\napi=%s\nabi=%s\n' "$scope" "$source_sha" "$mode" "$api" "$abi"
  adb shell wm size
  adb shell wm density
  adb shell getprop ro.build.fingerprint
} > "$evidence/manifest.txt"
[[ "$api" == 35 && "$abi" == x86_64 ]] || { echo 'FAIL device identity' | tee "$evidence/status.txt"; exit 1; }
saved_auto_rotation=$(adb shell settings get system accelerometer_rotation | tr -d '\r')
saved_user_rotation=$(adb shell settings get system user_rotation | tr -d '\r')
saved_density=$(adb shell wm density | tr -d '\r' | sed -n 's/^Override density: //p')
[[ $saved_auto_rotation =~ ^(null|[01])$ && $saved_user_rotation =~ ^(null|[0-3])$ ]]
[[ -z $saved_density || $saved_density =~ ^[0-9]+$ ]]
recorder_pidfile=
recorder_shell_pid=
recorder_dir=
stop_fixture_recorder() {
  local signal_rc=0 wait_rc=0 forced=0
  if [[ -n $recorder_pidfile ]]; then
    adb shell "p=\$(cat '$recorder_pidfile' 2>/dev/null); case \"\$(cat /proc/\$p/cmdline 2>/dev/null | tr '\\0' ' ')\" in *fluvi-r15-*) kill -INT \$p ;; *) exit 1 ;; esac" \
      > "${recorder_dir:-$evidence}/recorder-signal.txt" 2>&1 || signal_rc=$?
  fi
  if [[ -n $recorder_shell_pid ]]; then
    for _ in {1..30}; do kill -0 "$recorder_shell_pid" 2>/dev/null || break; sleep 1; done
    if kill -0 "$recorder_shell_pid" 2>/dev/null; then forced=1; kill "$recorder_shell_pid" 2>/dev/null || true; fi
    wait "$recorder_shell_pid" 2>/dev/null || wait_rc=$?
    printf 'signal_exit=%s\nwait_exit=%s\nforced=%s\n' "$signal_rc" "$wait_rc" "$forced" > "${recorder_dir:-$evidence}/recorder-exit.txt"
  fi
  recorder_pidfile=
  recorder_shell_pid=
  recorder_dir=
}
restore_rotation() {
  local key=$1 value=$2
  if [[ $value == null ]]; then adb shell settings delete system "$key" >/dev/null 2>&1 || true
  else adb shell settings put system "$key" "$value" >/dev/null 2>&1 || true; fi
}
cleanup() {
  stop_fixture_recorder
  restore_rotation user_rotation "$saved_user_rotation"
  restore_rotation accelerometer_rotation "$saved_auto_rotation"
  if [[ -n $saved_density ]]; then adb shell wm density "$saved_density" >/dev/null 2>&1 || true
  else adb shell wm density reset >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size | tr -d '\r' > "$evidence/size-after.txt"
adb shell wm density | tr -d '\r' > "$evidence/density-after.txt"
grep -Eq '(^|: )1080x2400$' "$evidence/size-after.txt" || { echo 'FAIL geometry' | tee "$evidence/status.txt"; exit 1; }
grep -Eq '(^|: )420$' "$evidence/density-after.txt" || { echo 'FAIL density' | tee "$evidence/status.txt"; exit 1; }
install_rc=0
adb install -r "$app" > "$evidence/install-app.txt" 2>&1 || install_rc=$?
printf '%s\n' "$install_rc" > "$evidence/install-app.exit"
[[ "$install_rc" == 0 ]] && grep -qx 'Success' "$evidence/install-app.txt" || { echo 'FAIL app install' | tee "$evidence/status.txt"; exit 1; }
install_rc=0
adb install -r "$test_apk" > "$evidence/install-test.txt" 2>&1 || install_rc=$?
printf '%s\n' "$install_rc" > "$evidence/install-test.exit"
[[ "$install_rc" == 0 ]] && grep -qx 'Success' "$evidence/install-test.txt" || { echo 'FAIL test install' | tee "$evidence/status.txt"; exit 1; }
verify_installed() {
  bash "$root/scripts/verify-keyguard-installed-apk.sh" "$1" "$2" "$evidence" "$3"
}
verify_installed com.fluvi.app "$app" app || { echo 'FAIL installed app identity' | tee "$evidence/status.txt"; exit 1; }
verify_installed com.fluvi.app.test "$test_apk" test || { echo 'FAIL installed test identity' | tee "$evidence/status.txt"; exit 1; }
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
  echo 'FAIL device preflight; no product conclusion' | tee "$evidence/status.txt"
  exit 1
fi
run_test() {
  local label=$1 method=$2 run_id=$3 test_mode=$4
  local dir="$evidence/$label" rc=0
  mkdir -p "$dir"
  printf 'source=%s\nrun_uuid=%s\nselector=%s\nmode=%s\n' "$source_sha" "$run_id" "$method" "$test_mode" > "$dir/identity.txt"
  adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || rc=1
  if [[ $label == first_composite_fixture ]]; then
    [[ $run_id =~ ^[0-9a-f-]{36}$ ]] || return 1
    adb shell screenrecord --help > "$dir/screenrecord-help.txt" 2>&1 || rc=1
    adb shell dumpsys display > "$dir/display-before.txt" 2>&1 || true
    adb shell dumpsys window > "$dir/window-before.txt" 2>&1 || true
    local remote_video="/sdcard/fluvi-r15-$run_id.mp4"
    recorder_pidfile="/data/local/tmp/fluvi-r15-$run_id.pid"
    recorder_dir="$dir"
    adb shell "sh -c 'echo \$\$ > $recorder_pidfile; exec screenrecord --verbose --time-limit 0 $remote_video'" > "$dir/recorder.txt" 2>&1 &
    recorder_shell_pid=$!
    local recorder_ready=0
    for _ in {1..20}; do
      if adb shell "test -s '$recorder_pidfile' && test -s '$remote_video'" >/dev/null 2>&1; then recorder_ready=1; break; fi
      kill -0 "$recorder_shell_pid" 2>/dev/null || break
      sleep 0.25
    done
    printf 'recorder_ready=%s\n' "$recorder_ready" > "$dir/recorder-status.txt"
    [[ $recorder_ready == 1 ]] || rc=1
  fi
  local instrument_rc=0
  timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" -e runUuid "$run_id" \
    -e r12Mode "$test_mode" -e class "$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
    > "$dir/instrumentation.txt" 2>&1 || instrument_rc=$?
  printf '%s\n' "$instrument_rc" > "$dir/command-exit.txt"
  [[ $instrument_rc == 0 ]] || rc=1
  if [[ $label == first_composite_fixture ]]; then
    stop_fixture_recorder
    if ! grep -Fxq 'signal_exit=0' "$dir/recorder-exit.txt" || ! grep -Fxq 'forced=0' "$dir/recorder-exit.txt"; then rc=1; fi
    adb shell dumpsys display > "$dir/display-after.txt" 2>&1 || true
    adb shell dumpsys window > "$dir/window-after.txt" 2>&1 || true
    if adb pull "$remote_video" "$dir/recording.mp4" > "$dir/pull-video.txt" 2>&1 && [[ -s $dir/recording.mp4 ]]; then
      sha256sum "$dir/recording.mp4" > "$dir/recording.sha256"
      if command -v ffprobe >/dev/null && command -v ffmpeg >/dev/null && python3 -c 'import PIL' >/dev/null 2>&1; then
        python3 "$root/scripts/keyguard-r15-video.py" --video "$dir/recording.mp4" --out "$dir/decoded" > "$dir/decode.txt" 2>&1 || rc=1
      else
        printf 'decoded=NOT_ESTABLISHED missing_ffmpeg_ffprobe_or_pillow\n' > "$dir/decode.txt"
        rc=1
      fi
    else
      printf 'video=UNOBSERVED\n' >> "$dir/recorder-status.txt"
      rc=1
    fi
  fi
  timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || rc=1
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
    > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || rc=1
  mkdir -p "$dir/probe"
  tar -xf "$dir/service-probe.tar" -C "$dir/probe" 2> "$dir/untar.stderr" || rc=1
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke \
    > "$dir/panel-probe.tar" 2> "$dir/panel-probe.stderr" || true
  sha256sum --check "$evidence/apks.sha256" > "$dir/apks-after-check.txt" 2>&1 || rc=1
  identity_rc=0
  bash "$root/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app "$app" "$dir" app-after > "$dir/installed-app-after-verdict.txt" 2>&1 || identity_rc=1
  bash "$root/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app.test "$test_apk" "$dir" test-after > "$dir/installed-test-after-verdict.txt" 2>&1 || identity_rc=1
  printf '%s\n' "$identity_rc" > "$dir/identity-after.exit"
  [[ "$identity_rc" == 0 ]] || rc=1
  return "$rc"
}
run_id=$(cat /proc/sys/kernel/random/uuid)
printf 'run_uuid=%s\n' "$run_id" >> "$evidence/manifest.txt"
result=0
if [[ "$scope" == r12_contract ]]; then
  # Run the actual Android Bitmap controls independently. Preserve the raw
  # runner transcript even on the reference's expected behavioral failure.
  financial_dir="$evidence/financial-orb-demand"
  mkdir -p "$financial_dir"
  adb shell pm list instrumentation > "$financial_dir/registered-runner.txt" 2>&1
  adb shell am force-stop com.fluvi.app > "$financial_dir/force-stop.txt" 2>&1
  financial_rc=0
  timeout -k 5s 260s adb shell am instrument -w -r \
    -e class com.fluvi.app.lockscreen.KeyguardFinancialOrbDemandInstrumentationTest \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
    > "$financial_dir/instrumentation.txt" 2>&1 || financial_rc=$?
  printf '%s\n' "$financial_rc" > "$financial_dir/command-exit.txt"
  timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$financial_dir/logcat.txt" 2>&1 || true
  if ! timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/r13-financial-pixels \
      > "$financial_dir/pixels.tar" 2> "$financial_dir/pixels.stderr"; then
    echo 'independent bitmap pixel archive unavailable' > "$financial_dir/pixels-status.txt"
  else
    mkdir -p "$financial_dir/pixels"
    if tar -xf "$financial_dir/pixels.tar" -C "$financial_dir/pixels"; then
      sha256sum "$financial_dir/pixels.tar" > "$financial_dir/pixels.sha256"
    else
      echo 'independent bitmap pixel archive invalid' > "$financial_dir/pixels-status.txt"
    fi
  fi
  financial_identity_rc=0
  bash "$root/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app "$app" "$financial_dir" app-after > "$financial_dir/installed-app-after-verdict.txt" 2>&1 || financial_identity_rc=1
  bash "$root/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app.test "$test_apk" "$financial_dir" test-after > "$financial_dir/installed-test-after-verdict.txt" 2>&1 || financial_identity_rc=1
  printf '%s\n' "$financial_identity_rc" > "$financial_dir/identity-after.exit"
  financial_named=0
  for method_name in constructionAndFirstDemandCountActualPaints concurrentFirstReadersShareOneRealBitmap demandPreservesIndependentReferencePixelsAndSemanticFields; do
    grep -Fxq "INSTRUMENTATION_STATUS: test=$method_name" "$financial_dir/instrumentation.txt" || financial_named=1
  done
  if [[ "$financial_rc" -eq 0 && "$financial_named" -eq 0 && "$financial_identity_rc" -eq 0 ]] && grep -Eq '^OK \(3 tests\)' "$financial_dir/instrumentation.txt"; then
    echo 'R13_T1=PASS (3 Android tests)' > "$financial_dir/status.txt"
  else
    echo 'R13_T1=FAIL_OR_INCOMPLETE; inspect raw assertion and actual paint count' > "$financial_dir/status.txt"
    result=1
  fi
  run_test financial_panel 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r13FinancialDemandAndPrivacyAcrossRetainedRouteChanges' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_STATIC || result=1
  run_test financial_widget 'com.fluvi.app.lockscreen.KeyguardFinancialSnapshotRemoteViewsInstrumentationTest#remoteViewsAndNotificationDelegateKeepRealPixelsAndText' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test financial_light 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r13FinancialWorkRetainsOwnedCountsInLight' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test financial_full 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r13FinancialWorkRetainsOwnedCountsInFull' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test financial_pressure 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r13FinancialWorkSurvivesPressureAndRemainsCaptureBounded' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test poster 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test static_panel 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r12StaticSurfaceMatchesFullAndNeutralReferenceOnRealPanel' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_STATIC || result=1
  run_test diagnostic_light 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r12SurfaceEvidenceRetainsItsShowOwnerInLight' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  run_test diagnostic_full 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r12SurfaceEvidenceRetainsItsShowOwnerInFull' "$(cat /proc/sys/kernel/random/uuid)" SURFACE_LIVE || result=1
  echo 'NOT ESTABLISHED: complete T1-T7 admission, lifecycle, privacy and independent real-service compositor oracle' >> "$evidence/status.txt"
else
  method='com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#fourRealWakeCyclesUseRequestedRoute'
  run_test timing "$method" "$run_id" "$mode" || result=1
  fixture="$evidence/timing/probe/files/keyguard-service-probe/r12-timing/$run_id/fixture.txt"
  capture="$evidence/timing/probe/files/keyguard-service-probe/r12-timing/$run_id/capture.txt"
  python3 "$root/scripts/keyguard-r12-candidate-oracle.py" --raw "$evidence/timing/instrumentation.txt" \
    --fixture "$fixture" --capture "$capture" --source "$source_sha" --mode "$mode" --run-id "$run_id" \
    > "$evidence/timing/verdict.txt" 2>&1 || result=1
  # This real service/cover fixture supplies attachment and raw screenshot
  # observations. It cannot pass the compositor row without the separately
  # collected, calibrated independent recording and owner-bound case record.
  run_test first_composite_fixture 'com.fluvi.app.lockscreen.KeyguardR15ServiceContractInstrumentationTest#firstCorrectServiceComposite' \
    "$(cat /proc/sys/kernel/random/uuid)" "$mode" || result=1
  echo 'NOT ESTABLISHED: separate calibrated real-service visual process and composite/privacy controls' >> "$evidence/status.txt"
fi
# A partial timing/panel pass cannot be substituted for independent service
# pixels, privacy and lifecycle evidence. Record individual rows and fail the
# scope while any required row is missing; the collector never manufactures a
# PASS from a producer callback or a single panel screenshot.
rows="$evidence/required-rows.txt"
printf 'source=%s scope=%s route=%s\n' "$source_sha" "$scope" "$mode" > "$rows"
test_row() {
  local label=$1 expected_method=$2 file="$evidence/$1/instrumentation.txt" rc_file="$evidence/$1/command-exit.txt"
  if [[ ! -f "$file" || ! -f "$rc_file" ]]; then
    printf '%s=NOT_ESTABLISHED\n' "$label" >> "$rows"
  elif [[ $(cat "$rc_file") == 0 && -f "$evidence/$1/identity-after.exit" && $(cat "$evidence/$1/identity-after.exit") == 0 ]] && grep -Fxq "INSTRUMENTATION_STATUS: test=$expected_method" "$file" && grep -Eq '^OK \(1 test\)' "$file"; then
    printf '%s=PASS\n' "$label" >> "$rows"
  else
    printf '%s=FAIL\n' "$label" >> "$rows"
  fi
}
if [[ "$scope" == r12_contract ]]; then
  cat "$financial_dir/status.txt" >> "$rows"
  test_row financial_panel r13FinancialDemandAndPrivacyAcrossRetainedRouteChanges
  test_row financial_widget remoteViewsAndNotificationDelegateKeepRealPixelsAndText
  test_row financial_light r13FinancialWorkRetainsOwnedCountsInLight
  test_row financial_full r13FinancialWorkRetainsOwnedCountsInFull
  test_row financial_pressure r13FinancialWorkSurvivesPressureAndRemainsCaptureBounded
  test_row poster r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases
  test_row static_panel r12StaticSurfaceMatchesFullAndNeutralReferenceOnRealPanel
  test_row diagnostic_light r12SurfaceEvidenceRetainsItsShowOwnerInLight
  test_row diagnostic_full r12SurfaceEvidenceRetainsItsShowOwnerInFull
else
  test_row timing fourRealWakeCyclesUseRequestedRoute
  test_row first_composite_fixture firstCorrectServiceComposite
fi
for required in r12_real_service_first_composite r12_real_service_privacy_downgrade r12_holder_lifecycle_races r12_selector_persistence r13_service_demand_burst; do
  printf '%s=NOT_ESTABLISHED\n' "$required" >> "$rows"
done
printf 'partial_observation_exit=%s\n' "$result" >> "$evidence/status.txt"
if [[ "$result" -ne 0 ]] || grep -Eq '=(FAIL|NOT_ESTABLISHED)' "$rows"; then
  printf 'full_scope=FAIL_INCOMPLETE\n' >> "$evidence/status.txt"
  exit 1
fi
printf 'full_scope=PASS\n' >> "$evidence/status.txt"
