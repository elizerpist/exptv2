# Mind fit-to-viewport heatmap, chart labels, and range-domain repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` for
> inline task-by-task execution. Steps use checkbox (`- [ ]`) syntax for
> tracking.

**Goal:** Repair the visible-scope Mind amount maximum, classify the Sum
observation from real paging provenance, and add a fitting 4×3 annual heatmap
plus optional five-label chart-time overlay without changing Mind financial
semantics.

**Architecture:** `DashboardCoreController` remains the sole owner of
prepared scoped amount-domain publication and visible-frame coordination.
`MindYearHeatmapPresentationController` gains only the third layout choice;
the viewport chooses a non-scrolling constraint-derived 4×3 renderer over the
existing immutable frame. A small chart-presentation controller owns only
label visibility, while `MindHeaderScoreChart` projects its five dates from
the already published chart series.

**Tech Stack:** Flutter/Dart, existing ChangeNotifier/ValueNotifier state,
immutable Mind projections, `flutter_test`, current SCIP codegraph.

## Global Constraints

- Work directly on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.
- Do not push, dispatch CI, or build an APK while the checklist gate is closed.
- No fallback to an unrelated canonical/all-time amount domain for a visible
  Mind scope.
- No Sum list implementation change unless a mounted/paged forensic RED
  proves real count/query/payload divergence.
- Preserve Query ownership, Time/Avatar controller/physics identity, LogBox
  renderer ownership, slider snapping, score mathematics, accepted chart plot,
  one shared Header ticker, Fastfood fixture, and Budget state.
- Run Flutter tooling only inside Ubuntu proot; online GitHub produces APKs.

## File map

- `lib/features/dashboard/application/dashboard_core_controller.dart` — scoped
  amount-domain admission/binding, new chart-presentation owner, disposal and
  UI wiring source.
- `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
  — layout enum/controller extension.
- `lib/features/dashboard/mind/domain/mind_header_score_chart_presentation.dart`
  (new) — immutable hidden/visible label setting and controller.
- `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
  — pure 4×3 fit solver plus non-scroll renderer that consumes the existing
  frame.
- `lib/features/dashboard/mind/presentation/mind_header_score_chart.dart` —
  five-label temporal projection and clipped semantic overlay only.
- `lib/features/dashboard/presentation/core_dashboard.dart`,
  `core_modes/dashboard_core_mode_host.dart`,
  `core_modes/mind_dashboard_core_surface.dart`, and
  `core_modes/dashboard_header_visual_tuner.dart` — pass presentation
  listenables and render existing-tuner controls.
- Existing Core/range/viewport/tuner/chart tests — extend alongside each
  production change; add a focused presentation-domain test as needed.

### Task 1: Record forensic REDs before production mutation

**Files:**
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify or create: focused current-query/range and LogBox paging test files
- Modify: checklist above

- [ ] Add a mounted Mind/Expense/Year-2027 test that derives its maximum from
  the actual Fastfood fixture, makes a preview/commit, transitions away and
  back, repeats quickly and injects a delayed old-domain publication.
- [ ] Assert one identity tuple at each visible target: Summary scope,
  visible-frame scope, `QueryAmountRange.domainScope`, binding maximum and
  rendered `Max.` label.
- [ ] Run only the new case against the unmodified parent and retain the
  expected failing assertion that shows the broad fallback.
- [ ] Add a deterministic Year-2027 → Sum paging test that consumes all 100
  Fastfood rows, checks the committed viewport query key/count/summary, then
  proves older dates occur or captures the first payload identity mismatch.
- [ ] Run it without source changes and classify it `NO DEFECT` if older rows
  appear normally; otherwise preserve the RED and trace its first owner.

### Task 2: Repair only the proved amount-domain owner

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: focused Core/range test(s)

- [ ] With the RED failure recorded, make `mindAmountRangeBindingFor` fail
  closed for a missing exact visible domain rather than substitute the broader
  canonical domain.
- [ ] Ensure the exact scope is published from the existing admitted prepared
  Mind base at the same visible-frame boundary and that stale scope/generation
  publications cannot overwrite it.
- [ ] Run the mounted RED to GREEN, then the direct range/core suite.
- [ ] Update RNG-01 through RNG-03 only with command-backed evidence.

### Task 3: Implement 4×3 fit-to-viewport presentation TDD cycle

**Files:**
- Modify: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`

- [ ] Add failing enum/tuner tests for `fourColumns` / `4 × 3`.
- [ ] Add a pure geometry test with actual reference constraints, all 12
  months and each footer combination; require shared square cells and total
  height no greater than available annual region.
- [ ] Add a constrained widget test requiring `maxScrollExtent == 0`, no
  nested Scrollable, all cards in bounds, and preservation of the external
  scroll-controller instance through 3×4 → 4×3 → 2×6.
- [ ] Implement the width/height solver once: derive the 4×3 card width from
  constraints, calculate chrome/footer subtraction, then choose the minimum
  of width-limited and height-limited square cell extents for all three rows.
- [ ] Render 4×3 as a fixed non-scrolling annual `Column`/rows over the same
  frame; keep existing ListView for 2×6/3×4.
- [ ] Run viewport/tuner/presentation tests and update H43 rows only after
  green evidence.

### Task 4: Implement chart label presentation TDD cycle

**Files:**
- Create: `lib/features/dashboard/mind/domain/mind_header_score_chart_presentation.dart`
- Create or modify: matching presentation-domain test
- Modify: chart, surface, host, core dashboard/controller and tuner files in
  the file map
- Modify: chart/tuner/boundary tests

- [ ] Add failing controller tests for hidden default, idempotent mutation and
  no financial/query dependency.
- [ ] Add failing pure chart projection tests for exact epoch days
  `start + round((end-start) * f)` at five fractions.
- [ ] Add failing widget tests for hidden/no labels, visible/exactly five,
  collapse clipping, fixed plot geometry, no ticker, and actual scope changes.
- [ ] Implement one presentation-only controller owned by Core and pass it to
  the already semantic `_MindHeaderScoreDetail` layer.
- [ ] Render five `IgnorePointer` labels below the unchanged plot using the
  actual series epoch domain and existing Hungarian month/date formatter; do
  not alter painter geometry, line, fade or endpoint.
- [ ] Run chart/tuner/boundary tests and update CLB rows only after green
  evidence.

### Task 5: Integrate, audit, and open the gate only with evidence

**Files:**
- Modify: new checklist
- Modify: `docs/FLUVI_ENGINEERING_JOURNAL.md` only after application commits

- [ ] Run representative cross combinations: label toggle + scope change,
  layout switch + Year/Sum, preview + year switch, and score setting + year
  switch.
- [ ] Run protected score/chart/range/heatmap and relevant Core/LogBox suites;
  inspect source counters for no pointer I/O and labels with no ticker.
- [ ] Run targeted Ubuntu-proot analyzer and `git diff --check`.
- [ ] Re-read checklist/reference, record only actual `DONE` statuses, and
  print the gate table. If any is not `DONE`, stop before build/push.

### Task 6: Delivery only after the gate opens

**Files:**
- Modify: `docs/FLUVI_ENGINEERING_JOURNAL.md` in a separate `[skip ci]` commit
- Tooling worktree: matching SCIP artifacts only

- [ ] Commit logically atomic amount-domain, 4×3, and chart-label production
  changes with test evidence in bodies; include no Sum runtime commit if its
  forensic result is no defect.
- [ ] Push the application branch only after Task 5 is green, then monitor the
  exact online human diagnostic job and download its APK to
  `/storage/emulated/0/Download/fluvi` with SHA-256/source marker evidence.
- [ ] Generate SCIP in a clean detached source checkout at the final app SHA,
  verify `manifest.source_head`, test/commit/push it only on
  `tooling/scip-codegraph-v1`, then add factual journal evidence separately.

## Plan self-review

- Every current user requirement maps to a checklist ID; Sum has a forensic
  classification gate rather than a speculative repair.
- The plan adds no score financial formula, Query state, ticker, list renderer
  or scrolling owner.
- The fit solver uses runtime constraints rather than a device-specific magic
  height; labels use immutable chart series dates rather than screen position.
- Build delivery remains impossible until the checklist changes truthfully to
  all functional rows `DONE`.
