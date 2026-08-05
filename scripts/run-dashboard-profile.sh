#!/usr/bin/env bash
set -euo pipefail

device_args=()
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  device_args+=(--device-id "$ANDROID_SERIAL")
elif [[ -n "${EMULATOR_PORT:-}" ]]; then
  device_args+=(--device-id "emulator-${EMULATOR_PORT}")
fi

flutter drive "${device_args[@]}" \
  --driver=test_driver/dashboard_profile_driver.dart \
  --target=integration_test/dashboard_interaction_profile_test.dart \
  --profile \
  --dart-define=FLUVI_VERBOSE_FLOW=false \
  "$@"
