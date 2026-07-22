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

const allSources = [
  "HF-001", "HF-002", "HF-003", "HF-004", "HF-005", "HF-006", "HF-007",
  "HF-008", "HF-009", "HF-010", "HF-011", "HF-012", "HF-013", "HF-014",
  "HF-015", "HF-016", "HF-017", "HF-018", "HF-019", "HF-020", "HF-021",
];
assert.match(html, /const sourceCopyRoles = \{/, "source role registry is required");
for (const id of allSources) {
  assert.match(html, new RegExp('"' + id + '": \\{'), id + " needs a source role");
}
assert.match(html, /"HF-008":[\s\S]*?mode: "deferred-no-copy"/, "HF-008 remains no-copy");
for (const id of ["HF-015", "HF-016", "HF-017", "HF-018", "HF-019"]) {
  assert.match(
    html,
    new RegExp('"' + id + '":[\\s\\S]*?mode: "engine-only"'),
    id + " must remain engine-only",
  );
}
assert.match(html, /function selectTraceSource\(sourceId\)/, "trace source navigation is required");
assert.match(html, /copyRoleBadge\(id\)/, "owner cards need copy-role badges");
assert.match(html, /data-trace-source/, "trace source controls are required");
const traceNavigation = html.slice(html.indexOf("function selectTraceSource"));
assert.match(
  traceNavigation,
  /\["engine-only", "deferred-no-copy"\]\.includes\(role\.mode\)/,
  "engine-only and deferred sources must be blocked from source navigation",
);
assert.match(html, /data-all-source-roles/, "full source-role map is required");
assert.match(html, /function renderAllSourceRoles\(\)/, "full source-role renderer is required");
assert.match(html, /function renderSharedEngineRoleBadges\(\)/, "shared engine sources need no-copy badges");

console.log("pulse_engine_decision_trace_test: PASS");
