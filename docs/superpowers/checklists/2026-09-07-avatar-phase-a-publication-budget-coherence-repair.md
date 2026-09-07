# Avatar Phase-A publication and Budget coherence — acceptance checklist

Status key: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

| ID | Source | Intended ownership/code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AVP-01 | Current Avatar evidence, seq 1913–2614 | `DashboardCoreController` Avatar preview path | 43-request/reject current behavior has a deterministic production-parent red regression. | Actual cache/binder attached; unmodified 5ba failed `Expected false, Actual true`; repaired replay regression is green. | DONE |
| AVP-02 | Current source + aa26 intent | `_bindBudgetAvatarLivePhaseA` | Exact painter readiness is evaluated from the active `budgetAvatarPreview` cache authority, not an unrelated complete hotset flag. | Warm exact-target / incomplete-hotset regression. | DONE |
| AVP-03 | Current Avatar evidence | `DashboardCoreController` pending candidate owner | A cold non-empty candidate is retained once, latest-wins, and is replayed when the existing resource completion resolves; a later cross-producer owner terminally stales it. | Cold first-drag, latest-wins, cross-producer Mind-owner, stale-completion and aggregate supersession tests. | DONE |
| AVP-04 | User no-heavy-work contract | Existing resource lane/cache | Cold replay introduces no extra cache/store/controller, DB/index/query commit/rich projection/TextPainter work at a semantic crossing. | Source inspection and focused counters pass; physical FrameTiming follow-up remains required. | PARTIAL |
| AVP-05 | Current Avatar evidence | Visible frame / focus / live interaction transaction | A target that remains current through a render opportunity atomically drives Avatar, Header, Summary, LogBox, count, extent, and paint identity. | Persistent real Core/cache/store/Budget presentation coherence regression. | DONE |
| AVP-06 | User requirement | Aggregate and exact-empty Avatar branches | Target 0 and exact-empty category are accepted, coherent, and use transparent zero-row output rather than a resource failure. | Aggregate supersession and exact-empty zero-row regressions. | DONE |
| AVP-07 | Current Budget evidence, seq 8760–9758 | Budget quick-edit boundary | A long press cannot edit/persist a target different from the visually selected target. | Mismatch fail-closed and selected-target edit widget tests. | DONE |
| AVP-08 | Current Budget evidence | Existing selected chrome | A positive-limit selected target renders the existing ring using its same target identity; no forced visible state or geometry redesign. | Ring widget/painter and post-persistence tests. | DONE |
| AVP-09 | User no-touch contract | Time / Mind / Slider | Time and Mind/Slider production files have no diff and their existing tests remain green. | `git diff --name-only`, protected focused tests. | DONE |
| AVP-10 | Performance acceptance | Avatar production parent | Frame timing is remeasured only after real accepted publications return; smooth-with-zero-data fails. | Profile diagnostics / physical follow-up. | NOT DONE |
| AVP-11 | Delivery contract | GitHub / APK / SCIP | Validated app commits are pushed; human APK and exact-SHA SCIP artifacts are delivered. | GitHub Actions, download/hash, tooling validation. | NOT DONE |

The reviewed references for this change are the frozen evidence manifest at
`docs/superpowers/evidence/2026-09-07-avatar-phase-a-publication-budget-coherence-session-fluvi-1788752412870045/manifest.json`, the matching current source, and the current test suite. No screenshot/design change is authorized; the existing Budget ring geometry and dashboard layout are protected.
