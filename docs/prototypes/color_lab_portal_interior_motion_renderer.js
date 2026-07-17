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
    const MAX_SOFT_STAMPS = 32;
    const CURVE_PROBE_SEGMENTS = 48;
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

    function rotatedExtents(radiusX, radiusY, rotation) {
      return {
        x: Math.hypot(radiusX * Math.cos(rotation), radiusY * Math.sin(rotation)),
        y: Math.hypot(radiusX * Math.sin(rotation), radiusY * Math.cos(rotation)),
      };
    }

    function fitRotatedEllipse(bounds, centerX, centerY, radiusX, radiusY, rotation) {
      let safeRadiusX = Math.abs(radiusX);
      let safeRadiusY = Math.abs(radiusY);
      if (safeRadiusX === 0 || safeRadiusY === 0) return null;
      let extents = rotatedExtents(safeRadiusX, safeRadiusY, rotation);
      const fitScale = Math.min(
        1,
        bounds.width / (2 * extents.x),
        bounds.height / (2 * extents.y),
      );
      if (!Number.isFinite(fitScale) || fitScale <= 0) return null;
      safeRadiusX *= fitScale;
      safeRadiusY *= fitScale;
      extents = rotatedExtents(safeRadiusX, safeRadiusY, rotation);
      return {
        centerX: clamp(centerX, bounds.x + extents.x, bounds.x + bounds.width - extents.x),
        centerY: clamp(centerY, bounds.y + extents.y, bounds.y + bounds.height - extents.y),
        radiusX: safeRadiusX,
        radiusY: safeRadiusY,
        rotation,
      };
    }

    function drawCircularSoftStamp(ctx, primitive, centerX, centerY, radius) {
      const gradient = ctx.createRadialGradient(
        centerX,
        centerY,
        0,
        centerX,
        centerY,
        radius,
      );
      addSoftMotherReturn(gradient, primitive);
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, TAU);
      ctx.fillStyle = gradient;
      ctx.fill();
    }

    function adaptiveStampPoints(pointAt, radius) {
      const probes = [];
      const cumulativeLengths = [0];
      let length = 0;
      for (let index = 0; index <= CURVE_PROBE_SEGMENTS; index += 1) {
        const point = pointAt(index / CURVE_PROBE_SEGMENTS);
        if (!point || !Number.isFinite(point.x) || !Number.isFinite(point.y)) return [];
        if (index > 0) length += Math.hypot(
          point.x - probes[index - 1].x,
          point.y - probes[index - 1].y,
        );
        probes.push(point);
        if (index > 0) cumulativeLengths.push(length);
      }
      const targetSpacing = Math.max(1, radius * 1.5);
      const stampCount = Math.max(
        2,
        Math.min(MAX_SOFT_STAMPS, Math.ceil(length / targetSpacing) + 1),
      );
      let probeIndex = 1;
      return Array.from({ length: stampCount }, (_, index) => {
        const targetLength = length * (index / (stampCount - 1));
        while (probeIndex < cumulativeLengths.length - 1
          && cumulativeLengths[probeIndex] < targetLength) probeIndex += 1;
        const lowerLength = cumulativeLengths[probeIndex - 1];
        const upperLength = cumulativeLengths[probeIndex];
        const segmentProgress = upperLength === lowerLength
          ? 0
          : (targetLength - lowerLength) / (upperLength - lowerLength);
        const lower = probes[probeIndex - 1];
        const upper = probes[probeIndex];
        return {
          x: lower.x + ((upper.x - lower.x) * segmentProgress),
          y: lower.y + ((upper.y - lower.y) * segmentProgress),
        };
      });
    }

    function drawSoftStampField(ctx, primitive, bounds, rawRadius, pointAt) {
      const radius = Math.min(
        Math.abs(rawRadius),
        bounds.width / 2,
        bounds.height / 2,
      );
      if (!Number.isFinite(radius) || radius <= 0) return false;
      const points = adaptiveStampPoints(pointAt, radius);
      if (points.length < 2) return false;
      points.forEach((point) => {
        const centerX = clamp(point.x, bounds.x + radius, bounds.x + bounds.width - radius);
        const centerY = clamp(point.y, bounds.y + radius, bounds.y + bounds.height - radius);
        drawCircularSoftStamp(ctx, primitive, centerX, centerY, radius);
      });
      return true;
    }

    function drawRadialEllipse(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'centerX', 'centerY', 'radiusX', 'radiusY', 'rotation',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'ellipse', 'fill',
        'translate', 'rotate', 'scale',
      ])) return false;

      const fitted = fitRotatedEllipse(
        bounds,
        pointX(bounds, geometry.centerX),
        pointY(bounds, geometry.centerY),
        Number(geometry.radiusX) * bounds.width,
        Number(geometry.radiusY) * bounds.height,
        Number(geometry.rotation) * TAU,
      );
      if (!fitted) return false;

      ctx.translate(fitted.centerX, fitted.centerY);
      ctx.rotate(fitted.rotation);
      ctx.scale(fitted.radiusX, fitted.radiusY);
      try {
        const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, 1);
        addSoftMotherReturn(gradient, primitive);
        ctx.beginPath();
        ctx.ellipse(0, 0, 1, 1, 0, 0, TAU);
        ctx.fillStyle = gradient;
        ctx.fill();
      } finally {
        ctx.scale(1 / fitted.radiusX, 1 / fitted.radiusY);
        ctx.rotate(-fitted.rotation);
        ctx.translate(-fitted.centerX, -fitted.centerY);
      }
      return true;
    }

    function drawLinearRibbon(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'startX', 'startY', 'controlX', 'controlY', 'endX', 'endY', 'thickness',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'arc', 'fill',
      ])) return false;

      const startX = pointX(bounds, geometry.startX);
      const startY = pointY(bounds, geometry.startY);
      const controlX = pointX(bounds, geometry.controlX);
      const controlY = pointY(bounds, geometry.controlY);
      const endX = pointX(bounds, geometry.endX);
      const endY = pointY(bounds, geometry.endY);
      const radius = Number(geometry.thickness) * Math.min(bounds.width, bounds.height);
      return drawSoftStampField(ctx, primitive, bounds, radius, (progress) => {
        const inverse = 1 - progress;
        const startWeight = inverse ** 3;
        const controlWeight = (3 * inverse * inverse * progress)
          + (3 * inverse * progress * progress);
        const endWeight = progress ** 3;
        return {
          x: (startX * startWeight) + (controlX * controlWeight) + (endX * endWeight),
          y: (startY * startWeight) + (controlY * controlWeight) + (endY * endWeight),
        };
      });
    }

    function drawSineBand(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'anchorX', 'anchorY', 'amplitude', 'frequency', 'phase', 'thickness',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'arc', 'fill',
      ])) return false;

      const anchorY = pointY(bounds, geometry.anchorY);
      const amplitude = Number(geometry.amplitude) * bounds.height;
      const frequency = 1 + (Number(geometry.frequency) * 3);
      const phase = Number(geometry.phase) + Number(geometry.anchorX);
      const radius = Number(geometry.thickness) * Math.min(bounds.width, bounds.height);
      return drawSoftStampField(ctx, primitive, bounds, radius, (progress) => ({
        x: bounds.x + (progress * bounds.width),
        y: anchorY + (Math.sin(TAU * (phase + (progress * frequency))) * amplitude),
      }));
    }

    function drawRadialArc(ctx, primitive, bounds) {
      const geometry = primitive.geometry;
      if (!finiteGeometry(geometry, [
        'centerX', 'centerY', 'radius', 'start', 'span', 'thickness',
      ]) || !canCall(ctx, [
        'createRadialGradient', 'beginPath', 'arc', 'fill',
      ])) return false;

      const centerX = pointX(bounds, geometry.centerX);
      const centerY = pointY(bounds, geometry.centerY);
      const scale = Math.min(bounds.width, bounds.height);
      const pathRadius = Math.abs(Number(geometry.radius) * scale);
      const stampRadius = Number(geometry.thickness) * scale;
      if (pathRadius === 0) return false;
      const start = Number(geometry.start) * TAU;
      const span = Number(geometry.span) * TAU;
      return drawSoftStampField(ctx, primitive, bounds, stampRadius, (progress) => {
        const angle = start + (span * progress);
        return {
          x: centerX + (Math.cos(angle) * pathRadius),
          y: centerY + (Math.sin(angle) * pathRadius),
        };
      });
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
      const drawingBounds = protectedDrawingBounds(polygons, width, height);
      if (!drawingBounds) return off();

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

      try {
        drawProtectedPass(ctx, polygons.left, leftPrimitives, drawingBounds.left);
        drawProtectedPass(ctx, polygons.right, rightPrimitives, drawingBounds.right);
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
