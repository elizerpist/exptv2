#!/usr/bin/env bash
set -euo pipefail

# Establish only the known precondition for the lower screenshot suite.  This
# is deliberately host-side setup: it neither changes Fluvi nor retries the
# measured instrumentation once it has started.
if (( $# != 1 )); then
  printf 'Usage: %s EVIDENCE_DIRECTORY\n' "$0" >&2
  exit 64
fi

evidence_dir=$1
if [[ -e "$evidence_dir" ]]; then
  printf 'Refusing to overwrite lower-environment evidence: %s\n' "$evidence_dir" >&2
  exit 1
fi
mkdir -p "$evidence_dir"

status_file="$evidence_dir/status.txt"
source_sha=$(git rev-parse HEAD 2>/dev/null || printf 'UNKNOWN')
{
  printf 'stage=before-lower\n'
  printf 'source_sha=%s\n' "$source_sha"
  printf 'host_started_epoch_ms=%s\n' "$(date +%s%3N)"
  printf 'github_run_id=%s\n' "${GITHUB_RUN_ID:-UNSET}"
  printf 'github_run_attempt=%s\n' "${GITHUB_RUN_ATTEMPT:-UNSET}"
} > "$status_file"

append_status() { printf '%s\n' "$1" >> "$status_file"; }

capture_window() {
  local label=$1
  local stdout="$evidence_dir/${label}-window.txt"
  local stderr="$evidence_dir/${label}-window.stderr"
  set +e
  timeout -k 2s 5s adb shell dumpsys window >"$stdout" 2>"$stderr"
  local rc=$?
  set -e
  printf '%s\n' "$rc" > "$evidence_dir/${label}-window.exit"
  append_status "${label}_window_exit=$rc"
  if (( rc != 0 )) || [[ ! -s "$stdout" ]] || ! grep -q 'mCurrentFocus' "$stdout"; then
    return 1
  fi
  return 0
}

# Output is one of clean, known, unknown or malformed.  Only the exact known
# Launcher ANR is eligible for the one existing CLOSE_SYSTEM_DIALOGS action.
focus_state() {
  local file=$1 line
  line=$(grep -m1 'mCurrentFocus' "$file" || true)
  if [[ -z "$line" ]]; then printf 'malformed\n'; return; fi
  if [[ "$line" != *'Application Not Responding'* ]]; then printf 'clean\n'; return; fi
  if printf '%s\n' "$line" | grep -Eq '(^|[^[:alnum:]_.])com\.android\.launcher3([^[:alnum:]_.]|$)'; then
    printf 'known\n'
  else
    printf 'unknown\n'
  fi
}

capture_before_mutation() {
  set +e
  timeout -k 2s 5s adb exec-out screencap -p > "$evidence_dir/before-anr-screen.png" 2> "$evidence_dir/before-anr-screen.stderr"
  local screen_rc=$?
  timeout -k 2s 10s adb logcat -b all -d -v monotonic > "$evidence_dir/before-anr-logcat.txt" 2> "$evidence_dir/before-anr-logcat.stderr"
  local logcat_rc=$?
  set -e
  printf '%s\n' "$screen_rc" > "$evidence_dir/before-anr-screen.exit"
  printf '%s\n' "$logcat_rc" > "$evidence_dir/before-anr-logcat.exit"
  append_status "before_anr_screencap_exit=$screen_rc"
  append_status "before_anr_logcat_exit=$logcat_rc"
  (( screen_rc == 0 )) && [[ -s "$evidence_dir/before-anr-screen.png" ]] && (( logcat_rc == 0 ))
}

if ! capture_window before; then
  append_status 'result=FAIL unreadable_or_malformed_before_window'
  exit 1
fi

case "$(focus_state "$evidence_dir/before-window.txt")" in
  clean)
    append_status 'result=CLEAN_NO_RESET'
    exit 0
    ;;
  unknown|malformed)
    append_status 'result=FAIL unknown_or_malformed_focused_anr'
    exit 1
    ;;
  known)
    append_status 'recognized_focused_anr=com.android.launcher3'
    ;;
esac

if ! capture_before_mutation; then
  append_status 'result=FAIL unable_to_retain_known_anr_evidence'
  exit 1
fi

set +e
timeout -k 2s 10s adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS -p android \
  > "$evidence_dir/close-system-dialogs.txt" 2> "$evidence_dir/close-system-dialogs.stderr"
broadcast_rc=$?
set -e
printf '%s\n' "$broadcast_rc" > "$evidence_dir/close-system-dialogs.exit"
append_status "close_system_dialogs_exit=$broadcast_rc"
if (( broadcast_rc != 0 )); then
  append_status 'result=FAIL close_system_dialogs_failed'
  exit 1
fi

cleared=false
for poll in $(seq 1 20); do
  label=$(printf 'poll-%02d' "$poll")
  if ! capture_window "$label"; then
    append_status 'result=FAIL unreadable_or_malformed_poll'
    exit 1
  fi
  case "$(focus_state "$evidence_dir/${label}-window.txt")" in
    clean) cleared=true; break ;;
    known) if (( poll < 20 )); then sleep 0.25; fi ;;
    unknown|malformed)
      append_status 'result=FAIL unknown_or_malformed_focused_anr_during_poll'
      exit 1
      ;;
  esac
done
if [[ "$cleared" != true ]]; then
  append_status 'result=FAIL known_launcher_anr_persisted'
  exit 1
fi

set +e
timeout -k 2s 20s adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.HOME \
  > "$evidence_dir/home.txt" 2> "$evidence_dir/home.stderr"
home_rc=$?
set -e
printf '%s\n' "$home_rc" > "$evidence_dir/home.exit"
append_status "home_exit=$home_rc"
if (( home_rc != 0 )) || ! capture_window final; then
  append_status 'result=FAIL home_or_final_window_failed'
  exit 1
fi
case "$(focus_state "$evidence_dir/final-window.txt")" in
  clean)
    append_status 'result=PREPARED_KNOWN_LAUNCHER_ANR'
    exit 0
    ;;
  *)
    append_status 'result=FAIL focused_anr_after_preparation'
    exit 1
    ;;
esac
