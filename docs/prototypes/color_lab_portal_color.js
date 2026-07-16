(function attachPortalMessageColor(root, factory) {
  const energy = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_energy.js')
    : root?.MindPortalEnergy;
  const api = factory(energy);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageColor = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageColor(energy) {
  'use strict';

  const modeOrder = Object.freeze([
    'none',
    'static',
    'dual-tide',
    'magnetic-membrane',
    'breathing-lens',
    'cellular-field',
  ]);
  const dynamicModes = Object.freeze(modeOrder.slice(2));
  const modeLabels = Object.freeze({
    none: 'Semmi',
    static: 'Statikus portál A/B',
    'dual-tide': 'Kettős árapály',
    'magnetic-membrane': 'Mágneses membrán',
    'breathing-lens': 'Lélegző lencse',
    'cellular-field': 'Celluláris mező',
  });
  const paletteStops = Object.freeze([
    Object.freeze({ position: 0, color: '#fffdfd' }),
    Object.freeze({ position: 50, color: '#ffc4e4' }),
    Object.freeze({ position: 100, color: '#8b5cf6' }),
  ]);
  const defaults = Object.freeze({ center: 50, windowSize: 68 });
  const emptyControls = Object.freeze([]);

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
  const normalizeNumber = (value, fallback, min, max) => {
    const empty = value === null || value === undefined
      || (typeof value === 'string' && value.trim() === '');
    const numeric = empty ? fallback : Number(value);
    return Math.round(clamp(Number.isFinite(numeric) ? numeric : fallback, min, max));
  };
  const normalizeMode = (mode) => modeOrder.includes(mode) ? mode : 'none';
  const normalizeCenter = (value) => normalizeNumber(value, defaults.center, 0, 100);
  const normalizeWindow = (value) => normalizeNumber(value, defaults.windowSize, 10, 100);
  const normalizePercent = (value) => {
    const numeric = Number(value);
    return clamp(Number.isFinite(numeric) ? numeric : 0, 0, 100);
  };
  const hexChannels = (hex) => [1, 3, 5]
    .map((index) => parseInt(hex.slice(index, index + 2), 16));
  const mixHex = (left, right, amount) => {
    const a = hexChannels(left);
    const b = hexChannels(right);
    const channel = (index) => Math.round(a[index] + ((b[index] - a[index]) * amount))
      .toString(16)
      .padStart(2, '0');
    return `#${channel(0)}${channel(1)}${channel(2)}`;
  };
  const samplePalette = (value) => {
    const position = normalizePercent(value);
    return position <= 50
      ? mixHex('#fffdfd', '#ffc4e4', position / 50)
      : mixHex('#ffc4e4', '#8b5cf6', (position - 50) / 50);
  };
  const sampleWindow = (center, windowSize) => {
    const safeCenter = normalizeCenter(center);
    const safeWindow = normalizeWindow(windowSize);
    const lower = clamp(safeCenter - (safeWindow / 2), 0, 100);
    const upper = clamp(safeCenter + (safeWindow / 2), 0, 100);
    return {
      center: safeCenter,
      windowSize: safeWindow,
      lower,
      upper,
      a: samplePalette(lower),
      b: samplePalette(upper),
    };
  };
  const isDynamicMode = (mode) => dynamicModes.includes(mode);
  const controlsForMode = (mode) => isDynamicMode(mode)
    ? energy.controlsForMode(mode)
    : emptyControls;
  const createModeSettings = (mode) => Object.fromEntries(
    controlsForMode(mode).map((meta) => [meta.key, meta.default]),
  );
  const normalizeControlValue = (meta, value) => {
    const empty = value === null || value === undefined
      || (typeof value === 'string' && value.trim() === '');
    const numeric = empty ? Number(meta.default) : Number(value);
    const fallback = Number(meta.default);
    const bounded = clamp(
      Number.isFinite(numeric) ? numeric : fallback,
      Number(meta.min),
      Number(meta.max),
    );
    const step = Number(meta.step);
    const snapped = Number(meta.min)
      + (Math.round((bounded - Number(meta.min)) / step) * step);
    const decimals = String(meta.step).includes('.')
      ? String(meta.step).split('.')[1].length
      : 0;
    return Number(snapped.toFixed(decimals));
  };
  const buildTransition = (mode, targetState, windowOpacity, duration, reducedMotion) => {
    const activeMode = normalizeMode(mode);
    const target = targetState === 'balance' ? 'balance' : 'message';
    const alpha = clamp(Number(windowOpacity) || 0, 0, 1);
    const balanceRest = { baseOpacity: alpha, colorOpacity: 0 };
    const messageRest = activeMode === 'none'
      ? { ...balanceRest }
      : { baseOpacity: 0, colorOpacity: alpha };

    if (activeMode === 'none') {
      return {
        mode: 'none',
        targetState: target,
        duration: 0,
        easing: 'linear',
        baseKeyframes: [],
        colorKeyframes: [],
        balanceRest,
        messageRest,
      };
    }

    const forward = target === 'message';
    return {
      mode: activeMode,
      targetState: target,
      duration: reducedMotion
        ? 160
        : clamp(Math.round(Number(duration) || 900), 0, 4000),
      easing: reducedMotion ? 'linear' : 'cubic-bezier(.2,.82,.2,1)',
      baseKeyframes: forward
        ? [{ opacity: alpha, offset: 0 }, { opacity: 0, offset: 1 }]
        : [{ opacity: 0, offset: 0 }, { opacity: alpha, offset: 1 }],
      colorKeyframes: forward
        ? [{ opacity: 0, offset: 0 }, { opacity: alpha, offset: 1 }]
        : [{ opacity: alpha, offset: 0 }, { opacity: 0, offset: 1 }],
      balanceRest,
      messageRest,
    };
  };

  return Object.freeze({
    modeOrder,
    modeLabels,
    dynamicModes,
    paletteStops,
    defaults,
    normalizeMode,
    normalizeCenter,
    normalizeWindow,
    samplePalette,
    sampleWindow,
    isDynamicMode,
    controlsForMode,
    createModeSettings,
    normalizeControlValue,
    buildTransition,
  });
});
