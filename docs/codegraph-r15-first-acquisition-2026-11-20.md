# R15 first-acquisition experiment: graph and native inventory

Application source: `b372a694dbf1e78e90917b73a75990c599ffc68f` (parent
`5489dbcdec9a0b0c5adda6f1992c4b5a47b0bb15`). Tooling descends from
`69d9742f39e5075d9c95ff46ceca17a4970098d6`. Source checkout:
`/workspace/r15-graph-source`; tooling checkout: `/workspace/r15-graph-tooling`.
This indexes the experiment and does not establish correctness, performance,
screen presentation or physical acceptance.

SCIP-Dart 1.6.2 generated `index.scip` SHA-256
`175879c00c45f93f42bc133608bd1e6cb21155eb72616241f519543dd1750fac`.
The manifest records 808 documents, 20,269 repository-defined symbols,
136,449 references and 42,246 edges. All 102 shard hashes and record counts
were recomputed. Manifest SHA-256:
`b6b2789dcf19d10fa717efae5a0a70c64a3aa4aec33759c05f5f286c461974cf`.
The graph is a Dart index: **Kotlin SCIP coverage is absent**. The table below
is a manually verified Kotlin source inventory, not inferred SCIP calls.

| Source location (under `android/app/src/main/kotlin/com/fluvi/app/lockscreen/`) | Caller and boundary |
| --- | --- |
| `FluviKeyguardCardService.kt:894`, `:944` | New wake publishes an opportunity only for the already prepared route. |
| `KeyguardCardWindow.kt:149`, `:188` | Main-owned prepared settings/profile and selected effective route. |
| `KeyguardFirstAcquisition.kt:11`, `:18`, `:22` | One-use scalar opportunity, invalidation and ticket/authority check under the queue lock. |
| `KeyguardInspectionFreshness.kt:26`, `:32`, `:41` | Freshness requirement, ticket and actual boundary acknowledgement remain independent. |
| `FluviKeyguardCardService.kt:1172`, `:1266`, `:1620`, `:1701` | Queue, serial physical read, current inspection and root-hint consumption. |
| `KeyguardWindowSnapshotReader.kt:55`, `:131`, `:378`, `:464`, `:484`, `:514` | Root flag selection, single call, full existing traversal and child batching/fallback. |
| `KeyguardCardSurface.kt:89`, `FluviKeyguardCardService.kt:1892`, `:2528` | Current complete classifier, Main apply and actual window show. No previous MAIN is authorization. |
| `FluviKeyguardCardService.kt:2679`, `KeyguardCardWindow.kt:476` | Original operation owns withdrawal; root visibility and removal stay immediate. |
| `material/KeyguardOrbSurfacePresenter.kt:127`, `material/KeyguardOrbSurfaceWorker.kt:269`, `:385` | Captured target revoke, access closure, worker cleanup and Canvas work remain distinct. |
| `material/KeyguardOrbSurfaceMetrics.kt:62`, `:78`, `:121` | Bounded per-generation holder timestamps and capture-time snapshots; no displayed-frame claim. |
| `FluviKeyguardCardService.kt:1444`, `:2930`, `KeyguardCardSettings.kt:1618`, `:2016`, `:2397`, `:2411` | Owner-qualified inspection/revoke events, bounded reduction, compact cause and withdrawal export. |

Representative tests: `KeyguardFirstAcquisitionTest.kt:6`,
`KeyguardWindowSnapshotReaderPolicyTest.kt:144`,
`KeyguardCardDiagnosticsInstrumentationTest.kt:706` and
`KeyguardR12ServiceTimingInstrumentationTest.kt:51`. These are distinct from
the missing calibrated composite/privacy and balanced comparison fixtures.
The R15 ref routes the latter available independent controls in
`.github/workflows/fluvi-core.yml:370`; the collector does not yet emit the
complete R14 aggregate's per-case JSON records. Missing evidence remains
`NOT_ESTABLISHED` and is not a pass.

Dart query: `KeyguardTimingCaptureBridge` has 11 references (3 production,
8 tests); `KeyguardTimingCaptureSnapshot` has 12 production references and
`DebugConsoleDialog` has 6 references (3 production, 3 tests). These
references navigate the debug console bridge; they do not prove Kotlin state
flow or accessibility/Surface ordering.
