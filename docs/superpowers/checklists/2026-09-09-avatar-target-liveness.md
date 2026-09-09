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
| AVL-16 Hardened K | §11.3; DoD19–21 | integration_test/dashboard_interaction_profile_test.dart; test_driver; profile validator | All requested final identity/non-empty/pending/rejection fields; repeated flings; false-green artifact rejected | Validator negatives + actual a047 K four-flight JSON independently validated; broader suite tracked separately in16b | DONE |
| AVL-16a Exact renderer evidence | §§9,11.3; actual CI34348237362 K timeout | existing profile collector/validator/tests | Both actual readable Phase A and actual rich Phase B paint are valid nonempty exact paint; zero-row/empty/stale/mismatched paint still fails. Export raw final counts and revisions. | Genuine rich-only red/green; a047 actual final Phase A0/Rich B2,3,2,3, exact-emptyfalse, revisions2=2; negative gates retained | DONE |
| AVL-16b Complete profile handoff | §§11.3,15,DoD19,26; actual CI34351134148 false success after suite timeout | existing report owner, integration collector, host profile driver, profile script/tests | A partial/timed-out suite cannot return successful host delivery. Persist partial diagnostics, then require complete A–K reports and an explicit completion marker written only after all suite assertions. Keep per-flight/identity/performance gates unchanged; use a finite suite budget justified by actual completed scenario durations. | Actual incomplete-artifact red/rejection,96 focused tests, driver/marker/budget boundary passed; exact next-SHA complete suite JSON/log pending | PARTIAL |
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

## First exact-SHA CI follow-up

App174ad841 passes online analyzer/fast369/native tests and builds/downloads its normal human APK. K fails its first final target: physical/desired/semantic/painted/selected/focus/Header/progress/LogBox/canonical identities all3, matching category/query/value fields,8 requests=8 accepted nonempty terminals, pending0. Only final_target_exact_painted is false. The unchanged actual artifact is retained. The collector uses hasReadablePhaseAPaint and excludes the DTO's separate hasRichPhaseBPaint at three sites. The old artifact lacks the final raw Phase A/B counters and revision pair, so rich-only paint is a source-supported diagnosis to prove by controlled regression and the next raw CI evidence, not an invented recovered log field. AVL-16 remains PARTIAL and new16a must be verified before final delivery.

The measured-paint predicate now has a genuine controlled red and62 focused green tests. The existing report owner handles both actual render phases through one pure predicate, and raw final empty/count/revision fields are mandatory. Overall renderer metrics and legacy Phase A metrics remain distinct. See [profile correction report](../evidence/2026-09-09-avatar-target-liveness/profile-rich-renderer-task-report.md). No production source changed after174ad841. Actual new-SHA CI/K evidence is still required; no earlier failed JSON was rewritten or accepted.

## Actual a047 K and whole-suite timeout

The next run34351134148 validates AVL16/16a with real four-flight K evidence. Final handles3,0,3,0 have matching actual Header/progress/LogBox/canonical identities and values,8/8 accepted nonempty terminals each, pending0, no Time input, raw rich rows2,3,2,3 and matching revision2. See `ci-a047e216-root-K-verification.json` and the unchanged raw JSON. The broader suite times out later during J, but the SDK driver incorrectly exits successfully; its green workflow is rejected as full-suite proof. AVL16b remains NOT DONE until a fail-closed complete-suite contract and an actual complete next-SHA run are verified. Delivery and online motion/comparison gates remain pending. Earlier pending statements above are historical milestones.

The complete-suite guard now has a genuine actual-artifact red, rejects that unchanged missing-J response, and passes96 focused tests, including the retained renderer/identity/motion negative cases. The driver persists raw data before the shared guard; the collector writes completion only after every existing assertion. Test35m, SDK38m, shell40m+30s and workflow60m preserve finite ordered margins without changing performance or flight thresholds. AVL16b is PARTIAL pending actual complete next-SHA CI. See `profile-suite-completion-task-report.md` for SDK source references, exact commands and evidence.
