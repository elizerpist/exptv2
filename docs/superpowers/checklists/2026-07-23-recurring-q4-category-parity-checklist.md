# Recurring Q4 Category Parity Acceptance Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RQP-001 | User, 2026-07-23: Q3A is initialization only | `docs/prototypes/color_lab.html` Q3A block | Q3A has no progress bar, trigger-progress attribute, or `0. lépés a 9-ből` text; Push remains selected and `Tovább` remains present. | Scoped static assertion and direct markup review | NOT DONE |
| RQP-002 | User, 2026-07-23: Q4 should resemble Q2 | `docs/prototypes/color_lab.html` Q4 block | Q4 contains exactly one Q2-style name pill, a Q2 inline category window with `Lakás` selected, then `Új kategória`, then the existing `Tovább` CTA. | Scoped static assertion and direct markup review | NOT DONE |
| RQP-003 | User, 2026-07-23: no partner, no note | `docs/prototypes/color_lab.html` Q4 block | Q4 contains no standalone category pill, Partner/Kedvezményezett field, or Megjegyzés field. | Scoped negative static assertion | NOT DONE |
| RQP-004 | User, 2026-07-23: all text-input pills match Q2 | `docs/prototypes/color_lab.html` recurring field CSS | Recurring text fields use Q2-equivalent fill, border, shadow, and rounded pill profile; non-input choices retain their existing component styling. | CSS static assertion and direct CSS review | NOT DONE |
| RQP-005 | User, 2026-07-23: prototype must remain valid | `docs/prototypes/color_lab_static_test.js` | The full Color Lab static suite passes after Q3A/Q4 changes. | `node docs/prototypes/color_lab_static_test.js` | NOT DONE |
