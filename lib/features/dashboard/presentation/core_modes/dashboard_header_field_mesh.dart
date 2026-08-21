import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Describes the source-field sampling grid separately from Flutter's physical
/// output. The Header uses a direct vector mesh, so no low-resolution bitmap
/// is stretched across the device surface.
@immutable
final class DashboardHeaderFieldSamplingGeometry {
  const DashboardHeaderFieldSamplingGeometry._({
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.renderScale,
    required this.physicalWidth,
    required this.physicalHeight,
    required this.columns,
    required this.rows,
  });

  factory DashboardHeaderFieldSamplingGeometry.resolve({
    required Size logicalSize,
    required double devicePixelRatio,
    required double renderScale,
  }) {
    final width = math.max(0.0, logicalSize.width);
    final height = math.max(0.0, logicalSize.height);
    final dpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final quality = renderScale.clamp(.35, 1.0).toDouble();
    return DashboardHeaderFieldSamplingGeometry._(
      logicalSize: Size(width, height),
      devicePixelRatio: dpr,
      renderScale: quality,
      physicalWidth: (width * dpr).ceil(),
      physicalHeight: (height * dpr).ceil(),
      // These are source-field nodes, not painted rectangles. Flutter
      // rasterizes the interpolated mesh at the actual device resolution.
      columns: math.max(16, (width * quality / 4).round()),
      rows: math.max(6, (height * quality / 4).round()),
    );
  }

  final Size logicalSize;
  final double devicePixelRatio;
  final double renderScale;
  final int physicalWidth;
  final int physicalHeight;
  final int columns;
  final int rows;

  bool get hasIntermediateRaster => false;
  DashboardHeaderFieldInterpolation get interpolation =>
      DashboardHeaderFieldInterpolation.triangularLinear;
  bool get usesDirectCellRectangles => false;

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderFieldSamplingGeometry &&
      logicalSize == other.logicalSize &&
      devicePixelRatio == other.devicePixelRatio &&
      renderScale == other.renderScale &&
      physicalWidth == other.physicalWidth &&
      physicalHeight == other.physicalHeight &&
      columns == other.columns &&
      rows == other.rows;

  @override
  int get hashCode => Object.hash(
    logicalSize,
    devicePixelRatio,
    renderScale,
    physicalWidth,
    physicalHeight,
    columns,
    rows,
  );
}

enum DashboardHeaderFieldInterpolation {
  triangularLinear;

  /// The output mesh is formed from two linearly interpolated triangles per
  /// source quad.  This helper freezes the one-dimensional in-triangle
  /// interpolation used by the continuity regression test; the production
  /// mesh itself is rasterized by Skia at the actual physical output size.
  static double linearSample({
    required double topLeft,
    required double topRight,
    required double bottomLeft,
    required double bottomRight,
    required double x,
    required double y,
  }) {
    final tx = x.clamp(0.0, 1.0).toDouble();
    final ty = y.clamp(0.0, 1.0).toDouble();
    final top = topLeft + (topRight - topLeft) * tx;
    final bottom = bottomLeft + (bottomRight - bottomLeft) * tx;
    return top + (bottom - top) * ty;
  }
}

/// Content identity for a Header field surface. The direct mesh owns no
/// offscreen image cache, but retaining this complete identity prevents a
/// future raster/cache adapter from silently dropping a physical input.
@immutable
final class DashboardHeaderFieldRenderIdentity {
  const DashboardHeaderFieldRenderIdentity({
    required this.logicalWidth,
    required this.logicalHeight,
    required this.devicePixelRatio,
    required this.renderScale,
    required this.effectIdentity,
    required this.renderStepMs,
    required this.settingsGeneration,
  });

  final double logicalWidth;
  final double logicalHeight;
  final double devicePixelRatio;
  final double renderScale;
  final String effectIdentity;
  final int renderStepMs;
  final int settingsGeneration;

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderFieldRenderIdentity &&
      logicalWidth == other.logicalWidth &&
      logicalHeight == other.logicalHeight &&
      devicePixelRatio == other.devicePixelRatio &&
      renderScale == other.renderScale &&
      effectIdentity == other.effectIdentity &&
      renderStepMs == other.renderStepMs &&
      settingsGeneration == other.settingsGeneration;

  @override
  int get hashCode => Object.hash(
    logicalWidth,
    logicalHeight,
    devicePixelRatio,
    renderScale,
    effectIdentity,
    renderStepMs,
    settingsGeneration,
  );
}

/// One retained colour mesh. Source effects fill the vertex colours; Skia
/// linearly interpolates them between vertices at physical paint resolution.
/// This deliberately cannot expose the source sampling grid as rectangle
/// tiles.
final class DashboardHeaderInterpolatedFieldMesh {
  DashboardHeaderFieldSamplingGeometry? _geometry;
  Float32List? _positions;
  Uint16List? _indices;
  Int32List? _colors;
  ui.Vertices? _vertices;

  DashboardHeaderFieldSamplingGeometry? get geometry => _geometry;
  int get vertexCount => _colors?.length ?? 0;

  bool configure(DashboardHeaderFieldSamplingGeometry geometry) {
    if (_geometry == geometry && _positions != null) return false;
    final count = geometry.columns * geometry.rows;
    if (count > 65535) {
      throw ArgumentError.value(
        count,
        'geometry',
        'Header mesh exceeds 16-bit index capacity.',
      );
    }
    final positions = Float32List(count * 2);
    final colors = Int32List(count);
    var vertex = 0;
    for (var y = 0; y < geometry.rows; y += 1) {
      final py = geometry.rows == 1
          ? 0.0
          : geometry.logicalSize.height * y / (geometry.rows - 1);
      for (var x = 0; x < geometry.columns; x += 1) {
        final px = geometry.columns == 1
            ? 0.0
            : geometry.logicalSize.width * x / (geometry.columns - 1);
        positions[vertex * 2] = px;
        positions[vertex * 2 + 1] = py;
        vertex += 1;
      }
    }
    final quadColumns = geometry.columns > 1 ? geometry.columns - 1 : 0;
    final quadRows = geometry.rows > 1 ? geometry.rows - 1 : 0;
    final indices = Uint16List(quadColumns * quadRows * 6);
    var index = 0;
    for (var y = 0; y < geometry.rows - 1; y += 1) {
      for (var x = 0; x < geometry.columns - 1; x += 1) {
        final topLeft = y * geometry.columns + x;
        final topRight = topLeft + 1;
        final bottomLeft = topLeft + geometry.columns;
        final bottomRight = bottomLeft + 1;
        indices[index++] = topLeft;
        indices[index++] = bottomLeft;
        indices[index++] = topRight;
        indices[index++] = topRight;
        indices[index++] = bottomLeft;
        indices[index++] = bottomRight;
      }
    }
    _geometry = geometry;
    _positions = positions;
    _indices = indices;
    _colors = colors;
    _vertices = null;
    return true;
  }

  void setColor(int index, Color color) {
    final colors = _colors;
    if (colors == null) {
      throw StateError('configure must be called before assigning colours.');
    }
    colors[index] = color.toARGB32();
    _vertices = null;
  }

  void draw(Canvas canvas) {
    final positions = _positions;
    final colors = _colors;
    final indices = _indices;
    if (positions == null || colors == null || indices == null) return;
    final vertices = _vertices ??= ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      colors: colors,
      indices: indices,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, Paint());
  }
}
