# Acceptance checklist: dashboard interaction performance isolation

Baseline: `40f8431`. Backup branch:
`backup/dashboard-best-performance-40f8431`. Backup tag:
`milestone/dashboard-functional-performance-baseline-40f8431`.

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| BAS-01 | User backup requirement | git refs | Exact baseline has backup branch and annotated tag; work is on a feature branch | `git show-ref`, `git rev-list` | DONE |
| ARC-01 | structuring-apps | dashboard application/query | One visible truth, one canonical bundle owner and one background-work owner | boundary test + dependency inspection | PARTIAL |
| NAV-01 | preserved child rail | centered carousel + presentation | Every distinct child crossing can publish before settle | frozen widget/controller regression suite | PARTIAL |
| NAV-02 | open-rail parent transition | dashboard core/time navigation | Parent/deck/snapshot owners match and retained child is clamped atomically | open-rail transition tests | PARTIAL |
| NAV-03 | SummaryPill parent navigation | summary navigation + registry | Cached month/year target is one lookup and one atomic publish | controller/widget counters | NOT DONE |
| STATE-01 | parent/child/direction parity | query keys + presentation | Parent scope, child cursor, direction and filters never mix | income/expense/filter race tests | PARTIAL |
| CACHE-01 | canonical cache reuse | bundle registry | Complete entry reused at same revision with no bundle request or read | registry integration test | DONE |
| CACHE-02 | bounded memory | bundle registry | Current parent pinned; adjacent entries byte-bounded; explicit zero is a hit | eviction and stress tests | DONE |
| LIVE-01 | fresh interaction has no I/O | query/live sync | Child settle, rail open/close and cached parent navigation start no read/watch churn | repository/native counters | NOT DONE |
| LIVE-02 | stable invalidation | native bridge/query | Child selection does not change subscription identity | 10/100 settle test | NOT DONE |
| BG-01 | interaction gate | background coordinator | No expensive queued work starts during any interaction/transition phase | fake scheduler test + trace | NOT DONE |
| BG-02 | latest-wins | background coordinator | Duplicate jobs coalesce and stale jobs/results never publish | race/cancellation tests | NOT DONE |
| AMT-01 | direct/no-op amount | amount widget/policy | Preview is direct; equal amount no-op; actual execution diagnostics are truthful | controller/rebuild counter tests | PARTIAL |
| UI-01 | narrow rebuilds | motion host/dashboard widgets | Pulse/amount/query changes do not rebuild dashboard root, rail, SummaryPill or LogBox unnecessarily | instrumented widget tests | NOT DONE |
| MOT-01 | frozen motion | centered carousel | Controller, position, widget State and physics parameters/identity stay stable | identity and physics regression tests | PARTIAL |
| LOG-01 | O(1) content preview | LogBox adapter/projector/viewport | Preview selects immutable viewport state; no grouping/formatting/paging | projection and row-build counters | NOT DONE |
| LOG-02 | stable lazy viewport | LogBox widget | Same viewport State/controller; only visible bounded rows build | widget test + profile counters | PARTIAL |
| PRE-01 | low-priority prewarm | background coordinator | Adjacent work is idle-only, one-at-a-time, deduped and cancelable | scheduler tests | NOT DONE |
| NAT-01 | scalable native bundle | Room/read service/channel | SQL aggregate + bounded rows; no full-parent in-memory grouping; mapping off-main | Kotlin tests + trace | NOT DONE |
| START-01 | exact first frame | bootstrap + registry | No dash/stale first frame; first mother-child open is cache-only | bootstrap/widget tests | PARTIAL |
| RACE-01 | callback isolation | epochs/store/query | Old rail/live/prefetch/animation callback cannot mutate current target | deterministic race tests | PARTIAL |
| PERF-01 | profile evidence | performance harness | UI/raster p50/p90/p95/p99 and operation/rebuild counters recorded | physical profile run | BLOCKED |
| PERF-02 | density invariance | rail/SummaryPill/LogBox | 0/94/1000-entry p95 difference targets <=10% without target drift | repeated identical gesture profile | BLOCKED |
| STRESS-01 | 5k/20k/100k | native/cache/LogBox | Preview remains aggregate O(1), bounded memory and committed-only paging | deterministic stress suite | NOT DONE |
| REG-01 | milestone parity | complete regression suite | No startup, direction, mother/child, zero-result, rail or SummaryPill regression | targeted + full Flutter/Kotlin suite | NOT DONE |
| TEST-01 | no golden tests | repository tests | No golden file/test is added | `rg` inventory | DONE |
| DEL-01 | delivery | git/GitHub Actions | All non-deferred items DONE, committed and feature branch pushed for online builds | checklist reread + CI | NOT DONE |

`BLOCKED` performance rows require a connected physical profile session. They
must not be reported as PASS from host/unit evidence.

Cache evidence: the registry RED suite covers semantic identity, revision and
stale misses, explicit-zero hits, current-parent pinning and byte eviction. The
integration regression reuses the identical complete current bundle after four
adjacent prewarms with no additional parent or child read. The focused
parent/child/bootstrap/direction/stress suite passed 40 tests in Ubuntu/proot.
