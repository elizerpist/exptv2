const assert = require('assert');
const background = require('./color_lab_portal_background.js');

const expectedModes = [
  'none',
  'energy-compression',
  'refraction-wave',
  'seam-flare',
  'depth-focus',
  'chromatic-alert',
];

const expectedLabels = [
  'Nincs háttéreffekt',
  'Energiakompresszió',
  'Refrakciós hullám',
  'Határfény',
  'Mélységi fókusz',
  'Kromatikus riasztás',
];

const expectedSchemas = {
  'energy-compression': [
    ['duration', 'Időtartam', 300, 2400, 10, 900, 'ms'],
    ['strength', 'Erősség', 0, 100, 1, 62, '%'],
    ['peak', 'Csúcspont', 20, 80, 1, 48, '%'],
    ['centerX', 'Középpont X', 0, 100, 1, 50, '%'],
    ['centerY', 'Középpont Y', 0, 100, 1, 50, '%'],
    ['compression', 'Kompresszió', 0, 40, 1, 18, '%'],
    ['bloom', 'Bloom', 0, 100, 1, 44, '%'],
    ['fieldScale', 'Mezőskála', 70, 130, 1, 92, '%'],
    ['hold', 'Üzenetállapot tartás', 0, 100, 1, 18, '%'],
    ['decay', 'Lecsengés', 0, 100, 1, 66, '%'],
  ],
  'refraction-wave': [
    ['duration', 'Időtartam', 400, 2600, 10, 1120, 'ms'],
    ['strength', 'Erősség', 0, 100, 1, 58, '%'],
    ['peak', 'Csúcspont', 20, 80, 1, 52, '%'],
    ['sourceX', 'Forrás X', 0, 100, 1, 50, '%'],
    ['sourceY', 'Forrás Y', 0, 100, 1, 50, '%'],
    ['radius', 'Hullámsugár', 20, 180, 1, 122, '%'],
    ['ringWidth', 'Gyűrűszélesség', 2, 30, 1, 12, '%'],
    ['rings', 'Gyűrűk', 1, 5, 1, 2, ''],
    ['refraction', 'Töréserő', 0, 40, 1, 16, '%'],
    ['blur', 'Blur', 0, 24, 1, 8, 'px'],
    ['hold', 'Üzenetállapot tartás', 0, 100, 1, 10, '%'],
    ['decay', 'Lecsengés', 0, 100, 1, 70, '%'],
  ],
  'seam-flare': [
    ['duration', 'Időtartam', 300, 2200, 10, 820, 'ms'],
    ['strength', 'Erősség', 0, 100, 1, 58, '%'],
    ['peak', 'Csúcspont', 20, 80, 1, 46, '%'],
    ['width', 'Fénysáv szélesség', 2, 45, 1, 14, '%'],
    ['wander', 'Határvándorlás', 0, 30, 1, 8, '%'],
    ['branching', 'Elágazás', 0, 100, 1, 32, '%'],
    ['bloom', 'Bloom', 0, 100, 1, 48, '%'],
    ['phase', 'Vertikális fázis', 0, 360, 1, 110, '°'],
    ['hold', 'Üzenetállapot tartás', 0, 100, 1, 24, '%'],
    ['decay', 'Lecsengés', 0, 100, 1, 68, '%'],
  ],
  'depth-focus': [
    ['duration', 'Időtartam', 300, 2200, 10, 880, 'ms'],
    ['strength', 'Erősség', 0, 100, 1, 48, '%'],
    ['peak', 'Csúcspont', 20, 80, 1, 50, '%'],
    ['focusX', 'Fókusz X', 0, 100, 1, 50, '%'],
    ['focusY', 'Fókusz Y', 0, 100, 1, 48, '%'],
    ['radius', 'Fókuszsugár', 20, 100, 1, 62, '%'],
    ['vignette', 'Peremsötétítés', 0, 100, 1, 36, '%'],
    ['depthScale', 'Mélységskála', 90, 110, 1, 97, '%'],
    ['centerLight', 'Középfény', 0, 100, 1, 30, '%'],
    ['blur', 'Blur', 0, 20, 1, 5, 'px'],
    ['hold', 'Üzenetállapot tartás', 0, 100, 1, 34, '%'],
    ['decay', 'Lecsengés', 0, 100, 1, 72, '%'],
  ],
  'chromatic-alert': [
    ['duration', 'Időtartam', 300, 2200, 10, 760, 'ms'],
    ['strength', 'Erősség', 0, 100, 1, 56, '%'],
    ['peak', 'Csúcspont', 20, 80, 1, 42, '%'],
    ['overlayOpacity', 'Overlay opacity', 0, 45, 1, 24, '%'],
    ['pinkRatio', 'Rózsaszín arány', 0, 100, 1, 58, '%'],
    ['lilacRatio', 'Lila arány', 0, 100, 1, 42, '%'],
    ['spread', 'Terjedés', 20, 160, 1, 96, '%'],
    ['pulses', 'Pulzusszám', 1, 4, 1, 2, ''],
    ['blur', 'Blur', 0, 24, 1, 9, 'px'],
    ['hold', 'Üzenetállapot tartás', 0, 100, 1, 12, '%'],
    ['decay', 'Lecsengés', 0, 100, 1, 64, '%'],
  ],
};

function schemaTuple(meta) {
  return [meta.key, meta.label, meta.min, meta.max, meta.step, meta.default, meta.unit];
}

function assertMonotonicOffsets(frames, message) {
  let previous = -Infinity;
  frames.forEach((frame) => {
    assert(Number.isFinite(frame.offset), `${message}: every frame needs an offset`);
    assert(frame.offset >= previous, `${message}: offsets must be monotonic`);
    assert(frame.offset >= 0 && frame.offset <= 1, `${message}: offsets must be bounded`);
    previous = frame.offset;
  });
}

assert.deepStrictEqual(background.modeOrder, expectedModes);
assert.deepStrictEqual(expectedModes.map((mode) => background.modeLabels[mode]), expectedLabels);
assert.deepStrictEqual(background.controlsForMode('none'), []);
assert.deepStrictEqual(background.createModeSettings('none'), {});

for (const mode of expectedModes.slice(1)) {
  const controls = background.controlsForMode(mode);
  assert.deepStrictEqual(controls.map(schemaTuple), expectedSchemas[mode]);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  const settings = background.createModeSettings(mode);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(background.normalizeValue(meta, meta.min - 1000), meta.min);
    assert.strictEqual(background.normalizeValue(meta, meta.max + 1000), meta.max);
    assert.strictEqual(background.normalizeValue(meta, ''), meta.default);
  });
}

const noEffect = background.buildResponse('none', {}, 'message', {}, false);
assert.deepStrictEqual(noEffect, {
  mode: 'none',
  targetState: 'message',
  duration: 0,
  easing: 'linear',
  keyframes: [],
  balanceRest: {},
  messageRest: {},
  configuration: {},
});
assert.deepStrictEqual(
  background.buildResponse('unknown-mode', {}, 'message', {}, false),
  noEffect,
  'Unknown response modes must fall back to the exact no-effect baseline',
);

const visualSignatures = new Set();
for (const mode of expectedModes.slice(1)) {
  const settings = background.createModeSettings(mode);
  const context = { signature: 'money-flow', incomePercent: 25 };
  const forward = background.buildResponse(mode, settings, 'message', context, false);
  const backward = background.buildResponse(mode, settings, 'balance', context, false);

  assert.strictEqual(forward.mode, mode);
  assert.strictEqual(forward.targetState, 'message');
  assert.strictEqual(backward.targetState, 'balance');
  assert.strictEqual(forward.duration, settings.duration);
  assert(forward.keyframes.length >= 3);
  assert(backward.keyframes.length >= 3);
  assertMonotonicOffsets(forward.keyframes, `${mode} forward`);
  assertMonotonicOffsets(backward.keyframes, `${mode} backward`);
  assert.deepStrictEqual(forward.keyframes[0], forward.balanceRest);
  assert.deepStrictEqual(forward.keyframes.at(-1), forward.messageRest);
  assert.deepStrictEqual(backward.keyframes[0], backward.messageRest);
  assert.deepStrictEqual(backward.keyframes.at(-1), backward.balanceRest);
  assert.strictEqual(forward.balanceRest.opacity, 0);
  assert.strictEqual(backward.balanceRest.opacity, 0);
  assert(forward.keyframes.some((frame) => frame.opacity > forward.messageRest.opacity));

  const serialized = JSON.stringify(forward);
  assert(!/canvas|touch|trail|signatureValue|colorA|colorB/i.test(serialized));
  visualSignatures.add(JSON.stringify({ frames: forward.keyframes, config: forward.configuration }));

  for (const meta of background.controlsForMode(mode)) {
    const changed = {
      ...settings,
      [meta.key]: settings[meta.key] === meta.max ? meta.min : meta.max,
    };
    assert.notStrictEqual(
      JSON.stringify(background.buildResponse(mode, changed, 'message', context, false)),
      JSON.stringify(forward),
      `${mode}.${meta.key} must measurably affect its response descriptor`,
    );
  }
}
assert.strictEqual(visualSignatures.size, 5, 'Every animated mode needs a distinct descriptor');

const seamResponse = background.buildResponse(
  'seam-flare',
  background.createModeSettings('seam-flare'),
  'message',
  { signature: 'money-flow', incomePercent: 0 },
  false,
);
assert.strictEqual(seamResponse.configuration['--portal-response-seam'], '50%');
const seamContexts = [0, 50, 100].map((incomePercent) => background.buildResponse(
  'seam-flare',
  background.createModeSettings('seam-flare'),
  'message',
  { signature: 'money-flow', incomePercent },
  false,
));
assert.deepStrictEqual(seamContexts[0], seamContexts[1]);
assert.deepStrictEqual(seamContexts[1], seamContexts[2]);
const midpointSeam = background.buildResponse(
  'seam-flare',
  background.createModeSettings('seam-flare'),
  'message',
  { signature: 'balanced', incomePercent: 0 },
  false,
);
assert.strictEqual(midpointSeam.configuration['--portal-response-seam'], '50%');

const defaultCompression = background.buildResponse(
  'energy-compression',
  background.createModeSettings('energy-compression'),
  'message',
  {},
  false,
);
assert.strictEqual(defaultCompression.configuration['--portal-response-bloom-stop'], '15.28%');
assert.strictEqual(defaultCompression.configuration['--portal-response-compression-stop'], '35.24%');
const defaultRefraction = background.buildResponse(
  'refraction-wave',
  background.createModeSettings('refraction-wave'),
  'message',
  {},
  false,
);
assert.strictEqual(defaultRefraction.configuration['--portal-response-ring-highlight'], '1.92%');
assert.strictEqual(defaultRefraction.configuration['--portal-response-ring-color'], '4.08%');
assert.strictEqual(defaultRefraction.configuration['--portal-response-ring-fade'], '8.64%');
assert.strictEqual(defaultRefraction.configuration['--portal-response-field-size'], '104%');
assert.strictEqual(seamResponse.configuration['--portal-response-seam-inner-width'], '8.96%');
const defaultDepth = background.buildResponse(
  'depth-focus',
  background.createModeSettings('depth-focus'),
  'message',
  {},
  false,
);
assert.strictEqual(defaultDepth.configuration['--portal-response-center-alpha'], '0.36');
assert.strictEqual(defaultDepth.configuration['--portal-response-vignette-alpha'], '0.2304');
const defaultChromatic = background.buildResponse(
  'chromatic-alert',
  background.createModeSettings('chromatic-alert'),
  'message',
  {},
  false,
);
assert.strictEqual(defaultChromatic.configuration['--portal-response-field-size'], '104%');

const chromatic = background.buildResponse(
  'chromatic-alert',
  { ...background.createModeSettings('chromatic-alert'), overlayOpacity: 100 },
  'message',
  {},
  false,
);
for (const frame of [...chromatic.keyframes, chromatic.balanceRest, chromatic.messageRest]) {
  if ('opacity' in frame) assert(frame.opacity <= 0.45, 'Chromatic opacity must stay at or below 45%');
}

for (const mode of expectedModes.slice(1)) {
  const reduced = background.buildResponse(
    mode,
    background.createModeSettings(mode),
    'message',
    {},
    true,
  );
  assert.strictEqual(reduced.duration, 160);
  assert(reduced.keyframes.length >= 2);
  reduced.keyframes.forEach((frame) => {
    assert.deepStrictEqual(Object.keys(frame).sort(), ['offset', 'opacity']);
  });
}

console.log('Portal message background checks passed');
