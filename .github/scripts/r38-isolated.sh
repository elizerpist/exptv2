#!/usr/bin/env bash
set -uo pipefail
out="$RUNNER_TEMP/r38-isolated"
adb devices -l > "$out/device.txt"
adb shell getprop ro.build.fingerprint >> "$out/device.txt"
failed=0
methods=(isolatedOrbReadyFrameCannotSubmitAfterItsAttachmentIsRetired isolatedOrbStaleFirstCommitCannotUndoSameRootPrivacyOrSizeReplacement isolatedOrbRevocationDrainsLateSteadyPublication)
for mode in r37 r38; do
  adb install -r "$out/$mode/app.apk" > "$out/$mode/install-app.txt" 2>&1 || { echo "$mode FAIL install" >> "$out/results.txt"; failed=1; continue; }
  adb install -r "$out/$mode/test.apk" > "$out/$mode/install-test.txt" 2>&1 || { echo "$mode FAIL install-test" >> "$out/results.txt"; failed=1; continue; }
  for method in "${methods[@]}"; do
    rc=0
    timeout -k 5s 180s adb shell am instrument -w -r -e class "com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#$method" com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$mode/$method.txt" 2>&1 || rc=$?
    adb exec-out screencap -p > "$out/$mode/$method.png" 2>/dev/null || true
    if ((rc == 0)) && grep -Eq '^OK \(1 test\)' "$out/$mode/$method.txt" && ! grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$mode/$method.txt"; then
      echo "$mode $method PASS" >> "$out/results.txt"
    else echo "$mode $method FAIL_OR_NOT_REACHED exit=$rc" >> "$out/results.txt"; failed=1; fi
  done
done
adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true
cat "$out/results.txt"
exit "$failed"
