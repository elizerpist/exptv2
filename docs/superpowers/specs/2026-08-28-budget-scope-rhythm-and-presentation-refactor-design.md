# Budget scope rhythm and presentation refactor — accepted design

**Status:** approved for implementation (2026-08-28)  
**Baseline:** `separated-core-modes` at `3127abc018ddea7694661e25015790dcd773bf9e`  
**Drive evidence:** *Fluvi Logs*, Drive revision 45, read 2026-08-28  
**Pre-existing user work preserved:** `docs/prototypes/category_palette_variation_lab.html`

## Scope and sources

This is one cohesive refactor of four presentation concerns and the Partner
rhythm data path. It does **not** alter the accepted four-scope Budget
semantics, limit model, or temporal-navigation model.

The authoritative requirements are the user prompt in this conversation and
the approved 3-hour correction. The DAY rhythm has exactly these eight local
clock buckets, in this fixed ordinal order:

| Ordinal | Range | Product label |
| --- | --- | --- |
| 0 | 00:00–02:59 | Éjfél |
| 1 | 03:00–05:59 | Hajnal |
| 2 | 06:00–08:59 | Reggel |
| 3 | 09:00–11:59 | Délelőtt |
| 4 | 12:00–14:59 | Kora délután |
| 5 | 15:00–17:59 | Délután |
| 6 | 18:00–20:59 | Este |
| 7 | 21:00–23:59 | Késő este |

The latest Log record and the implementation prove that the old Partner
rhythm is rolling: month has seven days, year six months, and SUM five years.
`DashboardBudgetRhythmProjector` derives its end from a clock/window. This
path is retired; it is not retained under a scope-aware name.

## Locked product semantics

| Scope | Budget semantics (unchanged) | Spending Rhythm bucket identity |
| --- | --- | --- |
| DAY | Napi tempó | the eight fixed local 3-hour parts of the selected calendar day |
| MONTH | Havi állás | every actual calendar day in the selected month |
| YEAR | Éves állás | Jan–Dec of the selected calendar year |
| SUM | Havi átlag | every concrete year in the selected target/direction history span |

The rhythm key is exactly `(coreRevision, direction, selected Budget target,
active LedgerTimeScope)`. A Partner row highlight remains a distribution-list
state; it does not silently turn the chart into a selected-partner history.
The visible/prepared frame remains the authority during temporal preview
crossings.

## Spending Rhythm architecture card

### Single source and write path

| Concern | Owner | Contract |
| --- | --- | --- |
| Transaction local time classification | native `BudgetRhythmDayPartClassifier` | one `00:00…1439` → ordinal `0…7` mapping; no Dart UI classification |
| Prepared rhythm facts | native `FluviPreparedSpendingRhythmSnapshot` / Dart `PreparedSpendingRhythmSnapshot` | immutable RAM transit facts, keyed by direction and target |
| Binary transport | native `DashboardBinaryCodec` / Dart `DashboardPreparedBudgetLimitSnapshotBinaryCodec` | one versioned, lockstep codec contract; old in-memory payloads are unavailable rather than guessed |
| Scope interpretation | Dart `DashboardSpendingRhythmProjector` | pure, clock-free conversion of prepared facts plus exact `LedgerTimeScope` into typed analysis |
| Publication/cancellation | `DashboardSpendingRhythmController` | listens to existing Budget selection, navigation and visible frame; publishes only prepared state |
| Geometry | `SpendingRhythmBarLayout` | pure layout result, shared by chart painting and tests |
| Rendering/intent | Partner chart widget | consumes immutable projection only; no repository I/O or money aggregation |

The prepared direction bank is deliberately compact and indexed rather than a
set of per-widget maps:

```
targetOffsets[]
epochDays[]                 // sorted, local calendar identity
dailyActualScaled100[]
dayPartActualScaled100[]    // flat: pointIndex * 8 + dayPartOrdinal
```

Offsets form lightweight target views rather than allocating copied sublists.
Each prepared day satisfies `daily == sum(eight day parts)`. The native query
groups by direction, target/category, local epoch day and the classifier
ordinal, then materializes the compact day record. This preserves timestamp
information before daily aggregation discards it.

The transport version is bumped atomically in Kotlin and Dart, with explicit
payload-size accounting and fail-closed validation of array length, offsets,
sort order, ordinal count, and money range. This snapshot is transient RAM
data; there is no persistent-data migration and no compatibility fallback that
could reinterpret the former daily-only payload.

### Typed scope analysis

The old nullable rolling projection is replaced by a sealed/closed analysis
catalogue:

- `DaySpendingRhythm` — exactly eight values and canonical labels;
- `MonthSpendingRhythm` — 28–31 explicit days, including zeroes;
- `YearSpendingRhythm` — exactly twelve Jan–Dec values;
- `SumSpendingRhythm` — a continuous concrete-year domain including internal
  zero years;
- `UnavailableSpendingRhythm` — explicit unavailable data state.

The projector has no `FluviClock`, rollover timer, rolling endpoint, `last N`
title, or date-window API. DAY/MONTH/YEAR derive only from the active selected
scope. SUM uses the prepared target/direction first and last data year, capped
at the canonical current/data boundary without invented future years. It
projects compact year aggregates in `O(yearCount)`, not transactions.

The controller is a thin visible-frame subscriber: exact active scope in,
published typed analysis out. It does not own selection, temporal state or
queries. Existing prepared-cache and stale-generation publication routes are
reused.

### Full-width Partner composition

`BudgetDistributionPageSurface` remains the Category-card composition
boundary. Partner receives a separate composition that reuses extracted,
neutral primitives for its heading and distribution legend/list but owns this
specific structure:

```
Partner card
  upper section: donut + vertically scrollable Partner legend
  lower section: full-inner-width Spending Rhythm chart
```

The existing card outer height, donut scale, row typography and row height are
protected. Only the Partner legend viewport is reduced to make a meaningful
lower plot area. Category geometry cannot acquire Partner-footer flags.

### Bar geometry and normalization

`BudgetRhythmBarChart._BudgetRhythmBar._trackWidth == 11.0` is the existing
authored **maxBarWidth** source and is promoted to a named shared layout token
without changing its value. A single pure `SpendingRhythmBarLayout.resolve`
owns widths, pitch, gaps, content extent and scroll requirement.

For a supported non-scroll viewport:

```
fitWidth = (availableWidth - (count - 1) * minGap) / count
barWidth = clamp(fitWidth, minBarWidth, maxBarWidth)
gap = (availableWidth - count * barWidth) / (count - 1)
```

`minGap` is an explicit chart token selected from the narrowest existing
rounded-bar/card spacing after implementation measurement. The supported
minimum inner chart width and `minGap` derive one documented
`minBarWidth = (minimumWidth - 30 * minGap) / 31`; they are pinned by layout
tests rather than hidden in a widget. Six DAY bars retain the 11dp cap and
gain equal gaps rather than becoming columns. MONTH never scrolls. SUM with
more than 31 years uses the fixed 31-slot pitch and one persistent local
horizontal controller; it still renders every concrete year.

Bars normalize only inside their current analysis:

```
maxBucket = max(values)
fraction = value / maxBucket, when maxBucket > 0
mean = sum(values) / bucketCount       // zero buckets included
averageFraction = mean / maxBucket
```

All-zero analyses retain their required x-axis slots, render zero bars, and
omit a fake average line. X labels are analysis-owned: all DAY labels;
`1,5,10,15,20,25,last` for MONTH (deduplicated); Jan–Dec for YEAR; concrete
moving year labels for SUM.

## SUM ring presentation architecture card

`DashboardBudgetRingPresentationSettings` and its controller own only ring
presentation preferences:

```
BudgetSumRingStyle
  current
  coloredScaleWhiteArc
  coloredScaleMovingSphere

BudgetHealthyColorMode
  fixedGreen
  targetAccent
```

They are independent from Header settings. `current` is the default and
routes to the existing SUM paint strategy unchanged. The selected-avatar state
resolves a typed ring presentation model before it reaches
`_SelectionChromePainter`; painters never read tuner state.

Both coloured styles use the existing canonical clockwise ring coordinate,
track geometry and 3D material. A centralized scale-material resolver owns a
smooth healthy→warning→danger hue blend around the unchanged `.75` and `.90`
semantic thresholds. Its named blend width/profile is visual-only. Warning
stays yellow and danger stays red.

| Style | Current indicator | Fixed scale references |
| --- | --- | --- |
| `current` | current existing short marker | current existing references |
| `coloredScaleWhiteArc` | one fixed-length white 3D rounded arc at clamped typical ratio | two white 3D spheres at `.75`, `.90` |
| `coloredScaleMovingSphere` | one white 3D sphere at clamped typical ratio | two white 3D spheres at `.75`, `.90` |

Every marker center uses
`center + polar(trackRadius, canonicalClockwiseStartAngle + 2πr)`. The
coloured styles paint scale track → moving value → fixed reference spheres.
They do not add a `.50` sphere. Raw typical ratio remains unbounded in state;
only its visual coordinate is clamped.

`BudgetHealthyVisualColorResolver` is the sole owner of fixed-green versus
target-accent healthy presentation. It supplies hue-preserving 3D material to
YEAR healthy cells and the coloured SUM healthy region. It deliberately does
not alter DAY/MONTH's accepted below-warning category-accent behavior.

## Header presentation architecture card

`DashboardBudgetHeaderPresentationSettings` remains the owner for Header-only
appearance, extended with:

```
showPartitionContour: bool       // default false
textContrastStyle:
  none | hardOppositeShadow | oppositeOutline
```

`BudgetAllocationPartitionLane` owns the existing outer `RRect` and paints
one thin white contour from that same geometry after fills; it never outlines
individual partitions and never changes bounds/hit testing.

`DashboardHeaderContrastText` is the single textual primitive for Header
foreground-family text. It receives normal typography and the resolved
opposite foreground colour. `none` is byte-for-byte equivalent styling;
`hardOppositeShadow` uses one named near-zero-blur opposing shadow;
`oppositeOutline` uses a proper fill+stroke pair with the stroke semantics
excluded. It is applied to Budget target, metric, primary value, scope label
and supporting text without altering measurements, baselines or semantics
count.

## Upper-content gesture architecture card

The existing `DashboardExpansionController` remains the sole expansion state.
`DashboardUpperVerticalGestureCoordinator` is extended into a single
pointer-sequence arbiter, not duplicated per card. It has explicit outcomes:

```
undecided → child horizontal / child tap / child vertical scroll /
            header vertical drag / cancelled
```

Background surfaces participate through parent arena listeners and precise
hit regions behind/alongside child controls; no opaque full-card overlay sits
above taps, PageView or avatar controls. The previous only-reliable route was
right legend `OverscrollNotification`, which explains why empty card,
heading, donut whitespace and chart surface were inert.

| Surface | Vertical behavior | Protected behavior |
| --- | --- | --- |
| Header/handler | existing baseline controller mapping | unchanged |
| empty heading/card/donut whitespace | direct coordinator drag | donut/list taps |
| non-scrollable lower chart | direct coordinator drag | SUM strong horizontal chart scroll |
| Partner legend list | its existing scroll first; residual boundary delta to coordinator in same pointer sequence | row taps |
| Summary selector rect | temporal selector only | no expansion/reset conflict |
| avatar/PageView/chart horizontal control | child horizontal wins | no Header theft |

The list handoff retains the child `ScrollController` and `ScrollPosition`.
Direction signs are inherited from the working Header/handler path and tested
against it in both directions. The coordinator cancels stale input ownership
on a new foreground gesture; no second swipe is needed at the boundary.

## Tuner and dependency flow

The existing Header hamburger tuner composes the two injected presentation
owners; it neither persists data nor contains render logic. It adds independent
controls for SUM style, healthy colour, partition contour and text contrast.

```
widget → presentation/controller → immutable prepared analysis/layout → widget
native query/index → binary adapter → prepared snapshot → pure projector
```

Presentation depends on contracts and immutable models, never on Room/native
queries. No paint path aggregates transactions or creates text layout.

## Verification strategy

Tests are written red-first for native/Dart codec parity, eight-bucket
classification, typed scope analyses, no-rolling history, zero buckets,
full-width layout, 6/12/28/29/30/31/>31 bar geometry, normalization and
labels, ring strategy/material invariants, header contrast/contour, and real
pointer gesture ownership/handoff. Architecture boundary tests prohibit UI
repository access and duplicate settings/gesture owners. Visual cases inspect
the changed SUM styles and Partner chart states. Flutter checks run inside the
Ubuntu proot; the human Android APK is built and delivered through GitHub
Actions only after a production commit is pushed.
