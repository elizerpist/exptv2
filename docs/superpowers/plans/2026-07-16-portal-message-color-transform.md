# Portal Message Color Transform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an independently selectable white–light-pink–purple message-color field that can fully replace the standalone portal's financial background while a message is visible, including static and four reused dynamic A/B modes.

**Architecture:** A pure UMD model owns mode order, palette sampling, A/B window sampling, settings isolation, and reversible opacity descriptors. A second pure UMD renderer converts the selected static/dynamic A/B field into deterministic RGBA pixels by consuming `MindPortalEnergy` without touching its runtime state. The existing HTML controller owns one dedicated canvas, controls, lifecycle, common animation-group integration, and 180 ms settled-message previews.

**Tech Stack:** HTML, CSS, browser JavaScript, Canvas 2D, Web Animations API, CommonJS-compatible UMD modules, Node `assert` tests.

## Global Constraints

- Follow `docs/superpowers/specs/2026-07-16-portal-message-color-transform-design.md` exactly.
- HTML prototype only; do not edit Flutter code or run a Flutter build.
- Execute inline; do not use subagents.
- Preserve the accepted touch CSS/function hashes and all existing portal-energy, foreground-morph, and background-response behavior.
- Never write financial A/B colors, Money-flow ratio, base energy mode/settings/phase, touch variables, foreground settings, or background-response settings from the message-color controller.
- Exact mode order: `none`, `static`, `dual-tide`, `magnetic-membrane`, `breathing-lens`, `cellular-field`.
- Exact palette: `#fffdfd` at 0%, `#ffc4e4` at 50%, `#8b5cf6` at 100%.
- Palette defaults: center 50%, window 68%; window commits only on Enter, `change`, or blur and clamps to 10–100.
- Existing shared prototype files are intentionally dirty with user-owned work. Commit new isolated module/test files only; do not stage or commit the shared HTML, static test, checklist, or unrelated files without a later explicit integration decision.

---

### Task 1: Pure message-color model and reversible descriptor

**Files:**

- Create: `docs/prototypes/color_lab_portal_color.js`
- Create: `docs/prototypes/color_lab_portal_color_test.js`
- Read: `docs/prototypes/color_lab_portal_energy.js`

**Interfaces:**

- Produces global/CommonJS `PortalMessageColor`.
- Exports `modeOrder`, `modeLabels`, `dynamicModes`, `paletteStops`, `defaults`, `normalizeMode(mode)`, `normalizeCenter(value)`, `normalizeWindow(value)`, `samplePalette(percent)`, `sampleWindow(center, windowSize)`, `isDynamicMode(mode)`, `controlsForMode(mode)`, `createModeSettings(mode)`, `normalizeControlValue(meta, value)`, and `buildTransition(mode, targetState, windowOpacity, duration, reducedMotion)`.
- `sampleWindow` returns `{ center, windowSize, lower, upper, a, b }` with normalized numeric values and lowercase hex colors.
- `buildTransition` returns `{ mode, targetState, duration, easing, baseKeyframes, colorKeyframes, balanceRest, messageRest }`. Rest objects contain numeric `baseOpacity` and `colorOpacity`.

- [x] **Step 1: Write the failing model test**

Create `color_lab_portal_color_test.js` with concrete assertions:

```js
const assert = require('assert');
const color = require('./color_lab_portal_color.js');

assert.deepStrictEqual(color.modeOrder, [
  'none', 'static', 'dual-tide', 'magnetic-membrane',
  'breathing-lens', 'cellular-field',
]);
assert.deepStrictEqual(color.modeOrder.map((mode) => color.modeLabels[mode]), [
  'Semmi', 'Statikus portál A/B', 'Kettős árapály',
  'Mágneses membrán', 'Lélegző lencse', 'Celluláris mező',
]);
assert.deepStrictEqual(color.paletteStops, [
  { position: 0, color: '#fffdfd' },
  { position: 50, color: '#ffc4e4' },
  { position: 100, color: '#8b5cf6' },
]);
assert.strictEqual(color.samplePalette(0), '#fffdfd');
assert.strictEqual(color.samplePalette(25), '#ffe1f1');
assert.strictEqual(color.samplePalette(50), '#ffc4e4');
assert.strictEqual(color.samplePalette(75), '#c590ed');
assert.strictEqual(color.samplePalette(100), '#8b5cf6');
assert.deepStrictEqual(color.sampleWindow(50, 100), {
  center: 50, windowSize: 100, lower: 0, upper: 100,
  a: '#fffdfd', b: '#8b5cf6',
});
assert.strictEqual(color.normalizeCenter(-1), 0);
assert.strictEqual(color.normalizeCenter(101), 100);
assert.strictEqual(color.normalizeWindow(0), 10);
assert.strictEqual(color.normalizeWindow(101), 100);
assert.strictEqual(color.normalizeWindow(''), 68);
assert.strictEqual(color.normalizeMode('invalid'), 'none');
```

For every dynamic mode, assert that `controlsForMode` exactly equals `MindPortalEnergy.controlsForMode(mode)`, defaults match, and every bound clamps. Assert `none` and `static` expose zero dynamic controls.

Assert transition endpoints:

```js
const forward = color.buildTransition('dual-tide', 'message', 0.72, 900, false);
assert.deepStrictEqual(forward.baseKeyframes, [
  { opacity: 0.72, offset: 0 }, { opacity: 0, offset: 1 },
]);
assert.deepStrictEqual(forward.colorKeyframes, [
  { opacity: 0, offset: 0 }, { opacity: 0.72, offset: 1 },
]);
const backward = color.buildTransition('dual-tide', 'balance', 0.72, 900, false);
assert.deepStrictEqual(backward.baseKeyframes, forward.baseKeyframes.slice().reverse().map(
  (frame, index) => ({ ...frame, offset: index }),
));
assert.strictEqual(color.buildTransition('static', 'message', 1, 900, true).duration, 160);
assert.deepStrictEqual(
  color.buildTransition('none', 'message', 1, 900, false).colorKeyframes,
  [],
);
console.log('Portal message color checks passed');
```

- [x] **Step 2: Run the model test and witness RED**

Run:

```bash
node docs/prototypes/color_lab_portal_color_test.js
```

Expected: exit 1 with `MODULE_NOT_FOUND` for `color_lab_portal_color.js`.

- [x] **Step 3: Implement the pure UMD model**

The UMD wrapper must load `MindPortalEnergy` from CommonJS or the browser global:

```js
(function attachPortalMessageColor(root, factory) {
  const energy = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_energy.js')
    : root?.MindPortalEnergy;
  const api = factory(energy);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageColor = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageColor(energy) {
  'use strict';
  const modeOrder = Object.freeze([
    'none', 'static', 'dual-tide', 'magnetic-membrane',
    'breathing-lens', 'cellular-field',
  ]);
  const dynamicModes = Object.freeze(modeOrder.slice(2));
  const paletteStops = Object.freeze([
    Object.freeze({ position: 0, color: '#fffdfd' }),
    Object.freeze({ position: 50, color: '#ffc4e4' }),
    Object.freeze({ position: 100, color: '#8b5cf6' }),
  ]);
  const defaults = Object.freeze({ center: 50, windowSize: 68 });
  const modeLabels = Object.freeze({
    none: 'Semmi',
    static: 'Statikus portál A/B',
    'dual-tide': 'Kettős árapály',
    'magnetic-membrane': 'Mágneses membrán',
    'breathing-lens': 'Lélegző lencse',
    'cellular-field': 'Celluláris mező',
  });
  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
  const normalizeNumber = (value, fallback, min, max) => {
    const empty = value === null || value === undefined
      || (typeof value === 'string' && value.trim() === '');
    const numeric = empty ? fallback : Number(value);
    return Math.round(clamp(Number.isFinite(numeric) ? numeric : fallback, min, max));
  };
  const normalizeMode = (mode) => modeOrder.includes(mode) ? mode : 'none';
  const normalizeCenter = (value) => normalizeNumber(value, defaults.center, 0, 100);
  const normalizeWindow = (value) => normalizeNumber(value, defaults.windowSize, 10, 100);
  const normalizePercent = (value) => {
    const numeric = Number(value);
    return clamp(Number.isFinite(numeric) ? numeric : 0, 0, 100);
  };
  const hexChannels = (hex) => [1, 3, 5].map((index) => parseInt(hex.slice(index, index + 2), 16));
  const mixHex = (left, right, amount) => {
    const a = hexChannels(left);
    const b = hexChannels(right);
    const channel = (index) => Math.round(a[index] + ((b[index] - a[index]) * amount))
      .toString(16).padStart(2, '0');
    return `#${channel(0)}${channel(1)}${channel(2)}`;
  };
  const samplePalette = (value) => {
    const position = normalizePercent(value);
    return position <= 50
      ? mixHex('#fffdfd', '#ffc4e4', position / 50)
      : mixHex('#ffc4e4', '#8b5cf6', (position - 50) / 50);
  };
  const sampleWindow = (center, windowSize) => {
    const safeCenter = normalizeCenter(center);
    const safeWindow = normalizeWindow(windowSize);
    const lower = clamp(safeCenter - (safeWindow / 2), 0, 100);
    const upper = clamp(safeCenter + (safeWindow / 2), 0, 100);
    return {
      center: safeCenter, windowSize: safeWindow, lower, upper,
      a: samplePalette(lower), b: samplePalette(upper),
    };
  };
  const isDynamicMode = (mode) => dynamicModes.includes(mode);
  const controlsForMode = (mode) => isDynamicMode(mode)
    ? energy.controlsForMode(mode)
    : Object.freeze([]);
  const createModeSettings = (mode) => Object.fromEntries(
    controlsForMode(mode).map((meta) => [meta.key, meta.default]),
  );
  const normalizeControlValue = (meta, value) => {
    const empty = value === null || value === undefined
      || (typeof value === 'string' && value.trim() === '');
    const numeric = empty ? Number(meta.default) : Number(value);
    const fallback = Number(meta.default);
    const bounded = clamp(Number.isFinite(numeric) ? numeric : fallback, meta.min, meta.max);
    const snapped = meta.min + (Math.round((bounded - meta.min) / meta.step) * meta.step);
    const decimals = String(meta.step).includes('.') ? String(meta.step).split('.')[1].length : 0;
    return Number(snapped.toFixed(decimals));
  };
  const buildTransition = (mode, targetState, windowOpacity, duration, reducedMotion) => {
    const activeMode = normalizeMode(mode);
    const target = targetState === 'balance' ? 'balance' : 'message';
    const alpha = clamp(Number(windowOpacity) || 0, 0, 1);
    const balanceRest = { baseOpacity: alpha, colorOpacity: 0 };
    const messageRest = activeMode === 'none'
      ? { ...balanceRest }
      : { baseOpacity: 0, colorOpacity: alpha };
    if (activeMode === 'none') {
      return {
        mode: 'none', targetState: target, duration: 0, easing: 'linear',
        baseKeyframes: [], colorKeyframes: [], balanceRest, messageRest,
      };
    }
    const forward = target === 'message';
    return {
      mode: activeMode,
      targetState: target,
      duration: reducedMotion ? 160 : clamp(Math.round(Number(duration) || 900), 0, 4000),
      easing: reducedMotion ? 'linear' : 'cubic-bezier(.2,.82,.2,1)',
      baseKeyframes: forward
        ? [{ opacity: alpha, offset: 0 }, { opacity: 0, offset: 1 }]
        : [{ opacity: 0, offset: 0 }, { opacity: alpha, offset: 1 }],
      colorKeyframes: forward
        ? [{ opacity: 0, offset: 0 }, { opacity: alpha, offset: 1 }]
        : [{ opacity: alpha, offset: 0 }, { opacity: 0, offset: 1 }],
      balanceRest,
      messageRest,
    };
  };
  return Object.freeze({
    modeOrder, modeLabels, dynamicModes, paletteStops, defaults,
    normalizeMode, normalizeCenter, normalizeWindow, samplePalette,
    sampleWindow, isDynamicMode, controlsForMode, createModeSettings,
    normalizeControlValue, buildTransition,
  });
});
```

Use integer-rounded piecewise RGB interpolation. Normalize numeric input only at explicit API calls; do not model temporary empty editing state in this pure module.

- [x] **Step 4: Run model verification and witness GREEN**

Run:

```bash
node docs/prototypes/color_lab_portal_color_test.js
node --check docs/prototypes/color_lab_portal_color.js
```

Expected: `Portal message color checks passed`, then exit 0.

- [x] **Step 5: Commit only the isolated model files**

```bash
git add docs/prototypes/color_lab_portal_color.js \
  docs/prototypes/color_lab_portal_color_test.js
git diff --cached --check
git commit -m "feat: add portal message color model"
```

---

### Task 2: Pure portal-color pixel renderer

**Files:**

- Create: `docs/prototypes/color_lab_portal_color_renderer.js`
- Create: `docs/prototypes/color_lab_portal_color_renderer_test.js`
- Read: `docs/prototypes/color_lab_portal_energy.js`
- Consume: `docs/prototypes/color_lab_portal_color.js`

**Interfaces:**

- Produces global/CommonJS `PortalMessageColorRenderer`.
- Exports `renderFrame({ mode, width, height, phase, settings, colorA, colorB })`.
- Returns `{ width, height, data }`, where `data` is a `Uint8ClampedArray` of opaque RGBA pixels, or `null` for `none`/invalid modes.
- `static` uses `MindPortalEnergy.sampleField('static', ...)`; dynamic modes use the exact existing `sampleField` and `sampleColor` algorithms.

- [x] **Step 1: Write the failing renderer test**

Create assertions that render `9×5` frames for `static` and all four dynamic modes:

```js
const assert = require('assert');
const color = require('./color_lab_portal_color.js');
const renderer = require('./color_lab_portal_color_renderer.js');

const palette = color.sampleWindow(50, 68);
for (const mode of color.modeOrder.slice(1)) {
  const settings = color.createModeSettings(mode);
  const frame = renderer.renderFrame({
    mode, width: 9, height: 5, phase: 1.25,
    settings, colorA: palette.a, colorB: palette.b,
  });
  assert.strictEqual(frame.width, 9);
  assert.strictEqual(frame.height, 5);
  assert.strictEqual(frame.data.length, 9 * 5 * 4);
  for (let index = 3; index < frame.data.length; index += 4) {
    assert.strictEqual(frame.data[index], 255);
  }
  const repeated = renderer.renderFrame({
    mode, width: 9, height: 5, phase: 1.25,
    settings, colorA: palette.a, colorB: palette.b,
  });
  assert.deepStrictEqual([...repeated.data], [...frame.data]);
}
assert.strictEqual(renderer.renderFrame({ mode: 'none' }), null);
assert.strictEqual(renderer.renderFrame({ mode: 'invalid' }), null);
```

Also assert static output is unchanged by phase, each dynamic default changes between phase `0` and `2`, and a dynamic mode with `strength: 0` produces the same frame as static at identical dimensions/colors.

- [x] **Step 2: Run renderer test and witness RED**

Run `node docs/prototypes/color_lab_portal_color_renderer_test.js`.

Expected: exit 1 with `MODULE_NOT_FOUND` for the renderer module.

- [x] **Step 3: Implement the renderer**

Use this exact render loop structure:

```js
const sample = energy.sampleField(mode, nx, ny, Number(phase) || 0, settings);
const pixel = energy.sampleColor(rgbA, rgbB, sample);
const offset = ((y * safeWidth) + x) * 4;
data[offset] = pixel.r;
data[offset + 1] = pixel.g;
data[offset + 2] = pixel.b;
data[offset + 3] = 255;
```

Clamp dimensions to integers `1–2048`, parse only six-digit hex colors, and return `null` before allocating for unsupported modes. Do not reference DOM, canvas contexts, financial attributes, Money-flow, touch, or controller state.

- [x] **Step 4: Run renderer and upstream verification**

```bash
node docs/prototypes/color_lab_portal_color_renderer_test.js
node docs/prototypes/color_lab_portal_color_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node --check docs/prototypes/color_lab_portal_color_renderer.js
```

Expected: all three suites print their pass messages and exit 0.

- [x] **Step 5: Commit only isolated renderer files**

```bash
git add docs/prototypes/color_lab_portal_color_renderer.js \
  docs/prototypes/color_lab_portal_color_renderer_test.js
git diff --cached --check
git commit -m "feat: add portal message color renderer"
```

---

### Task 3: Message-color layer, selector, palette controls, and mobile shell

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js:2160-2260`
- Modify: `docs/prototypes/color_lab.html:505-900`
- Modify: `docs/prototypes/color_lab.html:10345-10475`
- Modify: `docs/prototypes/color_lab.html:10625-10632`

**Interfaces:**

- Adds `data-portal-message-color-canvas`, `data-portal-message-color-panel`, `data-portal-message-color-mode-select`, `data-portal-message-color-palette`, `data-portal-message-color-center`, `data-portal-message-color-window`, `data-portal-message-color-controls`, and `data-portal-message-color-controls-scroll`.
- Loads `color_lab_portal_color.js` and `color_lab_portal_color_renderer.js` after `color_lab_portal_background.js` and before the inline controller.

- [x] **Step 1: Add failing static layer/panel assertions**

Assert all of the following in `color_lab_static_test.js`:

```js
assert(
  headerBlock.indexOf('data-mind-portal-idle-canvas') <
    headerBlock.indexOf('data-portal-message-color-canvas') &&
  headerBlock.indexOf('data-portal-message-color-canvas') <
    headerBlock.indexOf('data-portal-background-response'),
  'Message color canvas must paint between the financial field and response overlay',
);
assert(/@property --mind-portal-base-visual-opacity[\s\S]*?syntax:\s*"<number>"/.test(html));
assert(/\.mind-portal-message-color-canvas\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?z-index:\s*0;[\s\S]*?pointer-events:\s*none;[\s\S]*?mix-blend-mode:\s*normal;[\s\S]*?opacity:\s*0;/.test(html));
```

Extract the new panel and assert exact option order, `none` selected, exact scale gradient, center `value="50"`, window `min="10" max="100" value="68"`, initial hidden controls, placement after `data-portal-background-panel`, shared phone width, and inclusion of the new viewport in the scrollable controls CSS.

Assert module load order:

```js
assert(
  html.indexOf('color_lab_portal_background.js') < html.indexOf('color_lab_portal_color.js') &&
  html.indexOf('color_lab_portal_color.js') < html.indexOf('color_lab_portal_color_renderer.js'),
);
```

- [x] **Step 2: Run static test and witness RED**

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: failure at the missing message-color canvas/panel contract.

- [x] **Step 3: Add the layer and compact panel**

Insert immediately after the idle canvas:

```html
<canvas class="mind-portal-message-color-canvas"
  data-portal-message-color-canvas aria-hidden="true"></canvas>
```

Insert `Portal üzenetszín` after the background-response panel. The palette control contains the 0–100 range, A/B swatches/readout, and a number input `min="10" max="100" step="1" value="68"`. Dynamic controls reuse `.mind-portal-energy-controls`, numbered rows, and `.mind-portal-energy-controls-scroll`.

Update panel material/width/title/reset selector groups to include the new panel. Add the registered base visual-opacity property and change the test-header base pseudo-element to:

```css
opacity: var(--mind-portal-base-visual-opacity, var(--mind-portal-window-opacity, 1));
```

Give the message canvas a CSS fallback background through `--portal-message-color-gradient` and normal blend mode.

- [x] **Step 4: Run markup/style verification and witness GREEN**

```bash
node docs/prototypes/color_lab_static_test.js
node --check docs/prototypes/color_lab_portal_color.js
node --check docs/prototypes/color_lab_portal_color_renderer.js
```

Expected: `Color lab static checks passed` and exit 0.

- [x] **Step 5: Record the shared-file checkpoint without committing**

Run `git diff --check` and inspect only the new layer/panel hunks with:

```bash
git diff -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
```

Do not stage these already-dirty shared files.

---

### Task 4: Isolated message-color state, renderer lifecycle, and controls

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js:2190-2270,4950-4990`
- Modify: `docs/prototypes/color_lab.html:10856-10890`
- Modify: `docs/prototypes/color_lab.html:12765-12810`
- Modify: `docs/prototypes/color_lab.html:13095-13315`
- Modify: `docs/prototypes/color_lab.html:13456-13545`

**Interfaces:**

- Adds `renderPortalMessageColorControls`, `setPortalMessageColorMode`, `resetPortalMessageColorMode`, `drawPortalMessageColorFrame`, `initPortalMessageColorCanvas`, `previewPortalMessageColor`, `clearPortalMessageColorCanvas`, and `syncPortalMessageColorEndpoint`.
- Extends the existing WeakMap state with the exact fields from the approved spec.

- [x] **Step 1: Add failing state/control/lifecycle assertions**

Require source contracts for:

```js
messageColorMode: 'none'
messageColorCenter: PortalMessageColor.defaults.center
messageColorWindow: PortalMessageColor.defaults.windowSize
messageColorSettingsByMode
messageColorPhaseByMode
messageColorFrame: 0
messageColorPreviewAnimation: null
```

Assert active-mode rendering rules, `PortalMessageColor.sampleWindow(...)`, A/B swatch updates, dynamic `PortalMessageColor.controlsForMode(mode)` rows, isolated reset, range `input` preview, and no `input` listener on the window number. Require Enter/`change`/blur commit and last-valid restoration.

Require `PortalMessageColorRenderer.renderFrame(...)`, `MindPortalEnergy.advancePhase(...)`, requestAnimationFrame lifecycle, IntersectionObserver visibility gating, reduced-motion phase freeze, CSS static fallback, and scroll-router inclusion:

```js
document.querySelectorAll('[data-mind-portal-energy-controls-scroll], [data-portal-message-controls-scroll], [data-portal-background-controls-scroll], [data-portal-message-color-controls-scroll]')
```

Extract the message-color runtime block and assert it contains neither `setMindPortalEnergyMode(` nor `ensureMindPortalEnergyState(` nor financial/touch style writes.

- [x] **Step 2: Run static test and witness RED**

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: failure at the missing message-color state/controller assertion.

- [x] **Step 3: Implement state and active-mode controls**

Initialize dynamic settings/phases with:

```js
const messageColorSettingsByMode = Object.fromEntries(
  PortalMessageColor.dynamicModes.map((mode) => [
    mode, PortalMessageColor.createModeSettings(mode),
  ]),
);
const messageColorPhaseByMode = Object.fromEntries(
  PortalMessageColor.dynamicModes.map((mode) => [mode, 0]),
);
```

`none` hides palette/dynamic controls. `static` shows only the palette. Dynamic modes show the palette plus generated numbered rows. Static reset restores center/window; dynamic reset restores only `messageColorSettingsByMode[activeMode]`.

Bind the window number using the existing deferred-number behavior: allow an empty value while typing, retain `data-last-committed-window`, commit only on Enter/`change`/blur, and normalize through `PortalMessageColor.normalizeWindow`.

- [x] **Step 4: Implement the dedicated canvas lifecycle**

For each visible frame:

1. Skip and clear for `none`, Balance endpoint, disconnected/offscreen header, or unavailable canvas.
2. Compute palette through `sampleWindow` and write `--portal-message-color-gradient` for the CSS fallback.
3. For dynamic modes, advance only that mode's stored phase unless reduced motion is active.
4. Respect the dynamic mode's `renderScale` and `frameMs` controls.
5. Call `PortalMessageColorRenderer.renderFrame`, copy the returned bytes into `ImageData`, and `putImageData`.
6. Never set the base energy mode, financial A/B variables, Money-flow attributes, or touch variables.
7. Replace the base renderer's final direct opacity write with a helper that returns zero while `data-portal-message-color-visible="true"` and the existing window opacity otherwise. A running Web Animation still owns intermediate transition opacity.

For `static`, draw once after a palette/mode/size change and stop scheduling pixel updates until another invalidation.

- [x] **Step 5: Integrate the existing window-opacity control**

After writing `--mind-portal-window-opacity`, call:

```js
syncPortalMessageColorEndpoint(wrap, boundedValue / 100);
retargetPortalMessageColorOpacity(wrap, boundedValue / 100);
```

The first helper updates settled Balance/message sources. The second uses `animation.effect.setKeyframes(...)` on running message-color opacity roles while preserving each animation's `currentTime`, so changing window opacity cannot reset transition progress.

- [x] **Step 6: Run focused lifecycle verification**

```bash
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_color_test.js
node docs/prototypes/color_lab_portal_color_renderer_test.js
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: all pass messages and exit 0.

- [x] **Step 7: Record the shared-file checkpoint without committing**

Run `git diff --check`; do not stage shared dirty files.

---

### Task 5: Common reversal group, endpoint commit, live preview, and fallbacks

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js:2190-2290`
- Modify: `docs/prototypes/color_lab.html:12800-13090`

**Interfaces:**

- Adds `buildPortalMessageColorDescriptor`, `configurePortalMessageColorField`, `applyPortalMessageColorRestState`, `cancelPortalMessageColorPreview`, `retargetPortalMessageColorOpacity`, and message-color roles in `activeAnimations`.

- [x] **Step 1: Add failing transition/reversal/fallback assertions**

Assert `runPortalMessageMorph` builds the color descriptor with the foreground duration:

```js
PortalMessageColor.buildTransition(
  state.messageColorMode,
  targetState,
  getMindPortalWindowOpacity(header),
  descriptor.duration,
  state.reducedMotionQuery?.matches === true,
)
```

Require these common animation roles when mode is not `none`:

- `message-color-base` animating the registered header opacity property;
- `message-color-idle-canvas` when the base idle canvas exists;
- `message-color-canvas` animating the dedicated canvas.

Assert they are pushed into the same local `activeAnimations` array before assignment to `state.activeAnimations`, so the existing `animation.reverse()` loop covers them.

Require endpoint commit behavior:

- Balance or `none`: base visual opacity equals current window opacity, dedicated canvas opacity is zero, visible flag false;
- settled message with active color mode: base visual opacity zero, base idle canvas opacity zero, dedicated canvas opacity equals current window opacity, visible flag true.

Require no-WAAPI direct endpoint commit, 160 ms reduced motion, CSS-gradient fallback when `getContext` is unavailable, and cancellation of live preview before trigger playback.

- [x] **Step 2: Run static test and witness RED**

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: failure at the missing common animation-group role or endpoint contract.

- [x] **Step 3: Add message-color animations to the common group**

Build the pure descriptor after the foreground descriptor. Configure/render the target portal field before starting animations. Convert base frames for the header custom property exactly as follows, while the base idle canvas consumes the original opacity frames and the message-color canvas consumes `colorKeyframes`:

```js
const headerBaseFrames = colorDescriptor.baseKeyframes.map(({ opacity, offset }) => ({
  '--mind-portal-base-visual-opacity': String(opacity),
  offset,
}));
```

Push header/base-canvas/color-canvas Web Animations with the descriptor's keyframes and foreground duration. Keep every animation in the existing token-guarded `Promise.all` completion path.

When the user taps the opposite target during playback, do not create a new color descriptor or animation. The existing branch must continue to execute only:

```js
state.activeAnimations.forEach(({ animation }) => {
  animation.reverse();
});
```

- [x] **Step 4: Commit deterministic endpoint state**

After canceling filled animations in `commitPortalMessageState`, call `applyPortalMessageColorRestState`. Update the base pseudo variable, both canvases, visibility data, and render lifecycle according to target/mode. Do not reconstruct financial colors; exposing the untouched financial layers is the Balance restoration mechanism.

- [x] **Step 5: Implement 180 ms settled-message preview**

Snapshot the outgoing message-color canvas into a temporary pointer-free canvas before changing mode/palette/settings. Crossfade the snapshot out and the newly rendered source in over 180 ms. For active→`none`, crossfade the financial base back in; for `none`→active, crossfade it out. Do not call `runPortalMessageMorph`, alter content state, or replay the background response.

Store one preview group with animations, snapshot, and token. A new preview cancels/removes the previous group. A trigger press cancels preview before entering the common reversible transition.

- [x] **Step 6: Run all focused regressions**

```bash
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_portal_background_test.js
node docs/prototypes/color_lab_portal_color_test.js
node docs/prototypes/color_lab_portal_color_renderer_test.js
node --check docs/prototypes/color_lab_portal_color.js
node --check docs/prototypes/color_lab_portal_color_renderer.js
```

Expected: six pass messages and both syntax checks exit 0.

- [x] **Step 7: Record the shared-file checkpoint without committing**

Run `git diff --check` and inspect message-color runtime hunks. Do not stage shared dirty files.

---

### Task 6: Full verification and acceptance evidence

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md:368-372`
- Modify: `docs/superpowers/plans/2026-07-16-portal-message-color-transform.md`

- [x] **Step 1: Run the full fresh automated suite**

```bash
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_portal_background_test.js
node docs/prototypes/color_lab_portal_color_test.js
node docs/prototypes/color_lab_portal_color_renderer_test.js
node --check docs/prototypes/color_lab_portal_energy.js
node --check docs/prototypes/color_lab_portal_message.js
node --check docs/prototypes/color_lab_portal_background.js
node --check docs/prototypes/color_lab_portal_color.js
node --check docs/prototypes/color_lab_portal_color_renderer.js
```

Expected: all suites pass and every syntax check exits 0.

- [x] **Step 2: Parse inline scripts and check whitespace**

Extract every non-`src` script from `color_lab.html`, compile it with `new Function(source)`, require exactly one inline script, then run `git diff --check`. Expected: `Inline scripts parse: 1` and exit 0.

- [x] **Step 3: Run HTTP source smoke**

Serve `docs/prototypes` and require HTTP 200 with non-empty bodies for:

- `color_lab.html`;
- `color_lab_portal_energy.js`;
- `color_lab_portal_message.js`;
- `color_lab_portal_background.js`;
- `color_lab_portal_color.js`;
- `color_lab_portal_color_renderer.js`.

Expected: `HTTP portal source checks passed`.

- [x] **Step 4: Update checklist evidence honestly**

Change `COLOR-LAB-328`–`332` from `NOT DONE` to `PARTIAL`. Record every witnessed RED/GREEN command, pure-model/renderer coverage, protected regressions, parse, diff, and HTTP evidence. Explicitly retain Android visual/manual checks as remaining evidence.

- [x] **Step 5: Re-run verification after documentation edits**

Repeat Steps 1–3. Do not claim UI completion unless Android-browser evidence covers all six modes, center/window combinations, four dynamic motions, simultaneous background responses, forward/backward/rapid reversal, live preview, window opacity, scrolling/manual input, touch preservation, and exact Money-flow restoration.
