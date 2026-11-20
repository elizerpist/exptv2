# R15 first-acquisition experiment

## Status

- **Implementation:** experimental candidate, not qualified. Latest application
  source `96cf20d4f64c2e3a06c10507f919dd133033852b`, parent
  `b372a694dbf1e78e90917b73a75990c599ffc68f`, experiment ref
  `fluvi-r15-first-acquisition-export-96cf20d4f64c`. The root-only acquisition
  was introduced in `b372a694` on top of
  `5489dbcdec9a0b0c5adda6f1992c4b5a47b0bb15`; the next commit changes
  diagnostics and their focused test routing. The target branch has not been
  advanced to this experiment.
- **Automated validation:** local compilation/unit checks passed; the hosted
  [API 35 independent controls](https://github.com/elizerpist/exptv2/actions/runs/44728723205)
  are tracked below. Full R15 qualification is **NOT ESTABLISHED**: the
  calibrated balanced comparison and required service composite/privacy
  fixtures remain missing.
- **Human APK delivery:** NOT DELIVERED. The R15 advance rule requires
  reproducible total and independently sampled visual benefit plus the
  privacy/compositor gates. A debug/test APK is not a Human profile APK.
- **Physical acceptance:** R15 not tested. Only the user can decide; no phone
  installation is requested while these gates are incomplete.

## Baseline and interpretation

The phone tested R14 application `b6c71cfc350819e9a10a33e3e4cb6e078a4198d9`
in profile HUMAN_DIAGNOSTIC and reported worse latency. The R15 handoff's
source is its inline LIGHT capture
`6fdafefb-36de-4b73-b03f-fbcdc634be0f`; no independent raw download or
checksum is available in this workspace. The handoff records four initial
total inspections of 175/148/156/135 ms, root calls of 46/138/101/130 ms,
and child totals of 57/0/46/1 ms. Those times overlap other work and do not
predict any saving. Physical wake, appearance, unlock start and last visible
pixels were not measured. R14's 31,381-byte export omitted financial core IDs
`a6:r13Financial`, `a7:r13Financial`, `a8:r13Financial`.

The following rows are transcribed from the R15 handoff's inline phone
summary, not from an independently recovered capture. Durations use the
phone's uptime clock and must not be added where work overlaps.

| Phone attempt | initial / showing request | initial total / active root / children ms | SCREEN_ON → decision / distinct producer post ms | hide event → callback / callback → local / event → remove ms |
| --- | --- | --- | --- | --- |
| 1 | 1 / not specified in handoff | 175 / 46 / 57 | 112 / 254 | 1 / 26 / 91 |
| 6 | 152 / 153 | 148 / 138 / 0 | 198 / 251 | 74 / 31 / 130 |
| 7 | 183 / 191 | 156 / 101 / 46 | 212 / 265 | 81 / 34 / 142 |
| 8 | 212 / 221 | 135 / 130 / 1 | 173 / 233 | 77 / 12 / 103 |

Warm attempt 6's next read began 1 ms after request 152 ended; its queue
overlaps the earlier inspection. Attempts 7 and 8 saw MAIN markers but also an
unavailable window root and correctly remained hidden until later complete
inspection. The sampled window's identity and lifetime were unobserved.

## Candidate change and boundaries

The experiment binds one root-only opportunity to a new eligible wake and the
existing freshness/authority ticket, using the already prepared effective
standalone animated SURFACE_LIVE ORB. The selected active-root call is `0`;
accepted child batching remains `36` on API 35. The existing per-window
fallback, all-window traversal, 96-node cap, incomplete-observation privacy
classification, final admission and R14 readmission behavior remain in place.
New bounded fields record the initial root/child flags, first/total/max child,
first null window metadata and sampler timing. The withdrawal record binds
the actual Surface generation, synchronous revoke and bounded holder-operation
milestones to its original hide. A producer post or screenshot is not phone
panel presentation. Four selected financial cores are reserved before verbose
records.

The latest native source navigation and exact-source Dart graph are in
[tooling commit `6d055ad7bd07ff28058caca65d6e9d69453058ba`](https://github.com/elizerpist/exptv2/blob/6d055ad7bd07ff28058caca65d6e9d69453058ba/docs/codegraph-r15-export-correction-2026-11-20.md).
SCIP-Dart 1.6.2 index SHA-256
`1e02a14d22073b98c559b01d077f9337a3a4390a1acc2c8d869d1c9d1dff4ff6`;
manifest SHA-256 `19fafa8cda7be9b896644929b6f802d4085b99d98ab5d2c123307190db7defc2`.
All 102 shard hashes verified; Kotlin is source navigation, not SCIP coverage.
The first candidate's separate, historical graph remains at
[`aa29c8a690d8c0f8abc7690cdef0e0a2095d2f2d`](https://github.com/elizerpist/exptv2/blob/aa29c8a690d8c0f8abc7690cdef0e0a2095d2f2d/docs/codegraph-r15-first-acquisition-2026-11-20.md).

## Local validation and retained failures

| Gate | Result |
| --- | --- |
| `git diff --check`, `verify-fluvi-boundaries.sh`, lower-environment controls | PASS |
| R12 harness and timing-oracle controls; R14 aggregate and R15 routing negative controls | PASS (host controls only) |
| Full app/core JVM tests and debug plus AndroidTest assembly, writable test home | PASS on `96cf20d4`: 341 tests, 0 failures; 139 Gradle tasks, 1m 22s |
| Targeted Flutter diagnostics/boundaries | PASS on `96cf20d4`: 12 tests |
| `flutter analyze --no-fatal-infos` | PASS exit 0; 20 info-level deprecations |
| `scripts/test-fluvi-fast.sh --reporter expanded` | PASS on isolated retry: 1039 + 3 + 4 tests |
| First full Gradle attempt | FAIL: 105 of 150 core tests could not create `/home/agent/.robolectric-download-lock` on the read-only filesystem; original XML and log retained locally. |
| First writable-home assembly | FAIL: disk filled during AndroidTest compilation/native merge; unit tests had passed. Its log is retained. |
| First concurrent Flutter fast run | FAIL/INCOMPLETE: 304 tests passed, 67 test loads failed after disk exhaustion. The successful retry was separate. |
| Direct invocation of `test-keyguard-r14-candidate.sh` locally | NOT RUN: invocation stopped at missing `GITHUB_SHA`; the script requires a clean, source-pinned hosted device case. Its syntax and routing controls pass. |

The local machine has no connected Android device and no `/dev/kvm`; no local
connected-test or visual claim follows from compilation.

## Required evidence still open

- T1: deterministic opportunity, acquisition-call and policy checks pass
  locally; full platform call-order and the complete fallback/privacy matrix
  still require device evidence.
- T2: the initial source's first-LIVE flag control passed; all four R14
  service controls passed on corrected source `96cf20d4`. These do not
  substitute for both balanced stock/candidate blocks or a correct pixel.
- T3: an instrumented successor passed one held in-flight Canvas boundary;
  its screen samples are unclassified and no last visible ORB boundary has
  been qualified. See the separate test-source identity below.
- T4: the first hosted source failed the phone-shaped LIGHT/FULL cases. The
  corrected source passed both synthetic four-attempt exports and the
  stale-owner control; independent real-service/freeze coverage is incomplete.
- T5: no calibrated LIVE service first/return FULL, discreet, background,
  motion and forbidden-FULL transition oracle has been qualified.
- The five R14 real-service delivery fixtures, all required row/route JSON
  manifests and the same-source 28-row aggregate remain incomplete. Existing
  host oracle tests reject several fabricated inputs but are not device data.
- Two reverse-order blocks of cold plus three warm wakes per arm, matched total
  read and independently sampled first-correct images are not yet available.
  The H1 speed hypothesis is **NOT ESTABLISHED**. No inference is made from
  root call time alone.
- The explicit aggregate on the first run returned exit 1 and
  `R14_AGGREGATE=FAIL_INCOMPLETE`: all 28 owner/route rows lack the required
  `r14-case.json` records. Several individual controls passed, but their
  existing collector output cannot be relabelled an aggregate pass.
- Full native diagnostic (including two 30-cycle repetitions), ordinary CI,
  Human and dashboard qualification are **NOT RUN** behind these gates.

## Hosted controls

The first source `b372a694` ran 16 independent cases in
[run 44728723205](https://github.com/elizerpist/exptv2/actions/runs/44728723205)
on API 35 x86_64. Fourteen passed and two failed. These are individual control
results, not a complete R15 qualification or a balanced comparison.

| Case | Result | Job |
| --- | --- | --- |
| `r15-first-live` | PASS, timing/flag control only | [136262684675](https://github.com/elizerpist/exptv2/actions/runs/44728723205/job/136262684675) |
| `r15-phone-light` | FAIL, recovery records omitted under pressure | [136262684700](https://github.com/elizerpist/exptv2/actions/runs/44728723205/job/136262684700) |
| `r15-phone-full` | FAIL, same omitted recovery records | [136262684651](https://github.com/elizerpist/exptv2/actions/runs/44728723205/job/136262684651) |
| `r15-stale-owner` | PASS | [136262684721](https://github.com/elizerpist/exptv2/actions/runs/44728723205/job/136262684721) |
| `exclusion`, `fresh-main`, `late-only`, `real-return`, `terminal-stale` | PASS, each in its own emulator | [run jobs](https://github.com/elizerpist/exptv2/actions/runs/44728723205) |
| `pressure-light`, `pressure-full`, `pressure-combined`, `paired-light`, `paired-full`, `deferred-light`, `deferred-full` | PASS, each in its own emulator | [run jobs](https://github.com/elizerpist/exptv2/actions/runs/44728723205) |

The failed LIGHT/FULL reports were 31,187/31,183 UTF-8 bytes, both within the
32 KiB budget, with all four `R13_FINANCIAL` cores retained. Both nevertheless
omitted `a1:r14Recovery0/1`, `a6:r14Recovery0/1`, `a7:r14Recovery0/1`, and
`a8:r14Meta` plus `a8:r14Recovery0/1`. The first assertion failed at
`KeyguardCardDiagnosticsInstrumentationTest.kt:811`. Raw reports, runner
transcripts, installation hashes and logs are retained in artifacts
[LIGHT 14625687010](https://github.com/elizerpist/exptv2/actions/runs/44728723205/artifacts/14625687010)
and [FULL 14625597306](https://github.com/elizerpist/exptv2/actions/runs/44728723205/artifacts/14625597306).
The holder values in these two reports are synthetic stress-fixture inputs,
not observed Surface presentation.

The complete first run's downloaded specimens, logs, source/installed-APK
receipts, PNGs and failed aggregate were also archived as
[r15-run-44728723205-evidence.tar.gz](https://media.githubusercontent.com/media/elizerpist/exptv2/03f74e19b4272ee8f3d6707a697ee1fa5ef53274/r15-evidence/r15-run-44728723205-evidence.tar.gz).
An independent HTTPS fetch returned 30,514,208 bytes, SHA-256
`a68eaf815b051f60b16ed28fc83057fcacf2e67e4ea815a2d8c9c0861c04d1c9`.
This is evidence, not an installable APK.

The real-service flag case's retained capture
`5e225d48-177d-4284-bebf-5e8e96eb05cc`, PID 2466, is in
[artifact 14625907077](https://github.com/elizerpist/exptv2/actions/runs/44728723205/artifacts/14625907077).
Warm requests 41 and 67 used root flags `0` and accepted-child flags `36`.
Their full inspections took 666 and 559 ms; child acquisition totals were 557
and 332 ms, with first-child 489 and 126 ms and maxima 489 and 206 ms.
Cold request 1 and warm request 81 saw no windows; later showing requests 32
and 99 used stock root flags `36`. The capture omitted critical recovery ID
`a4:r14Recovery1`. These emulator samples identify transferred child cost as
a concern, but have no matched stock arm and cannot establish an improvement
or a regression. No independently classified first or last screen pixel was
recorded by this timing case.

### First-service timing and holder observations, initial source only

All timestamps below are the device's `SystemClock.uptimeMillis` in capture
`5e225d48-177d-4284-bebf-5e8e96eb05cc` (process 2466, route SURFACE_LIVE).
The host's wake time, service signal and independently observed attach are
different events; no intervals below are summed across overlapping work.
The producer post markers do not prove a correct or physically visible image.

| Wake | host wake / service callback | first request: queued → started → finished; result | show request: decision / add return | first / distinct producer post | actual hide local / remove return |
| --- | --- | --- | --- | --- | --- |
| cold | 53890 / 53937 | 1: 53978 → 54025 → 54257; NO_WINDOWS, no active-root call | 32: 58247 / 58284 | 58578 / 58596 | 60192 / 61173 |
| warm 1 | 64107 / 64208 | 41: 64213 → 64214 → 64880; MAIN, root 60 ms, children 557 ms | 41: 64889 / 64905 | 65157 / 65394 | 71870 / 72320 |
| warm 2 | 76672 / 76723 | 67: 76729 → 76730 → 77289; MAIN, root 223 ms, children 332 ms | 67: 77293 / 77302 | 77566 / 78171 | 80216 / 80658 |
| warm 3 | 84534 / 84598 | 81: 84598 → 84669 → 84673; NO_WINDOWS, no active-root call | 99: 85997 / 86014 | 86436 / 86601 | 88466 / 89623 |

The first captured in-flight boundary was attachment/generation `1/1`, holder
operation 10: lock/draw/post entry 60170, synchronous revoke 60191, local hide
60192, post return and record 60341, remove return 61173. The producer call
had entered before revocation; the content and the last visible screen pixel
were not independently sampled. A second example is attachment/generation `3/3`,
operation 13: post entry 80177, revoke 80187, local hide 80216, post return
80362. These edges are reviewer evidence, not proof of stale displayed content
or a justification for an unreviewed holder policy change.

## Export correction

`96cf20d4` reserves compact first/show/hide and financial summaries plus
recovery records ahead of optional expansions. Its independent sampler data are
accepted only for their original capture and authority; the sampler is not
polled or used for visibility authorization. This is a narrow diagnostics
correction to the two retained phone-shape failures, not another latency
hypothesis or another performance sample. Its focused API 35 run is
[44731582159](https://github.com/elizerpist/exptv2/actions/runs/44731582159);
LIGHT [job 136272417509](https://github.com/elizerpist/exptv2/actions/runs/44731582159/job/136272417509),
[artifact 14627405901](https://github.com/elizerpist/exptv2/actions/runs/44731582159/artifacts/14627405901),
and FULL [job 136272417443](https://github.com/elizerpist/exptv2/actions/runs/44731582159/job/136272417443),
[artifact 14626528363](https://github.com/elizerpist/exptv2/actions/runs/44731582159/artifacts/14626528363)
passed. Each report was 31,057 bytes, retained attempts 1/6/7/8, all four
financial cores and recovery pairs, with `omittedCriticalRecordIds=none` and
`incompleteExportAttemptIds=none`. Those fixture timestamps are synthetic.
`R14_RECOVERY_META.retained` describes the in-memory recovery ring; check the
export omission IDs and actual recovery rows as well when the budget is tight.
Other focused results and independent R14 controls are listed separately.

The focused export run completed **10/10 PASS**: both phone-shape modes,
stale-owner, three existing pressure cases and both paired and deferred
LIGHT/FULL cases. It did not run the real-service first-read performance
experiment again. Two independent same-source runs were then dispatched:
[R14 service controls 44732664214](https://github.com/elizerpist/exptv2/actions/runs/44732664214)
and [ordinary R12 contract 44732734516](https://github.com/elizerpist/exptv2/actions/runs/44732734516).
The R14 run completed **12/12 PASS**, including exclusion, fresh MAIN,
late-only, actual temporary-cover return and terminal-stale cases. Individual
instrumentation successes do not supply the missing aggregate case manifests
or independently calibrated privacy/compositor measurements.

The final-source real-service observations were separate processes: exclusion
PID 2458 held A=84, then successor B=105 classified HIDDEN_OCCLUDED and the
root stayed detached; fresh-MAIN PID 2472 held A=84, then B=85 classified
SHOW_FULL and attachment advanced from 1 to 2; late-only PID 2495 admitted
A=81 before later withdrawal request 87; real-return PID 2453 observed a
framework-origin return request 79 after exclusion request 51, attachment 2.
These are their controlled admission results, not measurements of visible
ORB pixels. The distinct terminal-stale process was PID 2443.
All 12 specimens and their source/install receipts are also
[archived](https://media.githubusercontent.com/media/elizerpist/exptv2/2e57b70009ebd3c3a5037d7101ec08359ec7a9ae/r15-evidence/r15-run-44732664214-evidence.tar.gz):
25,693,848 bytes, independently downloaded SHA-256
`4f1fb04e1b74caf590a85497eaa78bad66f37c600e88adcf1cfdb142de02e5be`.
All focused specimens and the final-source aggregate failure are also
[archived](https://media.githubusercontent.com/media/elizerpist/exptv2/ed83e7b07fea912a3eaf487e938487c9974db646/r15-evidence/r15-run-44731582159-evidence.tar.gz):
11,701,148 bytes, independently downloaded SHA-256
`72480e085c99bd771f47b90c9055c07b2d7c0b9e545e24aa43df9fe7e0ee443e`.
The aggregate still returns `FAIL_INCOMPLETE`: the expected case JSON and
required visual/lifecycle rows have not been produced by this focused run.

The separate R12 contract run **FAIL_INCOMPLETE**
([job 136276357538](https://github.com/elizerpist/exptv2/actions/runs/44732734516/job/136276357538),
[artifact 14626824543](https://github.com/elizerpist/exptv2/actions/runs/44732734516/artifacts/14626824543)).
The actual service ordered-read test passed in the LEGACY_R11 fixture, as did
12 independent Android tests: three financial-bitmap tests and nine panel,
widget, poster and LIGHT/FULL diagnostic controls. The wrapper nevertheless
returned failure because `firstCorrectServiceComposite`,
`serviceDowngradeRevokesOldFull`, `realHolderRevocationAcrossGeneration`,
`routeSelectionSurvivesReattachAndRestart` and
`stableServiceMainConfirmationsDoNotDemandBitmaps` have not been established.
The emulator's initial ADB offline messages were followed by a successful boot
and actual test execution; they are not the cause of the final gate failure.
[Retained archive](https://media.githubusercontent.com/media/elizerpist/exptv2/2e3139f7ca6a0351ddfe3c1848d620ab77db315d/r15-evidence/r15-run-44732734516-evidence.tar.gz):
9,083,220 bytes, independently downloaded SHA-256
`b27c8580e13e4f5def3104079522ed3a1ffac80ac0d294eb9676e05798b45258`.

## Held real-service Canvas observation

The separate test-source commit
[`03677d622f0dd9873b6e1c2d323c3e1f2a7a1b5e`](https://github.com/elizerpist/exptv2/commit/03677d622f0dd9873b6e1c2d323c3e1f2a7a1b5e)
descends from `96cf20d4` and adds a debug-only barrier, test and focused
workflow wiring. It is not the same application source identity as the
`96cf20d4` experiment. Profile Kotlin compiled with the Flutter profile build
task excluded, and `javap` confirmed no test-hook reference in the compiled
profile worker; the debug worker does contain it. This check is not a Human
APK build or delivery.
The later identity-collector source
`6d03df62af5c0b02fe86efcf2085c5c7916d1149` has its own
[Dart graph and Kotlin inventory](https://github.com/elizerpist/exptv2/blob/2554994c876e7db7a7872820838fe1cfdf70ff36/docs/codegraph-r15-holder-harness-2026-11-20.md),
tooling commit `2554994c876e7db7a7872820838fe1cfdf70ff36`, index SHA-256
`4de71f94d5a6e0463cd27d2ea4622a4434dce4991a93d066754a1a607b79bf59`
and manifest SHA-256
`531045e5450f3c67743e8dcf86679b538b1806652eb2ba5730002f98524ca111`.
All 102 graph shard hashes were checked; this graph identifies the test
successor and does not relabel the `96cf20d4` app graph.

The named real-service case passed in
[run 44736433739, job 136288883109](https://github.com/elizerpist/exptv2/actions/runs/44736433739/job/136288883109)
([artifact 14629206992](https://github.com/elizerpist/exptv2/actions/runs/44736433739/artifacts/14629206992)).
The app and test APKs matched their installed bytes before and after that run.
Capture `e7e4035b-a48c-4934-87d5-00f18e3f743d`, PID 2441, used FULL,
SURFACE_LIVE and one actual locked service attachment. On the device's uptime
clock, request 12's event/callback were 63624/63629, read start/end
63630/64130, Main entry 64155, and decision/revoke/local hide 64156. The
root-read component was 486 ms. The test held the real attachment/generation
`1/1`, holder identity 86888383, operation 14 after lock 63020/63020.
Remove began 64157; the deliberately held worker was released at 66077,
draw/post occurred 66077/66077–66079 and remove returned 67543
(capture receipt 67544). The delay after local hide was intentionally induced
by the fixture, so it is not a performance measurement.

Raw screen samples were taken before service, while the service reported its
window visible, after local hide with the worker held, and after removal. Their screenshot brackets were
54439–55051, 60453–61522, 64190–64620 and 67598–68091 respectively;
the 168×168 crop was at `(456,1905)–(624,2073)` on display 0. They are
**UNCLASSIFIED**: no independent calibrated full/discreet/background oracle
was applied, no first/last visible ORB is established and physical display
presentation is unknown. The pre-service crop was flat and cannot serve as a
qualified calibration. The before-hold crop and after-removal crop had no
pixel with a channel difference of 7 or more; this is an uncalibrated raw
comparison ([raw crop statistics](https://github.com/elizerpist/exptv2/blob/417377db548b6ef2dbd06cab6cc93ed4cb83eb4b/r15-evidence/r15-run-44736433739-crop-raw-statistics.txt)),
not proof that an orb was absent or present in either sample.
The screenshot calls themselves took 430–1,069 ms,
too coarse to resolve an onset on the scale of the phone's reported hundreds
of milliseconds. This control does not implement the complete holder
lifecycle/privacy fixture across generations and routes.

[Retained holder archive](https://media.githubusercontent.com/media/elizerpist/exptv2/89bc0b00e3b9de01b64562ff6a19665e2c600247/r15-evidence/r15-run-44736433739-evidence.tar.gz):
7,999,792 bytes, independently downloaded SHA-256
`ec7afd4681b14def01e3dd581cabd9fe176c986782a0306d361d1a3bca2fecb5`.

## Separate route and package-identity controls

Test-source `6d03df62af5c0b02fe86efcf2085c5c7916d1149` adds a fail-closed
installed-package verifier to the R12 collector. It records install exit,
the actual `pm path` split list and package listing, and compares installed
app/test APK bytes with their source files both before and after each case.
Its host controls passed matching before/after receipts and five negative
split, identity, command and byte-mismatch cases. This does not qualify the
application's visual output.

| Route | Run and artifact | Timing case | Full route gate | App APK SHA-256, before = after |
| --- | --- | --- | --- | --- |
| LEGACY_R11 | [44737514537](https://github.com/elizerpist/exptv2/actions/runs/44737514537), [14629852185](https://github.com/elizerpist/exptv2/actions/runs/44737514537/artifacts/14629852185) | PASS, 4 wakes, PID 2456 | FAIL_INCOMPLETE | `f7b4b961b5a6cbfa20225be2c267331ad93afe53f296771d701424e23fbf37a5` |
| SURFACE_STATIC | [44737515067](https://github.com/elizerpist/exptv2/actions/runs/44737515067), [14629019191](https://github.com/elizerpist/exptv2/actions/runs/44737515067/artifacts/14629019191) | PASS, 4 wakes, PID 2502 | FAIL_INCOMPLETE | `76d642fc9c4985832457da5cbb722a403c4dabf8ba91d56cba97500bd992bde1` |
| SURFACE_LIVE | [44737515219](https://github.com/elizerpist/exptv2/actions/runs/44737515219), [14630415609](https://github.com/elizerpist/exptv2/actions/runs/44737515219/artifacts/14630415609) | PASS, 4 wakes, PID 2459 | FAIL_INCOMPLETE | `89d9dc2751e5edcbcbd5f6292d6d623447c98e43cc5eaab6cfc90a4885a96e01` |

The installed test APK hashes also matched before and after in all three
cases; both install commands and the post-test identity checks returned zero.
The different debug APK hashes belong to separately built emulator jobs and
are not a matched stock/candidate performance comparison. STATIC preflight
found a known Launcher3 ANR, retained its evidence, closed the system dialog
and proceeded after the fixture reported `PREPARED_KNOWN_LAUNCHER_ANR`; that
is distinct from the later product-test and full-contract outcomes. All three
wrappers correctly returned failure for the five absent service compositor,
privacy, holder-lifecycle, selector-persistence and financial-demand cases.

[All three route specimens and receipts](https://media.githubusercontent.com/media/elizerpist/exptv2/ef1d8ba9886a139a93ff7c366ede30a699975980/r15-evidence/r15-route-controls-6d03df62-evidence.tar.gz)
were independently downloaded: 3,218,453 bytes, SHA-256
`2a39885c9dab86ad19b7f11901d2d0685b5341479c708a674e4d60b4ef472cbe`.
