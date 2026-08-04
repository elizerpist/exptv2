#!/usr/bin/env bash
set -euo pipefail

flutter drive \
  --driver=test_driver/dashboard_profile_driver.dart \
  --target=integration_test/dashboard_interaction_profile_test.dart \
  --profile \
  --dart-define=FLUVI_VERBOSE_FLOW=false \
  "$@"
