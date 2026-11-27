#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
mode="${1:-release}"
case "$mode" in debug|profile|release) ;; *) exit 2 ;; esac
: "${FLUVI_BUILD_COMMIT:?Exact committed Fluvi source is required}"
: "${FLUVI_JDK17:?Path to JDK 17}"
: "${FLUVI_JDK21:?Path to JDK 21}"
: "${ANDROID_HOME:?Stock Flutter SDK}"
: "${FLUVI_WA_ANDROID_SDK:?Isolated WA compile SDK}"
test "$(git rev-parse HEAD)" = "$FLUVI_BUILD_COMMIT"
test "$(git rev-parse 'HEAD:third_party/widgets-anywhere')" = d00525e0c97815cbdf1c46ef806fffbd2100b10e
git diff --quiet HEAD

mkdir -p "${FLUVI_R49_STAGE_ROOT:-$root/build}"
stage="$(mktemp -d "${FLUVI_R49_STAGE_ROOT:-$root/build}/wa-${mode}-XXXXXXXX")"
module="$stage/payload"
export FLUVI_PAYLOAD_REPO="$module/build/host/outputs/repo"
export FLUVI_NATIVE_REPO="$stage/native-repo"
export FLUVI_ANDROID_MODE="$mode"
stock_sdk="$ANDROID_HOME"
host_gradle="${FLUVI_WA_GRADLE_HOME:-$stage/host-gradle}"
native_gradle="${GRADLE_USER_HOME:-$stage/native-gradle}"

(
    export JAVA_HOME="$FLUVI_JDK17"
    export PATH="$JAVA_HOME/bin:$PATH"
    export GRADLE_USER_HOME="$native_gradle"
    export ANDROID_SDK_ROOT="$stock_sdk"
    flutter create --no-pub --template=module --project-name fluvi --org com.fluvi "$module"
    # Both builds use the same original Dart package and root asset URIs.
    mv "$module/lib" "$module/scaffold-lib"
    ln -s "$root/lib" "$module/lib"
    ln -s "$root/assets" "$module/assets"
    ln -s "$root/shaders" "$module/shaders"
    cp "$root/pubspec.lock" "$module/pubspec.lock"
    cp "$root/pubspec.yaml" "$module/pubspec.yaml"
    cat >> "$module/pubspec.yaml" <<'YAML'
  module:
    androidX: true
    androidPackage: com.fluvi.payload
    iosBundleIdentifier: com.fluvi.payload
YAML
    (
        cd "$module"
        flutter pub get
        cmp pubspec.lock "$root/pubspec.lock"
        modes=(--no-debug --no-profile --no-release)
        case "$mode" in
            debug) modes[0]=--debug ;;
            profile) modes[1]=--profile ;;
            release) modes[2]=--release ;;
        esac
        flutter build aar "${modes[@]}" --no-pub \
            --dart-define=FLUVI_BUILD_COMMIT="$FLUVI_BUILD_COMMIT" \
            --dart-define=FLUVI_BUILD_PURPOSE="${FLUVI_BUILD_PURPOSE:-release}" \
            --dart-define=FLUVI_SEED_DEMO="${FLUVI_SEED_DEMO:-false}" \
            --dart-define=FLUVI_PHYSICAL_RAIL_DIAGNOSTICS="${FLUVI_PHYSICAL_RAIL_DIAGNOSTICS:-false}" \
            --dart-define=FLUVI_ONSCREEN_DIAGNOSTICS="${FLUVI_ONSCREEN_DIAGNOSTICS:-false}"
    )
    test -f "$FLUVI_PAYLOAD_REPO/com/fluvi/payload/flutter_$mode/1.0/flutter_$mode-1.0.pom"
    "$root/android/gradlew" -p "$root/android/r49-native" \
        publishReleasePublicationToFluviNativeRepository --no-daemon --max-workers=3
)

python3 "$root/android/wa-integration/prepare-host.py" "$stage/host"
(
    export JAVA_HOME="$FLUVI_JDK21"
    export PATH="$JAVA_HOME/bin:$PATH"
    export GRADLE_USER_HOME="$host_gradle"
    export ANDROID_HOME="$FLUVI_WA_ANDROID_SDK"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    cd "$stage/host"
    tasks=(":app:assemble${mode^}")
    if [[ "${FLUVI_R49_INCLUDE_FIXTURE:-false}" = true ]]; then
        tasks+=(":r49-control:assembleDebug")
    fi
    bash ./gradlew "${tasks[@]}" --no-daemon --max-workers=3 --console=plain
)
out="$root/build/app/outputs/flutter-apk/app-$mode.apk"
mkdir -p "$(dirname "$out")"
mapfile -t outputs < <(find "$stage/host/app/build/outputs/apk/$mode" -maxdepth 1 -name '*.apk' -type f)
test "${#outputs[@]}" = 1
cp "${outputs[0]}" "$out"
if [[ "${FLUVI_R49_INCLUDE_FIXTURE:-false}" = true ]]; then
    cp "$stage/host/r49-control/build/outputs/apk/debug/r49-control-debug.apk" "$(dirname "$out")/r49-control.apk"
fi
python3 scripts/verify-r49-host.py --apk "$out"
sha256sum "$out"
