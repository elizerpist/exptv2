# Acceptance checklist: Mind Year 2x6 and Sum curve presentation

| ID | Requirement source | Code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| Y26-01 | User §1 | `mind_year_heatmap_viewport.dart` | Header selector has 4x3, 3x4, 2x6; widget test | DONE |
| Y26-02 | User §§1–2 | Year viewport | 2x6 has 12 rounded MonthCards with name, heatmap, Scope, Zárás; widget/golden test | DONE |
| Y26-03 | User §3 | Shared day-label overlay + Year viewport | 2x6 top-left day labels use Month view primitive; widget test | DONE |
| Y26-04 | User §4 | settings, tuner, MonthCard | Border applies 3x4/2x6 only, 4x3 unchanged; widget/settings test | DONE |
| Y26-05 | User §4 | settings, resolver, MonthCard | Profit/loss/zero tint + independent opacity apply 3x4/2x6 only; widget test | DONE |
| Y26-06 | User §4/8 | Year painter | Cell palette/intensity/text and Scope/Zárás semantics unchanged; regression test | DONE |
| SUM-01 | User §5 | shared Sum header | Detailed and bar bands use same header/type/layout/total source; widget test | DONE |
| SUM-02 | User §6 | settings/tuner | Independent interpolation, smoothing, window, tension and zoom-adaptive controls; settings/tuner test | DONE |
| SUM-03 | User §6 | detailed Sum model/painter | Weighted paint-only smoothing preserves extrema; deep zoom trends raw; model test | DONE |
| SUM-04 | User §6/8 | detailed Sum painter | Monotone/Catmull controls cannot overshoot endpoint extrema; focused renderer/model test | DONE |
| REG-01 | User §8 | affected viewports | 4x3 / Query / filters / range semantics unaffected; focused regression tests | DONE |
| VIS-01 | AGENTS UI evidence | Year 2x6 golden | 2x6 card/date-label composition has golden evidence | DONE |
| VAL-01 | User deliverable | tests/analyze/diff | Focused test, format, analyze, boundaries, diff reported | PARTIAL — final analyzer/fast/boundary run pending |
| APK-01 | Global Flutter delivery | GitHub Actions | After app commit push, normal human APK downloaded/hash verified | NOT DONE |
| PHYS-01 | User/AGENTS | device | Physical validation is user-only | BLOCKED — USER ONLY |
