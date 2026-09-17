# Mind temporal heatmaps, fixed footer, and score-atomicity — acceptance checklist

**Status:** `NOT DONE`, `IN PROGRESS`, `DONE`, `PARTIAL`, or `BLOCKED`.
Every `DONE` item needs its listed evidence. **BUILD GATE = CLOSED** until all
functional rows are `DONE` and their focused checks are green.

## Authoritative inputs

- User product/forensic specification, 2026-09-17.
- Runtime feature baseline: `9a8a7575902288eebf8b95ae60c698be035531c4`.
- Test-only/profile assertion source: `c67e713925150a058d1c9a3c85ce55a97af65693`.
- Current journal-only branch head at inventory: `e74905de9d14c3039bd734de6902d761a64e03db`.
- Matching graph: tooling `1d9f1178d41df8784450c2cf6b776cf9fe09121a`,
  `source_head=c67e7139`, `scip_dart=1.6.2`, raw index SHA-256
  `128070323a4a86bb72cd86148df7d7b8ff9b83d8c35cfc69dfb9de3051bd8434`.
- Presentation reference: `origin/spendeetest:balance_latest_layout.html`,
  `createMindAnnualSumGridPrototypeScreen` (B3M-MYS) and
  `createMindMonthlyActivityPrototypeScreen` (B3M-MYM). It is visual/layout
  authority only; its fixture years, totals and intensity arrays are excluded.
- Approved Header-chart visual baseline:
  `/storage/emulated/0/spendee/mind score Reference .png`.

## Architecture card

| Concern | Sole owner/write path | Reused core | Explicitly prohibited |
| --- | --- | --- | --- |
| Temporal heatmap data | `DashboardCoreController` semantic publication coordinator | admitted `MindYearHeatmapPreparedMembership`, focus/range identity, latest-wins generation | Sum/Year/Month Query states, widget aggregation, renderer/repository reads |
| Buckets | immutable temporal heatmap projection/frame | year day buckets and amount-prefix preview strategy | raw-row scan per thumb event |
| Header/heatmap liveness | Core accepted visual-target admission | existing segmented-target acknowledgement and score live projection | timer/debounce/remount, widget-owned score publication |
| Palette and legend | one existing palette resolver | `MindYearHeatmapPaletteResolver` + presentation setting | copied purple/B3M colors in legend or plane-specific palette settings |
| Footer | one Mind surface composition | `QueryAmountRangePresentation.compactMind` | four RangeSlider instances/controllers or plane-specific positions |
| Year six-row envelope | viewport presentation geometry | existing calendar geometry/painter | fake days or a separate calendar source |

## Requirement inventory

| ID | Requirement/source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | §§13–14 | Core temporal coordinator | one semantic identity/range/prepared-membership authority across Sum/Year/Month | boundary + projection tests | DONE — one `mindTemporalHeatmap` Core lane, immutable typed payloads and the mounted Sum/Month/Year range matrix are green. |
| ARC-02 | §§19–21 | Core visual-target admission | heatmap/score/chart/palette publish atomically for accepted target | mounted frame RED→GREEN | DONE — Year RED→GREEN, Sum/Month immediate target and held-slider tests prove one matching frame. |
| ARC-03 | §25 | surface/viewport layers | no new ticker, Query owner, range owner, scroll owner or gesture layer | boundary/source tests + profile B | PARTIAL — application `463222fa` incorrectly retained a passive `dashboard-core-mode-content-gesture-region` around Sum/Year/Month. Online profile B caught the wrong mounted hit-test topology. The repair restores direct temporal-viewport ownership; focused widget evidence is green and the next online profile B is required. |
| LEG-01 | §15.1 | palette resolver + fixed footer | exactly five low→high compact swatches above range | widget test | DONE — `RED LEG-01/04` and the focused Mind suite prove the five fixed swatches are above the compact range. |
| LEG-02 | §15.2 | palette resolver | Fluvi samples existing resolver at .00/.25/.50/.75/1; B3M exact L0–L4; excludes empty/equal range | pure resolver test | DONE — `RED LEG-02` green |
| LEG-03 | §15.3 | presentation controller | palette switch repaints Sum/Year/Month/legend without Query/projection/I/O | live presentation test | DONE — Sum/Month same-frame identity, resolver and Core setting-combination tests are green. |
| LEG-04 | §§15,17 | Mind surface | legend is fixed below temporal content and never scrolls | production-parent bounds/scroll test | DONE — Year and a multi-year scrolling Sum viewport retain identical legend/footer bounds. |
| Y6-01 | §16 | Year MonthCard | all layouts reserve six display rows, equal outer card height | geometry/widget test | DONE — `RED YEAR-6R-01`, the focused Mind suite, and the four-column constrained layout tests are green. |
| Y6-02 | §16 | existing calendar painter | real dates/weekday/Feb 29 correct; unused sixth row paints nothing | painter test | DONE — the painter test proves five-row January has no fabricated sixth-row slots; leap-February projection coverage proves 29 real dates only. |
| Y6-03 | §16.2 + user decision | Mind mode geometry + 4×3 fit solver | accounts for 3×6 rows plus legend/footers, has maxScrollExtent 0 by giving Mind its required body height | constrained widget all-footer matrix + visual check | DONE — RED proved the 49px deficit; the targeted 50px Mind+Year+4×3 body extension, all footer combinations and restoration on 3×4 are green. |
| FTR-01 | §17 | MindDashboardCoreSurface | one stable Column: Expanded temporal content, legend, compact range | production-parent topology test | DONE — the Sum scroll test proves the stable Column keeps its one legend/range footer outside content scrolling. |
| FTR-02 | §17.1 | QueryAmountRangeControl | Sum/Year/Month/Day use compactMind with identical slider/caption bounds | four-plane widget test | DONE — `FOOT-01/11` proves identical legend, RangeSlider and `Összeg` bounds for Sum/Year/Month/Day; the real CoreDashboard Day rail mount is additionally covered by `FOOT-04/DAY-01`. |
| FTR-03 | §17.2 | stable surface footer | range survives plane switch; exactly one slider/hit-test owner | mounted interaction test | DONE — `FTR-03` first reproduced the Day wrapper unmount. The Mind surface now stays invariant while only Day's temporal-content slot owns the expansion gesture, keeping the same active RangeSlider element and held thumb values through Year → Sum → Month → Day. |
| SUM-01 | §§8–9 | temporal projection/frame | dynamic real years, left year, 12 MYS month cells, axis and right current-filter total | projection/widget test | DONE — pure projection and `SUM-HM-03/04/05` viewport coverage are green. |
| SUM-02 | §9 | temporal projection | complete Mind filter/range precedes monthly aggregation; global non-empty normalization and deterministic equal range | numerical tests | DONE — range-before-aggregation, global intensity and equal-range/empty-state cases are green |
| SUM-03 | §§9.3,22 | admitted base boundary | full all-time coverage is source-proven; grid scrolls only when real years need it | coverage/performance test | PARTIAL — source proves native all-filter scan retains all focus rows while Year/Month/Day frames alone are window-bounded; a native regression was added but this Termux Android runner fails before tests at AAPT2 daemon startup |
| SUM-04 | §18 | live temporal coordinator | Sum reacts same/next frame to preview/direction/focus/search/target | production-parent frame test | DONE — `SUM/MON-03/04`, `ATOM-03/04` and `LIV-04` cover focus, direction, target and held preview without settling. |
| MON-01 | §§10–11 | temporal projection/frame | selected real YearMonth; six-row Monday–Sunday daily calendar with no fake days | numerical/geometry/widget tests | DONE — selected-month numerical projection, leap-February, and viewport coverage are green. |
| MON-02 | §11 | Month frame | exact active-day count and current-filter monthly total | numerical tests | DONE — `RED MONTH-HM-02` green |
| MON-03 | §18 | live temporal coordinator | Month reacts same/next frame to range/focus/direction/month | production-parent frame test | DONE — `SUM/MON-03/04`, `ATOM-03/04` and `LIV-04` cover Month target, focus/direction and held preview same/next frame. |
| DAY-01 | §12 | shared footer/legend | Day main content unchanged, but footer/legend exact parity | four-plane bounds test | DONE — `FOOT-04/DAY-01` mounts the real CoreDashboard Day rail, finds exactly one shared legend/range control and no hourly heatmap. |
| LIV-01 | §§19.1–.2 | current production parent | pre-change mounted RED records first frame where heatmap can be target Y and score is old X, or rejects hypothesis | no-settle frame test/diagnostics | DONE — `RED SCA-01` reproduced score target 2026 while accepted heatmap target was 2025 |
| LIV-02 | §19.3 | Core admission transaction | proven first failing target admission publishes matching score/heatmap atomically | direct Year RED→GREEN | DONE — `RED SCA-01` green after Core target-admission repair |
| LIV-03 | §19.4 | same coordinator | ballistic Year, Month and Sum never resurrect stale target | mounted latest-wins tests | DONE — direct Year, actual ballistic Year, Sum→Month and stale target guards now assert matching score provenance as well as heatmap identity. |
| LIV-04 | §20 | preview lanes | preview range, heatmap, score, chart/palette share generation at first visible preview | held-slider no-settle test | DONE — mounted `LIV-04` exposed then fixed the held Month→Sum score-identity split and proves Month/Sum/Year first-frame convergence. |
| LIV-05 | §32 | existing diagnostic ring | bounded target/publish/paint timing fields only if test counters insufficient | diagnostic test/review | DONE — existing `MIND_SCORE|ACCEPTED_TEMPORAL_TARGET_PUBLISHED`, preview and slider-summary records carry target/range/generation/work counters; no second diagnostic system is needed. |
| PRF-01 | §§21,33 | projections/counters | no source rows, repository, index or scene prep on pointer; bounded bucket visits/timing evidence | performance tests | DONE — mounted `LIV-04` proves source/repository/index zero and <=366 score buckets; diagnostic-profile run measured six score previews: p50=270µs, p95=max=4710µs. This is harness evidence, not a device-frame claim. |
| PRF-02 | §33 | presentation | legend palette switch has no projection rebuild; Header ticker does no score work | counter/boundary tests | DONE — same-frame palette test keeps payload identity, and Header policy/chart boundary tests retain one ticker and no financial work. |
| PRF-03 | §25 / online profile B | mode host | temporal Mind viewport has no outer content gesture region | mounted profile B + host widget test | IN PROGRESS — current online RED: `dashboard-core-mode-content-gesture-region` was found in `_profileMindYearHeatmapSlider` at integration-test line 1578. The minimal host repair and focused production-host test are green locally; exact online profile rerun pending. |
| NRG-01 | §35 | protected owners | preserve Time/Avatar, Query commit, snapping, LogBox, Budget, score math, fixture and Header visuals | full protected suites/diff review | PARTIAL — local Core production-parent 91/91, Mind/viewport/header focused 44/44, Header chart/tuner 26/26 and chart golden were green for `463222fa`; online profile B then found the outer temporal gesture-region regression. Focused repair evidence is green; full final CI pending. |
| VAL-01 | §38 | Flutter/Core | focused projection, resolver, viewport, surface, score, Header and Query suites | exact Ubuntu commands | PARTIAL — Flutter/Core focused and full suites plus chart golden are green. The Android native focused runner still fails before tests during AAPT2 daemon startup and must be re-run online. |
| VAL-02 | §38 | tooling/Git | analyzer and `git diff --check` | exact command output | DONE — Ubuntu `flutter analyze` on all 21 changed Dart paths: `No issues found!`; `git diff --check`: clean. |
| DEL-01 | §§39–40 | Git/CI | atomic application commits, exact online CI/APK and separate journal commits | remote/APK evidence | NOT DONE |
| DEL-02 | §40 | tooling branch | final exact-source SCIP manifest, raw hash and tooling tests | graph provenance | NOT DONE |

## Build-gate table

| Functional delivery item | Status |
| --- | --- |
| Score-lag current-parent RED and first boundary | DONE |
| Atomic temporal admission | DONE |
| Fixed legend and shared footer | DONE |
| Six-row Year cards including 4×3 fit | DONE |
| Month heatmap | DONE |
| Sum heatmap / all-time coverage | PARTIAL — implementation/source proof and Dart coverage are green; its Android native regression cannot execute locally because AAPT2 fails before test execution. |
| Range/focus/direction realtime matrix | DONE |
| Performance and protected regressions | PARTIAL — online profile B caught the temporal outer-gesture regression; repair awaits exact final online profile evidence. |
| Analyzer/diff | DONE |

**BUILD GATE = CLOSED** for the profile-B temporal gesture ownership repair,
its final online validation, final delivery and matching SCIP refresh. The
native Android all-time coverage test is now independently covered by the
successful online `test-core` job for `f5d74e04`.
