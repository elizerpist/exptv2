# Task 9 — Final clean-room review remediation report

## Status

`DONE` for every implementation and verification item in
`.superpowers/sdd/task-9-brief.md`.

The remediation itself deliberately performed no remote mutation. Subsequent
authorized delivery completed the push, GitHub Actions APK build, release
publication, download, and local SHA-256 verification recorded below.

The delivery-only checklist row `B2P-011` is `DONE`. Visual row `B2P-001`
remains `PARTIAL` until a fresh screenshot from the final GitHub-built APK can
be captured. All Task 9 review rows (`T7-R01` through `T7-R05`) are `DONE`.

## Architecture result

- `BudgetV2InteractionDiagnostics` is the only standalone B2 interaction
  trace owner. Shared-carousel step traces are controlled by an explicit
  presentation policy so permitted legacy routes keep their existing traces.
- `TransactionStore` filter-sensitive caches use an immutable structural
  `_TransactionFilterCacheKey`; the legacy display-log window adds its row
  limit with a typed `_BalanceVisibleDisplayLogCacheKey`.
- `BudgetV2LogProjectionCache` retains one immutable, fully ordered logical
  result per source/filter identity. `rowLimit` is excluded from that identity;
  each cumulative page is materialized from an ordered prefix and no materialized
  page windows are retained.
- Same-store prepared-snapshot revisions and structural vendor-data changes
  invalidate controlled vendor ticking.
- `BudgetV2SelectionController.cancelIfCurrent` explicitly restores committed
  state and invalidates the cancelled generation.
- Legacy display-log materialization now reuses the already ordered logical
  rows, eliminating the second full sort.

## TDD evidence

### T7-R01 — terminal-only standalone diagnostics

Focused RED:

- The real 4,096-record route rejected raw standalone output:
  `[BudgetV2AvatarRail] phase=start`, `phase=settle`,
  `[BudgetV2Carousel] phase=filter_schedule`, and `phase=commit`.

GREEN:

- Every standalone `[BudgetV2...]` entry is now a bounded terminal
  `[BudgetV2Interaction]` summary.
- Legacy belt/carousel trace tests remain green.

### T7-R02 — reusable deep B2 paging

Focused RED:

- Forty-three cumulative materializations from 96 through 4,096 rows produced
  43 cache misses and 43 full projections because `rowLimit` was part of the
  cache key.

GREEN:

- `cacheMissCount=1`
- `projectionCount=1`
- `fullScanCount=1`
- `materializationCount=43`
- `cachedQueryCount=1`
- `retainedLogicalRowCount=4096`
- `retainedMaterializedWindowCount=0`
- Cumulative record order, exact keys, ghost rows, and canonical date headers
  remain correct.

### T7-R03 — structural TransactionStore cache identity

Focused RED:

- Sequential scopes `{'ACME,Shop'}` then `{'ACME','Shop'}` reused the stale
  delimiter-joined cache entry (expected expense `50`, actual `100`).

GREEN:

- Immutable typed keys distinguish the two scopes for all relevant summary,
  visible/log, LRU, and display-window caches.
- The real B2 route keeps summary, chips, and local log aligned across the same
  sequential scope change.

### T7-R04 — same-store ticker revision invalidation

Focused RED:

- Deleting the pending target during a multi-step tick left the stale
  `Other Vendor` key selected.

GREEN:

- A same-store source revision/vendor-data change invalidates the ticker.
- The deleted vendor is absent from legend and log, the remaining rows stay
  visible, the controlled card vendor is `null`, and the store merchant scope
  is empty.

### T7-R05 — lifecycle and legacy projection cost

Focused RED:

- The selection controller had no cancellation transition.
- The legacy store had no evidence that display-log materialization avoided a
  second full ordering projection.

GREEN:

- Physical selection followed by cancellation returns to committed selection
  with zero offset; stale settle, commit, and cancel generations are rejected.
- A final read-only review found that a pending local avatar could be reset in
  the controller without rebuilding the already-rendered dashboard. The
  strengthened real route reproduced this RED (`rail selectedIndex` remained
  Food `1` instead of committed Overview `0`). The fix rebuilds only when the
  visible local avatar actually changes, advances the external rail epoch,
  and resets the local log window. GREEN now proves rail index `0`, Overview
  mother-card marker, both Overview log rows, and a successful later Food
  commit. The reviewer re-reviewed this follow-up and returned `APPROVED`.
- A subsequent independent review found a distinct private rail-state gap:
  after a direct release ticked from Overview to Food, a pointer-down could
  interrupt its residual motion and then lift without dragging while the
  carousel still rendered Food even though dashboard/controller state was
  already Overview. The exact real-route RED observed the Overview semantic
  selection as `false`. The rail now records that interruption and, only if
  the pointer ends without becoming a drag, resets its controller and retained
  items to the committed `selectedIndex`. If horizontal drag recognition
  begins, that reset is suppressed so the established restarted-drag residual
  handoff remains unchanged. GREEN proves Overview rail/card/log restoration,
  zero store notifications, and a subsequent physical preview with no store
  work; the pre-existing restarted-drag lifecycle contract also remains green.
  The fresh independent re-review returned `APPROVED` with no new important
  finding.
- Repeated logical/display reads report
  `legacyLogOrderProjectionCount == 1` and
  `legacyDisplayLogMaterializationCount == 1`.

## Final verification

All Flutter commands ran through Ubuntu/proot.

| Verification | Result |
| --- | --- |
| Exact Task 7 command: `spendee_budget_v2_contract_test.dart` + `budget_v2_interaction_diagnostics_test.dart` | `65/65`, exit 0 |
| Standalone 4,096-row deep-paging contract by exact name | `1/1`, exit 0 (`00:18`) |
| Query/selection/store suite | `63/63`, exit 0 |
| Full affected 18-file regression matrix | `247/247`, exit 0 |
| Full `flutter analyze` | `No issues found! (ran in 49.5s)` |
| Dart formatting | 13 changed-area files checked, 0 changes required |
| `git diff --check` | exit 0 |

Source inspection confirmed:

- no direct `DebugConsole` writer remains in
  `spendee_budget_v2_dashboard.dart`;
- shared carousel step writes are guarded by `emitDebugDiagnostics`, supplied
  from the standalone/legacy diagnostics scope;
- `BudgetV2InteractionDiagnostics` owns the standalone terminal write;
- store filter identities are immutable structural values rather than
  delimiter-joined strings;
- standalone B2 has no dependency on legacy Balance visible-log query/load-more
  APIs;
- B2 page identity excludes `rowLimit` and retains no materialized windows.

## Visual evidence

Reinspected:

`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`

The reference still contains the required Budget header, fixed five-avatar
rail, vendor distribution card, type/search/filter controls, cumulative log,
and bottom navigation structure. Task 9 changed lifecycle, diagnostics, cache,
and projection code only; no geometry or visual-token code was changed.

## Remediation scope discipline

- No remote mutation occurred during the Task 9 remediation implementation;
  delivery was intentionally deferred until the final clean review approved.

## Delivery evidence

- Code commit: `801e8b9a195c766c56c414fcd89112f16c72f759`, pushed to
  `feature/budget-v2-performance-rewrite`.
- GitHub Actions: [run #30572598567](https://github.com/elizerpist/exptv2/actions/runs/30572598567),
  successful for that exact `headSha`; the remote `debug-latest` tag resolves
  to the same commit.
- Release asset: `exptv2-debug-801e8b9.apk` (161,949,635 bytes), downloaded
  to
  `/storage/emulated/0/Download/exptv2-budget-v2-performance-rewrite-801e8b9/exptv2-debug-801e8b9.apk`.
- GitHub-provided and locally recomputed SHA-256:
  `18f440e4c1270ea5bc1974fa540d2d8e2508b3b0106af1751d7dc5eea5879772`.
