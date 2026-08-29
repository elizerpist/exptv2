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
  device capture to identify the actual gray-pixel owner.
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
| G2 | A rail hotset request made before bootstrap was silently lost because there was no index yet. Core now retains the bounded semantic horizon and primes it at canonical index publication/idle. The pre-bootstrap red test and the 22-test focus suite are green. | Measured time-vs-Avatar delta and repeated/reverse physical fling with no visible semantic-tick hitch. | PARTIAL |
| G3 | Summary raw pointer-down preempts the time motion lane and pending neighbour work before gesture resolution. The real Summary-after-live-time-ballistic test is green. | Device pointer-down-to-action timing while active and immediately after a time fling; exact remaining lock owner if any. | PARTIAL |
| G4 | The screenshot proves the slab. Isolated Card2/Rhythm raster coverage is green, but it does not include the real Dashboard, LogBox, collapse-handle and composition stack. | Identify the actual intermediate gray-pixel RenderObject/layer; then prove Split and Unified slow/fast/reverse/interrupted collapse without the slab. | NOT DONE |
| G5 | The canonical applied-query facet loader gives Mind and Query Menu the same `CurrentQueryController` domain owner. Ready/loading/latest-wins and two-endpoint tests are green. | Device parity: two visible draggable endpoints and matching values after navigation/change in both hosts. | PARTIAL |
| G6 | Unified now has only `budget-unified-content-card-surface`; `BudgetDistributionCardShell` becomes content clipping only. The topology/controller-identity tests are green. | Device Split → Unified → Split verification with selected Avatar/page retained and no nested physical card. | PARTIAL |
| G7 | The resolved plot target is 48.4dp and compact floor 38.72dp; conservation and Card2/Rhythm tests are green. | Device inspection at reference Split/Unified geometries: outer Card2 unchanged and upper Partner space reclaimed. | PARTIAL |
| P1 | No palette/render-engine source was altered in this pass. The category-scale, palette transport, visual engine, fragment-backend, and renderer-contract suite passed 88 tests. | Verify representative category transitions on device. | PARTIAL |

## Current automated verification (not physical closure)

The following targeted suites were re-run after the current source changes:

- diagnostics, debug-panel, applied-facet loader, amount-range/control/query
  sheet, Core ephemeral-focus, Budget presentation, and complete CoreDashboard:
  **99 tests passed**;
- Avatar rail/quick-edit plus the protected Header palette/visual/backend/
  renderer suites: **134 tests passed**;
- Budget core surface, pager, Partner distribution, and Rhythm geometry:
  **29 tests passed**.
- Directional applied-Query retention, facet-loader latest-wins behavior, and
  both shared amount-range hosts: **15 tests passed**.

`flutter analyze` over the 11 affected production files reported no issues and
`git diff --check` passed. The former failed run that named obsolete test paths
did not execute a failing test; it was re-run with the repository's actual
paths above. None of these automated results changes a physical gate to
`DONE`.
