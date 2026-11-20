# R15 corrected export experiment: exact-source graph and native inventory

Application source `96cf20d4f64c2e3a06c10507f919dd133033852b`, parent
`b372a694dbf1e78e90917b73a75990c599ffc68f`. The source checkout was
`/workspace/r15-final-graph-source`; this tooling checkout was
`/workspace/r15-final-graph-tooling`, descended from
`69d9742f39e5075d9c95ff46ceca17a4970098d6` through the separately retained
R15 initial graph. This is an experiment, not a safety, performance, screen
presentation, release or phone acceptance finding.

SCIP-Dart 1.6.2 index SHA-256:
`1e02a14d22073b98c559b01d077f9337a3a4390a1acc2c8d869d1c9d1dff4ff6`.
Manifest SHA-256:
`19fafa8cda7be9b896644929b6f802d4085b99d98ab5d2c123307190db7defc2`.
It identifies 808 documents, 20,269 repository-defined symbols, 136,449
references and 42,246 edges. All 102 shard hashes and record counts were
recomputed; tooling analysis and 16 tests passed. `KeyguardTimingCaptureBridge`
has 11 references, three production and eight test. SCIP indexes Dart only;
the Kotlin map below is source-verified navigation, not SCIP coverage or a
claim of runtime behavior.

| Location under `android/app/src/main/kotlin/com/fluvi/app/lockscreen/` | Boundary |
| --- | --- |
| `FluviKeyguardCardService.kt:897`, `:1007`, `:1024` | New wake, existing system sampler, capture-bound already-completed evidence. |
| `KeyguardCardWindow.kt:149`, `:188` | Prepared root and already-selected effective render route. |
| `KeyguardFirstAcquisition.kt:6`, `:11`, `:18`, `:22` | One-use scalar opportunity and authority/ticket consumption. |
| `KeyguardInspectionFreshness.kt:32`, `FluviKeyguardCardService.kt:1183`, `:1641`, `:1722` | Existing queue and freshness ticket lead to serial physical reading. |
| `KeyguardWindowSnapshotReader.kt:55`, `:131`, `:307`, `:378`, `:484`, `:513` | First eligible active-root call, accepted-child batching and existing bounded traversal. |
| `KeyguardCardSurface.kt:89`, `FluviKeyguardCardService.kt:1913`, `:2549`, `KeyguardCardWindow.kt:307` | Complete classification and current admission before the actual show. |
| `FluviKeyguardCardService.kt:2700`, `KeyguardCardWindow.kt:476`, `material/KeyguardOrbSurfacePresenter.kt:127`, `material/KeyguardOrbSurfaceWorker.kt:269` | Actual hide, captured target, synchronous revocation and worker cleanup. |
| `material/KeyguardOrbSurfaceWorker.kt:431`, `:443`, `:446`, `:458`, `material/KeyguardOrbSurfaceMetrics.kt:62` | Holder lock/draw/post/record observations are bounded and do not establish a displayed frame. |
| `FluviKeyguardCardService.kt:1459`, `:2951`, `KeyguardCardSettings.kt:1625`, `:2023`, `:2384`, `:2440`, `:2533` | Owner-qualified inspection and revoke observations, byte-budget selection and exported holder/cause records. |

The R15 first-service control is timing/flag evidence only. The calibrated
first/last compositor and privacy/holder fixtures, balanced stock/candidate
blocks and complete 28-row aggregate remain separate requirements. The
workflow's focused export mapping is a correction test, not a replacement for
those gates. The earlier `b372a694` graph remains historical and has its own
source and index identities.
