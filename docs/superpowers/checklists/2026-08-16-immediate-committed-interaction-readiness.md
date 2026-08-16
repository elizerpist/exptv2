# Immediate committed interaction readiness — acceptance checklist

Starting point: `3f4a684ae4271d19b0bf60068679fff7d0ac05c6` on `query`.

| ID | Source requirement | Owner / code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| ICR-01 | Full ready-ahead cannot be swallowed by deferred presentation | `ExplicitCommittedPagingController` serial drain | 67-row target 2 drains 1 then 2 after structural idle without a new gesture | DONE |
| ICR-02 | Ballistic permits only exact deferred presentation | Paging controller + core lifecycle | One pre-admitted page publishes after pointer-up; next read waits for vertical idle | DONE |
| ICR-03 | Current scope/supersede safety | Paging request identity | Old deferred page and continuation cannot publish/read after new committed scope | DONE |
| ICR-04 | Generic motion is not paging safety | `DashboardCoreController` typed lanes | Rail/structural blocks; summary text/amount motion does not strand exact readiness | DONE |
| ICR-05 | No priority/speculation inversion | Core priority lifecycle | Query ready target settles before rail/Summary/chip cache-only work resumes | DONE |
| ICR-06 | One terminal gesture classification | Viewport/session + scroll observer | Real ballistic and no-simulation/boundary traces never emit contradictory terminal events | DONE |
| ICR-07 | Pointer foreground preemption | Core + viewport | Pointer turns prevent new cache-only starts until legitimate idle | DONE |
| ICR-08 | Summary retention rejection does not storm | Existing prepared scene cache admission | Capacity-full protected state skips repeated same Summary candidate until cache/index state changes | DONE |
| ICR-09 | Diagnostic keys are bounded | Core and prepared-scene cache diagnostics | Exact internal key retained; emitted key is a short digest and payload is bounded | DONE |
| ICR-10 | Foreground genuine Query miss keeps old world | Query candidate lifecycle | Prior committed viewport remains drawable until atomic publication; same target promotion remains one acquisition | DONE |
| ICR-11 | Virtual geometry/render contracts | Cache, viewport, render surface | No extent/geometry/controller/position/physics identity mutation; renderer remains fail-closed | DONE |
| ICR-12 | One final delivery only | GitHub Actions human APK | One final commit, one push, one normal `lib/main.dart` human diagnostic APK, SHA-256 recorded | NOT DONE |

Unrelated pre-existing local modifications and helper files are preserved and excluded from the final commit.

Local verification note: `flutter analyze`, boundary verification and focused
new/existing paging, cache, viewport and query tests are green. The unmodified
30-second scene-bank tests in the full Core/fast suites time out under this
Android proot environment; their targeted functional counterparts were run
successfully. No assertion was weakened and no production capacity/budget was
changed to accommodate the host.
