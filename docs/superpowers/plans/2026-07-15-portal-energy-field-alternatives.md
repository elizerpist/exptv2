# Portal Energy Field Alternatives Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken rotation-coupled portal experiment with a color-faithful static A/B reference and four independently controllable animated energy-field alternatives while preserving the accepted touch effect.

**Architecture:** Move deterministic field math and complete control schemas into a browser/Node-compatible pure JavaScript module. Keep the existing touch bloom/trail layer in `color_lab.html`, render exactly one selected idle field through one canvas, and generate only the active mode's numbered controls from schema data. Static mode bypasses the canvas so the CSS A/B gradient is the authoritative reference.

**Tech Stack:** HTML/CSS, browser Canvas 2D, dependency-free JavaScript, Node `assert` regression tests, local HTTP smoke verification.

## Global Constraints

- Implement only the standalone portal test header in the HTML color lab; do not migrate this work into Flutter/Dart.
- Preserve the production D-row Mind header's existing `mindHeaderValueWater`, `setMindHeaderGradientStops`, and mode-scale behavior; the rebuild targets only `.mind-portal-test-header`.
- Preserve the existing touch bloom, trail dots, pointer handlers, release fade, colors, size, and interaction-opacity behavior.
- Do not reintroduce rotation, side-view level bands, legacy mesh/plumes, gray/white veils, or flame-like repeated streaks.
- Page load begins in exact static A/B mode with no idle canvas painting.
- The last local Traffic, Limit, or Cool slider moved selects exact portal endpoint colors A and B using a fixed `center ± 14` sample window.
- Show only the active animated mode's controls; every setting has a synchronized range and numeric input.
- The animation-control viewport scrolls internally on vertical slider gestures and keeps horizontal range adjustment.
- Keep checklist items `COLOR-LAB-286` through `COLOR-LAB-292` honest until their acceptance evidence exists.

---

## File map

- Create `docs/prototypes/color_lab_portal_energy.js`: pure schemas, defaults, field samplers, color interpolation, phase advancement, and CommonJS/browser exports.
- Create `docs/prototypes/color_lab_portal_energy_test.js`: deterministic unit tests for all field algorithms, bounds, controls, and color fidelity.
- Modify `docs/prototypes/color_lab.html`: static A/B DOM/CSS, mode selector, generated controls, canvas lifecycle, scroll routing, and module integration.
- Modify `docs/prototypes/color_lab_static_test.js`: replace obsolete rotation/water/level assertions with the new portal contract while retaining touch regressions.
- Modify `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`: record RED/GREEN and visual/runtime evidence and update statuses.

### Task 1: Deterministic energy-field module

**Files:**
- Create: `docs/prototypes/color_lab_portal_energy_test.js`
- Create: `docs/prototypes/color_lab_portal_energy.js`

**Interfaces:**
- Produces: `MindPortalEnergy.modeOrder`, `modeLabels`, `commonControls`, `modeControls`, `createModeSettings(mode)`, `sampleField(mode, x, y, phase, settings)`, `sampleColor(a, b, sample)`, `advancePhase(phase, elapsedSeconds, speed)`, and `clamp01(value)`.
- Browser export: `globalThis.MindPortalEnergy`.
- Node export: `module.exports = MindPortalEnergy`.

- [x] **Step 1: Write the failing pure-engine test**

Create `docs/prototypes/color_lab_portal_energy_test.js` with these assertions:

```js
const assert = require('assert');
const energy = require('./color_lab_portal_energy.js');

assert.deepStrictEqual(energy.modeOrder, [
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
]);

for (const mode of energy.modeOrder.slice(1)) {
  const settings = energy.createModeSettings(mode);
  const schema = [...energy.commonControls, ...energy.modeControls[mode]];
  assert(schema.length >= 28, `${mode} must expose maximum-detail controls`);
  assert.strictEqual(new Set(schema.map(({ key }) => key)).size, schema.length);
  for (const meta of schema) {
    assert(Number.isFinite(settings[meta.key]), `${mode}.${meta.key} needs a default`);
    assert(settings[meta.key] >= meta.min && settings[meta.key] <= meta.max);
  }
}

for (const mode of energy.modeOrder) {
  const settings = energy.createModeSettings(mode);
  for (const x of [0, 0.17, 0.5, 0.83, 1]) {
    for (const y of [0, 0.5, 1]) {
      for (const phase of [0, 3.25, 17.5]) {
        const sample = energy.sampleField(mode, x, y, phase, settings);
        assert(Number.isFinite(sample.mix) && sample.mix >= 0 && sample.mix <= 1);
        assert(Number.isFinite(sample.light) && sample.light >= -0.25 && sample.light <= 0.25);
      }
    }
  }
}

for (const mode of energy.modeOrder.slice(1)) {
  const settings = energy.createModeSettings(mode);
  settings.strength = 0;
  for (const x of [0, 0.25, 0.5, 0.75, 1]) {
    assert.strictEqual(energy.sampleField(mode, x, 0.37, 9, settings).mix, x);
  }
}

const a = { r: 255, g: 59, b: 79 };
const b = { r: 53, g: 199, b: 110 };
assert.deepStrictEqual(energy.sampleColor(a, b, { mix: 0, light: 0 }), a);
assert.deepStrictEqual(energy.sampleColor(a, b, { mix: 1, light: 0 }), b);
assert.strictEqual(energy.advancePhase(4, 0.5, 0), 4);
assert.strictEqual(energy.advancePhase(4, 0.5, 2), 5);

for (const mode of energy.modeOrder.slice(1)) {
  const base = energy.createModeSettings(mode);
  const fixtures = [
    [0.19, 0.23, 2.7],
    [0.37, 0.61, 7.3],
    [0.79, 0.82, 13.1],
    [0.52, 0.14, 21.7],
  ];
  const baseSamples = fixtures.map(([x, y, phase]) => energy.sampleField(mode, x, y, phase, base));
  for (const meta of [...energy.commonControls, ...energy.modeControls[mode]]) {
    if (['speed', 'renderScale', 'frameMs'].includes(meta.key)) continue;
    const changed = { ...base, [meta.key]: base[meta.key] === meta.max ? meta.min : meta.max };
    const probes = fixtures.map(([x, y, phase]) => energy.sampleField(mode, x, y, phase, changed));
    assert(
      probes.some((probe, index) =>
        Math.abs(probe.mix - baseSamples[index].mix) > 1e-6 ||
        Math.abs(probe.light - baseSamples[index].light) > 1e-6),
      `${mode}.${meta.key} must measurably affect the field`,
    );
  }
}

console.log('Portal energy field checks passed');
```

- [x] **Step 2: Run the test and verify RED**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: FAIL with `Cannot find module './color_lab_portal_energy.js'`.

- [x] **Step 3: Implement the dependency-free module**

Create `docs/prototypes/color_lab_portal_energy.js` as a UMD-style module. Define all metadata with the exact bounds/defaults from `docs/superpowers/specs/2026-07-15-portal-energy-field-alternatives-design.md`. Use this public skeleton and return contract:

```js
(function attachMindPortalEnergy(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.MindPortalEnergy = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildMindPortalEnergy() {
  'use strict';

  const modeOrder = ['static', 'dual-tide', 'magnetic-membrane', 'breathing-lens', 'cellular-field'];
  const modeLabels = Object.freeze({
    static: 'Statikus A/B',
    'dual-tide': 'Kettős árapály',
    'magnetic-membrane': 'Mágneses membrán',
    'breathing-lens': 'Lélegző lencse',
    'cellular-field': 'Celluláris mező',
  });

  const clamp01 = (value) => Math.max(0, Math.min(1, value));
  const lerp = (a, b, amount) => a + ((b - a) * amount);
  const smoothstep = (edge0, edge1, value) => {
    const t = clamp01((value - edge0) / Math.max(1e-6, edge1 - edge0));
    return t * t * (3 - (2 * t));
  };
  const gaussian = (dx, dy, rx, ry) => Math.exp(-(
    ((dx * dx) / Math.max(1e-6, rx * rx)) +
    ((dy * dy) / Math.max(1e-6, ry * ry))
  ));
  const hash = (x, y, seed = 0) => {
    let value = Math.imul(x | 0, 374761393)
      ^ Math.imul(y | 0, 668265263)
      ^ Math.imul(Math.round(seed * 1000), 1442695041);
    value = Math.imul(value ^ (value >>> 13), 1274126177);
    value ^= value >>> 16;
    return (value >>> 0) / 4294967295;
  };
  const valueNoise = (x, y, seed = 0) => {
    const xi = Math.floor(x);
    const yi = Math.floor(y);
    const tx = smoothstep(0, 1, x - xi);
    const ty = smoothstep(0, 1, y - yi);
    return lerp(
      lerp(hash(xi, yi, seed), hash(xi + 1, yi, seed), tx),
      lerp(hash(xi, yi + 1, seed), hash(xi + 1, yi + 1, seed), tx),
      ty,
    );
  };
  const fbm = (x, y, seed = 0) => {
    let value = 0;
    let amplitude = 0.58;
    let norm = 0;
    let frequency = 1;
    for (let octave = 0; octave < 3; octave += 1) {
      value += valueNoise(x * frequency, y * frequency, seed + octave * 17.3) * amplitude;
      norm += amplitude;
      frequency *= 1.93;
      amplitude *= 0.46;
    }
    return value / norm;
  };

  const commonControls = Object.freeze([
    { key: 'strength', label: 'Animáció erő', min: 0, max: 1, step: 0.01, default: 0.82 },
    { key: 'speed', label: 'Sebesség', min: 0, max: 2, step: 0.01, default: 0.42 },
    { key: 'bias', label: 'A/B alaparány', min: -0.35, max: 0.35, step: 0.01, default: 0 },
    { key: 'ratioSwing', label: 'Aránykilengés', min: 0, max: 0.35, step: 0.01, default: 0.12 },
    { key: 'ratioSpeed', label: 'Aránysebesség', min: 0, max: 1, step: 0.01, default: 0.18 },
    { key: 'fieldScale', label: 'Mezőméret', min: 0.5, max: 2, step: 0.01, default: 1 },
    { key: 'morphAmount', label: 'Morfológia', min: 0, max: 1, step: 0.01, default: 0.34 },
    { key: 'morphSpeed', label: 'Morfológia seb.', min: 0, max: 1, step: 0.01, default: 0.16 },
    { key: 'softness', label: 'Határ puhaság', min: 0.02, max: 0.48, step: 0.01, default: 0.22 },
    { key: 'detail', label: 'Felületi részlet', min: 0, max: 0.5, step: 0.01, default: 0.10 },
    { key: 'pulseAmount', label: 'Energiaimpulzus', min: 0, max: 0.35, step: 0.01, default: 0.08 },
    { key: 'pulseSpeed', label: 'Impulzus seb.', min: 0, max: 1, step: 0.01, default: 0.12 },
    { key: 'lightAmount', label: 'Fénykiemelés', min: 0, max: 0.25, step: 0.01, default: 0.05 },
    { key: 'renderScale', label: 'Render minőség', min: 0.35, max: 1, step: 0.05, default: 0.60 },
    { key: 'frameMs', label: 'Render lépés', min: 16, max: 100, step: 1, default: 42 },
  ]);
```

Add the complete mode schemas and field samplers below. These formulas keep all motion local to the selected field and never rotate shared coordinates:

```js
  const modeControls = Object.freeze({
    'dual-tide': Object.freeze([
      { key: 'wanderX', label: 'Vándorlás X', min: 0, max: 0.48, step: 0.01, default: 0.28 },
      { key: 'wanderY', label: 'Vándorlás Y', min: 0, max: 0.38, step: 0.01, default: 0.18 },
      { key: 'intrusion', label: 'Behatolás', min: 0, max: 0.65, step: 0.01, default: 0.34 },
      { key: 'separation', label: 'Mezőtávolság', min: 0, max: 0.80, step: 0.01, default: 0.42 },
      { key: 'lobeARadius', label: 'A mező sugár', min: 0.12, max: 0.75, step: 0.01, default: 0.42 },
      { key: 'lobeBRadius', label: 'B mező sugár', min: 0.12, max: 0.75, step: 0.01, default: 0.40 },
      { key: 'lobeAEllipse', label: 'A nyújtás', min: 0.50, max: 2, step: 0.01, default: 0.95 },
      { key: 'lobeBEllipse', label: 'B nyújtás', min: 0.50, max: 2, step: 0.01, default: 1.05 },
      { key: 'phaseOffset', label: 'Ellenfázis', min: 0, max: 360, step: 1, default: 180 },
      { key: 'counterFlow', label: 'Visszaáramlás', min: 0, max: 1, step: 0.01, default: 0.72 },
      { key: 'warpAmount', label: 'Mezőtorzítás', min: 0, max: 0.50, step: 0.01, default: 0.16 },
      { key: 'warpScale', label: 'Torzítás méret', min: 0.40, max: 3, step: 0.01, default: 1.10 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.14 },
    ]),
    'magnetic-membrane': Object.freeze([
      { key: 'nodeTop', label: 'Felső pólus', min: -0.50, max: 0.50, step: 0.01, default: 0.14 },
      { key: 'nodeMiddle', label: 'Középső pólus', min: -0.50, max: 0.50, step: 0.01, default: -0.08 },
      { key: 'nodeBottom', label: 'Alsó pólus', min: -0.50, max: 0.50, step: 0.01, default: 0.12 },
      { key: 'nodeWander', label: 'Pólusvándorlás', min: 0, max: 0.40, step: 0.01, default: 0.16 },
      { key: 'nodePhaseSpread', label: 'Pólusfázis', min: 0, max: 360, step: 1, default: 120 },
      { key: 'primaryAmplitude', label: 'Fő hullámerő', min: 0, max: 0.45, step: 0.01, default: 0.18 },
      { key: 'primaryWavelength', label: 'Fő hullámhossz', min: 0.35, max: 3, step: 0.01, default: 1.25 },
      { key: 'primarySpeed', label: 'Fő hullámseb.', min: 0, max: 1, step: 0.01, default: 0.16 },
      { key: 'secondaryAmplitude', label: 'Mellékhullám-erő', min: 0, max: 0.30, step: 0.01, default: 0.08 },
      { key: 'secondaryWavelength', label: 'Mellékhullámhossz', min: 0.35, max: 4, step: 0.01, default: 2.10 },
      { key: 'secondarySpeed', label: 'Mellékhullám-seb.', min: 0, max: 1, step: 0.01, default: 0.09 },
      { key: 'skew', label: 'Membrándőlés', min: -0.50, max: 0.50, step: 0.01, default: 0.08 },
      { key: 'tension', label: 'Membránfeszülés', min: 0, max: 1, step: 0.01, default: 0.62 },
      { key: 'warpAmount', label: 'Felülettorzítás', min: 0, max: 0.35, step: 0.01, default: 0.09 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.12 },
    ]),
    'breathing-lens': Object.freeze([
      { key: 'centerX', label: 'Lencseközép X', min: 0.10, max: 0.90, step: 0.01, default: 0.55 },
      { key: 'centerY', label: 'Lencseközép Y', min: 0.10, max: 0.90, step: 0.01, default: 0.48 },
      { key: 'wanderX', label: 'Középvándorlás X', min: 0, max: 0.40, step: 0.01, default: 0.18 },
      { key: 'wanderY', label: 'Középvándorlás Y', min: 0, max: 0.40, step: 0.01, default: 0.14 },
      { key: 'radiusX', label: 'Lencsesugár X', min: 0.08, max: 0.80, step: 0.01, default: 0.34 },
      { key: 'radiusY', label: 'Lencsesugár Y', min: 0.08, max: 1, step: 0.01, default: 0.46 },
      { key: 'breathX', label: 'Légzés X', min: 0, max: 0.40, step: 0.01, default: 0.16 },
      { key: 'breathY', label: 'Légzés Y', min: 0, max: 0.40, step: 0.01, default: 0.12 },
      { key: 'breathSpeed', label: 'Légzés seb.', min: 0, max: 1, step: 0.01, default: 0.18 },
      { key: 'pressure', label: 'Lencsenyomás', min: -1, max: 1, step: 0.01, default: 0.48 },
      { key: 'refraction', label: 'Mezőtörés', min: 0, max: 0.60, step: 0.01, default: 0.20 },
      { key: 'edgeFalloff', label: 'Peremlecsengés', min: 0.02, max: 0.50, step: 0.01, default: 0.18 },
      { key: 'satelliteAmount', label: 'Mellékmező erő', min: -1, max: 1, step: 0.01, default: 0.22 },
      { key: 'satelliteRadius', label: 'Mellékmező sugár', min: 0.05, max: 0.50, step: 0.01, default: 0.18 },
      { key: 'satelliteDistance', label: 'Mellékmező táv', min: 0, max: 0.75, step: 0.01, default: 0.36 },
      { key: 'satellitePhase', label: 'Mellékmező fázis', min: 0, max: 360, step: 1, default: 140 },
    ]),
    'cellular-field': Object.freeze([
      { key: 'cellCount', label: 'Cellaszám', min: 3, max: 7, step: 1, default: 5 },
      { key: 'cellSize', label: 'Cellaméret', min: 0.12, max: 0.75, step: 0.01, default: 0.36 },
      { key: 'cellVariation', label: 'Méretváltozatosság', min: 0, max: 0.70, step: 0.01, default: 0.25 },
      { key: 'advectionX', label: 'Áramlás X', min: -0.50, max: 0.50, step: 0.01, default: 0.16 },
      { key: 'advectionY', label: 'Áramlás Y', min: -0.50, max: 0.50, step: 0.01, default: 0.06 },
      { key: 'curlAmount', label: 'Örvénymező', min: 0, max: 1, step: 0.01, default: 0.35 },
      { key: 'curlScale', label: 'Örvényméret', min: 0.35, max: 3, step: 0.01, default: 1.10 },
      { key: 'mergeThreshold', label: 'Összeolvadási küszöb', min: -0.50, max: 0.50, step: 0.01, default: 0 },
      { key: 'polarityBalance', label: 'Cellapolaritás', min: -0.50, max: 0.50, step: 0.01, default: 0 },
      { key: 'cellWander', label: 'Cellavándorlás', min: 0, max: 0.50, step: 0.01, default: 0.22 },
      { key: 'cellMorph', label: 'Cellamorfológia', min: 0, max: 1, step: 0.01, default: 0.28 },
      { key: 'noiseScale', label: 'Morfológia méret', min: 0.35, max: 3, step: 0.01, default: 1.40 },
      { key: 'noiseAmount', label: 'Morfológia erő', min: 0, max: 0.50, step: 0.01, default: 0.12 },
      { key: 'noiseSpeed', label: 'Morfológia seb.', min: 0, max: 1, step: 0.01, default: 0.14 },
      { key: 'pressure', label: 'Cellanyomás', min: 0, max: 1, step: 0.01, default: 0.70 },
    ]),
  });

  function createModeSettings(mode) {
    if (mode === 'static') return { strength: 0, speed: 0, renderScale: 0.60, frameMs: 42 };
    if (!modeControls[mode]) throw new RangeError(`Unknown portal mode: ${mode}`);
    return [...commonControls, ...modeControls[mode]].reduce((settings, meta) => {
      settings[meta.key] = meta.default;
      return settings;
    }, {});
  }

  function prepareField(x, y, phase, settings) {
    const scale = Math.max(0.01, settings.fieldScale);
    const sx = 0.5 + ((x - 0.5) * scale);
    const sy = 0.5 + ((y - 0.5) * scale);
    const ratio = settings.bias + (Math.sin(phase * settings.ratioSpeed * Math.PI * 2) * settings.ratioSwing);
    const morphTime = phase * settings.morphSpeed;
    const broadNoise = (fbm(
      (sx * 1.17) + (morphTime * 0.07),
      (sy * 1.09) - (morphTime * 0.05),
      31.7,
    ) - 0.5) * settings.morphAmount;
    const detailNoise = (fbm(
      (sx * 2.8) - (morphTime * 0.09),
      (sy * 2.5) + (morphTime * 0.08),
      67.3,
    ) - 0.5) * settings.detail;
    return { sx, sy, ratio, broadNoise, detailNoise };
  }

  function finishField(field, phase, settings, context, localLight = 0) {
    const softness = Math.max(0.001, settings.softness);
    const mix = smoothstep(0.5 - softness, 0.5 + softness, field);
    const seam = 4 * mix * (1 - mix);
    const pulse = Math.sin(phase * settings.pulseSpeed * Math.PI * 2) * settings.pulseAmount;
    const texture = (context.broadNoise + context.detailNoise) * settings.lightAmount;
    const light = Math.max(-0.25, Math.min(0.25, (pulse + texture + localLight) * seam));
    return { mix, light };
  }

  function sampleDualTide(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const offset = settings.phaseOffset * Math.PI / 180;
    const aPhase = phase * 0.52;
    const bPhase = (phase * 0.47) + offset;
    const aX = 0.5 - (settings.separation * 0.5)
      + (Math.sin(aPhase * 0.83) * settings.wanderX)
      + ((0.5 + 0.5 * Math.sin(aPhase * 0.31)) * settings.intrusion);
    const bX = 0.5 + (settings.separation * 0.5)
      - (Math.sin(bPhase * 0.79) * settings.wanderX)
      - ((0.5 + 0.5 * Math.sin(bPhase * 0.29)) * settings.intrusion);
    const aY = 0.5 + (Math.sin(aPhase * 0.61) * settings.wanderY);
    const bY = 0.5 - (Math.sin(bPhase * 0.57) * settings.wanderY);
    const aMass = gaussian(c.sx - aX, c.sy - aY, settings.lobeARadius, settings.lobeARadius / settings.lobeAEllipse);
    const bMass = gaussian(c.sx - bX, c.sy - bY, settings.lobeBRadius, settings.lobeBRadius / settings.lobeBEllipse);
    const warp = (fbm(
      (c.sx * settings.warpScale) + (phase * settings.warpSpeed * 0.11),
      (c.sy * settings.warpScale) - (phase * settings.warpSpeed * 0.09),
      103.2,
    ) - 0.5) * settings.warpAmount;
    const field = c.sx + c.ratio + warp
      + ((bMass - aMass) * settings.counterFlow * 0.46)
      + (c.broadNoise * 0.20)
      + (c.detailNoise * 0.12);
    return finishField(field, phase, settings, c, (aMass + bMass - 0.7) * settings.lightAmount * 0.12);
  }

  function sampleMagneticMembrane(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const spread = settings.nodePhaseSpread * Math.PI / 180;
    const nodes = [settings.nodeTop, settings.nodeMiddle, settings.nodeBottom].map((base, index) =>
      base + (Math.sin((phase * 0.23) + (spread * index)) * settings.nodeWander));
    const iy = clamp01(c.sy);
    const nodeCurve = ((1 - iy) * (1 - iy) * nodes[0])
      + (2 * (1 - iy) * iy * nodes[1])
      + (iy * iy * nodes[2]);
    const primary = Math.sin(
      ((c.sy / settings.primaryWavelength) * Math.PI * 2)
      + (phase * settings.primarySpeed * Math.PI * 2),
    ) * settings.primaryAmplitude;
    const secondary = Math.sin(
      ((c.sy / settings.secondaryWavelength) * Math.PI * 2)
      - (phase * settings.secondarySpeed * Math.PI * 2)
      + 1.7,
    ) * settings.secondaryAmplitude;
    const warp = (fbm(
      (c.sy * 1.4) + (phase * settings.warpSpeed * 0.08),
      (c.sx * 0.9) - (phase * settings.warpSpeed * 0.05),
      211.6,
    ) - 0.5) * settings.warpAmount;
    const boundary = 0.5 + c.ratio
      + (nodeCurve * (1 - (settings.tension * 0.68)))
      + primary + secondary
      + (settings.skew * (c.sy - 0.5))
      + warp
      + (c.broadNoise * 0.18)
      + (c.detailNoise * 0.10);
    const field = 0.5 + (c.sx - boundary);
    return finishField(field, phase, settings, c, Math.abs(primary + secondary) * settings.lightAmount * 0.16);
  }

  function sampleBreathingLens(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const breathPhase = phase * settings.breathSpeed * Math.PI * 2;
    const centerX = settings.centerX + (Math.sin(phase * 0.31) * settings.wanderX);
    const centerY = settings.centerY + (Math.cos(phase * 0.27) * settings.wanderY);
    const radiusX = Math.max(0.03, settings.radiusX * (1 + (Math.sin(breathPhase) * settings.breathX)));
    const radiusY = Math.max(0.03, settings.radiusY * (1 + (Math.cos(breathPhase * 0.83) * settings.breathY)));
    const dx = (c.sx - centerX) / radiusX;
    const dy = (c.sy - centerY) / radiusY;
    const lensDistance = Math.sqrt((dx * dx) + (dy * dy));
    const lens = Math.exp(-(lensDistance * lensDistance) / Math.max(0.01, settings.edgeFalloff));
    const satelliteAngle = settings.satellitePhase * Math.PI / 180;
    const satelliteX = centerX + (Math.cos(satelliteAngle + (phase * 0.13)) * settings.satelliteDistance);
    const satelliteY = centerY + (Math.sin(satelliteAngle + (phase * 0.11)) * settings.satelliteDistance);
    const satellite = gaussian(
      c.sx - satelliteX,
      c.sy - satelliteY,
      settings.satelliteRadius,
      settings.satelliteRadius,
    );
    const pressure = ((lens * settings.pressure) + (satellite * settings.satelliteAmount)) * settings.refraction;
    const field = c.sx + c.ratio + pressure
      + (c.broadNoise * 0.19)
      + (c.detailNoise * 0.10);
    return finishField(field, phase, settings, c, (lens + satellite) * settings.lightAmount * 0.12);
  }

  const cellSeeds = Object.freeze([
    [0.13, 0.18, 0.1], [0.34, 0.76, 1.7], [0.52, 0.32, 3.1], [0.72, 0.80, 4.8],
    [0.88, 0.24, 6.4], [0.22, 0.51, 8.2], [0.66, 0.52, 10.3],
  ]);
  const wrap01 = (value) => ((value % 1) + 1) % 1;

  function sampleCellularField(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const count = Math.max(3, Math.min(7, Math.round(settings.cellCount)));
    let pressureSum = 0;
    let lightSum = 0;
    for (let index = 0; index < count; index += 1) {
      const [baseX, baseY, seed] = cellSeeds[index];
      const curl = (fbm(
        (baseX * settings.curlScale) + (phase * 0.04),
        (baseY * settings.curlScale) - (phase * 0.03),
        seed + 301,
      ) - 0.5) * settings.curlAmount;
      const cellX = wrap01(baseX + (phase * settings.advectionX * 0.025)
        + (Math.sin((phase * 0.19) + seed) * settings.cellWander) + curl);
      const cellY = wrap01(baseY + (phase * settings.advectionY * 0.025)
        + (Math.cos((phase * 0.17) + seed) * settings.cellWander) - curl);
      const sizeWave = Math.sin((phase * 0.21) + seed) * settings.cellMorph;
      const variation = 1 + (((index / Math.max(1, count - 1)) - 0.5) * settings.cellVariation);
      const radius = Math.max(0.04, settings.cellSize * variation * (1 + (sizeWave * 0.35)));
      const cell = gaussian(c.sx - cellX, c.sy - cellY, radius, radius * (0.84 + ((index % 3) * 0.11)));
      const polarity = index % 2 === 0 ? -1 : 1;
      const weightedPolarity = polarity + settings.polarityBalance;
      pressureSum += cell * weightedPolarity;
      lightSum += cell;
    }
    const noise = (fbm(
      (c.sx * settings.noiseScale) + (phase * settings.noiseSpeed * 0.07),
      (c.sy * settings.noiseScale) - (phase * settings.noiseSpeed * 0.06),
      409.4,
    ) - 0.5) * settings.noiseAmount;
    const field = c.sx + c.ratio + settings.mergeThreshold
      + ((pressureSum / count) * settings.pressure)
      + noise
      + (c.broadNoise * 0.18)
      + (c.detailNoise * 0.10);
    return finishField(field, phase, settings, c, (lightSum / count) * settings.lightAmount * 0.16);
  }

  const samplers = Object.freeze({
    'dual-tide': sampleDualTide,
    'magnetic-membrane': sampleMagneticMembrane,
    'breathing-lens': sampleBreathingLens,
    'cellular-field': sampleCellularField,
  });
```

Compose strength exactly as follows so zero is the static reference:

```js
function sampleField(mode, x, y, phase, settings = createModeSettings(mode)) {
  const nx = clamp01(Number(x));
  const ny = clamp01(Number(y));
  if (mode === 'static') return { mix: nx, light: 0 };
  const sampler = samplers[mode];
  if (!sampler) throw new RangeError(`Unknown portal mode: ${mode}`);
  const animated = sampler(nx, ny, phase, settings);
  const strength = clamp01(settings.strength);
  return {
    mix: clamp01(lerp(nx, animated.mix, strength)),
    light: Math.max(-0.25, Math.min(0.25, animated.light * strength)),
  };
}

function sampleColor(a, b, sample) {
  const mix = clamp01(sample.mix);
  const seam = 4 * mix * (1 - mix);
  const light = Math.max(-0.25, Math.min(0.25, sample.light)) * seam;
  const channel = (left, right) => Math.max(0, Math.min(255, Math.round(lerp(left, right, mix) * (1 + light))));
  return { r: channel(a.r, b.r), g: channel(a.g, b.g), b: channel(a.b, b.b) };
}

function advancePhase(phase, elapsedSeconds, speed) {
  return phase + (Math.max(0, elapsedSeconds) * Math.max(0, speed));
}
```

Return the complete API explicitly:

```js
  return Object.freeze({
    modeOrder: Object.freeze(modeOrder.slice()),
    modeLabels,
    commonControls,
    modeControls,
    createModeSettings,
    sampleField,
    sampleColor,
    advancePhase,
    clamp01,
  });
});
```

- [x] **Step 4: Run the pure-engine test and verify GREEN**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: `Portal energy field checks passed`.

### Task 2: Static reference and obsolete-system removal

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: `MindPortalEnergy.modeOrder` and `modeLabels`.
- Produces DOM hooks: `data-mind-portal-mode`, `data-mind-portal-mode-button`, `data-mind-portal-energy-controls`, and `data-mind-portal-energy-controls-scroll`.

- [x] **Step 1: Replace obsolete portal assertions with a failing contract**

Remove required-string and regex assertions that require old test-canvas-fluid attributes, signature window-size inputs, test-header background opacity, old test motion presets, level/legacy functions, or rotation functions. Retain the existing production D-row `mindHeaderValueWater`, `setMindHeaderGradientStops`, and three global mode-scale assertions. Add these standalone-lab assertions:

```js
const portalStart = html.indexOf('<div class="mind-portal-test-header-wrap" data-mind-portal-test-header>');
const portalEnd = html.indexOf('</section>', portalStart);
const portalLab = html.slice(portalStart, portalEnd);

assert(portalStart >= 0, 'Missing standalone portal test lab');
assert(portalLab.includes('data-mind-portal-mode="static"'));
assert.strictEqual((portalLab.match(/data-mind-portal-signature-slider=/g) || []).length, 3);
assert(!portalLab.includes('data-mind-portal-signature-window-input'));
assert(!portalLab.includes('data-mind-portal-bg-opacity-slider'));
assert(!portalLab.includes('data-mind-portal-motion-panel'));
assert(!portalLab.includes('data-mind-portal-rotation-pad'));
for (const mode of ['static', 'dual-tide', 'magnetic-membrane', 'breathing-lens', 'cellular-field']) {
  assert(portalLab.includes(`data-mind-portal-mode-button="${mode}"`));
}
for (const removed of [
  'mindPortalGlobalTransform',
  'mindPortalUpdateRotationClock',
  'mindPortalLevelViewField',
  'mindPortalLegacyMeshField',
  'mindPortalYinYangField',
  'mindPortalMotionPresets',
]) {
  assert(!html.includes(removed), `Removed portal system leaked: ${removed}`);
}
assert(html.includes('src="./color_lab_portal_energy.js"'));
assert(/--mind-portal-color-a:[^;]+;[\s\S]*?--mind-portal-color-b:[^;]+;/.test(html));
assert(/linear-gradient\(90deg, var\(--mind-portal-color-a\) 0%, var\(--mind-portal-color-b\) 100%\)/.test(html));
```

Retain the existing touch-layer/trail/pointer assertions without changing their expected colors, sizes, or timing.

- [x] **Step 2: Run the static test and verify RED**

Run:

```sh
node docs/prototypes/color_lab_static_test.js
```

Expected: FAIL because static mode/new buttons are missing and old controls/functions remain.

- [x] **Step 3: Replace portal markup and CSS**

In `color_lab.html`:

- add `<script src="./color_lab_portal_energy.js"></script>` before the main inline script;
- reduce `.mind-portal-test-header-wrap` height to content-driven `height:auto`;
- override only `.common-header-card.mind-portal-test-header::before` with the exact `90deg` A/B gradient and `animation:none`, leaving the production D-row header animation intact;
- keep `.common-mind-portal-layer`, `.common-mind-portal-layer::after`, `.common-mind-portal-trail`, `.common-mind-portal-trail-dot`, and `@keyframes mindPortalTrailFade` unchanged;
- replace the old signature rows with three slider-only rows;
- move the unchanged interaction-opacity control directly after them;
- add five mode buttons and an initially hidden controls viewport;
- delete old motion/rotation CSS and DOM.

Use this complete structural markup:

```html
<div class="mind-portal-test-header-wrap" data-mind-portal-test-header>
  <header class="common-header-card mind-portal-test-header" data-mind-portal-drag-surface="true" data-mind-portal-mode="static" aria-label="Portal touch teszt header">
    <canvas class="common-mind-portal-idle-canvas" data-mind-portal-idle-canvas aria-hidden="true"></canvas>
    <div class="mind-portal-test-copy">
      <strong>Portal energiamező</strong>
      <span>Húzd az ujjad ezen a headeren · swipe itt nem scrolloz</span>
    </div>
  </header>
  <div class="mind-portal-signature-panel" data-mind-portal-signature-panel>
    <div class="mind-portal-signature-title"><span>Portal színezés</span><span data-mind-portal-signature-source-label>Traffic</span></div>
    <label class="mind-portal-signature-row" data-signature-kind="balance">
      <span>Traffic</span>
      <input type="range" min="0" max="100" step="1" value="50" data-mind-portal-signature-slider="balance" aria-label="Portal traffic színezés">
      <em data-mind-portal-signature-value="balance">50%</em>
    </label>
    <label class="mind-portal-signature-row" data-signature-kind="limits">
      <span>Limit</span>
      <input type="range" min="0" max="100" step="1" value="50" data-mind-portal-signature-slider="limits" aria-label="Portal limit színezés">
      <em data-mind-portal-signature-value="limits">50%</em>
    </label>
    <label class="mind-portal-signature-row" data-signature-kind="cool">
      <span>Cool</span>
      <input type="range" min="0" max="100" step="1" value="50" data-mind-portal-signature-slider="cool" aria-label="Portal cool színezés">
      <em data-mind-portal-signature-value="cool">50%</em>
    </label>
  </div>
  <div class="mind-portal-opacity-control" data-mind-portal-opacity-control>
    <label><span>Interakció opacity</span><span data-mind-portal-opacity-value>100%</span></label>
    <input type="range" min="0" max="100" step="1" value="100" data-mind-portal-opacity-slider aria-label="Portal interaction color opacity">
  </div>
  <div class="mind-portal-mode-panel" data-mind-portal-mode-panel>
    <div class="mind-portal-motion-title"><span>Energiamező alternatívák</span><span data-mind-portal-mode-label>Statikus A/B</span></div>
    <div class="mind-portal-mode-buttons" role="group" aria-label="Portal energiamező mód">
      <button type="button" data-mind-portal-mode-button="static" aria-pressed="true">Statikus A/B</button>
      <button type="button" data-mind-portal-mode-button="dual-tide" aria-pressed="false">Kettős árapály</button>
      <button type="button" data-mind-portal-mode-button="magnetic-membrane" aria-pressed="false">Mágneses membrán</button>
      <button type="button" data-mind-portal-mode-button="breathing-lens" aria-pressed="false">Lélegző lencse</button>
      <button type="button" data-mind-portal-mode-button="cellular-field" aria-pressed="false">Celluláris mező</button>
    </div>
    <div class="mind-portal-energy-controls" data-mind-portal-energy-controls hidden>
      <div class="mind-portal-energy-controls-head">
        <strong data-mind-portal-controls-title></strong>
        <button type="button" data-mind-portal-mode-reset>Aktív mód reset</button>
      </div>
      <div class="mind-portal-energy-controls-scroll" data-mind-portal-energy-controls-scroll></div>
    </div>
  </div>
</div>
```

Replace the three-stop signature builder with a fixed two-stop builder:

```js
function buildMindPortalSignature(kind, center) {
  const boundedCenter = clampValue(Number(center), 0, 100);
  const sample = {
    balance: sampleBalanceScaleColor,
    limits: sampleLimitsScaleColor,
    cool: sampleCoolScaleColor,
  }[kind] || sampleBalanceScaleColor;
  return {
    a: sample(boundedCenter - 14),
    b: sample(boundedCenter + 14),
  };
}
```

`applyMindPortalSignature` must write `--mind-portal-color-a`, `--mind-portal-color-b`, `--spendee-header-bg`, source label, and last-writer source attributes only on the standalone header.

- [x] **Step 4: Delete the obsolete idle/control implementation and initialize static mode**

Delete old rotation, level, legacy, mesh, weighted color-mixing, preset, and old control functions. Keep `mindPortalIdleStates`, ripple state, and accepted touch functions available. Initialize the header with mode `static`, a clear/transparent canvas, and no running paint loop until Task 4 connects the new engine.

- [x] **Step 5: Run static and parse checks and verify GREEN**

Run:

```sh
node docs/prototypes/color_lab_static_test.js
node -e "const fs=require('fs'),vm=require('vm');const h=fs.readFileSync('docs/prototypes/color_lab.html','utf8');const s=[...h.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m=>m[1]).filter(Boolean);s.forEach((x,i)=>new vm.Script(x,{filename:'inline-'+i}));console.log('Inline scripts parse:',s.length)"
```

Expected: static checks pass and inline scripts parse.

### Task 3: Schema-driven maximum-detail controls

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: `MindPortalEnergy.commonControls`, `modeControls`, `createModeSettings`, and `modeLabels`.
- Produces: `initMindPortalEnergyControls()`, `setMindPortalEnergyMode(header, mode)`, `renderMindPortalEnergyControls(wrap, mode)`, and `resetMindPortalEnergyMode(wrap)`.

- [x] **Step 1: Add failing control-generation assertions**

Assert the HTML contains the four named functions, range/number synchronization hooks, active-mode retention state, mode-local reset, and active-controls-only rendering. Assert the mode panel uses one generated scroll viewport rather than pre-rendering four simultaneous control lists.

- [x] **Step 2: Run the static test and verify RED**

Expected: FAIL because control generation does not exist.

- [x] **Step 3: Implement mode state and generated rows**

Store per-mode settings in `state.settingsByMode`. Render rows from `[...commonControls, ...modeControls[mode]]` with sequential `01`, `02`, … numbering. Each row must use:

```html
<label class="mind-portal-energy-row" data-mind-portal-energy-key="KEY">
  <b>NUMBER</b>
  <span>LABEL</span>
  <input type="range" min="MIN" max="MAX" step="STEP" value="VALUE" data-mind-portal-energy-range="KEY">
  <input type="number" min="MIN" max="MAX" step="STEP" value="VALUE" data-mind-portal-energy-number="KEY">
</label>
```

The shared write path clamps and normalizes through the schema metadata, updates both inputs, and mutates only `state.settingsByMode[state.activeMode][key]`. Mode buttons update `aria-pressed`, header `data-mind-portal-mode`, labels, and visible controls. Static mode sets `hidden=true` on the controls container. Reset replaces only the active mode object with `createModeSettings(activeMode)` and rerenders its rows.

- [x] **Step 4: Run tests and verify GREEN**

Run both Node test files. Expected: both pass.

### Task 4: Canvas lifecycle and four renderer integration

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: `MindPortalEnergy.sampleField`, `sampleColor`, `advancePhase`, and generated settings.
- Produces: `initMindPortalEnergyCanvas()`, `drawMindPortalEnergyFrame()`, one `requestAnimationFrame` loop, one resize-aware buffer, and per-mode continuous phase.

- [x] **Step 1: Add failing lifecycle assertions**

Assert that static/zero-strength clears and hides canvas, animated modes call the pure module sampler, phase advances using elapsed time and current speed, rendering pauses when disconnected/offscreen, and reduced motion starts static.

- [x] **Step 2: Run the static test and verify RED**

Expected: FAIL because the new lifecycle functions are missing.

- [x] **Step 3: Implement one canvas renderer**

Maintain state with `activeMode`, `settingsByMode`, `phaseByMode`, `lastNow`, `lastFrameTime`, `visible`, `ripples`, and `lastPulseTime`. Use an `IntersectionObserver` when available. In the animation tick:

- return without painting for static mode, zero strength, disconnected header, or non-visible header;
- cap elapsed time to `0.12s`;
- advance only the active mode phase using `advancePhase`;
- size the buffer from `renderScale`;
- sample normalized pixels through `sampleField` and `sampleColor`;
- retain the existing ripple coordinate perturbation and fade duration constants before sampling;
- set canvas opacity to `1` only after a completed animated frame;
- clear/hide it immediately on static selection.

- [x] **Step 4: Run engine, static, and parse tests and verify GREEN**

Run all three verification commands from Tasks 1 and 2. Expected: all pass.

### Task 5: Internally scrollable slider viewport

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Produces: `initMindPortalControlScrollRouting()` and CSS contract for `.mind-portal-energy-controls-scroll`.

- [x] **Step 1: Add failing gesture-routing assertions**

Assert CSS includes `max-height: min(52vh, 520px)`, `overflow-y:auto`, momentum scrolling, `touch-action:pan-y`, and non-containing boundary overscroll. Assert JS classifies after 7px using the existing `absY > absX * 1.15` rule, scrolls the nearest control viewport first, and scrolls the window only when that viewport cannot consume the delta.

- [x] **Step 2: Run the static test and verify RED**

Expected: FAIL because the internal viewport routing is missing.

- [x] **Step 3: Implement scroll routing**

Replace `initMindPortalSliderScrollPassThrough` with `initMindPortalControlScrollRouting`. On vertical range gestures:

```js
const before = viewport.scrollTop;
viewport.scrollTop += deltaY;
const consumed = viewport.scrollTop !== before;
if (!consumed) window.scrollBy({ top: deltaY, left: 0, behavior: 'auto' });
```

Do not intercept horizontal gestures. Clear gesture state on `touchend` and `touchcancel`. Leave the header's `touch-action:none` unchanged.

- [x] **Step 4: Run tests and verify GREEN**

Run engine/static/parse checks. Expected: all pass.

### Task 6: Full verification and checklist closure

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`

**Interfaces:**
- Consumes all implemented behavior and acceptance requirements.
- Produces fresh test evidence and honest final statuses for `COLOR-LAB-286` through `COLOR-LAB-292`.

- [x] **Step 1: Run complete automated verification**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
node docs/prototypes/color_lab_static_test.js
node -e "const fs=require('fs'),vm=require('vm');const h=fs.readFileSync('docs/prototypes/color_lab.html','utf8');const s=[...h.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m=>m[1]).filter(Boolean);s.forEach((x,i)=>new vm.Script(x,{filename:'inline-'+i}));console.log('Inline scripts parse:',s.length)"
git diff --check
```

Expected: both test suites pass, inline scripts parse, and `git diff --check` prints nothing.

- [x] **Step 2: Run local HTTP smoke**

Start a temporary server rooted at the worktree and fetch both scripts:

```sh
python3 -m http.server 8765
```

Verify HTTP 200 for `docs/prototypes/color_lab.html` and `docs/prototypes/color_lab_portal_energy.js`, and confirm the returned HTML contains all five mode buttons and the scroll viewport.

- [ ] **Step 3: Capture visual evidence**

In the Android browser, keep one Traffic palette position fixed and capture one screenshot for each of the five modes. For animated modes, observe at least two separated moments to verify morphology actually changes. Drag once across the header and compare the touch bloom/trail to the pre-rebuild appearance. Verify the internal slider panel scrolls when a vertical swipe begins over a range control.

- [x] **Step 4: Update checklist statuses**

Set an item to `DONE` only when its automated and visual acceptance evidence exists. Leave any visually unverified item `PARTIAL` and report it explicitly.

- [x] **Step 5: Review the final diff without committing unrelated work**

Run:

```sh
git status --short
git diff -- docs/prototypes/color_lab.html docs/prototypes/color_lab_portal_energy.js docs/prototypes/color_lab_portal_energy_test.js docs/prototypes/color_lab_static_test.js docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md
```

Expected: only the intended portal rebuild plus pre-existing in-scope prototype/checklist changes are present. Do not stage or commit unrelated files.
