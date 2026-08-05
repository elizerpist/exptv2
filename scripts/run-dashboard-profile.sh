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

capture_profile_host_diagnostics() {
  profile_status=$?
  trap - EXIT
  set +e

  profile_diagnostics_dir=build/dashboard-profile-diagnostics
  mkdir -p "$profile_diagnostics_dir"
  {
    date --iso-8601=seconds
    uname -a
    free -m
    df -h
    ps -eo pid,ppid,stat,rss,vsz,comm,args --sort=-rss
  } >"$profile_diagnostics_dir/host-state.txt" 2>&1
  if [[ -r /sys/fs/cgroup/memory.events ]]; then
    cp /sys/fs/cgroup/memory.events \
      "$profile_diagnostics_dir/cgroup-memory.events"
  fi
  if [[ -r /proc/pressure/memory ]]; then
    cp /proc/pressure/memory "$profile_diagnostics_dir/memory-pressure.txt"
  fi
  diagnostic_timeout=(timeout --signal=TERM --kill-after=2s 10s)
  "${diagnostic_timeout[@]}" sudo -n dmesg --ctime \
    >"$profile_diagnostics_dir/kernel-dmesg.txt" 2>&1
  "${diagnostic_timeout[@]}" journalctl -k -b --no-pager \
    >"$profile_diagnostics_dir/kernel-journal.txt" 2>&1
  "${diagnostic_timeout[@]}" adb "${adb_device_args[@]}" logcat -b all -d \
    >"$profile_diagnostics_dir/android-logcat.txt" 2>&1
  cp -a /tmp/android-runner/emu-crash-* "$profile_diagnostics_dir/" \
    2>>"$profile_diagnostics_dir/host-state.txt"

  exit "$profile_status"
}

trap capture_profile_host_diagnostics EXIT

adb "${adb_device_args[@]}" shell am wait-for-broadcast-barrier --flush-broadcast-loopers --flush-application-threads
adb "${adb_device_args[@]}" shell am wait-for-application-barrier

flutter drive "${device_args[@]}" \
  --driver=test_driver/dashboard_profile_driver.dart \
  --target=integration_test/dashboard_interaction_profile_test.dart \
  --profile \
  --no-dds \
  --dart-define=FLUVI_VERBOSE_FLOW=false \
  "$@"
