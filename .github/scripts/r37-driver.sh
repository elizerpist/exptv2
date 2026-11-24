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
  test -z "$(git status --porcelain --untracked-files=no)"
  if [[ "$BASELINE" = true ]]; then
    fixture="$GITHUB_WORKSPACE/harness/test/KeyguardR26DirectOrderingInstrumentationTest.kt"
    test -f "$fixture"
    test "$(git -C "$GITHUB_WORKSPACE/harness" rev-parse HEAD)" = "$HARNESS_SHA"
    cp "$fixture" android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt
    git diff -- android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt > "$out/fixture.patch"
    sha256sum "$fixture" > "$out/fixture.sha256"
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
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r26/$uuid" > "$out/service-$uuid.tar" 2> "$out/service-$uuid.stderr" || true
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$out/visual-$uuid.tar" 2> "$out/visual-$uuid.stderr" || true
    done
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
  methods=(r26ExactDirectEvidenceSurvivesLightAndFullPressure)
  for method in "${methods[@]}"; do
    uuid=$(cat /proc/sys/kernel/random/uuid)
    r37_uuids="$r37_uuids $uuid"
    printf '%s %s\n' "$method" "$uuid" >> "$out/trials.txt"
    rc=0
    timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e harnessSha "$HARNESS_SHA" -e runUuid "$uuid" -e class "com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$method.txt" 2>&1 || rc=$?
    if (( rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$method.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$method.txt"; then
      printf '%s FAIL exit=%s\n' "$method" "$rc" >> "$out/results.txt"; failed=1
    else printf '%s PASS\n' "$method" >> "$out/results.txt"; fi
  done
  cat "$out/results.txt"
  exit "$failed"
  ;;
 *) exit 2;;
esac
