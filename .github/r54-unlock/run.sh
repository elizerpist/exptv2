#!/usr/bin/env bash
set -euo pipefail
observer="$RUNNER_TEMP/observer.apk"
case "$CASE" in
    upgrade)
        python3 .github/r54-unlock/upgrade.py --apk "$RUNNER_TEMP/r54.apk" \
          --baseline "$RUNNER_TEMP/r52.apk" --observer "$observer" --sha "$APP_SHA" --output evidence/upgrade
        ;;
    optical-r52|optical-r54)
        product=r54
        source_sha="$APP_SHA"
        if [[ "$CASE" == optical-r52 ]]; then product=r52; source_sha="$R52_SHA"; fi
        python3 .github/r53-unlock/run_unlock.py --app-sha "$source_sha" --repeat-valid \
          --apk "$RUNNER_TEMP/$product.apk" --observer "$observer" \
          --reference "$RUNNER_TEMP/reference.apk" --reference-sha "$REFERENCE_SHA" --output evidence/unlock
        ;;
    material)
        python3 .github/r52-stock/mask_controls.py --apk "$RUNNER_TEMP/r54.apk" \
          --observer "$observer" --sha "$APP_SHA" --mask .github/r52-stock/expected-lock-mask.png \
          --output evidence/material
        ;;
    legacy)
        python3 .github/r54-unlock/legacy.py --apk "$RUNNER_TEMP/r54.apk" \
          --observer "$observer" --sha "$APP_SHA" --output evidence/legacy
        ;;
    restricted)
        python3 .github/r54-unlock/restricted.py --apk "$RUNNER_TEMP/r54.apk" \
          --observer "$observer" --output evidence/restricted
        ;;
esac
