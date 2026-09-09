# Avatar-only target liveness — acceptance checklist

Authoritative source: [user prompt](../evidence/2026-09-09-avatar-target-liveness/user-prompt.txt), current user scope lock, and frozen evidence in that directory. All numbered DoD items map below. Historical temporal prompt in /storage/emulated/0/Download/fluvi/diag/Fluvi_temporal_desync_performance_milestone_diagnosis_and_prompt (1) (1).md is read-only historical context, superseded by current Avatar-only instruction.

AA61242 AVATAR CORRECTNESS — PHYSICALLY REJECTED BASELINE

AA61242 / E8 AVATAR MOTION — PRESERVE EXACTLY

TIME PRODUCTION SOURCE — NO TOUCH

NEW AVATAR CANDIDATE — PHYSICAL VALIDATION PENDING, USER ONLY

| ID | Source | Code area | Acceptance | Verification | Status |
|---|---|---|---|---|---|
| AVL-01 Exact source/evidence | §§2–5,13.1–5 | docs/superpowers/evidence | aa61242 base, c8 graph, exact immutable export, full lineage and rejection recorded | Git + decoded raw hash + input audit | DONE |
| AVL-02 Nine non-empty targets from startup | §10.1; DoD1,2 | test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart | Persistent production CoreDashboard, real rail/Core/cache/binder, disjoint category rows, non-empty aggregate; sequence 3→2→1→0→8→7→6 | Deterministic red/green composition trace | DONE |
| AVL-03 Twenty persistent cycles | §10.2; DoD8 | same composition test | At least 20 complete forward/reverse nine-target cycles without recreating owners | Stress with per-final-target assertions | DONE |
| AVL-04 Empty/non-empty control | §10.3; DoD5 | same composition test | Sparse fixture cannot pass solely from empty targets | Separate non-empty requested/accepted/painted counts | DONE |
| AVL-05 Typed rejection reasons | §§8,10.4 | Core Avatar resource-window diagnostics | pending plan, empty keys, missing entry, aggregate failure, scope/base/identity mismatch, stale foreground distinguished; bounded metadata no rows | One deterministic branch test each | DONE |
| AVL-06 Target-local resource liveness | §9.1; DoD2–4 | Core Avatar candidate + existing budgetAvatarPreview lane | Exact already-derived payload schedules bounded preparation independent of broad hotset, retains old visual; completion binds/publishes original order once | Real-cache starvation red/green, preparation/binder trace | DONE |
| AVL-07 Terminal request classification | §9.2; DoD3,4,19 | Core candidate / Avatar acknowledgement seams | Exactly one permitted terminal per request; pending has real work; no generic coordinatorRejected/unknown terminal | Completion/coalescing/cancel/disposal/failure tests | DONE |
| AVL-08 Final physical authority | §§9.3,10.5; DoD9,17 | Avatar settle + Core deferred install | Earlier painted1/final8 pending resolves to8 without extra gesture; foreground priority, no earlier canonical final | Physical rail final8 race | DONE |
| AVL-09 Aggregate0 | §10.6; DoD6 | Core clear Avatar focus | Non-empty aggregate clears category and paints/canonicalizes base | Composition handle0 | DONE |
| AVL-10 Endpoints7/8 | §10.7; DoD7 | Core category focus | Both non-empty disjoint endpoints bind/paint/settle | Composition handles7/8 | DONE |
| AVL-11 Stale canonical install | §10.8; DoD16 | Core deferred focus installation | Older delayed install never replaces newer visible or canonical target | Controlled completion race | DONE |
| AVL-12 Pointer supersede | §10.9 | Core latest candidate/order | Old resource completion cannot mutate newer target; bounded owner; terminal once | Held cache completion + new crossing/pointer | DONE |
| AVL-13 Actual surface identity | §10.10; DoD9–15 | Header/progress/LogBox existing paint acknowledgements | Physical/desired/accepted/painted/Budget/focus/visible/canonical identities and values equal at final paint | Actual render probes, not model-only | DONE |
| AVL-14 No Time-reset dependency | §10.11; DoD1,18 | composition tests only | Startup/full cycles have no Time input; one negative-control Time gesture does not rescue correctness | Paired control | DONE |
| AVL-15 Bounded memory/owners | §10.12; DoD24,25 | Core hotset/cache/diagnostics | Bounded plans/candidates/indexes/banks/scenes/listeners/diagnostics after20cycles; no new authorities | Runtime cache/scene/query/ring bounds + static finite index/listener ownership audit | DONE |
| AVL-16 Hardened K | §11.3; DoD19–21 | integration_test/dashboard_interaction_profile_test.dart; test_driver; profile validator | All requested final identity/non-empty/pending/rejection fields; repeated flings; false-green artifact rejected | Validator negative fixtures + actual exact-SHA CI JSON | PARTIAL |
| AVL-17 Protected motion | §12; DoD22 | Avatar/shared carousel existing implementation | Physics, extent, spacing, thresholds, controller/position ownership unchanged; motion not smooth-through-zero-data | No-touch source/boundary diff + production counters/profile | PARTIAL |
| AVL-18 Protected other systems | §§1,12; DoD23 | Time/Mind/Slider/layout/design/finance/DB | No production changes in protected systems, no cache capacity increase/timers/polling/new cache/store/controller | Boundary hashes and diff review | DONE |
| AVL-19 Automated gates | §15; DoD26 | test + analysis + CI | Focused/application/fast/presentation/analyzer/format pass or exact inherited19 failures identified, no new regressions | Recorded exact commands and outputs | PARTIAL |
| AVL-20 APK/SCIP delivery | §§13,14; DoD27 | GitHub Actions + tooling branch | App branch pushed, normal human APK downloaded+hashed, exact-SHA SCIP regenerated twice+tested+pushed | SHA equality and local artifact verification | NOT DONE |
| AVL-21 Physical verdict | §16; DoD28 | follow-up forensic report | Baseline physically rejected; new candidate pending USER ONLY; no physical success claim | Honest checklist and final report | DONE |


## Verification progress

All local implementation requirements are verified. See [final local validation](../evidence/2026-09-09-avatar-target-liveness/local-validation-final.md) for commands, counts, evidence limits, source hashes and exact baseline comparisons. The full final composition passes all eight scenarios, including the last added retention assertions. The application suite passes311; fast passes369; full presentation passes605 with19 exactly inherited failures; full boundary passes25 with one separately reproduced inherited source-regex failure. Analyzer and format are clean. No new regression, golden update or protected production edit exists.

The [composition report](../evidence/2026-09-09-avatar-target-liveness/composition-task-report.md) records genuine baseline starvation/final8 mismatch reds and actual Header/progress/LogBox green evidence. The [owner audit](../evidence/2026-09-09-avatar-target-liveness/owner-bound-audit.md) distinguishes measured resource counts from static bounded focus-index/listener ownership, without claiming a heap census.

AVL-16 remains PARTIAL until actual exact-SHA Android K JSON is inspected. AVL-17 has completed no-touch source/controller/physics and composition evidence; the online motion profile remains pending. AVL-19 has completed local gates with exact inherited failure parity; CI remains pending. AVL-20 remains NOT DONE until normal human APK download/hash and deterministic exact-SHA graph push are complete. The final immutable delivery record will close these rows against this application commit.

Physical acceptance is explicitly reserved to the user by §16; AVL-21 DONE means the pending status is preserved, not that the candidate was physically accepted.
