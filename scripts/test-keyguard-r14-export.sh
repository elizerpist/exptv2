#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
source_sha=$(git -C "$root" rev-parse HEAD)
[[ "$source_sha" == "${GITHUB_SHA:?missing exact source}" ]]
[[ -z $(git -C "$root" status --porcelain --untracked-files=no) ]]
evidence="$root/android/keyguard-r14-export"
[[ ! -e "$evidence" ]]
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
{
  printf 'scope=export-pressure\nsource_sha=%s\n' "$source_sha"
  adb shell getprop ro.build.fingerprint
  adb shell getprop ro.product.cpu.abi
  adb shell getprop ro.build.version.sdk
  adb shell wm size
  adb shell wm density
  adb shell pm list instrumentation
} > "$evidence/manifest.txt"
[[ $(adb shell getprop ro.build.version.sdk | tr -d '\r') == 35 ]]
[[ $(adb shell getprop ro.product.cpu.abi | tr -d '\r') == x86_64 ]]
adb shell wm density 420
trap 'adb shell wm density reset >/dev/null 2>&1 || true' EXIT
[[ $(adb shell wm size | tr -d '\r' | tail -1) == *1080x2400 ]]
[[ $(adb shell wm density | tr -d '\r' | tail -1) == *420 ]]
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
adb shell pm list instrumentation > "$evidence/registered-runner.txt"
grep -Fq 'com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$evidence/registered-runner.txt"
for pair in "com.fluvi.app:$app:app" "com.fluvi.app.test:$test_apk:test"; do
  IFS=: read -r package binary label <<< "$pair"
  path=$(adb shell pm path "$package" | tr -d '\r' | sed -n 's/^package://p')
  [[ $path == /*/base.apk ]]
  expected=$(sha256sum "$binary" | cut -d ' ' -f 1)
  actual=$(timeout -k 2s 30s adb exec-out cat "$path" | sha256sum | cut -d ' ' -f 1)
  printf 'expected=%s installed=%s\n' "$expected" "$actual" > "$evidence/installed-$label-sha256.txt"
  [[ $expected == "$actual" ]]
done
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
  echo 'FAIL device preflight; no product conclusion' > "$evidence/status.txt"; exit 1
fi
result=0
run_case() {
  local label=$1 method=$2 id dir rc=0
  id=$(cat /proc/sys/kernel/random/uuid)
  dir="$evidence/$label"
  mkdir -p "$dir"
  printf 'source=%s\nrun_uuid=%s\nselector=%s\n' "$source_sha" "$id" "$method" > "$dir/identity.txt"
  adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || true
  timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" \
    -e runUuid "$id" -e class "com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#$method" \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$dir/command-exit.txt"
  timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
    > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || true
  mkdir -p "$dir/probe"
  tar -xf "$dir/service-probe.tar" -C "$dir/probe" 2> "$dir/untar.stderr" || true
  if [[ $rc == 0 ]] && grep -Fxq "INSTRUMENTATION_STATUS: test=$method" "$dir/instrumentation.txt" && grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then
    printf '%s=PASS\n' "$label" >> "$evidence/status.txt"
  else
    printf '%s=FAIL_OR_NOT_ESTABLISHED\n' "$label" >> "$evidence/status.txt"
    result=1
  fi
}
run_case light r14LightPressureRetainsEverySelectedEpisode
run_case full r14FullPressureRetainsEverySelectedEpisode
run_case combined lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget
run_case paired-light r14PairedEpisodesWithFinancialPressureLight
run_case paired-full r14PairedEpisodesWithFinancialPressureFull
run_case financial r13FinancialWorkSurvivesPressureAndRemainsCaptureBounded
run_case surface-light r12SurfaceEvidenceRetainsItsShowOwnerInLight
run_case surface-full r12SurfaceEvidenceRetainsItsShowOwnerInFull
run_case hide-commit firstDirectAndHideCommitEvidenceKeepTheirOriginalOperations
run_case recovery-light r08LightRecoveryExportRetainsItsOwnerAndBudget
run_case recovery-full r08FullRecoveryExportRetainsItsOwnerAndBudget
printf 'candidate_qualification=NOT_ESTABLISHED (export-only source)\n' >> "$evidence/status.txt"
exit "$result"
