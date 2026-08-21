import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'dashboard_header_field_mesh.dart';
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

/// Two retained Portal field adapters. They cache scalar source-field values,
/// never colours: a live Budget A/B change recolours the existing mesh without
/// reconstructing the fog/island/cloud field. The mesh interpolates samples
/// directly at physical paint resolution instead of drawing cell rectangles.
final class DashboardHeaderPortalMaterialPaintLane {
  final DashboardHeaderInterpolatedFieldMesh _backgroundMesh =
      DashboardHeaderInterpolatedFieldMesh();
  final DashboardHeaderInterpolatedFieldMesh _interiorMesh =
      DashboardHeaderInterpolatedFieldMesh();
  Float64List? _backgroundMatter;
  Float64List? _interiorMatter;
  DashboardHeaderFieldSamplingGeometry? _backgroundGeometry;
  DashboardHeaderFieldSamplingGeometry? _interiorGeometry;
  DashboardHeaderPortalChannelState? _backgroundState;
  DashboardHeaderPortalChannelState? _interiorState;
  Map<String, double>? _backgroundSettings;
  Map<String, double>? _interiorSettings;
  int _backgroundPaintSignature = 0;
  int _interiorPaintSignature = 0;
  int _lastBackgroundMicros = -1;
  int _lastInteriorMicros = -1;
  int _backgroundFieldRebuildCount = 0;
  int _interiorFieldRebuildCount = 0;

  @visibleForTesting
  int get backgroundFieldRebuildCount => _backgroundFieldRebuildCount;

  @visibleForTesting
  int get interiorFieldRebuildCount => _interiorFieldRebuildCount;

  void paintBackground(
    Canvas canvas,
    Size size, {
    required DashboardHeaderPortalChannelState state,
    required Color colorA,
    required Color colorB,
    required double opacity,
    required int elapsedMicros,
    required double devicePixelRatio,
  }) {
    if (!state.enabled || size.isEmpty) return;
    final profile = DashboardHeaderPortalMaterialCatalog.renderProfile(
      state.effect,
    );
    final dynamic = DashboardHeaderPortalMaterialCatalog.effectFor(
      state.effect,
    ).isAnimated;
    final geometry = DashboardHeaderFieldSamplingGeometry.resolve(
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
      renderScale: profile.renderScale,
    );
    final settings = state.settingsFor(state.effect);
    final refresh =
        _backgroundMatter == null ||
        _backgroundGeometry != geometry ||
        !identical(_backgroundState, state) ||
        !identical(_backgroundSettings, settings) ||
        (dynamic &&
            elapsedMicros - _lastBackgroundMicros >= profile.frameMs * 1000);
    if (refresh) {
      _backgroundFieldRebuildCount += 1;
      _backgroundMesh.configure(geometry);
      final sampleCount = geometry.columns * geometry.rows;
      final next = _backgroundMatter?.length == sampleCount
          ? _backgroundMatter!
          : Float64List(sampleCount);
      var index = 0;
      final phase = state.phaseFor(state.effect);
      for (var y = 0; y < geometry.rows; y += 1) {
        final py = geometry.rows == 1 ? .5 : y / (geometry.rows - 1);
        for (var x = 0; x < geometry.columns; x += 1) {
          final px = geometry.columns == 1 ? .5 : x / (geometry.columns - 1);
          next[index++] = DashboardHeaderPortalMaterialField.sample(
            effect: state.effect,
            x: px,
            y: py,
            phase: phase,
            settings: settings,
          );
        }
      }
      _backgroundMatter = next;
      _backgroundGeometry = geometry;
      _backgroundState = state;
      _backgroundSettings = settings;
      _lastBackgroundMicros = elapsedMicros;
    }
    final paintSignature = Object.hash(
      colorA,
      colorB,
      opacity,
      state.paletteCenterPercent,
      state.paletteWindowPercent,
    );
    if (refresh || _backgroundPaintSignature != paintSignature) {
      _backgroundPaintSignature = paintSignature;
      final palette = DashboardHeaderPortalMaterialProjection.backgroundPalette(
        colorA: colorA,
        colorB: colorB,
        centerPercent: state.paletteCenterPercent,
        windowPercent: state.paletteWindowPercent,
      );
      final matter = _backgroundMatter!;
      for (var index = 0; index < matter.length; index += 1) {
        _backgroundMesh.setColor(
          index,
          DashboardHeaderPortalMaterialProjection._mix(
            palette.colorA,
            palette.colorB,
            matter[index],
          ).withValues(alpha: opacity),
        );
      }
    }
    _backgroundMesh.draw(canvas);
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
    required double devicePixelRatio,
  }) {
    if (!state.enabled || size.isEmpty) return;
    final profile = DashboardHeaderPortalMaterialCatalog.renderProfile(
      state.effect,
    );
    final dynamic = DashboardHeaderPortalMaterialCatalog.effectFor(
      state.effect,
    ).isAnimated;
    final geometry = DashboardHeaderFieldSamplingGeometry.resolve(
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
      renderScale: profile.renderScale,
    );
    final settings = state.settingsFor(state.effect);
    final refresh =
        _interiorMatter == null ||
        _interiorGeometry != geometry ||
        !identical(_interiorState, state) ||
        !identical(_interiorSettings, settings) ||
        (dynamic &&
            elapsedMicros - _lastInteriorMicros >= profile.frameMs * 1000);
    if (refresh) {
      _interiorFieldRebuildCount += 1;
      _interiorMesh.configure(geometry);
      final sampleCount = geometry.columns * geometry.rows;
      final next = _interiorMatter?.length == sampleCount
          ? _interiorMatter!
          : Float64List(sampleCount);
      final phase = state.phaseFor(state.effect);
      var index = 0;
      for (var y = 0; y < geometry.rows; y += 1) {
        final py = geometry.rows == 1 ? .5 : y / (geometry.rows - 1);
        for (var x = 0; x < geometry.columns; x += 1) {
          final px = geometry.columns == 1 ? .5 : x / (geometry.columns - 1);
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
          next[index++] = matter;
        }
      }
      _interiorMatter = next;
      _interiorGeometry = geometry;
      _interiorState = state;
      _interiorSettings = settings;
      _lastInteriorMicros = elapsedMicros;
    }
    final paintSignature = Object.hash(
      colorA,
      colorB,
      opacity,
      paletteSplitPercent,
    );
    if (refresh || _interiorPaintSignature != paintSignature) {
      _interiorPaintSignature = paintSignature;
      final matter = _interiorMatter!;
      final split = (paletteSplitPercent / 100).clamp(.04, .96).toDouble();
      final columns = geometry.columns;
      for (var index = 0; index < matter.length; index += 1) {
        final x = columns == 1 ? .5 : (index % columns) / (columns - 1);
        final alpha = matter[index] * .38 * opacity;
        _interiorMesh.setColor(
          index,
          alpha <= .002
              ? Colors.transparent
              : DashboardHeaderPortalMaterialProjection.interiorTint(
                  colorA: colorA,
                  colorB: colorB,
                  x: x,
                  split: split,
                ).withValues(alpha: alpha),
        );
      }
    }
    _interiorMesh.draw(canvas);
  }
}
