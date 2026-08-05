# Acceptance checklist: dashboard interaction performance isolation

Baseline: `40f8431`. Backup branch:
`backup/dashboard-best-performance-40f8431`. Backup tag:
`milestone/dashboard-functional-performance-baseline-40f8431`.

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| BAS-01 | User backup requirement | git refs | Exact baseline has backup branch and annotated tag; work is on a feature branch | `git show-ref`, `git rev-list` | DONE |
| ARC-01 | structuring-apps | dashboard application/query | One visible truth, one canonical bundle owner and one background-work owner | boundary test + dependency inspection | DONE |
| NAV-01 | preserved child rail | centered carousel + presentation | Every distinct child crossing can publish before settle | frozen widget/controller regression suite | DONE |
| NAV-02 | open-rail parent transition | dashboard core/time navigation | Parent/deck/snapshot owners match and retained child is clamped atomically | open-rail transition tests | DONE |
| NAV-03 | SummaryPill parent navigation | summary navigation + registry | Cached month/year target is one lookup and one atomic publish | controller/widget counters | DONE |
| STATE-01 | parent/child/direction parity | query keys + presentation | Parent scope, child cursor, direction and filters never mix | income/expense/filter race tests | DONE |
| CACHE-01 | canonical cache reuse | bundle registry | Complete entry reused at same revision with no bundle request or read | registry integration test | DONE |
| CACHE-02 | bounded memory | bundle registry | Current parent pinned; adjacent entries byte-bounded; explicit zero is a hit | eviction and stress tests | DONE |
| LIVE-01 | fresh interaction has no I/O | query/live sync | Child settle, rail open/close and cached parent navigation start no read/watch churn | repository/native counters | DONE |
| LIVE-02 | stable invalidation | native bridge/query | Child selection does not change subscription identity | 10/100 settle test | DONE |
| BG-01 | interaction gate | background coordinator | No expensive queued work starts during any interaction/transition phase | fake scheduler test + trace | DONE |
| BG-02 | latest-wins | background coordinator | Duplicate jobs coalesce and stale jobs/results never publish | race/cancellation tests | DONE |
| AMT-01 | direct/no-op amount | amount widget/policy | Preview is direct; equal amount no-op; actual execution diagnostics are truthful | controller/rebuild counter tests | DONE |
| UI-01 | narrow rebuilds | motion host/dashboard widgets | Pulse/amount/query changes do not rebuild dashboard root, rail, SummaryPill or LogBox unnecessarily | instrumented widget tests | DONE |
| MOT-01 | frozen motion | centered carousel | Controller, position, widget State and physics parameters/identity stay stable | identity and physics regression tests | DONE |
| LOG-01 | O(1) content preview | LogBox adapter/projector/viewport | Preview selects immutable viewport state; no grouping/formatting/paging | projection and row-build counters | DONE |
| LOG-02 | stable lazy viewport | LogBox widget | Same viewport State/controller; only visible bounded rows build | widget test + profile counters | DONE |
| PRE-01 | low-priority prewarm | background coordinator | Adjacent work is idle-only, one-at-a-time, deduped and cancelable | scheduler tests | DONE |
| NAT-01 | scalable native bundle | Room/read service/channel | SQL aggregate + bounded rows; no full-parent in-memory grouping; mapping off-main | Kotlin tests + trace | DONE |
| START-01 | exact first frame | bootstrap + registry | No dash/stale first frame; first mother-child open is cache-only | bootstrap/widget tests | DONE |
| RACE-01 | callback isolation | epochs/store/query | Old rail/live/prefetch/animation callback cannot mutate current target | deterministic race tests | DONE |
| PERF-01 | profile evidence | performance harness | UI/raster p50/p90/p95/p99 and operation/rebuild counters recorded | physical profile run | BLOCKED |
| PERF-02 | density invariance | rail/SummaryPill/LogBox | 0/94/1000-entry p95 difference targets <=10% without target drift | repeated identical gesture profile | BLOCKED |
| STRESS-01 | 5k/20k/100k | native/cache/LogBox | Preview remains aggregate O(1), bounded memory and committed-only paging | deterministic stress suite | DONE |
| REG-01 | milestone parity | complete regression suite | No startup, direction, mother/child, zero-result, rail or SummaryPill regression | targeted + full Flutter/Kotlin suite | DONE |
| TEST-01 | no golden tests | repository tests | No golden file/test is added | `rg` inventory | DONE |
| DEL-01 | delivery | git/GitHub Actions | All non-deferred items DONE, committed and feature branch pushed for online builds | checklist reread + CI | BLOCKED |

`BLOCKED` performance rows require a connected physical profile session. They
must not be reported as PASS from host/unit evidence.

Local evidence on 2026-08-04:

- `flutter test` over every non-golden test with concurrency 2: 345 passed.
- `flutter analyze --no-fatal-infos`: exit 0; three pre-existing info findings.
- `verify-fluvi-boundaries.sh` and `git diff --check`: passed.
- Registry tests cover semantic identity, revision/stale misses, explicit-zero
  hits, current-parent pinning and byte eviction. Complete bundles survive four
  adjacent prewarms without another parent/child read.
- Stable invalidation is covered by separate 10- and 100-settle regressions.
- Profile reporting covers UI/raster p50/p90/p95/p99, 0/94/1000-row p95 delta,
  RSS/GC streams, counters, cache weight and target-drift assertions.

GitHub Actions evidence:

- [Run 30948898088](https://github.com/elizerpist/exptv2/actions/runs/30948898088)
  passed `test-core`, `test-flutter`, `build-profile-harness` and
  `build-debug-apk` for implementation commit `36fc841`.
- The x86 run executed the clean Room core suite including deterministic
  5k/20k/100k coverage, the native dashboard bridge suite, Flutter analyze and
  every non-golden Flutter test.
- The profile APK build proves the harness compiles and is distributable. It
  does not replace the still-blocked physical-device measurement.

`DEL-01` remains blocked only because `PERF-01` and `PERF-02` require a connected
physical profile device or an explicit user-approved deferral. Commit, branch
push and online build portions are complete.

## Seeded Android startup hotfix — 2026-08-05

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| HOTFIX-START-01 | User log and latest Android screenshot, 2026-08-05 | `DashboardSummaryMetricsController` bundle assembly; bootstrap boundary | When seed completion starts a snapshot-less child prewarm and bootstrap joins it with the authoritative parent snapshot, the same repository read produces one complete canonical parent/child bundle; bootstrap reaches `ready` and does not remain on the initialization spinner | Deterministic overlap regression test asserting one child-bundle read, complete bundle identity and completed bootstrap future | DONE |
| HOTFIX-START-02 | User log values, 2026-08-05 | startup query/presentation wiring | The fix preserves the committed July 2026 income snapshot (`70,700,000` minor, 6 entries) and does not start a duplicate parent watch/read to escape the race | Focused core startup test plus existing bootstrap/query regressions | DONE |
| HOTFIX-DEL-01 | User delivery instruction, 2026-08-05 | git, GitHub Actions, Android artifact | Fix is committed on a new branch, pushed, online Android build passes, and its APK is downloaded to `/storage/emulated/0/Download/fluvi` | Git/Actions evidence, local APK path and SHA-256 | PARTIAL |

Evidence input:

- Screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260805-060134.png`.
- The supplied trace completes seed (`D1`), DB verification (`D2`), parent
  result publication (`D5`/`D7`/`D8`) and child SQL/mapping/serialization, then
  stops after `I1 CHILD_PREVIEW_BUNDLE_RECEIVED`; it never emits
  `DASHBOARD_BUNDLE_READY` or `DASHBOARD_FIRST_VALID_PAINT`.

Compact architecture gate:

- Lifecycle readiness remains owned by `DashboardBootstrapController`.
- Canonical parent/child assembly and in-flight deduplication remain owned by
  `DashboardSummaryMetricsController` and `DashboardParentBundleRegistry`.
- The hotfix must let a parent-aware caller finish the already-running
  snapshot-less bundle load. It must not add a second cache, coordinator,
  repository read, query/watch lane, or UI-owned recovery workflow.

Local hotfix evidence:

- The deterministic RED run reproduced the device boundary exactly: after
  `I1 CHILD_PREVIEW_BUNDLE_RECEIVED`, bootstrap completed in `failed` rather
  than `ready`.
- The GREEN run emits `DASHBOARD_BUNDLE_READY` followed by
  `DASHBOARD_FIRST_VALID_PAINT`, retains `70,700,000` minor and 6 entries for
  July 2026 income, and asserts one exact parent watch plus one current-parent
  child-bundle read.
- Focused startup/bootstrap/bundle/navigation regressions: 37 passed.
- Every non-golden Flutter test: 346 passed.
- `flutter analyze --no-fatal-infos`: exit 0; the same three pre-existing info
  findings remain outside the changed files.
- `scripts/verify-fluvi-boundaries.sh` and `git diff --check`: passed.

`HOTFIX-DEL-01` remains partial until the branch is pushed, its online Android
build passes, and the APK is downloaded to the requested device folder.
