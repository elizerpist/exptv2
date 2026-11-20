#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
source_sha=$(git rev-parse HEAD)
[[ $source_sha == "${GITHUB_SHA:?missing exact harness source}" ]]
[[ -z $(git status --porcelain --untracked-files=no) ]]
requested=${FLUVI_R14_CASE:?missing declared isolated case}
case "$requested" in matched-negative|matched-negative-disabled|exclusion|fresh-main|late-only|baseline-full|r12-ordered|legacy) ;; *) echo 'unknown stock-resume case' >&2; exit 64;; esac
evidence="$root/android/keyguard-r14-r14_recovery_stock/$requested"
[[ ! -e $evidence ]]
mkdir -p "$evidence"
app="$root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks.sha256"
cat > "$evidence/case-list.txt" <<'CASES'
matched-negative com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#matchedNegativeForensicStages
matched-negative-disabled com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#matchedNegativeProbeDisabledControl
exclusion com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#supersededExternalEventSuppressesOnlyTheRecoveryAdd
fresh-main com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#freshMainSuccessorRestoresExactlyOnce
late-only com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#postAttachOnlyExclusionNeverDefersPriorAdmission
baseline-full com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#r14FullPressureRetainsEverySelectedEpisode
r12-ordered com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply
legacy com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles
CASES
cat "$evidence/case-list.txt"
{
 printf 'scope=stock-resume\nharness_sha=%s\nstock_runtime=e3a3ef5ca6370c3eca573f699ff21168c24df9fc\n' "$source_sha"
 adb shell getprop ro.build.fingerprint
 adb shell getprop ro.product.cpu.abi
 adb shell getprop ro.build.version.sdk
 adb shell wm size
 adb shell wm density
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
result=0
contaminated=0
while read -r label selector; do
 [[ $label == "$requested" ]] || continue
 dir="$evidence/$label"
 mkdir -p "$dir"
 if [[ $contaminated == 1 ]]; then
   printf '%s=NOT_RUN_ENVIRONMENT_RESTORATION_UNPROVED\n' "$label" | tee -a "$evidence/status.txt"
   result=1
   continue
 fi
 id=$(cat /proc/sys/kernel/random/uuid)
 printf 'source=%s\nharness=%s\nrun_uuid=%s\nselector=%s\n' "$source_sha" "$source_sha" "$id" "$selector" > "$dir/identity.txt"
 adb shell am force-stop com.fluvi.app > "$dir/force-stop.txt" 2>&1 || true
 limit=260
 if [[ $label == legacy ]]; then limit=390; fi
 timeout -k 5s "${limit}s" adb shell am instrument -w -r -e sourceSha "$source_sha" -e harnessSha "$source_sha" \
   -e runUuid "$id" -e r12Mode SURFACE_LIVE -e class "$selector" \
   com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 &
 command_pid=$!
 if [[ $label == matched-negative ]]; then
   for index in 1 2; do
     probe="files/keyguard-service-probe/r14/$id/$label/forensic-snapshot-$index.txt"
     found=0
     while kill -0 "$command_pid" 2>/dev/null; do
       if adb shell run-as com.fluvi.app test -f "$probe" >/dev/null 2>&1; then found=1; break; fi
       sleep 1
     done
     if [[ $found == 1 ]]; then
       pid=$(adb shell pidof com.fluvi.app | tr -d '\r' | awk '{print $1}')
       printf 'pid=%s host_utc=%s\n' "$pid" "$(date -u +%FT%TZ)" > "$dir/debuggerd-$index.meta"
       if [[ $pid =~ ^[0-9]+$ ]]; then
         timeout -k 2s 8s adb shell debuggerd -j "$pid" > "$dir/debuggerd-$index.txt" 2> "$dir/debuggerd-$index.stderr" || printf 'exit=%s\n' "$?" >> "$dir/debuggerd-$index.meta"
       else printf 'unavailable=no_app_pid\n' >> "$dir/debuggerd-$index.meta"; fi
     else printf 'unavailable=no_outstanding_stall_snapshot\n' > "$dir/debuggerd-$index.meta"; break; fi
   done
 fi
 rc=0
 wait "$command_pid" || rc=$?
 printf '%s\n' "$rc" > "$dir/command-exit.txt"
 timeout -k 2s 20s adb logcat -b all -d -v monotonic > "$dir/logcat.txt" 2>&1 || true
 grep -Eo '/data/anr/anr_[0-9_-]+' "$dir/logcat.txt" | sort -u > "$dir/anr-paths.txt" || true
 while read -r path; do
   [[ $path =~ ^/data/anr/anr_[0-9_-]+$ ]] || continue
   base=${path##*/}
   timeout -k 2s 8s adb exec-out cat "$path" > "$dir/$base.txt" 2> "$dir/$base.stderr" || printf 'unavailable exit=%s\n' "$?" >> "$dir/$base.stderr"
 done < "$dir/anr-paths.txt"
 if [[ -s $dir/anr-paths.txt ]]; then
   timeout -k 2s 8s adb shell dumpsys dropbox --print data_app_anr > "$dir/dropbox-anr.txt" 2> "$dir/dropbox-anr.stderr" || printf 'unavailable exit=%s\n' "$?" >> "$dir/dropbox-anr.stderr"
 fi
 timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-service-probe > "$dir/service-probe.tar" 2> "$dir/service-probe.stderr" || true
 mkdir -p "$dir/probe"
 tar -xf "$dir/service-probe.tar" -C "$dir/probe" 2> "$dir/untar.stderr" || true
 sha256sum --check "$evidence/apks.sha256" > "$dir/apks-after-check.txt" 2>&1 || true
 method=${selector##*#}
 fixture="$dir/probe/files/keyguard-service-probe/r14/$id/$label/fixture.txt"
 if [[ $label != baseline-full && $label != r12-ordered && $label != legacy ]]; then
   if [[ ! -s $fixture ]] || ! grep -q 'stage=CLEANUP_OK.*verify_secure_settings' "$fixture" || ! grep -q 'stage=CLEANUP_OK.*verify_preferences' "$fixture" || ! grep -q 'stage=CLEANUP_OK.*verify_lock' "$fixture"; then
     contaminated=1
     printf 'environment_restoration=UNPROVED; subsequent cases require fresh disposable AVD\n' >> "$dir/status.txt"
   fi
 fi
 if ! grep -Fxq "INSTRUMENTATION_STATUS: test=$method" "$dir/instrumentation.txt"; then
   verdict=NOT_ESTABLISHED_NO_NAMED_TEST
 elif [[ $label == exclusion || $label == fresh-main || $label == late-only ]]; then
   queue="$(dirname "$fixture")/queue-and-reads.txt"
   if python3 "$root/scripts/r14_stock_oracle.py" --case "$label" --fixture "$fixture" --queue "$queue" --raw "$dir/instrumentation.txt" --source "$source_sha" --run-id "$id" > "$dir/oracle.txt" 2>&1; then
     if [[ $label == exclusion ]] || { [[ $rc == 0 ]] && grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; }; then
       verdict=$(head -1 "$dir/oracle.txt")
     else verdict=INVALID_CONTROL_FAILED; fi
   else verdict=INVALID_OR_NOT_ESTABLISHED; fi
 elif [[ $rc == 0 ]] && grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then
   if [[ $label == matched-negative* ]]; then verdict=NOT_REPRODUCED_OR_READ_COMPLETED_INSPECT_TRACE; else verdict=PASS; fi
 else verdict=FAIL_OR_NOT_ESTABLISHED; fi
 printf '%s=%s\n' "$label" "$verdict" | tee -a "$evidence/status.txt"
 case "$verdict" in VALID_STOCK_RED|VALID_CONTROL|PASS|NOT_REPRODUCED_OR_READ_COMPLETED_INSPECT_TRACE) ;; *) result=1;; esac
done < "$evidence/case-list.txt"
printf 'candidate_qualification=NOT_ESTABLISHED (requires RED and both independent controls plus candidate gates)\n' >> "$evidence/status.txt"
exit "$result"
