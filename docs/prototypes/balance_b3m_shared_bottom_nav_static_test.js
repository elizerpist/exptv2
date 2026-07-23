#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..');
const layoutPath = path.join(root, 'balance_latest_layout.html');
const colorLabPath = path.join(__dirname, 'color_lab.html');
const html = fs.readFileSync(layoutPath, 'utf8');
const colorLab = fs.readFileSync(colorLabPath, 'utf8');

const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((match) => match[1]);
assert.equal(scripts.length, 1, 'the B3M prototype must keep one inspectable inline renderer');
for (const script of scripts) new Function(script);

const b3mSourceNav = colorLab.match(/<nav class="bottom-nav common-header-bottom-nav" data-common-header-bottom-nav data-nav-style="legacy-inline-fab"[\s\S]*?<\/nav>/)?.[0];
assert.ok(b3mSourceNav, 'the B3M source must retain its full-width common-header nav');
assert.match(b3mSourceNav, /data-nav-destination="dashboard"/, 'the B3M source nav must retain its dashboard action');
assert.match(b3mSourceNav, /data-common-header-inline-fab/, 'the B3M source nav must retain its inline center FAB');
assert.match(b3mSourceNav, /data-nav-destination="settings"/, 'the B3M source nav must retain its settings action');

const prepareTodayRenderer = html.match(/function prepareTodayRedesignScreen\(column, card\) \{[\s\S]*?(?=\n\s*function createTodayTimeScopeDrawer)/)?.[0];
assert.ok(prepareTodayRenderer, 'the B3M-A preparation helper must remain inspectable');
assert.match(prepareTodayRenderer, /const sourceBottomNav = screen\.querySelector\('\[data-common-header-bottom-nav\]'\)\?\.cloneNode\(true\) \|\| null;/, 'B3M-A must clone the original B3M navigation before replacing its screen DOM');
assert.match(prepareTodayRenderer, /return \{ doc, screen, sourceBrand, sourceBottomNav \};/, 'the cloned B3M nav must reach the B3M-A renderer');

const todayRenderer = html.match(/function populateTodayRedesignScreen\([\s\S]*?(?=\n\s*function installPulseForecastGalleryStyles)/)?.[0];
assert.ok(todayRenderer, 'the B3M-A renderer must remain inspectable');
assert.match(todayRenderer, /const \{ doc, screen, sourceBrand, sourceBottomNav \} = prepareTodayRedesignScreen\(column, card\);/, 'B3M-A must receive the B3M nav clone');
assert.match(todayRenderer, /if \(!sourceBottomNav\) throw new Error\('Today redesign requires the B3M bottom navigation'\);/, 'B3M-A must fail visibly instead of falling back to a different nav');
assert.match(todayRenderer, /sourceBottomNav\.setAttribute\('data-b3m-shared-bottom-nav', 'true'\);/, 'the cloned nav must identify itself as the B3M shared navigation');
assert.match(todayRenderer, /layout\.append\(scrollViewport, topbar, heroOverlay, budgetPill, sourceBottomNav\);/, 'B3M-A must mount the shared B3M nav in the same fixed layout layer');
assert.doesNotMatch(todayRenderer, /stage2-redesign-bottom-nav|stage2-redesign-nav-item|stage2-redesign-nav-fab/, 'B3M-A must not build the retired five-item island nav');
assert.doesNotMatch(html, /stage2-redesign-bottom-nav|stage2-redesign-nav-item|stage2-redesign-nav-fab/, 'the retired island nav CSS and renderer must be removed rather than hidden');

assert.match(
  html,
  /\[data-exact-b3m-gallery="true"\]\s+\[data-common-header-static-preview="strict-mother-child"\]\s+\[data-common-header-inline-fab\]\s*\{[\s\S]*?background:\s*linear-gradient\(140deg,\s*#6065f5 0%,\s*#8c5cef 52%,\s*#f25cbf 100%\);[\s\S]*?\}/,
  'only the B3M navigation FAB must adopt the retired B3M-A purple-pink gradient',
);

console.log('B3M shared bottom navigation static contract passed');
