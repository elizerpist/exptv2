# Pulse Engine Group Rail Acceptance Checklist

Working artifact: `docs/prototypes/pulse_engine_panel_mockup.html`.

Reference design: `docs/superpowers/specs/2026-07-22-pulse-engine-group-rail-design.md`.

| ID | Source instruction or approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| PEP-RAIL-001 | User, 2026-07-22: the last-screenshot rail must be grouped rather than `Manual / Forecasts / Triggers / Stories / Tuning` | Sticky rail in the HTML prototype | The primary rail has exactly `Budget pressure`, `Cashflow pressure`, and `Data quality`; the old five labels are not primary navigation. | Static selector/text check; Android screenshot. | PARTIAL |
| PEP-RAIL-002 | User, 2026-07-22: split Manual, Forecasts, Triggers, and related content here by group | Each group dossier | Selecting one rail group exposes its complete sequential dossier: how it works, forecasts/calculations, trigger cards, story/lifecycle/header path, and tuning; no nested replacement of the old five tabs. | Direct DOM inspection; browser interaction. | PARTIAL |
| PEP-RAIL-003 | Accepted hidden-forecast source register; group-rail design | Budget pressure dossier | HF-001–004, HF-012–015, and HF-020 appear with their calculation/evidence, event rule, lifecycle state, and applicable user-defined controls. `behavior_shift` source metadata remains visible. | Static HF-ID membership test; browser review. | PARTIAL |
| PEP-RAIL-004 | Accepted hidden-forecast source register; group-rail design | Cashflow pressure dossier | HF-005–007 and HF-009–011 appear with their calculation/evidence, event rule, lifecycle state, and applicable user-defined controls. HF-008 is visible only as explicitly deferred/not active. `fixed_load` source metadata remains visible. | Static HF-ID membership test; browser review. | PARTIAL |
| PEP-RAIL-005 | Accepted HF-021 design; group-rail design | Data quality dossier | HF-021 shows its data condition, forecast-confidence effect, delayed/grouped eligibility, resolve-on-categorization path, and delay/feedback tuning. | Static content check; browser review. | PARTIAL |
| PEP-RAIL-006 | Accepted HF-016–019 engine design; user: every Pulse-affecting event must be understandable here | Shared engine trace inside every group dossier | HF-016 priority, HF-017 lifecycle, HF-018 header delivery, and HF-019 panel diagnostics are visibly explained from every selected group but are not mislabelled as financial detectors or made into a fourth rail group. | Static source check; browser review. | PARTIAL |
| PEP-RAIL-007 | Existing Pulse Engine Panel acceptance; user: every relevant function, calculation, and trigger must be present | All group trigger cards | Each accepted source retains a distinct audit card with current state/value, trigger condition, formula or mini-chart evidence, transition/lifecycle detail, and a local tuning affordance where relevant. | Source inspection; static card count/ID checks. | PARTIAL |
| PEP-RAIL-008 | Existing mobile mockup; Android reference `Screenshot_20260722-145619.png` | Responsive rail and panels | The three-button rail remains accessible and horizontally scrollable on phone widths; group panels have no text clipping, control overlap, or inaccessible hidden active content. | Android screenshots and manual browser interaction. | PARTIAL |
| PEP-RAIL-009 | User, 2026-07-22 | Scope protection | `balance_latest_layout.html` is not edited by this feature. | `git hash-object balance_latest_layout.html` compared with the pre-feature baseline. | DONE |

## Verification evidence

2026-07-22 automated evidence:

- `node docs/prototypes/pulse_engine_panel_group_rail_test.js` passed.
- The embedded browser script compiled through `new Function` without a syntax error.
- The generated range-output IDs were checked for duplicates and passed.
- The Spendee worktree server returned `HTTP 200` for the prototype on port 8790.
- `balance_latest_layout.html` retained baseline hash `a4b940489c11582f7252d6d2f5b86c0114f9817a`.

Android visual review of all three selected group panels remains pending. The
prototype has been opened at `http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html`.
