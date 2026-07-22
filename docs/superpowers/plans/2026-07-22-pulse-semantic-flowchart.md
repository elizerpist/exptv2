# Pulse Semantic Flowchart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put an inspectable, detailed semantic Pulse decision flowchart above the current mockup so every route from input to shown, waiting, suppressed, discarded, or retriggered message is clear.

**Architecture:** Add a static semantic HTML card immediately after the top bar. It uses an ordered set of labelled stages and branch lanes rather than a canvas/SVG graph, so the same policy is accessible and readable at Android width. The existing Decision Trace remains the concrete scenario renderer; the new card explains the invariant engine policy.

**Tech Stack:** Static HTML, scoped CSS, existing Node.js static contract tests.

## Global Constraints

- Work only in the Pulse mockup, its focused static test, and Pulse flowchart documentation.
- Place `data-pulse-semantic-flowchart` before `.hero-grid` and create no fourth primary rail.
- Use semantic HTML: `section`, `ol`, `li`, `article`, headings, decision copy, and labelled branches; do not draw an untestable image or SVG-only graph.
- The flow must explicitly say user score inspection is not a trigger and score alone is not enough.
- Eligibility and evidence must appear before priority; an excluded signal cannot regain eligibility through score.
- Show deferred/engine-only no-copy, stale/muted/same-fingerprint/insufficient-confidence/below-delay wait paths, forming, suppression without queueing, background pending, shown/dismissed non-repeat, supersede, and retrigger.
- Preserve existing Decision Trace, its three scenario controls, and the three approved group rails.
- Do not modify `balance_latest_layout.html`.
- Use local automated verification; do not pause for screenshots or user confirmation.

---

## File Map

- Create: `docs/prototypes/pulse_semantic_flowchart_test.js`
  - Static contract for top placement, all stage and branch anchors, score rule,
    priority formula, lifecycle exits, responsive CSS marker, and three-rail
    invariant.
- Modify: `docs/prototypes/pulse_engine_panel_mockup.html`
  - Add scoped `.semantic-flow-*` styles near existing overview/flow styles.
  - Insert the full flowchart directly after `</header>` and before
    `<section class="hero-grid">`.
- Modify: `docs/superpowers/checklists/2026-07-22-pulse-semantic-flowchart.md`
  - Record fresh automated evidence and honest visual-review status.
- Modify: `docs/superpowers/plans/2026-07-22-pulse-semantic-flowchart.md`
  - Mark exact completed steps and evidence after fresh verification.

## Shared anchors

```html
<section class="card pulse-semantic-flowchart" data-pulse-semantic-flowchart>
  <ol class="semantic-flow-grid">
    <li data-flow-stage="entry">…</li>
    <li data-flow-stage="recalculation">…</li>
    <li data-flow-stage="source-gate">…</li>
    <li data-flow-stage="evidence">…</li>
    <li data-flow-stage="priority">…</li>
    <li data-flow-stage="selection">…</li>
    <li data-flow-stage="composition">…</li>
    <li data-flow-stage="delivery">…</li>
    <li data-flow-stage="lifecycle">…</li>
  </ol>
</section>
```

Every non-linear route uses a stable `data-flow-branch` value. The test requires:

```text
inspect-only, trigger-input, no-copy, wait-no-score, forming, ready,
suppressed-not-queued, selected, pending-resume, shown, no-header,
superseded, retrigger
```

### Task 1: Define the semantic flowchart contract

**Files:**

- Create: `docs/prototypes/pulse_semantic_flowchart_test.js`
- Read: `docs/prototypes/pulse_engine_decision_trace_test.js`
- Read: `docs/superpowers/specs/2026-07-22-pulse-semantic-flowchart-design.md`

**Consumes:** The current top bar, hero grid, Decision Trace, and rail markup.

**Produces:** A focused failing contract that describes the exact information
the new top flowchart must expose.

- [ ] **Step 1: Write the failing static contract**

Create `docs/prototypes/pulse_semantic_flowchart_test.js` with:

```js
#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const html = fs.readFileSync(
  path.join(__dirname, "pulse_engine_panel_mockup.html"),
  "utf8",
);

const flowStart = html.indexOf("data-pulse-semantic-flowchart");
const heroStart = html.indexOf('<section class="hero-grid">');
assert.notEqual(flowStart, -1, "semantic flowchart root is required");
assert.ok(flowStart < heroStart, "flowchart must appear before the hero grid");

for (const stage of [
  "entry", "recalculation", "source-gate", "evidence", "priority",
  "selection", "composition", "delivery", "lifecycle",
]) {
  assert.match(html, new RegExp('data-flow-stage="' + stage + '"'), "missing flow stage: " + stage);
}

for (const branch of [
  "inspect-only", "trigger-input", "no-copy", "wait-no-score", "forming",
  "ready", "suppressed-not-queued", "selected", "pending-resume", "shown",
  "no-header", "superseded", "retrigger",
]) {
  assert.match(html, new RegExp('data-flow-branch="' + branch + '"'), "missing flow branch: " + branch);
}

assert.match(html, /Score önmagában nem elég/, "score must not be enough on its own");
assert.match(html, /domináns eligible source base/, "priority needs a dominant base explanation");
assert.match(html, /urgent due state[\s\S]*newer materially changed fingerprint[\s\S]*stable source-ID order/, "tie-break order is required");
assert.match(html, /deferred[\s\S]*engine-only[\s\S]*nem készít header copyt/, "no-copy exclusions are required");
assert.match(html, /background[\s\S]*open\/resume/, "background delivery route is required");
assert.match(html, /shown\/dismissed fingerprint[\s\S]*nem ismétel/, "same fingerprint non-repeat is required");
assert.match(html, /\.semantic-flow-grid[\s\S]*grid-template-columns/, "flowchart grid CSS is required");
assert.equal((html.match(/data-group-rail=/g) || []).length, 3, "no fourth primary rail");

console.log("pulse_semantic_flowchart_test: PASS");
```

- [ ] **Step 2: Confirm the contract is red**

Run:

```sh
node docs/prototypes/pulse_semantic_flowchart_test.js
```

Expected: fails with `semantic flowchart root is required`.

### Task 2: Add the top semantic policy flow

**Files:**

- Modify: `docs/prototypes/pulse_engine_panel_mockup.html` near the existing
  `.flow` styles and immediately after the top bar.
- Test: `docs/prototypes/pulse_semantic_flowchart_test.js`

**Consumes:** Existing visual tokens (`--line`, `--surface`, status tags) and
the published Pulse policy.

**Produces:** An accessible, detailed decision flow with every decision and
outcome route visible in the top-level mockup.

- [ ] **Step 1: Add responsive, scoped CSS**

Add styles for `.pulse-semantic-flowchart`, `.semantic-flow-grid`,
`.semantic-flow-step`, `.semantic-flow-node`, `.semantic-flow-branches`,
`.semantic-flow-branch`, `.semantic-flow-arrow`, `.semantic-flow-formula`, and
`.semantic-flow-legend`.

Desktop behavior:

```css
.semantic-flow-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}
```

At the existing narrow breakpoint, use:

```css
.semantic-flow-grid {
  grid-template-columns: 1fr;
}
```

Use neutral cards for processing, red/warn lanes for stopped or waiting paths,
violet for composition, and green for delivery/retrigger. Text must state the
outcome without relying on color.

- [ ] **Step 2: Add the semantic chart before the hero grid**

Insert a `section.card.pulse-semantic-flowchart` after the top-bar header. It
contains a section heading, a legend, and a nine-item `ol.semantic-flow-grid`.

The ordered stage contents must include these exact policy decisions:

```text
entry: user selects/inspects score -> inspect-only; data/forecast/app event -> trigger-input
recalculation: compute current source, domain/target, confidence, fingerprint
source-gate: deferred + engine-only -> no-copy; stale/muted/same fingerprint/insufficient confidence/below delay -> wait-no-score
evidence: related signals share domain/target -> forming or ready; unrelated -> independent candidate
priority: score is calculated only for ready candidates; formula and score-is-not-enough rule
selection: highest ready candidate selected; lower ready -> suppressed-not-queued; published tie-break order
composition: headline/evidence/time-cause/caveat/recovery slots; no-copy source exclusions
delivery: foreground -> shown; background -> pending-resume then open/resume
lifecycle: shown/dismissed fingerprint no replay; stronger state -> superseded; changed/resolved -> retrigger; no ready candidate -> no-header
```

Use `data-flow-stage` and `data-flow-branch` exactly as defined in Shared
anchors. Keep the wording visible in the DOM; do not hide the explanatory
branches in tooltips or JavaScript.

- [ ] **Step 3: Run the new contract and existing regressions**

Run:

```sh
node docs/prototypes/pulse_semantic_flowchart_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
```

Expected: every command reports `PASS`.

- [ ] **Step 4: Commit the top flowchart**

```sh
git add docs/prototypes/pulse_semantic_flowchart_test.js docs/prototypes/pulse_engine_panel_mockup.html
git commit -m "feat: add Pulse semantic decision flow"
```

### Task 3: Record fresh evidence

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-22-pulse-semantic-flowchart.md`
- Modify: `docs/superpowers/plans/2026-07-22-pulse-semantic-flowchart.md`

**Consumes:** The completed flowchart and fresh local verification results.

**Produces:** Honest requirement statuses and a record of every verification
command used for handoff.

- [ ] **Step 1: Run the final complete verification**

Run:

```sh
node docs/prototypes/pulse_semantic_flowchart_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
node -e 'const fs=require("fs"); const html=fs.readFileSync("docs/prototypes/pulse_engine_panel_mockup.html","utf8"); for (const item of html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/g)) new Function(item[1]); console.log("embedded script parse: PASS");'
curl -fsS -o /dev/null -w 'HTTP %{http_code} %{size_download} bytes\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
git diff --check
test "$(git hash-object balance_latest_layout.html)" = "a4b940489c11582f7252d6d2f5b86c0114f9817a"
```

Expected: every command exits `0`.

- [ ] **Step 2: Update evidence statuses**

Set PSF-001 through PSF-008 to `DONE` only when their direct static contracts
pass. Set PSF-009 to `PARTIAL` because the user asked not to request or capture
screenshots; record the CSS/static evidence without claiming visual review.
Set PSF-010 to `DONE` only after the baseline hash command passes. Add the
actual passing command names and outputs below the checklist.

- [ ] **Step 3: Mark plan execution and commit evidence**

Mark every completed checkbox in this plan and append a dated execution record.
Then run:

```sh
git add docs/superpowers/checklists/2026-07-22-pulse-semantic-flowchart.md docs/superpowers/plans/2026-07-22-pulse-semantic-flowchart.md
git diff --cached --check
git commit -m "docs: verify Pulse semantic decision flow"
```

## Plan Self-Review

- Every acceptance ID maps to a contract assertion, styling rule, or final
  evidence step.
- The static design keeps the flowchart independent from the existing scenario
  renderer, so it cannot produce an alternate score or header decision.
- The plan names every stage and branch before implementation; the test and
  markup use the same exact anchor values.
