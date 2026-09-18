# Mind heatmap presentation and interaction repair — acceptance checklist

**Status vocabulary:** `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`. Every `DONE`
row needs the stated evidence. **BUILD GATE = CLOSED** until all functional
rows are `DONE` and focused tests are green.

## Sources and architecture

| ID | Source / reference | Code owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | §§11–12 | `MindYearHeatmapPresentationController` | one presentation write path; no Query/projection write | settings/no-data-mutation test | DONE |
| ARC-02 | §§12,14.F | `MindYearHeatmapPaletteResolver` | one colour/contrast resolver for all planes and legend | resolver + all-plane identity test | DONE |
| ARC-03 | §§8,14.E | `DashboardUpperVerticalGestureCoordinator` | one expansion owner and Budget-style boundary reuse | mounted gesture test | DONE |
| ARC-04 | §15 | all changed UI | no repo/index/raw-row work from presentation toggle or pointer | source boundary + mounted presentation test | DONE |
| SUM-PAINT-01 | §§8.1,13.A | `MindSumHeatmapViewport` | non-empty cell has visible positive render bounds and resolver colour | mounted bounds test | DONE |
| SUM-PAINT-02 | §14.C | Sum row composition | 12 cells/axis/totals/scroll remain intact | viewport regression suite | DONE |
| LEG-01 | §§4.B,13.B | `_MindTemporalBody` | legend default ON has bounded five samples | widget test | DONE |
| LEG-02 | §§4.B,14.A | settings + body | OFF removes widget and reserves exactly zero legend lane | real controller geometry test | DONE |
| LEG-03 | §§4.B,13.C | Year 4×3 composition | reclaimed lane increases content only; slider bounds invariant | constrained host test | DONE |
| SURF-01 | §§4.C,13.D | Year viewport | MonthCard and direct styles selectable over same frame | same-frame widget test | DONE |
| SURF-02 | §14.B | direct Year renderer | no muted shell; 12 real titled groups/no fake days/totals retained | render-tree + geometry test | DONE |
| MONTH-01 | §§8.4,13.E | Month viewport | centered `min(width,282)` seven-column grid | constrained widget test | DONE |
| MONTH-02 | §14.D | Month painter/labels | 4px gaps, square cells, 3px insets, 6px radius, upper-left 7px/900 labels | bounds/style test | DONE |
| MONTH-03 | §§8.4,14.D | Month frame | only real production day values/totals, no HTML fixture values | existing projection + widget test | DONE |
| PAL-01 | §14.F | palette enum/resolver | Fluvi and B3M exact existing behavior retained | byte-value regression tests | DONE |
| PAL-02 | §14.F | palette enum/resolver | Ocean Sunset all 10 exact stops selectable/interpolated | pure resolver test | DONE |
| PAL-03 | §14.F | palette enum/resolver | Bold Berry, Meadow Green, Peachy Delight exact stops | pure resolver tests | DONE |
| PAL-04 | §14.F | palette enum/resolver | Soft Rainbow, Cherry Blossom, Soft Pastels exact stops | pure resolver tests | DONE |
| PAL-05 | §14.F | palette enum/resolver | fixed `Custom colour` only; no picker/duplicate HSL/RGB style | enum/tuner test | DONE |
| PAL-06 | §14.F | resolver | new palettes traverse all stops; five bounded legend samples use same resolver | interpolation/legend test | DONE |
| TUNER-01 | §§8.6,13.H,14.G | existing tuner | palette, legend, surface and layout controls have stable keys | tuner widget test | DONE |
| TUNER-02 | §13.H | presentation controller | a no-op does not revise; real action increments once | domain test | DONE |
| GEST-01 | §§8.7,13.I | temporal scroll | interior drag scrolls only; no expansion | production-parent test | DONE |
| GEST-02 | §§8.8,13.J | boundary handoff | unconsumed boundary delta expands once, correct sign/end | production-parent test | DONE |
| GEST-03 | §13.K | zero-extent temporal content | card drag reaches same expansion owner | production-parent test | DONE |
| GEST-04 | §§12,13.L | range sibling | both thumbs work and produce zero expansion/scroll displacement | mounted range test | DONE |
| GEST-05 | §13.M | Header | existing Header drag still expands | host regression | DONE |
| NRG-01 | §11 | protected systems | Time/Avatar/Query/LogBox/Room/Kotlin/score/Budget untouched | scoped diff + protected suite | DONE |
| NRG-02 | §§12,15 | controller identity | no new expansion/scroll/range controller and no broad recognizer | host topology + source inspection | DONE |
| VAL-01 | §17 | changed Dart | formatter + focused suites green | exact command output | DONE |
| VAL-02 | §§15,17 | dashboard | analyzer, fast and broader relevant suites green or exact inherited proof | `flutter analyze --no-pub`, targeted dashboard suite, `test-fluvi-fast.sh`, diff check | DONE |
| DEL-01 | §18 | journal | separate non-duplicate journal-only entry after each substantive commit | `git show --name-only` | NOT DONE |
| DEL-02 | §19 | CI/APK | final app SHA triggers normal CI/human APK with verified marker/hash | workflow + local SHA-256 | NOT DONE |
| DEL-03 | §19 | tooling | manifest indexes exact final app SHA | tooling test + manifest | NOT DONE |

## Build gate

| Functional group | Status |
| --- | --- |
| Sum visible cell repair | DONE |
| Optional legend / 4×3 reclaim | DONE |
| Direct annual presentation | DONE |
| Exact B3M-MYM Month geometry | DONE |
| Eight fixed palette presets | DONE |
| Gesture arbitration and slider isolation | DONE |
| Protected regressions / analyzer | DONE |

**BUILD GATE = OPEN — all functional checklist rows above are `DONE`; delivery rows remain intentionally open until the exact application SHA is pushed, built, and indexed.**
