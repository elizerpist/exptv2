#!/usr/bin/env bash
# Verify the reviewed R35 baseline did not already register the trial provider.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
base="$root/r36-baseline"
out="$root/android/keyguard-r36-widget"
mkdir -p "$out"
test "$(git -C "$base" rev-parse HEAD)" = c1d1c552315618e24a224b8dae6ef26852e48d03
(cd "$base" && flutter pub get) > "$out/baseline-pub-get.log" 2>&1
if ! (cd "$base/android" && ./gradlew :app:processProfileMainManifest --no-daemon --max-workers=3 --console=plain) > "$out/baseline-manifest-build.log" 2>&1; then
  tail -80 "$out/baseline-manifest-build.log"; exit 1
fi
manifest=$(find "$base/build/app/intermediates/merged_manifest" -path '*profile*' -name AndroidManifest.xml -type f -print -quit)
test -n "$manifest" && test -s "$manifest"
cp "$manifest" "$out/baseline-profile-manifest.xml"
if grep -Fq 'FluviOrbLockscreenTrialProvider' "$manifest"; then
  echo 'Unexpected trial provider in the R35 baseline' >&2; exit 1
fi
printf 'baseline=%s\nprovider=ABSENT\n' c1d1c552315618e24a224b8dae6ef26852e48d03 > "$out/baseline-status.txt"
