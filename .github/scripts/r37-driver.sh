#!/usr/bin/env bash
set -euo pipefail
root="$GITHUB_WORKSPACE/app"
out="$RUNNER_TEMP/r37-evidence"
mkdir -p "$out"
cd "$root"
printf 'app=%s\nharness=%s\nfixture=%s\n' "$APP_SHA" "$HARNESS_SHA" "$BASELINE" > "$out/source.txt"
case "${1:-}" in
 build)
  test "$(git rev-parse HEAD)" = "$APP_SHA"
  if [[ "$BASELINE" == true ]]; then
    cp "$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/
    cp "$GITHUB_WORKSPACE/harness/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/
    python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt');s=p.read_text()
needle='    fun yielded(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,\n        startedAt: Long, finishedAt: Long, visited: Int) {}\n'
assert s.count(needle)==1
p.write_text(s.replace(needle,needle+'    fun r37BoundaryClaimed(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest, boundary: String, at: Long) {}\n'))
PY
    git diff --name-status > "$out/baseline-fixture-diff.txt"
  else
    test -z "$(git status --porcelain --untracked-files=no)"
  fi
  flutter pub get > "$out/pub-get.log" 2>&1
  rc=0
  (cd android && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build.log" 2>&1 || rc=$?
  if (( rc != 0 )); then tail -100 "$out/build.log"; exit "$rc"; fi
  sha256sum build/app/outputs/apk/debug/app-debug.apk build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/pair.sha256"
  # This is a disposable hosted runner. Keep the APK pair and evidence.
  rm -rf -- "$root/build/app/intermediates" "$root/build/app/tmp" "$HOME/.gradle/caches"
  sha256sum -c "$out/pair.sha256"
  ;;
 run)
  collect() {
    adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
    adb shell dumpsys window > "$out/final-window.txt" 2>&1 || true
    for uuid in ${r37_uuids:-}; do
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r22/$uuid" > "$out/service-$uuid.tar" 2> "$out/service-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$out/visual-$uuid.tar" 2> "$out/visual-$uuid.stderr" || true
      for probe in r25 r26; do
        adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/$probe/$uuid" > "$out/$probe-$uuid.tar" 2> "$out/$probe-$uuid.stderr" || true
      done
    done
    adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/panel-evidence.tar" 2> "$out/panel-evidence.stderr" || true
  }
  trap collect EXIT
  { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
  test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard || true
  adb install -r build/app/outputs/apk/debug/app-debug.apk > "$out/install-app.txt" 2>&1
  adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk > "$out/install-test.txt" 2>&1
  bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"
  failed=0
  r37_uuids=""
  case "$SAFETY_LANE" in
    service) methods=(
      com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#r26VisibleDirectUnlockAndRapidRelock
      com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#r31RestrictiveIngressWhileSuccessorChildIsHeld
      com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#externalIngressWhileFirstPaintIsHeldCannotUseOldProof
      com.fluvi.app.lockscreen.KeyguardR25ServiceInstrumentationTest#heldPositiveCannotShowAfterRealShadeWithCompositorSamples
    ) ;;
    panel) methods=(
      com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r22_4BoundedResizedPrivacyStripWhite
      com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r22_4BoundedResizedPrivacyStripBlack
    ) ;;
    *) echo "unknown lane: $SAFETY_LANE"; exit 2 ;;
  esac
  for testid in "${methods[@]}"; do
    method=${testid#*#}
    uuid=$(cat /proc/sys/kernel/random/uuid)
    r37_uuids="$r37_uuids $uuid"
    printf '%s %s\n' "$method" "$uuid" >> "$out/trials.txt"
    rc=0
    timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e harnessSha "$HARNESS_SHA" -e runUuid "$uuid" -e class "$testid" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
    if (( rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then
      printf '%s FAIL exit=%s\n' "$method" "$rc" >> "$out/results.txt"; failed=1
    else printf '%s PASS\n' "$method" >> "$out/results.txt"; fi
  done
  cat "$out/results.txt"
  exit "$failed"
  ;;
 *) exit 2;;
esac
