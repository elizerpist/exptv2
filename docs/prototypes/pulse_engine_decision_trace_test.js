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

assert.match(html, /const decisionTraceScenarios = \{/, "scenario trace data is required");
for (const key of ["risk", "recovery", "data"]) {
  assert.match(
    html,
    new RegExp(key + ": \\{[\\s\\S]*?recalculation:"),
    key + " needs a recalculation record",
  );
}
assert.match(html, /function calculatePriority\(candidate\)/, "priority calculator is required");
assert.match(html, /candidate\.modifiers\.reduce/, "priority must sum visible modifiers");
assert.match(html, /Math\.max\(0, Math\.min\(100,/, "priority must clamp to 0..100");
assert.match(html, /function renderDecisionTrace\(scenarioKey\)/, "trace renderer is required");
assert.match(html, /function applyScenario\(scenarioKey\)/, "scenario synchronizer is required");

console.log("pulse_engine_decision_trace_test: PASS");
