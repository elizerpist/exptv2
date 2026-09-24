# Fixed Balance carousel and whole-HUF presentation Implementation Plan

> **For agentic workers:** Execute inline, task-by-task with a witnessed RED →
> GREEN cycle. These tasks share `balance_dashboard_core_surface.dart` and the
> focused production-parent fixture, so parallel implementation would create
> conflicting geometry and widget state.

**Goal:** Replace experimental Balance rail geometry with a fixed,
outer-edge-preserving production layout; finalize the compact Latest card;
reduce Balance palettes; use whole HUF for exact monetary text; and make the
Balance Header value occupy Mind's primary metric lane.

**Architecture:** Keep `CenteredCarousel` as the only motion/gesture owner.
Derive fixed Balance geometry locally from constraint and existing vertical
layout geometry, not user settings or screenshot pixels. Keep exact HUF in the
central formatter and preserve independent compact formatters. Put shared
header primary-value metrics in the existing neutral trend visual token.

**Tech stack:** Flutter/Dart, existing `flutter_test`, GitHub Actions normal
human APK workflow, SCIP Dart 1.6.2 codegraph tooling.

## Global constraints

- No repository/Query/index/scene work from widgets or setting changes.
- No new ticker, timer, controller, ScrollPosition, physics, or palette engine.
- Do not modify shared `CenteredCarousel`, Balance financial projection,
  Summary/Query, Movers/topic order, Budget/Mind semantics or global geometry.
- Exact HUF has no fractional suffix; compact `k`/`M` values may retain a
  decimal comma.
- Preserve `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` as the interaction floor.
- Final device status remains `PENDING — USER ONLY`.

---

### Task 1: Capture and lock the carousel contract

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `test/features/dashboard/presentation/balance_presentation_settings_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`

**Interfaces:**
- Consumes the current `.30` / `0` pre-change test fixture only to freeze
  outer-edge baseline measurements.
- Produces a settings model with only `chartMode`, `timeLabels`, `revision`;
  and a Balance-local immutable geometry calculation supplied to the existing
  `CenteredCarouselSpec`.

- [x] Write a production-parent RED test that renders the legacy max/zero
  baseline and final fixed geometry at reference, narrow and wide constraints;
  assert selected width increases, its center stays centered, side outer edges
  stay equal to baseline, symmetric inner gaps equal the actual Summary→card
  vertical gap, and cards do not overlap.
- [x] Run the focused test against unmodified source and record the missing
  fixed-width/gap assertion as RED.
- [x] Write RED tests that reject geometry fields/setters and two tuner keys,
  while retaining chart/time settings and controls.
- [x] Run settings/tuner tests and record the obsolete state/control failure.
- [x] Implement the smallest Balance-local fixed resolver. Its inputs are
  production constraint/layout values; it must solve card width and item extent
  simultaneously from fixed-side-edge and target-gap invariants rather than a
  replacement width percentage. Retire geometry settings/setters/sliders.
- [x] Add hit-test and semantics assertions for gained visible card space;
  retain CenteredCarousel controller/ScrollPosition/motion identity tests.
- [x] Re-run focused settings/surface/tuner tests until GREEN.

### Task 2: Finalize selected Latest compact hierarchy

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`

**Interfaces:**
- Consumes `DashboardBalanceScopedTransaction` and `BalanceCategoryVisualBadge`.
- Produces a Latest-specific selected renderer with exactly two rows; side-card
  renderer and lower Latest renderer remain unchanged.

- [x] Write a mounted RED test requiring `Utolsó tranzakció`, a white receipt
  icon inside a circle derived from an existing Balance/Fluvi accent, top-biased
  header row and larger-than-18px/labelMedium primary row.
- [x] Assert no `balance-carousel-latest-inline-date`, no date/time/amount text
  in selected Latest, exactly two visible rows, no overflow, and preserved
  rounded-square category badge.
- [x] Run the focused widget test and record the rejected current title/date
  contract as RED.
- [x] Implement the local Latest composition without changing generic carousel
  card padding or shared mechanics; use an existing semantic accent token.
- [x] Re-run selected/compact/large Latest regression tests to GREEN.

### Task 3: Reduce catalog to four palette families

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_balance_palette_catalog_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

**Interfaces:**
- Consumes existing `DashboardBalanceHeaderPalette` / variant catalog and
  session-lifetime visual tuning.
- Produces exactly four enum/catalog selector choices × three variants.

- [x] Source-audit enum serialization, codec, preferences, JSON/database and
  `palette.name` use. Record whether selection is session-only before deletion.
- [x] Write RED catalog/tuner tests for the four named families, three variants,
  twelve combinations and complete exact literal arrays for all surviving
  original/saturated/vivid scales.
- [x] Run RED tests; current 11/33 expectation must fail for cardinality.
- [x] Delete only the seven inactive enum/catalog/label/switch entries and
  update active source comments/tests; leave historical documents unchanged.
- [x] Re-run catalog/controller/policy/tuner tests to GREEN and audit no active
  removed enum use remains.

### Task 4: Establish exact whole-HUF formatting

**Files:**
- Modify: `lib/features/dashboard/prepared/data/dashboard_prepared_formatter.dart`
- Modify: tests proven by the source-wide HUF audit, beginning with
  `test/features/dashboard/prepared/data/dashboard_prepared_formatter_test.dart`
- Modify: representative existing Balance/Budget/Mind/Summary/LogBox/Query
  presentation tests only where their exact rendered expectation changes.

**Interfaces:**
- Consumes existing scaled-100 domain amounts.
- Produces whole-HUF exact strings from `DashboardPreparedFormatter.amountMinor`
  and retains `amountMinorPerDay` suffix behavior.

- [x] Run and record source-wide `rg` inventory for exact-money call sites,
  literal `Ft/HUF`, decimal construction and compact formatters; classify each
  as exact, compact, non-money or test/debug.
- [x] Inspect domain/import/test precedent for sub-forint values; use the
  established Query major-unit `~/ 100` policy if production values permit
  them, rather than inventing a rounding policy.
- [x] Write formatter RED expectations for zero, positive, negative, large and
  per-day values without fractions; add representative mode tests and a compact
  decimal preservation test.
- [x] Run the tests and observe the old `,00 Ft` output as RED.
- [x] Replace only central exact fraction construction with the source-proven
  whole-unit policy; update affected presentation expectations; do not alter
  compact k/M or non-money decimal paths.
- [x] Re-run targeted mode tests to GREEN and repeat residual audit, classifying
  every remaining decimal HUF match.

### Task 5: Share Balance/Mind Header primary metrics

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: relevant existing Balance/Mind Header widget tests.

**Interfaces:**
- Produces one Header-local `TextStyle` metric contract: 19px, .96 height,
  -.76 tracking, w900; callers inject selected typography profile/color.

- [x] Write a mounted RED test finding `balance-header-net-amount` and
  `mind-header-score-text`, asserting equal left/top, font size, height,
  letter spacing and weight while preserving respective values/colors.
- [x] Run test against existing source and record Balance's current titleMedium
  / w700 mismatch as RED.
- [x] Add the smallest neutral shared token in the trend visual kernel and make
  both surfaces apply it with their existing frame/profile/color paths.
- [x] Re-run Balance/Mind Header tests to GREEN; verify max-line/ellipsis
  protection remains on Balance.

### Task 6: Final verification, delivery and evidence

**Files:**
- Modify after app commit only: `docs/FLUVI_ENGINEERING_JOURNAL.md`
- Tooling worktree only: final `docs/codegraph/*` artifacts.

- [ ] Re-read this checklist and all relevant visual/user contracts. Update
  every acceptance status truthfully; do not build if an app requirement is
  incomplete.
- [ ] Run focused Balance settings/surface/tuner/palette, prepared formatter,
  Balance/Budget/Mind/Summary/LogBox/Query and protected carousel tests in
  Ubuntu proot; then fast suite, analyzer, format check, and `git diff --check`.
- [ ] Review `git diff --stat` and full diff, make one atomic application commit
  with exact evidence/limitations, and push it.
- [ ] Monitor GitHub Actions for that exact SHA, require normal human APK job,
  download `/storage/emulated/0/Download/fluvi/<apk>`, verify file/hash and
  embedded `FLUVI_BUILD_COMMIT`; classify profile separately.
- [ ] Regenerate SCIP from a detached exact-source worktree; prove manifest
  `source_head` equals application SHA; test and commit/push tooling separately.
- [ ] Append factual evidence to the journal in a docs-only `[skip ci]` commit
  after application build/graph evidence, push without starting a new build.
