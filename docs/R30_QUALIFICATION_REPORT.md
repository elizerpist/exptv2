# R30 stock Android ORB — qualification report

Application source: [`93248d0aeee4ebc69d305020e7d5b2d5bdbbdb2a`](https://github.com/elizerpist/exptv2/commit/93248d0aeee4ebc69d305020e7d5b2d5bdbbdb2a), based on phone-tested `de807259cd370d18e422772ed0943b8d65be4bca`; branch `implement/r30-stock-orb-transitions`. The owner accepted improved perceived opening on the baseline but still reported slow unlock withdrawal. This report does not treat an app callback as a physical pixel.

The [HUMAN_DIAGNOSTIC profile APK](https://media.githubusercontent.com/media/elizerpist/exptv2/f573e70d3f627a7d75f8dd8afcd6112c2eb4a12e/fluvi_R30_HUMAN_93248d0aeee4.apk) is 120805687 bytes, SHA-256 `2bf9b6685f86fb7336f21027ffbc37f5382c9dec93eb80035370e4f18eb01e66`, signer SHA-256 `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`. Anonymous full GET: HTTP 200 and identical bytes; v2 and v3 signatures verified. The application SHA and HUMAN_DIAGNOSTIC purpose were found in all three ABI AOT libraries; non-signature payload entries matched the original runner APK. Builder [45132491904](https://github.com/elizerpist/exptv2/actions/runs/45132491904), job 137550955412, artifact 14799110404. Private [update run 45133535652](https://github.com/elizerpist/pushparserv2/actions/runs/45133535652) installed the actual signed de807259 baseline and then used `adb install -r` for the candidate; a demo-data sentinel remained. This is an owner demo-data-only build; the earlier R22.4 visual privacy FAIL and R27 shade ambiguity remain open.

The application change uses interruptible hybrid child prefetch only for the accepted primary SystemUI root of the revalidated original virgin DIRECT opening. It preserves the tree walk and normal fallback. A completed, attributable and current NO_MAIN_MARKER read can seal only the exact captured PRESENTED DIRECT owner before the second system sample; final sampling and Main cleanup remain, and an old receipt cannot act on a replacement. Bounded capture fields record the classification, second sample and seal/retire request. The untouched `lib/` and `test/` trees are identical to the baseline.

## Automated checks

| Check | Result | Evidence or limit |
| --- | --- | --- |
| `git diff --check`; `bash scripts/verify-fluvi-boundaries.sh` | PASS | Local source. |
| `:app:generateKeyguardHeaderMaterial :app:compileDebugKotlin :app:compileDebugAndroidTestKotlin` | PASS | JDK 17, Flutter 3.41.4; local API35 device and KVM unavailable. |
| Focused acquisition, reader, coordinator, virgin-route and R30 JVM suites | PASS | 38 tests, 0 failures or skips. |
| `:app:assembleDebug :app:assembleDebugAndroidTest :app:testDebugUnitTest :fluvi-core:testDebugUnitTest` | PASS after infrastructure retry | App 331/331 and core 150/150. The initial invocation failed at `:app:mergeLibDexDebug` because the local filesystem was full; both transcripts are retained. |
| `flutter analyze --no-fatal-infos` | PASS | 22 informational findings. |
| `flutter test --reporter expanded` | FAIL | 2780 passed, 115 failed, 3 skipped. The exact 115 names, complete log and generated images are private evidence. Earlier equal counts do not establish identical causes. |
| LIGHT/FULL compact evidence pressure | PASS | Candidate private run 45132490897. |
| Candidate stock-held, warm canonical, no-ready cold controls | PASS | Candidate private run 45132490897, one each. |
| Initial original-opening control | NOT REACHED | Baseline private run 45132451578: original A returned ROOT_UNAVAILABLE. Candidate run 45132490897: original A returned FOREIGN_ABOVE with a truncated tree; no eligible child observation. |
| Corrected original-opening control | PASS, gated | Baseline private run 45134570200 (production files unchanged from de807259, test-only SHA `550cdf25913605942feee24c4096407cf16389a8`) observed actual child flags 36. Candidate run 45134704622 observed 4. Both used root flags 4, 12 actual child calls and a current complete SHOW_FULL/MAIN_CONFIRMED result. Original A was held until an independent complete SystemUI tree existed; the inherited `NATURAL_UNHELD` text in the fixture log is inaccurate. This is ordering evidence, not a performance comparison. |
| Initial visible-DIRECT withdrawal | NOT REACHED | Baseline run 45134151540 and candidate run 45134152733: no acknowledged visible DIRECT owner after an incomplete FOREIGN_ABOVE read and fallback. |
| Candidate visible-unlock and opening positive/negative controls | NOT REACHED | In run 45132490897 all three timed out establishing locked sleep. |
| Corrected visible-DIRECT withdrawal | NOT REACHED | Baseline run 45136036401 and candidate run 45136599181 did not establish launcher focus after reference calibration. No real NO_MAIN_MARKER withdrawal or same-owner replacement was reached. The sole corrected repeat per arm was retained. |
| Initial unheld signed-profile A/B/B/A | FAIL, harness | Run 45135743248: each block failed before any trial because debug test code requested the variant-mangled `serviceForInstrumentation$app_debug` method from a profile APK. The signed APKs themselves installed. |
| Corrected unheld signed-profile A/B/B/A | FAIL / INCOMPLETE | Run 45136704345 attempted all 12 trials; only B1 warm1 reached an acknowledged DIRECT owner, so there is no matched comparison or supported speed conclusion. The one corrected repeat is retained. |
| Real shade and credential visual protection; held same-owner negative, replacement and duplicate controls | NOT ESTABLISHED | JVM classification guards pass. Initial and corrected real-service fixtures did not reach all required boundaries; prior R22.4 FAIL and R27 shade ambiguity remain open. |
| Normal public CI plus five native scopes | NOT RUN | Required changed-path and visual fixture prerequisites were not met; no result is inferred. |

Private raw logs, all 12 captures, images, reproducible crop comparison and failure list: [evidence commit `387f201`](https://github.com/elizerpist/pushparserv2/tree/387f2012c86b61f51ed3e2027b103cbc0db3a4c6/evidence/r30-93248d0a). No private screenshot, trace or financial data is published in this report.

## Unheld profile trials

The four blocks used the actual signed profile APKs and the same emulator, with no held reader. Each block attempted one cold and two warm cycles while keeping its service instance alive; all twelve capture reports were retained. NR means the test did not reach an acknowledged DIRECT owner within its limit.

| Block | Cold | Warm 1 | Warm 2 |
| --- | --- | --- | --- |
| A1 — baseline | NR | NR | NR |
| B1 — candidate | NR | DIRECT owner reached | NR |
| B2 — candidate | NR | NR | NR |
| A2 — baseline | NR | NR | NR |

In B1 warm 1 the recorded DIRECT owner was reservation 2, host 2, output generation 3, attachment 2, child 69768227. The app wake callback was uptime 210454, proof 31 was accepted at 215658 and reveal returned at 216419: 5204 ms and 5965 ms respectively, on this loaded emulator only. The original opening 27 was truncated by a child-acquisition exception and used child flags 36; the reason it did not take the R30-qualified opening path is not established by this capture. It is not a successful unheld exercise of the 36→4 change. A later system-sample withdrawal sealed at 243542 and native retirement returned at 243558 (16 ms). Local hide was 243542 and remove returned 247359. Physical display times are UNOBSERVED.

Six screenshots were retained. The inner circle of samples 1 and 4 exactly matched a prior A/C/B/A controlled reference for the same shader and palette; sample 5 was within the existing near-equality threshold. The reference was produced in a different run and the transparent exterior was not assessed. Sample 1 acquisition spanned uptime 221983–223158, so it cannot timestamp the first correct pixel. The only post-unlock screenshot spans 243115–246547 and overlaps seal and retirement; without a same-scene underlay it is UNCLASSIFIED and cannot prove complete disappearance or its timing. All other trials remain NR; do not calculate medians or compare these unmatched rows to the phone.

## Baseline handset evidence

The owner's LIGHT capture on `de807259` contained four comparable attempts. App wake to accepted paint proof was 324/357/325/288 ms; wake to reveal return was 356/407/342/320 ms. Restrictive event to app callback was 127/9/83/98 ms, callback to seal 18/19/11/9 ms, and seal to native-retire return 4/1/2/3 ms. These are separate app uptime intervals. System.nanoTime worker spans and physical wake/display/last-pixel timestamps are different or unobserved clocks. No calibrated candidate phone comparison exists.

## Graph and acceptance

[Exact-source graph commit `cad4b763bbb7acf30b087d35143c0d08238c19ed`](https://github.com/elizerpist/exptv2/tree/cad4b763bbb7acf30b087d35143c0d08238c19ed/docs/codegraph); [Kotlin source inventory](https://github.com/elizerpist/exptv2/blob/cad4b763bbb7acf30b087d35143c0d08238c19ed/docs/codegraph-r30-stock-inventory.md). Manifest SHA-256 `8aad08d39d800fd19cb141d55d33ee2ca9bea3846e04df8ca2d0a74911b2151c`; index SHA-256 `870f84e9d8451ba8a25cbb19e43dca08d1b216943948c7a1088b83617ab5b7aa`. SCIP-Dart 1.6.2 indexes 809 documents, 20271 repository symbols, 136479 references and 42258 edges. Kotlin entries are manually located source, not SCIP call edges. Graph run 45132819546 PASS.

The app build, automated safety qualification, owner APK delivery and physical acceptance are independent: the owner APK is delivered and update-install verified; automated qualification remains incomplete. Each of the three physical ≤10 ms endpoints is PENDING — USER ONLY. Real shade/credential visual protection and full formal native scope qualification are not established by the current successful JVM and gated-opening tests.
