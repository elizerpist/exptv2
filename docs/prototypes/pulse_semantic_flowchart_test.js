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

assert.match(html, /A pontszám önmagában nem elég/, "a pontszám önmagában nem elég");
assert.match(html, /Nincs általános megjelenési határ/, "a pontszám nem általános megjelenési küszöb");
assert.match(html, /fő jel alapértéke/, "a fő jel alapértékének magyarázata kötelező");
assert.match(html, /pénzben nagy eltérés \+15/, "a pénzben nagy eltérés módosítója kötelező");
assert.match(html, /3 napon belüli esedékesség \+10/, "a közeli esedékesség módosítója kötelező");
assert.match(html, /kapcsolódó jel \+10/, "a kapcsolódó jel módosítója kötelező");
assert.equal(/bizonytalan adat/i.test(html), false, "a homályos adatminőségi fogalom nem maradhat");
assert.match(html, /Adatellenőrzés a pontszám előtt/, "az adatellenőrzésnek a pontozás előtt kell állnia");
assert.match(
  html,
  /Hiányzó kategória csak a kategóriaalapú HF-002, HF-012 és HF-020 jeleket állítja meg/,
  "a kategóriahiány csak a saját hatókörében állíthat meg jelet",
);
assert.match(html, /nemrég elutasított −30/, "a nemrég elutasított levonása kötelező");
assert.match(html, /pontszám = fő jel alapértéke/, "a pontszám képlete látható legyen");
assert.match(
  html,
  /sürgős határidő[\s\S]*frissebb valódi változás[\s\S]*állandó HF-sorrend/,
  "a döntetlen feloldásának sorrendje kötelező",
);
assert.match(
  html,
  /későbbre halasztott HF-008[\s\S]*csak a motorhoz tartozó HF-015–HF-019[\s\S]*nem ír üzenetet/,
  "a későbbre halasztott és a csak motorhoz tartozó jelek nem írhatnak üzenetet",
);
assert.match(html, /alkalmazás nincs nyitva[\s\S]*csak megnyitás után jelenik meg/, "a háttérben számolt üzenet útja kötelező");
assert.match(
  html,
  /már megmutatott vagy elutasított azonos helyzet nem ismétel/,
  "azonos helyzet nem ismételhet",
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
