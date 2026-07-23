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

const laneRule = stylesheetRule('.horizontal-lane');
assert.match(laneRule, /display:\s*grid/, 'lanes must keep cards on a grid row');
assert.match(laneRule, /grid-auto-flow:\s*column/, 'lanes must grow horizontally');
assert.match(laneRule, /grid-auto-columns:\s*minmax\(260px,\s*330px\)/, 'lanes need readable card widths');
assert.match(laneRule, /overflow-x:\s*auto/, 'lanes need their own horizontal scroll');
assert.match(laneRule, /scroll-snap-type:\s*x\s+proximity/, 'lanes should settle on card starts');

const groupPanelRule = stylesheetRule('.group-panel');
assert.match(groupPanelRule, /display:\s*grid/, 'a group must be a wide workboard');
assert.match(groupPanelRule, /grid-template-columns:\s*minmax\(0,\s*1\.45fr\)\s+minmax\(280px,\s*\.75fr\)/, 'story and tuning need desktop columns');

assert.match(html, /class="semantic-flow-grid horizontal-lane"[\s\S]*?data-horizontal-lane="semantic-flow"/, 'the nine-step flow must be a horizontal lane');
assert.match(html, /\.semantic-flow-arrow::before\s*\{[\s\S]*?content:\s*"→"/, 'the flow arrow must point right');
assert.match(html, /class="group-flow horizontal-lane"[\s\S]*?data-horizontal-lane="manual"/, 'manual cards must be a horizontal lane');
assert.match(html, /class="grid-3 horizontal-lane"[\s\S]*?data-horizontal-lane="forecasts"/, 'forecast cards must be a horizontal lane');
assert.equal((html.match(/class="trigger-grid horizontal-lane"/g) || []).length, 3, 'each group needs one horizontal trigger lane');
assert.equal((html.match(/data-horizontal-lane="triggers"/g) || []).length, 3, 'each trigger lane needs an explicit marker');
assert.equal((html.match(/class="shared-engine-trace horizontal-lane"/g) || []).length, 3, 'each group needs one horizontal engine lane');
assert.equal((html.match(/data-horizontal-lane="engine"/g) || []).length, 3, 'each engine lane needs an explicit marker');

assert.match(html, /data-dossier-section="manual"\]\s*,[\s\S]*?data-dossier-section="forecasts"\]\s*,[\s\S]*?data-dossier-section="triggers"\]\s*\{[\s\S]*?grid-column:\s*1\s*\/\s*-1/, 'long sections must span the workboard');
assert.match(html, /data-dossier-section="story"\]\s*\{[\s\S]*?grid-column:\s*1/, 'story must occupy the first desktop column');
assert.match(html, /data-dossier-section="tuning"\]\s*\{[\s\S]*?grid-column:\s*2/, 'tuning must occupy the second desktop column');

const mobileCss = html.slice(html.indexOf('@media (max-width: 640px)'), html.indexOf('</style>'));
assert.doesNotMatch(mobileCss, /\.semantic-flow-grid\s*\{\s*grid-template-columns:\s*1fr/, 'mobile must not collapse the flow into one column');
assert.doesNotMatch(mobileCss, /\.trigger-grid\s*\{\s*grid-template-columns:\s*1fr/, 'mobile must not collapse trigger lanes into one column');
assert.doesNotMatch(mobileCss, /\.group-flow,[\s\S]*?\.shared-engine-trace,[\s\S]*?\.trace-stage-grid\s*\{\s*grid-template-columns:\s*1fr/, 'mobile must not collapse the manual and engine lanes');

console.log('pulse_wide_layout_test: PASS');
