(function attachPortalMessageMorph(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageMorph = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function buildPortalMessageMorph() {
  'use strict';

  const modeOrder = Object.freeze([
    'diffuse-focus',
    'portal-aperture',
    'energy-sweep',
    'spectral-echo',
  ]);

  const modeLabels = Object.freeze({
    'diffuse-focus': 'Diffúz fókusz',
    'portal-aperture': 'Portal rekesz',
    'energy-sweep': 'Energia-söprés',
    'spectral-echo': 'Spektrális visszhang',
  });

  const freezeControls = (controls) => Object.freeze(
    controls.map((control) => Object.freeze({ ...control })),
  );

  const modeControls = Object.freeze({
    'diffuse-focus': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2400, step: 10, default: 900, unit: 'ms' },
      { key: 'overlap', label: 'Átfedés', min: 0, max: 100, step: 1, default: 38, unit: '%' },
      { key: 'blur', label: 'Blur', min: 0, max: 32, step: 1, default: 16, unit: 'px' },
      { key: 'shrink', label: 'Összehúzás', min: 90, max: 100, step: 1, default: 96, unit: '%' },
      { key: 'driftY', label: 'Vertikális sodródás', min: -24, max: 24, step: 1, default: 6, unit: 'px' },
      { key: 'afterglow', label: 'Utófény', min: 0, max: 100, step: 1, default: 28, unit: '%' },
      { key: 'softness', label: 'Lágyság', min: 1, max: 5, step: 0.1, default: 2.4, unit: '' },
    ]),
    'portal-aperture': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2400, step: 10, default: 980, unit: 'ms' },
      { key: 'overlap', label: 'Átfedés', min: 0, max: 100, step: 1, default: 28, unit: '%' },
      { key: 'focusX', label: 'Fókusz X', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'focusY', label: 'Fókusz Y', min: 0, max: 100, step: 1, default: 50, unit: '%' },
      { key: 'apertureMin', label: 'Rekesz minimum', min: 0, max: 40, step: 1, default: 7, unit: '%' },
      { key: 'edgeSoftness', label: 'Éllágyság', min: 0, max: 40, step: 1, default: 18, unit: '%' },
      { key: 'blur', label: 'Blur', min: 0, max: 28, step: 1, default: 12, unit: 'px' },
      { key: 'bloom', label: 'Bloom', min: 0, max: 100, step: 1, default: 42, unit: '%' },
    ]),
    'energy-sweep': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2400, step: 10, default: 840, unit: 'ms' },
      { key: 'overlap', label: 'Átfedés', min: 0, max: 100, step: 1, default: 52, unit: '%' },
      { key: 'angle', label: 'Szög', min: -60, max: 60, step: 1, default: 8, unit: '°' },
      { key: 'waveWidth', label: 'Hullámszélesség', min: 6, max: 60, step: 1, default: 24, unit: '%' },
      { key: 'edgeSoftness', label: 'Éllágyság', min: 0, max: 40, step: 1, default: 16, unit: '%' },
      { key: 'travel', label: 'Elmozdulás', min: 0, max: 36, step: 1, default: 10, unit: 'px' },
      { key: 'blur', label: 'Blur', min: 0, max: 24, step: 1, default: 9, unit: 'px' },
      { key: 'brightness', label: 'Fényerő', min: 0, max: 100, step: 1, default: 48, unit: '%' },
    ]),
    'spectral-echo': freezeControls([
      { key: 'duration', label: 'Időtartam', min: 300, max: 2400, step: 10, default: 1120, unit: 'ms' },
      { key: 'overlap', label: 'Átfedés', min: 0, max: 100, step: 1, default: 44, unit: '%' },
      { key: 'echoCount', label: 'Visszhangok', min: 2, max: 5, step: 1, default: 3, unit: '' },
      { key: 'distance', label: 'Távolság', min: 0, max: 30, step: 1, default: 12, unit: 'px' },
      { key: 'spreadAngle', label: 'Terülési szög', min: -45, max: 45, step: 1, default: 14, unit: '°' },
      { key: 'blur', label: 'Blur', min: 0, max: 28, step: 1, default: 13, unit: 'px' },
      { key: 'ghostOpacity', label: 'Szellem opacity', min: 0, max: 100, step: 1, default: 34, unit: '%' },
      { key: 'convergence', label: 'Konvergencia', min: 80, max: 120, step: 1, default: 94, unit: '%' },
    ]),
  });

  const round = (value, digits = 6) => {
    const factor = 10 ** digits;
    return Math.round(value * factor) / factor;
  };

  function controlsForMode(mode) {
    return modeControls[mode] || Object.freeze([]);
  }

  function normalizeValue(meta, value) {
    const numeric = Number(value);
    const fallback = Number(meta.default);
    const bounded = Math.max(
      Number(meta.min),
      Math.min(Number(meta.max), Number.isFinite(numeric) ? numeric : fallback),
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

  function transitionOffsets(overlap) {
    const normalizedOverlap = Math.max(0, Math.min(100, Number(overlap) || 0)) / 100;
    const segment = 1 / (2 - normalizedOverlap);
    return Object.freeze({
      outgoingEnd: round(segment, 9),
      incomingStart: round(1 - segment, 9),
    });
  }

  function oppositeState(state) {
    return state === 'message' ? 'balance' : 'message';
  }

  function frameWithOffset(frame, offset) {
    return { ...frame, offset };
  }

  function assembleFrames(visible, outgoingHidden, incomingHidden, offsets) {
    return {
      outgoing: [
        frameWithOffset(visible, 0),
        frameWithOffset(outgoingHidden, offsets.outgoingEnd),
        frameWithOffset(outgoingHidden, 1),
      ],
      incoming: [
        frameWithOffset(incomingHidden, 0),
        frameWithOffset(incomingHidden, offsets.incomingStart),
        frameWithOffset(visible, 1),
      ],
    };
  }

  function visibleFrame(extra = {}) {
    return {
      opacity: 1,
      filter: 'blur(0px) brightness(1)',
      transform: 'translate3d(0px, 0px, 0px) scale(1)',
      clipPath: 'circle(150% at 50% 50%)',
      textShadow: 'none',
      ...extra,
    };
  }

  function makeEchoShadow(settings, direction) {
    const angle = (settings.spreadAngle * Math.PI) / 180;
    const opacity = settings.ghostOpacity / 100;
    const shadows = [];
    for (let index = 1; index <= settings.echoCount; index += 1) {
      const progress = index / settings.echoCount;
      const distance = settings.distance * progress;
      const x = round(Math.cos(angle) * distance * direction, 2);
      const y = round(Math.sin(angle) * distance, 2);
      const alpha = round(opacity * (1 - (progress * 0.46)), 3);
      const blur = round(2 + (settings.blur * progress * 0.56), 2);
      const color = `color-mix(in srgb, currentColor ${round(alpha * 100, 1)}%, transparent)`;
      shadows.push(`${x}px ${y}px ${blur}px ${color}`);
    }
    return shadows.join(', ');
  }

  function diffuseDescriptor(settings, direction, offsets) {
    const bloomAlpha = round(settings.afterglow / 220, 3);
    const bloomRadius = round(4 + (settings.afterglow * 0.14), 2);
    const hidden = {
      opacity: 0,
      filter: `blur(${settings.blur}px) brightness(${round(1 + (settings.afterglow / 360), 3)})`,
      transform: `translate3d(0px, ${settings.driftY * direction}px, 0px) scale(${round(settings.shrink / 100, 3)})`,
      clipPath: 'circle(150% at 50% 50%)',
      textShadow: `0 0 ${bloomRadius}px color-mix(in srgb, currentColor ${round(bloomAlpha * 100, 1)}%, transparent)`,
    };
    const controlA = round(0.08 + (settings.softness * 0.018), 3);
    const controlB = round(0.12 + (settings.softness * 0.03), 3);
    return {
      ...assembleFrames(visibleFrame(), hidden, hidden, offsets),
      easing: `cubic-bezier(${controlA}, 1, ${controlB}, 1)`,
    };
  }

  function apertureDescriptor(settings, direction, offsets) {
    const blur = round(settings.blur + (settings.edgeSoftness * 0.16), 2);
    const bloomAlpha = round(settings.bloom / 180, 3);
    const origin = `${settings.focusX}% ${settings.focusY}%`;
    const hidden = {
      opacity: 0,
      filter: `blur(${blur}px) brightness(${round(1 + (settings.bloom / 260), 3)})`,
      transform: `translate3d(${direction * 2}px, 0px, 0px) scale(${round(0.94 + (settings.apertureMin / 700), 3)})`,
      transformOrigin: origin,
      clipPath: `circle(${settings.apertureMin}% at ${origin})`,
      textShadow: `0 0 ${round(5 + settings.edgeSoftness * 0.45, 2)}px color-mix(in srgb, currentColor ${round(bloomAlpha * 100, 1)}%, transparent)`,
    };
    return {
      ...assembleFrames(
        visibleFrame({ clipPath: `circle(150% at ${origin})`, transformOrigin: origin }),
        hidden,
        hidden,
        offsets,
      ),
      easing: 'cubic-bezier(.2, .82, .2, 1)',
    };
  }

  function energySweepDescriptor(settings, direction, offsets) {
    const angleRadians = (settings.angle * Math.PI) / 180;
    const skew = Math.max(-92, Math.min(92, Math.tan(angleRadians) * 52));
    const leftTop = round(-44 - skew, 2);
    const leftBottom = round(-44 + skew, 2);
    const rightTop = round(144 - skew, 2);
    const rightBottom = round(144 + skew, 2);
    const leftLine = `polygon(${leftTop}% -40%, ${leftTop}% -40%, ${leftBottom}% 140%, ${leftBottom}% 140%)`;
    const rightLine = `polygon(${rightTop}% -40%, ${rightTop}% -40%, ${rightBottom}% 140%, ${rightBottom}% 140%)`;
    const brightness = round(1 + (settings.brightness / 150), 3);
    const glowAlpha = round(settings.brightness / 145, 3);
    const glowRadius = round(settings.waveWidth * 0.42, 2);
    const blur = round(settings.blur + (settings.edgeSoftness * 0.11), 2);
    const baseHidden = {
      opacity: 0,
      filter: `blur(${blur}px) brightness(${brightness})`,
      textShadow: `0 0 ${glowRadius}px color-mix(in srgb, currentColor ${round(glowAlpha * 100, 1)}%, transparent)`,
    };
    const outgoingHidden = {
      ...baseHidden,
      transform: `translate3d(${settings.travel * direction}px, 0px, 0px) scale(1)`,
      clipPath: rightLine,
    };
    const incomingHidden = {
      ...baseHidden,
      transform: `translate3d(${-settings.travel * direction}px, 0px, 0px) scale(1)`,
      clipPath: leftLine,
    };
    return {
      ...assembleFrames(
        visibleFrame({ clipPath: 'polygon(-80% -80%, 180% -80%, 180% 180%, -80% 180%)' }),
        outgoingHidden,
        incomingHidden,
        offsets,
      ),
      easing: 'cubic-bezier(.3, .72, .22, 1)',
    };
  }

  function spectralEchoDescriptor(settings, direction, offsets) {
    const shadow = makeEchoShadow(settings, direction);
    const hidden = {
      opacity: 0,
      filter: `blur(${settings.blur}px) brightness(${round(1 + (settings.ghostOpacity / 300), 3)})`,
      transform: `translate3d(${round(settings.distance * 0.28 * direction, 2)}px, ${round(settings.distance * 0.08, 2)}px, 0px) scale(${round(settings.convergence / 100, 3)})`,
      clipPath: 'circle(150% at 50% 50%)',
      textShadow: shadow || '0 0 0 rgba(255,255,255,0)',
    };
    return {
      ...assembleFrames(visibleFrame(), hidden, hidden, offsets),
      easing: 'cubic-bezier(.12, .88, .18, 1)',
    };
  }

  function reducedMotionDescriptor(settings, direction, offsets) {
    return {
      mode: 'reduced-motion',
      targetState: direction === 1 ? 'message' : 'balance',
      direction,
      duration: 160,
      easing: 'linear',
      outgoing: [
        { opacity: 1, offset: 0 },
        { opacity: 0, offset: offsets.outgoingEnd },
        { opacity: 0, offset: 1 },
      ],
      incoming: [
        { opacity: 0, offset: 0 },
        { opacity: 0, offset: offsets.incomingStart },
        { opacity: 1, offset: 1 },
      ],
    };
  }

  function buildTransition(mode, settings, targetState = 'message', reducedMotion = false) {
    const activeMode = modeOrder.includes(mode) ? mode : modeOrder[0];
    const normalized = normalizedSettings(activeMode, settings);
    const direction = targetState === 'balance' ? -1 : 1;
    const offsets = transitionOffsets(normalized.overlap);
    if (reducedMotion) return reducedMotionDescriptor(normalized, direction, offsets);

    let descriptor;
    if (activeMode === 'portal-aperture') {
      descriptor = apertureDescriptor(normalized, direction, offsets);
    } else if (activeMode === 'energy-sweep') {
      descriptor = energySweepDescriptor(normalized, direction, offsets);
    } else if (activeMode === 'spectral-echo') {
      descriptor = spectralEchoDescriptor(normalized, direction, offsets);
    } else {
      descriptor = diffuseDescriptor(normalized, direction, offsets);
    }

    return Object.freeze({
      mode: activeMode,
      targetState: direction === 1 ? 'message' : 'balance',
      direction,
      duration: normalized.duration,
      easing: descriptor.easing,
      outgoing: Object.freeze(descriptor.outgoing.map((frame) => Object.freeze(frame))),
      incoming: Object.freeze(descriptor.incoming.map((frame) => Object.freeze(frame))),
    });
  }

  return Object.freeze({
    modeOrder,
    modeLabels,
    modeControls,
    controlsForMode,
    createModeSettings,
    normalizeValue,
    transitionOffsets,
    oppositeState,
    buildTransition,
  });
});
