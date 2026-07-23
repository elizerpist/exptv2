(function attachMindPortalEnergy(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.MindPortalEnergy = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildMindPortalEnergy() {
  'use strict';

  const modeOrder = [
    'static',
    'dual-tide',
    'magnetic-membrane',
    'breathing-lens',
    'cellular-field',
    'balance-membrane',
    'balance-counterflow',
    'balance-charges',
  ];
  const modeLabels = Object.freeze({
    static: 'Statikus A/B',
    'dual-tide': 'Kettős árapály',
    'magnetic-membrane': 'Mágneses membrán',
    'breathing-lens': 'Lélegző lencse',
    'cellular-field': 'Celluláris mező',
    'balance-membrane': 'Balance membrán',
    'balance-counterflow': 'Balance ellenáram',
    'balance-charges': 'Balance töltések',
  });

  const balanceModeIds = Object.freeze([
    'balance-membrane',
    'balance-counterflow',
    'balance-charges',
  ]);

  const commonControls = Object.freeze([
    { key: 'strength', label: 'Animáció erő', min: 0, max: 1, step: 0.01, default: 0.82 },
    { key: 'speed', label: 'Sebesség', min: 0, max: 2, step: 0.01, default: 0.42 },
    { key: 'bias', label: 'A/B alaparány', min: -0.35, max: 0.35, step: 0.01, default: 0 },
    { key: 'ratioSwing', label: 'Aránykilengés', min: 0, max: 0.35, step: 0.01, default: 0.12 },
    { key: 'ratioSpeed', label: 'Aránysebesség', min: 0, max: 1, step: 0.01, default: 0.18 },
    { key: 'fieldScale', label: 'Mezőméret', min: 0.5, max: 2, step: 0.01, default: 1 },
    { key: 'morphAmount', label: 'Morfológia', min: 0, max: 1, step: 0.01, default: 0.34 },
    { key: 'morphSpeed', label: 'Morfológia seb.', min: 0, max: 1, step: 0.01, default: 0.16 },
    { key: 'softness', label: 'Határ puhaság', min: 0.02, max: 0.48, step: 0.01, default: 0.22 },
    { key: 'detail', label: 'Felületi részlet', min: 0, max: 0.5, step: 0.01, default: 0.10 },
    { key: 'pulseAmount', label: 'Energiaimpulzus', min: 0, max: 0.35, step: 0.01, default: 0.08 },
    { key: 'pulseSpeed', label: 'Impulzus seb.', min: 0, max: 1, step: 0.01, default: 0.12 },
    { key: 'lightAmount', label: 'Fénykiemelés', min: 0, max: 0.25, step: 0.01, default: 0.05 },
    { key: 'renderScale', label: 'Render minőség', min: 0.35, max: 1, step: 0.05, default: 0.60 },
    { key: 'frameMs', label: 'Render lépés', min: 16, max: 100, step: 1, default: 42 },
  ]);

  const balanceCommonControls = Object.freeze([
    { key: 'strength', label: 'Animáció erő', min: 0, max: 1, step: 0.01, default: 0.82 },
    { key: 'speed', label: 'Sebesség', min: 0, max: 2, step: 0.01, default: 0.24 },
    { key: 'seamSoftness', label: 'Határ puhaság', min: 0.02, max: 0.32, step: 0.01, default: 0.12 },
    { key: 'lightAmount', label: 'Fényenergia', min: 0, max: 0.22, step: 0.01, default: 0.08 },
    { key: 'chromaAmount', label: 'Színenergia', min: 0, max: 0.35, step: 0.01, default: 0.10 },
    { key: 'pulseAmount', label: 'Pulzus', min: 0, max: 0.20, step: 0.01, default: 0.05 },
    { key: 'pulseSpeed', label: 'Pulzus seb.', min: 0, max: 1, step: 0.01, default: 0.10 },
    { key: 'renderScale', label: 'Render minőség', min: 0.35, max: 1, step: 0.05, default: 0.60 },
    { key: 'frameMs', label: 'Render lépés', min: 16, max: 100, step: 1, default: 42 },
  ]);

  const modeControls = Object.freeze({
    'dual-tide': Object.freeze([
      { key: 'wanderX', label: 'Vándorlás X', min: 0, max: 0.48, step: 0.01, default: 0.28 },
      { key: 'wanderY', label: 'Vándorlás Y', min: 0, max: 0.38, step: 0.01, default: 0.18 },
      { key: 'intrusion', label: 'Behatolás', min: 0, max: 0.65, step: 0.01, default: 0.34 },
      { key: 'separation', label: 'Mezőtávolság', min: 0, max: 0.80, step: 0.01, default: 0.42 },
      { key: 'lobeARadius', label: 'A mező sugár', min: 0.12, max: 0.75, step: 0.01, default: 0.42 },
      { key: 'lobeBRadius', label: 'B mező sugár', min: 0.12, max: 0.75, step: 0.01, default: 0.40 },
      { key: 'lobeAEllipse', label: 'A nyújtás', min: 0.50, max: 2, step: 0.01, default: 0.95 },
      { key: 'lobeBEllipse', label: 'B nyújtás', min: 0.50, max: 2, step: 0.01, default: 1.05 },
      { key: 'phaseOffset', label: 'Ellenfázis', min: 0, max: 360, step: 1, default: 180 },
      { key: 'counterFlow', label: 'Visszaáramlás', min: 0, max: 1, step: 0.01, default: 0.72 },
      { key: 'warpAmount', label: 'Mezőtorzítás', min: 0, max: 0.50, step: 0.01, default: 0.16 },
      { key: 'warpScale', label: 'Torzítás méret', min: 0.40, max: 3, step: 0.01, default: 1.10 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.14 },
    ]),
    'magnetic-membrane': Object.freeze([
      { key: 'nodeTop', label: 'Felső pólus', min: -0.50, max: 0.50, step: 0.01, default: 0.14 },
      { key: 'nodeMiddle', label: 'Középső pólus', min: -0.50, max: 0.50, step: 0.01, default: -0.08 },
      { key: 'nodeBottom', label: 'Alsó pólus', min: -0.50, max: 0.50, step: 0.01, default: 0.12 },
      { key: 'nodeWander', label: 'Pólusvándorlás', min: 0, max: 0.40, step: 0.01, default: 0.16 },
      { key: 'nodePhaseSpread', label: 'Pólusfázis', min: 0, max: 360, step: 1, default: 120 },
      { key: 'primaryAmplitude', label: 'Fő hullámerő', min: 0, max: 0.45, step: 0.01, default: 0.18 },
      { key: 'primaryWavelength', label: 'Fő hullámhossz', min: 0.35, max: 3, step: 0.01, default: 1.25 },
      { key: 'primarySpeed', label: 'Fő hullámseb.', min: 0, max: 1, step: 0.01, default: 0.16 },
      { key: 'secondaryAmplitude', label: 'Mellékhullám-erő', min: 0, max: 0.30, step: 0.01, default: 0.08 },
      { key: 'secondaryWavelength', label: 'Mellékhullámhossz', min: 0.35, max: 4, step: 0.01, default: 2.10 },
      { key: 'secondarySpeed', label: 'Mellékhullám-seb.', min: 0, max: 1, step: 0.01, default: 0.09 },
      { key: 'skew', label: 'Membrándőlés', min: -0.50, max: 0.50, step: 0.01, default: 0.08 },
      { key: 'tension', label: 'Membránfeszülés', min: 0, max: 1, step: 0.01, default: 0.62 },
      { key: 'warpAmount', label: 'Felülettorzítás', min: 0, max: 0.35, step: 0.01, default: 0.09 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.12 },
    ]),
    'breathing-lens': Object.freeze([
      { key: 'centerX', label: 'Lencseközép X', min: 0.10, max: 0.90, step: 0.01, default: 0.55 },
      { key: 'centerY', label: 'Lencseközép Y', min: 0.10, max: 0.90, step: 0.01, default: 0.48 },
      { key: 'wanderX', label: 'Középvándorlás X', min: 0, max: 0.40, step: 0.01, default: 0.18 },
      { key: 'wanderY', label: 'Középvándorlás Y', min: 0, max: 0.40, step: 0.01, default: 0.14 },
      { key: 'radiusX', label: 'Lencsesugár X', min: 0.08, max: 0.80, step: 0.01, default: 0.34 },
      { key: 'radiusY', label: 'Lencsesugár Y', min: 0.08, max: 1, step: 0.01, default: 0.46 },
      { key: 'breathX', label: 'Légzés X', min: 0, max: 0.40, step: 0.01, default: 0.16 },
      { key: 'breathY', label: 'Légzés Y', min: 0, max: 0.40, step: 0.01, default: 0.12 },
      { key: 'breathSpeed', label: 'Légzés seb.', min: 0, max: 1, step: 0.01, default: 0.18 },
      { key: 'pressure', label: 'Lencsenyomás', min: -1, max: 1, step: 0.01, default: 0.48 },
      { key: 'refraction', label: 'Mezőtörés', min: 0, max: 0.60, step: 0.01, default: 0.20 },
      { key: 'edgeFalloff', label: 'Peremlecsengés', min: 0.02, max: 0.50, step: 0.01, default: 0.18 },
      { key: 'satelliteAmount', label: 'Mellékmező erő', min: -1, max: 1, step: 0.01, default: 0.22 },
      { key: 'satelliteRadius', label: 'Mellékmező sugár', min: 0.05, max: 0.50, step: 0.01, default: 0.18 },
      { key: 'satelliteDistance', label: 'Mellékmező táv', min: 0, max: 0.75, step: 0.01, default: 0.36 },
      { key: 'satellitePhase', label: 'Mellékmező fázis', min: 0, max: 360, step: 1, default: 140 },
    ]),
    'cellular-field': Object.freeze([
      { key: 'cellCount', label: 'Cellaszám', min: 3, max: 7, step: 1, default: 5 },
      { key: 'cellSize', label: 'Cellaméret', min: 0.12, max: 0.75, step: 0.01, default: 0.36 },
      { key: 'cellVariation', label: 'Méretváltozatosság', min: 0, max: 0.70, step: 0.01, default: 0.25 },
      { key: 'advectionX', label: 'Áramlás X', min: -0.50, max: 0.50, step: 0.01, default: 0.16 },
      { key: 'advectionY', label: 'Áramlás Y', min: -0.50, max: 0.50, step: 0.01, default: 0.06 },
      { key: 'curlAmount', label: 'Örvénymező', min: 0, max: 1, step: 0.01, default: 0.35 },
      { key: 'curlScale', label: 'Örvényméret', min: 0.35, max: 3, step: 0.01, default: 1.10 },
      { key: 'mergeThreshold', label: 'Összeolvadási küszöb', min: -0.50, max: 0.50, step: 0.01, default: 0 },
      { key: 'polarityBalance', label: 'Cellapolaritás', min: -0.50, max: 0.50, step: 0.01, default: 0 },
      { key: 'cellWander', label: 'Cellavándorlás', min: 0, max: 0.50, step: 0.01, default: 0.22 },
      { key: 'cellMorph', label: 'Cellamorfológia', min: 0, max: 1, step: 0.01, default: 0.28 },
      { key: 'noiseScale', label: 'Morfológia méret', min: 0.35, max: 3, step: 0.01, default: 1.40 },
      { key: 'noiseAmount', label: 'Morfológia erő', min: 0, max: 0.50, step: 0.01, default: 0.12 },
      { key: 'noiseSpeed', label: 'Morfológia seb.', min: 0, max: 1, step: 0.01, default: 0.14 },
      { key: 'pressure', label: 'Cellanyomás', min: 0, max: 1, step: 0.01, default: 0.70 },
    ]),
    'balance-membrane': Object.freeze([
      { key: 'boundaryAmplitude', label: 'Határkilengés', min: 0, max: 0.28, step: 0.01, default: 0.12 },
      { key: 'primaryWavelength', label: 'Fő hullámhossz', min: 0.35, max: 3, step: 0.01, default: 1.10 },
      { key: 'secondaryAmplitude', label: 'Mellékhullám', min: 0, max: 0.18, step: 0.01, default: 0.06 },
      { key: 'secondaryWavelength', label: 'Mellékhullámhossz', min: 0.35, max: 4, step: 0.01, default: 2.20 },
      { key: 'nodePhase', label: 'Csomópont fázis', min: 0, max: 360, step: 1, default: 118 },
      { key: 'driftSpeed', label: 'Határvándorlás', min: 0, max: 1, step: 0.01, default: 0.14 },
      { key: 'tension', label: 'Membránfeszülés', min: 0, max: 1, step: 0.01, default: 0.58 },
      { key: 'warpAmount', label: 'Lokális torzítás', min: 0, max: 0.18, step: 0.01, default: 0.05 },
      { key: 'warpScale', label: 'Torzítás méret', min: 0.4, max: 3, step: 0.01, default: 1.35 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.10 },
    ]),
    'balance-counterflow': Object.freeze([
      { key: 'intrusion', label: 'Benyúlás', min: 0, max: 0.32, step: 0.01, default: 0.15 },
      { key: 'lobeCount', label: 'Áramlatpárok', min: 1, max: 6, step: 1, default: 3 },
      { key: 'lobeRadius', label: 'Áramlatsugár', min: 0.08, max: 0.45, step: 0.01, default: 0.22 },
      { key: 'lobeEllipse', label: 'Áramlatnyújtás', min: 0.5, max: 2, step: 0.01, default: 1.15 },
      { key: 'counterPhase', label: 'Ellenfázis', min: 90, max: 270, step: 1, default: 180 },
      { key: 'verticalDrift', label: 'Függőleges sodrás', min: 0, max: 1, step: 0.01, default: 0.12 },
      { key: 'compensation', label: 'Aránykompenzáció', min: 0, max: 1, step: 0.01, default: 0.86 },
      { key: 'lobeSharpness', label: 'Áramlatkarakter', min: 0.5, max: 3, step: 0.01, default: 1.35 },
      { key: 'warpAmount', label: 'Lokális torzítás', min: 0, max: 0.16, step: 0.01, default: 0.04 },
      { key: 'warpScale', label: 'Torzítás méret', min: 0.4, max: 3, step: 0.01, default: 1.20 },
      { key: 'warpSpeed', label: 'Torzítás seb.', min: 0, max: 1, step: 0.01, default: 0.09 },
    ]),
    'balance-charges': Object.freeze([
      { key: 'seamDrift', label: 'Határvándorlás', min: 0, max: 0.12, step: 0.01, default: 0.035 },
      { key: 'seamWavelength', label: 'Határhullámhossz', min: 0.4, max: 3, step: 0.01, default: 1.45 },
      { key: 'seamSpeed', label: 'Határsebesség', min: 0, max: 1, step: 0.01, default: 0.10 },
      { key: 'chargeCount', label: 'Töltésszám', min: 2, max: 8, step: 1, default: 6 },
      { key: 'chargeSize', label: 'Töltésméret', min: 0.06, max: 0.42, step: 0.01, default: 0.18 },
      { key: 'chargeVariation', label: 'Méretváltozatosság', min: 0, max: 0.7, step: 0.01, default: 0.24 },
      { key: 'chargeWander', label: 'Töltésvándorlás', min: 0, max: 0.32, step: 0.01, default: 0.12 },
      { key: 'chargeLight', label: 'Töltés fényereje', min: 0, max: 1, step: 0.01, default: 0.72 },
      { key: 'chargeChroma', label: 'Töltés színessége', min: 0, max: 1, step: 0.01, default: 0.64 },
      { key: 'sidePhase', label: 'Oldalak fázisa', min: 0, max: 360, step: 1, default: 180 },
      { key: 'chargeMorph', label: 'Töltésmorfológia', min: 0, max: 1, step: 0.01, default: 0.22 },
      { key: 'noiseScale', label: 'Morfológia méret', min: 0.4, max: 3, step: 0.01, default: 1.35 },
    ]),
  });

  const clamp01 = (value) => Math.max(0, Math.min(1, value));
  const lerp = (a, b, amount) => a + ((b - a) * amount);
  const smoothstep = (edge0, edge1, value) => {
    const t = clamp01((value - edge0) / Math.max(1e-6, edge1 - edge0));
    return t * t * (3 - (2 * t));
  };
  const gaussian = (dx, dy, rx, ry) => Math.exp(-(
    ((dx * dx) / Math.max(1e-6, rx * rx)) +
    ((dy * dy) / Math.max(1e-6, ry * ry))
  ));
  const hash = (x, y, seed = 0) => {
    let value = Math.imul(x | 0, 374761393)
      ^ Math.imul(y | 0, 668265263)
      ^ Math.imul(Math.round(seed * 1000), 1442695041);
    value = Math.imul(value ^ (value >>> 13), 1274126177);
    value ^= value >>> 16;
    return (value >>> 0) / 4294967295;
  };
  const valueNoise = (x, y, seed = 0) => {
    const xi = Math.floor(x);
    const yi = Math.floor(y);
    const tx = smoothstep(0, 1, x - xi);
    const ty = smoothstep(0, 1, y - yi);
    return lerp(
      lerp(hash(xi, yi, seed), hash(xi + 1, yi, seed), tx),
      lerp(hash(xi, yi + 1, seed), hash(xi + 1, yi + 1, seed), tx),
      ty,
    );
  };
  const fbm = (x, y, seed = 0) => {
    let value = 0;
    let amplitude = 0.58;
    let norm = 0;
    let frequency = 1;
    for (let octave = 0; octave < 3; octave += 1) {
      value += valueNoise(x * frequency, y * frequency, seed + octave * 17.3) * amplitude;
      norm += amplitude;
      frequency *= 1.93;
      amplitude *= 0.46;
    }
    return value / norm;
  };

  const moneyFlowPaletteHex = Object.freeze([
    '#49cfc5',
    '#8defe5',
    '#f8e8f3',
    '#f7b2f5',
    '#d8b4fe',
  ]);

  function moneyFlowVisualSplit(incomePercent) {
    const split = 0.08 + (clamp01(Number(incomePercent) / 100) * 0.84);
    return Math.round(split * 1e12) / 1e12;
  }

  function moneyFlowStopPositions(incomePercent) {
    const split = moneyFlowVisualSplit(incomePercent);
    const fadeWidth = 0.3;
    return Object.freeze([
      0,
      Math.max(0.001, split - fadeWidth),
      split,
      Math.min(0.999, split + fadeWidth),
      1,
    ]);
  }

  function normalizePalettePositions(palette, positions) {
    if (
      Array.isArray(positions) &&
      positions.length === palette.length &&
      positions.every((position) => Number.isFinite(Number(position)))
    ) {
      const bounded = positions.map((position) => clamp01(Number(position)));
      bounded[0] = 0;
      bounded[bounded.length - 1] = 1;
      return bounded;
    }
    return palette.map((_, index) => (
      palette.length <= 1 ? 0 : index / (palette.length - 1)
    ));
  }

  function samplePaletteColor(palette, sample, positions = null) {
    const safePalette = Array.isArray(palette) && palette.length
      ? palette
      : [{ r: 255, g: 255, b: 255 }];
    if (safePalette.length === 1) {
      return {
        r: Math.round(safePalette[0].r),
        g: Math.round(safePalette[0].g),
        b: Math.round(safePalette[0].b),
      };
    }
    const resolvedPositions = normalizePalettePositions(safePalette, positions);
    const coordinate = clamp01(Number(sample.coordinate ?? sample.mix ?? 0.5));
    let segment = resolvedPositions.length - 2;
    for (let index = 0; index < resolvedPositions.length - 1; index += 1) {
      if (coordinate <= resolvedPositions[index + 1]) {
        segment = index;
        break;
      }
    }
    const width = Math.max(1e-6, resolvedPositions[segment + 1] - resolvedPositions[segment]);
    const amount = clamp01((coordinate - resolvedPositions[segment]) / width);
    const base = {
      r: lerp(safePalette[segment].r, safePalette[segment + 1].r, amount),
      g: lerp(safePalette[segment].g, safePalette[segment + 1].g, amount),
      b: lerp(safePalette[segment].b, safePalette[segment + 1].b, amount),
    };
    const light = Math.max(-0.22, Math.min(0.22, Number(sample.light) || 0));
    const chroma = Math.max(-0.35, Math.min(0.35, Number(sample.chroma) || 0));
    const gray = (base.r + base.g + base.b) / 3;
    const channel = (value) => Math.max(0, Math.min(255, Math.round(
      lerp(gray, value, 1 + chroma) * (1 + light),
    )));
    return {
      r: channel(base.r),
      g: channel(base.g),
      b: channel(base.b),
    };
  }

  function sampleMoneyFlowColor(palette, incomePercent, sample) {
    return samplePaletteColor(palette, sample, moneyFlowStopPositions(incomePercent));
  }

  const isBalanceMode = (mode) => balanceModeIds.includes(mode);

  function controlsForMode(mode) {
    if (!modeControls[mode]) throw new RangeError(`Unknown portal mode: ${mode}`);
    return Object.freeze([
      ...(isBalanceMode(mode) ? balanceCommonControls : commonControls),
      ...modeControls[mode],
    ]);
  }

  function createModeSettings(mode) {
    if (mode === 'static') {
      return { strength: 0, speed: 0, renderScale: 0.60, frameMs: 42 };
    }
    return controlsForMode(mode).reduce((settings, meta) => {
      settings[meta.key] = meta.default;
      return settings;
    }, {});
  }

  function prepareField(x, y, phase, settings) {
    const scale = Math.max(0.01, settings.fieldScale);
    const sx = 0.5 + ((x - 0.5) * scale);
    const sy = 0.5 + ((y - 0.5) * scale);
    const ratio = settings.bias
      + (Math.sin(phase * settings.ratioSpeed * Math.PI * 2) * settings.ratioSwing);
    const morphTime = phase * settings.morphSpeed;
    const broadNoise = (fbm(
      (sx * 1.17) + (morphTime * 0.07),
      (sy * 1.09) - (morphTime * 0.05),
      31.7,
    ) - 0.5) * settings.morphAmount;
    const detailNoise = (fbm(
      (sx * 2.8) - (morphTime * 0.09),
      (sy * 2.5) + (morphTime * 0.08),
      67.3,
    ) - 0.5) * settings.detail;
    return { sx, sy, ratio, broadNoise, detailNoise };
  }

  function finishField(field, phase, settings, context, localLight = 0) {
    const softness = Math.max(0.001, settings.softness);
    const mix = smoothstep(0.5 - softness, 0.5 + softness, field);
    const seam = 4 * mix * (1 - mix);
    const pulse = Math.sin(phase * settings.pulseSpeed * Math.PI * 2)
      * settings.pulseAmount;
    const texture = (context.broadNoise + context.detailNoise) * settings.lightAmount;
    const light = Math.max(
      -0.25,
      Math.min(0.25, (pulse + texture + localLight) * seam),
    );
    return { mix, light };
  }

  function sampleDualTide(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const offset = settings.phaseOffset * Math.PI / 180;
    const aPhase = phase * 0.52;
    const bPhase = (phase * 0.47) + offset;
    const aX = 0.5 - (settings.separation * 0.5)
      + (Math.sin(aPhase * 0.83) * settings.wanderX)
      + ((0.5 + 0.5 * Math.sin(aPhase * 0.31)) * settings.intrusion);
    const bX = 0.5 + (settings.separation * 0.5)
      - (Math.sin(bPhase * 0.79) * settings.wanderX)
      - ((0.5 + 0.5 * Math.sin(bPhase * 0.29)) * settings.intrusion);
    const aY = 0.5 + (Math.sin(aPhase * 0.61) * settings.wanderY);
    const bY = 0.5 - (Math.sin(bPhase * 0.57) * settings.wanderY);
    const aMass = gaussian(
      c.sx - aX,
      c.sy - aY,
      settings.lobeARadius,
      settings.lobeARadius / settings.lobeAEllipse,
    );
    const bMass = gaussian(
      c.sx - bX,
      c.sy - bY,
      settings.lobeBRadius,
      settings.lobeBRadius / settings.lobeBEllipse,
    );
    const warp = (fbm(
      (c.sx * settings.warpScale) + (phase * settings.warpSpeed * 0.11),
      (c.sy * settings.warpScale) - (phase * settings.warpSpeed * 0.09),
      103.2,
    ) - 0.5) * settings.warpAmount;
    const field = c.sx + c.ratio + warp
      + ((bMass - aMass) * settings.counterFlow * 0.46)
      + (c.broadNoise * 0.20)
      + (c.detailNoise * 0.12);
    return finishField(
      field,
      phase,
      settings,
      c,
      (aMass + bMass - 0.7) * settings.lightAmount * 0.12,
    );
  }

  function sampleMagneticMembrane(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const spread = settings.nodePhaseSpread * Math.PI / 180;
    const nodes = [settings.nodeTop, settings.nodeMiddle, settings.nodeBottom]
      .map((base, index) => base
        + (Math.sin((phase * 0.23) + (spread * index)) * settings.nodeWander));
    const iy = clamp01(c.sy);
    const nodeCurve = ((1 - iy) * (1 - iy) * nodes[0])
      + (2 * (1 - iy) * iy * nodes[1])
      + (iy * iy * nodes[2]);
    const primary = Math.sin(
      ((c.sy / settings.primaryWavelength) * Math.PI * 2)
      + (phase * settings.primarySpeed * Math.PI * 2),
    ) * settings.primaryAmplitude;
    const secondary = Math.sin(
      ((c.sy / settings.secondaryWavelength) * Math.PI * 2)
      - (phase * settings.secondarySpeed * Math.PI * 2)
      + 1.7,
    ) * settings.secondaryAmplitude;
    const warp = (fbm(
      (c.sy * 1.4) + (phase * settings.warpSpeed * 0.08),
      (c.sx * 0.9) - (phase * settings.warpSpeed * 0.05),
      211.6,
    ) - 0.5) * settings.warpAmount;
    const boundary = 0.5 + c.ratio
      + (nodeCurve * (1 - (settings.tension * 0.68)))
      + primary
      + secondary
      + (settings.skew * (c.sy - 0.5))
      + warp
      + (c.broadNoise * 0.18)
      + (c.detailNoise * 0.10);
    const field = 0.5 + (c.sx - boundary);
    return finishField(
      field,
      phase,
      settings,
      c,
      Math.abs(primary + secondary) * settings.lightAmount * 0.16,
    );
  }

  function sampleBreathingLens(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const breathPhase = phase * settings.breathSpeed * Math.PI * 2;
    const centerX = settings.centerX + (Math.sin(phase * 0.31) * settings.wanderX);
    const centerY = settings.centerY + (Math.cos(phase * 0.27) * settings.wanderY);
    const radiusX = Math.max(
      0.03,
      settings.radiusX * (1 + (Math.sin(breathPhase) * settings.breathX)),
    );
    const radiusY = Math.max(
      0.03,
      settings.radiusY * (1 + (Math.cos(breathPhase * 0.83) * settings.breathY)),
    );
    const dx = (c.sx - centerX) / radiusX;
    const dy = (c.sy - centerY) / radiusY;
    const lensDistance = Math.sqrt((dx * dx) + (dy * dy));
    const lens = Math.exp(
      -(lensDistance * lensDistance) / Math.max(0.01, settings.edgeFalloff),
    );
    const satelliteAngle = settings.satellitePhase * Math.PI / 180;
    const satelliteX = centerX
      + (Math.cos(satelliteAngle + (phase * 0.13)) * settings.satelliteDistance);
    const satelliteY = centerY
      + (Math.sin(satelliteAngle + (phase * 0.11)) * settings.satelliteDistance);
    const satellite = gaussian(
      c.sx - satelliteX,
      c.sy - satelliteY,
      settings.satelliteRadius,
      settings.satelliteRadius,
    );
    const pressure = (
      (lens * settings.pressure) + (satellite * settings.satelliteAmount)
    ) * settings.refraction;
    const field = c.sx + c.ratio + pressure
      + (c.broadNoise * 0.19)
      + (c.detailNoise * 0.10);
    return finishField(
      field,
      phase,
      settings,
      c,
      (lens + satellite) * settings.lightAmount * 0.12,
    );
  }

  const cellSeeds = Object.freeze([
    [0.13, 0.18, 0.1],
    [0.34, 0.76, 1.7],
    [0.52, 0.32, 3.1],
    [0.72, 0.80, 4.8],
    [0.88, 0.24, 6.4],
    [0.22, 0.51, 8.2],
    [0.66, 0.52, 10.3],
  ]);
  const wrap01 = (value) => ((value % 1) + 1) % 1;

  function sampleCellularField(x, y, phase, settings) {
    const c = prepareField(x, y, phase, settings);
    const count = Math.max(3, Math.min(7, Math.round(settings.cellCount)));
    let pressureSum = 0;
    let lightSum = 0;
    for (let index = 0; index < count; index += 1) {
      const [baseX, baseY, seed] = cellSeeds[index];
      const curl = (fbm(
        (baseX * settings.curlScale) + (phase * 0.04),
        (baseY * settings.curlScale) - (phase * 0.03),
        seed + 301,
      ) - 0.5) * settings.curlAmount;
      const cellX = wrap01(
        baseX
        + (phase * settings.advectionX * 0.025)
        + (Math.sin((phase * 0.19) + seed) * settings.cellWander)
        + curl,
      );
      const cellY = wrap01(
        baseY
        + (phase * settings.advectionY * 0.025)
        + (Math.cos((phase * 0.17) + seed) * settings.cellWander)
        - curl,
      );
      const sizeWave = Math.sin((phase * 0.21) + seed) * settings.cellMorph;
      const variation = 1
        + (((index / Math.max(1, count - 1)) - 0.5) * settings.cellVariation);
      const radius = Math.max(
        0.04,
        settings.cellSize * variation * (1 + (sizeWave * 0.35)),
      );
      const cell = gaussian(
        c.sx - cellX,
        c.sy - cellY,
        radius,
        radius * (0.84 + ((index % 3) * 0.11)),
      );
      const polarity = index % 2 === 0 ? -1 : 1;
      pressureSum += cell * (polarity + settings.polarityBalance);
      lightSum += cell;
    }
    const noise = (fbm(
      (c.sx * settings.noiseScale) + (phase * settings.noiseSpeed * 0.07),
      (c.sy * settings.noiseScale) - (phase * settings.noiseSpeed * 0.06),
      409.4,
    ) - 0.5) * settings.noiseAmount;
    const field = c.sx + c.ratio + settings.mergeThreshold
      + ((pressureSum / count) * settings.pressure)
      + noise
      + (c.broadNoise * 0.18)
      + (c.detailNoise * 0.10);
    return finishField(
      field,
      phase,
      settings,
      c,
      (lightSum / count) * settings.lightAmount * 0.16,
    );
  }

  function mapMoneyFlowCoordinate(x, baseSplit, boundary) {
    if (x <= boundary) {
      return baseSplit * (x / Math.max(1e-6, boundary));
    }
    return baseSplit + ((1 - baseSplit)
      * ((x - boundary) / Math.max(1e-6, 1 - boundary)));
  }

  function zeroMeanSine(y, waveNumber, phase) {
    const safeWaveNumber = Math.max(1e-6, Math.abs(waveNumber));
    const signedWaveNumber = waveNumber < 0 ? -safeWaveNumber : safeWaveNumber;
    const mean = (
      Math.cos(phase) - Math.cos(signedWaveNumber + phase)
    ) / signedWaveNumber;
    return Math.sin((signedWaveNumber * y) + phase) - mean;
  }

  function antisymmetricFbm(y, offsetX, offsetY, scale, seed) {
    return fbm((y * scale) + offsetX, offsetY, seed)
      - fbm(((1 - y) * scale) + offsetX, offsetY, seed);
  }

  function limitMoneyFlowDeformation(raw, maximum, baseSplit) {
    const safeAmplitude = Math.max(
      0.001,
      Math.min(baseSplit - 0.04, 0.96 - baseSplit),
    );
    const normalization = maximum > safeAmplitude
      ? safeAmplitude / Math.max(1e-6, maximum)
      : 1;
    return raw * normalization;
  }

  function finishMoneyFlowField(
    x,
    baseSplit,
    animatedBoundary,
    rawLight,
    rawChroma,
    phase,
    settings,
  ) {
    const strength = clamp01(settings.strength);
    if (strength === 0) {
      return {
        coordinate: x,
        boundary: baseSplit,
        light: 0,
        chroma: 0,
        side: x <= baseSplit ? 'income' : 'expense',
      };
    }
    const boundary = Math.max(
      0.04,
      Math.min(0.96, lerp(baseSplit, animatedBoundary, strength)),
    );
    const seamDistance = Math.abs(x - boundary);
    const seamEnergy = Math.exp(
      -seamDistance / Math.max(0.01, settings.seamSoftness),
    );
    const pulse = Math.sin(phase * settings.pulseSpeed * Math.PI * 2)
      * settings.pulseAmount * seamEnergy;
    return {
      coordinate: clamp01(mapMoneyFlowCoordinate(x, baseSplit, boundary)),
      boundary,
      light: Math.max(
        -0.22,
        Math.min(0.22, ((rawLight * settings.lightAmount) + pulse) * strength),
      ),
      chroma: Math.max(
        -0.35,
        Math.min(0.35, rawChroma * settings.chromaAmount * strength),
      ),
      side: x <= boundary ? 'income' : 'expense',
    };
  }

  function sampleBalanceMembrane(x, y, phase, baseSplit, settings) {
    const phaseOffset = settings.nodePhase * Math.PI / 180;
    const drift = phase * settings.driftSpeed * Math.PI * 2;
    const primary = zeroMeanSine(
      y,
      Math.PI * 2 / settings.primaryWavelength,
      drift,
    );
    const secondary = zeroMeanSine(
      y,
      Math.PI * 2 / settings.secondaryWavelength,
      -(drift * 0.71) + phaseOffset,
    );
    const warp = antisymmetricFbm(
      y,
      phase * settings.warpSpeed * 0.08,
      (phase * settings.warpSpeed * 0.06) + 0.37,
      settings.warpScale,
      701.3,
    ) * settings.warpAmount;
    const damping = 1 - (settings.tension * 0.72);
    const rawDeformation = (
      (primary * settings.boundaryAmplitude)
      + (secondary * settings.secondaryAmplitude)
      + warp
    ) * damping;
    const maximum = 2 * (
      settings.boundaryAmplitude
      + settings.secondaryAmplitude
      + settings.warpAmount
    ) * damping;
    const deformation = limitMoneyFlowDeformation(
      rawDeformation,
      maximum,
      baseSplit,
    );
    return finishMoneyFlowField(
      x,
      baseSplit,
      baseSplit + deformation,
      Math.abs((primary * 0.68) + (secondary * 0.32)),
      warp,
      phase,
      settings,
    );
  }

  function sampleBalanceCounterflow(x, y, phase, baseSplit, settings) {
    const drift = phase * settings.verticalDrift * Math.PI * 2;
    const waveNumber = settings.lobeCount * Math.PI * 2;
    const counter = settings.counterPhase * Math.PI / 180;
    const aWave = zeroMeanSine(y, waveNumber, drift);
    const bWave = zeroMeanSine(y, waveNumber, drift + counter);
    const paired = aWave
      - (bWave * settings.compensation * settings.lobeEllipse);
    const shaped = Math.sign(paired)
      * Math.pow(Math.abs(paired), settings.lobeSharpness);
    const shapedMaximum = Math.pow(
      1 + (settings.compensation * settings.lobeEllipse),
      settings.lobeSharpness,
    );
    const normalizedShape = shaped / Math.max(1e-6, shapedMaximum);
    const radiusGain = settings.lobeRadius / 0.22;
    const warp = antisymmetricFbm(
      y,
      -(phase * settings.warpSpeed * 0.07),
      (phase * settings.warpSpeed * 0.05) + 0.73,
      settings.warpScale,
      811.9,
    ) * settings.warpAmount;
    const rawDeformation = (
      normalizedShape * settings.intrusion * radiusGain * 0.5
    ) + warp;
    const maximum = (settings.intrusion * radiusGain * 0.5)
      + settings.warpAmount;
    const deformation = limitMoneyFlowDeformation(
      rawDeformation,
      maximum,
      baseSplit,
    );
    return finishMoneyFlowField(
      x,
      baseSplit,
      baseSplit + deformation,
      (Math.abs(paired) / Math.max(1, shapedMaximum)) * 0.72,
      normalizedShape * 0.55,
      phase,
      settings,
    );
  }

  const balanceChargeSeeds = Object.freeze([
    [0.16, 0.18, 0.7],
    [0.34, 0.72, 1.9],
    [0.56, 0.36, 3.2],
    [0.78, 0.81, 4.6],
    [0.88, 0.22, 6.1],
    [0.44, 0.54, 7.8],
    [0.24, 0.88, 9.4],
    [0.68, 0.10, 11.2],
  ]);

  function sampleBalanceCharges(x, y, phase, baseSplit, settings) {
    const rawSeam = zeroMeanSine(
      y,
      Math.PI * 2 / settings.seamWavelength,
      phase * settings.seamSpeed * Math.PI * 2,
    ) * settings.seamDrift;
    const seam = limitMoneyFlowDeformation(
      rawSeam,
      settings.seamDrift * 2,
      baseSplit,
    );
    const boundary = baseSplit + seam;
    const side = x <= boundary ? 0 : 1;
    const sidePhase = settings.sidePhase * Math.PI / 180;
    const count = Math.max(2, Math.min(8, Math.round(settings.chargeCount)));
    let light = 0;
    let chroma = 0;
    for (let index = 0; index < count; index += 1) {
      if (index % 2 !== side) continue;
      const [seedX, seedY, seed] = balanceChargeSeeds[index];
      const sideStart = side === 0 ? 0 : baseSplit;
      const sideWidth = side === 0 ? baseSplit : 1 - baseSplit;
      const centerX = sideStart + (sideWidth * (0.12 + (seedX * 0.76)))
        + (Math.sin((phase * 0.13) + seed) * settings.chargeWander * sideWidth);
      const centerY = seedY
        + (Math.cos((phase * 0.11) + seed) * settings.chargeWander);
      const variation = 1 + (
        ((index / Math.max(1, count - 1)) - 0.5) * settings.chargeVariation
      );
      const morph = 1 + (
        Math.sin((phase * 0.17) + (seed * settings.noiseScale))
        * settings.chargeMorph
        * 0.35
      );
      const radius = Math.max(0.03, settings.chargeSize * variation * morph);
      const charge = gaussian(
        x - centerX,
        y - centerY,
        radius,
        radius * 0.82,
      );
      const polarity = Math.sin((phase * 0.16) + seed + (side * sidePhase));
      light += charge * polarity * settings.chargeLight;
      chroma += charge * polarity * settings.chargeChroma;
    }
    return finishMoneyFlowField(
      x,
      baseSplit,
      boundary,
      light,
      chroma,
      phase,
      settings,
    );
  }

  const moneyFlowSamplers = Object.freeze({
    'balance-membrane': sampleBalanceMembrane,
    'balance-counterflow': sampleBalanceCounterflow,
    'balance-charges': sampleBalanceCharges,
  });

  function sampleMoneyFlowField(
    mode,
    x,
    y,
    phase,
    incomePercent,
    settings = createModeSettings(mode),
  ) {
    const sampler = moneyFlowSamplers[mode];
    if (!sampler) throw new RangeError(`Unknown balance portal mode: ${mode}`);
    const nx = clamp01(Number(x));
    const ny = clamp01(Number(y));
    return sampler(
      nx,
      ny,
      Number(phase) || 0,
      moneyFlowVisualSplit(incomePercent),
      settings,
    );
  }

  const samplers = Object.freeze({
    'dual-tide': sampleDualTide,
    'magnetic-membrane': sampleMagneticMembrane,
    'breathing-lens': sampleBreathingLens,
    'cellular-field': sampleCellularField,
  });

  function sampleField(mode, x, y, phase, settings = createModeSettings(mode)) {
    const nx = clamp01(Number(x));
    const ny = clamp01(Number(y));
    if (mode === 'static') return { mix: nx, light: 0 };
    const sampler = samplers[mode];
    if (!sampler) throw new RangeError(`Unknown portal mode: ${mode}`);
    const animated = sampler(nx, ny, phase, settings);
    const strength = clamp01(settings.strength);
    return {
      mix: clamp01(lerp(nx, animated.mix, strength)),
      light: Math.max(-0.25, Math.min(0.25, animated.light * strength)),
    };
  }

  function sampleColor(a, b, sample) {
    const mix = clamp01(sample.mix);
    const seam = 4 * mix * (1 - mix);
    const light = Math.max(-0.25, Math.min(0.25, sample.light)) * seam;
    const channel = (left, right) => Math.max(
      0,
      Math.min(255, Math.round(lerp(left, right, mix) * (1 + light))),
    );
    return {
      r: channel(a.r, b.r),
      g: channel(a.g, b.g),
      b: channel(a.b, b.b),
    };
  }

  function advancePhase(phase, elapsedSeconds, speed) {
    return phase + (Math.max(0, elapsedSeconds) * Math.max(0, speed));
  }

  return Object.freeze({
    modeOrder: Object.freeze(modeOrder.slice()),
    modeLabels,
    commonControls,
    balanceCommonControls,
    modeControls,
    balanceModeIds,
    controlsForMode,
    isBalanceMode,
    createModeSettings,
    sampleField,
    sampleColor,
    samplePaletteColor,
    moneyFlowPaletteHex,
    moneyFlowVisualSplit,
    moneyFlowStopPositions,
    sampleMoneyFlowColor,
    sampleMoneyFlowField,
    advancePhase,
    clamp01,
  });
});
