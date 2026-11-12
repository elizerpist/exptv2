#!/usr/bin/env bash
set -euo pipefail

# Inert shell controls for the lower-suite preflight.  adb is a local fake;
# this script never touches a connected device.
repo_root=$(git rev-parse --show-toplevel)
helper="$repo_root/scripts/prepare-keyguard-lower-environment.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_fake_adb() {
  local state=$1 calls=$2
  mkdir -p "$tmp/bin"
  cat > "$tmp/bin/adb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FAKE_ADB_CALLS"
state=$(cat "$FAKE_ADB_STATE")
if [[ "$*" == *'dumpsys window'* ]]; then
  count_file="${FAKE_ADB_STATE}.count"; count=0; [[ -f "$count_file" ]] && count=$(cat "$count_file")
  count=$((count + 1)); printf '%s' "$count" > "$count_file"
  case "$state" in
    clean) printf 'mCurrentFocus=null\n' ;;
    postanr) if (( count == 1 )); then printf 'mCurrentFocus=null\n'; else printf 'mCurrentFocus=Application Not Responding: com.android.launcher3\n'; fi ;;
    known) if (( count == 1 )); then printf 'mCurrentFocus=Application Not Responding: com.android.launcher3\n'; else printf 'mCurrentFocus=null\n'; fi ;;
    persistent) printf 'mCurrentFocus=Application Not Responding: com.android.launcher3\n' ;;
    unknown) printf 'mCurrentFocus=Application Not Responding: com.example.other\n' ;;
    malformed) printf 'no focus here\n' ;;
    readfail) exit 7 ;;
  esac
elif [[ "$*" == *'exec-out screencap -p'* ]]; then printf 'PNG';
elif [[ "$*" == *'logcat '* ]]; then printf 'logcat\n';
elif [[ "$*" == *'CLOSE_SYSTEM_DIALOGS'* || "$*" == *'android.intent.action.MAIN'* ]]; then printf 'ok\n';
else printf 'ok\n'; fi
EOF
  chmod +x "$tmp/bin/adb"
  printf '%s' "$state" > "$tmp/state"
  : > "$calls"
}

run_case() {
  local name=$1 state=$2 expected=$3
  local calls="$tmp/$name.calls" evidence="$tmp/$name-evidence"
  rm -f "$tmp/state.count"; make_fake_adb "$state" "$calls"
  set +e
  PATH="$tmp/bin:$PATH" FAKE_ADB_STATE="$tmp/state" FAKE_ADB_CALLS="$calls" bash "$helper" "$evidence"
  local rc=$?
  set -e
  [[ "$rc" == "$expected" ]] || { printf '%s expected %s got %s\n' "$name" "$expected" "$rc" >&2; return 1; }
  printf '%s\n' "$evidence"
}

clean_evidence=$(run_case clean clean 0)
! grep -q 'CLOSE_SYSTEM_DIALOGS\|android.intent.action.MAIN' "$tmp/clean.calls"
grep -q 'result=CLEAN_NO_RESET' "$clean_evidence/status.txt"

known_evidence=$(run_case known known 0)
[[ $(grep -c 'CLOSE_SYSTEM_DIALOGS' "$tmp/known.calls") == 1 ]]
[[ $(grep -c 'android.intent.action.MAIN' "$tmp/known.calls") == 1 ]]
grep -q 'result=PREPARED_KNOWN_LAUNCHER_ANR' "$known_evidence/status.txt"

for state in persistent unknown malformed readfail; do
  evidence=$(run_case "$state" "$state" 1)
  ! grep -q 'android.intent.action.MAIN' "$tmp/$state.calls"
  grep -q 'result=FAIL' "$evidence/status.txt"
done

# Existing evidence must be refused rather than overwritten.
mkdir -p "$tmp/existing"
set +e
PATH="$tmp/bin:$PATH" FAKE_ADB_STATE="$tmp/state" FAKE_ADB_CALLS="$tmp/existing.calls" bash "$helper" "$tmp/existing"
overwrite_rc=$?
set -e
(( overwrite_rc != 0 ))

# Exercise the wrapper's sticky aggregation in an isolated tree.  The copied
# scripts have fake adb/gradle/service binaries only; no real device is used.
runtime_root="$tmp/runtime-repo"
mkdir -p "$runtime_root/scripts" "$runtime_root/android"
cp "$helper" "$runtime_root/scripts/prepare-keyguard-lower-environment.sh"
cp "$repo_root/scripts/test-keyguard-runtime.sh" "$runtime_root/scripts/test-keyguard-runtime.sh"
cat > "$runtime_root/scripts/test-keyguard-service-trace.sh" <<'EOF'
#!/usr/bin/env bash
mkdir -p keyguard-service-evidence
printf trace > keyguard-service-evidence/fluvi-keyguard-service.perfetto-trace
exit "${FAKE_SERVICE_RC:-0}"
EOF
cat > "$runtime_root/android/gradlew" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_GRADLE_CALLS}"
exit "${FAKE_GRADLE_RC:-0}"
EOF
cat > "$tmp/bin/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == 'rev-parse HEAD' ]]; then printf 'fake-source\n'; else exit 1; fi
EOF
chmod +x "$runtime_root/scripts/prepare-keyguard-lower-environment.sh" "$runtime_root/scripts/test-keyguard-runtime.sh" "$runtime_root/scripts/test-keyguard-service-trace.sh" "$runtime_root/android/gradlew" "$tmp/bin/git"

run_runtime_case() {
  local name=$1 state=$2 gradle_rc=$3 service_rc=$4 expected=$5
  rm -rf "$runtime_root/android/keyguard-lower-environment" "$runtime_root/android/keyguard-service-evidence"
  rm -f "$tmp/state.count"; make_fake_adb "$state" "$tmp/$name.adb.calls"; : > "$tmp/$name.gradle.calls"
  set +e
  (cd "$runtime_root" && PATH="$tmp/bin:$PATH" FAKE_ADB_STATE="$tmp/state" FAKE_ADB_CALLS="$tmp/$name.adb.calls" FAKE_GRADLE_CALLS="$tmp/$name.gradle.calls" FAKE_GRADLE_RC="$gradle_rc" FAKE_SERVICE_RC="$service_rc" bash scripts/test-keyguard-runtime.sh)
  local rc=$?
  set -e
  [[ "$rc" == "$expected" ]] || { printf 'runtime %s expected %s got %s\n' "$name" "$expected" "$rc" >&2; return 1; }
}

run_runtime_case preflight_failure persistent 0 0 1
[[ ! -s "$tmp/preflight_failure.gradle.calls" ]]
run_runtime_case lower_failure clean 1 0 1
[[ -s "$tmp/lower_failure.gradle.calls" ]]
run_runtime_case service_failure clean 0 1 1
run_runtime_case all_pass clean 0 0 0
run_runtime_case post_anr postanr 0 0 1
! grep -q 'CLOSE_SYSTEM_DIALOGS' "$tmp/post_anr.adb.calls"
mkdir -p "$runtime_root/android/keyguard-lower-environment"
printf 'preserve-me\n' > "$runtime_root/android/keyguard-lower-environment/marker"
rm -f "$tmp/state.count"; make_fake_adb clean "$tmp/wrapper-overwrite.adb.calls"; : > "$tmp/wrapper-overwrite.gradle.calls"
set +e
(cd "$runtime_root" && PATH="$tmp/bin:$PATH" FAKE_ADB_STATE="$tmp/state" FAKE_ADB_CALLS="$tmp/wrapper-overwrite.adb.calls" FAKE_GRADLE_CALLS="$tmp/wrapper-overwrite.gradle.calls" FAKE_GRADLE_RC=0 FAKE_SERVICE_RC=0 bash scripts/test-keyguard-runtime.sh)
wrapper_overwrite_rc=$?
set -e
(( wrapper_overwrite_rc != 0 ))
grep -qx 'preserve-me' "$runtime_root/android/keyguard-lower-environment/marker"
[[ ! -s "$tmp/wrapper-overwrite.gradle.calls" ]]

printf 'PASS lower-environment inert controls: preflight states, overwrite refusal, sticky runtime/lower/service/post-observation results\n'
