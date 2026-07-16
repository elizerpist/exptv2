const assert = require('assert');
const energy = require('./color_lab_portal_energy.js');
const color = require('./color_lab_portal_color.js');

assert.deepStrictEqual(color.modeOrder, [
  'none',
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
]);
assert.deepStrictEqual(color.modeOrder.map((mode) => color.modeLabels[mode]), [
  'Semmi',
  'Statikus portál A/B',
  'Kettős árapály',
  'Mágneses membrán',
  'Lélegző lencse',
  'Celluláris mező',
]);
assert.deepStrictEqual(color.dynamicModes, [
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
]);
assert.deepStrictEqual(color.paletteStops, [
  { position: 0, color: '#fffdfd' },
  { position: 50, color: '#ffc4e4' },
  { position: 100, color: '#8b5cf6' },
]);
assert.deepStrictEqual(color.defaults, { center: 50, windowSize: 68 });

assert.strictEqual(color.samplePalette(-10), '#fffdfd');
assert.strictEqual(color.samplePalette(0), '#fffdfd');
assert.strictEqual(color.samplePalette(25), '#ffe1f1');
assert.strictEqual(color.samplePalette(50), '#ffc4e4');
assert.strictEqual(color.samplePalette(75), '#c590ed');
assert.strictEqual(color.samplePalette(100), '#8b5cf6');
assert.strictEqual(color.samplePalette(110), '#8b5cf6');
assert.strictEqual(color.samplePalette(12.5), '#ffeff7');

assert.strictEqual(color.normalizeMode('dual-tide'), 'dual-tide');
assert.strictEqual(color.normalizeMode('invalid'), 'none');
assert.strictEqual(color.normalizeCenter(-1), 0);
assert.strictEqual(color.normalizeCenter(49.6), 50);
assert.strictEqual(color.normalizeCenter(101), 100);
assert.strictEqual(color.normalizeCenter(''), 50);
assert.strictEqual(color.normalizeWindow(0), 10);
assert.strictEqual(color.normalizeWindow(67.6), 68);
assert.strictEqual(color.normalizeWindow(101), 100);
assert.strictEqual(color.normalizeWindow(''), 68);

assert.deepStrictEqual(color.sampleWindow(50, 100), {
  center: 50,
  windowSize: 100,
  lower: 0,
  upper: 100,
  a: '#fffdfd',
  b: '#8b5cf6',
});
assert.deepStrictEqual(color.sampleWindow(0, 68), {
  center: 0,
  windowSize: 68,
  lower: 0,
  upper: 34,
  a: '#fffdfd',
  b: '#ffd6ec',
});
assert.deepStrictEqual(color.sampleWindow('', ''), {
  center: 50,
  windowSize: 68,
  lower: 16,
  upper: 84,
  a: '#ffebf5',
  b: '#b07df0',
});

assert.strictEqual(color.isDynamicMode('static'), false);
assert.strictEqual(color.isDynamicMode('dual-tide'), true);
assert.deepStrictEqual(color.controlsForMode('none'), []);
assert.deepStrictEqual(color.controlsForMode('static'), []);
assert.deepStrictEqual(color.createModeSettings('none'), {});
assert.deepStrictEqual(color.createModeSettings('static'), {});

for (const mode of color.dynamicModes) {
  assert.deepStrictEqual(color.controlsForMode(mode), energy.controlsForMode(mode));
  const controls = color.controlsForMode(mode);
  const settings = color.createModeSettings(mode);
  assert(controls.length > 20, `${mode} must expose the complete existing schema`);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(color.normalizeControlValue(meta, ''), meta.default);
    assert.strictEqual(color.normalizeControlValue(meta, meta.min - 1000), meta.min);
    assert.strictEqual(color.normalizeControlValue(meta, meta.max + 1000), meta.max);
  });
  const isolated = color.createModeSettings(mode);
  isolated[controls[0].key] = controls[0].max;
  assert.strictEqual(color.createModeSettings(mode)[controls[0].key], controls[0].default);
}

const forward = color.buildTransition('dual-tide', 'message', 0.72, 900, false);
assert.deepStrictEqual(forward, {
  mode: 'dual-tide',
  targetState: 'message',
  duration: 900,
  easing: 'cubic-bezier(.2,.82,.2,1)',
  baseKeyframes: [
    { opacity: 0.72, offset: 0 },
    { opacity: 0, offset: 1 },
  ],
  colorKeyframes: [
    { opacity: 0, offset: 0 },
    { opacity: 0.72, offset: 1 },
  ],
  balanceRest: { baseOpacity: 0.72, colorOpacity: 0 },
  messageRest: { baseOpacity: 0, colorOpacity: 0.72 },
});

const backward = color.buildTransition('dual-tide', 'balance', 0.72, 900, false);
assert.deepStrictEqual(backward.baseKeyframes, [
  { opacity: 0, offset: 0 },
  { opacity: 0.72, offset: 1 },
]);
assert.deepStrictEqual(backward.colorKeyframes, [
  { opacity: 0.72, offset: 0 },
  { opacity: 0, offset: 1 },
]);
assert.deepStrictEqual(backward.balanceRest, { baseOpacity: 0.72, colorOpacity: 0 });
assert.deepStrictEqual(backward.messageRest, { baseOpacity: 0, colorOpacity: 0.72 });

const noEffect = color.buildTransition('none', 'message', 0.64, 1200, false);
assert.deepStrictEqual(noEffect, {
  mode: 'none',
  targetState: 'message',
  duration: 0,
  easing: 'linear',
  baseKeyframes: [],
  colorKeyframes: [],
  balanceRest: { baseOpacity: 0.64, colorOpacity: 0 },
  messageRest: { baseOpacity: 0.64, colorOpacity: 0 },
});
assert.deepStrictEqual(
  color.buildTransition('invalid', 'message', 0.64, 1200, false),
  noEffect,
);

const reduced = color.buildTransition('cellular-field', 'message', 1, 2000, true);
assert.strictEqual(reduced.duration, 160);
assert.strictEqual(reduced.easing, 'linear');
for (const frame of [...reduced.baseKeyframes, ...reduced.colorKeyframes]) {
  assert.deepStrictEqual(Object.keys(frame).sort(), ['offset', 'opacity']);
}

console.log('Portal message color checks passed');
