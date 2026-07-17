"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const api = require("./color_lab_portal_interior_motion_renderer.js");

function createFakeContext(options = {}) {
  const calls = [];
  const colorStops = [];
  const occurrences = new Map();
  const record = (name, args = []) => {
    calls.push({ name, args: [...args] });
    const occurrence = (occurrences.get(name) || 0) + 1;
    occurrences.set(name, occurrence);
    if (options.throwAt?.[name] === occurrence) {
      throw new Error(`forced ${name} failure`);
    }
  };
  const createGradient = (name, args) => {
    record(name, args);
    return {
      addColorStop(offset, color) {
        colorStops.push({ offset, color });
        record("addColorStop", [offset, color]);
      },
    };
  };
  return {
    calls,
    colorStops,
    globalAlpha: 1,
    lineWidth: 1,
    save() { record("save"); },
    restore() { record("restore"); },
    beginPath() { record("beginPath"); },
    closePath() { record("closePath"); },
    moveTo(...args) { record("moveTo", args); },
    lineTo(...args) { record("lineTo", args); },
    bezierCurveTo(...args) { record("bezierCurveTo", args); },
    ellipse(...args) { record("ellipse", args); },
    arc(...args) { record("arc", args); },
    translate(...args) { record("translate", args); },
    rotate(...args) { record("rotate", args); },
    scale(...args) { record("scale", args); },
    clip() { record("clip"); },
    fill() { record("fill"); },
    stroke() { record("stroke"); },
    clearRect(...args) { record("clearRect", args); },
    fillRect(...args) { record("fillRect", args); },
    createRadialGradient(...args) {
      return createGradient("createRadialGradient", args);
    },
    createLinearGradient(...args) {
      return createGradient("createLinearGradient", args);
    },
    set fillStyle(value) { record("fillStyle", [value]); },
    set strokeStyle(value) { record("strokeStyle", [value]); },
  };
}

const boundary = {
  leftXAt: (y) => 104 + Math.sin(y / 20) * 4,
  rightXAt: (y) => 132 + Math.sin(y / 20) * 4,
  featherPx: 5,
};
const polygons = api.buildInteriorRegionPolygons({
  width: 240, height: 96, boundary, samples: 24,
});
assert.ok(polygons.left.every((p) => p.x <= boundary.leftXAt(p.y) - 5));
assert.ok(polygons.right.every((p) => p.x >= boundary.rightXAt(p.y) + 5));
assert.equal(polygons.left[0].y, 0);
assert.equal(polygons.left.at(-3).y, 96);
assert.deepEqual(polygons.left.slice(-2), [{ x: 0, y: 96 }, { x: 0, y: 0 }]);
assert.deepEqual(polygons.right.slice(-2), [{ x: 240, y: 96 }, { x: 240, y: 0 }]);

const clamped = api.buildInteriorRegionPolygons({
  width: 240,
  height: 96,
  samples: 4,
  boundary: { leftXAt: () => -20, rightXAt: () => 260, featherPx: 5 },
});
assert.ok(clamped.left.every((point) => point.x === 0));
assert.ok(clamped.right.every((point) => point.x === 240));
assert.deepEqual(api.buildInteriorRegionPolygons({ width: 240, height: 96 }), {
  left: [], right: [],
});
assert.deepEqual(api.buildInteriorRegionPolygons({
  width: 240,
  height: 96,
  boundary: { leftXAt: () => Number.NaN, rightXAt: () => 132, featherPx: 5 },
}), { left: [], right: [] });

const painterCases = [
  ["radialEllipse", {
    centerX: 0.4, centerY: 0.5, radiusX: 0.2, radiusY: 0.3, rotation: 0.25,
  }, "createRadialGradient", ["ellipse", "fill"]],
  ["linearRibbon", {
    startX: 0.1, startY: 0.2, controlX: 0.5, controlY: 0.8,
    endX: 0.9, endY: 0.3, thickness: 0.08,
  }, "createLinearGradient", ["bezierCurveTo", "stroke"]],
  ["sineBand", {
    anchorX: 0.4, anchorY: 0.5, amplitude: 0.1, frequency: 0.3,
    phase: 0.2, thickness: 0.06,
  }, "createLinearGradient", ["lineTo", "stroke"]],
  ["radialArc", {
    centerX: 0.45, centerY: 0.55, radius: 0.3, start: 0.2,
    span: 0.4, thickness: 0.05,
  }, "createRadialGradient", ["arc", "stroke"]],
];
painterCases.forEach(([kind, geometry, gradientCall, shapeCalls]) => {
  const ctx = createFakeContext();
  assert.equal(api.drawInteriorPrimitive(ctx, {
    kind,
    geometry,
    innerColor: "#abcdef",
    edgeColor: "#36c9b8",
    alpha: 0.2,
  }, { x: 10, y: 20, width: 200, height: 80 }), true);
  assert.equal(ctx.calls.filter((call) => call.name === gradientCall).length, 1);
  shapeCalls.forEach((name) => {
    assert.ok(ctx.calls.some((call) => call.name === name), `${kind} must call ${name}`);
  });
  assert.deepEqual(ctx.colorStops.map((stop) => stop.offset), [0, 0.58, 1]);
  assert.match(ctx.colorStops[0].color, /^rgba\(171, 205, 239, 0\.2\)$/);
  assert.match(ctx.colorStops[1].color, /^rgba\(171, 205, 239, 0\.096/);
  assert.match(ctx.colorStops[2].color, /^rgba\(54, 201, 184, 0\)$/);
  assert.equal(ctx.calls.filter((call) => call.name === "save").length, 0);
  assert.equal(ctx.calls.filter((call) => call.name === "restore").length, 0);
});
assert.equal(api.drawInteriorPrimitive(createFakeContext(), {
  kind: "unknown", geometry: {}, innerColor: "#abcdef", edgeColor: "#36c9b8", alpha: 0.2,
}, { x: 0, y: 0, width: 240, height: 96 }), false);

const renderOptions = {
  mode: "balance",
  state: { enabled: true, effect: "driftingMist", strength: 0.4, speed: 0.5 },
  width: 240,
  height: 96,
  timeMs: 1000,
  boundary,
  leftMother: "#36c9b8",
  rightMother: "#d890ef",
};
const off = api.renderPortalInteriorMotion(createFakeContext(), {
  ...renderOptions,
  state: { enabled: false },
});
assert.deepEqual(off, { rendered: false, leftPrimitiveCount: 0, rightPrimitiveCount: 0 });

[
  { ...renderOptions, mode: "message" },
  { ...renderOptions, width: 0 },
  { ...renderOptions, height: 0 },
  { ...renderOptions, boundary: null },
  {
    ...renderOptions,
    boundary: { leftXAt: () => Number.POSITIVE_INFINITY, rightXAt: () => 132, featherPx: 5 },
  },
  {
    ...renderOptions,
    boundary: { leftXAt: () => 5, rightXAt: () => 132, featherPx: 5 },
  },
].forEach((options) => {
  const ctx = createFakeContext();
  assert.deepEqual(api.renderPortalInteriorMotion(ctx, options), {
    rendered: false, leftPrimitiveCount: 0, rightPrimitiveCount: 0,
  });
  assert.deepEqual(ctx.calls, []);
});

const ctx = createFakeContext();
let animationRequests = 0;
const originalRequestAnimationFrame = globalThis.requestAnimationFrame;
globalThis.requestAnimationFrame = () => { animationRequests += 1; };
let on;
try {
  on = api.renderPortalInteriorMotion(ctx, renderOptions);
} finally {
  if (originalRequestAnimationFrame === undefined) delete globalThis.requestAnimationFrame;
  else globalThis.requestAnimationFrame = originalRequestAnimationFrame;
}
assert.equal(on.rendered, true);
assert.ok(on.leftPrimitiveCount > 0 && on.rightPrimitiveCount > 0);
assert.equal(ctx.calls.filter((call) => call.name === "save").length, 2);
assert.equal(ctx.calls.filter((call) => call.name === "clip").length, 2);
assert.equal(ctx.calls.filter((call) => call.name === "restore").length, 2);
assert.ok(ctx.colorStops.some((stop) => stop.color.includes("54, 201, 184")));
assert.ok(ctx.colorStops.some((stop) => stop.color.includes("216, 144, 239")));
assert.equal(animationRequests, 0);
assert.equal(ctx.calls.filter((call) => ["clearRect", "fillRect"].includes(call.name)).length, 0);
assert.equal(ctx.calls.some((call) => (
  ["fillStyle", "strokeStyle"].includes(call.name)
  && /(?:#fff(?:fff)?|white|rgba?\(255,\s*255,\s*255)/i.test(String(call.args[0]))
)), false);

const saveIndices = ctx.calls.reduce((indices, call, index) => (
  call.name === "save" ? [...indices, index] : indices
), []);
const restoreIndices = ctx.calls.reduce((indices, call, index) => (
  call.name === "restore" ? [...indices, index] : indices
), []);
assert.equal(saveIndices.length, 2);
assert.equal(restoreIndices.length, 2);
saveIndices.forEach((start, passIndex) => {
  const pass = ctx.calls.slice(start, restoreIndices[passIndex] + 1).map((call) => call.name);
  const clipIndex = pass.indexOf("clip");
  assert.equal(pass[0], "save");
  assert.equal(pass.at(-1), "restore");
  assert.ok(pass.indexOf("beginPath") > 0 && pass.indexOf("beginPath") < clipIndex);
  assert.ok(pass.indexOf("closePath") > 0 && pass.indexOf("closePath") < clipIndex);
  assert.ok(clipIndex > 0);
  assert.ok(pass.slice(clipIndex + 1, -1).some((name) => ["fill", "stroke"].includes(name)));
});

const throwingCtx = createFakeContext({ throwAt: { fill: 5 } });
assert.deepEqual(api.renderPortalInteriorMotion(throwingCtx, renderOptions), {
  rendered: false, leftPrimitiveCount: 0, rightPrimitiveCount: 0,
});
assert.equal(throwingCtx.calls.filter((call) => call.name === "save").length, 2);
assert.equal(throwingCtx.calls.filter((call) => call.name === "restore").length, 2);

const browserCalls = { palettes: [], frames: [] };
const browserModel = {
  normalizeInteriorMotionState(state) { return state; },
  deriveInteriorPalette(leftMother, rightMother) {
    browserCalls.palettes.push({ leftMother, rightMother });
    return {
      left: { mother: leftMother, accentA: "#abcdef", accentB: "#fedcba" },
      right: { mother: rightMother, accentA: "#abcdef", accentB: "#fedcba" },
    };
  },
  createInteriorPrimitives(options) {
    browserCalls.frames.push(options);
    return {
      primitives: [{
        kind: "radialEllipse",
        geometry: {
          centerX: 0.5, centerY: 0.5, radiusX: 0.2, radiusY: 0.2, rotation: 0,
        },
        innerColor: options.palette.accentA,
        edgeColor: options.palette.mother,
        alpha: 0.2,
      }],
    };
  },
};
const browserRoot = { PortalInteriorMotion: browserModel };
vm.runInNewContext(
  fs.readFileSync(require.resolve("./color_lab_portal_interior_motion_renderer.js"), "utf8"),
  browserRoot,
);
assert.equal(typeof browserRoot.PortalInteriorMotionRenderer.renderPortalInteriorMotion, "function");
const browserResult = browserRoot.PortalInteriorMotionRenderer.renderPortalInteriorMotion(
  createFakeContext(),
  {
    ...renderOptions,
    width: 40,
    height: 20,
    boundary: { leftXAt: () => 15, rightXAt: () => 25, featherPx: 2 },
  },
);
assert.equal(browserResult.rendered, true);
assert.equal(browserResult.leftPrimitiveCount, 1);
assert.equal(browserResult.rightPrimitiveCount, 1);
assert.deepEqual(browserCalls.palettes, [{
  leftMother: "#36c9b8", rightMother: "#d890ef",
}]);
assert.deepEqual(browserCalls.frames.map((frame) => frame.side), ["left", "right"]);
assert.equal(browserCalls.frames[0].palette.mother, "#36c9b8");
assert.equal(browserCalls.frames[1].palette.mother, "#d890ef");

console.log("Portal interior motion renderer checks passed");
