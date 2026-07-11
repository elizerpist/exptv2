const fs = require('fs');
const path = require('path');

const htmlPath = path.join(__dirname, 'stats_common_2025_snapshot_mode.html');
const html = fs.readFileSync(htmlPath, 'utf8');

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function includesAll(values) {
  for (const value of values) {
    assert(html.includes(value), `Missing required text/snippet: ${value}`);
  }
}

includesAll([
  'Snapshot mód',
  'Mentett nézetek',
  'Aktuális mentése',
  'Bevétel',
  'Kiadás',
  'Összegzés',
  'Keresés vagy vendor',
  'alatti tranzakciók rejtve',
]);

includesAll([
  'const snapshots =',
  'function applySnapshot',
  'function stepSnapshot',
  'function handleJoystickDrag',
  'function showTickFeedback',
  'function saveCurrentSnapshot',
  'data-snapshot-id',
  'page: 1',
  'page: 2',
  "scope: 'month'",
  "scope: 'year'",
  'threshold',
  'categories',
  'vendors',
]);

assert(/type: 'expense'/.test(html), 'Snapshot must store expense side');
assert(/type: 'income'/.test(html), 'Snapshot must store income side');
assert(/categories:\s*\[/.test(html), 'Snapshot must store category scope');
assert(/vendors:\s*\[/.test(html), 'Snapshot must store vendor filter');
assert(/threshold:\s*\d+/.test(html), 'Snapshot must store threshold');
assert(/scope: 'year'/.test(html), 'Snapshot must store yearly view');
assert(/scope: 'month'/.test(html), 'Snapshot must store monthly view');
assert(/month:\s*(null|\d+)/.test(html), 'Snapshot must store focused month state');

assert(!/<section class="snapshot-dock"/.test(html), 'Snapshot dock must not occupy main content space');
assert(/<section class="snapshot-editor"/.test(html), 'Missing snapshot editor inside FAB sheet');
assert(/<section class="content-viewport"/.test(html), 'Missing content viewport');
assert(!/id="prevSnapshot"/.test(html), 'Previous snapshot button should be removed; use swipe + tap-select');
assert(!/id="nextSnapshot"/.test(html), 'Next snapshot button should be removed; use swipe + tap-select');
assert(/data-save-snapshot/.test(html), 'Missing save snapshot card');
assert(/📷|camera-icon/.test(html), 'Missing camera save icon');
assert(/id="tickFeedback"/.test(html), 'Missing tick feedback element');
assert(/pointerdown/.test(html) && /pointermove/.test(html) && /pointerup/.test(html), 'Missing joystick pointer drag handlers');
assert(/joystickStepThreshold/.test(html), 'Missing joystick drag step threshold');
assert(/id="thresholdSheet"/.test(html), 'Missing combined threshold/snapshot sheet');
assert(/id="pageOne"/.test(html), 'Missing Page 1 surface');
assert(/id="pageTwo"/.test(html), 'Missing Page 2 surface');
assert(!html.includes('Hózárás'), 'Old render mode copy must not appear');
assert(!html.includes('Hőtérkép'), 'Old render mode copy must not appear');
assert(!html.includes('Kategória scope'), 'Old render mode copy must not appear');

console.log('Snapshot mode static checks passed');
