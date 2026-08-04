# Dashboard cold-start and cold-parent acceptance checklist

Baseline: `2d8f4d2` on `feature/dashboard-bootstrap-frame-stress`.

Frozen rail milestone: `1430c50` (`feat(fluvi): render complete child previews during rail motion`).

This slice addresses only the invalid startup/parent placeholder state. Rail
physics, fling behavior, query calculations, preview lookup and LogBox design
remain frozen.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CP-01 | Latest user prompt §3–6 | `DashboardParentDisplayBundle`, summary controller | Parent amount, count, scope and child bundle form one complete readiness boundary | Model and controller tests | DONE |
| CP-02 | Latest user prompt §4 | `DashboardBootstrapController`, app shell | Dashboard data UI mounts only after a valid initial parent bundle; startup dash is not rendered by Summary | Bootstrap/widget tests | DONE |
| CP-03 | Latest user prompt §5–6 | `DashboardCoreController`, summary controller | Cold horizontal parent navigation retains the complete outgoing visual state until target bundle is ready | Cold-parent regression test | DONE |
| CP-04 | Latest user prompt §6 | `CurrentQueryController`, summary controller | Target parent summary and child preview bundle are prepared before scope commit; adjacent parents are prewarmed outside rail preview | Core navigation test and code inspection | DONE |
| CP-05 | Latest user prompt §10 | Summary diagnostics | `presentationMode` is independent from `dataOrigin`; invalid null/loading selection is not logged as a visible D12 presentation | Diagnostics tests and log inspection | DONE |
| CP-06 | Latest user prompt §8–9 | Summary/store/amount presentation | Identical preview→committed snapshots cause no visual rebound or placeholder | Existing promotion/no-op tests | DONE |
| CP-07 | Latest user prompt §11–13 | Stress fixtures/cache | 10k/50k/100k fixtures are deterministic and preview rows remain bounded | Fixture/cache tests | DONE |
| CP-08 | Latest user prompt §14–15 | Dashboard widget boundaries | Header/rail/viewport identities remain stable through preview and parent swaps | Existing identity/rebuild tests | DONE |
| CP-09 | User delivery instruction | GitHub Actions and APK delivery | Only after all implementation/tests: one final commit, push, online build, and APK download to Fluvi Download folder | Git/Actions/file hash check | NOT DONE |

## Evidence limits

Physical device UI/raster p95/p99, RSS and GC measurements are not available
from the local Termux test environment. They must be reported as not run or
blocked unless the online profile runner supplies actual measurements.
