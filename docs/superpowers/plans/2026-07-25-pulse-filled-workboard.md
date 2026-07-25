# Pulse kitöltő munkafal – megvalósítási terv

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Pulse mockup töltse ki a rendelkezésre álló képernyőt, és a motor útja rácsos, első pillantásra olvasható formában jelenjen meg.

**Architecture:** A fő információs blokkok a korábbi `horizontal-lane` belső görgetés helyett közös `layout-board` rácsosztályt kapnak. A 9 részletes motorlépés fölött egy ötállomásos, rövid olvasási sáv mutatja a történetet; a három meglévő rail-csoport és minden HF-adat változatlan marad.

**Tech Stack:** Egyetlen önálló HTML/CSS/JavaScript mockup és Node.js statikus tesztek (`node:assert/strict`, `node:fs`, `node:path`).

## Global Constraints

- Ne módosítsd a `balance_latest_layout.html` fájlt.
- A három rail-csoport, HF-001–HF-021, HF-008 halasztása, HF-016–HF-019 motorjellege és a döntési nyomvonal maradjon meg.
- A fő információs blokkok ne használjanak belső, oldalirányú `overflow-x` görgetést.
- Minden felhasználói felirat magyar marad.
- A szerver `http://127.0.0.1:8790` címen fut; ne állítsd le.

---

### Task 1: A kitöltő munkafal szerződése

**Files:**

- Create: `docs/prototypes/pulse_filled_workboard_test.js`
- Modify: `docs/prototypes/pulse_wide_layout_test.js`
- Read: `docs/prototypes/pulse_engine_panel_mockup.html`

**Interfaces:**

- Consumes: `.page`, `.layout-board`, `data-layout-board`, `data-pulse-phase-rail`, `data-pulse-phase`.
- Produces: a rácsos, teljes szélességű elrendezést őrző, futtatható Node szerződés.

- [ ] **Step 1: Write the failing test**

Create `docs/prototypes/pulse_filled_workboard_test.js` with the following assertions:

~~~js
#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, 'pulse_engine_panel_mockup.html'), 'utf8');

function rule(selector) {
  const start = html.indexOf(selector + ' {');
  assert.notEqual(start, -1, 'missing CSS rule: ' + selector);
  const end = html.indexOf('\n    }', start);
  return html.slice(start, end + 6);
}

const page = rule('.page');
assert.match(page, /width:\s*calc\(100vw\s*-\s*28px\)/);
assert.match(page, /max-width:\s*none/);
const board = rule('.layout-board');
assert.match(board, /display:\s*grid/);
assert.match(board, /overflow-x:\s*visible/);
assert.match(html, /data-pulse-phase-rail/);
for (const phase of ['change', 'validation', 'situation', 'priority', 'message']) {
  assert.match(html, new RegExp('data-pulse-phase="' + phase + '"'));
}
for (const area of ['semantic-flow', 'manual', 'forecasts', 'triggers', 'engine']) {
  assert.match(html, new RegExp('data-layout-board="' + area + '"'));
}
assert.doesNotMatch(html, /horizontal-lane/);
console.log('pulse_filled_workboard_test: PASS');
~~~

- [ ] **Step 2: Run the test to verify red**

Run:

~~~sh
node docs/prototypes/pulse_filled_workboard_test.js
~~~

Expected: fail because `.layout-board` and `data-pulse-phase-rail` do not yet exist.

- [ ] **Step 3: Update the former wide-layout test contract**

Replace `horizontal-lane` expectations in `pulse_wide_layout_test.js` with the
same `layout-board` and `data-layout-board` contract. Keep the checks that
story and tuning occupy separate desktop columns, but remove assertions that
main content has internal `overflow-x: auto` or a right-arrow-only flow.

### Task 2: Teljes szélességű lap és értelmező motorút

**Files:**

- Modify: `docs/prototypes/pulse_engine_panel_mockup.html:42-48, 705-760, 1292-1445, 1470-1485, 2490-2510`
- Test: `docs/prototypes/pulse_filled_workboard_test.js`

**Interfaces:**

- Consumes: the classes and data attributes from Task 1.
- Produces: five compact phase cards and visible grid areas for every detailed Pulse block.

- [ ] **Step 1: Replace the page and lane CSS**

Use this layout contract:

~~~css
.page {
  width: calc(100vw - 28px);
  max-width: none;
  margin: 0 auto;
  padding: 22px 0 48px;
}

.layout-board {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  align-items: stretch;
  gap: 12px;
  min-width: 0;
  max-width: 100%;
  overflow-x: visible;
}

.layout-board > * { min-width: 0; }
.layout-board--flow { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.layout-board--forecast { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.layout-board--trigger { grid-template-columns: repeat(4, minmax(0, 1fr)); }
.layout-board--manual,
.layout-board--engine { grid-template-columns: repeat(4, minmax(0, 1fr)); }

@media (max-width: 1100px) {
  .page { width: calc(100vw - 20px); max-width: none; }
  .layout-board--flow,
  .layout-board--forecast,
  .layout-board--trigger,
  .layout-board--manual,
  .layout-board--engine { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}

@media (max-width: 640px) {
  .page { width: calc(100vw - 16px); max-width: none; }
  .layout-board--flow,
  .layout-board--forecast,
  .layout-board--trigger,
  .layout-board--manual,
  .layout-board--engine { grid-template-columns: 1fr; }
}
~~~

Remove the `.horizontal-lane` rules and class usage. Do not remove the
rail's own `.horizontal-tabs` overflow behavior.

- [ ] **Step 2: Add the five-phase reading rail**

Insert this after `.semantic-flow-legend` and before the detailed `<ol>`:

~~~html
<div class="pulse-phase-rail" data-pulse-phase-rail aria-label="A Pulse egyszerű olvasási útja">
  <article class="pulse-phase" data-pulse-phase="change"><span>1</span><strong>Változás</strong><p>Valami pénzügyi vagy alkalmazásállapot változik.</p></article>
  <article class="pulse-phase" data-pulse-phase="validation"><span>2</span><strong>Adatellenőrzés</strong><p>Csak a számolható jel mehet tovább.</p></article>
  <article class="pulse-phase" data-pulse-phase="situation"><span>3</span><strong>Helyzet</strong><p>Az összetartozó jelek egy történetté állnak össze.</p></article>
  <article class="pulse-phase" data-pulse-phase="priority"><span>4</span><strong>Fontosság</strong><p>A kész helyzetek közül egy nyer.</p></article>
  <article class="pulse-phase" data-pulse-phase="message"><span>5</span><strong>Felső üzenet</strong><p>Csak a kiválasztott helyzet jelenik meg felül.</p></article>
</div>
~~~

Style `.pulse-phase-rail` as a five-column grid with a two-column breakpoint
and clear sequence numbers. Keep its text compact and Hungarian.

- [ ] **Step 3: Mark every dense area as a board**

Use these exact patterns:

~~~html
<ol class="semantic-flow-grid layout-board layout-board--flow" data-layout-board="semantic-flow">
<div class="group-flow layout-board layout-board--manual" data-layout-board="manual">
<div class="grid-3 layout-board layout-board--forecast" data-layout-board="forecasts">
<div class="trigger-grid layout-board layout-board--trigger" data-group-trigger-grid data-layout-board="triggers">
<div class="shared-engine-trace layout-board layout-board--engine" data-shared-engine-trace data-layout-board="engine">
~~~

- [ ] **Step 4: Run red tests to green**

Run:

~~~sh
node docs/prototypes/pulse_filled_workboard_test.js
node docs/prototypes/pulse_wide_layout_test.js
~~~

Expected: both print `PASS`.

### Task 3: Regressziók, ellenőrző lista és rögzítés

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-25-pulse-filled-workboard.md`
- Test: all `docs/prototypes/pulse_*_test.js`

**Interfaces:**

- Consumes the final HTML and test contracts.
- Produces verified acceptance evidence and a scoped commit.

- [ ] **Step 1: Run the full Pulse verification set**

~~~sh
node docs/prototypes/pulse_filled_workboard_test.js
node docs/prototypes/pulse_wide_layout_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_data_input_rules_test.js
node docs/prototypes/pulse_hungarian_copy_test.js
node docs/prototypes/pulse_plain_language_png_flowchart_test.js
node docs/prototypes/pulse_semantic_flowchart_test.js
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
~~~

Expected: every Node test prints `PASS`; curl prints `200`.

- [ ] **Step 2: Complete acceptance and commit only targeted files**

Set PFW-001 through PFW-006 to `DONE` only after the preceding commands pass.
Then run:

~~~sh
git add docs/prototypes/pulse_engine_panel_mockup.html \
  docs/prototypes/pulse_filled_workboard_test.js \
  docs/prototypes/pulse_wide_layout_test.js \
  docs/superpowers/checklists/2026-07-25-pulse-filled-workboard.md \
  docs/superpowers/plans/2026-07-25-pulse-filled-workboard.md
git diff --cached --check
git commit -m "feat: fill Pulse workboard layout"
~~~
