# Dashboard rail motion ownership implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` inline task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove autonomous rail motion and motion-lane query jank without changing the synchronous child preview/display contract or the established fling target semantics.

**Architecture:** The shared carousel receives a narrow lifecycle correction: an anchored `ScrollPosition`, a stable controller, pure target physics and neutral numeric motion trace. The dashboard adapter does only synchronous intent/display selection; a dashboard application coordinator defers repository observation through a cancellable latest-wins lease. The aggregate motion host listens only to visual-motion signals, so query/status emissions cannot rebuild the physical rail.

**Tech Stack:** Flutter `ScrollController`/`ScrollPosition`/`ScrollPhysics`, `ChangeNotifier`, `flutter_test`, existing dashboard finite display bundles, Ubuntu-proot Flutter tooling, GitHub Actions Android build.

## Global Constraints

- Preserve the existing `D12 → LOG_PREVIEW_BOUND` display path and all query results.
- Do not restore a placeholder, settle-only display, per-tick read, manual fling override or a second rail engine.
- Retain target velocity bands, max-item cap, direction and cyclic/boundary semantics unless a regression proves them wrong.
- `createBallisticSimulation` is synchronous, deterministic and side-effect-free.
- The rail preview callback is synchronous/O(1); no Future, I/O, logging, formatting, controller call or lease activation enters it.
- No golden tests; all Flutter tests/analyze run in Ubuntu proot. APK builds run only in GitHub Actions.
- Keep user-owned `.tmp-*.log` files unmodified.

## File structure and interfaces

| File | Responsibility |
| --- | --- |
| `lib/shared/motion/centered_carousel/centered_carousel_scroll_controller.dart` | Stable raw-scroll owner that configures first-attach pixels before a position exists and disables raw scroll restoration. |
| `lib/shared/motion/centered_carousel/centered_carousel_motion.dart` | Neutral origin/epoch state and fixed-size numeric ring events; no dashboard dependency. |
| `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | Logical/physical mapping, one position invariant, synchronous crossings, semantic-settle dedupe and user-tap command only. |
| `lib/shared/motion/centered_carousel/centered_carousel_physics.dart` | Pure `RailFlingPlan` calculation and one spring simulation. |
| `lib/shared/motion/centered_carousel/centered_carousel.dart` | Stable viewport/physics construction and depth-0 notification adaptation; no post-frame recenter. |
| `lib/features/dashboard/time_navigation/.../dashboard_time_navigation_controller.dart` | Canonical configured logical child and display-scope intent; never positions a scroll controller. |
| `lib/features/dashboard/widgets/time_refinement_rail.dart` | Render/input adapter: immediate preview forwarding, one semantic-settle forwarding and repaint boundary. |
| `lib/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart` | Latest-wins, cancellable quiescence gate for live watch activation. |
| `lib/features/dashboard/query/application/current_query_controller.dart` | Activates/cancels only allowed live leases and ignores equal/stale result binds. |
| `lib/features/dashboard/application/dashboard_core_controller.dart` | Connects navigation settle/motion state to the display promotion and lease application lanes. |
| `lib/core/motion/dashboard_motion_host.dart` | Listens to motion-only signals, not aggregate query notifications. |

```dart
enum RailMotionOrigin { none, userDrag, nativeBallistic, userTap, programmaticInitialisation, dimensionCorrection, programmaticRebase }
enum RailMotionState { idle, dragging, ballistic }

@immutable
class RailMotionSnapshot {
  const RailMotionSnapshot({required this.epoch, required this.origin, required this.state});
  final int epoch;
  final RailMotionOrigin origin;
  final RailMotionState state;
}

abstract interface class DashboardLiveQueryLeaseCoordinator {
  void request(CurrentLedgerQueryScope scope, {required int motionEpoch});
  void onRailMotion(RailMotionSnapshot motion);
  void dispose();
}
```

### Task 1: Lock the frozen display contract and capture pre-fix trace evidence

**Files:**
- Modify: `test/features/dashboard/widgets/time_refinement_rail_test.dart`
- Modify: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Modify: `test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart`

- [ ] **Step 1: Write failing regressions**

```dart
testWidgets('startup emits no rail motion while retaining the configured child', (tester) async {
  await pumpOpenRail(tester, selectedChild: 13);
  await tester.pump(const Duration(seconds: 2));
  expect(trace.ballisticStarts, 0);
  expect(trace.programmaticMotions, 0);
  expect(navigation.state.selectedChildLogicalIndex, 13);
  expect(navigation.state.navigationRevision, 0);
});

test('matching preview promotion does not visually rebind', () {
  coordinator.synchronizeCommittedQuery();
  expect(events.single, const PreviewPromotion(visualChange: false, listRebound: false, amountAnimationStarted: false));
});
```

- [ ] **Step 2: Run each named test and record the expected RED evidence**

```sh
proot-distro login ubuntu --bind /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi:/mnt/fluvi -- bash -lc 'cd /mnt/fluvi && /root/flutter/bin/flutter test test/features/dashboard/widgets/time_refinement_rail_test.dart test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart'
```

Expected before Task 2: repeated low-level idle/snap or an autonomous motion count, while the display promotion baseline remains green.

- [ ] **Step 3: Preserve existing atomic deck assertions**

Add a helper asserting `navigation.queryKey == amount.queryKey == count.queryKey == log.queryKey` after every controlled child callback; assert non-empty snapshots contain neither `—` nor an empty group list.

- [ ] **Step 4: Re-run frozen-display tests**

Expected: display contract tests remain green before movement changes.

### Task 2: Replace post-frame alignment with first-attach anchor ownership

**Files:**
- Create: `lib/shared/motion/centered_carousel/centered_carousel_scroll_controller.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`

- [ ] **Step 1: Write failing first-attach and identity tests**

```dart
testWidgets('cyclic controller first attach starts at anchor plus logical offset', (tester) async {
  final controller = CenteredCarouselController(initialIndex: 13);
  await pumpCyclicCarousel(tester, controller: controller);
  expect(controller.selectedPhysicalIndex, CenteredCarouselController.virtualAnchorIndex);
  expect(controller.scrollController.offset, closeTo(anchorPixels, 0.01));
  expect(controller.motionTrace.programmaticRequests, isEmpty);
});

testWidgets('one controller and position survive one hundred display rebuilds', (tester) async {
  final identity = controller.scrollController;
  final position = controller.scrollController.position;
  await pumpOneHundredPreviewSwaps(tester);
  expect(identical(controller.scrollController, identity), isTrue);
  expect(identical(controller.scrollController.position, position), isTrue);
  expect(controller.scrollController.positions, hasLength(1));
});
```

- [ ] **Step 2: Run RED tests**

Expected: current default offset/post-frame jump produces a non-anchor start or a programmatic request.

- [ ] **Step 3: Implement an anchored controller/position**

Create `CenteredCarouselScrollController extends ScrollController` with `keepScrollOffset: false`, a `configureInitialPixels(double)` method allowed only before first attachment, and a custom `ScrollPositionWithSingleContext` that records attach/activity transitions. In `updateConfiguration`, calculate the selected physical pixel before first attach and configure it; on a true dimension correction use `correctPixels`, never public `jumpTo`.

Remove `_scheduleRecenter`, `jumpToIndexSilently` baseline scheduling and `_syncMotionBaseline` post-frame jumps. Initialize `DashboardTimeNavigationController.timeCarousel` with the already-selected logical child. Keep rare corridor rebasing as a position-lifecycle `correctPixels` operation permitted only at idle, never on selection/rebuild.

- [ ] **Step 4: Run GREEN tests**

Expected: configured anchor first attach, zero startup/rail-open programmatic motion and exactly one attached position.

### Task 3: Make physics pure and establish one semantic motion epoch

**Files:**
- Create: `lib/shared/motion/centered_carousel/centered_carousel_motion.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_physics_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`

- [ ] **Step 1: Write failing pure-factory and settle-dedupe tests**

```dart
test('physics is deterministic and produces no observer side effect', () {
  final first = physics.createBallisticSimulation(metrics, 2400);
  final second = physics.createBallisticSimulation(metrics, 2400);
  expect(targetOf(first), targetOf(second));
  expect(mutableControllerState, before);
  expect(numericTrace.events, isEmpty);
});

test('one drag epoch emits one settle despite duplicate idle events', () {
  controller.beginUserDrag();
  controller.recordNativeBallistic();
  controller.recordIdle();
  controller.recordIdle();
  expect(settled, [expectedLogicalChild]);
});
```

- [ ] **Step 2: Run RED tests**

Expected: existing physics callback/frozen-plan behavior mutates controller/performance state; duplicate end paths can report more than one low-level idle.

- [ ] **Step 3: Implement the neutral state machine**

Keep `createFlingPlan` target math and return one `ScrollSpringSimulation`, but remove `resolveFlingPlan`, target observer, dashboard trace and debug formatting from `CenterSnapScrollPhysics`. Store numeric activity events in a capacity-256 `RailMotionTrace`; format neither strings nor stacks on the hot path. The custom position calls controller transitions only for its own position. A user drag creates one epoch, a ballistic transition retains it, and only the first matching idle generates `onSelectionSettled`. Initialisation, dimension correction and rebase cannot produce a semantic settle. Remove rail target-prefetch observer rather than introducing a second velocity target resolver.

- [ ] **Step 4: Run GREEN tests**

Expected: one ballistic owner/settle, no manual drag-end animate/jump, low velocity nearest snap, and repeated physics factory calls return equivalent targets without effects.

### Task 4: Keep every child preview synchronous and isolate the motion lane

**Files:**
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Modify: `lib/core/motion/dashboard_motion_host.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/performance/dashboard_performance_trace.dart`
- Test: `test/features/dashboard/widgets/time_refinement_rail_test.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`

- [ ] **Step 1: Write failing callback/rebuild tests**

```dart
testWidgets('every selected child updates all display keys synchronously', (tester) async {
  for (final child in [1, 2, 3, 4, 5]) {
    emitSelectedChild(child);
    expect(display.queryKeys, [keyFor(child), keyFor(child), keyFor(child), keyFor(child)]);
  }
});

testWidgets('query notification does not rebuild the rail motion lane', (tester) async {
  final before = railBuildCount;
  query.emitFreshnessOnly();
  await tester.pump();
  expect(railBuildCount, before);
});
```

- [ ] **Step 2: Run RED tests**

Expected: `_queuePreview` defers to post-frame and aggregate core notification rebuilds the motion host.

- [ ] **Step 3: Implement render boundaries**

Forward `previewChildLogicalIndex` inline from the rail callback, retaining normal Flutter frame coalescing. Cache `CenterSnapScrollPhysics` in state and rebuild it only when its immutable spec changes. Put the rail viewport and LogBox display lane in separate `RepaintBoundary` widgets. Make `DashboardMotionHost` subscribe to expansion/rail/direction motion signals rather than aggregate query notifications. Keep one stable pulse controller; trigger paint-only transform/opacity and fire haptics unawaited outside physics.

- [ ] **Step 4: Run GREEN tests**

Expected: all five/ten crossing keys update synchronously, query events leave rail identity/build count unchanged, and tick/haptic do not change target/settle.

### Task 5: Split display promotion from latest-wins live observation

**Files:**
- Create: `lib/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart`
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart`
- Test: `test/features/dashboard/query/dashboard_live_query_lease_coordinator_test.dart`
- Test: `test/features/dashboard/query/current_query_controller_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Test: `test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart`

- [ ] **Step 1: Write failing lease tests using fake time**

```dart
test('ten rapid settled intents activate only the final live lease', () {
  for (final scope in rapidScopes) coordinator.request(scope, motionEpoch: epochFor(scope));
  fakeAsync.elapse(const Duration(milliseconds: 179));
  expect(repository.watchRequests, 0);
  fakeAsync.elapse(const Duration(milliseconds: 1));
  expect(repository.watchRequests, 1);
  expect(repository.readRequests, 1);
  expect(repository.lastScope, rapidScopes.last);
});

test('no live work starts while motion is active', () {
  coordinator.onRailMotion(ballisticEpoch);
  coordinator.request(scope, motionEpoch: ballisticEpoch.epoch);
  fakeAsync.elapse(const Duration(seconds: 1));
  expect(repository.watchRequests, 0);
  expect(repository.readRequests, 0);
});
```

- [ ] **Step 2: Run RED tests**

Expected: current `setTimeScope` starts a watch/read at every cache-miss settle.

- [ ] **Step 3: Implement the lease coordinator**

`DashboardCoreController` accepts the navigation's committed display scope immediately and invokes existing preview promotion before requesting a lease. `DashboardLiveQueryLeaseCoordinator` owns one cancellable 180 ms quiescence timer and generation. New pointer/motion epoch cancels a pending candidate; drag/ballistic prevents activation; only the latest idle candidate calls `CurrentQueryController.activateLiveLease`. Initial application refresh remains explicit and is not a rail settle.

`CurrentQueryController` cancels/starts repository observation only from `activateLiveLease`, generation-filters results and exposes live metadata separately from display readiness. `DashboardLogPageCoordinator` accepts an incoming live result only when `queryKey`, core revision and content digest differ from the displayed immutable snapshot; otherwise it updates no list/amount/count state.

- [ ] **Step 4: Run GREEN tests**

Expected: intermediate watch/read/bind counts are zero, final count is one, stale results are ignored, matching preview promotion is visual no-op and identical fresh output does not rebind.

### Task 6: Add production-safe diagnostics and complete regression suite

**Files:**
- Modify: `lib/features/dashboard/query/application/dashboard_query_debug.dart`
- Modify: `lib/features/dashboard/performance/dashboard_performance_trace.dart`
- Modify: focused carousel/dashboard tests listed above
- Modify: `docs/superpowers/checklists/2026-08-03-dashboard-rail-motion-ownership.md`

- [ ] **Step 1: Write failing bounded-trace/logger tests**

```dart
test('motion trace retains only the newest fixed-size numeric events', () {
  for (var index = 0; index != 300; index++) trace.append(kind: 1, valueA: index);
  expect(trace.events, hasLength(256));
  expect(trace.events.first.valueA, 44);
});
```

- [ ] **Step 2: Run RED test**

Expected: human-readable flow logging still executes at motion events.

- [ ] **Step 3: Implement lazy diagnostic export**

Guard verbose `DashboardQueryDebug` at the call site and remove it from all selected-child/activity paths. Preserve explicit, post-motion diagnostic export by formatting the numeric trace only on export/panel request. Extend profile trace counters for attach/position recreation, selected-to-display, lease request/read/bind and active-motion violations.

- [ ] **Step 4: Run focused and broad verification**

```sh
proot-distro login ubuntu --bind /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi:/mnt/fluvi -- bash -lc 'cd /mnt/fluvi && /root/flutter/bin/flutter test test/shared/motion/centered_carousel test/features/dashboard/widgets/time_refinement_rail_test.dart test/features/dashboard/query test/features/dashboard/application/dashboard_core_controller_test.dart test/features/dashboard/logbox/dashboard_log_page_coordinator_test.dart test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/performance/dashboard_performance_trace_test.dart'
proot-distro login ubuntu --bind /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi:/mnt/fluvi -- bash -lc 'cd /mnt/fluvi && /root/flutter/bin/flutter analyze lib/shared/motion/centered_carousel lib/features/dashboard lib/core/motion'
```

Expected: all selected tests/analyze pass; no golden test runs.

### Task 7: Profile, deliver and truthfully close the checklist

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-03-dashboard-rail-motion-ownership.md`
- Optional Modify: `.github/workflows/fluvi-core.yml` only if a profile artifact job is needed for device installation.

- [ ] **Step 1: Capture a physical-device profile matrix**

Use a profile build on-device for A–K (rail only, empty/5-row/full display, haptic/logger/lease variants). Export UI/raster p50/p90/p99/worst, jank count, attach/recreation count, motion-active repository counts, target equality and selected-to-display duration. Do not substitute debug timings or invent numbers.

- [ ] **Step 2: Commit implementation and evidence**

```sh
git add lib test docs .github
git commit -m 'fix(dashboard): isolate rail motion and live leases'
git push origin refactor/fluvi-production
```

- [ ] **Step 3: Wait for GitHub Actions and download the APK**

After the online Android job succeeds, download its release artifact, verify SHA-256, create `/storage/emulated/0/Download/fluvi` if needed, and copy the exact APK there. Record Actions URL, source SHA, artifact SHA and local destination in RMO-13.

## Coverage self-review

RMO-01 maps Tasks 1/4/5; RMO-02–06 map Tasks 2/3/6; RMO-07 maps Task 4;
RMO-08–10 map Task 5; RMO-11 maps Tasks 4/6; RMO-12 maps Task 7; and
RMO-13 maps Tasks 6/7. The plan intentionally has no golden task because the
user explicitly declined golden verification.

