#!/usr/bin/env bash
set -euo pipefail

reference_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out=${1:?absolute build directory}
signer=${2:?existing PKCS12 reference keystore}
: "${R53_KEYSTORE_PASSWORD:?reference keystore password}"
sdk=${ANDROID_HOME:?}/platforms/android-35/android.jar
tools=$ANDROID_HOME/build-tools/36.0.0
source_head=$(git -C "$reference_dir" rev-parse HEAD)
git -C "$reference_dir" diff --quiet HEAD -- .
test -z "$(git -C "$reference_dir" ls-files --others --exclude-standard -- .)"

mkdir -p "$out/classes"
cat > "$out/BuildIdentity.java" <<EOF
package com.fluvi.r53.reference;

final class BuildIdentity {
    static final String SOURCE = "$source_head";
    private BuildIdentity() {}
}
EOF

javac --release 8 -cp "$sdk" -d "$out/classes" \
    "$reference_dir/ReferenceActivity.java" "$out/BuildIdentity.java"
"$tools/d8" --lib "$sdk" --min-api 26 --output "$out" "$out/classes/com/fluvi/r53/reference/"*.class
"$tools/aapt2" link -I "$sdk" --manifest "$reference_dir/AndroidManifest.xml" -o "$out/base.apk"
# Add DEX without compression, then align before signing.
(cd "$out" && zip -q -0 base.apk classes.dex)
"$tools/zipalign" -f 4 "$out/base.apk" "$out/unsigned.apk"
"$tools/apksigner" sign --ks "$signer" --ks-key-alias r53-reference \
    --ks-pass env:R53_KEYSTORE_PASSWORD --out "$out/reference.apk" "$out/unsigned.apk"
"$tools/apksigner" verify --verbose --print-certs "$out/reference.apk"
