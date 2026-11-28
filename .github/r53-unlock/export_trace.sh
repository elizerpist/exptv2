#!/usr/bin/env bash
set -euo pipefail
evidence_dir=${1:?evidence directory}
shopt -s nullglob
traces=("$evidence_dir"/attempt-*/unlock.pftrace)
((${#traces[@]} > 0)) || exit 0
tool="$RUNNER_TEMP/trace_processor_shell"
curl --disable -fsSL --proto '=https' \
  https://commondatastorage.googleapis.com/perfetto-luci-artifacts/v59.1/linux-amd64/trace_processor_shell -o "$tool"
printf '2434129a3af4dc9e2034a476f7b76447b490975213e301769310d3bd0d5d6458  %s\n' "$tool" | sha256sum -c
chmod 700 "$tool"
"$tool" --version > "$evidence_dir/trace-processor-version.txt"
for trace in "${traces[@]}"; do
  out=$(dirname "$trace")
  sha256sum "$trace" > "$out/trace-sha256.txt"
  query() {
    local target=$1
    cat > "$out/$target.sql"
    "$tool" --query-file "$out/$target.sql" "$trace" > "$out/$target.csv" 2>> "$out/trace-query-errors.txt" ||
      printf '%s unavailable\n' "$target" >> "$out/trace-query-errors.txt"
  }
  query markers <<'SQL'
SELECT ts, dur, name, track_id FROM slice
WHERE name GLOB 'FluviR52.*' OR name GLOB 'FluviR53.*' OR name GLOB '*Keyguard*' ORDER BY ts;
SQL
  query counters <<'SQL'
SELECT c.ts, a.name, c.value FROM counter c JOIN counter_track a ON c.track_id=a.id
WHERE a.name GLOB 'fluvi.r52.*' OR a.name GLOB 'fluvi.r53.*' ORDER BY ts;
SQL
  query clock-snapshots <<'SQL'
SELECT * FROM clock_snapshot ORDER BY ts;
SQL
  query layers <<'SQL'
WITH owned AS (
    SELECT DISTINCT layer_id FROM surfaceflinger_layer
    WHERE layer_name LIKE '%Fluvi Balance ORB%' OR layer_name LIKE '%com.fluvi.r53.reference%'
)
SELECT s.ts, l.layer_id, l.parent AS parent_layer_id, l.layer_name, l.is_visible, l.arg_set_id
FROM surfaceflinger_layer l JOIN surfaceflinger_layers_snapshot s ON l.snapshot_id=s.id
WHERE l.layer_id IN owned OR l.parent IN owned
ORDER BY s.ts,l.layer_id;
SQL
  query snapshots <<'SQL'
SELECT id, ts, has_invalid_elapsed_ts FROM surfaceflinger_layers_snapshot ORDER BY ts;
SQL
  query frame-timeline <<'SQL'
SELECT * FROM actual_frame_timeline_slice ORDER BY ts;
SQL
  query shell-transitions <<'SQL'
SELECT * FROM window_manager_shell_transitions;
SQL
  query sources <<'SQL'
SELECT 'input_dispatch' AS source, count(*) AS rows FROM __intrinsic_android_input_event_dispatch
UNION ALL SELECT 'wm_snapshots', count(*) FROM __intrinsic_windowmanager
UNION ALL SELECT 'sf_transactions', count(*) FROM surfaceflinger_transactions
UNION ALL SELECT 'shell_transitions', count(*) FROM window_manager_shell_transitions
UNION ALL SELECT 'actual_frame_timeline', count(*) FROM actual_frame_timeline_slice;
SQL
  query loss <<'SQL'
SELECT name, idx, value, severity FROM stats
WHERE value != 0 AND (name LIKE '%loss%' OR name LIKE '%overrun%' OR name LIKE '%drop%' OR severity != 'info')
ORDER BY name, idx;
SQL
done
