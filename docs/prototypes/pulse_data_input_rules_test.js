#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const html = fs.readFileSync(
  path.join(__dirname, "pulse_engine_panel_mockup.html"),
  "utf8",
);

assert.equal(
  /bizonytalan adat/i.test(html),
  false,
  "a homályos adatminőségi fogalom nem maradhat a prototípusban",
);
assert.equal(
  /−\s*bizonytalan adat\s*−20/i.test(html),
  false,
  "adatminőség nem lehet általános −20 pontos levonás",
);
assert.match(html, /data-flow-branch="input-check"/, "adatellenőrzési ág kötelező");
assert.match(html, /Adatellenőrzés a pontszám előtt/, "az adatellenőrzésnek a pontozás előtt kell állnia");
assert.match(
  html,
  /Hiányzó összeg vagy dátum:[\s\S]*?pontszám nélkül/,
  "a hiányzó összegnek vagy dátumnak egyértelmű következménye kell legyen",
);
assert.match(
  html,
  /Hiányzó kategória csak a kategóriaalapú HF-002, HF-012 és HF-020 jeleket állítja meg/,
  "a kategóriahiány hatóköre legyen pontos",
);
assert.match(
  html,
  /A várt, de meg nem érkezett bevétel nem adathiba/,
  "a várt bevételt el kell választani az adathibától",
);
assert.match(
  html,
  /HF-021[\s\S]*?nem von le pontot/,
  "a HF-021 nem lehet pénzügyi pontlevonás",
);
assert.match(html, /inputChecks:\s*\[/, "minden döntési példához kell adatellenőrzés");
for (const scenarioKey of ["risk", "recovery", "data"]) {
  const start = html.indexOf("      " + scenarioKey + ": {");
  assert.notEqual(start, -1, scenarioKey + " döntési példa kötelező");
  const next = html.indexOf("\n      },", start);
  const scenario = html.slice(start, next === -1 ? undefined : next);
  assert.match(
    scenario,
    /inputChecks:\s*\[/,
    scenarioKey + " döntési példának saját adatellenőrzést kell mutatnia",
  );
}
assert.match(html, /function traceInputCheck\(check\)/, "adatellenőrzés-kirajzoló kötelező");
assert.match(
  html,
  /scenario\.inputChecks\.map\(traceInputCheck\)/,
  "a döntési nyomvonalnak ténylegesen ki kell rajzolnia az adatellenőrzést",
);
assert.match(
  html,
  /scope: "Teljes költés és pénzáramlás"/,
  "a teljes költés és pénzáramlás külön számolhatósága kötelező",
);
assert.match(
  html,
  /scope: "Kategóriaalapú jelek: HF-002, HF-012, HF-020"/,
  "az érintett kategóriaalapú jeleknek látszaniuk kell",
);
assert.match(
  html,
  /\{ id: "HF-002", state: "waiting"/,
  "a kategóriahiány példájában a HF-002 várakozzon",
);

console.log("pulse_data_input_rules_test: PASS");
