const assert = require('assert');
const transition = require('./color_lab_portal_transition.js');
const renderer = require('./color_lab_portal_transition_renderer.js');

const solidFrame = (red, green, blue, width = 2, height = 2) => {
  const data = new Uint8ClampedArray(width * height * 4);
  for (let index = 0; index < data.length; index += 4) {
    data[index] = red;
    data[index + 1] = green;
    data[index + 2] = blue;
    data[index + 3] = 255;
  }
  return { width, height, data };
};

const source = solidFrame(10, 20, 30);
const portalBase = solidFrame(110, 120, 130);
const portalTarget = solidFrame(210, 220, 230);
const settings = transition.createModeSettings('pigment-spread');
const render = (progress, frames = {}) => renderer.renderFrame({
  mode: 'pigment-spread',
  progress,
  settings,
  sourceFrame: frames.sourceFrame || source,
  portalBaseFrame: frames.portalBaseFrame || portalBase,
  portalTargetFrame: frames.portalTargetFrame || portalTarget,
});

assert.deepStrictEqual([...render(0).data], [...source.data]);
assert.deepStrictEqual([...render(1).data], [...portalTarget.data]);

const middle = render(0.4);
assert.strictEqual(middle.width, 2);
assert.strictEqual(middle.height, 2);
assert(middle.data instanceof Uint8ClampedArray);
for (let index = 0; index < middle.data.length; index += 4) {
  assert(middle.data[index] >= 10 && middle.data[index] <= 210);
  assert(middle.data[index + 1] >= 20 && middle.data[index + 1] <= 220);
  assert(middle.data[index + 2] >= 30 && middle.data[index + 2] <= 230);
  assert.strictEqual(middle.data[index + 3], 255);
}

for (let y = 0; y < 2; y += 1) {
  for (let x = 0; x < 2; x += 1) {
    const { base, matter } = transition.sampleChannels(
      'pigment-spread',
      x,
      y,
      0.4,
      settings,
    );
    const expectedRed = Math.round((10 + ((110 - 10) * base))
      + ((210 - (10 + ((110 - 10) * base))) * matter));
    assert.strictEqual(middle.data[((y * 2) + x) * 4], expectedRed);
  }
}

assert.deepStrictEqual([...render(0.4).data], [...middle.data]);

const reusableOutput = solidFrame(0, 0, 0);
const reusableData = reusableOutput.data;
const reused = renderer.renderFrame({
  mode: 'pigment-spread',
  progress: 0.4,
  settings,
  sourceFrame: source,
  portalBaseFrame: portalBase,
  portalTargetFrame: portalTarget,
  outputFrame: reusableOutput,
});
assert.strictEqual(reused, reusableOutput);
assert.strictEqual(reused.data, reusableData);
assert.deepStrictEqual([...reused.data], [...middle.data]);

const reversed = render(0, {
  sourceFrame: portalTarget,
  portalBaseFrame: portalBase,
  portalTargetFrame: source,
});
assert.deepStrictEqual([...reversed.data], [...portalTarget.data]);
assert.deepStrictEqual(
  [...render(1, {
    sourceFrame: portalTarget,
    portalBaseFrame: portalBase,
    portalTargetFrame: source,
  }).data],
  [...source.data],
);

assert.strictEqual(render(0.5, { portalTargetFrame: solidFrame(210, 220, 230, 3, 2) }), null);
assert.strictEqual(renderer.renderFrame(null), null);
assert.strictEqual(renderer.renderFrame({
  mode: 'pigment-spread',
  progress: 0.5,
  settings,
  sourceFrame: { width: 2, height: 2, data: [] },
  portalBaseFrame: portalBase,
  portalTargetFrame: portalTarget,
}), null);

assert.deepStrictEqual([...source.data], [...solidFrame(10, 20, 30).data]);
assert.deepStrictEqual([...portalBase.data], [...solidFrame(110, 120, 130).data]);
assert.deepStrictEqual([...portalTarget.data], [...solidFrame(210, 220, 230).data]);

console.log('Portal transition renderer checks passed');
