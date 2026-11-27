#!/usr/bin/env bash
set -euo pipefail
python -m pip install Pillow==11.3.0
command -v ffmpeg || { sudo apt-get -qq update && sudo apt-get -qq install -y --no-install-recommends ffmpeg; }
test -c /dev/kvm
sudo chmod 0666 /dev/kvm
bash scripts/r49-fixture/build-observer.sh "$RUNNER_TEMP/observer"
keytool -genkeypair -keystore "$RUNNER_TEMP/observer.jks" -alias fixture -storepass android \
  -keypass android -dname 'CN=Fluvi disposable observer' -keyalg RSA -validity 1
"$ANDROID_HOME/build-tools/36.0.0/apksigner" sign --ks "$RUNNER_TEMP/observer.jks" --ks-pass pass:android \
  --out "$RUNNER_TEMP/observer.apk" "$RUNNER_TEMP/observer/observer-unsigned.apk"
ffmpeg -version > evidence/decoder-version.txt
ffprobe -version >> evidence/decoder-version.txt
