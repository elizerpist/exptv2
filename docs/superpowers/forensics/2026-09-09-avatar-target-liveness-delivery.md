# Avatar target liveness — final delivery record

Application source: `33ee878b070345c336bb73df2b087d9a63c87c5a`, branch `fix/avatar-target-liveness-codex-20260909`. All required automated validation and artifact delivery are complete for this immutable source. Physical-device acceptance remains PENDING — USER ONLY.

AA61242 AVATAR CORRECTNESS — PHYSICALLY REJECTED BASELINE

AA61242 / E8 MOTION — PRESERVED

NEW AVATAR CANDIDATE — PHYSICAL VALIDATION PENDING, USER ONLY

## Repair and evidence boundary

The [user instruction][prompt], [acceptance checklist][checklist], [architecture card][architecture], [plan][plan] and [forensic record][forensics] define the exact scope. This record closes their delivery-dependent states against an immutable application commit; it does not move application HEAD after the APK build.

The production repair in 174ad841 keeps the latest immutable Avatar payload and request order in the existing candidate owner. It prepares the target through the existing `budgetAvatarPreview` cache lane independently of stale broad hotsets, fences superseded completion, and explicitly completes or terminates each request. Actual Header, progress and LogBox painting, final selection and canonical focus follow the latest target. Every subsequent commit through 33ee878b changes only profile/test tooling and evidence; the `lib/` and `android/` diff from 174ad841 is empty.

The frozen physical export is session `fluvi-1788938720595789`, sequences 2329–3353, 689397 UTF-8 bytes, SHA-256 `dcab9c791ba80d09ad79f20ab01cb33ce8c07d366757c241428f76f3bc4183d3`. Its 2000 event copies contain 1025 unique records and 975 identical duplicates. Its inner null-window rejection reason was not recorded. The real-cache tests prove reachable pending-plan starvation and the earlier 1-painted/final 8 binder-miss race; they do not invent the missing physical subcause.

All 232 protected production files match aa61242. The Avatar rail differs only in one diagnostic rejection label; the e8→aa shared-motion diff is empty. Physics, controller/ScrollPosition ownership, spacing, thresholds, Time, Mind, Slider, finance, database, layout and clipping are preserved. No new cache, visible store, controller, timer, retry loop, capacity increase or focus authority was added.

## Verification

Commands and original evidence are in [local validation][local], [composition verification][composition], [owner bounds][owners], [renderer correction][renderer] and [complete-suite handoff][suite]. Flutter/Dart ran inside Ubuntu proot; APK builds ran on GitHub.

| Gate | Recorded result |
|---|---|
| Full final local `bash scripts/test-fluvi-fast.sh` | 417 passed, 4m42 |
| Final full `flutter analyze --no-pub` | No issues, 23.3s |
| Changed Dart formatting | 0 changes; initial 14 files, renderer 4, suite 5, final boundary 1 |
| Full application suite | 311 passed |
| Full presentation suite | 605 passed / 19 inherited failures; baseline 597 passed / identical 19 |
| Additional full boundary suite | 25 passed / 1 inherited failure; baseline 23 passed / identical 1 |
| Final focused profile/report boundary suite | 96 passed, including original strict renderer/identity negatives |
| Native/Flutter boundary script | Passed |
| Codegraph generator `dart test` | 15 passed; tooling source unchanged at c8a49968 |
| Final CI Flutter prerequisite | 417 passed; clean analyzer |
| Final CI native prerequisite | Passed |
| Actual complete Android profile | Required A–K gates passed; all 11 reports and completion marker verified; 28m21 |
| Optional physical-device frame targets | Failed in the swangle emulator: 59 limit entries; phone performance remains PENDING — USER ONLY |

All 19 presentation failure names and complete normalized assertion outputs match the fresh aa-equivalent baseline, including pixel counts, values and stack locations. The separate boundary failure, `CoreDashboard hosts one mode domain outside its singleton LogBox`, counts three textual occurrences (one constructor and two diagnostic strings) where the unchanged test expects one. No new failure is hidden and no unrelated golden was regenerated.

All eight real production-composition scenarios pass, including startup `3→2→1→0→8→7→6`, aggregate 0, endpoints 7/8, sparse controls, forty flights over twenty persistent cycles, actual earlier 1 paint/final 8 binder loss, and a paired Time negative control. Actual surface/canonical parity is asserted at each final target. The visible-day fixture uses 412×1200 because 412×892 leaves a zero-height inner viewport after opening Time and the focused chip; production geometry is unchanged. Resource, scene, candidate-byte, prepared-query and cumulative diagnostic-ring bounds are measured. Focus-index and listener ownership use static finite-slot/lifecycle proof; no runtime heap or listener census is claimed.

## Actual CI and human APK

Run [34358444008](https://github.com/elizerpist/exptv2/actions/runs/34358444008) completed successfully for the exact application SHA above: Flutter, native, full-profile and normal human APK jobs all passed. The actual test reached `28:21 +2: All tests passed!`; the full log contains no hidden timeout or failure. The immutable [final CI metadata](../evidence/2026-09-09-avatar-target-liveness-delivery/ci-run-final.json) records the exact jobs and source.

The [profile verification report](../evidence/2026-09-09-avatar-target-liveness-delivery/profile/profile-verification-report.md) and [root independent raw verification](../evidence/2026-09-09-avatar-target-liveness-delivery/profile/root-validation.json) prove all eleven A–K reports, the schema-1 completion marker written after all assertions, equality of all 19 separate JSON exports with the complete response, the ten-fling timeline and four density timelines of ten flights each. The actual four K finals are `3, 0, 3, 0`: Phase A rows `0, 0, 0, 0`, rich Phase B rows `2, 3, 2, 3`, exact-empty false and paint/visible revisions `2=2`. Each flight has eight requests and eight accepted nonempty paint terminals, pending zero, coherent physical/desired/semantic/painted/selected/focus/Header/progress/LogBox/canonical targets, category/query digests and displayed values. The separate post-renderer final remains target 0, rich rows 3 with the same guarantees. All targets 0–8 occur in 32 actual renderer paint acknowledgements; the literal Phase A subset is 27.

All existing motion-isolation and populated/empty/first-tenth comparison gates pass. First/tenth motion durations are 25.957/24.031 seconds; velocity, semantic sequence and endpoints agree. The optional [physical-device frame-target report](../evidence/2026-09-09-avatar-target-liveness-delivery/profile/dashboard_profile_dashboard_physical_frame_targets.json) is explicitly `passed: false` with 59 limit entries in the swangle emulator. The existing `FLUVI_REQUIRE_PHYSICAL_FRAME_TARGETS` opt-in was not enabled by this normal CI run. No phone frame-rate, latency or smoothness acceptance is claimed.

The unchanged [original 28-file profile ZIP](../evidence/2026-09-09-avatar-target-liveness-delivery/profile/dashboard-profile-results.zip) is 2,125,859 bytes, SHA-256 `adb92df9fd0bd2eb593dcff77037ba237a88ea767a6336221b80c6129d327218`, matching GitHub artifact 10108606541. It retains the complete 26,068,357-byte raw response, SHA-256 `016400d624f7b1ab8d9da6be4378bb5d972e46dafb5ddd6f85881a1751c651a8`. Extraction was byte-compared against all original entries. Selected raw reports, per-file hashes, validators, full job log and comparison evidence are also retained alongside it.

The normal default `lib/main.dart` human APK is downloaded to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_33ee878.apk`: 82236721 bytes, SHA-256 `44d02722a48bedd8a4a36efd0d8605476a7d65a0c52d65e6d96c74f1974e97f1`. Root independently rehashed the local file; hash and size match the GitHub asset, and the release target is the exact application SHA. [Delivery provenance](../evidence/2026-09-09-avatar-target-liveness-delivery/human-apk-delivery.json) identifies job 102491185062 and the [normal human APK release](https://github.com/elizerpist/exptv2/releases/download/fluvi-human-diagnostic-33ee878/fluvi_HUMAN_DIAGNOSTIC_33ee878.apk). This is the normal application entrypoint, not the automated profile harness.

Earlier attempts remain historical under `../evidence/2026-09-09-avatar-target-liveness-delivery/attempts/` and in the immutable application evidence. Run 174ad841 exposed a collector false negative for rich paint. Actual a047 then proves four K finals 3,0,3,0 with raw Phase A 0 and rich Phase B 2,3,2,3, matching revisions/identities, 8 accepted nonempty terminals per flight and pending 0. Its wider suite later timed out during J but the SDK driver falsely reported success. The new shared completion guard requires all eleven reports and a marker written after every existing assertion, persisting partial evidence before rejection. Whole-suite budgets 35/38/40/60 minutes preserve all per-flight and performance thresholds. A stale 30m boundary expectation then blocked 6adeb42 and was corrected before the complete local 417-test green. Neither partial attempt is reported as complete A–K evidence.

## Exact-source SCIP graph

[Manifest](../../codegraph/manifest.json) indexes 33ee878b, parent 6adeb42c, with SCIP Dart 1.6.2. Raw index SHA-256: `3f6a36a51bc29c6798752ce7c6005762ae55985d678339aece0f60ef9fb2d48a`. The graph contains 436 documents, 9962 repository symbols, 72009 references and 21355 edges. Immediate-parent changed impact is 0 for the final test-only assertion correction; this does not describe the whole aa→final repair.

Two generations produced all 58 files with identical SHA-256 values. The final query finds the suite guard's nine references in the host driver and tests, with no production consumers. [Provenance](../evidence/2026-09-09-avatar-target-liveness-delivery/graph-provenance.json), [determinism hashes](../evidence/2026-09-09-avatar-target-liveness-delivery/graph-determinism.json), index/generation logs, query output and the 15-test tooling log are retained. Raw `index.scip` is not committed. Graph and raw delivery evidence are published in [924847d4](https://github.com/elizerpist/exptv2/commit/924847d4356f2c9806cc2f7c257bc6499ece11c7) on `tooling/scip-codegraph-v1`; its remote SHA was verified after push. The graph manifest, CI run and normal APK release all identify the same application source `33ee878b070345c336bb73df2b087d9a63c87c5a`. Documentation-only workflow cancellation is retained in [publication proof](../evidence/2026-09-09-avatar-target-liveness-delivery/publication-proof.json).

## Acceptance closure

The immutable [checklist][checklist] provides each requirement's source, code owner, acceptance condition and verification method. The following records the final status of every stable ID; this delivery record supersedes their historical pending artifact states without rewriting the built application commit.

| ID | Verification | Status |
|---|---|---|
| AVL-01 | Frozen export hash, source/lineage/initial graph audit | DONE |
| AVL-02 | Eight real composition scenarios and exact startup sequence | DONE |
| AVL-03 | Twenty persistent forward/reverse cycles, forty flights | DONE |
| AVL-04 | Separate empty/nonempty controls and nonempty paint counts | DONE |
| AVL-05 | Typed window/binder rejection branches and tests | DONE |
| AVL-06 | Real-cache starvation red/green and bounded target preparation | DONE |
| AVL-07 | One typed terminal per request, cancel/failure/disposal coverage | DONE |
| AVL-08 | Earlier 1-painted/final 8-miss race resolves to actual final 8 | DONE |
| AVL-09 | Nonempty aggregate 0 paint and category focus clear | DONE |
| AVL-10 | Nonempty endpoint 7/8 actual paint | DONE |
| AVL-11 | Older deferred canonical installation fenced | DONE |
| AVL-12 | Superseded pointer/resource completion fenced | DONE |
| AVL-13 | Actual Header/progress/LogBox/focus/visible/canonical parity | DONE |
| AVL-14 | No Time startup dependency; paired Time control | DONE |
| AVL-15 | Runtime resource bounds and static index/listener ownership | DONE |
| AVL-16 | Strict negative fixtures and actual final 33ee four-flight K plus post-renderer proof | DONE |
| AVL-16a | Genuine rich-only red/green and final raw rich rows 2,3,2,3 plus post-renderer 3 | DONE |
| AVL-16b | Actual complete 11-report suite, explicit marker, 19 export comparisons and no hidden failure | DONE |
| AVL-17 | Protected source/ownership unchanged; all required final motion-isolation and comparison gates pass | DONE |
| AVL-18 | Protected-source hashes and full production diff review | DONE |
| AVL-19 | Local/CI gates and actual full profile passed; inherited failures and optional physical-frame failures reported | DONE |
| AVL-20 | Exact-source normal APK downloaded/hashed; matching deterministic graph published at 924847d4 | DONE |
| AVL-21 | Physical acceptance remains PENDING — USER ONLY | DONE |

AVL-21 DONE preserves the user's reserved verdict. It does not report physical acceptance or measured phone smoothness for the new candidate.

[prompt]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/user-prompt.txt
[checklist]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/checklists/2026-09-09-avatar-target-liveness.md
[architecture]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/architecture/2026-09-09-avatar-target-liveness.md
[plan]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/plans/2026-09-09-avatar-target-liveness.md
[forensics]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/forensics/2026-09-09-avatar-target-liveness.md
[local]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/local-validation-final.md
[composition]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/composition-task-report.md
[owners]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/owner-bound-audit.md
[renderer]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/profile-rich-renderer-task-report.md
[suite]: https://github.com/elizerpist/exptv2/blob/33ee878b070345c336bb73df2b087d9a63c87c5a/docs/superpowers/evidence/2026-09-09-avatar-target-liveness/profile-suite-completion-task-report.md
