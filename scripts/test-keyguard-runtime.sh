#!/usr/bin/env bash
set -euo pipefail

# The emulator action executes each input line in a separate shell. Keep the
# test exit status and post-test evidence capture in this single owned script.
cd "$(dirname "$0")/../android"
test_result=0
./gradlew :app:connectedDebugAndroidTest --no-daemon \
  -Pandroid.injected.androidTest.leaveApksInstalledAfterRun=true \
  -Pandroid.testInstrumentationRunnerArguments.class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest,com.fluvi.app.lockscreen.KeyguardFirstDrawObservationInstrumentationTest,com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest \
  || test_result=$?
adb logcat -d -s FluviDrawProbe:I '*:S' > keyguard-draw-probe.log || true
# AGP otherwise uninstalls the target before this pull (run42926044104
# retained only "run-as: unknown package"). Keep the installation just long
# enough to collect the existing bounded failure images, then restore the
# same clean installation boundary before the independent service fixture.
# No assertion or sampling deadline changes; a passing smoke creates no PNG.
adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke \
  > keyguard-material-smoke.tar 2> keyguard-material-smoke-pull.log || true
adb uninstall com.fluvi.app.test || test_result=1
adb uninstall com.fluvi.app || test_result=1
bash ../scripts/test-keyguard-service-trace.sh || test_result=$?
exit "$test_result"
