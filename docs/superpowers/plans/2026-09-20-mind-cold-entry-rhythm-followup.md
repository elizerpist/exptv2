# Mind cold-entry, sparse-Sum, and temporal-card follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Repair the proven sparse detailed-Sum paint-context boundary, measure
then repair the first Mind-entry cold path, and complete the requested
presentation improvements without changing financial membership semantics.

**Architecture:** The existing Core-owned immutable Mind frames remain the
only financial data path. Sparse Sum continuity is a paint-only selection
extension over the existing LOD model; cold-start work first adds bounded
Core→widget timing evidence. Month/Day visual changes reuse the existing
palette resolver and shared temporal-stat component, while partner labels must
be admitted into the immutable Day event model rather than queried from UI.

**Tech Stack:** Flutter/Dart, existing `package:test`/Flutter widget tests,
GitHub Actions normal human diagnostic APK, existing Mind presentation settings.

## Global Constraints

- Preserve canonical Query, filters, amount-slider preview/commit semantics,
  heatmap intensity, Scope/Zárás authority, Budget/Balance behavior and the
  `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` interaction floor.
- No Drive-log inference beyond the frozen 19c proof; cold-start repair needs
  stage-correlated evidence before production mutation.
- No repository, Room, raw-ledger or Query work in chart paint/tap/pinch,
  timeline build, slider preview or presentation-setting changes.
- Use tests first; every implementation commit receives a separate
  `docs/FLUVI_ENGINEERING_JOURNAL.md`-only `[skip ci]` commit.
- Final delivery requires a pushed application SHA, exact Actions lane report,
  normal downloaded human APK/hash and user-only physical validation status.

---

### Task 1: Freeze the sparse-Sum boundary with a failing contract

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Modify: `test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`

**Consumes:** `MindSumHeatmapFrame.detailPointsForYear`,
`MindDetailedSumLod.select`, `MindDetailedSumLodSelection.inspectablePoints`,
`MindDetailedSumLodSelection.paintPoints`.

**Produces:** A test proving that a sparse 2027 real neighbour outside current
one-bucket padding is available to paint but is never inspectable.

- [ ] **Step 1: Write the failing sparse-neighbour test**

```dart
test('SUM-SPARSE-01 keeps the nearest real out-of-window anchor for paint only', () {
  final selection = selectSparseYearWithNeighbourBeyondSinglePadding();
  expect(selection.inspectablePoints, hasLength(6));
  expect(selection.paintPoints, contains(neighbourOutsideWindow));
  expect(selection.inspectablePoints, isNot(contains(neighbourOutsideWindow)));
});
```

- [ ] **Step 2: Run it red**

Run:
`flutter test --no-pub test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart --reporter expanded`

Expected: FAIL because `_detailSourceForWindow` never requests the nearest
full-year neighbour beyond one padding bucket.

- [ ] **Step 3: Add the minimal paint-context source selection**

```dart
final visible = frame.detailPointsForYear(...visible window...);
final paintContext = frame.nearestDetailNeighboursForYear(
  year: year,
  beforeEpochMinute: window.startEpochMinute,
  afterEpochMinute: window.endEpochMinute,
);
return mergeTimeOrdered(visible, paintContext);
```

The implementation must return actual current-frame points, keep them outside
the inspection list, and let the painter clip their segment at plot bounds.

- [ ] **Step 4: Run the focused domain/widget tests green**

Run:
`flutter test --no-pub test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart --reporter expanded`

Expected: PASS, including no fake boundary data and existing nearest-point
inspection coverage.

- [ ] **Step 5: Commit sparse-Sum repair and journal separately**

Commit application changes, append factual RED/GREEN evidence to the journal,
then commit only that journal file with `[skip ci]`.

### Task 2: Establish cold/warm Mind-entry timing before any liveness repair

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: relevant Core/Mind host tests discovered by source audit

**Consumes:** existing `FluviDiagnosticLogger`, `mindTemporalHeatmap`, prepared
base admission, existing Core mode/Mind body composition.

**Produces:** Correlated, bounded `MIND_COLD_ENTRY` timing stages from mode
acceptance through first actual body layout and paint.

- [ ] **Step 1: Write failing production-parent cold/warm timing test**

```dart
testWidgets('MIND-COLD-01 records request, base, projection, publish, layout and paint for cold then warm entry', (tester) async {
  final harness = await mountBudgetThenMindHarness(tester);
  await harness.enterMind();
  expect(mindColdEntryStages(), containsAll(<String>['REQUEST', 'BASE_READY', 'FRAME_PUBLISHED', 'FIRST_LAYOUT', 'FIRST_PAINT']));
  await harness.leaveAndReenterMind();
  expect(mindWarmEntryStages(), containsAll(<String>['REQUEST', 'FRAME_PUBLISHED', 'FIRST_PAINT']));
});
```

- [ ] **Step 2: Run it red**

Run the focused Core/host test. Expected: FAIL because no full correlated
cold/warm stage trace exists.

- [ ] **Step 3: Add diagnostics only**

```dart
_logMindColdEntry('REQUEST', flowId: flowId);
_logMindColdEntry('BASE_READY', flowId: flowId, elapsedMicros: elapsed);
_logMindColdEntry('PROJECTION_REUSED_OR_BUILT', flowId: flowId, elapsedMicros: elapsed);
_logMindColdEntry('FRAME_PUBLISHED', flowId: flowId, elapsedMicros: elapsed);
```

The Mind surface reports first layout and post-frame first paint for that
identity. Cap retained events by flow/stage; do not log rows or transaction
content.

- [ ] **Step 4: Run tests green and capture a real cold/warm diagnostic APK**

Do not implement a warmup until the timing trace identifies the slow owner.
Record the measured owner or mark the repair blocked by user-only capture.

### Task 3: Adaptive detailed Sum labels

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

**Produces:** One axis policy that derives full Hungarian names only when
visible span and available slot width admit non-overlapping labels.

- [ ] **Step 1: Write overview and zoomed label tests**
- [ ] **Step 2: Verify red**
- [ ] **Step 3: Add a pure month-axis label resolver and use it in the widget**
- [ ] **Step 4: Verify green and commit/journal separately**

### Task 4: Additive Month comparison rhythm and shared larger stat cards

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_secondary_cards.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Create/update a focused golden if project harness supports this card.

**Produces:** A third Month page retaining the existing daily rhythm; a
comparison painter with only nonzero rounded bars and resolver-derived colour;
one enlarged `_MindTemporalStats` geometry shared by Month and Day.

- [ ] **Step 1: Write red page, zero-bar, palette/range and shared-bounds tests**
- [ ] **Step 2: Verify red**
- [ ] **Step 3: Implement `MindMonthComparisonRhythmCard` and use the existing
  palette resolver; extract only neutral bar geometry if Budget and Mind share
  a real layout invariant**
- [ ] **Step 4: Scale `_MindTemporalStats` once and verify both cards**
- [ ] **Step 5: Inspect/generate the representative visual evidence; commit and journal**

### Task 5: Day partner/amount labels from immutable prepared data

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_secondary_cards.dart`
- Modify: matching domain/presentation tests

**Produces:** `MindDayTimelineEvent.partnerLabel` sourced at prepared
projection admission and a primary painter label formatted as
`partner · amount`; local time remains in the axis/secondary context.

- [ ] **Step 1: Write a red projection test with same-day partner names**
- [ ] **Step 2: Verify red**
- [ ] **Step 3: Add bounded immutable prepared label transport and map it into
  current/full timeline events**
- [ ] **Step 4: Change painter label and verify green; commit and journal**

### Task 6: Year-bar palette proof and full regression delivery

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart` only if test coverage needs present controls

- [ ] **Step 1: Add the missing Year partial-bar active-palette regression**
- [ ] **Step 2: Run all focused tests, formatter, analyzer, fast and boundary suites**
- [ ] **Step 3: Re-read checklist; commit only remaining tested source changes
  and journal each application commit separately**
- [ ] **Step 4: Push exact final app SHA; monitor lanes, download normal human
  APK to `/storage/emulated/0/Download/fluvi`, hash it, regenerate exact-source
  SCIP on tooling branch, append final journal evidence**

## Spec coverage review

- Sparse SUM root-cause contract: Task 1.
- Cold Mind trace before repair: Task 2; a repair is intentionally gated on
  measured first owner rather than guessed.
- Full month labels: Task 3.
- Header parity, curve settings, Year 2×6 and MonthCard styling are preserved
  existing delivered contracts and remain regression rows in the checklist.
- Month comparison/bigger Month+Day cards: Task 4.
- Day partner+amount labelling: Task 5.
- Year palette-reactive bar verification: Task 6.

`PHYSICAL VALIDATION — PENDING, USER ONLY`
