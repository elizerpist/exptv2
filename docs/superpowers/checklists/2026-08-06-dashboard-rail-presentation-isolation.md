# Dashboard rail/presentation isolation acceptance checklist

Date: 2026-08-06

Source: the user's “FLUVI DASHBOARD — MILESTONE UTÁNI CÉLZOTT
RAIL/PRESENTATION IZOLÁCIÓ” instruction in the current conversation.

Pre-milestone implementation commit:
`c083ef403c45e7365779734d13cd0683a9f371ce`

Milestone commit:
`2243cfda9d507f4e55124713c50b320b07520fae`

Milestone branch:
`milestone/dashboard-best-performance-before-rail-presentation-isolation`

Milestone tag:
`milestone/dashboard-best-performance-before-rail-presentation-isolation-20260806`

Work branch: `refactor/dashboard-rail-presentation-isolation`

Status vocabulary: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This checklist is the release gate. Compilation, green CI or an APK does not
complete the work while any required row is `PARTIAL`, `BLOCKED` or
`NOT DONE`.

## Milestone and proof-first audit

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| BASE-01 | §2 | Git history | The best-performing code is recoverable through a dedicated branch, exact milestone commit and annotated tag; work proceeds on another branch. | `git branch`, `git show`, `git tag`. | DONE |
| BASE-02 | §2 | baseline evidence | Baseline commit, rail/physics/controller/index SHA-256 values, tests and interaction acquisition counters are recorded. | Baseline audit document. | DONE |
| BASE-03 | §2 | verification | Full non-golden Flutter baseline passes and analyze has no findings in Ubuntu proot. | 237/237 tests; `No issues found`. | DONE |
| BASE-04 | §2 | workspace safety | User-owned untracked `.tmp-*` and failure artifacts remain unmodified and uncommitted. | Status/diff inspection. | DONE |
| AUDIT-01 | §4 | call graph | SummaryPill, plane, parent, rail open/close/cross/settle, direction, commit, revision, Room, bridge, decode, visible publish, amount/count and LogBox paths are mapped to concrete methods/listeners. | Root-cause audit document and source links. | DONE |
| AUDIT-02 | §4–5 | dynamic proof | Gesture release velocity, ballistic input, endpoint, activity lifecycle, metrics, identity, presentation apply and pointer-release overlap are measured independently. | Typed flight-recorder events and 270-fling deterministic matrix. | DONE |
| AUDIT-03 | §7 | causal decision | The exact first divergence is identified before any production behavior fix is made. | Equal velocity/input/endpoint and zero interruption/metrics; first divergence is populated LogBox render work. | DONE |

## Non-negotiable preservation constraints

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| KEEP-01 | §3 | carousel physics/spec | No friction, sensitivity, velocity multiplier/threshold, snap, max distance or item extent tuning. | Physics/math/metrics/index hashes exactly match milestone; no diff. | DONE |
| KEEP-02 | §3 | gesture/motion | No manual fling, timed stepping, GestureDetector `animateTo`, debounce, throttle, settle-only preview or crossing suppression. | Static boundary test and semantic diff. | DONE |
| KEEP-03 | §3 | identities | No navigation-dependent controller, ScrollPosition, physics, viewport or QueryKey remount. | Flight traces and widget identity/recreation counters. | DONE |
| KEEP-04 | §3 | presentation | No hidden LogBox during motion, fake populated UI, cached Widget trees, eager IndexedStack, shrinkWrap or full child pre-render. | Boundary scan and widget inspection. | DONE |
| KEEP-05 | §1, §14 | existing behavior | Prepared index, bootstrap barrier, instant first frame, intermediate first-fling values, visual rail mechanics, cyclic/retained-child semantics, direction/plane/Summary navigation and explicit paging remain intact. | Existing and new non-golden suites (249/249). | DONE |
| KEEP-06 | §3, §12 | tests | No golden test or golden asset is added or regenerated. | Git diff and test scan. | DONE |

## Low-overhead causal instrumentation

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| INST-01 | §5 | diagnostic model | One fling has stable gesture, motion and presentation epochs plus parent key, direction and child kind. | Recorder unit/widget tests. | DONE |
| INST-02 | §5.1–5.3 | raw gesture lane | `GESTURE_START`, one aggregated `GESTURE_SAMPLE_SUMMARY`, and `GESTURE_RELEASED` capture the requested position/sample/gap/frame/velocity fields without per-pixel logging. | Diagnostic unit/widget tests. | DONE |
| INST-03 | §5.4 | ballistic handoff | `BALLISTIC_STARTED` captures exact input velocity, simulation/target, geometry, identities and timestamp without changing simulation behavior. | Controller/widget test and physics-target parity matrix. | DONE |
| INST-04 | §5.5–5.7 | crossing/apply lane | Crossing and presentation apply start/completion carry density, digest, frame and split timing/rebuild/layout/paint deltas. | Flight-recorder tests and report-schema tests. | DONE |
| INST-05 | §5.8–5.9 | ScrollPosition lifecycle | Real metric changes, attach/detach and activity transitions/interruption/replacement/idle are recorded with active gesture and apply state. | Widget flight-recorder test. | DONE |
| INST-06 | §5.10–5.11 | timing/settle | Per-gesture frame timing and final settle aggregate include endpoint, crossings, interruptions, metrics, apply/rebuild and zero-I/O counters. | Report-schema and deterministic trace tests. | DONE |
| INST-07 | §5, §13 | overhead | Diagnostics use a bounded typed ring buffer, are disabled/no-op by default, allocate no strings in the hot path, and verbose FLOW logging is off in profile. | Capacity/disabled-path tests and profile configuration. | DONE |

## Deterministic reproduction and causal thresholds

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| REPRO-01 | §6 | integration harness | Scripted input fixes start index/pixels, pointer positions, distances, durations, event cadence and release velocity. | Deterministic widget harness. | DONE |
| REPRO-02 | §6A | month/day fixtures | Empty-only, populated-only, mixed, 0/1–2/7–9 rows, large amount/few rows and bounded-preview cases run at least 30 times. | 150-fling machine-readable aggregate. | DONE |
| REPRO-03 | §6B | year/month fixtures | Empty, 94-row month, 658-row year, mixed and both directions run at least 30 times. | 120-fling machine-readable aggregate. | DONE |
| REPRO-04 | §4, §7 | first divergence | Drag/release velocity, ballistic input, endpoint, interruption, metric and render-only divergence are evaluated separately rather than inferred from feel. | Aggregate comparisons in root-cause report. | DONE |

## Targeted presentation and layout isolation

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PRES-01 | §8 | prepared frame selection | Crossing performs constant-time prepared-frame identity/reference selection with no deep equality/hash, copy, projection, formatting, asset resolution or async work. | O(1) model/store tests and boundary test. | DONE |
| PRES-02 | §8 | presentation lanes | Rail semantic selection, prepared amount, count and LogBox viewport are narrow explicit lanes sourced atomically from one frame; the rail listens to none of the content lanes. | Store and widget architecture tests. | DONE |
| PRES-03 | §7.1, §8 | display frame boundary | Any heavy synchronous notification discovered on the pointer stack is removed; per-display-frame last-target coalescing remains, with no timer, backlog or lost cross-frame targets. | Flight timestamps and existing coalescer tests. | DONE |
| PRES-04 | §8, §11 | rebuild boundary | A crossing rebuilds no dashboard root, Summary shell, rail or SVG subtree; only changed amount/count/label/visible LogBox rows update. | Counter assertions in every density run. | DONE |
| PRES-05 | §8 | identity tokens | `presentationId`, `contentDigest`, `frameId` and `logViewportId` are precomputed constant-time identifiers; row collections are never walked for equality/hash during crossing. | Model/store tests and boundary scan. | DONE |
| LOG-01 | §9 | LogBox state | LogBox State, vertical controller and viewport survive key, density, parent, direction and plane changes. | Identity widget tests. | DONE |
| LOG-02 | §9 | LogBox rendering | Stable lazy sliver consumes bounded preprojected items; no full-list rebuild, group/sort/format/SVG parse, QueryKey remount or nested shrinkWrap. | Boundary and viewport widget tests. | DONE |
| LOG-03 | §9–10 | geometry | LogBox content changes cannot alter rail constraints, gesture surface, viewport dimension or scroll extents. | Empty/populated metric traces: zero changes/corrections. | DONE |
| LAYOUT-01 | §10 | rail geometry | Width, height, item extent, parent constraints, min/max extent, padding, DPR, transform and physics identity are equal for empty/populated frames. | Geometry/identity assertions in deterministic harness. | DONE |
| ACT-01 | §7.3, §12.7 | activity guard | Presentation apply cannot interrupt/replace ballistic activity or cause programmatic scrolling/metric correction. | 270 repeated traces: zero interruptions/metric changes. | DONE |

## Counters, invariants and no-data-work gate

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| COUNT-01 | §11 | build counters | Root, Summary, rail/items, amount, count, LogBox/rows and SVG build counters exist. | Unit/widget tests. | DONE |
| COUNT-02 | §11 | render counters | Rail and LogBox layout/paint counters exist without changing render geometry. | Profile-only render probes and report tests. | DONE |
| COUNT-03 | §11 | identity counters | Controller, physics and position recreation stay zero. | Existing/new tests. | DONE |
| INV-01 | §12.1 | apply invariant | Prepared-frame apply does no copy/projection/format/async work and remains constant-time across row counts. | Model/store and density tests. | DONE |
| INV-02 | §12.2 | velocity invariant | Empty/populated drag-end and ballistic input velocity differ by at most 2%. | 30 repetitions per fixture: measured difference 0%. | DONE |
| INV-03 | §12.3 | endpoint invariant | Same start/input ends within half item extent and one child; interruption and metric-change counts are zero. | 30 repetitions per fixture: exact endpoint parity. | DONE |
| INV-04 | §12.4–6 | density/warm invariant | First/tenth, 0/2/9-day and 0/94-month cases use identical identities and endpoints within tolerance. | Density pairs locally pass; first/tenth profile artifact pending. | PARTIAL |
| INV-05 | §12.8 | layout invariant | Empty→populated produces zero viewport dimension/extent change and zero pixel correction. | Metric trace test. | DONE |
| INV-06 | §12.9 | rebuild invariant | 100 crossings cause root/Summary/SVG deltas of zero and no controller restart. | 270-fling counter assertions. | DONE |
| INV-07 | §12.10 | data-work invariant | 100 crossings and 20 settles cause zero SQL, repository, bridge, index build, format/group/project. | Existing fake-transport interaction suite plus density traces. | DONE |
| INV-08 | §12.11 | immediate repeat | A new fling after settle inherits no queued presentation work or degraded pointer samples. | Rapid-gesture and coalescer tests. | DONE |

## Profile, verification and delivery

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PROF-01 | §13 | profile matrix | Ten requested profile scenarios run with bounded diagnostics and identical scripted inputs where compared. | Profile artifact. | NOT DONE |
| PROF-02 | §13 | report | Gesture/ballistic/endpoint parity, apply p50/p95/p99, UI/raster p50/p95/p99, activity/metrics/rebuild/allocation/GC are reported. | JSON/report-schema test. | NOT DONE |
| PROF-03 | §14 | acceptance | Empty/populated and first/warm motion meet specified tolerances with zero navigation/motion data work. | Automated profile assertions. | NOT DONE |
| PROF-04 | §13, §15 | environment honesty | Emulator evidence is reproducible and explicitly not claimed as physical smoothness proof; exact physical-device steps are documented. | Final report §16. | DONE |
| VERIFY-01 | global | local verification | Targeted RED/GREEN tests, full non-golden Flutter suite and analyze run in Ubuntu proot. | 249/249 tests; analyze clean; boundary and diff checks pass. | DONE |
| VERIFY-02 | global | GitHub/CI | Completed coherent branch is committed and pushed; online checks/build execute. | Branch pushed; native CI passed; Actions partial outage blocks profile/APK jobs. | PARTIAL |
| REPORT-01 | §15 | final report | All 18 requested factual report items and every acceptance row are reported PASS/FAIL; any FAIL is not merge-ready. | Report drafted; AOT evidence fields remain pending. | PARTIAL |

## Automatic failure conditions

The release gate fails if the final diff contains any physics compensation,
time-based debounce/throttle, settle-only presentation, hidden/fake populated
content, QueryKey remount, eager/shrinkWrap list, cached Widget tree, data work
during navigation/motion, a golden test, or a claimed causal fix without the
pre-fix repeated trace proving its divergence point.
