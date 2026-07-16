# Portal Message Field and Transition Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the standalone test Portal's invalid left/right message field with an A-base/B-matter energy field, split delivery into three independently switchable layers, and animate a full-header Balance↔Portal color transformation.

**Architecture:** New pure UMD modules own the settled Portal matter field, its pixel renderer, the three background-transition masks, the transition compositor, and an animation-like reversible rAF player. The existing foreground and text-background modules retain their focused responsibilities, while the HTML controller coordinates their independent switches and one shared reversible delivery lifecycle. Colored visual layers become direct full-header siblings; only text remains inside the padded viewport.

**Tech Stack:** HTML, CSS, browser JavaScript, Canvas 2D, Web Animations API, CommonJS-compatible UMD modules, Node `assert` tests.

## Global Constraints

- Follow `docs/superpowers/specs/2026-07-16-portal-message-field-transition-redesign-design.md` exactly.
- Acceptance IDs are `COLOR-LAB-333` through `COLOR-LAB-340` in `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`.
- HTML prototype only; do not edit Flutter or run a Flutter/APK build.
- Execute inline; the user explicitly rejected subagents for this work.
- Preserve the accepted touch bloom, trail, ripple, pointer capture, drag interception, delayed release fade, and interaction-opacity code and CSS.
- Preserve every Balance signature, Money-flow ratio and 8–92% mapping, base-energy mode/settings/phase, and exact restoration after returning from a message.
- Portal palette remains `#fffdfd → #ffc4e4 → #8b5cf6`; center defaults to 50 and deferred window size defaults to 68 with a 10–100 commit clamp.
- Portal endpoint defaults: `wandering-mist`; Balance→Portal transition defaults: `pigment-spread`.
- Three switches are independent: foreground text morph, local text-background morph, and full-header background morph.
- Text-background off means a true zero-output visual state. Full-background morph off means an immediate switch between still-distinct endpoint backgrounds.
- Every colored canvas/overlay is `inset: 0` outside the `16px 17px` content viewport and clipped only by the header radius.
- Existing shared HTML, static test, and checklist files contain prior user-owned work. Commit isolated new/clean module files only; do not stage the shared dirty files.

## File structure

- Create `docs/prototypes/color_lab_portal_message_field.js`: Portal palette delegation, exact endpoint mode schemas, matter-mask samplers, phase and render profiles.
- Create `docs/prototypes/color_lab_portal_message_field_test.js`: model/schema/mask invariants and per-control sensitivity.
- Create `docs/prototypes/color_lab_portal_message_field_renderer.js`: direct A→B RGBA rendering.
- Create `docs/prototypes/color_lab_portal_message_field_renderer_test.js`: pixel, phase, opacity, and dimension contracts.
- Create `docs/prototypes/color_lab_portal_transition.js`: exact transition schemas and two-channel progress fields.
- Create `docs/prototypes/color_lab_portal_transition_test.js`: mode/schema/boundary/per-control tests.
- Create `docs/prototypes/color_lab_portal_transition_renderer.js`: source→Portal-A→Portal-target compositor.
- Create `docs/prototypes/color_lab_portal_transition_renderer_test.js`: deterministic pixel-composition tests.
- Create `docs/prototypes/color_lab_portal_transition_player.js`: reversible rAF animation adapter.
- Create `docs/prototypes/color_lab_portal_transition_player_test.js`: fake-clock reverse/cancel/finish tests.
- Modify `docs/prototypes/color_lab_portal_message.js`: foreground descriptors become content-only.
- Modify `docs/prototypes/color_lab_portal_message_test.js`: forbid foreground accent output.
- Modify `docs/prototypes/color_lab_portal_background.js`: remove financial-seam ownership from the local text reaction.
- Modify `docs/prototypes/color_lab_portal_background_test.js`: enforce local/text-centered semantics and exact zero fallback.
- Modify `docs/prototypes/color_lab.html`: full-header layers, switches, menus, runtime, lifecycle, fallback, and scroll routing.
- Modify `docs/prototypes/color_lab_static_test.js`: DOM/CSS/runtime/source-contract coverage.
- Modify the acceptance checklist only after fresh verification.

---

### Task 1: Pure A-base/B-matter Portal endpoint model

**Files:**

- Create: `docs/prototypes/color_lab_portal_message_field.js`
- Create: `docs/prototypes/color_lab_portal_message_field_test.js`
- Read: `docs/prototypes/color_lab_portal_color.js`

**Interfaces:**

- Consumes browser/CommonJS `PortalMessageColor` only for `paletteStops`, `defaults`, `samplePalette`, `sampleWindow`, `normalizeCenter`, and `normalizeWindow`.
- Produces browser/CommonJS `PortalMessageField` with `modeOrder`, `modeLabels`, `animatedModes`, `defaults`, palette delegates, `controlsForMode(mode)`, `createModeSettings(mode)`, `normalizeValue(meta,value)`, `sampleMatter(mode,x,y,phase,settings)`, `advancePhase(mode,phase,elapsed,settings)`, and `renderProfile(mode)`.
- `sampleMatter` always returns a finite number in `[0,1]`; zero means exact A and one means exact B.

- [ ] **Step 1: Write the failing field-model test**

Create a Node `assert` test containing these exact contracts:

```js
const assert = require('assert');
const field = require('./color_lab_portal_message_field.js');

assert.deepStrictEqual(field.modeOrder, [
  'solid-a', 'static-matter', 'wandering-mist',
  'living-archipelago', 'forming-clouds',
]);
assert.deepStrictEqual(field.modeOrder.map((id) => field.modeLabels[id]), [
  'Nincs dinamikus effekt', 'Statikus köd/szigetek', 'Vándorló köd',
  'Élő szigetvilág', 'Keletkező energiafelhők',
]);
assert.deepStrictEqual(field.animatedModes, [
  'wandering-mist', 'living-archipelago', 'forming-clouds',
]);
assert.strictEqual(field.defaults.mode, 'wandering-mist');
assert.deepStrictEqual(field.paletteStops, [
  { position: 0, color: '#fffdfd' },
  { position: 50, color: '#ffc4e4' },
  { position: 100, color: '#8b5cf6' },
]);
assert.deepStrictEqual(field.sampleWindow(50, 68), {
  center: 50, windowSize: 68, lower: 16, upper: 84,
  a: '#ffebf5', b: '#b07df0',
});
assert.strictEqual(field.sampleMatter('solid-a', .2, .8, 12, {}), 0);
assert.strictEqual(
  field.sampleMatter('static-matter', .31, .67, 0, field.createModeSettings('static-matter')),
  field.sampleMatter('static-matter', .31, .67, 900, field.createModeSettings('static-matter')),
);

for (const mode of field.modeOrder.slice(1)) {
  const controls = field.controlsForMode(mode);
  const settings = field.createModeSettings(mode);
  assert(controls.length > 0, `${mode} needs controls`);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(field.normalizeValue(meta, meta.min - 9999), meta.min);
    assert.strictEqual(field.normalizeValue(meta, meta.max + 9999), meta.max);
  });
  for (const phase of [0, .75, 2.25]) {
    for (const [x, y] of [[0, 0], [.13, .81], [.5, .5], [.92, .17], [1, 1]]) {
      const value = field.sampleMatter(mode, x, y, phase, settings);
      assert(Number.isFinite(value) && value >= 0 && value <= 1);
    }
  }
  for (const meta of controls) {
    const changed = { ...settings, [meta.key]: settings[meta.key] === meta.max ? meta.min : meta.max };
    const signature = (input) => [0, .2, .4, .6, .8, 1].flatMap((x) =>
      [0, .33, .66, 1].map((y) => field.sampleMatter(mode, x, y, 1.7, input))
    );
    assert.notDeepStrictEqual(signature(changed), signature(settings), `${mode}.${meta.key}`);
  }
}

for (const mode of field.animatedModes) {
  const settings = field.createModeSettings(mode);
  const before = [0, .25, .5, .75, 1].map((x) => field.sampleMatter(mode, x, .42, 0, settings));
  const after = [0, .25, .5, .75, 1].map((x) => field.sampleMatter(mode, x, .42, 3, settings));
  assert.notDeepStrictEqual(after, before, `${mode} must move`);
}
console.log('Portal message field checks passed');
```

- [ ] **Step 2: Run the new test and witness RED**

Run `node docs/prototypes/color_lab_portal_message_field_test.js`.

Expected: exit 1 with `MODULE_NOT_FOUND` for `color_lab_portal_message_field.js`.

- [ ] **Step 3: Implement the exact schemas and deterministic field helpers**

Use a UMD wrapper that receives `PortalMessageColor`. Define frozen schemas with these keys and exact `min/max/step/default/unit` tuples:

```js
const schemas = Object.freeze({
  'solid-a': freeze([]),
  'static-matter': freeze([
    ['coverage', 'B-fedettség', 0, 80, 1, 34, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 72, '%'],
    ['scale', 'Anyagskála', 20, 180, 1, 100, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 76, '%'],
    ['detail', 'Részletesség', 0, 100, 1, 28, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 137, ''],
  ]),
  'wandering-mist': freeze([
    ['coverage', 'B-fedettség', 0, 80, 1, 36, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 74, '%'],
    ['scale', 'Ködskála', 20, 200, 1, 118, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 82, '%'],
    ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 22, '%'],
    ['curl', 'Curl erősség', 0, 100, 1, 44, '%'],
    ['morphRate', 'Alakváltozás', 0, 100, 1, 28, '%'],
    ['detail', 'Részletesség', 0, 100, 1, 24, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 311, ''],
  ]),
  'living-archipelago': freeze([
    ['islandCount', 'Szigetszám', 2, 12, 1, 6, ''],
    ['size', 'Átlagos méret', 8, 80, 1, 34, '%'],
    ['sizeVariance', 'Méreteltérés', 0, 100, 1, 42, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 78, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 66, '%'],
    ['wanderSpeed', 'Vándorlási sebesség', 0, 100, 1, 30, '%'],
    ['mergeAttraction', 'Összeolvadási vonzás', 0, 100, 1, 55, '%'],
    ['morphRate', 'Alakváltozás', 0, 100, 1, 36, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 521, ''],
  ]),
  'forming-clouds': freeze([
    ['density', 'Aktív felhősűrűség', 1, 10, 1, 4, ''],
    ['lifetime', 'Élettartam', 2, 30, 1, 14, 's'],
    ['birthOverlap', 'Születési átfedés', 0, 100, 1, 58, '%'],
    ['growth', 'Növekedés', 0, 100, 1, 46, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 76, '%'],
    ['scale', 'Felhőskála', 10, 120, 1, 46, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 78, '%'],
    ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 24, '%'],
    ['pathIrregularity', 'Útvonal-szabálytalanság', 0, 100, 1, 52, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 887, ''],
  ]),
});
```

Convert tuples to frozen metadata objects. Implement deterministic 2D value noise, three-octave fBm, Gaussian blobs, smooth thresholds, and seeded hashes. Implement the field dispatch exactly as:

```js
function sampleMatter(mode, x, y, phase, input) {
  const id = normalizeMode(mode);
  if (id === 'solid-a') return 0;
  const s = normalizedSettings(id, input);
  const nx = clamp01(Number(x));
  const ny = clamp01(Number(y));
  const t = Number(phase) || 0;
  if (id === 'static-matter') return sampleStaticMatter(nx, ny, s);
  if (id === 'wandering-mist') return sampleWanderingMist(nx, ny, t, s);
  if (id === 'living-archipelago') return sampleArchipelago(nx, ny, t, s);
  return sampleFormingClouds(nx, ny, t, s);
}

function advancePhase(mode, phase, elapsed, input) {
  const id = normalizeMode(mode);
  if (!animatedModes.includes(id)) return Number(phase) || 0;
  const s = normalizedSettings(id, input);
  const speed = id === 'living-archipelago' ? s.wanderSpeed : s.driftSpeed;
  return (Number(phase) || 0) + Math.max(0, Number(elapsed) || 0) * speed / 24;
}

function renderProfile(mode) {
  return mode === 'forming-clouds'
    ? { renderScale: .48, frameMs: 52 }
    : { renderScale: .55, frameMs: 48 };
}
```

Static uses an fBm threshold controlled by coverage/softness. Wandering mist domain-warps both coordinates with independent fBm fields before thresholding. Archipelago sums seeded moving Gaussians and converts the sum with `1 - Math.exp(-sum * mergeFactor)`. Forming clouds uses `age = fract(phase / lifetime + seededOffset)`, a `Math.sin(Math.PI * age)` life envelope, seeded curved paths, and staggered centers. Multiply the final bounded mask by `strength / 100`; never alter A/B colors in this module.

Use these concrete sampler bodies so every approved control has a defined role:

```js
function materialThreshold(value, coverage, softness) {
  const center = 1 - (coverage / 100);
  const width = .015 + ((softness / 100) * .24);
  return smoothstep(center - width, center + width, value);
}

function sampleStaticMatter(x, y, s) {
  const frequency = 3.8 - ((s.scale / 180) * 2.9);
  const coarse = fbm(x * frequency, y * frequency, s.seed, 3);
  const fine = fbm(x * frequency * 2.7, y * frequency * 2.7, s.seed + 41, 2);
  const value = lerp(coarse, fine, s.detail / 180);
  return clamp01(materialThreshold(value, s.coverage, s.softness) * s.strength / 100);
}

function sampleWanderingMist(x, y, phase, s) {
  const frequency = 4.2 - ((s.scale / 200) * 3.35);
  const drift = phase * (.035 + (s.driftSpeed / 420));
  const morph = phase * (.025 + (s.morphRate / 520));
  const curl = (s.curl / 100) * .48;
  const warpX = fbm((x * 1.7) + Math.cos(drift), (y * 1.7) + Math.sin(morph), s.seed + 17, 3) - .5;
  const warpY = fbm((x * 1.7) - Math.sin(morph), (y * 1.7) + Math.cos(drift), s.seed + 73, 3) - .5;
  const px = ((x + (warpX * curl)) * frequency) + Math.cos(drift * .73);
  const py = ((y + (warpY * curl)) * frequency) + Math.sin(drift * .61);
  const broad = fbm(px, py, s.seed, 3);
  const fine = fbm((px * 2.6) - morph, (py * 2.6) + morph, s.seed + 191, 2);
  const value = lerp(broad, fine, s.detail / 150);
  return clamp01(materialThreshold(value, s.coverage, s.softness) * s.strength / 100);
}

function sampleArchipelago(x, y, phase, s) {
  let sum = 0;
  for (let index = 0; index < s.islandCount; index += 1) {
    const angle = hash2(index, 1, s.seed) * Math.PI * 2;
    const rate = .08 + (s.wanderSpeed / 560) + (hash2(index, 2, s.seed) * .09);
    const orbit = .10 + (hash2(index, 3, s.seed) * .34);
    const cx = .5 + (Math.cos(angle + (phase * rate)) * orbit);
    const cy = .5 + (Math.sin((angle * 1.31) - (phase * rate * .83)) * orbit * .72);
    const variance = 1 + ((hash2(index, 4, s.seed) - .5) * s.sizeVariance / 100);
    const morph = 1 + (Math.sin((phase * (.08 + s.morphRate / 600)) + angle) * s.morphRate / 310);
    const radius = Math.max(.025, (s.size / 220) * variance * morph);
    sum += gaussian(x - cx, y - cy, radius, radius * (.72 + hash2(index, 5, s.seed) * .42));
  }
  const merged = 1 - Math.exp(-sum * (.7 + (s.mergeAttraction / 42)));
  const width = .03 + (s.softness / 260);
  return clamp01(smoothstep(.20 - width, .20 + width, merged) * s.strength / 100);
}

function sampleFormingClouds(x, y, phase, s) {
  let fieldValue = 0;
  const count = Math.max(2, s.density * 2);
  for (let index = 0; index < count; index += 1) {
    const offset = hash2(index, 11, s.seed);
    const age = fract((phase / Math.max(2, s.lifetime)) + offset);
    const overlap = .35 + (s.birthOverlap / 125);
    const life = Math.pow(Math.max(0, Math.sin(Math.PI * age)), .65 + ((100 - s.growth) / 95));
    const irregularity = s.pathIrregularity / 100;
    const drift = age * (.05 + (s.driftSpeed / 170));
    const cx = fract(hash2(index, 12, s.seed) + drift + Math.sin((age + offset) * 6.28) * .08 * irregularity);
    const cy = clamp01(hash2(index, 13, s.seed) + Math.sin((age * 4.7) + offset * 8) * .20 * irregularity);
    const radius = Math.max(.02, (s.scale / 210) * (.35 + (life * overlap)));
    fieldValue = Math.max(fieldValue, gaussian(x - cx, y - cy, radius, radius * .76) * life);
  }
  const width = .02 + (s.softness / 240);
  return clamp01(smoothstep(.18 - width, .18 + width, fieldValue) * s.strength / 100);
}
```

- [ ] **Step 4: Run model verification**

Run:

```bash
node docs/prototypes/color_lab_portal_message_field_test.js
node --check docs/prototypes/color_lab_portal_message_field.js
```

Expected: `Portal message field checks passed`; syntax exits 0.

- [ ] **Step 5: Commit the isolated model**

```bash
git add docs/prototypes/color_lab_portal_message_field.js docs/prototypes/color_lab_portal_message_field_test.js
git commit -m "feat: add portal message matter field"
```

---

### Task 2: Direct-color Portal field renderer

**Files:**

- Create: `docs/prototypes/color_lab_portal_message_field_renderer.js`
- Create: `docs/prototypes/color_lab_portal_message_field_renderer_test.js`

**Interfaces:**

- Consumes `PortalMessageField.sampleMatter`.
- Produces `PortalMessageFieldRenderer.renderFrame(options)` returning `{ width, height, data }` or `null` for invalid colors/options.
- `data` is an opaque `Uint8ClampedArray`; each RGB channel is direct interpolation `A + (B-A)*mask`.

- [ ] **Step 1: Write the failing renderer test**

```js
const assert = require('assert');
const field = require('./color_lab_portal_message_field.js');
const renderer = require('./color_lab_portal_message_field_renderer.js');
const palette = field.sampleWindow(50, 68);
const render = (mode, phase, settings = field.createModeSettings(mode)) => renderer.renderFrame({
  mode, phase, settings, width: 17, height: 7,
  colorA: palette.a, colorB: palette.b,
});

const solid = render('solid-a', 20, {});
for (let i = 0; i < solid.data.length; i += 4) {
  assert.deepStrictEqual([...solid.data.slice(i, i + 4)], [255, 235, 245, 255]);
}
assert.deepStrictEqual([...render('static-matter', 0).data], [...render('static-matter', 80).data]);
for (const mode of field.animatedModes) {
  assert.notDeepStrictEqual([...render(mode, 0).data], [...render(mode, 3).data]);
}
for (const mode of field.modeOrder) {
  const frame = render(mode, 1.5);
  assert.strictEqual(frame.data.length, 17 * 7 * 4);
  for (let i = 0; i < frame.data.length; i += 4) {
    assert.strictEqual(frame.data[i + 3], 255);
    assert(frame.data[i] >= 139 && frame.data[i] <= 255);
    assert(frame.data[i + 1] >= 92 && frame.data[i + 1] <= 235);
    assert(frame.data[i + 2] >= 240 && frame.data[i + 2] <= 246);
  }
}
assert.strictEqual(renderer.renderFrame({ colorA: '#fff', colorB: '#8b5cf6' }), null);
assert.strictEqual(renderer.renderFrame(null), null);
console.log('Portal message field renderer checks passed');
```

- [ ] **Step 2: Run the renderer test and witness RED**

Run `node docs/prototypes/color_lab_portal_message_field_renderer_test.js`.

Expected: `MODULE_NOT_FOUND` for the renderer.

- [ ] **Step 3: Implement direct color interpolation**

Use the established UMD pattern and this pixel loop:

```js
for (let y = 0; y < height; y += 1) {
  const ny = height === 1 ? .5 : y / (height - 1);
  for (let x = 0; x < width; x += 1) {
    const nx = width === 1 ? .5 : x / (width - 1);
    const mask = field.sampleMatter(mode, nx, ny, phase, settings);
    const offset = ((y * width) + x) * 4;
    data[offset] = Math.round(a.r + ((b.r - a.r) * mask));
    data[offset + 1] = Math.round(a.g + ((b.g - a.g) * mask));
    data[offset + 2] = Math.round(a.b + ((b.b - a.b) * mask));
    data[offset + 3] = 255;
  }
}
```

Clamp dimensions to 1–2048 and require six-digit hex colors. Do not apply black, gray, luminance, blend-mode, or alpha veils.

- [ ] **Step 4: Run and commit**

Run the model and renderer tests plus `node --check` for both modules. Expected: both pass messages and exit 0. Then commit only the two new renderer files with `git commit -m "feat: render portal message matter field"`.

---

### Task 3: Pure Balance→Portal transition model and compositor

**Files:**

- Create: `docs/prototypes/color_lab_portal_transition.js`
- Create: `docs/prototypes/color_lab_portal_transition_test.js`
- Create: `docs/prototypes/color_lab_portal_transition_renderer.js`
- Create: `docs/prototypes/color_lab_portal_transition_renderer_test.js`

**Interfaces:**

- `PortalMessageTransition` exports exact mode/schema APIs and `sampleChannels(mode,x,y,progress,settings)` returning `{ base, matter }` in `[0,1]`.
- `PortalMessageTransitionRenderer.renderFrame` consumes equal-size `sourceFrame`, `portalBaseFrame`, and `portalTargetFrame`, then returns a same-size RGBA frame.
- Composition order is `mix(source, portalBase, base)` followed by `mix(result, portalTarget, matter)`.

- [ ] **Step 1: Write failing transition-model assertions**

Assert exact order/labels:

```js
assert.deepStrictEqual(transition.modeOrder, [
  'pigment-spread', 'island-takeover', 'liquid-remap',
]);
assert.deepStrictEqual(transition.modeOrder.map((id) => transition.modeLabels[id]), [
  'Pigmentterjedés', 'Szigetes átalakulás', 'Folyékony színátírás',
]);
```

For every mode, assert unique controls, defaults, bound clamping, every control changes either its descriptor or a 6×4 sampled channel signature, `progress=0` returns `{base:0,matter:0}` at all pixels, `progress=1` returns `{base:1,matter:1}`, intermediate values remain bounded, and forward signatures are neither one global constant nor a single horizontal/vertical threshold.

Use these exact schemas:

```js
const expected = {
  'pigment-spread': [
    ['duration','Időtartam',300,3000,10,1100,'ms'], ['seedCount','Forrásszám',1,12,1,5,''],
    ['sourceSpread','Forrásszórás',0,100,1,62,'%'], ['softness','Frontlágyság',0,100,1,78,'%'],
    ['diffusion','Diffúzió',0,100,1,56,'%'], ['warp','Domain warp',0,100,1,48,'%'],
    ['matterDelay','Portal-B késleltetés',0,80,1,24,'%'], ['overlap','Átfedés',0,100,1,38,'%'],
    ['easing','Lágyság',1,5,.1,2.4,''],
  ],
  'island-takeover': [
    ['duration','Időtartam',300,3000,10,1200,'ms'], ['seedCount','Magpontok',2,14,1,6,''],
    ['initialRadius','Kezdősugár',1,30,1,7,'%'], ['growth','Növekedési ráta',10,200,1,96,'%'],
    ['merge','Összeolvadás',0,100,1,58,'%'], ['softness','Peremlágyság',0,100,1,74,'%'],
    ['wander','Útvonal-vándorlás',0,100,1,38,'%'], ['matterEmergence','B megjelenése',0,100,1,46,'%'],
    ['overlap','Átfedés',0,100,1,42,'%'], ['easing','Lágyság',1,5,.1,2.3,''],
  ],
  'liquid-remap': [
    ['duration','Időtartam',300,3000,10,980,'ms'], ['colorStart','Színváltás kezdete',0,60,1,12,'%'],
    ['geometryStart','Geometriaváltás kezdete',0,60,1,28,'%'], ['warpScale','Warp skála',20,200,1,108,'%'],
    ['warpStrength','Warp erősség',0,100,1,46,'%'], ['flowSpeed','Áramlási sebesség',0,100,1,24,'%'],
    ['softness','Peremlágyság',0,100,1,68,'%'], ['overlap','Átfedés',0,100,1,52,'%'],
    ['easing','Lágyság',1,5,.1,2.2,''],
  ],
};
```

- [ ] **Step 2: Witness model RED, then implement it**

Run the missing-module test. Implement frozen schemas, normalization, seeded 2D noise, and three distinct samplers. Force exact endpoints before mode dispatch:

```js
function sampleChannels(mode, x, y, progress, input) {
  const p = clamp01(Number(progress));
  if (p <= 0) return { base: 0, matter: 0 };
  if (p >= 1) return { base: 1, matter: 1 };
  const id = normalizeMode(mode);
  const settings = normalizedSettings(id, input);
  return samplers[id](clamp01(Number(x)), clamp01(Number(y)), p, settings);
}
```

`pigment-spread` uses the minimum warped distance to several seeded sources, with matter progress delayed by `matterDelay`. `island-takeover` grows and merges seeded circles with independently wandered centers. `liquid-remap` offsets local color/geometry progress with low-frequency 2D noise and separate start controls. `buildDescriptor` returns normalized mode/settings, duration, easing string, target state, and reduced-motion flag; reduced motion fixes duration at 160 ms.

Use these exact progress constructions, with `ease(p,e) = 1 - Math.pow(1 - clamp01(p), e)` and `softReveal(distance,radius,softness) = 1 - smoothstep(radius-softness,radius+softness,distance)`:

```js
function pigmentChannels(x, y, progress, s) {
  const p = ease(progress, s.easing);
  let distance = Infinity;
  for (let index = 0; index < s.seedCount; index += 1) {
    const spread = s.sourceSpread / 100;
    const cx = .5 + ((hash2(index, 1, 401) - .5) * spread);
    const cy = .5 + ((hash2(index, 2, 401) - .5) * spread);
    const warp = (noise2(x * 3.2, y * 3.2, index + 17) - .5) * s.warp / 180;
    distance = Math.min(distance, Math.hypot(x - cx, y - cy) + warp);
  }
  const softness = .01 + (s.softness / 360);
  const radius = p * (.72 + s.diffusion / 90) * (1 + s.overlap / 240);
  const delay = s.matterDelay / 100;
  const matterP = clamp01((progress - delay) / Math.max(.001, 1 - delay));
  return {
    base: softReveal(distance, radius, softness),
    matter: softReveal(distance, matterP * radius, softness),
  };
}

function islandChannels(x, y, progress, s) {
  const p = ease(progress, s.easing);
  let sum = 0;
  for (let index = 0; index < s.seedCount; index += 1) {
    const angle = hash2(index, 4, 733) * Math.PI * 2;
    const wander = s.wander / 100;
    const cx = hash2(index, 5, 733) + Math.cos(angle + p * 3) * .12 * wander;
    const cy = hash2(index, 6, 733) + Math.sin(angle - p * 2.4) * .10 * wander;
    const radius = (s.initialRadius / 100) + (p * s.growth / 190);
    sum += gaussian(x - cx, y - cy, radius, radius);
  }
  const merged = 1 - Math.exp(-sum * (.7 + s.merge / 45));
  const soft = .02 + s.softness / 250;
  const base = smoothstep(.18 - soft, .18 + soft, merged);
  const matterP = clamp01((progress - ((100 - s.matterEmergence) / 180)) * (1 + s.overlap / 100));
  return { base, matter: base * ease(matterP, s.easing) };
}

function liquidChannels(x, y, progress, s) {
  const scale = .8 + (s.warpScale / 80);
  const flow = progress * s.flowSpeed / 65;
  const noise = noise2((x * scale) + flow, (y * scale) - flow * .73, 997) - .5;
  const offset = noise * s.warpStrength / 115;
  const width = .02 + (s.softness / 220);
  const local = clamp01(progress + offset + ((s.overlap - 50) / 220));
  const colorP = clamp01((local - s.colorStart / 100) / Math.max(.01, 1 - s.colorStart / 100));
  const geometryP = clamp01((local - s.geometryStart / 100) / Math.max(.01, 1 - s.geometryStart / 100));
  return {
    base: smoothstep(0 - width, 1 + width, ease(colorP, s.easing)),
    matter: smoothstep(0 - width, 1 + width, ease(geometryP, s.easing)),
  };
}
```

- [ ] **Step 3: Write failing compositor tests**

Use three 2×2 frames with solid RGB values: source `[10,20,30]`, Portal base `[110,120,130]`, and Portal target `[210,220,230]`. Assert progress 0 equals source byte-for-byte, progress 1 equals target byte-for-byte, all intermediate channels are bounded by source/target extrema, alpha stays 255, reverse input frames swaps endpoints, mismatched dimensions return `null`, and output is deterministic.

- [ ] **Step 4: Implement the compositor**

For each pixel, sample `{base,matter}` and perform:

```js
const stage = mixPixel(source, portalBase, channels.base);
const output = mixPixel(stage, portalTarget, channels.matter);
```

Validate `{width,height,data}` and equal dimensions before allocating output. Never mutate input arrays.

- [ ] **Step 5: Run and commit the transition core**

Run both transition tests and syntax checks. Expected: `Portal transition checks passed` and `Portal transition renderer checks passed`. Commit only these four new files with `git commit -m "feat: add portal background transition core"`.

---

### Task 4: Reversible animation-like rAF player

**Files:**

- Create: `docs/prototypes/color_lab_portal_transition_player.js`
- Create: `docs/prototypes/color_lab_portal_transition_player_test.js`

**Interfaces:**

- Produces `PortalTransitionPlayer.createPlayback(options)`.
- Playback exposes Web-Animation-compatible `reverse()`, `cancel()`, `finished`, `playState`, `currentProgress`, and `currentTime` so it can join `activeAnimations`.
- Options are `{ duration, startProgress, direction, now, requestFrame, cancelFrame, onFrame }`.

- [ ] **Step 1: Write a deterministic fake-clock RED test**

Create a scheduler that stores callbacks and advances timestamps manually. Assert a 1000 ms forward playback emits 0, .5, 1 and resolves at 1; reversing at .6 continues smoothly to .3 then 0; starting at 1 with direction -1 reaches 0; `cancel()` stops queued frames and rejects `finished` with an `AbortError`; duration 0 commits the selected boundary synchronously.

- [ ] **Step 2: Implement continuous reversal**

Use this tick relationship:

```js
const delta = Math.max(0, timestamp - lastTimestamp) / duration;
progress = clamp01(progress + (delta * direction));
onFrame(progress);
if ((direction > 0 && progress >= 1) || (direction < 0 && progress <= 0)) finish();
else frameId = requestFrame(tick);
```

`reverse()` flips only `direction`, resets `lastTimestamp` from `now()`, and schedules a frame if needed; it never resets progress. `cancel()` calls `cancelFrame`, marks `playState='idle'`, and rejects once. Freeze the returned API except for getter-backed state.

- [ ] **Step 3: Run and commit**

Run the player test and syntax check. Expected: `Portal transition player checks passed`. Commit the two isolated files with `git commit -m "feat: add reversible portal transition player"`.

---

### Task 5: Remove the implicit foreground color accent

**Files:**

- Modify: `docs/prototypes/color_lab_portal_message.js:120-330`
- Modify: `docs/prototypes/color_lab_portal_message_test.js:35-108`

**Interfaces:**

- `PortalMessageMorph.buildTransition` continues to produce content `outgoing`, `incoming`, `duration`, `easing`, `direction`, and mode metadata.
- It no longer produces colored accent frames or an accent origin. Local color reaction belongs only to `PortalMessageBackground`.

- [ ] **Step 1: Add a failing content-only assertion**

For every foreground mode, add:

```js
const descriptor = morph.buildTransition(mode, settings, 'message', false);
assert(!Object.hasOwn(descriptor, 'accent'), `${mode} must not own a color accent`);
assert(!Object.hasOwn(descriptor, 'accentOrigin'), `${mode} must not own an accent origin`);
assert(!/rgba\(|#[0-9a-f]{3,8}/i.test(JSON.stringify(descriptor)));
```

Run `node docs/prototypes/color_lab_portal_message_test.js`.

Expected: FAIL because current descriptors contain `accent` and some contain `accentOrigin`.

- [ ] **Step 2: Remove accent construction from all four descriptors**

Delete each `accent` array and `accentOrigin` return property. Keep text shadow values used directly on glyphs, because they are part of the foreground descriptor; forbid only separate colored backdrop output. Ensure reduced-motion descriptors remain opacity-only.

- [ ] **Step 3: Run protected pure regressions**

```bash
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_portal_background_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node --check docs/prototypes/color_lab_portal_message.js
```

Expected: all three pass messages and syntax exit 0. Do not commit these already shared/untracked historical files yet; record the checkpoint with `git diff --check`.

---

### Task 6: Full-header layer DOM and three independent switches

**Files:**

- Modify: `docs/prototypes/color_lab.html:513-1135,10495-10660,12957-14185,14364`
- Modify: `docs/prototypes/color_lab_static_test.js:2100-2490,5120-5140`
- Modify: `docs/prototypes/color_lab_portal_background.js:250-402`
- Modify: `docs/prototypes/color_lab_portal_background_test.js:1-268`

**Interfaces:**

- DOM layer order becomes base canvas → settled Portal field canvas → transition canvas → text-background response → padded text-only viewport.
- Generic buttons use `data-portal-layer-toggle="text|text-background|full-background"` and `aria-pressed`.
- State flags are `textMorphEnabled`, `textBackgroundEnabled`, and `fullBackgroundMorphEnabled`.
- Local response mode remains stored as `backgroundMode`; its explicit disabled state is the independent switch, not a misleading residual foreground accent.

- [ ] **Step 1: Add failing static contracts for layer ancestry and switches**

Add assertions that the header contains, in this order:

```text
data-mind-portal-idle-canvas
data-portal-message-field-canvas
data-portal-background-transition-canvas
data-portal-background-response
data-portal-message-viewport
```

Assert the viewport substring contains only the Balance/message panels, contains no canvas/response/accent node, and the whole HTML contains no `data-portal-message-accent` or `.mind-portal-message-accent`. Assert three toggle buttons exist with initial `aria-pressed="true"`. Assert state initialization contains the three boolean flags and one generic `setPortalLayerEnabled` handler.

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: FAIL at the new full-header layer/switch assertion.

- [ ] **Step 2: Rewrite the header markup and CSS paint order**

Replace the visual portion of the test header with:

```html
<canvas class="common-mind-portal-idle-canvas" data-mind-portal-idle-canvas aria-hidden="true"></canvas>
<canvas class="mind-portal-message-field-canvas" data-portal-message-field-canvas aria-hidden="true"></canvas>
<canvas class="mind-portal-background-transition-canvas" data-portal-background-transition-canvas aria-hidden="true"></canvas>
<span class="mind-portal-message-background-response" data-portal-background-response data-portal-background-mode="none" aria-hidden="true"></span>
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
</div>
```

Both canvases and the response use `position:absolute; inset:0; width:100%; height:100%; border-radius:inherit; z-index:0; pointer-events:none; contain:paint`. The transition canvas follows the field canvas in DOM paint order. Delete every accent selector. Keep `.mind-portal-content-viewport { inset:16px 17px; z-index:3; overflow:hidden; }` only for text.

- [ ] **Step 3: Add compact accessible toggle UI**

Place one button in each relevant panel title:

```html
<button class="mind-portal-layer-toggle" type="button" data-portal-layer-toggle="text" aria-pressed="true">Be</button>
<button class="mind-portal-layer-toggle" type="button" data-portal-layer-toggle="text-background" aria-pressed="true">Be</button>
<button class="mind-portal-layer-toggle" type="button" data-portal-layer-toggle="full-background" aria-pressed="true">Be</button>
```

Use the matching panel's existing title label plus toggle; do not create a taller wrapper. Style 38×24 px pills with `touch-action:manipulation`; `[aria-pressed="false"]` reads `Ki` through text synchronization and uses neutral gray, while true uses the current purple/pink accent.

- [ ] **Step 4: Make the local text reaction independent and truly clearable**

Initialize:

```js
textMorphEnabled: true,
textBackgroundEnabled: true,
fullBackgroundMorphEnabled: true,
backgroundMode: 'energy-compression',
```

Change `buildPortalBackgroundDescriptor` to pass `'none'` whenever `textBackgroundEnabled` is false. `clearPortalBackgroundOverlay` remains the sole zero-state cleanup and must remove style plus set `data-portal-background-mode="none"`.

Keep `none` in the pure module as its deterministic fallback, but remove it from the visible text-background dropdown. Make `energy-compression` the selected default and render its controls immediately. Update the previous six-option static assertion to require five visible animated choices plus the independent switch.

Keep the existing `seam-flare` ID/label for control compatibility, but remove financial split ownership: its configured center is always the text focus at 50%/50%, and its CSS combines a bounded radial mask with the luminous membrane. Remove `moneyFlowSeamPercent` use from response construction and replace its test with assertions that income 0, 50, and 100 produce identical text-centered configuration.

- [ ] **Step 5: Implement generic switch behavior**

Add:

```js
const portalLayerFlags = Object.freeze({
  text: 'textMorphEnabled',
  'text-background': 'textBackgroundEnabled',
  'full-background': 'fullBackgroundMorphEnabled',
});

function setPortalLayerEnabled(wrap, layer, enabled) {
  const state = ensurePortalMessageMorphState(wrap);
  const flag = portalLayerFlags[layer];
  if (!flag) return;
  state[flag] = enabled === true;
  const button = wrap.querySelector(`[data-portal-layer-toggle="${layer}"]`);
  button?.setAttribute('aria-pressed', state[flag] ? 'true' : 'false');
  if (button) button.textContent = state[flag] ? 'Be' : 'Ki';
  if (layer === 'text-background' && !state[flag]) {
    cancelPortalBackgroundPreview(state);
    clearPortalBackgroundOverlay(wrap.querySelector('[data-portal-background-response]'));
  }
  if (!state.activeAnimations.length) return;
  const roles = layer === 'text'
    ? new Set(['outgoing', 'incoming'])
    : new Set([layer]);
  state.activeAnimations.forEach(({ role, animation }) => {
    if (roles.has(role)) animation.cancel();
  });
  if (layer === 'text') applyPortalContentEndpoint(wrap, state.targetState);
  if (layer === 'text-background') clearPortalBackgroundOverlay(
    wrap.querySelector('[data-portal-background-response]'),
  );
  if (layer === 'full-background') applyPortalBackgroundEndpoint(wrap, state, state.targetState);
}
```

For this task's working checkpoint, define `applyPortalBackgroundEndpoint(wrap,state,targetState)` as a thin call to the existing `applyPortalMessageColorRestState(wrap,state,targetState)`. Task 7 replaces its internals with the new settled-field ownership without changing callers.

Bind all three buttons once. `applyPortalContentEndpoint` sets only header content-state and panel `aria-hidden`; it does not set the final controller state. Turning a layer on while settled changes no endpoint.

- [ ] **Step 6: Make delivery build animations conditionally**

In `runPortalMessageMorph`, remove accent lookup and animation. Push outgoing/incoming only when `textMorphEnabled`; otherwise call `applyPortalContentEndpoint` before starting remaining layers. Build/push the response only when `textBackgroundEnabled`. Use role `text-background`. If no layer creates an animation, commit immediately. Keep `updatePortalMessageTrigger` and the shared reverse loop.

- [ ] **Step 7: Run the current regressions**

```bash
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_portal_background_test.js
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: all pass. Run `git diff --check`; do not stage shared files.

---

### Task 7: Integrate the new settled Portal endpoint and controls

**Files:**

- Modify: `docs/prototypes/color_lab.html:800-1135,10610-10660,10814-10825,12957-14185,14590-14605`
- Modify: `docs/prototypes/color_lab_static_test.js:2220-2425,5120-5140`

**Interfaces:**

- HTML loads `PortalMessageField` and `PortalMessageFieldRenderer` after the existing Portal palette model.
- Runtime state names use `messageFieldMode`, `messageFieldCenter`, `messageFieldWindow`, `messageFieldSettingsByMode`, and `messageFieldPhaseByMode`.
- The existing white/pink/purple palette controls remain, but A and B are material colors instead of left/right anchors.

- [ ] **Step 1: Replace old selector/source assertions with failing new contracts**

Require exact `Portal végállapot` option order:

```html
<option value="solid-a">Nincs dinamikus effekt</option>
<option value="static-matter">Statikus köd/szigetek</option>
<option value="wandering-mist" selected>Vándorló köd</option>
<option value="living-archipelago">Élő szigetvilág</option>
<option value="forming-clouds">Keletkező energiafelhők</option>
```

Assert the message menu contains none of `dual-tide`, `magnetic-membrane`, `breathing-lens`, `cellular-field`, while the separate Balance energy menu still contains them. Assert the new field scripts load and runtime calls `PortalMessageFieldRenderer.renderFrame` and `PortalMessageField.advancePhase` without calling `MindPortalEnergy.advancePhase` inside the field-runtime block.

- [ ] **Step 2: Update the panel without increasing its footprint unnecessarily**

Rename the existing message-color panel heading to `Portal háttér-morph`. Its first compact select row is labeled `Portal végállapot` and uses the exact options above. Keep the palette row visible for all modes. Hide only the numbered field-control viewport for `solid-a`; show it for `static-matter` and all dynamic modes. Preserve the deferred window input behavior and window-opacity separation.

- [ ] **Step 3: Replace message-color state and renderer calls**

Initialize the new settings/phase maps from `PortalMessageField.modeOrder.slice(1)` and `animatedModes`. Use defaults:

```js
messageFieldMode: PortalMessageField.defaults.mode,
messageFieldCenter: PortalMessageField.defaults.center,
messageFieldWindow: PortalMessageField.defaults.windowSize,
```

Rewrite palette/control functions to consume `PortalMessageField`. `drawPortalMessageFieldFrame` obtains `profile = PortalMessageField.renderProfile(mode)`, advances phase only for animated modes, renders at `profile.renderScale`, throttles by `profile.frameMs`, and uses the dedicated field canvas/context. Use one rAF and the existing IntersectionObserver/reduced-motion lifecycle.

- [ ] **Step 4: Implement deterministic endpoint ownership**

Add this single endpoint function and route commit, no-canvas fallback, opacity changes, and immediate-switch behavior through it:

```js
function applyPortalBackgroundEndpoint(wrap, state, targetState) {
  const header = wrap.querySelector('.mind-portal-test-header');
  const idle = wrap.querySelector('[data-mind-portal-idle-canvas]');
  const fieldCanvas = wrap.querySelector('[data-portal-message-field-canvas]');
  const alpha = getMindPortalWindowOpacity(header);
  const message = targetState === 'message';
  header.style.setProperty('--mind-portal-base-visual-opacity', message ? '0' : String(alpha));
  if (idle) idle.style.opacity = message ? '0' : getMindPortalBaseCanvasOpacity(header);
  if (fieldCanvas) fieldCanvas.style.opacity = message ? String(alpha) : '0';
  header.dataset.portalMessageFieldVisible = message ? 'true' : 'false';
  if (message) {
    invalidatePortalMessageField(wrap);
    schedulePortalMessageFieldFrame(wrap);
  } else {
    clearPortalMessageFieldCanvas(wrap, state);
  }
}
```

If canvas is unavailable, set `--portal-message-solid-a` from the sampled palette and show a full-header solid-A CSS layer at the Portal endpoint. Never fall back to a left/right gradient.

- [ ] **Step 5: Preserve settled field-only preview**

Adapt the existing 180 ms ghost-canvas preview: snapshot the outgoing field, render the new field, crossfade only the two field canvases, and never call `runPortalMessageMorph`. Palette/field mode/field control changes during an active delivery are deferred until endpoint commit; settled changes cancel and replace the prior preview.

- [ ] **Step 6: Run field integration verification**

Run static, old portal regressions, both new field suites, syntax checks, and `git diff --check`. Expected: all pass, exact new dropdown order, no old message-field IDs, unchanged Balance IDs, and no touch source differences. Do not stage shared files.

---

### Task 8: Integrate selectable full-header Balance→Portal transformations

**Files:**

- Modify: `docs/prototypes/color_lab.html:513-545,820-1135,10615-10685,10814-10830,12957-14220,14590-14610`
- Modify: `docs/prototypes/color_lab_static_test.js:2160-2490,5120-5145`

**Interfaces:**

- State adds `backgroundTransitionMode`, `backgroundTransitionSettingsByMode`, canvas/context, active playback, and preview token.
- Runtime helpers are `capturePortalBalanceFrame`, `capturePortalTargetFrames`, `drawPortalTransitionProgress`, `startPortalBackgroundTransition`, `clearPortalBackgroundTransition`, and `renderPortalTransitionControls`.
- One custom playback enters `activeAnimations` with role `full-background`.

- [ ] **Step 1: Add failing transition UI/runtime assertions**

Require a second select inside the full-background panel with exact order `pigment-spread`, `island-takeover`, `liquid-remap`, followed by active-only numbered slider/manual controls and reset. Require script order: field renderer → transition model → transition renderer → transition player → inline runtime. Require transition canvas full-header ancestry and runtime use of `PortalTransitionPlayer.createPlayback` plus role `full-background`.

- [ ] **Step 2: Add transition controls**

Render `PortalMessageTransition.controlsForMode(activeMode)` using the established numbered row pattern. Range updates are immediate. Manual inputs allow a temporarily empty value and commit/clamp only on Enter, change, or blur. Preserve settings per mode; reset only the active transition. Mode changes during delivery are stored and take effect on the next toggle.

- [ ] **Step 3: Capture a Balance frame from authoritative state**

Create an opaque RGBA frame at the transition render size. Read `ensureMindPortalEnergyState(header)`, computed `--mind-portal-color-a/b`, signature, ratio, current energy mode/settings/phase. For Money-flow static, call `MindPortalEnergy.sampleMoneyFlowColor(palette, income, {coordinate:nx,light:0,chroma:0})`. For animated Balance modes call `sampleMoneyFlowField`; for other modes call `sampleField` and `sampleColor`. Exclude touch ripples and pigment trails because those remain a separate live layer above the transition.

- [ ] **Step 4: Capture Portal A and live target frames**

Render `portalBaseFrame` with `solid-a` and `portalTargetFrame` with the selected message field at its current phase, both using the same width/height and sampled Portal A/B. Do not mutate the live field state during capture.

- [ ] **Step 5: Start the custom full-background animation**

Implement:

```js
function startPortalBackgroundTransition(wrap, state, targetState) {
  if (!state.fullBackgroundMorphEnabled) {
    applyPortalBackgroundEndpoint(wrap, state, targetState);
    return null;
  }
  const descriptor = PortalMessageTransition.buildDescriptor(
    state.backgroundTransitionMode,
    state.backgroundTransitionSettingsByMode[state.backgroundTransitionMode],
    targetState,
    state.reducedMotionQuery?.matches === true,
  );
  const frames = capturePortalTransitionFrames(wrap, state);
  const forward = targetState === 'message';
  hidePortalEndpointSources(wrap);
  return PortalTransitionPlayer.createPlayback({
    duration: descriptor.duration,
    startProgress: forward ? 0 : 1,
    direction: forward ? 1 : -1,
    onFrame(progress) {
      drawPortalTransitionProgress(wrap, state, frames, descriptor, progress);
    },
  });
}
```

`drawPortalTransitionProgress` calls the transition renderer, writes one `ImageData`, and keeps only the transition canvas at current window opacity. At completion, `commitPortalMessageState` clears the transition canvas and calls `applyPortalBackgroundEndpoint` for the settled target.

- [ ] **Step 6: Join shared reversal without replacing the array**

Push `{role:'full-background', animation:playback}` into the same `activeAnimations` array. The existing opposite-target path calls `.reverse()` on WAAPI and custom entries. Do not reconstruct frames during in-flight reversal. Starting from a settled message captures the current live Portal frame before playing 1→0.

- [ ] **Step 7: Implement full-background off during playback**

When its switch turns off, cancel only role `full-background`, clear the transition canvas, and call `applyPortalBackgroundEndpoint(wrap,state,state.targetState)`. Leave foreground and text-background animations running. The canceled `finished` rejection is already consumed by the group's `.catch`; final commit remains token guarded.

- [ ] **Step 8: Run transition integration verification**

Run all pure transition/field tests, static test, old portal tests, and syntax checks. Expected: all pass; static source proves custom and WAAPI animations share reversal, disabled background snaps to the distinct endpoint, and no visual layer is nested in the content viewport. Run `git diff --check`; do not stage shared files.

---

### Task 9: Fallbacks, interruption cleanup, scrolling, and protected behavior

**Files:**

- Modify: `docs/prototypes/color_lab.html:12957-14610`
- Modify: `docs/prototypes/color_lab_static_test.js:2290-2490,5120-5160`

- [ ] **Step 1: Add failing switch/reversal/fallback source contracts**

Assert: each switch cancels only its own roles; text off calls `applyPortalContentEndpoint`; text-background off calls `clearPortalBackgroundOverlay`; full-background off calls endpoint switch; reduced motion passes 160 ms descriptors; no canvas uses solid A; no WAAPI commits content/local endpoint without leaving both panels visible; one `IntersectionObserver` and one rAF own the live Portal field; transition buffers are reused.

- [ ] **Step 2: Harden commit and cancellation order**

At every commit: cancel settled previews, cancel/copy then clear active animations, clear transition playback/canvas, set `currentState/targetState`, apply content endpoint, apply local response rest only when enabled/message, and apply full background endpoint. Increment the animation token before starting and before forced cancellation so stale promises cannot recommit an obsolete target.

- [ ] **Step 3: Implement reduced-motion and capability fallbacks**

Reduced motion uses opacity-only foreground/local response and a 160 ms full endpoint crossfade; render one deterministic Portal field frame. If Canvas 2D is absent, use full-header solid A. If WAAPI is absent, content and local reaction commit immediately; the custom background player may still run when Canvas/rAF exist. If rAF is absent, all three layers commit deterministic endpoints immediately.

Route the existing `Ablak opacity` control through one `syncPortalVisibleBackgroundOpacity(wrap,alpha)` helper. While Balance is settled it updates only the Balance pseudo/canvas; while a Portal message is settled it updates only the message field; while a full-background transition is active it updates only the transition canvas and keeps both endpoint sources hidden. It must not alter content, local text reaction, touch opacity, or transition progress.

- [ ] **Step 4: Extend scroll routing to both new control viewports**

Add `data-portal-message-field-controls-scroll` and `data-portal-transition-controls-scroll` to the existing selector. Keep the vertical-on-range gesture arbitration unchanged. Confirm only the header has `touch-action:none`; panels, selects, toggles, ranges, number inputs, reset, and trigger use normal pan/tap behavior.

- [ ] **Step 5: Protect the touch implementation**

Keep the current pointer handlers and `.common-mind-portal-layer`, trail-dot, ripple, and release CSS byte-identical. Run the existing source/hash assertions. If a layer-order adjustment is necessary, change only z-index/DOM placement outside the protected block.

- [ ] **Step 6: Run the full automated suite**

```bash
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node docs/prototypes/color_lab_portal_message_test.js
node docs/prototypes/color_lab_portal_background_test.js
node docs/prototypes/color_lab_portal_color_test.js
node docs/prototypes/color_lab_portal_color_renderer_test.js
node docs/prototypes/color_lab_portal_message_field_test.js
node docs/prototypes/color_lab_portal_message_field_renderer_test.js
node docs/prototypes/color_lab_portal_transition_test.js
node docs/prototypes/color_lab_portal_transition_renderer_test.js
node docs/prototypes/color_lab_portal_transition_player_test.js
```

Expected: eleven pass messages. Run `node --check` on every `color_lab_portal_*.js`; all exit 0.

---

### Task 10: Fresh verification, Android evidence, and checklist update

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md:373-380, end evidence section`
- Modify: this plan's checkboxes as each witnessed step completes.

- [ ] **Step 1: Parse the inline script and check whitespace**

Run:

```bash
node - <<'NODE'
const fs = require('fs');
const html = fs.readFileSync('docs/prototypes/color_lab.html', 'utf8');
const scripts = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi)]
  .map((match) => match[1]);
scripts.forEach((source) => new Function(source));
if (scripts.length !== 1) throw new Error(`Expected 1 inline script, got ${scripts.length}`);
console.log(`Inline scripts parse: ${scripts.length}`);
NODE
git diff --check
```

Expected: `Inline scripts parse: 1`; diff check exits 0.

- [ ] **Step 2: Run HTTP source smoke**

Start `python3 -m http.server 8765 --directory docs/prototypes` in a PTY. In a second shell run this exact loop:

```bash
for file in color_lab.html color_lab_portal_energy.js color_lab_portal_message.js color_lab_portal_background.js color_lab_portal_color.js color_lab_portal_color_renderer.js color_lab_portal_message_field.js color_lab_portal_message_field_renderer.js color_lab_portal_transition.js color_lab_portal_transition_renderer.js color_lab_portal_transition_player.js; do
  test -n "$(curl -fsS "http://127.0.0.1:8765/$file")" || exit 1
done
echo 'HTTP portal redesign source checks passed'
```

Expected: `HTTP portal redesign source checks passed`. Stop the server afterward.

- [ ] **Step 3: Re-run every automated test from Task 9**

Expected: all eleven suites pass again after documentation changes. Do not use an earlier run as evidence.

- [ ] **Step 4: Inspect the Android prototype**

Open the served prototype on the phone and capture screenshots in `/storage/emulated/0/Pictures/Screenshots` for:

- all five settled Portal endpoint modes;
- all three Balance→Portal transitions in both directions;
- text-only, text-background-only, full-background-only, all-on, and all-off combinations;
- text-background off with zero residual pigment;
- full-header edge coverage without 16/17 px static strips;
- rapid mid-transition reversal;
- controls scrolling from ranges and manual input editing;
- unchanged touch down, trail, drag, release fade, and interaction opacity.

Open the latest files directly and compare them with `COLOR-LAB-333`–`340`. If a visual fails, leave its requirement `PARTIAL` or `NOT DONE`, add the evidence, and return to the responsible task.

- [ ] **Step 5: Update checklist statuses honestly**

For each `COLOR-LAB-333`–`340`, record exact automated commands and screenshot filenames. Set `DONE` only when its automated and Android acceptance conditions both pass. Use `PARTIAL` when implementation/tests pass but required mobile visual evidence is incomplete. Keep superseded `COLOR-LAB-328`, `330`, and `332` as historical `NOT DONE` entries and describe their replacement rather than reviving them.

- [ ] **Step 6: Final shared-file safety review**

Run `git status --short`, `git diff --stat`, and `git diff --check`. Confirm no Flutter file, Balance mode implementation, touch implementation, unrelated screen, or user-owned file was overwritten. Do not stage the shared dirty HTML, static test, or checklist. Report isolated module commits separately from shared working-tree changes.

---

## Execution handoff

The user already selected inline execution and explicitly declined subagents. Use the `executing-plans` skill, execute the tasks in order with review checkpoints after Tasks 4, 7, and 9, and keep commentary updates under 60 seconds while tools are running.
