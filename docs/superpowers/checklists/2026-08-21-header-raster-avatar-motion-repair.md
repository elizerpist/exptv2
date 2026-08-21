# Header raster + Avatar motion repair — acceptance checklist

Re-read `docs/dashboard/dashboard-motion-data-root-cause.md`,
`docs/dashboard/dashboard-motion-data-refactor-report.md`,
`MILESTONE_COMMITS.md`, and
`docs/superpowers/specs/2026-08-21-header-raster-avatar-motion-repair.md`
before each task commit.

| ID | Source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HRA-01 | User CRITICAL-log hard gate | current local Fluvi diagnostics | The complete current log is read and each relevant CRITICAL/WARN event has a chronological disposition. | Exact local file and evidence table. | BLOCKED — log absent from accessible workspace/storage. |
| HRA-02 | Current Header painter source + user reproduction | Header visual paint lane | At maximum quality, field output is continuous between samples; no direct rectangular grid remains visible. DPR affects effective sampling identity. | Pure continuity/DPR tests and render-path inspection pass; physical-device visual evidence remains pending. | PARTIAL |
| HRA-03 | User render-cache contract | Header visual renderer | Size, DPR, quality, cadence, effect and source field settings cannot reuse incompatible material state; palette-only changes do not recompute field geometry. | Field-identity/retained-mesh tests pass. The implementation has no offscreen raster cache to reuse. | DONE |
| HRA-04 | Motion root-cause docs + current avatar source | `BudgetTargetAvatarRail` / drilldown handoff | Semantic avatar crossing has no focus derivation, query publication, repository, native bridge, SVG or full-Dashboard work. Live target/Header preview remains. | Crossing/settlement widget test and owner-path inspection pass. | DONE |
| HRA-05 | Motion root-cause docs | display-frame preview owner | Several target crossings in one display frame publish only the latest transient visual target, without an arbitrary timer/debounce or changed physics. | Deterministic scheduler/coalescer tests pass. | DONE |
| HRA-06 | User TimeRail control requirement | shared carousel consumers | TimeRail and avatar retain stable controller, position and physics identities; the shared ballistic engine source has no behavior change. | Existing centered-carousel identity test passes; physics-file diff is empty. | DONE |
| HRA-07 | User diagnostics contract | Header / avatar motion diagnostics | Surface configuration and bounded motion summary diagnostics are semantic and no per-frame logging is introduced. | Code inspection confirms deduplicated surface config and one summary at settle; device diagnostic capture pending. | PARTIAL |
| HRA-08 | Milestone commits + user performance contract | dashboard render/scene owners | No regression to prepared scene, paging, scroll or expansion ownership; Header clock remains a leaf paint source. | Focused header, rail, core-surface and carousel tests pass; full suite/CI still pending. | PARTIAL |
| HRA-09 | User physical-profile requirement | normal `lib/main.dart` APK | CI produces/delivers normal human APK; physical smoothness/profile claims are made only from actual device evidence. | GitHub Actions + downloaded APK hash; manual profile pending. | NOT DONE |
