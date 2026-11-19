# R10 first-render implementation and evidence

The user physically rejected R09 on a Nothing A142. One cold phone attachment
in capture `ad2a0b9b-8a59-4bac-bfb0-d7b20e6aa2fb` had screen-on → CPU live
submission 1,433 ms, including 1,228 ms post-add setup → first root draw.
The separately observed 1,221 ms Worker interval overlaps that root interval
by approximately 1,215 ms. These durations are not additive and neither
identifies a one-second phone GPU operation. Actual physical presentation,
unlock start and removal are UNOBSERVED. The first actual withdrawal was
accessibility-event → remove return 203 ms; later retained withdrawals were
70, 73 and 132 ms, and were not treated as screen-off-triggered. The user did
not accept R09's visible performance.

## Exact identities and scope

- R09 phone and baseline application: `1dddbf6f6fbe4b17ec0fdcb033848c8996721529`.
- R10 observation-only harness: `c3b313b8cc27197a3a60110abed9cae9f1194666`.
- First R10 candidate application: `7a1ec21b55aeaf69ef56c2b49dcc5114d7271b60`, tag `fluvi-r10-orb-first-7a1ec21b55ae`.
- Its separate tooling: `6bba18efc8127b83dea73aa3c8173786f20ad3a5`; manifest SHA-256 `5228b75e1b1b38092f4ddeea056456aaf5f19ef8e98947953aa4c7894cf78781`, index SHA-256 `d0f8d076ff684acdf46fa80d2acc5fc46de8891dbf90b1eb718b955bf0438706`.
- Corrected candidate application: `8a91bf2d79f25780bb420c1a4d14abe846eac333`, tag `fluvi-r10-orb-first-8a91bf2d79f2`.
- Its separate tooling: `44bc9b1cca84fb2bd09f4c953382d6cedd9cf2ee`; manifest SHA-256 `8861fa8edf92084d44c5889b9880cf47bf0cf8e7d2edfa3f193c60ade0ca7282`, index SHA-256 `d2dead5900c63d2afd8cf3ac13f0d86b63d02beaec7c6b3fc7346908517ef19b`. All 102 shard hashes and record counts were checked.

The reviewer selected H1: unnecessary detached work and a blend seeded by
preparation-only content can contend with the first authorized output. This
candidate bounds compatible preparation, supersedes unsubmitted detached work,
requires previously submitted same-attachment content for a previous scene,
and adds owner-qualified cold and report-budget evidence. Published buffers
remain subject to their real release/fence; no timeout provides reuse. The
three-slot pool, admission, privacy, overlay geometry, direct current-child
handoff and existing fallback are retained. Whether H1 explains the user's
phone symptom is a separate measurement question.

## Independent baseline

[Baseline diagnostic run 44557552897, job 135677631120](https://github.com/elizerpist/exptv2/actions/runs/44557552897/job/135677631120),
[artifact 14547216184](https://github.com/elizerpist/exptv2/actions/runs/44557552897/artifacts/14547216184),
239,076,765 bytes, SHA-256 `99cc0d0e8532288340fa371bf1452806c61e1911f06e13f1e306f50c3d78572a`.
The production files matched the exact R09 SHA; only labelled observation
instrumentation was added. Its debug app/test APK hashes were
`404121395bc66e595edd14f5312038ed1e5ab273e79d2499a0c8bc020e8d67fc` /
`a7670f329d34db977d3db6281f14b0d2792f133d9cb0ff5bd7a9ce1476caf15e`.
The API35 x86_64 panel was 1080×2400 at 420 dpi. The real controller RED
showed `latestOrbPreviousScene` was non-null for preparation-only content.

| Independent process | Cold outcome | Warm outcome | Raw timing / limits |
| --- | --- | --- | --- |
| PID 2449 | reached first real authorized service attach | reached the second, warm service attach | Cold wake 48178, add return 52178, first root 52346, first live submission 52694 ms uptime. Correct-crop bracket last negative 50922 / first positive 54048. Warm wake 89186, add return 89437, root 89988, live 90688; crop bracket 89594 / 92142. |
| PID 2689 | setup FAIL waiting for `MATERIAL_ISOLATED_BACKEND_PREPARED` | NOT REACHED | No cold first-image or warm timing can be inferred. |

Rep 1 and 2 retained trace hashes `e2cf275e8e73669a81361e6d37310695bf83083e2a2ad19af6a5295e97bcde18`
and `c3d0cb9338e9641d7616533b38180d86ce409b110626165b2e096b73e3e255a0`.
The 24-screen capture strips consumed about 32.7 s cold and 31.9 s warm;
they perturb the timeline, so visual speed comparison is INCONCLUSIVE. The
artifact retains all original target/negative images and timestamps. The
second run's missing boundary is a setup finding, not a product PASS/FAIL.

In the first baseline process, first inspection request 1 initially classified
`HIDDEN_OCCLUDED`; showing request 26 was a fresh `SHOW_FULL` and spent 223 ms
in its active-root read. Actual hide 3 belonged to attach 1/lease 1/2, child
63670295: trigger 84717, local hide 85210, layer apply return 85210, commit
receipt 85337, remove return 85242 and eventual lease drain 85499. The first
positive frame was slot 1/use 3, Worker configure 52182, start 52221, result
52302, ready 52302, Main entry 52682, direct apply return 52694, commit
receipt 52732, bootstrap retirement 52752. These are app/transaction
observations, not physical presentation. The same trace reports one app
RenderThread `DrawFrames -1` slice at 49707.330–52157.769 ms with a nested
`shader_compile` of 909.491 ms; it overlaps addView 49365–52178 but has no
proven exact lease and runs with intrusive screenshot sampling. It is API35
emulator evidence, not a diagnosis of the phone. The trace has 36
`ftrace_setup_errors` notices and retains the remaining scheduler/slice rows.

## Local checks

- `git diff --check`, `bash scripts/verify-fluvi-boundaries.sh`, `bash scripts/test-keyguard-lower-environment.sh`, `python3 scripts/test-keyguard-r09-panel-harness.py` and the R10 fake cold-harness controls: PASS.
- Specified Flutter boundaries: 12/12 PASS. `flutter analyze --no-fatal-infos`: PASS with 20 informational notices. `bash scripts/test-fluvi-fast.sh --reporter expanded`: 1037 + 3 + 4 PASS.
- `:app:assembleDebug :app:assembleDebugAndroidTest :fluvi-core:testDebugUnitTest :app:testDebugUnitTest`: coherent-source retry PASS. Independently rerun app JVM tests: 154/154 PASS; core 150/150 PASS.
- Baseline-compatible real-controller Robolectric RED on R09 was reproduced and candidate passed; two additional production-shaped FULL/LIGHT export controls passed. These JVM controls do not establish compositor pixels.
- Initial concurrent Android compilation failed with unresolved `previousValid` because the test compiled after the field was added while the main task had compiled the earlier source. Log retained; coherent-source recompilation passed. No device test result is inferred from that build error.
- The local VM has no `/dev/kvm` and no connected Android device; runtime and calibrated screenshots use the separately pinned API35 GitHub runs.

## First candidate device results and correction

[Independent cold run 44563394719](https://github.com/elizerpist/exptv2/actions/runs/44563394719),
job 135698513935, [artifact 14551612097](https://github.com/elizerpist/exptv2/actions/runs/44563394719/artifacts/14551612097),
archive SHA-256 `392dab8cd4587a4738ebf8b97e0f19f3d56434050a22c1d0fc19898a70cf26cb`:
both separately launched PIDs 2514 and 2656 failed waiting for successful
detached preparation, before the first wake or any correct-pixel measurement.
Their captures were `8c915306-7ed7-4665-a59c-5407a824a38f` and
`b8809375-bed4-4bbb-9874-9465d3786093`; trace hashes were
`8993968ba1edb10fabbe1b74e0cca03f654931fe7a6c0c72f0027fc661fe9fce` and
`12354050561184426eddb7d8149406a7e8bcc6e149c3125d117411aace97f22d`.
Both preserve actual trace and capture; neither may be treated as an image
speed result. Baseline repetition 2 also failed this setup boundary.

The first candidate cleared an explicitly armed asynchronous prime on a
`HIDE_NOOP_ALREADY_HIDDEN` while the root was already detached. In capture 1,
the explicit request was 47059, the no-op hide was 47079–47080, and artifact
and program readiness followed at 47125/47153, all uptime ms. The newly added
controller regression failed on exact source 7a1 with the explicit assertion
that an already-detached no-op hide must preserve a pending prime. The scoped
follow-up only preserves that valid existing request in this no-op case;
real withdrawal, pending show and disposal retain invalidation. It does not
change privacy, visual quality, release or the selected R10 hypothesis.

[Separate first-candidate panel 44563394717](https://github.com/elizerpist/exptv2/actions/runs/44563394717),
job 135698508380, [artifact 14550778524](https://github.com/elizerpist/exptv2/actions/runs/44563394717/artifacts/14550778524),
archive SHA-256 `dcd87f63afd303dbc7afde66afaf5bd3fb86bd5d4656d0764c814420dc7d2200`,
ran 20 methods: 15 PASS, 5 FAIL. The corrected withheld-root first/direct
test and all seven new R10 controls passed. The stale-pressure privacy test
captured a first 168×168 target that is entirely white (28,224 white pixels);
the five following retained frames contained material. No prior full-detail
pixels were established by that white frame. The positive neutral oracle failed
before judging the target because its external reference fiducial was not
presented. The failing fiducial screenshot was not archived: the fixture
asserted before its persistence call. The six archived transition crops have
their ordering and dimensions but lack individual sampling timestamps; these
missing items are not reconstructed. The held-release and mixed-size controls both timed out waiting for
requested frame 4, and the pressure-motion control sampled an empty orb crop.
These distinct failures are not erased by the first-direct or R10 controls.
Full native and normal delivery are NOT RUN because their entry gate failed.
All first-candidate archives were copied to separate LFS artifact commit
`3c40732` as well as retained in the immutable GitHub runs.

The held-release fixture's Worker owner was renderer 9: A lease 1/1, child
212452625, first slot/use 1/1 and steady 2/1; its exact final clear applied at
175488. B lease 2/2, child 256577419, submitted first slot/use 3/1 at 175663.
B's later requested frame 4 was not submitted before the test's limit; B was
then retired and its real receipt/fence completed at 175804/175865. The test
intentionally held A's real release delivery until cleanup; A slot 1/1 and 2/1
then received and completed at 183679–183682. These held fixture uses are not
the phone's independently observed old lease 1/2. In the mixed-size fixture,
the original A was likewise held; the replacement produced a real first use
but its requested second sample timed out. Slot IDs are monotonically assigned
identifiers and do not by themselves imply more than three simultaneous slots.

## First candidate delivery

Candidate Human profile evaluation APK:
https://media.githubusercontent.com/media/elizerpist/exptv2/03625d7b6bcd9ca46dec267f55ccd20930ba516e/fluvi_HUMAN_DIAGNOSTIC_7a1ec21b55ae_R10_REVIEW.apk

Built from a clean tracked checkout of the candidate with
`FLUVI_BUILD_COMMIT=7a1ec21b55aeaf69ef56c2b49dcc5114d7271b60 bash scripts/build-human-diagnostic-apk.sh`.
Length 120,213,714 bytes; SHA-256
`03f26ba16d219ffd00a85c012baa2329b2e859b50bdf7723f4c485e90575880c`.
Direct HTTPS returned 200 with `application/octet-stream`; independently
downloaded bytes, length and hash matched the VM build, ZIP integrity passed,
and APK v2 signing verified against certificate SHA-256
`faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`.
All three packaged `libapp.so` ABIs contain the full application SHA and
`HUMAN_DIAGNOSTIC`; DEX contains `R10_COMPACT`,
`R10_ROOT_ATTACH_DISPATCH`, `fluvi-r10-render` and `r10Cold0`. The initial
signature command could not find `apksigner` on PATH; rerunning the installed
36.0.0 tool by absolute path succeeded. The artifact branch also independently
preserves the complete baseline archive at immutable commit
`c596094f00a8148a5b3fa27fa89ff738c9237feb`.

This first APK is REVIEW ONLY and superseded by the no-op lifecycle correction;
it is not a request for physical installation. R09 and first-R10 panel
failures remain historical failures regardless of later runs.

## Corrected candidate

The exact-source debug application and androidTest assemblies passed. The
controller reproduction that failed on 7a1, the original prepared-only
controller control, and the two FULL/LIGHT pressure-export controls passed
locally (4/4). The full corrected-source JVM suites passed again: app 154/154,
core 150/150; Flutter boundary rules remained green. The real
delayed-artifact/GPU completion control is added to
the separately dispatched API35 panel. The independent cold and panel runs
use tag `fluvi-r10-orb-first-8a91bf2d79f2`; their results are recorded below
when both have completed. The candidate profile APK and graph are generated
from separate clean tracked worktrees at the same exact application SHA.

Corrected Human profile review APK:
https://media.githubusercontent.com/media/elizerpist/exptv2/3e18572442d79a23096a7a9abb7bde546a24418a/fluvi_HUMAN_DIAGNOSTIC_8a91bf2d79f2_R10_REVIEW.apk

The VM built it with the project Human script and
`FLUVI_BUILD_COMMIT=8a91bf2d79f25780bb420c1a4d14abe846eac333` from a
tracked-clean detached checkout. It is 120,213,714 bytes, SHA-256
`9eb2e6c175e14a54d151dbbf5bc88ddd4f4364e78de69a3e8084e26c7cf5b8e9`.
Independent HTTPS returned 200/application/octet-stream; downloaded bytes
match the local file, ZIP integrity passed, and v2 signer SHA-256 is
`faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`.
The full SHA and HUMAN_DIAGNOSTIC purpose occur in arm64-v8a, armeabi-v7a and
x86_64 AOT libraries; `R10_COMPACT`, `R10_ROOT_ATTACH_DISPATCH`,
`fluvi-r10-render` and `r10Cold0` occur in DEX. The APK remains REVIEW ONLY
until the corrected privacy/compositor gate is resolved.

The corrected cold and panel evidence archives were also preserved outside
the expiring CI artifact store on immutable LFS commit
`70ea7b473ce9d4926185cb859a3b1d4455f4a889`:
[cold archive](https://media.githubusercontent.com/media/elizerpist/exptv2/70ea7b473ce9d4926185cb859a3b1d4455f4a889/r10-corrected-cold-44566440642.zip)
and [panel archive](https://media.githubusercontent.com/media/elizerpist/exptv2/70ea7b473ce9d4926185cb859a3b1d4455f4a889/r10-corrected-panel-44566440872.zip).
Both links returned HTTP 200/application-zip; their source ZIP integrity and
hashes are recorded below. The baseline and first candidate archives remain
in the same artifact branch history, rather than being replaced.

### Corrected independent cold service experiment — FAIL / partial evidence

[Run 44566440642, job 135709363166](https://github.com/elizerpist/exptv2/actions/runs/44566440642/job/135709363166),
[artifact 14552273362](https://github.com/elizerpist/exptv2/actions/runs/44566440642/artifacts/14552273362),
133,244,943 bytes, SHA-256 `5fd618ea4b06e708861dbb34593e080a4590e705d982d304b15c8e587aeb6a21`.
The diagnostic job ran 11 min 21 s; its two instrumented repetitions failed
after 43.914 s and 42.267 s, respectively.
The application and test APK hashes were
`e9d0c26f83b3d6a86db17d1379ad29e7097b58781e20752c50a3d738b31cf395` and
`ae08c2bc0535880bac458eca8f88b45ee1479d671e64d3df476939ef7d14b7c5`,
with source SHA `8a91bf2d79f25780bb420c1a4d14abe846eac333`. API35 x86_64,
1080×2400/420 dpi; both clean preflights required no reset, both launches had
no earlier app root and distinct PIDs, and both APK hashes remained unchanged.
Both real detached preparations completed and both real authorized first
attachments reached CPU live submission. The independent image observer did
not complete within its existing bound on either run, so its calibration,
correct-pixel classification, both warm controls and measured user-style
withdrawals were NOT REACHED. No third identical replay was attempted.

| Process / capture | Actual observed cold boundaries, uptime ms | Outcome |
| --- | --- | --- |
| PID 2426 / `a5a1a203-3f6d-494d-8e6c-cf06c3683c47` | detached ready 40072; wake input 42710; screen-on 42941; show 44984; add 44991/45192; post-add 45195; async Main 45198; actual attach dispatch 45202; first layout 45650; preDraw 45654; root draw 45672; first CPU live submit 45988 | one detached completed frame before wake, zero pre-wake publications; screen-on → live 3047 ms; add return → root 480 ms; add return → live 796 ms. Screenshot observer timed out; 24 whole screens, 22 crops, 23 sample rows were retained, with no independently calibrated first correct image. |
| PID 2623 / `59a90629-3119-4459-8ddd-25a181491d7e` | detached ready 92840; wake input 95776; screen-on 95875; show 96247; add 96278/96652; post-add 96654; async Main 96672; actual attach dispatch 96682; first layout 97097; preDraw 97099; root draw 97135; first CPU live submit 97639 | one detached completed frame before wake, zero pre-wake publications; screen-on → live 1764 ms; add return → root 483 ms; add return → live 987 ms. Screenshot observer timed out; 24 whole screens, 23 crops, 22 sample rows retained, without an independently calibrated first correct image. |

These are emulator observations under an intrusive multi-second screenshot
strip, not a performance comparison or FPS measurement. Request 1 on the
first process was an initially occluded/incomplete inspection; showing
request 29 had active-root read 13 ms. The second process used showing request
1 with active-root read 270 ms. In both, the test froze the capture before
withdrawal, so its attachment RENDER summary and first lease/slot/use, apply,
commit and bootstrap-retirement tuple are UNOBSERVED. A visible-frame capture
frozen before withdrawal therefore did not export those new Worker fields;
this is a diagnostic limitation requiring review, not evidence of no work.

Raw trace hashes, respectively:
`495aad27ef74caed19d16a94256f4a275a87a4d358a3f6098d47944a1d2ef622` /
`8dcd7fb9469113e06eb867900f8ec8fbe328a9703240891c30a5f1bc3aff458e`.
Each trace had 36 `ftrace_setup_errors` notices. The app's asynchronous
`fluvi-r10-render` spans include 45222.245–45590.708 and
96680.562–97075.328 ms; they overlap the actual attach-to-layout intervals.
The trace does not directly label the exact lease/use for these spans, and
their duration includes app submission-to-callback latency. Their overlap
does not prove what delayed layout or establish the Nothing phone's cause.
Cleanup occurred after the failed test froze capture: rep 1 lease 1/2 child
8881553 final clear 81349 and last observed lease drain 81785; rep 2 lease
1/2 child 261530713 clear 133118 and drain 133383. These are cleanup events,
not the missing matched user-unlock measurements.

### Corrected panel — FAIL, 16/21

[Run 44566440872, job 135709363646](https://github.com/elizerpist/exptv2/actions/runs/44566440872/job/135709363646),
[artifact 14553072106](https://github.com/elizerpist/exptv2/actions/runs/44566440872/artifacts/14553072106),
2,752,218 bytes, SHA-256 `9d5cafe0124849325ed358ecfadc3e869baaabd392624a8d273fcaaece0361e8`.
The diagnostic job ran 12 min 34 s.
Application/test debug APK hashes were
`d90a299b626da868c0a7733b0ff3022a9a619e710bc1c97bf25a45eb65770972` /
`862a230a0bb54ba9ea3534ff90d288842fc5c5a7a07f1a8928097f15da4924ef`;
21 named cases executed, 16 PASS, five FAIL, zero skipped, 100.76 s.
Its preflight was clean without a reset and the pre/post APK hashes matched.
The original seven R10 controls, the new real delayed-artifact no-op-hide
control and the corrected held-next-root first/direct control passed.

The five failures remained distinct:

1. `stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges`:
   the first 168×168 transition crop was entirely white (28,224 pixels),
   while the following five retained crops contained material. Its sampling
   time relative to compositor presentation is not established, and that
   white image is not evidence of leaked full-detail pixels.
2. `r09NeutralPrivacyTransitionHasPositivePixels`: the external neutral
   reference fiducial was not presented, so the target was NOT REACHED. The
   failed fiducial screenshot was not saved because the fixture asserts before
   persisting it; preserve this as missing evidence, not a passing oracle.
3. `oldUsesPreventSuccessorButCurrentOrbKeepsMoving`: the handoff strip
   contained an empty orb crop, so later pressure-motion claims were not made.
4. `r09RetiredChildUnlinksAfterOrderedClearWithReleaseHeld`: requested frame 4
   was not submitted before the fixed test limit.
5. `r09MixedSizeHeldOldUseLeavesCurrentSuccessorCapacity`: requested frame 4
   was not submitted before the fixed test limit.

In failure 4, renderer 10 had A lease 1/1 child 26074573 with slots 1/1 and
2/1. Its final clear applied at 184184; B lease 2/2 child 255606504 first
submitted slot 3/1 at 184432 and entered pressure at 184493. B was withdrawn,
then its real release/fence/lease drain occurred at 184521/184584/184590.
The test intentionally held A's receipts until cleanup, when slots 2/1 and
1/1 were received at 192442/192447 and completed at 192452/192455. These
fixture-held uses are distinct from the old R09 phone lease. Failure 5's
renderer 13 similarly retained A 1/1 child 53902184 until its explicitly held
release at 228414; resized current lease 2/3 child 31955287 had a first
submitted use but did not deliver the requested later sample. Slot identifiers
4 and 5 are allocation sequence numbers, not evidence of five live slots.

The panel command was the fixed `r10_panel_candidate` selector in
`scripts/test-keyguard-r09-panel.sh`, which invokes
`:app:connectedDebugAndroidTest` for the registered methods. Each method was
present in the non-skipped XML. Exact case status and runtime in seconds:

| Method | Result | s |
| --- | --- | ---: |
| `r10CompactColdAndWorstGapSurviveLightPressure` | PASS | 0.567 |
| `firstDirectAndHideCommitEvidenceKeepTheirOriginalOperations` | PASS | 0.018 |
| `r09WorstGapSurvivesLightExportPressure` | PASS | 0.026 |
| `r09WorstGapSurvivesFullExportPressure` | PASS | 0.029 |
| `r10CompactColdAndWorstGapSurviveFullPressure` | PASS | 0.388 |
| `r10ColdRootReportsActualAttachAndLayoutForEachObservation` | PASS | 2.095 |
| `r10DetachedNoopHidePreservesExplicitPendingPreparation` | PASS | 4.432 |
| `isolatedOrbSameLeaseLayoutRetainsAcceptedSteadyGrant` | PASS | 4.698 |
| `r10VisiblePaletteChangeKeepsBlendButPrivacyChangeDoesNot` | PASS | 5.367 |
| `isolatedOrbFirstDirectAppearsWhileNextRootDrawIsWithheld` | PASS | 5.404 |
| `r10PreparedOnlySceneCannotSeedVisibleBlend` | PASS | 0.981 |
| `r10UnsubmittedDetachedWorkYieldsToAuthorizedAttach` | PASS | 2.092 |
| `stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges` | FAIL | 3.787 |
| `isolatedOrbStaleFirstCommitCannotUndoSameRootPrivacyOrSizeReplacement` | PASS | 3.001 |
| `r09UnchangedPlacementSkipsRedundantTransactions` | PASS | 4.267 |
| `r09RetiredChildUnlinksAfterOrderedClearWithReleaseHeld` | FAIL | 11.151 |
| `r09NeutralPrivacyTransitionHasPositivePixels` | FAIL | 2.712 |
| `isolatedOrbRevocationDrainsLateSteadyPublication` | PASS | 10.549 |
| `oldUsesPreventSuccessorButCurrentOrbKeepsMoving` | FAIL | 7.340 |
| `r09MixedSizeHeldOldUseLeavesCurrentSuccessorCapacity` | FAIL | 12.094 |
| `r10AuthorizedFirstShowDoesNotStartAnotherDetachedRender` | PASS | 2.608 |

T10-A's selected first-show/current-pass controls passed. T10-B's no-op and
unsubmitted-work controls passed, while the separate held-release/mixed-size
successor controls failed; a separately forced outstanding detached GPU fence
case was not established by these results. T10-C's palette-change control passed
but the privacy and neutral controls failed. T10-D's actual attach/layout and
cancelled-observation control passed; a live freeze without withdrawal left
the bounded Worker tuple UNOBSERVED. T10-E's FULL and LIGHT export-pressure
controls passed. These results do not establish W-LOCK-ANIM, W-HIDE or
W-HOME-ANIM acceptance or a physical first-image improvement.

Full native diagnostic, both 30-cycle full-service repetitions, normal
delivery, normal Human CI and dashboard-profile gates were NOT RUN because
the required cold and panel entry gates failed. The profile APK above is an
independently built **REVIEW ONLY** artifact. The reviewer must decide the
privacy/compositor failure and how to obtain an unperturbed calibrated cold
measurement; no additional speculative rendering change was attempted.
Physical validation of this exact candidate remains PENDING, USER ONLY.
