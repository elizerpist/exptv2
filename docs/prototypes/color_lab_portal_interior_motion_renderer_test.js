"use strict";

const assert = require("node:assert/strict");
const field = require("./color_lab_portal_message_field.js");
const motion = require("./color_lab_portal_interior_motion.js");
const api = require("./color_lab_portal_interior_motion_renderer.js");

function createFakeContext() {
  const calls = [];
  const record = (name, args = []) => calls.push({ name, args: [...args] });
  return {
    calls,
    save() { record("save"); },
    restore() { record("restore"); },
    beginPath() { record("beginPath"); },
    closePath() { record("closePath"); },
    moveTo(...args) { record("moveTo", args); },
    lineTo(...args) { record("lineTo", args); },
    clip() { record("clip"); },
    fillRect(...args) { record("fillRect", args); },
    clearRect(...args) { record("clearRect", args); },
    set fillStyle(value) { record("fillStyle", [value]); },
  };
}

const styleBeforeFillMatching = (ctx, predicate) => {
  let currentStyle = null;
  for (const call of ctx.calls) {
    if (call.name === "fillStyle") currentStyle = call.args[0];
    if (call.name === "fillRect" && predicate(call.args)) return currentStyle;
  }
  return null;
};

const rgbaAlpha = (style) => {
  const match = String(style).match(/^rgba\(\d+,\s*\d+,\s*\d+,\s*(0(?:\.\d+)?|1(?:\.0+)?)\)$/);
  return match ? Number(match[1]) : NaN;
};
const round12 = (value) => Math.round(value * 1e12) / 1e12;

assert.equal(
  Object.prototype.hasOwnProperty.call(api, "buildInteriorRegionPolygons"),
  false,
  "Interior motion overlay must not expose split-mask polygon helpers",
);
assert.equal(typeof api.projectInteriorOverlaySamplePoint, "function");
assert.deepEqual(
  api.projectInteriorOverlaySamplePoint({
    x: 0.5,
    y: 0,
    width: 160,
    height: 40,
    phase: 0.25,
    rotationEnabled: false,
    rotationSpeed: 100,
  }),
  {
    x: 0.5,
    y: 0.375,
    angle: 0,
    spanPx: 160,
    overscanX: 0,
    overscanY: 60,
  },
  "Unrotated overlay sampling must use a width-based virtual field with vertical overscan",
);
assert.deepEqual(
  api.projectInteriorOverlaySamplePoint({
    x: 0,
    y: 0.5,
    width: 160,
    height: 40,
    phase: 0.25,
    rotationEnabled: true,
    rotationSpeed: 100,
  }),
  {
    x: 0.5,
    y: 0,
    angle: round12(Math.PI / 2),
    spanPx: 160,
    overscanX: 0,
    overscanY: 60,
  },
  "A 90-degree rotation must turn the horizontal plane into a vertical travel axis",
);
assert.deepEqual(
  api.projectInteriorOverlaySamplePoint({
    x: 0,
    y: 0.5,
    width: 160,
    height: 40,
    phase: 0.25,
    rotationEnabled: true,
    rotationSpeed: 0,
  }),
  {
    x: 0,
    y: 0.5,
    angle: 0,
    spanPx: 160,
    overscanX: 0,
    overscanY: 60,
  },
  "Enabled rotation with zero speed must keep the sampling plane unrotated",
);

const staticSettings = motion.createInteriorSettingsByMode();
staticSettings["static-matter"] = {
  ...field.createModeSettings("static-matter"),
  coverage: 80,
  strength: 100,
  scale: 180,
  softness: 100,
  detail: 100,
};
const staticState = motion.normalizeInteriorMotionState({
  enabled: true,
  mode: "static-matter",
  settingsByMode: staticSettings,
  phaseByMode: {},
});
const renderOptions = {
  mode: "balance",
  state: staticState,
  width: 16,
  height: 4,
  split: 0.5,
  leftColors: ["#49cfc5", "#8defe5"],
  rightColors: ["#f7b2f5", "#d8b4fe"],
};

const disabledCtx = createFakeContext();
assert.deepEqual(api.renderPortalInteriorMotion(disabledCtx, {
  ...renderOptions,
  state: { ...staticState, enabled: false },
}), {
  rendered: false,
  overlayPixelCount: 0,
});
assert.equal(disabledCtx.calls.length, 0);

const nonBalanceCtx = createFakeContext();
assert.deepEqual(api.renderPortalInteriorMotion(nonBalanceCtx, {
  ...renderOptions,
  mode: "static",
}), {
  rendered: false,
  overlayPixelCount: 0,
});
assert.equal(nonBalanceCtx.calls.length, 0);

const overlayCtx = createFakeContext();
const overlay = api.renderPortalInteriorMotion(overlayCtx, {
  ...renderOptions,
  phase: 0,
});
assert.equal(overlay.rendered, true);
assert.ok(overlay.overlayPixelCount > 0);
assert.equal(overlayCtx.calls.filter((call) => call.name === "clip").length, 0);
assert.equal(overlayCtx.calls.filter((call) => call.name === "beginPath").length, 0);
assert.equal(overlayCtx.calls.filter((call) => call.name === "moveTo").length, 0);
assert.equal(overlayCtx.calls.filter((call) => call.name === "lineTo").length, 0);
assert.equal(overlayCtx.calls.filter((call) => call.name === "clearRect").length, 0);
assert.equal(overlayCtx.calls.some((call) => call.name === "createRadialGradient"), false);
assert.equal(overlayCtx.calls.some((call) => call.name === "ellipse"), false);
assert.equal(overlayCtx.calls.some((call) => call.name === "arc"), false);

const fillStyles = overlayCtx.calls
  .filter((call) => call.name === "fillStyle")
  .map((call) => call.args[0]);
assert.ok(fillStyles.length > 0);
assert.ok(
  fillStyles.every((style) => String(style).startsWith("rgba(")),
  "Overlay must draw translucent rgba pixels so the lower Balance gradient remains visible",
);
const alphaValues = fillStyles.map(rgbaAlpha);
assert.ok(alphaValues.every((alpha) => Number.isFinite(alpha) && alpha > 0 && alpha < 1));
assert.ok(Math.max(...alphaValues) <= 0.42);
assert.match(
  styleBeforeFillMatching(overlayCtx, ([x]) => x === 0),
  /^rgba\(73,\s*207,\s*197,\s*0\.\d+\)$/,
  "A-side overlay tint must use the known darker green endpoint",
);
assert.match(
  styleBeforeFillMatching(overlayCtx, ([x]) => x === 15),
  /^rgba\(216,\s*180,\s*254,\s*0\.\d+\)$/,
  "B-side overlay tint must use the known darker lilac endpoint",
);

const wanderingState = motion.normalizeInteriorMotionState({
  enabled: true,
  mode: "wandering-mist",
  settingsByMode: motion.createInteriorSettingsByMode(),
  phaseByMode: { "wandering-mist": 0 },
});
const animatedCtx0 = createFakeContext();
const animatedCtx3 = createFakeContext();
api.renderPortalInteriorMotion(animatedCtx0, {
  ...renderOptions,
  state: wanderingState,
  phase: 0,
});
api.renderPortalInteriorMotion(animatedCtx3, {
  ...renderOptions,
  state: wanderingState,
  phase: 3,
});
assert.notDeepEqual(
  animatedCtx0.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  animatedCtx3.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  "wandering-mist overlay must visibly change across phase",
);

const rotatedStaticState = motion.normalizeInteriorMotionState({
  ...staticState,
  rotationEnabled: true,
  rotationSpeed: 100,
});
const rotatedStaticCtx = createFakeContext();
api.renderPortalInteriorMotion(rotatedStaticCtx, {
  ...renderOptions,
  state: rotatedStaticState,
  phase: 0.25,
});
assert.notDeepEqual(
  overlayCtx.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  rotatedStaticCtx.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  "Rotating the overlay sampling plane must change the sampled matter pattern",
);

const staticCtx0 = createFakeContext();
const staticCtx9 = createFakeContext();
api.renderPortalInteriorMotion(staticCtx0, {
  ...renderOptions,
  state: staticState,
  phase: 0,
});
api.renderPortalInteriorMotion(staticCtx9, {
  ...renderOptions,
  state: staticState,
  phase: 9,
});
assert.deepEqual(
  staticCtx0.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  staticCtx9.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  "static-matter overlay must not depend on phase",
);

console.log("Portal interior motion renderer checks passed");
