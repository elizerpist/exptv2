# Avatar fling frame-pacing — acceptance checklist

Authoritative inputs: the user task **FLUVI — AVATAR FLING FRAME-PACING
FORENSICS AND MINIMAL PROVEN SMOOTHNESS REPAIR**,
`docs/FLUVI_ENGINEERING_JOURNAL.md`, `MILESTONE_COMMITS.md`, and the frozen
Drive export from `Fluvi logs avatar fling`
(`1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`).

Runtime comparison rule: application behaviour is evaluated from the tree at
`92222edddeee5bb13792f62f939eedf81c867a52`; its application parent is
`a658c08cee7207b1b1b22d0494f21e56b4e20a64`. The current branch head
`5b1fe5067c8c3f2b14f7eb6398811566b25dbaef` adds only the prompt-writer
journal. It is retained in ancestry but is never described as physically
tested application code or a performance baseline.

| ID | Source | Intended owner/area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AFP-01 | Task §§2–3 | Git provenance | Runtime baseline is 92222edd; journal descendants are verified docs-only; protected physical floor remains 6e962187. | fetch, ancestry, `git diff --name-only`, log graph | DONE |
| AFP-02 | Task §5 | Drive evidence | Full current Avatar document is frozen/audited with metadata, byte/hash, tail union, duplicate and gap audit; USER_MARK is not mechanism proof. | Drive export, SHA-256, sequence audit | DONE |
| AFP-03 | Task §§6–8 | Existing Core/cache/rail source | Relevant commits, matching SCIP 3f1a2bda, owners, production/test consumers and first-order impact are independently audited before shared edits. | `git show`, manifest, graph queries, source read | DONE |
| AFP-04 | Task §§10,12–13 | Existing production-parent profile/test path | A real CoreDashboard Avatar workload covers nine non-empty targets, cold/warm/mixed, 20 forward/reverse flings, drag-to-ballistic and supersession without bypassing the real cache/publication lane. | New/strengthened profile + real-component test | PARTIAL — strengthened source and local real-component evidence exist; Android profile evidence is pending. |
| AFP-05 | Task §§9–10 | `DashboardLogBoxPreparedSceneCache.prepareWindow` | Bounded diagnostics correlate target, focus generation, epoch, resource key/owner/currentness, exact row-discovery unit, publication and FrameTiming interval; they introduce no owner or scheduling path. | RED diagnostic assertion and trace inspection | PARTIAL — bounded exact-resource/candidate records are green; Android FrameTiming correlation is pending. |
| AFP-06 | Task §§10,13 | Same production composition | The first >1 ms contiguous operation is causally isolated; the deterministic regression is RED on 92222edd runtime behaviour for that operation, not an arbitrary synthetic timing ceiling. | Captured RED output and source-to-trace mapping | NOT DONE |
| AFP-07 | Task §§11,14 | Proven existing owner only | The smallest repair restores the established <=1 ms contiguous UI-slice contract without dropping targets/publications or changing physics. | RED→GREEN focused test and diff review | NOT DONE |
| AFP-08 | Task §§11–15 | Avatar correctness/pacing owners | Latest-wins, stale rejection, exact final target, painted equality, no pending settle, one rail/controller/position/physics, and zero tick repository/index/scene/canonical work remain true. | Protected tests and profile evidence | NOT DONE |
| AFP-09 | Task §15 | Same-workload evidence | Same-environment cold and mixed distributions have no >1 ms contiguous slice and materially improve: at least 30% fewer missed frames on the representative cold/mixed workload, with no causal P95 regression. | Before/after profile report | NOT DONE |
| AFP-10 | Task §§16–19 | CI/delivery/tooling | Focused and protected suites, fast suite, analyzer, CI, strengthened A–K evidence, final human APK and exact-SHA SCIP graph all identify the final application SHA. | Command transcripts, Actions/artifacts, APK hash, manifest | NOT DONE |
| AFP-11 | Task §§4,20–21 | Human validation | No automated evidence is called physical acceptance; final handoff names exactly one APK to test. | Final report | NOT DONE |

## Architecture card

- **Single selection/write path:** `BudgetTargetAvatarRail` collects physical
  input and forwards it through `DashboardBudgetLogboxDrilldownCoordinator` to
  `DashboardCoreController`, then existing
  `DashboardBudgetPresentationController` and `DashboardVisibleFrameStore`.
- **Single preparation owner:** `DashboardLogBoxPreparedSceneCache.prepareWindow`
  owns staged immutable scenes, row/text layout leasing, cancellation and the
  contiguous UI-slice/yield policy. `DashboardCoreController` only selects the
  existing `budgetAvatarPreview` live-interaction resource lane.
- **UI boundary:** the rail remains input/rendering only. It must not own a
  cache, persistence, multi-step preparation workflow, a second controller,
  or a second frame-timing authority.
- **Reuse decision:** all candidates already flow through the shared cache and
  its `checkpoint` policy. This task extends that owner only; it must not copy
  a cache/yield loop into Avatar UI or Core.
- **Boundary evidence:** existing avatar-core, prepared-scene-cache, rail and
  profile tests enforce the one controller/position/physics and direct
  production cache path. The new regression will assert no new owner and no
  per-tick data/canonical work.

## Explicit gates

1. **Forensic gate:** instrumentation and workload fidelity only. No
   optimisation is permitted until a first inner work unit is correlated with
   a reproducible >1 ms slice.
2. **Causal/RED gate:** a production-parent test must fail because that exact
   unit violates the existing `maxContiguousUiSliceMicros == 1000` contract.
3. **Repair/GREEN gate:** one minimal change in the already-proven owner turns
   that exact test green while all correctness and identity checks remain
   green.
4. **Delivery gate:** same-workload before/after evidence, CI, normal human
   APK and matching SCIP must all refer to the final application SHA. Device
   acceptance remains user-only.
