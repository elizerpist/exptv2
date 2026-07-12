# Retained Render Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove warm stats loading/pending screens by retaining the last complete stats frame, using a bounded multi-key render-frame cache, and prewarming common stats targets.

**Architecture:** Keep the existing `StatsPage`/worker shape, but replace the single-entry frame cache with a bounded multi-entry cache. Change warm frame misses from "show pending spinner" to "keep last-good frame visible, queue target frame, publish atomically"; keep first cold stats frame as the only allowed pending state.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing `StatsRenderFrameWorker`, existing `TransactionStore`, Ubuntu proot Flutter commands.

## Global Constraints

- Do not run local Flutter APK builds in Termux; APK builds belong on GitHub Actions.
- Run local Flutter tests/analyze through Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Do not revert unrelated dirty worktree changes.
- Production behavior changes require a failing test first.
- This pass targets RRC-002, RRC-008, RRC-009, RRC-010, RRC-013, RRC-015, RRC-016, and RRC-019. RRC lifecycle/home-wide refinements remain checklist items until implemented.

---

## Files

- Modify: `lib/features/stats/data/stats_render_frame.dart`
  - Responsibility: bounded multi-key `StatsRenderFrameCache`.
- Modify: `lib/features/stats/stats_page.dart`
  - Responsibility: stale-while-revalidate stats frame selection, warm no-spinner policy, prewarm scheduling.
- Modify: `test/stats/stats_render_frame_test.dart`
  - Responsibility: cache retains multiple frame keys and evicts bounded old entries.
- Modify: `test/stats/stats_page_test.dart`
  - Responsibility: high-volume type/search/snapshot warm paths retain content and do not show `stats-frame-pending` or `stats-type-switch-pending`.
- Modify: `docs/superpowers/checklists/2026-07-12-retained-render-cache-checklist.md`
  - Responsibility: update only rows actually completed by this pass.

## Task 1: Multi-Key StatsRenderFrameCache

**Files:**
- Modify: `test/stats/stats_render_frame_test.dart`
- Modify: `lib/features/stats/data/stats_render_frame.dart`

**Interfaces:**
- Consumes: `StatsRenderFrameKey`, `StatsRenderFrame`.
- Produces: `StatsRenderFrameCache({int capacity = 12})`, `resolve`, `lookup`, `seed`, `clear`.

- [ ] **Step 1: Write the failing test**

Add this test after `cache rebuilds when only data revision changes`:

```dart
test('cache retains multiple warm stats frames before evicting old keys', () {
  final categories = [
    category(id: 1, name: 'Expense', type: TransactionType.expense),
    category(id: 2, name: 'Income', type: TransactionType.income),
  ];
  final transactions = [
    record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
    record(id: 2, date: '2026-01-01', amount: 7000, categoryId: 2),
  ];
  final revision = Object();
  final cache = StatsRenderFrameCache(capacity: 2);
  var buildCount = 0;

  StatsRenderFrame frameFor(TransactionType type) {
    buildCount += 1;
    return StatsRenderFrame.build(
      year: 2026,
      month: 1,
      activeType: type,
      thresholdValue: 5000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
      today: DateTime(2026, 1, 10),
    );
  }

  StatsRenderFrameKey key(TransactionType type, double threshold) =>
      StatsRenderFrameKey(
        dataRevision: revision,
        activeType: type,
        summaryScope: StatsSummaryScope.yearly,
        year: 2026,
        month: 1,
        categoryIds: const {},
        vendorNames: const {},
        query: '',
        threshold: threshold,
      );

  final expense = cache.resolve(
    key(TransactionType.expense, 5000),
    () => frameFor(TransactionType.expense),
  );
  final income = cache.resolve(
    key(TransactionType.income, 5000),
    () => frameFor(TransactionType.income),
  );

  expect(cache.lookup(key(TransactionType.expense, 5000)), same(expense));
  expect(cache.lookup(key(TransactionType.income, 5000)), same(income));
  expect(buildCount, 2);

  final threshold = cache.resolve(
    key(TransactionType.expense, 10000),
    () => frameFor(TransactionType.expense),
  );

  expect(threshold, isNot(same(expense)));
  expect(cache.lookup(key(TransactionType.expense, 5000)), isNull);
  expect(cache.lookup(key(TransactionType.income, 5000)), same(income));
  expect(cache.lookup(key(TransactionType.expense, 10000)), same(threshold));
  expect(buildCount, 3);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_render_frame_test.dart --plain-name "cache retains multiple warm stats frames before evicting old keys"'
```

Expected: FAIL because `StatsRenderFrameCache` does not accept `capacity` and only stores one frame.

- [ ] **Step 3: Implement minimal cache**

Update `StatsRenderFrameCache` to store a `LinkedHashMap<StatsRenderFrameKey, StatsRenderFrame>`, refresh recency on lookup/resolve, and evict oldest entries when length exceeds `capacity`.

- [ ] **Step 4: Run test to verify it passes**

Run the same command. Expected: PASS.

## Task 2: Warm Type/Search Miss Keeps Last Frame Visible

**Files:**
- Modify: `test/stats/stats_page_test.dart`
- Modify: `lib/features/stats/stats_page.dart`

**Interfaces:**
- Consumes: `_lastRenderFrame`, `_lastRenderFrameKey`, `_frameForBuild`, `_scheduleFrameRequest`.
- Produces: warm frame misses return the last complete frame instead of `_buildFramePending()`.

- [ ] **Step 1: Write failing tests**

Change the high-volume type switch test so after tapping income it expects:

```dart
expect(find.byKey(const ValueKey('stats-type-switch-pending')), findsNothing);
expect(find.byKey(const ValueKey('stats-frame-pending')), findsNothing);
expect(find.byKey(const ValueKey('stats-content-switcher')), findsOneWidget);
expect(worker.requests, hasLength(2));
```

Change the high-volume search test so after search changes and stale worker completion it expects:

```dart
expect(find.byKey(const ValueKey('stats-frame-pending')), findsNothing);
expect(find.byKey(const ValueKey('stats-content-switcher')), findsOneWidget);
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "high-volume type switch schedules one internally consistent final frame" --plain-name "10k worker keeps feedback light and publishes only latest search frame"'
```

Expected: FAIL because current code shows `stats-type-switch-pending`/`stats-frame-pending` on warm misses.

- [ ] **Step 3: Implement stale-while-revalidate for warm misses**

In `StatsPage.build`, call `_frameForBuild(target)` and show `_buildFramePending()` only when there is no last complete frame at all. For warm misses, keep `_lastRenderFrame` visible while `_scheduleFrameRequest(target)` runs.

- [ ] **Step 4: Run tests to verify they pass**

Run the same command. Expected: PASS.

## Task 3: Snapshot Recall Avoids Warm Spinner

**Files:**
- Modify: `test/stats/stats_page_test.dart`
- Modify: `lib/features/stats/stats_page.dart`

**Interfaces:**
- Consumes: `_applySnapshot`, `_snapshotFramePending`, `StatsSnapshotRecallGeneration`.
- Produces: snapshot recall keeps current frame visible while target frame builds.

- [ ] **Step 1: Write the failing test**

In `snapshot recall publishes one final frame and keeps Page 2`, after tapping the snapshot card and before final pump completion, assert:

```dart
expect(find.byKey(const ValueKey('stats-frame-pending')), findsNothing);
expect(find.byKey(const ValueKey('stats-content-switcher')), findsOneWidget);
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "snapshot recall publishes one final frame and keeps Page 2"'
```

Expected: FAIL if snapshot recall still drives `_snapshotFramePending` into pending UI.

- [ ] **Step 3: Implement minimal snapshot no-spinner behavior**

Keep race handling and final atomic publish, but stop using `_snapshotFramePending` as a reason to build `_buildFramePending()` when `_lastRenderFrame` exists.

- [ ] **Step 4: Run test to verify it passes**

Run the same command. Expected: PASS.

## Task 4: Stats Prewarm Of Common Neighbor Frames

**Files:**
- Modify: `test/stats/stats_page_test.dart`
- Modify: `lib/features/stats/stats_page.dart`

**Interfaces:**
- Consumes: `_publishFrame`, `_frameTarget`, `_renderFrameCache`, `_renderFrameWorker`.
- Produces: `_prewarmStatsFrames(String reason)` queues opposite active type for the current scope without replacing visible UI.

- [ ] **Step 1: Write failing test**

Add a widget test using `ControlledStatsFrameWorker` that completes the initial expense frame and expects a second worker request for income prewarm without user tapping income.

- [ ] **Step 2: Run test to verify it fails**

Run the new test by `--plain-name`. Expected: FAIL because no prewarm request is queued.

- [ ] **Step 3: Implement minimal prewarm**

After `_publishFrame`, queue an opposite-type frame if it is not cached or in flight. Store prewarm keys in a small set so duplicate publish cycles do not spam workers.

- [ ] **Step 4: Run test to verify it passes**

Run the same command. Expected: PASS.

## Task 5: Checklist Update And Verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-12-retained-render-cache-checklist.md`

- [ ] **Step 1: Update only completed rows**

Set rows that are truly covered by the implemented tests to `DONE` or `PARTIAL`. Leave lifecycle/home-wide rows `NOT DONE` unless implemented.

- [ ] **Step 2: Run targeted stats tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_render_frame_test.dart test/stats/stats_page_test.dart'
```

Expected: PASS.

- [ ] **Step 3: Run analyze**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: PASS or report exact existing failures.

- [ ] **Step 4: Commit only this pass**

Run:

```bash
git add lib/features/stats/data/stats_render_frame.dart lib/features/stats/stats_page.dart test/stats/stats_render_frame_test.dart test/stats/stats_page_test.dart docs/superpowers/checklists/2026-07-12-retained-render-cache-checklist.md docs/superpowers/plans/2026-07-12-retained-render-cache-implementation.md
git commit -m "perf(stats): retain warm render frames"
```
