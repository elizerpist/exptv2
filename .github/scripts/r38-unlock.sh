#!/usr/bin/env bash
set -uo pipefail
out="$RUNNER_TEMP/r38-unlock"
adb devices -l > "$out/device.txt"
adb shell getprop ro.build.fingerprint >> "$out/device.txt"
failed=0
methods=(r26VisibleDirectUnlockAndRapidRelock r21ExclusionRetiresSubmittedOrbWithMainAckHeld externalIngressWhileFirstPaintIsHeldCannotUseOldProof)
for mode in r38 r39 r40; do
  adb install -r "$out/$mode/app.apk" > "$out/$mode/install-app.txt" 2>&1 || { echo "$mode FAIL install" >> "$out/results.txt"; failed=1; continue; }
  adb install -r "$out/$mode/test.apk" > "$out/$mode/install-test.txt" 2>&1 || { echo "$mode FAIL install-test" >> "$out/results.txt"; failed=1; continue; }
  for method in "${methods[@]}"; do
    uuid=$(cat /proc/sys/kernel/random/uuid); source_sha=$(cat "$out/$mode/source.txt"); rc=0
    printf 'source=%s\nuuid=%s\n' "$source_sha" "$uuid" > "$out/$mode/$method-identity.txt"
    timeout -k 5s 240s adb shell am instrument -w -r -e sourceSha "$source_sha" -e runUuid "$uuid" -e class "com.fluvi.app.lockscreen.KeyguardFirstAuthorizedOrbInstrumentationTest#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$mode/$method.txt" 2>&1 || rc=$?
    for scope in r19 r26; do adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/$scope/$uuid" > "$out/$mode/$method-$scope.tar" 2> "$out/$mode/$method-$scope-stderr.txt" || true; done
    if ((rc == 0)) && grep -Eq '^OK \(1 test\)' "$out/$mode/$method.txt" && ! grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$mode/$method.txt"; then
      echo "$mode $method PASS" >> "$out/results.txt"
    else echo "$mode $method FAIL_OR_NOT_REACHED exit=$rc" >> "$out/results.txt"; failed=1; fi
  done
done
adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
cat "$out/results.txt"
exit "$failed"
