# Balance Money-Flow Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fourth, A1-colored Money-flow signature and three ratio-safe Balance energy-field modes to the standalone portal test header without changing the existing signatures, five modes, or touch interaction.

**Architecture:** Extend the dependency-free portal module with pure ratio/palette helpers and a separate Balance-field sampling path. Keep the current two-endpoint renderers intact. The HTML controller selects the appropriate color path inside the existing single canvas loop and adds one compact signature row plus three dropdown entries.

**Tech Stack:** HTML/CSS, browser Canvas 2D, dependency-free JavaScript, Node `assert`, local HTTP smoke checks.

## Global Constraints

- Work only in the existing `spendeetest-worktree`; do not create another worktree.
- Execute inline because the user explicitly requested no subagents.
- Preserve all existing dirty-worktree changes. Do not commit shared implementation files unless the user later requests it, because those files already contain accumulated user work.
- Keep the exact palette `#49cfc5`, `#8defe5`, `#f8e8f3`, `#f7b2f5`, `#d8b4fe`.
- Map semantic income 0–100 to the visual split interval 8–92%.
- Turquoise/income remains left; pink-purple/expense remains right; both outer-edge colors remain visible.
- Do not change the existing mode IDs, labels, order, schemas, samplers, or output formulas.
- Do not change touch bloom/trail/ripple/fade source or CSS.
- Reuse one canvas, one requestAnimationFrame loop, and the existing visibility/reduced-motion lifecycle.
- UI-facing checklist rows remain `PARTIAL` until Android screenshots and direct mobile interaction evidence exist.

---

### Task 1: Pure Money-flow Ratio and Palette Contract

**Files:**
- Modify: `docs/prototypes/color_lab_portal_energy_test.js`
- Modify: `docs/prototypes/color_lab_portal_energy.js`

**Interfaces:**
- Produces: `moneyFlowPaletteHex: readonly string[]`
- Produces: `moneyFlowVisualSplit(incomePercent: number): number`
- Produces: `moneyFlowStopPositions(incomePercent: number): number[]`
- Produces: `sampleMoneyFlowColor(palette: RGB[], incomePercent: number, sample: { coordinate: number, light?: number, chroma?: number }): RGB`
- Existing `sampleField` and `sampleColor` contracts remain unchanged.

- [ ] **Step 1: Add failing palette and ratio tests**

Append before the final log in `color_lab_portal_energy_test.js`:

```js
assert.deepStrictEqual(energy.moneyFlowPaletteHex, [
  '#49cfc5',
  '#8defe5',
  '#f8e8f3',
  '#f7b2f5',
  '#d8b4fe',
]);
assert.strictEqual(energy.moneyFlowVisualSplit(0), 0.08);
assert.strictEqual(energy.moneyFlowVisualSplit(50), 0.5);
assert.strictEqual(energy.moneyFlowVisualSplit(100), 0.92);
assert.strictEqual(energy.moneyFlowVisualSplit(-40), 0.08);
assert.strictEqual(energy.moneyFlowVisualSplit(140), 0.92);

for (const ratio of [0, 17, 50, 83, 100]) {
  const positions = energy.moneyFlowStopPositions(ratio);
  assert.strictEqual(positions.length, 5);
  assert.strictEqual(positions[0], 0);
  assert.strictEqual(positions[2], energy.moneyFlowVisualSplit(ratio));
  assert.strictEqual(positions[4], 1);
  positions.slice(1).forEach((position, index) => {
    assert(position > positions[index], `money-flow stops must increase at ${ratio}`);
  });
}

const moneyPalette = energy.moneyFlowPaletteHex.map((hex) => ({
  r: parseInt(hex.slice(1, 3), 16),
  g: parseInt(hex.slice(3, 5), 16),
  b: parseInt(hex.slice(5, 7), 16),
}));
assert.deepStrictEqual(
  energy.sampleMoneyFlowColor(moneyPalette, 50, { coordinate: 0, light: 0, chroma: 0 }),
  moneyPalette[0],
);
assert.deepStrictEqual(
  energy.sampleMoneyFlowColor(moneyPalette, 50, { coordinate: 0.5, light: 0, chroma: 0 }),
  moneyPalette[2],
);
assert.deepStrictEqual(
  energy.sampleMoneyFlowColor(moneyPalette, 50, { coordinate: 1, light: 0, chroma: 0 }),
  moneyPalette[4],
);
```

- [ ] **Step 2: Run RED verification**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: FAIL because `moneyFlowPaletteHex`/`moneyFlowVisualSplit` are not exported.

- [ ] **Step 3: Implement the pure helpers**

Add beside the existing math helpers in `color_lab_portal_energy.js`:

```js
const moneyFlowPaletteHex = Object.freeze([
  '#49cfc5', '#8defe5', '#f8e8f3', '#f7b2f5', '#d8b4fe',
]);

function moneyFlowVisualSplit(incomePercent) {
  return 0.08 + (clamp01(Number(incomePercent) / 100) * 0.84);
}

function moneyFlowStopPositions(incomePercent) {
  const split = moneyFlowVisualSplit(incomePercent);
  return Object.freeze([
    0,
    split * 0.58,
    split,
    split + ((1 - split) * 0.46),
    1,
  ]);
}

function sampleMoneyFlowColor(palette, incomePercent, sample) {
  const positions = moneyFlowStopPositions(incomePercent);
  const coordinate = clamp01(Number(sample.coordinate));
  let segment = positions.length - 2;
  for (let index = 0; index < positions.length - 1; index += 1) {
    if (coordinate <= positions[index + 1]) {
      segment = index;
      break;
    }
  }
  const width = Math.max(1e-6, positions[segment + 1] - positions[segment]);
  const amount = clamp01((coordinate - positions[segment]) / width);
  const base = {
    r: lerp(palette[segment].r, palette[segment + 1].r, amount),
    g: lerp(palette[segment].g, palette[segment + 1].g, amount),
    b: lerp(palette[segment].b, palette[segment + 1].b, amount),
  };
  const light = Math.max(-0.22, Math.min(0.22, Number(sample.light) || 0));
  const chroma = Math.max(-0.35, Math.min(0.35, Number(sample.chroma) || 0));
  const gray = (base.r + base.g + base.b) / 3;
  const channel = (value) => Math.max(0, Math.min(255, Math.round(
    lerp(gray, value, 1 + chroma) * (1 + light),
  )));
  return { r: channel(base.r), g: channel(base.g), b: channel(base.b) };
}
```

Export all four helpers without altering the existing exports.

- [ ] **Step 4: Run GREEN verification**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: `Portal energy field checks passed`.

---

### Task 2: Three Balance-specific Deterministic Fields

**Files:**
- Modify: `docs/prototypes/color_lab_portal_energy_test.js`
- Modify: `docs/prototypes/color_lab_portal_energy.js`

**Interfaces:**
- Produces: appended mode IDs `balance-membrane`, `balance-counterflow`, `balance-charges`
- Produces: `balanceModeIds: readonly string[]`
- Produces: `controlsForMode(mode): readonly ControlMeta[]`
- Produces: `isBalanceMode(mode): boolean`
- Produces: `sampleMoneyFlowField(mode, x, y, phase, incomePercent, settings): { coordinate, boundary, light, chroma, side }`
- Consumes: Task 1 ratio and palette helpers.

- [ ] **Step 1: Add failing schema, bounds, and semantic-side tests**

Extend the expected mode list only by appending:

```js
'balance-membrane',
'balance-counterflow',
'balance-charges',
```

Then add:

```js
assert.deepStrictEqual(energy.modeOrder.slice(0, 5), [
  'static', 'dual-tide', 'magnetic-membrane', 'breathing-lens', 'cellular-field',
]);
assert.deepStrictEqual(energy.balanceModeIds, [
  'balance-membrane', 'balance-counterflow', 'balance-charges',
]);

for (const mode of energy.balanceModeIds) {
  const schema = energy.controlsForMode(mode);
  const settings = energy.createModeSettings(mode);
  assert(schema.length >= 16, `${mode} needs detailed controls`);
  assert.strictEqual(new Set(schema.map(({ key }) => key)).size, schema.length);
  for (const ratio of [0, 50, 100]) {
    for (const phase of [0, 3.25, 17.5]) {
      for (const x of [0, 0.17, 0.5, 0.83, 1]) {
        for (const y of [0, 0.5, 1]) {
          const sample = energy.sampleMoneyFlowField(mode, x, y, phase, ratio, settings);
          assert(sample.coordinate >= 0 && sample.coordinate <= 1);
          assert(sample.boundary >= 0.04 && sample.boundary <= 0.96);
          assert(sample.light >= -0.22 && sample.light <= 0.22);
          assert(sample.chroma >= -0.35 && sample.chroma <= 0.35);
          if (x === 0) assert.strictEqual(sample.side, 'income');
          if (x === 1) assert.strictEqual(sample.side, 'expense');
        }
      }
    }
  }
  const off = { ...settings, strength: 0 };
  for (const x of [0, 0.25, 0.5, 0.75, 1]) {
    const sample = energy.sampleMoneyFlowField(mode, x, 0.37, 9, 61, off);
    assert.strictEqual(sample.coordinate, x);
    assert.strictEqual(sample.boundary, energy.moneyFlowVisualSplit(61));
    assert.strictEqual(sample.light, 0);
    assert.strictEqual(sample.chroma, 0);
  }
}
```

Add this exact control-response loop:

```js
for (const mode of energy.balanceModeIds) {
  const base = energy.createModeSettings(mode);
  const fixtures = [
    [0.19, 0.23, 2.7, 21],
    [0.47, 0.61, 7.3, 50],
    [0.79, 0.82, 13.1, 79],
    [0.52, 0.14, 21.7, 64],
  ];
  const baseSamples = fixtures.map(([x, y, phase, ratio]) =>
    energy.sampleMoneyFlowField(mode, x, y, phase, ratio, base));
  for (const meta of energy.controlsForMode(mode)) {
    if (['speed', 'renderScale', 'frameMs'].includes(meta.key)) continue;
    const changed = {
      ...base,
      [meta.key]: base[meta.key] === meta.max ? meta.min : meta.max,
    };
    const probes = fixtures.map(([x, y, phase, ratio]) =>
      energy.sampleMoneyFlowField(mode, x, y, phase, ratio, changed));
    assert(probes.some((probe, index) =>
      Math.abs(probe.coordinate - baseSamples[index].coordinate) > 1e-6 ||
      Math.abs(probe.boundary - baseSamples[index].boundary) > 1e-6 ||
      Math.abs(probe.light - baseSamples[index].light) > 1e-6 ||
      Math.abs(probe.chroma - baseSamples[index].chroma) > 1e-6),
    `${mode}.${meta.key} must measurably affect the field`);
  }
}
```

- [ ] **Step 2: Run RED verification**

Run `node docs/prototypes/color_lab_portal_energy_test.js`.

Expected: FAIL because the appended modes and Balance APIs do not exist.

- [ ] **Step 3: Add mode metadata and isolated schemas**

Append the three IDs and Hungarian labels without editing the first five entries:

```js
const modeOrder = [
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
  'balance-membrane',
  'balance-counterflow',
  'balance-charges',
];

const modeLabels = Object.freeze({
  static: 'Statikus A/B',
  'dual-tide': 'Kettős árapály',
  'magnetic-membrane': 'Mágneses membrán',
  'breathing-lens': 'Lélegző lencse',
  'cellular-field': 'Celluláris mező',
  'balance-membrane': 'Balance membrán',
  'balance-counterflow': 'Balance ellenáram',
  'balance-charges': 'Balance töltések',
});

const balanceModeIds = Object.freeze([
  'balance-membrane',
  'balance-counterflow',
  'balance-charges',
]);
```

Use separate Balance common controls so the existing schemas remain unchanged:

```js
const balanceCommonControls = Object.freeze([
  { key: 'strength', label: 'Animáció erő', min: 0, max: 1, step: 0.01, default: 0.82 },
  { key: 'speed', label: 'Sebesség', min: 0, max: 2, step: 0.01, default: 0.24 },
  { key: 'seamSoftness', label: 'Határ puhaság', min: 0.02, max: 0.32, step: 0.01, default: 0.12 },
  { key: 'lightAmount', label: 'Fényenergia', min: 0, max: 0.22, step: 0.01, default: 0.08 },
  { key: 'chromaAmount', label: 'Színenergia', min: 0, max: 0.35, step: 0.01, default: 0.10 },
  { key: 'pulseAmount', label: 'Pulzus', min: 0, max: 0.20, step: 0.01, default: 0.05 },
  { key: 'pulseSpeed', label: 'Pulzus seb.', min: 0, max: 1, step: 0.01, default: 0.10 },
  { key: 'renderScale', label: 'Render minőség', min: 0.35, max: 1, step: 0.05, default: 0.60 },
  { key: 'frameMs', label: 'Render lépés', min: 16, max: 100, step: 1, default: 42 },
]);
```

Append these exact schemas to `modeControls`:

```js
'balance-membrane': Object.freeze([
  { key: 'boundaryAmplitude', label: 'Határkilengés', min: 0, max: 0.28, step: 0.01, default: 0.12 },
  { key: 'primaryWavelength', label: 'Fő hullámhossz', min: 0.35, max: 3, step: 0.01, default: 1.10 },
  { key: 'secondaryAmplitude', label: 'Mellékhullám', min: 0, max: 0.18, step: 0.01, default: 0.06 },
  { key: 'secondaryWavelength', label: 'Mellékhullámhossz', min: 0.35, max: 4, step: 0.01, default: 2.20 },
  { key: 'nodePhase', label: 'Csomópont fázis', min: 0, max: 360, step: 1, default: 118 },
  { key: 'driftSpeed', label: 'Határvándorlás', min: 0, max: 1, step: 0.01, default: 0.14 },
  { key: 'tension', label: 'Membránfeszülés', min: 0, max: 1, step: 0.01, default: 0.58 },
  { key: 'warpAmount', label: 'Lokális torzítás', min: 0, max: 0.18, step: 0.01, default: 0.05 },
  { key: 'warpScale', label: 'Torzítás méret', min: 0.4, max: 3, step: 0.01, default: 1.35 },
  { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.10 },
]),
'balance-counterflow': Object.freeze([
  { key: 'intrusion', label: 'Benyúlás', min: 0, max: 0.32, step: 0.01, default: 0.15 },
  { key: 'lobeCount', label: 'Áramlatpárok', min: 1, max: 6, step: 1, default: 3 },
  { key: 'lobeRadius', label: 'Áramlatsugár', min: 0.08, max: 0.45, step: 0.01, default: 0.22 },
  { key: 'lobeEllipse', label: 'Áramlatnyújtás', min: 0.5, max: 2, step: 0.01, default: 1.15 },
  { key: 'counterPhase', label: 'Ellenfázis', min: 90, max: 270, step: 1, default: 180 },
  { key: 'verticalDrift', label: 'Függőleges sodrás', min: 0, max: 1, step: 0.01, default: 0.12 },
  { key: 'compensation', label: 'Aránykompenzáció', min: 0, max: 1, step: 0.01, default: 0.86 },
  { key: 'lobeSharpness', label: 'Áramlatkarakter', min: 0.5, max: 3, step: 0.01, default: 1.35 },
  { key: 'warpAmount', label: 'Lokális torzítás', min: 0, max: 0.16, step: 0.01, default: 0.04 },
  { key: 'warpScale', label: 'Torzítás méret', min: 0.4, max: 3, step: 0.01, default: 1.20 },
  { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.09 },
]),
'balance-charges': Object.freeze([
  { key: 'seamDrift', label: 'Határvándorlás', min: 0, max: 0.12, step: 0.01, default: 0.035 },
  { key: 'seamWavelength', label: 'Határhullámhossz', min: 0.4, max: 3, step: 0.01, default: 1.45 },
  { key: 'seamSpeed', label: 'Határsebesség', min: 0, max: 1, step: 0.01, default: 0.10 },
  { key: 'chargeCount', label: 'Töltésszám', min: 2, max: 8, step: 1, default: 6 },
  { key: 'chargeSize', label: 'Töltésméret', min: 0.06, max: 0.42, step: 0.01, default: 0.18 },
  { key: 'chargeVariation', label: 'Méretváltozatosság', min: 0, max: 0.7, step: 0.01, default: 0.24 },
  { key: 'chargeWander', label: 'Töltésvándorlás', min: 0, max: 0.32, step: 0.01, default: 0.12 },
  { key: 'chargeLight', label: 'Töltés fényereje', min: 0, max: 1, step: 0.01, default: 0.72 },
  { key: 'chargeChroma', label: 'Töltés színessége', min: 0, max: 1, step: 0.01, default: 0.64 },
  { key: 'sidePhase', label: 'Oldalak fázisa', min: 0, max: 360, step: 1, default: 180 },
  { key: 'chargeMorph', label: 'Töltésmorfológia', min: 0, max: 1, step: 0.01, default: 0.22 },
  { key: 'noiseScale', label: 'Morfológia méret', min: 0.4, max: 3, step: 0.01, default: 1.35 },
]),
```

Implement schema selection exactly as:

```js
const isBalanceMode = (mode) => balanceModeIds.includes(mode);

function controlsForMode(mode) {
  if (!modeControls[mode]) throw new RangeError(`Unknown portal mode: ${mode}`);
  return Object.freeze([
    ...(isBalanceMode(mode) ? balanceCommonControls : commonControls),
    ...modeControls[mode],
  ]);
}
```

Keep the special static settings branch, then make `createModeSettings` reduce `controlsForMode(mode)`.

- [ ] **Step 4: Implement the shared coordinate mapping and samplers**

Use one semantic mapping for all modes:

```js
function mapMoneyFlowCoordinate(x, baseSplit, boundary) {
  if (x <= boundary) return baseSplit * (x / Math.max(1e-6, boundary));
  return baseSplit + ((1 - baseSplit)
    * ((x - boundary) / Math.max(1e-6, 1 - boundary)));
}

function finishMoneyFlowField(x, baseSplit, animatedBoundary, rawLight, rawChroma, phase, settings) {
  const strength = clamp01(settings.strength);
  if (strength === 0) {
    return { coordinate: x, boundary: baseSplit, light: 0, chroma: 0,
      side: x <= baseSplit ? 'income' : 'expense' };
  }
  const boundary = Math.max(0.04, Math.min(0.96,
    lerp(baseSplit, animatedBoundary, strength)));
  const seamDistance = Math.abs(x - boundary);
  const seamEnergy = Math.exp(-seamDistance / Math.max(0.01, settings.seamSoftness));
  const pulse = Math.sin(phase * settings.pulseSpeed * Math.PI * 2)
    * settings.pulseAmount * seamEnergy;
  return {
    coordinate: clamp01(mapMoneyFlowCoordinate(x, baseSplit, boundary)),
    boundary,
    light: Math.max(-0.22, Math.min(0.22,
      ((rawLight * settings.lightAmount) + pulse) * strength)),
    chroma: Math.max(-0.35, Math.min(0.35,
      rawChroma * settings.chromaAmount * strength)),
    side: x <= boundary ? 'income' : 'expense',
  };
}
```

Use these deterministic formulas (the implementation may extract repeated noise/charge helpers without changing the equations):

```js
function sampleBalanceMembrane(x, y, phase, baseSplit, settings) {
  const phaseOffset = settings.nodePhase * Math.PI / 180;
  const drift = phase * settings.driftSpeed * Math.PI * 2;
  const primary = Math.sin((y / settings.primaryWavelength) * Math.PI * 2 + drift);
  const secondary = Math.sin(
    (y / settings.secondaryWavelength) * Math.PI * 2 - (drift * 0.71) + phaseOffset,
  );
  const warp = ((fbm(
    (y * settings.warpScale) + (phase * settings.warpSpeed * 0.08),
    (phase * settings.warpSpeed * 0.06) + 0.37,
    701.3,
  ) - 0.5) * 2) * settings.warpAmount;
  const damping = 1 - (settings.tension * 0.72);
  const deformation = ((primary * settings.boundaryAmplitude)
    + (secondary * settings.secondaryAmplitude) + warp) * damping;
  return finishMoneyFlowField(
    x, baseSplit, baseSplit + deformation,
    Math.abs(primary * 0.68 + secondary * 0.32), warp,
    phase, settings,
  );
}

function sampleBalanceCounterflow(x, y, phase, baseSplit, settings) {
  const drift = phase * settings.verticalDrift * Math.PI * 2;
  const angle = (y * settings.lobeCount * Math.PI * 2) + drift;
  const counter = settings.counterPhase * Math.PI / 180;
  const aWave = Math.sin(angle);
  const bWave = Math.sin((angle * settings.lobeEllipse) + counter);
  const paired = aWave - (bWave * settings.compensation);
  const shaped = Math.sign(paired)
    * Math.pow(Math.abs(paired), settings.lobeSharpness);
  const radiusGain = settings.lobeRadius / 0.22;
  const warp = ((fbm(
    (y * settings.warpScale) - (phase * settings.warpSpeed * 0.07),
    (phase * settings.warpSpeed * 0.05) + 0.73,
    811.9,
  ) - 0.5) * 2) * settings.warpAmount;
  const deformation = (shaped * settings.intrusion * radiusGain * 0.5) + warp;
  return finishMoneyFlowField(
    x, baseSplit, baseSplit + deformation,
    Math.abs(paired) * 0.72, shaped * 0.55,
    phase, settings,
  );
}

const balanceChargeSeeds = Object.freeze([
  [0.16, 0.18, 0.7], [0.34, 0.72, 1.9], [0.56, 0.36, 3.2],
  [0.78, 0.81, 4.6], [0.88, 0.22, 6.1], [0.44, 0.54, 7.8],
  [0.24, 0.88, 9.4], [0.68, 0.10, 11.2],
]);

function sampleBalanceCharges(x, y, phase, baseSplit, settings) {
  const seam = Math.sin(
    (y / settings.seamWavelength) * Math.PI * 2
      + (phase * settings.seamSpeed * Math.PI * 2),
  ) * settings.seamDrift;
  const boundary = baseSplit + seam;
  const side = x <= boundary ? 0 : 1;
  const sidePhase = settings.sidePhase * Math.PI / 180;
  const count = Math.max(2, Math.min(8, Math.round(settings.chargeCount)));
  let light = 0;
  let chroma = 0;
  for (let index = 0; index < count; index += 1) {
    if (index % 2 !== side) continue;
    const [seedX, seedY, seed] = balanceChargeSeeds[index];
    const sideStart = side === 0 ? 0 : baseSplit;
    const sideWidth = side === 0 ? baseSplit : 1 - baseSplit;
    const centerX = sideStart + (sideWidth * (0.12 + (seedX * 0.76)))
      + (Math.sin(phase * 0.13 + seed) * settings.chargeWander * sideWidth);
    const centerY = seedY
      + (Math.cos(phase * 0.11 + seed) * settings.chargeWander);
    const variation = 1 + (((index / Math.max(1, count - 1)) - 0.5)
      * settings.chargeVariation);
    const morph = 1 + (Math.sin(phase * 0.17 + seed * settings.noiseScale)
      * settings.chargeMorph * 0.35);
    const radius = Math.max(0.03, settings.chargeSize * variation * morph);
    const charge = gaussian(x - centerX, y - centerY, radius, radius * 0.82);
    const polarity = Math.sin(phase * 0.16 + seed + (side * sidePhase));
    light += charge * polarity * settings.chargeLight;
    chroma += charge * polarity * settings.chargeChroma;
  }
  return finishMoneyFlowField(
    x, baseSplit, boundary, light, chroma, phase, settings,
  );
}
```

Dispatch them in `sampleMoneyFlowField`; throw `RangeError` for non-Balance mode IDs. Export `balanceModeIds`, `controlsForMode`, `isBalanceMode`, and `sampleMoneyFlowField`.

- [ ] **Step 5: Run GREEN and unchanged-existing-mode verification**

Run:

```sh
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: `Portal energy field checks passed`, including the original mode fixture assertions.

---

### Task 3: Fourth Signature Row and Static Five-stop Header

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Produces DOM: `[data-mind-portal-signature-slider="money-flow"]`
- Produces DOM: `[data-mind-portal-money-flow-input]`
- Produces CSS variables: `--mind-portal-money-flow-1` through `--mind-portal-money-flow-5`, `--mind-portal-static-bg`
- Produces controller: `applyMindPortalMoneyFlow(incomePercent)`
- Consumes Task 1 `moneyFlowStopPositions` and palette constants.

- [ ] **Step 1: Add failing static assertions**

Add assertions that the extracted portal lab contains exactly four signature sliders, the Money-flow row, the five palette hexes, `50–50`, a 0–100 numeric input, and the following controller contracts:

```js
assert.strictEqual(
  (rebuiltPortalLab.match(/data-mind-portal-signature-slider=/g) || []).length,
  4,
);
for (const token of [
  'data-mind-portal-signature-slider="money-flow"',
  'data-mind-portal-signature-value="money-flow"',
  'data-mind-portal-money-flow-input',
  '50–50',
]) assert(rebuiltPortalLab.includes(token), `Missing Money-flow UI token: ${token}`);
for (const color of ['#49cfc5', '#8defe5', '#f8e8f3', '#f7b2f5', '#d8b4fe']) {
  assert(html.includes(color), `Missing Money-flow palette color: ${color}`);
}

assert(
  html.includes('function applyMindPortalMoneyFlow(incomePercent)') &&
  html.includes('MindPortalEnergy.moneyFlowStopPositions') &&
  html.includes("data-mind-portal-signature-source', 'money-flow'") &&
  html.includes("data-mind-portal-money-flow-income") &&
  html.includes("`${income}–${100 - income}`"),
  'Money-flow slider must drive the five-stop static ratio gradient',
);
```

- [ ] **Step 2: Run RED verification**

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: FAIL with missing Money-flow signature UI.

- [ ] **Step 3: Add compact row and static-background CSS**

Add a fourth `.mind-portal-signature-row` after Cool:

```html
<label class="mind-portal-signature-row" data-signature-kind="money-flow">
  <span>Money flow</span>
  <input type="range" min="0" max="100" step="1" value="50"
    data-mind-portal-signature-slider="money-flow"
    aria-label="Portal bevétel kiadás arány">
  <em data-mind-portal-signature-value="money-flow">50–50</em>
  <input class="mind-portal-signature-window-input mind-portal-money-flow-input"
    type="number" min="0" max="100" step="1" value="50" inputmode="numeric"
    data-mind-portal-money-flow-input aria-label="Bevétel százalék">
</label>
```

Give this row a turquoise accent:

```css
.mind-portal-signature-row[data-signature-kind="money-flow"] input[type="range"] {
  accent-color: #49cfc5;
}
```

Replace the test-header static pseudo background with:

```css
background: var(--mind-portal-static-bg,
  linear-gradient(90deg, var(--mind-portal-color-a) 0%, var(--mind-portal-color-b) 100%));
```

Do not edit any touch/trail selectors.

- [ ] **Step 4: Implement last-writer-wins Money-flow wiring**

Keep `buildMindPortalSignature` unchanged for its three existing kinds. Add:

```js
function applyMindPortalMoneyFlow(incomePercent) {
  const income = Math.round(clampValue(Number(incomePercent), 0, 100));
  const expense = 100 - income;
  const palette = MindPortalEnergy.moneyFlowPaletteHex;
  const positions = MindPortalEnergy.moneyFlowStopPositions(income);
  const gradient = `linear-gradient(90deg, ${palette.map((color, index) =>
    `${color} ${(positions[index] * 100).toFixed(2)}%`).join(', ')})`;
  document.querySelectorAll('[data-mind-portal-test-header] .mind-portal-test-header')
    .forEach((header) => {
      palette.forEach((color, index) => {
        header.style.setProperty(`--mind-portal-money-flow-${index + 1}`, color);
      });
      header.style.setProperty('--mind-portal-color-a', palette[0]);
      header.style.setProperty('--mind-portal-color-b', palette[4]);
      header.style.setProperty('--mind-portal-static-bg', gradient);
      header.style.setProperty('--spendee-header-bg', gradient);
      header.style.setProperty('--spendee-header-glow', buildSpendeeHeaderGlow(gradient));
      header.style.setProperty('--spendee-header-gloss-accent', buildReactiveGlassAccent(gradient));
      header.setAttribute('data-mind-portal-signature-source', 'money-flow');
      header.setAttribute('data-mind-portal-money-flow-income', String(income));
    });
  document.querySelectorAll('[data-mind-portal-signature-value="money-flow"]')
    .forEach((label) => { label.textContent = `${income}–${expense}`; });
  document.querySelectorAll('[data-mind-portal-signature-slider="money-flow"]')
    .forEach((slider) => { slider.value = String(income); });
  document.querySelectorAll('[data-mind-portal-money-flow-input]')
    .forEach((input) => { input.value = String(income); });
  document.querySelectorAll('[data-mind-portal-signature-source-label]')
    .forEach((label) => { label.textContent = 'Money flow'; });
}
```

Update `applyMindPortalTestHeaderColors` to set `--mind-portal-static-bg` to the exact existing two-color gradient, so returning from Money flow to Traffic/Limit/Cool restores the original path.

In `initMindPortalTestSignatureControls`, use this dispatch and synchronization while keeping the initial signature `Traffic`:

```js
const applySlider = (slider) => {
  const kind = slider.dataset.mindPortalSignatureSlider;
  if (kind === 'money-flow') applyMindPortalMoneyFlow(slider.value);
  else applyMindPortalSignature(kind, slider.value, windowFor(kind));
};

panel.querySelectorAll('[data-mind-portal-money-flow-input]').forEach((input) => {
  const applyRatioInput = () => {
    if (input.value === '' || !Number.isFinite(Number(input.value))) return;
    applyMindPortalMoneyFlow(input.value);
  };
  input.addEventListener('input', applyRatioInput);
  input.addEventListener('change', applyRatioInput);
});
```

- [ ] **Step 5: Run GREEN verification**

Run:

```sh
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
```

Expected: both success messages.

---

### Task 4: Dropdown, Controls, and Single-canvas Balance Rendering

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: `MindPortalEnergy.isBalanceMode`, `controlsForMode`, `sampleMoneyFlowField`, `sampleMoneyFlowColor`.
- Preserves: the current non-Balance `sampleField` → `sampleColor` branch.

- [ ] **Step 1: Add failing dropdown and canvas-branch assertions**

Assert that all first five options still exist and that these three are appended:

```html
<option value="balance-membrane">Balance membrán</option>
<option value="balance-counterflow">Balance ellenáram</option>
<option value="balance-charges">Balance töltések</option>
```

Assert source contracts:

```js
assert(
  html.includes('MindPortalEnergy.controlsForMode(mode)') &&
  html.includes('MindPortalEnergy.isBalanceMode(activeMode)') &&
  html.includes('MindPortalEnergy.sampleMoneyFlowField(') &&
  html.includes('MindPortalEnergy.sampleMoneyFlowColor(') &&
  html.includes('applyMindPortalMoneyFlow('),
  'Balance modes must reuse the active controls and single canvas lifecycle',
);
```

Keep the existing touch function hashes in the same test file unchanged.

- [ ] **Step 2: Run RED verification**

Run `node docs/prototypes/color_lab_static_test.js`.

Expected: FAIL on the new dropdown/canvas assertions.

- [ ] **Step 3: Append dropdown options and schema selection**

Append the three `<option>` elements after `Celluláris mező`. In `renderMindPortalEnergyControls`, replace the direct shared-schema spread with:

```js
const schema = MindPortalEnergy.controlsForMode(mode);
```

No other control row or scroll-routing code changes.

- [ ] **Step 4: Activate the semantic signature for a Balance mode**

In `setMindPortalEnergyMode`, when `MindPortalEnergy.isBalanceMode(mode)` is true, read the Money-flow slider's current value and call `applyMindPortalMoneyFlow`:

```js
if (MindPortalEnergy.isBalanceMode(mode)) {
  const ratioSlider = wrap?.querySelector('[data-mind-portal-signature-slider="money-flow"]');
  applyMindPortalMoneyFlow(ratioSlider?.value || 50);
}
```

This makes the dropdown name and visible semantic palette agree while retaining the stored settings for all modes.

Do not reset the ratio during mode reset.

- [ ] **Step 5: Add the Balance branch inside the existing pixel loop**

Before the loop, parse the five palette colors once per frame and read `incomePercent` from `data-mind-portal-money-flow-income`:

```js
const incomePercent = Math.max(0, Math.min(100,
  Number(header.getAttribute('data-mind-portal-money-flow-income') || 50)));
const moneyFlowPalette = MindPortalEnergy.moneyFlowPaletteHex.map((hex) =>
  mindPortalEnergyColor(hex, { r: 255, g: 255, b: 255 }));
```

Inside the existing loop use:

```js
let color;
if (MindPortalEnergy.isBalanceMode(activeMode)) {
  const sample = MindPortalEnergy.sampleMoneyFlowField(
    activeMode, sx, sy, phase, incomePercent, settings,
  );
  sample.light = Math.max(-0.22, Math.min(0.22, sample.light + (pulse * 0.025)));
  color = MindPortalEnergy.sampleMoneyFlowColor(moneyFlowPalette, incomePercent, sample);
} else {
  const sample = MindPortalEnergy.sampleField(activeMode, sx, sy, phase, settings);
  sample.light = Math.max(-0.25, Math.min(0.25, sample.light + (pulse * 0.025)));
  color = MindPortalEnergy.sampleColor(colorA, colorB, sample);
}
```

Write the resulting RGB through the existing `ImageData`. Do not add a canvas or requestAnimationFrame.

- [ ] **Step 6: Run GREEN verification**

Run:

```sh
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node --check docs/prototypes/color_lab_static_test.js
node --check docs/prototypes/color_lab_portal_energy.js
```

Expected: both suites pass and both parse checks exit 0.

---

### Task 5: Full Regression, Runtime Smoke, and Honest Checklist Status

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: evidence lines for `COLOR-LAB-295` through `COLOR-LAB-300`.

- [ ] **Step 1: Verify inline scripts parse**

Run:

```sh
node - <<'NODE'
const fs = require('fs');
const vm = require('vm');
const html = fs.readFileSync('docs/prototypes/color_lab.html', 'utf8');
const scripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
  .filter((match) => !/\bsrc=/.test(match[0]));
scripts.forEach((match, index) => new vm.Script(match[1], {
  filename: `color_lab.inline.${index + 1}.js`,
}));
console.log(`Inline scripts parse: ${scripts.length}`);
NODE
```

Expected: `Inline scripts parse: 1` and exit 0.

- [ ] **Step 2: Run full automated regression**

Run:

```sh
node docs/prototypes/color_lab_static_test.js
node docs/prototypes/color_lab_portal_energy_test.js
node --check docs/prototypes/color_lab_static_test.js
node --check docs/prototypes/color_lab_portal_energy.js
git diff --check
```

Expected: success messages, parse exit 0, and no whitespace errors.

- [ ] **Step 3: Run HTTP smoke verification**

Run:

```sh
node - <<'NODE'
const http = require('http');
http.get('http://127.0.0.1:8765/docs/prototypes/color_lab.html', (response) => {
  let body = '';
  response.setEncoding('utf8');
  response.on('data', (chunk) => { body += chunk; });
  response.on('end', () => {
    const required = [
      'data-mind-portal-signature-slider="money-flow"',
      'data-mind-portal-money-flow-input',
      'value="balance-membrane"',
      'value="balance-counterflow"',
      'value="balance-charges"',
      '#49cfc5', '#8defe5', '#f8e8f3', '#f7b2f5', '#d8b4fe',
      'max-height: min(30vh, 240px)',
    ];
    if (response.statusCode !== 200 || required.some((token) => !body.includes(token))) {
      process.exitCode = 1;
      return;
    }
    console.log('HTTP smoke: balance money-flow portal present');
  });
}).on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
NODE
```

This asserts the response includes:

- `data-mind-portal-signature-slider="money-flow"`;
- `data-mind-portal-money-flow-input`;
- the three `balance-*` dropdown values;
- the five palette hex values;
- the compact `min(30vh, 240px)` controls viewport.

Expected: `HTTP smoke: balance money-flow portal present`.

- [ ] **Step 4: Re-read the acceptance checklist and update evidence**

For `COLOR-LAB-295`–`300`, record automated RED/GREEN, parse, invariant, and HTTP evidence. Mark code-verifiable parts `DONE` only when every acceptance condition is automated; keep screenshot/touch-facing rows `PARTIAL` until Android evidence exists.

- [ ] **Step 5: Request visual evidence without overstating completion**

Ask the user to refresh the prototype and provide screenshots for `0–100`, `50–50`, `100–0`, plus each new mode. Report automated status separately from pending visual/mobile verification.
