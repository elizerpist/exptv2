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
adb shell wm density 420
trap 'adb shell wm density reset >/dev/null 2>&1 || true' EXIT
adb shell wm size | tr -d '\r' > "$evidence/size-after.txt"
adb shell wm density | tr -d '\r' > "$evidence/density-after.txt"
grep -Eq '(^|: )1080x2400$' "$evidence/size-after.txt" || { echo 'FAIL geometry' | tee "$evidence/status.txt"; exit 1; }
grep -Eq '(^|: )420$' "$evidence/density-after.txt" || { echo 'FAIL density' | tee "$evidence/status.txt"; exit 1; }
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
verify_installed() {
  local package=$1 expected_file=$2 name=$3 installed_path expected actual
  adb shell pm path "$package" | tr -d '\r' > "$evidence/installed-$name-path.txt"
  [[ $(wc -l < "$evidence/installed-$name-path.txt") -eq 1 ]] || return 1
  installed_path=$(sed -n 's/^package://p' "$evidence/installed-$name-path.txt")
  [[ "$installed_path" == /*/base.apk ]] || return 1
  expected=$(sha256sum "$expected_file" | cut -d ' ' -f 1)
  actual=$(timeout -k 2s 30s adb exec-out cat "$installed_path" | sha256sum | cut -d ' ' -f 1)
  printf 'expected=%s installed=%s\n' "$expected" "$actual" > "$evidence/installed-$name-sha256.txt"
  [[ "$expected" == "$actual" ]]
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
  adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || rc=1
  timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" -e runUuid "$run_id" \
    -e r12Mode "$test_mode" -e class "$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
    > "$dir/instrumentation.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$dir/command-exit.txt"
  timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || rc=1
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
    > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || rc=1
  mkdir -p "$dir/probe"
  tar -xf "$dir/service-probe.tar" -C "$dir/probe" 2> "$dir/untar.stderr" || rc=1
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke \
    > "$dir/panel-probe.tar" 2> "$dir/panel-probe.stderr" || true
  sha256sum --check "$evidence/apks.sha256" > "$dir/apks-after-check.txt" 2>&1 || rc=1
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
  if [[ "$financial_rc" -eq 0 ]] && grep -Eq '^OK \(3 tests\)' "$financial_dir/instrumentation.txt"; then
    echo 'R13_T1=PASS (3 Android tests)' > "$financial_dir/status.txt"
  else
    echo 'R13_T1=FAIL_OR_INCOMPLETE; inspect raw assertion and actual paint count' > "$financial_dir/status.txt"
    result=1
  fi
  run_test poster 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases' "$run_id" SURFACE_LIVE || result=1
  run_test static_panel 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r12StaticSurfaceMatchesFullAndNeutralReferenceOnRealPanel' "$run_id" SURFACE_STATIC || result=1
  run_test diagnostic_light 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r12SurfaceEvidenceRetainsItsShowOwnerInLight' "$run_id" SURFACE_LIVE || result=1
  run_test diagnostic_full 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r12SurfaceEvidenceRetainsItsShowOwnerInFull' "$run_id" SURFACE_LIVE || result=1
  echo 'NOT ESTABLISHED: complete T1-T7 admission, lifecycle, privacy and independent real-service compositor oracle' >> "$evidence/status.txt"
else
  method='com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#fourRealWakeCyclesUseRequestedRoute'
  run_test timing "$method" "$run_id" "$mode" || result=1
  fixture="$evidence/timing/probe/files/keyguard-service-probe/r12-timing/$run_id/fixture.txt"
  capture="$evidence/timing/probe/files/keyguard-service-probe/r12-timing/$run_id/capture.txt"
  python3 "$root/scripts/keyguard-r12-candidate-oracle.py" --raw "$evidence/timing/instrumentation.txt" \
    --fixture "$fixture" --capture "$capture" --source "$source_sha" --mode "$mode" --run-id "$run_id" \
    > "$evidence/timing/verdict.txt" 2>&1 || result=1
  echo 'NOT ESTABLISHED: separate calibrated real-service visual process and composite/privacy controls' >> "$evidence/status.txt"
fi
# A partial timing/panel pass cannot be substituted for the required product
# scope. Keep it red and preserve all collected evidence for the reviewer.
printf 'partial_observation_exit=%s\nfull_scope=FAIL_INCOMPLETE\n' "$result" >> "$evidence/status.txt"
exit 1
