#!/usr/bin/env bash
set -eu
out="$1"
shopt -s nullglob
items=("$out"/*.pftrace)
if (( ${#items[@]} == 0 )); then
  printf 'No trace was collected\n' > "$out/trace-status.txt"
  exit 0
fi
tool="$RUNNER_TEMP/trace_processor"
if ! curl -fsSL --proto '=https' https://get.perfetto.dev/trace_processor -o "$tool"; then
  printf 'Trace Processor download unavailable\n' > "$out/trace-status.txt"
  exit 0
fi
chmod 700 "$tool"
"$tool" --version > "$out/trace-processor-version.txt" 2>&1 || true
for trace in "${items[@]}"; do
  name="${trace%.pftrace}"
  cat > "$out/statistics.sql" <<'SQL'
SELECT name, idx, severity, source, value FROM stats WHERE value > 0 ORDER BY name, idx;
SQL
  "$tool" --query-file "$out/statistics.sql" "$trace" > "$name-stats.csv" 2> "$name-query-errors.txt" || true
  cat > "$out/markers.sql" <<'SQL'
SELECT ts, dur, name, track_id
FROM slice
WHERE name GLOB 'FluviR52.*' OR name LIKE '%keyguardGoingAway%' OR name LIKE '%PowerManager%'
 OR name LIKE '%KeyguardTransition%' OR name LIKE '%dispatchMotion%'
ORDER BY ts;
SQL
  "$tool" --query-file "$out/markers.sql" "$trace" > "$name-markers.csv" 2>> "$name-query-errors.txt" || true
  cat > "$out/counters.sql" <<'SQL'
SELECT c.ts, t.name, c.value FROM counter c JOIN counter_track t ON t.id = c.track_id
WHERE t.name GLOB 'fluvi.r52.*' ORDER BY c.ts, t.name;
SQL
  "$tool" --query-file "$out/counters.sql" "$trace" > "$name-counters.csv" 2>> "$name-query-errors.txt" || true
  cat > "$out/layer.sql" <<'SQL'
SELECT * FROM surfaceflinger_layer WHERE name LIKE '%Fluvi Balance ORB%';
SQL
  "$tool" --query-file "$out/layer.sql" "$trace" > "$name-orb-layer.csv" 2>> "$name-query-errors.txt" || true
done
