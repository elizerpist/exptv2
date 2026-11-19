#!/usr/bin/env bash
set -euo pipefail

# The harness is a pinned revision, distinct from its stock R11 app worktree.
root=$(git rev-parse --show-toplevel)
harness=$(git rev-parse HEAD)
baseline=1d19624751169e3af0270b151378cdfcdf1a1129
app_root=${FLUVI_R12_APP_DIR:-$root}
app_sha=$(git -C "$app_root" rev-parse HEAD)
[[ "$app_sha" == "$baseline" ]] || { echo 'application is not the stock R11 checkout' >&2; exit 1; }
allowed=android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt
[[ $(git -C "$app_root" diff --name-only "$baseline") == "$allowed" ]] || { echo 'stock overlay is not the single audited androidTest file' >&2; exit 1; }
cmp "$root/$allowed" "$app_root/$allowed" || { echo 'test overlay differs from pinned harness' >&2; exit 1; }
[[ -z $(git -C "$app_root" ls-files --others --exclude-standard) ]] || { echo 'untracked app source in stock checkout' >&2; exit 1; }
evidence="$root/android/keyguard-r12-admission-baseline"
[[ ! -e "$evidence" ]] || { echo 'refusing to overwrite evidence' >&2; exit 1; }
mkdir -p "$evidence"
app="$app_root/build/app/outputs/apk/debug/app-debug.apk"
test_apk="$app_root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
test -s "$app"
test -s "$test_apk"
run=$(python3 -c 'import uuid; print(uuid.uuid4())')
app_hash=$(sha256sum "$app" | cut -d' ' -f1)
test_hash=$(sha256sum "$test_apk" | cut -d' ' -f1)
git -C "$app_root" diff --stat "$baseline" > "$evidence/overlay-diff.txt"
git -C "$app_root" diff "$baseline" -- "$allowed" > "$evidence/overlay.patch"
sha256sum "$app" "$test_apk" > "$evidence/apks-before.sha256"
api=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
{
  printf 'run=%s\nmode=baseline\napp=%s\nharness=%s\n' "$run" "$app_sha" "$harness"
  printf 'api=%s\nabi=%s\napp_hash=%s\ntest_hash=%s\n' "$api" "$abi" "$app_hash" "$test_hash"
} > "$evidence/manifest.txt"
[[ "$api" == 35 && "$abi" == x86_64 ]] || { echo 'FAIL=device_mismatch' > "$evidence/status.txt"; exit 1; }
adb shell wm density 420
cleanup() { adb shell wm density reset > "$evidence/density-restore.txt" 2>&1 || true; }
trap cleanup EXIT
if ! timeout -k 2s 60s bash "$root/scripts/prepare-keyguard-lower-environment.sh" "$evidence/preflight"; then
  echo 'FAIL=fixture_preflight' > "$evidence/status.txt"
  exit 1
fi
printf 'preflight=PASS\n' >> "$evidence/manifest.txt"
adb install -r "$app" > "$evidence/install-app.txt"
adb install -r "$test_apk" > "$evidence/install-test.txt"
grep -qx 'Success' "$evidence/install-app.txt"
grep -qx 'Success' "$evidence/install-test.txt"
installed_hash() {
  local name=$1 package_path
  package_path=$(adb shell pm path "$name" | tr -d '\r' | sed -n 's/^package://p')
  [[ "$package_path" == /data/app/*/base.apk && "$package_path" != *$'\n'* ]]
  adb exec-out cat "$package_path" | sha256sum | cut -d' ' -f1
}
installed_app_hash=$(installed_hash com.fluvi.app)
installed_test_hash=$(installed_hash com.fluvi.app.test)
printf 'installed_app_hash=%s\ninstalled_test_hash=%s\n' "$installed_app_hash" "$installed_test_hash" >> "$evidence/manifest.txt"
adb shell am force-stop com.fluvi.app > "$evidence/force-stop.txt" 2>&1
if [[ -n $(adb shell pidof com.fluvi.app | tr -d '\r') ]]; then
  printf 'forced_stop=FAIL\n' >> "$evidence/manifest.txt"
  echo 'FAIL=force_stop' > "$evidence/status.txt"
  exit 1
fi
printf 'forced_stop=PASS\n' >> "$evidence/manifest.txt"
set +e
timeout -k 5s 110s adb shell am instrument -w -r -e sourceSha "$app_sha" -e harnessSha "$harness" -e runUuid "$run" \
  -e class 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply' \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$evidence/instrumentation.txt" 2>&1 &
instrument_job=$!
pid=''
for _ in {1..100}; do
  kill -0 "$instrument_job" 2>/dev/null || break
  pid=$(timeout -k 1s 2s adb shell pidof com.fluvi.app 2>/dev/null | tr -d '\r')
  [[ "$pid" =~ ^[0-9]+$ ]] && break
  pid=''
  sleep 0.2
done
printf '%s\n' "$pid" > "$evidence/pid-during-instrumentation.txt"
wait "$instrument_job"
instrument_rc=$?
timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$evidence/logcat.txt" 2>&1
log_rc=$?
timeout -k 2s 20s adb exec-out run-as com.fluvi.app tar -C files/keyguard-service-probe/r12-admission -cf - "$run" > "$evidence/probe.tar" 2> "$evidence/probe.stderr"
probe_rc=$?
timeout -k 2s 10s adb shell dumpsys window > "$evidence/window-after.txt" 2>&1
window_rc=$?
sha256sum --check "$evidence/apks-before.sha256" > "$evidence/apks-after-check.txt" 2>&1
identity_rc=$?
tar -tf "$evidence/probe.tar" > "$evidence/tar-list.txt" 2> "$evidence/untar.stderr"
extract_rc=$?
set -e
{
  printf 'instrument_rc=%s\nlog_rc=%s\nprobe_rc=%s\nwindow_rc=%s\nidentity_rc=%s\nextract_rc=%s\n' \
    "$instrument_rc" "$log_rc" "$probe_rc" "$window_rc" "$identity_rc" "$extract_rc"
  printf 'pid=%s\n' "$pid"
} >> "$evidence/manifest.txt"
if python3 "$root/scripts/validate-keyguard-r12-admission.py" --dir "$evidence" --run "$run" --mode baseline --app "$app_sha" --harness "$harness" > "$evidence/status.txt" 2>&1; then
  exit 0
fi
exit 1
