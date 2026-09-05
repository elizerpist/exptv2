# Live count / Summary-variant / Avatar repair — acceptance checklist

Source of truth: the user's 2026-09-05 physical-feedback prompt, exact base
`fcc574b6cf2e58a181e0b841d6252a475ca9342c`, and source/log evidence audited
on this branch.  Statuses are deliberately conservative.  A green test or APK
is not physical acceptance.

| ID | Source instruction / evidence | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PREFLIGHT-01 | User §§1–5 | Git lineage, Drive documents, tooling manifest | Exact fcc base/ref, clean starting worktree, full deduplicated Drive audit, matching graph provenance | Recorded command output; document parser; manifest/source check | DONE |
| COUNT-01 | User §6.2, §7; Slider `10906–11906` | `DashboardLogBoxHeader`, `DashboardVisibleFrameStore` count lane | Header immediately displays the accepted exact live total, not `_value` or bounded row count | Red/green focused header + production-parent tests | DONE |
| COUNT-02 | User §7, §12.1 | Header count selector/reconciliation seam | Stale producer/epoch cannot win; cancellation and canonical completion reconcile without zero/stale flicker | Lane ordering and canonical reconciliation tests | DONE |
| COUNT-03 | User §7, §10.4 | Header repaint boundary / viewport | Count changes invalidate only header count presentation; ScrollController, render surface, header geometry and clipping retain identity | Widget identity/performance assertions and source review | DONE |
| VARIANT-01 | User §§6.4–6.7, §8 | `SummaryPillVariantController`, `_DashboardSummaryRegion`, both adapters | Persistent production-parent classic → segmented → classic reproducer reports semantic, bound, layout and painted states with a monotonic transition epoch | Deterministic transition test plus bounded diagnostic assertions | PARTIAL — real segmented→classic active-motion reproducer and bounded transition evidence exist; full physical A→B→A visual sequence remains user validation |
| VARIANT-02 | User §§8, §10.1, §12.3/12.7 | Proven transition owner only | Removed adapter cannot retain motion, ticker/listener, callbacks, input, semantics, paint or geometry authority; incoming adapter projects shared state | Stale-callback, one-active-adapter, semantics and gesture tests | PARTIAL — source-proven stale shared-motion handoff is repaired and epoch-rejected; exhaustive layer/semantics/hit-test cases remain outside automated coverage |
| AVATAR-01 | User §§6.3, §9, §12.4 | Budget presentation, avatar rail/drilldown, LogBox/count binders | Each accepted Avatar target has one target/query/revision/publication identity across header, distribution, count, LogBox rows, chip and actual paint | Production-parent ballistic/settle identity test | PARTIAL — Core-confirmed LogBox paint is correlated into the real rail; the complete multi-surface physical sequence remains pending |
| PAINT-01 | User §6.7, §12.6 | Avatar flight recorder / LogBox paint acknowledgement | Flight summary counts the same Core-confirmed Phase-A/Phase-B render-extent domain that emits target-painted events; unpainted targets are not claimed | Paint-accounting regressions, including unpainted same-target re-entry and retained exact paint | DONE |
| LAYER-01 | User §10, §12.5 | `CoreDashboard` Stack, tuner, geometry resolver | One active Summary surface; tuner/rail no hidden hit test; geometry/bounds/anchors/clip/semantics remain valid in both variants | Real-rectangle, hit-test, semantics and bounds tests | PARTIAL — existing Core/geometry suites pass; no speculative Stack/geometry rewrite and the full requested rectangle matrix is not newly automated |
| PERF-01 | User §§6.8, §11, §12.8 | Existing Time/Avatar/mind performance ownership | Time semantic ticks retain zero query/index/scene/DB/text-layout work and one canonical settle; count does not full-dashboard rebuild | Existing/new structural counter tests | PARTIAL — structural Time/Mind protections remain green and count binding retains viewport/render identity; no device frame-timing claim |
| SCOPE-01 | User §14 | All application changes | No physics, filtering, DB/schema, financial semantics, paging, stable controller, Phase-A/B, or typed publication-order regression | Diff/graph impact review and protected tests | DONE — matching graph neighborhood and CURRENT HEAD consumers reviewed; no protected owner is modified |
| DELIVERY-01 | User §§17–21 and global AGENTS | App branch + GitHub Actions + tooling worktree | Validated atomic app commit is pushed; exact normal human APK is downloaded to `/storage/emulated/0/Download/fluvi` and hashed; separately regenerated graph matches final app SHA or is explicitly stale | Exact commands, action/artifact and manifest records | NOT DONE |
| PHYSICAL-01 | User §§1, 20, 23 | User device | New build has user physical validation | User-only test | PENDING — USER ONLY |

## Required source reuse / non-duplication check

`DashboardVisibleFrameStore.countLane` is the existing shared live-count
engine.  The repair must consume it through a compact selector at the header;
it must not create a second store, counter, query, renderer, cache, or
presentation pipeline.  Summary adapters remain input/presentation adapters
of the existing core/navigation/geometry owners.
