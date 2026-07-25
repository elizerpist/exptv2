#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const html = fs.readFileSync(
  path.join(__dirname, 'pulse_engine_panel_mockup.html'),
  'utf8',
);

function stylesheetRule(selector) {
  const start = html.indexOf(selector + ' {');
  assert.notEqual(start, -1, 'missing stylesheet rule: ' + selector);
  const end = html.indexOf('\n    }', start);
  assert.notEqual(end, -1, 'unterminated stylesheet rule: ' + selector);
  return html.slice(start, end + 6);
}

const pageRule = stylesheetRule('.page');
assert.match(pageRule, /width:\s*calc\(100vw\s*-\s*28px\)/, 'the board must use the full viewport width');
assert.match(pageRule, /max-width:\s*none/, 'the board must not use a fixed narrow maximum');

const boardRule = stylesheetRule('.layout-board');
assert.match(boardRule, /display:\s*grid/, 'dense content must be a fill grid');
assert.match(boardRule, /grid-template-columns:\s*repeat\(4,\s*minmax\(0,\s*1fr\)\)/, 'the shared board needs four desktop columns');
assert.match(boardRule, /overflow-x:\s*visible/, 'dense content must stay visible in the main board');

const groupPanelRule = stylesheetRule('.group-panel');
assert.match(groupPanelRule, /display:\s*grid/, 'a group must remain a wide workboard');
assert.match(groupPanelRule, /grid-template-columns:\s*minmax\(0,\s*1\.45fr\)\s+minmax\(280px,\s*\.75fr\)/, 'story and tuning need desktop columns');

assert.match(html, /class="semantic-flow-grid layout-board layout-board--flow"[\s\S]*?data-layout-board="semantic-flow"/, 'the nine-step flow must fill a three-column board');
assert.match(html, /data-pulse-phase-rail/, 'the detailed flow needs its short reading rail');
assert.match(html, /class="group-flow layout-board layout-board--manual"[\s\S]*?data-layout-board="manual"/, 'manual cards must fill a board');
assert.match(html, /class="grid-3 layout-board layout-board--forecast"[\s\S]*?data-layout-board="forecasts"/, 'forecast cards must fill a board');
assert.equal((html.match(/class="trigger-grid layout-board layout-board--trigger"/g) || []).length, 3, 'each group needs one trigger board');
assert.equal((html.match(/data-layout-board="triggers"/g) || []).length, 3, 'each trigger board needs an explicit marker');
assert.equal((html.match(/class="shared-engine-trace layout-board layout-board--engine"/g) || []).length, 3, 'each group needs one engine board');
assert.equal((html.match(/data-layout-board="engine"/g) || []).length, 3, 'each engine board needs an explicit marker');

assert.match(html, /data-dossier-section="manual"\]\s*,[\s\S]*?data-dossier-section="forecasts"\]\s*,[\s\S]*?data-dossier-section="triggers"\]\s*\{[\s\S]*?grid-column:\s*1\s*\/\s*-1/, 'long sections must span the workboard');
assert.match(html, /data-dossier-section="story"\]\s*\{[\s\S]*?grid-column:\s*1/, 'story must occupy the first desktop column');
assert.match(html, /data-dossier-section="tuning"\]\s*\{[\s\S]*?grid-column:\s*2/, 'tuning must occupy the second desktop column');

const mobileCss = html.slice(html.indexOf('@media (max-width: 640px)'), html.indexOf('</style>'));
assert.match(mobileCss, /\.page\s*\{[\s\S]*?width:\s*calc\(100vw\s*-\s*16px\)[\s\S]*?max-width:\s*none/, 'mobile must use the available viewport width');
assert.match(mobileCss, /\.layout-board--flow,[\s\S]*?\.layout-board--engine\s*\{[\s\S]*?grid-template-columns:\s*1fr/, 'mobile boards must collapse readably instead of hiding in a lane');
assert.doesNotMatch(html, /horizontal-lane/, 'the superseded lane layout must not remain');

console.log('pulse_wide_layout_test: PASS');
