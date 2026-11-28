#!/usr/bin/env bash
set -euo pipefail
case "$LANE" in
    upgrade)
        python3 .github/r55/upgrade_ambient.py --sha "$APP_SHA" --baseline "$RUNNER_TEMP/r54.apk" \
          --apk "$RUNNER_TEMP/fluvi.apk" --observer "$RUNNER_TEMP/observer.apk" --output evidence/upgrade
        ;;
    masked)
        python3 .github/r53-unlock/run_unlock.py --app-sha "$APP_SHA" --apk "$RUNNER_TEMP/fluvi.apk" \
          --observer "$RUNNER_TEMP/observer.apk" --reference "$RUNNER_TEMP/reference.apk" \
          --reference-sha "$REFERENCE_SHA" --output evidence/unlock
        ;;
esac
