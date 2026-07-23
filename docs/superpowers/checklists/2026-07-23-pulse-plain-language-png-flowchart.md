# Pulse Plain-Language PNG Flowchart Acceptance Checklist

Working artifact: `docs/prototypes/pulse_engine_panel_mockup.html`.

Reference design: `docs/superpowers/specs/2026-07-23-pulse-plain-language-png-flowchart-design.md`.

| ID | Source instruction or approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| PLPF-001 | User, 2026-07-23: clear explanatory PNG flowchart | `docs/prototypes/assets/pulse-egyszeru-mukodes.png` | One project-local, valid PNG exists and is not a remote or placeholder asset. | PNG signature/static test. | NOT DONE |
| PLPF-002 | User: put the PNG at the bottom of the HTML | Bottom of mockup before footer | A full-width semantic figure references the local PNG immediately before the existing footer note. | Static placement test. | NOT DONE |
| PLPF-003 | User: foreign/technical language is unintelligible | PNG content | The visual is readable Hungarian and uses the plain-language flow from score inspection through shown/wait/no-message/recheck. | Direct image inspection. | NOT DONE |
| PLPF-004 | User: clarify whether score is enough | Central PNG rule | The largest rule says `A pontszám önmagában nem elég.` and distinguishes score inspection from an actual data change. | Direct image inspection; alt/static check. | NOT DONE |
| PLPF-005 | User: every message branch should be understandable | PNG decision exits | The visual shows wait, no message, one winner, app-open delivery, non-repeat, and true-change recheck paths without engineering jargon. | Direct image inspection. | NOT DONE |
| PLPF-006 | Existing mobile mockup constraint | Figure CSS | The embedded image scales to the available width without horizontal crop. | Static CSS/direct source check. | NOT DONE |
| PLPF-007 | Approved three-group rail design | Existing rail | No fourth primary rail or changed group rail is introduced. | Existing rail contract test. | NOT DONE |
| PLPF-008 | User, 2026-07-23 | Scope protection | `balance_latest_layout.html` is untouched. | Baseline hash comparison. | NOT DONE |
