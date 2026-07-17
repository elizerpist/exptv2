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

    const emptyPolygons = () => ({ left: [], right: [] });
    const emptyRenderResult = () => ({
      rendered: false,
      leftPixelCount: 0,
      rightPixelCount: 0,
    });
    const clamp = (value, minimum, maximum) => Math.max(minimum, Math.min(maximum, value));
    const canCall = (ctx, methods) => (
      ctx && typeof ctx === 'object' && methods.every((method) => typeof ctx[method] === 'function')
    );

    function buildInteriorRegionPolygons(options = {}) {
      const width = Number(options.width);
      const height = Number(options.height);
      const { boundary } = options;
      if (!Number.isFinite(width) || width <= 0 || !Number.isFinite(height) || height <= 0) {
        return emptyPolygons();
      }
      if (!boundary
        || typeof boundary.leftXAt !== 'function'
        || typeof boundary.rightXAt !== 'function') {
        return emptyPolygons();
      }

      const featherPx = Number(boundary.featherPx);
      if (!Number.isFinite(featherPx) || featherPx < 0) return emptyPolygons();

      const requestedSamples = options.samples === undefined ? 32 : Number(options.samples);
      if (!Number.isFinite(requestedSamples) || requestedSamples < 1) return emptyPolygons();
      const samples = Math.max(1, Math.min(512, Math.round(requestedSamples)));
      const left = [];
      const right = [];

      try {
        for (let index = 0; index <= samples; index += 1) {
          const y = height * (index / samples);
          const leftBoundaryX = Number(boundary.leftXAt(y));
          const rightBoundaryX = Number(boundary.rightXAt(y));
          if (!Number.isFinite(leftBoundaryX) || !Number.isFinite(rightBoundaryX)) {
            return emptyPolygons();
          }
          left.push({ x: clamp(leftBoundaryX - featherPx, 0, width), y });
          right.push({ x: clamp(rightBoundaryX + featherPx, 0, width), y });
        }
      } catch (error) {
        return emptyPolygons();
      }

      left.push({ x: 0, y: height }, { x: 0, y: 0 });
      right.push({ x: width, y: height }, { x: width, y: 0 });
      return { left, right };
    }

    function polygonArea(points) {
      if (!Array.isArray(points) || points.length < 3) return 0;
      let doubledArea = 0;
      for (let index = 0; index < points.length; index += 1) {
        const point = points[index];
        const next = points[(index + 1) % points.length];
        doubledArea += (point.x * next.y) - (next.x * point.y);
      }
      return Math.abs(doubledArea) / 2;
    }

    function hasProtectedGeometry(polygons) {
      if (!polygons
        || !Array.isArray(polygons.left)
        || !Array.isArray(polygons.right)
        || polygons.left.length !== polygons.right.length
        || polygonArea(polygons.left) <= 0
        || polygonArea(polygons.right) <= 0) return false;
      const sampledPointCount = polygons.left.length - 2;
      for (let index = 0; index < sampledPointCount; index += 1) {
        if (polygons.left[index].x >= polygons.right[index].x) return false;
      }
      return true;
    }

    function protectedDrawingBounds(polygons, width, height) {
      const sampledPointCount = polygons.left.length - 2;
      const leftEdge = Math.min(
        ...polygons.left.slice(0, sampledPointCount).map((point) => point.x),
      );
      const rightEdge = Math.max(
        ...polygons.right.slice(0, sampledPointCount).map((point) => point.x),
      );
      if (!Number.isFinite(leftEdge)
        || !Number.isFinite(rightEdge)
        || leftEdge <= 0
        || rightEdge >= width) return null;
      return {
        left: { x: 0, y: 0, width: leftEdge, height },
        right: { x: rightEdge, y: 0, width: width - rightEdge, height },
      };
    }

    function tracePolygon(ctx, polygon) {
      ctx.beginPath();
      ctx.moveTo(polygon[0].x, polygon[0].y);
      for (let index = 1; index < polygon.length; index += 1) {
        ctx.lineTo(polygon[index].x, polygon[index].y);
      }
      ctx.closePath();
    }

    function parseHex(value) {
      if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
      return {
        r: parseInt(value.slice(1, 3), 16),
        g: parseInt(value.slice(3, 5), 16),
        b: parseInt(value.slice(5, 7), 16),
      };
    }

    const interpolate = (left, right, amount) => left + ((right - left) * amount);
    const colorAt = (palette, amount) => {
      const light = parseHex(palette.light);
      const dark = parseHex(palette.dark);
      if (!light || !dark) return null;
      const safeAmount = clamp(Number(amount) || 0, 0, 1);
      return {
        r: Math.round(interpolate(light.r, dark.r, safeAmount)),
        g: Math.round(interpolate(light.g, dark.g, safeAmount)),
        b: Math.round(interpolate(light.b, dark.b, safeAmount)),
      };
    };

    function drawSideField(ctx, polygon, bounds, sideOptions, palette) {
      let pixelCount = 0;
      const xStart = Math.max(0, Math.floor(bounds.x));
      const yStart = Math.max(0, Math.floor(bounds.y));
      const xEnd = Math.max(xStart, Math.ceil(bounds.x + bounds.width));
      const yEnd = Math.max(yStart, Math.ceil(bounds.y + bounds.height));
      ctx.save();
      try {
        tracePolygon(ctx, polygon);
        ctx.clip();
        for (let y = yStart; y < yEnd; y += 1) {
          const normalizedY = bounds.height <= 1
            ? 0.5
            : clamp((y - bounds.y) / (bounds.height - 1), 0, 1);
          for (let x = xStart; x < xEnd; x += 1) {
            const rawX = bounds.width <= 1
              ? 0.5
              : clamp((x - bounds.x) / (bounds.width - 1), 0, 1);
            const normalizedX = sideOptions.flipX ? 1 - rawX : rawX;
            const matter = field.sampleMatter(
              sideOptions.mode,
              normalizedX,
              normalizedY,
              sideOptions.phase,
              sideOptions.settings,
            );
            const color = colorAt(palette, matter);
            if (!color) continue;
            ctx.fillStyle = `rgb(${color.r}, ${color.g}, ${color.b})`;
            ctx.fillRect(x, y, 1, 1);
            pixelCount += 1;
          }
        }
      } finally {
        ctx.restore();
      }
      return pixelCount;
    }

    function renderPortalInteriorMotion(ctx, options = {}) {
      const off = emptyRenderResult;
      if (!motion
        || !field
        || typeof motion.normalizeInteriorMotionState !== 'function'
        || typeof motion.deriveInteriorPalettes !== 'function'
        || typeof motion.createSideRenderOptions !== 'function'
        || typeof field.sampleMatter !== 'function'
        || !canCall(ctx, [
          'save', 'restore', 'beginPath', 'closePath', 'moveTo', 'lineTo', 'clip', 'fillRect',
        ])
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

      const polygons = buildInteriorRegionPolygons({
        width,
        height,
        boundary: options.boundary,
        samples: options.samples,
      });
      if (!hasProtectedGeometry(polygons)) return off();
      const drawingBounds = protectedDrawingBounds(polygons, width, height);
      if (!drawingBounds) return off();

      try {
        const mode = state.mode;
        const settings = state.settingsByMode?.[mode] || motion.createModeSettings(mode);
        const phase = Number.isFinite(Number(options.phase))
          ? Number(options.phase)
          : Number(state.phaseByMode?.[mode]) || 0;
        const palettes = motion.deriveInteriorPalettes(options);
        const leftOptions = motion.createSideRenderOptions({
          mode,
          side: 'left',
          phase,
          settings,
        });
        const rightOptions = motion.createSideRenderOptions({
          mode,
          side: 'right',
          phase,
          settings,
        });
        const leftPixelCount = drawSideField(
          ctx,
          polygons.left,
          drawingBounds.left,
          leftOptions,
          palettes.left,
        );
        const rightPixelCount = drawSideField(
          ctx,
          polygons.right,
          drawingBounds.right,
          rightOptions,
          palettes.right,
        );
        return {
          rendered: leftPixelCount > 0 || rightPixelCount > 0,
          leftPixelCount,
          rightPixelCount,
        };
      } catch (error) {
        return off();
      }
    }

    return Object.freeze({
      buildInteriorRegionPolygons,
      renderPortalInteriorMotion,
    });
  },
);
