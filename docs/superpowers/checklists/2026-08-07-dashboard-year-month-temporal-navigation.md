# Dashboard year/month isolation and temporal navigation acceptance checklist

Date: 2026-08-07

Source: the user's “FLUVI DASHBOARD — MILESTONE LOCK + YEAR→MONTH RAIL
PERFORMANCE ÉS TEMPORAL NAVIGATION HELYREÁLLÍTÁS” instruction in the current
conversation.

Milestone commit: `f33152b1657d0916eef68c6ffb7ca89697320a51`

Milestone branch:
`milestone/month-day-perfect-before-year-month-final-isolation`

Milestone tag:
`milestone/month-day-perfect-before-year-month-final-isolation-20260807`

Work branch: `fix/dashboard-year-month-temporal-navigation`

Status vocabulary: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This is the release gate. A compilation, green CI or APK does not complete the
work while any required row is `PARTIAL`, `BLOCKED` or `NOT DONE`.

## Milestone and preservation

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| MILE-01 | §1 | Git history | The exact current best version is recoverable by dedicated branch, empty milestone commit and annotated tag; implementation uses a separate branch. | `git show`, `git branch`, `git tag`. | DONE |
| MILE-02 | §1 | baseline evidence | Milestone hash plus month/day rail, controller/position, physics, prepared-index and navigation/state SHA-256 inventory is recorded. | Baseline section in the root-cause report. | DONE |
| MILE-03 | §1 | verification | Fresh full non-golden baseline and analyze pass in Ubuntu proot. | 249/249 PASS; analyze `No issues found`. | DONE |
| FREEZE-01 | §1, §3, §17 | centered carousel physics | Friction, sensitivity, velocity limits/multipliers, snap, item extent and gesture mechanics remain byte-identical. | SHA-256 and empty semantic diff against milestone. | DONE |
| FREEZE-02 | §1, §15.7, §18.1 | month/day path | Existing 0/2/9-row and mixed 30-run traces retain velocity, endpoint, identity, rebuild and zero-I/O results. | 30-run regression density matrix: exact velocity/endpoint parity, zero interruption/metric change. | DONE |
| FREEZE-03 | §3, §17 | implementation diff | No manual fling, timer stepping, debounce/throttle, settle-only content, hidden LogBox, post-frame navigation correction, retry or golden test. | Fail-closed boundary test and final diff scan. | DONE |
| SAFE-01 | global | workspace | User-owned `.tmp-*` logs and `test/.../failures/` remain untouched and uncommitted. | `git status`, staged diff inspection. | DONE |

## Differential root-cause proof

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| AUDIT-01 | §7 | rail-to-presentation call graph | Month/day and year/month paths are mapped side by side; every operation unique to year/month is identified. | Root-cause audit with concrete files/methods. | DONE |
| AUDIT-02 | §7–§10 | prepared presentation | Frame size, preview rows/groups, equality/hash/copy, notifier fanout, rebuild/layout/paint, labels and Sliver identities are audited. | Source audit, 24-row widget fixture and 30-run traces. | DONE |
| AUDIT-03 | §7, §12 | motion result | Release velocity, ballistic input, endpoint, activity interruption, rail metrics and controller/position/physics identity are measured independently. | 30 identical empty/populated runs with 24-row monthly payload. | DONE |
| AUDIT-04 | §16 | first access | The first year/month frame has no lazy VM/projection/format/asset initialization during the first fling. | First/tenth trace, immutable prepared-model boundary and operation counters. | DONE |
| ROOT-01 | §3, §7 | causal report | A concrete measured first divergence is recorded before production behavior changes. | 24 rows expanded to 71 sliver children and an O(groups) painter walk; root-cause report. | DONE |

## Canonical temporal navigation

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| TEMP-01 | §5–§6 | time-navigation domain/state | One immutable `DashboardTemporalAnchor` owns visible year/month/day, source plane/keys/ordinal, direction, filter identity, revision and navigation epoch. | Domain tests and source ownership scan. | DONE |
| TEMP-02 | §5.1 | navigation write path | Only semantic navigation commits mutate the anchor; data/index/LogBox/amount/animation/post-frame/stale callbacks cannot. | Boundary test plus stale-callback tests. | DONE |
| TEMP-03 | §5.2 | Year → Month | `year:2026` with May retained/settled always derives `month:2026-05`; closed rail uses retained May; no stale committed key is read. | Unit/controller tests. | DONE |
| TEMP-04 | §5.3 | Month → Year | `month:2026-07` derives `year:2026` with July retained. | Unit/controller tests. | DONE |
| TEMP-05 | §5.4 | SUM ↔ Year | Selected year is preserved in both directions through the anchor. | Unit/controller tests. | DONE |
| TEMP-06 | §6 | transition transaction | Each plane transition performs one anchor derivation, one atomic navigation commit and one visual target; no second correction. | Notification/publish counters and controller/presentation test. | DONE |
| TEMP-07 | §14.1 | regression | Year 2024 → Year 2026 → Month targets 2026 on the first attempt. | Deterministic unit and presentation-controller tests. | DONE |
| TEMP-08 | §14.2–3 | retained child | Year May and Month July round trips preserve the exact child. | Unit tests. | DONE |
| TEMP-09 | §14.4–5 | epochs | Rapid 2024 → 2026 → plane switch is latest-wins; a stale 2024 callback cannot mutate the anchor. | Epoch/stale callback tests. | DONE |
| TEMP-10 | §14.6–7 | direction/rail | Direction toggles and open/closed rail produce the same temporal target and never lose the anchor. | Parameterized tests. | DONE |

## Year/month presentation isolation

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| PRES-01 | §8 | prepared presentation domain | The frame exposes immutable constant-time `PreparedSummaryFrame` and `PreparedLogViewportPayload` identities/references; no full row graph copy occurs on selection. | Model pointer-identity/copy tests. | DONE |
| PRES-02 | §9 | equality | Crossing performs no `ListEquality`, `DeepCollectionEquality`, row walk, deep hash, projection, formatting or list/map copy. | Fail-closed source boundary and operation counters. | DONE |
| PRES-03 | §8–§10 | visible lanes | Crossing selects summary and `logViewportId` by O(1) lookup and frame-bound coalescing; no timer/backlog/settle wait. | Store/coalescer tests and timings. | DONE |
| PRES-04 | §11 | rail dependencies | Rail subtree observes only controller/position/physics/catalog/logical selection; presentation payload dependency triggers `RAIL_PRESENTATION_DATA_DEPENDENCY_VIOLATION`. | Architecture test/assert counter. | DONE |
| PRES-05 | §9, §15 | density cost | 0-row and real 24-preview-row/94-entry month select/apply does not scale linearly with entry count. | 30-run trace: apply p95 993/1110 µs, exact endpoint parity. | DONE |
| LOG-01 | §8–§9 | LogBox prepared payload | LogBox receives the same bounded immutable payload by `logViewportId`; State/controller/sliver identity remain stable. | Widget identity and payload tests. | DONE |
| LOG-02 | §9, §12 | LogBox render | Year/month does not traverse or eagerly build offscreen monthly rows/groups in the rail frame; visible rows remain present and lazy. | 24 groups produce 24 lazy transaction slots; painter binary-searches visible groups. | DONE |
| LAYOUT-01 | §12 | rail geometry | Empty/populated year/month keeps viewport, constraints, item extent, scroll extents and motion identities identical; no `correctPixels` or activity replacement. | 30-run recorder and identity assertions. | DONE |
| REBUILD-01 | §11, §15.5 | subtree isolation | One month crossing has root/SummaryPill/rail/SVG build deltas of zero. | Counter assertions in every density trace. | DONE |
| IO-01 | §18.11 | runtime boundary | Navigation/crossing/settle starts zero SQL, repository, native/bridge or prepared-index work. | Fake-transport/counter suite and every density trace. | DONE |

## Diagnostics, tests, profile and delivery

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| DIAG-01 | §13 | bounded diagnostics | `TEMPORAL_ANCHOR_CHANGED` and `PLANE_TARGET_DERIVED` contain the requested typed fields without hot-path string payloads. | Recorder unit tests. | DONE |
| DIAG-02 | §13 | year/month diagnostics | `YEAR_MONTH_FRAME_SELECTED/APPLIED` expose IDs/density/timings/rebuild-layout-paint deltas. | Recorder and profile schema tests. | DONE |
| DIAG-03 | §11, §13 | violations/summary | Rail presentation-dependency violation and `RAIL_FLING_SUMMARY` are bounded and disabled/no-op by default. | Capacity/disabled path tests. | DONE |
| TEST-01 | §14 | temporal suite | All seven required temporal scenarios pass without golden tests. | Focused Flutter unit/controller/presentation tests. | DONE |
| TEST-02 | §15 | performance suite | Empty/94-entry, 30-repeat, O(1), equality, rebuild, first/tenth and month/day regression tests pass. | Density trace, profile schema and widget tests. | DONE |
| TEST-03 | §3, §17 | golden prohibition | No golden test or asset is written, regenerated or run as evidence. | Git diff/test command scan. | DONE |
| PROF-01 | §13, §15 | profile validation | Profile-mode year/month empty/populated and first/tenth results include apply/UI/raster percentiles, activity/metrics/rebuild/allocation/GC. | Exact-commit GitHub profile artifact. | NOT DONE |
| VERIFY-01 | global | local verification | Full non-golden suite, analyze and boundary tests pass in Ubuntu proot. | 262/262 PASS; analyze `No issues found!`; `git diff --check` PASS. | DONE |
| VERIFY-02 | project workflow | online build | Final branch is committed/pushed and exact-commit GitHub tests/profile/APK complete. | Actions run and artifacts. | NOT DONE |
| REPORT-01 | §19 | final report | All requested factual fields and every acceptance criterion are reported PASS/FAIL; any FAIL is not merge-ready. | Final report inspection. | NOT DONE |
