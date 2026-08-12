# Query Projection, Cancellation, and Candidate Retention Checklist

## Architecture card

### Scope and sources

- User requirement: remove whole-partition rich LogBox projection from staged
  Query readiness, cancel superseded native Query work, retain exact immutable
  candidates across sheet sessions, delay speculative chip preparation until
  the sheet is no longer foreground, and make diagnostics request-exact.
- Current implementation: `DashboardDataRuntime`,
  `DashboardPreparedIndexBinaryCodec`, `PreparedDashboardIndex`,
  `DashboardCoreController`, `DashboardLogBoxPreparedSceneCache`,
  `MethodChannelDashboardDataRuntimeRepository`, `MainActivity`, and
  `FluviLedgerReadService`.
- Comparison evidence: `e64e84aededa61f7f41124100309e819eceb269e` and later
  commits only; no earlier history is used.

### Single source and write path

| State | Owner | Write path | Publication rule |
| --- | --- | --- | --- |
| Compact immutable index data | `PreparedDashboardIndex` / `DashboardDataRuntime` | native partition decode or exact partition composition | Never becomes visible alone |
| Bounded rich LogBox projection | existing `DashboardLogBoxPreparedSceneCache` pipeline | exact scene-window preparation | Only complete active window may paint |
| Latest native Query generation | Android `MainActivity` Query coordinator | exact request generation | A superseded generation cannot return/publish |
| Prepared query candidate data cache | `DashboardCoreController` | exact composite query/revision LRU | immutable data may outlive an editor session; staged scene may not |
| Sheet foreground lifecycle | `FluviAppShell` | sheet state transition | speculative prewarm starts only after removal boundary |

### Reuse and centralization decision

| Mechanism | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Prepared scene/layout cache | `DashboardLogBoxPreparedSceneCache` | extend its input with bounded projection; no second cache | window tests and cache ownership checks |
| Query generation cancellation | `PreparedDashboardIndexBuilder` plus Android channel handler | preserve Dart token, add one native Query job owner | A→B→C cancellation test |
| Candidate LRU | `DashboardCoreController` | retain exact immutable data while discarding session scene staging | close/reopen cache test |
| Chip prewarm priority | `DashboardCoreController`/shell boundary | controller receives explicit post-dismiss signal | ordering test |

## Acceptance checklist

| ID | Requirement | Code area | Acceptance | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QP-01 | Direction-specific decode avoids opposite lane construction | codec/index assembly | Partition builds one semantic universe, not two then removes one | codec RED/GREEN test | DONE |
| QP-02 | Heavy index stays compact until needed rich window projection | codec/index/scene pipeline | Candidate readiness projects only its exact publication/current interaction domain | codec heavy-window fixture plus staged Query lifecycle test | DONE |
| QP-03 | Navigation remains fail-closed/RAM-only | core/scene cache | every published visible non-empty scope has an exact projected scene | scene-window, density, continuity and paging suites | DONE |
| QP-04 | Superseded native Query work cancels | Android channel/core service | A/B stop at checkpoints; only C can return | Kotlin cancellation test | BLOCKED — test task reaches `:app:processDebugResources`, then the Termux/proot AAPT2 daemon cannot start before tests execute |
| QP-05 | Complete immutable candidate survives close/reopen | core candidate LRU | exact revision/query hit avoids native rebuild; no stale scene activation | controller cache tests | DONE |
| QP-06 | Chip speculation is post-dismiss only | shell/core | ordering is publication → sheet removal → prewarm | deterministic controller test | DONE |
| QP-07 | Diagnostics identify exact request generation/query | core/runtime/native/shell | start/ready/cancel and apply timeline correlate by request identity | focused query lifecycle tests and static analysis | DONE |
| QP-08 | Protected behavior remains intact | rail/paging/query model | no physics/paging/ownership/fail-closed regression | 32 scene-window, 4 density, 46 query/continuity/paging and 6 codec tests; full analyzer | DONE |
| QP-09 | Delivery | CI/release/download | one final online build only after all code and tests | Actions + SHA-256 | NOT DONE |

## Root-cause record

At `03cb7dda`, the native partition reuse correctly avoids rebuilding the
unchanged direction.  The Dart codec still projects every decoded native row
through `DashboardLogViewModelProjector.presentRow` and constructs every sparse
`DashboardLogViewportState`; partition decoding also creates the dual zero
universe then removes the omitted direction.  The physical `projectionMicros`
therefore tracks whole-partition rich presentation allocation, not scene
layout.  A staged Apply correctly waits for that candidate, so it becomes
sheet-dismiss latency.  Native MethodChannel requests currently have no
generation job owner; Dart can reject a result but cannot stop obsolete native
SQL/mapping/serialization work.

## Scope constraints

- No rail physics, ScrollPosition/controller identity, committed paging,
  direction independence, scene fail-closed behavior, or Query Menu redesign.
- No render-time rich projection, SQL, MethodChannel work, or TextPainter.
- No new dashboard data/scene cache owner; bounded projection belongs under
  the current prepared LogBox scene pipeline.

## Follow-up rail readiness evidence

- An index replacement while the rail is already open activates the bounded
  immediate interaction bank atomically with the new immutable index. It does
  not widen ordinary Summary Pill publication barriers.
- A rail-open intent that arrives while a structural plane candidate is pending
  remains latest-intent state in `DashboardCoreController`. After the
  structural candidate commits, visibility derives from that final committed
  state; an old-plane rail candidate cannot supersede it.
- `dashboard_rail_density_trace_test.dart` verifies the full MONTH/DAY and
  YEAR/MONTH 30-repetition matrices. Populated rails paint positive slot counts
  (the YEAR path regressed to zero before this coordinator fix).
