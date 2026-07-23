# Pulse Engine Decision Trace Acceptance Checklist

Working artifact: `docs/prototypes/pulse_engine_panel_mockup.html`.

Reference design: `docs/superpowers/specs/2026-07-22-pulse-engine-decision-trace-design.md`.

| ID | Source instruction or approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| PEDT-001 | User, 2026-07-22: make the engine understandable rather than only its detectors/triggers | Global engine area in the HTML prototype | A visible Decision Trace explains raw signals through one header delivery without becoming a fourth primary rail. | Static DOM check; browser review. | PARTIAL |
| PEDT-002 | Accepted trace design, Scenario model | Scenario controls and renderer | Risk, recovery, and data-quality scenarios update one coherent engine trace and phone-header preview. | Static scenario test; manual interaction. | PARTIAL |
| PEDT-003 | User: when does it appear? | Eligibility/lifecycle stage | The panel visibly distinguishes recalculation, foreground/background delivery timing, waiting, eligible, shown, suppressed, superseded, resolved, muted, and same-fingerprint non-repeat. | Static content check; scenario review. | PARTIAL |
| PEDT-004 | User: why is one trigger stronger?; accepted weighting rules | Priority ledger | Each candidate shows dominant base weight, all existing modifiers, final clamped priority, gate outcome, and tie-break when needed; scores cannot bypass ineligibility. | Static formula/fixture test; browser review. | PARTIAL |
| PEDT-005 | Accepted evidence/composition rules | Story-formation stage | The trace shows related evidence rules, forming versus ready stories, one selected story, and ready losers as suppressed rather than queued. | Static scenario test; browser review. | PARTIAL |
| PEDT-006 | User: how does the story evolve? | Lifecycle/story timeline | The state path from raw signal through selected/delivered/shown plus supersede/retrigger behavior is inspectable per scenario. | Static state test; browser review. | PARTIAL |
| PEDT-007 | User: which trigger inserts which sentence part? | Copy map and group source cards | Header copy is visibly split into headline, evidence, time/cause, caveat, and recovery slots; each displayed fragment names its HF source, while omitted/deferred/engine-only sources state why they add no copy. | Source-role coverage test; browser review. | PARTIAL |
| PEDT-008 | Accepted source register | All active/deferred/engine source mappings | HF-001–021 retain clear source roles; HF-008 remains deferred/no V1 copy and HF-015–019 cannot masquerade as financial header copy. | Static HF mapping test. | DONE |
| PEDT-009 | Approved three-group rail design | Existing group rail and dossiers | Budget pressure, Cashflow pressure, and Data quality remain the only primary rail groups; each can still expose its owner source cards. | Existing rail contract test; browser review. | PARTIAL |
| PEDT-010 | Existing mobile mockup | Responsive trace and source map | The trace, ledger, and sentence fragments remain readable and operable on Android width without clipping or covered active content. | Android screenshots/manual interaction. | PARTIAL |
| PEDT-011 | User, 2026-07-22 | Scope protection | `balance_latest_layout.html` is untouched. | Baseline hash comparison. | DONE |

## Execution evidence — 2026-07-22

- `pulse_engine_decision_trace_test.js`: PASS — trace shell, all scenarios,
  clamped priority interface, 21 HF roles, no-copy exclusions, source controls,
  and shared engine badges.
- `pulse_engine_panel_group_rail_test.js`: PASS — exactly the three approved
  primary rails remain.
- Embedded script syntax: PASS.
- Isolated fixture ledger: PASS — Risk selected `100`, Risk suppressed `80`,
  Recovery selected `70`, Data-quality selected `35`; HF-008 stays
  `deferred-no-copy`; HF-015–019 stay `engine-only`.
- HTTP server: `200` for the working prototype; `git diff --check`: PASS.
- `balance_latest_layout.html` hash matches the protected baseline
  `a4b940489c11582f7252d6d2f5b86c0114f9817a`.
- Direct Android-width/browser review and screenshots were intentionally not
  performed at the user's request. The related visual/manual acceptance items
  remain `PARTIAL`; this is not being represented as visual completion.
