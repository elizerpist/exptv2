# Retained Render And Cache Pipeline Design

Date: 2026-07-12

Checklist: `docs/superpowers/checklists/2026-07-12-retained-render-cache-checklist.md`

## Goal

After the first app load, the user should not see gray loading or circular progress screens when switching income/expense, home/stats, summary scopes, threshold values, snapshots, or bottom-nav tabs. The app should keep the last complete UI visible, prepare new data/render frames invisibly, and publish the new frame atomically when ready.

This is a retained UI and cache architecture change, not a visual redesign.

## Current Findings

- `ExptShell` already creates a long-lived `TransactionStore`, a long-lived `StatsPageController`, `_transactionHomePage`, `_statsPage`, and `_retainedTabPages`. It uses `PageView.builder` plus `_RetainedShellTab`/`TickerMode`, so the shell already has the beginning of a retained-tab model.
- `PageView.builder` means pages are still constructed lazily as the user visits them. That is good for memory but conflicts with the user's request that the common home/stats routes are already warm after first load.
- `TransactionStore.start()` is already guarded by `_startCompleted` and `_startFuture`, and the store has home-side caches plus `_prewarmCriticalCaches`.
- `TransactionStore` still uses broad invalidation for summary changes and reloads. That can stay initially, but the new design needs a versioned invalidation model so visible switches can be selection-only where possible.
- `StatsPage` has a local `StatsRenderFrameCache`, local in-flight scheduling, pending type/snapshot state, and a `_buildFramePending()` spinner screen.
- `StatsRenderFrameCache` currently stores only one key/frame pair. This is the direct reason common switches miss cache and fall into pending UI.
- `StatsRenderFrameWorker` already builds frames off the UI isolate through `Isolate.run`, which is the right direction. The missing layer is a multi-key cache/prewarm coordinator and stale-frame UI policy.
- Existing stats tests currently assert pending/spinner states in some paths. Those tests must be rewritten to assert retained stale frame plus final publish.

## Main Decision

Do not try to "load the stats menu from the VGA/GPU" as a primary fix. In Flutter, the GPU/raster side draws and composites already prepared render objects; it does not run transaction aggregation, threshold filtering, snapshot recall, scope selection, or Dart widget build decisions.

The recommended architecture is:

1. Keep app/page state retained.
2. Keep transaction data in a long-lived, versioned store.
3. Move expensive aggregation/render-frame production behind keyed caches.
4. Prewarm the common routes and neighboring states.
5. During any warm interaction, keep the last complete frame visible.
6. Optimize widget/raster cost only after measuring which stats surfaces are expensive.

This is intended to satisfy RRC-001 through RRC-020 without turning the UI into a full custom canvas rewrite up front.

## Proposed Architecture

### 1. Retained App Shell

Owner: `lib/features/shell/expt_shell.dart`

`ExptShell` should remain the owner of long-lived app objects:

- `TransactionStore`
- stats render/aggregation cache coordinator
- stats snapshot repository
- retained home/stats page widgets
- lifecycle sync service

The current retained map can be upgraded in one of two ways:

- Eagerly create home and stats pages at shell init after dependencies exist.
- Keep `PageView.builder`, but pre-seed `_retainedTabPages` for home and stats before user interaction and run stats frame prewarm before the first stats tab tap.

The second option is less risky because it preserves the current shell shape, while still meeting RRC-007 and RRC-012.

### 2. Lifecycle Sync

New owner candidate: `LifecycleSyncService` or a small shell-owned coordinator.

Resume should never recreate the store or page state. It should:

1. Keep the current `AppTab`, stats scope, page index, active type, threshold, selected snapshot, category/vendor filters, search query, and scroll positions as-is.
2. Ask event/native sources for deltas.
3. Merge changed transactions into `TransactionStore`.
4. Bump a transaction data version only if data actually changed.
5. Mark affected caches dirty.
6. Queue background prewarm for the currently visible state and likely neighboring states.
7. Publish new frames when ready without showing a blocking overlay.

The existing `didChangeAppLifecycleState()` paths in `ExptShell` are the correct hook, but the work should be made explicit and non-resetting.

### 3. Versioned Store Snapshot

Owner: `TransactionStore`

Add stable version counters instead of using list object identity as the only data revision:

- `transactionDataVersion`
- `categoryDataVersion`
- `limitDataVersion` if home budget/summary output needs it
- optional `recurringGhostVersion`

These versions should increment only when the underlying data actually changes. Cache keys should depend on versions, not mutable list references.

`TransactionStore` should keep its current home caches, but the invalidation rules should become narrower over time:

- Type switch should read already-warmed per-type visible data.
- Summary scope changes should invalidate scope-specific summaries, not every unrelated cache.
- External transaction merge should invalidate affected transaction/category/home/stat keys.
- Reload should remain a fallback for operations that cannot produce deltas yet.

### 4. Aggregation Cache

New owner candidate: `StatsAggregationCache`.

This layer stores CPU/Dart business data, not widgets:

- total income/expense
- per-type transaction sets
- yearly/monthly/all-time summary aggregates
- category and vendor scoped aggregates
- threshold-independent raw day/month/year buckets
- threshold-dependent derived buckets where needed

The key principle is to split threshold-independent work from threshold-dependent presentation. A joystick threshold step should not require rebuilding raw period/category/vendor aggregation from scratch.

### 5. Render Frame Cache

Owner: replace/expand `StatsRenderFrameCache`.

The current cache is single-entry. Replace it with a bounded multi-entry cache, probably LRU or small fixed window, keyed by:

- transaction data version
- category data version
- active type
- summary scope
- year/month
- selected category IDs
- vendor names
- normalized search query
- threshold value or threshold bucket
- layout/page mode if it changes frame output
- theme/layout dimension key only where output geometry actually depends on it

The cache value remains a `StatsRenderFrame` or a split pair:

- `StatsAggregationFrame`: data-heavy, threshold/scoped model.
- `StatsVisualFrame`: preformatted labels, chart samples, cell colors, paint geometry inputs.

Splitting can be deferred until measurement proves the current `StatsRenderFrame` object is too broad.

### 6. Prewarm Scheduler

New owner candidate: `PrewarmScheduler`.

Prewarm work should be prioritized:

1. Current visible frame.
2. Opposite income/expense type for the current scope.
3. Home income/expense visible data.
4. Stats current summary scope for both types.
5. Adjacent summary periods where useful.
6. Current snapshot and neighboring snapshots.
7. Threshold neighbor buckets around the current threshold.

Prewarm must yield to UI. It should run after first frame, in idle/post-frame slices, or through the existing isolate worker. It should coalesce duplicate requests and drop stale generations.

### 7. Warm Interaction Policy

This should be the global UI contract:

- Cold start with no data: show initial loading.
- Warm state with old complete frame: keep the old frame visible.
- New target frame missing: queue worker/prewarm and show old frame with updated controls where safe.
- New frame ready: publish it atomically.
- Error: keep the last good frame visible if possible and surface error non-blockingly.

`StatsPage._buildFramePending()` should not be used for warm type/snapshot/summary/threshold switches. It may remain only for the first ever stats frame if no last-good frame exists.

### 8. Threshold Joystick

Threshold should have two layers:

- Immediate preview state: the displayed threshold number/control changes on every joystick step.
- Final frame state: expensive threshold-derived stats are coalesced and built after a short idle/debounce window or after the current frame.

If the cache already has the target threshold bucket, publish immediately. If not, keep the current chart/grid visible or use a cheap preview overlay, then publish the final frame.

This keeps RRC-009 smooth without pretending all threshold math can be moved to GPU.

### 9. Snapshot Recall

Snapshot recall should avoid the current full pending path:

1. Apply the snapshot's cheap local UI state immediately where possible.
2. Resolve the target cache key.
3. If cached, publish immediately.
4. If missing, keep the current last-good frame visible and queue the target frame.
5. Commit store mutation only when the target generation is still latest.

Current race handling through `StatsSnapshotRecallGeneration` is useful and should be preserved.

### 10. GPU/Raster-Oriented Rendering

Only after cache/prewarm changes are measured, optimize Flutter rendering cost:

- Keep `RepaintBoundary` around stable stats regions.
- Avoid `Opacity`/`saveLayer`-like expensive routes unless needed.
- Convert very dense month/year grids or charts to `CustomPainter` if widget build/layout cost remains high.
- Keep hit testing by mapping pointer position to cell geometry in a gesture layer.
- Consider `ui.Picture` caching only for repeated static paint content.

This is the Flutter equivalent of the user's "VGA/GPU" intuition: make the CPU produce fewer and more stable render instructions, then let the raster pipeline repaint less.

## Implementation Phases

### Phase 1: Contract And Instrumentation

- Add cache hit/miss and prewarm logs.
- Add tests that define the new no-spinner warm interaction contract.
- Mark existing spinner-expecting tests for rewrite.

Covers: RRC-002, RRC-019, RRC-020.

### Phase 2: Shell And Lifecycle Retention

- Pre-seed retained home and stats pages.
- Keep lifecycle resume non-resetting.
- Add resume delta sync contract tests.

Covers: RRC-001, RRC-003, RRC-004, RRC-007, RRC-012.

### Phase 3: Multi-Key Stats Frame Cache

- Replace single-entry `StatsRenderFrameCache` with bounded multi-entry cache.
- Use explicit store versions in `StatsRenderFrameKey`.
- Prewarm current/opposite type and summary scopes.

Covers: RRC-008, RRC-011, RRC-015, RRC-016.

### Phase 4: Stale-While-Revalidate Stats UI

- Remove warm spinner behavior from type, summary, snapshot, threshold paths.
- Preserve last-good stats frame while target frame builds.
- Keep generation cancellation/out-of-order safety.

Covers: RRC-002, RRC-008, RRC-009, RRC-010, RRC-011, RRC-013.

### Phase 5: Home Cache Refinement

- Keep home transaction lazy list behavior intact.
- Narrow invalidation for type and summary changes.
- Prewarm both home types and common summary scopes.

Covers: RRC-005, RRC-006, RRC-018.

### Phase 6: Measured Render Optimization

- Use DevTools/profile evidence to decide whether stats grid/chart widgets need `CustomPainter`.
- If needed, convert the most expensive repeated surfaces first and keep hit testing behavior.

Covers: RRC-014, RRC-017, RRC-020.

## Verification Strategy

Local Flutter commands must run through Ubuntu proot, for example:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart'
```

Do not run local Flutter APK builds in Termux. APK builds must use GitHub Actions.

Minimum targeted verification after implementation:

- `flutter test test/stats/stats_render_frame_test.dart`
- `flutter test test/stats/stats_page_test.dart`
- `flutter test test/shell/expt_shell_test.dart` if present, or add targeted shell tests
- `flutter analyze`
- manual/profile Android run for cold start, home/stats switching, threshold joystick, snapshot swipe, summary navigation, pause/resume with an injected/new transaction

## Open Risks

- Prewarming every possible frame can waste memory and battery. Use bounded cache size and priority-based prewarm.
- Keeping stale frames visible can confuse users if controls update before charts do. Prefer atomic publish for data-heavy visuals and a small non-blocking refresh indicator only if needed.
- Snapshot recall currently combines local state and store mutation. The final design must preserve race safety so old snapshot worker results cannot overwrite newer selections.
- Broad `TransactionStore._reload()` paths will still invalidate many caches until native/data-layer delta APIs are available.
- CustomPainter work can improve build/layout cost but can also regress accessibility/testability if introduced too early. It should be a measured phase, not the first fix.
