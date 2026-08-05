#!/usr/bin/env bash
set -euo pipefail

device_args=()
adb_device_args=()
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  device_args+=(--device-id "$ANDROID_SERIAL")
  adb_device_args+=(-s "$ANDROID_SERIAL")
elif [[ -n "${EMULATOR_PORT:-}" ]]; then
  device_args+=(--device-id "emulator-${EMULATOR_PORT}")
  adb_device_args+=(-s "emulator-${EMULATOR_PORT}")
fi

adb "${adb_device_args[@]}" shell am wait-for-broadcast-barrier --flush-broadcast-loopers --flush-application-threads
adb "${adb_device_args[@]}" shell am wait-for-application-barrier

flutter drive "${device_args[@]}" \
  --driver=test_driver/dashboard_profile_driver.dart \
  --target=integration_test/dashboard_interaction_profile_test.dart \
  --profile \
  --no-dds \
  --dart-define=FLUVI_VERBOSE_FLOW=false \
  "$@"
