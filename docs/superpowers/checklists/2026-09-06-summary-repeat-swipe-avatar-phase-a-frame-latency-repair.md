# Summary repeat swipe / Avatar Phase-A authority / latency — acceptance checklist

Source of truth: the user-approved execution authorization of 2026-09-06,
the immutable evidence snapshot manifest at
`docs/superpowers/evidence/2026-09-06-profile-9e8a7b3a-session-fluvi-1788686737010611/manifest.json`,
and CURRENT `9e8a7b3…` source. A green build, a test, or an APK alone does
not mark a physical requirement DONE.

| ID | Source instruction / evidence | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| BASE-01 | User §1, revised stop conditions | Git worktrees / refs | Repair worktree, physical app ref and graph manifest remain at exact `9e8a7b3…`; tooling remains `70aa55a…` | Fetch/preflight commands; manifest inspection | DONE |
| EVIDENCE-01 | User §§1–4 | Frozen local evidence | Three full Drive documents are frozen once, hashed, read-only, deduplicated by seq, and later Drive mutations cannot silently alter this cycle | Snapshot manifest, SHA-256 verification, duplicate comparison | DONE |
| EVIDENCE-02 | User §2 | Forensics | Historical `178866…` is explicitly labelled same-SHA history; current `178868…` is authoritative; no old range/count is reused as current evidence | Forensic journal review | DONE |
| SUMMARY-DIAG-01 | User §4 | `summary_pill_experiments.dart`, `core_dashboard.dart`, carousel/coordinator diagnostics | Each attempted selector pointer has bounded raw-start, hit classification, selected visual/interaction/semantics rects, variant/geometry, callback and ownership evidence | Persistent production-parent diagnostic/reproducer | PARTIAL — bounded start/hit evidence is wired; device trace still needed for actual Flutter arena winner/path |
| SUMMARY-REPRO-01 | User §4 | Existing segmented Summary + upper vertical coordinator | Rapid repeat day swipes at 0/16/32/50/100/250/500/1000 ms reproduce current route without recreating dashboard/controller/physics | Red production-parent test without `pumpAndSettle` | DONE — clean-9e red boundary probe and persistent production-parent timing matrix |
| SUMMARY-OWNER-01 | User §§4–5 | Segmented selector interaction boundary | A pointer beginning in the intended selector cell reaches selector ownership immediately, preempts hold/ballistic activity and never starts collapse | Boundary matrix: center/edges ±1 px, separator, amount, background; event/behavior assertions | DONE — geometry-derived cells, selector-exclusive repeat test and no controller/position/physics recreation |
| SUMMARY-BACKGROUND-01 | User §§4–5 | `DashboardUpperVerticalGestureCoordinator` | Genuine background vertical drags still expand/collapse; one pointer has one owner; no timer/cooldown/forced settle | Production-parent background-drag regression | DONE — unassigned background remains the collapse owner |
| SUMMARY-GEOMETRY-01 | User §4 | `SummarySegmentedTrackGeometry` only if red test proves glyph hit region too small | Separate visual, interaction and semantics rects are geometry-derived, disjoint, responsive, do not change visual placement or invade amount/background zones | Unit geometry matrix + widget hit/semantics test | DONE — midpoint/separator-derived interaction cells; original visual rect is retained via layout transform |
| AVATAR-RED-01 | User §5; frozen Avatar seq 1337–1358 and equivalents | `DashboardLogBoxPreparedSceneCache`, `DashboardLogBoxViewport`, core Avatar activation | Real production parent proves committed private prearm can be armed while the railPreview painter reports `hasCompleteReadablePhaseAFor(exactPayload)==false` | Focused red test using actual resource/cache owners | DONE — clean-9e red probe then green production-parent/cache regressions |
| AVATAR-AUTH-01 | User §5 | Same existing prepared-scene cache and publication boundary | Nonempty Avatar payload becomes visible only when the exact active painter can discover its compact Phase-A geometry + row/header resources, or candidate is coalesced while prior valid visual remains | Red/green parent test; exact resource-owner identity assertions | DONE — exact binder validates the active cache authority before visible publication |
| AVATAR-OUTCOME-01 | User §5 | Avatar target recorder / LogBox acknowledgement | Every accepted target has one terminal outcome: exact Phase A, rich Phase B, exact empty, coalesced, stale or cancelled; no current target ends missing-resource, zero-row nonempty, or 13 px surface | Identity-deduplicated terminal-outcome tests and bounded diagnostics | PARTIAL — current missing-resource path is gated before acceptance; broad physical terminal-outcome audit awaits the new APK |
| AVATAR-MEM-01 | User §5 | Prepared-scene cache | Sparse bounded window remains bounded; no eager all-target geometry, second cache/store, or cache-limit increase | Resource-window cap/memory regression and source inspection | PARTIAL — source and existing cache tests protect bounded existing bank; no physical retained-bank measurement this cycle |
| AVATAR-PERF-01 | User §6 | Existing FrameTiming / visual binding instrumentation | Remeasure current FrameTiming after correctness repair and optimize only a correlation-proven residual build/raster source | Before/after profile diagnostic summary; no device-specific unit-test threshold | PENDING — USER/PROFILE APK measurement after correctness repair; physics intentionally unchanged |
| SLIDER-DIAG-01 | User §7 | Existing RangeSlider/Mind coordinator diagnostics | One bounded drag summary distinguishes raw pointer, recognizer, onChanged, normalization, preview, membership, publish, exact-empty/nonempty, visible rows, paint and raster | Production-parent pipeline instrumentation test | PARTIAL — one summary per drag now covers pointer/recognizer/value/preview stages and shares flow with paint acknowledgement; its Listener/Stopwatch/counters are compile-time diagnostic opt-in and physical raster evidence remains pending |
| SLIDER-BEHAVIOR-01 | User §7 | Mind slider/query/count | No production behavior/query/count change unless a deterministic test plus fresh pipeline evidence identifies an application bottleneck | Diff review + unchanged live-count regression | DONE — no behavior change authorized yet |
| TIME-PROTECT-01 | User §8; frozen Time flights 18–22 | Time projection, LogBox render/extent, target acknowledgement | No Time semantic/query/paint/extent change; existing exact paint/empty/coalescing and zero tick heavy work remain green | Existing Time production-parent regressions run unchanged | DONE — targeted Time/LogBox production-parent coverage remains green; no Time production source changed |
| OWNER-01 | Global architecture gate | Shared controller/cache/render flow | No second controller, visible-frame store, LogBox, resource cache or copied gesture engine; UI remains intent/rendering only | Architecture card, dependency/source inspection, focused boundary test | DONE — existing prepared-scene cache is bound through the existing coordinator; no new owner was allocated |
| HOTPATH-01 | User §§5–8 | Summary/Avatar/Mind hot paths | No DB/query/index/rich projection/TextPainter work at semantic ticks; no timer/cooldown/reduced target frequency/physics retune | Flight counters, source inspection, focused tests | DONE — cache-only compact resource binding; new Mind pointer diagnostics are opt-in rather than retained on a normal release slider path; no timer or physics change |
| PROFILE-IDLE-01 | Repeated aa26 profile-gate failures; current `CenteredCarouselController` source | Shared terminal motion lifecycle | A terminal `HoldScrollActivity` that becomes idle cannot leave the Time motion kernel in `drag`; it must publish one current settle without controller recreation, delay, timeout expansion or physics change | Red/green shared-carousel widget test plus Time/profile validation | PARTIAL — pre-fix red test observed; bounded one-retry green tests and the persistent `CoreDashboard -> TimeRefinementRail -> DashboardMotionKernel` regression pass locally; exact new-SHA profile validation remains required |
| VALIDATE-01 | User §9 | Changed Dart/test surfaces | Red tests observed first; format, analyzer, focused, app, fast and presentation suites are compared against exact 9e baseline | Exact proot commands and normalized failures | PARTIAL — current change passes format, analyzer, shared motion (`+35`), Summary (`+48`), CoreDashboard (`+31`), application (`+278`) and fast (`+291`); presentation is `+583 -19`, matching the documented clean-9e inherited signatures; remote CI remains pending |
| DELIVERY-01 | Global AGENTS + user §5 | App branch / GitHub Actions | Atomic application commits are pushed; exact normal human APK is built online, downloaded to `/storage/emulated/0/Download/fluvi`, and SHA-256 recorded | GitHub run/artifact/download verification | NOT DONE |
| GRAPH-01 | User §5 | Tooling worktree only | Separate SCIP regeneration indexes exact final app SHA; deterministic tooling checks pass and tooling commit is pushed | Manifest/hash/tooling test report | NOT DONE |
| PHYSICAL-01 | User | Device | Human validates repaired behavior | User-only device test | PENDING — USER ONLY |

## Test matrix

| Test group | Production parent / persistent owners | Required assertion |
| --- | --- | --- |
| Summary rapid repeat | One CoreDashboard, CoreController, segmented Summary, upper coordinator and carousel controllers | Selector pointer at each interval/activity is exclusive; no collapse for selector ownership |
| Summary boundary | Actual layout geometry under normal/mirrored widths and selector combinations | visual/interaction/semantics rects and background cells are deterministic/non-overlapping |
| Carousel terminal lifecycle | Shared carousel controller plus persistent CoreDashboard/Time rail | one current settle after transient Hold→Idle; persistent Hold has one bounded retry and no unbounded frame scheduling |
| Avatar resource gap | Actual CommittedLogViewportCache + PreparedSceneCache + stable LogBox surface | private prearm alone is not painter readiness; exact bounded Phase A paints by next frame |
| Avatar rapid targets | Real category/partner focus sequence in one dashboard | exact terminal classification; coherent selected/header/distribution/count/LogBox/paint identity |
| Avatar memory/perf | Real resource-window owner and existing FrameTiming collector | bounded bank; no heavy tick work; measured residual only |
| Slider pipeline | Real RangeSlider, typed count and LogBox parent | pointer-to-visible result stages, exact empty/nonempty distinction, no semantic change |
| Time protection | Existing production Time parent | Time correct rows/empty/identity/handoff and zero per-tick heavy work unchanged |

## Pre-commit gate

Before every application commit: reread this checklist, the architecture card,
the frozen manifest and the relevant source/test paths. No status may move to
DONE because an APK or an event-start assertion exists. Physical validation
always remains **PENDING — USER ONLY**.

## Current automated validation record

- **Red first:** clean `9e8a7b3` proof showed a point immediately left of the
  day glyph rect was background-owned (`Expected <1>; Actual <0>`), and the
  private committed resource-window probe showed
  `hasCompleteReadablePhaseAFor(focusedPayload)==false`. Both probes were
  removed from the clean control after recording their result.
- **PASS:** `dart format --output=none --set-exit-if-changed` over all 13
  changed Dart files — `Formatted 13 files (0 changed)`.
- **PASS:** `flutter analyze` — `No issues found!`.
- **PASS:** changed focused compound suite — `+185`.
- **PASS:** Avatar/LogBox direct batch — `+124`.
- **PASS:** Summary/geometry/motion batch — `+39`; diagnostics batch — `+17`.
- **PASS:** direct focused groups: Summary experiments `+28`, CoreDashboard
  `+30`, prepared-scene cache `+47`, query range `+7`, core ephemeral focus
  `+48`.
- **PASS:** the new Slider release-opt-out red/green regression (`+8` for the
  direct range-control group) proves that a control with an available summary
  callback but disabled diagnostics has no passive pointer probe, Stopwatch or
  per-drag summary, while its preview/commit lane remains unchanged.
- **FAIL — inherited control:** `dashboard_logbox_stable_render_surface_test.dart`
  fails identically on clean 9e and repair branch: `Too many elements` at its
  `find.byType(Scrollable)` singleton assumption.
- **FAIL — inherited control:** direct
  `dashboard_header_space_fabric_temporal_test.dart` fails identically on
  clean 9e with eight header/ticker failures; no production header source was
  changed.
- **PASS:** `flutter test test/features/dashboard/application --reporter
  failures-only` — `+278`.
- **PASS:** `PATH=/home/flutteruser/flutter/bin:$PATH
  ./scripts/test-fluvi-fast.sh` — `+291`. The first script attempt is recorded
  separately as an environment invocation failure because its inherited shell
  PATH did not expose `flutter`; it did not run tests.
- **FAIL — normalized inherited:** `flutter test
  test/features/dashboard/presentation --reporter failures-only` — `+582 -19`.
  The exact 19 failures match the clean-9e header/golden/ticker and stable
  render-surface signatures; the changed Summary, Avatar Phase-A and Mind
  diagnostics tests pass within that run. No golden was regenerated. Remote
  CI remains the delivery gate.

- **PASS — current terminal-lifecycle repair:** both new shared-carousel
  red/green regressions and `time rail settles after a terminal non-scrolling
  Hold handoff` pass. The complete
  `test/features/dashboard/presentation/core_dashboard_test.dart` suite also
  passes (`+31`).
- **PASS — current change:** proot formatter reports `Formatted 3 files (0
  changed)`; `flutter analyze` reports `No issues found!`; the shared motion
  batch is `+35`, the Summary batch is `+48`, the application suite is `+278`,
  and `./scripts/test-fluvi-fast.sh` is `+291`.
- **FAIL — normalized inherited:** the complete presentation suite is
  `+583 -19`. The extra passing test is the new terminal-Hold regression; the
  19 failure count and observed header/golden/ticker/Scrollable signatures
  match the clean-9e baseline. The protected direct Time/LogBox batch similarly
  completes `+71 -1`; its sole failure is the same pre-existing
  `find.byType(Scrollable).single` assertion in
  `dashboard_logbox_stable_render_surface_test.dart`.
