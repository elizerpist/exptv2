# Daily Budget and Summary parity implementation plan

> **For agentic workers:** Execute this plan inline: the Budget controller,
> Core temporal ownership, and visible-frame route share state. Parallel edits
> would create unnecessary integration risk.

**Goal:** Add a pure month-end Daily Budget forecast while restoring prepared
segmented temporal publication, immediate Dynamic Trio idle collapse, compact
segmented tracks, and a composited BottomNav top contour.

**Architecture:** Persisted financial limits remain SUM/YEAR/MONTH. Core owns
one injectable logical as-of date. `DashboardBudgetMonthEndProjection` is a
pure input to the existing Budget presentation controller and separates a
forecast display numerator from the canonical monthly actual used by editing
and partition rules. The existing visible-frame store receives generalized
prepared temporal frames; coverage work stays secondary. Existing BottomNav
path geometry is reused in one foreground, non-interactive contour overlay.

**Tech stack:** Flutter/Dart, package:test/widget tests, current prepared
Budget snapshot and visible-frame/cache layers. Run all Flutter commands in
Ubuntu/proot; normal Android APK delivery runs through GitHub Actions only.

## Non-negotiable boundaries

- Preserve the exact monthly `FinancialLimitKey` for matching DAY/MONTH;
  never add Day persistence, repository calls, migrations, or a daily limit.
- Do not route a forecast into `DashboardBudgetLimitEditContext.actualScaled100`,
  partition math, persisted financial data, or analytics canonical actuals.
- Use the Core-resolved logical date, never a Budget-layer wall clock.
- Do not add a navigation store, scene cache, hand-drawn BottomNav half arc,
  post-settle Trio timer, or per-crossing structural/repository barrier.
- Existing Legacy Summary, prepared text/scene architecture, one LogBox
  ScrollController/ScrollPosition, target semantics and FAB geometry remain
  protected.

## Task 1 — Define and prove pure Daily Budget projection

**Files:**
`lib/features/dashboard/application/dashboard_budget_period.dart`,
`lib/features/dashboard/application/prepared_budget_rhythm_snapshot.dart`, new
or existing neutral Budget projection file, and focused domain/controller
tests.

1. Inspect the established scaled-money rounding helper and keep its explicit
   half-way behavior. Add a RED pure test for current-month projection:
   80,000 / 10 × 30 = 240,000; raw ratio 1.20; gauge .90; danger tone.
2. Add RED cases for zero-spend calendar days, 28/29/30/31-day months,
   selected-day invariance inside one month, month/key invalidation, past final
   actual and future unavailable/zero behavior.
3. Add immutable `DashboardBudgetMonthEndProjection` and analysis-mode/value
   types. It owns month-to-date canonical money, elapsed calendar days, month
   length, unbounded forecast, raw ratio, visual fill, break-even position and
   health input; no repository dependency or serialization.
4. Extend the prepared target-local rhythm source with a bounded through-as-of
   month sum. It includes zero-spend calendar days through the denominator and
   excludes current-month post-as-of seeded data. Cache only the current
   revision/direction/target/year/month/as-of key.
5. Run the new focused projection tests RED, implement, then rerun GREEN.

## Task 2 — Wire typed Budget presentation without contaminating edits

**Files:**
`lib/features/dashboard/application/dashboard_core_controller.dart`,
`dashboard_budget_presentation_controller.dart`, Header/selected-avatar
presentation adapters, current limit-edit context/controller tests.

1. Add RED tests that DAY and MONTH obtain equal monthly keys, DAY Header uses
   forecast/limit while Summary/LogBox remain selected-day values, and DAY
   editing receives the exact MONTH canonical actual.
2. Resolve `initialDate ?? DateTime.now()` once in `DashboardCoreController`,
   normalize it to the existing logical date type and inject the same value
   into navigation and Budget presentation. Remove duplicate downstream
   fallback ownership.
3. Replace ambiguous live-state use with explicit
   `displayNumeratorScaled100` and `canonicalActualScaled100ForLimitEdit`.
   Standard modes retain actual utilization; DAY receives a projection. Keep
   partitions and editor context on canonical monthly actual.
4. Reuse the current health resolver. Add a selected-chrome geometry mode:
   MONTH stays circular; DAY paints a bottom-to-top fill inside the same
   envelope, clamped `rawRatio * .75`, with a fixed .75 break-even mark.
5. Add RED/GREEN optimistic edit test: 240k forecast / 200k limit becomes .96
   raw and .72 fill at effective 250k before persistence, with forecast and
   editor actual unchanged. Run relevant existing Budget and edit suites.

## Task 3 — Generalize prepared segmented temporal publication

**Files:**
`lib/features/dashboard/application/dashboard_core_controller.dart`,
`dashboard_presentation_controller.dart`, visible-frame/prepared-index
implementation and Summary interaction tests.

1. Add causal RED tests using real crossing callbacks for prepared segmented
   MONTH and YEAR (plus DAY regression): candidate → canonical commit → exact
   prepared visible frame → LogBox selection, before any structural
   preparation, repository call, or settle. Add Current/Dynamic Trio and
   Legacy control parity, slow secondary preparation, and rapid A→E stale
   completion cases.
2. Inspect strict prepared-frame lookup versus materialization. Generalize
   `publishPreparedExperimentalChild` only into a capability that accepts a
   candidate when an exact already-prepared frame exists; do not call coverage
   materialization in this foreground path.
3. Atomically commit canonical navigation through the existing owner, advance
   the current presentation epoch, and queue the exact frame through the
   existing visible-frame coalescer/store. Retain the existing structural path
   fail-closed for misses.
4. Keep scene-window and parent-hotset preparation coalesced, stale guarded,
   and foreground-preemptible after publication. Keep Legacy untouched.
5. Rerun tests and collect trace fields proving no per-crossing barrier.

## Task 4 — Correct Summary motion and compact only visual tracks

**Files:** `lib/features/dashboard/presentation/widgets/summary_pill_experiments.dart`
and focused Summary geometry/motion tests.

1. Add RED deterministic motion test: Trio is present during drag, ballistic
   and final snap; it is center-only at the first observed idle state with no
   fake-time advance. Add test proving no scheduled delayed change remains.
2. Remove 2500ms timer state (`_trioCooldown`, retention boolean and ballistic
   cooldown helpers); derive visibility from physical controller activity.
3. Extract one segmented visual-track resolver from the quarter-track layout.
   Preserve amount-zone bounds and semantic nonoverlapping touch tracks. At
   reference width, define adjacent active visual gaps as exactly 50% baseline
   and derive enabled separator centers from those same gaps.
4. Add RED/GREEN resolver/widget tests for SUM/YEAR/MONTH/DAY, amount right
   edge/width, separator on/off stability and hit rectangles. Do not change
   typography, outer Summary dimensions or temporal semantics.

## Task 5 — Put the one BottomNav contour in the final composition pass

**Files:** `lib/app/shell/bnb03_bottom_navigation.dart` and existing/new
contour widget or golden tests.

1. Add RED pure geometry test that the canonical path has left rise, crest,
   right fall and both side continuations. Add a composed Stack test/golden
   sampling the actual final pixels on left edge, both FAB sides and right
   edge; a Path-only test is insufficient.
2. Make `_Bnb03BarSurfacePainter` fill-only. When enabled, render one final
   `IgnorePointer` painter after FAB/content that invokes the same
   `Bnb03BottomNavigationContour.topContour` with the existing border token
   and 1px source width.
3. Remove the under-FAB border pass, verify zero double stroke/no line through
   the FAB, and test rounded/straight × border off/on plus unchanged FAB bounds
   and hit behavior.

## Task 6 — Evidence, docs, verification, delivery

1. Update the checklist only with factual status/evidence and record Drive r45
   and exact old source divergence. Update the active plan with final metric,
   formula and trace evidence. Do not claim Android validation before it occurs
   and do not add a physically accepted milestone without human acceptance.
2. Run targeted tests followed by affected existing domain, Budget, Summary,
   visible-frame/cache, LogBox identity and BottomNav suites in Ubuntu/proot:
   `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && /home/flutteruser/flutter/bin/flutter test test/<target>'`.
3. Run Ubuntu/proot `flutter analyze`; run `git diff --check`; inspect status
   and full diff for unrelated edits. Resolve all task-created failures.
4. Commit one focused production change, push according to repository
   workflow, monitor the Actions run for that SHA, download the normal human
   APK to `/storage/emulated/0/Download/fluvi`, and record its SHA-256.

## Completion gate

Every row in
`docs/superpowers/checklists/2026-08-27-daily-budget-summary-parity-checklist.md`
must be `DONE`, apart from an explicitly identified unavailable external
validation. Re-read this plan, the approved design and the screenshot before
commit; compilation/build status never substitutes for those conditions.

## Implementation evidence — 2026-08-27

- `DashboardBudgetMonthEndProjection` is now a pure immutable type. It
  separates `displayNumeratorScaled100` from
  `canonicalActualScaled100ForLimitEdit`; the latter alone reaches
  `DashboardBudgetLimitEditContext.actualScaled100` and partition arithmetic.
  DAY and MONTH retain the same `FinancialLimitMonthPeriod` key.
- `DashboardCoreController` creates `logicalAsOfDate` once from injected
  `initialDate` (or one constructor-bound fallback). The projection uses the
  prepared target-local rhythm bank through that date: integer half-up
  `monthToDate * daysInMonth / elapsedDays`. It is bounded by one target's
  current-month prepared points and causes no repository request.
- Past months resolve final monthly actual; future months are explicitly
  unavailable/zero; current months exclude post-as-of rhythm points. The
  projection key contains revision, direction, target, year/month, as-of date
  and effective monthly limit—not selected day.
- `DashboardPresentationController.publishPreparedExperimentalTemporalCandidate`
  generalizes the old DAY-only strict prepared-frame path to YEAR/MONTH/DAY.
  `DashboardCoreController` activates an already-retained scene window before
  that direct commit, then logs `SUMMARY_COMPONENT_PREPARED_PUBLICATION`.
  Cache misses continue through the existing fail-closed structural route.
- Dynamic Trio has no timer or cooldown state. Its neighbor set depends only
  on `CenteredCarouselController.hasActiveScrollActivity`; first idle state is
  center-only.
- `SummarySegmentedTrackGeometry` keeps quarter-width touch tracks but packs
  active visual centers at `navigationWidth / 8` pitch rather than the former
  `navigationWidth / 4`; the amount zone remains 40% and separators use those
  same visual midpoints.
- BottomNav keeps `Bnb03BottomNavigationContour.topContour` as its sole
  geometry owner. The surface painter is fill-only; one 1px
  `FluviVisualTokens.border` `IgnorePointer` overlay follows the FAB in the
  Stack, so the FAB backing cannot hide the right cubic arc.
- Focused domain/Budget tests passed 24 cases; Core/Summary/scene-window/
  BottomNav passed 75; visible-frame/cache/LogBox/Query/limit-edit passed 150;
  Budget surface/rail/distribution passed 57; the final BottomNav raster test
  passed 6. The existing Partner pager `>104` height assertion fails
  identically on clean r45 (`100.8`) and is recorded as inherited. `flutter
  analyze` also passed with no issues. Delivery build and physical Android
  inspection remain the final external gates at the time of this note.
