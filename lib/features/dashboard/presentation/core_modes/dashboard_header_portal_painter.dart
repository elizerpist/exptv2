import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_header_portal_material_field.dart';

@immutable
final class DashboardHeaderPortalPalette {
  const DashboardHeaderPortalPalette({
    required this.colorA,
    required this.colorB,
  });

  final Color colorA;
  final Color colorB;
}

@immutable
final class DashboardHeaderPortalInteriorSamplePoint {
  const DashboardHeaderPortalInteriorSamplePoint({
    required this.x,
    required this.y,
    required this.angle,
    required this.spanPx,
  });

  final double x;
  final double y;
  final double angle;
  final double spanPx;
}

/// Pure source-derived projection helpers. They consume a Header-provided A/B
/// palette and never understand a Budget target, persistence or animation
/// ownership.
abstract final class DashboardHeaderPortalMaterialProjection {
  static DashboardHeaderPortalPalette backgroundPalette({
    required Color colorA,
    required Color colorB,
    required double centerPercent,
    required double windowPercent,
  }) {
    final center = centerPercent.clamp(0.0, 100.0).toDouble();
    final window = windowPercent.clamp(10.0, 100.0).toDouble();
    final half = window / 2;
    return DashboardHeaderPortalPalette(
      colorA: _mix(colorA, colorB, ((center - half) / 100).clamp(0.0, 1.0)),
      colorB: _mix(colorA, colorB, ((center + half) / 100).clamp(0.0, 1.0)),
    );
  }

  static DashboardHeaderPortalInteriorSamplePoint interiorSamplePoint({
    required double x,
    required double y,
    required double width,
    required double height,
    required double phase,
    required bool rotationEnabled,
    required double rotationSpeed,
  }) {
    final safeWidth = math.max(1, width);
    final safeHeight = math.max(1, height);
    final span = math.max(safeWidth, safeHeight).toDouble();
    final speed = rotationSpeed.clamp(0.0, 100.0).toDouble();
    final angle = rotationEnabled && speed > 0
        ? phase * (speed / 100) * math.pi * 2
        : 0.0;
    final px = (x.clamp(0.0, 1.0) - .5) * safeWidth;
    final py = (y.clamp(0.0, 1.0) - .5) * safeHeight;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final rotatedX = px * cosine - py * sine;
    final rotatedY = px * sine + py * cosine;
    return DashboardHeaderPortalInteriorSamplePoint(
      x: _round12((.5 + rotatedX / span).clamp(0.0, 1.0)),
      y: _round12((.5 + rotatedY / span).clamp(0.0, 1.0)),
      angle: _round12(angle),
      spanPx: _round12(span),
    );
  }

  static Color interiorTint({
    required Color colorA,
    required Color colorB,
    required double x,
    required double split,
    double transitionWidth = .36,
  }) {
    final amount = _smoothstep(
      split - transitionWidth / 2,
      split + transitionWidth / 2,
      x.clamp(0.0, 1.0).toDouble(),
    );
    return _mix(colorA, colorB, amount);
  }

  static Color _mix(Color left, Color right, double amount) => Color.fromARGB(
    255,
    ((left.r + (right.r - left.r) * amount) * 255)
        .round()
        .clamp(0, 255)
        .toInt(),
    ((left.g + (right.g - left.g) * amount) * 255)
        .round()
        .clamp(0, 255)
        .toInt(),
    ((left.b + (right.b - left.b) * amount) * 255)
        .round()
        .clamp(0, 255)
        .toInt(),
  );

  static double _smoothstep(double edge0, double edge1, double value) {
    if (edge0 == edge1) return value < edge0 ? 0 : 1;
    final amount = ((value - edge0) / (edge1 - edge0))
        .clamp(0.0, 1.0)
        .toDouble();
    return amount * amount * (3 - 2 * amount);
  }

  static double _round12(double value) => (value * 1e12).round() / 1e12;
}

/// The two narrow, cached Portal visual paint adapters. A cache is retained
/// across phase ticks and re-rasterized only at each source render cadence;
/// static modes do not request phase-based raster work.
final class DashboardHeaderPortalMaterialPaintLane {
  List<Color>? _backgroundCells;
  List<Color>? _interiorCells;
  int _backgroundColumns = 0;
  int _backgroundRows = 0;
  int _interiorColumns = 0;
  int _interiorRows = 0;
  Size? _backgroundSize;
  Size? _interiorSize;
  DashboardHeaderPortalChannelState? _backgroundState;
  DashboardHeaderPortalChannelState? _interiorState;
  Color? _backgroundInputA;
  Color? _backgroundInputB;
  Color? _interiorInputA;
  Color? _interiorInputB;
  double? _backgroundOpacity;
  double? _interiorOpacity;
  int _lastBackgroundMicros = -1;
  int _lastInteriorMicros = -1;

  void paintBackground(
    Canvas canvas,
    Size size, {
    required DashboardHeaderPortalChannelState state,
    required Color colorA,
    required Color colorB,
    required double opacity,
    required int elapsedMicros,
  }) {
    if (!state.enabled || size.isEmpty) return;
    final profile = DashboardHeaderPortalMaterialCatalog.renderProfile(
      state.effect,
    );
    final dynamic = DashboardHeaderPortalMaterialCatalog.effectFor(
      state.effect,
    ).isAnimated;
    final refresh =
        _backgroundCells == null ||
        _backgroundSize != size ||
        !identical(_backgroundState, state) ||
        _backgroundInputA != colorA ||
        _backgroundInputB != colorB ||
        _backgroundOpacity != opacity ||
        (dynamic &&
            elapsedMicros - _lastBackgroundMicros >= profile.frameMs * 1000);
    if (refresh) {
      _backgroundColumns = math.max(
        16,
        (size.width * profile.renderScale / 4).round(),
      );
      _backgroundRows = math.max(
        6,
        (size.height * profile.renderScale / 4).round(),
      );
      final palette = DashboardHeaderPortalMaterialProjection.backgroundPalette(
        colorA: colorA,
        colorB: colorB,
        centerPercent: state.paletteCenterPercent,
        windowPercent: state.paletteWindowPercent,
      );
      final cellCount = _backgroundColumns * _backgroundRows;
      // Keep the raster bank stable across source-cadence phase frames. A
      // resize/effect-resolution change is the only reason to allocate a new
      // bank; each animated frame merely rewrites the retained cells.
      final next = _backgroundCells?.length == cellCount
          ? _backgroundCells!
          : List<Color>.filled(cellCount, Colors.transparent);
      var index = 0;
      final settings = state.settingsFor(state.effect);
      final phase = state.phaseFor(state.effect);
      for (var y = 0; y < _backgroundRows; y += 1) {
        final py = _backgroundRows == 1 ? .5 : y / (_backgroundRows - 1);
        for (var x = 0; x < _backgroundColumns; x += 1) {
          final px = _backgroundColumns == 1
              ? .5
              : x / (_backgroundColumns - 1);
          final matter = DashboardHeaderPortalMaterialField.sample(
            effect: state.effect,
            x: px,
            y: py,
            phase: phase,
            settings: settings,
          );
          final color = DashboardHeaderPortalMaterialProjection._mix(
            palette.colorA,
            palette.colorB,
            matter,
          );
          next[index++] = color.withValues(alpha: opacity);
        }
      }
      _backgroundCells = next;
      _backgroundSize = size;
      _backgroundState = state;
      _backgroundInputA = colorA;
      _backgroundInputB = colorB;
      _backgroundOpacity = opacity;
      _lastBackgroundMicros = elapsedMicros;
    }
    _drawCells(
      canvas,
      size,
      _backgroundCells,
      _backgroundColumns,
      _backgroundRows,
    );
  }

  void paintInterior(
    Canvas canvas,
    Size size, {
    required DashboardHeaderPortalChannelState state,
    required Color colorA,
    required Color colorB,
    required double opacity,
    required double paletteSplitPercent,
    required int elapsedMicros,
  }) {
    if (!state.enabled || size.isEmpty) return;
    final profile = DashboardHeaderPortalMaterialCatalog.renderProfile(
      state.effect,
    );
    final dynamic = DashboardHeaderPortalMaterialCatalog.effectFor(
      state.effect,
    ).isAnimated;
    final refresh =
        _interiorCells == null ||
        _interiorSize != size ||
        !identical(_interiorState, state) ||
        _interiorInputA != colorA ||
        _interiorInputB != colorB ||
        _interiorOpacity != opacity ||
        (dynamic &&
            elapsedMicros - _lastInteriorMicros >= profile.frameMs * 1000);
    if (refresh) {
      _interiorColumns = math.max(
        16,
        (size.width * profile.renderScale / 4).round(),
      );
      _interiorRows = math.max(
        6,
        (size.height * profile.renderScale / 4).round(),
      );
      final cellCount = _interiorColumns * _interiorRows;
      // Match the background lane's retained-bank policy: tuning and phase
      // changes repaint this narrow Header lane without allocating an N-cell
      // temporary collection every frame.
      final next = _interiorCells?.length == cellCount
          ? _interiorCells!
          : List<Color>.filled(cellCount, Colors.transparent);
      final settings = state.settingsFor(state.effect);
      final phase = state.phaseFor(state.effect);
      final split = (paletteSplitPercent / 100).clamp(.04, .96).toDouble();
      var index = 0;
      for (var y = 0; y < _interiorRows; y += 1) {
        final py = _interiorRows == 1 ? .5 : y / (_interiorRows - 1);
        for (var x = 0; x < _interiorColumns; x += 1) {
          final px = _interiorColumns == 1 ? .5 : x / (_interiorColumns - 1);
          final point =
              DashboardHeaderPortalMaterialProjection.interiorSamplePoint(
                x: px,
                y: py,
                width: size.width,
                height: size.height,
                phase: phase,
                rotationEnabled: state.rotationEnabled,
                rotationSpeed: state.rotationSpeed,
              );
          final matter = DashboardHeaderPortalMaterialField.sample(
            effect: state.effect,
            x: point.x,
            y: point.y,
            phase: phase,
            settings: settings,
          );
          final alpha = matter * .38 * opacity;
          next[index++] = alpha <= .002
              ? Colors.transparent
              : DashboardHeaderPortalMaterialProjection.interiorTint(
                  colorA: colorA,
                  colorB: colorB,
                  x: px,
                  split: split,
                ).withValues(alpha: alpha);
        }
      }
      _interiorCells = next;
      _interiorSize = size;
      _interiorState = state;
      _interiorInputA = colorA;
      _interiorInputB = colorB;
      _interiorOpacity = opacity;
      _lastInteriorMicros = elapsedMicros;
    }
    _drawCells(canvas, size, _interiorCells, _interiorColumns, _interiorRows);
  }

  static void _drawCells(
    Canvas canvas,
    Size size,
    List<Color>? cells,
    int columns,
    int rows,
  ) {
    if (cells == null || columns <= 0 || rows <= 0) return;
    final width = size.width / columns;
    final height = size.height / rows;
    final paint = Paint();
    var index = 0;
    for (var y = 0; y < rows; y += 1) {
      for (var x = 0; x < columns; x += 1) {
        paint.color = cells[index++];
        canvas.drawRect(
          Rect.fromLTWH(x * width, y * height, width + .5, height + .5),
          paint,
        );
      }
    }
  }
}
