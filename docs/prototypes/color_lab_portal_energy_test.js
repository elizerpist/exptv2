const assert = require('assert');
const energy = require('./color_lab_portal_energy.js');

assert.deepStrictEqual(energy.modeOrder, [
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
  'balance-membrane',
  'balance-counterflow',
  'balance-charges',
]);

const existingAnimatedModes = [
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
];

for (const mode of existingAnimatedModes) {
  const settings = energy.createModeSettings(mode);
  const schema = [...energy.commonControls, ...energy.modeControls[mode]];
  assert(schema.length >= 28, `${mode} must expose maximum-detail controls`);
  assert.strictEqual(new Set(schema.map(({ key }) => key)).size, schema.length);
  for (const meta of schema) {
    assert(Number.isFinite(settings[meta.key]), `${mode}.${meta.key} needs a default`);
    assert(settings[meta.key] >= meta.min && settings[meta.key] <= meta.max);
  }
}

for (const mode of ['static', ...existingAnimatedModes]) {
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

for (const mode of existingAnimatedModes) {
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

for (const mode of existingAnimatedModes) {
  const base = energy.createModeSettings(mode);
  const fixtures = [
    [0.19, 0.23, 2.7],
    [0.37, 0.61, 7.3],
    [0.79, 0.82, 13.1],
    [0.52, 0.14, 21.7],
  ];
  const baseSamples = fixtures.map(([x, y, phase]) =>
    energy.sampleField(mode, x, y, phase, base));
  for (const meta of [...energy.commonControls, ...energy.modeControls[mode]]) {
    if (['speed', 'renderScale', 'frameMs'].includes(meta.key)) continue;
    const changed = {
      ...base,
      [meta.key]: base[meta.key] === meta.max ? meta.min : meta.max,
    };
    const probes = fixtures.map(([x, y, phase]) =>
      energy.sampleField(mode, x, y, phase, changed));
    assert(
      probes.some((probe, index) =>
        Math.abs(probe.mix - baseSamples[index].mix) > 1e-6 ||
        Math.abs(probe.light - baseSamples[index].light) > 1e-6),
      `${mode}.${meta.key} must measurably affect the field`,
    );
  }
}

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
assert.deepStrictEqual(
  Array.from(energy.moneyFlowStopPositions(50)),
  [0, 0.2, 0.5, 0.8, 1],
  'money-flow 50-50 balance must have a wide turquoise-white-purple fade region',
);

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

assert.deepStrictEqual(energy.modeOrder.slice(0, 5), [
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
]);
assert.deepStrictEqual(energy.balanceModeIds, [
  'balance-membrane',
  'balance-counterflow',
  'balance-charges',
]);

for (const mode of energy.balanceModeIds) {
  const schema = energy.controlsForMode(mode);
  const settings = energy.createModeSettings(mode);
  assert(schema.length >= 16, `${mode} needs detailed controls`);
  assert.strictEqual(new Set(schema.map(({ key }) => key)).size, schema.length);
  for (const meta of schema) {
    assert(Number.isFinite(settings[meta.key]), `${mode}.${meta.key} needs a default`);
    assert(settings[meta.key] >= meta.min && settings[meta.key] <= meta.max);
  }
  for (const ratio of [0, 50, 100]) {
    for (const phase of [0, 3.25, 17.5]) {
      for (const x of [0, 0.17, 0.5, 0.83, 1]) {
        for (const y of [0, 0.5, 1]) {
          const sample = energy.sampleMoneyFlowField(
            mode,
            x,
            y,
            phase,
            ratio,
            settings,
          );
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
    assert(
      probes.some((probe, index) =>
        Math.abs(probe.coordinate - baseSamples[index].coordinate) > 1e-6 ||
        Math.abs(probe.boundary - baseSamples[index].boundary) > 1e-6 ||
        Math.abs(probe.light - baseSamples[index].light) > 1e-6 ||
        Math.abs(probe.chroma - baseSamples[index].chroma) > 1e-6),
      `${mode}.${meta.key} must measurably affect the field`,
    );
  }
}

for (const mode of energy.balanceModeIds) {
  const settings = energy.createModeSettings(mode);
  for (const ratio of [0, 50, 100]) {
    const split = energy.moneyFlowVisualSplit(ratio);
    for (const phase of [0, 2.5, 5, 7.5, 10]) {
      let boundarySum = 0;
      const sampleCount = 401;
      for (let index = 0; index < sampleCount; index += 1) {
        const y = index / (sampleCount - 1);
        boundarySum += energy.sampleMoneyFlowField(
          mode,
          split,
          y,
          phase,
          ratio,
          settings,
        ).boundary;
      }
      const averageBoundary = boundarySum / sampleCount;
      assert(
        Math.abs(averageBoundary - split) < 0.0025,
        `${mode} must preserve ratio ${ratio} at phase ${phase}: ${averageBoundary}`,
      );
    }
  }
}

for (const mode of energy.balanceModeIds) {
  const stressed = energy.createModeSettings(mode);
  for (const meta of energy.controlsForMode(mode)) {
    if (!['speed', 'renderScale', 'frameMs'].includes(meta.key)) {
      stressed[meta.key] = meta.max;
    }
  }
  for (const ratio of [0, 50, 100]) {
    const split = energy.moneyFlowVisualSplit(ratio);
    for (const phase of [0, 1.25, 3.75, 9.5]) {
      let boundarySum = 0;
      const sampleCount = 401;
      for (let index = 0; index < sampleCount; index += 1) {
        const y = index / (sampleCount - 1);
        const center = energy.sampleMoneyFlowField(
          mode,
          split,
          y,
          phase,
          ratio,
          stressed,
        );
        const left = energy.sampleMoneyFlowField(
          mode,
          0,
          y,
          phase,
          ratio,
          stressed,
        );
        const right = energy.sampleMoneyFlowField(
          mode,
          1,
          y,
          phase,
          ratio,
          stressed,
        );
        boundarySum += center.boundary;
        assert.strictEqual(left.side, 'income');
        assert.strictEqual(left.coordinate, 0);
        assert.strictEqual(right.side, 'expense');
        assert.strictEqual(right.coordinate, 1);
      }
      assert(
        Math.abs((boundarySum / sampleCount) - split) < 0.0025,
        `${mode} stress controls must preserve ratio ${ratio} at ${phase}`,
      );
    }
  }
}

console.log('Portal energy field checks passed');
