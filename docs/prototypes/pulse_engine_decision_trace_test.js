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
