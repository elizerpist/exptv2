# Avatar target liveness implementation plan

> For agentic workers: use executing-plans inline, task-by-task. User-supplied implementation prompt is the approved specification. Do not switch to SDD just because a plan exists.

Goal: exact bounded latest-target Phase-A completion and atomic final settle, without Time or motion changes.

Architecture: follow ../architecture/2026-09-09-avatar-target-liveness.md and the AVL acceptance checklist. Flutter/Dart production owners remain unchanged; tests run in Ubuntu proot; APK only GitHub Actions.

## Global constraints

Base aa61242c4b933ad9d650361ae1014d67fd184186. TIME PRODUCTION SOURCE — NO TOUCH. Avatar physics/controller/ScrollPosition/extent/threshold/design/layout, Mind/Slider, financial formulas/DB/cache capacities untouched. No polling, timers, duplicate cache/store/controller. Physical validation PENDING — USER ONLY. Every required AVL item must be verified, not inferred from a green build.

## Task 1 — evidence and production reproducer

Files: evidence/2026-09-09-avatar-target-liveness, forensics/2026-09-09-avatar-target-liveness.md, test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart, test/support/avatar_target_liveness_fixture.dart, test/boundary/dashboard_avatar_target_liveness_boundary_test.dart.

- [x] Freeze exact export losslessly as JSON content, verify decoded UTF-8 bytes/hash; inspect all supplied unique documents; duplicate hashes recorded.
- [x] Resolve aa61242 and c8 graph; source-verify coordinator/publication/resource consumer chain.
- [x] Complete lineage/historical evidence audit and record which conclusions are superseded.
- [x] Build one real CoreDashboard fixture using normal runtime repository seam, eight fixed categories with different amounts and non-empty current-day rows, aggregate=sum, exact Budget limit snapshot. Mount once, obtain real rail and viewport cache through widget tree; never replace binder.
- [x] Drive physical rail and assert final selected/focus/visible/paint/canonical target identity within bounded frames. Reproduce sequence 3,2,1,0,8,7,6 and earlier1/final8.
- [x] Add typed window-rejection instrumentation, with bounded digests/counts only. Establish actual red subcause before changing behavior.
- [x] Extend independent boundary suite to protect owners and Time/motion code.

Command prefix for all local Dart/Flutter: proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909 && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --reporter expanded'. Expected baseline failure must be a non-empty binder/liveness assertion, not fixture compilation/layout error.

## Task 2 — exact target completion

Files: Core Avatar candidate/resource methods; focused typed resource-window value/helper if needed; existing cache Avatar lane only if evidence requires.

Consumes already-derived candidate visible payload and original order. Produces one bounded exact preparation completion or explicit terminal; no broad-bank dependency.

- [x] Red: pending-plan/empty-keys/missing-entry/aggregate-StateError/scope mismatch, cold non-empty payload and interrupted stale preparation.
- [x] Retain immutable exact payload in existing candidate; schedule one target-local window through existing shared preparation helper and budgetAvatarPreview lane. Resource identity includes base/scope/payload; old visual remains readable.
- [x] Revalidate candidate/order before promotion, bind exact payload once on completion, terminally reject failed invariant instead of leaving unowned pending. Superseded completion cannot replace latest target.
- [x] Focused green plus all null-branch diagnostics and owner bounds. Do not fix unproven object-identity hypothesis.

## Task 3 — final target / canonical fencing

Files: Core existing deferred install; Avatar rail semantic callbacks only as required.

- [x] Red: accepted1 then pending8 at physical end; old delayed canonical install completed after newer target; new pointer during preparation.
- [x] Fence older deferred canonical install with existing focus generation/order. Final physical target retains foreground exact completion; publish during motion when ready, no settle-only data policy.
- [x] Verify Header/progress/LogBox actual paints, aggregate0/endpoints7/8, and exactly one request terminal.
- [x] Twenty complete forward/reverse cycles on one owner; sparse control; no Time reset; one negative-control Time gesture in test only; bounded retained resources/listeners/diagnostics.

## Task 4 — false-green profile contract

Files: integration_test/dashboard_interaction_profile_test.dart, test_driver/dashboard_profile_driver.dart, scripts/check-dashboard-profile.dart or existing discovered validator owner, focused report tests.

- [x] Red validator tests against supplied K JSON: empty-only, earlier painted/final pending, stale canonical, mismatched Header/progress/LogBox, unresolved candidate.
- [x] Add every field specified in user prompt §11.3 to the existing report owner. Use repeated real flings and non-empty target fixture. Require final identity equality and zero pending, not positive counts alone.
- [ ] Run focused validator/report tests and inspect actual CI JSON.

## Task 5 — verification/delivery

- [x] Re-read prompt/checklist/reference paths; diff protected source and motion ownership.
- [x] Run format/analyze, focused suites, application suite, scripts/test-fluvi-fast.sh, full presentation and boundary suites. Compare exact inherited19 failure names/normalized output; no unrelated golden changes.
- [ ] Review changes, update honest checklist. Atomic commit(s) with Why/Evidence/Changed/Validation/Physical pending bodies; push repair branch.
- [ ] Monitor exact-SHA GitHub Actions, inspect hardened K artifact, download exact normal main.dart human APK into /storage/emulated/0/Download/fluvi, verify bytes and SHA-256.
- [ ] Regenerate matching SCIP in tooling worktree, test and deterministic double generation, commit/push separately; cancel docs-only CI. Final app SHA=APK source SHA=graph source_head.
- [ ] Completion report distinguishes physically rejected baseline, preserved motion code, automated evidence, and new physical candidate pending USER ONLY.

Final local verification: see evidence/2026-09-09-avatar-target-liveness/local-validation-final.md. The only full-suite failures exactly match fresh baseline:19 presentation plus one separately identified boundary regex. App commit/push and exact-SHA CI/K/APK/graph delivery remain in progress.

## Task4 follow-up — exact renderer evidence after actual CI

Profile174ad841 rejects final exact target3 despite complete matching identity/terminal/pending fields. Before behavior change, factor the existing nonempty paint-readability predicate into the existing pure report owner and reproduce its rejection of a valid rich-only paint. Then accept positive actual Phase A or Phase B rows, export the final raw counts/empty/revision evidence, and keep empty/zero-row/stale/identity/terminal gates strict. Update every affected collector use and label phase-specific metrics truthfully. Profile agent owns integration collector/report/tests; root owns forensic/checklist/CI/APK/graph delivery. No production source edit. Final sourceSHA/APK/SCIP must be regenerated after this profile correction.

Profile correction local implementation and root diff review complete:62 focused tests,4-file format and focused analyzer pass; production delta is empty. Full analyzer and the next exact-SHA CI/K/APK/SCIP delivery remain required.

Full follow-up analyzer now passes with no issues(34.1s). Exact-SHA online delivery follows this profile-only commit.

## Task4 follow-up — reject incomplete integration-driver success

Actual a047 CI34351134148 contains valid four-flight K evidence, including raw rich-only final paints, but the whole A–K integration test times out at25minutes during J. Flutter's host driver nevertheless prints success and the workflow is green. The artifact lacks J and final suite comparisons. Do not deliver this as a complete A–K pass.

Before code, add AVL-16b. Extend the existing pure DashboardProfileReport owner with one fail-closed complete-suite contract. The collector writes its completion record only after every existing suite assertion; the existing driver retains partial evidence before checking that contract. No production owner changes. Reproduce rejection using the unchanged actual incomplete artifact and test missing/malformed completion and scenario reports. Inspect SDK driver behavior to establish the timeout propagation boundary. Retain every per-flight, identity, motion and performance threshold. A finite overall suite/host budget may be adjusted only to fit the measured completed scenario durations plus remaining J; keep workflow bounds and do not add retries or reduce coverage.

Profile agent owns the existing integration collector/report, host driver, profile script and focused report/boundary tests. Root owns immutable failed-attempt preservation, acceptance/architecture documentation, review and exact-SHA CI/APK/SCIP delivery. These are independent file boundaries under the approved Task4/Task5 plan. Next source requires a new exact-SHA human APK and graph; neither earlier candidate is silently relabelled final.
