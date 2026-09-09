# E8 milestone, Time window atomicity and Avatar first-load — acceptance checklist

Status key: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This repair starts from the exact user-accepted application commit
`e8b73e3e939104164e55b09caf592f84ee59fb14`, not from a later inferred
baseline. The byte-faithful frozen e8 logs are recorded in
`docs/superpowers/evidence/2026-09-09-e8-milestone-time-window-avatar-first-load/`.
They share one session but have a retention gap; the missing interval is not
used as evidence.

| ID | Source | Intended ownership / code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| E8M-01 | User decision §2 | `MILESTONE_COMMITS.md` | e8 is permanently recorded as the user-accepted direct-manipulation performance floor and rollback anchor while its open correctness edges remain explicit. | Inspect top milestone entry and separate documentation commit `135dcaa2`. | DONE |
| E8M-02 | User §§4–5 | Evidence manifest and frozen Drive exports | Both refreshed logs are retained byte-faithfully with title, ID, session, build, duplicate audit, retained ranges and gap stated honestly. | Decode `.base64`, verify byte count/SHA-256, audit event sequence fields. | DONE |
| E8M-03 | User §§3, 6–8 | SCIP manifest and source/test audit | The exact e8 graph is used only as navigation; source and test consumers are inspected before shared changes. | Manifest/hash verification; graph queries; CURRENT-source audit recorded in forensics. | PARTIAL |
| E8M-04 | User §§8–9, 14.2–14.8 | `DashboardCoreController`, `DashboardDataRuntime`, prepared index and presentation controller | An out-of-prepared-window direct Time target stays pending behind a bounded, latest-wins prepared-window transition; it never takes the canonical compatibility fallback. | Production-parent lower-bound, rebased-month, coalescing, and settle regressions red on e8/green after repair. | DONE |
| E8M-05 | User §§8.6–8.7, 9.2 | Visible-frame order and Time pending candidate | A direct Time target retains its original `summaryTime` interaction order throughout preparation; no target is accepted with producer `none`, epoch `0`, generation `0`, or unknown terminal state. | Interaction-order assertions and diagnostic terminal-outcome regression. | DONE |
| E8M-06 | User §§8.6, 9.1 | Navigation, prepared index, visible store, Budget presentation, LogBox | Every surviving Time target atomically aligns selected target, navigation, Summary, visible query, Budget scope, LogBox, ready-ahead/committed identity and settle identity. | Temporal-authority equality production-parent regression across lower-bound and month crossings. | DONE |
| E8M-07 | User §§8.8–8.10, 10, 14.9–14.10 | Avatar focus derivation and `BudgetTargetAvatarRail` | Avatar category and aggregate target `0` publish coherent exact Phase A immediately after a Time-window transition; no admission exception or progress identity mismatch remains. | Post-rebase Avatar drag/ballistic and aggregate regression; typed error evidence red/green. | DONE |
| E8M-08 | User §8.9, §10 | Avatar admission diagnostics | A production-facing fail-safe records bounded runtime type, message digest, stack fingerprint, boundary and temporal identities before it rejects an unexpected Avatar admission error. | Forced old mixed-base regression verifies e8 generic error and repaired typed diagnostic. | DONE |
| E8M-09 | User §§8.2, 11, 14.11–14.12 | Avatar rail, Core diagnostics and actual paint probes | A fresh normal first Avatar fling preserves the complete pointer-to-raster pipeline, publishes at least one exact target without a second fling, and distinguishes slop/distance, readiness, build, paint and raster time. | Fresh production-parent cold/warm tests and retained flight summary. | DONE |
| E8M-10 | User §§8.3, 13, 14.17 | Diagnostic logger and flight recorder | A USER_MARK retains the latest completed Avatar/Time flights, first-target pipeline and exceptional outcomes despite rolling-ring pressure; layer/geometry noise is materially coalesced and bounded. | Over-capacity diagnostic-retention regression plus emitted drop/coalesce accounting. | DONE |
| E8M-11 | User §§8.11, 12, 19 | Existing prepared-scene cache scheduler | Scene-slice/queue optimization happens only after frame-correlated measurement; an exact foreground resource can overtake lower-value work at a safe unit boundary. | Scheduler-priority/memory regression and before/after measured report. | NOT DONE |
| E8M-12 | User §§1, 8.1, 15, 19 | Carousel, layout and protected surfaces | e8 motion performance is not regressed through changed physics, thresholds, geometry, z-order, clipping, hit testing, target suppression or duplicate authority. | Diff audit; existing carousel/geometry tests; accepted-publication parity control. | PARTIAL |
| E8M-13 | User §§14.1, 14.13–14.15, 18 | Existing Core/cache/paint production parents | Normal in-window e8 Time/Avatar controls continue to have exact Phase A, matching Header/progress/LogBox paint, stable controller identities and zero forbidden tick work; zero accepted publications fails performance validation. | Focused control and no-false-smoothness regressions. | DONE |
| E8M-14 | User §§15, 18 | Mind/Slider production files and tests | Mind/Slider behavior and source remain untouched; no new cache, store, controller, viewport or LogBox exists. | `git diff --name-only`, protected tests, architecture/diff audit. | DONE |
| E8M-15 | User §§17–20 | Ubuntu/proot test matrix, CI, human APK, SCIP tooling | Focused/broad validation is honestly reported; final production SHA is pushed, human APK is downloaded/hashed, and separately committed SCIP artifacts index that exact SHA. | Exact commands/results, Actions artifact audit, APK and graph manifests. | PARTIAL |
| E8M-16 | User §§19, 22–23 | Physical Android behavior | Only the user can accept a new candidate; e8 remains the preferred performance anchor unless that happens. | User physical testing of exact candidate APK. | NOT DONE |

## Preserved boundary

The prior e8 tree already protects foreground handoff, Time exact Phase A,
Avatar exact Phase A, target-correlated Header/progress paint probes, stable
carousel ownership and the single Core/store/cache/viewport/LogBox topology.
This work may extend the existing runtime prepared-index transition and typed
`timePreview` lane, but it must not recreate those owners or retune physics.

## Current evidence classification

- `DONE`: e8 is the human-accepted motion baseline, and its frozen source
  logs identify a real Time prepared-frame miss followed by a canonical
  fallback and later Avatar exceptions.
- `DONE`: automated production-parent regressions prove the bounded Time
  rebase, original direct interaction order, atomic visible authority,
  post-rebase Avatar category/aggregate admissions, typed error evidence,
  first-target pipeline and rolling-log retention.
- `PARTIAL`: source/automated controls preserve the e8 protected surfaces,
  but no new physical device performance measurement or user acceptance is
  available. Final push/APK/SCIP delivery is also still pending.

## 2026-09-09 automated validation evidence

- `flutter test` over the changed logger, Core, Avatar, LogBox and
  `core_dashboard_test.dart` files: **187 passed**.
- `flutter test test/features/dashboard/application --reporter failures-only`:
  **293 passed**.
- `bash scripts/test-fluvi-fast.sh` with Ubuntu Flutter on `PATH`:
  **294 passed**.
- Candidate `test/features/dashboard/presentation` run: **597 tests, 19
  failures**. The exact e8 baseline run has **595 tests, the same 19
  inherited failures**; the candidate contains two additional passing tests.
- `flutter analyze --no-pub`: **No issues found**. `dart format
  --output=none --set-exit-if-changed` over the changed Dart files: **0
  changed**. `git diff --check`: clean.
