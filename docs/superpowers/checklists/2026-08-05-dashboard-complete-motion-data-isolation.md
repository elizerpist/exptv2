# Dashboard complete motion/data isolation acceptance checklist

Date: 2026-08-05

Source: user specification “FLUVI DASHBOARD – TELJES ARCHITEKTURÁLIS REFAKTOR”

Branch: `refactor/dashboard-complete-motion-data-isolation`

Baseline: `16072f0ef633c27fca8f7aeea0c3d0c7305badc4`

Milestone: `bb6c294257b94859a902d445113ab3f739db0783`

Status vocabulary is intentionally closed: `DONE`, `PARTIAL`, `BLOCKED`,
`NOT DONE`. Compilation, green CI or an APK does not complete any behavioral
row by itself.

## Milestone record

- Current implementation commit before the refactor:
  `16072f0ef633c27fca8f7aeea0c3d0c7305badc4`.
- Dedicated branch: `refactor/dashboard-complete-motion-data-isolation`.
- Safety commit: `bb6c294257b94859a902d445113ab3f739db0783`, with
  the exact requested subject.
- Tracked files were unmodified at the milestone. Existing untracked
  `.tmp-*` logs and `test/features/dashboard/presentation/failures/` belong to
  the user and remain unmodified, unremoved and unstaged.
- Known baseline behavior: seeded bootstrap reaches revision 1 and produces
  correct parent totals; cold first rail use can omit intermediate child
  content; populated/cold motion changes observed fling distance; open-rail
  cold parent changes wait for bundle publication; repeated idle/settle events
  occur; SUM/year work can stall SummaryPill and SVG pulse frames.
- Frozen behavior: visual layout, amount/count arithmetic, LogBox content,
  QueryKey meaning, carousel geometry, friction, velocity scaling, snap and
  animation timing.

## Safety, audit and preservation

| ID | Source | Intended code/document area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| SAF-01 | §0.1 | Git worktree | Baseline tracked tree inspected; user-owned untracked files recorded and untouched. | `git status --short --branch`; milestone notes. | DONE |
| SAF-02 | §0.2 | Git branch | Work occurs on a dedicated branch. | `git branch --show-current`. | DONE |
| SAF-03 | §0.3 | Git history | Exact milestone subject exists before implementation. | `git show bb6c294`. | DONE |
| SAF-04 | §0.4 | Checklist/design docs | Baseline commit, branch, modified/unmodified files and known behavior are documented. | Re-read this checklist and design milestone section. | DONE |
| PRES-01 | §0 | motion tokens/physics | Rail item extent, friction, velocity scale, snap, thresholds, controller characteristics and visual timings remain unchanged. | Constants diff plus focused motion tests. | NOT DONE |
| PRES-02 | §0 | query/domain/presentation | Amount/count business calculations, LogBox content and QueryKey semantics remain unchanged. | Native/Dart parity tests and representative widget tests. | NOT DONE |
| AUD-01 | §1–2 | `docs/dashboard/dashboard-motion-data-root-cause.md` | Logs and complete gesture→settle→live event graph are incorporated. | Direct source re-read and audit doc review. | DONE |
| AUD-02 | §2 | same audit | Every UI-isolate heavy function, notification, rebuild boundary and identity lifecycle is named. | Source/function cross-check. | DONE |
| AUD-03 | §2.7 | same audit | Populated/cold/repeatability/year/SUM symptoms have concrete causal explanations, not only “main isolate load”. | Audit doc symptom section. | DONE |

## State and ownership architecture

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| ARC-01 | §3 | dashboard application | Exactly four owned systems remain: Motion Kernel, Prepared Data Pipeline, Visible Presentation Frame, Committed Live Query. | Boundary test and source ownership review. | NOT DONE |
| ARC-02 | §3 | all four systems | Motion cannot start data preparation; data cannot mutate motion; presentation cannot recreate motion identity; settle is not a render trigger. | Boundary test plus interaction counters. | NOT DONE |
| STATE-01 | §17 | application models | Immutable `DashboardMotionState` exposes offset, velocity, activity, semantic index, motion epoch and gesture ID. | Unit tests and immutability inspection. | NOT DONE |
| STATE-02 | §17 | prepared-data models | `DashboardPreparedState` owns deck cache, in-flight preparations, revisions and generations. | Unit tests/source review. | NOT DONE |
| STATE-03 | §17 | visible model/store | One immutable `DashboardVisibleFrame` is the complete visible snapshot. | Atomic-invariant tests. | NOT DONE |
| STATE-04 | §17 | committed-query model | `DashboardCommittedState` owns committed key/revision/epoch/live generation. | Unit tests. | NOT DONE |
| STATE-05 | §17 | navigation model | `DashboardNavigationState` owns plane, parent key, rail open, retained child and navigation epoch. | Unit/property tests. | NOT DONE |
| STATE-06 | §17 | state owners | No all-purpose mutable notifier; motion and presentation are never the same mutable object. | Boundary/source test. | NOT DONE |

## Motion Kernel

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| MOT-01 | §4 | motion kernel/catalog | Kernel owns only gesture, offset, ballistic simulation, semantic index, snap and settle. | Dependency boundary test. | NOT DONE |
| MOT-02 | §4 | semantic catalog | Immutable catalog with logical index, label, child period, child QueryKey and identity exists before motion. | Catalog tests and source inspection. | NOT DONE |
| MOT-03 | §4 | semantic-crossing callback | Hot path is `ScrollPosition → index → O(1) catalog lookup → frame request`. | Counters/boundary test. | NOT DONE |
| MOT-04 | §4 | motion dependencies | Hot path has no async/await, repository, platform channel, parse, formatting, grouping, sorting, projection or per-pixel logging. | Static boundary test and 100-crossing test. | NOT DONE |
| MOT-05 | §4 | carousel/controller | Rail `ScrollController`, app physics object, position/viewport identity are stable through parent/plane/direction/open-close/publish. | Identity widget test and counters. | NOT DONE |
| MOT-06 | §4, §21 | physics/config | No friction/velocity/threshold/snap/gesture workaround changes. | Exact constant assertions/diff. | NOT DONE |
| MOT-07 | §4 | rail subtree | Semantic child changes do not rebuild rail or dashboard root. | Rebuild-counter widget test. | NOT DONE |

## Prepared Data Pipeline and transport

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PREP-01 | §5 | prepared models | Immutable `DashboardPreparedDeck` contains all required identity, revision, catalog, frames, completeness, digest, generation and timestamp fields. | Model unit tests/source review. | NOT DONE |
| PREP-02 | §5 | prepared frame | Frame contains exact key/revision/total/preformatted amount/count/error/empty/header/LogBox first-page groups/rows/cursor/stable identities/digest. | Decoder/projector tests. | NOT DONE |
| PREP-03 | §5 | data pipeline | SQL, aggregation, grouping, sorting, formatting and LogBox projection complete before the deck becomes selectable. | Prepared-deck tests and motion counters. | NOT DONE |
| PREP-04 | §5 | Android/bridge/Dart worker | SQL/mapping/transport encoding run off Android main; large Dart decode/projection runs off UI isolate; transport is bounded binary/minimal. | Native tests, bridge tests, timeline evidence. | NOT DONE |
| PREP-05 | §5 | native month batch | Month→day uses one parent batch and constant SQL count, never 30–31 child calls. | Native query-count test and source boundary test. | NOT DONE |
| PREP-06 | §5 | native year batch | Year→month uses one annual batch and constant SQL count, never 12 child calls. | Native query-count test. | NOT DONE |
| PREP-07 | §5 | SUM catalog/batch | SUM→year uses an explicit bounded, deterministic year window. | Catalog/native tests. | NOT DONE |
| PREP-08 | §5 | payload memory | Output rows are bounded by parent/child page budgets; no full parent list is materialized in Kotlin/Dart UI. | 10k/50k/100k stress and native allocation/query assertions. | NOT DONE |
| PREP-09 | §5 | QueryKey/scopes | Prepared keys exactly match canonical Dart/native QueryKey semantics. | Cross-language fixture tests. | NOT DONE |

## Deck cache, seed and revision

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| CACHE-01 | §6 | prepared deck key | Key includes direction, parent QueryKey, filters, refinements, child kind, revision, page size, model version and semantic window identity. | Key equality tests. | NOT DONE |
| CACHE-02 | §6 | cache | Only immutable complete prepared decks are stored in bounded O(1) LRU. | Cache tests/source boundary. | NOT DONE |
| CACHE-03 | §6 | residency policy | Active, previous, next and needed opposite-direction decks are retained within explicit bounds. | Eviction/residency tests. | NOT DONE |
| CACHE-04 | §6 | lookup path | One event performs one canonical lookup; duplicate consecutive lookup/miss is absent. | Diagnostic/counter test. | NOT DONE |
| CACHE-05 | §6 | in-flight registry | Same key has at most one preparation Future; callers join it. | Concurrency test. | NOT DONE |
| CACHE-06 | §6, §12 | revision | Revision mismatch rejects cached deck and async completion. | Revision invalidation tests. | NOT DONE |
| CACHE-07 | §6, §12 | seed gate | Revision zero cannot enter valid cache, publish visible, or overwrite revision one. | Seed-gate tests and native/Dart guards. | NOT DONE |

## Atomic visible presentation and frame coalescing

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| VIS-01 | §7 | visible frame | Frame atomically contains key/parent/plane/rail/index/direction/revision/amount/count/LogBox/epochs/mode. | Model test. | NOT DONE |
| VIS-02 | §7 | frame invariants | Amount, count and LogBox always share frame QueryKey and revision. | Constructor assertions/property test. | NOT DONE |
| VIS-03 | §7 | crossing selection | Crossing selects `preparedDeck.frames[key]` synchronously in O(1) and publishes only locally. | Isolation/counter test. | NOT DONE |
| VIS-04 | §7 | lanes | Partial amount/count/LogBox lane updates are impossible. | API boundary and randomized test. | NOT DONE |
| COAL-01 | §8 | frame scheduler | At most one visible publish per display frame, selecting the latest target in that frame. | Deterministic scheduler unit test. | NOT DONE |
| COAL-02 | §8 | frame scheduler | Targets in separate display frames are each visible. | Unit/widget test. | NOT DONE |
| COAL-03 | §8 | frame scheduler | No debounce, throttle, idle wait, backlog, replay or delayed trailing publish exists. | Static source test and fake-clock test. | NOT DONE |
| COAL-04 | §8 | motion | Coalescing never changes physical simulation or forces every crossed child to render. | Motion repeatability test. | NOT DONE |

## UI subtree and presentation behavior

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| UI-01 | §9 | dashboard widget tree | Summary motion, rail motion, amount, count, LogBox, pulse and header have isolated stable subtrees. | Widget tree/source review. | NOT DONE |
| UI-02 | §9 | selectors/listenables | Visible updates reach only amount/count/LogBox/child-label consumers; root/header/rail/pulse do not rebuild per crossing. | Rebuild counter tests. | NOT DONE |
| UI-03 | §9 | render boundaries | Appropriate `RepaintBoundary`s isolate moving/expensive regions without changing visuals. | Widget inspection/profile layers. | NOT DONE |
| UI-04 | §9 | direction pulse | Pulse controller/subtree does not depend on deck, visible frame, LogBox or native work and never restarts due to them. | Widget identity/restart test. | NOT DONE |
| UI-05 | §9, §14 | SummaryPill | Shell/text animation starts independently and does not rebuild the full dashboard per tick. | Transition widget test/rebuild counters. | NOT DONE |
| LOG-01 | §10 | LogBox viewport | Stable State and ScrollController; no QueryKey remount, frame controller creation, eager raw projection or nested shrinkWrap. | Identity/static/widget tests. | NOT DONE |
| LOG-02 | §10 | LogBox VM | Prepared immutable VM pointer swap feeds stable lazy slivers with stable group/row/asset keys. | Widget tests and source inspection. | NOT DONE |
| LOG-03 | §10 | LogBox ownership | Grouping/sorting/formatting/SVG parsing are absent from build/crossing; LogBox never feeds motion state. | Boundary/isolation tests. | NOT DONE |
| LOG-04 | §10 | density | Empty/populated LogBox content cannot change rail target/distance. | Density invariance test/profile. | NOT DONE |
| AMT-01 | §11 | amount subtree | Preview amount is a direct prepared value, at most one update per display frame, with no queue/format/await. | Coalescer/amount tests. | NOT DONE |
| AMT-02 | §11 | amount animation policy | Preview and commit cannot animate the same value twice; same-value settle is no-op. | Amount execution tests. | NOT DONE |
| AMT-03 | §11 | count subtree | Count updates only through the same atomic visible frame. | Atomic invariant/widget test. | NOT DONE |

## Committed live query and navigation

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| LIVE-01 | §12 | committed controller | Only committed state owns one live lease; preview/crossing starts no read/watch/page/lease. | 100-crossing isolation test. | NOT DONE |
| LIVE-02 | §12 | settle | Settle promotes current frame metadata without a visual publish, LogBox rebind, amount restart, viewport reset or controller creation. | Settle no-op test/counters. | NOT DONE |
| LIVE-03 | §12 | acceptance guard | Live response must match committed key, direction, filters, refinements, revision and presentation epoch. | Stale callback tests. | NOT DONE |
| LIVE-04 | §12 | latest wins | Old async callbacks increment rejection counter and cannot alter visible/motion state. | Rapid navigation/property tests. | NOT DONE |
| LIVE-05 | §12, §21 | lease activation | No timer debounce/quiescence is used for correctness or preview. | Source boundary test. | NOT DONE |
| PARENT-01 | §13 | open-rail navigation | Motion kernel/controller remain stable and retained child maps deterministically to new parent. | Identity and mapping tests. | NOT DONE |
| PARENT-02 | §13 | day mapping | Jul 31→Jun clamps 30; Jun 30→Jul remains 30. | Unit/integration tests. | NOT DONE |
| PARENT-03 | §13 | month mapping | 2025 May→2026 May and Dec 2026→Dec 2025 preserve month. | Unit/integration tests. | NOT DONE |
| PARENT-04 | §13 | warm target | Warm parent selects exact new child in one display frame. | Scheduler/widget test. | NOT DONE |
| PARENT-05 | §13 | cold target | Old coherent frame remains; motion continues; full new deck atomically publishes with no dash/mix/placeholder. | Delayed repository test. | NOT DONE |
| PARENT-06 | §13 | rapid navigation | A→B→C latest target wins and old parent frame never publishes. | Integration/property test. | NOT DONE |
| PLANE-01 | §14 | navigation/motion | SUM→year, year→month, month→day/SUM, parent, direction and rail open/close animations do not wait for data. | Widget/integration tests. | NOT DONE |
| PLANE-02 | §14 | SummaryPill callbacks | No repository read or UI-isolate child parse occurs in animation callback. | Boundary/counter test. | NOT DONE |
| DIR-01 | §13, §19.10 | direction | Open/closed direction change exposes no old-direction or mixed frame; old callbacks reject. | Widget/integration test. | NOT DONE |

## Background preparation and legacy removal

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| WARM-01 | §15 | pipeline scheduler | Prewarm is cancelable, deduplicated, generation-guarded and lower priority than interaction. | Unit tests. | NOT DONE |
| WARM-02 | §15 | cache publication | Prewarm completion updates cache only; visible publish happens only for the current awaited full target. | Delayed completion test. | NOT DONE |
| WARM-03 | §15 | UI isolation | Expensive prewarm decode/projection is not executed on the UI isolate during interaction. | Timeline/counter evidence. | NOT DONE |
| LEG-01 | §16 | old controllers/cache | Old preview coordinators, metrics-only child index path, redundant cache adapters and duplicate notifiers are removed from production. | `rg` boundary assertions and file diff. | NOT DONE |
| LEG-02 | §16 | visual commit path | Settle-time visual publish, motion-time repository paths, timers/debounces and ballistic/scroll presentation guards are removed. | Static boundary tests. | NOT DONE |
| LEG-03 | §16 | viewport/motion hacks | QueryKey remount, post-frame recenter patching, temporary flags and dual truth/fallback paths are absent. | Static/source inspection. | NOT DONE |

## Diagnostics

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| DIAG-01 | §18 | typed diagnostics | All 14 required named events exist and are bounded/profile-safe. | Diagnostic unit test. | NOT DONE |
| DIAG-02 | §18 | event context | Events carry gesture/motion/navigation/presentation epochs, keys, revision, index, frame, source and relevant duration. | Event-model tests. | NOT DONE |
| DIAG-03 | §18 | hot-path policy | No per-pixel logging; per-crossing verbose recording is switchable; disabled path is allocation bounded. | Source/test/profile check. | NOT DONE |
| DIAG-04 | §18 | counters | All 15 requested rebuild/I/O/projection/stale/identity counters exist. | Counter slot/unit tests. | NOT DONE |
| DIAG-05 | §18 | per-frame invariant | Counter proves visible publications per display frame never exceed one. | Coalescer/profile assertion. | NOT DONE |

## Required deterministic tests

| ID | Source | Intended test area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| TEST-01 | §19.1 | unit | 100 crossings produce 0 SQL/native/repository/lease/format/projection calls. | New isolation test. | NOT DONE |
| TEST-02 | §19.2 | unit/widget | 0, 1, 94 and 658-row frames yield equal target/settle within fixed tolerance. | Density test. | NOT DONE |
| TEST-03 | §19.3 | unit/widget | First and tenth fling have same sequence, target and duration tolerance. | Cold/warm test. | NOT DONE |
| TEST-04 | §19.4 | widget | Fast long fling never collapses to a one-item jump because of load. | Long-fling test. | NOT DONE |
| TEST-05 | §19.5 | property/unit | Same start/velocity repeated 100 times yields same target. | Repeatability test. | NOT DONE |
| TEST-06 | §19.6 | unit | Same-frame crossings coalesce last; separate frames publish all; no backlog/trailing event. | Fake scheduler test. | NOT DONE |
| TEST-07 | §19.7 | unit/widget | Settle is a visual no-op by all requested counters. | Settle test. | NOT DONE |
| TEST-08 | §19.8 | widget | 100 open/close/plane/direction/parent changes preserve controller/physics/position/LogBox identities where supported. | Identity test. | NOT DONE |
| TEST-09 | §19.9 | integration | All specified open-rail parent cases, empty/populated, cold/warm and A→B→C produce exact expected key. | Navigation suite. | NOT DONE |
| TEST-10 | §19.10 | integration | Direction open/closed has no old/mixed/stale publication. | Direction suite. | NOT DONE |
| TEST-11 | §19.11 | unit | Old revision deck is unusable after revision change. | Cache/pipeline test. | NOT DONE |
| TEST-12 | §19.12 | unit/integration | Seed revision zero never caches/publishes. | Seed test. | NOT DONE |
| TEST-13 | §19.13 | widget | Required rapid plane transitions start no data work, preserve pulse controller and bound root rebuilds. | Widget test. | NOT DONE |
| TEST-14 | §19.14 | widget | LogBox never remounts or exposes stale rows across all specified transitions. | Widget identity/content test. | NOT DONE |
| TEST-15 | §19.15 | randomized | Random navigation/revision/callback sequences preserve exact-key/revision/atomic/no-I/O invariants. | Seeded property test. | NOT DONE |
| TEST-16 | §21 | all tests | No new golden test or golden asset is written/regenerated. | Git diff and test file scan. | NOT DONE |

## Profile benchmark and delivery

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PROF-01 | §20.A–J | integration/profile harness | Reproducible scenarios A–J include SUM/year/month/day, empty/populated, parent/direction/pulse, first/tenth fling. | Harness source and report. | NOT DONE |
| PROF-02 | §20 | report schema | UI/raster times, missed frames, build/layout/paint, GC/allocation, channel/SQL/parse, publishes, target/settle are captured. | Report JSON validation. | NOT DONE |
| PROF-03 | §20 | real device/current benchmark environment | Before/after numeric evidence is collected with minimal logger. | Profile artifacts and device metadata. | NOT DONE |
| PROF-04 | §20, §23 | profile acceptance | Density, cold/warm and first/tenth results are invariant; motion has 0 data I/O and no data-pipeline long UI task/frame drop. | Automated report assertions plus timeline inspection. | NOT DONE |
| VERIFY-01 | global instructions | Flutter validation | Targeted RED→GREEN tests, full non-golden suite and analyze run in Ubuntu proot. | Captured commands/output. | NOT DONE |
| VERIFY-02 | global instructions | Android validation | Native core/app tests and boundary verification pass. | Gradle/CI output. | NOT DONE |
| CLEAN-01 | §16, §22 | repository | Dead production paths/imports/files are removed; no TODO/temporary/legacy/fallback/feature flag remains. | `rg`, analyzer, diff review. | NOT DONE |
| DELIV-01 | global + prior request | Git/GitHub | Final implementation is committed and pushed on this branch; GitHub tests/builds pass. | Commit hash and Actions run. | NOT DONE |
| DELIV-02 | prior request | APK delivery | Built APK is downloaded to `/storage/emulated/0/Download/fluvi`. | File hash/path and release URL. | NOT DONE |
| REPORT-01 | §24 | final response/docs | Final report includes all 20 requested root-cause, architecture, files, evidence, benchmark, tests and commit items. | Checklist against final report. | NOT DONE |

## Explicit forbidden-solution gate

The following are acceptance failures even if a local symptom improves:

- physics/velocity/threshold/snap manipulation;
- time debounce, trailing throttle, idle/settle-only rendering, ballistic
  suppression or delayed replay;
- density-specific rendering policy, loading placeholder masking, IndexedStack
  prebuilding or offscreen rendering of every child;
- 12/30/31 child queries or child platform calls;
- dashboard-root `setState`, controller recreation, async/platform calls or
  LogBox projection from a motion callback;
- cache warmth as a correctness condition;
- a feature-flagged legacy route, second source of truth, or another patch
  coordinator layered over the existing coordinators;
- completion claims without the required profile benchmark;
- any new or regenerated golden test.
