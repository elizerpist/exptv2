# Performance milestone + final two-blocker forensic pass — acceptance checklist

**Authoritative source:** user direction dated 2026-08-30, current local
source, Android screenshots in `/storage/emulated/0/Pictures/Screenshots`, and
Google Drive **Fluvi Logs** revision 56. This checklist is a scoped follow-up
to `2026-08-30-forensic-stabilization.md`; it does not convert earlier
automated-only physical rows to `DONE`.

| ID | Requirement source | Intended owner / code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PM-01 | User: accepted physical performance must be checkpointed first | Git history and `MILESTONE_COMMITS.md` | The accepted interaction state has an immutable source checkpoint, exact SHA, rollback anchor, known-open defects, and no experimental repair in that commit. | Preflight records, focused regression run, commit/readback. | DONE |
| PM-02 | User: retain current 2,000-line diagnostic capacity, stop frame-level noise | `FluviDiagnosticLogger`, Header visual engine, diagnostics tests | Header fidelity/touch facts are recorded only on session/backend/error or sparse collapse milestones; one reproduction preserves both new collapse and Mind causal chains without altering performance. | Red-to-green sparse-emission unit/widget tests, logger FIFO tests, source review, device dump. | PARTIAL |
| CS-01 | Current screenshot/log: gray slab during collapse/expand | Full Budget core composition: cascade, unified/split shell, page viewport, Partner upper, Rhythm footer, collapse handle and LogBox boundary | A real intermediate-collapse capture identifies the exact RenderObject/layer that owns the slab's pixels, including bounds, fill, clip, opacity, transform and z-order. | Production-parent intermediate geometry test plus temporary debug-only owner probe and device slow/fast/reverse capture. | PARTIAL |
| CS-02 | User: no cosmetic sixth attempt | The proven CS-01 owner only | The structural owner is repaired; upper Partner remains intact for the proven reason; no mask, fade-out, screenshot dimensions, broad shadow removal, or arbitrary clip is used. | Regression fails before repair, passes after; physical complete collapse/expand matrix in Split and Unified layouts. | NOT DONE |
| MR-01 | Current screenshot: Mind remains at `Az összeg tartomány betöltése folyamatban` | `DashboardAppliedQueryFacetLoader` → `CurrentQueryController` → Core host → Mind binding → `QueryAmountRangeControl` | The full request → result/rejection → canonical publication → render gate → mount/layout/visible chain is observable for the active exact scope/generation. | Red-to-green lifecycle diagnostics tests, cold/warm/replacement navigation tests, device capture. | PARTIAL |
| MR-02 | User: no fabricated slider or stale fallback | Canonical Query amount-domain owner and shared control | No indefinite false loading after a request completes or fails; the shared control is visible only when canonical state says it is ready, with explicit error/loading semantics otherwise. | Failure-path and ready-path tests; physical cold/warm/rapid re-entry verification. | PARTIAL |
| PR-01 | User: performance remains gold baseline | Existing rail, time, collapse, mode-navigation and logging hot paths | Both repairs preserve direct-input/animation behavior; diagnostics allocate/format only at bounded semantic events. | Existing input-fair suites, analyzer, evidence counters, user physical regression matrix. | NOT DONE |
| RB-01 | Prior accepted category Header behavior | Header palette/fragment material identities | No palette/ticker/backend semantic change. | Existing header source/test review and physical category sampling. | NOT DONE |

**Hard release rule:** Android build, push-triggered APK artifact, and APK
download are prohibited while any row other than PM-01 is `NOT DONE`,
`PARTIAL`, or `BLOCKED`. No automated result alone promotes CS-02, MR-02, or
PR-01 to `DONE`; their required device evidence is explicit above.

## Evidence known before edits after the milestone

- Fluvi Logs revision 56 remains the newest Drive revision at this pass's
  preflight. It carries 18 `HEADER_RENDER_FIDELITY_CONFIG` and 18
  `HEADER_TOUCH_RENDER_PATH_BOUND` records over the collapse movement. The
  observed physical height changes, while each reported path has
  `usesSaveLayer=false` and `usesOffscreenIntermediate=false`.
- That log contains no `MIND|...` events, so it cannot identify the Mind
  lifecycle failure stage and does not prove a slider repair.
- The current source signature for both Header events includes logical and
  physical size, so it changes at virtually every collapse frame. This is a
  proven diagnostic-noise source, not evidence that Header owns the slab.
- The latest local screenshots were inspected directly. They show the accepted
  Budget presentation/Rhythm settled state; no settled screenshot is used as
  evidence against the intermediate-only gray slab.

## Evidence after diagnostic hardening (automated only; no physical closure)

- PM-02 red-to-green evidence: a controlled sequence of six Header size-only
  collapse frames produced six `HEADER_RENDER_FIDELITY_CONFIG` records before
  the signature change and one after it. The binding now keys only renderer
  contract facts; Header bounds remain available through sparse
  `COLLAPSE|GEOMETRY` records.
- The existing `FluviDiagnosticLogger` FIFO/export tests still prove the exact
  1,999 / 2,000 / 2,001 behavior. The capacity remains exactly 2,000.
- CS-01 now has a debug-only, post-layout probe for the real full composition:
  cascade card, physical/viewport shell, page content, Partner Rhythm footer,
  Rhythm chart, unified surface, LogBox viewport and collapse handle. It
  records existing render-object global bounds, paint bounds, declared
  material/clip/z-order and ancestry only at semantic collapse buckets. It
  neither paints nor clips nor changes hit testing.
- The real Partner/Rhythm collapse widget composition passed its intermediate
  split/unified/order proxy after proving all five probe candidates are present.
  This is **not** physical pixel-owner proof: a slow/fast/reverse device
  capture from this source revision is still required before CS-01 can be
  marked `DONE` or any visual repair can be made.

## Mind lifecycle evidence after instrumentation (automated only; no physical closure)

- MR-01 red-to-green test recorded a missing lifecycle before the change: the
  loader emitted only `MIND_SLIDER_DOMAIN_REQUESTED`, not a reconstructable
  request-to-publication chain. It now records bounded
  `MIND|RANGE_REQUIRED`, cache hit/miss, request/join, result, reject with an
  exact reason, publication and state records keyed by the canonical scope and
  request generation.
- The same production Mind host now records `MIND|SLIDER_MOUNT`,
  `MIND|SLIDER_LAYOUT`, and `MIND|SLIDER_VISIBLE` only after the shared
  `QueryAmountRangeControl` has really been laid out. The Core render gate
  carries the corresponding canonical scope/query generation and exact reason
  when it is unavailable.
- A source-proven false-loading path was repaired: a completed facet request
  error previously changed the loader out of loading internally but left Mind
  subscribed only to `CurrentQueryController`, so its visible text remained
  `betöltése folyamatban`. Mind now observes the loader's transport state and
  renders an explicit, direct user retry state; no range value or slider is
  fabricated. The retry repeats the same canonical scope request.
- These results do **not** identify why the physical Android request stayed
  pending/failed in the user's screenshot. No device is attached to this
  workspace, and Drive revision 56 contains no Mind lifecycle events. MR-01
  and MR-02 remain `PARTIAL` until a physical cold/warm/re-entry capture from
  this source revision proves the actual terminal path and visible control.

## Verification note: inherited full-dashboard suite failure

- The current-repository equivalent of the requested missing `test/homev2`
  path is `flutter test test/features/dashboard --reporter expanded`.
  That broad run reached
  `dashboard_logbox_stable_render_surface_test.dart` and failed at its
  pre-existing `find.byType(Scrollable)` single-element assumption with
  `Bad state: Too many elements`.
- The exact focused test was then run in a temporary clean worktree at the
  initial local SHA `a2bfe74604c96ce5505347ab16f2e15aa044f189`; it failed at
  the identical file, line 87, and error. It is therefore inherited rather
  than silently attributed to the post-checkpoint changes. The interrupted
  broad run also emitted shutdown stream errors after the first failure; those
  are not counted as independent product failures.
