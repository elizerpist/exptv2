# Dashboard rail continuity repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` for this
> tightly coupled sequence. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate startup self-scroll and every transient empty/`—` rail
frame without altering the shared centered-carousel milestone behaviour.

**Architecture:** The dashboard render adapter owns whether a rail viewport
exists; a complete `DashboardParentDisplayBundle` owns every finite tick's
immutable content; the summary and LogBox coordinators project that same deck
for both preview and settled child states. The core stages direction changes
until a target deck and exact committed first page are ready.

**Tech Stack:** Flutter/Dart `ChangeNotifier`, existing immutable display
bundles, `flutter_test`, Ubuntu-proot Flutter verification, GitHub Actions.

## Global Constraints

- Restore the shared carousel implementation to `5b71141`; do not change its
  physics, haptic, snap, rebasing or callback behaviour.
- A normal finite rail tick performs no I/O, no cache mutation and no
  formatting/projection work.
- An explicit empty deck snapshot is immediate valid content, never a loading
  state.
- Run Flutter commands only inside Ubuntu proot; do not build an APK locally.
- Do not reset, checkout or overwrite unrelated work.

## File map

| File | Responsibility |
| --- | --- |
| `lib/shared/motion/centered_carousel/centered_carousel.dart` | Milestone viewport recenter behaviour. |
| `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | Milestone selection/scroll lifecycle. |
| `lib/features/dashboard/presentation/core_dashboard.dart` | Dashboard-owned lifecycle boundary for the rail widget. |
| `lib/features/dashboard/application/dashboard_core_controller.dart` | Finite-deck rail eligibility and staged direction transition. |
| `lib/features/dashboard/application/dashboard_summary_amount_controller.dart` | Exact deck metrics and concrete-state continuity guard. |
| `lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart` | Exact deck LogBox projection for preview and settled child. |
| Dashboard presentation/application/logbox tests | Regressions for physical mount, atomic snapshots and multi-tick flings. |

### Task 1: Restore the milestone rail engine and move bootstrap safety to the dashboard boundary

**Files:**

- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Test: `test/features/dashboard/widgets/time_refinement_rail_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`

**Consumes:** `DashboardVisualFrame.railReveal`,
`DashboardTimeNavigationController.isRailOpen`, and existing
`TimeRefinementRail` callbacks.

**Produces:** A rail viewport only when `railReveal > 0`; the hidden startup
tree contains no `TimeRefinementRail`.

- [ ] **Step 1: Write failing lifecycle regressions.**

  Replace the closed-mounted-rail expectation with an absence assertion and
  add this dashboard test shape:

  ```dart
  expect(find.byType(TimeRefinementRail), findsNothing);
  expect(controller.rail.state.navigationRevision, 0);
  expect(controller.rail.state.previewChild, isNull);
  controller.rail.setRailOpen(true);
  await tester.pump(const Duration(milliseconds: 32));
  expect(find.byType(TimeRefinementRail), findsOneWidget);
  ```

- [ ] **Step 2: Run the focused tests red.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart'
  ```

  Expected: failure because the closed tree still contains `TimeRefinementRail`.

- [ ] **Step 3: Restore and isolate.**

  Restore both shared carousel files exactly from `5b71141` with a controlled
  patch. In `CoreDashboard`, replace the unconditional rail child with this
  render-only lifecycle gate, preserving the fade and pointer policy:

  ```dart
  child: frame.railReveal > 0
      ? Opacity(
          opacity: frame.railReveal,
          child: IgnorePointer(
            ignoring: !geometry.isRailExpanded,
            child: _DashboardRenderProbeBoundary(
              onBuild: widget.renderRebuildProbe?.didBuildRailShell,
              child: TimeRefinementRail(/* existing arguments unchanged */),
            ),
          ),
        )
      : const SizedBox.shrink(),
  ```

  Do not add a callback gate or a different scroll command to the shared
  engine.

- [ ] **Step 4: Run focused tests green and check milestone parity.**

  Run the command from Step 2 plus:

  ```sh
  git diff --exit-code 5b71141 -- lib/shared/motion/centered_carousel/centered_carousel.dart lib/shared/motion/centered_carousel/centered_carousel_controller.dart
  ```

  Expected: tests pass and diff exits `0`.

- [ ] **Step 5: Commit the independently testable rail-boundary change.**

  ```sh
  git add lib/shared/motion/centered_carousel lib/features/dashboard/presentation/core_dashboard.dart test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart
  git commit -m 'fix(dashboard): isolate hidden rail viewport'
  ```

### Task 2: Make the complete finite deck the immediate source for preview and settle

**Files:**

- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart`
- Test: `test/features/dashboard/application/dashboard_summary_amount_controller_test.dart`
- Test: `test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart`

**Consumes:** `DashboardParentDisplayBundleController.previewFor`,
`ScopeSummaryMetrics` with `childPreviewIndex` or `childSettledIndex`, and
the existing `DashboardLogPreviewSnapshot` view models.

**Produces:** Concrete exact summary and LogBox state at every finite logical
child; no visible loading state replaces a concrete snapshot.

- [ ] **Step 1: Write failing multi-tick and settle regressions.**

  Build a complete month deck for five days and drive metrics through five
  child preview scopes followed by a settled scope. Assert every observer
  state contains its target key, non-null amount/count and either
  `DashboardLogData` or `DashboardLogEmpty`:

  ```dart
  expect(observedMetricKeys, orderedEquals(targetKeys));
  expect(observedMetricValues.every((value) => value != null), isTrue);
  expect(observedLogStates, isNot(contains(isA<DashboardLogPreviewLoading>())));
  ```

  Add a cold-target regression that first supplies a concrete prior state,
  withholds the target deck, then supplies it; assert the visible state is
  prior-or-target concrete content only.

- [ ] **Step 2: Run the named tests red.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/application/dashboard_summary_amount_controller_test.dart test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart'
  ```

  Expected: current cache-miss tests observe `—` and
  `DashboardLogPreviewLoading`.

- [ ] **Step 3: Implement one deck-projection predicate and continuity guard.**

  Keep the established owners. Define a private predicate in the LogBox
  coordinator for both finite deck sources:

  ```dart
  bool _isDeckProjection(ScopeSummaryMetrics metrics) =>
      metrics.source == SummaryMetricsSource.childPreviewIndex ||
      metrics.source == SummaryMetricsSource.childSettledIndex;
  ```

  Use `previewBundles.previewFor(metrics.scope)` for either source and keep
  that state active through a matching committed-query load. When no exact
  deck snapshot exists, publish loading only if no concrete visible state
  exists; otherwise retain the previous immutable state and log the
  diagnostic without notification. Apply the equivalent rule to summary
  metrics: only publish `_loadingMetricsForScope` when no concrete metrics
  have been rendered. Never mutate its scope/key to impersonate the target.

- [ ] **Step 4: Run focused tests green.**

  Run the command from Step 2. Expected: all exact deck crossings and the
  settled promotion have concrete values; only a first-ever cold screen may
  use initial loading.

- [ ] **Step 5: Commit the application-layer projection change.**

  ```sh
  git add lib/features/dashboard/application/dashboard_summary_amount_controller.dart lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart test/features/dashboard/application/dashboard_summary_amount_controller_test.dart test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart
  git commit -m 'fix(dashboard): keep finite rail snapshots continuous'
  ```

### Task 3: Stage direction changes behind a complete deck and exact first page

**Files:**

- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`

**Consumes:** `TransactionDirectionController`, finite-bundle request helpers,
`DashboardParentDisplayBundleController.prewarmFiniteBundle`, and
`CurrentQueryController.prefetchFirstDayGroupPage`.

**Produces:** A direction switch whose observed display frames are either the
old complete identity or the new complete identity, never loading/mixed.

- [ ] **Step 1: Write a deferred target-direction regression.**

  Use the existing recording finite-bundle repository. Open the rail, publish
  a populated income deck, defer the expense deck and select expense. Assert
  that visible metrics/LogBox remain concrete during the defer. Complete the
  deck and first page, then assert the first expense frame has the target
  query key, revision, amount, count and rows together.

- [ ] **Step 2: Run the core regression red.**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/application/dashboard_core_controller_test.dart test/features/dashboard/presentation/core_dashboard_test.dart'
  ```

  Expected: the direction notification immediately changes query identity and
  produces a null metric or LogBox loading state before the expense deck.

- [ ] **Step 3: Add one core-owned staged direction command.**

  Replace direct direction query commit with a generation-guarded preparation
  sequence. It calculates the target parent and effective committed scope,
  awaits both the complete target deck and:

  ```dart
  query.prefetchFirstDayGroupPage(
    targetCommittedScope,
    reason: 'directionTransitionReady',
  )
  ```

  Only after both identities/revisions match, activate the prepared bundle
  with `notify: false` and call the existing query direction intent. Existing
  rail target fallback remains blocked while the target finite deck is
  loading. Add a core getter/listenable-backed predicate so the presentation
  rail can mount only when its current finite deck can serve its selected
  child.

- [ ] **Step 4: Run focused tests green.**

  Run the command from Step 2 and assert zero fallback target-prefetches,
  old-or-new complete state only, and direct exact target display after the
  staged commit.

- [ ] **Step 5: Commit the direction atomicity change.**

  ```sh
  git add lib/features/dashboard/application/dashboard_core_controller.dart test/features/dashboard/application/dashboard_core_controller_test.dart test/features/dashboard/presentation/core_dashboard_test.dart
  git commit -m 'fix(dashboard): stage direction display transitions'
  ```

### Task 4: Verify, update acceptance evidence and deliver

**Files:**

- Modify: `docs/superpowers/checklists/2026-08-03-dashboard-rail-continuity.md`

- [ ] **Step 1: Run all focused dashboard regressions in Ubuntu proot.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/shared/motion/centered_carousel test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart test/features/dashboard/application/dashboard_core_controller_test.dart test/features/dashboard/application/dashboard_summary_amount_controller_test.dart test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart'
  ```

- [ ] **Step 2: Run analysis and the full golden-excluded suite.**

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze && /home/flutteruser/flutter/bin/flutter test --exclude-tags=golden'
  ```

- [ ] **Step 3: Re-read and update DRC-01 through DRC-07.**

  Mark only measured conditions `DONE`; record any environment-only
  limitation explicitly rather than inferring it from compilation.

- [ ] **Step 4: Commit, push and verify the online artifact.**

  ```sh
  git add docs/superpowers/checklists/2026-08-03-dashboard-rail-continuity.md
  git commit -m 'docs(dashboard): verify rail continuity repair'
  git push origin refactor/fluvi-production
  ```

  Wait for GitHub Actions; only after success download the generated debug APK
  into `/storage/emulated/0/Download/fluvi` and report its commit and checksum.
