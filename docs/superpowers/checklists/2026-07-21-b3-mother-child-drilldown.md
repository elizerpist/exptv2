# B3 Strict Mother-Child Drilldown Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| B3MC-001 | User: `b3-at duplikáld, és b3 melletti screenbe rajzold fel` | `docs/prototypes/color_lab.html` B-row markup | The original B3 screen remains and an adjacent `B3M` Stage 2 screen is present. | Scoped static assertion and markup inspection. | DONE |
| B3MC-002 | User: strict mother-child example with `Legnagyobb kiadás` | B3M Stage 1 clone | `Legnagyobb kiadás` is visibly the active parent insight in the preserved Stage 1 layer. | Scoped assertion of the active parent class, selected key, and `aria-current`; CSS inspection. | DONE |
| B3MC-003 | User: `mi lesz alatta ... kemény kapcsolatban` | B3M Stage 2 child panel | The child panel contains the selected expense's merchant, amount, date/category, monthly share/progress, comparison, recurring context, and a trend visual. | Scoped static assertion of all child content and visual primitives. | DONE |
| B3MC-004 | User: `figyelj a designra` | B3M CSS | The child is a single polished glass detail surface with hierarchy and no overcrowded nested-card layout. | CSS assertion for active parent, positioned scroll layer, glass panel, and progress; direct CSS inspection. | DONE |
| B3MC-005 | Global verification requirement | `color_lab_static_test.js`, static server | The targeted static checks pass and the served HTML responds successfully. | Static test, inline-JS syntax check, runtime-isolation assertion, `curl` HTTP 200, and `git diff --check`. | DONE |

## Verification Note

The local static server is available at `http://127.0.0.1:8787/color_lab.html`.
Browser screenshot capture was attempted but this Android environment returns `screencap Status: -1`; no local Chromium, Playwright, or HTML renderer is installed. The implementation was therefore verified through scoped markup/CSS/runtime assertions and the served document.
