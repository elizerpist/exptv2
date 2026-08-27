# Daily Budget projection and Summary parity design

**Status:** Approved — the user explicitly approved the clean derived-state
refactor and confirmed that segmented temporal parity, Dynamic Trio immediate
idle collapse, and the BottomNav contour repair are mandatory co-deliverables.

**Reference state:** `separated-core-modes` at
`44b1992a8c0d5b66ce0c39acaf44155515dc1131`; clean local/remote state.
`Fluvi Logs` Drive document
`13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU`, revision **45**,
inspected 2026-08-27. Current visual evidence:
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260827-092059.png`.

## Goal

Keep Financial Limits monthly while making DAY Budget a typed, derived
month-end forecast. Restore prepared publication parity for all segmented
Summary temporal components, remove Dynamic Trio's idle timer, compact the
segmented hierarchy tracks, and make the one BottomNav contour visible above
the FAB composition.

## Architecture card

| State / responsibility | Single owner | Write path | Consumers |
| --- | --- | --- | --- |
| Persisted Budget limit | existing `FinancialLimitRepository` / Room | existing monthly `FinancialLimitKey` optimistic edit queue | controller, Header, selected avatar, partition |
| Logical as-of date | `DashboardCoreController` | constructor-injected `initialDate`, resolved once | navigation setup and Budget projection |
| Month-end forecast | new immutable `DashboardBudgetMonthEndProjection` | pure projection from prepared snapshot + logical as-of date | DAY Header and selected avatar chrome only |
| Canonical Budget actual | existing prepared monthly `PreparedBudgetLimitCell.actualScaled100` | immutable prepared index | limit edit, partition, MONTH/SUM/YEAR presentation |
| Temporal visible frame | existing `DashboardPresentationController` / `DashboardVisibleFrameStore` | generalized prepared temporal publication | Summary amount, LogBox, Budget consumers |
| Summary selector geometry | one new pure segmented-track layout resolver | constructor computation from navigation width | selectors, separators, hit rectangles |
| BottomNav contour | existing `Bnb03BottomNavigationContour` | existing path factory | background fill, one foreground border stroke |

No new database tables, FinancialLimit periods, navigation stores, scene
caches, or widget-owned persistence are introduced.

## Daily Budget model

### Limit identity

`DashboardBudgetPeriodResolver.fromTimeScope(DayScope)` remains a
`BudgetLimitMonthPeriod`. The conversion to `FinancialLimitMonthPeriod` stays
in the existing `_financialLimitKeyFor` mapping. DAY and MONTH therefore
create bit-for-bit equal `FinancialLimitKey` values for the same direction,
target and year/month.

There is deliberately no `FinancialLimitDayPeriod`, daily Budget row,
repository method, Room migration, per-day allowance, or synchronization
layer.

### Typed semantic split

`DashboardBudgetLiveSelectionState` must stop using one ambiguous amount for
both a display and a financial rule. Its successor shape is:

```dart
enum DashboardBudgetAnalysisMode { actualUtilization, projectedMonthEnd }

final class DashboardBudgetMonthEndProjection {
  const DashboardBudgetMonthEndProjection({
    required this.key,
    required this.monthToDateActualScaled100,
    required this.elapsedCalendarDays,
    required this.daysInMonth,
    required this.projectedMonthEndScaled100,
    required this.projectionRatio,
    required this.gaugeFillRatio,
    required this.breakEvenGaugeRatio,
    required this.healthBand,
  });
}
```

The selection state will retain a clearly named
`canonicalActualScaled100ForLimitEdit` from the containing monthly prepared
cell. It will expose a separately named `displayNumeratorScaled100`: actual
for SUM/YEAR/MONTH and projected month-end amount for DAY. Header rendering
reads only the latter. `DashboardBudgetLimitEditContext.actualScaled100`
receives only the former. Partition actuals remain canonical prepared actuals;
forecast values may not enter them.

The projection key contains core revision, direction, target handle, year,
month, logical as-of date and effective monthly limit, but never selected
day-of-month. It has no independent mutable cache: derivation reads only the
already prepared, target-local rhythm points, so a same-month DAY crossing is
bounded and performs no repository I/O.

### As-of source and formula

`DashboardCoreController` resolves the optional `initialDate` once (falling
back to `DateTime.now()` once at startup), converts it to the canonical
`LocalDate`, and passes that same logical date to both initial temporal
navigation and Budget projection. The Budget layer receives no wall-clock
callback and uses no `DateTime.now()`.

For a current month, use the prepared target-local rhythm bank through the
logical as-of date, including only transactions on or before that day:

```
projectedMonthEndScaled100 = round(
  monthToDateActualScaled100 * daysInMonth / elapsedCalendarDays,
)
```

The existing project money rounding convention will be found and used; the
test will pin the chosen half-way behavior. Elapsed days are calendar days,
including zero-spend days. The rhythm bank remains sparse and is never used as
a day-count. Its existing target-local ordering is extended with one bounded
month-through-as-of sum helper: O(log n + k), where `k` is only that target's
non-zero points in the one calendar month (at most a 31-day calendar range).

Past month: `elapsedCalendarDays == daysInMonth` and projection equals final
actual. Future month: `elapsedCalendarDays == 0`, no division occurs, and the
projection is explicitly unavailable/zero according to the current no-data
visual contract. Current month excludes future-dated seeded transactions.

### DAY presentation

The DAY Header renders `displayNumeratorScaled100 / monthly limit`, while
Summary, LogBox, transaction count and daily distributions continue using the
selected DayScope. The selected avatar gets a progress-chrome geometry enum:

- SUM/YEAR/MONTH retain the existing circular `BudgetLimitProgressProjection`.
- DAY uses bottom-to-top vertical fill in the same selected chrome envelope.
- raw health is resolved once by the existing `BudgetLimitProgressToneResolver`
  from the unbounded projection ratio.
- `gaugeFillRatio = clamp(projectionRatio * .75, 0, 1)`.
- one permanent break-even marker is painted at `.75` of gauge height.

Thus 100% projection is 75% gauge height, 120% is 90%, 4/3 is full height,
and greater forecasts retain their full numerical value even though the paint
clamps. The existing circular MONTH ring is untouched.

Optimistic edits change only the effective monthly denominator. The existing
edit controller/key/queue/reconciliation remain unchanged; recomputation of
ratio and gauge is synchronous from the unchanged forecast numerator and new
effective denominator.

## Segmented Summary publication

### Proven current divergence

In r45, a cache-miss MONTH crossing has the trace sequence:

```
SCENE_NAVIGATION_INPUT_ACCEPTED (summaryExperimentMonthCrossed)
→ SCENE_COVERAGE_DEMAND_CREATED
→ SCENE_NAVIGATION_TRANSITION_REQUESTED
→ SCENE_WINDOW_REBASE_REQUESTED
→ STRUCTURAL_PUBLICATION_PREPARE_STARTED
→ SCENE_WINDOW_PREPARE_STARTED
→ SCENE_NAVIGATION_TRANSITION_COMMITTED
```

Rapid crossings supersede prior preparation; observed input-to-commit samples
include 38, 46, 60, 61 and 97 ms. In source,
`DashboardCoreController.navigateExperimentalTemporalComponentCandidate`
calls `presentation.publishPreparedExperimentalChild(candidate)` only for
`DashboardTemporalAnchorComponent.day`; YEAR and MONTH invoke
`_navigateExperimentalTemporalCandidate`, so they wait for scene coverage.

### Design

Generalize the existing prepared-frame capability, not its data store. A
candidate with an exact materialized prepared frame will:

1. atomically commit its canonical `DashboardNavigationState` through the
   existing navigation owner;
2. synchronously select/queue the exact prepared visible frame in the existing
   `DashboardVisibleFrameStore` with a new presentation epoch;
3. let Header, Budget and LogBox project from that one frame on the next
   render opportunity;
4. schedule broad scene-window/parent-hotset coverage only as stale-guarded,
   coalesced, foreground-preemptible maintenance.

This generalizes the prepared DAY child contract to all valid YEAR/MONTH/DAY
candidate shapes. It does not call a repository, build text, create another
visible-frame owner, lower crossing rate, or wait for settle. A target lacking
an exact prepared frame keeps the existing fail-closed structural path.

Legacy mother-child navigation is a control and is not rerouted or slowed.
Current and Dynamic Trio selectors invoke the identical crossing callback and
therefore the identical publication route.

## Summary motion and geometry

`_HierarchyValueSelectorState` removes `_dynamicTrioBallisticCooldown`,
`Timer`, `_ballisticMotionSeen` and `_keepDynamicTrioVisible`. Trio visibility
is simply `presentation == dynamicTrio && controller.hasActiveScrollActivity`.
The controller's final snap remains motion; the first observed idle state
collapses to the center label immediately. Setting changes, replacement and
dispose have no pending delayed work to cancel.

The existing Summary amount zone remains exactly 40% and right-aligned. A pure
segmented-track resolver will define:

- semantic/hit rectangles that remain non-overlapping and accessible;
- visual content centers packed from the left with each resolved adjacent gap
  equal to half of the current reference gap;
- separator centers derived from the same visual gaps.

It will be used for SUM/YEAR/MONTH/DAY, so inactive quarter tracks no longer
produce phantom whitespace. Font metrics, outer Summary bounds and the amount
zone do not change.

## BottomNav contour

`Bnb03BottomNavigationContour.topContour` is retained as the one source of
geometry. `_Bnb03BarSurfacePainter` paints only the physical fill. When the
optional border is enabled, a final `IgnorePointer` CustomPaint layer after
the FAB paints that same top contour once using the existing 1px
`FluviVisualTokens.border` token. It owns no semantics or hit testing.

This solves the real composition order: the white FAB no longer hides the
right arc. Rounded/straight settings keep the same FAB x/y/diameter and all
four shape × border combinations retain one contour stroke.

## Test and verification strategy

Before production edits, targeted RED tests will be written and observed
failing in Ubuntu/proot. Coverage includes:

- projection formula, rounding, month lengths, current/past/future policy,
  zero-spend denominator, selected-day invariance and zero repository reads;
- exact Day/Month key equality; header/display versus edit-context semantic
  separation; optimistic limit denominator updates; circular-month regression;
- vertical gauge transform, marker and raw-ratio tone boundaries;
- real segmented YEAR/MONTH/DAY carousel crossings whose visible publication
  precedes any structural preparation; legacy and Trio route parity; rapid
  stale completion; zero I/O on prepared first publication;
- Trio immediate idle collapse and no delayed post-settle state;
- resolver-level half-gap, unchanged amount zone, separator positions and hit
  rectangles for all hierarchy levels;
- actual composed BottomNav Stack pixel/painting evidence for left edge,
  both FAB sides and right edge, plus border-off and four-mode matrix.

Relevant existing Budget, visible-frame, scene/cache, LogBox identity, Summary
and BottomNav suites will run afterward, followed by `flutter analyze` and
`git diff --check` in Ubuntu/proot. The Android human APK remains a GitHub
Actions-only delivery artifact and physical-device validation remains explicit
rather than assumed.

## Implemented evidence

The approved design is implemented with the named pure
`DashboardBudgetMonthEndProjection` input. The projection does not persist or
masquerade as actual: Header uses `displayNumeratorScaled100`; the existing
limit editor and partition retain `canonicalActualScaled100ForLimitEdit` and
the original monthly `FinancialLimitKey`. The Core resolves the injected
logical as-of `LocalDate` once.

The r45 MONTH/YEAR asymmetry is removed by one strict prepared-frame method,
not a second navigation service. It is invoked by every segmented component;
retained scene hits are activated synchronously before the existing visible
frame store receives the candidate. Structural preparation remains the
fail-closed cache-miss path and is no longer on a prepared crossing's first
publication path.

The 2500ms Trio retention owner was removed rather than shortened. The
compacted Summary visual pitch is exactly `navigationWidth / 8` (half the
former `navigationWidth / 4`) while semantic tracks remain quarter-width.
BottomNav's original two-sided cubic contour remains the only path; it now
paints once in a final non-interactive overlay after the FAB.

The BottomNav widget regression renders the complete Stack into a
`RepaintBoundary` and samples the actual raster at both horizontal sections,
the left FAB rise, the crest and the right FAB fall. The previous under-FAB
stroke would fail the right-fall sample; this is therefore compositing evidence
rather than a path-only assertion.

No physical Android observation is claimed here. The one unrelated test
failure observed in this worktree—the Partner pager `height > 104` assertion
with actual `100.8`—was reproduced unchanged on clean r45.
