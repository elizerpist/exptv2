(function attachPortalMessageField(root, factory) {
  const palette = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_color.js')
    : root?.PortalMessageColor;
  const api = factory(palette);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageField = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageField(palette) {
  'use strict';

  const modeOrder = Object.freeze([
    'solid-a',
    'static-matter',
    'wandering-mist',
    'living-archipelago',
    'forming-clouds',
  ]);
  const animatedModes = Object.freeze([
    'wandering-mist',
    'living-archipelago',
    'forming-clouds',
  ]);
  const modeLabels = Object.freeze({
    'solid-a': 'Nincs dinamikus effekt',
    'static-matter': 'Statikus köd/szigetek',
    'wandering-mist': 'Vándorló köd',
    'living-archipelago': 'Élő szigetvilág',
    'forming-clouds': 'Keletkező energiafelhők',
  });
  const defaults = Object.freeze({
    mode: 'wandering-mist',
    center: palette?.defaults?.center ?? 50,
    windowSize: palette?.defaults?.windowSize ?? 68,
  });
  const paletteStops = Object.freeze(
    (palette?.paletteStops || []).map((stop) => Object.freeze({ ...stop })),
  );

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
    'solid-a': freezeSchema([]),
    'static-matter': freezeSchema([
      ['coverage', 'B-fedettség', 0, 80, 1, 34, '%'],
      ['strength', 'B-erősség', 0, 100, 1, 72, '%'],
      ['scale', 'Anyagskála', 20, 180, 1, 100, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 76, '%'],
      ['detail', 'Részletesség', 0, 100, 1, 28, '%'],
      ['seed', 'Véletlenmag', 0, 9999, 1, 137, ''],
    ]),
    'wandering-mist': freezeSchema([
      ['coverage', 'B-fedettség', 0, 80, 1, 36, '%'],
      ['strength', 'B-erősség', 0, 100, 1, 74, '%'],
      ['scale', 'Ködskála', 20, 200, 1, 118, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 82, '%'],
      ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 22, '%'],
      ['curl', 'Curl erősség', 0, 100, 1, 44, '%'],
      ['morphRate', 'Alakváltozás', 0, 100, 1, 28, '%'],
      ['detail', 'Részletesség', 0, 100, 1, 24, '%'],
      ['seed', 'Véletlenmag', 0, 9999, 1, 311, ''],
    ]),
    'living-archipelago': freezeSchema([
      ['islandCount', 'Szigetszám', 2, 12, 1, 6, ''],
      ['size', 'Átlagos méret', 8, 80, 1, 34, '%'],
      ['sizeVariance', 'Méreteltérés', 0, 100, 1, 42, '%'],
      ['strength', 'B-erősség', 0, 100, 1, 78, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 66, '%'],
      ['wanderSpeed', 'Vándorlási sebesség', 0, 100, 1, 30, '%'],
      ['mergeAttraction', 'Összeolvadási vonzás', 0, 100, 1, 55, '%'],
      ['morphRate', 'Alakváltozás', 0, 100, 1, 36, '%'],
      ['seed', 'Véletlenmag', 0, 9999, 1, 521, ''],
    ]),
    'forming-clouds': freezeSchema([
      ['density', 'Aktív felhősűrűség', 1, 10, 1, 4, ''],
      ['lifetime', 'Élettartam', 2, 30, 1, 14, 's'],
      ['birthOverlap', 'Születési átfedés', 0, 100, 1, 58, '%'],
      ['growth', 'Növekedés', 0, 100, 1, 46, '%'],
      ['strength', 'B-erősség', 0, 100, 1, 76, '%'],
      ['scale', 'Felhőskála', 10, 120, 1, 46, '%'],
      ['softness', 'Peremlágyság', 0, 100, 1, 78, '%'],
      ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 24, '%'],
      ['pathIrregularity', 'Útvonal-szabálytalanság', 0, 100, 1, 52, '%'],
      ['seed', 'Véletlenmag', 0, 9999, 1, 887, ''],
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
  const hash2 = (x, y, seed) => fract(
    Math.sin((x * 127.1) + (y * 311.7) + (seed * 0.0173)) * 43758.5453123,
  );
  const valueNoise = (x, y, seed) => {
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
  const fbm = (x, y, seed, octaves) => {
    let frequency = 1;
    let amplitude = 0.5;
    let total = 0;
    let weight = 0;
    for (let octave = 0; octave < octaves; octave += 1) {
      total += valueNoise(x * frequency, y * frequency, seed + (octave * 97)) * amplitude;
      weight += amplitude;
      frequency *= 2.03;
      amplitude *= 0.5;
    }
    return weight ? total / weight : 0;
  };
  const gaussian = (dx, dy, radiusX, radiusY) => {
    const safeX = Math.max(0.0001, radiusX);
    const safeY = Math.max(0.0001, radiusY);
    return Math.exp(-0.5 * (((dx / safeX) ** 2) + ((dy / safeY) ** 2)));
  };

  const normalizeMode = (mode) => modeOrder.includes(mode) ? mode : 'solid-a';
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
  const materialThreshold = (value, coverage, softness) => {
    const center = 1 - (coverage / 100);
    const width = 0.015 + ((softness / 100) * 0.24);
    return smoothstep(center - width, center + width, value);
  };

  const sampleStaticMatter = (x, y, settings) => {
    const frequency = 3.8 - ((settings.scale / 180) * 2.9);
    const coarse = fbm(x * frequency, y * frequency, settings.seed, 3);
    const fine = fbm(
      x * frequency * 2.7,
      y * frequency * 2.7,
      settings.seed + 41,
      2,
    );
    const value = lerp(coarse, fine, settings.detail / 180);
    return clamp01(
      materialThreshold(value, settings.coverage, settings.softness)
        * settings.strength / 100,
    );
  };

  const sampleWanderingMist = (x, y, phase, settings) => {
    const frequency = 4.2 - ((settings.scale / 200) * 3.35);
    const drift = phase * (0.035 + (settings.driftSpeed / 420));
    const morph = phase * (0.025 + (settings.morphRate / 520));
    const curl = (settings.curl / 100) * 0.48;
    const warpX = fbm(
      (x * 1.7) + Math.cos(drift),
      (y * 1.7) + Math.sin(morph),
      settings.seed + 17,
      3,
    ) - 0.5;
    const warpY = fbm(
      (x * 1.7) - Math.sin(morph),
      (y * 1.7) + Math.cos(drift),
      settings.seed + 73,
      3,
    ) - 0.5;
    const px = ((x + (warpX * curl)) * frequency) + Math.cos(drift * 0.73);
    const py = ((y + (warpY * curl)) * frequency) + Math.sin(drift * 0.61);
    const broad = fbm(px, py, settings.seed, 3);
    const fine = fbm(
      (px * 2.6) - morph,
      (py * 2.6) + morph,
      settings.seed + 191,
      2,
    );
    const value = lerp(broad, fine, settings.detail / 150);
    return clamp01(
      materialThreshold(value, settings.coverage, settings.softness)
        * settings.strength / 100,
    );
  };

  const sampleArchipelago = (x, y, phase, settings) => {
    let sum = 0;
    for (let index = 0; index < settings.islandCount; index += 1) {
      const angle = hash2(index, 1, settings.seed) * Math.PI * 2;
      const rate = 0.08 + (settings.wanderSpeed / 560)
        + (hash2(index, 2, settings.seed) * 0.09);
      const orbit = 0.1 + (hash2(index, 3, settings.seed) * 0.34);
      const cx = 0.5 + (Math.cos(angle + (phase * rate)) * orbit);
      const cy = 0.5
        + (Math.sin((angle * 1.31) - (phase * rate * 0.83)) * orbit * 0.72);
      const variance = 1
        + ((hash2(index, 4, settings.seed) - 0.5) * settings.sizeVariance / 100);
      const morph = 1 + (
        Math.sin((phase * (0.08 + (settings.morphRate / 600))) + angle)
        * settings.morphRate / 310
      );
      const radius = Math.max(0.025, (settings.size / 220) * variance * morph);
      sum += gaussian(
        x - cx,
        y - cy,
        radius,
        radius * (0.72 + (hash2(index, 5, settings.seed) * 0.42)),
      );
    }
    const merged = 1 - Math.exp(-sum * (0.7 + (settings.mergeAttraction / 42)));
    const width = 0.03 + (settings.softness / 260);
    return clamp01(
      smoothstep(0.2 - width, 0.2 + width, merged) * settings.strength / 100,
    );
  };

  const sampleFormingClouds = (x, y, phase, settings) => {
    let fieldValue = 0;
    const count = Math.max(2, settings.density * 2);
    for (let index = 0; index < count; index += 1) {
      const offset = hash2(index, 11, settings.seed);
      const age = fract((phase / Math.max(2, settings.lifetime)) + offset);
      const overlap = 0.35 + (settings.birthOverlap / 125);
      const life = Math.pow(
        Math.max(0, Math.sin(Math.PI * age)),
        0.65 + ((100 - settings.growth) / 95),
      );
      const irregularity = settings.pathIrregularity / 100;
      const drift = age * (0.05 + (settings.driftSpeed / 170));
      const cx = fract(
        hash2(index, 12, settings.seed)
          + drift
          + (Math.sin((age + offset) * Math.PI * 2) * 0.08 * irregularity),
      );
      const cy = clamp01(
        hash2(index, 13, settings.seed)
          + (Math.sin((age * 4.7) + (offset * 8)) * 0.2 * irregularity),
      );
      const radius = Math.max(
        0.02,
        (settings.scale / 210) * (0.35 + (life * overlap)),
      );
      fieldValue = Math.max(
        fieldValue,
        gaussian(x - cx, y - cy, radius, radius * 0.76) * life,
      );
    }
    const width = 0.02 + (settings.softness / 240);
    return clamp01(
      smoothstep(0.18 - width, 0.18 + width, fieldValue)
        * settings.strength / 100,
    );
  };

  const sampleMatter = (mode, x, y, phase, settings) => {
    const activeMode = normalizeMode(mode);
    if (activeMode === 'solid-a') return 0;
    const safeSettings = normalizedSettings(activeMode, settings);
    const nx = clamp01(Number(x));
    const ny = clamp01(Number(y));
    const time = Number(phase) || 0;
    if (activeMode === 'static-matter') return sampleStaticMatter(nx, ny, safeSettings);
    if (activeMode === 'wandering-mist') {
      return sampleWanderingMist(nx, ny, time, safeSettings);
    }
    if (activeMode === 'living-archipelago') {
      return sampleArchipelago(nx, ny, time, safeSettings);
    }
    return sampleFormingClouds(nx, ny, time, safeSettings);
  };

  const advancePhase = (mode, phase, elapsedSeconds, settings) => {
    const activeMode = normalizeMode(mode);
    const current = Number(phase) || 0;
    if (!animatedModes.includes(activeMode)) return current;
    const safeSettings = normalizedSettings(activeMode, settings);
    const speed = activeMode === 'living-archipelago'
      ? safeSettings.wanderSpeed
      : safeSettings.driftSpeed;
    return current + (Math.max(0, Number(elapsedSeconds) || 0) * speed / 24);
  };
  const renderProfile = (mode) => normalizeMode(mode) === 'forming-clouds'
    ? Object.freeze({ renderScale: 0.48, frameMs: 52 })
    : Object.freeze({ renderScale: 0.55, frameMs: 48 });

  return Object.freeze({
    modeOrder,
    modeLabels,
    animatedModes,
    defaults,
    paletteStops,
    normalizeMode,
    normalizeCenter: palette.normalizeCenter,
    normalizeWindow: palette.normalizeWindow,
    samplePalette: palette.samplePalette,
    sampleWindow: palette.sampleWindow,
    controlsForMode,
    createModeSettings,
    normalizeValue,
    sampleMatter,
    advancePhase,
    renderProfile,
  });
});
