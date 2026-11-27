#!/usr/bin/env bash
set -euo pipefail

base=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out="${1:?observer temporary directory}"
mkdir -p "$out/classes"
sdk="$ANDROID_HOME/platforms/android-35/android.jar"
tools="$ANDROID_HOME/build-tools/36.0.0"
javac -cp "$sdk" --release 8 -d "$out/classes" "$base"/{ReadVisibleHierarchy,FrameTutorialTouch}.java
"$tools/d8" --lib "$sdk" --min-api 24 --output "$out" \
    "$out/classes/com/fluvi/r49/fixture/"{ReadVisibleHierarchy,FrameTutorialTouch}.class
"$tools/aapt2" link --manifest "$base/AndroidManifest.xml" -I "$sdk" -o "$out/empty.apk"
(cd "$out" && zip -q -0 empty.apk classes.dex)
"$tools/zipalign" -f 4 "$out/empty.apk" "$out/observer-unsigned.apk"
