(function attachPortalMessageColorRenderer(root, factory) {
  const energy = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_energy.js')
    : root?.MindPortalEnergy;
  const color = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_color.js')
    : root?.PortalMessageColor;
  const api = factory(energy, color);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalMessageColorRenderer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalMessageColorRenderer(energy, color) {
    'use strict';

    const normalizeDimension = (value) => {
      const numeric = Number(value);
      return Math.max(1, Math.min(2048, Math.round(Number.isFinite(numeric) ? numeric : 1)));
    };
    const parseHex = (value) => {
      if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
      return {
        r: parseInt(value.slice(1, 3), 16),
        g: parseInt(value.slice(3, 5), 16),
        b: parseInt(value.slice(5, 7), 16),
      };
    };

    function renderFrame(options) {
      if (!options || typeof options !== 'object') return null;
      const mode = color.normalizeMode(options.mode);
      if (mode === 'none' || !color.modeOrder.includes(options.mode)) return null;

      const rgbA = parseHex(options.colorA);
      const rgbB = parseHex(options.colorB);
      if (!rgbA || !rgbB) return null;

      const safeWidth = normalizeDimension(options.width);
      const safeHeight = normalizeDimension(options.height);
      const settings = options.settings && typeof options.settings === 'object'
        ? options.settings
        : color.createModeSettings(mode);
      const data = new Uint8ClampedArray(safeWidth * safeHeight * 4);

      for (let y = 0; y < safeHeight; y += 1) {
        const ny = safeHeight === 1 ? 0.5 : y / (safeHeight - 1);
        for (let x = 0; x < safeWidth; x += 1) {
          const nx = safeWidth === 1 ? 0.5 : x / (safeWidth - 1);
          const sample = energy.sampleField(
            mode,
            nx,
            ny,
            Number(options.phase) || 0,
            settings,
          );
          const pixel = energy.sampleColor(rgbA, rgbB, sample);
          const offset = ((y * safeWidth) + x) * 4;
          data[offset] = pixel.r;
          data[offset + 1] = pixel.g;
          data[offset + 2] = pixel.b;
          data[offset + 3] = 255;
        }
      }

      return { width: safeWidth, height: safeHeight, data };
    }

    return Object.freeze({ renderFrame });
  },
);
