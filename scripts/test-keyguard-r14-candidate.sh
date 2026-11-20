#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
source_sha=$(git rev-parse HEAD)
[[ $source_sha == "${GITHUB_SHA:?missing candidate source}" ]]
[[ -z $(git status --porcelain --untracked-files=no) ]]
requested=${FLUVI_R14_CASE:?missing isolated case}
evidence="$root/android/keyguard-r14-candidate/$requested"
[[ ! -e $evidence ]]
mkdir -p "$evidence"
cat > "$evidence/case-list.txt" <<'CASES'
exclusion com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#supersededExternalEventSuppressesOnlyTheRecoveryAdd
fresh-main com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#freshMainSuccessorRestoresExactlyOnce
late-only com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#postAttachOnlyExclusionNeverDefersPriorAdmission
real-return com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#temporaryRealOcclusionReturnsToMain
terminal-stale com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#terminalWithdrawalDiscardsPendingWork
pressure-light com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14LightPressureRetainsEverySelectedEpisode
pressure-full com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14FullPressureRetainsEverySelectedEpisode
pressure-combined com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget
paired-light com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14PairedEpisodesWithFinancialPressureLight
paired-full com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14PairedEpisodesWithFinancialPressureFull
deferred-light com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14DeferredRecoveryWithoutShowLight
deferred-full com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14DeferredRecoveryWithoutShowFull
CASES
cat "$evidence/case-list.txt"
selector=$(awk -v label="$requested" '$1==label {print $2}' "$evidence/case-list.txt")
[[ -n $selector ]]
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
{
 printf 'scope=r14-candidate\nsource_sha=%s\ncase=%s\n' "$source_sha" "$requested"
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
 echo 'FAIL device preflight; no product conclusion' > "$evidence/status.txt"
 exit 1
fi
id=$(cat /proc/sys/kernel/random/uuid)
printf 'source=%s\nharness=%s\nrun_uuid=%s\nselector=%s\n' "$source_sha" "$source_sha" "$id" "$selector" > "$evidence/identity.txt"
adb shell am force-stop com.fluvi.app > "$evidence/force-stop.txt" 2>&1 || true
rc=0
timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" \
 -e runUuid "$id" -e r12Mode SURFACE_LIVE -e r14Expected candidate -e class "$selector" \
 com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$evidence/instrumentation.txt" 2>&1 || rc=$?
printf '%s\n' "$rc" > "$evidence/command-exit.txt"
timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$evidence/logcat.txt" 2>&1 || true
timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe > "$evidence/service-probe.tar" 2> "$evidence/service-probe.stderr" || true
mkdir -p "$evidence/probe"
tar -xf "$evidence/service-probe.tar" -C "$evidence/probe" 2> "$evidence/untar.stderr" || true
sha256sum --check "$evidence/apks.sha256" > "$evidence/apks-after-check.txt" 2>&1 || true
method=${selector##*#}
if ! grep -Fxq "INSTRUMENTATION_STATUS: test=$method" "$evidence/instrumentation.txt"; then
 echo 'NOT_ESTABLISHED_NO_NAMED_TEST' > "$evidence/status.txt"; exit 1
fi
if [[ $requested == exclusion || $requested == fresh-main || $requested == late-only ]]; then
 fixture="$evidence/probe/files/keyguard-service-probe/r14/$id/$requested/fixture.txt"
 queue="$(dirname "$fixture")/queue-and-reads.txt"
 capture="$(dirname "$fixture")/capture.txt"
 if ! python3 "$root/scripts/r14_candidate_oracle.py" --case "$requested" --fixture "$fixture" --queue "$queue" --capture "$capture" --raw "$evidence/instrumentation.txt" --source "$source_sha" --run-id "$id" > "$evidence/oracle.txt" 2>&1; then
   echo 'INVALID_OR_NOT_ESTABLISHED' > "$evidence/status.txt"; exit 1
 fi
fi
if [[ $rc == 0 ]] && grep -Eq '^OK \(1 test\)' "$evidence/instrumentation.txt"; then
 echo 'CASE_PASS_NOT_FULL_QUALIFICATION' > "$evidence/status.txt"
else
 echo 'FAIL_OR_NOT_ESTABLISHED' > "$evidence/status.txt"; exit 1
fi
