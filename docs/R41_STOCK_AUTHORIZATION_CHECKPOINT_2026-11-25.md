# R41 stock authorization — incomplete implementation checkpoint

Application `aa4d98b6970ffa50ca46e1e74b110c5087c9cb1b` on `implement/r41-stock-authorization`, based on owner-tested R40 `11b4a67a08f402968bd55ff62f63f0494227d0a9`. Coordination handoff `330f36a0c0248241d64367a97ac6aa6c0adf3f08`. This is not a release or a phone acceptance report.

## Implementation and boundaries

H1 starts the already selected physical reader before optional reporting, avoids R25 reconstruction in the frozen R38-ordered no-successor branch, and retains mandatory R19 ordering and existing privacy admission. Complete end-to-end evidence is not yet implemented. The planned H2 one-shot stale-predecessor intervention is not implemented; partial shadow counters cannot establish a qualifying claim and H2 remains disabled. A non-DIRECT candidate and its same-show first-post callback are observations only; an equivalent fallback authorization remains `UNOBSERVED`.

## Qualification summary

- Actual R40 T2 baseline RED: [45511744332](https://github.com/elizerpist/exptv2/actions/runs/45511744332); actual A38/B39, one unwanted R25 evaluation. Earlier R41 source `5f7d86c8` T2 pending-DIRECT subset PASS: [45512003066](https://github.com/elizerpist/exptv2/actions/runs/45512003066). On this exact source, [45518214082](https://github.com/elizerpist/exptv2/actions/runs/45518214082) was **NOT REACHED**, not PASS: no complete positive DIRECT snapshot.
- T1 baseline and candidate did not reach a complete positive DIRECT request: [45513835683](https://github.com/elizerpist/exptv2/actions/runs/45513835683), [45513846147](https://github.com/elizerpist/exptv2/actions/runs/45513846147). T3/T4 guarded H2 and all of their races are NOT RUN. T5 complete winning fallback and exclusive partition are INCOMPLETE.
- Exact-source native JVM tests PASS: [45517059269](https://github.com/elizerpist/exptv2/actions/runs/45517059269), 396 app and 150 fluvi-core tests, no skipped tests. Exact-source LIGHT/FULL pressure and ownership/rotation tests PASS: [45517059580](https://github.com/elizerpist/exptv2/actions/runs/45517059580), four selected methods; this does not finish T6 persistence, OFF overhead or all required reports. Structural R40/R41 guards, Fluvi boundaries, lower-environment self-check and 14 analyzer checks passed. Flutter fast/boundary checks and `analyze --no-fatal-infos` passed on the unchanged Dart source; stricter `analyze --no-pub` separately returned 1 for 22 existing informational notices.
- A real warm non-DIRECT service observation passed its narrow identity/post test: [45517059075](https://github.com/elizerpist/exptv2/actions/runs/45517059075), request 40, show 5, attachment/generation 2/2. Recorded wake callback to candidate call 770.019 ms; candidate to first-post callback receipt 942.884 ms. Its preflight also handled a known launcher ANR. These are not equivalent fallback permission, physical pixels or a handset measurement.
- DIRECT visual/unlock on candidate was NOT REACHED: [45513007368](https://github.com/elizerpist/exptv2/actions/runs/45513007368), [45514821932](https://github.com/elizerpist/exptv2/actions/runs/45514821932), [45516735773](https://github.com/elizerpist/exptv2/actions/runs/45516735773), [45518634223](https://github.com/elizerpist/exptv2/actions/runs/45518634223). The prepared-route fixture also found no prepared DIRECT route on R40 [45516736048](https://github.com/elizerpist/exptv2/actions/runs/45516736048). A separate warmed-platform R40 trial reached DIRECT but failed the immediate calibrated FULL crop [45518634166](https://github.com/elizerpist/exptv2/actions/runs/45518634166). These are not evidence of a new R41 privacy regression or a candidate visual PASS. R21 held-ACK controls [45515012713](https://github.com/elizerpist/exptv2/actions/runs/45515012713) did not reach real DIRECT acknowledgement.
- R40 and candidate natural 20-attempt exercises: [45518855827](https://github.com/elizerpist/exptv2/actions/runs/45518855827) and [45518855894](https://github.com/elizerpist/exptv2/actions/runs/45518855894), respectively. Harness `e116b3b9234f391c6142e0d4fb7b17073c2f5b1c`; Android API 35 x86_64 Pixel 7 emulator, **debug**, LIGHT, synthetic data. The observer waits for a new attachment/generation, yet a worker canvas post can still precede actual presentation. The R40 preflight was `CLEAN_NO_RESET`; the R41 preflight found a launcher ANR and the existing preparation script closed its dialog and returned HOME (`PREPARED_KNOWN_LAUNCHER_ANR`). The runners were therefore not identically clean; do not attribute their timing difference to the application. Both jobs completing means all test loops executed; it does not mean the latency, motion, privacy or pixel gates passed. Earlier runs [45517471362](https://github.com/elizerpist/exptv2/actions/runs/45517471362) and [45517471499](https://github.com/elizerpist/exptv2/actions/runs/45517471499) are retained, but their observer could accept a preceding owner's post.
- The candidate's first trial had no new qualifying producer callback within 7 seconds, with 9 omitted request records and no established grant. Of 19 other recorded matching DIRECT grant/ack pairs, 18 were at or above 300 ms from the bound wake callback. The per-attempt coverage is incomplete, the capture can end before later cancellation, and the earliest actual causal callback and optical pixel are not proven. These rows cannot qualify the user’s Nothing A142 or establish a valid population comparison.

## Candidate per-attempt observations

The table uses milliseconds. `wake → offer` is the bound callback to the winning request offer on SUCCESS rows, or to the first retained read on other rows; it can contain other reads or waits and is not a single queue or CPU cost. `dispatch → Main` is a call-to-runnable bracket, not proven Looper wait. Missing or incomplete is not zero. All rows are **INCOMPLETE**, and no physical pixel is observed. Trials 6 and 7 each recorded two separate attempts; neither is discarded. Full synthetic timing rows and capture SHA-256 values are in [the candidate CSV](R41_NATURAL_CANDIDATE_2026-11-25.csv). [R40 control CSV](R41_NATURAL_R40_CONTROL_2026-11-25.csv) uses its first DIRECT grant and uptime milliseconds; it is not an equivalent effective-winner endpoint.

| Trial / attempt | Eligibility / outcome | Wake → offer | Offer → worker | Read | Dispatch → Main | Main → grant | Bound wake → recorded grant | Loss |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 / 1 | true / UNOBSERVED | 23.595 | 96.895 | 455.743 | 1713.445 | — | — | 9 |
| 2 / 1 | true / SUCCESS | 1051.177 | 83.540 | 19.877 | 5.761 | 27.157 | 1187.745 | 0 |
| 3 / 1 | true / SUCCESS | 763.980 | 3.962 | 93.858 | 0.179 | 27.666 | 889.832 | 0 |
| 4 / 1 | true / SUCCESS | 280.769 | 2.314 | 25.743 | 36.135 | 13.955 | 359.077 | 0 |
| 5 / 1 | true / SUCCESS | 1019.402 | 3.534 | 60.977 | 0.163 | 4.470 | 1088.737 | 0 |
| 6 / 1 | true / UNOBSERVED | 21.069 | 0.234 | 46.476 | 29.361 | — | — | 0 |
| 6 / 2 | true / SUCCESS | 590.988 | 17.791 | 20.442 | 0.170 | 37.524 | 670.874 | 0 |
| 7 / 1 | UNOBSERVED / UNOBSERVED | 0.805 | 4.770 | 801.179 | 886.799 | — | — | 0 |
| 7 / 2 | true / SUCCESS | 149.379 | 0.099 | 7.471 | 2.334 | 0.464 | 159.900 | 0 |
| 8 / 1 | true / SUCCESS | 632.412 | 6.575 | 10.515 | 0.114 | 3.220 | 652.949 | 0 |
| 9 / 1 | true / SUCCESS | 499.235 | 31.367 | 55.283 | 0.184 | 12.236 | 598.443 | 0 |
| 10 / 1 | true / SUCCESS | 964.258 | 3.527 | 7.119 | 0.185 | 2.374 | 977.597 | 0 |
| 11 / 1 | true / SUCCESS | 639.188 | 0.401 | 40.607 | 11.902 | 12.645 | 704.876 | 0 |
| 12 / 1 | true / SUCCESS | 609.691 | 44.868 | 46.056 | 3.456 | 8.369 | 712.655 | 0 |
| 13 / 1 | true / SUCCESS | 613.911 | 36.110 | 26.836 | 8.855 | 3.198 | 689.073 | 0 |
| 14 / 1 | true / SUCCESS | 919.469 | 6.189 | 21.558 | 0.243 | 2.337 | 949.949 | 0 |
| 15 / 1 | true / SUCCESS | 430.967 | 41.207 | 25.401 | 0.112 | 7.532 | 505.502 | 0 |
| 16 / 1 | true / SUCCESS | 1115.896 | 6.953 | 33.456 | 174.880 | 6.444 | 1337.916 | 0 |
| 17 / 1 | true / SUCCESS | 586.263 | 52.053 | 392.283 | 6.022 | 9.960 | 1046.770 | 0 |
| 18 / 1 | true / SUCCESS | 36.405 | 9.988 | 175.216 | 176.826 | 43.691 | 454.024 | 0 |
| 19 / 1 | true / SUCCESS | 768.056 | 20.078 | 15.176 | 0.213 | 0.650 | 804.336 | 0 |
| 20 / 1 | true / SUCCESS | 754.235 | 15.651 | 391.222 | 0.249 | 19.147 | 1180.871 | 0 |

In trial 16, the retained bound wake-to-grant observation was 1,337.916 ms. The winning request 109 was offered 1,115.896 ms after the bound wake, spent 33.456 ms in its recorded read, 174.880 ms between dispatch call and Main entry, and 6.444 ms from Main entry to recorded grant. Earlier request 106 had an approximately 92.200 ms read and a 464.422 ms dispatch-to-Main bracket; request 108 had an approximately 478.520 ms read. These are nested or potentially overlapping observations inside the larger interval; do **not** add them. Android/IPC/scheduling causes and the earliest causal callback are not established.

## Source graph and delivery status

[Dart SCIP graph at commit 1635b6d6](https://github.com/elizerpist/exptv2/tree/1635b6d689aa98cc265015bf80ab6ed8baa4bfb6/docs/codegraph) indexes the exact application source. It has 809 documents, 20,271 repository symbols and 102 verified shards; index SHA-256 `870f84e9d8451ba8a25cbb19e43dca08d1b216943948c7a1088b83617ab5b7aa` and manifest SHA-256 `8d1344335ba7a35beabf08e6def838ad9283ceb53d280ea6118a3655ac290896`. Kotlin is not SCIP-covered; see the [separate source inventory](https://github.com/elizerpist/exptv2/blob/587a6e84dba2099b225442dc6be6a38898df4ab4/docs/codegraph-r41-native-inventory.md).

Full normal/native qualification is NOT RUN; W-SHOW, W-HIDE and W-LOCK-ANIM are NOT QUALIFIED, and W-HOME is not fully requalified by a Dart boundary test. H2 and complete per-wake attribution remain unfinished. A private exact-source profile build was started independently; its result and any later delivery must be recorded separately. An update-signed R41 binary has not been installed over actual R40 and no R41 APK has been published. The original R40 signer is `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`; checking that key locally does not establish update compatibility. PHYSICAL VALIDATION — PENDING, USER ONLY.
