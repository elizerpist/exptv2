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

const signatures = api.EFFECT_IDS.map((effect) => {
  const frame = api.createInteriorPrimitives({
    effect, side: "left", width: 220, height: 88,
    timeMs: 1200, speed: 0.5, strength: 0.4,
    palette: palette.left,
  });
  assert.ok(frame.primitives.length >= 2);
  assert.ok(frame.primitives.every((p) => p.edgeColor === palette.left.mother));
  return frame.primitives.map((p) => p.kind).join(",");
});
assert.equal(new Set(signatures).size, api.EFFECT_IDS.length);
console.log("Portal interior motion model checks passed");
