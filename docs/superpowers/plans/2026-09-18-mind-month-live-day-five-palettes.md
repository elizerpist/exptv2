# Mind Month live publication, Day activity, and five palettes implementation plan

> **For agentic workers:** Execute inline with RED → GREEN checkpoints. The Core temporal frame, score publication and Mind body are coupled, so parallel edits would duplicate or race the single semantic owner.

**Goal:** Make accepted Mind Month targets publish body and Header atomically like Year, add a bounded DayScope 24-hour activity surface, and retain exactly five ten-stop palettes.

**Architecture:** `DashboardCoreController` remains the only semantic admission and prepared-membership owner. A Month accepted target uses the existing renderer-acknowledged admission principle with an exact target identity and a year-narrowed resident contribution stream; the existing behavioral score publication is part of that transaction. Day is a typed immutable temporal frame derived from the same prepared contribution transport after it carries `bookedLocalTimeMinutes`; UI renders frames and forwards no financial work. `MindBehavioralScoreProjection` remains the sole score authority.

**Tech stack:** Flutter/Dart, immutable prepared projections, `flutter_test`, existing `ValueNotifier` publication, Ubuntu/proot Flutter tooling.

## Global constraints

- Work on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`; preserve all untracked user files.
- Runtime base: `33facc5`; docs-only head: `894159f` at preflight. Fresh Drive logs are absent; revisions 5/51 are historical only.
- No `TimePlane.day`, second Query/focus/score/frame notifier, timer/debounce, repository/index acquisition on accepted Month/Day targets, or raw source scan on range preview.
- Preserve Time/Avatar controller/ScrollPosition/physics, range snapping/commit, LogBox, Room/Kotlin/schema, Budget, Year inspection and Header plot/ticker.
- The final palette contract is five ten-stop choices; supersede the prior seven-palette checklist only for this product decision.
- Do not build locally. Build gate remains closed until the new checklist is fully functional-green.

## Architecture card

| Concern | Single owner/write path | Reuse decision | Evidence |
| --- | --- | --- | --- |
| Month accepted target | Core temporal visual admission | generalize Year’s accepted-target transaction, not a second Month pipeline | mounted atomicity/positive-control tests |
| Month source narrowing | prepared Year membership | reuse `contributionsForYear` before Month projection filtering | contribution-touch counters |
| Day local time | common prepared contribution | carry ledger’s existing local minutes through the one resident transport | 0/59/60/1439 projection tests |
| Day range preview | typed Day projection | reuse `MindHeatmapAmountRangeBucket`; 24 fixed buckets | preview-work tests |
| Day body | existing Mind temporal body switch | dispatch on effective `DayScope`, not a new TimePlane | host/body exclusivity tests |
| Day score/chart | existing behavioral score projection | separate visual chart domain from canonical target point only if required | point parity/31-day tests |
| Palette product state | presentation controller + central resolver | remove cases; do not fork palette maps by surface | resolver/tuner identity tests |

### Task 1: Establish Month accepted-target evidence

**Files:**
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify: direct CoreDashboard/host test discovered from current source
- Inspect/possibly modify: `lib/features/dashboard/application/dashboard_core_controller.dart`

1. Write `MONTH-LIVE-01…07` RED tests through the real segmented renderer acknowledgement for an in-plane Month change and a parent-Year change; assert actual body/header/chart/colour target on the first eligible frame, rapid latest-wins and no settle visual delta.
2. Run the named cases at `33facc5`; record whether each fails at missing accepted-target admission, broader work, or another boundary.
3. Add bounded counters to the existing owner only if existing counters cannot identify Month contributions touched/repository/index/scene work.
4. Compare the working Year admission with Month line by line; document one hypothesis before production change.

### Task 2: Repair Month admission and narrow prepared work

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify only if required: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Test: Task 1 Core tests and `test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart`

1. Implement the smallest Core-owned accepted Month target transaction: exact candidate YearMonth → resident body projection + matching behavioral score publication under one generation, fail-closed if either is obsolete.
2. Feed Month construction with `contributionsForYear(year: target.year, membership: selected.entryIndices)` before applying selected month. Do not construct a repository cache.
3. Re-run the same Month REDs and Year positive control. Assert source I/O/index/query/scene counters are zero and unrelated years are untouched.
4. Commit the focused application change and append a separate journal-only evidence commit before the next substantive application work.

### Task 3: Reduce palette product choices

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart`
- Modify: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

1. Add `PAL-REDUCE-01…03` tests expecting exactly the five names, ten anchors and ten swatches; run RED against seven choices.
2. Remove Soft Rainbow and Peachy Delight from enum labels, resolver cases/definitions, tests and tuner controls; retain all exact anchors for the five survivors.
3. Run settings/resolver/tuner and all-plane frame-identity regressions; commit and journal separately.

### Task 4: Carry local time and create a bounded Day frame

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

1. Add `DAY-DATA-01…05` RED tests for exact local-hour mapping, selected-date isolation, membership refinements and bounded range preview.
2. Extend the common prepared contribution construction with canonical `bookedLocalTimeMinutes`, preserving existing ordinal/day/amount consumers.
3. Introduce `MindDayHeatmapProjection`/frame beside the existing typed Sum/Month frames. It owns exactly 24 sorted amount buckets and derives range previews without retaining raw ledger entries.
4. Core installs the Day frame only through existing temporal publication when effective scope is `DayScope`; all filtering is inherited from the admitted selected membership.
5. Run domain/Core REDs GREEN, then commit and journal separately.

### Task 5: Render Day as the Month-plane child body

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify only if direct dispatch ownership requires it: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Test: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`

1. Write `DAY-UI-01…05` and `DAY-HOST-01` RED tests. Require one Day body only when the Month child is an actual `DayScope`; keys, positive bounds, four rows/six columns and row/footer geometry must be mounted facts.
2. Render one `MindDayHeatmapViewport` from the immutable frame, using the central resolver and noninteractive hour cells. Keep the common legend/range footer outside the content.
3. Re-run Day UI/host and existing Month/Sum/Year presentation regressions; commit and journal separately.

### Task 6: Make Day score/chart target semantics explicit

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify only if proved necessary: `lib/features/dashboard/mind/domain/mind_behavioral_score_projection.dart`
- Test: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Test: `test/features/dashboard/mind/domain/mind_behavioral_score_projection_test.dart`
- Test: direct Header chart/colour tests discovered by source audit

1. Write `DAY-LIVE-01…06` REDs: before-settle target atomicity, daily point parity, D−30…D chart domain/end point, no hourly coupling, rapid latest wins and empty Day.
2. Preserve the canonical selected-day point. If the existing series request conflates target evaluation and visual window, add the smallest explicit chart-display boundary rather than changing score mathematics.
3. Run MBS-01 and all Day/Month/Year score regressions GREEN; commit the application change.

### Task 7: Gate, delivery, and final graph

1. Re-read this plan, the checklist, journal and milestone. Mark rows only with recorded evidence.
2. Run formatter, all required Ubuntu/proot focused suites, direct Core cases, analyzer, fast suite, boundary verification and `git diff --check`.
3. Audit scope/protected files and record profile failure separately.
4. When every functional checklist row is DONE, push the final application SHA as the branch tip, monitor CI, download the normal `lib/main.dart` human APK, verify hash and embedded SHA.
5. Regenerate/test/push SCIP from the exact application SHA, then append and push the final one-file journal commit. End at user-only physical validation.

## Plan self-review

The plan maps every requested behavior to a checklist row. It extends the existing Core temporal lane, prepared contribution transport, score authority and palette resolver instead of creating siblings. The only root-cause claim deferred to RED evidence is how much of Month’s physical lag is admission versus broad prepared traversal; both source-proven asymmetries receive independent tests.
