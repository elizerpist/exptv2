#!/usr/bin/env bash
set -euo pipefail

# The emulator action executes each input line in a separate shell. Keep the
# test exit status and post-test evidence capture in this single owned script.
cd "$(dirname "$0")/../android"
test_result=0
./gradlew :app:connectedDebugAndroidTest --no-daemon \
  -Pandroid.testInstrumentationRunnerArguments.class=com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest,com.fluvi.app.lockscreen.KeyguardFirstDrawObservationInstrumentationTest,com.fluvi.app.lockscreen.KeyguardCardDiagnosticsInstrumentationTest \
  || test_result=$?
adb logcat -d -s FluviDrawProbe:I '*:S' > keyguard-draw-probe.log || true
bash ../scripts/test-keyguard-service-trace.sh || test_result=$?
exit "$test_result"
