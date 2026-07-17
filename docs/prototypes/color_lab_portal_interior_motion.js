(function attachPortalInteriorMotion(root, factory) {
  const field = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_message_field.js')
    : root?.PortalMessageField;
  const api = factory(field);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalInteriorMotion = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalInteriorMotion(field) {
  'use strict';

  const MODE_IDS = Object.freeze((field?.modeOrder || []).slice());
  const MODE_LABELS = Object.freeze({ ...(field?.modeLabels || {}) });
  const ANIMATED_MODE_IDS = Object.freeze((field?.animatedModes || []).slice());
  const DEFAULT_MODE = field?.defaults?.mode || MODE_IDS[0] || 'solid-a';

  const cloneSettings = (settings) => ({ ...(settings || {}) });
  const deepFreeze = (value) => {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.values(value).forEach((child) => deepFreeze(child));
    return Object.freeze(value);
  };

  function normalizeMode(mode) {
    return typeof field?.normalizeMode === 'function'
      ? field.normalizeMode(mode)
      : (MODE_IDS.includes(mode) ? mode : MODE_IDS[0]);
  }

  function controlsForMode(mode) {
    if (typeof field?.controlsForMode !== 'function') return Object.freeze([]);
    return Object.freeze(field.controlsForMode(normalizeMode(mode)).map((meta) => Object.freeze({
      key: meta.key,
      label: meta.label,
      min: meta.min,
      max: meta.max,
      step: meta.step,
      default: meta.default,
      unit: meta.unit,
    })));
  }

  function createModeSettings(mode) {
    if (typeof field?.createModeSettings !== 'function') return {};
    return cloneSettings(field.createModeSettings(normalizeMode(mode)));
  }

  function normalizeValue(meta, value) {
    return typeof field?.normalizeValue === 'function'
      ? field.normalizeValue(meta, value)
      : Number(value);
  }

  function createInteriorSettingsByMode() {
    return Object.fromEntries(
      MODE_IDS.slice(1).map((mode) => [mode, createModeSettings(mode)]),
    );
  }

  function createInteriorPhaseByMode() {
    return Object.fromEntries(ANIMATED_MODE_IDS.map((mode) => [mode, 0]));
  }

  function normalizeModeSettings(mode, settings) {
    const activeMode = normalizeMode(mode);
    return Object.fromEntries(
      controlsForMode(activeMode).map((meta) => [
        meta.key,
        normalizeValue(meta, settings?.[meta.key]),
      ]),
    );
  }

  const DEFAULT_INTERIOR_MOTION_STATE = deepFreeze({
    enabled: false,
    mode: DEFAULT_MODE,
    settingsByMode: createInteriorSettingsByMode(),
    phaseByMode: createInteriorPhaseByMode(),
  });

  function normalizeInteriorMotionState(value = {}) {
    const input = value && typeof value === 'object' ? value : {};
    const settingsByMode = createInteriorSettingsByMode();
    MODE_IDS.slice(1).forEach((mode) => {
      settingsByMode[mode] = normalizeModeSettings(mode, input.settingsByMode?.[mode]);
    });
    const phaseByMode = createInteriorPhaseByMode();
    ANIMATED_MODE_IDS.forEach((mode) => {
      const phase = Number(input.phaseByMode?.[mode]);
      phaseByMode[mode] = Number.isFinite(phase) ? phase : 0;
    });
    return {
      enabled: Boolean(input.enabled),
      mode: normalizeMode(input.mode),
      settingsByMode,
      phaseByMode,
    };
  }

  function hexToRgb(value) {
    if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
    return {
      r: parseInt(value.slice(1, 3), 16),
      g: parseInt(value.slice(3, 5), 16),
      b: parseInt(value.slice(5, 7), 16),
    };
  }

  function luminance(hex) {
    const rgb = hexToRgb(hex);
    if (!rgb) return -1;
    const channel = (value) => {
      const normalized = value / 255;
      return normalized <= 0.03928
        ? normalized / 12.92
        : ((normalized + 0.055) / 1.055) ** 2.4;
    };
    return (0.2126 * channel(rgb.r)) + (0.7152 * channel(rgb.g)) + (0.0722 * channel(rgb.b));
  }

  function uniqueHexColors(colors, fallback) {
    const values = (Array.isArray(colors) ? colors : [colors])
      .filter((color) => typeof color === 'string' && /^#[0-9a-f]{6}$/i.test(color))
      .map((color) => color.toLowerCase());
    return values.length ? Array.from(new Set(values)) : [fallback.toLowerCase()];
  }

  function deriveSideScale(colors, fallback) {
    const palette = uniqueHexColors(colors, fallback);
    let light = palette[0];
    let dark = palette[0];
    palette.forEach((color) => {
      if (luminance(color) > luminance(light)) light = color;
      if (luminance(color) < luminance(dark)) dark = color;
    });
    return { light, dark };
  }

  function deriveInteriorPalettes(options = {}) {
    return {
      left: deriveSideScale(
        options.leftColors || options.leftMother || '#49cfc5',
        '#49cfc5',
      ),
      right: deriveSideScale(
        options.rightColors || options.rightMother || '#d8b4fe',
        '#d8b4fe',
      ),
    };
  }

  function sideSeedOffset(side) {
    return side === 'right' ? 509 : 101;
  }

  function createSideRenderOptions(options = {}) {
    const mode = normalizeMode(options.mode);
    const side = options.side === 'right' ? 'right' : 'left';
    const settings = normalizeModeSettings(mode, options.settings);
    if (Number.isFinite(Number(settings.seed))) {
      settings.seed = (Number(settings.seed) + sideSeedOffset(side)) % 10000;
    }
    const phaseBase = Number(options.phase) || 0;
    const phase = phaseBase + (side === 'right' ? 0.673 : 0.137);
    return {
      mode,
      side,
      phase,
      settings,
      flipX: side === 'right',
    };
  }

  function advanceInteriorPhase(mode, phase, elapsedSeconds, settings) {
    if (typeof field?.advancePhase !== 'function') return Number(phase) || 0;
    return field.advancePhase(
      normalizeMode(mode),
      Number(phase) || 0,
      elapsedSeconds,
      settings,
    );
  }

  return Object.freeze({
    MODE_IDS,
    MODE_LABELS,
    ANIMATED_MODE_IDS,
    DEFAULT_INTERIOR_MOTION_STATE,
    normalizeMode,
    controlsForMode,
    createModeSettings,
    createInteriorSettingsByMode,
    createInteriorPhaseByMode,
    normalizeValue,
    normalizeModeSettings,
    normalizeInteriorMotionState,
    deriveInteriorPalettes,
    createSideRenderOptions,
    advanceInteriorPhase,
  });
});
