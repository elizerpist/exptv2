#!/usr/bin/env bash
set -euo pipefail
flags=(--effects)
if [[ "$MODE" = baseline ]]; then flags+=(--baseline --effects-only); fi
python3 scripts/test-r51-orb-transitions.py "$RUNNER_TEMP/human.apk" "$STOCK_API" evidence \
    --observer "$RUNNER_TEMP/observer.apk" --app-sha "$APP_SHA" --repetitions 1 "${flags[@]}"
