#!/usr/bin/env bash
set -euo pipefail
python3 .github/r51-stock/lifecycle.py "$RUNNER_TEMP/human.apk" evidence \
    --observer "$RUNNER_TEMP/observer.apk" --app-sha "$APP_SHA"
