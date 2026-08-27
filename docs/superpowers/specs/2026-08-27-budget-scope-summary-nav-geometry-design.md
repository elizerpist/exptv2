# Budget scope, segmented Summary, and BottomNav geometry design

## Evidence and boundaries

- Baseline: `separated-core-modes` at `58bd90eb4aa7a62584869ccad40f747ac1f5268c`; local and `origin/separated-core-modes` match and the worktree is clean.
- Latest inspected **Fluvi Logs** revision: **45** (document `13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU`).  It records the pre-`8853ea65` segmented Month cache-miss structural-publication barrier (38–97 ms) and is retained as the regression boundary.  Current `DashboardCoreController.navigateExperimentalTemporalComponentCandidate` publishes prepared YEAR/MONTH/DAY candidates first; that route must remain the foreground path.
- Physical evidence: `Screenshot_20260827-122025.png`, `Screenshot_20260827-121052.png`, and `Screenshot_20260827-120530.png`.  They show the current Summary visual/hit divergence and the BottomNav asymmetry; source geometry, not screenshot measurements, is authoritative.
- `MILESTONE_COMMITS.md` remains a protected boundary for input-first prepared navigation, one vertical `ScrollController`/`ScrollPosition`, immutable committed LogBox geometry, bounded resources, and no render-hot-path `TextPainter` work.

## Ownership map

| Concern | Sole owner | Rule |
|---|---|---|
| Persistent budget limit truth | financial-limit repository/native Room schema | base monthly limit plus concrete month override only |
| Effective denominator | resolved-monthly-limit bank/resolver | `override ?? base ?? unavailable` |
| Scope meanings | typed Budget scope analysis factory | Month, Day projection, Year vector, Typical-month are distinct values |
| Logical as-of date | Dashboard Core injected logical date | never `DateTime.now()` in Budget projection |
| Scope display vs edit actual | live selection state | `displayNumeratorScaled100` is never the canonical edit actual |
| Ring geometry/material | one selected-avatar Fluvi ring authority | strategies vary fill only |
| Segmented Summary rects | segmented layout geometry | visual, clipping, hit test and semantics share each rect |
| BottomNav physical shape | BottomNav physical geometry | fill, clip and contour stroke use its one top-edge path |

## Root causes being removed

### Segmented Summary

Before this delivery, `SummarySegmentedTrackGeometry` retained quarter-width semantic tracks and moved content with `visualOffsetForTrack`. `_FixedHierarchyTracks`, `_ModeSelector`, and `_HierarchyValueSelector` therefore retained old gesture lanes while drawing elsewhere: a swipe over visual DAY could control MONTH. The implemented replacement has no visual translation or quarter track: it creates one actual padded owner `Rect` per active MODE/YEAR/MONTH/DAY section and gives that same rect to clipping, semantics and the vertical carousel; authored content is centred inside that same owner.

At the 378 × 59 reference Summary, amount width is 151.2 and the authored 8 px outer inset yields an old 210.8 px navigation width. With the old 25 px mode badge and 54 px `2026` content width, the old content-edge gap is exactly 13.2 px. The new 218.8 px navigation surface uses an exactly 6.6 px visual content-edge gap at every active boundary. Its final DAY owner rects are MODE `[8.9, 50.0]`, YEAR `[53.1, 107.1]`, MONTH `[113.7, 154.8]`, DAY `[154.8, 195.8]`; visual content stays centred in each owner and remains non-overlapping. The 34 px mode visual itself begins at x=12.5, exactly its `(59 - 34) / 2` top inset. The mode badge uses its existing `DashboardLogBoxTokens.avatarSize` outer visual size.

### BottomNav

Before this delivery, the contour was centred at `navWidth / 2`, but the FAB layer was positioned independently (`left: 169.5` at 428 logical px), placing its 96 px shell centre at 217.5 rather than 214. Independent cubic controls and paint passes made symmetry and clearance unverifiable. The implemented `Bnb03BottomNavigationContour` uses `navWidth / 2` for both physical contour and unchanged 96 px shell; its two cubic halves are mirrored circle-derived controls. The visible 84 px FAB ring and its 6 px white surround define a 48 px contour radius, preserving the apparent 96 px outer geometry while making equal clearance constructional. The optional stroke is one final `IgnorePointer` overlay of the same `topContour` path.

### Budget model

`FinancialLimitSumPeriod`, `FinancialLimitYearPeriod`, and `FinancialLimitMonthPeriod` currently encode three independently writable limit truths. This conflicts with the accepted product model. Active storage becomes:

- `baseMonthly(direction, target)`;
- `monthlyOverride(direction, target, yearMonth)`.

Legacy period values are migration-only inputs. Explicit legacy MONTH values become overrides; SUM becomes base. Legacy YEAR values deterministically seed only missing months after explicit overrides, with base profile/even distribution and stable largest-remainder allocation. Reads and writes never fall back to legacy rows once migration completes.

## Scope semantics

| Global scope | numerator | denominator | ring strategy | edit target |
|---|---|---|---|---|
| SUM | completed-calendar-month typical average | base monthly | fixed short position marker | base monthly |
| YEAR | sum of 12 actual months | sum of 12 resolved month limits | 12 equal independent mini-arcs | atomic proportional 12-month override batch |
| MONTH | selected monthly actual | resolved selected month | classic clockwise fill | selected month override |
| DAY | pure month-end forecast | same resolved selected month | bottom-to-top reveal, fixed .75 marker | same selected month override |

Day's immutable `DashboardBudgetMonthEndProjection` owns month-to-date actual, elapsed calendar days, days in month, forecast and raw ratio. It receives the injected Core as-of date, does not contain the selected day, stores no financial data, and its forecast is never used as canonical limit-edit actual.

All scope analyses and the renderer map through the single `BudgetProgressHealthResolver`: `< .75` accent, `.75 … .90` warning, `> .90` danger. Day maps raw projection to visual fill `clamp(raw * .75, 0, 1)` and keeps a .75 break-even marker; only the visual representation clamps.

## Migration and interaction invariants

- Migration is versioned, transactional where native storage permits, idempotent, and emits only canonical base/override rows.
- A Year edit scales resolved monthly values proportionally, distributes scaled-integer residuals by largest fractional remainder then calendar order, and persists the complete vector atomically. Zero totals distribute evenly.
- Sum edits change base only; Month/Day edits create/update one monthly override only.
- Prepared snapshots hold a bounded resolved-month bank and cached completed-month aggregate; first visible avatar/time interaction issues no repository read.
- Query/LogBox scope remains raw global temporal scope. Only Budget Header/avatar/partition consume the Budget scope analysis.

## Ring source contract

The source is the existing selected-avatar Fluvi ring: one 308 viewport, centre 154, face radius 122, source track radius `96 × 1.12 = 107.52`, track width 24, gradient/shading/highlight material and rounded active-cap language. The production painter consumes `BudgetProgressRingGeometry.source`, including its geometry, track gradient, shadow, gloss and cap width; `BudgetProgressRingGeometry.sourceId` is `fluvi-selected-budget-ring-v1`. Month, Day, Year and Sum use that one geometry/material source. Year resolves each segment from the unmodified target accent, never the annual aggregate tone. Day is no longer a standalone vertical `RRect` bar; Year is no separate chart; Sum is no separate dial.
