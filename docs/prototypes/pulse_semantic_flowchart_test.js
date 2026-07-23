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
assert.match(html, /<ol class="semantic-flow-grid"/, "flowchart must use a semantic ordered flow");

for (const stage of [
  "entry", "recalculation", "source-gate", "evidence", "priority",
  "selection", "composition", "delivery", "lifecycle",
]) {
  assert.match(
    html,
    new RegExp('data-flow-stage="' + stage + '"'),
    "missing flow stage: " + stage,
  );
}

for (const branch of [
  "inspect-only", "trigger-input", "no-copy", "wait-no-score", "forming",
  "ready", "suppressed-not-queued", "selected", "pending-resume", "shown",
  "no-header", "superseded", "retrigger",
]) {
  assert.match(
    html,
    new RegExp('data-flow-branch="' + branch + '"'),
    "missing flow branch: " + branch,
  );
}

assert.match(html, /Score önmagában nem elég/, "score must not be enough on its own");
assert.match(html, /Nincs univerzális megjelenítési küszöb/, "priority needs no universal threshold rule");
assert.match(html, /domináns eligible source base/, "priority needs a dominant base explanation");
assert.match(html, /material-money \+15/, "material-money modifier is required");
assert.match(html, /due-within-3-days \+10/, "due-window modifier is required");
assert.match(html, /related evidence \+10/, "related evidence modifier is required");
assert.match(html, /low confidence -20/, "low confidence modifier is required");
assert.match(html, /recent dismiss -30/, "recent dismiss modifier is required");
assert.match(html, /clamp\(0\.\.100,/, "priority must be visibly clamped");
assert.match(
  html,
  /urgent due state[\s\S]*newer materially changed fingerprint[\s\S]*stable source-ID order/,
  "tie-break order is required",
);
assert.match(
  html,
  /deferred[\s\S]*engine-only[\s\S]*nem készít header copyt/,
  "deferred and engine-only sources must remain no-copy",
);
assert.match(html, /background[\s\S]*open\/resume/, "background delivery route is required");
assert.match(
  html,
  /shown\/dismissed fingerprint[\s\S]*nem ismétel/,
  "same fingerprint must not replay",
);

const gridRules = html.match(/\.semantic-flow-grid\s*\{[\s\S]*?\}/g) || [];
assert.ok(
  gridRules.some((rule) => /grid-template-columns:\s*repeat\(3/.test(rule)),
  "desktop flowchart grid is required",
);
assert.ok(
  gridRules.some((rule) => /grid-template-columns:\s*1fr/.test(rule)),
  "narrow flowchart grid is required",
);
assert.equal((html.match(/data-group-rail=/g) || []).length, 3, "no fourth primary rail");

console.log("pulse_semantic_flowchart_test: PASS");
