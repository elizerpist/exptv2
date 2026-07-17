# Portal Message Morph Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the standalone test portal into a reusable Balance/message relay with an adjacent trigger, four reversible content morphs, and fully tunable scrollable controls.

**Architecture:** Keep the accepted portal background and touch engine isolated. Add a small UMD pure module for morph schemas, settings normalization, timing, state alternation, and deterministic content keyframes; keep DOM playback and controls wiring in the existing HTML runtime. Two persistent foreground panels animate through Web Animations and use exact CSS endpoint states as a fallback.

**Tech Stack:** HTML, CSS, browser JavaScript, Web Animations API, CommonJS-compatible UMD helpers, Node `assert` regression tests.

## Global Constraints

- Implement only the standalone D-row test portal in `docs/prototypes/color_lab.html`; Flutter code is out of scope.
- Preserve the existing portal energy renderer, A/B coloring, canvas lifecycle, touch bloom, trail, ripple, release fade, and both opacity controls.
- The trigger must remain outside the `data-mind-portal-drag-surface="true"` header.
- The control panel must remain phone-width and internally scrollable.
- Follow RED → GREEN for every task and do not run a local Flutter build.
- Execute inline; the user explicitly declined subagents for this prototype work.

---

## File map

- Create `docs/prototypes/color_lab_portal_message.js`: pure schemas, normalization, overlap timing, state alternation, and deterministic keyframe descriptors.
- Create `docs/prototypes/color_lab_portal_message_test.js`: Node unit coverage for the pure module.
- Modify `docs/prototypes/color_lab.html`: relay markup, layout, four-mode controls, WAAPI controller, accessible state, reversal, and fallback.
- Modify `docs/prototypes/color_lab_static_test.js`: DOM/CSS/runtime regression assertions and preservation contracts.
- Modify `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`: `COLOR-LAB-319`–`323` evidence and honest status.

### Task 1: Pure message-morph contract

**Files:**

- Create: `docs/prototypes/color_lab_portal_message_test.js`
- Create: `docs/prototypes/color_lab_portal_message.js`

**Interfaces:**

- Produces: global/CommonJS `PortalMessageMorph` with `modeOrder`, `modeLabels`, `modeControls`, `controlsForMode(mode)`, `createModeSettings(mode)`, `normalizeValue(meta, value)`, `transitionOffsets(overlap)`, `oppositeState(state)`, and `buildTransition(mode, settings, targetState, reducedMotion)`.
- Consumes: no DOM and no portal-energy APIs.

- [ ] **Step 1: Write the failing pure-module test**

Create `docs/prototypes/color_lab_portal_message_test.js` with assertions for exact mode order, labels, schemas/defaults, clamping, overlap endpoints, repeated state alternation, four distinct descriptors, content-only properties, direction mirroring, and reduced-motion output:

```js
const assert = require('assert');
const morph = require('./color_lab_portal_message.js');

assert.deepStrictEqual(morph.modeOrder, [
  'diffuse-focus',
  'portal-aperture',
  'energy-sweep',
  'spectral-echo',
]);
assert.deepStrictEqual(morph.modeOrder.map((mode) => morph.modeLabels[mode]), [
  'Diffúz fókusz',
  'Portal rekesz',
  'Energia-söprés',
  'Spektrális visszhang',
]);

for (const mode of morph.modeOrder) {
  const controls = morph.controlsForMode(mode);
  const settings = morph.createModeSettings(mode);
  assert(controls.length >= 7);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(morph.normalizeValue(meta, meta.min - 1000), meta.min);
    assert.strictEqual(morph.normalizeValue(meta, meta.max + 1000), meta.max);
  });
}

assert.deepStrictEqual(morph.transitionOffsets(0), { outgoingEnd: 0.5, incomingStart: 0.5 });
assert.deepStrictEqual(morph.transitionOffsets(100), { outgoingEnd: 1, incomingStart: 0 });
let state = 'balance';
for (let index = 0; index < 8; index += 1) state = morph.oppositeState(state);
assert.strictEqual(state, 'balance');

const signatures = new Set();
for (const mode of morph.modeOrder) {
  const settings = morph.createModeSettings(mode);
  const forward = morph.buildTransition(mode, settings, 'message', false);
  const backward = morph.buildTransition(mode, settings, 'balance', false);
  assert(forward.duration >= 300 && forward.duration <= 2400);
  assert.strictEqual(forward.outgoing[0].opacity, 1);
  assert.strictEqual(forward.incoming.at(-1).opacity, 1);
  assert.strictEqual(backward.direction, -1);
  const serialized = JSON.stringify(forward);
  assert(!/background|canvas|touch|trail/i.test(serialized));
  signatures.add(JSON.stringify(forward.outgoing));
}
assert.strictEqual(signatures.size, 4);

const reduced = morph.buildTransition(
  'spectral-echo',
  morph.createModeSettings('spectral-echo'),
  'message',
  true,
);
assert.strictEqual(reduced.duration, 160);
assert.deepStrictEqual(Object.keys(reduced.outgoing[1]).sort(), ['offset', 'opacity']);

console.log('Portal message morph checks passed');
```

- [ ] **Step 2: Run the test and witness RED**

Run:

```bash
node docs/prototypes/color_lab_portal_message_test.js
```

Expected: FAIL with `Cannot find module './color_lab_portal_message.js'`.

- [ ] **Step 3: Implement the pure UMD module**

Create `docs/prototypes/color_lab_portal_message.js` with frozen per-mode schemas matching the approved spec. Use this public structure:

```js
(function attachPortalMessageMorph(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageMorph = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageMorph() {
  'use strict';

  const modeOrder = Object.freeze([
    'diffuse-focus',
    'portal-aperture',
    'energy-sweep',
    'spectral-echo',
  ]);
  const modeLabels = Object.freeze({
    'diffuse-focus': 'Diffúz fókusz',
    'portal-aperture': 'Portal rekesz',
    'energy-sweep': 'Energia-söprés',
    'spectral-echo': 'Spektrális visszhang',
  });

  // modeControls contains the exact min/max/step/default values from the design spec.
  // normalizeValue clamps and step-snaps without reading DOM state.
  // transitionOffsets uses segment = 1 / (2 - overlap / 100).
  // buildTransition returns { mode, targetState, direction, duration,
  //   easing, outgoing, incoming, accent } and emits only foreground
  //   opacity/filter/transform/clipPath/textShadow keyframes.

  return Object.freeze({
    modeOrder,
    modeLabels,
    modeControls,
    controlsForMode,
    createModeSettings,
    normalizeValue,
    transitionOffsets,
    oppositeState,
    buildTransition,
  });
});
```

Use opacity/blur/scale/drift frames for `diffuse-focus`, circle clip-path frames for `portal-aperture`, left-to-right polygon clip frames for `energy-sweep`, and bounded generated `textShadow` echoes for `spectral-echo`. Returning to Balance mirrors directional transforms while preserving the same selected values.

- [ ] **Step 4: Run the pure test and witness GREEN**

Run:

```bash
node docs/prototypes/color_lab_portal_message_test.js
node --check docs/prototypes/color_lab_portal_message.js
```

Expected: `Portal message morph checks passed` and both commands exit 0.

### Task 2: Relay layout, content endpoints, and separate controls shell

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**

- Consumes: the approved B1 copy and `PortalMessageMorph.modeOrder` labels.
- Produces: `data-portal-message-row`, `data-portal-message-state`, `data-portal-message-content`, `data-portal-message-trigger`, `data-portal-message-mode-select`, and the active controls shell.

- [ ] **Step 1: Replace the obsolete instructional-copy assertion with failing relay assertions**

In `docs/prototypes/color_lab_static_test.js`, require:

```js
assert(
  /<div class="mind-portal-test-row" data-portal-message-row>[\s\S]*?<header[^>]*data-portal-message-state="balance"[\s\S]*?data-portal-message-content="balance"[^>]*aria-hidden="false"[\s\S]*?Balance[\s\S]*?-372 047 472 Ft[\s\S]*?data-portal-message-content="message"[^>]*aria-hidden="true"[\s\S]*?Portal üzenet[\s\S]*?Új pénzügyi jel érkezett[\s\S]*?<\/header>[\s\S]*?<button[^>]*data-portal-message-trigger[^>]*aria-pressed="false"/.test(html),
  'The test portal must expose matched Balance/message panels and an adjacent trigger outside the drag header',
);
assert(
  /\.mind-portal-test-row\s*\{[\s\S]*?width:\s*min\(360px,\s*calc\(100% - 40px\)\);[\s\S]*?display:\s*flex;/.test(html) &&
    /\.mind-portal-message-trigger\s*\{[\s\S]*?width:\s*44px;[\s\S]*?height:\s*44px;[\s\S]*?touch-action:\s*manipulation;/.test(html),
  'The adjacent trigger row must remain phone-width and outside the touch-action:none surface',
);
assert(
  html.includes('data-portal-message-panel') &&
    html.includes('data-portal-message-mode-select') &&
    ['diffuse-focus', 'portal-aperture', 'energy-sweep', 'spectral-echo'].every((mode) =>
      html.includes(`<option value="${mode}"`)),
  'The separate portal-message controls panel must expose all approved modes',
);
```

Keep the existing touch function and touch-CSS hashes unchanged.

- [ ] **Step 2: Run the static test and witness RED**

Run:

```bash
node docs/prototypes/color_lab_static_test.js
```

Expected: FAIL at the new relay-content assertion because the old instructional copy still exists.

- [ ] **Step 3: Add the relay markup and CSS endpoints**

In `docs/prototypes/color_lab.html`:

```html
<div class="mind-portal-test-row" data-portal-message-row>
  <header class="common-header-card mind-portal-test-header"
      data-mind-portal-drag-surface="true"
      data-mind-portal-mode="static"
      data-portal-message-state="balance"
      aria-label="Portal touch és üzenet teszt header">
    <canvas class="common-mind-portal-idle-canvas" data-mind-portal-idle-canvas aria-hidden="true"></canvas>
    <div class="mind-portal-content-viewport" data-portal-message-viewport>
      <div class="mind-portal-content-panel" data-portal-message-content="balance" aria-hidden="false">
        <span class="mind-portal-content-label">Balance</span>
        <strong class="mind-portal-balance-value">-372 047 472 Ft</strong>
      </div>
      <div class="mind-portal-content-panel" data-portal-message-content="message" aria-hidden="true">
        <span class="mind-portal-content-label">Portal üzenet</span>
        <strong class="mind-portal-message-value">Új pénzügyi jel érkezett</strong>
        <small>Tesztüzenet · koppints a visszatéréshez</small>
      </div>
      <span class="mind-portal-message-accent" data-portal-message-accent aria-hidden="true"></span>
    </div>
  </header>
  <button class="mind-portal-message-trigger" type="button"
      data-portal-message-trigger aria-pressed="false"
      aria-label="Tesztüzenet megjelenítése"><span aria-hidden="true">✦</span></button>
</div>
```

Add scoped CSS for the 360 px row, flexible header, 44 px satellite, content clipping, matched panels, exact Balance/message endpoint selectors, readable typography, and button pressed state. Add the new panel shell below the existing energy panel using the existing select/head/scroll row visual language.

Load the pure module after the energy module:

```html
<script src="./color_lab_portal_energy.js"></script>
<script src="./color_lab_portal_message.js"></script>
```

- [ ] **Step 4: Run the static test and witness GREEN**

Run:

```bash
node docs/prototypes/color_lab_static_test.js
```

Expected: `Color lab static checks passed`.

### Task 3: Reversible WAAPI controller and maximum-detail controls

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**

- Consumes: `PortalMessageMorph` and the Task 2 data attributes.
- Produces: `initPortalMessageMorphLab()`, per-wrapper settings/state, active animation reversal, accessible commits, active-mode-only control rendering/reset, and reduced-motion/no-WAAPI behavior.

- [ ] **Step 1: Add failing runtime-contract assertions**

Extend `docs/prototypes/color_lab_static_test.js` to require the controller contract:

```js
assert(
  html.includes('function initPortalMessageMorphLab()') &&
    html.includes('function runPortalMessageMorph(wrap, targetState)') &&
    html.includes('function commitPortalMessageState(wrap, state, targetState)') &&
    html.includes('animation.reverse()') &&
    html.includes("window.matchMedia('(prefers-reduced-motion: reduce)')") &&
    html.includes("typeof outgoingPanel.animate !== 'function'") &&
    html.includes("header.dataset.portalMessageState = targetState") &&
    html.includes("trigger.setAttribute('aria-pressed', targetState === 'message' ? 'true' : 'false')"),
  'Portal message playback must toggle, reverse in flight, and commit accessible state with fallbacks',
);
assert(
  html.includes('function renderPortalMessageControls(wrap, mode)') &&
    html.includes('PortalMessageMorph.controlsForMode(mode)') &&
    html.includes('data-portal-message-control-range') &&
    html.includes('data-portal-message-control-number') &&
    html.includes('settingsByMode') &&
    html.includes('function resetPortalMessageMode(wrap)') &&
    html.includes('initPortalMessageMorphLab();'),
  'Message morph controls must render only the active schema with synchronized range/manual inputs and isolated reset',
);
```

- [ ] **Step 2: Run the static test and witness RED**

Run:

```bash
node docs/prototypes/color_lab_static_test.js
```

Expected: FAIL at the new playback/controller assertion.

- [ ] **Step 3: Implement state, playback, reversal, and controls**

Add a dedicated `WeakMap` state with current/target state, selected mode, settings per mode, active animations, an animation token, and reduced-motion media query.

Use this runtime structure:

```js
const portalMessageMorphStates = new WeakMap();

function runPortalMessageMorph(wrap, targetState) {
  const state = ensurePortalMessageMorphState(wrap);
  if (state.activeAnimations.length && targetState !== state.targetState) {
    state.targetState = targetState;
    updatePortalMessageTrigger(wrap, targetState);
    state.activeAnimations.forEach(({ animation }) => animation.reverse());
    return;
  }
  // Resolve source/target panels, build the pure descriptor, use WAAPI,
  // and commit only after both animations reach an endpoint.
}

function commitPortalMessageState(wrap, state, targetState) {
  const header = wrap.querySelector('.mind-portal-test-header');
  const trigger = wrap.querySelector('[data-portal-message-trigger]');
  header.dataset.portalMessageState = targetState;
  wrap.querySelectorAll('[data-portal-message-content]').forEach((panel) => {
    panel.setAttribute('aria-hidden', panel.dataset.portalMessageContent === targetState ? 'false' : 'true');
  });
  trigger.setAttribute('aria-pressed', targetState === 'message' ? 'true' : 'false');
  trigger.setAttribute('aria-label', targetState === 'message'
    ? 'Balance visszaállítása'
    : 'Tesztüzenet megjelenítése');
  state.currentState = targetState;
  state.targetState = targetState;
}
```

Use `PortalMessageMorph.buildTransition(...)`, `Element.animate`, and `Promise.all(animation.finished)` with a token guard. If a second press requests the opposite endpoint while active, call `animation.reverse()` on the existing pair. If reduced motion is active, request the 160 ms opacity-only descriptor. If WAAPI is missing, call the endpoint commit directly.

Generate active controls with the same numbered grid used by energy controls. Synchronize range and manual values through `PortalMessageMorph.normalizeValue`. Preserve `settingsByMode`, and have reset replace only `settingsByMode[state.activeMode]`. Give the message controls viewport the existing `.mind-portal-energy-controls-scroll` class so the accepted vertical gesture router also handles it without editing the protected touch functions.

- [ ] **Step 4: Run focused GREEN checks**

Run:

```bash
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_static_test.js
node --check docs/prototypes/color_lab_portal_message.js
```

Expected: both suites print their pass messages and syntax exits 0.

### Task 4: Integration evidence and honest checklist status

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`

**Interfaces:**

- Consumes: all Task 1–3 behavior and `COLOR-LAB-319`–`323` acceptance conditions.
- Produces: reproducible automated evidence and explicit remaining Android visual checks.

- [ ] **Step 1: Run full fresh verification**

Run:

```bash
set -e
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node docs/prototypes/color_lab_portal_message_test.js
node --check docs/prototypes/color_lab_static_test.js
node --check docs/prototypes/color_lab_portal_energy.js
node --check docs/prototypes/color_lab_portal_message.js
node <<'NODE'
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('docs/prototypes/color_lab.html', 'utf8');
const scripts = [...html.matchAll(new RegExp('<script\\b(?![^>]*\\bsrc=)[^>]*>([\\s\\S]*?)</script>', 'gi'))]
  .map((match) => match[1]);
scripts.forEach((code, index) => new vm.Script(code, { filename: `inline-${index + 1}.js` }));
console.log(`Inline scripts parse: ${scripts.length}`);
NODE
git diff --check
```

Expected: all three test suites pass, all JavaScript parses, and `git diff --check` emits no errors.

- [ ] **Step 2: Run HTTP source smoke**

Serve the worktree or reuse the existing local prototype server, then assert HTTP 200 and the message module/trigger/mode/control tokens:

```bash
node <<'NODE'
const http = require('node:http');
http.get('http://127.0.0.1:8765/docs/prototypes/color_lab.html', (res) => {
  let body = '';
  res.setEncoding('utf8');
  res.on('data', (chunk) => { body += chunk; });
  res.on('end', () => {
    const required = [
      'src="./color_lab_portal_message.js"',
      'data-portal-message-trigger',
      'data-portal-message-state="balance"',
      'Diffúz fókusz',
      'Portal rekesz',
      'Energia-söprés',
      'Spektrális visszhang',
      'data-portal-message-controls-scroll',
    ];
    if (res.statusCode !== 200 || required.some((token) => !body.includes(token))) process.exit(1);
    console.log('HTTP portal message source checks passed');
  });
}).on('error', () => process.exit(1));
NODE
```

Expected: `HTTP portal message source checks passed`.

- [ ] **Step 3: Update checklist evidence and status**

Append a `Portal message morph evidence — 2026-07-16` section. Record the witnessed RED/GREEN commands, pure/static/runtime/HTTP evidence, and protected touch/energy regressions. Change `COLOR-LAB-319`–`323` from `NOT DONE` to `PARTIAL`, not `DONE`, until Android screenshots and manual touch/rapid-reversal/control-scroll inspection exist.

- [ ] **Step 4: Re-run verification after documentation edits**

Repeat the full commands from Step 1 so the completion report is backed by fresh post-checklist evidence.
