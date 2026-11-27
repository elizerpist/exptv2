#!/usr/bin/env bash
set -euo pipefail
python3 .github/r52-stock/r52_measure.py --apk "$RUNNER_TEMP/human.apk" --sha "$APP_SHA" \
  --observer "$RUNNER_TEMP/observer.apk" --api "$STOCK_API" --output evidence/experiment
