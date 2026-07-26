# Bugfix 20260726 v2 – implementation plan

**Reference checklist:** `docs/superpowers/checklists/bugfix20260726v2.md`
**Visual source of truth:** `balance_latest_layout.html`, B3M-A3 permanent
time-rail screen and the approved Android screenshot cited by the checklist.

## Root cause recorded before implementation

- Income/expense switching changes store state immediately.  The observed
  0.6–1.6 s delay occurs afterwards while a new `BalanceFrame` scans and
  aggregates the query scope on the UI isolate, then rebuilds the dashboard.
- The log is bounded, but its visible-window/cache decisions and the frame
  cache outcome are not logged together; this obscures whether a stall is a
  query, cache or widget-build problem.
- The shared ticking viewport builds only the five logical rail slots.  It
  therefore has no already-built neighbour when a new rail item crosses the
  visible edge.
- Flutter uses stale B3M-A3 geometry constants, while the current HTML
  permanent rail has a 72 px FastInfo row, 218 px detail stage and 11 px
  vertical grid gaps.  The app cannot be exact while those values are copied
  separately.

## Execution and verification

1. Add failing unit/widget tests for the B3M-A3 metric manifest, the rail's
   prebuilt neighbours and structured trace fields.  Make the Flutter visual
   constants consume the metric manifest.
2. Correct SearchPill focus/layout and action-toggle surface ownership from
   exact constants; test the single outer focus outline and inactive surface.
3. Build one extra offscreen neighbour at either end of a rail; keep the
   visual five-slot viewport clipped.  Keep FastInfo/detail pages alive around
   selection and log their local selection lifecycle.
4. Move the log-row avatar to central category colour/icon resolution, remove
   the redundant right-edge edit control, and add the rounded-square layered
   light/shadow treatment.  Add a category-change regression test.
5. Make the frame and log-window cache outcome explicit.  Avoid eagerly
   counting every log entry when a bounded source count can answer `hasMore`.
   Add correlated, release-safe traces for type switch, rail selection/load,
   FastInfo detail selection and scroll sessions.
6. Run targeted tests in Ubuntu proot, then the relevant test suite and
   `flutter analyze`.  Re-read the checklist and update each evidence-backed
   status; screenshot parity remains `PARTIAL` until verified on device.

## Guardrails

- No full list construction or per-frame logging in a scrolling path.
- Diagnostic fields are enum, count, duration, cache-state and safe scope
  tokens only; never transaction text, merchant names or user queries.
- The prebuilt slots remain clipped outside the five visible rail positions,
  so the B3M-A3 gutter remains unchanged.
