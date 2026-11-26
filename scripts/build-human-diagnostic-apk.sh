#!/usr/bin/env bash
set -euo pipefail

: "${FLUVI_BUILD_COMMIT:?FLUVI_BUILD_COMMIT is required}"

# The static handset widget needs no demo database. Keep existing user data
# intact on update; explicit disposable fixtures may opt in to demo seeding.
flutter build apk --profile \
  --dart-define=FLUVI_SEED_DEMO="${FLUVI_HUMAN_SEED_DEMO:-false}" \
  --dart-define=FLUVI_PHYSICAL_RAIL_DIAGNOSTICS=true \
  --dart-define=FLUVI_ONSCREEN_DIAGNOSTICS=true \
  --dart-define=FLUVI_BUILD_PURPOSE=human_diagnostic \
  --dart-define=FLUVI_R448_SAFE_SAMPLE_ONLY="${FLUVI_R448_SAFE_SAMPLE_ONLY:-false}" \
  --dart-define=FLUVI_BUILD_COMMIT="${FLUVI_BUILD_COMMIT}" \
  --dart-define=FLUVI_VERBOSE_FLOW=false
