#!/usr/bin/env bash
set -uo pipefail
out="$RUNNER_TEMP/r38-compare"
adb devices -l > "$out/device.txt"
adb shell getprop ro.build.fingerprint >> "$out/device.txt"
adb shell getprop ro.build.version.sdk >> "$out/device.txt"
adb shell wm size >> "$out/device.txt"
adb shell wm density >> "$out/device.txt"
failed=0
specs=(enabled:OFF:first enabled:OFF:repeat disabled:OFF:first disabled:OFF:repeat disabled:OFF:alternate enabled:OFF:alternate enabled:OFF:burst disabled:OFF:burst)
for spec in "${specs[@]}"; do
  IFS=: read -r mode capture label <<< "$spec"
  pair="$out/$mode"; trial="$out/$mode/$capture/$label"; mkdir -p "$trial"
  if [[ "$label" != repeat ]]; then
    adb install -r "$pair/app.apk" > "$trial/install-app.txt" 2>&1 || { echo "$spec FAIL install-app" >> "$out/results.txt"; failed=1; continue; }
    adb install -r "$pair/test.apk" > "$trial/install-test.txt" 2>&1 || { echo "$spec FAIL install-test" >> "$out/results.txt"; failed=1; continue; }
  fi
  source_sha=$(cat "$pair/source.txt"); uuid=$(cat /proc/sys/kernel/random/uuid)
  printf 'source=%s\nuuid=%s\ntrial=%s\nfixture=f3fb9694351158fd677240ed6e2a5b2e0bbfc8b7\n' "$source_sha" "$uuid" "$spec" > "$trial/identity.txt"
  method=stableInitialFullUsesOneVirginOutputWithoutReadinessRead
  [[ "$label" = burst ]] && method=externalIngressWhileFirstPaintIsHeldCannotUseOldProof
  rc=0
  timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source_sha" -e runUuid "$uuid" -e r40Capture "$capture" -e class "com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$trial/instrumentation.txt" 2>&1 || rc=$?
  adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r19/$uuid" > "$trial/service.tar" 2> "$trial/tar-stderr.txt" || true
  if ((rc == 0)) && grep -Eq '^OK \(1 test\)' "$trial/instrumentation.txt" && ! grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$trial/instrumentation.txt"; then
    echo "$spec PASS" >> "$out/results.txt"
  else echo "$spec FAIL_OR_NOT_REACHED exit=$rc" >> "$out/results.txt"; failed=1; fi
done
adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
cat "$out/results.txt"
exit "$failed"
