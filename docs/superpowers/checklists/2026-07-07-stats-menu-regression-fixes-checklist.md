# Stats Menu Current Guard Checklist

This file replaces the older July regression checklist content. It must not be used as a separate source of truth for focus mode or old graph behavior.

Current source of truth:

- Full acceptance checklist: `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md`
- Current spec: `docs/superpowers/specs/2026-07-07-stats-main-menu-redesign-design.md`
- Current plan: `docs/superpowers/plans/2026-07-07-stats-main-menu-redesign.md`
- Mandatory HTML reference: `.superpowers/brainstorm/11665-1783356886/content/stats-current-concept-summary-v26.html`
- Browser URL while the HTML server runs: `http://127.0.0.1:8765/stats-current-concept-summary-v26.html`
- Mandatory heatmap HTML reference: `.superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html`
- Mandatory closing HTML reference: `.superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html`

Checklist ID ranges:

- `STAT-SHARED-*`: shared annual stats shell.
- `STAT-CAT-*`: accepted `Kategória scope`.
- `STAT-HEAT-*`: accepted annual `Hőtérkép`.
- `STAT-CLOSE-*`: accepted annual `Hózárás`.

| ID | Source instruction / approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| STAT-GUARD-001 | User: current implementation must follow the accepted HTML exactly | All stats menu implementation | Implementation starts only after re-reading the mandatory HTML and full acceptance checklist. | Review checklist before coding. | NOT DONE |
| STAT-GUARD-002 | User: focus will be designed later | Stats annual menu | Month focus/detail behavior is not implemented from old regression notes in this pass. | Code review and checklist review. | NOT DONE |
| STAT-GUARD-003 | User approved heatmap and closing annual render modes | Annual stats menu | Heatmap and Hózárás are implemented only from the accepted v28/v29 HTML, current spec, current plan, and `STAT-HEAT-*` / `STAT-CLOSE-*` rows. Older notes are not used as source of truth. | Requirements gate in implementation plan. | NOT DONE |
| STAT-GUARD-004 | User: old stat plans should not confuse current work | Docs and implementation workflow | Older pre-July standalone stats redesign/joystick docs are removed; current July docs point to the accepted v26 HTML and current checklist. | `find docs/superpowers ... | rg 'stats|statistics|joystick'` review. | DONE |
| STAT-GUARD-005 | User approved one main checklist with ID ranges | Docs and implementation workflow | Before spec or implementation work, run `rg -n "STAT-(SHARED\|CAT\|HEAT\|CLOSE)-" docs/superpowers` and use every matching approved requirement. | Requirements gate in implementation plan. | DONE |
