#!/usr/bin/env bash
set -euo pipefail
trials=1
if [[ "$STOCK_API" = 37.0 ]]; then trials=3; fi
flags=()
if [[ "$MODE" = baseline ]]; then flags+=(--baseline); fi
python3 scripts/test-r51-orb-transitions.py "$RUNNER_TEMP/human.apk" "$STOCK_API" evidence \
    --observer "$RUNNER_TEMP/observer.apk" --app-sha "$APP_SHA" --repetitions "$trials" "${flags[@]}"
