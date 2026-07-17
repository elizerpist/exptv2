"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const model = require("./color_lab_portal_interior_motion.js");
const api = require("./color_lab_portal_interior_motion_renderer.js");

function createFakeContext(options = {}) {
  const calls = [];
  const colorStops = [];
  const gradients = [];
  const occurrences = new Map();
  const record = (name, args = [], details = {}) => {
    calls.push({ name, args: [...args], ...details });
    const occurrence = (occurrences.get(name) || 0) + 1;
    occurrences.set(name, occurrence);
    if (options.throwAt?.[name] === occurrence) {
      throw new Error(`forced ${name} failure`);
    }
    if (options.throwWhen?.({ name, args: [...args], calls, occurrence })) {
      throw new Error(`forced ${name} failure`);
    }
  };
  const createGradient = (name, args) => {
    const gradient = {
      id: gradients.length,
      name,
      args: [...args],
      colorStops: [],
    };
    gradients.push(gradient);
    record(name, args, { gradientId: gradient.id });
    return {
      addColorStop(offset, color) {
        const colorStop = { gradientId: gradient.id, offset, color };
        colorStops.push(colorStop);
        gradient.colorStops.push(colorStop);
        record("addColorStop", [offset, color], { gradientId: gradient.id });
      },
    };
  };
  return {
    calls,
    colorStops,
    gradients,
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

const palette = model.deriveInteriorPalette("#36c9b8", "#d890ef");
const paletteThemes = [
  ["#49cfc5", "#d8b4fe"],
  ["#36c9b8", "#d890ef"],
  ["#22b89f", "#e879f9"],
].map(([leftMother, rightMother]) => ({
  leftMother,
  rightMother,
  derived: model.deriveInteriorPalette(leftMother, rightMother),
}));
const hueDistance = (a, b) => Math.abs((((a - b) + 540) % 360) - 180);
paletteThemes.forEach(({ leftMother, rightMother, derived }) => {
  assert.equal(derived.left.mother, leftMother);
  assert.equal(derived.right.mother, rightMother);
  assert.equal(derived.left.hueA, derived.left.motherHue);
  assert.equal(derived.left.hueB, derived.left.motherHue);
  assert.ok(derived.left.lightnessA > derived.left.motherLightness);
  assert.ok(derived.left.lightnessB < derived.left.motherLightness);
  assert.ok(
    hueDistance(derived.right.hueA, 332) < hueDistance(derived.right.motherHue, 332),
  );
  assert.ok(
    hueDistance(derived.right.hueB, 274) < hueDistance(derived.right.motherHue, 274),
  );
});
assert.equal(new Set(paletteThemes.map(({ derived }) => derived.left.accentA)).size, 3);
assert.equal(new Set(paletteThemes.map(({ derived }) => derived.left.accentB)).size, 3);
assert.equal(new Set(paletteThemes.map(({ derived }) => derived.right.accentA)).size, 3);
assert.equal(new Set(paletteThemes.map(({ derived }) => derived.right.accentB)).size, 3);

const frameFor = (side, timeMs) => model.createInteriorPrimitives({
  effect: "innerCurrent",
  side,
  width: 220,
  height: 88,
  timeMs,
  speed: 0.5,
  strength: 0.4,
  palette: palette[side],
});
const leftFrame0 = frameFor("left", 0);
const leftFrame900 = frameFor("left", 900);
const repeatLeftFrame900 = frameFor("left", 900);
const rightFrame0 = frameFor("right", 0);
const rightFrame900 = frameFor("right", 900);
const rightFrame1800 = frameFor("right", 1800);

assert.notDeepEqual(leftFrame0.primitives, leftFrame900.primitives);
assert.notDeepEqual(rightFrame0.primitives, rightFrame900.primitives);
assert.notDeepEqual(leftFrame900.primitives, rightFrame900.primitives);
assert.deepEqual(leftFrame900, repeatLeftFrame900);
assert.notDeepEqual(rightFrame900.primitives, rightFrame1800.primitives);

const isolationOptions = {
  effect: "innerCurrent",
  side: "left",
  width: 220,
  height: 88,
  timeMs: 900,
  palette: palette.left,
};
const strength0Frame = model.createInteriorPrimitives({
  ...isolationOptions, speed: 0.5, strength: 0,
});
const strength100Frame = model.createInteriorPrimitives({
  ...isolationOptions, speed: 0.5, strength: 1,
});
assert.deepEqual(strength0Frame.motion, strength100Frame.motion);
assert.deepEqual(
  strength0Frame.primitives.map((primitive) => primitive.geometry),
  strength100Frame.primitives.map((primitive) => primitive.geometry),
);
assert.deepEqual(
  strength0Frame.primitives.map(({ kind, innerColor, edgeColor }) => ({
    kind, innerColor, edgeColor,
  })),
  strength100Frame.primitives.map(({ kind, innerColor, edgeColor }) => ({
    kind, innerColor, edgeColor,
  })),
);
assert.ok(strength0Frame.primitives.every((primitive) => primitive.alpha === 0.04));
assert.ok(strength100Frame.primitives.every((primitive) => primitive.alpha === 0.26));

const speed0Frame = model.createInteriorPrimitives({
  ...isolationOptions, speed: 0, strength: 0.4,
});
const speed100Frame = model.createInteriorPrimitives({
  ...isolationOptions, speed: 1, strength: 0.4,
});
assert.notEqual(speed0Frame.motion.phase, speed100Frame.motion.phase);
assert.notDeepEqual(
  speed0Frame.primitives.map((primitive) => primitive.geometry),
  speed100Frame.primitives.map((primitive) => primitive.geometry),
);
assert.deepEqual(
  speed0Frame.primitives.map(({ kind, innerColor, edgeColor, alpha }) => ({
    kind, innerColor, edgeColor, alpha,
  })),
  speed100Frame.primitives.map(({ kind, innerColor, edgeColor, alpha }) => ({
    kind, innerColor, edgeColor, alpha,
  })),
);

const splitWidth = 220;
const splitHeight = 88;
const splitFeatherPx = 5;
[0.35, 0.5, 0.65].forEach((splitRatio) => {
  const splitBoundary = {
    leftXAt: (y) => (splitWidth * splitRatio) + Math.sin(y / 16) * 2 - 7,
    rightXAt: (y) => (splitWidth * splitRatio) + Math.sin(y / 16) * 2 + 7,
    featherPx: splitFeatherPx,
  };
  const splitPolygons = api.buildInteriorRegionPolygons({
    width: splitWidth,
    height: splitHeight,
    boundary: splitBoundary,
    samples: 32,
  });
  const leftSamples = splitPolygons.left.slice(0, -2);
  const rightSamples = splitPolygons.right.slice(0, -2);
  assert.equal(leftSamples.length, 33);
  assert.equal(rightSamples.length, 33);
  leftSamples.forEach((point) => {
    assert.ok(
      point.x <= splitBoundary.leftXAt(point.y) - splitFeatherPx,
      `${splitRatio} left sample crossed its protected edge at y=${point.y}`,
    );
  });
  rightSamples.forEach((point) => {
    assert.ok(
      point.x >= splitBoundary.rightXAt(point.y) + splitFeatherPx,
      `${splitRatio} right sample crossed its protected edge at y=${point.y}`,
    );
  });
  leftSamples.forEach((leftPoint, index) => {
    const corridorWidth = rightSamples[index].x - leftPoint.x;
    assert.ok(
      corridorWidth > 0,
      `${splitRatio} protected corridor collapsed at y=${leftPoint.y}`,
    );
  });
});

const polygons = api.buildInteriorRegionPolygons({
  width: 240, height: 96, boundary, samples: 24,
});
assert.ok(polygons.left.every((p) => p.x <= boundary.leftXAt(p.y) - 5));
assert.ok(polygons.right.every((p) => p.x >= boundary.rightXAt(p.y) + 5));
assert.equal(polygons.left[0].y, 0);
assert.equal(polygons.left.at(-3).y, 96);
assert.deepEqual(polygons.left.slice(-2), [{ x: 0, y: 96 }, { x: 0, y: 0 }]);
assert.deepEqual(polygons.right.slice(-2), [{ x: 240, y: 96 }, { x: 240, y: 0 }]);

const exactPolygons = api.buildInteriorRegionPolygons({
  width: 20,
  height: 8,
  samples: 4,
  boundary: {
    leftXAt: (y) => 4 + (y / 2),
    rightXAt: (y) => 12 + (y / 4),
    featherPx: 2,
  },
});
assert.deepEqual(exactPolygons.left, [
  { x: 2, y: 0 },
  { x: 3, y: 2 },
  { x: 4, y: 4 },
  { x: 5, y: 6 },
  { x: 6, y: 8 },
  { x: 0, y: 8 },
  { x: 0, y: 0 },
]);
assert.deepEqual(exactPolygons.right, [
  { x: 14, y: 0 },
  { x: 14.5, y: 2 },
  { x: 15, y: 4 },
  { x: 15.5, y: 6 },
  { x: 16, y: 8 },
  { x: 20, y: 8 },
  { x: 20, y: 0 },
]);

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

const contourFailures = [];
const contourCheck = (name, check) => {
  try {
    check();
  } catch (error) {
    contourFailures.push(`${name}: ${error.message}`);
  }
};
const assertClose = (actual, expected, message) => {
  assert.ok(Math.abs(actual - expected) <= 1e-9, `${message}: expected ${expected}, got ${actual}`);
};
const assertArrayClose = (actual, expected, message) => {
  assert.equal(actual.length, expected.length, `${message} length`);
  actual.forEach((value, index) => assertClose(value, expected[index], `${message}[${index}]`));
};
const softAlphaAt = (position, alpha) => {
  if (position >= 1) return 0;
  if (position <= 0.58) return alpha + (((alpha * 0.48) - alpha) * (position / 0.58));
  return (alpha * 0.48) * (1 - ((position - 0.58) / 0.42));
};
const assertSoftStops = (gradient) => {
  assert.deepEqual(gradient.colorStops.map((stop) => stop.offset), [0, 0.58, 1]);
  assert.equal(gradient.colorStops[0].color, "rgba(171, 205, 239, 0.2)");
  assert.equal(gradient.colorStops[1].color, "rgba(171, 205, 239, 0.096)");
  assert.equal(gradient.colorStops[2].color, "rgba(54, 201, 184, 0)");
};
const directPrimitive = (kind, geometry) => ({
  kind,
  geometry,
  innerColor: "#abcdef",
  edgeColor: "#36c9b8",
  alpha: 0.2,
});
const directBounds = { x: 10, y: 20, width: 200, height: 80 };

const ellipseCtx = createFakeContext();
assert.equal(api.drawInteriorPrimitive(ellipseCtx, directPrimitive("radialEllipse", {
  centerX: 0.4,
  centerY: 0.5,
  radiusX: 0.2,
  radiusY: 0.3,
  rotation: 0.25,
}), directBounds), true);
contourCheck("ellipse short-axis contour alpha", () => {
  const gradient = ellipseCtx.gradients[0];
  const ellipse = ellipseCtx.calls.find((call) => call.name === "ellipse");
  const shortAxisPosition = ellipse.args[3] / gradient.args[5];
  const contourAlpha = softAlphaAt(shortAxisPosition, 0.2);
  assert.equal(
    contourAlpha,
    0,
    `short-axis position ${shortAxisPosition} retains alpha ${contourAlpha}`,
  );
});
contourCheck("ellipse normalized rotated field geometry", () => {
  assert.equal(ellipseCtx.gradients.length, 1);
  assert.equal(ellipseCtx.gradients[0].name, "createRadialGradient");
  assertArrayClose(ellipseCtx.gradients[0].args, [0, 0, 0, 0, 0, 1], "ellipse gradient");
  const ellipse = ellipseCtx.calls.find((call) => call.name === "ellipse");
  assertArrayClose(ellipse.args, [0, 0, 1, 1, 0, 0, Math.PI * 2], "unit ellipse contour");
  const transforms = ellipseCtx.calls.filter((call) => (
    ["translate", "rotate", "scale"].includes(call.name)
  ));
  assert.deepEqual(transforms.map((call) => call.name), [
    "translate", "rotate", "scale", "scale", "rotate", "translate",
  ]);
  assertArrayClose(transforms[0].args, [90, 60], "ellipse translate");
  assertArrayClose(transforms[1].args, [Math.PI / 2], "ellipse rotation");
  assertArrayClose(transforms[2].args, [40, 24], "ellipse scale");
  assertArrayClose(transforms[3].args, [1 / 40, 1 / 24], "ellipse inverse scale");
  assertArrayClose(transforms[4].args, [-Math.PI / 2], "ellipse inverse rotation");
  assertArrayClose(transforms[5].args, [-90, -60], "ellipse inverse translate");
  assertSoftStops(ellipseCtx.gradients[0]);
  assert.equal(ellipseCtx.calls.filter((call) => call.name === "save").length, 0);
  assert.equal(ellipseCtx.calls.filter((call) => call.name === "restore").length, 0);
});

const fieldCases = [
  ["linearRibbon", {
    startX: 0.1, startY: 0.2, controlX: 0.5, controlY: 0.8,
    endX: 0.9, endY: 0.3, thickness: 0.08,
  }],
  ["sineBand", {
    anchorX: 0.4, anchorY: 0.5, amplitude: 0.1, frequency: 0.3,
    phase: 0.2, thickness: 0.06,
  }],
  ["radialArc", {
    centerX: 0.45, centerY: 0.55, radius: 0.3, start: 0.2,
    span: 0.4, thickness: 0.05,
  }],
];
fieldCases.forEach(([kind, geometry]) => {
  const fieldCtx = createFakeContext();
  assert.equal(api.drawInteriorPrimitive(
    fieldCtx,
    directPrimitive(kind, geometry),
    directBounds,
  ), true);
  contourCheck(`${kind} complete 2-D feather and caps`, () => {
    const lateralAlpha = softAlphaAt(0.5, 0.2);
    assert.equal(
      fieldCtx.calls.filter((call) => call.name === "createLinearGradient").length,
      0,
      `${kind} 1-D field leaves lateral/cap alpha ${lateralAlpha}`,
    );
    assert.equal(
      fieldCtx.calls.filter((call) => call.name === "stroke").length,
      0,
      `${kind} stroke leaves a nonzero boundary/cap alpha ${lateralAlpha}`,
    );
    const arcs = fieldCtx.calls.filter((call) => call.name === "arc");
    assert.equal(fieldCtx.gradients.length, arcs.length);
    assert.ok(arcs.length > 1, `${kind} requires multiple bounded 2-D stamps`);
    assert.ok(arcs.length <= 32, `${kind} exceeds the deterministic 32-stamp bound`);
    const requestedRadius = Math.abs(geometry.thickness) * Math.min(
      directBounds.width,
      directBounds.height,
    );
    arcs.forEach((arc, index) => {
      const gradient = fieldCtx.gradients[index];
      assertClose(arc.args[2], requestedRadius, `${kind} requested radius ${index}`);
      assert.equal(gradient.name, "createRadialGradient");
      assertArrayClose(
        gradient.args,
        [arc.args[0], arc.args[1], 0, arc.args[0], arc.args[1], arc.args[2]],
        `${kind} stamp ${index} support`,
      );
      assertArrayClose(arc.args.slice(3), [0, Math.PI * 2], `${kind} stamp ${index} cap`);
      assertSoftStops(gradient);
      if (index > 0) {
        const previous = arcs[index - 1];
        const distance = Math.hypot(
          arc.args[0] - previous.args[0],
          arc.args[1] - previous.args[1],
        );
        assert.ok(
          distance <= (arc.args[2] + previous.args[2]) + 1e-9,
          `${kind} stamps ${index - 1}/${index} leave a support gap`,
        );
      }
    });
    const repeatCtx = createFakeContext();
    assert.equal(api.drawInteriorPrimitive(
      repeatCtx,
      directPrimitive(kind, geometry),
      directBounds,
    ), true);
    assert.deepEqual(
      repeatCtx.gradients.map((gradient) => gradient.args),
      fieldCtx.gradients.map((gradient) => gradient.args),
      `${kind} stamp field must be deterministic`,
    );
    assert.equal(fieldCtx.calls.filter((call) => call.name === "save").length, 0);
    assert.equal(fieldCtx.calls.filter((call) => call.name === "restore").length, 0);
  });
});

const thinRibbon = directPrimitive("linearRibbon", {
  startX: 0,
  startY: 0.5,
  controlX: 0.5,
  controlY: 0.5,
  endX: 1,
  endY: 0.5,
  thickness: 0.001,
});
const thinBounds = { x: 0, y: 0, width: 200, height: 80 };
const thinCtx = createFakeContext();
assert.equal(api.drawInteriorPrimitive(thinCtx, thinRibbon, thinBounds), true);
contourCheck("thin capped field adapts radius without gaps", () => {
  const arcs = thinCtx.calls.filter((call) => call.name === "arc");
  assert.ok(arcs.length > 1 && arcs.length <= 32);
  arcs.forEach((arc, index) => {
    const [centerX, centerY, radius] = arc.args;
    assert.ok(centerX - radius >= -1e-9 && centerX + radius <= 200 + 1e-9);
    assert.ok(centerY - radius >= -1e-9 && centerY + radius <= 80 + 1e-9);
    if (index > 0) {
      const previous = arcs[index - 1];
      const distance = Math.hypot(
        centerX - previous.args[0],
        centerY - previous.args[1],
      );
      assert.ok(
        distance <= (radius + previous.args[2]) + 1e-9,
        `thin stamps ${index - 1}/${index} gap ${distance} > ${radius + previous.args[2]}`,
      );
    }
  });
  assert.ok(arcs[0].args[2] > 0.08, "thin field must increase its infeasible requested radius");
  const repeatCtx = createFakeContext();
  assert.equal(api.drawInteriorPrimitive(repeatCtx, thinRibbon, thinBounds), true);
  assert.deepEqual(
    repeatCtx.gradients.map((gradient) => gradient.args),
    thinCtx.gradients.map((gradient) => gradient.args),
  );
});

contourCheck("impossible thin field fails before drawing", () => {
  const impossibleCtx = createFakeContext();
  assert.equal(api.drawInteriorPrimitive(
    impossibleCtx,
    thinRibbon,
    { x: 0, y: 0, width: 1000, height: 1 },
  ), false);
  assert.deepEqual(impossibleCtx.calls, []);
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
const assertInactiveInteriorLifecycle = (options, label) => {
  const inactiveCtx = createFakeContext();
  const result = api.renderPortalInteriorMotion(inactiveCtx, options);
  assert.deepEqual(result, {
    rendered: false, leftPrimitiveCount: 0, rightPrimitiveCount: 0,
  }, `${label} must report zero primitives`);
  assert.equal(inactiveCtx.gradients.length, 0, `${label} must create zero gradients`);
  assert.equal(
    inactiveCtx.calls.filter((call) => call.name === "fill").length,
    0,
    `${label} must draw zero primitives`,
  );
  assert.deepEqual(inactiveCtx.calls, [], `${label} must not touch the canvas`);
};
assertInactiveInteriorLifecycle({
  ...renderOptions,
  state: { enabled: false },
}, "disabled Balance interior motion");
assertInactiveInteriorLifecycle({
  ...renderOptions,
  mode: "message",
}, "enabled non-Balance interior motion");

[
  { ...renderOptions, state: undefined },
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
  {
    ...renderOptions,
    boundary: { leftXAt: () => 104, rightXAt: () => 235, featherPx: 5 },
  },
  {
    ...renderOptions,
    boundary: { leftXAt: () => 130, rightXAt: () => 120, featherPx: 5 },
  },
  {
    ...renderOptions,
    boundary: { leftXAt: () => 136, rightXAt: () => 120, featherPx: 5 },
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

const savedPasses = (calls) => {
  const saveIndices = calls.reduce((indices, call, index) => (
    call.name === "save" ? [...indices, index] : indices
  ), []);
  const restoreIndices = calls.reduce((indices, call, index) => (
    call.name === "restore" ? [...indices, index] : indices
  ), []);
  assert.equal(saveIndices.length, restoreIndices.length);
  return saveIndices.map((start, index) => calls.slice(start, restoreIndices[index] + 1));
};
const passes = savedPasses(ctx.calls);
assert.equal(passes.length, 2);
passes.forEach((pass) => {
  const names = pass.map((call) => call.name);
  const clipIndex = names.indexOf("clip");
  assert.equal(names[0], "save");
  assert.equal(names.at(-1), "restore");
  assert.ok(names.indexOf("beginPath") > 0 && names.indexOf("beginPath") < clipIndex);
  assert.ok(names.indexOf("closePath") > 0 && names.indexOf("closePath") < clipIndex);
  assert.ok(clipIndex > 0);
  assert.ok(names.slice(clipIndex + 1, -1).some((name) => name === "fill"));
});
[
  "rgba(54, 201, 184, 0)",
  "rgba(216, 144, 239, 0)",
].forEach((expectedMotherStop, passIndex) => {
  const edgeStops = passes[passIndex].filter((call) => (
    call.name === "addColorStop" && call.args[0] === 1
  ));
  assert.ok(edgeStops.length > 0);
  assert.ok(edgeStops.every((call) => call.args[1] === expectedMotherStop));
  const middleStops = passes[passIndex].filter((call) => (
    call.name === "addColorStop" && call.args[0] === 0.58
  ));
  assert.ok(middleStops.length > 0);
  assert.ok(middleStops.every((call) => (
    /^rgba\(\d+, \d+, \d+, 0\.06144\)$/.test(call.args[1])
  )));
});

const lastCallBefore = (calls, endIndex, name) => {
  for (let index = endIndex - 1; index >= 0; index -= 1) {
    if (calls[index].name === name) return calls[index];
  }
  return null;
};
const softSupports = (pass) => pass.flatMap((call, index) => {
  if (call.name === "arc"
    && Math.abs(call.args[3]) <= 1e-9
    && Math.abs(call.args[4] - (Math.PI * 2)) <= 1e-9) {
    return [{
      minX: call.args[0] - call.args[2],
      maxX: call.args[0] + call.args[2],
      minY: call.args[1] - call.args[2],
      maxY: call.args[1] + call.args[2],
    }];
  }
  if (call.name !== "ellipse") return [];
  const translation = lastCallBefore(pass, index, "translate");
  const rotation = lastCallBefore(pass, index, "rotate");
  const scale = lastCallBefore(pass, index, "scale");
  if (!translation || !rotation || !scale) return [];
  const [centerX, centerY] = translation.args;
  const [radiusX, radiusY] = scale.args;
  const angle = rotation.args[0];
  const extentX = Math.hypot(radiusX * Math.cos(angle), radiusY * Math.sin(angle));
  const extentY = Math.hypot(radiusX * Math.sin(angle), radiusY * Math.cos(angle));
  return [{
    minX: centerX - extentX,
    maxX: centerX + extentX,
    minY: centerY - extentY,
    maxY: centerY + extentY,
  }];
});

["driftingMist", "innerCurrent", "softTide", "slowVortex"].forEach((effect) => {
  const supportCtx = createFakeContext();
  const supportResult = api.renderPortalInteriorMotion(supportCtx, {
    ...renderOptions,
    state: { ...renderOptions.state, effect },
  });
  contourCheck(`${effect} support fits before protected clip`, () => {
    assert.equal(supportResult.rendered, true);
    const supportPolygons = api.buildInteriorRegionPolygons({
      width: renderOptions.width,
      height: renderOptions.height,
      boundary,
    });
    const sampledCount = supportPolygons.left.length - 2;
    const leftSafeEdge = Math.min(
      ...supportPolygons.left.slice(0, sampledCount).map((point) => point.x),
    );
    const rightSafeEdge = Math.max(
      ...supportPolygons.right.slice(0, sampledCount).map((point) => point.x),
    );
    const supportPasses = savedPasses(supportCtx.calls);
    assert.equal(supportPasses.length, 2);
    supportPasses.forEach((pass, passIndex) => {
      const supports = softSupports(pass);
      assert.ok(supports.length > 0, `${effect} pass ${passIndex} has no 2-D support`);
      supports.forEach((support) => {
        assert.ok(support.minY >= -1e-9 && support.maxY <= renderOptions.height + 1e-9);
        if (passIndex === 0) assert.ok(support.maxX <= leftSafeEdge + 1e-9);
        else assert.ok(support.minX >= rightSafeEdge - 1e-9);
      });
    });
  });
});

if (contourFailures.length > 0) {
  assert.fail(`2-D contour checks failed:\n${contourFailures.join("\n")}`);
}

const throwingCtx = createFakeContext({
  throwWhen: ({ name, calls }) => (
    name === "fill" && calls.filter((call) => call.name === "clip").length === 2
  ),
});
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
