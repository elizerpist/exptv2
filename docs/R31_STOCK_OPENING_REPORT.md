# R31 stock opening — diagnostic delivery and qualification

## Owner diagnostic APK

[Direct HUMAN_DIAGNOSTIC profile APK (120,805,687 bytes)](https://media.githubusercontent.com/media/elizerpist/exptv2/ef914a4ea1723b20f0d3338640b51cf781269037/fluvi_R31_HUMAN_5b18235f261d.apk)

- Application SHA: `5b18235f261df24dcee06cf3050e3e20411612fa` on `implement/r31-stock-opening`; intermediate runtime implementation `a2fe31f29d369683983310e24548f664989ee842`; phone-tested, previously preferred production parent `de807259cd370d18e422772ed0943b8d65be4bca`.
- SHA-256: `5137dcf2499b42d5e6841a6d3c55273e46d7148ff9e8772ce791dfb8984ac1ae`; package `com.fluvi.app`; profile `HUMAN_DIAGNOSTIC`. Test signer certificate `CN=Android Debug`; certificate SHA-256: `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb` (v2 and v3 verified).
- The complete file was downloaded without authentication from that exact immutable URL: HTTP 200, byte count and digest above, equal to the locally verified signed bytes. All 471 non-signature ZIP entries match the exact-source builder APK. Source and purpose markers were checked in all packaged AOT ABIs; R31 markers were found in DEX. ZIP integrity and alignment were verified.
- Exact-source [builder run 45152233603](https://github.com/elizerpist/exptv2/actions/runs/45152233603), artifact `14806673842`; pinned builder source `200aaebd1eaa79382feb977ba57996b0c72e2d28`. [API35 update-install run 45153683948](https://github.com/elizerpist/pushparserv2/actions/runs/45153683948), artifact `14808216032`: install `-r` over the actual signed R30 `93248d0aeee4ebc69d305020e7d5b2d5bdbbdb2a` APK succeeded and the demo-data sentinel survived.
- This is an **experimental owner diagnostic**, authorized for demo data only. The existing R22.4 visual privacy failure and R27 shade ambiguity remain open; the R31 shade and visible-unlock controls below did not qualify. Delivery does not imply privacy, performance, physical, or production acceptance. The earlier `a2fe31f...` diagnostic link is superseded by this `5b18235...` file.

## Scope, ownership and material limits

[Application diff from the phone-tested milestone](https://github.com/elizerpist/exptv2/compare/de807259cd370d18e422772ed0943b8d65be4bca...5b18235f261df24dcee06cf3050e3e20411612fa).

The single reader may, once after A→B, transfer from an obsolete B to the actual latest eligible pending C at a returned-child boundary. Restrictive evidence from that child is consumed first; C must perform a fresh complete authorized read. Queue ownership is identity-bound through unwind and cancellation; no C→D transfer is introduced. The application base retains de807259's API35 root=4 and accepted child=36 prefetch arguments and its withdrawal order. Capture-qualified compact evidence records the follow-on without selecting eligibility. The final small child `5b18235...` additionally prevents diagnostic child counting after a capture cut. No claim is made that this change improves the owner's physical latency.

The requested `project_sources` mount was absent. The three supplied portable rule texts were read from accessible copies and their required SHA-256 digests verified. The pinned handoff, the relevant R30 report and historical sections were read. The shared journal was available in full (17,803 lines); relevant sections were inspected, but the entire historical journal was not semantically reviewed. This is an incomplete preflight item, not a claim of complete review. Kotlin graph coverage is manual source navigation, not SCIP coverage.

## Newly recorded handset observations: preliminary APK only

The concurrently appended coordination journal at `f73b33ecb3f2a760bd940edabb2343a13c6bbed6` records capture `430abd6a-7379-4297-81f1-3c2e62121299` on the **preliminary** `a2fe31f29d369683983310e24548f664989ee842` APK, not on the final `5b18235...` APK delivered above. The owner has not ranked or accepted that preliminary build against the milestone. The same journal preserves the owner's design question and a separate review-only dispatch evidence task; no new production refactor was selected here.

| Detailed attempt | App wake callback → accepted proof ms | Worker enter → first post ms (nanoseconds clock) | Wake callback → native reveal return ms | Restriction event timestamp → callback ms | Callback → seal / seal → native retire return ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 501 | 8.150 | 542 | 114 | 34 / 5 |
| 5 | 220 | 3.137 | 236 | 103 | 20 / 1 |
| 6 | 413 | 5.572 | 434 | 156 | 17 / 1 |
| 7 | 440 | 2.964 | 462 | 133 | 20 / 1 |

All four detailed routes were DIRECT; seven aggregate openings were recorded. The LIGHT export retained 244 of 1,293 events, with 808 evicted, 241 diagnostic drops and 66 omitted evidence records. Three detailed rows, physical stimulus, eligible/restrictive system frame and actual first/last pixel are missing. B recorded `inventory` rejections on attempts 1 and 6; attempt 7's B handed off to C=128, but C became stale and request 131 supplied the accepted proof. These observations neither establish an optical duration nor prove a recoverable amount. The complete bounded account is in the preserved coordination journal.

## Real reader and service controls

| Boundary | Source, status, evidence |
| --- | --- |
| Baseline, controlled AMBIGUOUS | **RED observed** using unchanged de807259 production and test-only `0eb42939df9d73c1823b4eb317edb202088133aa`: A=1, B=18, C=19. A real SystemUI root and a returned child existed; C was the actual pending offer. B made 11 further child acquisitions, completed `SHOW_FULL/MAIN_CONFIRMED`, then was rejected `SCENE_CHANGED`; C eventually revealed. B→C expectation failed at that boundary. The test gate deliberately held the reader, so the timestamps do not measure speed. [Private run 45148056075](https://github.com/elizerpist/pushparserv2/actions/runs/45148056075), device job `137608105130` (3m49s), artifact `14804649653`, ZIP SHA-256 `7470add9b0b44c51e9c8817494ac8794608600f9ae1e7dcbf772eac7e8a1d9b6`. |
| Baseline, controlled SYSTEM_UI | **NOT REACHED**: locked/sleep setup timed out before the required opening boundary. Same run, retained separately. |
| Candidate, controlled SYSTEM_UI | On preliminary application `a2fe31f...`, A=1, B=34, C=35. B made zero further child acquisitions after C, C produced a fresh complete `SHOW_FULL` and DIRECT consumed proof 35. A/B/A calibrated reference crops matched. **Overall visual test FAIL / NOT REACHED:** no real shade ingress was obtained afterward. |
| Candidate, controlled AMBIGUOUS | On `a2fe31f...`, A=1, B=26, C=27. B made zero further child acquisitions after C, C produced fresh complete `SHOW_FULL` and DIRECT consumed proof 27; A/B/A reference crops matched. The later withdrawal assertion timed out. The retained full screenshots show the normal lockscreen without an expanded shade, so the fixture's marker alone does not establish a true shade transition or an application privacy regression. **Shade qualification remains unresolved.** |
| Restrictive returned child | **NOT REACHED on actual service:** A ended `HIDDEN_UNKNOWN/WALK_TRUNCATED` before the intended held B child. Reader unit tests separately cover returned shade/exclusion before transfer, null child and wrong root; they do not substitute for this service observation. |
| Stable B, visible FULL unlock and rapid relock | **NOT REACHED on actual service:** stable case did not obtain the required clean pending setup; visible-unlock case did not obtain acknowledged DIRECT FULL. No visual fast-withdrawal claim can be made. |
| Diagnostics LIGHT and FULL | **PASS** for bounded pressure/export in both the preliminary run and the final-production-code test-only observer run detailed below. |

For both preliminary positive controls and the final AMBIGUOUS structural control, the calibrated crop was `Rect(456,1905–624,2073)` with transparent exterior intact. Initial A matched its reference on sample 0. After switching to B, sample 0 differed by 15,648 pixels (total component delta 761,123; max 61) and sample 1 matched exactly. After return to A, sample 0 had the same difference and sample 1 matched. These retained transitional samples do not prove a physical presentation deadline or uninterrupted privacy.

The controlled boundaries and final authorized reveal below are app `uptimeMs`; different rows are different held runs and cannot be used as a paired performance claim. `B end` is completion or unwind, as labeled. The callback and reader may be deliberately held by the fixture.

| Run | B start | C offered | B end | C fresh read start / end | Final DIRECT reveal return |
| --- | ---: | ---: | ---: | --- | ---: |
| Baseline AMBIGUOUS | 118918 | 118933 | 118953 (complete) | 118991 / 119022 | 119263, proof 19 |
| Preliminary SYSTEM_UI | 97862 | 97866 | 97867 (yield) | 97867 / 97873 | 97908, proof 35 |
| Preliminary AMBIGUOUS | 154186 | 154189 | 154190 (yield) | 154191 / 154196 | 154229, proof 27 |
| Final-code AMBIGUOUS | 129177 | 129184 | 129186 (yield) | 129186 / 129195 | 129252, proof 27 |

Preliminary candidate [private run 45149778389](https://github.com/elizerpist/pushparserv2/actions/runs/45149778389), device job `137613192170` (8m20s), artifact `14806393012`, ZIP SHA-256 `0d544e9181d56df82518957792a1323cc25a9c2083c2d2fe7ba4b156ac705102`, contains all of these attempts, including partial frames. The unchanged failed shade, stable and unlock boundaries were not repeatedly run to obtain a green result. The independent final structural-only test does not execute or qualify shade withdrawal.

**Final production-code structural-only run:** [private run 45154884365](https://github.com/elizerpist/pushparserv2/actions/runs/45154884365), device job `137631097935` (5m04s), overall **FAIL**; artifact `14808812010`, ZIP SHA-256 `9b33071cc3a3b2a68ae7f4f34f60d3dd4ab6ee255ba3b53e51d930e3e85d9335`. Its observer-only test SHA `52c8532954b6bb35d6a42452557711dc065be1d5` changes only two `androidTest` files; the entire `android/app/src/main` production tree equals `5b18235...`. Harness `cdb2cec93a59fb490d0b33c176c1485b7bd15255`. This is a debug test pair and not the shipped profile binary.

- **AMBIGUOUS PASS** as a controlled structural and A/B/A crop observation: A=1, B=26, actual pending C=27; B made zero subsequent child acquisitions, C completed `SHOW_FULL/MAIN_CONFIRMED`, proof 27 was accepted and DIRECT returned at 129252 uptime ms. The report explicitly records `STRUCTURAL_A_B_A_ONLY_SHADE_NOT_RUN`. The visual transition samples above were retained.
- **SYSTEM_UI NOT REACHED / test FAIL**: reference calibration completed but `sleep/locked timed out` before the service opening boundary. No inference about B→C, shade or unlock is available from that attempt. The distinct preliminary SYSTEM_UI positive boundary remains documented above.
- **LIGHT PASS and FULL PASS** for the two capture pressure/export tests. An in-flight capture-freeze service scenario remains unrun. All original full shade/negative assertions remain in their original tests and were not silently weakened. The structural-only observer is a separate test.


## Unheld profile comparison and endpoints

One private A/B/B/A run used the signed milestone as A and the preliminary `a2fe31f...` signed diagnostic as B. It retained all 12 cold/warm trials. **0/12 reached acknowledged DIRECT**, ten produced a `SURFACE_LIVE` fallback and two had no observed winner. Consequently there is no matched DIRECT speed or visible FULL withdrawal comparison. The loaded emulator, differing scene outcomes, and app-uptime timestamps cannot establish physical phone latency. [Private run 45151096822](https://github.com/elizerpist/pushparserv2/actions/runs/45151096822), job `137612397395` (10m27s), artifact `14807052153`, ZIP SHA-256 `020208a8a3c4f4025479a4b74e3b4d00d021c66c6b64455dd7a9be892302c0b5`.

`wake → winning fallback post / first distinct submitted motion`, milliseconds in app uptime (`—` means unobserved):

| Block | Cold | Warm 1 | Warm 2 |
| --- | --- | --- | --- |
| A1 milestone | 11766 / 12217 | 5483 / 6848 | 3789 / 5979 |
| B1 preliminary R31 | 9951 / 9979 | — / — | 6662 / 7065 |
| B2 preliminary R31 | 10620 / 11109 | — / — | 8362 / 8383 |
| A2 milestone | 9209 / 9709 | 5639 / 6040 | 9786 / 10266 |

The retained raw rows include first reader classifications, request IDs, proof and winner. Fallbacks are not pooled with native DIRECT reveal. Bitmap hit/miss, common matched DIRECT cadence, physical first eligible lockscreen frame, actual first FULL pixel and actual last visible pixel were not established. The three physical ≤10 ms endpoints remain open.

## Other validation

| Check | Result on final application source `5b18235...` |
| --- | --- |
| `git diff --check`; `bash scripts/verify-fluvi-boundaries.sh` | **PASS**. |
| Gradle generated material, compile Debug/AndroidTest, focused opening/reader/queue tests | **PASS**, 1m44s. Saved XML lists 8 R31 handoff, 17 reader, 10 existing opening, 7 post-claim, 27 queue and 9 first-authorized tests, with zero failures. |
| `:app:assembleDebug :app:assembleDebugAndroidTest :app:testDebugUnitTest :fluvi-core:testDebugUnitTest` | **PASS**, 1m57s; 341 app and 150 core JVM tests, no failures or skips. |
| `flutter analyze --no-fatal-infos` | **PASS**, 22 informational findings. |
| `flutter test --reporter expanded` | **FAIL**, 2,780 passed, 115 failed, 3 skipped, 8m06s. All 115 failing test names also appear in the retained R30 run; matching names alone do not prove identical causes. |
| Final-source freeze while child work is in flight | **NOT RUN** as an independently staged service scenario; the guard compiles and focused tests pass, but do not prove this lifecycle. |
| Ordinary public `fluvi-core.yml` | **NOT RUN**: changed-path visual safety entry conditions were not met. |
| `native_scope=r12_live` | **NOT RUN**, same entry condition. |
| `native_scope=r12_static` | **NOT RUN**, same entry condition. |
| `native_scope=r12_legacy` | **NOT RUN**, same entry condition. |
| `native_scope=r12_contract` | **NOT RUN**, same entry condition. |
| `native_scope=full` | **NOT RUN**, same entry condition. |

The first baseline compile attempt failed on a stale copied Flutter plugin registrant (`IntegrationTestPlugin` missing); `flutter pub get` repaired the fixture before the retained RED run. The first candidate focused compile failed on an unresolved test `capture` variable; the test wiring was corrected and rerun successfully. A temporary copied Gradle cache exhausted the isolated RAM filesystem; its own partial copy was removed and the pre-existing cache reused. These are retained failures, not RED evidence about behavior. The local host had no provisioned API35 emulator/KVM; private KVM runner evidence is identified above. Raw log and screenshots remain [access-controlled](https://github.com/elizerpist/pushparserv2/tree/fd14b01a8387b560999f006b3d6c99d202ce3103/evidence/r31-a2fe31f29d36). Existing private artifacts remain available.

## Exact-source graph

[Tooling commit `381000eb52b5d3729134b4df3f33abb5f78c56bd`](https://github.com/elizerpist/exptv2/tree/381000eb52b5d3729134b4df3f33abb5f78c56bd/docs/codegraph), [native inventory](https://github.com/elizerpist/exptv2/blob/381000eb52b5d3729134b4df3f33abb5f78c56bd/docs/codegraph-r31-stock-inventory.md), [graph run 45152232319](https://github.com/elizerpist/exptv2/actions/runs/45152232319), artifact `14806452610`. Manifest source head/ref `5b18235f261df24dcee06cf3050e3e20411612fa`, manifest SHA-256 `c2e723b8fac6b6f60baf90c358d96fe4bd1a6681c15c6132d18fe7058ce0c0f1`; SCIP Dart 1.6.2 index SHA-256 `870f84e9d8451ba8a25cbb19e43dca08d1b216943948c7a1088b83617ab5b7aa`, 809 documents, 20,271 repository symbols, 136,479 references, 42,258 edges. Manifest and all 102 shard hashes/counts were checked. Kotlin call paths are source-inventoried separately.

## Reviewer handback and owner acceptance

Return the unqualified shade-marker fixture and missing restrictive/visible-unlock boundaries to the reviewer with the private raw images and logs. No runtime repair hypothesis or privacy relaxation was inferred from those missing preconditions. Physical wake, eligible frame and restriction/removal require actual independent measurement. **PHYSICAL VALIDATION — PENDING, USER ONLY.**

Owner test card (Hungarian):

1. A demoadatokkal használt Nothing A142 készülékre telepítsd az APK-t, és a Fluvi diagnosztikai konzoljában ellenőrizd a `5b18235f261df24dcee06cf3050e3e20411612fa` buildet. Maradjon azonos az ORB/orbOnly/full, a színpaletta, a szolgáltatás és a kijelző beállítása.
2. Indíts FULL rögzítést, majd végezz négy zárolás–ébresztés–feloldás ciklust. Feloldás előtt várd meg a látható teljes ORB-ot; ha valamelyik próbában ez nem történik meg, külön jegyezd fel. A végén azonnal fagyaszd és exportáld a konzol szövegét.
3. Próbánként külön írd le a késői megjelenést, a látható animációt, a feloldás utáni bent maradást, valamint a villanást vagy régi részletes tartalmat. Az értesítési sáv ismert adatvédelmi kockázata miatt csak demoadatot használj. A konzol időbélyege önmagában nem fizikai képpontmérés.
4. Ha az animáció látható állapotban akadozik, külön 60 másodperces próbát is végezhetsz; azonos beállítású LIGHT kontroll külön sorozat legyen. A konzolszöveg és a megfigyeléseid ADB vagy videó nélkül visszaküldhetők.
