(function attachPortalMessageTransition(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageTransition = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageTransition() {
  'use strict';

  const modeOrder = Object.freeze([
    'pigment-spread',
    'island-takeover',
    'liquid-remap',
  ]);
  const modeLabels = Object.freeze({
    'pigment-spread': 'Pigmentterjedés',
    'island-takeover': 'Szigetes átalakulás',
    'liquid-remap': 'Folyékony színátírás',
  });
  const defaults = Object.freeze({ mode: 'pigment-spread' });

  const freezeSchema = (tuples) => Object.freeze(tuples.map((tuple) => Object.freeze({
    key: tuple[0],
    label: tuple[1],
    min: tuple[2],
    max: tuple[3],
    step: tuple[4],
    default: tuple[5],
    unit: tuple[6],
  })));
  const modeControls = Object.freeze({
    'pigment-spread': freezeSchema([
      ['duration', 'Időtartam', 300, 3000, 10, 1100, 'ms'],
      ['seedCount', 'Forrásszám', 1, 12, 1, 5, ''],
      ['sourceSpread', 'Forrásszórás', 0, 100, 1, 62, '%'],
      ['softness', 'Frontlágyság', 0, 100, 1, 78, '%'],
      ['diffusion', 'Diffúzió', 0, 100, 1, 56, '%'],
      ['warp', 'Domain warp', 0, 100, 1, 48, '%'],
      ['matterDelay', 'Portal-B késleltetés', 0, 80, 1, 24, '%'],
      ['overlap', 'Átfedés', 0, 100, 1, 38, '%'],
      ['easing', 'Lágyság', 1, 5, 0.1, 2.4, ''],
    ]),
    'island-takeover': freezeSchema([
      ['duration', 'Időtartam', 300, 3000, 10, 1200, 'ms'],
      ['seedCount', 'Magpontok', 2, 14, 1, 6, ''],
      ['initialRadius', 'Kezdősugár', 1, 30, 1, 7, '%'],
      ['growth', 'Növekedési ráta', 10, 200, 1, 96, '%'],
      ['merge', 'Összeolvadás', 0, 100, 1, 58, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 74, '%'],
      ['wander', 'Útvonal-vándorlás', 0, 100, 1, 38, '%'],
      ['matterEmergence', 'B megjelenése', 0, 100, 1, 46, '%'],
      ['overlap', 'Átfedés', 0, 100, 1, 42, '%'],
      ['easing', 'Lágyság', 1, 5, 0.1, 2.3, ''],
    ]),
    'liquid-remap': freezeSchema([
      ['duration', 'Időtartam', 300, 3000, 10, 980, 'ms'],
      ['colorStart', 'Színváltás kezdete', 0, 60, 1, 12, '%'],
      ['geometryStart', 'Geometriaváltás kezdete', 0, 60, 1, 28, '%'],
      ['warpScale', 'Warp skála', 20, 200, 1, 108, '%'],
      ['warpStrength', 'Warp erősség', 0, 100, 1, 46, '%'],
      ['flowSpeed', 'Áramlási sebesség', 0, 100, 1, 24, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 68, '%'],
      ['overlap', 'Átfedés', 0, 100, 1, 52, '%'],
      ['easing', 'Lágyság', 1, 5, 0.1, 2.2, ''],
    ]),
  });

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
  const clamp01 = (value) => clamp(Number.isFinite(value) ? value : 0, 0, 1);
  const lerp = (left, right, amount) => left + ((right - left) * amount);
  const fract = (value) => value - Math.floor(value);
  const smoothstep = (edge0, edge1, value) => {
    if (edge0 === edge1) return value < edge0 ? 0 : 1;
    const amount = clamp01((value - edge0) / (edge1 - edge0));
    return amount * amount * (3 - (2 * amount));
  };
  const ease = (progress, exponent) => 1 - ((1 - clamp01(progress)) ** exponent);
  const hash2 = (x, y, seed) => fract(
    Math.sin((x * 127.1) + (y * 311.7) + (seed * 0.0173)) * 43758.5453123,
  );
  const noise2 = (x, y, seed) => {
    const ix = Math.floor(x);
    const iy = Math.floor(y);
    const fx = x - ix;
    const fy = y - iy;
    const sx = fx * fx * (3 - (2 * fx));
    const sy = fy * fy * (3 - (2 * fy));
    const top = lerp(hash2(ix, iy, seed), hash2(ix + 1, iy, seed), sx);
    const bottom = lerp(hash2(ix, iy + 1, seed), hash2(ix + 1, iy + 1, seed), sx);
    return lerp(top, bottom, sy);
  };
  const gaussian = (dx, dy, radiusX, radiusY) => {
    const safeX = Math.max(0.0001, radiusX);
    const safeY = Math.max(0.0001, radiusY);
    return Math.exp(-0.5 * (((dx / safeX) ** 2) + ((dy / safeY) ** 2)));
  };
  const softReveal = (distance, radius, softness) => (
    1 - smoothstep(radius - softness, radius + softness, distance)
  );

  const normalizeMode = (mode) => modeOrder.includes(mode) ? mode : defaults.mode;
  const controlsForMode = (mode) => modeControls[normalizeMode(mode)];
  const normalizeValue = (meta, value) => {
    const empty = value === null || value === undefined
      || (typeof value === 'string' && value.trim() === '');
    const numeric = empty ? Number(meta.default) : Number(value);
    const fallback = Number(meta.default);
    const bounded = clamp(
      Number.isFinite(numeric) ? numeric : fallback,
      Number(meta.min),
      Number(meta.max),
    );
    const step = Math.max(Number.EPSILON, Number(meta.step) || 1);
    const snapped = Number(meta.min)
      + (Math.round((bounded - Number(meta.min)) / step) * step);
    const decimals = String(meta.step).includes('.')
      ? String(meta.step).split('.')[1].length
      : 0;
    return Number(snapped.toFixed(decimals));
  };
  const createModeSettings = (mode) => Object.fromEntries(
    controlsForMode(mode).map((meta) => [meta.key, meta.default]),
  );
  const normalizedSettings = (mode, settings) => Object.fromEntries(
    controlsForMode(mode).map((meta) => [meta.key, normalizeValue(meta, settings?.[meta.key])]),
  );

  function pigmentChannels(x, y, progress, settings) {
    const eased = ease(progress, settings.easing);
    let distance = Infinity;
    for (let index = 0; index < settings.seedCount; index += 1) {
      const spread = settings.sourceSpread / 100;
      const centerX = 0.5 + ((hash2(index, 1, 401) - 0.5) * spread);
      const centerY = 0.5 + ((hash2(index, 2, 401) - 0.5) * spread);
      const warp = (noise2(x * 3.2, y * 3.2, index + 17) - 0.5)
        * settings.warp / 180;
      distance = Math.min(distance, Math.hypot(x - centerX, y - centerY) + warp);
    }
    const softness = 0.01 + (settings.softness / 360);
    const radius = eased * (0.72 + (settings.diffusion / 90))
      * (1 + (settings.overlap / 240));
    const delay = settings.matterDelay / 100;
    const matterProgress = clamp01((progress - delay) / Math.max(0.001, 1 - delay));
    return {
      base: softReveal(distance, radius, softness),
      matter: softReveal(distance, matterProgress * radius, softness),
    };
  }

  function islandChannels(x, y, progress, settings) {
    const eased = ease(progress, settings.easing);
    let sum = 0;
    for (let index = 0; index < settings.seedCount; index += 1) {
      const angle = hash2(index, 4, 733) * Math.PI * 2;
      const wander = settings.wander / 100;
      const centerX = hash2(index, 5, 733)
        + (Math.cos(angle + (eased * 3)) * 0.12 * wander);
      const centerY = hash2(index, 6, 733)
        + (Math.sin(angle - (eased * 2.4)) * 0.1 * wander);
      const radius = (settings.initialRadius / 100) + (eased * settings.growth / 190);
      sum += gaussian(x - centerX, y - centerY, radius, radius);
    }
    const merged = 1 - Math.exp(-sum * (0.7 + (settings.merge / 45)));
    const softness = 0.02 + (settings.softness / 250);
    const base = smoothstep(0.18 - softness, 0.18 + softness, merged);
    const matterProgress = clamp01(
      (progress - ((100 - settings.matterEmergence) / 180))
        * (1 + (settings.overlap / 100)),
    );
    return { base, matter: base * ease(matterProgress, settings.easing) };
  }

  function liquidChannels(x, y, progress, settings) {
    const scale = 0.8 + (settings.warpScale / 80);
    const flow = progress * settings.flowSpeed / 65;
    const noise = noise2((x * scale) + flow, (y * scale) - (flow * 0.73), 997) - 0.5;
    const offset = noise * settings.warpStrength / 115;
    const width = 0.02 + (settings.softness / 220);
    const local = clamp01(progress + offset + ((settings.overlap - 50) / 220));
    const colorStart = settings.colorStart / 100;
    const geometryStart = settings.geometryStart / 100;
    const colorProgress = clamp01((local - colorStart) / Math.max(0.01, 1 - colorStart));
    const geometryProgress = clamp01(
      (local - geometryStart) / Math.max(0.01, 1 - geometryStart),
    );
    return {
      base: smoothstep(0 - width, 1 + width, ease(colorProgress, settings.easing)),
      matter: smoothstep(0 - width, 1 + width, ease(geometryProgress, settings.easing)),
    };
  }

  const samplers = Object.freeze({
    'pigment-spread': pigmentChannels,
    'island-takeover': islandChannels,
    'liquid-remap': liquidChannels,
  });

  function sampleChannels(mode, x, y, progress, input) {
    const numericProgress = Number(progress);
    const safeProgress = clamp01(Number.isFinite(numericProgress) ? numericProgress : 0);
    if (safeProgress <= 0) return { base: 0, matter: 0 };
    if (safeProgress >= 1) return { base: 1, matter: 1 };
    const activeMode = normalizeMode(mode);
    const settings = normalizedSettings(activeMode, input);
    const channels = samplers[activeMode](
      clamp01(Number(x)),
      clamp01(Number(y)),
      safeProgress,
      settings,
    );
    return {
      base: clamp01(channels.base),
      matter: clamp01(channels.matter),
    };
  }

  const easingString = (value) => {
    const strength = clamp01((Number(value) - 1) / 4);
    return `cubic-bezier(${(0.18 + (strength * 0.08)).toFixed(3)}, 0, ${(0.2 + (strength * 0.22)).toFixed(3)}, 1)`;
  };

  function buildDescriptor(mode, input, targetState, reducedMotion) {
    const activeMode = normalizeMode(mode);
    const settings = normalizedSettings(activeMode, input);
    const isReduced = Boolean(reducedMotion);
    return Object.freeze({
      mode: activeMode,
      settings: Object.freeze({ ...settings }),
      duration: isReduced ? 160 : settings.duration,
      easing: easingString(settings.easing),
      targetState: targetState === 'balance' ? 'balance' : 'message',
      reducedMotion: isReduced,
    });
  }

  return Object.freeze({
    modeOrder,
    modeLabels,
    defaults,
    normalizeMode,
    controlsForMode,
    createModeSettings,
    normalizeValue,
    sampleChannels,
    buildDescriptor,
  });
});
