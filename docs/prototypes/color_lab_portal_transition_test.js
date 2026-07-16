const assert = require('assert');
const transition = require('./color_lab_portal_transition.js');

const expected = {
  'pigment-spread': [
    ['duration', 'Időtartam', 300, 3000, 10, 1100, 'ms'],
    ['seedCount', 'Forrásszám', 1, 12, 1, 5, ''],
    ['sourceSpread', 'Forrásszórás', 0, 100, 1, 62, '%'],
    ['softness', 'Frontlágyság', 0, 100, 1, 78, '%'],
    ['diffusion', 'Diffúzió', 0, 100, 1, 56, '%'],
    ['warp', 'Domain warp', 0, 100, 1, 48, '%'],
    ['matterDelay', 'Portal-B késleltetés', 0, 80, 1, 24, '%'],
    ['overlap', 'Átfedés', 0, 100, 1, 38, '%'],
    ['easing', 'Lágyság', 1, 5, 0.1, 2.4, ''],
  ],
  'island-takeover': [
    ['duration', 'Időtartam', 300, 3000, 10, 1200, 'ms'],
    ['seedCount', 'Magpontok', 2, 14, 1, 6, ''],
    ['initialRadius', 'Kezdősugár', 1, 30, 1, 7, '%'],
    ['growth', 'Növekedési ráta', 10, 200, 1, 96, '%'],
    ['merge', 'Összeolvadás', 0, 100, 1, 58, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 74, '%'],
    ['wander', 'Útvonal-vándorlás', 0, 100, 1, 38, '%'],
    ['matterEmergence', 'B megjelenése', 0, 100, 1, 46, '%'],
    ['overlap', 'Átfedés', 0, 100, 1, 42, '%'],
    ['easing', 'Lágyság', 1, 5, 0.1, 2.3, ''],
  ],
  'liquid-remap': [
    ['duration', 'Időtartam', 300, 3000, 10, 980, 'ms'],
    ['colorStart', 'Színváltás kezdete', 0, 60, 1, 12, '%'],
    ['geometryStart', 'Geometriaváltás kezdete', 0, 60, 1, 28, '%'],
    ['warpScale', 'Warp skála', 20, 200, 1, 108, '%'],
    ['warpStrength', 'Warp erősség', 0, 100, 1, 46, '%'],
    ['flowSpeed', 'Áramlási sebesség', 0, 100, 1, 24, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 68, '%'],
    ['overlap', 'Átfedés', 0, 100, 1, 52, '%'],
    ['easing', 'Lágyság', 1, 5, 0.1, 2.2, ''],
  ],
};

assert.deepStrictEqual(transition.modeOrder, [
  'pigment-spread',
  'island-takeover',
  'liquid-remap',
]);
assert.deepStrictEqual(
  transition.modeOrder.map((id) => transition.modeLabels[id]),
  ['Pigmentterjedés', 'Szigetes átalakulás', 'Folyékony színátírás'],
);

const tuples = (mode) => transition.controlsForMode(mode).map((control) => [
  control.key,
  control.label,
  control.min,
  control.max,
  control.step,
  control.default,
  control.unit,
]);

for (const mode of transition.modeOrder) {
  assert.deepStrictEqual(tuples(mode), expected[mode]);
  const schema = transition.controlsForMode(mode);
  assert.strictEqual(new Set(schema.map(({ key }) => key)).size, schema.length);
  assert.deepStrictEqual(
    transition.createModeSettings(mode),
    Object.fromEntries(schema.map(({ key, default: value }) => [key, value])),
  );

  for (const control of schema) {
    assert.strictEqual(transition.normalizeValue(control, control.min - 10000), control.min);
    assert.strictEqual(transition.normalizeValue(control, control.max + 10000), control.max);
    assert.strictEqual(transition.normalizeValue(control, ''), control.default);
  }
}

const grid = [];
for (let y = 0; y < 4; y += 1) {
  for (let x = 0; x < 6; x += 1) grid.push([x / 5, y / 3]);
}
const signatureProgresses = {
  'pigment-spread': [0.05, 0.12, 0.22, 0.53],
  'island-takeover': [0.025, 0.06, 0.11, 0.18, 0.35, 0.53],
  'liquid-remap': [0.15, 0.29, 0.53, 0.77],
};
const probeProgress = {
  'pigment-spread': 0.1,
  'island-takeover': 0.1,
  'liquid-remap': 0.53,
};
const signature = (mode, settings, progresses = signatureProgresses[mode]) => progresses.flatMap(
  (progress) => grid.flatMap(([x, y]) => {
    const channels = transition.sampleChannels(mode, x, y, progress, settings);
    return [channels.base.toFixed(6), channels.matter.toFixed(6)];
  }),
);

for (const mode of transition.modeOrder) {
  const settings = transition.createModeSettings(mode);
  for (const [x, y] of grid) {
    assert.deepStrictEqual(transition.sampleChannels(mode, x, y, 0, settings), {
      base: 0,
      matter: 0,
    });
    assert.deepStrictEqual(transition.sampleChannels(mode, x, y, 1, settings), {
      base: 1,
      matter: 1,
    });
    const channels = transition.sampleChannels(mode, x, y, probeProgress[mode], settings);
    assert(channels.base >= 0 && channels.base <= 1);
    assert(channels.matter >= 0 && channels.matter <= 1);
  }

  const middle = grid.map(([x, y]) => (
    transition.sampleChannels(mode, x, y, probeProgress[mode], settings)
  ));
  const spatialKey = ({ base, matter }) => `${base.toFixed(5)}:${matter.toFixed(5)}`;
  assert(new Set(middle.map(({ base, matter }) => `${base.toFixed(5)}:${matter.toFixed(5)}`)).size > 2);
  assert(new Set(middle.slice(0, 6).map(spatialKey)).size > 1);
  assert(new Set([0, 6, 12, 18].map((index) => spatialKey(middle[index]))).size > 1);

  const baseline = signature(mode, settings);
  for (const control of transition.controlsForMode(mode)) {
    const alternative = control.default === control.min ? control.max : control.min;
    const changedSettings = { ...settings, [control.key]: alternative };
    if (control.key === 'duration' || control.key === 'easing') {
      const before = transition.buildDescriptor(mode, settings, 'message', false);
      const after = transition.buildDescriptor(mode, changedSettings, 'message', false);
      assert.notDeepStrictEqual(after, before, `${mode}.${control.key} must affect its descriptor`);
    } else {
      assert.notDeepStrictEqual(
        signature(mode, changedSettings),
        baseline,
        `${mode}.${control.key} must affect the sampled transition`,
      );
    }
  }
}

const descriptor = transition.buildDescriptor(
  'pigment-spread',
  transition.createModeSettings('pigment-spread'),
  'message',
  false,
);
assert.strictEqual(descriptor.mode, 'pigment-spread');
assert.strictEqual(descriptor.duration, 1100);
assert.strictEqual(descriptor.targetState, 'message');
assert.strictEqual(descriptor.reducedMotion, false);
assert.match(descriptor.easing, /^cubic-bezier\(/);
assert.strictEqual(
  transition.buildDescriptor('pigment-spread', {}, 'balance', true).duration,
  160,
);

console.log('Portal transition checks passed');
