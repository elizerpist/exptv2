# Mind Year populated-payload readiness implementation plan

> **For agentic workers:** Execute inline because the data-flow investigation,
> RED, and smallest repair share the same Core ownership boundary; splitting
> them would create conflicting state assumptions.

**Goal:** Make actual populated Mind MonthCard payload paint with the same
accepted Summary/list Year generation, without losing realtime transient
following or adding hot-path work.

**Architecture:** Reuse the existing Core accepted temporal target, bounded
prepared base and immutable annual membership.  First locate the precise
admission/publication boundary where that resident data fails to travel with a
populated visible target; then change only that owner.  The list rich scene is
not a dependency.

**Tech stack:** Flutter widget tests, Core diagnostics, Ubuntu-proot Flutter,
existing SCIP graph.

## Global constraints

- Time carousel/controller/ScrollPosition/physics are no-touch.
- No timer, debounce, settle-only fallback, target drop, remount, cache flush,
  repository/Room/index/full-row/query/rich-scene/TextPainter hot-path work,
  or second Year authority.
- Tests must assert exact non-empty colored day sets and actual MonthCard paint,
  not identity alone.

### Task 1: Establish a deterministic populated-payload RED

**Files:**

- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

- [x] Seed 2025 and 2026 with disjoint, multi-day Income fixture rows and
  2027 empty; mount `CoreDashboard` in Mind/Year through the real segmented
  selector.
- [x] In `MYPL-01`, capture actual `SUMMARY_TARGET_PAINTED`,
  `LOGBOX|VISIBLE_ROWS_BOUND`, `MIND_HEATMAP|IDENTITY_RESOLVED`,
  `FRAME_PUBLISHED` and `PAINTED` events each rendered frame.  At the first
  real populated 2026 Summary/list paint, require
  `_coloredHeatmapDates(core.mindYearHeatmap.value!)` to equal the exact 2026
  dates and require the viewport's paint diagnostic to carry the same year/G
  no later than one further `tester.pump()`.
- [x] Run only the test through Ubuntu proot and retain its expected
  current-parent assertion failure before changing application source.

### Task 2: Prove the first late owner

**Files:**

- Potentially modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Potentially modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

- [x] If `MYPL-01` does not expose each Core decision, add one bounded safe
  diagnostic at `noteSegmentedSummaryComponentVisualTargetPainted` and its
  exact rejection/admission boundary.  It must record Year/G, accepted-target
  identity, admitted-base/membership availability, install result and no
  transaction payload.
- [x] Repeat `MYPL-01` and identify the first absence before list-ready data:
  callback, base/membership, projection, live publication, or actual paint.
- [x] Do not mutate the repair owner until this test/diagnostic result is
  explicit.

### Task 3: Repair exactly the proven Core boundary

**Files:**

- Modify: exact first-owner file proved by Task 2 (expected:
  `lib/features/dashboard/application/dashboard_core_controller.dart`)
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

- [x] Keep the existing accepted Year/G as the only temporal authority and
  make its already-admitted immutable annual membership eligible before the
  populated Summary/list target may visually publish.
- [x] Run MYPL-01 RED-to-GREEN; then add/run empty→populated, list-vs-heatmap,
  stress, held-slider and zero-work checks.
- [x] Reject stale/coalesced frames rather than masking them with previous
  colors or waiting for canonical settle.

### Task 4: Validate delivery

**Files:**

- Modify: factual architecture/checklist/plan and
  `docs/FLUVI_ENGINEERING_JOURNAL.md` in a separate `[skip ci]` commit after
  the application commit.

- [x] Run affected Mind/Core/Summary/Time/LogBox/slider suites and analyzer in
  Ubuntu proot; report profile failures without weakening gates.
- [ ] Push the atomic application repair, monitor the matching GitHub human
  APK job, download the normal APK to `/storage/emulated/0/Download/fluvi`,
  hash it, and regenerate final matching SCIP outside the user-untracked
  application `index.scip`.
