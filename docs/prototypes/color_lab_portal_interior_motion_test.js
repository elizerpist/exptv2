"use strict";

const assert = require("node:assert/strict");
const field = require("./color_lab_portal_message_field.js");
const api = require("./color_lab_portal_interior_motion.js");

const schemaTuple = (meta) => [
  meta.key,
  meta.label,
  meta.min,
  meta.max,
  meta.step,
  meta.default,
  meta.unit,
];

assert.deepEqual(api.MODE_IDS, field.modeOrder);
assert.deepEqual(api.MODE_LABELS, field.modeLabels);
assert.deepEqual(api.ANIMATED_MODE_IDS, field.animatedModes);
assert.equal(api.DEFAULT_INTERIOR_MOTION_STATE.enabled, false);
assert.equal(api.DEFAULT_INTERIOR_MOTION_STATE.mode, field.defaults.mode);
assert.deepEqual(
  Object.keys(api.DEFAULT_INTERIOR_MOTION_STATE.settingsByMode),
  field.modeOrder.slice(1),
);
assert.deepEqual(
  Object.keys(api.DEFAULT_INTERIOR_MOTION_STATE.phaseByMode),
  field.animatedModes,
);

for (const mode of field.modeOrder) {
  assert.deepEqual(
    api.controlsForMode(mode).map(schemaTuple),
    field.controlsForMode(mode).map(schemaTuple),
    `${mode} controls must match Portal background morph`,
  );
  assert.deepEqual(
    api.createModeSettings(mode),
    field.createModeSettings(mode),
    `${mode} defaults must match Portal background morph`,
  );
}

const normalized = api.normalizeInteriorMotionState({
  enabled: 1,
  mode: "invalid",
  settingsByMode: {
    "wandering-mist": {
      coverage: -100,
      strength: 999,
      scale: "",
      softness: 83.4,
      driftSpeed: 22,
      curl: 44,
      morphRate: 28,
      detail: 24,
      seed: 311,
    },
  },
  phaseByMode: {
    "wandering-mist": 4.25,
    "forming-clouds": "bad",
  },
});
assert.equal(normalized.enabled, true);
assert.equal(normalized.mode, "solid-a");
assert.equal(
  normalized.settingsByMode["wandering-mist"].coverage,
  field.controlsForMode("wandering-mist")[0].min,
);
assert.equal(
  normalized.settingsByMode["wandering-mist"].strength,
  field.controlsForMode("wandering-mist")[1].max,
);
assert.equal(
  normalized.settingsByMode["wandering-mist"].scale,
  field.createModeSettings("wandering-mist").scale,
);
assert.equal(normalized.settingsByMode["wandering-mist"].softness, 83);
assert.equal(normalized.phaseByMode["wandering-mist"], 4.25);
assert.equal(normalized.phaseByMode["forming-clouds"], 0);

const palettes = api.deriveInteriorPalettes({
  leftColors: ["#49cfc5", "#8defe5"],
  rightColors: ["#f7b2f5", "#d8b4fe"],
});
assert.deepEqual(palettes.left, {
  light: "#8defe5",
  dark: "#49cfc5",
});
assert.deepEqual(palettes.right, {
  light: "#f7b2f5",
  dark: "#d8b4fe",
});

const leftSide = api.createSideRenderOptions({
  mode: "wandering-mist",
  side: "left",
  phase: 2.5,
  settings: field.createModeSettings("wandering-mist"),
});
const rightSide = api.createSideRenderOptions({
  mode: "wandering-mist",
  side: "right",
  phase: 2.5,
  settings: field.createModeSettings("wandering-mist"),
});
assert.equal(leftSide.mode, "wandering-mist");
assert.equal(rightSide.mode, "wandering-mist");
assert.notEqual(leftSide.phase, rightSide.phase);
assert.notEqual(leftSide.settings.seed, rightSide.settings.seed);
assert.equal(leftSide.flipX, false);
assert.equal(rightSide.flipX, true);
assert.deepEqual(
  api.createSideRenderOptions({
    mode: "wandering-mist",
    side: "left",
    phase: 2.5,
    settings: field.createModeSettings("wandering-mist"),
  }),
  leftSide,
);

const stillPhase = api.advanceInteriorPhase(
  "static-matter",
  8,
  1,
  field.createModeSettings("static-matter"),
);
assert.equal(stillPhase, 8);
const movingPhase = api.advanceInteriorPhase(
  "wandering-mist",
  8,
  1,
  field.createModeSettings("wandering-mist"),
);
assert.equal(
  movingPhase,
  field.advancePhase("wandering-mist", 8, 1, field.createModeSettings("wandering-mist")),
);

console.log("Portal interior motion model checks passed");
