(function attachPortalInteriorMotion(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalInteriorMotion = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalInteriorMotion() {
  'use strict';

  const EFFECT_IDS = Object.freeze([
    'driftingMist', 'innerCurrent', 'softTide', 'slowVortex',
  ]);
  const DEFAULT_INTERIOR_MOTION_STATE = Object.freeze({
    enabled: false,
    effect: 'driftingMist',
    strength: 0.36,
    speed: 0.42,
  });

  function clamp01(value, fallback) {
    const number = Number(value);
    return Number.isFinite(number) ? Math.max(0, Math.min(1, number)) : fallback;
  }

  function normalizeInteriorMotionState(value = {}) {
    return {
      enabled: Boolean(value.enabled),
      effect: EFFECT_IDS.includes(value.effect) ? value.effect : 'driftingMist',
      strength: clamp01(value.strength, 0.36),
      speed: clamp01(value.speed, 0.42),
    };
  }

  const normalizeHue = (value) => ((Number(value) % 360) + 360) % 360;
  const clampChannel = (value) => {
    const number = Number(value);
    return Math.round(Math.max(0, Math.min(255, Number.isFinite(number) ? number : 0)));
  };
  const channelHex = (value) => clampChannel(value).toString(16).padStart(2, '0');
  const rgbToHex = (rgb) => `#${channelHex(rgb.r)}${channelHex(rgb.g)}${channelHex(rgb.b)}`;

  function hexToRgb(value) {
    if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) {
      return { r: 0, g: 0, b: 0 };
    }
    return {
      r: parseInt(value.slice(1, 3), 16),
      g: parseInt(value.slice(3, 5), 16),
      b: parseInt(value.slice(5, 7), 16),
    };
  }

  function rgbToHsl(rgb) {
    const red = clampChannel(rgb.r) / 255;
    const green = clampChannel(rgb.g) / 255;
    const blue = clampChannel(rgb.b) / 255;
    const max = Math.max(red, green, blue);
    const min = Math.min(red, green, blue);
    const delta = max - min;
    const lightness = clamp01((max + min) / 2, 0);
    let hue = 0;

    if (delta > 0) {
      if (max === red) hue = 60 * (((green - blue) / delta) % 6);
      else if (max === green) hue = 60 * (((blue - red) / delta) + 2);
      else hue = 60 * (((red - green) / delta) + 4);
    }

    const saturation = delta === 0
      ? 0
      : delta / (1 - Math.abs((2 * lightness) - 1));
    return {
      hue: normalizeHue(hue),
      saturation: clamp01(saturation, 0),
      lightness,
    };
  }

  function hslToRgb(hue, saturation, lightness) {
    const safeHue = normalizeHue(hue) / 360;
    const safeSaturation = clamp01(saturation, 0);
    const safeLightness = clamp01(lightness, 0);

    if (safeSaturation === 0) {
      const channel = clampChannel(safeLightness * 255);
      return { r: channel, g: channel, b: channel };
    }

    const q = safeLightness < 0.5
      ? safeLightness * (1 + safeSaturation)
      : safeLightness + safeSaturation - (safeLightness * safeSaturation);
    const p = (2 * safeLightness) - q;
    const hueChannel = (offset) => {
      let channel = offset;
      if (channel < 0) channel += 1;
      if (channel > 1) channel -= 1;
      if (channel < 1 / 6) return p + ((q - p) * 6 * channel);
      if (channel < 1 / 2) return q;
      if (channel < 2 / 3) return p + ((q - p) * (2 / 3 - channel) * 6);
      return p;
    };
    return {
      r: clampChannel(hueChannel(safeHue + (1 / 3)) * 255),
      g: clampChannel(hueChannel(safeHue) * 255),
      b: clampChannel(hueChannel(safeHue - (1 / 3)) * 255),
    };
  }

  const hslToHex = (hue, saturation, lightness) => (
    rgbToHex(hslToRgb(hue, saturation, lightness))
  );
  const mixHue = (source, target, amount) => {
    const delta = ((normalizeHue(target) - normalizeHue(source) + 540) % 360) - 180;
    return normalizeHue(normalizeHue(source) + (delta * clamp01(amount, 0)));
  };

  function paletteSide(motherRgb, hueA, hueB, lightnessA, lightnessB) {
    const motherHsl = rgbToHsl(motherRgb);
    const safeHueA = normalizeHue(hueA);
    const safeHueB = normalizeHue(hueB);
    const safeLightnessA = clamp01(lightnessA, motherHsl.lightness);
    const safeLightnessB = clamp01(lightnessB, motherHsl.lightness);
    return {
      mother: rgbToHex(motherRgb),
      motherHue: motherHsl.hue,
      motherSaturation: motherHsl.saturation,
      motherLightness: motherHsl.lightness,
      hueA: safeHueA,
      hueB: safeHueB,
      lightnessA: safeLightnessA,
      lightnessB: safeLightnessB,
      accentA: hslToHex(safeHueA, motherHsl.saturation, safeLightnessA),
      accentB: hslToHex(safeHueB, motherHsl.saturation, safeLightnessB),
    };
  }

  function deriveInteriorPalette(leftMother, rightMother) {
    const leftRgb = hexToRgb(leftMother);
    const rightRgb = hexToRgb(rightMother);
    const leftHsl = rgbToHsl(leftRgb);
    const rightHsl = rgbToHsl(rightRgb);
    return {
      left: paletteSide(
        leftRgb,
        leftHsl.hue,
        leftHsl.hue,
        leftHsl.lightness + 0.14,
        leftHsl.lightness - 0.15,
      ),
      right: paletteSide(
        rightRgb,
        mixHue(rightHsl.hue, 332, 0.38),
        mixHue(rightHsl.hue, 274, 0.42),
        rightHsl.lightness,
        rightHsl.lightness,
      ),
    };
  }

  function createSideMotion(effect, side, timeMs, speed) {
    const safeEffect = EFFECT_IDS.includes(effect) ? effect : 'driftingMist';
    const safeSide = side === 'right' ? 'right' : 'left';
    const seed = EFFECT_IDS.indexOf(safeEffect) * 97 + (safeSide === 'left' ? 17 : 61);
    const direction = safeSide === 'left' ? 1 : -1;
    const offset = safeSide === 'left' ? 0.13 : 0.67;
    const cycles = (Number(timeMs) || 0) * (0.000035 + clamp01(speed, 0.42) * 0.00022);
    return { seed, direction, phase: ((offset + cycles * direction) % 1 + 1) % 1 };
  }

  const TAU = Math.PI * 2;
  const roundNormalized = (value) => Math.round(clamp01(value, 0) * 1e6) / 1e6;
  const motionUnit = (motion, index, channel) => roundNormalized(
    0.5 + (Math.sin(TAU * (
      motion.phase
      + (motion.seed * 0.011)
      + (index * 0.173 * motion.direction)
      + (channel * 0.271)
    )) * 0.5),
  );
  const boundedPosition = (motion, index, channel, inset = 0) => {
    const safeInset = Math.max(0, Math.min(0.49, Number(inset) || 0));
    return roundNormalized(safeInset + (motionUnit(motion, index, channel) * (1 - (2 * safeInset))));
  };
  const geometry = (values) => Object.fromEntries(
    Object.entries(values).map(([key, value]) => [key, roundNormalized(value)]),
  );

  function primitive(kind, index, context, values) {
    return {
      kind,
      geometry: geometry(values),
      innerColor: index % 2 === 0 ? context.palette.accentA : context.palette.accentB,
      edgeColor: context.palette.mother,
      alpha: context.alpha,
    };
  }

  function buildMistEllipses(context) {
    return Array.from({ length: 4 }, (_, index) => {
      const radiusX = 0.13 + (index * 0.018);
      const radiusY = 0.2 - (index * 0.016);
      return primitive('radialEllipse', index, context, {
        centerX: boundedPosition(context.motion, index, 0, radiusX),
        centerY: boundedPosition(context.motion, index, 1, radiusY),
        radiusX,
        radiusY,
        rotation: motionUnit(context.motion, index, 2),
      });
    });
  }

  function buildCurrentRibbons(context) {
    return Array.from({ length: 3 }, (_, index) => primitive(
      'linearRibbon',
      index,
      context,
      {
        startX: boundedPosition(context.motion, index, 0, 0.04),
        startY: boundedPosition(context.motion, index, 1, 0.04),
        controlX: boundedPosition(context.motion, index, 2, 0.04),
        controlY: boundedPosition(context.motion, index, 3, 0.04),
        endX: boundedPosition(context.motion, index, 4, 0.04),
        endY: boundedPosition(context.motion, index, 5, 0.04),
        thickness: 0.055 + (index * 0.018),
      },
    ));
  }

  function buildTideBands(context) {
    return Array.from({ length: 3 }, (_, index) => primitive(
      'sineBand',
      index,
      context,
      {
        anchorX: boundedPosition(context.motion, index, 0, 0.06),
        anchorY: boundedPosition(context.motion, index, 1, 0.1),
        amplitude: 0.075 + (index * 0.024),
        frequency: 0.24 + (index * 0.08),
        phase: motionUnit(context.motion, index, 2),
        thickness: 0.045 + (index * 0.014),
      },
    ));
  }

  function buildVortexArcs(context) {
    return Array.from({ length: 3 }, (_, index) => primitive(
      'radialArc',
      index,
      context,
      {
        centerX: boundedPosition(context.motion, index, 0, 0.2),
        centerY: boundedPosition(context.motion, index, 1, 0.2),
        radius: 0.18 + (index * 0.09),
        start: motionUnit(context.motion, index, 2),
        span: 0.28 + (index * 0.08),
        thickness: 0.035 + (index * 0.012),
      },
    ));
  }

  const BUILDERS = {
    driftingMist: buildMistEllipses,
    innerCurrent: buildCurrentRibbons,
    softTide: buildTideBands,
    slowVortex: buildVortexArcs,
  };

  function createInteriorPrimitives(options = {}) {
    const effect = EFFECT_IDS.includes(options.effect) ? options.effect : 'driftingMist';
    const side = options.side === 'right' ? 'right' : 'left';
    const width = Math.max(1, Number(options.width) || 1);
    const height = Math.max(1, Number(options.height) || 1);
    const strength = clamp01(options.strength, 0.36);
    const motion = createSideMotion(effect, side, options.timeMs, options.speed);
    const palette = options.palette && typeof options.palette === 'object'
      ? options.palette
      : { mother: '', accentA: '', accentB: '' };
    const context = {
      motion,
      palette,
      alpha: 0.04 + (strength * 0.22),
    };
    return {
      effect,
      side,
      width,
      height,
      motion,
      primitives: BUILDERS[effect](context),
    };
  }

  return Object.freeze({
    EFFECT_IDS,
    DEFAULT_INTERIOR_MOTION_STATE,
    normalizeInteriorMotionState,
    deriveInteriorPalette,
    createSideMotion,
    createInteriorPrimitives,
  });
});
