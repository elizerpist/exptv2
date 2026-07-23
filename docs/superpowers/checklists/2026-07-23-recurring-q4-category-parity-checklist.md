# Recurring Q4 Category Parity Acceptance Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RQP-001 | User, 2026-07-23: Q3A is initialization only | `docs/prototypes/color_lab.html` Q3A block | Q3A has no progress bar, trigger-progress attribute, or `0. lépés a 9-ből` text; Push remains selected and `Tovább` remains present. | Scoped static assertion and direct markup review | DONE — static suite passed |
| RQP-002 | User, 2026-07-23: Q4 controls must match Név height | `docs/prototypes/color_lab.html` Q4 block and scoped CSS | The Q4 name pill, one-row scrollable category window, and `Új kategória` action are each exactly 50px high; `Lakás` remains selected and `Tovább` remains present. | Scoped static assertion, CSS review, and served-HTML check | DONE — static suite and served-HTML check passed |
| RQP-003 | User, 2026-07-23: no partner, no note | `docs/prototypes/color_lab.html` Q4 block | Q4 contains no standalone category pill, Partner/Kedvezményezett field, or Megjegyzés field. | Scoped negative static assertion | DONE — static suite passed |
| RQP-004 | User, 2026-07-23: all text-input pills match Q2 | `docs/prototypes/color_lab.html` recurring field CSS | Recurring text fields use Q2-equivalent fill, border, shadow, and rounded pill profile; non-input choices retain their existing component styling. | CSS static assertion and direct CSS review | DONE — static suite passed |
| RQP-005 | User, 2026-07-23: prototype must remain valid | `docs/prototypes/color_lab_static_test.js` | The full Color Lab static suite passes after Q3A/Q4 changes. | `node docs/prototypes/color_lab_static_test.js` | DONE — passed |
