#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r37-ab"
base_sha=3a8c355caaccf1519d25edf042c2cf04dd7f9e38
candidate_sha=d2b1890a8c892a4ba3b3ec0ebe18279b4bb2b158
mkdir -p "$out/apks"
case "${1:-}" in
 build)
  printf 'baseline=%s\ncandidate=%s\n' "$base_sha" "$candidate_sha" > "$out/source.txt"
  for variant in baseline candidate; do
    if [[ "$variant" == baseline ]]; then root="$GITHUB_WORKSPACE/base"; expected="$base_sha"; else root="$GITHUB_WORKSPACE/app"; expected="$candidate_sha"; fi
    cd "$root"
    test "$(git rev-parse HEAD)" = "$expected"
    if [[ "$variant" == baseline ]]; then
      cp "$GITHUB_WORKSPACE/app/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/
      cp "$GITHUB_WORKSPACE/app/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/
      python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt');s=p.read_text()
needle='    fun yielded(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,\n        startedAt: Long, finishedAt: Long, visited: Int) {}\n'
assert s.count(needle)==1
p.write_text(s.replace(needle,needle+'    fun r37BoundaryClaimed(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest, boundary: String, at: Long) {}\n'))
PY
      git diff --stat > "$out/baseline-fixture-diff.txt"
    else test -z "$(git status --porcelain --untracked-files=no)"; fi
    flutter pub get > "$out/$variant-pub-get.log" 2>&1
    rc=0
    (cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/$variant-build.log" 2>&1 || rc=$?
    if (( rc != 0 )); then tail -100 "$out/$variant-build.log"; exit "$rc"; fi
    mkdir -p "$out/apks/$variant"
    cp build/app/outputs/apk/debug/app-debug.apk "$out/apks/$variant/app.apk"
    cp build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk "$out/apks/$variant/test.apk"
    sha256sum "$out/apks/$variant/"*.apk >> "$out/pair.sha256"
    rm -rf -- "$root/build/app/intermediates" "$root/build/app/tmp"
  done
  sha256sum -c "$out/pair.sha256"
  ;;
 run)
  collect() {
    adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
    adb shell dumpsys window > "$out/final-window.txt" 2>&1 || true
  }
  trap collect EXIT
  { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; adb shell settings get global animator_duration_scale; } > "$out/device.txt" 2>&1
  test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
  test "$(adb shell settings get global animator_duration_scale | tr -d '\r')" != 0.0
  cd "$GITHUB_WORKSPACE/app"
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard || true
  bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
  failed=0
  for trial in 1 2 3 4 5 6; do
    if (( trial % 2 )); then variant=baseline; sha="$base_sha"; else variant=candidate; sha="$candidate_sha"; fi
    uuid=$(cat /proc/sys/kernel/random/uuid)
    printf '%s %s %s %s\n' "$trial" "$variant" "$sha" "$uuid" >> "$out/trials.txt"
    adb shell am force-stop com.fluvi.app || true
    adb install -r "$out/apks/$variant/app.apk" > "$out/install-$trial-app.txt" 2>&1
    adb install -r "$out/apks/$variant/test.apk" > "$out/install-$trial-test.txt" 2>&1
    rc=0
    timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$sha" -e runUuid "$uuid" -e class 'com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#stableInitialFullUsesOneVirginOutputWithoutReadinessRead' com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/trial-$trial.txt" 2>&1 || rc=$?
    if (( rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/trial-$trial.txt" || ! grep -Eq '^OK \(1 test\)' "$out/trial-$trial.txt"; then
      printf '%s %s FAIL_OR_NOT_REACHED exit=%s\n' "$trial" "$variant" "$rc" >> "$out/results.txt"; failed=1
    else printf '%s %s PASS\n' "$trial" "$variant" >> "$out/results.txt"; fi
    adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$out/trial-$trial.tar" 2> "$out/trial-$trial.stderr" || true
  done
  cat "$out/results.txt"
  exit "$failed"
  ;;
 *) exit 2;;
esac
