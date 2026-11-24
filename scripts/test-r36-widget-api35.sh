#!/usr/bin/env bash
# Synthetic framework-host control; it does not qualify a primary lockscreen.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
out="$root/android/keyguard-r36-widget"
mkdir -p "$out"
test "${FLUVI_R09_SCOPE:-}" = r36_widget
source_sha=$(git -C "$root" rev-parse HEAD)
if [[ -n "${GITHUB_SHA:-}" ]]; then test "$source_sha" = "$GITHUB_SHA"; fi
printf 'source=%s\n' "$source_sha" > "$out/identity.txt"
case "${1:-}" in
  build)
    if ! (cd "$root/android" && ./gradlew :app:assembleDebug :app:assembleDebugAndroidTest --no-daemon --max-workers=3 --console=plain) > "$out/build.log" 2>&1; then
      tail -100 "$out/build.log"; exit 1
    fi
    sha256sum "$root/build/app/outputs/apk/debug/app-debug.apk" "$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" > "$out/pair.sha256"
    rm -rf -- "$root/build/app/intermediates" "$root/build/app/tmp" "$HOME/.gradle/caches"
    sha256sum -c "$out/pair.sha256"
    df -h / > "$out/runner-space.txt"
    ;;
  run)
    collect() {
      adb logcat -b all -d -v monotonic 2>/dev/null | grep -E 'R36_FRAMEWORK_HOST|R36_DIAGNOSTIC|AppWidget|RemoteViews|FATAL EXCEPTION|Process: com\.fluvi' > "$out/logcat.txt" || true
      adb exec-out run-as com.fluvi.app cat files/r36-framework-host.png > "$out/framework-host.png" 2> "$out/screenshot.stderr" || true
    }
    trap collect EXIT
    { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
    test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
    test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
    adb shell input keyevent KEYCODE_WAKEUP
    adb shell wm dismiss-keyguard
    adb install -r "$root/build/app/outputs/apk/debug/app-debug.apk" > "$out/install-app.txt" 2>&1
    adb install -r "$root/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" > "$out/install-test.txt" 2>&1
    adb logcat -c
    rc=0
    timeout -k 5s 180s adb shell am instrument -w -r \
      -e class com.fluvi.app.widget.trial.FluviOrbLockscreenTrialInstrumentationTest \
      com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/instrumentation.txt" 2>&1 || rc=$?
    printf 'adb_exit=%s\n' "$rc" > "$out/device-status.txt"
    collect
    test "$rc" -eq 0
    ! grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/instrumentation.txt"
    grep -Eq '^OK \(1 test\)' "$out/instrumentation.txt"
    grep -Fq 'R36_FRAMEWORK_HOST bound=true category=KEYGUARD' "$out/logcat.txt"
    test -s "$out/framework-host.png"
    timeout -k 5s 30s adb shell am start -W -n com.fluvi.app/.MainActivity > "$out/launch.txt" 2>&1
    grep -Fq 'Status: ok' "$out/launch.txt"
    echo 'FRAMEWORK_HOST_PASS (simulated host; not a primary lockscreen)' >> "$out/device-status.txt"
    echo 'DEBUG_ACTIVITY_LAUNCH_PASS' >> "$out/device-status.txt"
    ;;
  *) echo 'Expected build or run' >&2; exit 2 ;;
esac
