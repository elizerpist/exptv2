#!/usr/bin/env bash
set -euo pipefail

# A bounded, test-only API35 route for R-NATIVE-TERMINAL-OBSERVATION-01.
# It never publishes an APK and accepts no caller-provided class or command.
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

mode=diagnostic
case "${1:-}" in
  '') ;;
  --helper-only) mode=helper-only ;;
  *)
    printf 'Usage: %s [--helper-only]\n' "$0" >&2
    exit 64
    ;;
esac

app_apk=build/app/outputs/apk/debug/app-debug.apk
test_apk=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
evidence_root=android/keyguard-native-diagnostic
helper_dir="$evidence_root/helper-only"
service_evidence=android/keyguard-service-evidence

require_apk() {
  local apk=$1
  if [[ ! -s "$apk" ]]; then
    printf 'Required assembled APK is missing or empty: %s\n' "$apk" >&2
    exit 1
  fi
}

write_manifest() {
  local target=$1
  mkdir -p "$target"
  {
    printf 'source_sha=%s\n' "$(git rev-parse HEAD)"
    printf 'execution_mode=%s\n' "$mode"
    printf 'repetition_model=same-emulator-two-predeclared-service-runs\n'
    sha256sum "$app_apk" "$test_apk"
    printf 'device_fingerprint='
    adb shell getprop ro.build.fingerprint | tr -d '\r'
    printf 'device_api='
    adb shell getprop ro.build.version.sdk | tr -d '\r'
    printf 'device_abi='
    adb shell getprop ro.product.cpu.abi | tr -d '\r'
  } > "$target/source-apk-device-manifest.txt"
}

run_helper() {
  local result=0
  mkdir -p "$helper_dir"
  write_manifest "$helper_dir"

  if ! timeout -k 2s 30s adb install -r "$app_apk" > "$helper_dir/install-app.txt" 2>&1; then
    result=1
  fi
  if ! timeout -k 2s 30s adb install -r "$test_apk" > "$helper_dir/install-test.txt" 2>&1; then
    result=1
  fi
  if ! timeout -k 2s 10s adb shell am force-stop com.fluvi.app > "$helper_dir/force-stop.txt" 2>&1; then
    result=1
  fi

  set +e
  timeout -k 5s 120s adb shell am instrument -w -r \
    -e class com.fluvi.app.lockscreen.TerminalReentryObservationInstrumentationTest \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner \
    | tee "$helper_dir/instrumentation.txt"
  local pipe_status=("${PIPESTATUS[@]}")
  set -e
  if (( pipe_status[0] != 0 || pipe_status[1] != 0 )); then
    result=1
  fi
  # `am instrument` can return zero for a JUnit failure. Require the exact
  # deterministic control count in the runner transcript too.
  if ! grep -Eq '^OK \(7 tests\)' "$helper_dir/instrumentation.txt"; then
    result=1
  fi
  printf 'helper_result=%s\n' "$result" > "$helper_dir/status.txt"
  return "$result"
}

require_apk "$app_apk"
require_apk "$test_apk"

if ! run_helper; then
  printf 'aggregate_result=FAIL helper controls failed; service repetitions not started\n' \
    > "$evidence_root/aggregate-status.txt"
  exit 1
fi

if [[ "$mode" == helper-only ]]; then
  printf 'aggregate_result=PASS helper-only\n' > "$evidence_root/aggregate-status.txt"
  exit 0
fi

if [[ -e "$service_evidence" ]]; then
  printf 'Refusing to overwrite pre-existing service evidence: %s\n' "$service_evidence" >&2
  exit 1
fi

aggregate_result=0
for repetition in 1 2; do
  repetition_dir="$evidence_root/repetition-$repetition"
  if [[ -e "$repetition_dir" ]]; then
    printf 'Refusing to overwrite diagnostic repetition evidence: %s\n' "$repetition_dir" >&2
    exit 1
  fi

  set +e
  bash scripts/test-keyguard-service-trace.sh
  service_result=$?
  set -e

  analysis_result=0
  if [[ -s "$service_evidence/fluvi-keyguard-service.perfetto-trace" ]]; then
    set +e
    bash scripts/analyze-keyguard-service-trace.sh
    analysis_result=$?
    set -e
  else
    analysis_result=1
  fi
  if (( service_result != 0 || analysis_result != 0 )); then
    aggregate_result=1
  fi

  # The existing service script owns setup/restoration and its fixed scenario
  # deadlines. Preserve the complete raw directory before the next declared
  # repetition; no third attempt is ever made to obtain a lucky result.
  if [[ -d "$service_evidence" ]]; then
    mv "$service_evidence" "$repetition_dir"
    printf 'service_result=%s\nanalysis_result=%s\n' "$service_result" "$analysis_result" \
      > "$repetition_dir/diagnostic-status.txt"
  else
    mkdir -p "$repetition_dir"
    printf 'service_result=%s\nanalysis_result=%s\nevidence_directory=MISSING\n' \
      "$service_result" "$analysis_result" > "$repetition_dir/diagnostic-status.txt"
    aggregate_result=1
  fi
done

if (( aggregate_result != 0 )); then
  printf 'aggregate_result=FAIL helper=PASS repetitions=2\n' > "$evidence_root/aggregate-status.txt"
  exit 1
fi
printf 'aggregate_result=PASS helper=PASS repetitions=2\n' > "$evidence_root/aggregate-status.txt"
