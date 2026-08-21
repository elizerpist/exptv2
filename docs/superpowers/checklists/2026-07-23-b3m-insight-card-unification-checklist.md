# B3M Compact Insight Card Unification Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BIC-001 | User, 2026-07-23: every small box uses one layout | `balance_latest_layout.html` `populateTodayRedesignScreen` and insight-card CSS | The four B3M compact insight cards use one shared icon/title/value/secondary layout with aligned rows. | Static renderer and CSS assertions | DONE |
| BIC-002 | User, 2026-07-23: simplify 30–60-day rhythm | Trend compact-card renderer | The rhythm card shows only its percentage and a directional arrow as the main metric; current/previous 30-day totals are absent. | Scoped static assertion | DONE |
| BIC-003 | User, 2026-07-23: ghost transaction switch on every box | Shared compact-card helper and CSS | Each compact card has a bottom-right ghost icon button that toggles its `data-include-ghost-transactions` state and `aria-pressed` value. | Isolated click smoke and static assertion | DONE |
| BIC-004 | User, 2026-07-23: remove irrelevant fixed-exclusion text | Upper compact-card renderer and trend catalog copy | The compact-card scope contains no `fixek nélkül`, `fix tételek kizárva`, or equivalent fixed-exclusion copy. | Scoped negative static assertion | DONE |
| BIC-005 | User, 2026-07-23: preserve prototype validity | `docs/prototypes/balance_stage2_mother_child_gallery_static_test.js` | The full B3M static contract passes after the change. | `node docs/prototypes/balance_stage2_mother_child_gallery_static_test.js` | DONE |
