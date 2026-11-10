#!/usr/bin/env bash
set -euo pipefail
# ARM64/proot fallback for pure contracts only, NOT Android/hardware validation.
# Android-file model declarations and pure freshness functions are extracted
# verbatim from production sources (Android-dependent reader APIs stay in CI);
# no queue, sampler, gate, visibility or freshness implementation is replaced.
compiler_lib=${1:?pass the Gradle distribution lib directory}
gate_tmp=$(mktemp -d /tmp/fluvi-system-gate.XXXXXX)
native=android/app/src/main/kotlin/com/fluvi/app/lockscreen
tests=android/app/src/test/kotlin/com/fluvi/app/lockscreen
{
  printf 'package com.fluvi.app.lockscreen\n'
  awk '/^internal enum class KeyguardWindowFreshness / { copy=1 } copy { print } copy && /^}/ { exit }' "$native/KeyguardWindowSnapshotReader.kt"
  awk '/^internal data class KeyguardDiagnosticContext\(/ { copy=1 } copy { print } copy && /^\)/ { exit }' "$native/KeyguardCardSettings.kt"
  printf 'internal object KeyguardWindowSnapshotReaderPolicy {\n'
  awk '/    fun shouldClearCache\(/ { copy=1 } /    \/\*\* Strategy selection/ { exit } copy { print }' "$native/KeyguardWindowSnapshotReader.kt"
  printf '}\n'
} > "$gate_tmp/ProductionModels.kt"
java -cp "$compiler_lib/*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect \
  -classpath "$compiler_lib/kotlin-stdlib-2.0.21.jar:$compiler_lib/junit-4.13.2.jar" \
  -d "$gate_tmp/tests.jar" "$gate_tmp/ProductionModels.kt" \
  "$native/KeyguardSystemState.kt" "$native/KeyguardCardInspectionQueue.kt" \
  "$native/KeyguardCardInspectionGate.kt" "$native/KeyguardInspectionFreshness.kt" "$native/KeyguardCardSurface.kt" \
  "$tests/KeyguardSystemStateSamplerTest.kt" "$tests/KeyguardCardInspectionQueueTest.kt" \
  "$tests/KeyguardInspectionFreshnessTest.kt"
java -cp "$gate_tmp/tests.jar:$compiler_lib/*" org.junit.runner.JUnitCore \
  com.fluvi.app.lockscreen.KeyguardSystemStateSamplerTest \
  com.fluvi.app.lockscreen.KeyguardCardInspectionQueueTest \
  com.fluvi.app.lockscreen.KeyguardInspectionFreshnessTest
printf 'Pure JVM evidence: %s\n' "$gate_tmp"
