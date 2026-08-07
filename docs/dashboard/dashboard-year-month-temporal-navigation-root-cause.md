# Dashboard year/month residual lag and temporal navigation audit

Date: 2026-08-07

Status: targeted implementation and local non-golden verification complete;
exact-commit online profile and APK delivery remain the release gate.

## Recoverable milestone

- source before milestone: `c35c680276385deda5a7fad6e116c486634bd4eb`;
- milestone commit: `f33152b1657d0916eef68c6ffb7ca89697320a51`;
- milestone branch:
  `milestone/month-day-perfect-before-year-month-final-isolation`;
- annotated tag:
  `milestone/month-day-perfect-before-year-month-final-isolation-20260807`;
- work branch: `fix/dashboard-year-month-temporal-navigation`.

The milestone commit is intentionally empty. Existing untracked `.tmp-*` logs
and `test/features/dashboard/presentation/failures/` remain user-owned and were
not modified.

## Baseline hashes

| Ownership | File | SHA-256 |
|---|---|---|
| dashboard rail | `lib/features/dashboard/widgets/time_refinement_rail.dart` | `685f5871c53f488ce05a00be19699d9d7134d14849853f87b57c38bbce9478e7` |
| presentation rail adapter | `lib/features/dashboard/presentation/widgets/time_refinement_rail.dart` | `5cb67e0aaf92b44430534d28da68832daa9ff52bd95989e0262e60a5a15feaa9` |
| viewport/gesture | `lib/shared/motion/centered_carousel/centered_carousel.dart` | `d629b7ba139e134d91091b36cb17b3ff6bf37c70621556ff2fb8d799d0fff621` |
| controller/position owner | `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | `a7268aa7294adf2a85d1254526de90e06c7595eaae4b39b398c0296173b3ee0c` |
| physics | `lib/shared/motion/centered_carousel/centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| carousel math | `lib/shared/motion/centered_carousel/centered_carousel_math.dart` | `5558bf2bf909a6316c337e07a777addfc44430060f03cc3070e28a3ad366a6e8` |
| carousel metrics | `lib/shared/motion/centered_carousel/centered_carousel_metrics.dart` | `6d9d73066afcf6cef698ec2bb3939b2d3f4ea6168ae9253bf782b6081fa7008a` |
| prepared index | `lib/features/dashboard/runtime/domain/prepared_dashboard_index.dart` | `470ff2f595d57460abc453eca04480f4cc3f02a76a20d24a9829911463ad27e5` |
| prepared frame | `lib/features/dashboard/runtime/domain/prepared_presentation_frame.dart` | `c2d2edf3d4f019024da6d1b19b5e86041b1768c3e98f8cc74efad065f504ae0d` |
| navigation controller | `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart` | `ce5a9ca79e3d35fafb6e3ac616e972757ab9616c9da06c3494fd03e1ec6bb3fe` |
| navigation state | `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart` | `dcbd1618f1bb5d9126a65237b768d3df0cdeb3d1d4d4726ba7cdeca914b61c65` |
| presentation controller | `lib/features/dashboard/runtime/application/dashboard_presentation_controller.dart` | `f669ef0d169cbef6ad98ccb4606ef8df852e23937f169f56d23b3ff1b4a0217a` |

Fresh milestone verification through Ubuntu proot:

- non-golden Flutter suite: **249/249 PASS**;
- Flutter analyze: **PASS**, `No issues found!`;
- targeted month/day + year/month matrix: **PASS**;
- no golden test was run or generated.

## Side-by-side hot path

Both paths are identical through prepared selection:

```text
CenteredCarousel ScrollPosition
  -> TimeRefinementRail._semanticCrossed
  -> DashboardMotionKernel.semanticCrossed
  -> DashboardPresentationController._onSemanticCrossed
  -> PreparedDashboardIndex.frameForKey             O(1)
  -> DashboardVisibleFrame.fromPrepared             scalar/reference wrapper
  -> DashboardDisplayFrameCoalescer.request
  -> DashboardVisibleFrameStore.publish
  -> navigation/amount/count/LogBox lanes
```

### Month parent → day child (frozen reference)

```text
DayScope
  -> one short numeric rail label
  -> normally one day group
  -> 0–9 prepared rows in the measured production fixture
  -> normally one header plus 0–9 rows in the rendered viewport
```

### Year parent → month child (pre-fix divergence)

```text
MonthScope
  -> a longer month-name rail label (data-density independent)
  -> up to 24 preview rows for a 94-entry month
  -> rows may span many day groups
  -> flat LogBox items: header + row + inter-group gap as separate children
  -> 24 rows across 24 groups expand to 71 sliver children
  -> group background painter walks every prepared group
  -> 360 px sliver cache extent builds additional offscreen row widgets
```

Operations present or materially amplified only in year/month are therefore:

- more distinct day headers and group gaps in `flatItems`;
- more lazy children admitted by the 360 px cache extent;
- more `DashboardLogRow` text/icon/semantics/Material subtrees on first use;
- a `CustomPainter.paint` loop over all prepared `groupLayouts`;
- longer rail label text shaping, which is constant for empty/populated months
  and cannot by itself explain density sensitivity.

No collection was copied, projected or formatted in `_onSemanticCrossed`, and
the rail's release velocity, ballistic input and geometry were already
density-independent. The first concrete divergence after the prepared pointer
lookup was therefore the LogBox render graph: the 24-row production bound
created 71 lazy-list children and an O(groups) paint walk. A fail-first widget
fixture reproduced that expansion before the render-boundary change.

The fix keeps every transaction row and day label but places a group's gap and
header inside its first transaction slot. Twenty-four rows are now exactly 24
lazy sliver children. The background painter binary-searches the first possibly
visible group and stops beyond the viewport. The viewport State,
`ScrollController`, sliver key, cache extent and prepared row identities remain
stable. No rail, controller, position, geometry or physics code changed.

## Final deterministic motion proof

Thirty identical scripted inputs per fixture currently produce:

| Measurement | Month/day empty/populated | Year/month empty/94-entry |
|---|---:|---:|
| release velocity | exact parity | exact parity |
| ballistic input | exact parity | exact parity |
| logical delta | 10 / 10 | 10 / 10 |
| pixel distance | 524.520179 / 524.520179 | 524.520179 / 524.520179 |
| activity interruptions | 0 / 0 | 0 / 0 |
| rail metric changes | 0 / 0 | 0 / 0 |

The year/month fixture uses the real bound of 24 prepared preview rows spread
across 24 day groups under a 94-entry month/658-entry year. Thirty identical
forward gestures on each side produced:

| Year/month apply evidence | Empty | 94-entry / 24-preview-row |
|---|---:|---:|
| release velocity | -2032.861194 px/s | -2032.861194 px/s |
| ballistic input | 2199.996612 px/s | 2199.996612 px/s |
| final logical delta | 10 | 10 |
| final pixel distance | 524.520179 px | 524.520179 px |
| apply p50 | 602 µs | 617 µs |
| apply p95 | 993 µs | 1110 µs |
| apply p99 | 1112 µs | 3759 µs |
| LogBox bind p95 | 489 µs | 380 µs |
| activity interruption | 0 | 0 |
| metric correction | 0 | 0 |

Forward and reverse runs have exact absolute velocity, 10-child endpoint and
524.520179-pixel-distance parity. The first and tenth runs also retain the same
velocity, endpoint, controller, position and physics identities. These are
debug/widget-harness microsecond measurements, not substitutes for the pending
profile-mode UI/raster artifact or a physical-device feel check.

## Temporal ownership root cause

The current navigation snapshot stores the same semantic time across six
mutable scalar/value fields:

- `yearCursor`;
- `monthCursor` (which also contains a year);
- `dayCursor`;
- `retainedChildYear`;
- `retainedChildMonth`;
- `retainedChildDay`.

Additional temporal copies/readers exist in:

- `DashboardVisibleFrame.queryKey`, `parentQueryKey` and semantic index;
- `DashboardCommittedState.committedScope/queryKey`;
- `DashboardMotionState.semanticIndex`;
- SummaryPill's merged navigation/visible-frame projection.

`DashboardNavigationController.planeCursorCandidate` currently selects among
the independent cursor and retained fields depending on plane and rail-open
state. `retainSettledChild` updates only one retained field (and only month/day
also partly update a cursor). Parent navigation updates a different subset.
Consequently the model has no single value whose epoch proves “this is the
latest semantic Y/M/D”. Tests cover individual transitions but not the user's
2024 → 2026 → immediate plane switch sequence or a stale callback racing it.

This was the structural temporal root cause: plane target derivation merged
independently retained values rather than projecting one canonical semantic
time.

## Canonical temporal navigation after the fix

`DashboardNavigationState` now stores one immutable
`DashboardTemporalAnchor`. Its derived accessors preserve existing callers, but
there are no longer six stored cursor/retained fields. The anchor owns Y/M/D,
source plane and parent/child keys, semantic child ordinal, direction,
filter/refinement identity, core revision and navigation epoch.

Every parent, plane, direction and rail-visibility candidate is derived from
that anchor and committed atomically with one new navigation epoch. Rail settle
only promotes semantic metadata and rejects a stale expected epoch; it emits no
visual notification. A source-boundary test prevents any other dashboard file
from becoming a second anchor writer and rejects async/timer/post-frame logic in
the navigation controller.

Deterministic tests prove:

- Year 2024 → Year 2026 → Month produces `month:2026-05` with one notification;
- settled May in Year produces Month 2026-05;
- Month 2026-07 → Year → Month returns to July;
- Year 2024 → SUM → Year returns to 2024;
- a stale settle epoch cannot overwrite the 2026 anchor;
- direction changes and open/closed rail states preserve the same temporal
  target.

There is no retry, post-frame correction, animation-completion write or
committed-query fallback.

## Frozen exclusions

The audit found no data-dependent input in carousel friction, velocity bands,
snap spring, item extent, controller identity, ScrollPosition identity or rail
viewport geometry. These files are frozen by hash for this work.

The final semantic diff from the milestone is empty for both dashboard rail
implementations and the entire `lib/shared/motion` centered-carousel module.
The controller/position, physics, math, metrics and prepared-index SHA-256
values remain exactly those listed above.

## Local verification

- full non-golden Flutter suite: **262/262 PASS**;
- Flutter analyzer: **PASS**, `No issues found! (ran in 133.0s)`;
- boundary/architecture tests: **PASS**;
- 30-run month/day and year/month density matrices: **PASS**;
- root/SummaryPill/rail/SVG crossing rebuild deltas: **0**;
- controller/physics/position recreation counts: **0**;
- motion-time SQL/repository/platform/format/projection counts: **0**;
- activity interruption and metric correction counts: **0**;
- golden tests created or run: **0**.
