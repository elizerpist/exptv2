#!/usr/bin/env bash
# Scoped synthetic ImageReader control; it does not exercise the primary lockscreen.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
scope=${FLUVI_R09_SCOPE:?R35 native scope required}
out="$root/android/keyguard-r35-publisher"
parent_sha=e41485b4988112947d6c8884668d9008ce96224b
r35_base=1393e8c5023065f2930b67c9c4a95f78c8d1473c
case "$scope" in
  r35_parent) arm=parent; app="$root/r35-parent" ;;
  r35_candidate) arm=candidate; app="$root" ;;
  *) echo "Unexpected R35 scope: $scope" >&2; exit 2 ;;
esac
mkdir -p "$out"
fixture_sha=$(git -C "$root" rev-parse HEAD)
app_sha=$(git -C "$app" rev-parse HEAD)
if [[ -n "${GITHUB_SHA:-}" ]]; then test "$fixture_sha" = "$GITHUB_SHA"; fi
printf 'arm=%s\napp=%s\nfixture=%s\n' "$arm" "$app_sha" "$fixture_sha" > "$out/identity.txt"
case "${1:-}" in
  prepare)
    if [[ "$arm" == parent ]]; then
      test "$app_sha" = "$parent_sha"
      while IFS= read -r path; do
        mkdir -p "$app/$(dirname "$path")"
        cp "$root/$path" "$app/$path"
        cmp "$root/$path" "$app/$path"
      done <<'FILES'
android/app/build.gradle.kts
android/app/src/debug/AndroidManifest.xml
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29Ownership.kt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R29HostClient.kt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R35EmptyReceipt.kt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R35MaterialPublication.kt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/host/R35ResidentPublisher.kt
android/app/src/debug/kotlin/com/fluvi/app/lockscreen/host/R35DebugResidentService.kt
android/app/src/debug/kotlin/com/fluvi/app/lockscreen/host/R35FrameSequencer.kt
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/host/R35ResidentPublisherInstrumentationTest.kt
FILES
      git -C "$app" diff --exit-code "$parent_sha" -- \
        android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardMaterialProfile.kt \
        android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt
      (cd "$app" && flutter pub get) > "$out/pub-get.log" 2>&1
      git -C "$app" status --short > "$out/fixture-status.txt"
    else
      # actions/checkout defaults to a shallow clone; fetch only the exact
      # comparison commit when it is not already available.
      if ! git -C "$root" cat-file -e "${r35_base}^{commit}" 2>/dev/null; then
        git -C "$root" fetch --no-tags --depth=1 origin "$r35_base"
      fi
      git -C "$root" diff --exit-code "$r35_base" HEAD -- \
        android/app/src/main lib platform pubspec.yaml pubspec.lock
      git -C "$root" status --short --untracked-files=no > "$out/fixture-status.txt"
    fi
    sha256sum \
      "$app/android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardMaterialProfile.kt" \
      "$app/android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt" \
      "$app/android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/host/R35ResidentPublisherInstrumentationTest.kt" \
      > "$out/entrypoints.sha256"
    ;;
  build)
    if ! (cd "$app/android" && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build.log" 2>&1; then
      tail -100 "$out/build.log"; exit 1
    fi
    if [[ "$arm" == candidate ]]; then
      if ! (cd "$app/android" && ./gradlew :app:testDebugUnitTest \
        --tests 'com.fluvi.app.lockscreen.host.R35*' \
        --tests 'com.fluvi.app.lockscreen.host.R29OwnershipTest' \
        --no-daemon --max-workers=3 --console=plain) > "$out/unit.log" 2>&1; then
        tail -100 "$out/unit.log"; exit 1
      fi
    fi
    sha256sum "$app/build/app/outputs/apk/debug/app-debug.apk" \
      "$app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" > "$out/pair.sha256"
    df -h / > "$out/runner-space-before.txt"
    du -sh "$app/build/app/intermediates" "$HOME/.gradle/caches" > "$out/runner-reclaim.txt" 2>&1 || true
    # These are generated caches on a disposable GitHub-hosted runner. Preserve
    # the APKs, exact identity, source and reports; verify the APK bytes again.
    rm -rf -- "$app/build/app/intermediates" "$app/build/app/tmp" "$HOME/.gradle/caches"
    sha256sum -c "$out/pair.sha256"
    df -h / > "$out/runner-space-after.txt"
    ;;
  run)
    collect() {
      adb logcat -b all -d -v monotonic 2>/dev/null | \
        grep -E 'R35_DEMO_|R35_PARENT_|FATAL EXCEPTION|Process: com\.fluvi' > "$out/logcat.txt" || true
      adb exec-out run-as com.fluvi.app tar -cf - files/r35-demo-captures \
        > "$out/demo-captures.tar" 2> "$out/demo-captures.stderr" || true
    }
    trap collect EXIT
    { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
    test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
    test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
    adb shell wm density 420
    adb shell settings put system accelerometer_rotation 0
    adb shell settings put system user_rotation 0
    adb shell input keyevent KEYCODE_WAKEUP
    adb shell wm dismiss-keyguard
    adb install -r "$app/build/app/outputs/apk/debug/app-debug.apk" > "$out/install-app.txt" 2>&1
    adb install -r "$app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" > "$out/install-test.txt" 2>&1
    adb shell pm list instrumentation > "$out/instrumentation-list.txt"
    grep -Fq 'instrumentation:com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner' "$out/instrumentation-list.txt"
    adb logcat -c
    parent=false
    if [[ "$arm" == parent ]]; then parent=true; fi
    rc=0
    timeout -k 5s 240s adb shell am instrument -w -r \
      -e r35ParentFixture "$parent" \
      -e class com.fluvi.app.lockscreen.host.R35ResidentPublisherInstrumentationTest \
      com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/instrumentation.txt" 2>&1 || rc=$?
    printf 'adb_exit=%s\n' "$rc" > "$out/device-status.txt"
    collect
    test "$rc" -eq 0
    python3 "$root/scripts/r35-publisher-verdict.py" "$arm" "$out/instrumentation.txt" "$out/logcat.txt" | tee -a "$out/device-status.txt"
    ;;
  *) echo 'Expected prepare, build or run' >&2; exit 2 ;;
esac
