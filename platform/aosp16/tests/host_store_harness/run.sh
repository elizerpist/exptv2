#!/usr/bin/env bash
# Compile the actual platform store and reducer with a controllable renderer.
# This is a concurrency/unit control, not a SystemUI, GPU or pixel test.
set -euo pipefail
: "${R29_KOTLIN_COMPILER_CP:?Set to the Kotlin compiler and runtime classpath}"
: "${R29_KOTLIN_STDLIB:?Set to the matching Kotlin stdlib jar}"
root=$(git rev-parse --show-toplevel)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
java -cp "$R29_KOTLIN_COMPILER_CP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -no-stdlib -no-reflect -classpath "$R29_KOTLIN_STDLIB" -d "$tmpdir" \
  "$root/platform/aosp16/contract/src/com/fluvi/r29/contract/R29Protocol.kt" \
  "$root/platform/aosp16/contract/src/com/fluvi/r29/contract/R29HostReducer.kt" \
  "$root/platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt" \
  "$root/platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt" \
  "$root/platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R35HostMemoryPolicy.kt" \
  "$root/platform/aosp16/tests/host_store_harness/R29HostRendererStub.kt" \
  "$root/platform/aosp16/tests/host_store_harness/ResidentHarness.kt"
java -cp "$tmpdir:$R29_KOTLIN_STDLIB" com.android.systemui.keyguard.fluvi.ResidentHarnessKt
