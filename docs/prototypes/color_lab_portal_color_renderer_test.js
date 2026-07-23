const assert = require('assert');
const color = require('./color_lab_portal_color.js');
const renderer = require('./color_lab_portal_color_renderer.js');

const palette = color.sampleWindow(50, 68);
const render = (mode, phase, settings = color.createModeSettings(mode), dimensions = {}) => (
  renderer.renderFrame({
    mode,
    width: dimensions.width ?? 9,
    height: dimensions.height ?? 5,
    phase,
    settings,
    colorA: palette.a,
    colorB: palette.b,
  })
);

for (const mode of color.modeOrder.slice(1)) {
  const frame = render(mode, 1.25);
  assert.strictEqual(frame.width, 9);
  assert.strictEqual(frame.height, 5);
  assert(frame.data instanceof Uint8ClampedArray);
  assert.strictEqual(frame.data.length, 9 * 5 * 4);
  for (let index = 3; index < frame.data.length; index += 4) {
    assert.strictEqual(frame.data[index], 255);
  }
  assert.deepStrictEqual([...render(mode, 1.25).data], [...frame.data]);
}

assert.strictEqual(renderer.renderFrame({ mode: 'none' }), null);
assert.strictEqual(renderer.renderFrame({ mode: 'invalid' }), null);
assert.strictEqual(renderer.renderFrame(null), null);

assert.deepStrictEqual(
  [...render('static', 0).data],
  [...render('static', 900).data],
  'Static portal color must not depend on phase',
);

for (const mode of color.dynamicModes) {
  assert.notDeepStrictEqual(
    [...render(mode, 0).data],
    [...render(mode, 2).data],
    `${mode} must change with phase at its defaults`,
  );
  assert.deepStrictEqual(
    [...render(mode, 4, { ...color.createModeSettings(mode), strength: 0 }).data],
    [...render('static', 0).data],
    `${mode} with zero strength must equal static`,
  );
}

const clampedDimensions = render('static', 0, {}, { width: 3000.8, height: -4 });
assert.strictEqual(clampedDimensions.width, 2048);
assert.strictEqual(clampedDimensions.height, 1);
assert.strictEqual(clampedDimensions.data.length, 2048 * 4);

const fallbackDimensions = renderer.renderFrame({
  mode: 'static',
  width: 'invalid',
  height: null,
  phase: 0,
  settings: {},
  colorA: palette.a,
  colorB: palette.b,
});
assert.strictEqual(fallbackDimensions.width, 1);
assert.strictEqual(fallbackDimensions.height, 1);

assert.strictEqual(renderer.renderFrame({
  mode: 'static',
  width: 2,
  height: 2,
  colorA: '#fff',
  colorB: '#8b5cf6',
}), null);
assert.strictEqual(renderer.renderFrame({
  mode: 'static',
  width: 2,
  height: 2,
  colorA: '#fffdfd',
  colorB: 'purple',
}), null);

console.log('Portal message color renderer checks passed');
