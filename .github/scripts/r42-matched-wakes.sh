#!/usr/bin/env bash
set -euo pipefail

out="$RUNNER_TEMP/r42-matched-wakes"
orchestrator="$GITHUB_WORKSPACE/orchestrator"
app_a="$GITHUB_WORKSPACE/app-r41"
app_b="$GITHUB_WORKSPACE/app-r42"
source_a=97f9704120e2ae997185ea6e35fbc053e1d7f0ab
source_b=1584ccb020a8500efd5f9c67eac8ebd4830b1271
fixture_rel=android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt
fixture="$orchestrator/.github/fixtures/KeyguardR42MatchedWakeFixture.kt"
mkdir -p "$out"

case "${1:-}" in
  build)
    git -C "$orchestrator" rev-parse HEAD > "$out/orchestration-sha.txt"
    printf '%s\n' 'test fixture based on 14399cb246a3a73a24cc1820d264f68b999776bb; only wake count and capture mode are parameterized' > "$out/fixture-parent.txt"
    sha256sum "$fixture" > "$out/fixture-sha256.txt"
    for arm in a b; do
      if [[ "$arm" == a ]]; then app="$app_a"; expected="$source_a"; else app="$app_b"; expected="$source_b"; fi
      test "$(git -C "$app" rev-parse HEAD)" = "$expected"
      test -z "$(git -C "$app" status --porcelain --untracked-files=no)"
      (cd "$app" && flutter pub get) > "$out/pub-get-$arm.log" 2>&1
      test -z "$(git -C "$app" status --porcelain --untracked-files=no)"
      cp "$fixture" "$app/$fixture_rel"
      git -C "$app" diff -- "$fixture_rel" > "$out/fixture-$arm.patch"
      # Only the androidTest fixture may differ from the pinned source.
      unexpected=$(git -C "$app" diff --name-only -- . ':!android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt')
      test -z "$unexpected"
      rc=0
      (cd "$app/android" && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build-$arm.log" 2>&1 || rc=$?
      printf '%s\n' "$rc" > "$out/build-$arm-exit.txt"
      if (( rc != 0 )); then tail -80 "$out/build-$arm.log"; exit "$rc"; fi
      sha256sum "$app/build/app/outputs/apk/debug/app-debug.apk" "$app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" > "$out/pair-$arm.sha256"
      printf '%s\n' "$expected" > "$out/source-$arm.txt"
    done
    ;;
  run|run-continuation)
    { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
    test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
    adb shell input keyevent KEYCODE_WAKEUP
    adb shell wm dismiss-keyguard || true
    failed=0
    # Six alternating five-wake LIGHT blocks per arm were declared in
    # advance. Every attempted wake and every failure is retained.
    blocks=(a b a b a b a b a b a b)
    modes=(LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT LIGHT)
    # Matched FULL and OFF controls are reported separately; OFF has no
    # in-process permission or optical latency evidence.
    blocks+=(a b a b)
    modes+=(FULL FULL OFF OFF)
    # Independent continuation after the first emulator became offline.
    # Do not rerun or replace its ten recorded blocks.
    if [[ "$1" == run-continuation ]]; then
      blocks=(a b a b a b)
      modes=(LIGHT LIGHT FULL FULL OFF OFF)
    fi
    for index in "${!blocks[@]}"; do
      arm="${blocks[$index]}"; mode="${modes[$index]}"; number=$((index+1))
      if [[ "$arm" == a ]]; then app="$app_a"; source="$source_a"; else app="$app_b"; source="$source_b"; fi
      dir="$out/block-$(printf '%02d' "$number")-$arm-$mode"
      mkdir -p "$dir"
      uuid=$(cat /proc/sys/kernel/random/uuid)
      printf 'block=%s\narm=%s\nmode=%s\nsource=%s\nuuid=%s\n' "$number" "$arm" "$mode" "$source" "$uuid" > "$dir/identity.txt"
      app_apk="$app/build/app/outputs/apk/debug/app-debug.apk"
      test_apk="$app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
      if ! adb install -r "$app_apk" > "$dir/install-app.txt" 2>&1; then
        printf '%s\n' 'FAIL: app installation' > "$dir/result.txt"; failed=1; continue
      fi
      if ! adb install -r "$test_apk" > "$dir/install-test.txt" 2>&1; then
        printf '%s\n' 'FAIL: test installation' > "$dir/result.txt"; failed=1; continue
      fi
      if ! bash "$app/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app "$app_apk" "$dir" app > "$dir/verify-app.txt" 2>&1 ||
         ! bash "$app/scripts/verify-keyguard-installed-apk.sh" com.fluvi.app.test "$test_apk" "$dir" test > "$dir/verify-test.txt" 2>&1; then
        printf '%s\n' 'FAIL: installed APK pair differs from built bytes' > "$dir/result.txt"; failed=1; continue
      fi
      if (( index == 0 )); then (cd "$app" && bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight"); fi
      rc=0
      timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source" -e runUuid "$uuid" \
        -e wakeCount 5 -e captureMode "$mode" -e class \
        'com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#r41TwentyUnheldWakeAttempts' \
        com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dir/instrumentation.txt" 2>&1 || rc=$?
      tar_rc=0
      adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid/r41-natural" > "$dir/device.tar" 2> "$dir/device-tar.stderr" || tar_rc=$?
      if (( rc != 0 || tar_rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$dir/instrumentation.txt" ||
         ! grep -Eq '^OK \(1 test\)' "$dir/instrumentation.txt"; then
        printf 'FAIL or NOT REACHED: instrumentation=%s evidenceTar=%s\n' "$rc" "$tar_rc" > "$dir/result.txt"; failed=1
      else
        printf '%s\n' 'PASS: fixture finished five attempted wakes; eligibility and latency require independent analysis.' > "$dir/result.txt"
      fi
    done
    adb logcat -b all -d -v monotonic > "$out/final-logcat.txt" 2>&1 || true
    adb shell dumpsys window > "$out/final-window.txt" 2>&1 || true
    exit "$failed"
    ;;
  *) exit 2;;
esac
