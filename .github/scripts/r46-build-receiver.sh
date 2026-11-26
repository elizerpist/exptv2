#!/usr/bin/env bash
set -euo pipefail
fixture="$GITHUB_WORKSPACE/orchestrator/.github/fixtures/r46-paste"
dest="$RUNNER_TEMP/r46-receiver"
mkdir -p "$dest/classes" "$dest/dex"
tools="$ANDROID_HOME/build-tools/36.0.0"
platform="$ANDROID_HOME/platforms/android-36/android.jar"
test -f "$platform"
javac -source 8 -target 8 -classpath "$platform" -d "$dest/classes" "$fixture/PasteActivity.java"
mapfile -t classfiles < <(find "$dest/classes" -name '*.class' -type f | sort)
"$tools/d8" --lib "$platform" --output "$dest/dex" "${classfiles[@]}"
"$tools/aapt" package -f -M "$fixture/AndroidManifest.xml" -I "$platform" -F "$dest/unsigned.apk"
(cd "$dest/dex" && zip -q "$dest/unsigned.apk" classes.dex)
"$tools/zipalign" -f 4 "$dest/unsigned.apk" "$dest/aligned.apk"
keytool -genkeypair -keystore "$dest/receiver.keystore" -storepass android -keypass android \
  -alias receiver -dname 'CN=R46 Test Receiver' -keyalg RSA -keysize 2048 -validity 3 >/dev/null 2>&1
"$tools/apksigner" sign --ks "$dest/receiver.keystore" --ks-key-alias receiver --ks-pass pass:android \
  --key-pass pass:android --out "$dest/receiver.apk" "$dest/aligned.apk"
"$tools/apksigner" verify "$dest/receiver.apk"
