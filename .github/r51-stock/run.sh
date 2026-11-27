#!/usr/bin/env bash
set -euo pipefail
python3 .github/r51-stock/home-probe.py "$RUNNER_TEMP/human.apk" evidence \
    --observer "$RUNNER_TEMP/observer.apk"
