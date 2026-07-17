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

const boundary = {
  leftXAt: (y) => 52 + Math.sin(y / 12) * 3,
  rightXAt: (y) => 76 + Math.sin(y / 12) * 3,
  featherPx: 4,
};

const polygons = api.buildInteriorRegionPolygons({
  width: 128,
  height: 48,
  boundary,
  samples: 16,
});
assert.ok(polygons.left.every((point, index) => (
  index >= 17 || point.x <= boundary.leftXAt(point.y) - boundary.featherPx
)));
assert.ok(polygons.right.every((point, index) => (
  index >= 17 || point.x >= boundary.rightXAt(point.y) + boundary.featherPx
)));

const state = motion.normalizeInteriorMotionState({
  enabled: true,
  mode: "wandering-mist",
  settingsByMode: motion.createInteriorSettingsByMode(),
  phaseByMode: { "wandering-mist": 0 },
});
const renderOptions = {
  mode: "balance",
  state,
  width: 128,
  height: 48,
  boundary,
  leftColors: ["#49cfc5", "#8defe5"],
  rightColors: ["#f7b2f5", "#d8b4fe"],
};

const disabledCtx = createFakeContext();
assert.deepEqual(api.renderPortalInteriorMotion(disabledCtx, {
  ...renderOptions,
  state: { ...state, enabled: false },
}), {
  rendered: false,
  leftPixelCount: 0,
  rightPixelCount: 0,
});
assert.equal(disabledCtx.calls.length, 0);

const nonBalanceCtx = createFakeContext();
assert.deepEqual(api.renderPortalInteriorMotion(nonBalanceCtx, {
  ...renderOptions,
  mode: "static",
}), {
  rendered: false,
  leftPixelCount: 0,
  rightPixelCount: 0,
});
assert.equal(nonBalanceCtx.calls.length, 0);

const animatedCtx0 = createFakeContext();
const animated0 = api.renderPortalInteriorMotion(animatedCtx0, {
  ...renderOptions,
  phase: 0,
});
assert.equal(animated0.rendered, true);
assert.ok(animated0.leftPixelCount > 0);
assert.ok(animated0.rightPixelCount > 0);
assert.equal(animatedCtx0.calls.filter((call) => call.name === "clip").length, 2);
assert.equal(animatedCtx0.calls.some((call) => call.name === "createRadialGradient"), false);
assert.equal(animatedCtx0.calls.some((call) => call.name === "ellipse"), false);
assert.equal(animatedCtx0.calls.some((call) => call.name === "arc"), false);
assert.ok(animatedCtx0.calls.some((call) => (
  call.name === "fillStyle" && String(call.args[0]).includes("rgb(")
)));

const animatedCtx3 = createFakeContext();
api.renderPortalInteriorMotion(animatedCtx3, {
  ...renderOptions,
  phase: 3,
});
assert.notDeepEqual(
  animatedCtx0.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  animatedCtx3.calls.filter((call) => call.name === "fillStyle").map((call) => call.args[0]),
  "wandering-mist must visibly change across phase",
);

const staticSettings = motion.createInteriorSettingsByMode();
staticSettings["static-matter"] = field.createModeSettings("static-matter");
const staticState = motion.normalizeInteriorMotionState({
  enabled: true,
  mode: "static-matter",
  settingsByMode: staticSettings,
  phaseByMode: {},
});
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
  "static-matter must not depend on phase",
);

console.log("Portal interior motion renderer checks passed");
