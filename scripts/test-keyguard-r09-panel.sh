#!/usr/bin/env bash
set -euo pipefail

# Fixed R09 focused diagnostic. This harness cannot accept a source ref or
# command: the baseline is the literal physical R08 source, the candidate is
# the dispatched checkout. It never invokes the service/trace scripts.
root=$(git rev-parse --show-toplevel)
scope=${FLUVI_R09_SCOPE:-}
case "$scope" in
  r09_panel_baseline)
    target="$root/r09-baseline"
    expected=4464cd0f5fe7abf8eab1e8b876063bdbbf37350a
    ;;
  r09_panel_candidate)
    target="$root"
    expected=${GITHUB_SHA:?candidate dispatch must supply GITHUB_SHA}
    ;;
  *) printf 'Unsupported R09 panel scope: %s\n' "$scope" >&2; exit 64 ;;
esac

actual=$(git -C "$target" rev-parse HEAD)
harness=$(git -C "$root" rev-parse HEAD)
[[ "$actual" == "$expected" ]] || { printf 'Refusing source mismatch: %s != %s\n' "$actual" "$expected" >&2; exit 1; }
[[ -z $(git -C "$target" status --porcelain --untracked-files=no) ]] || { printf 'Tracked target changes are not allowed\n' >&2; exit 1; }
evidence="$root/android/keyguard-r09-panel"
[[ ! -e "$evidence" ]] || { printf 'Refusing to overwrite: %s\n' "$evidence" >&2; exit 1; }
mkdir -p "$evidence"
class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest
methods=(
  stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges
  isolatedOrbStaleFirstCommitCannotUndoSameRootPrivacyOrSizeReplacement
  oldUsesPreventSuccessorButCurrentOrbKeepsMoving
  isolatedOrbRevocationDrainsLateSteadyPublication
  isolatedOrbSameLeaseLayoutRetainsAcceptedSteadyGrant
  isolatedOrbFirstDirectAppearsWhileNextRootDrawIsWithheld
)
# Candidate-only controls are deliberately separate from the unmodified R08
# baseline. Add the registered R09 methods here with their implementation.
if [[ "$scope" == r09_panel_candidate ]]; then
  methods+=(r09RetiredChildUnlinksAfterOrderedClearWithReleaseHeld
    r09MixedSizeHeldOldUseLeavesCurrentSuccessorCapacity
    r09UnchangedPlacementSkipsRedundantTransactions
    r09NeutralPrivacyTransitionHasPositivePixels)
fi
selector=''
for method in "${methods[@]}"; do
  selector+="${selector:+,}${class}#${method}"
  printf '%s#%s\n' "$class" "$method" >> "$evidence/requested-tests.txt"
done
device_api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
device_abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
{
  printf 'scope=%s\nharness_sha=%s\napplication_sha=%s\noverlay=none\n' "$scope" "$harness" "$actual"
  printf 'device_api=%s\ndevice_abi=%s\n' "$device_api" "$device_abi"
  printf 'device_fingerprint='; adb shell getprop ro.build.fingerprint | tr -d '\r'
  adb shell wm size
  adb shell wm density
} > "$evidence/manifest.txt"
[[ "$device_api" == 35 && "$device_abi" == x86_64 ]] || { printf 'Expected API35/x86_64, got %s/%s\n' "$device_api" "$device_abi" >> "$evidence/status.txt"; exit 1; }
app="$target/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$target/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app" && test -s "$test_apk"
sha256sum "$app" "$test_apk" > "$evidence/apks-before.sha256"
result=0
preflight=0
(cd "$target" && timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$evidence/preflight") || preflight=$?
printf 'preflight_result=%s\n' "$preflight" > "$evidence/status.txt"
if (( preflight == 0 )); then
  set +e
  (cd "$target/android" && ./gradlew :app:connectedDebugAndroidTest --no-daemon \
    -Pandroid.injected.androidTest.leaveApksInstalledAfterRun=true \
    "-Pandroid.testInstrumentationRunnerArguments.class=$selector") > "$evidence/gradle.log" 2>&1
  result=$?
  set -e
else
  result=1
fi
printf 'gradle_result=%s\n' "$result" >> "$evidence/status.txt"
# Preserve all observations even for a failed assertion or preflight.
set +e
mkdir -p "$evidence/results" "$evidence/reports"
cp -a "$target/build/app/outputs/androidTest-results/connected/." "$evidence/results/" 2> "$evidence/results-copy.stderr"
cp -a "$target/build/app/reports/androidTests/connected/." "$evidence/reports/" 2> "$evidence/reports-copy.stderr"
timeout -k 2s 5s adb shell dumpsys window > "$evidence/window-after.txt" 2> "$evidence/window-after.stderr"
window_rc=$?
timeout -k 2s 5s adb exec-out screencap -p > "$evidence/screen-after.png" 2> "$evidence/screen-after.stderr"
screen_rc=$?
timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$evidence/logcat.txt" 2> "$evidence/logcat.stderr"
logcat_rc=$?
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$evidence/material-smoke.tar" 2> "$evidence/material-smoke-pull.stderr"
sha256sum --check "$evidence/apks-before.sha256" > "$evidence/apks-after-check.txt" 2>&1
identity=$?
set -e
printf 'apk_identity_result=%s\nwindow_result=%s\nscreen_result=%s\nlogcat_result=%s\n' "$identity" "$window_rc" "$screen_rc" "$logcat_rc" >> "$evidence/status.txt"
if (( identity != 0 || window_rc != 0 || screen_rc != 0 || logcat_rc != 0 )) || [[ ! -s "$evidence/screen-after.png" || ! -s "$evidence/window-after.txt" ]]; then result=1; fi
# Android instrumentation may report a successful command with skipped or
# unselected tests; the exact named tests must each have a non-skipped result.
python3 - "$evidence" <<'PY' || result=1
import pathlib, sys, xml.etree.ElementTree as ET
root=pathlib.Path(sys.argv[1]); expected=[x.split('#',1)[1] for x in (root/'requested-tests.txt').read_text().splitlines()]
found={}
for path in (root/'results').rglob('TEST-*.xml'):
    for case in ET.parse(path).iter('testcase'):
        name=case.get('name','').split('[',1)[0]
        if name in expected:
            found.setdefault(name,[]).append('SKIPPED' if case.find('skipped') is not None else 'FAIL' if case.find('failure') is not None or case.find('error') is not None else 'PASS')
with (root/'executed-tests.txt').open('w') as out:
    for name in expected: print(name, ','.join(found.get(name,['NOT_RUN'])), file=out)
if any(found.get(name)!=['PASS'] for name in expected): sys.exit(1)
PY
printf 'aggregate_result=%s\n' "$result" >> "$evidence/status.txt"
exit "$result"
