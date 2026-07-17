(function attachPortalMessageBackground(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageBackground = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageBackground() {
  'use strict';

  const modeOrder = Object.freeze([
    'none',
    'energy-compression',
    'refraction-wave',
    'seam-flare',
    'depth-focus',
    'chromatic-alert',
  ]);

  const modeLabels = Object.freeze({
    none: 'Nincs háttéreffekt',
    'energy-compression': 'Energiakompresszió',
    'refraction-wave': 'Refrakciós hullám',
    'seam-flare': 'Határfény',
    'depth-focus': 'Mélységi fókusz',
    'chromatic-alert': 'Kromatikus riasztás',
  });

  const freezeControls = (controls) => Object.freeze(
    controls.map((control) => Object.freeze({ ...control })),
  );

  const modeControls = Object.freeze({
    none: freezeControls([]),
    'energy-compression': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2400, step: 10, default: 900, unit: 'ms' },
      { key: 'strength', label: 'Erősség', min: 0, max: 100, step: 1, default: 62, unit: '%' },
      { key: 'peak', label: 'Csúcspont', min: 20, max: 80, step: 1, default: 48, unit: '%' },
      { key: 'centerX', label: 'Középpont X', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'centerY', label: 'Középpont Y', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'compression', label: 'Kompresszió', min: 0, max: 40, step: 1, default: 18, unit: '%' },
      { key: 'bloom', label: 'Bloom', min: 0, max: 100, step: 1, default: 44, unit: '%' },
      { key: 'fieldScale', label: 'Mezőskála', min: 70, max: 130, step: 1, default: 92, unit: '%' },
      { key: 'hold', label: 'Üzenetállapot tartás', min: 0, max: 100, step: 1, default: 18, unit: '%' },
      { key: 'decay', label: 'Lecsengés', min: 0, max: 100, step: 1, default: 66, unit: '%' },
    ]),
    'refraction-wave': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 400, max: 2600, step: 10, default: 1120, unit: 'ms' },
      { key: 'strength', label: 'Erősség', min: 0, max: 100, step: 1, default: 58, unit: '%' },
      { key: 'peak', label: 'Csúcspont', min: 20, max: 80, step: 1, default: 52, unit: '%' },
      { key: 'sourceX', label: 'Forrás X', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'sourceY', label: 'Forrás Y', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'radius', label: 'Hullámsugár', min: 20, max: 180, step: 1, default: 122, unit: '%' },
      { key: 'ringWidth', label: 'Gyűrűszélesség', min: 2, max: 30, step: 1, default: 12, unit: '%' },
      { key: 'rings', label: 'Gyűrűk', min: 1, max: 5, step: 1, default: 2, unit: '' },
      { key: 'refraction', label: 'Töréserő', min: 0, max: 40, step: 1, default: 16, unit: '%' },
      { key: 'blur', label: 'Blur', min: 0, max: 24, step: 1, default: 8, unit: 'px' },
      { key: 'hold', label: 'Üzenetállapot tartás', min: 0, max: 100, step: 1, default: 10, unit: '%' },
      { key: 'decay', label: 'Lecsengés', min: 0, max: 100, step: 1, default: 70, unit: '%' },
    ]),
    'seam-flare': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2200, step: 10, default: 820, unit: 'ms' },
      { key: 'strength', label: 'Erősség', min: 0, max: 100, step: 1, default: 58, unit: '%' },
      { key: 'peak', label: 'Csúcspont', min: 20, max: 80, step: 1, default: 46, unit: '%' },
      { key: 'width', label: 'Fénysáv szélesség', min: 2, max: 45, step: 1, default: 14, unit: '%' },
      { key: 'wander', label: 'Határvándorlás', min: 0, max: 30, step: 1, default: 8, unit: '%' },
      { key: 'branching', label: 'Elágazás', min: 0, max: 100, step: 1, default: 32, unit: '%' },
      { key: 'bloom', label: 'Bloom', min: 0, max: 100, step: 1, default: 48, unit: '%' },
      { key: 'phase', label: 'Vertikális fázis', min: 0, max: 360, step: 1, default: 110, unit: '°' },
      { key: 'hold', label: 'Üzenetállapot tartás', min: 0, max: 100, step: 1, default: 24, unit: '%' },
      { key: 'decay', label: 'Lecsengés', min: 0, max: 100, step: 1, default: 68, unit: '%' },
    ]),
    'depth-focus': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2200, step: 10, default: 880, unit: 'ms' },
      { key: 'strength', label: 'Erősség', min: 0, max: 100, step: 1, default: 48, unit: '%' },
      { key: 'peak', label: 'Csúcspont', min: 20, max: 80, step: 1, default: 50, unit: '%' },
      { key: 'focusX', label: 'Fókusz X', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'focusY', label: 'Fókusz Y', min: 0, max: 100, step: 1, default: 48, unit: '%' },
      { key: 'radius', label: 'Fókuszsugár', min: 20, max: 100, step: 1, default: 62, unit: '%' },
      { key: 'vignette', label: 'Peremsötétítés', min: 0, max: 100, step: 1, default: 36, unit: '%' },
      { key: 'depthScale', label: 'Mélységskála', min: 90, max: 110, step: 1, default: 97, unit: '%' },
      { key: 'centerLight', label: 'Középfény', min: 0, max: 100, step: 1, default: 30, unit: '%' },
      { key: 'blur', label: 'Blur', min: 0, max: 20, step: 1, default: 5, unit: 'px' },
      { key: 'hold', label: 'Üzenetállapot tartás', min: 0, max: 100, step: 1, default: 34, unit: '%' },
      { key: 'decay', label: 'Lecsengés', min: 0, max: 100, step: 1, default: 72, unit: '%' },
    ]),
    'chromatic-alert': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2200, step: 10, default: 760, unit: 'ms' },
      { key: 'strength', label: 'Erősség', min: 0, max: 100, step: 1, default: 56, unit: '%' },
      { key: 'peak', label: 'Csúcspont', min: 20, max: 80, step: 1, default: 42, unit: '%' },
      { key: 'overlayOpacity', label: 'Overlay opacity', min: 0, max: 45, step: 1, default: 24, unit: '%' },
      { key: 'pinkRatio', label: 'Rózsaszín arány', min: 0, max: 100, step: 1, default: 58, unit: '%' },
      { key: 'lilacRatio', label: 'Lila arány', min: 0, max: 100, step: 1, default: 42, unit: '%' },
      { key: 'spread', label: 'Terjedés', min: 20, max: 160, step: 1, default: 96, unit: '%' },
      { key: 'pulses', label: 'Pulzusszám', min: 1, max: 4, step: 1, default: 2, unit: '' },
      { key: 'blur', label: 'Blur', min: 0, max: 24, step: 1, default: 9, unit: 'px' },
      { key: 'hold', label: 'Üzenetállapot tartás', min: 0, max: 100, step: 1, default: 12, unit: '%' },
      { key: 'decay', label: 'Lecsengés', min: 0, max: 100, step: 1, default: 64, unit: '%' },
    ]),
  });

  const round = (value, digits = 6) => {
    const factor = 10 ** digits;
    return Math.round(value * factor) / factor;
  };

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

  function controlsForMode(mode) {
    return modeControls[mode] || modeControls.none;
  }

  function normalizeValue(meta, value) {
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
    const snapped = Number(meta.min) + (Math.round((bounded - Number(meta.min)) / step) * step);
    const stepText = String(meta.step);
    const decimals = stepText.includes('.') ? Math.min(5, stepText.split('.')[1].length) : 0;
    return decimals ? Number(snapped.toFixed(decimals)) : Math.round(snapped);
  }

  function createModeSettings(mode) {
    return Object.fromEntries(
      controlsForMode(mode).map((meta) => [meta.key, meta.default]),
    );
  }

  function normalizedSettings(mode, settings) {
    return Object.fromEntries(
      controlsForMode(mode).map((meta) => [
        meta.key,
        normalizeValue(meta, settings?.[meta.key]),
      ]),
    );
  }

  function noEffect(targetState) {
    return {
      mode: 'none',
      targetState: targetState === 'balance' ? 'balance' : 'message',
      duration: 0,
      easing: 'linear',
      keyframes: [],
      balanceRest: {},
      messageRest: {},
      configuration: {},
    };
  }

  function temporalValues(settings) {
    const strength = settings.strength / 100;
    const hold = settings.hold / 100;
    const peakOffset = settings.peak / 100;
    return {
      strength,
      hold,
      peakOffset,
      easing: `cubic-bezier(.18, ${round(0.58 + (settings.decay * 0.0042), 3)}, .22, 1)`,
    };
  }

  function frame(opacity, transform, filter, clipPath) {
    return { opacity: round(opacity, 4), transform, filter, clipPath };
  }

  function compressionDescriptor(settings) {
    const { strength, hold } = temporalValues(settings);
    const peakScale = round((settings.fieldScale / 100) * (1 - (settings.compression / 500)), 4);
    const brightness = round(1 + (strength * settings.bloom / 125), 4);
    const peak = frame(
      round(strength * 0.9, 4),
      `scale(${peakScale})`,
      `blur(${round(settings.compression / 24, 2)}px) brightness(${brightness})`,
      `circle(${round(62 - (settings.compression * 0.55), 2)}% at ${settings.centerX}% ${settings.centerY}%)`,
    );
    return {
      balance: frame(0, 'scale(1)', 'blur(0px) brightness(1)', `circle(150% at ${settings.centerX}% ${settings.centerY}%)`),
      peak,
      message: frame(
        peak.opacity * hold,
        `scale(${round(1 - ((1 - peakScale) * hold), 4)})`,
        `blur(${round((settings.compression / 24) * hold, 2)}px) brightness(${round(1 + ((brightness - 1) * hold), 4)})`,
        `circle(${round(150 - ((88 + (settings.compression * 0.55)) * hold), 2)}% at ${settings.centerX}% ${settings.centerY}%)`,
      ),
      configuration: {
        '--portal-response-center-x': `${settings.centerX}%`,
        '--portal-response-center-y': `${settings.centerY}%`,
        '--portal-response-compression': `${settings.compression}%`,
        '--portal-response-bloom': `${settings.bloom}%`,
        '--portal-response-bloom-stop': `${round(10 + (settings.bloom * 0.12), 2)}%`,
        '--portal-response-compression-stop': `${round(32 + (settings.compression * 0.18), 2)}%`,
        '--portal-response-field-scale': `${settings.fieldScale}%`,
      },
    };
  }

  function refractionDescriptor(settings) {
    const { strength, hold } = temporalValues(settings);
    const radiusScale = round(settings.radius / 100, 4);
    const brightness = round(1 + (settings.refraction * strength / 72), 4);
    const peak = frame(
      strength * 0.72,
      `scale(${radiusScale})`,
      `blur(${settings.blur}px) brightness(${brightness})`,
      `circle(${settings.radius}% at ${settings.sourceX}% ${settings.sourceY}%)`,
    );
    return {
      balance: frame(0, 'scale(.12)', `blur(${settings.blur}px) brightness(1)`, `circle(0% at ${settings.sourceX}% ${settings.sourceY}%)`),
      peak,
      message: frame(
        peak.opacity * hold,
        `scale(${round(radiusScale * (0.82 + (hold * 0.18)), 4)})`,
        `blur(${round(settings.blur * (0.35 + (hold * 0.65)), 2)}px) brightness(${round(1 + ((brightness - 1) * hold), 4)})`,
        `circle(${round(settings.radius * (0.88 + (hold * 0.12)), 2)}% at ${settings.sourceX}% ${settings.sourceY}%)`,
      ),
      configuration: {
        '--portal-response-source-x': `${settings.sourceX}%`,
        '--portal-response-source-y': `${settings.sourceY}%`,
        '--portal-response-radius': `${settings.radius}%`,
        '--portal-response-ring-width': `${settings.ringWidth}%`,
        '--portal-response-ring-highlight': `${round(settings.ringWidth * 0.16, 2)}%`,
        '--portal-response-ring-color': `${round(settings.ringWidth * 0.34, 2)}%`,
        '--portal-response-ring-fade': `${round(settings.ringWidth * 0.72, 2)}%`,
        '--portal-response-rings': String(settings.rings),
        '--portal-response-field-size': `${round(88 + (settings.rings * 8), 2)}%`,
        '--portal-response-refraction': `${settings.refraction}%`,
        '--portal-response-blur': `${settings.blur}px`,
      },
    };
  }

  function seamDescriptor(settings) {
    const { strength, hold } = temporalValues(settings);
    const seam = 50;
    const brightness = round(1 + (settings.bloom * strength / 120), 4);
    const peak = frame(
      strength * 0.82,
      `translate3d(${round(settings.wander * 0.22, 2)}%, 0, 0) scaleX(${round(1 + (settings.branching / 250), 4)})`,
      `blur(${round(1 + (settings.bloom / 18), 2)}px) brightness(${brightness})`,
      `polygon(${round(seam - settings.width, 2)}% 0%, ${round(seam + settings.width, 2)}% 0%, ${round(seam + (settings.width * 0.62), 2)}% 100%, ${round(seam - (settings.width * 0.62), 2)}% 100%)`,
    );
    return {
      balance: frame(0, 'translate3d(0, 0, 0) scaleX(1)', 'blur(0px) brightness(1)', `polygon(${seam}% 0%, ${seam}% 0%, ${seam}% 100%, ${seam}% 100%)`),
      peak,
      message: frame(
        peak.opacity * hold,
        `translate3d(${round(settings.wander * 0.22 * hold, 2)}%, 0, 0) scaleX(${round(1 + ((settings.branching / 250) * hold), 4)})`,
        `blur(${round((1 + (settings.bloom / 18)) * hold, 2)}px) brightness(${round(1 + ((brightness - 1) * hold), 4)})`,
        `polygon(${round(seam - (settings.width * hold), 2)}% 0%, ${round(seam + (settings.width * hold), 2)}% 0%, ${round(seam + (settings.width * 0.62 * hold), 2)}% 100%, ${round(seam - (settings.width * 0.62 * hold), 2)}% 100%)`,
      ),
      configuration: {
        '--portal-response-seam': `${seam}%`,
        '--portal-response-seam-width': `${settings.width}%`,
        '--portal-response-seam-inner-width': `${round(settings.width * 0.64, 2)}%`,
        '--portal-response-wander': `${settings.wander}%`,
        '--portal-response-branching': `${settings.branching}%`,
        '--portal-response-bloom': `${settings.bloom}%`,
        '--portal-response-phase': `${settings.phase}deg`,
      },
    };
  }

  function depthDescriptor(settings) {
    const { strength, hold } = temporalValues(settings);
    const peakScale = round(settings.depthScale / 100, 4);
    const brightness = round(1 + (settings.centerLight * strength / 135), 4);
    const peak = frame(
      strength * 0.74,
      `scale(${peakScale})`,
      `blur(${settings.blur}px) brightness(${brightness})`,
      `circle(${settings.radius}% at ${settings.focusX}% ${settings.focusY}%)`,
    );
    return {
      balance: frame(0, 'scale(1)', 'blur(0px) brightness(1)', `circle(150% at ${settings.focusX}% ${settings.focusY}%)`),
      peak,
      message: frame(
        peak.opacity * hold,
        `scale(${round(1 - ((1 - peakScale) * hold), 4)})`,
        `blur(${round(settings.blur * hold, 2)}px) brightness(${round(1 + ((brightness - 1) * hold), 4)})`,
        `circle(${round(150 - ((150 - settings.radius) * hold), 2)}% at ${settings.focusX}% ${settings.focusY}%)`,
      ),
      configuration: {
        '--portal-response-focus-x': `${settings.focusX}%`,
        '--portal-response-focus-y': `${settings.focusY}%`,
        '--portal-response-focus-radius': `${settings.radius}%`,
        '--portal-response-vignette': `${settings.vignette}%`,
        '--portal-response-vignette-alpha': String(round(settings.vignette * 0.0064, 4)),
        '--portal-response-depth-scale': `${settings.depthScale}%`,
        '--portal-response-center-light': `${settings.centerLight}%`,
        '--portal-response-center-alpha': String(round(0.24 + (settings.centerLight * 0.004), 3)),
        '--portal-response-blur': `${settings.blur}px`,
      },
    };
  }

  function chromaticDescriptor(settings) {
    const { strength, hold } = temporalValues(settings);
    const boundedOpacity = Math.min(0.45, settings.overlayOpacity / 100);
    const peakOpacity = round(boundedOpacity * strength, 4);
    const peakScale = round(settings.spread / 100, 4);
    const peak = frame(
      peakOpacity,
      `scale(${peakScale})`,
      `blur(${settings.blur}px) saturate(${round(1 + (strength * 0.34), 4)})`,
      `circle(${settings.spread}% at 50% 50%)`,
    );
    return {
      balance: frame(0, 'scale(.24)', 'blur(0px) saturate(1)', 'circle(0% at 50% 50%)'),
      peak,
      message: frame(
        peak.opacity * hold,
        `scale(${round(peakScale * (0.88 + (hold * 0.12)), 4)})`,
        `blur(${round(settings.blur * hold, 2)}px) saturate(${round(1 + (strength * 0.34 * hold), 4)})`,
        `circle(${round(settings.spread * (0.9 + (hold * 0.1)), 2)}% at 50% 50%)`,
      ),
      configuration: {
        '--portal-response-overlay-opacity': String(boundedOpacity),
        '--portal-response-pink-ratio': `${settings.pinkRatio}%`,
        '--portal-response-lilac-ratio': `${settings.lilacRatio}%`,
        '--portal-response-spread': `${settings.spread}%`,
        '--portal-response-pulses': String(settings.pulses),
        '--portal-response-field-size': `${round(88 + (settings.pulses * 8), 2)}%`,
        '--portal-response-blur': `${settings.blur}px`,
      },
    };
  }

  function descriptorFor(mode, settings) {
    if (mode === 'energy-compression') return compressionDescriptor(settings);
    if (mode === 'refraction-wave') return refractionDescriptor(settings);
    if (mode === 'seam-flare') return seamDescriptor(settings);
    if (mode === 'depth-focus') return depthDescriptor(settings);
    return chromaticDescriptor(settings);
  }

  function withOffset(style, offset) {
    return { ...style, offset: round(offset, 6) };
  }

  function buildResponse(mode, settings, targetState = 'message', context = {}, reducedMotion = false) {
    if (!modeOrder.includes(mode) || mode === 'none') return noEffect(targetState);
    const normalized = normalizedSettings(mode, settings);
    const temporal = temporalValues(normalized);
    const descriptor = descriptorFor(mode, normalized);
    const toMessage = targetState !== 'balance';
    const balanceRest = withOffset(descriptor.balance, toMessage ? 0 : 1);
    const messageRest = withOffset(descriptor.message, toMessage ? 1 : 0);

    if (reducedMotion) {
      return {
        mode,
        targetState: toMessage ? 'message' : 'balance',
        duration: 160,
        easing: 'linear',
        keyframes: toMessage
          ? [{ opacity: 0, offset: 0 }, { opacity: descriptor.message.opacity, offset: 1 }]
          : [{ opacity: descriptor.message.opacity, offset: 0 }, { opacity: 0, offset: 1 }],
        balanceRest: { opacity: 0, offset: toMessage ? 0 : 1 },
        messageRest: { opacity: descriptor.message.opacity, offset: toMessage ? 1 : 0 },
        configuration: descriptor.configuration,
      };
    }

    const peakOffset = toMessage ? temporal.peakOffset : 1 - temporal.peakOffset;
    const peak = withOffset(descriptor.peak, peakOffset);
    return {
      mode,
      targetState: toMessage ? 'message' : 'balance',
      duration: normalized.duration,
      easing: temporal.easing,
      keyframes: toMessage
        ? [balanceRest, peak, messageRest]
        : [messageRest, peak, balanceRest],
      balanceRest,
      messageRest,
      configuration: descriptor.configuration,
    };
  }

  return Object.freeze({
    modeOrder,
    modeLabels,
    modeControls,
    controlsForMode,
    createModeSettings,
    normalizeValue,
    buildResponse,
  });
});
