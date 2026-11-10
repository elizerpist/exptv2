-- Evidence only: do not interpret aggregate CPU, shader submissions or an
-- emulator's FrameTimeline as Nothing-device performance/physical acceptance.
SELECT 'COVERAGE' AS section, (SELECT count(*) FROM sched) AS sched_rows,
  (SELECT count(*) FROM thread_state) AS thread_state_rows,
  (SELECT count(*) FROM slice) AS slice_rows,
  (SELECT count(*) FROM actual_frame_timeline_slice) AS frame_timeline_rows;
SELECT 'TRACE_ISSUE' AS section, name, idx, severity, value FROM stats
  WHERE value != 0 AND (severity != 'info' OR name GLOB '*lost*' OR name GLOB '*drop*');
SELECT 'APP_THREAD' AS section, p.pid, p.name AS process, t.tid, t.name AS thread
  FROM thread t JOIN process p USING(upid) WHERE p.name GLOB '*com.fluvi.app*';
SELECT 'SCENARIO' AS section, s.ts, s.dur, s.name, t.name AS thread
  FROM slice s JOIN thread_track tt ON tt.id=s.track_id JOIN thread t USING(utid)
  WHERE s.name GLOB 'KGProbe.*' ORDER BY s.ts;
SELECT 'OWN_MAIN_RENDER_SLICE' AS section, s.ts, s.dur, s.name, t.tid, t.name AS thread
  FROM slice s JOIN thread_track tt ON tt.id=s.track_id
  JOIN thread t USING(utid) JOIN process p USING(upid)
  WHERE p.name='com.fluvi.app' AND (t.tid=p.pid OR t.name='RenderThread') AND s.dur>0
  ORDER BY s.dur DESC LIMIT 100;
SELECT 'MAIN_THREAD_STATE' AS section, state, blocked_function, count(*) AS spans,
  sum(dur)/1e6 AS total_ms, max(dur)/1e6 AS max_ms
  FROM thread_state JOIN thread USING(utid) JOIN process USING(upid)
  WHERE process.name='com.fluvi.app' AND thread.tid=process.pid AND dur>0
  GROUP BY state, blocked_function ORDER BY total_ms DESC;
SELECT 'OVERLAY_FRAMETIMELINE' AS section, layer_name, jank_type, present_type,
  count(*) AS frames, avg(dur)/1e6 AS avg_ms, max(dur)/1e6 AS max_ms
  FROM actual_frame_timeline_slice WHERE layer_name GLOB '*FluviKeyguardCard*'
  GROUP BY layer_name,jank_type,present_type;
SELECT 'FRAME_LAYERS' AS section, layer_name, count(*) AS frames
  FROM actual_frame_timeline_slice GROUP BY layer_name ORDER BY frames DESC LIMIT 30;
