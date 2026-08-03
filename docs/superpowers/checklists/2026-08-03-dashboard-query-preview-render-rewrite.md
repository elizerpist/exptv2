# Dashboard query–preview–render rewrite checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| RWR-01 | User correction | Git history | `85f41ab1e17e28ca9702252deb3cbff327cd8520` is the rewrite base and rail baseline | `git rev-parse HEAD`; protected rail diff audit | DONE |
| RWR-02 | Rollback request | Git refs | Current pre-rewrite state is recoverable from `backup/dashboard-regression-20260803` and tag `dashboard-regression-20260803` | `git show-ref` | DONE |
| RWR-03 | QueryKey requirements | query/domain | Direction, full scope, filters and refinements are part of one canonical key | unit tests | DONE |
| RWR-04 | Snapshot requirements | query/application/presentation | Amount, count and LogBox rows come from one immutable revisioned snapshot | unit/widget tests | PARTIAL — immutable amount/count/entry snapshot exists; baseline has no LogBox row store |
| RWR-05 | Preview lane | rail/application | Every centered child projects synchronously from the in-memory batch index; no I/O during motion | motion isolation tests | PARTIAL — synchronous projection and root-isolation test are green; full motion-I/O matrix remains |
| RWR-06 | Commit lane | query coordinator | Preview promotion is a no-op for an identical snapshot and does not reread | promotion tests | PARTIAL — store promotion and prewarm tests are green; end-to-end lease test remains |
| RWR-07 | Direction toggle | dashboard presentation | Income/expense switches atomically with no stale amount/count/rows | widget test | PARTIAL — core snapshot direction/amount/count test is green; widget-level frame assertion remains |
| RWR-08 | Batch child index | infrastructure/query | Parent children are prepared by one bounded batch snapshot, not N+1 reads | repository tests | NOT DONE |
| RWR-09 | Rail baseline | shared carousel | `85f41ab` rail physics/gesture mechanics remain unchanged; no manual fling | diff + rail tests | PARTIAL — protected shared rail was not rewritten; targeted rail tests are green |
| RWR-10 | Parent navigation | SummaryPill | Closed-rail year swipe changes 2026→2027→2028 exactly once per gesture | widget test | PARTIAL — year parent state/preview and transition tests are green; widget gesture endpoint remains |
| RWR-11 | Rebuild boundaries | presentation | Rail, amount, count, LogBox and header have isolated selectors/rebuilds | widget instrumentation tests | PARTIAL — store-backed amount/count/header selectors exist; rebuild counters remain |
| RWR-12 | Instrumentation | dashboard/query | Numeric bounded counters expose motion I/O, cache, promotion and rebuild counts | unit/integration tests | DONE |
| RWR-13 | Performance | profile benchmark | Dense-data rail is within 10% p95 of the `85f41ab` baseline and has no repeated >50 ms interaction frame | profile benchmark report | BLOCKED — requires profile device/CI run |
| RWR-14 | Test policy | repository | No golden tests are added or run; all non-golden regressions pass | explicit test commands | PARTIAL — no golden tests added/run and targeted non-golden suite is green |

## Baseline decision

The user clarified that `85f41ab` is the correct starting point: its rail is
the same accepted rail and is therefore the behavioral baseline. The earlier
temporary rewrite branch based on `5b71141` was moved to `85f41ab`; no
milestone-after changes were copied in. The later broken state remains
preserved only by the backup branch/tag above.
