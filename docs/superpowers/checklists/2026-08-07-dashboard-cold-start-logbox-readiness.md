# Dashboard cold-start LogBox readiness acceptance checklist

Date: 2026-08-07

Source: the user's “FLUVI DASHBOARD — FINAL RAIL/LOGBOX RENDER ISOLATION +
COLD-START READINESS REFAKTOR” instruction in the current conversation.

Milestone commit: `fb6aaec4573fd8728bfc5e1f14ca062ec74fd0fe`

Milestone branch:
`milestone/best-runtime-before-cold-start-logbox-render-isolation`

Milestone tag:
`milestone/best-runtime-before-cold-start-logbox-render-isolation-20260807`

Work branch: `refactor/dashboard-cold-start-logbox-readiness`

Comparators:

- previous final: `9c066f3ecbfa6d64e2a264e11d4878cb84ec7ba3`
- physical-device regression comparator: `c35c680276385deda5a7fad6e116c486634bd4eb`

Status vocabulary: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This file is the release gate. Compilation, CI or an APK cannot complete the
work while any required row is `PARTIAL`, `BLOCKED` or `NOT DONE`.

## Milestone, preservation and evidence

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| MILE-01 | §1 | Git history | The best current runtime is recoverable by branch, exact milestone commit and annotated tag; implementation uses a separate branch. | `git show`, `git branch`, `git tag`. | DONE |
| MILE-02 | §1 | baseline inventory | Milestone/current/c35 hashes and rail physics, controller, prepared index, LogBox and bootstrap SHA-256 values are recorded. | Root-cause report baseline table. | DONE |
| MILE-03 | §1 | verification | Fresh full non-golden baseline and analyze pass in Ubuntu proot. | 262/262 PASS; analyze `No issues found`. | DONE |
| FREEZE-01 | §1, §19 | rail physics/controller | Physics, item extent, gesture mapping, controller and position implementation remain byte-identical. | SHA-256 and empty diff against milestone. | DONE — frozen paths have no work-branch diff; final hash recheck remains part of VERIFY-01. |
| SAFE-01 | global | workspace | User-owned `.tmp-*` logs and `test/.../failures/` remain untouched and uncommitted. | `git status`, staged-diff inspection. | DONE |

## Root-cause and first-use proof

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| AUDIT-01 | §2–§5 | startup/readiness call graph | Spinner work, dashboard mount, first layout, first populated presentation and first interaction are mapped to concrete owners/functions. | Root-cause report and source links. | DONE |
| AUDIT-02 | §5 | first-use inventory | Every `late final`, cache miss, asset/vector/font/text/layout/sliver/render/semantics/layer/GC first-use candidate is inventoried. | Source audit plus bounded diagnostic events. | DONE — root-cause inventory and typed subsystem events cover the rail-critical lifecycle; unsupported per-gesture GC/allocation is explicitly capability-marked. |
| AUDIT-03 | §6–§7 | end-to-end render timeline | Child crossing is timed through selection, notification, build, layout, paint and presented frame, not only pointer swap. | Widget/profile recorder tests and physical report. | PARTIAL — exact AOT evidence exposed and a red/green test corrected the presented-frame metric from the outer repaint probe to the actual CustomPainter surface; final exact artifact and device timeline remain. |
| AUDIT-04 | §7–§8 | real gesture sampling | Real pointer gaps, drag-end velocity, ballistic input and release-frame work are recorded without per-pixel stdout. | Bounded ring-buffer schema/export test and device run. | PARTIAL — bounded recorder/export is verified; target-device evidence awaits PROF-02. |
| AUDIT-05 | §7 | density differential | Month/day empty/populated and year/month empty/populated first/2nd/5th/10th timelines identify what warms. | Cold-first fixture and physical report. | PARTIAL — 30× matrix plus exact AOT first/2nd/5th/10th artifact exist; all synthetic inputs/endpoints match, while physical-device sampling remains blocked. |
| ROOT-01 | central question | causal report | The earliest evidenced mechanism common to `c35c680` and current code is named; scripted harness blind spots are documented. | Source comparison, run `31163562199`, corrected CustomPainter trace and pre-fix source. | DONE — the stable painter still performed four `TextPainter.layout` calls per row plus day-header layout; first child strings warmed paragraph/font work inside fling paint frames. |

## Single interaction-readiness contract

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| READY-01 | §3 | dashboard application | One `DashboardInteractionReadiness` is the sole lifecycle owner with `databasePending`, `indexBuilding`, `presentationPreparing`, `renderCriticalWarmup`, `ready` and failure semantics. | Unit tests and ownership boundary scan. | DONE |
| READY-02 | §3–§4 | app shell/bootstrap | The replaced bootstrap gate is removed; no parallel/legacy readiness source remains. | Architecture test and source scan. | DONE — old owner/test deleted. |
| READY-03 | §4 | readiness barrier | `ready` requires the valid prepared index, semantic catalog, bounded current/adjacent payloads, indexed resources and the normal visible LogBox render surface to have presented. | Unit/widget tests. | DONE — resource readiness uses three bounded atlas surfaces and exact-width pinned text paragraphs before the surface acknowledgement. |
| READY-04 | §3, §12 | interaction gate | Rail, SummaryPill and temporal navigation accept no user intent before `ready`; spinner overlay remains until the same moment. | Widget tests and intent counters. | DONE — final dashboard is mounted under one absorbing gate and spinner overlay. |
| READY-05 | §4, §12 | normal first layout | The one real current Dashboard/LogBox surface is mounted during `renderCriticalWarmup`; no hidden/offscreen child dashboard, `IndexedStack` or 256-widget pre-render is used. | Boundary test and widget identity test. | DONE |
| READY-06 | §5, §15 | post-ready invariant | No rail-critical `FIRST_USE_WORK_STARTED`, cache miss, asset parse, VM build, row identity creation, controller or heavyweight viewport creation occurs after `ready`. | Hard diagnostic assertions, source boundary and first-fling test. | DONE — stable build/paint contains no `.layout(`; `logTextLayoutFallback` is a profile-gate zero counter. |
| READY-07 | §12 | retry/failure | Readiness failure exposes the existing retry UI and retry creates one coherent lifecycle without leaking a mounted interactive surface. | Controller/widget tests. | DONE |

## Stable bounded LogBox render surface

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| LOG-01 | §6, §9–§10 | LogBox viewport | One stable visible viewport State, ScrollController and render hierarchy survive empty/populated and child crossings. | State/controller/render-object identity widget tests. | DONE |
| LOG-02 | §9 | prepared payload | Horizontal preview contains only the visible viewport plus bounded overscan; 94/700/full page rows never become horizontal-motion children. | VM/cache unit tests and 94-entry widget fixture. | DONE — 100,000-total stress remains 24 prepared rows. |
| LOG-03 | §9–§10 | slot renderer | A bounded slot/render model updates prepared row references without 0→N `SliverList`/row Element/RenderObject/semantics/layer churn. | Widget/render counters and source boundary. | DONE — one CustomPaint surface; no row Widgets/RenderObjects. |
| LOG-04 | §10 | visual semantics | Group header/gap/card treatment remains visually equivalent and row hit-testing/accessibility remain correct without separate structural children. | Widget semantics/hit-test tests and direct source inspection; no golden. | DONE — bounded custom semantics/tap tests pass. |
| LOG-05 | §9, §17 | paging | Explicit committed vertical near-end paging still appends prepared rows and remains the only detailed-list acquisition trigger. | Paging integration/widget tests. | DONE |
| LOG-06 | §6 | end-to-end events | `LOGBOX_FRAME_PRESENTATION_STARTED/PRESENTED` contain density, build/layout/paint/presented timing and structural counters. | Recorder schema/capacity tests. | DONE |
| LOG-07 | §20.6–7 | bounded cost | 94-entry/dense months create at most the bounded visible/overscan surface, and render cost does not scale with total entry count. | 0/2/4/9/24/94/dense performance matrix. | PARTIAL — structural bound, 30× matrix and exact AOT bounded slot counts pass; corrected surface percentiles await the final run and physical confirmation. |

## Resource, paint and cache isolation

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| RES-01 | §4–§5 | category/icon/text resources | Deterministically preparable rail-critical assets, lookup tables, row identities and reusable formatter/resource objects are ready before interaction. | Readiness tests, exact-width paragraph pin test and zero first-use counters. | DONE |
| RES-02 | §5, §11 | vector renderer | The LogBox hot paint path performs no first SVG/vector decode and no per-row tint `saveLayer`; bounded prepared category imagery is reused. | Painter boundary test and paint diagnostics. | DONE — one badge atlas, one icon atlas and one group surface; no per-paint sprite allocation. |
| RES-03 | §11 | group/card paint | Shadow/clip/layer policy is bounded; a denser month cannot create an unbounded blur/layer burst. | Layer/saveLayer counters and profile timeline. | PARTIAL — one prepared nine-slice surface is source/test proven; profile timeline pending. |
| PAINT-01 | §11 | repaint boundaries | Rail, LogBox, direction pulse and dashboard background have isolated dirty regions; LogBox changes do not repaint the rail/background/SVG subtree. | Repaint/build counters and widget tests. | DONE |
| CACHE-01 | §13 | cache inventory | Data, prepared presentation, asset, text/layout, renderer/layer and viewport caches document owner/key/lifetime/warmup/eviction/max/miss behavior. | Root-cause report cache table. | DONE — text cache key is entry ID + precomputed text identity + live width; State lifetime; explicit replacement/disposal; 8,192-row hard cap. |
| CACHE-02 | §13 | critical miss guard | `RAIL_CRITICAL_CACHE_MISS` is a hard debug/test violation after `ready`; current/adjacent parent resources are bounded and explicitly pinned. | Unit/widget invariant tests and exact profile gate. | DONE |
| MEM-01 | §14 | memory budget | Prepared index, viewport payloads, row VMs, asset cache, Flutter/native/graphics memory are measured and bounded; no full-widget preload. | Test estimates and profile RSS/memory artifact. | PARTIAL — exact AOT peak RSS, 5,035,814-byte index and 1,745,280-byte/three-surface raster cache are exported; per-gesture Flutter/native/graphics subdivision is unavailable and capability-marked. |

## Diagnostics, non-golden tests and profile

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| DIAG-01 | §5, §18 | bounded diagnostics | First-use, critical-cache, readiness, LogBox presentation and real-gesture records use an in-memory bounded ring and never stdout-log motion pixels. | Recorder unit tests/source scan. | DONE |
| DIAG-02 | §18 | device export | A user can export one aggregated physical-device report with first ten fling timelines, pointer gaps, velocities, deltas, frame/render/GC/first-use/cache fields. | UI/export schema widget test and documented device steps. | DONE — profile APK exposes clipboard export; unsupported per-gesture GC/allocation fields are capability-marked rather than fabricated. |
| TEST-01 | §15 | ready-first-fling architecture | After `ready`, first fling performs zero I/O/projection/format/parse/VM/key/cache/controller/viewport first-use work. | Fail-closed architecture/widget test. | DONE |
| TEST-02 | §16 | first/tenth parity | A truly cold first fling (without fixture warmup) and tenth fling differ by ≤1 child, have zero critical first-use/miss, and no structurally worse frame profile. | Recorded-pointer regression test. | PARTIAL — run `31163562199` correctly failed duration parity and exposed paint-time paragraph layout; local red/green tests now prove zero post-READY layout fallback, but the corrected exact AOT rerun and physical parity remain. |
| TEST-03 | §17 | empty/populated parity | Month/day 0/2/4/9 and year/month empty/sparse/24-preview/94/dense use identical motion identities and bounded rendering. | Parameterized tests. | DONE — 30 repetitions per pair. |
| TEST-04 | §19 | prohibited solutions | No physics tuning, velocity compensation, hidden/offscreen prewarm, content freeze, settle-only update, debounce/throttle, unlimited cache, DB rewrite or golden test. | Boundary/source scan and git diff. | DONE |
| TEST-05 | §9, §15 | no data work | Navigation/100 crossings/20 settles cause zero SQL/repository/bridge/index build/projection/format work. | Existing and extended fake-counter suite. | DONE |
| PROF-01 | §7, §13, §16–§18 | profile validation | Exact-commit profile artifact includes first ten timelines, real/synthetic parity, UI/raster, LogBox render, GC/allocation/cache/first-use and memory fields. | GitHub profile workflow artifact. | PARTIAL — run `31163562199` produced corrected CustomPainter evidence and failed first/tenth duration as intended; the new paragraph-readiness commit still needs its exact rerun. Unsupported per-gesture GC/allocation remains capability-marked. |
| PROF-02 | §20.15 | physical validation | A new physical-device diagnostic report confirms first-vs-warm parity. Emulator/CI alone is explicitly insufficient. | User-run exported report. | BLOCKED |
| VERIFY-01 | global | local verification | Focused tests, full non-golden suite, analyze, boundary scan and `git diff --check` pass in Ubuntu proot. | Command output. | DONE — focused readiness/render/profile/boundary suite 26/26 PASS; full non-golden suite 282/282 PASS in 3:26; analyze `No issues found` in 156.9 s; frozen-source diff and `git diff --check` are clean. |
| VERIFY-02 | project workflow | online delivery | Final commit is pushed; exact-commit GitHub tests/profile/APK finish and APK is downloaded to `/storage/emulated/0/Download/fluvi`. | Actions run/artifact/hash. | PARTIAL — `cbf46d56` tests/profile/APK completed and its verified APK is downloaded; corrected diagnostic/workflow final HEAD still requires an exact run. |
| REPORT-01 | §21 | final report | All requested factual fields and every acceptance criterion are reported PASS/FAIL; any remaining FAIL/BLOCKED is not merge-ready. | Final report inspection. | PARTIAL — source/root-cause report is current; final exact-run and physical-device status remain. |
