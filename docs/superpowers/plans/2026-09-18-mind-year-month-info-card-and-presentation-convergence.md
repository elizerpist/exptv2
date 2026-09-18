# Mind Year MonthCard information and presentation convergence implementation plan

> **For agentic workers:** Execute inline with a separate RED → GREEN cycle per task. This repository has a coupled Core/frame/viewport surface, so inline execution is deliberately chosen over parallel agents to prevent competing edits to the same immutable frame contract.

**Goal:** Add local tappable Year-month financial inspection and complete the
remaining Mind palette, Month, 4×3 and compact-footer requirements without
altering financial Query, navigation or interaction ownership.

**Architecture:** `DashboardCoreController` remains the single prepared-data
publication owner. A Year frame continues to carry the query-independent
monthly bank and gains, only if the RED proves it necessary, a separate
immutable twelve-month effective-scope summary computed during semantic frame
admission. `MindYearHeatmapViewport` owns the transient `(year, month)`
inspection state and its one bounded animation. The palette settings controller
and central resolver remain presentation-only.

**Tech stack:** Flutter/Dart, `flutter_test`, immutable Mind projections,
existing `ValueNotifier` presentation settings, Ubuntu/proot Flutter tooling.

## Global constraints

- Work only on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` and
  preserve user untracked files.
- Source base is application SHA `43b5fc1090cfd35562df84d8d65838a297c0b689`;
  commits above it are audited documentation only.
- Reference `origin/spendeetest:balance_latest_layout.html` is layout-only;
  never copy its fake activity or money values.
- No second Query/focus/palette/expansion controller; no timer, debounce,
  remount, repository read or index build for inspection actions.
- Keep Time/Avatar physics/controller/position identity, LogBox ownership,
  amount snapping/commit, Budget, score/chart and `MILESTONE_COMMITS.md`
  unchanged.
- Run Flutter checks in Ubuntu/proot; no local APK builds. Build gate remains
  closed until the checklist is complete.

## Architecture card

| Concern | Sole owner / write path | Reuse decision | Boundary evidence |
| --- | --- | --- | --- |
| Inspected month | `MindYearHeatmapViewportState` | one nullable `(frame.year, month)` identity | state/tap/stale-year widget tests |
| Full financial metrics | `MindYearHeatmapMonthlyAggregates` | render existing full-ledger bank; do not filter it | direction/focus/range regression tests |
| Optional scope amount | Core Year-frame admission | bounded 12-slot immutable read model from `DashboardFocusMembershipSeed.select` | Core no-I/O and intersection tests |
| Scope metadata/tint | existing focus/query facets + `CategoryVisualResolver` | mirror `DashboardQueryFacetChips` precedence | facet/render tests |
| Month-card morph | Year viewport local transition | one implicit or viewport-local animation, never one controller/card | intermediate-frame/ticker test |
| Palette / legend | `MindYearHeatmapPresentationController` + resolver | replace stale enum cases; one resolver samples 10 anchors | resolver/tuner/frame-identity tests |
| Responsive Year/Month | existing `LayoutBuilder` and calendar geometry | solve from actual constraints and true row count | constrained Rect/overflow tests |

## Task 1: Establish the inspection data boundary

**Files:**
- Modify: `test/features/dashboard/mind/domain/mind_year_heatmap_projection_test.dart`
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_projection.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`

**Produces:** a frame-owned immutable twelve-month scope summary whose values
are selected at Core semantic admission, not at a card tap.

- [ ] Write `YEAR-INFO-05/06/07/08/09/11/12/18` RED cases. The fixtures must
  prove a whole-month bank differs from category/partner/intersection totals,
  remains direction/range independent, and needs no repository/index/Query/Time
  work after admission.
- [ ] Run the new named cases at `43b5fc10`; expected result: RED because a
  separate scoped month model does not exist.
- [ ] Add a typed immutable `MindYearHeatmapScopedMonthlyAggregate` (or a
  source-equivalent type) with exactly 12 totals and visible facet metadata.
  Compute it once from Core’s selected resident membership immediately before
  Year-frame publication. Do not change `MindYearHeatmapMonthlyAggregates`.
- [ ] Publish the scoped model through `MindYearHeatmapFrame`; use the existing
  full bank for net/income/expense. Preserve all existing constructor callers
  through explicit empty/no-scope defaults.
- [ ] Re-run domain/Core focused cases; expected result: GREEN.
- [ ] Commit the data/test change with a body recording the current source,
  RED result, no-I/O boundary, and unchanged financial owners; add its separate
  journal-only commit before subsequent application work.

## Task 2: Add Year-local MonthCard inspection and morph

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`

**Consumes:** `MindYearHeatmapFrame.monthlyAggregates` and Task 1 scoped model.
**Produces:** semantic tappable MonthCards with an at-most-one inspection state.

- [ ] Write `YEAR-INFO-01..04`, `YEAR-INFO-10`, `YEAR-INFO-13..17` RED
  tests against actual viewport composition: tap/toggle/transfer, no Time or
  Query navigation, intermediate morph, stable outer Rect/scroll extent,
  stale-year clearing, drag-vs-tap, both surface styles and mobile bounds.
- [ ] Run the named cases before production edits; expected failure: no
  inspection semantic/content exists.
- [ ] Add only one viewport-local selected identity. Pass a callback/state
  projection to `MindYearHeatmapMonthCard`; use `Semantics(button: true)` and
  an implicit/one-owner transition that replaces its inner content while the
  outer fixed `SizedBox` is unchanged.
- [ ] Render base values as the existing net/income/expense, using existing
  formatters and financial colours. Render optional scope metadata from Task 1
  with `CategoryVisualResolver.resolve(...).gradient.middleColor`; expose
  complete semantics even when bounded visual text ellipsizes.
- [ ] Invalidate selection synchronously when accepted frame year changes;
  retain it through same-year presentation/range/direction changes.
- [ ] Re-run inspection widget and production-host tests; expected GREEN.
- [ ] Commit the presentation/test change and append a separate journal-only
  evidence commit.

## Task 3: Replace the palette product contract

**Files:**
- Modify: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`

- [ ] Write `PALETTE-01..04` RED assertions: exact seven enum choices and
  labels, ten exact anchors for every style, ten legend swatches in one
  bounded lane, and financial-frame identity after setting changes.
- [ ] Run them; expected failure: stale ten-choice enum and five-sample legend.
- [ ] Replace enum cases with precisely Fluvi, B3M-MY3, Meadow Green, Soft
  Rainbow, Peachy Delight, Fluvi stretched and B3M-MY3 stretched. Store all
  exact authored colours in the one resolver, interpolating adjacent anchors.
- [ ] Make `legendSamples` return ten resolver-generated anchor samples; keep
  empty state outside the scale and remove no-longer-product tuner controls.
- [ ] Re-run resolver/settings/tuner suite; expected GREEN. Commit and journal.

## Task 4: Correct real Month rows and compact caption

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Modify: `test/features/dashboard/query/presentation/query_amount_range_control_test.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Modify: `lib/features/dashboard/query/presentation/query_amount_range_control.dart`

- [ ] Write `MONTH-B3M-REAL-ROW-01`, `MONTH-B3M-HEAD-02`, and
  `COMPACT-RANGE-01` RED tests. Use July 2026 and one real six-row month;
  record exact grid/header rects and standard/compact caption distinction.
- [ ] Run the cases; expected failure: six-row cap/four sequential headers and
  compact standalone `Összeg`.
- [ ] Solve Month cell extent using `geometry.rowCount`, preserve the 282px
  max/7 columns/4px gaps/square cells, and render title/count plus month/active
  count as two `Row(mainAxisAlignment: spaceBetween)` header groups. Do not
  alter data or day slot geometry.
- [ ] Remove only the compact caption and its gap; leave standard Query control
  and all slider semantics unchanged.
- [ ] Run focused Month/range cases; expected GREEN. Commit and journal.

## Task 5: Re-solve legend-free 4×3 geometry

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Modify only if direct source proof requires it: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`

- [ ] Write `YEAR-4X3-LEGEND-OFF-01` RED, comparing actual content/card/cell
  rects with legend on/off and asserting zero scroll, invariant footer bounds,
  and a recorded width-versus-height limiting term.
- [ ] Run it; expected failure if static extra height / stale fit sizing does
  not consume the actual legend-free temporal envelope.
- [ ] Remove only the stale presentation sizing assumption proven by the RED;
  pass real temporal constraints into the existing four-column fit solver.
  Never make square cells exceed the width limit or add a nested scroll.
- [ ] Re-run 4×3 and neighboring layout tests; expected GREEN. Commit and
  journal.

## Task 6: Full regression, delivery and graph

- [ ] Re-read this plan, the checklist and the HTML reference. Mark each
  requirement only after its evidence succeeds; keep BUILD GATE closed for any
  non-DONE functional row.
- [ ] Run formatter and all required Ubuntu/proot focused suites, Core/focus
  cases, analyzer, fast suite, boundary script and `git diff --check`.
- [ ] Inspect final diff to prove no prohibited owner changed; record any
  inherited profile failure exactly against the baseline.
- [ ] When all functional checklist rows are DONE, commit any remaining
  application changes with the exact validation results. Push that application
  SHA as branch tip (not a journal tip), monitor CI, download normal human APK
  to `/storage/emulated/0/Download/fluvi`, verify SHA-256 and embedded SHA.
- [ ] Regenerate SCIP from that exact application SHA in an isolated temporary
  source worktree, test and push the tooling branch, then create/push one
  journal-only `[skip ci]` commit. End at `PHYSICAL VALIDATION — PENDING, USER ONLY`.

## Plan self-review

Every user requirement maps to a checklist ID: INFO/FIN for the MonthCard
feature, PAL for the seven ten-stop migration, LAY/MONTH/RANGE for pending UI
corrections, ARC/VAL/DEL for authority, no-I/O and delivery constraints. No
financial data is derived in a widget, and no reference fixture is a data
source. The only intentionally unresolved visual decision is the exact local
morph curve/duration; the implementation must audit existing motion tokens and
capture an intermediate-frame test before choosing the bounded local value.
