#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
scope=${FLUVI_R14_SCOPE:?missing R14 stock/candidate scope}
case "$scope" in r14_recovery_stock|r14_recovery_candidate) ;; *) echo 'invalid R14 scope' >&2; exit 64;; esac
source_sha=$(git -C "$root" rev-parse HEAD)
[[ $source_sha == "${GITHUB_SHA:?missing exact source}" ]]
[[ -z $(git -C "$root" status --porcelain --untracked-files=no) ]]
evidence="$root/android/keyguard-r14-$scope"
[[ ! -e "$evidence" ]]
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
{
  printf 'scope=%s\nsource_sha=%s\nstock_runtime=e3a3ef5ca6370c3eca573f699ff21168c24df9fc\n' "$scope" "$source_sha"
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
adb shell wm size | tr -d '\r' > "$evidence/size.txt"
adb shell wm density | tr -d '\r' > "$evidence/density.txt"
grep -Eq '(^|: )1080x2400$' "$evidence/size.txt"
grep -Eq '(^|: )420$' "$evidence/density.txt"
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
adb shell pm list instrumentation > "$evidence/registered-runner.txt"
grep -Fq 'com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$evidence/registered-runner.txt"
for pair in "com.fluvi.app:$app:app" "com.fluvi.app.test:$test_apk:test"; do
  IFS=: read -r package binary label <<< "$pair"
  adb shell pm path "$package" | tr -d '\r' > "$evidence/installed-$label-path.txt"
  [[ $(wc -l < "$evidence/installed-$label-path.txt") -eq 1 ]]
  path=$(sed -n 's/^package://p' "$evidence/installed-$label-path.txt")
  [[ $path == /*/base.apk ]]
  expected=$(sha256sum "$binary" | cut -d ' ' -f 1)
  actual=$(timeout -k 2s 30s adb exec-out cat "$path" | sha256sum | cut -d ' ' -f 1)
  printf 'expected=%s installed=%s\n' "$expected" "$actual" > "$evidence/installed-$label-sha256.txt"
  [[ $expected == "$actual" ]]
done
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
  echo 'FAIL device preflight; no product conclusion' > "$evidence/status.txt"; exit 1
fi
run_case() {
  local label=$1 selector=$2 id dir rc=0 limit=260
  # The existing real-service scenario owns its original 330 s deadline.
  if [[ $label == service-occlusion ]]; then limit=390; fi
  id=$(cat /proc/sys/kernel/random/uuid)
  dir="$evidence/$label"
  mkdir -p "$dir"
  printf 'source=%s\nrun_uuid=%s\nselector=%s\n' "$source_sha" "$id" "$selector" > "$dir/identity.txt"
  adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || true
  timeout -k 5s "${limit}s" adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" \
    -e runUuid "$id" -e r12Mode SURFACE_LIVE -e class "$selector" \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$dir/command-exit.txt"
  timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
  timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe \
    > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || true
  mkdir -p "$dir/probe"
  tar -xf "$dir/service-probe.tar" -C "$dir/probe" 2> "$dir/untar.stderr" || true
  sha256sum --check "$evidence/apks.sha256" > "$dir/apks-after-check.txt" 2>&1 || true
}
if [[ ${FLUVI_R14_TERMINAL_ONLY:-0} == 1 ]]; then
  run_case terminal-stale 'com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#terminalWithdrawalDiscardsPendingWork'
elif [[ ${FLUVI_R14_T3_ONLY:-0} == 1 ]]; then
  run_case real-return 'com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#temporaryRealOcclusionReturnsToMain'
else
run_case exclusion 'com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#supersededExternalEventSuppressesOnlyTheRecoveryAdd'
run_case fresh-main 'com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#freshMainSuccessorRestoresExactlyOnce'
run_case late-only 'com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#postAttachOnlyExclusionNeverDefersPriorAdmission'
run_case pressure 'com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget'
if [[ ${FLUVI_R14_CONTROLS_ONLY:-0} != 1 ]]; then
  run_case ordered 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply'
  run_case service-occlusion 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles'
  run_case natural 'com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#fourRealWakeCyclesUseRequestedRoute'
fi
fi
result=0
labels=(exclusion fresh-main late-only pressure ordered service-occlusion natural)
if [[ ${FLUVI_R14_CONTROLS_ONLY:-0} == 1 ]]; then labels=(exclusion fresh-main late-only pressure); fi
if [[ ${FLUVI_R14_T3_ONLY:-0} == 1 ]]; then labels=(real-return); fi
if [[ ${FLUVI_R14_TERMINAL_ONLY:-0} == 1 ]]; then labels=(terminal-stale); fi
for label in "${labels[@]}"; do
  transcript="$evidence/$label/instrumentation.txt"
  id=$(sed -n 's/^run_uuid=//p' "$evidence/$label/identity.txt")
  case "$label" in
    terminal-stale) method=terminalWithdrawalDiscardsPendingWork ;;
    real-return) method=temporaryRealOcclusionReturnsToMain ;;
    exclusion) method=supersededExternalEventSuppressesOnlyTheRecoveryAdd ;;
    fresh-main) method=freshMainSuccessorRestoresExactlyOnce ;;
    late-only) method=postAttachOnlyExclusionNeverDefersPriorAdmission ;;
    pressure) method=lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget ;;
    ordered) method=r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply ;;
    service-occlusion) method=connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles ;;
    natural) method=fourRealWakeCyclesUseRequestedRoute ;;
  esac
  if ! grep -Fxq "INSTRUMENTATION_STATUS: test=$method" "$transcript"; then
    echo "$label=NOT_ESTABLISHED (named case not executed)" >> "$evidence/status.txt"; result=1; continue
  fi
  if [[ $label == exclusion && $scope == r14_recovery_stock ]]; then
    fixture="$evidence/$label/probe/files/keyguard-service-probe/r14/$id/exclusion/fixture.txt"
    image="$evidence/$label/probe/files/keyguard-service-probe/r14/$id/exclusion/before-a-occluder.png"
    before="$evidence/$label/probe/files/keyguard-service-probe/r14/$id/exclusion/before-a-before.png"
    if [[ -s $fixture && -s $image && -s $before ]] && grep -q 'stage=INDEPENDENT_EXCLUSION.*visual=true' "$fixture" && \
       grep -q 'stage=RESULT.*readDecision=HIDDEN_OCCLUDED.*aAttached=true' "$fixture" && grep -q 'pendingTrigger=authorityReconcile:attach' "$fixture" && \
       grep -q 'R14 candidate assertion: pending B must suppress the excess A add' "$transcript"; then
      echo "$label=VALID_STOCK_RED (candidate assertion fails on actual extra add)" >> "$evidence/status.txt"
    else
      echo "$label=INVALID_OR_NOT_ESTABLISHED (inspect fixture, image and assertion)" >> "$evidence/status.txt"; result=1
    fi
  elif [[ $(cat "$evidence/$label/command-exit.txt") == 0 ]] && grep -Eq '^OK \(1 test\)' "$transcript"; then
    echo "$label=PASS" >> "$evidence/status.txt"
  else
    echo "$label=FAIL_OR_NOT_ESTABLISHED" >> "$evidence/status.txt"; result=1
  fi
done
# A valid controlled RED or a passing scoped subset is not the missing
# independent compositor/privacy and complete delivery qualification.
echo 'qualification=NOT_ESTABLISHED (real compositor/privacy/lifecycle aggregate remains mandatory)' >> "$evidence/status.txt"
exit "$result"
