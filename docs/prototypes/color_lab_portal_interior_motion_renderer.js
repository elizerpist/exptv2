(function attachPortalInteriorMotionRenderer(root, factory) {
  const motion = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_interior_motion.js')
    : root?.PortalInteriorMotion;
  const field = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_message_field.js')
    : root?.PortalMessageField;
  const api = factory(motion, field);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalInteriorMotionRenderer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalInteriorMotionRenderer(motion, field) {
    'use strict';

    const emptyRenderResult = () => ({
      rendered: false,
      overlayPixelCount: 0,
    });
    const clamp = (value, minimum, maximum) => Math.max(minimum, Math.min(maximum, value));
    const clamp01 = (value) => clamp(Number.isFinite(value) ? value : 0, 0, 1);
    const round12 = (value) => Math.round(value * 1e12) / 1e12;
    const canCall = (ctx, methods) => (
      ctx && typeof ctx === 'object' && methods.every((method) => typeof ctx[method] === 'function')
    );

    function parseHex(value) {
      if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
      return {
        r: parseInt(value.slice(1, 3), 16),
        g: parseInt(value.slice(3, 5), 16),
        b: parseInt(value.slice(5, 7), 16),
      };
    }

    const interpolate = (left, right, amount) => left + ((right - left) * amount);
    const smoothstep = (edge0, edge1, value) => {
      if (edge0 === edge1) return value < edge0 ? 0 : 1;
      const amount = clamp01((value - edge0) / (edge1 - edge0));
      return amount * amount * (3 - (2 * amount));
    };
    const mixColor = (left, right, amount) => ({
      r: Math.round(interpolate(left.r, right.r, amount)),
      g: Math.round(interpolate(left.g, right.g, amount)),
      b: Math.round(interpolate(left.b, right.b, amount)),
    });
    const formatAlpha = (value) => {
      const rounded = Math.round(clamp(value, 0, 1) * 1000) / 1000;
      return rounded.toFixed(3).replace(/0+$/, '').replace(/\.$/, '');
    };
    const rotationAngle = (phase, rotationEnabled, rotationSpeed) => {
      if (rotationEnabled !== true) return 0;
      const speed = clamp(Number(rotationSpeed) || 0, 0, 100);
      if (speed <= 0) return 0;
      return (Number(phase) || 0) * (speed / 100) * Math.PI * 2;
    };

    function projectInteriorOverlaySamplePoint(options = {}) {
      const width = Math.max(1, Number(options.width) || 1);
      const height = Math.max(1, Number(options.height) || 1);
      const spanPx = Math.max(width, height);
      const angle = rotationAngle(
        options.phase,
        options.rotationEnabled,
        options.rotationSpeed,
      );
      const px = (clamp01(Number(options.x)) - 0.5) * width;
      const py = (clamp01(Number(options.y)) - 0.5) * height;
      const cos = Math.cos(angle);
      const sin = Math.sin(angle);
      const rotatedX = (px * cos) - (py * sin);
      const rotatedY = (px * sin) + (py * cos);
      return {
        x: round12(clamp01(0.5 + (rotatedX / spanPx))),
        y: round12(clamp01(0.5 + (rotatedY / spanPx))),
        angle: round12(angle),
        spanPx: round12(spanPx),
        overscanX: round12(Math.max(0, (spanPx - width) / 2)),
        overscanY: round12(Math.max(0, (spanPx - height) / 2)),
      };
    }

    function renderPortalInteriorMotion(ctx, options = {}) {
      const off = emptyRenderResult;
      if (!motion
        || !field
        || typeof motion.normalizeInteriorMotionState !== 'function'
        || typeof motion.deriveInteriorPalettes !== 'function'
        || typeof motion.createModeSettings !== 'function'
        || typeof field.sampleMatter !== 'function'
        || !canCall(ctx, ['save', 'restore', 'fillRect'])
        || !options
        || typeof options !== 'object'
        || options.mode !== 'balance') return off();

      const width = Number(options.width);
      const height = Number(options.height);
      if (!Number.isFinite(width) || width <= 0 || !Number.isFinite(height) || height <= 0) {
        return off();
      }

      let state;
      try {
        state = motion.normalizeInteriorMotionState(options.state);
      } catch (error) {
        return off();
      }
      if (!state || !state.enabled) return off();

      let palettes;
      try {
        palettes = motion.deriveInteriorPalettes(options);
      } catch (error) {
        return off();
      }
      const leftTint = parseHex(palettes?.left?.dark);
      const rightTint = parseHex(palettes?.right?.dark);
      if (!leftTint || !rightTint) return off();

      const mode = state.mode;
      const settings = state.settingsByMode?.[mode] || motion.createModeSettings(mode);
      const phase = Number.isFinite(Number(options.phase))
        ? Number(options.phase)
        : Number(state.phaseByMode?.[mode]) || 0;
      const split = clamp(
        Number.isFinite(Number(options.split)) ? Number(options.split) : 0.5,
        0.04,
        0.96,
      );
      const transitionWidth = clamp(
        Number.isFinite(Number(options.transitionWidth)) ? Number(options.transitionWidth) : 0.36,
        0.02,
        1,
      );
      const configuredOverlayAlpha = Number(options.overlayAlpha);
      const maxOverlayAlpha = Number.isFinite(configuredOverlayAlpha)
        ? clamp(configuredOverlayAlpha, 0, 0.5)
        : 0.38;
      if (maxOverlayAlpha <= 0) return off();

      const xEnd = Math.ceil(width);
      const yEnd = Math.ceil(height);
      let overlayPixelCount = 0;
      ctx.save();
      try {
        for (let y = 0; y < yEnd; y += 1) {
          const normalizedY = height <= 1 ? 0.5 : clamp01(y / (height - 1));
          for (let x = 0; x < xEnd; x += 1) {
            const normalizedX = width <= 1 ? 0.5 : clamp01(x / (width - 1));
            const samplePoint = projectInteriorOverlaySamplePoint({
              x: normalizedX,
              y: normalizedY,
              width,
              height,
              phase,
              rotationEnabled: state.rotationEnabled === true,
              rotationSpeed: state.rotationSpeed,
            });
            const matter = field.sampleMatter(
              mode,
              samplePoint.x,
              samplePoint.y,
              phase,
              settings,
            );
            const alpha = clamp01(matter) * maxOverlayAlpha;
            if (alpha <= 0.002) continue;
            const rightAmount = smoothstep(
              split - (transitionWidth / 2),
              split + (transitionWidth / 2),
              normalizedX,
            );
            const tint = mixColor(leftTint, rightTint, rightAmount);
            ctx.fillStyle = `rgba(${tint.r}, ${tint.g}, ${tint.b}, ${formatAlpha(alpha)})`;
            ctx.fillRect(x, y, 1, 1);
            overlayPixelCount += 1;
          }
        }
      } finally {
        ctx.restore();
      }

      return {
        rendered: overlayPixelCount > 0,
        overlayPixelCount,
      };
    }

    return Object.freeze({
      projectInteriorOverlaySamplePoint,
      renderPortalInteriorMotion,
    });
  },
);
