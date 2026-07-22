#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const html = fs.readFileSync(
  path.join(__dirname, 'pulse_engine_panel_mockup.html'),
  'utf8',
);

const groups = {
  budget: ['HF-001', 'HF-002', 'HF-003', 'HF-004', 'HF-012', 'HF-013', 'HF-014', 'HF-015', 'HF-020'],
  cashflow: ['HF-005', 'HF-006', 'HF-007', 'HF-008', 'HF-009', 'HF-010', 'HF-011'],
  'data-quality': ['HF-021'],
};
const sectionNames = ['manual', 'forecasts', 'triggers', 'story', 'tuning'];
const sharedIds = ['HF-016', 'HF-017', 'HF-018', 'HF-019'];

function panelFor(group) {
  const marker = `data-group-panel="${group}"`;
  const markerIndex = html.indexOf(marker);
  assert.notEqual(markerIndex, -1, `missing group panel: ${group}`);
  const start = html.lastIndexOf('<section', markerIndex);
  const nextPanel = html.indexOf('<section class="group-panel', markerIndex + marker.length);
  const end = nextPanel === -1 ? html.indexOf('<p class="footer-note"', markerIndex) : nextPanel;
  assert.notEqual(end, -1, `missing end marker for group: ${group}`);
  return html.slice(start, end);
}

assert.equal((html.match(/data-group-rail=/g) || []).length, 3, 'exactly three rail buttons are required');
assert.doesNotMatch(html, /data-tab-target="(?:manual|forecasts|triggers|stories|tuning)"/, 'old primary tab buttons must be removed');
assert.doesNotMatch(html, /data-tab-panel="(?:manual|forecasts|triggers|stories|tuning)"/, 'old global panels must be removed');

for (const [group, ids] of Object.entries(groups)) {
  const panel = panelFor(group);
  for (const section of sectionNames) {
    assert.match(panel, new RegExp(`data-dossier-section="${section}"`), `${group} misses ${section}`);
  }
  for (const id of ids) {
    assert.equal(
      (html.match(new RegExp(`data-hf-id="${id}"`, 'g')) || []).length,
      1,
      `${id} must have exactly one display-group owner`,
    );
    assert.match(panel, new RegExp(`data-hf-id="${id}"`), `${id} must belong to ${group}`);
  }
  assert.match(panel, /data-shared-engine-trace/, `${group} misses shared engine trace`);
  for (const id of sharedIds) {
    assert.match(panel, new RegExp(`data-shared-hf-id="${id}"`), `${group} misses ${id}`);
  }
}

assert.match(html, /data-hf-id="HF-008"[\s\S]*?deferred[\s\S]*?not active/, 'HF-008 must remain deferred');
assert.match(html, /data-source-domain="fixed_load"/, 'fixed_load provenance must remain visible');
assert.match(html, /data-source-domain="behavior_shift"/, 'behavior_shift provenance must remain visible');
assert.match(html, /data-source-domain="engine"/, 'engine provenance must remain visible');
assert.match(html, /function selectGroup\(group, shouldScroll = true\)/, 'group selector must exist');
assert.match(html, /ArrowRight/, 'group rail needs ArrowRight keyboard navigation');
assert.match(html, /ArrowLeft/, 'group rail needs ArrowLeft keyboard navigation');
assert.match(html, /data-group-summary="budget"/, 'budget summary must select its group');
assert.match(html, /data-group-summary="cashflow"/, 'cashflow summary must select its group');
assert.match(html, /data-group-summary="data-quality"/, 'data summary must select its group');

console.log('pulse_engine_panel_group_rail_test: PASS');
