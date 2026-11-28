#!/usr/bin/env bash
set -euo pipefail
url=${1:?reference APK URL}
hash=${2:?reference APK SHA-256}
size=${3:?reference APK bytes}
sha=${4:?reference source SHA}
cert=${5:?reference certificate SHA-256}
apk=${6:?local destination}
[[ "$url" =~ ^https://media\.githubusercontent\.com/media/elizerpist/exptv2/[0-9a-f]{40}/[A-Za-z0-9_]+\.apk$ ]]
[[ "$hash" =~ ^[0-9a-f]{64}$ && "$sha" =~ ^[0-9a-f]{40}$ && "$cert" =~ ^[0-9a-f]{64}$ && "$size" =~ ^[0-9]+$ ]]
tools=${ANDROID_HOME:?}/build-tools/36.0.0
http=$(curl --disable --fail --silent --show-error --location --proto '=https' \
  --max-time 120 -w '%{http_code}' "$url" -o "$apk")
test "$http" = 200
test "$(wc -c < "$apk")" = "$size"
printf '%s  %s\n' "$hash" "$apk" | sha256sum -c
"$tools/apksigner" verify --verbose --print-certs "$apk" |
  tee "$apk.signers" | grep -Fx "Signer #1 certificate SHA-256 digest: $cert"
badging=$("$tools/aapt2" dump badging "$apk")
printf '%s\n' "$badging" | grep "package: name='com.fluvi.r53.reference' versionCode='1' versionName='1.0'"
printf '%s\n' "$badging" | grep "launchable-activity: name='com.fluvi.r53.reference.ReferenceActivity'"
if printf '%s\n' "$badging" | grep -qE '^uses-permission:'; then
  exit 1
fi
unzip -tq "$apk" >/dev/null
unzip -p "$apk" classes.dex | strings | grep -Fx "$sha"
"$tools/zipalign" -c 4 "$apk"
printf 'url=%s\nhttp=%s\nbytes=%s\nsha256=%s\nsource=%s\ncertificate=%s\n' "$url" "$http" "$size" "$hash" "$sha" "$cert"
