# Dashboard rail smoothness acceptance checklist

Baseline: `bef62ae8c92d18ae1dde74dd521bb739fadd556b`.
Rail-preview reference: `1430c50666bc48deb2ea10f01592ccf567decf87`.
Feature branch: `feature/dashboard-rail-smoothness`.

Golden tests are explicitly excluded.

| ID | Source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| RS-01 | Latest user request, priority 1 | `CurrentQueryController`, live lease coordinator | New rail motion invalidates pending lease before activation | Unit test with delayed lease and new motion epoch | DONE |
| RS-02 | Latest user request, priority 2 | Query/store boundary | Active old lease may cache, but cannot notify or rebind current preview | Regression test with old live result during child preview | DONE |
| RS-03 | Latest user request, priority 3 | Summary amount presentation | Preview uses direct update; equal amount is no-op; no 120 ms animation starts | Widget/unit counters and diagnostics test | DONE |
| RS-04 | Latest user request, priority 4 | Shared carousel/dashboard motion coordinator | One semantic idle and one settle per motion epoch; duplicates are counted and dropped | Motion controller/widget test | DONE |
| RS-05 | Latest user request, priority 5 | `DashboardCoreController` adjacent prewarm | Adjacent prewarm does not start during active drag/ballistic motion and has no duplicate request | Coordinator test with fake prewarm gate | DONE |
| RS-06 | Latest user request, priority 6 | Method-channel bundle decoding and diagnostics | Child bundle emits one aggregate parse event; per-child D7 is verbose-only | Decoder/diagnostic test | DONE |
| RS-07 | Latest user request, priority 7 | LogBox adapter and viewport | Preview lookup/project/build/layout/paint phases have bounded numeric diagnostics | Instrumentation test; device profile trace pending | PARTIAL |
| RS-08 | Baseline invariants | Shared carousel and rail | Crossing sequence, final target, controller, position and physics identity remain unchanged | Existing regression suite; device baseline profile pending | PARTIAL |
| RS-09 | Baseline invariants | Dashboard presentation | Preview amount/count/LogBox remain atomic and preview I/O stays zero | Existing preview regression suite plus counters | DONE |
| RS-10 | Stress requirements | Fixtures/cache/paging | 5k/20k/100k fixtures remain bounded; no preview paging or unbounded cache growth | Deterministic fixture/cache tests; device profile run pending | PARTIAL |
| RS-11 | Delivery instruction | GitHub Actions/build | Only after all checks are green: commit, push, one full online build, download APK | Final verification report and artifact hash | NOT DONE |

## Frozen invariants

- Do not change `ScrollController`, `ScrollPosition`, `ScrollPhysics`,
  simulation, velocity mapping, item extent, snap target, cyclic mapping,
  haptics, or gesture ownership.
- Do not debounce or settle-gate preview publication.
- Preview performs no repository read, native watch subscription, or paging.
- The LogBox viewport and its vertical controller keep stable identity.
- No golden test is added.
