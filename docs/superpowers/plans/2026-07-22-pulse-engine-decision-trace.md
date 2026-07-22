# Pulse Engine Decision Trace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Pulse Engine mockup into an inspectable deterministic decision trace that explains eligibility, story formation, priority, header delivery, lifecycle, and HF-to-copy contribution.

**Architecture:** Preserve the approved three-group rail. Add one global Engine Decision Trace before the group dossiers; it reads one local scenario object and writes six stage containers plus the existing phone preview. Keep source ownership in the current group cards and add role badges/navigation rather than duplicate cards.

**Tech Stack:** Static HTML, CSS, vanilla browser JavaScript, Node.js static contract tests.

## Global Constraints

- Work only in docs/prototypes/pulse_engine_panel_mockup.html and Pulse trace documentation/tests.
- The only primary rail entries are Budget pressure, Cashflow pressure, and Data quality.
- No AI, no server, no remote data, no notification queue, and no fourth rail.
- Eligibility/evidence happens before priority; a score cannot revive waiting, muted, stale, superseded, or same-fingerprint state.
- Priority is dominant base weight plus visible existing modifiers, clamped from 0 through 100.
- HF-008 is deferred/no V1 copy. HF-015 through HF-019 are engine-only and cannot generate financial header copy.
- Preserve the current group rail contract and do not edit balance_latest_layout.html.
- Use local automated verification; do not pause for screenshots or user confirmation.

---

## File Map

- Create: docs/prototypes/pulse_engine_decision_trace_test.js
  - Node static contract for trace stages, scenarios, score formula, role coverage, and prohibited copy.
- Modify: docs/prototypes/pulse_engine_panel_mockup.html
  - CSS near existing group-flow styles around line 400.
  - Trace markup after the hero-grid around line 1221 and before the workspace.
  - Scenario model/rendering in the script block beginning around line 2086.
  - Role badges in renderTriggerCard around line 2243.
  - Source navigation next to selectGroup around line 2279.
- Modify: docs/superpowers/checklists/2026-07-22-pulse-engine-decision-trace.md
  - Only after fresh verification.
- Modify: docs/superpowers/plans/2026-07-22-pulse-engine-decision-trace.md
  - Mark completed execution steps and record evidence.

## Shared Interfaces

~~~js
const decisionTraceScenarios = {
  risk: { phone, recalculation, signals, candidates, lifecycle, copy, omitted },
  recovery: { phone, recalculation, signals, candidates, lifecycle, copy, omitted },
  data: { phone, recalculation, signals, candidates, lifecycle, copy, omitted }
};

const sourceCopyRoles = {
  "HF-001": { group: "budget", role: "headline", mode: "can-lead", reason: "Month-end forecast claim" }
};

function calculatePriority(candidate) {
  const delta = candidate.modifiers.reduce((sum, modifier) => sum + modifier.value, 0);
  return Math.max(0, Math.min(100, candidate.base + delta));
}

function renderDecisionTrace(scenarioKey) {}
function applyScenario(scenarioKey) {}
function selectTraceSource(sourceId) {}
~~~

### Task 1: Test and add the semantic Decision Trace shell

**Files:**

- Create: docs/prototypes/pulse_engine_decision_trace_test.js
- Modify: docs/prototypes/pulse_engine_panel_mockup.html:400-460, 990-1042, 1221

**Consumes:** Existing card, tag, scenario-button, phone-preview, and group-rail styles.

**Produces:** Six stable trace stage anchors and an accessible three-scenario selector without changing the group rail.

- [ ] **Step 1: Write the failing contract test**

Create docs/prototypes/pulse_engine_decision_trace_test.js:

~~~js
#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const html = fs.readFileSync(
  path.join(__dirname, "pulse_engine_panel_mockup.html"),
  "utf8",
);

const stages = [
  "recalculation",
  "eligibility",
  "formation",
  "priority",
  "delivery",
  "copy-map",
];

assert.match(html, /data-engine-decision-trace/, "Decision Trace root is required");
assert.match(html, /data-engine-scenario-tabs/, "scenario tablist is required");
for (const key of ["risk", "recovery", "data"]) {
  assert.match(html, new RegExp('data-engine-scenario="' + key + '"'), key + " button is required");
}
for (const stage of stages) {
  assert.match(html, new RegExp('data-trace-stage="' + stage + '"'), "missing stage: " + stage);
}
assert.equal((html.match(/data-group-rail=/g) || []).length, 3, "no fourth primary rail");
console.log("pulse_engine_decision_trace_test: PASS");
~~~

- [ ] **Step 2: Confirm the test is red**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
~~~

Expected: fails with Decision Trace root is required.

- [ ] **Step 3: Add the trace markup and responsive styles**

Insert this directly before the existing workspace section:

~~~html
<section class="card engine-decision-trace" data-engine-decision-trace aria-labelledby="engine-trace-title">
  <div class="section-head">
    <div>
      <h2 id="engine-trace-title">Engine decision trace</h2>
      <p>Ugyanaz a lokális állapot végigkövethető a raw signaloktól az egyetlen header-storyig.</p>
    </div>
    <span class="tag violet">why this pulse?</span>
  </div>
  <div class="scenario-buttons engine-scenario-tabs" role="tablist" aria-label="Engine trace scenario" data-engine-scenario-tabs>
    <button class="active" type="button" role="tab" aria-selected="true" aria-controls="engine-trace-output" data-engine-scenario="risk">Risk</button>
    <button type="button" role="tab" aria-selected="false" aria-controls="engine-trace-output" data-engine-scenario="recovery">Recovery</button>
    <button type="button" role="tab" aria-selected="false" aria-controls="engine-trace-output" data-engine-scenario="data">Data quality</button>
  </div>
  <div class="engine-trace-output" id="engine-trace-output" role="tabpanel">
    <section class="trace-stage" data-trace-stage="recalculation"></section>
    <section class="trace-stage" data-trace-stage="eligibility"></section>
    <section class="trace-stage" data-trace-stage="formation"></section>
    <section class="trace-stage" data-trace-stage="priority"></section>
    <section class="trace-stage" data-trace-stage="delivery"></section>
    <section class="trace-stage" data-trace-stage="copy-map"></section>
  </div>
</section>
~~~

Add scoped CSS for .engine-decision-trace, .engine-trace-output, .trace-stage,
.trace-stage-grid, .trace-source-list, .trace-candidate, .trace-copy-fragment,
and .trace-source-button. The desktop trace uses two columns where appropriate;
the existing narrow-screen media rule collapses all trace grids to one column.
Only source-list overflow may scroll horizontally.

- [ ] **Step 4: Confirm the shell and regression tests are green**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
~~~

Expected: both report PASS.

- [ ] **Step 5: Commit the shell**

~~~sh
git add docs/prototypes/pulse_engine_decision_trace_test.js docs/prototypes/pulse_engine_panel_mockup.html
git commit -m "feat: add Pulse decision trace shell"
~~~

### Task 2: Implement the deterministic motor renderer

**Files:**

- Modify: docs/prototypes/pulse_engine_decision_trace_test.js
- Modify: docs/prototypes/pulse_engine_panel_mockup.html:1083-1097, 2086-2121

**Consumes:** The trace stage anchors, existing phone IDs, and existing scenario buttons.

**Produces:** One source of truth for Risk, Recovery, and Data quality; every scenario updates phone and all stages together.

- [ ] **Step 1: Extend the test for data and renderer interfaces**

Append before the test PASS line:

~~~js
assert.match(html, /const decisionTraceScenarios = \{/, "scenario data is required");
for (const key of ["risk", "recovery", "data"]) {
  assert.match(html, new RegExp(key + ": \\{[\\s\\S]*?recalculation:"), key + " needs recalculation data");
}
assert.match(html, /function calculatePriority\(candidate\)/, "priority function is required");
assert.match(html, /candidate\.modifiers\.reduce/, "priority must use visible modifiers");
assert.match(html, /Math\.max\(0, Math\.min\(100,/, "priority must clamp 0..100");
assert.match(html, /function renderDecisionTrace\(scenarioKey\)/, "trace renderer is required");
assert.match(html, /function applyScenario\(scenarioKey\)/, "scenario synchronizer is required");
~~~

- [ ] **Step 2: Confirm the expanded contract is red**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
~~~

Expected: fails with scenario data is required.

- [ ] **Step 3: Define all three deterministic scenario fixtures**

Replace the existing scenarios object with decisionTraceScenarios. Each scenario must have:

~~~js
{
  phone: { pulse, detail, title },
  recalculation: { event, background },
  signals: [{ id, state, reason, group }],
  candidates: [{ id, title, status, dominant, base, modifiers, evidence, outcome }],
  lifecycle: ["observing", "eligible", "ready", "selected", "delivered", "shown"],
  copy: [{ slot, source, text }],
  omitted: [{ id, reason }]
}
~~~

Use these required facts:

- Risk: HF-001, HF-002, HF-005, and HF-006 are eligible; HF-003 and HF-021 wait. The selected month-end story starts from HF-001 base 85, gets +15 material money impact and +10 related evidence, and clamps to 100. A due fixed-cost story starts from HF-006 base 70, gets +10 due window, and is suppressed.
- Recovery: a resolved HF-001 plus arrived-income HF-007 and existing score movement HF-014 form a meaningful recovery. The selected recovery has base 70 and no invented modifiers.
- Data: HF-021 becomes eligible only after the 12h delay/group threshold. Its base is 35; unrelated HF-014 remains waiting and cannot strengthen it.

- [ ] **Step 4: Implement the priority and synchronized renderer**

Add:

~~~js
function calculatePriority(candidate) {
  const delta = candidate.modifiers.reduce((sum, modifier) => sum + modifier.value, 0);
  return Math.max(0, Math.min(100, candidate.base + delta));
}
~~~

renderDecisionTrace must populate all six existing stage containers with:

1. recalculation event and foreground/background explanation;
2. source state, eligibility outcome, and reason;
3. forming/ready evidence relationship;
4. candidate base, each modifier, final priority, selected/suppressed outcome;
5. lifecycle progression and same-fingerprint/retrigger explanation;
6. labelled headline/evidence/time-cause/caveat/recovery fragments plus omitted reasons.

applyScenario must update phonePulse, phoneDetail, selectedTitle, selectedScore,
scorebar, both visible scenario button sets, and then call renderDecisionTrace.
Keyboard behavior for both selector sets supports ArrowLeft, ArrowRight, Home,
and End. Initialize with applyScenario("risk").

- [ ] **Step 5: Run renderer and regression verification**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
node -e 'const fs=require("fs"); const html=fs.readFileSync("docs/prototypes/pulse_engine_panel_mockup.html","utf8"); for (const item of html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/g)) new Function(item[1]); console.log("embedded script parse: PASS");'
~~~

Expected: all commands report PASS.

- [ ] **Step 6: Commit the renderer**

~~~sh
git add docs/prototypes/pulse_engine_decision_trace_test.js docs/prototypes/pulse_engine_panel_mockup.html
git commit -m "feat: render Pulse engine decision trace"
~~~

### Task 3: Map every HF source to a story role

**Files:**

- Modify: docs/prototypes/pulse_engine_decision_trace_test.js
- Modify: docs/prototypes/pulse_engine_panel_mockup.html:2123-2197, 2243-2249, 2279-2294
- Modify: docs/superpowers/checklists/2026-07-22-pulse-engine-decision-trace.md
- Modify: docs/superpowers/plans/2026-07-22-pulse-engine-decision-trace.md

**Consumes:** decisionTraceScenarios, groupDossiers, renderTriggerCard, and selectGroup.

**Produces:** Full HF copy-role visibility, clickable owner-card trace references, and fresh evidence.

- [ ] **Step 1: Extend the contract for every source role**

Append before PASS:

~~~js
const allSources = [
  "HF-001", "HF-002", "HF-003", "HF-004", "HF-005", "HF-006", "HF-007",
  "HF-008", "HF-009", "HF-010", "HF-011", "HF-012", "HF-013", "HF-014",
  "HF-015", "HF-016", "HF-017", "HF-018", "HF-019", "HF-020", "HF-021"
];
assert.match(html, /const sourceCopyRoles = \{/, "source role registry is required");
for (const id of allSources) {
  assert.match(html, new RegExp('"' + id + '": \\{'), id + " needs a source role");
}
assert.match(html, /"HF-008":[\s\S]*?mode: "deferred-no-copy"/, "HF-008 remains no-copy");
for (const id of ["HF-015", "HF-016", "HF-017", "HF-018", "HF-019"]) {
  assert.match(html, new RegExp('"' + id + '":[\\s\\S]*?mode: "engine-only"'), id + " remains engine-only");
}
assert.match(html, /function selectTraceSource\(sourceId\)/, "source navigation is required");
assert.match(html, /copyRoleBadge\(id\)/, "owner cards need role badges");
~~~

- [ ] **Step 2: Confirm the source-role test is red**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
~~~

Expected: fails with source role registry is required.

- [ ] **Step 3: Add sourceCopyRoles and badge rendering**

Define all 21 source roles using these stable modes:

~~~text
HF-001: headline/can-lead
HF-002, HF-004, HF-012, HF-013, HF-020: evidence/support
HF-003: coach detail/support
HF-005, HF-006: time-cause/support
HF-007: headline or recovery/can-lead
HF-008: none/deferred-no-copy
HF-009, HF-010, HF-011: headline/can-lead
HF-014: context/support
HF-015–HF-019: none/engine-only
HF-021: confidence caveat/can-lead
~~~

Implement copyRoleBadge(id), call it from renderTriggerCard, and display mode plus
role without creating another card.

- [ ] **Step 4: Add trace-source navigation**

Render trace references as buttons containing data-trace-source="HF-xxx".
Implement:

~~~js
function selectTraceSource(sourceId) {
  const role = sourceCopyRoles[sourceId];
  if (!role || role.group === "engine") return;
  selectGroup(role.group, false);
  requestAnimationFrame(() => {
    const card = document.querySelector('[data-hf-id="' + sourceId + '"]');
    if (!card) return;
    card.scrollIntoView({ behavior: "smooth", block: "center" });
    card.tabIndex = -1;
    card.focus({ preventScroll: true });
  });
}
~~~

Click, Enter, and Space invoke selectTraceSource. Engine-only/deferred sources
show their no-copy reason rather than a fake header-copy link.

- [ ] **Step 5: Run final fresh verification**

Run:

~~~sh
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
node -e 'const fs=require("fs"); const html=fs.readFileSync("docs/prototypes/pulse_engine_panel_mockup.html","utf8"); for (const item of html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/g)) new Function(item[1]); console.log("embedded script parse: PASS");'
curl -fsS -o /dev/null -w 'HTTP %{http_code} %{size_download} bytes\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
git diff --check
test "$(git hash-object balance_latest_layout.html)" = "a4b940489c11582f7252d6d2f5b86c0114f9817a"
~~~

Expected: every command exits 0.

- [ ] **Step 6: Record evidence and commit**

Mark PEDT-001 through PEDT-009 only when the corresponding automated/direct
browser evidence exists. Mark PEDT-010 PARTIAL if Android-width direct
inspection cannot be performed locally; never claim it done only from static
tests. Mark PEDT-011 DONE only after its hash command succeeds.

~~~sh
git add docs/prototypes/pulse_engine_decision_trace_test.js docs/prototypes/pulse_engine_panel_mockup.html docs/superpowers/checklists/2026-07-22-pulse-engine-decision-trace.md docs/superpowers/plans/2026-07-22-pulse-engine-decision-trace.md
git commit -m "feat: explain Pulse engine decisions"
~~~

## Plan Self-Review

- The nine runtime subprocesses map to the three tasks: recalculation through
  priority in Task 2, copy composition and source ownership in Task 3, delivery
  and lifecycle in Tasks 2 and 3.
- The score formula, source-role exclusions, three-group rail constraint, and
  Balance scope protection all have explicit contract checks.
- The plan uses the same interface names in every task: decisionTraceScenarios,
  sourceCopyRoles, calculatePriority, renderDecisionTrace, applyScenario, and
  selectTraceSource.
