(function attachPortalMessageTransitionRenderer(root, factory) {
  const transition = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_transition.js')
    : root?.PortalMessageTransition;
  const api = factory(transition);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageTransitionRenderer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalMessageTransitionRenderer(transition) {
    'use strict';

    const validFrame = (frame) => {
      if (!frame || typeof frame !== 'object') return false;
      if (!Number.isInteger(frame.width) || frame.width < 1 || frame.width > 2048) return false;
      if (!Number.isInteger(frame.height) || frame.height < 1 || frame.height > 2048) return false;
      return frame.data instanceof Uint8ClampedArray
        && frame.data.length === frame.width * frame.height * 4;
    };
    const sameSize = (left, right) => (
      left.width === right.width && left.height === right.height
    );
    const mix = (left, right, amount) => left + ((right - left) * amount);

    function renderFrame(options) {
      if (!options || typeof options !== 'object' || !transition) return null;
      if (!transition.modeOrder.includes(options.mode)) return null;
      const source = options.sourceFrame;
      const portalBase = options.portalBaseFrame;
      const portalTarget = options.portalTargetFrame;
      if (!validFrame(source) || !validFrame(portalBase) || !validFrame(portalTarget)) return null;
      if (!sameSize(source, portalBase) || !sameSize(source, portalTarget)) return null;

      const settings = options.settings && typeof options.settings === 'object'
        ? options.settings
        : transition.createModeSettings(options.mode);
      const progress = Number(options.progress) || 0;
      const reducedMotion = options.reducedMotion === true;
      const crossfade = Math.max(0, Math.min(1, progress));
      const { width, height } = source;
      if (options.outputFrame !== undefined
        && (!validFrame(options.outputFrame) || !sameSize(source, options.outputFrame))) {
        return null;
      }
      const output = options.outputFrame || {
        width,
        height,
        data: new Uint8ClampedArray(source.data.length),
      };
      const { data } = output;

      for (let y = 0; y < height; y += 1) {
        const normalizedY = height === 1 ? 0.5 : y / (height - 1);
        for (let x = 0; x < width; x += 1) {
          const normalizedX = width === 1 ? 0.5 : x / (width - 1);
          const offset = ((y * width) + x) * 4;
          if (reducedMotion) {
            for (let channel = 0; channel < 3; channel += 1) {
              data[offset + channel] = mix(
                source.data[offset + channel],
                portalTarget.data[offset + channel],
                crossfade,
              );
            }
            data[offset + 3] = 255;
            continue;
          }
          const channels = transition.sampleChannels(
            options.mode,
            normalizedX,
            normalizedY,
            progress,
            settings,
          );
          for (let channel = 0; channel < 3; channel += 1) {
            const stage = mix(
              source.data[offset + channel],
              portalBase.data[offset + channel],
              channels.base,
            );
            data[offset + channel] = mix(
              stage,
              portalTarget.data[offset + channel],
              channels.matter,
            );
          }
          data[offset + 3] = 255;
        }
      }

      return output;
    }

    return Object.freeze({ renderFrame });
  },
);
