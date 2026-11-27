#!/usr/bin/env bash
set -uo pipefail

# Both unchanged app revisions run on the same disposable API35 emulator and
# runner. Every return code is retained; neither arm can suppress the other.
base="$GITHUB_WORKSPACE/baseline"
candidate="$GITHUB_WORKSPACE/app"
out="$RUNNER_TEMP/r47-paired-${PAIR_KIND:?}"
mkdir -p "$out"
base_sha=fd74df6057793f6fdd12e0ccb61a20bdbfdd7f20
candidate_sha=af20365a5ec96ff92b35321a03c0a2679ee7d2fd

build_arm() {
  local label=$1 directory=$2 expected=$3
  mkdir -p "$out/$label"
  (
    set -euo pipefail
    cd "$directory"
    test "$(git rev-parse HEAD)" = "$expected"
    test -z "$(git status --porcelain --untracked-files=no)"
    printf 'source=%s\npair_kind=%s\n' "$expected" "$PAIR_KIND" > "$out/$label/source.txt"
    sha256sum scripts/test-keyguard-runtime.sh scripts/test-keyguard-service-trace.sh scripts/run-dashboard-profile.sh > "$out/$label/scripts.sha256"
    flutter pub get
    if [[ "$PAIR_KIND" == native ]]; then
      (cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain)
      sha256sum build/app/outputs/apk/debug/app-debug.apk build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/$label/apks.sha256"
    elif [[ "$PAIR_KIND" == dashboard ]]; then
      flutter build apk --profile --target=integration_test/dashboard_interaction_profile_test.dart \
        --dart-define=FLUVI_VERBOSE_FLOW=false --dart-define=FLUVI_RAIL_FLIGHT_RECORDER=true \
        --dart-define=FLUVI_PHYSICAL_RAIL_DIAGNOSTICS=true --dart-define=FLUVI_ONSCREEN_DIAGNOSTICS=true \
        --dart-define=FLUVI_BUILD_PURPOSE=automated_profile_test \
        --dart-define=FLUVI_AUTOMATED_SCENARIO_RUNNER_PRESENT=true \
        --dart-define=FLUVI_AUTOMATED_INPUT_DRIVER_ACTIVE=true \
        --dart-define="FLUVI_BUILD_COMMIT=$expected"
      sha256sum build/app/outputs/flutter-apk/app-profile.apk > "$out/$label/apks.sha256"
      (cd android && ./gradlew --stop)
    else exit 64; fi
  ) > "$out/$label/build.log" 2>&1
  local rc=$?
  printf '%s\n' "$rc" > "$out/$label/build.exit"
  if ((rc != 0)); then tail -50 "$out/$label/build.log"; fi
  return "$rc"
}

inventory() {
  local dir=$1
  {
    adb devices -l
    adb shell getprop ro.build.fingerprint
    adb shell getprop ro.build.version.sdk
    adb shell getprop ro.product.cpu.abi
    adb shell cat /proc/sys/kernel/random/boot_id
    adb shell wm size
    adb shell wm density
    adb shell settings get global animator_duration_scale
    adb shell dumpsys window | grep -m1 'mCurrentFocus' || true
  } > "$dir/device.txt" 2>&1
}

prepare_arm() {
  local dir=$1
  mkdir -p "$dir"
  adb shell input keyevent KEYCODE_WAKEUP > "$dir/wake.txt" 2>&1 || true
  adb shell wm dismiss-keyguard > "$dir/dismiss.txt" 2>&1 || true
  for package in com.fluvi.app.test com.fluvi.app; do
    if adb shell pm path "$package" 2>/dev/null | grep -q '^package:'; then
      adb uninstall "$package" >> "$dir/uninstall.txt" 2>&1 || return 1
    fi
  done
  adb shell wm density reset > "$dir/reset-density.txt" 2>&1 || return 1
  inventory "$dir"
  [[ $(adb shell getprop ro.build.version.sdk | tr -d '\r') == 35 ]]
  [[ $(adb shell getprop ro.product.cpu.abi | tr -d '\r') == x86_64 ]]
}

run_native() {
  local label=$1 directory=$2
  local helper=0 runtime=0
  (
    cd "$directory" || exit 1
    timeout -k 5s 300s bash scripts/test-keyguard-native-diagnostic.sh --helper-only > "$out/$label/helper.log" 2>&1 || helper=$?
    printf '%s\n' "$helper" > "$out/$label/helper.exit"
    timeout -k 5s 1500s bash scripts/test-keyguard-runtime.sh > "$out/$label/runtime.log" 2>&1 || runtime=$?
    printf '%s\n' "$runtime" > "$out/$label/runtime.exit"
    paths=()
    for path in android/keyguard-native-diagnostic android/keyguard-lower-environment android/keyguard-service-evidence \
      android/keyguard-material-smoke.tar android/keyguard-material-smoke-pull.log \
      build/app/outputs/androidTest-results build/app/reports/androidTests; do
      [[ -e "$path" ]] && paths+=("$path")
    done
    if ((${#paths[@]})); then tar -czf "$out/$label/runtime-evidence.tar.gz" "${paths[@]}"; fi
    if ((helper != 0 || runtime != 0)); then exit 1; fi
  )
}

run_dashboard() {
  local label=$1 directory=$2
  (
    cd "$directory" || exit 1
    rc=0
    timeout -k 30s 45m bash scripts/run-dashboard-profile.sh \
      --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk > "$out/$label/dashboard.log" 2>&1 || rc=$?
    printf '%s\n' "$rc" > "$out/$label/dashboard.exit"
    paths=()
    for path in build/dashboard_profile_*.json build/dashboard-profile-diagnostics; do
      [[ -e "$path" ]] && paths+=("$path")
    done
    if ((${#paths[@]})); then tar -czf "$out/$label/dashboard-evidence.tar.gz" "${paths[@]}"; fi
    exit "$rc"
  )
}

case "${1:-}" in
  build-baseline)
    build_arm baseline "$base" "$base_sha"
    ;;
  run)
    result=0
    prepare_arm "$out/baseline" || result=1
    if [[ $(cat "$out/baseline/build.exit" 2>/dev/null) == 0 ]]; then
      if [[ "$PAIR_KIND" == native ]]; then run_native baseline "$base" || result=1
      else run_dashboard baseline "$base" || result=1; fi
    else
      printf 'NOT_RUN: baseline build failed\n' > "$out/baseline/not-run.txt"
      result=1
    fi
    # Only build outputs in this disposable CI checkout are removed; source,
    # binary hashes, logs and the compressed evidence above are retained.
    rm -rf -- "$base/build" "$base/android/.gradle" 
    if ! prepare_arm "$out/candidate"; then result=1; fi
    if build_arm candidate "$candidate" "$candidate_sha"; then
      if [[ "$PAIR_KIND" == native ]]; then run_native candidate "$candidate" || result=1
      else run_dashboard candidate "$candidate" || result=1; fi
    else
      printf 'NOT_RUN: candidate build failed\n' > "$out/candidate/not-run.txt"
      result=1
    fi
    sha256sum "$out"/*/*.sha256 > "$out/manifest.sha256" 2>/dev/null || true
    printf 'aggregate_exit=%s\ncomparison=one_runner_same_emulator_sequential\norder=R46_then_R47\n' "$result" > "$out/status.txt"
    exit "$result"
    ;;
  *) exit 64 ;;
esac
