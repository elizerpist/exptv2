# Pulse Engine Group Rail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Replace the generic Pulse Engine rail with three complete group dossiers: Budget pressure, Cashflow pressure, and Data quality.

**Architecture:** The standalone HTML will use one sticky three-button rail and three static, accessible group panels. Every selected panel contains its own manual, forecast/calculation cards, audit trigger cards, story/lifecycle/header explanation, and tuning. HF-016 through HF-019 are repeated as labelled shared-engine mechanics inside every group; every financial source has one display-group owner.

**Tech Stack:** Plain HTML, CSS, browser JavaScript, and a Node.js static assertion script using only node:assert/strict, node:fs, and node:path.

## Global Constraints

- Change docs/prototypes/pulse_engine_panel_mockup.html and create its static test only.
- Do not modify balance_latest_layout.html.
- Keep the panel local, deterministic, AI-free, and not a notification inbox.
- Preserve HF-001 through HF-021; HF-008 is visible but deferred/not active.
- Preserve source-domain labels: fixed_load, behavior_shift, and engine.
- The primary rail must have exactly three entries. Do not replace it with nested Manual, Forecasts, Triggers, Stories, or Tuning tabs.
- Verify with Node static checks, HTTP 200, Android-browser screenshots, and a targeted Balance diff check.

---

### Task 1: Define the group-rail contract test

**Files:**
- Create: docs/prototypes/pulse_engine_panel_group_rail_test.js
- Read: docs/prototypes/pulse_engine_panel_mockup.html

**Interfaces:**
- Consumes data-group-rail, data-group-panel, data-dossier-section, data-hf-id, data-shared-engine-trace, and data-shared-hf-id attributes.
- Produces a repeatable Node check for source ownership and rail structure.

- [x] **Step 1: Write the failing static test**

~~~js
#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const html = fs.readFileSync(
  path.join(__dirname, 'pulse_engine_panel_mockup.html'),
  'utf8',
);

const groups = {
  budget: ['HF-001', 'HF-002', 'HF-003', 'HF-004', 'HF-012', 'HF-013', 'HF-014', 'HF-015', 'HF-020'],
  cashflow: ['HF-005', 'HF-006', 'HF-007', 'HF-008', 'HF-009', 'HF-010', 'HF-011'],
  'data-quality': ['HF-021'],
};
const sectionNames = ['manual', 'forecasts', 'triggers', 'story', 'tuning'];
const sharedIds = ['HF-016', 'HF-017', 'HF-018', 'HF-019'];

function panelFor(group) {
  const marker = 'data-group-panel="' + group + '"';
  const markerIndex = html.indexOf(marker);
  assert.notEqual(markerIndex, -1, 'missing group panel: ' + group);
  const start = html.lastIndexOf('<section', markerIndex);
  const nextPanel = html.indexOf('<section class="group-panel', markerIndex + marker.length);
  const end = nextPanel === -1 ? html.indexOf('<p class="footer-note"', markerIndex) : nextPanel;
  assert.notEqual(end, -1, 'missing end marker for group: ' + group);
  return html.slice(start, end);
}

assert.equal((html.match(/data-group-rail=/g) || []).length, 3, 'exactly three rail buttons are required');
assert.doesNotMatch(html, /data-tab-target="(?:manual|forecasts|triggers|stories|tuning)"/, 'old primary tab buttons must be removed');
assert.doesNotMatch(html, /data-tab-panel="(?:manual|forecasts|triggers|stories|tuning)"/, 'old global panels must be removed');

for (const [group, ids] of Object.entries(groups)) {
  const panel = panelFor(group);
  for (const section of sectionNames) {
    assert.match(panel, new RegExp('data-dossier-section="' + section + '"'), group + ' misses ' + section);
  }
  for (const id of ids) {
    assert.equal(
      (html.match(new RegExp('data-hf-id="' + id + '"', 'g')) || []).length,
      1,
      id + ' must have exactly one display-group owner',
    );
    assert.match(panel, new RegExp('data-hf-id="' + id + '"'), id + ' must belong to ' + group);
  }
  assert.match(panel, /data-shared-engine-trace/, group + ' misses shared engine trace');
  for (const id of sharedIds) {
    assert.match(panel, new RegExp('data-shared-hf-id="' + id + '"'), group + ' misses ' + id);
  }
}

assert.match(html, /data-hf-id="HF-008"[\s\S]*?deferred[\s\S]*?not active/, 'HF-008 must remain deferred');
assert.match(html, /data-source-domain="fixed_load"/, 'fixed_load provenance must remain visible');
assert.match(html, /data-source-domain="behavior_shift"/, 'behavior_shift provenance must remain visible');
assert.match(html, /data-source-domain="engine"/, 'engine provenance must remain visible');
assert.match(html, /function selectGroup\(group, shouldScroll = true\)/, 'group selector must exist');
assert.match(html, /ArrowRight/, 'group rail needs ArrowRight keyboard navigation');
assert.match(html, /ArrowLeft/, 'group rail needs ArrowLeft keyboard navigation');
assert.match(html, /data-group-summary="budget"/, 'budget summary must select its group');
assert.match(html, /data-group-summary="cashflow"/, 'cashflow summary must select its group');
assert.match(html, /data-group-summary="data-quality"/, 'data summary must select its group');

console.log('pulse_engine_panel_group_rail_test: PASS');
~~~

- [x] **Step 2: Run the test before implementation**

Run:

~~~sh
cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
node docs/prototypes/pulse_engine_panel_group_rail_test.js
~~~

Expected: failure because the old five global tabs are still present and no group panels exist.

- [x] **Step 3: Commit the test**

~~~sh
git add docs/prototypes/pulse_engine_panel_group_rail_test.js
git commit -m "test: define Pulse Engine group rail contract"
~~~

### Task 2: Build the three static group dossiers

**Files:**
- Modify: docs/prototypes/pulse_engine_panel_mockup.html CSS rail and dossier rules
- Modify: docs/prototypes/pulse_engine_panel_mockup.html workspace markup
- Test: docs/prototypes/pulse_engine_panel_group_rail_test.js

**Interfaces:**
- Consumes group identifiers from Task 1.
- Produces three static section.group-panel elements and a single static owner for every financial HF source.

- [x] **Step 1: Add stylesheet primitives**

Add these rules beside the current rail CSS:

~~~css
.group-panel { display: block; }
.group-panel[hidden] { display: none; }
.group-panel > .dossier-section + .dossier-section { margin-top: 18px; }
.group-panel-head {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  align-items: flex-start;
  margin-bottom: 14px;
}
.group-flow,
.shared-engine-trace {
  display: grid;
  grid-template-columns: repeat(4, minmax(136px, 1fr));
  gap: 10px;
}
.group-flow-step,
.shared-engine-step {
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: var(--r);
  background: var(--surface-2);
}
.source-domain {
  color: var(--muted);
  font-size: 12px;
  font-weight: 750;
}
.signal-row[data-group-summary] { cursor: pointer; }
.signal-row[data-group-summary]:focus-visible {
  outline: 3px solid rgba(8, 167, 199, .45);
  outline-offset: 3px;
}
@media (max-width: 640px) {
  .group-flow,
  .shared-engine-trace { grid-template-columns: 1fr; }
}
~~~

- [x] **Step 2: Replace the five-button rail**

Use exactly this accessible rail:

~~~html
<div class="horizontal-tabs" role="tablist" aria-label="Pulse group rail">
  <button class="tab-button active" id="group-rail-budget" type="button" role="tab"
    aria-selected="true" aria-controls="group-budget" data-group-rail="budget">Budget pressure</button>
  <button class="tab-button" id="group-rail-cashflow" type="button" role="tab"
    aria-selected="false" aria-controls="group-cashflow" data-group-rail="cashflow">Cashflow pressure</button>
  <button class="tab-button" id="group-rail-data-quality" type="button" role="tab"
    aria-selected="false" aria-controls="group-data-quality" data-group-rail="data-quality">Data quality</button>
</div>
~~~

- [x] **Step 3: Replace the old global panels with three static group panels**

Each group has this five-section outer structure. Budget starts active; Cashflow and Data quality start with hidden.

~~~html
<section class="group-panel active" id="group-budget" role="tabpanel"
  aria-labelledby="group-rail-budget" data-group-panel="budget">
  <section class="card dossier-section" data-dossier-section="manual"></section>
  <section class="card dossier-section" data-dossier-section="forecasts"></section>
  <section class="card dossier-section" data-dossier-section="triggers"></section>
  <section class="card dossier-section" data-dossier-section="story"></section>
  <section class="card dossier-section" data-dossier-section="tuning"></section>
</section>
~~~

Use matching id, aria-labelledby, and data-group-panel values for cashflow and data-quality. Do not retain panel-manual, panel-forecasts, panel-triggers, panel-stories, or panel-tuning.

- [x] **Step 4: Place content by the exact source ownership table**

| Display group | Trigger audit cards | Forecast/calculation cards |
| --- | --- | --- |
| Budget pressure | HF-001, HF-002, HF-003, HF-004, HF-012, HF-013, HF-014, HF-015, HF-020 | HF-001; HF-002; HF-020; HF-012/HF-013/HF-014 |
| Cashflow pressure | HF-005, HF-006, HF-007, HF-008 deferred, HF-009, HF-010, HF-011 | HF-005/HF-006/HF-007; HF-009/HF-010; HF-011 |
| Data quality | HF-021 | HF-021 |

On every financial audit card, add data-hf-id and retain a visible source-domain label. Use:
- behavior_shift on HF-012, HF-013, and HF-014;
- fixed_load on HF-005 and HF-006;
- data_quality on HF-021;
- deferred and not active copy on HF-008.

Each group manual section must name source inputs, calculation path, confidence implications, and its transition rule. Each group story section must name how its signals can form, wait, suppress, resolve, recover, or reach the header. Retain the current mini-SVG evidence and local control from every existing trigger card.

- [x] **Step 5: Add the shared engine trace inside every group story section**

Repeat this structure in all three group panels:

~~~html
<div class="shared-engine-trace" data-shared-engine-trace>
  <article class="shared-engine-step" data-shared-hf-id="HF-016" data-source-domain="engine">
    <strong>Priority and selection</strong><p>Filter, group, score, then select one current header story.</p>
  </article>
  <article class="shared-engine-step" data-shared-hf-id="HF-017" data-source-domain="engine">
    <strong>Lifecycle and fingerprint</strong><p>Changed state can retrigger; unchanged shown state cannot replay.</p>
  </article>
  <article class="shared-engine-step" data-shared-hf-id="HF-018" data-source-domain="engine">
    <strong>Header delivery</strong><p>Only the selected story morphs through the header.</p>
  </article>
  <article class="shared-engine-step" data-shared-hf-id="HF-019" data-source-domain="engine">
    <strong>Panel diagnostics</strong><p>This panel exposes raw signals, formation, selection, history, and tuning.</p>
  </article>
</div>
~~~

- [x] **Step 6: Run the static test and whitespace check**

~~~sh
cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
node docs/prototypes/pulse_engine_panel_group_rail_test.js
git diff --check -- docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_engine_panel_group_rail_test.js
~~~

Expected: test PASS and no whitespace output.

- [x] **Step 7: Commit the group structure**

~~~sh
git add docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_engine_panel_group_rail_test.js
git commit -m "feat: group Pulse Engine panel by pressure domain"
~~~

### Task 3: Implement accessible group selection and summary navigation

**Files:**
- Modify: docs/prototypes/pulse_engine_panel_mockup.html summary rows and final browser script
- Test: docs/prototypes/pulse_engine_panel_group_rail_test.js

**Interfaces:**
- Consumes data-group-rail buttons, data-group-panel panels, and data-group-summary rows.
- Produces one selected panel at a time, pointer selection, keyboard selection, and summary-to-group navigation.

- [x] **Step 1: Mark group summaries**

Set the existing three signal rows to data-group-summary values budget, cashflow, and data-quality. Add role="button", tabindex="0", and aria-controls referencing their group panels.

- [x] **Step 2: Replace the old five-tab runtime with this selector**

~~~js
const groupRailButtons = Array.from(document.querySelectorAll('[data-group-rail]'));
const groupPanels = Array.from(document.querySelectorAll('[data-group-panel]'));
const groupSummaries = Array.from(document.querySelectorAll('[data-group-summary]'));
const groupRail = document.querySelector('.horizontal-tabs');

function selectGroup(group, shouldScroll = true) {
  groupRailButtons.forEach((button) => {
    const active = button.dataset.groupRail === group;
    button.classList.toggle('active', active);
    button.setAttribute('aria-selected', String(active));
    button.tabIndex = active ? 0 : -1;
  });
  groupPanels.forEach((panel) => {
    const active = panel.dataset.groupPanel === group;
    panel.hidden = !active;
    panel.classList.toggle('active', active);
  });
  if (shouldScroll && groupRail) {
    groupRail.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

groupRailButtons.forEach((button, index) => {
  button.addEventListener('click', () => selectGroup(button.dataset.groupRail));
  button.addEventListener('keydown', (event) => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
    event.preventDefault();
    const nextIndex = event.key === 'Home' ? 0
      : event.key === 'End' ? groupRailButtons.length - 1
      : (index + (event.key === 'ArrowRight' ? 1 : -1) + groupRailButtons.length) % groupRailButtons.length;
    const nextButton = groupRailButtons[nextIndex];
    nextButton.focus();
    selectGroup(nextButton.dataset.groupRail, false);
  });
});

groupSummaries.forEach((summary) => {
  const select = () => selectGroup(summary.dataset.groupSummary);
  summary.addEventListener('click', select);
  summary.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      select();
    }
  });
});
~~~

- [x] **Step 3: Run interaction-contract and HTTP checks**

~~~sh
cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
node docs/prototypes/pulse_engine_panel_group_rail_test.js
curl --max-time 3 -s -o /dev/null -w 'HTTP %{http_code} %{size_download} bytes\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
~~~

Expected: static test PASS and HTTP 200.

- [x] **Step 4: Commit accessible navigation**

~~~sh
git add docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_engine_panel_group_rail_test.js
git commit -m "feat: make Pulse group rail accessible"
~~~

### Task 4: Verify and record evidence

**Files:**
- Modify: docs/superpowers/checklists/2026-07-22-pulse-engine-group-rail.md
- Read: docs/prototypes/pulse_engine_panel_mockup.html
- Read: docs/prototypes/pulse_engine_panel_group_rail_test.js
- Read: balance_latest_layout.html

**Interfaces:**
- Consumes final static test and live HTTP URL.
- Produces accurate acceptance statuses and evidence.

- [x] **Step 1: Run the complete verification set**

~~~sh
cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
node docs/prototypes/pulse_engine_panel_group_rail_test.js
git diff --check -- docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_engine_panel_group_rail_test.js docs/superpowers/checklists/2026-07-22-pulse-engine-group-rail.md
curl --max-time 3 -s -o /dev/null -w 'HTTP %{http_code} %{size_download} bytes\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
test "$(git hash-object balance_latest_layout.html)" = "a4b940489c11582f7252d6d2f5b86c0114f9817a"
~~~

Expected: static test PASS, no whitespace output, HTTP 200, and the unchanged baseline hash for balance_latest_layout.html. If the hash differs, stop and determine whether the user changed the file before continuing.

- [ ] **Step 2: Review all three groups on Android browser**

Open http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html and inspect Budget pressure, Cashflow pressure, and Data quality. Confirm readable sticky rail, complete dossier order, working group summary navigation, usable controls, and no clipping.

- [x] **Step 3: Update checklist only from evidence**

Mark PEP-RAIL-001 through PEP-RAIL-008 DONE only after their static and visual evidence exists. Keep a row PARTIAL when browser evidence remains absent. Mark PEP-RAIL-009 DONE only after the targeted Balance check confirms this feature did not edit it.

- [ ] **Step 4: Commit verification evidence**

~~~sh
git add docs/superpowers/checklists/2026-07-22-pulse-engine-group-rail.md
git commit -m "docs: verify Pulse Engine group rail"
~~~
