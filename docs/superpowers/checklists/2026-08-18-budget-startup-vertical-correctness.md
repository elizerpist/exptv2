# Budget, startup and committed vertical correctness — acceptance checklist

Starting point: `separated-core-modes` at
`563863f954f5acec2345144c6c963279c25de218`.

| ID | Source requirement | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BUD-01 | §§3–7 | `DashboardBudgetPresentationController` | One immutable selected-limit state binds target, key, actual, limit, `hasPositiveLimit`, raw and source progress. | Unit + widget handoff tests | NOT DONE |
| BUD-02 | §5 | Budget avatar artwork / rail | Missing or non-positive limit paints no selection shell, track, arc or shell shadow; centred avatar remains. | Widget tests | NOT DONE |
| BUD-03 | §§6–8 | Budget presentation + edit overlay | Positive limit uses the selected target's exact `actual / limit`; optimistic create/delete changes header and chrome together. | Unit + widget tests | NOT DONE |
| BUD-04 | §9, §26 | Budget rail repaint lane | Semantic limit tick causes no repository, bridge, SQL, Query, LogBox, SVG parse or target-catalog rebuild. | Existing/new focused tests and code inspection | NOT DONE |
| START-01 | §§19–21 | `FluviAppShell` bootstrap coordinator | Each launch records one bounded attempt and stage failure/ready diagnostics; no timer/debounce/retry loop. | Widget tests + diagnostic assertions | NOT DONE |
| START-02 | §§20–23 | Proven startup failure owner | Fresh, existing-v5 and v4→v5 bootstrap reach READY in one healthy attempt after root cause is reproduced. | Flutter tests + Kotlin migration/core tests | NOT DONE |
| VERT-01 | §§10–14 | `ExplicitCommittedPagingController` | Raw vertical pointer contact starts no new read and commits no page; post-release ballistic live demand may replenish through the same serial owner. | Paging controller RED/GREEN tests | NOT DONE |
| VERT-02 | §§15–18 | `CommittedLogViewportCache` + paging controller | Repeated fast demand across >12 pages has no visible miss, keeps bounded/pinned retention, unchanged immutable geometry and one I/O request at a time. | Runtime/cache regression tests | NOT DONE |
| VERT-03 | §16 | Exact failing owner | Reproduce and correct the ordinal-9/next-10 `Invalid argument(s): 10`; do not suppress it. | Focused regression with stack/source evidence | NOT DONE |
| VERT-04 | §§17, 27 | Diagnostics | Normal target tests leave virtual/cache/root/geometry mismatch counters at zero and identify live-vs-idle work origin. | Runtime tests | NOT DONE |
| SAFE-01 | §§24, 28 | Cross-cutting boundaries | Preserve a single paging cursor owner, immutable geometry/physics and existing quick-edit, Query and LogBox ownership. | Boundary and protected regression suites | NOT DONE |
| DELIVERY-01 | §§29–31 | Branch / GitHub Actions | Targeted Flutter, boundary and applicable Kotlin tests green; focused commits pushed; normal `lib/main.dart` APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256. | Fresh command output + GitHub run/artifact | NOT DONE |

No golden tests, integration harnesses, automated gestures, alternate human entrypoints,
capacity-only paging workarounds, or physical-acceptance claims are permitted.
