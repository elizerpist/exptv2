# R15 visual and A/B continuation — bounded, unqualified result

Date: 2026-11-20. Handoff: `d248987751c34710ab52e4ebd38c5ad6eb47e343`, between `FLUVI_R15_VISUAL_AND_AB_CONTINUATION_BEGIN/END` in the shared journal.

**Implementation:** An experimental candidate and test/diagnostic collectors exist at [`536987c2345bf0c0cc2cb297b68c7227a0aed3c8`](https://github.com/elizerpist/exptv2/tree/536987c2345bf0c0cc2cb297b68c7227a0aed3c8). They are not promoted to the target application branch. The conditional detached motion guard followed a valid predecessor RED. The five named tests execute, but some fixture paths and the independent visual classification remain incomplete.

**Automated qualification:** FAIL/INCOMPLETE. The 28-key aggregate has 12 PASS and 16 failing or unestablished evidence rows. The one actual 16-slot A/B dataset is NOT_ESTABLISHED. No positive claim of H1 benefit or privacy safety follows.

**APK delivery:** NOT QUALIFIED / NOT DELIVERED. The handoff requires the 28-row, visual/privacy and paired-benefit gates before the full native and normal Human-delivery gates and permits a phone download only for a qualified artifact. The installed A/B APKs were debug and androidTest packages, not a Human profile binary. No source/hash/signature is asserted for an undelivered candidate Human APK.

**Physical acceptance:** PENDING — USER ONLY. Emulator results do not establish user-visible latency or frame rate on the Nothing A142. The latest handset evidence remains R14 `b6c71cfc350819e9a10a33e3e4cb6e078a4198d9`, capture `6fdafefb-36de-4b73-b03f-fbcdc634be0f`; its physical presentation timestamps were not measured.

## Source and audit provenance

The app worktree merged the append-only target journal into descendant `6d03df62af5c0b02fe86efcf2085c5c7916d1149`. The runtime guard is [`9a5a9be58b1c35ac053aed017325f1d27f43b6e5`](https://github.com/elizerpist/exptv2/commit/9a5a9be58b1c35ac053aed017325f1d27f43b6e5); actual-service fixtures and debug observations [`be3bdbacf2f109094eda6d7fa8c1f34db50ba75a`](https://github.com/elizerpist/exptv2/commit/be3bdbacf2f109094eda6d7fa8c1f34db50ba75a); collection/routing/manifest changes [`536987c2345bf0c0cc2cb297b68c7227a0aed3c8`](https://github.com/elizerpist/exptv2/commit/536987c2345bf0c0cc2cb297b68c7227a0aed3c8). The original R15 stock-vs-experimental root argument is still an experiment. The guard updates a Main-owned motion eligibility value and invalidates an already-issued opportunity under the existing queue lock on motion-off; it does not reissue that opportunity during the same wake. The debug comparison and holder barriers are absent from compiled profile call sites. Complete classification and visibility checks remain in force.

Reviewer originals `/workspace/scratch/538f5e8d2f3a/project_sources/` were inaccessible. The journal's portable copies at `161f63675121302432be2026898bed07b23d7ded` supplied the three rule assets; this does not establish the SHA256 of the inaccessible original uploads. The full target journal and cited milestones/reports are preserved. The target app was at `d248987751c34710ab52e4ebd38c5ad6eb47e343` when the report branch was prepared.

The exact-source graph is [`cb2793dd5718344e586a40d4a24e25955d4ec5a1`](https://github.com/elizerpist/exptv2/blob/cb2793dd5718344e586a40d4a24e25955d4ec5a1/docs/codegraph-r15-continuation-536987c2.md); its [manifest](https://github.com/elizerpist/exptv2/blob/cb2793dd5718344e586a40d4a24e25955d4ec5a1/docs/codegraph/manifest.json) identifies application `536987c...`. SCIP-Dart index SHA256 `beffdbb55cea86e4ef920b097d8ea7ca055773b9145ca35ba27bd2033c543abf`, manifest SHA256 `50507e449d186a1903c5891aac42c806507f9642a88aae9aaf24c6c29db9449b`; 808 Dart documents, 20,269 repository symbols, 136,449 references and 42,246 edges. The 102 shard checks and 16 tooling tests passed. Kotlin is a manually source-verified inventory, not SCIP coverage. Graph source `/workspace/r15-continuation-graph-source`, tooling `/workspace/r15-continuation-graph-tooling`.

## Balanced acquisition comparison

First exact-source [run 44757516540](https://github.com/elizerpist/exptv2/actions/runs/44757516540), job `136361052525`, failed before instrumentation because hosted `ffmpeg` was absent: zero of 16 measurement slots used. A separately identified workflow-only harness [`d40c7dde1bf87537a88e8ff1192986bc627e888e`](https://github.com/elizerpist/exptv2/commit/d40c7dde1bf87537a88e8ff1192986bc627e888e) installed ffmpeg and checked out exact app/test source `536987c...`. It did not change application source; the GitHub workflow head for this second run is the harness SHA, not the application SHA. [Run 44759137322](https://github.com/elizerpist/exptv2/actions/runs/44759137322), job `136366687265`, executed all four distinct processes and the prescribed 16 slots on one API35 device with the same installed package bytes before/after. All four single-method instrumentation invocations returned one successful test, but the collection exited nonzero and qualification remained NOT_ESTABLISHED. Its installed debug app SHA256 `f80486120f5bb099f877bd97f8b9f8b65cb4530377c3e02e107dce5155d7778b`; debug androidTest SHA256 `f05028ec2081ac2426244fda9293b5c22308da8b7b7578a01a25f32b116063ae`. These hashes are not Human APK identities.

[Raw ZIP](https://media.githubusercontent.com/media/elizerpist/exptv2/f6f34ae9b6a5657ea0f52bc10cb922d399c950c9/r15-evidence/r15-run-44759137322.zip): 20,770,135 bytes, SHA256 `24223b97452a3f8ac702cb93e4029faeece7c30dce2f8a2586e5fabe0c66ebf0`, independently downloaded and checked. [Full slot JSON](https://github.com/elizerpist/exptv2/blob/f6f34ae9b6a5657ea0f52bc10cb922d399c950c9/r15-evidence/r15-ab-16-slots-536987c2.json) preserves capture/UUID, process, wake/request, ownership, windows, durations and exclusions.

The four recordings had 181, 162, 174 and 178 video timestamps. The original ffmpeg-based metadata extraction produced zero data packets and returned `winscope_v2_track_missing_or_ambiguous`. Independent analysis with separate [ISO-BMFF sample-table tooling](https://github.com/elizerpist/exptv2/tree/4c3cb3e1f3f7547e4c98cd72ddfc6bee78881415/tools/r15_recording) recovered real v2 timestamp samples from all four; [mapping and hashes](https://github.com/elizerpist/exptv2/blob/c76599761b6bf5e4d003d436fffcdbef90f461e5/r15-evidence/r15-ab-bmff-timestamps-536987c2.json). Full PNG extraction for these four videos was not done on the disk-constrained VM. Raw MP4s and frame timestamp lists are preserved. Scene classification and first-correct composites remain UNCLASSIFIED; cross-clock or physical-presentation claims are not implied. Video sample gaps peaked at 1.461/1.660/1.532/1.514 seconds, respectively, which is an observation gap, not a render-FPS estimate.

All rows below are actual first inspection per wake. `root` gives the attempted platform flags or `none`, `accepted` means accepted current root, and read/child are milliseconds. `eligible` records the issued opportunity; it does not mean a platform root call occurred. Outcomes and tree sizes are retained to prevent comparison of unequal samples.

| Block | Arm | Position | PID | Wake / req | Root | Accepted | Complete | First classification / reason | Visited | Children | Total read ms | Root ms | Child ms |
|---:|---|---|---:|---|---|---|---|---|---:|---:|---:|---:|---:|
| 1 | stock | cold | 2496 | 2/1 | 36 | true | true | HIDDEN_OCCLUDED/FOREIGN_ABOVE | 13 | 12 | 1756 | 606 | 507 |
| 1 | stock | warm1 | 2496 | 4/36 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 1 | 0 | 0 |
| 1 | stock | warm2 | 2496 | 6/74 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 0 | 0 | 0 |
| 1 | stock | warm3 | 2496 | 8/101 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 1 | 0 | 0 |
| 1 | candidate | cold | 3372 | 2/1 | 0 | false | false | HIDDEN_OCCLUDED/FOREIGN_ABOVE | 1 | 1 | 720 | 238 | 0 |
| 1 | candidate | warm1 | 3372 | 4/33 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 9 | 0 | 0 |
| 1 | candidate | warm2 | 3372 | 6/78 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 16 | 0 | 0 |
| 1 | candidate | warm3 | 3372 | 8/111 | none | false | false | HIDDEN_OCCLUDED/FOREIGN_ABOVE | 1 | 1 | 532 | 0 | 14 |
| 2 | candidate | cold | 4157 | 2/1 | none | false | true | HIDDEN_OCCLUDED/FOREIGN_ABOVE | 2 | 1 | 348 | 0 | 173 |
| 2 | candidate | warm1 | 4157 | 4/47 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 18 | 0 | 0 |
| 2 | candidate | warm2 | 4157 | 6/79 | 0 | true | true | SHOW_FULL/MAIN_CONFIRMED | 12 | 11 | 679 | 568 | 95 |
| 2 | candidate | warm3 | 4157 | 8/98 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 1 | 0 | 0 |
| 2 | stock | cold | 4976 | 2/1 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 38 | 0 | 0 |
| 2 | stock | warm1 | 4976 | 4/40 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 13 | 0 | 0 |
| 2 | stock | warm2 | 4976 | 6/72 | 36 | true | true | SHOW_FULL/MAIN_CONFIRMED | 13 | 12 | 712 | 546 | 0 |
| 2 | stock | warm3 | 4976 | 8/85 | none | false | true | HIDDEN_UNKNOWN/NO_WINDOWS | 0 | 0 | 26 | 0 | 0 |

Only three rows had an accepted actual first root (stock block 1 cold, candidate and stock block 2 warm2). The apparent 679 vs 712ms warm2 reads are **not an eligible matched effect**: 12 vs 13 visited nodes/tree shape and no classified composite. All other warm positions lacked an accepted first opportunity in at least one arm. Block 1 warm3 additionally had an incomplete candidate and different outcome. Each block's onset intervals, eligible matched warm median and end-to-end benefit are unavailable, not zero. The H1 benefit is therefore NOT ESTABLISHED, and it is not proven false for every environment.

## Independent visual and lifecycle observation

[LIVE artifact 14639238397](https://github.com/elizerpist/exptv2/actions/runs/44757516332/artifacts/14639238397) / [verified raw ZIP](https://media.githubusercontent.com/media/elizerpist/exptv2/382d6352ea0a6d690e86f27adb4346deae9c4aed/r15-evidence/r15-run-44757516332.zip) SHA256 `8027771574ea1224a1aa1d14010a585b311522ee725ab9828bb16cc160b2a359`, 37,086,693 bytes. One artificial held-worker privacy downgrade used case UUID `c8a4ee26-287d-43a2-ad42-0df6392a9099`, capture `6f6e7691-4fbe-47a1-b940-23e8395d2e14`, process PID 3369/start 10692, service session 1/wake 2, attachment 1, G1 holder 33855507. Actual measured ROI is `(456,1905)-(624,2073)` on the 1080×2400 emulator recording.

All 145 native presentation-order full-frame PNGs, per-frame hashes and elapsed timestamps are [preserved here](https://github.com/elizerpist/exptv2/tree/3efba1e12a17890c44599b62bc1cfbc28709791c/r15-evidence/live-privacy-frames-536987c2), along with the raw MP4 and supplemental decoder. The same colored ROI RGB hash `931e9a0ed22f85dd59ea6e78b69324697721a7d09df6060d85ec84a1d54cf9d4` was sampled at elapsed 115502.118ms, before old generation revocation at uptime 115533ms, and at 115624.933 through 116092.498ms after revocation. A different gray ROI was sampled at 116312.507ms. Awake uptime/elapsed offset was about 0–1ms. The held G1 post returned at uptime 115630ms, so the 115624.933ms sample precedes that post. The subsequent samples do not distinguish retained composition from that post. G2 discreet producer first post was 116185ms. Native samples are not continuously observed; timestamps do not locate an exact last pixel. The references do not positively classify FULL or discreet, so this is not proof of forbidden FULL, safe privacy, or physical screen behavior.

The LIVE and STATIC independent-shade checks timed out. Frames 64, 93 and 136 show the lockscreen at 118.667, 124.026 and 132.950 seconds; the fixture's SystemUI node test did not establish an expanded shade. This is a fixture/measurement failure, not proof the app remained visible over a confirmed shade. The LIVE G1 holder lock was at uptime 156806ms, revoke return 158819, independent release 158821, post return 158824, destruction return 158941; G2 Callback2 requested 162824 and completed 163277, then the fixture failed a generic check before the G2 owner record. The STATIC fixture observed G1 lock 167456, revoke return 168507, release 168515, post 168669, destruction return 168676; G2 holder post and Callback2 completion 173964. The STATIC test passed the exercised path, but calibrated G2 compositor and early-revoked Callback2 behavior were not established. No unobserved holder release, composited latch or physical disappearance is inferred.

## Five named service cases by route

| Case | LIVE | STATIC | LEGACY_R11 |
|---|---|---|---|
| `firstCorrectServiceComposite` | instrumentation PASS; compositor UNCLASSIFIED | instrumentation PASS; compositor UNCLASSIFIED | FAIL: `bounds()` found no matching legacy element |
| `serviceDowngradeRevokesOldFull` | FAIL: shade withdrawal timeout; shade not independently established | same shade precondition/timeout | FAIL: `bounds()` fixture before visual boundary |
| `realHolderRevocationAcrossGeneration` | FAIL after real G2 creation; generic check, exact assertion unproved | instrumentation PASS for exercised holder sequence; full visual and early-redraw claims NOT_ESTABLISHED | FAIL: `bounds()` fixture before holder control |
| `routeSelectionSurvivesReattachAndRestart` | PASS two real process phases | PASS two real process phases | PASS two real process phases |
| `stableServiceMainConfirmationsDoNotDemandBitmaps` | PASS 32 distinct complete MAIN IDs, zero update paints/demands/binds | same | PASS 32; genuine update positive control: 1 paint, 2 demands and 2 binds |

Selector receipts: LIVE case `11515075-414c-4092-98e8-f730a90410f2`, PID/start 4707/32361 → 4924/35205; STATIC `b7d09a76-033b-4a0c-b71c-49a0eec30ad2`, 5145/37956 → 5358/40706; LEGACY `cff3c88f-1a67-4568-88b0-b53676206d42`, 5576/43201 → 5787/45988. Phase two reads selection before the fixture can rewrite it. The complete identity, package receipts and transcripts are in the case archive.

## Exact-source 28-row aggregate

[All 28 case manifests and retained single-method inputs](https://media.githubusercontent.com/media/elizerpist/exptv2/3efba1e12a17890c44599b62bc1cfbc28709791c/r15-evidence/r15-aggregate-28-cases-536987c2.tar.gz), SHA256 `4472aac117113a1570531ad6d41c61e8d8b923568a2156e3e8583f355ce6a2c1`. The [exact output and error detail](https://github.com/elizerpist/exptv2/blob/3efba1e12a17890c44599b62bc1cfbc28709791c/r15-evidence/r15-aggregate-28-536987c2.log) is FAIL_INCOMPLETE. For the five R14 control rows, the individual instrumentation passed but the case generator did not establish required typed/visual evidence: the aggregate FAIL below is an evidence-extraction/qualification failure, not a claim that those five Android test methods failed. The two older R12 cases actually failed, as recorded below. Missing visual flags are not positive or negative privacy classifications.

```text
r14_exclusion[SURFACE_LIVE]=FAIL:fixture_not_pass,r14_identity_or_timing_missing,r14_a_precondition,r14_b_origin_or_order,r14_exclusion_contract,visual_files_missing_or_corrupt
r14_fresh_main[SURFACE_LIVE]=FAIL:fixture_not_pass,r14_identity_or_timing_missing,r14_a_precondition,r14_b_origin_or_order,r14_fresh_recovery
r14_late_only[SURFACE_LIVE]=FAIL:fixture_not_pass,r14_identity_or_timing_missing,r14_a_precondition,r14_late_only,visual_files_missing_or_corrupt
r14_pressure[LIGHT]=PASS
r14_pressure[FULL]=PASS
r12_pressure[LIGHT_FULL]=PASS
r12_ordered[LEGACY_R11]=FAIL:unexecuted_or_failed_test,fixture_not_pass
r12_occlusion[LEGACY_R11]=FAIL:unexecuted_or_failed_test,fixture_not_pass
r14_real_occlusion[SURFACE_LIVE]=FAIL:fixture_not_pass,real_occlusion_return_not_established
r14_terminal_stale[SURFACE_LIVE]=FAIL:fixture_not_pass,terminal_stale_not_established
r12_real_service_first_composite[SURFACE_LIVE]=FAIL:fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,first_composite_not_established
r12_real_service_privacy_downgrade[SURFACE_LIVE]=FAIL:unexecuted_or_failed_test,fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,privacy_transition_not_established
r12_holder_lifecycle_races[SURFACE_LIVE]=FAIL:unexecuted_or_failed_test,fixture_not_pass,holder_race_not_established
r12_selector_persistence[SURFACE_LIVE]=PASS
r13_service_demand_burst[SURFACE_LIVE]=PASS
r12_natural_timing[SURFACE_LIVE]=PASS
r12_real_service_first_composite[SURFACE_STATIC]=FAIL:fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,first_composite_not_established
r12_real_service_privacy_downgrade[SURFACE_STATIC]=FAIL:unexecuted_or_failed_test,fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,privacy_transition_not_established
r12_holder_lifecycle_races[SURFACE_STATIC]=FAIL:fixture_not_pass,holder_race_not_established
r12_selector_persistence[SURFACE_STATIC]=PASS
r13_service_demand_burst[SURFACE_STATIC]=PASS
r12_natural_timing[SURFACE_STATIC]=PASS
r12_real_service_first_composite[LEGACY_R11]=FAIL:unexecuted_or_failed_test,fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,first_composite_not_established
r12_real_service_privacy_downgrade[LEGACY_R11]=FAIL:unexecuted_or_failed_test,fixture_not_pass,visual_files_missing_or_corrupt,visual_owner_or_calibration_missing,privacy_transition_not_established
r12_holder_lifecycle_races[LEGACY_R11]=FAIL:unexecuted_or_failed_test,fixture_not_pass,legacy_holder_count
r12_selector_persistence[LEGACY_R11]=PASS
r13_service_demand_burst[LEGACY_R11]=PASS
r12_natural_timing[LEGACY_R11]=PASS
R14_AGGREGATE=FAIL_INCOMPLETE
```

## Device test and failure ledger

| Scope / run | Job / artifact | Actual status and first relevant boundary |
|---|---|---|
| [LIVE 44757516332](https://github.com/elizerpist/exptv2/actions/runs/44757516332) | `136361052168` / `14639238397` | FAIL_INCOMPLETE: independent shade timeout and G2 holder assertion; timing and first fixture passed separately |
| [STATIC 44757517210](https://github.com/elizerpist/exptv2/actions/runs/44757517210) | `136361052923` / `14640252427` | FAIL_INCOMPLETE: shade timeout; timing, first and exercised holder fixture passed separately |
| [LEGACY 44757516622](https://github.com/elizerpist/exptv2/actions/runs/44757516622) | `136361051838` / `14641176527` | FAIL_INCOMPLETE: 3 fixture bounds lookups failed; timing passed |
| [Contract 44757517198](https://github.com/elizerpist/exptv2/actions/runs/44757517198) | `136361053242` / `14641305733` | FAIL_INCOMPLETE: `r12_ordered` did not reach A Main application; `r12_occlusion` expected HardwareBufferRenderer/SurfaceControl but saw RuntimeShader/AGSL; selector, financial and other described controls passed |
| [R14 matrix 44758461466](https://github.com/elizerpist/exptv2/actions/runs/44758461466) | 17 individual jobs; [all retained artifacts](https://github.com/elizerpist/exptv2/tree/d5b3acefb6a567e6fdb515eb0c50e72bf6d12476/r15-evidence) | 16 PASS; `deferred-light` job `136364358787` failed SDK emulator ZIP installation before test (SeekableByteChannel ZIP read error). Combined LIGHT result does not replace that job. |
| [A/B initial 44757516540](https://github.com/elizerpist/exptv2/actions/runs/44757516540) | `136361052525` / `14640711479` | FAIL before slots: ffmpeg absent |
| [A/B actual 44759137322](https://github.com/elizerpist/exptv2/actions/runs/44759137322) | `136366687265` / `14640419233` | Four successful instrumentations/16 rows, collection FAIL, visual and matched benefit NOT_ESTABLISHED |

The 16 PASS matrix cases: deferred-full `136364358645`, exclusion `136364358907`, fresh-main `136364358688`, late-only `136364358744`, paired-full `136364358656`, paired-light `136364358764`, pressure-combined `136364358828`, pressure-full `136364358642`, pressure-light `136364358928`, combined-recovery `136364359228`, first-live `136364358605`, phone-full `136364358951`, phone-light `136364358589`, stale-owner `136364359123`, real-return `136364358741`, terminal-stale `136364358975`. Exact source `536987c...` on that run. Raw per-job ZIPs and failed logs are on the evidence branch, along with job metadata.

Detached-motion guard RED: predecessor `022ffa1b...`, [run 44747871135](https://github.com/elizerpist/exptv2/actions/runs/44747871135), job `136327764278`, artifact `14633508789`, real observer off but eligibility remained true. Guarded predecessor `da1ff228...`, [run 44750797663](https://github.com/elizerpist/exptv2/actions/runs/44750797663), panel job `136337861630`/artifact `14634943801` PASS; outstanding opportunity could not be consumed or revived in the wake, next wake allowed. Actual-service control job `136337861262`/artifact `14635766904` failed to establish the stock call because the real result was `HIDDEN_UNKNOWN/NO_WINDOWS`, not an inferred renderer failure. Held-timeout job `136337860924`/artifact `14635177368` could not run due Maven HTTP 429; an earlier predecessor's independent timeout negative passed. Predecessor-only results are not relabelled exact-source results.

## Local and conditional gates

- PASS: `git diff --check`, `scripts/verify-fluvi-boundaries.sh`, `scripts/test-keyguard-lower-environment.sh`, R12 harness/oracle, R14 aggregate host controls (14), route mapping, installed-package checks, visual host controls (10), comparison host controls (9), case-manifest controls (4) and slot parser controls (3). Host controls are not real-device visual qualification.
- PASS: `:app:testDebugUnitTest :fluvi-core:testDebugUnitTest`, 192 + 150; debug AndroidTest Kotlin and profile Kotlin compilation. Profile disassembly shows no acquisition/worker debug hook references at call sites. PASS: targeted Flutter tests 12; `flutter analyze --no-fatal-infos` with 20 info-level deprecations; `scripts/test-fluvi-fast.sh --reporter expanded`, 1039 + 3 + 4 tests.
- FAIL infrastructure: local all-ABI assembly encountered `No space left on device`; a later x86_64 attempt also failed at `:app:stripDebugDebugSymbols`, unable to create `stripped_native_libs`. Local assembly did not produce a candidate APK. Hosted A/B built and installed its debug pair. Local VM has no `/dev/kvm` and no connected Android device, so local instrumentation NOT RUN. The four A/B MP4s remain intact but were not fully extracted to PNG locally because of disk pressure.
- NOT RUN by handoff qualification order: full native diagnostic 2×30, ordinary core/Flutter/native/Human/dashboard delivery jobs and Human APK signature/download checks. The required prerequisite aggregate, calibrated privacy and paired benefit did not qualify. This is a gate outcome, not a passing build or a claim that those unrun jobs failed.

[Preflight and failed-command logs](https://media.githubusercontent.com/media/elizerpist/exptv2/c76599761b6bf5e4d003d436fffcdbef90f461e5/r15-evidence/r15-continuation-preflight-logs-536987c2.tar.gz), SHA256 `acb44890c7de83ba68642950061fa366d4916374d49869d5306471f7bebdf465`. [Evidence branch](https://github.com/elizerpist/exptv2/tree/c76599761b6bf5e4d003d436fffcdbef90f461e5/r15-evidence) contains immutable run ZIPs, frames, aggregate cases and analysis. No fabricated calibration, APK, comparison interval, independent shade state, or phone acceptance is asserted.
