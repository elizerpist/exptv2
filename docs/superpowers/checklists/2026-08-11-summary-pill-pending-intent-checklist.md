# Summary Pill pending structural intent checklist

## Architecture card

- **Scope/source:** device lifecycle evidence and the 2026-08-11 Summary Pill
  regression specification. This is a dashboard coordinator correctness fix;
  it deliberately excludes direction-twin scene construction, LogBox painting,
  vertical paging, SQL/query semantics, and rail physics.
- **Existing owner/write path:** `DashboardCoreController` owns the required
  scene coverage demand, pending scene-covered navigation, scene-rebase
  generation, and immutable-index installation. `DashboardPresentationController`
  owns candidate/commit presentation state. No widget owns this workflow.
- **Shared mechanism:** extend the existing scene-window coordinator; do not
  create a second settle, retry, or scene preparation scheduler.
- **State boundary:** pending structural intent and committed maintenance are
  controller-local transient state. The exact `coreRevision + indexGeneration`
  scene identity is the invalidation boundary.
- **Verification:** focused controller/scene-window regressions, existing
  dashboard correctness suite, Proot analysis, GitHub human APK build and
  SHA-verified delivery.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SPI-01 | User §§3–9, 18 | `DashboardCoreController` scene-demand coordinator | An old committed SUM settle cannot replace an unresolved pending YEAR structural demand. | RED/GREEN SUM→YEAR old-settle race test | DONE |
| SPI-02 | User §§10–13, 19–20 | pending navigation/rebase lifecycle | Repeated identical structural intents join one transition and never cancel/restart its own preparation; a genuinely new target supersedes it. | Coalescing, old-settle-plus-repeat and existing different-target tests | DONE |
| SPI-03 | User §§14–17, 21–22 | prepared-index installation/rebase guards | Replacing immutable index generation invalidates pending navigation, required demand, queued and in-flight old-index work immediately. | Same-core-revision index replacement and real `applyQuery()` supersession regressions | DONE |
| SPI-04 | User §24–25, §29 | structural navigation coordinator | Visible rail child retention and SUM→YEAR→MONTH→SUM semantics remain intact while the pending candidate commits exactly once after its bank activates. | Focused race, presentation, continuity and query-apply tests | DONE |
| SPI-05 | User §1, §27 | protected dashboard systems | Direction-twin scene bank, painter invalidation, paging, query SQL, ScrollPosition ownership and rail physics remain unchanged. | Focused diff inspection complete; full fast suite pending CI | PARTIAL |
| SPI-06 | Global delivery rule | branch/CI/APK | Changes are committed, pushed, GitHub build is monitored, and the normal human APK is SHA-verified in `/storage/emulated/0/Download/fluvi`. | Git/GHA/artifact SHA evidence | NOT DONE |
