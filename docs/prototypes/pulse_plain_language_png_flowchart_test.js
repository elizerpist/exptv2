#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const prototypeDir = __dirname;
const html = fs.readFileSync(
  path.join(prototypeDir, "pulse_engine_panel_mockup.html"),
  "utf8",
);
const assetPath = path.join(
  prototypeDir,
  "assets",
  "pulse-egyszeru-mukodes.png",
);

assert.ok(fs.existsSync(assetPath), "plain-language PNG asset is required");
const png = fs.readFileSync(assetPath);
assert.deepEqual(
  [...png.subarray(0, 8)],
  [137, 80, 78, 71, 13, 10, 26, 10],
  "asset must be a PNG",
);
assert.ok(png.length > 20_000, "asset must contain a substantial diagram");

const figureStart = html.indexOf("data-plain-language-flowchart");
const footerStart = html.indexOf('<p class="footer-note">');
assert.notEqual(figureStart, -1, "bottom PNG figure is required");
assert.ok(figureStart < footerStart, "PNG figure must appear before the footer");
const figure = html.slice(figureStart, footerStart);
assert.match(figure, /src="assets\/pulse-egyszeru-mukodes\.png"/, "figure needs local PNG source");
assert.match(figure, /alt="[^"]*pontszám[^"]*"/, "figure needs Hungarian explanatory alt");
assert.match(figure, /A pontszám önmagában nem elég/, "figure needs central rule fallback");
assert.match(
  html,
  /\.plain-language-flowchart-image img\s*\{[\s\S]*max-width:\s*100%/,
  "responsive image CSS is required",
);
assert.equal((html.match(/data-group-rail=/g) || []).length, 3, "no fourth primary rail");

console.log("pulse_plain_language_png_flowchart_test: PASS");
