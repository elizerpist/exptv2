# Dashboard Complete Motion/Data Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. This plan is explicitly inline-only; do not delegate any task or spawn an agent.

**Goal:** Replace Fluvi's dashboard motion/data presentation architecture so every rail and dashboard animation is physically independent of data density, cache state, SQLite, platform transport and LogBox projection.

**Architecture:** Keep and extend the single shared centered-carousel engine as the Motion Kernel, but feed it a prebuilt immutable semantic catalog. Prepare complete immutable parent decks through a constant-query Android batch, versioned binary transport and Dart worker-isolate projection; select one atomic visible frame through a display-frame coalescer; start exactly one epoch-guarded live query only after commit.

**Tech Stack:** Flutter 3.41.4, Dart 3.11.1, Flutter Scheduler/Scroll APIs, Dart isolates and typed data, Kotlin 2.x/JVM 17, Room 2.8.4, Android MethodChannel/EventChannel, GitHub Actions.

## Global Constraints

- Work only on `refactor/dashboard-complete-motion-data-isolation`, preserving milestone `bb6c294257b94859a902d445113ab3f739db0783`.
- Run Flutter tests/analyze only inside Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`; never run a local Flutter APK build on Termux/Android ARM64.
- Preserve QueryKey meaning, exact amount/count arithmetic, LogBox content, visual layout, rail item extent, friction `0.135`, velocity multiplier `0.66`, velocity limits, maximum fling steps, snap/spring/tolerance, gesture thresholds and visual animation durations.
- Add no golden test and regenerate no golden image.
- Use one canonical production path; no feature flag, legacy fallback, second store, time debounce/throttle, settle-only rendering, ballistic suppression, loading-placeholder masking, 12/31 child calls or per-child platform calls.
- Treat the acceptance checklist as executable scope; before each commit update only rows with direct evidence.
- Preserve every pre-existing user-owned untracked `.tmp-*` file and `test/features/dashboard/presentation/failures/` artifact.

## File and responsibility map

### New focused production files

- `lib/features/dashboard/motion/dashboard_motion_state.dart`: immutable numeric motion snapshot/context/activity.
- `lib/features/dashboard/motion/dashboard_semantic_catalog.dart`: immutable O(1) logical-index/query-key catalog and bounded SUM year-window policy.
- `lib/features/dashboard/motion/dashboard_motion_kernel.dart`: sole rail motion owner wrapping the shared centered-carousel engine.
- `lib/features/dashboard/motion/dashboard_display_frame_coalescer.dart`: one-latest-target-per-engine-frame scheduler.
- `lib/features/dashboard/prepared/domain/dashboard_prepared_deck.dart`: prepared key/deck/frame/amount/count/header/empty/digest models.
- `lib/features/dashboard/prepared/application/dashboard_prepared_deck_cache.dart`: typed residency-aware bounded LRU.
- `lib/features/dashboard/prepared/application/dashboard_prepared_deck_pipeline.dart`: seed/revision/in-flight/prewarm/generation owner.
- `lib/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart`: production preparation/live-page contracts.
- `lib/features/dashboard/prepared/data/dashboard_prepared_binary_codec.dart`: pure versioned binary decoder/projector invoked in a worker isolate.
- `lib/features/dashboard/visible/domain/dashboard_visible_frame.dart`: atomic immutable visible model and invariant assertions.
- `lib/features/dashboard/visible/application/dashboard_visible_frame_store.dart`: sole visual publication and nonvisual commit promotion owner.
- `lib/features/dashboard/query/application/dashboard_committed_query_controller.dart`: single committed lease and latest-wins acceptance.
- `lib/features/dashboard/diagnostics/dashboard_runtime_diagnostics.dart`: required event ring and fixed counters.
- `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviPreparedDeckModels.kt`: bounded native deck/frame models and metrics.
- `android/app/src/main/kotlin/com/fluvi/app/dashboard/DashboardBinaryCodec.kt`: versioned byte-array deck/frame encoder.

### Existing files to rewrite/extend

- `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`: expose one stable physics/configuration handle and identity counters; preserve math/constants.
- `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`: support the stable dynamic geometry handle without changing target math.
- `lib/shared/motion/centered_carousel/centered_carousel.dart`: consume the stable physics and precreated source; remove dashboard-driven configuration churn/recenter.
- `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart`: become/alias the immutable structural `DashboardNavigationState`; remove transient preview ownership.
- `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`: structural navigation only; install prepared catalogs through the Motion Kernel.
- `lib/features/dashboard/widgets/time_refinement_rail.dart`: render catalog and forward motion-only callbacks; never derive QueryKeys/data.
- `lib/features/dashboard/application/dashboard_core_controller.dart`: shrink to orchestration façade connecting four independent owners.
- `lib/features/dashboard/application/dashboard_bootstrap_controller.dart`: gate on one complete nonzero-revision deck/visible frame.
- `lib/features/dashboard/application/dashboard_performance_counters.dart`: replace slots with the complete requested counter set or delegate to runtime diagnostics.
- `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`: request/receive bytes and invoke worker decode for decks/live/page.
- `lib/features/dashboard/query/domain/current_ledger_query_scope.dart`: compute canonical QueryKey once while preserving exact string semantics.
- `lib/features/dashboard/logbox/application/dashboard_log_viewport_state.dart`: make frame metadata fully immutable and pointer-reusable.
- `lib/features/dashboard/logbox/application/dashboard_log_paging_coordinator.dart`: committed-only prepared-page merge.
- `lib/features/dashboard/presentation/core_dashboard.dart`: compose stable isolated subtrees and visible-frame selectors.
- `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`: direct prepared VM pointer, stable shell/controller/slivers.
- `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`: static shell plus narrow count selector.
- `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`: start shell return before structural intent and consume atomic prepared amount.
- `lib/core/motion/dashboard_motion_host.dart`: observe only structural motion/navigation and expose identity/rebuild counters.
- `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`: constant-query streamed parent deck.
- `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`: return byte arrays and binary live events encoded off main.
- `integration_test/dashboard_interaction_profile_test.dart` and support/report files: scenarios A–J and full metrics.
- `.github/workflows/fluvi-core.yml`: retain normal verification/APK build and validate profile harness artifact.

### Old production files/routes to remove after migration

- `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- `lib/features/dashboard/application/dashboard_parent_bundle_registry.dart`
- `lib/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator.dart`
- `lib/features/dashboard/application/dashboard_background_work_coordinator.dart`
- `lib/features/dashboard/application/dashboard_rail_motion_coordinator.dart`
- `lib/features/dashboard/query/application/current_query_controller.dart`
- `lib/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart`
- `lib/features/dashboard/query/application/dashboard_parent_display_bundle.dart`
- `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- `lib/features/dashboard/query/application/dashboard_presentation_diagnostics.dart`
- `lib/features/dashboard/query/data/dashboard_child_summary_repository.dart`
- `lib/features/dashboard/query/domain/time_child_summary.dart`
- `lib/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart`
- old nested-map child-preview method and mapper in `MainActivity`/method-channel repository.

---

### Task 1: Fail-closed architecture boundary

**Files:**
- Modify: `test/boundary/dashboard_interaction_performance_boundary_test.dart`
- Create: `test/boundary/dashboard_motion_data_isolation_boundary_test.dart`

**Interfaces:**
- Consumes: repository source tree only.
- Produces: structural contract required by every later task.

- [ ] **Step 1: Write the failing boundary test**

```dart
test('dashboard motion and presentation have one-way dependencies', () {
  final motion = sources('lib/features/dashboard/motion');
  final presentation = sources('lib/features/dashboard/presentation');
  final production = sources('lib/features/dashboard');
  expect(motion, isNot(matches(RegExp(
    r'(Repository|MethodChannel|EventChannel|DashboardPreparedDeckPipeline|DashboardLogViewportState|DateFormat|formatTotalMinor)',
  ))));
  expect(RegExp(r'class\s+DashboardMotionKernel\b').allMatches(production), hasLength(1));
  expect(RegExp(r'class\s+DashboardVisibleFrameStore\b').allMatches(production), hasLength(1));
  expect(RegExp(r'class\s+DashboardPreparedDeckPipeline\b').allMatches(production), hasLength(1));
  expect(RegExp(r'class\s+DashboardCommittedQueryController\b').allMatches(production), hasLength(1));
  expect(presentation, isNot(contains('method_channel_dashboard_ledger_repository.dart')));
});
```

Add fail-closed checks that no scroll/preview callback body contains
`await`, repository/read/watch/lease/platform/projection/format calls; only one
visible store and prepared cache owner exist; old production owners listed
above are absent at final migration; `childPreviewBundle` has no child loop
calling `queryTimelinePage`; no QueryKey viewport key or time debounce exists.

- [ ] **Step 2: Run it and record the expected RED state**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/boundary/dashboard_motion_data_isolation_boundary_test.dart'
```

Expected: FAIL because the four new canonical owner classes do not yet exist
and the old owners/N-child query loop are still present.

- [ ] **Step 3: Keep the boundary red while adding the new architecture**

Do not weaken patterns or add broad allowlists. Each subsequent task may make a
subset green; the whole test becomes green only after Task 13 removes old paths.

- [ ] **Step 4: Commit the executable boundary and planning documents**

```bash
git add docs/dashboard/dashboard-motion-data-root-cause.md docs/superpowers/checklists/2026-08-05-dashboard-complete-motion-data-isolation.md docs/superpowers/specs/2026-08-05-dashboard-complete-motion-data-isolation-design.md docs/superpowers/plans/2026-08-05-dashboard-complete-motion-data-isolation.md test/boundary/dashboard_motion_data_isolation_boundary_test.dart test/boundary/dashboard_interaction_performance_boundary_test.dart
git commit -m "test: define dashboard motion data architecture boundary"
```

### Task 2: Immutable keys, catalogs and state models

**Files:**
- Create: `lib/features/dashboard/motion/dashboard_motion_state.dart`
- Create: `lib/features/dashboard/motion/dashboard_semantic_catalog.dart`
- Create: `lib/features/dashboard/prepared/domain/dashboard_prepared_deck.dart`
- Create: `lib/features/dashboard/visible/domain/dashboard_visible_frame.dart`
- Modify: `lib/features/dashboard/query/domain/current_ledger_query_scope.dart`
- Test: `test/features/dashboard/motion/dashboard_semantic_catalog_test.dart`
- Test: `test/features/dashboard/prepared/dashboard_prepared_deck_test.dart`
- Test: `test/features/dashboard/visible/dashboard_visible_frame_test.dart`

**Interfaces:**
- Consumes: existing `LedgerTimeScope`, `LedgerDirection`, `LedgerQueryKey`,
  `DashboardLogViewportState`, exact existing label/money semantics.
- Produces:
  - `DashboardSemanticCatalog.forNavigation(parentScope:, childPeriod:, retainedValue:, yearWindowRadius:)`
  - `DashboardPreparedDeckKey`, `DashboardPreparedFrame`, `DashboardPreparedDeck`
  - `DashboardVisibleFrame.fromPrepared(frame, parentQueryKey:, plane:, railOpen:, semanticIndex:, navigationEpoch:, presentationEpoch:, frameGeneration:, mode:)`
  - memoized `CurrentLedgerQueryScope.key`.

- [ ] **Step 1: Write failing invariant/catalog tests**

```dart
test('month catalog precomputes exact child keys in logical order', () {
  final catalog = DashboardSemanticCatalog.forMonth(
    parentScope: scope(const MonthScope(YearMonth(year: 2026, month: 6))),
  );
  expect(catalog.length, 30);
  expect(catalog[29].queryKey.value, contains('day:2026-06-30'));
  expect(identical(catalog[29], catalog.entryAtLogicalIndex(29)), isTrue);
});

test('SUM catalog is a fixed retained-year plus/minus twelve window', () {
  final catalog = DashboardSemanticCatalog.forYears(
    parentScope: scope(const AllTimeScope()), retainedYear: 2026,
  );
  expect(catalog.values, orderedEquals(List.generate(25, (i) => 2014 + i)));
});

test('visible frame rejects mixed keys and revisions', () {
  final frame = preparedFrameFixture();
  expect(
    () => DashboardVisibleFrame.fromPrepared(
      frame.copyWith(logBox: frame.logBox.copyWith(queryKey: const LedgerQueryKey('different'))),
      parentQueryKey: frame.parentQueryKey,
      plane: TimePlane.month,
      railOpen: true,
      semanticIndex: 0,
      navigationEpoch: 1,
      presentationEpoch: 1,
      frameGeneration: 1,
      mode: DashboardVisibleMode.preview,
    ),
    throwsA(isA<AssertionError>()),
  );
});
```

Also test key model version/revision/page/window equality, revision-zero deck
rejection, complete-map/catalog coverage and exact memoized QueryKey parity.

- [ ] **Step 2: Run tests and verify RED**

Run the three new test files with the Ubuntu proot command. Expected: compile
failure for missing models.

- [ ] **Step 3: Implement the immutable models**

Required public signatures:

```dart
@immutable
final class DashboardSemanticEntry {
  const DashboardSemanticEntry({
    required this.logicalIndex,
    required this.value,
    required this.label,
    required this.semanticLabel,
    required this.childPeriod,
    required this.scope,
    required this.queryKey,
  });
}

@immutable
final class DashboardPreparedFrame {
  DashboardPreparedFrame({
    required CurrentLedgerQueryScope scope,
    required LedgerQueryKey parentQueryKey,
    required int coreRevision,
    required int totalMinor,
    required String formattedAmount,
    required int entryCount,
    required String formattedEntryCount,
    required DashboardLogViewportState logBox,
    required int presentationDigest,
  }) : assert(coreRevision > 0), assert(logBox.queryKey == scope.key);
}

@immutable
final class DashboardVisibleFrame {
  factory DashboardVisibleFrame.fromPrepared(
    DashboardPreparedFrame frame, {
    required LedgerQueryKey parentQueryKey,
    required TimePlane plane,
    required bool railOpen,
    required int semanticIndex,
    required int navigationEpoch,
    required int presentationEpoch,
    required int frameGeneration,
    required DashboardVisibleMode mode,
  });
}
```

Store lists/maps unmodifiable, calculate digests once, and store the canonical
QueryKey once in `CurrentLedgerQueryScope`'s constructor without changing its
string layout.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: all new pure-model tests pass and existing QueryKey/domain tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/motion lib/features/dashboard/prepared/domain lib/features/dashboard/visible/domain lib/features/dashboard/query/domain/current_ledger_query_scope.dart test/features/dashboard/motion test/features/dashboard/prepared test/features/dashboard/visible test/features/dashboard/query
git commit -m "feat: add immutable dashboard motion and prepared frame models"
```

### Task 3: Stable shared carousel Motion Kernel

**Files:**
- Create: `lib/features/dashboard/motion/dashboard_motion_kernel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Test: `test/features/dashboard/motion/dashboard_motion_kernel_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_identity_test.dart`
- Test: `test/features/dashboard/widgets/time_refinement_rail_test.dart`

**Interfaces:**
- Consumes: immutable `DashboardSemanticCatalog`, existing carousel math/spec.
- Produces: one `DashboardMotionKernel`, stable `carouselController`,
  `dashboardPhysics`, numeric state, crossing/settle callbacks.

- [ ] **Step 1: Write failing isolation and identity tests**

```dart
test('100 crossings perform catalog lookup only', () {
  final spy = DashboardMotionDependencySpy();
  final kernel = DashboardMotionKernel(catalog: catalog, diagnostics: spy);
  for (var i = 0; i < 100; i++) kernel.testOnlyCross(i % catalog.length);
  expect(spy.sql + spy.platform + spy.repository + spy.format + spy.logProject, 0);
});

testWidgets('controller physics and position survive 100 catalog installs', (tester) async {
  final kernel = DashboardMotionKernel(catalog: catalog);
  await pumpRail(tester, kernel);
  final controller = kernel.carouselController;
  final physics = kernel.dashboardPhysics;
  final position = controller.scrollController.position;
  for (var i = 0; i < 100; i++) kernel.installCatalog(catalogFor(i));
  expect(identical(kernel.carouselController, controller), isTrue);
  expect(identical(kernel.dashboardPhysics, physics), isTrue);
  expect(identical(controller.scrollController.position, position), isTrue);
});
```

Add 100-repeat target tests using the unchanged physics constants and 0/1/94/658
density metadata attached outside the kernel.

- [ ] **Step 2: Run and verify RED**

Expected: missing kernel/stable physics APIs.

- [ ] **Step 3: Implement the kernel and stable physics handle**

```dart
final class DashboardMotionKernel {
  DashboardMotionKernel({
    required DashboardSemanticCatalog catalog,
    required DashboardSemanticCrossing onSemanticCrossed,
    required DashboardMotionSettle onSettled,
    DashboardRuntimeDiagnostics? diagnostics,
  });
  final CenteredCarouselController carouselController;
  final CenterSnapScrollPhysics dashboardPhysics;
  DashboardMotionState get state;
  DashboardSemanticCatalog get catalog;
  void installCatalog(DashboardSemanticCatalog catalog, {required int selectedIndex});
  void beginGesture();
  void semanticCrossed(int logicalIndex);
  void settled(int logicalIndex);
}
```

The stable physics reads item extent/count through one controller-owned
configuration handle. Do not change the target/simulation formula or constants.
Keep only the initial attachment recenter; remove ordinary update-driven
post-frame recenter. `TimeRefinementRail` receives the kernel/catalog directly
and never reads navigation/query/presentation state.

- [ ] **Step 4: Run shared and dashboard motion tests GREEN**

Run centered-carousel math/physics/widget tests and the new kernel/rail tests.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/motion/centered_carousel lib/features/dashboard/motion lib/features/dashboard/widgets/time_refinement_rail.dart test/shared/motion test/features/dashboard/motion test/features/dashboard/widgets/time_refinement_rail_test.dart
git commit -m "refactor: isolate dashboard rail in stable motion kernel"
```

### Task 4: Display-frame coalescer and atomic visible store

**Files:**
- Create: `lib/features/dashboard/motion/dashboard_display_frame_coalescer.dart`
- Create: `lib/features/dashboard/visible/application/dashboard_visible_frame_store.dart`
- Test: `test/features/dashboard/motion/dashboard_display_frame_coalescer_test.dart`
- Test: `test/features/dashboard/visible/dashboard_visible_frame_store_test.dart`

**Interfaces:**
- Consumes: complete `DashboardVisibleFrame` candidates.
- Produces: `request(frame)`, visual `ValueListenable`, `promoteCommitted` no-op
  visual path, publish/frame counters.

- [ ] **Step 1: Write deterministic fake-frame scheduler tests**

```dart
test('same display frame publishes only the last target without backlog', () {
  final scheduler = FakeDashboardDisplayFrameScheduler();
  final published = <String>[];
  final c = DashboardDisplayFrameCoalescer(
    scheduler: scheduler, publish: (f) => published.add(f.queryKey.value),
  );
  c.request(frame('a')); c.request(frame('b')); c.request(frame('c'));
  scheduler.fireFrame();
  expect(published, ['c']);
  scheduler.fireFrame();
  expect(published, ['c']);
});

test('settle promotion changes no visual counters', () {
  store.publish(frame('a'));
  final before = store.visiblePublishCount;
  expect(store.promoteCommitted(expectedKey: key('a'), epoch: 1), isTrue);
  expect(store.visiblePublishCount, before);
  expect(store.logRebindCount + store.amountRestartCount, 0);
});
```

- [ ] **Step 2: Verify RED**

Expected: missing scheduler/store classes.

- [ ] **Step 3: Implement one-slot coalescing and exact acceptance**

```dart
abstract interface class DashboardDisplayFrameScheduler {
  int get currentFrameNumber;
  void scheduleFrame(VoidCallback callback);
}

final class DashboardVisibleFrameStore extends ChangeNotifier
    implements ValueListenable<DashboardVisibleFrame?> {
  bool publish(DashboardVisibleFrame frame);
  bool promoteCommitted({required LedgerQueryKey expectedKey, required int epoch});
}
```

Store a single pending frame, clear before callback publication, compare the
precomputed visual digest and reject stale key/revision/epoch. Promotion updates
internal mode/current metadata without `notifyListeners`.

- [ ] **Step 4: Run GREEN and commit**

```bash
git add lib/features/dashboard/motion/dashboard_display_frame_coalescer.dart lib/features/dashboard/visible test/features/dashboard/motion/dashboard_display_frame_coalescer_test.dart test/features/dashboard/visible
git commit -m "feat: publish atomic dashboard frames at display boundaries"
```

### Task 5: Prepared deck LRU, seed/revision gate and in-flight pipeline

**Files:**
- Create: `lib/features/dashboard/prepared/application/dashboard_prepared_deck_cache.dart`
- Create: `lib/features/dashboard/prepared/application/dashboard_prepared_deck_pipeline.dart`
- Create: `lib/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart`
- Modify: `lib/features/dashboard/query/data/dashboard_bounded_cache.dart`
- Test: `test/features/dashboard/prepared/dashboard_prepared_deck_cache_test.dart`
- Test: `test/features/dashboard/prepared/dashboard_prepared_deck_pipeline_test.dart`

**Interfaces:**
- Consumes: `DashboardPreparedDeckRepository.prepare(request, token)`.
- Produces: O(1) `lookup`, deduplicated `prepareRequired`, cache-only `prewarm`,
  revision/seed invalidation, immutable `DashboardPreparedState`.

- [ ] **Step 1: Write failing cache/pipeline tests**

Test exact key dimensions, access-order eviction, pinned active/prev/next,
opposite-direction residency, one Future for 20 concurrent same-key calls,
cancelled/stale completion discard, revision mismatch, and revision-zero hard
rejection:

```dart
test('revision zero can neither complete nor cache', () async {
  final pipeline = pipelineReturning(deck(revision: 0));
  pipeline.openSeedGate();
  await expectLater(pipeline.prepareRequired(request(revision: 0)), throwsStateError);
  expect(pipeline.cache.length, 0);
});
```

- [ ] **Step 2: Run RED**

Expected: missing typed cache/pipeline.

- [ ] **Step 3: Implement the one preparation owner**

```dart
abstract interface class DashboardPreparedDeckRepository {
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  );
}

final class DashboardPreparedDeckPipeline {
  DashboardPreparedDeckLookup lookup(DashboardPreparedDeckKey key);
  Future<DashboardPreparedDeck> prepareRequired(DashboardPreparedDeckRequest request);
  Future<void> prewarm(DashboardPreparedDeckRequest request);
  void setInteractionActive(bool active);
  void acceptCoreRevision(int revision);
  void openSeedGate();
}
```

No Flutter scheduler/ticker dependency belongs in the pipeline. Interaction
blocks starting new prewarms but does not block required target preparation on
native/worker threads. Prewarm completion updates cache only.

- [ ] **Step 4: Run GREEN and commit**

```bash
git add lib/features/dashboard/prepared lib/features/dashboard/query/data/dashboard_bounded_cache.dart test/features/dashboard/prepared
git commit -m "feat: add revision safe prepared dashboard deck pipeline"
```

### Task 6: Native constant-query prepared deck and versioned encoder

**Files:**
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviPreparedDeckModels.kt`
- Create: `android/app/src/main/kotlin/com/fluvi/app/dashboard/DashboardBinaryCodec.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/dashboard/DashboardQueryArguments.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Test: `android/fluvi-core/src/test/kotlin/com/fluvi/core/query/FluviPreparedDeckTest.kt`
- Test: `android/app/src/test/kotlin/com/fluvi/app/dashboard/DashboardBinaryCodecTest.kt`

**Interfaces:**
- Consumes: unchanged `FluviQueryScope` predicate semantics and explicit child
  period/window/page request.
- Produces: `FluviLedgerReadService.preparedDeck(scope, childPeriodKind, previewPageSize, yearWindow)` and
  `DashboardBinaryCodec.encodeDeck/encodeSlice` byte arrays.

- [ ] **Step 1: Write failing native tests**

Use a query-counting SQLite wrapper/test checkpoint to assert month and year
deck count is constant and equal between 28/31 and 12 children. Assert exact
totals, 25-year SUM window, `pageSize + 1` row bound, revision, deterministic
ordering, cursor, magic/version and malformed-length rejection.

```kotlin
@Test fun monthDeckDoesNotQueryEachDay() = runTest {
    val deck = readService.preparedDeck(monthScope, QueryPeriodKind.day, 24, null)
    assertEquals(31, deck.children.size)
    assertEquals(constantSqlCount, metrics.sqlCallCount)
    assertTrue(deck.children.all { it.rows.size <= 25 })
}
```

- [ ] **Step 2: Run native tests RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi/android && ./gradlew :fluvi-core:testDebugUnitTest :app:testDebugUnitTest --no-daemon'
```

Expected: missing model/service/codec APIs.

- [ ] **Step 3: Implement streamed bounded scan and binary codec**

`preparedDeck` performs grouped aggregate plus one ordered cursor scan, retains
only the parent and per-child page budgets, maps on `Dispatchers.IO`, reports
SQL/materialized row counts, and never calls `queryTimelinePage` in a child
loop. Encode all strings as UTF-8 length-prefixed values, all counts with
validated fixed-width integers and magic `FLDK`/version `1`.

`MainActivity.handleQueryCall("readDashboardPreparedDeck")` performs service
and encoding inside the existing IO context and returns `ByteArray`. Live event
encoding is also performed under `flowOn(Dispatchers.IO)` before
`events.success(bytes)`.

- [ ] **Step 4: Run native GREEN and existing core tests**

Expected: new tests and all existing native tests pass.

- [ ] **Step 5: Commit**

```bash
git add android/fluvi-core/src/main android/fluvi-core/src/test android/app/src/main android/app/src/test
git commit -m "refactor: prepare dashboard decks in constant native batches"
```

### Task 7: Worker-isolate binary decoder and production repository

**Files:**
- Create: `lib/features/dashboard/prepared/data/dashboard_prepared_binary_codec.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Test: `test/features/dashboard/prepared/dashboard_prepared_binary_codec_test.dart`
- Test: `test/features/dashboard/query/method_channel_dashboard_ledger_repository_test.dart`

**Interfaces:**
- Consumes: native `FLDK` v1 bytes and `DashboardPreparedDeckRequest`.
- Produces: complete prepared deck/live frame/page after `Isolate.run`.

- [ ] **Step 1: Write failing byte-fixture and worker-boundary tests**

Test exact fixture decode, all LogBox strings/group order/row IDs/assets/cursor,
wrong magic/version, oversized lengths/counts, request/key/revision mismatch and
proof that the injected decoder executes with an isolate debug name different
from the UI isolate.

```dart
test('repository returns an already projected deck from its worker', () async {
  final repository = MethodChannelDashboardLedgerRepository(
    channel: channelReturning(validDeckBytes), worker: recordingWorker,
  );
  final deck = await repository.prepareDeck(request, token);
  expect(recordingWorker.invocations, 1);
  expect(deck.frames.values.every((f) => f.logBox.queryKey == f.queryKey), isTrue);
});
```

- [ ] **Step 2: Run RED**

Expected: nested-map decoder/new contract mismatch.

- [ ] **Step 3: Implement bounded decoder/projector**

Use `ByteData.sublistView`, explicit remaining-byte/count limits, the canonical
money/time/day formatter and contiguous native row order to build immutable
groups without resorting. Call through an injectable worker whose production
implementation is `Isolate.run(() => DashboardPreparedBinaryCodec.decode(bytes, request: request),
debugName: 'fluvi-dashboard-prepared-decode')`.

Remove production child-summary and nested child-preview calls from the method
channel adapter. Decode live/page bytes through the same worker codec.

- [ ] **Step 4: Run GREEN and commit**

```bash
git add lib/features/dashboard/prepared/data lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart test/features/dashboard/prepared test/features/dashboard/query/method_channel_dashboard_ledger_repository_test.dart
git commit -m "refactor: decode dashboard frames outside the UI isolate"
```

### Task 8: Structural navigation and core four-owner orchestration

**Files:**
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart`
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_bootstrap_controller.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Test: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_startup_test.dart`
- Test: `test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart`

**Interfaces:**
- Consumes: Motion Kernel, pipeline, coalescer/store and repository.
- Produces: structural navigation intents and one exact warm/cold deck activation
  path; bootstrap future.

- [ ] **Step 1: Write failing orchestration tests**

Test that preview crossing calls only O(1) frame selection, structural cold
navigation keeps old coherent frame while a delayed deck resolves, warm target
publishes in one frame, seed starts no request before gate, and rapid A→B→C
rejects A/B.

- [ ] **Step 2: Run RED**

Expected: old core still owns mixed query/summary/store/prewarm state.

- [ ] **Step 3: Rewrite core as a small orchestration façade**

Required owned fields:

```dart
final DashboardMotionKernel motion;
final DashboardNavigationController navigation;
final DashboardPreparedDeckPipeline prepared;
final DashboardVisibleFrameStore visibleFrames;
final DashboardDisplayFrameCoalescer frameCoalescer;
final DashboardCommittedQueryController committed;
```

`_onSemanticCrossed` performs only `activeDeck.frames[entry.queryKey]` and
`frameCoalescer.request`. `navigateParent/navigatePlane/selectDirection` derives
one target key/lookup, starts local structural state immediately, and activates
only a complete exact-generation deck. Bootstrap prepares one initial deck,
installs it and publishes the parent frame only after revision > 0.

- [ ] **Step 4: Run targeted GREEN and commit**

```bash
git add lib/features/dashboard/time_navigation lib/features/dashboard/application/dashboard_core_controller.dart lib/features/dashboard/application/dashboard_bootstrap_controller.dart lib/app/shell/fluvi_app_shell.dart test/features/dashboard/application test/features/dashboard/time_navigation
git commit -m "refactor: compose dashboard from four independent state owners"
```

### Task 9: Committed live query and prepared paging

**Files:**
- Create: `lib/features/dashboard/query/application/dashboard_committed_query_controller.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_paging_coordinator.dart`
- Test: `test/features/dashboard/query/application/dashboard_committed_query_controller_test.dart`
- Test: `test/features/dashboard/logbox/dashboard_log_paging_coordinator_test.dart`

**Interfaces:**
- Consumes: committed visible frame, prepared live-frame stream and prepared
  page repository.
- Produces: immutable `DashboardCommittedState`, one lease, stale rejection,
  exact accepted live frame and committed-only page frame.

- [ ] **Step 1: Write failing lease/settle/stale tests**

```dart
test('settle promotes visually once and starts one exact lease', () async {
  core.crossTo(day15); scheduler.fireFrame();
  final before = visible.visiblePublishCount;
  core.settle(day15);
  expect(visible.visiblePublishCount, before);
  expect(repository.liveStarts, 1);
  expect(visible.logRebindCount + visible.amountRestartCount, 0);
});
```

Also test preview starts zero leases, old direction/revision/epoch/generation
responses reject, same-digest live no-op and paging unavailable in preview.

- [ ] **Step 2: Run RED**

Expected: missing committed controller and old timer lease behavior.

- [ ] **Step 3: Implement immediate generation-guarded single lease**

No Timer. Cancel old subscription before starting a new one. Verify every
identity field before requesting visible publication. Live completion never
calls motion/navigation. Prepared paging merges off-isolate and submits one
committed frame with the same exact key/revision.

- [ ] **Step 4: Run GREEN and commit**

```bash
git add lib/features/dashboard/query/application/dashboard_committed_query_controller.dart lib/features/dashboard/logbox/application/dashboard_log_paging_coordinator.dart test/features/dashboard/query/application test/features/dashboard/logbox/dashboard_log_paging_coordinator_test.dart
git commit -m "refactor: make live dashboard data committed-only"
```

### Task 10: UI subtree and LogBox pointer isolation

**Files:**
- Modify: `lib/core/motion/dashboard_motion_host.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`
- Modify: `lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart`
- Test: `test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Test: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`

**Interfaces:**
- Consumes: structural navigation/motion and atomic visible-frame selectors.
- Produces: stable isolated UI subtrees with direct prepared VM pointer swaps.

- [ ] **Step 1: Write failing rebuild/identity tests**

Pump 100 visible child frames and assert root/header shell/rail/pulse rebuild
counts unchanged while amount/count/log leaves update at most 100 times. Pump
100 open/close/plane/direction/parent transitions and assert identical rail
controller/physics/position and LogBox State/ScrollController. Assert pulse
controller restart count changes only on direction selection.

- [ ] **Step 2: Run RED**

Expected: old store/adapter builders and header fan-out violate counters.

- [ ] **Step 3: Wire narrow selectors and stable viewport**

Remove `_presentationFromStore`, raw snapshot imports and
`DashboardLogPresentationAdapter`. Give SummaryPill amount, count leaf and
LogBox content distinct typed selectors over the same visible frame. Keep the
LogBox shell/CustomScrollView/ScrollController mounted; swap only immutable
`DashboardLogViewportState`. Start SummaryPill shell return controller before
calling the navigation intent. Keep SVG as the cached AnimatedBuilder child.

- [ ] **Step 4: Run widget GREEN without goldens and commit**

```bash
git add lib/core/motion/dashboard_motion_host.dart lib/features/dashboard/presentation test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart
git commit -m "refactor: isolate dashboard presentation subtrees"
```

### Task 11: Parent, plane, direction and randomized invariant coverage

**Files:**
- Create: `test/features/dashboard/application/dashboard_motion_data_isolation_test.dart`
- Create: `test/features/dashboard/application/dashboard_navigation_property_test.dart`
- Modify: `test/features/dashboard/application/dashboard_parent_navigation_performance_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart`

**Interfaces:**
- Consumes: complete core test fixture with controllable scheduler/repository.
- Produces: all deterministic tests in checklist TEST-01 through TEST-15.

- [ ] **Step 1: Add exact required scenario tests**

Cover 100 no-I/O crossings; density invariance 0/1/94/658; first/tenth parity;
long fling; 100 repeat target; frame coalescing; settle no-op; stable identities;
Jul31→Jun30, Jun30→Jul30, May/Dec year preservation; empty/populated;
cold/warm; rapid A→B→C; open/closed direction; revision/seed; rapid plane
transitions; LogBox stability.

- [ ] **Step 2: Add deterministic seeded property test**

```dart
for (final seed in List.generate(100, (i) => i + 1)) {
  final random = Random(seed);
  for (var step = 0; step < 250; step++) fixture.apply(randomEvent(random));
  expect(fixture.visible.queryKey, fixture.expectedVisibleQueryKey);
  expect(fixture.visible.coreRevision, fixture.expectedRevision);
  expect(fixture.visible.hasAtomicLanes, isTrue);
  expect(fixture.ioDuringMotion, 0);
}
```

- [ ] **Step 3: Run the suite and fix only canonical owners until GREEN**

Do not adjust physics/constants or test tolerances based on density. Use one
fixed timing/target tolerance justified by Flutter test-frame granularity.

- [ ] **Step 4: Commit**

```bash
git add test/features/dashboard/application test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart
git commit -m "test: prove dashboard motion data isolation invariants"
```

### Task 12: Required profile-safe diagnostics

**Files:**
- Create: `lib/features/dashboard/diagnostics/dashboard_runtime_diagnostics.dart`
- Modify: `lib/features/dashboard/application/dashboard_performance_counters.dart`
- Modify: Motion Kernel, pipeline, visible store, committed controller and UI
  counter call sites.
- Test: `test/features/dashboard/diagnostics/dashboard_runtime_diagnostics_test.dart`
- Test: `test/features/dashboard/application/dashboard_performance_counters_test.dart`

**Interfaces:**
- Produces all required event enum values/context and fixed counters with a
  disabled allocation-bounded hot path.

- [ ] **Step 1: Write failing event/counter tests**

Assert exact event names, bounded ring behavior, context field retention,
per-crossing toggle, no pixel event API and exact counter slots including
publishes per display frame and identity recreation counts.

- [ ] **Step 2: Implement typed events and fixed slots**

```dart
enum DashboardRuntimeEventKind {
  motionGestureStarted, motionBallisticStarted, motionSemanticCrossed,
  motionFrameTargetSelected, visibleFramePublished, motionSettled,
  committedFramePromoted, liveLeaseStarted, liveFrameAccepted,
  preparedDeckCacheHit, preparedDeckCacheMiss, preparedDeckStarted,
  preparedDeckReady, preparedDeckDiscarded, staleCallbackRejected,
}
```

Each record includes every required epoch/key/revision/index/frame/source and
optional duration. Use a fixed-capacity `ListQueue` only when enabled; disabled
record methods return before string/detail construction. Counters use a fixed
`List<int>`.

- [ ] **Step 3: Run GREEN and commit**

```bash
git add lib/features/dashboard/diagnostics lib/features/dashboard/application/dashboard_performance_counters.dart lib/features/dashboard/motion lib/features/dashboard/prepared lib/features/dashboard/visible lib/features/dashboard/query/application/dashboard_committed_query_controller.dart lib/features/dashboard/presentation test/features/dashboard/diagnostics test/features/dashboard/application/dashboard_performance_counters_test.dart
git commit -m "feat: add profile safe dashboard isolation diagnostics"
```

### Task 13: Delete the old architecture and close the boundary

**Files:**
- Delete every old production file listed in the file map after imports/tests
  have migrated.
- Modify affected old tests to target canonical owners or remove tests that
  exercised a deleted private architecture while retaining their behavioral
  assertions in Tasks 4–11.
- Modify: `test/boundary/dashboard_motion_data_isolation_boundary_test.dart`
- Modify: `scripts/verify-fluvi-boundaries.sh` if it enumerates boundary tests.

**Interfaces:**
- Produces: one canonical production dependency graph and green fail-closed
  boundary suite.

- [ ] **Step 1: Remove old files/imports/routes in one migration wave**

Delete metrics-only summary/index, parent bundle/display store, LogBox adapter,
old background/rail/prewarm coordinators, current query/timer lease and nested
bridge calls. Remove compatibility getters that retain state or notifications.
Only stateless type aliases are permitted when an exported name is genuinely
external.

- [ ] **Step 2: Scan for prohibited residue**

Run:

```bash
rg -n "DashboardSummaryMetricsController|DashboardParentBundleRegistry|DashboardPresentationStore|DashboardLogPresentationAdapter|DashboardLiveQueryLeaseCoordinator|CurrentQueryController|temporary|legacy|fallback old|isBallistic|ignore while ballistic|Timer\(" lib/features/dashboard android/app/src/main android/fluvi-core/src/main
```

Expected: no old production owner or prohibited workaround match. Legitimate
unrelated `fallback` visual token text must be manually classified and is not a
data-path exception.

- [ ] **Step 3: Run boundary suite GREEN**

Run all `test/boundary/*_test.dart` in Ubuntu proot. Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add -A lib/features/dashboard android/app/src/main android/fluvi-core/src/main test/features/dashboard test/boundary scripts/verify-fluvi-boundaries.sh
git commit -m "refactor: remove legacy dashboard presentation paths"
```

### Task 14: Full non-golden verification and static analysis

**Files:**
- Modify only source/tests required by real failures.
- Update: acceptance checklist statuses with command evidence.

**Interfaces:**
- Produces: locally verified Dart/native implementation, without claiming
  physical profile completion.

- [ ] **Step 1: Format mechanically**

Run `dart format` inside Ubuntu proot on changed Dart files. This is a mechanical
rewrite and does not replace review.

- [ ] **Step 2: Run focused Flutter suites**

Run boundary, motion, prepared, visible, query, application, presentation and
LogBox non-golden test directories. Expected: PASS.

- [ ] **Step 3: Run complete non-golden Flutter suite**

```bash
proot-distro login ubuntu -- bash -lc "cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && find test -type f -name '*_test.dart' ! -name '*_golden_test.dart' -print0 | xargs -0 /home/flutteruser/flutter/bin/flutter test"
```

Expected: all tests pass; no golden test is run.

- [ ] **Step 4: Run analyze and native verification**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze --no-fatal-infos && ./scripts/verify-fluvi-boundaries.sh && cd android && ./gradlew :fluvi-core:testDebugUnitTest :app:testDebugUnitTest --no-daemon'
```

Expected: no errors; any pre-existing info lints are reported honestly.

- [ ] **Step 5: Review diff/checklist and commit fixes**

```bash
git diff --check
git status --short
git diff --stat bb6c294..HEAD
```

Verify no user untracked file is staged and no golden asset changed.

### Task 15: Reproducible profile scenarios A–J

**Files:**
- Modify: `integration_test/dashboard_interaction_profile_test.dart`
- Modify: `integration_test/support/dashboard_profile_fixture_repository.dart`
- Modify: `integration_test/support/dashboard_profile_report.dart`
- Modify: `test/performance/dashboard_profile_report_test.dart`
- Modify: `scripts/run-dashboard-profile.sh`
- Modify: `test_driver/dashboard_profile_driver.dart`
- Modify: `.github/workflows/fluvi-core.yml`
- Create: `docs/dashboard/dashboard-motion-data-profile-report.md`

**Interfaces:**
- Consumes: runtime diagnostics/counters and deterministic gesture driver.
- Produces: validated JSON/timeline report with scenarios A–J and before/after
  comparison.

- [ ] **Step 1: Write report-schema tests RED**

Require scenario ID, device/build metadata, UI/raster p50/p90/p95/p99/max,
missed frames, build/layout/paint, GC/allocation/RSS, SQL/channel/decode,
visible publish, I/O-during-motion, target/settle, first/tenth and
empty/populated comparison fields. Reject missing/nonnumeric evidence.

- [ ] **Step 2: Implement scenarios A–J without correctness prewarm**

Use identical start position and fling velocity per comparison, bracket each
motion with diagnostic gesture/settle events, run logger minimal, and assert
SQL/platform/repository/lease/projection counters remain zero during motion.
Warm-cache setup may be a named comparison condition, never a prerequisite.

- [ ] **Step 3: Run report/unit tests and build profile harness online**

The local phone must not build the APK. Push/Actions in Task 17 creates the
profile APK. On a connected Android device run
`scripts/run-dashboard-profile.sh -d <device-id>` and retain generated JSON and
timeline artifacts outside generated build output; document exact device and
command.

- [ ] **Step 4: Compare before/after honestly**

Use the baseline artifacts/log timings available from the milestone and the
new run. Do not invent missing frame values. All checklist profile rows become
`DONE` only when a real/current benchmark environment produced numeric data
and automated acceptance assertions passed.

- [ ] **Step 5: Commit harness/report**

```bash
git add integration_test test/performance scripts test_driver .github/workflows/fluvi-core.yml docs/dashboard/dashboard-motion-data-profile-report.md
git commit -m "test: benchmark complete dashboard motion isolation"
```

### Task 16: Final cleanup, verification review and documentation

**Files:**
- Update: `docs/superpowers/checklists/2026-08-05-dashboard-complete-motion-data-isolation.md`
- Update: `docs/dashboard/dashboard-motion-data-root-cause.md`
- Update: `docs/dashboard/dashboard-motion-data-profile-report.md`
- Create: `docs/dashboard/dashboard-motion-data-refactor-report.md`

**Interfaces:**
- Produces: truthful 20-item final report and clean implementation commit.

- [ ] **Step 1: Re-read the full user spec, checklist and approved design**

Map every criterion to test/profile/source evidence. Leave `PARTIAL` or
`BLOCKED` rather than converting missing physical evidence to `DONE`.

- [ ] **Step 2: Run forbidden-pattern and dead-code scan**

Scan for old owner names, TODO/temporary/legacy/fallback flags, duplicate
formatters/cache/gesture engines, timers/debounces and motion callbacks with
I/O. Inspect all files above 500 lines for mixed responsibilities; no modified
mixed file may remain above 800 lines without a cohesive renderer reason.

- [ ] **Step 3: Write the final detailed report**

Include exact root cause, old/new components, rewritten/deleted files, hot
path, native/worker pipeline, open-rail navigation, live ownership,
cache/revision/seed, rebuild boundaries, numeric before/after, density,
cold/warm, first/tenth, tests, no-I/O evidence, settle no-op evidence,
identity evidence and the exact source commit hash, resolved after the final
source commit via a documentation-only amend when necessary.

- [ ] **Step 4: Invoke verification-before-completion and rerun required checks**

Fresh output is required; prior green logs are not sufficient for final claims.

- [ ] **Step 5: Commit final source/docs**

```bash
git add -A ':!*.tmp-*' ':!test/features/dashboard/presentation/failures'
git diff --cached --name-only
git commit -m "refactor: complete dashboard motion data isolation"
```

### Task 17: Push, GitHub build, APK download and final handoff

**Files:**
- No source mutation unless CI reveals a real defect; fixes repeat focused and
  full verification before a new commit.

**Interfaces:**
- Produces: remote branch, green Actions, downloadable debug/profile artifacts,
  local APK path and final commit hash.

- [ ] **Step 1: Push the dedicated branch**

```bash
git push -u origin refactor/dashboard-complete-motion-data-isolation
```

- [ ] **Step 2: Monitor GitHub Actions to terminal success**

Verify native tests, Flutter analyze/non-golden tests, debug APK and profile
harness jobs for the final commit. If a job fails, inspect logs, implement the
smallest architecture-consistent fix, rerun local verification, push and wait
again.

- [ ] **Step 3: Download APK to the requested Android directory**

Download the final release/artifact APK into
`/storage/emulated/0/Download/fluvi`, preserving a commit-addressed filename,
and calculate SHA-256. Do not overwrite unrelated user files.

- [ ] **Step 4: Record final hash and artifact evidence**

Update report/checklist only if that update can be committed and its resulting
CI build remains traceable; otherwise report the source commit hash and
artifact commit hash distinctly.

- [ ] **Step 5: Deliver the self-contained Hungarian final report**

Lead with completion/checklist truth, include local APK path/hash and GitHub
build link, then the requested 20 evidence items. Mention no internal planning
or tool details beyond what is useful for verification.

## Plan self-review

- Spec coverage: Tasks 1–13 implement architecture, every required deterministic
  test is enumerated in Task 11, Task 15 covers scenarios A–J and all metrics,
  Tasks 16–17 cover cleanup/report/commit/push/build/download.
- Placeholder scan: the plan contains no deferred implementation marker; the
  report's final hash is explicitly resolved by the final commit workflow.
- Type consistency: catalog → prepared deck/frame → visible frame → committed
  state is the same type flow throughout; repository produces only prepared
  values; UI consumes only visible frame submodels.
- Execution mode: inline only, as required by the user. The next action is to
  load `executing-plans` and begin Task 1; no execution-choice question is
  needed.
