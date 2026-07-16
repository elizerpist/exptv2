(function attachPortalMessageFieldRenderer(root, factory) {
  const field = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_message_field.js')
    : root?.PortalMessageField;
  const api = factory(field);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageFieldRenderer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalMessageFieldRenderer(field) {
    'use strict';

    const normalizeDimension = (value) => {
      const numeric = Number(value);
      const finite = Number.isFinite(numeric) ? numeric : 1;
      return Math.max(1, Math.min(2048, Math.round(finite)));
    };
    const parseHex = (value) => {
      if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
      return {
        r: parseInt(value.slice(1, 3), 16),
        g: parseInt(value.slice(3, 5), 16),
        b: parseInt(value.slice(5, 7), 16),
      };
    };
    const interpolate = (left, right, amount) => left + ((right - left) * amount);

    function renderFrame(options) {
      if (!options || typeof options !== 'object' || !field) return null;
      if (!field.modeOrder.includes(options.mode)) return null;

      const colorA = parseHex(options.colorA);
      const colorB = parseHex(options.colorB);
      if (!colorA || !colorB) return null;

      const width = normalizeDimension(options.width);
      const height = normalizeDimension(options.height);
      const phase = Number(options.phase) || 0;
      const settings = options.settings && typeof options.settings === 'object'
        ? options.settings
        : field.createModeSettings(options.mode);
      const data = new Uint8ClampedArray(width * height * 4);

      for (let y = 0; y < height; y += 1) {
        const normalizedY = height === 1 ? 0.5 : y / (height - 1);
        for (let x = 0; x < width; x += 1) {
          const normalizedX = width === 1 ? 0.5 : x / (width - 1);
          const matter = field.sampleMatter(
            options.mode,
            normalizedX,
            normalizedY,
            phase,
            settings,
          );
          const offset = ((y * width) + x) * 4;
          data[offset] = interpolate(colorA.r, colorB.r, matter);
          data[offset + 1] = interpolate(colorA.g, colorB.g, matter);
          data[offset + 2] = interpolate(colorA.b, colorB.b, matter);
          data[offset + 3] = 255;
        }
      }

      return { width, height, data };
    }

    return Object.freeze({ renderFrame });
  },
);
