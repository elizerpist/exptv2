# Query Time Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace Q1's static Sum/Year/Month period selector with a working time-scope picker that can select SUM, a full year, one month, or multiple arbitrary months in a year.

**Architecture:** Keep the implementation inside `docs/prototypes/color_lab.html` and its static contract in `docs/prototypes/color_lab_static_test.js`. The picker owns year, mode, and selected-month state in DOM data attributes/classes; runtime JS synchronizes the section label and the top floating header time-scope chips.

**Tech Stack:** Static HTML/CSS/vanilla JS prototype, Node static regression test.

## Global Constraints

- Do not use subagents for this implementation.
- Use TDD: update `docs/prototypes/color_lab_static_test.js`, observe RED, implement, observe GREEN.
- Preserve Q1 as the first row and focused screen.
- Preserve the single floating query header; do not reintroduce a second preview card.
- Do not run local Flutter APK builds in Termux.

---

### Task 1: Static Contract + Checklist

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-17-color-lab-universal-palettes.md`
- Modify: `docs/prototypes/color_lab_static_test.js`

**Interfaces:**
- Consumes: Existing `queryMenuBlock`, `queryMenuScreenBlock`, and `queryMenuHeaderBlock` extraction in the static test.
- Produces: A failing static assertion requiring the new `data-query-period-picker` markup, CSS, and JS bindings.

- [x] Add checklist item `CL-UP-038` for the approved time-picker redesign.
- [x] Update the Q1 static test to require:
  - `data-query-period-picker`
  - `data-query-period-mode="sum"`, `"year"`, and `"months"`
  - twelve `data-query-month` controls
  - selected September and December example state
  - no old `data-query-view-selector`
  - JS functions/bindings for mode, year, month toggles, and header time-chip sync.
- [x] Run `node docs/prototypes/color_lab_static_test.js`.
- [x] Expected result: FAIL on the new Q time picker assertion.

### Task 2: Q1 Period Picker Markup and CSS

**Files:**
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: Existing Q1 `view-components` section.
- Produces: A compact period picker with year navigation, mode selector, and a 4x3 month grid.

- [x] Replace the old `query-view-selector`, `query-period-grid`, and view-component chips with:
  - `query-period-picker`
  - `query-period-year-row`
  - `query-period-mode-selector`
  - `query-month-grid`
  - twelve `query-month-button` controls.
- [x] Default the prototype to `2026`, mode `months`, selected months `9` and `12`.
- [x] Update the floating header time chips to `2026`, `Szeptember`, `December`.
- [x] Add CSS for the period picker, selected state, and compact 4-column month grid.

### Task 3: Q1 Period Picker Runtime

**Files:**
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: Period picker DOM from Task 2.
- Produces: Runtime functions:
  - `getQueryPeriodPickerState(picker)`
  - `syncQueryHeaderTimeScope(route, labels)`
  - `syncQueryPeriodPicker(picker)`
  - `setQueryPeriodMode(picker, mode)`
  - `toggleQueryMonth(button)`
  - `changeQueryPeriodYear(button)`

- [x] Bind `[data-query-period-mode]` buttons to switch SUM / full year / months.
- [x] Bind `[data-query-month]` buttons to multi-select months without collapsing to one month.
- [x] Bind `[data-query-year-step]` buttons to update the selected year.
- [x] Update `[data-query-selected-period]`, `[data-query-period-summary]`, and top header time chips after each interaction.
- [x] Preserve generic query selectable behavior for category/vendor/refinement filters.

### Task 4: Verify

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-17-color-lab-universal-palettes.md`

- [x] Run `node docs/prototypes/color_lab_static_test.js`; expected PASS.
- [x] Run `git diff --check -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js docs/superpowers/checklists/2026-07-17-color-lab-universal-palettes.md`; expected exit 0.
- [x] Mark `CL-UP-038` DONE only after verification.
