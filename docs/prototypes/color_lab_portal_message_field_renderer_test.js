const assert = require('assert');
const field = require('./color_lab_portal_message_field.js');
const renderer = require('./color_lab_portal_message_field_renderer.js');

const palette = field.sampleWindow(50, 68);
const render = (mode, phase, settings = field.createModeSettings(mode), dimensions = {}) => (
  renderer.renderFrame({
    mode,
    phase,
    settings,
    width: dimensions.width ?? 17,
    height: dimensions.height ?? 7,
    colorA: palette.a,
    colorB: palette.b,
  })
);

const solid = render('solid-a', 20, {});
for (let index = 0; index < solid.data.length; index += 4) {
  assert.deepStrictEqual(
    [...solid.data.slice(index, index + 4)],
    [255, 235, 245, 255],
    'Solid A must render the exact palette endpoint without a veil',
  );
}

assert.deepStrictEqual(
  [...render('static-matter', 0).data],
  [...render('static-matter', 80).data],
  'Static matter must not depend on phase',
);

for (const mode of field.animatedModes) {
  assert.notDeepStrictEqual(
    [...render(mode, 0).data],
    [...render(mode, 3).data],
    `${mode} must visibly move at its default settings`,
  );
}

for (const mode of field.modeOrder) {
  const frame = render(mode, 1.5);
  assert.strictEqual(frame.width, 17);
  assert.strictEqual(frame.height, 7);
  assert(frame.data instanceof Uint8ClampedArray);
  assert.strictEqual(frame.data.length, 17 * 7 * 4);
  for (let index = 0; index < frame.data.length; index += 4) {
    assert.strictEqual(frame.data[index + 3], 255, `${mode} must remain opaque`);
    assert(frame.data[index] >= 139 && frame.data[index] <= 255);
    assert(frame.data[index + 1] >= 92 && frame.data[index + 1] <= 235);
    assert(frame.data[index + 2] >= 240 && frame.data[index + 2] <= 246);
  }
}

const clamped = render('solid-a', 0, {}, { width: 3000.8, height: -4 });
assert.strictEqual(clamped.width, 2048);
assert.strictEqual(clamped.height, 1);
assert.strictEqual(clamped.data.length, 2048 * 4);

assert.strictEqual(renderer.renderFrame({ colorA: '#fff', colorB: '#8b5cf6' }), null);
assert.strictEqual(renderer.renderFrame({ colorA: '#fffdfd', colorB: 'purple' }), null);
assert.strictEqual(renderer.renderFrame(null), null);

console.log('Portal message field renderer checks passed');
