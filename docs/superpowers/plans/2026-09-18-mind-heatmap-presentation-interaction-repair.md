# Mind heatmap presentation and interaction repair implementation plan

> **For agentic workers:** Execute the checked tasks inline, with a fresh RED →
> GREEN cycle for every production behavior. The audited user prompt dated
> 2026-09-18 is the approved design authority.

**Goal:** Repair the invisible Sum cells and extend the existing Mind
presentation layer with optional legend, direct annual cells, the exact
B3M-MYM Month geometry, fixed palette presets, and boundary-only card swipe
handoff—without changing financial, Query, projection or physical-motion
ownership.

**Architecture:** `MindYearHeatmapPresentationController` remains the sole
write path for heatmap presentation settings. `MindYearHeatmapPaletteResolver`
remains the only colour/contrast resolver for Year, Month, Sum and legend.
Temporal scrolling retains its own `Scrollable`; only a boundary overscroll is
offered to the existing `DashboardUpperVerticalGestureCoordinator`, which is
the sole route to `DashboardExpansionController`.

**Tech stack:** Flutter/Dart widget tests, immutable Mind frames, existing
`ValueNotifier` presentation controller, current Core dashboard composition.

## Global constraints

- Work only on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.
- Reference: `origin/spendeetest:balance_latest_layout.html`,
  `createMindMonthlyActivityPrototypeScreen`; it is layout-only authority.
- Preserve Query/amount semantics, Time/Avatar controllers and physics,
  LogBox/Room/Kotlin, score/chart, Budget, the Header ticker, and one range
  owner.
- Never add timer/debounce/remount/second controller/second resolver.
- Every presentation toggle is local: no repository/index/query/projection
  mutation. Test that boundary directly.
- Do not build locally. The final app SHA must be CI-built before the final
  journal-only commit and matching SCIP is mandatory.

## Architecture card

| Concern | Owner / only write path | Reuse decision | Evidence |
| --- | --- | --- | --- |
| Heatmap settings | `MindYearHeatmapPresentationController` setters | Extend the one immutable settings frame | settings + tuner tests |
| Palette and contrast | `MindYearHeatmapPaletteResolver` | Add ordered fixed stops there; no renderer colours | resolver + all-plane identity tests |
| Sum paint geometry | `MindSumHeatmapViewport` | Give the existing tile a bounded height | render-box RED → GREEN |
| Annual shell style | Year viewport + existing month painter | Select local shell composition over the same frame | same-frame widget test |
| Vertical expansion | `DashboardUpperVerticalGestureCoordinator` | Reuse Budget boundary handoff; no new recognizer owner | production-parent scroll/boundary tests |
| Range input | existing `_MindTemporalBody` / range binding | Keep fixed sibling outside notification/drag lane | RangeSlider isolation test |

## Task 1: Create forensic RED coverage

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

- [x] Add `SUM-PAINT-01`, mounting a non-empty Sum month and asserting its
  keyed `RenderBox` has positive width/height and is within the viewport.
- [x] Run only `SUM-PAINT-01`; it failed against `434276ac` because the
  `DecoratedBox` has zero height.
- [x] Add `LEGEND-GEOM-01/02`: a real controller toggle removes the legend
  widget and returns exactly its lane to temporal content while footer bounds
  stay invariant.
- [x] Add `YEAR-SURFACE-01`, `MONTH-B3M-01`, palette stop/one-authority and
  tuner no-op-revision REDs.
- [x] Add mounted `GESTURE-01..03`, `RANGE-ISOLATION-01` and Header regression
  cases. The scroll interior must not expand; only unconsumed boundary delta
  may expand; slider must never expand.

## Task 2: Repair Sum bounds

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`

- [x] Give each existing Sum month tile a full finite row height through its
  existing `Expanded` composition (no fake data/tile).
- [x] Re-run `SUM-PAINT-01` and Sum viewport suite; record concrete bounds.
- [x] Commit the isolated test/fix after neighboring tests pass (combined
  presentation repair commit after the build gate).

## Task 3: Extend presentation settings and tuner

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Test: settings and tuner suites above

- [x] Add typed `showHeatmapLegend` (default true) and typed annual shell
  style (MonthCard/direct-on-surface), include equality/hash/copy/revision
  semantics and idempotent setters.
- [x] Expose both controls with stable keys in the existing Mind heatmap
  section.
- [x] Prove no-op setters retain revision and presentation changes do not
  mutate the supplied financial frame/query/range.

## Task 4: Centralize palette presets and legend samples

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart`
- Test: `mind_year_heatmap_palette_resolver_test.dart`

- [x] Add the eight ordered authored presets exactly once each, retaining
  Fluvi and B3M byte-for-byte behavior.
- [x] Resolve new palettes by adjacent-stop interpolation with exact authored
  endpoints/stops and one deterministic contrast rule.
- [x] Keep legend at five samples (0/.25/.5/.75/1), generated only by the
  resolver, regardless of authored stop count.
- [x] Prove Year/Month/Sum/legend use the same style without frame identity
  replacement or projection work.

## Task 5: Implement optional legend and direct annual surface

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Test: viewport/host suites

- [x] Structure the legend conditionally: OFF has no widget and no 28px lane;
  temporal `Expanded` receives that space, while range stays in the existing
  keyed 74px footer.
- [x] Render the direct annual option from the exact existing Year frame and
  month painter/layout. It removes only the muted shell, retaining titles,
  calendar mapping, palette, optional totals and 2×6/3×4/4×3 choices.
- [x] Prove 4×3 reclaims the lane, remains non-scrolling and keeps slider
  coordinates/controller identity unchanged.

## Task 6: Match B3M-MYM Month geometry

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Test: `mind_temporal_heatmap_viewports_test.dart`

- [x] Derive `gridWidth = min(availableWidth, 282)` under existing content
  insets; center it.
- [x] Use seven equal columns, 4px gaps, square cells, 3px label insets, 6px
  radius, top-left 7px/900 labels. Keep real dates/frame/total untouched.
- [x] Verify at 282px+ and narrow constraints; add no fixture data.

## Task 7: Prove and implement gesture arbitration

**Files:**
- Modify only if RED proves it: `mind_dashboard_core_surface.dart`,
  `dashboard_core_mode_host.dart`, or coordinator API after all callers are
  graph/source audited.
- Test: host and coordinator suites

- [x] Compare the Budget `NotificationListener<ScrollNotification>` handoff
  with Mind's temporal scroll tree.
- [x] Implement boundary-only overscroll forwarding to the existing
  coordinator, excluding the range sibling entirely.
- [x] Prove interior scroll retains child ownership, both zero-extent and
  boundary drags expand once with correct sign, header still works, and slider
  has zero expansion events.

## Task 8: Boundary, regression and delivery verification

- [x] Run formatter, focused settings/resolver/viewport/host/tuner/coordinator
  suites, relevant broader dashboard suite, analyzer and `test-fluvi-fast.sh`.
- [x] Re-read this plan and the acceptance checklist; every functional row is
  `DONE` and the build gate is open before the final application push/build.
  before the final application push/build.
- [x] Commit and push the exact application tip, obtain and verify the normal
  human APK, regenerate/push matching SCIP, then append journal-only evidence.
  evidence after each substantive commit.
- [ ] Push the final application SHA as branch tip, monitor CI/human APK,
  verify local APK SHA/marker, regenerate final matching SCIP, then make/push
  final journal-only documentation commit.
