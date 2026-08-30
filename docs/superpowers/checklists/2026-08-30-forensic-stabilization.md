# Fluvi forensic stabilization — acceptance checklist

**Status: active forensic release gate.** This checklist supersedes the
`DONE` claims in the r54 dashboard closure for the defects covered here.  A
passing test, a prior APK, or a settled screenshot is not completion evidence.
No Android release build is allowed while a production acceptance row is not
`DONE`.

| ID | Source / observed evidence | Intended code area / owner | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| FS-A | 2026-08-30 forensic prompt, issue A | `FluviDiagnosticLogger`, `DebugConsole` | The on-screen and copied/exported chronological history retains exactly the newest 2,000 entries; entry 2,001 evicts precisely entry 1. Production diagnostics remain opt-in/debug-only. | Unit FIFO boundaries (1,999/2,000/2,001), capture/export FIFO boundary, console-visible-text test, source gating review; diagnostic-device confirmation still required. | PARTIAL |
| FS-B | Latest device screenshot `Screenshot_20260829-231404.png`, issue B | Full Dashboard Budget pager/cascade/surface composition | A recorded intermediate pager frame identifies one actual gray-pixel RenderObject/layer owner; its corrected composition has no unintended slab in each required transition direction/state. | Production-parent intermediate-offset widget/raster diagnostics and physical-device slow/fast/reverse/interrupted runs. | PARTIAL |
| FS-C | Latest device screenshot `Screenshot_20260829-231444.png`, issue C | Canonical Budget state → selected state → page/wrapper → Header/limit renderer | State replacement/absence is traceable with semantic key and generation through the actual renderer. Only a reproduced, semantically valid causal path may be corrected. | End-to-end bounded diagnostics plus transition stress and physical-device reproduction. | PARTIAL |
| FS-D | Device report and Fluvi Logs r56, issue D | Avatar carousel → semantic preview/commit → focus/query/scene scheduling | Avatar ballistic motion has the intended semantic commit count, no offset-driven refresh/recreation storm, and physical-device motion is smooth without hiding/delaying semantic feedback. | Event counters/owner-path tests; physical-device repeated/reverse fling. | PARTIAL |
| FS-E | Device report and Fluvi Logs r56, issue E | Time controller → period commit → query/summary/page scheduling | Time ballistic motion has the intended semantic period commits, no offset-driven heavy recomputation storm, and physical-device motion is smooth. | Event counters/owner-path tests; physical-device repeated/reverse fling. | PARTIAL |
| FS-F | Device screenshots `Screenshot_20260829-232223.png` and `Screenshot_20260830-011652.png`, issue F | `CurrentQueryController` canonical facet data → `CoreDashboard` → `MindDashboardCoreSurface` | The shared `QueryAmountRangeControl` is visibly mounted whenever the canonical applied Query supplies a range; loading/unavailable state follows one explicit product contract and can be diagnosed end-to-end. | Mind ready/loading/latest-wins widget tests and physical-device evidence. | PARTIAL |
| FS-P1 | Prior accepted Header palette behavior and `MILESTONE_COMMITS.md` | Header visual engine/palette policy | Category Header palette identities, retained backend/program/shader and ticker behavior remain unchanged. | Existing Header palette/visual tests and source review. | NOT DONE |

## Forensic classifications at the current baseline

| Issue | Classification | Current evidence |
|---|---|---|
| FS-A | **A — PROVEN ROOT CAUSE** | The persistent on-screen ring was `1000`; the separate capture/export ring also had a divergent `2048` limit. The console itself consumed `entries`/`allText` without a smaller UI cap. |
| FS-B | **B — OBSERVED / ROOT CAUSE NOT YET PROVEN** | Physical screenshot shows the intermediate slab; current source topology has multiple cascade/surface/clip owners but has not yet been correlated to the captured pixels. |
| FS-C | **B — OBSERVED / ROOT CAUSE NOT YET PROVEN** | Physical screenshot shows `— / —` with non-empty distribution data; Fluvi Logs r56 did not capture that state transition. |
| FS-D | **B — OBSERVED / ROOT CAUSE NOT YET PROVEN** | Device report and r56 show per-crossing preview/focus work and a catalog-preparation failure, but not a measured physical frame diagnosis. |
| FS-E | **B — OBSERVED / ROOT CAUSE NOT YET PROVEN** | Device report requires a separate time-lane trace; no current capture proves an owner. |
| FS-F | **A — PROVEN ROOT CAUSE** | The applied `CurrentQueryController` had the correct scope but no facet presentation until Query Menu was opened. Mind treated that nullable render-adjacent facet as its only amount-domain authority, so the shared control received no actionable domain. The newer device capture physically shows the exact resulting 1,000–1,000 single disabled thumb state. |

## Protected boundaries

Preserve the accepted stable LogBox controller/position and Scrollable physics,
immutable committed virtual geometry, bounded prepared-scene ownership,
latest-wins publication, input-first scheduling, and retained Category Header
visual identities described in `MILESTONE_COMMITS.md`.  No row may be changed
to `DONE` without its listed physical evidence.

## 2026-08-30 implementation evidence

- **FS-A:** both the persistent on-screen history and the capture/export
  history are now exactly 2,000 entries. The red-to-green tests cover 1,999,
  2,000, and 2,001 entries, chronological FIFO eviction in both paths, the
  visible console count/text, and the existing debug/compile-time enablement
  gate. `FluviDiagnosticEvent` now adds logger-owned monotonic `seq` and
  `elapsedMicros` fields to every retained record.
- **FS-F:** source inspection proved that the initial `CurrentQueryController`
  had an applied scope but no facet presentation, while Mind read only that
  nullable presentation. `DashboardAppliedQueryFacetLoader` now loads the
  active applied scope after dashboard readiness and writes the immutable
  result to that same controller. The loader is latest-wins on direction and
  scope changes; it does not maintain a Mind-local Query/domain. The real
  CoreDashboard Mind host test proves unavailable → shared-range mounting.
- **FS-B:** `HOME|PAGER_*`, `HOME|LAYER_CANDIDATES`, and the new
  `HOME|LAYER_STACK` record bounded intermediate pager/collapse milestones,
  actual Dashboard paint order, surface/clip topology, cascade opacity/scale,
  and the relevant physical bounds. The instrumentation deliberately does not
  paint a test cover or alter pixel ownership. It still needs an intermediate
  device capture to identify the actual gray-pixel owner. The new full-parent
  Partner/Rhythm collapse gate did, however, reproduce a concrete lower-only
  failure: at an intermediate Card2 width of `355.69512195121956dp`, the
  non-scrollable 31-day Rhythm resolver threw `Unsupported non-scrollable
  Spending Rhythm viewport`. The upper Partner donut/list does not use that
  resolver, explaining why it remained intact. The resolver now retains the
  minimum bar/gap geometry in a content-only horizontal viewport during that
  temporary narrow frame; it never throws, hides the footer, or adds a second
  card surface. The same full-parent test also exposed a diagnostic-only
  `RenderBox.localToGlobal` read during layout; pager diagnostics now use a
  post-frame viewport snapshot instead. This is source/raster evidence, not
  yet a physical gray-pixel ownership proof.
- **FS-C:** `LIMIT|STATE` records semantic visibility transitions and the new
  `LIMIT|SELECTION_UNAVAILABLE` event reports the first exact canonical
  rejection reason (`snapshotUnavailable`, stale revision/target mismatch,
  missing numerator, or prepared-window miss), with selection, generation,
  navigation and visible-frame identity. This is observability only; no stale
  amount is retained as a cosmetic fallback.
- **FS-D:** Avatar diagnostics remain bounded at gesture, semantic preview,
  settle and hotset boundaries. The requested focus horizon now survives the
  bootstrap gap and is prepared at the first canonical index publication.
- **FS-E:** `TM|FLING_*` now includes a deduplicated
  `TM|FLING_SETTLED` record after the motion kernel accepts the semantic
  settle, making the start → crossing → commit lifecycle reconstructible.
  None of FS-B through FS-E is a proven physical closure yet.

The production `BudgetDistributionPager` test now asserts that a real
intermediate PageView slide emits both `HOME|PAGER_MILESTONE` (including the
fractional offset) and `HOME|LAYER_CANDIDATES`. That proves the on-screen dump
will carry the surface/clip candidate context; it is not a pixel-owner proof.

## Original physical-gate matrix (still release-blocking)

The earlier G1–G7 contract remains in force in addition to the forensic pass.
This matrix prevents a newly green isolated test from being mistaken for an
APK/device acceptance result.

| ID | Current source evidence | Acceptance still required | Status |
|---|---|---|---|
| G1 | The selected Avatar always installs its long-press recognizer when the direct input controller exists. Its context is resolved through `directInputEditContext()`, which retains only an exact selected-target/scope authority and is not gated by `header.editContext`. Targeted first-contact and draft-survival widget tests are green. | Physical first edit, repeated ticks, reverse, release, revisit, and stale-write races on the actual device. | PARTIAL |
| G2 | A rail hotset request made before bootstrap was silently lost because there was no index yet. Core now retains the bounded semantic horizon and primes it at canonical index publication. A second reproduced gap was that the first ready-frame fling could begin before the `Priority.idle` hotset task ran, causing direct `deriveFast` misses. The Core now completes its fixed ≤17 target semantic horizon before direct Avatar input; later replenishment stays cancellable/idle. A third reproduced scheduler leak left a Card2 `Future.delayed(Duration.zero)` hotset timer pending after Avatar input/disposal. Card2 now uses the shared cancellable input-fair scheduler, with one revocable grant per optional scope. The pre-bootstrap, immediate-first-fling, cancellation, and real-pointer matrix tests are green. | Measured time-vs-Avatar delta and repeated/reverse physical fling with no visible semantic-tick hitch. | PARTIAL |
| G3 | Summary raw pointer-down preempts the time motion lane and pending neighbour work before gesture resolution. The real Summary-after-live-time-ballistic test is green. | Device pointer-down-to-action timing while active and immediately after a time fling; exact remaining lock owner if any. | PARTIAL |
| G4 | Full-parent split Budget coverage now mounts a real Partner/Rhythm frame and drives collapse in 5% steps. It reproduced and repaired the lower-only intermediate-width Rhythm layout exception and the layout-unsafe pager diagnostic, without a visual mask. The device screenshot's exact gray-pixel owner still needs capture. | Identify the actual intermediate gray-pixel RenderObject/layer; then prove Split and Unified slow/fast/reverse/interrupted collapse without the slab. | PARTIAL |
| G5 | The canonical applied-query facet loader gives Mind and Query Menu the same `CurrentQueryController` domain owner. Ready/loading/latest-wins and two-endpoint tests are green. | Device parity: two visible draggable endpoints and matching values after navigation/change in both hosts. | PARTIAL |
| G6 | Unified now has only `budget-unified-content-card-surface`; `BudgetDistributionCardShell` becomes content clipping only. The topology/controller-identity tests are green. | Device Split → Unified → Split verification with selected Avatar/page retained and no nested physical card. | PARTIAL |
| G7 | The resolved plot target is 48.4dp and compact floor 38.72dp; conservation and Card2/Rhythm tests are green. | Device inspection at reference Split/Unified geometries: outer Card2 unchanged and upper Partner space reclaimed. | PARTIAL |
| P1 | No palette/render-engine source was altered in this pass. The current category-scale, palette transport, visual-engine, and fragment-backend target suite passed 85 tests. | Verify representative category transitions on device. | PARTIAL |

## Current automated verification (not physical closure)

The following exact targeted suites have exit-code-confirmed green runs on the
current source checkpoints:

- diagnostic logger and debug panel: **16 tests** (including 1,999/2,000/2,001
  FIFO cases);
- Avatar rail, direct quick-edit gesture, limit edit controller, and Budget
  presentation controller: **87 tests**;
- Summary/time-motion controllers and Summary presentation widgets:
  **54 tests**;
- Category Header category-scale, palette transport, visual-engine, and
  fragment-backend regression suite: **85 tests**;
- shared amount-range/domain/query-menu suite: **12 tests**, plus the two
  concrete Core Mind ready/unavailable host gates;
- Budget core-surface, distribution pager, Partner distribution, and Rhythm
  geometry/layout suite: **33 tests**;
- immediate first-Avatar-fling focus-hotset gate and the combined G1/G2/G3
  affected suite: **96 tests**.
- the complete current `core_dashboard_test.dart` production-parent suite:
  **24 tests**, including G3 live-ballistic takeover, G4 every-5%-step
  collapse proxy, G5 ready/unavailable Mind hosts, and the unified/split
  surface checks.
- motion-density, zero-I/O navigation, carousel ballistic diagnostics/physics,
  and time-navigation target suite: **43 tests**.
- Card2 drawable input-fair cancellation, Card2 semantic-bank/scope, Budget
  Mode-nav, and the real 30× physical rail-density matrix: **22 tests**.
- the latest post-r56 combined Avatar/quick-edit/Budget-presentation,
  Core ephemeral-focus, Core Query-application, and production-parent Core
  Dashboard run: **172 tests**.

The current exact G3 production-parent ballistic-takeover gate is also green.
The former failed runs that named obsolete test paths did not execute a failing
test; they were rerun using the repository's actual paths. The unrelated
complete-Dashboard-directory failure recorded below remains inherited. None of
these automated results changes a physical gate to `DONE`.

`flutter analyze` over all **13** production Dart files changed since the
remote baseline reported no issues. `git diff --check` is re-run before each
source-coherent commit.

After the G4 source/raster repair, the current focused full-composition run
(`spending_rhythm_bar_layout`, `spending_rhythm_bar_chart`,
`budget_distribution_pager`, `budget_partner_distribution_card`, and
`core_dashboard`) passed **48 tests**. A fresh analyzer run over all three
changed production files and both changed test files reported no issues, and a
fresh `git diff --check` passed. This is still not a replacement for the
required device intermediate-frame evidence.

The first current full `test/features/dashboard` run through
`e904e0358722cc81cd2e96a00767bd01edd26baf` completed with **1,041 passing
tests and 25 failures**. The failure list is retained rather than suppressed:
LogBox stable render surface (1), rail-density trace (3), Budget mode-nav (1),
Header Deep Drift/classic/Space Fabric (12), geometry goldens (6), and Summary
experiments (2). The exact LogBox failure is `WidgetController.state` with
`Bad state: Too many elements` at line 87; it was previously reproduced at
both this pass's G4 checkpoint and pre-G4
`c0768dda358f1a91054abe30b3680f260a52976d`.

The four G2-adjacent failures were then independently reproduced: the three
rail-density cases did not hit their carousel because their 800×600 test root
ended above the widget at y=721, and the Mode-nav case leaked a pending Card2
maintenance timer. The trace harness now uses an 800×900 physical test root;
the Card2 owner uses the shared cancellable input-fair scheduler. The focused
Card2/Mode-nav/rail matrix passed **22 tests** after that repair. The full
Dashboard directory was rerun through
`5759aa444979278c91cfa9f3385d978b0a52f577` and improved to **1,046 passing
tests and 22 failures**: LogBox stable surface (1), Header Deep Drift (3),
Header classic parity (1), Header Space Fabric temporal (8), geometry goldens
(6), Summary experiments (2), and one Core Query idle-resume case (1). The
four former rail-density/Mode-nav failures are absent. The exact Core Query
idle-resume test was immediately rerun alone and passed **1/1**, so its
full-suite-only failure is an unresolved parallel-test interference, not a
proven Core regression or an inherited failure. The remaining failures are not
hidden and the directory is still **not green** for release proof.

## Continued G2 first-fling evidence

The new deterministic test
`RED G2: the first Avatar fling cannot fall through a pending idle hotset to
UI-isolate derivation` deliberately starts an eight-crossing Avatar motion in
the exact ready frame after the Core accepts the local horizon, without an
event-loop/idle yield. Before the repair the test recorded **2 hotset misses**;
the matching crossings fell through to the direct derivation path. The Core
now makes the existing fixed-capacity (maximum 17) immutable focus cache ready
at this no-input boundary. The same test now records **0 misses**, eight
hotset promotions, and `uiIsolateMicros=0` for every active-motion crossing.
This is a source-level critical-path closure only: no device is connected, so
G2 remains `PARTIAL` pending the required visible time-vs-Avatar fling matrix.

## Continued G2 revision-boundary evidence (Fluvi Logs r56)

The newest Drive revision is **56** (2026-08-29 21:16 UTC); it supersedes the
previous r54 reference. It contains an `INDEX_SCENE_WINDOW_PREPARE_FAILED`
with `Prepared index has no catalog for ...categories:utilities...` after
`FOCUS_INVALIDATED reason=coreRevisionChanged`.

The new real-controller regression
`RG-G2: a new base revision cannot request a focused catalog from the retired
ephemeral index` first failed on the prior current source with exactly that
error and `published=false`. The cause was proven: `installPreparedIndex`
cleared an obsolete ephemeral focus but still derived its next scene bank from
the old focused `navigation.state`.

The repair derives a base-query `DashboardNavigationState` through the
existing `DashboardNavigationController.appliedQueryCandidate` owner, prepares
that bank before publication, then commits the same base query through
`replaceAppliedQuery` at the existing atomic publication boundary. It creates
no second navigation or Query state. The regression now asserts successful
publication, no catalog-preparation error, cleared focus/category filter, and
the new visible revision. The combined current ephemeral-focus and
scene-window-rotation suites passed **58 tests**; the full Core Query
application suite passed **52 tests**; the G1/G2/G3 affected suite passed
**96 tests**; the full current CoreDashboard parent suite passed **24 tests**;
the latest six-file combined regression run passed **172 tests**; focused
analyzer passed.

This closes this specific r56 source path only. G2 remains `PARTIAL` until the
required physical Avatar motion matrix proves smoothness and the absence of
crossing-scaled work on a device.

## Continued G2 Card2 scheduling and physical-trace evidence

The current G2 source audit found a concrete second scheduling defect in
`DashboardBudgetDistributionDrawableController`: optional Card2 sibling
warming used bare `Future.delayed(Duration.zero)` calls. A real Avatar Card1
fling could therefore leave a fake-async Timer alive after the Card2 owner was
disposed; `core_dashboard_mode_navigation_test` reproduced the pending timer
from `_warmHotsetForScopes`.

The Card2 owner now consumes the existing
`DashboardSpeculativeWorkScheduler` rather than owning a second event-turn
mechanism. It has one cancellable idle grant at a time, revokes it on direct
foreground publication, category invalidation, or dispose, and requires a
fresh grant before each additional optional sibling. Two deterministic
regressions verify revocation on foreground promotion and disposal. The
previous rail-density trace failure was also proven to be a test-input error:
its carousel center was y=721 outside an 800×600 root. Restoring its real
800×900 physical surface causes the actual fling lifecycle to run; the full
30× Month/Year, empty/populated/mixed, dense, and reverse matrix passes.

This eliminates a source-level timer/queue owner and restores a valid physical
widget stress harness. It is not a device-FPS result, so G2 remains `PARTIAL`.
