#!/usr/bin/env bash
set -euo pipefail
if [[ "$SCENARIO" == home ]]; then
    python3 .github/r52-stock/home_provider.py "$RUNNER_TEMP/human.apk" evidence/home --observer "$RUNNER_TEMP/observer.apk"
else
    python3 .github/r52-stock/aod_control.py --apk "$RUNNER_TEMP/human.apk" --output evidence/aod \
      --observer "$RUNNER_TEMP/observer.apk" --sha "$APP_SHA"
fi
