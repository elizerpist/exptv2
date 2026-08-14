# Vertical scroll recovery forensic checkpoint

Date: 2026-08-14
Branch: `query` recovery branch (`fix/vertical-scroll-recovery`)
Starting production HEAD: `f18e6a351454ca0898299cb7e6fbdc55126ca360` — `perf: publish prepared runway before ballistic when possible`
Last-known-good vertical behavioural source: `e64e84aededa61f7f41124100309e819eceb269e` — `fix: retain visible temporal child across structural navigation`

This is a diagnosis checkpoint, not a claim of physical success. The user
verified the vertical lazy-rendering behaviour at `e64e84a` on an Android
device. The Query era begins at `381f2306856fcf6903b53e41b3b0c897aa497e1b`,
whose direct parent is `e64e84a`; that first commit adds a Query HTML prototype
and does not change production Flutter vertical code. Therefore `e64e84a` is
the vertical behavioural source of truth, not merely a comparison floor.

## Acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VSR-01 | User mission / `e64e84a` | vertical cache, paging, viewport | Port the known-good single-ready-frontier lifecycle without reverting Query | three-way source review, focused tests | NOT DONE |
| VSR-02 | Flutter framework contract | cache / viewport | No regular interaction-time mutation of Flutter content dimensions for readiness | source inspection, viewport tests, device trace | NOT DONE |
| VSR-03 | User H1/H4/H7 | paging controller | A five-page bounded, rolling exact-ready bank advances only from meaningful viewport progress or idle policy | RED/GREEN controller tests | NOT DONE |
| VSR-04 | User H2 | cache / controller | Common fling consumes fully laid-out cache pages; scheduler continuation is not steady-state readiness | source inspection, controller tests, physical trace | NOT DONE |
| VSR-05 | User hard constraints | cache / render surface | Root remains separately pinned; movable pages remain `<= 5`; byte bound, complete-page and fail-closed invariants remain | cache tests / boundary check | NOT DONE |
| VSR-06 | User Query boundary | Query controllers / data runtime | Directional Query state, atomic Apply, saved Query and native filtering remain unchanged | focused Query/native tests | NOT DONE |
| VSR-07 | User ownership constraints | viewport | Existing `ScrollController`, `ScrollPosition`, and physics identities remain | viewport/observer tests | NOT DONE |
| VSR-08 | User diagnostics | viewport diagnostics | One aggregated `VERTICAL_INTERACTION_PERF_SUMMARY`, no per-frame logging | code inspection / focused test where practical | NOT DONE |
| VSR-09 | User physical acceptance | normal `lib/main.dart` APK | Android manual scenarios show no recurring page-readiness braking or miss counters | GitHub human APK + human device test | NOT DONE |

## Local state and scope

The shared user worktree was on `fix/scene-window-input-decoupling` at
`0f47fd2f…` and had unrelated untracked diagnostics/tests. It was not changed.
This clean recovery worktree starts exactly at the verified remote `query` HEAD
`f18e6a351454ca0898299cb7e6fbdc55126ca360`; `origin/query` resolved to the
same SHA before diagnosis.

The target is a semantic three-way merge:

```
A. e64e84a: physically good vertical lazy-render contract
B. f18e6a3: current Query/domain/native correctness
C. f18e6a3: physically bad vertical readiness/runway machinery

target = B's Query correctness + A's vertical contract
         + only later independent correctness fixes that pass a necessity test
```

This explicitly does **not** mean reverting the branch or mechanically copying
old files. Query, its data model, and its atomic presentation flow are hard
non-regression boundaries.

## Production data-flow map at HEAD

```
pointer input
  -> Flutter GestureDetector / Scrollable / ScrollPosition activity
  -> DashboardLogBoxViewport / DashboardVerticalScrollController observer
  -> DashboardCoreController interaction and foreground gates
  -> CommittedVerticalDemandPlanner
  -> ExplicitCommittedPagingController (serial keyset cursor owner)
  -> MethodChannelDashboardDataRuntimeRepository
  -> Android MainActivity query task queue / FluviCore / Room keyset query
  -> binary reply -> IsolateDashboardCommittedPageDecodeWorker
  -> DashboardCommittedPageBinaryCodec + DashboardLogViewModelProjector
  -> ExplicitCommittedPagingController presentation hand-off
  -> CommittedLogViewportCache complete page layouts / geometry / retention
  -> DashboardLogBoxRenderSurface notifier, SizedBox height, LayoutBuilder,
     CustomPaint, semantics
  -> RenderViewport.applyContentDimensions / ScrollPosition activity
```

The normal committed-page repository path is serial and exact: Dart sends the
committed scope identity, query/revision/presentation generation, cursor,
ordinal and `pageSize=24` to `readDashboardCommittedPage`. Android's Room
transaction validates revision, performs a sequential keyset read, maps only
the requested page and returns an authoritative result. Dart decodes in an
isolate, validates identity/cursor/revision and projects the complete ordered
page before it reaches the vertical cache. Room remains the source of truth.

## Ownership and lifecycle map

| Owner | Mutable state / lifecycle | Inputs and outputs | Interaction / metric effect | Decision |
| --- | --- | --- | --- | --- |
| `DashboardCoreController` | vertical interaction flag, rail/query gates, idle callbacks | viewport lifecycle -> paging release/cancel | It currently retries/publishes readiness at interaction and layout boundaries; it must stop owning geometry timing | keep high-level owner; simplify vertical gate calls |
| `DashboardLogBoxViewport` | stable controller, session and observer diagnostics | Flutter notifications -> visible window / demand | HEAD calls interaction-start, drag-ready and low-watermark runway publication; each can change surface height and metrics | keep stable observer/controller; remove readiness-driven metric publication |
| `CommittedVerticalDemandPlanner` | current velocity/latency/adaptive lookahead | viewport progress -> desired ordinal | Multiple policy signals overlap paging state | reduce to a fixed, semantic progress-to-ready target adapter or remove adaptive policy |
| `ExplicitCommittedPagingController` | cursor, scope, desired ordinal, hotset state, background generation, pending/deferred page/promotion | demand -> serial read -> complete presentation | Currently makes foreground preparation normal during ballistic | keep sole cursor owner; replace one-shot/promotion state with bounded rolling target and one pending decoded page only if needed |
| `CommittedLogViewportCache` | page resources, prepared/exposed geometries, runway/low-watermark, retention | complete pages -> drawable geometry/notifier | Prepared/exposed split deliberately delays and later mutates scroll extent | keep resource/cache owner, root pin, five-page and byte caps; restore one complete drawable frontier |
| `DashboardLogBoxRenderSurface` | cache listener and post-frame setState avoidance | cache geometry -> `SizedBox`/layout/paint | A cache notification can rebuild a giant surface and update content dimensions | retain no-layout/no-TextPainter-in-paint rendering; it must observe stable complete geometry rather than runway batches |
| `DashboardLogBoxPreparedSceneCache` / `RailCriticalSceneBank` | rail scene readiness | rail scene -> root paint source | Separate rail-critical ownership | retain |
| `DashboardVisibleFrameStore` / `DashboardPresentationController` | atomic visible frame | prepared scene -> visible dashboard | Query and navigation publication boundary | retain |
| `CurrentQueryController` / `QueryComposerController` | applied directional Query and sheet draft | draft -> prepared candidate -> atomic Apply | Query boundary, not a vertical readiness owner | retain unchanged |

There are presently at least three partially overlapping models of “where the
user will go” and “what is ready”: viewport adaptive demand, paging desired and
hotset target, and cache prepared/exposed/runway frontiers. This is a
centralization failure: no later subsystem may retain a duplicate policy unless
it proves it is required by current Query.

## `e64e84a` compared with HEAD

At `e64e84a`, `ExplicitCommittedPagingController` is a roughly 470-line serial
cursor owner. It holds one desired forward ordinal, a page-in-flight guard and
forward request coalescing. A completed exact page is synchronously committed
to one cache geometry. The cache has one geometry frontier, complete
`TextPainter` resources before publication, a root pinned separately, and a
bounded five-page movable cache. There is no prepared/exposed split, runway,
low-watermark, hotset state, background generation, deferred presentation
promotion, scheduler task continuation, or active-drag geometry publication.

At HEAD, the same area has grown into independent interacting state machines:

* cache private prepared geometry versus public exposed geometry, runway
  publications, low-watermark intent and a scheduler-sliced preparation task;
* controller bounded-hotset enum, background generation/target, pending
  presentation, deferred presentation, promotion, foreground urgency and
  vertical-input gates;
* viewport interaction-start/drag-ready/ballistic-specific publications;
* adaptive velocity/observed-readiness demand planning.

The source diff from `e64e84a` to `f18e6a3` adds 6,376 lines and removes 747
in the principal vertical files. Size alone is not a root cause, but the
introduced lifecycle crossings coincide with the physical regression history.

## Commit archaeology ledger

Physical-device failure outweighs green unit tests. “Test evidence” below
means the commit changed or had focused tests, not that it proves physical
smoothness.

| SHA | Intent / production files changed | State or lifecycle introduced | Bug targeted / test evidence | Physical evidence and regression | Classification |
| --- | --- | --- | --- | --- | --- |
| `e64e84a` | Baseline production vertical architecture; commit itself changes structural-navigation tests | one ready geometry/cache contract | Existing lazy-render tests | User physically verified this contract before Query began | PROVEN_GOOD |
| `610925ad` | paging/cache/planner/viewport | async page presentation, adaptive ahead demand and foreground gates | avoid page starvation; focused tests added | first vertical behavioural departure after Query work; no device proof that it helped | SUSPECT_ARCHITECTURE |
| `f8657d73` | cache, viewport, scroll observer | `scheduleTask(Priority.animation)` continuation and interaction observer | avoid handoff/input interference; tests/diagnostics | current trace shows 40–63 ms handoff waits despite short slices | FAILED_PHYSICAL_EXPERIMENT |
| `76e32e81` | `MainActivity`, dispatch policy, channel repository | Android background MethodChannel task queue and IO query scope | remove Android platform thread queue latency; Kotlin/Dart dispatch tests | independent acquisition-boundary change; does not require runway; retain pending native regression verification | UNKNOWN |
| `de0a584d` | cache | bidirectional byte-accounted retention | retain nearby reverse pages and control resources | useful policy candidate but no independent physical proof | UNKNOWN |
| `cac85a97` | `core_dashboard.dart` | callback binding correction only | wire `verticalBackgroundWorkActive` as a callback | no vertical mechanism changed | FIXED_REAL_CORRECTNESS_BUG |
| `6b975f55` | controller/cache/core | pause page presentation through vertical input | prevent active-input preparation | later removed/overridden because frontier stopped | FAILED_PHYSICAL_EXPERIMENT |
| `742760dc` | cache/controller/tests | restored hard five movable-page bound alongside byte bound | bounded working set | required current hard invariant; tests cover bound | FIXED_REAL_CORRECTNESS_BUG |
| `31b9a4d3` | core/controller/tests | single-use input pause completion | repair pause waiter lifecycle | race correction, later pause policy still removed | FIXED_REAL_CORRECTNESS_BUG |
| `a6ecfc25` | core/controller/tests | allows frontier advance through fling | repair starvation caused by pause | made active-fling readiness ordinary | SUSPECT_ARCHITECTURE |
| `47938b12` | controller/core/tests | retries a fixed bounded hotset at foreground gates | retry blocked initial hotset | post-baseline control only; no evidence it restores e64 behaviour | SUSPECT_ARCHITECTURE |
| `986ba698` | cache/controller/viewport/tests | prepared-versus-exposed frontier, runway and low-watermark publication | batch metric growth | makes Flutter metric mutation a readiness mechanism | SUSPECT_ARCHITECTURE |
| `d36e0e45` | controller/tests | one-shot-per-scope hotset satisfaction | halt recursive preload | current traces demand pages after its fixed bank; likely under-prefetch | SUSPECT_ARCHITECTURE |
| `d4a39656` | controller/tests | retains one decoded page across input preemption | prevent an unnecessary same-identity reread | independent no-reread behaviour is useful if expressible without promotion state | FIXED_REAL_CORRECTNESS_BUG |
| `62cacf5b` | cache/controller/tests | frontier-critical 1 ms `scheduleTask` slices / urgency | reduce largest contiguous UI work | trace confirms short slices but tens-of-ms scheduler waits and worse wall time | FAILED_PHYSICAL_EXPERIMENT |
| `f18e6a35` | cache/viewport/tests | interaction-start and drag-ready runway publication | publish before ballistic | continues metric mutations immediately around handoff; physical issue persists | FAILED_PHYSICAL_EXPERIMENT |

Other intervening commits (`4f0acd4b`, `d588b5ea`, `d15c6507`,
`a0b41eab`, `777569ad`) are regression-history evidence, not restoration
sources. In particular, `47938b`, `610925ad`, `986ba`, and `d36e0e` are not
candidate baselines: they are post-`e64e84a` experiments to be deleted unless
they meet the burden of proof below.

## Installed Flutter framework contract

Inspected locally in Ubuntu proot, not inferred from memory:

* Flutter `3.41.4` stable, framework revision `ff37bef603` (2026-03-03),
  engine `e4b8dca3f1`, Dart `3.11.1`.
* `SchedulerBinding.scheduleTask` (`packages/flutter/lib/src/scheduler/binding.dart`)
  says tasks execute **between frames**, priority ordered and filtered by the
  scheduling strategy. It explicitly asks for work “up to a millisecond”. Its
  queue requests `Timer.run(_runTasks)` and services one eligible item before
  requesting another event-loop turn. It gives no next-display-frame or
  bounded-latency guarantee.
* The default strategy permits only priority `>= Priority.animation` while
  transient frame callbacks are outstanding; otherwise it permits all work.
  `Priority.touch` is numerically above `Priority.animation`, so changing to
  it would compete more aggressively with input/render work. It does not make
  readiness deterministic and is rejected for this recovery.
* Microtasks/event-loop callbacks run in idle/event-loop opportunities; they
  are not a display deadline. Frame callbacks are transient callbacks at the
  beginning of a frame, before mid-frame microtasks and the persistent
  build/layout/paint pipeline. `scheduleFrameCallback` asks for a frame but
  would consume that frame's budget; it is not a safe substitute for a page
  preparation deadline.
* `ScrollPosition.applyContentDimensions` detects changed min/max extents,
  calls `correctForNewDimensions`, marks dimensions pending, then calls
  `applyNewDimensions`. The latter calls the active activity's
  `applyNewDimensions`.
* `BallisticScrollActivity.applyNewDimensions` calls
  `delegate.goBallistic(velocity)`. `ScrollPositionWithSingleContext.goBallistic`
  creates a new `BallisticScrollActivity` from `physics.createBallisticSimulation`.
  The framework's own documentation states that a ballistic activity is
  replaced when metrics change, preserving its current velocity.

Relevant official API cross-checks:

* <https://api.flutter.dev/flutter/scheduler/SchedulerBinding/scheduleTask.html>
* <https://api.flutter.dev/flutter/scheduler/Priority-class.html>
* <https://api.flutter.dev/flutter/scheduler/SchedulerBinding/scheduleFrameCallback.html>
* <https://api.flutter.dev/flutter/widgets/ScrollPosition/applyContentDimensions.html>
* <https://api.flutter.dev/flutter/widgets/ScrollPosition/applyNewDimensions.html>
* <https://api.flutter.dev/flutter/widgets/BallisticScrollActivity-class.html>
* <https://api.flutter.dev/flutter/widgets/ScrollPositionWithSingleContext/goBallistic.html>

**Conclusion.** The current use of `Priority.animation` is suitable only for
short opportunistic work. It cannot promise that a page's next preparation
slice runs in the following frame. The physical 40–63 ms scheduler waits are
consistent with the actual contract. Repeated runway exposure can cause
`applyContentDimensions -> applyNewDimensions -> goBallistic` while a fling is
live. The application is therefore attempting to repair data readiness by
timing scroll geometry, which conflicts with the framework instead of using a
stable surface and ready content. No scheduler primitive will be retained for
the normal page-ready path.

## Hypothesis matrix

| Hypothesis | Evidence for | Evidence against / gap | Decision |
| --- | --- | --- | --- |
| H1 one-shot hotset under-prefetch | `d36e0e` intentionally fixes target near ordinal 2 for an entire scope; physical traces request 3+ during fling | needs controller tests for rolling bounded convergence | adopt bounded rolling target; target must not advance on completion/layout |
| H2 scheduler starvation | trace: 1–2 ms slices but 40–63 ms queue waits; installed SDK has no deadline | no proof every wait maps to every visible hitch | remove it from steady state; emergency remains exceptional and synchronous/complete only |
| H3 prepared/exposed runway wrong abstraction | introduced at `986`; viewport publishes at interaction-start, drag-ready and low-watermark; framework recreates ballistic activity on metric changes | need widget evidence of reduced metric changes | remove split/runway; publish only complete cache geometry |
| H4 platform latency needs prefetch | native SQL often fast but platform/Dart total can be tens of ms; keyset reads cannot repair a reached page | fixed five page capacity limits how far ahead | use the five movable slots deliberately; retain serial cursor and only emergency foreground read |
| H5 surface/layout cost | cache listener drives `setState`, `SizedBox` height, `LayoutBuilder`, `CustomPaint`, semantics; surface extent changes alter layout | no FrameTiming trace yet attributes a dominant cost | do not add unrelated renderer rewrite; reduce avoidable geometry notifications and aggregate timing diagnostics |
| H6 zero-velocity input | historic diagnostic has real pointer movement with zero end velocity | no causal connection shown; framework input may also be starved | keep separate diagnostic, do not alter physics/velocity |
| H7 retention policy | five slots can be spent on stale history or an insufficient forward bank | capacity change prohibited | preserve bound/root/byte cap, make current/backward safety plus forward exact readiness explicit |

## Candidate comparison and selected architecture

| Candidate | Advantages | Rejected risk / result |
| --- | --- | --- |
| HEAD incremental patch | small local changes | would preserve duplicate lifecycle models and continue compensating scheduler/geometry timing |
| `47938b`/`610925` restoration | fewer latest runway additions | both are already post-baseline and retain experimentation around interaction-time readiness |
| mechanical checkout of `e64e84a` files | physically good contract | would lose current Query types, correctness and independent retention/native fixes |
| **Semantic `e64e84a` restore on current Query** | smallest owner set, known physical contract, stable metrics | selected; port only the vertical lifecycle, retain independently proven Query and correctness boundaries |

Selected contract:

```
exact committed scope
  -> one serial keyset cursor owner
  -> five-slot movable ready bank (root separately pinned)
  -> complete exact layouts in one cache geometry
  -> stable Flutter scroll surface

visible meaningful forward progression / idle boundary
  -> one bounded ready target
  -> missing sequential pages only
```

The rolling target is a single controller policy, not another planner/cache
state machine. On a new scope it fills only the bounded initial bank. It moves
only on meaningful visible-ordinal progression (or one explicit idle
reconciliation), never from page completion or a render-extent callback. It
does not recursively chase the end of the ledger. While an interaction is
active, normal work consumes already complete exact pages. A true frontier
miss may take the existing serial emergency path, but is not the steady-state
architecture. A decoded page that was already acquired at preemption may be
retained once for idle presentation so `d4a39656`'s no-reread behaviour
survives without a promotion subsystem.

## Default-removal burden and disposition

The following HEAD-only mechanisms have no current Query requirement and fail
the burden of proof (requirement, incompatibility with `e64`, a necessity test,
and no physical-regression contribution). They are scheduled for removal:

* prepared/exposed frontier split and private runway publication;
* low-watermark, interaction-start and drag-ready publication APIs;
* scheduler-sliced `frontierCritical` / `background` preparation urgency;
* one-shot hotset enum, background generation, adaptive background target and
  page-presentation promotion machinery;
* interaction-time cache geometry timing as a readiness mechanism;
* velocity/observed-latency adaptive lookahead where it duplicates the single
  rolling target.

Keep, subject to regression tests:

* stable `ScrollController`, `ScrollPosition` and existing physics;
* `ExplicitCommittedPagingController` as the sole sequential keyset owner;
* `CommittedLogViewportCache` as sole page/resource owner, complete-page
  publication, root pin, five-page movable cap and byte cap;
* current Android background channel dispatch (`76e32e81`), binary validation,
  Query types and native directional filtering;
* rail-critical scene ownership, visible-frame atomic publication, fail-closed
  counters and no-`TextPainter` build/layout/paint invariant;
* one retained preempted decoded page only if the focused no-reread test proves
  it is needed without reintroducing a second readiness state machine.

## Query non-regression plan

Do not edit the Query model as part of this recovery. Preserve
`FluviDashboardDirectionalQuerySet`, `DashboardDirectionalQuerySet`,
`dashboardDirection`, `presentationDirection`, `editingDirection`,
`draftDirection`, `incomeAppliedQueryKey`, `expenseAppliedQueryKey`, and the
atomic flow:

```
draft edit -> exact candidate prepared under sheet -> Apply exact candidate
-> exact scene bank activated -> immutable index/query/navigation published
atomically -> sheet dismisses onto filtered dashboard
```

Focused suite selection will cover independent Income/Expense application,
direction switching, Apply atomicity and saved Query. Native demo fixture tests
are the source of expected counts: all Income/Expense `1846/2458`, 2026
`42/658`, 2025 `1804/1800`, and 2026-07 `6/94`. These values will be verified,
not encoded into production pagination.

## RED tests before implementation

The implementation begins only after the following behaviour tests fail
against HEAD for the selected contract:

1. initial scope fills no more than the five movable exact pages;
2. meaningful forward visible ordinal advances one bounded rolling target and
   reads exactly missing pages;
3. completion alone cannot advance the target or recursively preload;
4. repeated render/extent callbacks at the same ordinal create no reads;
5. fixed-position idle converges, then hundreds of callbacks add zero reads;
6. traversal within a ready bank requires no repository read on a visible
   ordinal change;
7. cursor reads remain serial, no duplicate identity or skipped cursor;
8. reverse movement retains immediate safety and avoids evict/reload thrash;
9. root and movable pages stay within the current five-page/byte bound;
10. superseding scope disposes/blocks stale partial publication;
11. current Query/controller tests and fixture count tests remain green;
12. viewport keeps controller, position and physics identity and produces no
    `TEXT_LAYOUT_MISS`, `VERTICAL_CACHE_MISS` or `VERTICAL_ROOT_NOT_DRAWABLE`.

No unit test will assert a scheduler-wait millisecond threshold.

## Physical acceptance plan

The diagnostic owner will emit one `VERTICAL_INTERACTION_PERF_SUMMARY` per
interaction, aggregating generation/query key, velocity/travel/wall time,
ballistic and dimension-change counts, interaction reads/preparation/publication,
UI/scheduler timing, ready-ahead pages/pixels, retention/bytes, fail-closed
counts, and, when available, frame timing aggregates. It must not log per
frame.

After focused and broader verification, the production commit will be pushed
to `query`; the GitHub normal `lib/main.dart` human APK job for that exact SHA
will be monitored and its APK downloaded to
`/storage/emulated/0/Download/fluvi` with a recorded SHA-256. The remaining
manual Android tests are short drag, strong/repeated/long forward fling,
reverse and rapid direction changes, Query direction switch, Query Apply, and
return to vertical scroll. Only that physical test can decide whether the
motion is visually smooth; this checkpoint makes no 60 fps claim.
