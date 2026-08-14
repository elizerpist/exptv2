# Pre-Query live vertical paging restoration

## Status and acceptance checklist

This document is a source-of-truth handoff for the recovery. It records evidence, not a claim that physical smoothness has been verified.

| ID | Requirement source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VPR-01 | User mission / `381f230` baseline | viewport + pure planner | A `ScrollUpdateNotification` derives bounded forward demand during the same interaction. | Planner and viewport tests | DONE |
| VPR-02 | User mission | paging controller | Same-scope forward acquisition may start during drag/ballistic. | Controller RED/GREEN test | DONE |
| VPR-03 | User mission | paging controller + cache | An exact current response commits atomically during same-scope vertical input. | Controller RED/GREEN test | DONE |
| VPR-04 | User mission | paging controller | Structural/rail motion and true Query/scope supersession remain fail-closed. | Controller tests | DONE |
| VPR-05 | User mission / `4f0acd4b` | viewport | Only a negative signed update can request a previous page. | Existing viewport test | DONE |
| VPR-06 | User mission | cache | Five movable pages, 2 MiB bound, pinned root, compact anchors, and complete-only publication remain. | Cache/controller suites | DONE |
| VPR-07 | User mission | Query owners | Directional Query, atomic Apply, candidate staging, and current counts remain intact. | Fast Query suite + successful GitHub clean Room/native bridge lane | DONE |
| VPR-08 | User mission | scroll surface | ScrollController, ScrollPosition, and physics identities are not replaced; no physics change. | Existing widget test + source review | DONE |
| VPR-09 | User mission | diagnostics | Existing aggregate diagnostics remain; normal same-axis input no longer emits `inputPreemptedBeforeCommit`. | Source/test + physical APK | PARTIAL |
| VPR-10 | User mission | Android delivery | Normal `lib/main.dart` human APK for the production SHA is downloaded to `/storage/emulated/0/Download/fluvi`. | Successful GitHub human-APK job + local SHA-256 | DONE |
| VPR-11 | User mission | physical Android | Strong/repeated/reverse flings and Query flows are manually checked. | Human device | NOT DONE |

## Starting state and canonical boundary

* Starting isolated recovery HEAD: `b8d2340edb1ea605dc5511043d7df49826bd536b` (`docs: record vertical scroll recovery verification`).
* Its production parent is `6aa15f10ececc86164f688918d34b52c3782bced` (`fix: restore bounded ready-ahead vertical scrolling`).
* Canonical known-good behavioural baseline: `381f2306856fcf6903b53e41b3b0c897aa497e1b` (`prototype: refine query menu interactions`). It is the direct parent of the first Query-branch commit.
* First commit after that baseline: `034626329060f7c872104d96bbbe626ee25062d6` (`feat: add reusable Fluvi slide-up sheet shell`), whose parent is `381f230`.
* Nearby pre-Query stable milestone: `e64e84aededa61f7f41124100309e819eceb269e`.

The user's device verification makes `381f230` the behavioural oracle for vertical lazy paging. It is **not** a file-level revert target: current Query identity, candidate staging, directional Query state, and later independent correctness work stay on the current branch.

## Architecture comparison

### `381f230`: known-good contract

```text
ScrollUpdateNotification
  -> DashboardLogBoxViewport computes drawable first/last page
  -> CommittedVerticalDemandPlanner.plan (pure, O(1), default +2)
  -> onLoadNextPage(target)
  -> ExplicitCommittedPagingController serial keyset read
  -> complete page preparation + atomic CommittedLogViewportCache commit
  -> one exact geometry frontier / stable render surface
```

The baseline controller has `isMotionActive`, but no `isVerticalInteractionActive` or background-prewarm gate. Rail/structural motion can preempt work; the LogBox's own drag/ballistic activity cannot invalidate its required forward demand. The viewport owns observation, the controller owns one sequential cursor, and the cache owns complete resources, geometry, and retention.

### Current `b8d2340`: broken contract

```text
ScrollUpdateNotification
  -> DashboardLogBoxViewport only reports a visible ordinal
  -> controller's idle ready-bank target
  -> _canPrepareNow() rejects vertical interaction
  -> read response may become _DeferredCommittedPage
  -> commit waits for ScrollEnd / an idle callback
```

At the starting source, the responsible functions are:

* `ExplicitCommittedPagingController.recordVisiblePage` (starting line 199), which holds the moving target rather than the viewport planner.
* `_canPrepareNow` (starting line 572), which requires both no motion and no vertical interaction, plus the background-prewarm gate.
* `_readAndCommit` (starting line 399), which retains an exact response and reports `inputPreemptedBeforeCommit` when that combined gate closes.
* `DashboardCoreController` constructor (starting line 304), which supplies the vertical interaction flag and a background gate; its idle and post-layout hooks call `prepareReadyAheadAtIdle`.
* `DashboardLogBoxViewport` `ScrollStartNotification`/`ScrollUpdateNotification` paths (about lines 1069--1146 and 1208--1288), which call `onVisiblePageChanged` rather than invoking baseline-style bounded demand.

This creates a cross-owner policy violation: a same-axis input lifecycle decides whether the data/resource owner may complete an exact page for that same interaction.

## Commit archaeology ledger

| Commit | Change / intent | Current classification | Disposition |
| --- | --- | --- | --- |
| `5f389823` | Slim native committed-page acquisition and codec payload. | Independent platform/data improvement. | KEEP |
| `610925ad` | Added bounded planner and live demand/frontier maintenance. | Consistent with baseline live contract; later complexity was added. | REIMPLEMENT useful viewport demand only |
| `f8657d73` | Added interaction observer and suppressed speculative rail/Query work during vertical input. | Correct separation for unrelated speculative work. | KEEP that separation |
| `76e32e81` | Removes Android platform-thread paging latency. | Independent acquisition improvement. | KEEP |
| `de0a584d` | Bidirectional, byte-bounded retention. | Correct bounded-resource fix. | KEEP |
| `6b975f55` | Paused complete page presentation for vertical input. | **First verified paging-contract regression boundary.** | REMOVE same-axis pause policy |
| `742760dc` | Extended vertical-input presentation pausing while restoring bounded cache resources. | Retention useful; pause suspect. | KEEP retention; REMOVE pause consequence |
| `777569ad` | Zero-velocity input diagnostics. | Diagnostic-only. | KEEP only if cheap |
| `31b9a4d3` | Corrected single-use pause signal. | Fixed a consequence of pause architecture. | Remove obsolete pause dependency |
| `a6ecfc25` | Attempted frontier advance through fling. | Did not restore baseline live acquisition. | Do not restore wholesale |
| `4f0acd4b` | Prohibits a previous keyset read on a forward signed update. | Real correctness fix. | KEEP |
| `d588b5ea` | Reduced presentation yielding. | Superseded by later simplification. | No separate restoration |
| `d15c6507` | Repaired interactive frontier readiness. | Symptom treatment, not baseline contract. | Do not retain as policy without proof |
| `a0b41eab` / `47938b12` | Bounded ready hotset and retry after foreground gates. | Useful initial optimization, not correctness. | Keep only bounded idle optimization |
| `986ba698` / `f18e6a35` | Prepared/exposed runway publication. | Removed by current one-frontier cache; physical result did not justify it. | Do not reintroduce |
| `d36e0e45` | One-shot per-scope hotset. | Moved readiness into active fling after bank exhaustion. | Do not use as correctness policy |
| `d4a39656` | Retain a preempted decoded page without reread. | Useful for real structural/surface preemption. | KEEP invariant, not vertical-input deferral |
| `62cacf5b` | Frame-budgeted frontier preparation. | Scheduler compensation for late foreground work. | Do not reintroduce |
| `6aa15f10` | Single ready frontier and five-page idle bank. | Removed runway state but retained idle-only input gate. | Replace gating/target ownership |

## Physical evidence and verified failure mechanism

The supplied trace on Expense / All (`2458` entries) showed the initial bank through roughly ordinal five, then repeated `VERTICAL_READY_AHEAD_DEFERRED verticalInteraction=true`. Page six could finish data (`totalDataReadyMicros` about 66 ms) but emitted `VERTICAL_PAGE_COMMIT_REJECTED reason=inputPreemptedBeforeCommit` merely because another same-scope pointer/drag began. The following interaction reported a completed repository read but zero prepared/published pages; its ready frontier stayed at five while prepared-ahead pixels collapsed from about 3271 to 765. This is direct evidence of intentionally withheld readiness, not a demonstrated physics defect.

## Flutter framework evidence

Installed SDK inspected in Ubuntu proot:

* Flutter `3.41.4`, framework revision `ff37bef603`, Dart `3.11.1`.
* `SchedulerBinding.scheduleTask` runs non-rendering work between frames under `schedulingStrategy`; source and official API say tasks should be short (about one millisecond). It offers priority, not a next-display-frame deadline. The default strategy permits `Priority.animation` or above while transient callbacks exist; `Priority.touch` merely competes more aggressively. Neither is a correct readiness guarantee for a reached page.
* `ScrollPosition.applyContentDimensions` calls `applyNewDimensions` after changed extents. `BallisticScrollActivity.applyNewDimensions` calls `delegate.goBallistic(velocity)`, and `ScrollPositionWithSingleContext` constructs a ballistic activity from physics if possible. Thus each complete-page surface-height change can re-evaluate ballistic motion. This recovery keeps one exact geometry frontier and changes no physics.
* Primary evidence: installed framework source under `/home/flutteruser/flutter/packages/flutter/lib/src/{scheduler,widgets}`, the official [scheduleTask API](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/scheduleTask.html), and [applyContentDimensions API](https://api.flutter.dev/flutter/widgets/ScrollPosition/applyContentDimensions.html).

## Selected architecture: semantic behavioural restoration

```text
exact current Query scope
  + viewport ScrollUpdate-derived CommittedVerticalDemandPlanner target
  + ExplicitCommittedPagingController's one serial cursor drain
  + CommittedLogViewportCache's complete page/text/geometry/retention commit
  + current five-page / 2 MiB / cursor-anchor policy
```

The initial five-page bank remains an **idle optimization**, not a scrolling correctness invariant. A live forward demand uses the same cursor drain and is eligible during its own vertical drag/ballistic phase. An exact, still-current read response can prepare and commit during that phase. Real rail/structural motion and scope identity mismatch still preempt/fail closed; a decoded response held by one of those real preemptions may retain the `d4a39656` no-reread property.

### Implemented mapping onto current Query ownership

* `CommittedVerticalDemandPlanner` is restored as a small pure policy in
  `lib/features/dashboard/logbox/application/`. It derives a bounded `+2`
  forward target, adds one page of protection near the drawable end, and never
  advances itself on a page completion or an extent callback.
* `DashboardLogBoxViewport` applies that policy from both `ScrollStart` and
  `ScrollUpdate` (current lines 1128--1140 and 1266--1279). It owns only
  observable position-to-demand conversion; it still permits a previous read
  only for a negative signed update at the retained lower boundary.
* `ExplicitCommittedPagingController.requestForwardDemand` (lines 213--235)
  starts the same serial cursor drain with a `liveViewportDemand` scheduling
  origin. This is not a second controller, cache, or cursor. If an idle drain
  is already reading, it is upgraded in place (lines 259--302).
* `_canRunReadyWork` (lines 595--602) keeps vertical input as an idle-prewarm
  guard only. `_canCommitCurrentPage` (lines 604--610) retains real
  structural motion and unknown-surface protection, but deliberately no
  same-scope vertical-input rejection. `_readAndCommit` now defers only for
  `structuralOrSurfacePreemptedBeforeCommit` (lines 474--485).
* `DashboardCoreController` no longer duplicates vertical input in its
  background-prewarm closure. Query, rail, candidate, and surface gates remain
  intact; the paging owner is the sole place that distinguishes optional idle
  work from the interaction's required live demand.

No `SchedulerBinding.scheduleTask`, scroll physics, `ScrollPosition`, fake
extent, prepared/exposed runway, or additional cache was added. The current
one-exact-frontier cache remains the geometry owner.

### Delete or remove as policy

* `onVisiblePageChanged` / `recordVisiblePage` controller-owned moving target.
* The `isVerticalInteractionActive` term from required forward acquisition/commit gating.
* Normal `inputPreemptedBeforeCommit` handling for same-scope vertical input.
* Idle-only claims in cache/controller comments.

### Keep

* `ExplicitCommittedPagingController` as only sequential keyset owner.
* `CommittedLogViewportCache` as only resource/geometry/retention owner.
* Atomic complete-page commit and prebuilt `TextPainter` resources.
* Query scope/presentation/generation checks and atomic Query Apply pipeline.
* `4f0acd4b` signed reverse demand gate.
* Five movable pages, pinned root, 2 MiB bound, compact cursor anchors.
* Existing aggregate interaction diagnostics and stable controller/position/physics identities.

## TDD evidence and verification

The first RED run added the missing pure planner and two controller contracts
before production code changed. On starting `b8`, the active-input test
requested ordinal six but observed only ordinal five, and the exact-response
test expected a commit but received `false`; the planner import also failed
because the baseline policy no longer existed. These are behavioural failures,
not timing thresholds.

The GREEN tests now cover:

1. A live forward demand starts while `isVerticalInteractionActive == true`,
   including a new scope whose idle bank never had an opportunity to run.
2. An exact response completing after same-scope vertical input starts commits
   atomically; a real structural preemption retains the decoded response and
   can resume without a reread.
3. Scope supersession cannot publish the old response, and completion cannot
   recursively move the target or whole-ledger preload.
4. The pure planner advances a small `+2` target from live demand, protects the
   drawable frontier, caps at the terminal ordinal, and stays fixed at an
   unchanged position.
5. Signed forward motion cannot request a previous page; cache retention keeps
   five movable pages, the root separately pinned, the byte bound, and
   complete-only publication.

Executed locally in Ubuntu proot:

```text
flutter test committed_log_viewport_cache + paging controller + planner
             + viewport + vertical observer + motion boundary  -> PASS (35)
./scripts/test-fluvi-fast.sh                                -> PASS (171)
./scripts/verify-fluvi-boundaries.sh                        -> PASS
flutter analyze                                             -> PASS (0 issues)
```

The fast suite includes directional Income/Expense applied Query independence,
atomic Query Apply/candidate publication, cancel/reopen behavior, query-menu
controllers, saved-query behavior, prepared index ownership, and scroll
identity invariants. The native fixture source
`DemoDatasetGeneratorTest.directionalYearAndAllTimeCountsRemainAuthoritative`
asserts current values `42/658` (2026), `1804/1800` (2025), and `1846/2458`
(all); its 2026 monthly fixture also asserts `6/94`, including July. An
attempt to execute the two native demo tests under Termux/proot reached the
Android resource task but failed because the local AAPT2 daemon cannot start;
the GitHub `test-core` lane subsequently passed its clean Room core and native
dashboard bridge test jobs for the exact production SHA. No Android production
code or acquisition boundary changed in this recovery.

## Remaining unrelated risks

Platform/decode latency, rare zero-velocity input, render-surface layout cost, and physical frame timing remain separate investigations. No CI result can certify 60 fps. Final physical status is **NOT VERIFIED BY CI** until a human runs the normal APK.

## Final implementation record

* Production commit: `674c9563` (`fix: restore pre-query live vertical paging
  contract`).
* Documentation commit: this document's separate commit is created after the
  production SHA and delivery evidence are known.
* Test/analysis results: focused vertical `PASS (35)`, fast Query/boundary
  `PASS (171)`, boundaries `PASS`, analyzer `PASS (0 issues)`, and the remote
  clean Room/native bridge lane `PASS`. The local native count runner remains
  blocked only by the Termux AAPT2 daemon environment, as recorded above.
* Human APK: GitHub job
  [`build-human-diagnostic-apk`](https://github.com/elizerpist/exptv2/actions/runs/31817115461/job/94822753814)
  succeeded for the exact production commit. The normal `lib/main.dart`
  artifact is
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_674c956.apk`
  (71,817,452 bytes); local SHA-256 and the published release digest both are
  `1aeec5d5be5a2abad1e1961c2e1b88892cc8bc079af02ac523f0ac44b464920e`.
* Physical acceptance: **NOT VERIFIED BY CI**
