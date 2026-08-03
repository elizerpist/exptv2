# Summary scope metrics implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to execute these tasks sequentially. Every production change begins with its failing test.

**Goal:** Publish SummaryPill amount and LogBox transaction count from one canonical, scope-identical metrics snapshot for parent, child-preview, and settled-child states.

**Architecture:** `DashboardSummaryMetricsController` remains the only derived presentation-state owner. It selects either a complete compatible `DashboardTimeChildSummaryIndex` bucket or a same-scope detailed result, then emits immutable `ScopeSummaryMetrics` and its single formatted `SummaryMetricsPresentation`. Widgets receive only the formatted value; Room retains one grouped `SUM`+`COUNT` query.

**Tech stack:** Flutter/Dart `ChangeNotifier`, Android Room/Kotlin `SimpleSQLiteQuery`, MethodChannel DTO, Flutter widget tests, Android in-memory Room tests.

## Global constraints

- Preview must use one O(1) child-index lookup and start zero detailed queries, watches, native subscriptions, or count-specific reads.
- A detailed result may only become parent metrics when `result.scopeKey` equals the current canonical query key.
- A missing bucket in a complete index is an explicit zero; an unavailable or incompatible index is loading/stale and never a mother fallback.
- No physics, haptic, rail gesture, query commit, or SummaryPill motion constant changes are permitted.
- SummaryPill and LogBox must consume the same `SummaryMetricsPresentation` instance.

---

### Task 1: Establish the failing metrics identity regressions

**Files:**
- Modify: `test/features/dashboard/application/dashboard_summary_amount_controller_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_header_test.dart`

**Produces:** tests for the exact day-21 amount/count fixture, complete-index zero buckets, cache-miss no-parent-fallback, and the one-presentation widget contract.

- [ ] Add a month parent fixture (`60000000`, `94`) and a day-21 child fixture (`1075384`, `4`). Open the rail, preload the index, preview day 21, and assert the sole emitted presentation has the day query key, `totalMinor == 1075384`, and `entryCount == 4`.
- [ ] Run the new test against the pre-refactor model; it must fail because `ScopeSummaryMetrics` and `SummaryMetricsPresentation` do not exist.
- [ ] Add a cache-miss test that changes the displayed child scope while the query retains a parent result; assert the result is loading/stale and neither parent total nor parent count is claimed for the child scope.
- [ ] Add a widget test that pumps SummaryPill and LogBox from one listenable and verifies both amount and count reflect the day-21 metrics snapshot.

### Task 2: Define the canonical metrics and formatted projection

**Files:**
- Create: `lib/features/dashboard/query/domain/scope_summary_metrics.dart`
- Create: `lib/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart`
- Modify: `lib/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart`
- Modify: imports that reference `summary_amount_presentation.dart`

**Consumes:** `CurrentLedgerQueryScope`, `DashboardLedgerResult`, and the existing amount formatter.

**Produces:** `ScopeSummaryMetrics`, `SummaryMetricsSource`, and `SummaryMetricsPresentation` with no independent amount/count projection.

- [ ] Implement immutable `ScopeSummaryMetrics` with the complete scope, canonical query key, revision, total, count, source, and state flags.
- [ ] Implement `SummaryMetricsPresentation.fromMetrics`, formatting both fields from the same value and rendering a loading placeholder rather than a false zero.
- [ ] Replace `SummaryPillPresenter.presentAmount` with `presentMetrics`, retaining the existing currency format policy but rejecting retained results whose query key differs from the current scope.
- [ ] Run the focused tests and make the new model tests pass.

### Task 3: Make the child index explicitly complete and metrics-safe

**Files:**
- Modify: `lib/features/dashboard/query/domain/time_child_summary.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviQueryModels.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Modify: `android/fluvi-core/src/test/kotlin/com/fluvi/core/query/FluviLedgerReadAndSnapshotTest.kt`
- Modify: `test/features/dashboard/query/method_channel_dashboard_ledger_repository_test.dart`

**Consumes:** the existing grouped child SQL predicate and DTO.

**Produces:** complete-index metadata and verified `SUM`+`COUNT` child bucket transport.

- [ ] Write the Room failing test for MonthScope(2026-03) / day 13 with parent (`66800000`, `94`) and child (`901489`, `4`), asserting both child fields originate in the grouped row.
- [ ] Expose `isComplete = true` from the atomic grouped index read through Kotlin, the channel map, and Dart decoding.
- [ ] Keep the existing `where(scope)` predicate and one grouped SQL query; do not create a count query.
- [ ] Run Android core tests and Dart bridge tests; assert the grouped child row carries both amount and count.

### Task 4: Replace the amount-named owner with one metrics emission path

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`

**Consumes:** Tasks 2 and 3.

**Produces:** atomic scope-safe parent/child metrics emissions and `D12 SUMMARY_METRICS_SELECTED` diagnostics.

- [ ] Write the failing transition tests for rail open, close, preview 20→21→22, and settle 21. They must assert one atomic amount/count state, zero preview watches, and exactly one settled detailed watch.
- [ ] Resolve `displayedMetricsScope` from closed parent or open `displayedChild`; use only a compatible complete index for child values.
- [ ] Produce explicit zero child metrics for absent complete-index buckets and atomic loading/stale metrics for cache misses.
- [ ] Replace every `SummaryAmountPresentation` publication with `SummaryMetricsPresentation`, compare all identity fields in deduplication, and emit one deduplicated `D12 SUMMARY_METRICS_SELECTED` event per selected metrics value.
- [ ] Run focused controller tests until all new regression tests pass.

### Task 5: Render the single metrics snapshot and prove isolation

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`
- Modify: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_header_test.dart`
- Modify: `test/boundary/fluvi_boundary_test.dart`

**Consumes:** `SummaryMetricsPresentation` from Task 2.

**Produces:** SummaryPill amount and LogBox count reading the same Listenable/snapshot without a presentation-to-repository dependency.

- [ ] Update widget signatures and builders to use `SummaryMetricsPresentation`.
- [ ] Keep the amount's preview direct replacement and all shell/text motion lanes untouched.
- [ ] Assert the LogBox debug event identifies the metrics source and selected child scope, and add the boundary assertion that presentation has no query/Room owner.
- [ ] Run focused widget and boundary tests.

### Task 6: Regression verification and delivery

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-03-summary-scope-metrics.md`

- [ ] Run Dart formatting and targeted Flutter tests for metrics, bridge, query, SummaryPill, LogBox, centered carousel, and boundary contracts.
- [ ] Run the Android in-memory Room core query suite in Ubuntu proot.
- [ ] Run `flutter analyze --no-fatal-infos` in Ubuntu proot and record any pre-existing diagnostics separately.
- [ ] Re-read the checklist, set each row to `DONE` only with recorded evidence, then commit implementation and checklist together.
- [ ] Push `refactor/fluvi-production`, monitor the GitHub debug-APK workflow to success, and download the release asset to `/storage/emulated/0/Download/fluvi/fluvi_<short-sha>.apk` without overwriting another build.

## Verification record

- Flutter test suite excluding golden tests: **221 passed** in Ubuntu proot.
- Flutter analysis: **passed** with three pre-existing informational diagnostics
  outside this feature's files.
- Flutter/core boundary script: **passed**.
- Android core test class: compiled, but all nine local Robolectric tests fail
  before test execution because Termux/ARM64 has no
  `conscrypt_openjdk_jni-linux-aarch_64`; the required GitHub Ubuntu workflow
  executes the same Room suite before the APK build.
- GitHub Actions run `30773384060`: **passed** Flutter analysis/tests, clean
  Room core tests, native dashboard bridge tests, and the debug APK build.
