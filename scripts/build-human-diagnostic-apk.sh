#!/usr/bin/env bash
set -euo pipefail

: "${FLUVI_BUILD_COMMIT:?FLUVI_BUILD_COMMIT is required}"

flutter build apk --profile \
  --dart-define=FLUVI_SEED_DEMO=true \
  --dart-define=FLUVI_PHYSICAL_RAIL_DIAGNOSTICS=true \
  --dart-define=FLUVI_ONSCREEN_DIAGNOSTICS=true \
  --dart-define=FLUVI_BUILD_PURPOSE=human_diagnostic \
  --dart-define=FLUVI_BUILD_COMMIT="${FLUVI_BUILD_COMMIT}" \
  --dart-define=FLUVI_VERBOSE_FLOW=false
