#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const html = fs.readFileSync(
  path.join(__dirname, 'pulse_engine_panel_mockup.html'),
  'utf8',
);

function rule(selector) {
  const start = html.indexOf(selector + ' {');
  assert.notEqual(start, -1, 'missing CSS rule: ' + selector);
  const end = html.indexOf('\n    }', start);
  assert.notEqual(end, -1, 'unterminated CSS rule: ' + selector);
  return html.slice(start, end + 6);
}

const page = rule('.page');
assert.match(page, /width:\s*calc\(100vw\s*-\s*28px\)/, 'the page must fill the viewport width');
assert.match(page, /max-width:\s*none/, 'the page must not stop at a narrow maximum width');

const board = rule('.layout-board');
assert.match(board, /display:\s*grid/, 'dense content must use a grid');
assert.match(board, /overflow-x:\s*visible/, 'main content must not hide in an inner horizontal lane');

assert.match(html, /data-pulse-phase-rail/, 'a short reading rail is required');
for (const phase of ['change', 'validation', 'situation', 'priority', 'message']) {
  assert.match(
    html,
    new RegExp('data-pulse-phase="' + phase + '"'),
    'missing reading phase: ' + phase,
  );
}

for (const area of ['semantic-flow', 'manual', 'forecasts', 'triggers', 'engine']) {
  assert.match(
    html,
    new RegExp('data-layout-board="' + area + '"'),
    'missing filled board: ' + area,
  );
}

assert.doesNotMatch(html, /horizontal-lane/, 'the superseded inner lane layout must be removed');

console.log('pulse_filled_workboard_test: PASS');
