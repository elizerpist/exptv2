"use strict";
const assert = require("node:assert/strict");
const api = require("./color_lab_portal_interior_motion.js");

assert.deepEqual(api.EFFECT_IDS, [
  "driftingMist", "innerCurrent", "softTide", "slowVortex",
]);
assert.deepEqual(api.DEFAULT_INTERIOR_MOTION_STATE, {
  enabled: false,
  effect: "driftingMist",
  strength: 0.36,
  speed: 0.42,
});
assert.deepEqual(api.normalizeInteriorMotionState({
  enabled: 1, effect: "invalid", strength: 3, speed: -1,
}), {
  enabled: true, effect: "driftingMist", strength: 1, speed: 0,
});

const palette = api.deriveInteriorPalette("#36c9b8", "#d890ef");
assert.equal(palette.left.mother, "#36c9b8");
assert.equal(palette.right.mother, "#d890ef");
assert.ok(palette.left.lightnessA > palette.left.motherLightness);
assert.ok(palette.left.lightnessB < palette.left.motherLightness);
assert.ok(palette.right.hueA > 300 || palette.right.hueA < 20);
assert.ok(palette.right.hueB >= 255 && palette.right.hueB <= 300);

const left = api.createSideMotion("innerCurrent", "left", 1200, 0.5);
const right = api.createSideMotion("innerCurrent", "right", 1200, 0.5);
assert.notEqual(left.seed, right.seed);
assert.notEqual(left.phase, right.phase);
assert.equal(left.direction, 1);
assert.equal(right.direction, -1);
assert.deepEqual(api.createSideMotion("innerCurrent", "left", 1200, 0.5), left);

const expectedCounts = {
  driftingMist: 4,
  innerCurrent: 3,
  softTide: 3,
  slowVortex: 3,
};
const expectedAlpha = 0.04 + (0.4 * 0.22);
const assertPrimitiveFrame = (frame, effect, sidePalette) => {
  assert.equal(frame.primitives.length, expectedCounts[effect]);
  frame.primitives.forEach((primitive, index) => {
    assert.ok(primitive.geometry && typeof primitive.geometry === "object");
    assert.ok(Object.values(primitive.geometry).every((value) => (
      Number.isFinite(value) && value >= 0 && value <= 1
    )));
    assert.equal(
      primitive.innerColor,
      index % 2 === 0 ? sidePalette.accentA : sidePalette.accentB,
    );
    assert.equal(primitive.edgeColor, sidePalette.mother);
    assert.equal(primitive.alpha, expectedAlpha);
  });
};

const signatures = api.EFFECT_IDS.map((effect) => {
  const leftOptions = {
    effect, side: "left", width: 220, height: 88,
    timeMs: 1200, speed: 0.5, strength: 0.4,
    palette: palette.left,
  };
  const leftFrame = api.createInteriorPrimitives(leftOptions);
  assertPrimitiveFrame(leftFrame, effect, palette.left);
  assert.deepEqual(api.createInteriorPrimitives(leftOptions), leftFrame);

  const rightOptions = { ...leftOptions, side: "right", palette: palette.right };
  const rightFrame = api.createInteriorPrimitives(rightOptions);
  assertPrimitiveFrame(rightFrame, effect, palette.right);
  assert.deepEqual(api.createInteriorPrimitives(rightOptions), rightFrame);
  assert.equal(rightFrame.side, "right");
  assert.equal(rightFrame.motion.direction, -1);
  assert.notEqual(rightFrame.motion.seed, leftFrame.motion.seed);
  assert.notEqual(rightFrame.motion.phase, leftFrame.motion.phase);
  assert.notDeepEqual(
    rightFrame.primitives.map((primitive) => primitive.geometry),
    leftFrame.primitives.map((primitive) => primitive.geometry),
  );

  return leftFrame.primitives.map((primitive) => primitive.kind).join(",");
});
assert.equal(new Set(signatures).size, api.EFFECT_IDS.length);
console.log("Portal interior motion model checks passed");
