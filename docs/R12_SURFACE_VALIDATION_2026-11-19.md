# Fluvi R12 continuation — working review report

Application candidate: `9495b1144bb5400efcdb95ec3a8be2adc6e0b21a`; production implementation commit `e664bf88b74cd99b56397b5d8698205764ad5d18`. Prior physically tested R11 app: `1d19624751169e3af0270b151378cdfcdf1a1129`. Only the R11 build has phone feedback. R12 physical acceptance is pending and belongs to the user.

The existing detached-negative admission queue was extended to allow a single compatible B read behind a completed, complete `NO_MAIN_MARKER` A while retaining ordered Main application and current permission checks. Eligible standalone animated ORB now selects a worker-owned SurfaceView by default. Its target is revoked on hide and uses the canonical scene/shader and bounded poster cache; legacy R11 and a non-animated surface remain diagnostic choices. Diagnostics expose route, holder, first post and bounded cadence without claiming those are physical pixels.

## Stock admission comparator

Run [44622939899](https://github.com/elizerpist/exptv2/actions/runs/44622939899), job 135909141734, [artifact 14579260873](https://github.com/elizerpist/exptv2/actions/runs/44622939899/artifacts/14579260873): valid expected RED, not an infrastructure or fixture failure. Stock production SHA `1d19624751169e3af0270b151378cdfcdf1a1129`; test harness SHA `9881f4a0c331a7ee5286505c095339f784e91497`. A=32: actual decision `HIDDEN_UNKNOWN`, reason `NO_MAIN_MARKER`, root complete, not stale; authority session/wake/visibility/interaction/attach `1/2/1/1/0`. B=34, same authority and freshness revision 5. A Main entry uptime 47134 ms, release signal 50136, A exit 50137, B actual reader entry 50137. The append sequence disambiguates the equal ticks: B entered after the release; B later gave `SHOW_FULL/MAIN_CONFIRMED`. Cleanup passed. Artifact SHA-256 `028de45922c75b27c9c39629ff2cf9e1da90d01314b5468b8f550bc70ee923cc`. The fixture counter covers the selected A/B, not every possible service inspection; the final candidate fixture separately records the service-wide maximum.

Previous baseline attempts are preserved: [44610202004](https://github.com/elizerpist/exptv2/actions/runs/44610202004) lacked the stock Git object before execution; [44612092816](https://github.com/elizerpist/exptv2/actions/runs/44612092816) failed before reaching A application; [44613950007](https://github.com/elizerpist/exptv2/actions/runs/44613950007) selected A=10 but did not retain its actual decision/reason. Neither is a valid product RED. Their evidence is retained under `/workspace/outputs/r12/preflight/`.

## Local validation

- `git diff --check`, `scripts/verify-fluvi-boundaries.sh`, lower-environment controls: PASS.
- Android debug and AndroidTest APK assembly plus app JVM tests: PASS, 174 tests, before final test-only fixture change. The final fixture Kotlin compilation passed separately.
- `:fluvi-core:testDebugUnitTest`: initial FAIL, 105/150, because the sandbox made `/home/agent/.robolectric-download-lock` read-only. Preserved under `/workspace/outputs/r12/preflight/core-unit-failure/`. A rerun with the test JVM's user directory inside the workspace passed 150/150.
- R09/R10/R11 host controls, R12 admission host controls and candidate timing oracle negatives: PASS. Flutter targeted console/bridge/architecture and dashboard boundary suites: 12/12 each PASS. Curated Flutter fast suite: PASS. `flutter analyze --no-fatal-infos`: PASS with 20 informational deprecations.
- No local Android device or `/dev/kvm` exists, so local device runtime tests were NOT RUN. Separate API35 GitHub runs are recorded below when complete.

## Graph

Tooling commit `af0e2160186209852ef0e87d0295af7476c80084`, branch `tooling/orb-r12-surface-9495b114`, [manifest](https://github.com/elizerpist/exptv2/blob/af0e2160186209852ef0e87d0295af7476c80084/docs/codegraph/manifest.json), [native inventory](https://github.com/elizerpist/exptv2/blob/af0e2160186209852ef0e87d0295af7476c80084/docs/codegraph-r12-surface-2026-11-19.md). Source HEAD 9495b114; SCIP-Dart 1.6.2 index SHA-256 `de6258a476c3901ee9e9d3899d35e4e84454a5d0f966ecacc708e1657b9b087c`, manifest SHA-256 `b6f937cb9b0846ed739d69626e8ddb38e320df81d4fd9ba3317804d0c25fcf42`. All 102 shard hashes and counts verified; 808 documents, 20,269 repository symbols, 136,449 references, 42,246 edges. Tooling analyze and 16 tests passed. Kotlin is a manually checked inventory, not SCIP coverage.

## Limits

The current candidate scope collector deliberately fails closed: its timing-only service run and focused panel tests do not establish all independent real-service compositor, lifecycle and privacy requirements. In particular a post or component-surface PixelCopy is not an externally composited pixel. Full native 2×30, normal delivery and physical acceptance cannot be reported as passed merely from these observations. Do not recommend installing a review-only build while privacy/image conditions remain unproven. The raw latest phone capture is not independently available in this workspace; its identified summary is taken from the immutable journal, not reconstructed from missing lines.

## Verified Human profile artifact

**REVIEW ONLY — do not recommend phone installation until the independent privacy and real-service compositor gates have been reviewed.** Source `9495b1144bb5400efcdb95ec3a8be2adc6e0b21a`; Flutter profile, Human diagnostic purpose, 120,312,018 bytes, SHA-256 `ddd0ba07b51297202535c9d0f3b9f869c17435287a56a721d0b67cd2dbb467ee`, Android debug signer SHA-256 `faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb`. [Direct HTTPS APK](https://media.githubusercontent.com/media/elizerpist/exptv2/8333c4dbcf426db2d0e16b78af7fc18a16b0672b/fluvi_HUMAN_DIAGNOSTIC_9495b1144bb5_R12_REVIEW.apk), artifact commit `8333c4dbcf426db2d0e16b78af7fc18a16b0672b`. A clean source build, ZIP test, v2 signature, full source SHA and `HUMAN_DIAGNOSTIC` marker in all three AOT ABIs, native DEX route/diagnostic markers, and an independent unauthenticated re-download with matching bytes and signer were verified. The initial probe incorrectly searched for lower-case `human_diagnostic` in the optimized AOT and failed; the exported marker is upper-case `HUMAN_DIAGNOSTIC`, matching the source mapping and the previous working Human build. `SURFACE_LIVE` is the source default; a clean-install device confirmation has not yet been obtained.

The release was created, but its asset upload returned HTTP 401 from `uploads.github.com`; the separate Git LFS artifact branch provided the verified direct bytes. Source code, graph, documentation and artifact commits remain distinct. APK physical acceptance remains pending, user only.

## Prior candidate CI (all results retained)

All 7c92161c and d616f323 rows below are **overall FAIL** even where an individual control passed. Exact raw ZIPs and logs are under `/workspace/outputs/r12/run-<run>/`.

| Source | Run / artifact | Scope and first observed boundary |
| --- | --- | --- |
| 7c92161c | [44623638285](https://github.com/elizerpist/exptv2/actions/runs/44623638285) / [14578592355](https://github.com/elizerpist/exptv2/actions/runs/44623638285/artifacts/14578592355) | LEGACY: Maven failed to resolve `kotlinx-coroutines-core-jvm:1.6.4` during Gradle tooling compilation. No candidate device test ran. |
| 7c92161c | [44623638440](https://github.com/elizerpist/exptv2/actions/runs/44623638440) / [14579301468](https://github.com/elizerpist/exptv2/actions/runs/44623638440/artifacts/14579301468) | STATIC timing: warm1 and warm3 could not observe the expected locked service window within the bound; independent full visual/privacy controls missing. |
| 7c92161c | [44623638627](https://github.com/elizerpist/exptv2/actions/runs/44623638627) / [14578079264](https://github.com/elizerpist/exptv2/actions/runs/44623638627/artifacts/14578079264) | LIVE timing: warm2 could not observe the locked service window; one separate locked interval advanced from 5 to 50 producer posts over 5 s. These are not physical-frame or phone measurements. |
| 7c92161c | [44623638268](https://github.com/elizerpist/exptv2/actions/runs/44623638268) / [14578348767](https://github.com/elizerpist/exptv2/actions/runs/44623638268/artifacts/14578348767) | Admission PASS for this source only: A=33 `HIDDEN_UNKNOWN/NO_MAIN_MARKER`; B=34 starts at 60446, before A Main entry 60449 and release 60450, A exit 60451, then B `SHOW_FULL` exit 60591. Capture `ab593a33-a288-4910-b44a-db1357eab4df`. Four separately invoked poster, static panel, LIGHT and FULL checks each returned `OK (1 test)`. Full scope deliberately FAIL_INCOMPLETE. |
| d616f323 | [44624107457](https://github.com/elizerpist/exptv2/actions/runs/44624107457) / [14578682204](https://github.com/elizerpist/exptv2/actions/runs/44624107457/artifacts/14578682204) | LEGACY timing: warm1 locked-service window timeout. |
| d616f323 | [44624106843](https://github.com/elizerpist/exptv2/actions/runs/44624106843) / [14579301751](https://github.com/elizerpist/exptv2/actions/runs/44624106843/artifacts/14579301751) | STATIC timing: warm1 and warm3 locked-service window timeout. |
| d616f323 | [44624106895](https://github.com/elizerpist/exptv2/actions/runs/44624106895) / [14578748570](https://github.com/elizerpist/exptv2/actions/runs/44624106895/artifacts/14578748570) | LIVE timing: warm1 and warm3 locked-service window timeout. |
| d616f323 | [44624107248](https://github.com/elizerpist/exptv2/actions/runs/44624107248) / [14579457874](https://github.com/elizerpist/exptv2/actions/runs/44624107248/artifacts/14579457874) | Admission FIXTURE_INVALID: tagged A was offered but never reached Main application, so A/B pair was not established; cleanup PASS. Four independently invoked poster, static panel, LIGHT and FULL checks each returned `OK (1 test)`. Full scope FAIL_INCOMPLETE. |

The 7c producer's `R12_SURFACE.firstPost` was observed on Main delivery and could be later than its `R12_CADENCE.firstPost` worker time. The 9495 source stores these as distinct values. Timed-out experiments were not retried unchanged; the final source uses the repository's synchronized sleep/wake input and public eligibility boundary. The older failure logs cannot establish whether their timeouts were caused by the fixture or the product.

## Final-source API35 evidence

[9495 contract run 44625794490](https://github.com/elizerpist/exptv2/actions/runs/44625794490), job 135919157738, [artifact 14579459283](https://github.com/elizerpist/exptv2/actions/runs/44625794490/artifacts/14579459283), archive SHA-256 `899375fcfab51dbefc68454f27ac9370cb2f9ab4924d85e55e1f4ddf6a17d167`: overall **FAIL_INCOMPLETE**, because the full independent T1–T7 compositor, privacy and lifecycle contract is not established. The operation-correlated admission subtest did PASS on the exact candidate: process 2408, capture `9e0461de-69fd-4960-b37f-f4f0f587e91e`, session/wake/visibility/interaction/attach `1/2/1/1/0`, A=38 `HIDDEN_UNKNOWN/NO_MAIN_MARKER`, complete and nonstale; B=39 `SHOW_FULL/MAIN_CONFIRMED`, same authority and freshness revision 4. In uptime milliseconds B reader started 56067, A Main entered 56068, A released and exited 56068, B Main entered 56080 and exited 56136. Append sequence resolves equal ticks. The service-wide maximum simultaneous inspections was 1 and cleanup passed. These observations establish this mechanism, not physical responsiveness.

On this same contract run the separately invoked hardware poster, static panel, LIGHT and FULL diagnostics each returned `OK (1 test)`. The static panel is not a substitute for the missing independent first-transition and privacy measurements on the actual lockscreen service.

All four final-source jobs completed with **FAIL_INCOMPLETE**, rather than a release pass. Each retained the whole original ZIP and an extracted copy under `/workspace/outputs/r12/run-<run>/`.

| Scope | Run / job / artifact | Actual observation and scope result |
| --- | --- | --- |
| LEGACY_R11 | [44625794358](https://github.com/elizerpist/exptv2/actions/runs/44625794358), job 135919156154, [artifact 14579727008](https://github.com/elizerpist/exptv2/actions/runs/44625794358/artifacts/14579727008); 9m51s | Four-wake timing-only control PASS; overall FAIL_INCOMPLETE because independent visual/compositor/privacy controls are missing. Preflight recognized and cleared a known Launcher3 ANR. ZIP SHA-256 `43a721a8406f118aaf16006eabb68ea2c45e9e97c0c09ff569e5ad3c65055209`. |
| SURFACE_STATIC | [44625794229](https://github.com/elizerpist/exptv2/actions/runs/44625794229), job 135919156691, [artifact 14579741928](https://github.com/elizerpist/exptv2/actions/runs/44625794229/artifacts/14579741928); 10m10s | Four-wake timing-only control PASS; warm1 locked posts stayed 2→2 over 5 s. Overall FAIL_INCOMPLETE: missing independent real-service visual/privacy controls. Preflight clean. ZIP SHA-256 `47251c19e996cf559426b5d320d5db13aa29e7fc3abc295d802ae893c61e7359`. |
| SURFACE_LIVE | [44625797029](https://github.com/elizerpist/exptv2/actions/runs/44625797029), job 135919170558, [artifact 14579459473](https://github.com/elizerpist/exptv2/actions/runs/44625797029/artifacts/14579459473); 10m20s | Four-wake timing-only control PASS; warm1 locked posts advanced 3→49 over 5 s. Overall FAIL_INCOMPLETE: missing independent real-service visual/privacy controls. Preflight recognized and cleared a known Launcher3 ANR. ZIP SHA-256 `f3075232b30a0fbea2fa6ea2e8cb5367f73604aa3eefd780960592f866544398`. |
| Contract | [44625794490](https://github.com/elizerpist/exptv2/actions/runs/44625794490), job 135919157738, [artifact 14579459283](https://github.com/elizerpist/exptv2/actions/runs/44625794490/artifacts/14579459283); 9m11s | Exact-pair admission PASS; poster, panel and two capture methods each `OK (1 test)`; overall FAIL_INCOMPLETE. ZIP SHA-256 `899375fcfab51dbefc68454f27ac9370cb2f9ab4924d85e55e1f4ddf6a17d167`. |

The timing rows below are raw monotonic **uptime milliseconds** from three different fresh emulator processes, FULL diagnostic mode. `attached` is when the fixture observed an attached service, not the `addView` return. The wake input is followed by a synchronized input/idle prerequisite. `firstPost` and `distinct` are producer observations; none is a composited pixel, physical presentation or phone latency. Missing endpoints remain UNOBSERVED. The legacy test did not perform the five-second interval; the separate visual processes and W-HOME comparison were not run.

| Mode / process / capture | Cycle | Wake input | Fixture-observed attached | First post | First distinct post | Dismiss command / fixture-observed detached |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| LEGACY / 2490 / `8e51f06c-f16b-43e8-b178-1e7d6d4f33ec` | cold | 53157 | 58595 | UNOBSERVED | UNOBSERVED | 58908 / 62307 |
| LEGACY | warm1 | 65826 | 68238 | UNOBSERVED | UNOBSERVED | 68248 / 70425 |
| LEGACY | warm2 | 74794 | 77696 | UNOBSERVED | UNOBSERVED | 77731 / 79398 |
| LEGACY | warm3 | 83751 | 86242 | UNOBSERVED | UNOBSERVED | 86352 / 88132 |
| STATIC / 2425 / `f7459fb3-c847-47dc-86f6-65e07ff06138` | cold | 49467 | 55339 | 54850 | UNOBSERVED | 55485 / 57474 |
| STATIC | warm1 | 62882 | 65285 | 65282 | UNOBSERVED | 70535 / 71627 |
| STATIC | warm2 | 76493 | 79669 | 78737 | UNOBSERVED | 79669 / 80687 |
| STATIC | warm3 | 85931 | 88493 | 87601 | UNOBSERVED | 88494 / 90212 |
| LIVE / 2534 / `5f71aba0-9754-4400-b4e6-0833d6e871bc` | cold | 70159 | 74458 | 74728 | 74739 | 75193 / 79995 |
| LIVE | warm1 | 82528 | 84549 | 84523 | 84533 | 89918 / 92145 |
| LIVE | warm2 | 96224 | 98696 | 98340 | 98437 | 99057 / 101024 |
| LIVE | warm3 | 104796 | 106313 | 106306 | 106315 | 106819 / 108604 |

The existing R11 phone capture showed wake-callback-to-CPU-live markers 297/103/144/135 ms and trigger-to-local-hide 11/17/11/35 ms in its retained attempts. The emulator input/producer rows above are different endpoints, hardware and scenes; they are not a numerical before/after comparison. Physical first correct appearance, first moving frame, unlock start and actual removal remain UNOBSERVED. The user's latest feedback is about R11, not this candidate.

## Requirement coverage

| Area | Status and remaining boundary |
| --- | --- |
| R1 / T1 admission | PASS for the one exact stock RED and final-candidate A/B sequence above; additional stale/revoke/latest-C/failure permutations on a real service are not fully established. |
| R2 / T2 real route and first image | PARTIAL: the real service attached the selected surface and emitted producer posts; the panel checks passed. A separately calibrated first-correct composite on the real service is NOT RUN. |
| R3 / T3 holder lifecycle | PARTIAL: local gate tests and visible service cycles ran; all specified destroy/resize/reentry/driver-error races and no-holder-after-destroy proofs are NOT RUN. |
| R4 / T4 material and cadence | PARTIAL: panel poster control and 5-second STATIC/LIVE producer observations ran; independent composited motion and the legacy five-second control are NOT RUN. |
| R5 / T5 withdrawal and privacy | NOT ESTABLISHED: local withdrawal and one static panel neutral control ran; atomic real-service downgrade, stale-pixel absence and physical removal remain unproven. |
| R6 / T6 diagnostic fidelity | PARTIAL: LIGHT/FULL export methods passed and first worker post is now separated from Main delivery; complete OFF/LIGHT/FULL pressure, rotation while visible and all byte/cost cases are NOT RUN. |
| R7 / T6 selector | PARTIAL: bridge/console host tests and packaged markers passed. Fresh-install default and pending-boundary persistence have not been independently observed on device. |
| R8 / T7 host/production delivery | PARTIAL: source/APK hashes, fixed-mode timing and admission oracle ran; independent visual oracle, full native 2×30, normal delivery and dashboard-profile gates are NOT RUN because scoped entry conditions did not pass. |

**Implementation:** substantive candidate present; complete R12 contract not established.  
**Automated validation:** scoped jobs failed closed as described; no overall PASS.  
**APK delivery:** verified REVIEW ONLY direct bytes above.  
**Physical acceptance:** PENDING — USER ONLY.

## Earlier local red and corrected checks

- The pre-implementation `keyguard_first_render_architecture_boundary_test.dart` run had 2 expected source-absence failures (`R12 presenter is required` and `R12 must expose SURFACE_LIVE`) and 2 passes. This is an architecture RED, not an API35 runtime result. The subsequent targeted Flutter suite passed 12/12 after implementation.
- The first render-mode Flutter run had 3 layout-overflow failures. The next run had one copy/freeze interaction failure because the control was off screen. The console layout and test interaction were corrected; the later targeted run passed 12/12. Original logs: `render-mode-flutter.log`, `render-mode-flutter-corrected.log`, and `continuation-integrated-flutter.log` under `/workspace/outputs/r12/preflight/`.
- `r12-surface-diagnostics-compile.log` initially had 1/52 JVM failures: `KeyguardOrbSurfaceMetricsTest` compared an `Int` literal with a `Long` result. The assertion literals were corrected; later app JVM suite passed 174/174. The separate first `fluvi-core` failure and writable-directory rerun are recorded above.
- The final APK probe first searched optimized AOT bytes for the lower-case input `human_diagnostic` and failed; source maps this to the exported `HUMAN_DIAGNOSTIC` marker. All three ABIs were then checked for the full source SHA and the actual exported marker, matching the previously verified Human build. No executable change was made to hide that failed probe.
