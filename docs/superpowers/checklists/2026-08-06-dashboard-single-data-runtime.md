# Dashboard single data runtime acceptance checklist

Date: 2026-08-06

Source: the user's “FLUVI DASHBOARD — TELJES DATA/MOTION ARCHITEKTÚRA-CSERE”
instruction in the current conversation.

Baseline commit: `1bb0f1d51c30f37065da591391acb18d195111f5`

Branch: `refactor/dashboard-single-data-runtime`

Checkpoint tag: `milestone/dashboard-before-single-data-runtime-20260806`

Status vocabulary: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This checklist is the release gate. A green build is insufficient while any
row remains `PARTIAL`, `BLOCKED`, or `NOT DONE`.

## Safety, evidence and root cause

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| SAFE-01 | §1 | Git history | Baseline is recoverable, work is on a dedicated branch, and user-owned untracked files are untouched. | Commit/tag/branch/status inspection. | DONE |
| SAFE-02 | §1, §11 | rail and physics sources | Baseline hashes are recorded and no physics constant, gesture threshold, friction, velocity, snap, extent, controller or viewport mechanism is tuned. | SHA-256 before/after plus `git diff`. | DONE |
| SAFE-03 | §1 | baseline verification | Current non-golden Flutter result and current interaction/native counters are recorded before implementation. | 250/250 test log and baseline logcat counts. | DONE |
| ROOT-01 | §1 | root-cause audit | SummaryPill, plane, parent, rail open/close/cross/settle, direction, commit, watch, Room, bridge, decode and binding paths are traced to concrete methods. | `docs/dashboard/dashboard-single-data-runtime-root-cause.md`. | DONE |
| ROOT-02 | premise | baseline evidence | Baseline proves navigation/settle creates exact-scope native subscriptions and reads. | A–J logcat counts and call-site inspection. | DONE |

## Canonical runtime and ownership

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| ARCH-01 | §3 | dashboard runtime | Exactly one production `DashboardDataRuntime` composes one revision observer, one index builder, one current/pending index and explicit paging. | Architecture boundary test and source scan. | DONE |
| ARCH-02 | §3 | data runtime | `GlobalCoreRevisionObserver` is the sole long-lived dashboard database observer. | Unit/integration count test. | DONE |
| ARCH-03 | §3 | prepared domain | One immutable `PreparedDashboardIndex` is the sole interactive data source. | Model/API tests and source scan. | DONE |
| ARCH-04 | §3 | presentation | `DashboardPresentationController` sees only synchronous prepared-index APIs for navigation and visible selection. | Import/boundary test. | DONE |
| ARCH-05 | §3 | paging | `ExplicitCommittedPagingController` is the only exact-scope acquisition owner and can run only for vertical near-end paging. | Controller and acquisition-reason tests. | DONE |
| ARCH-06 | §4 | legacy removal | Per-query live lease, dashboard EventChannel, navigation deck pipeline/cache/prewarm and their production owners are deleted, not retained as fallback. | File/import/symbol absence checks. | DONE |
| ARCH-07 | §4 | module boundary | Navigation and presentation cannot import repository, MethodChannel/EventChannel, SQL/index builder or async acquisition APIs. | Static architecture test. | DONE |

## Revision observer, bootstrap and index lifecycle

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| REV-01 | §3.1 | revision observer | A dashboard session subscribes exactly once; navigation never subscribes, cancels or replaces it. | Fake transport and Android log tests. | DONE |
| REV-02 | §3.7 | index builder/runtime | A real core revision starts a latest-wins background index build; stale generations cannot publish. | Deterministic delayed-builder tests. | DONE |
| REV-03 | §3.7 | runtime publication | A build completing during motion stays pending and swaps atomically on the first stable idle display frame. | Fake scheduler integration test. | DONE |
| REV-04 | §3.7 | presentation/motion | Index swap does not recreate or reset rail controller, position, physics, viewport or LogBox controller. | Identity widget test. | DONE |
| BOOT-01 | §3.4 | bootstrap | Interaction remains unmounted/disabled until the first complete nonzero-revision index and valid frame exist. | Bootstrap widget/controller tests. | DONE |
| BOOT-02 | §3.4 | first interaction | First fling and later flings select the same prepared index path and publish intermediate children. | Deterministic first/tenth tests. | DONE |
| BOOT-03 | §7 | acquisition reasons | `DataAcquisitionReason` has only bootstrap, databaseRevision and explicitCommittedVerticalPaging; any mismatch fails closed. | Enum/API/boundary tests. | DONE |

## Prepared index, transport and SQL

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| IDX-01 | §3.2 | index model | Index carries revision, filters/refinements, both directions, SUM/year/month/day frames, relationships, bounds, origins, generation, digest and metrics. | Constructor/model tests. | DONE |
| IDX-02 | §3.2, §3.5 | index lookup | Parent, child, SummaryPill and direction targets resolve in O(1) from RAM with exact canonical QueryKeys. | Lookup tests and hot-path source check. | DONE |
| IDX-03 | §3.2 | zero frames | Missing periods use deterministic synchronous zero frames without repository/native/SQL work. | Empty period tests. | DONE |
| IDX-04 | §3.3 | preview rows | Each frame contains only the bounded first viewport page, already ordered, grouped and formatted with stable row/asset identities. | Model/codec/projection bounds tests. | DONE |
| IDX-05 | §3.3 | memory/payload | Index payload deduplicates row data and does not create a per-scope duplicate raw object graph. | Codec structure and 100k stress metrics. | PARTIAL |
| SQL-01 | §5 | native read service | A complete filter/refinement index for both directions uses a constant number of SQL calls independent of years/months/days. | Native counter test. | PARTIAL |
| SQL-02 | §5 | native read service | No 31 day queries, 12 month queries, per-parent query or navigation query exists. | Native tests and static scan. | DONE |
| SQL-03 | §5 | query plans | Aggregate and ordered preview queries have recorded `EXPLAIN QUERY PLAN`; indexes change only if plan evidence requires it. | Robolectric plan test and report. | PARTIAL |
| THREAD-01 | §3.8 | Android bridge | Room, aggregation, mapping and serialization run off Android main. | Looper/thread assertions and source inspection. | DONE |
| THREAD-02 | §3.8 | Dart worker | Binary decode, formatting, grouping and VM/index construction run in a worker isolate; UI receives the completed index. | Decode-worker tests/profile timings. | DONE |
| THREAD-03 | §3.8 | metrics | SQL, native aggregation/mapping, serialization, bridge, Dart decode/projection, publish, first frame, payload/index bytes and memory are measured separately. | Report-schema tests/profile artifacts. | PARTIAL |

## RAM-only presentation and commit semantics

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| NAV-01 | §3.5 | presentation controller | Summary crossing/settle, plane, parent, direction, rail open/close, child crossing/settle and cyclic wrap start no Future, stream, repository, native, SQL, parsing, projection or formatting work. | Interaction sequence with fake acquisition counters. | DONE |
| NAV-02 | §3.5 | display coalescer | Child crossings are O(1) frame-reference selection and at most one last-target publish per display frame, with no debounce/backlog. | Scheduler tests. | DONE |
| NAV-03 | §11 | navigation semantics | Existing cyclic, retained-child, clamp, parent/child QueryKey, plane and horizontal navigation behavior is preserved. | Existing plus new navigation suites. | DONE |
| VIS-01 | §7 | visible frame | Amount, count and LogBox preview originate from one exact prepared frame and always share QueryKey/revision. | Constructor assertions/property tests. | DONE |
| VIS-02 | §3.6 | settle | Settle only promotes metadata; it does not publish pixels, bind LogBox, restart amount, reset scroll, query or watch. | Counter/identity/no-op tests. | DONE |
| VIS-03 | §3.6 | committed state | Committed selection stores key/revision/epoch only and never acquires data. | Unit and architecture tests. | DONE |
| VIS-04 | §3.7 | stale protection | Old revision/generation/epoch page or index callbacks cannot replace current presentation. | Delayed callback tests. | DONE |

## LogBox and rebuild isolation

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| LOG-01 | §6 | LogBox widget | Viewport State and ScrollController survive QueryKey, direction, parent, plane and index changes; no QueryKey remount. | Widget identity tests. | DONE |
| LOG-02 | §6 | LogBox rendering | Lazy slivers consume preprojected VMs; no shrinkWrap, eager full list, build-time group/sort/format/SVG parse. | Static and widget tests. | DONE |
| LOG-03 | §6 | paging | Only committed vertical near-end requests a next page; rail settle alone does not page. | Controller/widget tests. | DONE |
| UI-01 | §6 | widget tree | Rail crossing rebuilds only child label/amount/count/preview consumers, not dashboard root, header, rail or SVG pulse. | Rebuild counter widget test. | DONE |
| UI-02 | §6 | animation owners | Direction pulse and SummaryPill controllers remain independent and do not restart on index/frame/LogBox changes. | Controller/rebuild tests. | DONE |
| UI-03 | §6 | paint | Expensive lanes remain behind stable repaint boundaries without changing visuals. | Widget tree inspection/profile. | DONE |

## Diagnostics and invariant enforcement

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| DIAG-01 | §8 | diagnostics model | Required structured events exist with interaction/presentation/data generations, revision, key, mode, origin, motion and acquisition reason. | Unit test. | DONE |
| DIAG-02 | §8 | enums | `presentationMode` and `dataOrigin` are separate enums. | Model test/source check. | DONE |
| DIAG-03 | §8 | hot path | Per-pixel logging is absent and crossing logs are coalesced/disabled in profile. | Static test/profile config. | DONE |
| INV-01 | §7 | assertions | Visible key/revision/index and atomic lane invariants fail fast in debug/test. | Negative constructor/controller tests. | DONE |
| INV-02 | §7 | acquisition guard | Any navigation-triggered acquisition is recorded as `MOTION_DATA_IO_VIOLATION` and fails hard in debug/test. | Deliberate invalid-reason test. | DONE |

## Required test matrix

| ID | Source | Intended test area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| TEST-01 | §9.1–6 | Flutter unit/integration | First/later fling, populated/empty month-day, populated/empty year-month and intermediate values pass. | Targeted test command. | DONE |
| TEST-02 | §9.7–13 | Flutter integration | Open-rail parent/direction, plane changes, cyclic wrap, rapid/long/repeated gestures and density invariance pass. | Targeted test command. | DONE |
| TEST-03 | §9.14–19 | Flutter unit/integration | Motion-time revision, stale generation, and no-acquisition settle/parent/direction/SummaryPill pass. | Targeted test command. | DONE |
| TEST-04 | §9.20 | Flutter widget/integration | Explicit committed near-end paging still works and stale page responses reject. | Targeted test command. | DONE |
| TEST-05 | §9 counters | architecture/integration | After 50 month/day, 50 year/month, 30 Summary, 20 plane and 20 direction operations, interaction-caused repository/native cancel/SQL/build/payload counts are all zero; global subscribe is one. | Deterministic fake transport test. | DONE |
| TEST-06 | §9 | native | Constant SQL, codec, revision observer and 10k/50k/100k fixtures pass. | Gradle/Robolectric tests. | PARTIAL |
| TEST-07 | §2, §9 | repository | No golden test or golden asset is added or regenerated. | Git diff and test scan. | DONE |

## Stress, profile and delivery

| ID | Source | Intended code or document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PROF-01 | §10 | fixtures/harness | Reproducible 10k, 50k and 100k startup/index/memory fixtures exist. | Native/profile test artifacts. | PARTIAL |
| PROF-02 | §10 | scripted profile | Identical scripted empty/populated gestures report first/warm, month/day, year/month, Summary, direction and pulse scenarios. | Profile JSONs. | PARTIAL |
| PROF-03 | §10 | thresholds | UI/raster p95 <16.7 ms, p99 <24 ms, no >48 ms interaction frame, endpoint delta ≤1 child, and no navigation data work are evaluated honestly. | Automated report assertions. | NOT DONE |
| PROF-04 | §10 | environment disclosure | Emulator results are labeled as emulator evidence; exact physical-device command and script steps are documented. | Final report. | PARTIAL |
| VERIFY-01 | global instructions | local verification | Targeted RED/GREEN tests, full non-golden Flutter suite and analyze run in Ubuntu proot. | Captured output. | DONE |
| VERIFY-02 | global instructions | CI | Branch is committed and pushed; GitHub native tests, Flutter tests/analyze, profile and APK build complete. | Actions run. | NOT DONE |
| DELIV-01 | prior user instruction | APK delivery | Successful APK is downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256. | File inspection. | NOT DONE |
| REPORT-01 | §13 | final report | All 20 requested factual report items and a PASS/FAIL invariant table are present; FAIL is not called merge-ready. | Final report review. | NOT DONE |

## Explicit non-solutions

Any of the following makes the checklist fail regardless of test status:

- physics, friction, velocity, threshold, snap, extent or gesture tuning;
- timer/debounce/delayed-query/motion-aware-delay behavior;
- navigation-triggered watch, read, index build, platform payload or SQL;
- retaining PreparedDeck or per-query live watch as a fallback data source;
- QueryKey viewport remount, controller replacement, eager/shrinkWrap LogBox;
- build-time sort/group/format/SVG work or full dashboard notification;
- per-child/per-parent SQL or platform calls;
- cache warmth as correctness;
- a new golden test;
- claiming production/physical smoothness from green CI or emulator evidence.
