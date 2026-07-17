# Balance Interior Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one optional Balance-only interior animation that visibly animates both colored header regions, derives soft accents from each mother color, and never contaminates the animated white boundary corridor.

**Architecture:** Add a pure CommonJS/browser-compatible interior-motion model and a focused Canvas 2D renderer, then wire both into the existing Color Lab test-header state, shared frame loop, and optional-effect controls. The renderer performs two separately seeded clip passes around the current Balance boundary geometry; controls select exactly one effect and independently regulate strength and speed.

**Tech Stack:** Static HTML/CSS, browser Canvas 2D, plain JavaScript modules compatible with Node `require`, Node built-in `assert`, existing Color Lab test scripts.

## Global Constraints

- Mandatory reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260717-013843.png`.
- Scope is Balance mode only; default state is off.
- Existing boundary, energy, message, background-response, color, and transition effects remain independent.
- Exactly one of `driftingMist`, `innerCurrent`, `softTide`, or `slowVortex` can be selected.
- Both sides share effect/strength/speed, but use deterministic nonmatching seeds, phases, and directions.
- Green accents are lighter/deeper derivatives of the green mother; right accents are pinker/violet derivatives of the right mother.
- Every primitive feathers back into its own mother color; no hard contour is allowed.
- The full white boundary plus feather allowance is a protected no-draw corridor.
- Reuse the existing frame clock; do not add another `requestAnimationFrame` loop.
- Add no runtime dependency.
- Completion requires `COLOR-LAB-384` through `COLOR-LAB-394` to be `DONE` or explicitly deferred.

## File Structure

- Create `docs/prototypes/color_lab_portal_interior_motion.js`: state, deterministic timing, mother-color derivation, and effect primitives.
- Create `docs/prototypes/color_lab_portal_interior_motion_test.js`: pure model tests.
- Create `docs/prototypes/color_lab_portal_interior_motion_renderer.js`: protected masks and Canvas rendering.
- Create `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`: fake-canvas renderer tests.
- Modify `docs/prototypes/color_lab.html`: scripts, controls, state, boundary adapter, and shared-loop integration.
- Modify `docs/prototypes/color_lab_static_test.js`: DOM/source integration contracts.
- Modify `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`: verification evidence and statuses.

---

### Task 1: Interior State, Timing, Palette, and Primitive Model

**Files:**
- Create: `docs/prototypes/color_lab_portal_interior_motion.js`
- Create: `docs/prototypes/color_lab_portal_interior_motion_test.js`

**Interfaces:**
- Consumes: resolved mother colors as `#RRGGBB`, time in milliseconds, and serializable control state.
- Produces: `EFFECT_IDS`, `DEFAULT_INTERIOR_MOTION_STATE`, `normalizeInteriorMotionState`, `deriveInteriorPalette`, `createSideMotion`, and `createInteriorPrimitives`.

- [ ] **Step 1: Write the failing pure-model test**

Create `docs/prototypes/color_lab_portal_interior_motion_test.js`:

```js
"use strict";
const assert = require("node:assert/strict");
const api = require("./color_lab_portal_interior_motion.js");

assert.deepEqual(api.EFFECT_IDS, [
  "driftingMist", "innerCurrent", "softTide", "slowVortex",
]);
assert.deepEqual(api.DEFAULT_INTERIOR_MOTION_STATE, {
  enabled: false,
  effect: "driftingMist",
  strength: 0.36,
  speed: 0.42,
});
assert.deepEqual(api.normalizeInteriorMotionState({
  enabled: 1, effect: "invalid", strength: 3, speed: -1,
}), {
  enabled: true, effect: "driftingMist", strength: 1, speed: 0,
});

const palette = api.deriveInteriorPalette("#36c9b8", "#d890ef");
assert.equal(palette.left.mother, "#36c9b8");
assert.equal(palette.right.mother, "#d890ef");
assert.ok(palette.left.lightnessA > palette.left.motherLightness);
assert.ok(palette.left.lightnessB < palette.left.motherLightness);
assert.ok(palette.right.hueA > 300 || palette.right.hueA < 20);
assert.ok(palette.right.hueB >= 255 && palette.right.hueB <= 300);

const left = api.createSideMotion("innerCurrent", "left", 1200, 0.5);
const right = api.createSideMotion("innerCurrent", "right", 1200, 0.5);
assert.notEqual(left.seed, right.seed);
assert.notEqual(left.phase, right.phase);
assert.equal(left.direction, 1);
assert.equal(right.direction, -1);
assert.deepEqual(api.createSideMotion("innerCurrent", "left", 1200, 0.5), left);

const signatures = api.EFFECT_IDS.map((effect) => {
  const frame = api.createInteriorPrimitives({
    effect, side: "left", width: 220, height: 88,
    timeMs: 1200, speed: 0.5, strength: 0.4,
    palette: palette.left,
  });
  assert.ok(frame.primitives.length >= 2);
  assert.ok(frame.primitives.every((p) => p.edgeColor === palette.left.mother));
  return frame.primitives.map((p) => p.kind).join(",");
});
assert.equal(new Set(signatures).size, api.EFFECT_IDS.length);
console.log("Portal interior motion model checks passed");
```

- [ ] **Step 2: Run RED**

Run: `node docs/prototypes/color_lab_portal_interior_motion_test.js`

Expected: FAIL with `Cannot find module './color_lab_portal_interior_motion.js'`.

- [ ] **Step 3: Implement the model API**

Use the established portal-module browser/CommonJS wrapper. Define state and timing exactly:

```js
const EFFECT_IDS = Object.freeze([
  "driftingMist", "innerCurrent", "softTide", "slowVortex",
]);
const DEFAULT_INTERIOR_MOTION_STATE = Object.freeze({
  enabled: false,
  effect: "driftingMist",
  strength: 0.36,
  speed: 0.42,
});

function clamp01(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.max(0, Math.min(1, number)) : fallback;
}

function normalizeInteriorMotionState(value = {}) {
  return {
    enabled: Boolean(value.enabled),
    effect: EFFECT_IDS.includes(value.effect) ? value.effect : "driftingMist",
    strength: clamp01(value.strength, 0.36),
    speed: clamp01(value.speed, 0.42),
  };
}

function createSideMotion(effect, side, timeMs, speed) {
  const safeEffect = EFFECT_IDS.includes(effect) ? effect : "driftingMist";
  const safeSide = side === "right" ? "right" : "left";
  const seed = EFFECT_IDS.indexOf(safeEffect) * 97 + (safeSide === "left" ? 17 : 61);
  const direction = safeSide === "left" ? 1 : -1;
  const offset = safeSide === "left" ? 0.13 : 0.67;
  const cycles = (Number(timeMs) || 0) * (0.000035 + clamp01(speed, 0.42) * 0.00022);
  return { seed, direction, phase: ((offset + cycles * direction) % 1 + 1) % 1 };
}
```

Implement local RGB/HSL conversion. `deriveInteriorPalette` changes green lightness by `+0.14` and `-0.15`; it circularly mixes the right hue 38% toward 332 degrees and 42% toward 274 degrees. Clamp channels, saturation, and lightness; emit lowercase hex. Do not define fixed accent hex values.

`createInteriorPrimitives` dispatches to four bounded builders:

```js
const BUILDERS = {
  driftingMist: buildMistEllipses,   // four radialEllipse items
  innerCurrent: buildCurrentRibbons, // three linearRibbon items
  softTide: buildTideBands,          // three sineBand items
  slowVortex: buildVortexArcs,       // three radialArc items
};
```

Every item contains normalized geometry, `innerColor`, `edgeColor`, and `alpha`. Alternate `accentA`/`accentB`, always use `mother` as `edgeColor`, and map alpha to `0.04 + strength * 0.22`. Derive every position from `createSideMotion`; use no per-frame randomness.

- [ ] **Step 4: Run GREEN**

Run: `node docs/prototypes/color_lab_portal_interior_motion_test.js`

Expected: `Portal interior motion model checks passed`.

- [ ] **Step 5: Commit**

```bash
git add docs/prototypes/color_lab_portal_interior_motion.js docs/prototypes/color_lab_portal_interior_motion_test.js
git commit -m "feat: add balance interior motion model"
```

---

### Task 2: Protected Two-Mask Canvas Renderer

**Files:**
- Create: `docs/prototypes/color_lab_portal_interior_motion_renderer.js`
- Create: `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`

**Interfaces:**
- Consumes: Task 1 API, Canvas 2D context, dimensions, current mode/time/mother colors, and boundary edge samplers.
- Produces: `buildInteriorRegionPolygons(options)`, `drawInteriorPrimitive(ctx, primitive, bounds)`, and `renderPortalInteriorMotion(ctx, options)`.

- [ ] **Step 1: Write failing renderer tests**

Create a fake context recording path, clip, gradient, color-stop, fill, stroke, save, and restore calls. Test:

```js
const assert = require("node:assert/strict");
const api = require("./color_lab_portal_interior_motion_renderer.js");

function createFakeContext() {
  const calls = [];
  const colorStops = [];
  const record = (name, args = []) => calls.push({ name, args: [...args] });
  const createGradient = (name, args) => {
    record(name, args);
    return {
      addColorStop(offset, color) {
        colorStops.push({ offset, color });
      },
    };
  };
  return {
    calls,
    colorStops,
    globalAlpha: 1,
    lineWidth: 1,
    save() { record("save"); },
    restore() { record("restore"); },
    beginPath() { record("beginPath"); },
    closePath() { record("closePath"); },
    moveTo(...args) { record("moveTo", args); },
    lineTo(...args) { record("lineTo", args); },
    bezierCurveTo(...args) { record("bezierCurveTo", args); },
    ellipse(...args) { record("ellipse", args); },
    arc(...args) { record("arc", args); },
    translate(...args) { record("translate", args); },
    rotate(...args) { record("rotate", args); },
    scale(...args) { record("scale", args); },
    clip() { record("clip"); },
    fill() { record("fill"); },
    stroke() { record("stroke"); },
    createRadialGradient(...args) {
      return createGradient("createRadialGradient", args);
    },
    createLinearGradient(...args) {
      return createGradient("createLinearGradient", args);
    },
    set fillStyle(value) { record("fillStyle", [value]); },
    set strokeStyle(value) { record("strokeStyle", [value]); },
  };
}

const boundary = {
  leftXAt: (y) => 104 + Math.sin(y / 20) * 4,
  rightXAt: (y) => 132 + Math.sin(y / 20) * 4,
  featherPx: 5,
};
const polygons = api.buildInteriorRegionPolygons({
  width: 240, height: 96, boundary, samples: 24,
});
assert.ok(polygons.left.every((p) => p.x <= boundary.leftXAt(p.y) - 5));
assert.ok(polygons.right.every((p) => p.x >= boundary.rightXAt(p.y) + 5));

const off = api.renderPortalInteriorMotion(createFakeContext(), {
  mode: "balance", state: { enabled: false }, width: 240, height: 96,
  timeMs: 1000, boundary, leftMother: "#36c9b8", rightMother: "#d890ef",
});
assert.deepEqual(off, { rendered: false, leftPrimitiveCount: 0, rightPrimitiveCount: 0 });

const ctx = createFakeContext();
const on = api.renderPortalInteriorMotion(ctx, {
  mode: "balance",
  state: { enabled: true, effect: "driftingMist", strength: 0.4, speed: 0.5 },
  width: 240, height: 96, timeMs: 1000, boundary,
  leftMother: "#36c9b8", rightMother: "#d890ef",
});
assert.equal(on.rendered, true);
assert.ok(on.leftPrimitiveCount > 0 && on.rightPrimitiveCount > 0);
assert.equal(ctx.calls.filter((call) => call.name === "clip").length, 2);
assert.ok(ctx.colorStops.some((stop) => stop.color.includes("54, 201, 184")));
assert.ok(ctx.colorStops.some((stop) => stop.color.includes("216, 144, 239")));
console.log("Portal interior motion renderer checks passed");
```

- [ ] **Step 2: Run RED**

Run: `node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`

Expected: FAIL with missing renderer module.

- [ ] **Step 3: Implement region polygons**

Sample y from 0 through height. The left protected edge is `leftXAt(y) - featherPx`; the right protected edge is `rightXAt(y) + featherPx`. Clamp x to `[0, width]`, close each polygon against its outer header edge, and return empty polygons for missing/non-finite geometry.

- [ ] **Step 4: Implement primitive painters and isolated passes**

Provide one painter for each Task 1 kind:

```js
const PAINTERS = {
  radialEllipse: drawRadialEllipse,
  linearRibbon: drawLinearRibbon,
  sineBand: drawSineBand,
  radialArc: drawRadialArc,
};
```

All gradients use the same soft mother-color return:

```js
gradient.addColorStop(0, withAlpha(primitive.innerColor, primitive.alpha));
gradient.addColorStop(0.58, withAlpha(primitive.innerColor, primitive.alpha * 0.48));
gradient.addColorStop(1, withAlpha(primitive.edgeColor, 0));
```

`renderPortalInteriorMotion` returns immediately when disabled, outside Balance mode, dimensions are zero, or geometry is degenerate. Otherwise it derives one palette, creates left/right primitives with separate side names, and performs exactly two `save -> path -> clip -> draw -> restore` passes. It must not call `requestAnimationFrame`, clear the canvas, redraw the base fill, or draw the white boundary. Restore context and fail closed if an interior pass throws.

- [ ] **Step 5: Run model and renderer GREEN**

```bash
node docs/prototypes/color_lab_portal_interior_motion_test.js
node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js
```

Expected: both print `checks passed`.

- [ ] **Step 6: Commit**

```bash
git add docs/prototypes/color_lab_portal_interior_motion_renderer.js docs/prototypes/color_lab_portal_interior_motion_renderer_test.js
git commit -m "feat: render masked balance interior effects"
```

---

### Task 3: Color Lab Controls and Shared-Loop Integration

**Files:**
- Modify: `docs/prototypes/color_lab.html`
- Modify: `docs/prototypes/color_lab_static_test.js`

**Interfaces:**
- Consumes: Task 1-2 browser globals, existing Balance state/colors/boundary geometry, and current frame timestamp.
- Produces: an optional-effect row/panel, normalized `portalInteriorMotionState`, and one renderer call in the existing header pass.

- [ ] **Step 1: Write failing static integration assertions**

Add assertions for both scripts, their order, and these contracts:

```js
assert.ok(source.includes('data-portal-interior-motion-row'));
assert.ok(source.includes('data-portal-interior-motion-toggle'));
assert.ok(source.includes('data-portal-interior-motion-effect'));
assert.ok(source.includes('data-portal-interior-motion-strength'));
assert.ok(source.includes('data-portal-interior-motion-speed'));
for (const value of ["driftingMist", "innerCurrent", "softTide", "slowVortex"]) {
  assert.ok(source.includes(`value="${value}"`));
}
assert.ok(source.includes("renderPortalInteriorMotion"));
assert.ok(!/portalInteriorMotion[\s\S]{0,300}requestAnimationFrame/.test(source));
```

- [ ] **Step 2: Run static RED**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: FAIL on the first missing interior-motion assertion.

- [ ] **Step 3: Load scripts and add compact controls**

Load model before renderer and both before the main controller. Add one row consistent with existing portal effect rows:

```html
<section class="portal-option-row" data-portal-interior-motion-row>
  <button type="button" class="portal-option-summary" data-portal-interior-motion-expand>
    <span class="portal-option-title">PORTÁL BELSŐ MOZGÁS</span>
    <span class="portal-option-value" data-portal-interior-motion-label>VÁNDORLÓ KÖD</span>
  </button>
  <button type="button" class="portal-option-toggle"
          aria-pressed="false" data-portal-interior-motion-toggle>KI</button>
  <button type="button" class="portal-option-open"
          aria-label="Belső mozgás beállításai" data-portal-interior-motion-expand>›</button>
</section>
```

The expanded un-nested panel contains one select with the four Hungarian names and two `0..100` range/value rows: `Erősség` defaults to 36 and `Sebesség` to 42. Reuse existing control classes; scope any additional CSS to the new data attribute and verify no overflow at the reference mobile width.

- [ ] **Step 4: Wire independent state**

```js
let portalInteriorMotionState = {
  ...ColorLabPortalInteriorMotion.DEFAULT_INTERIOR_MOTION_STATE,
};
function setPortalInteriorMotionState(patch) {
  portalInteriorMotionState = ColorLabPortalInteriorMotion
    .normalizeInteriorMotionState({ ...portalInteriorMotionState, ...patch });
  syncPortalInteriorMotionControls();
  requestPortalHeaderRender();
}
```

Map ranges to `0..1`; the toggle changes only `enabled`; select replacement stores one string, not a list. Synchronize `aria-pressed`, `KI/BE`, selected effect label, values, and disabled appearance. Do not read/write another portal effect's state.

- [ ] **Step 5: Add one renderer call in the existing frame**

Call after Balance base colors and before the current white boundary/content pass:

```js
ColorLabPortalInteriorMotionRenderer.renderPortalInteriorMotion(ctx, {
  mode: currentPortalMode,
  state: portalInteriorMotionState,
  width: headerWidth,
  height: headerHeight,
  timeMs: reduceMotion ? 0 : frameTimeMs,
  leftMother: resolvedBalanceColors.left,
  rightMother: resolvedBalanceColors.right,
  boundary: {
    leftXAt: (y) => currentBoundaryEdgesAt(y).left,
    rightXAt: (y) => currentBoundaryEdgesAt(y).right,
    featherPx: Math.max(3, currentBoundaryFeatherPx),
  },
});
```

Adapt only local variable names to the inspected renderer. Preserve the data contract and use the existing frame scheduler. Existing white boundary and header content render immediately afterward.

- [ ] **Step 6: Run all tests**

```bash
node docs/prototypes/color_lab_portal_interior_motion_test.js
node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js
node docs/prototypes/color_lab_static_test.js
```

Expected: all exit 0 with pass messages.

- [ ] **Step 7: Commit**

```bash
git add docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
git commit -m "feat: add balance interior motion controls"
```

---

### Task 4: Runtime, Boundary, Visual, and Checklist Verification

**Files:**
- Modify: `docs/prototypes/color_lab_portal_interior_motion_renderer_test.js`
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md`

**Interfaces:**
- Consumes: complete model/renderer/integration.
- Produces: direct evidence for every `COLOR-LAB-384` through `COLOR-LAB-394` row.

- [ ] **Step 1: Add deterministic temporal regression tests**

Generate frames at 0, 900, and 1800 ms and assert:

```js
const model = require("./color_lab_portal_interior_motion.js");
const palette = model.deriveInteriorPalette("#36c9b8", "#d890ef");
const frameFor = (side, timeMs) => model.createInteriorPrimitives({
  effect: "innerCurrent",
  side,
  width: 220,
  height: 88,
  timeMs,
  speed: 0.5,
  strength: 0.4,
  palette: palette[side],
});
const leftFrame0 = frameFor("left", 0);
const leftFrame900 = frameFor("left", 900);
const repeatLeftFrame900 = frameFor("left", 900);
const rightFrame0 = frameFor("right", 0);
const rightFrame900 = frameFor("right", 900);
const rightFrame1800 = frameFor("right", 1800);

assert.notDeepEqual(leftFrame0.primitives, leftFrame900.primitives);
assert.notDeepEqual(rightFrame0.primitives, rightFrame900.primitives);
assert.notDeepEqual(leftFrame900.primitives, rightFrame900.primitives);
assert.deepEqual(leftFrame900, repeatLeftFrame900);
assert.notDeepEqual(rightFrame900.primitives, rightFrame1800.primitives);
```

For approximate 35/65, 50/50, and 65/35 splits, assert every left polygon sample is at/before `leftXAt(y) - featherPx`, every right sample is at/after `rightXAt(y) + featherPx`, and corridor width remains positive.

- [ ] **Step 2: Verify inactive lifecycle**

Use fake-context counters to prove disabled and non-Balance calls create zero gradients/primitives. Keep the static assertion preventing an interior-specific frame loop.

- [ ] **Step 3: Run tests and HTTP smoke**

```bash
node docs/prototypes/color_lab_portal_interior_motion_test.js
node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js
node docs/prototypes/color_lab_static_test.js
node -e "fetch('http://127.0.0.1:8765/docs/prototypes/color_lab.html').then(r => r.text()).then(s => { if (!s.includes('data-portal-interior-motion-row') || !s.includes('color_lab_portal_interior_motion_renderer.js')) process.exit(1); console.log('Interior motion HTTP smoke passed'); })"
```

Expected: all tests pass and HTTP smoke prints its pass message.

- [ ] **Step 4: Perform mandatory mobile visual verification**

At the viewport represented by `Screenshot_20260717-013843.png`, enable the new layer while Balance ellenáram remains enabled. Capture every effect at two timestamps at least one second apart. Confirm visible change well inside both fields; a neutral white corridor; lighter/deeper green and pinker/violet components; no hard blob edge, clipped blur, resize, overlap, or control overflow. Test Strength 0/100 and Speed 0/100 for parameter isolation. Disable the layer and confirm the baseline returns while boundary motion continues.

Record every exact new screenshot path in checklist evidence.

- [ ] **Step 5: Update checklist truthfully**

Append test/screenshot evidence to each `COLOR-LAB-384` through `COLOR-LAB-394` row. Set `DONE` only where the row's own acceptance condition is proven; retain `PARTIAL`, `BLOCKED`, or `NOT DONE` otherwise.

- [ ] **Step 6: Run final verification**

```bash
node docs/prototypes/color_lab_portal_interior_motion_test.js
node docs/prototypes/color_lab_portal_interior_motion_renderer_test.js
node docs/prototypes/color_lab_static_test.js
git diff --check -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js docs/prototypes/color_lab_portal_interior_motion.js docs/prototypes/color_lab_portal_interior_motion_test.js docs/prototypes/color_lab_portal_interior_motion_renderer.js docs/prototypes/color_lab_portal_interior_motion_renderer_test.js docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md
```

Expected: every Node script passes; `git diff --check` exits 0 with no output.

- [ ] **Step 7: Commit verification evidence**

```bash
git add docs/prototypes/color_lab_portal_interior_motion_renderer_test.js docs/prototypes/color_lab_static_test.js docs/superpowers/checklists/2026-07-17-balance-interior-motion-checklist.md
git commit -m "test: verify balance interior motion isolation"
```

## Plan Self-Review

- Spec coverage: Tasks 1-4 cover every approved behavior and `COLOR-LAB-384` through `COLOR-LAB-394`.
- Placeholder scan: no `TBD`, `TODO`, unnamed edge-case step, or deferred implementation remains.
- Interface consistency: Task 1 exports feed Task 2; Task 2's renderer contract feeds Task 3; Task 4 exercises those same state, primitive, polygon, and renderer interfaces.
- Execution: tasks share one sequential render pipeline and HTML state, so inline execution with checkpoints is safer than concurrent edits.
