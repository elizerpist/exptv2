# Vertical scroll recovery verification

Date: 2026-08-14  
Forensic checkpoint: `6759ee586407d088540ad0ca7b87fa40311ec40c`  
Production recovery: `6aa15f10ececc86164f688918d34b52c3782bced` — `fix: restore bounded ready-ahead vertical scrolling`  
Starting production HEAD: `f18e6a351454ca0898299cb7e6fbdc55126ca360`  
Known-good vertical source: `e64e84aededa61f7f41124100309e819eceb269e`

This document records automated verification and human-APK delivery. It is not
a claim that Android motion is physically fixed: the normal APK still requires
the manual scenarios listed below.

## Recovered architecture

The implementation is a semantic forward port of the vertical contract at
`e64e84a`, not a checkout or Query revert:

```
current directional Query/domain/native model
  + e64 single complete drawable geometry
  + one serial committed keyset cursor
  + five movable exact-ready pages (root pinned separately)
  + only independently useful later correctness fixes
```

`ExplicitCommittedPagingController` now owns one bounded ready target. A new
committed scope fills at most the five movable slots. Meaningful visible-page
progress advances that target; page completion, cache notification and render
extent callback do not. While a drag or ballistic interaction is active, it
records demand but does not turn a reached page into normal foreground I/O or
paragraph preparation. Idle then consumes the already-recorded serial target.

`CommittedLogViewportCache` has one complete exact geometry. A page constructs
its text resources before that geometry is published. There is no
prepared/exposed frontier, runway, low-watermark, interaction-start/drag-ready
publication, or vertical `SchedulerBinding.scheduleTask` continuation.

The retained `d4a39656` correctness property is deliberately smaller than its
old machinery: one immutable decoded page acquired just before input preemption
can be committed once at idle without rereading it. A failed cursor identity is
not spun through completion callbacks; it waits for a new user demand epoch.

## Removed and retained state

Removed from the vertical page-ready path:

* `CommittedVerticalDemandPlanner` and adaptive velocity/latency lookahead;
* prepared-versus-exposed geometry, runway and low-watermark publication;
* interaction-start and drag-ready geometry publication;
* one-shot hotset satisfaction, background prewarm generations, pending
  presentation/promotion, frontier-critical urgency and scheduler slices;
* cache-page preparation as normal active-drag/ballistic work.

Retained:

* Query's directional applied/draft identities and atomic prepared-candidate
  Apply flow, unchanged by this commit;
* the existing Room/MethodChannel/binary-validation acquisition boundary;
* one serial keyset cursor owner, page size 24, root pin, five-page movable
  cap, byte cap, complete-page publication and fail-closed counters;
* the stable viewport controller/position/physics lifecycle. The existing
  `DashboardVerticalScrollController` remains an observer only: it forwards
  framework ballistic behaviour unchanged and aggregates diagnostics; paging
  does not replace any of those identities.

The installed framework examined in the forensic checkpoint was Flutter
`3.41.4`, framework `ff37bef603`, Dart `3.11.1`. Its `scheduleTask` contract is
opportunistic work between frames, not a next-frame deadline. `Priority.touch`
would only compete harder with input/render work, and a transient
`scheduleFrameCallback` would spend the next frame's build/layout/paint budget.
No scheduler primitive is therefore used as the normal page-ready mechanism.
The framework path `applyContentDimensions -> applyNewDimensions ->
BallisticScrollActivity.applyNewDimensions -> goBallistic(velocity)` explains
why the removed ready-runway extent mutations could recreate ballistic
activities during a fling.

## RED -> GREEN evidence

The selected architecture began with behaviour tests that were incompatible
with HEAD's split runway/hotset design, then turned green after the restoration:

* a new scope prepares exactly its bounded five-page ready bank;
* preparation waits for known exact surface width, so no page can be read then
  committed without its drawable text layout contract;
* visible forward progression records one bounded rolling target only after
  idle, while 100 idle callbacks and 200 same-position extent callbacks create
  zero extra reads;
* a simulated common fling through ordinals already in the exact-ready bank
  starts no repository read during interaction;
* one serial cursor produces ordinals 1 through 5 without duplicate reads;
* a failed read cannot self-retry through the pipeline-idle callback; a fresh
  interaction epoch is required;
* reverse reload is deferred through input and avoids immediate evict/reload
  thrash; a preempted decoded page resumes at idle without reread;
* superseding a query scope rejects stale private work before it publishes.

The failure retry test initially exposed a real implementation defect in the
new drain: automatically reopening the drain after a failed identity could
loop indefinitely. The red test was stopped after 39 seconds, then made green
with an explicit two-second timeout by removing that completion restart and by
not invoking the core's idle reconciliation hook while a failed target remains.

## Automated verification

All Flutter commands below ran in Ubuntu proot, not through the Termux-host
Flutter binary. No golden test was added or executed.

| Evidence | Result |
| --- | --- |
| Focused cache/controller/viewport/observer suites | `+25`, all passed |
| Focused directional Query, atomic Apply, saved Query and query-menu suite | `+41`, all passed |
| Exact curated fast-test file selection, forced serial after one unrelated parallel timeout | `+171`, all passed |
| `./scripts/verify-fluvi-boundaries.sh` | passed |
| `flutter analyze` | `No issues found!` (52.5 s) |
| GitHub Actions [run 31798805453](https://github.com/elizerpist/exptv2/actions/runs/31798805453), exact production SHA | `test-flutter` passed in 1m24s; `test-core` passed in 4m50s; normal human APK job passed in 5m5s |

The first local default-parallel `test-fluvi-fast.sh` run had one timeout in
the unrelated rail-only `dashboard_scene_window_rotation_test`; its isolated
rerun passed, and the full exact selection passed serially. The CI's actual
curated script then passed on the exact production SHA, so this was treated as
local resource contention rather than a production recovery failure.

The local proot attempt to invoke the Kotlin fixture test was blocked before
test execution by an AAPT2 daemon startup failure in the Termux/proot
environment. The exact GitHub `test-core` job subsequently passed both clean
Room core tests and native dashboard bridge tests. The source fixture asserts
the expected demo counts rather than production code hardcoding them:
all Income/Expense `1846/2458`, 2026 `42/658`, 2025 `1804/1800`, and 2026-07
`6/94`.

## Checklist status

| ID | Status | Evidence / remaining boundary |
| --- | --- | --- |
| VSR-01 single-ready-frontier semantic restoration | DONE | production source, focused cache/controller tests |
| VSR-02 no readiness-driven live metric publication | PARTIAL | production path and tests prove removal; physical `goBallisticInvocationCount` trace remains required |
| VSR-03 bounded rolling exact-ready hotset | DONE | controller behaviour tests |
| VSR-04 common fling not normally foreground-ready | PARTIAL | simulated ready-bank test passes; physical fling confirmation remains required |
| VSR-05 root/five-page/byte/complete-page/fail-closed invariants | DONE | cache tests and boundary verification |
| VSR-06 directional Query non-regression | DONE | focused Flutter Query suite plus exact-SHA Room/native CI |
| VSR-07 controller/position/physics identity | DONE | viewport and rebuild-isolation tests |
| VSR-08 one aggregated interaction summary | DONE | viewport test and source inspection |
| VSR-09 physical Android acceptance | PARTIAL | normal human APK delivered; human scenarios have not yet been run |

## Human APK delivery

The exact normal human diagnostic profile APK, built from `lib/main.dart`, is
available locally at:

`/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_6aa15f1.apk`

* GitHub release: [fluvi-human-diagnostic-6aa15f1](https://github.com/elizerpist/exptv2/releases/tag/fluvi-human-diagnostic-6aa15f1)
* Asset size: 71,817,452 bytes
* SHA-256: `dd819790504b397bc28ae079f3933f0e1a6af297d6435a70ed1bb41396b01bd6`
* The locally computed digest equals the GitHub release asset digest.

## Required physical review

Run the APK manually through short drag, strong/repeated/long forward flings,
reverse fling, rapid forward/backward, Query direction switch, Query Apply,
and return to vertical scroll. Review the one
`VERTICAL_INTERACTION_PERF_SUMMARY` per interaction: normal forward motion
should show ready pages ahead and no recurring repository/readiness dependency
on the currently painted page. The fail-closed counters must remain zero:
`RAIL_CRITICAL_CACHE_MISS`, `TEXT_LAYOUT_MISS`, `VERTICAL_CACHE_MISS`, and
`VERTICAL_ROOT_NOT_DRAWABLE`.

Remaining unproven physical risks are a fling longer than the bounded initial
bank, rapid reversal beyond immediate retained safety, and residual renderer
layout/semantics cost on the real device. No automated result is presented as a
claim of restored 60 fps.
