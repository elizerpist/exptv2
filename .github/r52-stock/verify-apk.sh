#!/usr/bin/env bash
set -euo pipefail
url="$1"
hash="$2"
size="$3"
sha="$4"
apk="$5"
[[ "$url" =~ ^https://media\.githubusercontent\.com/media/elizerpist/exptv2/[0-9a-f]{40}/[A-Za-z0-9_]+\.apk$ ]]
[[ "$sha" =~ ^[0-9a-f]{40}$ && "$hash" =~ ^[0-9a-f]{64}$ && "$size" =~ ^[0-9]+$ ]]
curl --disable -fLsS --proto '=https' "$url" -o "$apk"
test "$(wc -c < "$apk")" = "$size"
printf '%s  %s\n' "$hash" "$apk" | sha256sum -c
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose --print-certs "$apk" |
  tee -a evidence/signers.txt |
  grep 'Signer #1 certificate SHA-256 digest: faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb'
python3 - "$apk" "$sha" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as apk:
    assert apk.testzip() is None
    for abi in ('arm64-v8a', 'armeabi-v7a', 'x86_64'):
        payload = apk.read(f'lib/{abi}/libapp.so')
        assert sys.argv[2].encode() in payload and b'HUMAN_DIAGNOSTIC' in payload
PY
printf '%s\n' "$sha $hash $size $url" >> evidence/apks.txt
