#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
evidence_dir=android/keyguard-service-evidence
trace="$evidence_dir/fluvi-keyguard-service.perfetto-trace"
test -s "$trace"
# Analysis runs on the CI host after the emulator workload. Record the actual
# official processor identity; it is not an application dependency.
curl --fail --location --retry 3 https://get.perfetto.dev/trace_processor \
  -o "$evidence_dir/trace_processor"
chmod +x "$evidence_dir/trace_processor"
"$evidence_dir/trace_processor" --version > "$evidence_dir/processor-version.txt"
sha256sum "$evidence_dir/trace_processor" > "$evidence_dir/processor-launcher.sha256"
"$evidence_dir/trace_processor" "$trace" -q scripts/keyguard-service-trace.sql \
  > "$evidence_dir/trace-analysis.txt" 2> "$evidence_dir/trace-analysis-stderr.txt"
