# Performance milestone + final two-blocker forensic pass — acceptance checklist

**Authoritative source:** user direction dated 2026-08-30, current local
source, Android screenshots in `/storage/emulated/0/Pictures/Screenshots`, and
Google Drive **Fluvi Logs** revision 56. This checklist is a scoped follow-up
to `2026-08-30-forensic-stabilization.md`; it does not convert earlier
automated-only physical rows to `DONE`.

| ID | Requirement source | Intended owner / code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PM-01 | User: accepted physical performance must be checkpointed first | Git history and `MILESTONE_COMMITS.md` | The accepted interaction state has an immutable source checkpoint, exact SHA, rollback anchor, known-open defects, and no experimental repair in that commit. | Preflight records, focused regression run, commit/readback. | DONE |
| PM-02 | User: retain current 2,000-line diagnostic capacity, stop frame-level noise | `FluviDiagnosticLogger`, Header visual engine, diagnostics tests | Header fidelity/touch facts are recorded only on session/backend/error or sparse collapse milestones; one reproduction preserves both new collapse and Mind causal chains without altering performance. | Red-to-green sparse-emission unit/widget tests, logger FIFO tests, source review, device dump. | NOT DONE |
| CS-01 | Current screenshot/log: gray slab during collapse/expand | Full Budget core composition: cascade, unified/split shell, page viewport, Partner upper, Rhythm footer, collapse handle and LogBox boundary | A real intermediate-collapse capture identifies the exact RenderObject/layer that owns the slab's pixels, including bounds, fill, clip, opacity, transform and z-order. | Production-parent intermediate geometry test plus temporary debug-only owner probe and device slow/fast/reverse capture. | NOT DONE |
| CS-02 | User: no cosmetic sixth attempt | The proven CS-01 owner only | The structural owner is repaired; upper Partner remains intact for the proven reason; no mask, fade-out, screenshot dimensions, broad shadow removal, or arbitrary clip is used. | Regression fails before repair, passes after; physical complete collapse/expand matrix in Split and Unified layouts. | NOT DONE |
| MR-01 | Current screenshot: Mind remains at `Az összeg tartomány betöltése folyamatban` | `DashboardAppliedQueryFacetLoader` → `CurrentQueryController` → Core host → Mind binding → `QueryAmountRangeControl` | The full request → result/rejection → canonical publication → render gate → mount/layout/visible chain is observable for the active exact scope/generation. | Red-to-green lifecycle diagnostics tests, cold/warm/replacement navigation tests, device capture. | NOT DONE |
| MR-02 | User: no fabricated slider or stale fallback | Canonical Query amount-domain owner and shared control | No indefinite false loading after a request completes or fails; the shared control is visible only when canonical state says it is ready, with explicit error/loading semantics otherwise. | Failure-path and ready-path tests; physical cold/warm/rapid re-entry verification. | NOT DONE |
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
