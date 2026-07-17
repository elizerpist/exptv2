(function attachPortalInteriorMotionRenderer(root, factory) {
  const motion = typeof module === 'object' && module.exports
    ? require('./color_lab_portal_interior_motion.js')
    : root?.PortalInteriorMotion;
  const api = factory(motion);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalInteriorMotionRenderer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalInteriorMotionRenderer(motion) {
    'use strict';

    const TAU = Math.PI * 2;
    const emptyPolygons = () => ({ left: [], right: [] });
    const emptyRenderResult = () => ({
      rendered: false,
      leftPrimitiveCount: 0,
      rightPrimitiveCount: 0,
    });
    const finite = (value) => Number.isFinite(Number(value));
    const clamp = (value, minimum, maximum) => Math.max(minimum, Math.min(maximum, value));

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

    function parseHex(value) {
      if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return null;
      return {
        r: parseInt(value.slice(1, 3), 16),
        g: parseInt(value.slice(3, 5), 16),
        b: parseInt(value.slice(5, 7), 16),
      };
    }

    function withAlpha(color, alpha) {
      const rgb = parseHex(color);
      if (!rgb) return null;
      const safeAlpha = clamp(Number(alpha), 0, 1);
      return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${safeAlpha})`;
    }

    function addSoftMotherReturn(gradient, primitive) {
      gradient.addColorStop(0, withAlpha(primitive.innerColor, primitive.alpha));
      gradient.addColorStop(0.58, withAlpha(primitive.innerColor, primitive.alpha * 0.48));
      gradient.addColorStop(1, withAlpha(primitive.edgeColor, 0));
    }

    function normalizeBounds(bounds) {
      if (!bounds || !finite(bounds.width) || !finite(bounds.height)) return null;
      const width = Number(bounds.width);
      const height = Number(bounds.height);
      const x = bounds.x === undefined ? 0 : Number(bounds.x);
      const y = bounds.y === undefined ? 0 : Number(bounds.y);
      if (width <= 0 || height <= 0 || !Number.isFinite(x) || !Number.isFinite(y)) return null;
      return { x, y, width, height };
    }

    const finiteGeometry = (geometry, keys) => (
      geometry
      && typeof geometry === 'object'
      && keys.every((key) => Number.isFinite(Number(geometry[key])))
    );
    const canCall = (ctx, methods) => (
      ctx && typeof ctx === 'object' && methods.every((method) => typeof ctx[method] === 'function')
    );
    const pointX = (bounds, normalized) => bounds.x + (Number(normalized) * bounds.width);
    const pointY = (bounds, normalized) => bounds.y + (Number(normalized) * bounds.height);

    function drawRadialEllipse(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'centerX', 'centerY', 'radiusX', 'radiusY', 'rotation',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'ellipse', 'fill',
      ])) return false;

      const centerX = pointX(bounds, geometry.centerX);
      const centerY = pointY(bounds, geometry.centerY);
      const radiusX = Math.abs(Number(geometry.radiusX) * bounds.width);
      const radiusY = Math.abs(Number(geometry.radiusY) * bounds.height);
      if (radiusX === 0 || radiusY === 0) return false;
      const gradient = ctx.createRadialGradient(
        centerX,
        centerY,
        0,
        centerX,
        centerY,
        Math.max(radiusX, radiusY),
      );
      addSoftMotherReturn(gradient, primitive);
      ctx.beginPath();
      ctx.ellipse(
        centerX,
        centerY,
        radiusX,
        radiusY,
        Number(geometry.rotation) * TAU,
        0,
        TAU,
      );
      ctx.fillStyle = gradient;
      ctx.fill();
      return true;
    }

    function drawLinearRibbon(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'startX', 'startY', 'controlX', 'controlY', 'endX', 'endY', 'thickness',
      ]) || !canCall(ctx, [
        'createLinearGradient', 'beginPath', 'moveTo', 'bezierCurveTo', 'stroke',
      ])) return false;

      const startX = pointX(bounds, geometry.startX);
      const startY = pointY(bounds, geometry.startY);
      const controlX = pointX(bounds, geometry.controlX);
      const controlY = pointY(bounds, geometry.controlY);
      const endX = pointX(bounds, geometry.endX);
      const endY = pointY(bounds, geometry.endY);
      const thickness = Math.abs(Number(geometry.thickness) * Math.min(bounds.width, bounds.height));
      if (thickness === 0) return false;
      const gradient = ctx.createLinearGradient(startX, startY, endX, endY);
      addSoftMotherReturn(gradient, primitive);
      ctx.beginPath();
      ctx.moveTo(startX, startY);
      ctx.bezierCurveTo(controlX, controlY, controlX, controlY, endX, endY);
      ctx.lineWidth = Math.max(0.5, thickness);
      ctx.lineCap = 'round';
      ctx.strokeStyle = gradient;
      ctx.stroke();
      return true;
    }

    function drawSineBand(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'anchorX', 'anchorY', 'amplitude', 'frequency', 'phase', 'thickness',
      ]) || !canCall(ctx, [
        'createLinearGradient', 'beginPath', 'moveTo', 'lineTo', 'stroke',
      ])) return false;

      const anchorY = pointY(bounds, geometry.anchorY);
      const amplitude = Number(geometry.amplitude) * bounds.height;
      const frequency = 1 + (Number(geometry.frequency) * 3);
      const phase = Number(geometry.phase) + Number(geometry.anchorX);
      const thickness = Math.abs(Number(geometry.thickness) * Math.min(bounds.width, bounds.height));
      if (thickness === 0) return false;
      const startX = bounds.x;
      const endX = bounds.x + bounds.width;
      const gradient = ctx.createLinearGradient(startX, anchorY, endX, anchorY);
      addSoftMotherReturn(gradient, primitive);
      ctx.beginPath();
      for (let index = 0; index <= 24; index += 1) {
        const progress = index / 24;
        const x = bounds.x + (progress * bounds.width);
        const y = anchorY + (Math.sin(TAU * (phase + (progress * frequency))) * amplitude);
        if (index === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.lineWidth = Math.max(0.5, thickness);
      ctx.lineCap = 'round';
      ctx.strokeStyle = gradient;
      ctx.stroke();
      return true;
    }

    function drawRadialArc(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'centerX', 'centerY', 'radius', 'start', 'span', 'thickness',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'arc', 'stroke',
      ])) return false;

      const centerX = pointX(bounds, geometry.centerX);
      const centerY = pointY(bounds, geometry.centerY);
      const scale = Math.min(bounds.width, bounds.height);
      const radius = Math.abs(Number(geometry.radius) * scale);
      const thickness = Math.abs(Number(geometry.thickness) * scale);
      if (radius === 0 || thickness === 0) return false;
      const halfThickness = thickness / 2;
      const gradient = ctx.createRadialGradient(
        centerX,
        centerY,
        Math.max(0, radius - halfThickness),
        centerX,
        centerY,
        radius + halfThickness,
      );
      addSoftMotherReturn(gradient, primitive);
      const start = Number(geometry.start) * TAU;
      const end = start + (Number(geometry.span) * TAU);
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, start, end);
      ctx.lineWidth = Math.max(0.5, thickness);
      ctx.lineCap = 'round';
      ctx.strokeStyle = gradient;
      ctx.stroke();
      return true;
    }

    const PAINTERS = {
      radialEllipse: drawRadialEllipse,
      linearRibbon: drawLinearRibbon,
      sineBand: drawSineBand,
      radialArc: drawRadialArc,
    };

    function drawInteriorPrimitive(ctx, primitive, bounds) {
      const safeBounds = normalizeBounds(bounds);
      const painter = primitive && PAINTERS[primitive.kind];
      if (!safeBounds || !painter || !parseHex(primitive.innerColor)
        || !parseHex(primitive.edgeColor) || !finite(primitive.alpha)) {
        return false;
      }
      return painter(ctx, primitive, safeBounds);
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
        || polygons.left.length !== polygons.right.length
        || polygonArea(polygons.left) <= 0
        || polygonArea(polygons.right) <= 0) return false;
      const sampledPointCount = polygons.left.length - 2;
      for (let index = 0; index < sampledPointCount; index += 1) {
        if (polygons.left[index].x >= polygons.right[index].x) return false;
      }
      return true;
    }

    function tracePolygon(ctx, polygon) {
      ctx.beginPath();
      ctx.moveTo(polygon[0].x, polygon[0].y);
      for (let index = 1; index < polygon.length; index += 1) {
        ctx.lineTo(polygon[index].x, polygon[index].y);
      }
      ctx.closePath();
    }

    function drawProtectedPass(ctx, polygon, primitives, bounds) {
      let saved = false;
      try {
        ctx.save();
        saved = true;
        tracePolygon(ctx, polygon);
        ctx.clip();
        primitives.forEach((primitive) => {
          if (!drawInteriorPrimitive(ctx, primitive, bounds)) {
            throw new Error('Unsupported portal interior primitive');
          }
        });
      } finally {
        if (saved) ctx.restore();
      }
    }

    function hasCanvasSurface(ctx) {
      return canCall(ctx, [
        'save', 'restore', 'beginPath', 'closePath', 'moveTo', 'lineTo', 'clip',
      ]);
    }

    function renderPortalInteriorMotion(ctx, options = {}) {
      const off = emptyRenderResult;
      if (!motion
        || typeof motion.normalizeInteriorMotionState !== 'function'
        || typeof motion.deriveInteriorPalette !== 'function'
        || typeof motion.createInteriorPrimitives !== 'function'
        || !hasCanvasSurface(ctx)
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

      let leftPrimitives;
      let rightPrimitives;
      try {
        const palette = motion.deriveInteriorPalette(options.leftMother, options.rightMother);
        const frameOptions = {
          effect: state.effect,
          width,
          height,
          timeMs: options.timeMs,
          speed: state.speed,
          strength: state.strength,
        };
        const leftFrame = motion.createInteriorPrimitives({
          ...frameOptions,
          side: 'left',
          palette: palette.left,
        });
        const rightFrame = motion.createInteriorPrimitives({
          ...frameOptions,
          side: 'right',
          palette: palette.right,
        });
        leftPrimitives = leftFrame && leftFrame.primitives;
        rightPrimitives = rightFrame && rightFrame.primitives;
      } catch (error) {
        return off();
      }

      if (!Array.isArray(leftPrimitives)
        || leftPrimitives.length === 0
        || !Array.isArray(rightPrimitives)
        || rightPrimitives.length === 0) return off();

      const bounds = { x: 0, y: 0, width, height };
      try {
        drawProtectedPass(ctx, polygons.left, leftPrimitives, bounds);
        drawProtectedPass(ctx, polygons.right, rightPrimitives, bounds);
      } catch (error) {
        return off();
      }

      return {
        rendered: true,
        leftPrimitiveCount: leftPrimitives.length,
        rightPrimitiveCount: rightPrimitives.length,
      };
    }

    return Object.freeze({
      buildInteriorRegionPolygons,
      drawInteriorPrimitive,
      renderPortalInteriorMotion,
    });
  },
);
