# Budget scope rhythm and presentation refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rolling Partner rhythm with a prepared, scope-aware eight-part Spending Rhythm chart, and add the accepted SUM, Header and upper-card presentation/gesture behavior without changing protected Budget semantics.

**Architecture:** Native preparation retains timestamp-faithful target-indexed daily totals and eight three-hour totals. A clock-free Dart projector derives typed DAY/MONTH/YEAR/SUM analyses from the exact visible scope. Partner gets its own full-width composition; ring, Header and gestures extend small existing owners instead of adding widget-local state.

**Tech Stack:** Flutter/Dart immutable presentation contracts, Kotlin/Room prepared acquisition, versioned binary transport, Flutter/Kotlin tests, GitHub Actions Android delivery.

## Global Constraints

- Baseline: `3127abc018ddea7694661e25015790dcd773bf9e`; preserve the unrelated `docs/prototypes/category_palette_variation_lab.html` change.
- Do not change DAY pace, MONTH utilization, YEAR cells, SUM typical ratio, financial-limit ownership, temporal navigation, Summary behavior, LogBox controller/position, or Header expansion geometry.
- DAY rhythm has exactly eight local 3-hour buckets: Éjfél, Hajnal, Reggel, Délelőtt, Kora délután, Délután, Este, Késő este.
- No rolling clock/window, `last N` history, repository call from a widget, LogBox-row aggregation, or paint-time aggregation.
- Existing authored rhythm track width `11.0` is the max-width source; its value must not change silently.
- Flutter production work follows red-green-refactor. Run Flutter in Ubuntu proot only. Android APK builds run in GitHub Actions and the normal human APK is downloaded after push.

## File structure and responsibilities

| File | Responsibility |
| --- | --- |
| `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviPreparedSpendingRhythmSnapshot.kt` | native 3-hour classifier and immutable indexed facts |
| `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviBudgetReadService.kt` | one timestamp-aware prepared acquisition |
| native Dashboard binary codec | version-5 writer matching Dart byte order |
| `lib/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart` | Dart validated immutable bank and no-copy target view |
| `lib/features/dashboard/runtime/data/prepared_budget_limit_snapshot_binary_codec.dart` | version-5 reader and fail-closed validation |
| `lib/features/dashboard/application/dashboard_spending_rhythm_controller.dart` | pure scope projector and visible-frame publication |
| `lib/features/dashboard/presentation/core_modes/spending_rhythm_bar_layout.dart` | pure width, gap, pitch and scroll solver |
| `lib/features/dashboard/presentation/core_modes/spending_rhythm_bar_chart.dart` | rendering, x-axis and average visual only |
| `lib/features/dashboard/presentation/core_modes/budget_partner_distribution_card.dart` | Partner-specific upper/lower full-width composition |
| `lib/core/financial_limits/presentation/budget_ring_presentation.dart` | SUM style and healthy-colour setting owner |
| `lib/features/dashboard/presentation/core_modes/dashboard_header_contrast_text.dart` | one Header text contrast primitive |
| `lib/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator.dart` | one pointer-sequence gesture arbiter and handoff owner |

### Task 1: Establish the indexed 8-part rhythm contract

**Files:**
- Create Kotlin `FluviPreparedSpendingRhythmSnapshot.kt` and its JUnit test in `android/fluvi-core/src/test/kotlin/com/fluvi/core/query/FluviPreparedSpendingRhythmSnapshotTest.kt`.
- Create Dart `prepared_spending_rhythm_snapshot.dart` and `test/features/dashboard/runtime/prepared_spending_rhythm_snapshot_test.dart`.
- Modify `prepared_budget_limit_snapshot.dart` and `test/boundary/budget_category_distribution_boundary_test.dart`.
- Delete old `prepared_budget_rhythm_snapshot.dart` only after consumers are migrated.

**Produces:**

```dart
enum SpendingRhythmDayPart { midnight, dawn, morning, lateMorning,
  earlyAfternoon, afternoon, evening, lateEvening }

final class PreparedSpendingRhythmDirectionBank {
  PreparedSpendingRhythmDirectionBank({required int targetCount,
    required List<int> targetOffsets, required List<int> epochDays,
    required List<int> dailyActualScaled100,
    required List<int> dayPartActualScaled100});
  PreparedSpendingRhythmTargetView targetView(int targetHandle);
}
```

- [ ] **Step 1: Write failing contract tests.** Test exact ordinal/label order, all boundary minutes (`0`, `179`, `180`, …, `1439`), invalid offsets and vectors, strict per-target epoch ordering, and `daily == sum(eight parts)`.

```dart
test('prepared day rejects a daily total unequal to its eight parts', () {
  expect(() => PreparedSpendingRhythmDirectionBank(
    targetCount: 1, targetOffsets: const [0, 1], epochDays: const [20],
    dailyActualScaled100: const [99],
    dayPartActualScaled100: const [10, 10, 10, 10, 10, 10, 10, 10],
  ), throwsArgumentError);
});
```

- [ ] **Step 2: Verify RED.** Run `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/runtime/prepared_spending_rhythm_snapshot_test.dart'`. Expect missing-contract failure.

- [ ] **Step 3: Implement the contract.** Kotlin classifies `booked_local_time_minutes / 180` exactly once. Both runtimes use target offsets plus flat `epochDays`, `dailyActuals`, and `pointIndex * 8 + ordinal` data. Dart target views hold ranges, not `sublist` copies.

- [ ] **Step 4: Add a red boundary test and then make it green.** The presentation layer may import only immutable rhythm contracts/controllers; native/repository imports and a second rhythm controller/projector fail the test.

- [ ] **Step 5: Run GREEN checks.** Run the new Dart test, Kotlin JUnit class, and boundary test. Commit `refactor(budget): add prepared spending rhythm contract`.

### Task 2: Replace day-only native facts and binary payload atomically

**Files:**
- Modify Kotlin `FluviBudgetReadService.kt`, `FluviPreparedBudgetLimitSnapshot.kt`, and the native Dashboard codec identified by `rg 'BUDGET_LIMIT_VERSION|DashboardBinaryCodec' android/fluvi-core/src/main/kotlin`.
- Modify Dart `prepared_budget_limit_snapshot_binary_codec.dart`, `prepared_budget_limit_snapshot.dart`, and codec tests.
- Modify `FluviPreparedDashboardIndexTest.kt`.

**Consumes:** Task 1 bank invariants. **Produces:** payload version `5`, with each direction serialized as `targetCount`, offsets, point count, then `epochDay`, daily actual, eight ordered int64 values per point.

- [ ] **Step 1: Write failing Dart codec tests.** Decode a version-5 fixture with four amounts crossing 02:59/03:00 and 20:59/21:00. Reject version 4, trailing bytes, target mismatch, invalid offset, invalid daily/parts sum and bytes above the calculated fixed-record payload limit.
- [ ] **Step 2: Verify RED.** Run the focused Flutter codec test in proot; expect the current version-4 reader to fail.
- [ ] **Step 3: Write failing native acquisition test.** Seed one category's local-day transactions at 02:59, 03:00, 20:59, and 21:00. Assert aggregate and category target records have amounts in ordinals 0, 1, 6, 7 and no values in the others.
- [ ] **Step 4: Verify native RED.** Run `cd android/fluvi-core && ./gradlew test --tests com.fluvi.core.query.FluviPreparedDashboardIndexTest`; current grouped-day query cannot pass.
- [ ] **Step 5: Implement one prepared acquisition.** Retain `booked_local_time_minutes` in the grouped native query, classify while accumulating the existing aggregate and category target handles, and freeze sorted compact day records. Do not add a second Room query.
- [ ] **Step 6: Implement codec parity.** Bump both writers/readers to `5`; calculate maximum point count from `maximumPayloadBytes` and the exact fixed record size before allocating. Validate count, offsets, sort order, target domain, non-negative values and daily/part equality.
- [ ] **Step 7: Verify GREEN.** Run Dart codec, prepared snapshot, Kotlin index and native ledger snapshot tests. Commit `refactor(budget): prepare timestamp-faithful rhythm facts`.

### Task 3: Replace the rolling controller with a typed, clock-free scope projector

**Files:**
- Create `lib/features/dashboard/application/dashboard_spending_rhythm_controller.dart` and test.
- Modify `core_dashboard.dart` and rhythm state consumers.
- Delete `dashboard_budget_rhythm_controller.dart` and its old test after migration.

**Produces:**

```dart
sealed class SpendingRhythmAnalysis { const SpendingRhythmAnalysis(); }
final class DaySpendingRhythm extends SpendingRhythmAnalysis {}
final class MonthSpendingRhythm extends SpendingRhythmAnalysis {}
final class YearSpendingRhythm extends SpendingRhythmAnalysis {}
final class SumSpendingRhythm extends SpendingRhythmAnalysis {}
final class UnavailableSpendingRhythm extends SpendingRhythmAnalysis {}

abstract final class DashboardSpendingRhythmProjector {
  static SpendingRhythmAnalysis project({required PreparedSpendingRhythmSnapshot snapshot,
    required LedgerDirection direction, required int targetHandle,
    required LedgerTimeScope scope});
}
```

- [ ] **Step 1: Write failing analysis tests.** With logical today in 2026 and fixture data in March 2022, assert DAY has eight selected-day bars, MONTH is March 1–31 with zeroes, YEAR is Jan–Dec 2022, and SUM is the continuous historic year range with internal zeroes. Assert rolling window/title fields do not appear in new public state.
- [ ] **Step 2: Verify RED.** Run `dashboard_spending_rhythm_controller_test.dart` in proot; expected missing type/projector error.
- [ ] **Step 3: Implement bounded analysis.** Binary-bound target day records. Materialize DAY/MONTH slots, derive exactly twelve YEAR totals and compact SUM year totals, never scanning a repository. Return `UnavailableSpendingRhythm` for absent data rather than inventing future years.
- [ ] **Step 4: Implement publication.** Listen to existing Budget selection, navigation and visible frame. Use exact `frame.scope` before settled navigation, retain current target colour source, publish immutable state, and remove clock/timer/rollover diagnostics.
- [ ] **Step 5: Write RED visible-frame tests.** Assert every accepted temporal and target crossing publishes prepared analysis without a repository callback; stale revision/domain produces unavailable state.
- [ ] **Step 6: Verify GREEN.** Run new controller test, Budget presentation tests and visible-frame/cache suite. Commit `refactor(budget): project spending rhythm by active scope`.

### Task 4: Build tested chart geometry and rendering

**Files:**
- Create `spending_rhythm_bar_layout.dart`, `spending_rhythm_bar_chart.dart`, and their two presentation tests.
- Delete old `budget_rhythm_bar_chart.dart` and its test after usage migration.

**Produces:**

```dart
final class SpendingRhythmBarLayout {
  static const double maxBarWidth = 11.0;
  static SpendingRhythmBarLayout resolve({required double availableWidth,
    required int barCount, required bool allowsHorizontalScroll});
  final double barWidth, gap, pitch, contentWidth;
  final bool scrollsHorizontally;
}
```

- [ ] **Step 1: Write solver RED tests.** Pin `11.0` to the former authored width. At measured minimum usable Partner width assert the corrected 8-part DAY chart remains 11; 12/28/29/30/31 fit with `min <= width <= 11` and equal non-negative gaps; 31 never scrolls; SUM 32 remains at min with content wider than viewport.
- [ ] **Step 2: Verify RED.** Run the layout test in proot; expected unresolved solver.
- [ ] **Step 3: Implement explicit layout tokens.** Measure actual Partner minimum inner width from constraints. Select a named minimum inter-bar visual gap, derive `minBarWidth = (minimumWidth - 30*minGap)/31`, assert positive, then implement documented fit/clamp/equal-gap math. SUM >31 freezes 31-slot pitch and uses all bars for extent.
- [ ] **Step 4: Write chart RED tests.** For values 5k/20k/10k/0 expect `.25/1/.5/0`, mean 8.75k and average fraction .4375; all-zero has no average. Check DAY labels, MONTH `1/5/10/15/20/25/last`, YEAR Jan–Dec and concrete moving SUM year labels.
- [ ] **Step 5: Implement chart GREEN.** Render immutable bars, one subtle average reference and semantics. Use one persistent horizontal controller only for SUM >31; x labels travel with its content. No aggregation or `TextPainter` in paint.
- [ ] **Step 6: Inspect a focused visual golden/screenshot and commit `feat(budget): render scope-aware spending rhythm bars`.**

### Task 5: Give Partner a separate full-width rhythm composition

**Files:**
- Create `budget_distribution_legend_list.dart`.
- Modify `budget_partner_distribution_card.dart`, `budget_distribution_page_surface.dart`, `budget_distribution_pager.dart`, and their tests.

**Consumes:** Task 4 chart. **Rule:** Category stays a current `BudgetDistributionPageSurface` client; no Partner-layout flag matrix.

- [ ] **Step 1: Write failing geometry tests.** Assert Partner lower chart equals usable card inner width, not donut column width; has positive plot height; card outer height/donut/row typography are unchanged; Category's original surface constraints stay unchanged.
- [ ] **Step 2: Verify RED.** Run Partner/card pager tests in proot; current narrow `leftFooter` fails bounds assertion.
- [ ] **Step 3: Extract one neutral legend/list primitive.** Retain one list controller, row interaction and donut interaction. Compose Partner as upper donut+scrollable legend plus lower full-width chart, reducing only list viewport.
- [ ] **Step 4: Wire `DashboardSpendingRhythmState` from CoreDashboard through pager.** Remove old chart/controller imports and prove Partner row selection remains a list state rather than chart-key change.
- [ ] **Step 5: Verify GREEN with Partner, chart and Category regression suites; inspect Partner visual state.** Commit `refactor(budget): give partner rhythm full card width`.

### Task 6: Add independent SUM ring settings and healthy material resolver

**Files:**
- Create `dashboard_budget_ring_presentation.dart`, `dashboard_budget_ring_presentation_controller.dart`, and controller test.
- Modify `core_dashboard.dart`, `dashboard_header_visual_tuner.dart`, `budget_category_avatar_artwork.dart`, and selected-avatar tests.

**Produces:**

```dart
enum BudgetSumRingStyle { current, coloredScaleWhiteArc, coloredScaleMovingSphere }
enum BudgetHealthyColorMode { fixedGreen, targetAccent }
final class BudgetHealthyVisualColorResolver {
  static Color resolve({required BudgetHealthyColorMode mode,
    required Color targetAccent});
}
```

- [ ] **Step 1: Write settings RED tests.** Exact enum catalogue, current/fixed-green defaults, equality/copy/reset, healthy target accent only for YEAR/SUM, unchanged DAY/MONTH semantics.
- [ ] **Step 2: Verify RED and implement owner.** Inject it from CoreDashboard; tuner uses controller only, painter receives resolved state.
- [ ] **Step 3: Write ring strategy RED tests.** Coloured styles use canonical clockwise ring coordinate and a named smooth .75/.90 blend; spheres are white, on `trackRadius`, exactly at .75/.90; Style B has one white arc/no sphere, Style C one sphere/no arc; raw ratio stays unbounded.
- [ ] **Step 4: Implement strategies/materials.** Keep `current` code path unchanged. Paint coloured track → moving value → references, use hue-preserving healthy material in YEAR and SUM only, and no .50 new-style sphere.
- [ ] **Step 5: Verify GREEN with DAY/MONTH/YEAR/SUM ring regressions and focused raster.** Commit `feat(budget): add selectable sum ring presentations`.

### Task 7: Add Header contour and centralized contrast primitive

**Files:**
- Create `dashboard_header_contrast_text.dart` and widget test.
- Modify `dashboard_budget_header_presentation.dart`, `budget_allocation_partition_lane.dart`, `budget_dashboard_core_surface.dart`, tuner and Header tests.

**Produces:**

```dart
enum DashboardHeaderTextContrastStyle { none, hardOppositeShadow, oppositeOutline }
final class DashboardHeaderContrastText extends StatelessWidget {
  const DashboardHeaderContrastText({required String data, required TextStyle style,
    required Color foreground, required DashboardHeaderTextContrastStyle contrastStyle});
}
```

- [ ] **Step 1: Write settings RED tests.** Default contour false/contrast none; `copyWith`, equality/hash and reset retain independent foreground and partition values.
- [ ] **Step 2: Write visual contract RED test matrix.** White/black x none/shadow/outline must resolve exact opposite shadow/stroke, leave width/baseline/value unchanged and announce text once.
- [ ] **Step 3: Verify RED.** Run contrast and visual-tuner tests in proot.
- [ ] **Step 4: Implement primitive and Header wiring.** One named sharp opposing shadow; outline uses a semantics-excluded stroke Text behind semantic fill. Apply only selected Budget Header textual family.
- [ ] **Step 5: Implement contour.** Reuse the lane's outer `RRect`, draw one thin white stroke after fills, never per partition, never changing bounds. Test thickness 0/50/100.
- [ ] **Step 6: Verify GREEN and commit `feat(dashboard): add header contrast and partition contour`.**

### Task 8: Make upper content-card gestures true pointer owners

**Files:**
- Modify `dashboard_upper_vertical_gesture_coordinator.dart`, `dashboard_core_mode_host.dart`, `budget_distribution_page_surface.dart`, `budget_partner_distribution_card.dart`, and equivalent Balance/Mind surfaces.
- Modify coordinator test and create `dashboard_upper_content_gesture_test.dart`.

**Produces:**

```dart
enum DashboardUpperPointerOutcome { undecided, headerDrag, childScroll,
  childHorizontal, childTap, cancelled }
```

- [ ] **Step 1: Write real-pointer RED tests.** Capture Header/handler reference expansion. Drag same delta/velocity on Partner heading, donut whitespace, empty card, lower chart and Balance/Mind background, in both working physical directions.
- [ ] **Step 2: Add conflict RED tests.** Donut/row taps work; scrollable list consumes while it has range; same pointer's residual overscroll crosses into Header; controller/position identities and offset remain. SUM strong horizontal chart drag wins; chart vertical drag expands; avatar/PageView/Summary selectors stay protected.
- [ ] **Step 3: Verify RED.** Run new content gesture and coordinator tests. Current list-only overscroll route must fail whitespace/card checks.
- [ ] **Step 4: Implement one arena-aware background adapter.** Parent surfaces join the arena behind interactive children, choose a vertical Header outcome after tap slop and forward to existing expansion mapping. Never put opaque detector above children. Coordinator records per-pointer outcome/cancellation but keeps one `DashboardExpansionController`.
- [ ] **Step 5: Implement same-pointer boundary handoff.** Child scroll consumes normal deltas; only overscroll residual enters coordinator. Reset ownership on end/cancel/new input and never recreate scroll owner.
- [ ] **Step 6: Verify GREEN conflict matrix and protected Summary/Header tests.** Commit `fix(dashboard): complete upper content gesture handoff`.

### Task 9: Document, verify, push and deliver

**Files:** update the accepted spec, active checklist and this plan checkboxes.

- [ ] **Step 1: Record factual final evidence.** Include actual native classifier/query path, codec byte accounting/version, measured `minGap`/minimum width/min width, old rolling paths, SUM blend/material policy, exact Header metrics and gesture hit route.
- [ ] **Step 2: Run focused suites in proot.** Run runtime, scope projector, chart layout/chart, ring, Header, content-gesture and Partner composition suites.
- [ ] **Step 3: Run protected checks.** Run `flutter test test/boundary test/features/dashboard/presentation`, `flutter analyze` in proot, native relevant Gradle tests and `git diff --check`.
- [ ] **Step 4: Inspect changed visual evidence.** SUM styles and full-width Partner chart are inspected; physical Android items are only marked after device evidence.
- [ ] **Step 5: Reread checklist and final diff.** Every item is DONE or explicitly deferred; pre-existing prototype work remains untouched.
- [ ] **Step 6: Commit final documentation if not already part of a buildable commit.** Use `docs(dashboard): record spending rhythm refactor delivery`.
- [ ] **Step 7: Push and complete human APK delivery.** Push `separated-core-modes`, monitor the exact SHA GitHub Actions job, download normal `lib/main.dart` human APK to `/storage/emulated/0/Download/fluvi`, verify it exists, and report its SHA-256.

## Plan self-review

| Requirement group | Implementation tasks |
| --- | --- |
| Robust prepared 8×3h data and codec | 1–2 |
| Scope semantics, no rolling, preview publication | 3 |
| Chart layout, labels, normalization and full-width Partner card | 4–5 |
| SUM styles and healthy-colour policy | 6 |
| Header contour and contrast | 7 |
| Physical upper-card gesture ownership/handoff | 8 |
| Documentation, regression verification and APK delivery | 9 |

The plan contains no widget-local data workflow, duplicate gesture state machine, second ring asset, or alternate persistence source. Every new visual constant is a named measured token, and every later interface is produced by an earlier task.
