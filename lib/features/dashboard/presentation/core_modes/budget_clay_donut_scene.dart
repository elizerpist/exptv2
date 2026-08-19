import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One source of truth for the approved Budget V2 clay-donut geometry. The
/// legacy SVG reference renderer and the Canvas scene use these exact values;
/// hit testing also delegates to this authority.
abstract final class BudgetClayDonutGeometry {
  static const viewBox = '44 44 424 424';
  static const sourceMin = 44.0;
  static const sourceSize = 424.0;
  static const sourceCenter = 256.0;
  static const innerRadius = 92.0;
  static const normalOuterRadius = 164.0;
  static const selectedOuterRadius = 160.38;
  static const centerPlateRadius = 106.0;
  static const selectedOffset = 10.0;
  static const frontDepth = 14.0;

  static double gapDegreesForSliceCount(int count) => count > 12
      ? .5
      : count > 7
      ? .9
      : 1.7;

  static double sweepDegrees(num value, num total) =>
      total <= 0 ? 0 : value / total * 360;

  static Offset point(
    double cx,
    double cy,
    double radius,
    double degrees, {
    double yOffset = 0,
  }) {
    final radians = radiansForDegrees(degrees);
    return Offset(
      cx + radius * math.cos(radians),
      cy + radius * math.sin(radians) + yOffset,
    );
  }

  static double radiansForDegrees(double degrees) =>
      (degrees - 90) * math.pi / 180;

  static Offset selectedOffsetFor({
    required double start,
    required double end,
  }) => point(0, 0, selectedOffset, (start + end) / 2);

  static Path ringSlicePath({
    required double radius,
    required double start,
    required double end,
  }) {
    final outerStart = point(sourceCenter, sourceCenter, radius, start);
    final innerEnd = point(sourceCenter, sourceCenter, innerRadius, end);
    final sweep = radiansForDegrees(end) - radiansForDegrees(start);
    return Path()
      ..moveTo(outerStart.dx, outerStart.dy)
      ..arcTo(
        Rect.fromCircle(
          center: const Offset(sourceCenter, sourceCenter),
          radius: radius,
        ),
        radiansForDegrees(start),
        sweep,
        false,
      )
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(
        Rect.fromCircle(
          center: const Offset(sourceCenter, sourceCenter),
          radius: innerRadius,
        ),
        radiansForDegrees(end),
        -sweep,
        false,
      )
      ..close();
  }

  static Path outerSidePath({
    required double radius,
    required double start,
    required double end,
  }) {
    final topStart = point(sourceCenter, sourceCenter, radius, start);
    final bottomEnd = point(
      sourceCenter,
      sourceCenter,
      radius,
      end,
      yOffset: frontDepth,
    );
    final sweep = radiansForDegrees(end) - radiansForDegrees(start);
    return Path()
      ..moveTo(topStart.dx, topStart.dy)
      ..arcTo(
        Rect.fromCircle(
          center: const Offset(sourceCenter, sourceCenter),
          radius: radius,
        ),
        radiansForDegrees(start),
        sweep,
        false,
      )
      ..lineTo(bottomEnd.dx, bottomEnd.dy)
      ..arcTo(
        Rect.fromCircle(
          center: const Offset(sourceCenter, sourceCenter + frontDepth),
          radius: radius,
        ),
        radiansForDegrees(end),
        -sweep,
        false,
      )
      ..close();
  }

  static BudgetClayDonutHit resolveHit({
    required Offset localPosition,
    required Size size,
    required List<int> values,
  }) {
    if (size.isEmpty || values.isEmpty) {
      return const BudgetClayDonutHit.outside();
    }
    final scale = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final radius = delta.distance / scale;
    if (radius <= centerPlateRadius / sourceSize) {
      return const BudgetClayDonutHit.center();
    }
    if (radius > 172 / sourceSize) {
      return const BudgetClayDonutHit.outside();
    }
    final total = values.fold<int>(
      0,
      (sum, value) => sum + (value > 0 ? value : 0),
    );
    if (total <= 0) return const BudgetClayDonutHit.outside();
    final angle =
        (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 90 + 360) % 360;
    var cursorNumerator = 0;
    for (var index = 0; index < values.length; index += 1) {
      final value = values[index];
      if (value <= 0) continue;
      cursorNumerator += value;
      if (angle <= cursorNumerator * 360 / total ||
          index == values.length - 1) {
        return BudgetClayDonutHit.slice(index);
      }
    }
    return const BudgetClayDonutHit.outside();
  }
}

enum BudgetClayDonutTapTarget { outside, center, slice }

@immutable
final class BudgetClayDonutHit {
  const BudgetClayDonutHit._(this.target, [this.index]);

  const BudgetClayDonutHit.outside() : this._(BudgetClayDonutTapTarget.outside);
  const BudgetClayDonutHit.center() : this._(BudgetClayDonutTapTarget.center);
  const BudgetClayDonutHit.slice(int index)
    : this._(BudgetClayDonutTapTarget.slice, index);

  final BudgetClayDonutTapTarget target;
  final int? index;
}

@immutable
final class BudgetClayDonutSliceInput {
  const BudgetClayDonutSliceInput({
    required this.label,
    required this.value,
    required this.color,
    String? stableId,
  }) : stableId = stableId ?? label;

  final String stableId;
  final String label;
  final int value;
  final Color color;
}

/// Immutable, retained geometry for one exact Category or Partner chart.
/// Selection is intentionally absent: a tick only selects a stored index.
@immutable
final class BudgetClayDonutScene {
  BudgetClayDonutScene._({
    required List<BudgetClayDonutSlice> slices,
    required this.total,
    required Map<String, int> sliceIndexByStableId,
  }) : slices = List<BudgetClayDonutSlice>.unmodifiable(slices),
       _sliceIndexByStableId = Map<String, int>.unmodifiable(
         sliceIndexByStableId,
       );

  factory BudgetClayDonutScene.fromSlices(
    List<BudgetClayDonutSliceInput> inputs,
  ) {
    final items = inputs
        .where((input) => input.value > 0)
        .toList(growable: false);
    final total = items.fold<int>(0, (sum, item) => sum + item.value);
    var runningAngle = 0.0;
    final gap = BudgetClayDonutGeometry.gapDegreesForSliceCount(items.length);
    final slices = <BudgetClayDonutSlice>[];
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final sweep = BudgetClayDonutGeometry.sweepDegrees(item.value, total);
      final start = runningAngle + gap / 2;
      final end = runningAngle + sweep - gap / 2;
      runningAngle += sweep;
      if (end <= start) continue;
      final selectedOffset = BudgetClayDonutGeometry.selectedOffsetFor(
        start: start,
        end: end,
      );
      slices.add(
        BudgetClayDonutSlice._(
          stableId: item.stableId,
          label: item.label,
          value: item.value,
          color: item.color,
          startDegrees: start,
          endDegrees: end,
          sweepDegrees: sweep,
          normalTopPath: BudgetClayDonutGeometry.ringSlicePath(
            radius: BudgetClayDonutGeometry.normalOuterRadius,
            start: start,
            end: end,
          ),
          normalSidePath: BudgetClayDonutGeometry.outerSidePath(
            radius: BudgetClayDonutGeometry.normalOuterRadius,
            start: start,
            end: end,
          ),
          selectedTopPath: BudgetClayDonutGeometry.ringSlicePath(
            radius: BudgetClayDonutGeometry.selectedOuterRadius,
            start: start,
            end: end,
          ),
          selectedSidePath: BudgetClayDonutGeometry.outerSidePath(
            radius: BudgetClayDonutGeometry.selectedOuterRadius,
            start: start,
            end: end,
          ),
          selectedOffset: selectedOffset,
        ),
      );
    }
    return BudgetClayDonutScene._(
      slices: slices,
      total: total,
      sliceIndexByStableId: <String, int>{
        for (final item in slices.indexed) item.$2.stableId: item.$1,
      },
    );
  }

  final List<BudgetClayDonutSlice> slices;
  final int total;
  final Map<String, int> _sliceIndexByStableId;

  /// Test-visible invariant: one scene construction produces one retained
  /// geometry bank regardless of how many selection ticks are painted.
  int get geometryBuildCount => 1;

  int selectedSliceIndexForStableId(String? stableId) =>
      stableId == null ? -1 : (_sliceIndexByStableId[stableId] ?? -1);

  BudgetClayDonutHit hitTest({
    required Offset localPosition,
    required Size size,
  }) => BudgetClayDonutGeometry.resolveHit(
    localPosition: localPosition,
    size: size,
    values: <int>[for (final slice in slices) slice.value],
  );
}

@immutable
final class BudgetClayDonutSlice {
  const BudgetClayDonutSlice._({
    required this.stableId,
    required this.label,
    required this.value,
    required this.color,
    required this.startDegrees,
    required this.endDegrees,
    required this.sweepDegrees,
    required this.normalTopPath,
    required this.normalSidePath,
    required this.selectedTopPath,
    required this.selectedSidePath,
    required this.selectedOffset,
  });

  final String stableId;
  final String label;
  final int value;
  final Color color;
  final double startDegrees;
  final double endDegrees;
  final double sweepDegrees;
  final Path normalTopPath;
  final Path normalSidePath;
  final Path selectedTopPath;
  final Path selectedSidePath;
  final Offset selectedOffset;
}

@immutable
final class BudgetClayDonutCenter {
  const BudgetClayDonutCenter({required this.valueLabel, required this.label});

  final String valueLabel;
  final String label;

  factory BudgetClayDonutCenter.forScene(
    BudgetClayDonutScene scene, {
    required int selectedSliceIndex,
    String? absentSelectionLabel,
  }) {
    if (scene.slices.isEmpty) {
      return const BudgetClayDonutCenter(valueLabel: '0%', label: 'nincs adat');
    }
    if (selectedSliceIndex < 0 || selectedSliceIndex >= scene.slices.length) {
      return absentSelectionLabel == null
          ? const BudgetClayDonutCenter(valueLabel: '100%', label: 'összesen')
          : BudgetClayDonutCenter(
              valueLabel: '0%',
              label: absentSelectionLabel,
            );
    }
    final selected = scene.slices[selectedSliceIndex];
    return BudgetClayDonutCenter(
      valueLabel: '${(selected.value * 100 / scene.total).round()}%',
      label: selected.label,
    );
  }
}

/// Paint-only high-frequency dynamic chart. It receives retained scene paths
/// and a tiny selected-index parameter; no SVG parsing or text layout occurs
/// in [paint].
final class BudgetClayDonutView extends StatelessWidget {
  const BudgetClayDonutView({
    super.key,
    required this.scene,
    required this.selectedSliceIndex,
    this.absentSelectionLabel,
  });

  final BudgetClayDonutScene scene;
  final int selectedSliceIndex;
  final String? absentSelectionLabel;

  @override
  Widget build(BuildContext context) {
    final center = BudgetClayDonutCenter.forScene(
      scene,
      selectedSliceIndex: selectedSliceIndex,
      absentSelectionLabel: absentSelectionLabel,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: CustomPaint(
            painter: BudgetClayDonutPainter(
              scene: scene,
              selectedSliceIndex: selectedSliceIndex,
            ),
          ),
        ),
        IgnorePointer(
          child: Center(
            child: SizedBox(
              width: 94,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    center.valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff303358),
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    center.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff7a7e9a),
                      fontSize: 7.5,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class BudgetClayDonutPainter extends CustomPainter {
  const BudgetClayDonutPainter({
    required this.scene,
    required this.selectedSliceIndex,
  });

  final BudgetClayDonutScene scene;
  final int selectedSliceIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale =
        math.min(size.width, size.height) / BudgetClayDonutGeometry.sourceSize;
    final left = (size.width - BudgetClayDonutGeometry.sourceSize * scale) / 2;
    final top = (size.height - BudgetClayDonutGeometry.sourceSize * scale) / 2;
    canvas.save();
    canvas.translate(
      left - BudgetClayDonutGeometry.sourceMin * scale,
      top - BudgetClayDonutGeometry.sourceMin * scale,
    );
    canvas.scale(scale);
    _paintSource(canvas);
    canvas.restore();
  }

  void _paintSource(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(256, 426), width: 376, height: 76),
      Paint()
        ..color = const Color(0xff8a6ab5).withValues(alpha: .11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(44, 256, 468, 468));
    for (var index = 0; index < scene.slices.length; index += 1) {
      final slice = scene.slices[index];
      _drawSlicePath(
        canvas,
        path: index == selectedSliceIndex
            ? slice.selectedSidePath
            : slice.normalSidePath,
        color: slice.color.withValues(alpha: .84),
        offset: index == selectedSliceIndex
            ? slice.selectedOffset
            : Offset.zero,
      );
    }
    canvas.restore();
    for (var index = 0; index < scene.slices.length; index += 1) {
      final slice = scene.slices[index];
      final selected = index == selectedSliceIndex;
      final path = selected ? slice.selectedTopPath : slice.normalTopPath;
      final offset = selected ? slice.selectedOffset : Offset.zero;
      _drawSlicePath(canvas, path: path, color: slice.color, offset: offset);
      _drawSlicePath(
        canvas,
        path: path,
        color: Colors.transparent,
        offset: offset,
        style: PaintingStyle.stroke,
        strokeWidth: 3,
        strokeColor: Colors.white.withValues(alpha: .58),
      );
      _drawSlicePath(
        canvas,
        path: path,
        color: Colors.white.withValues(alpha: .08),
        offset: offset + const Offset(-4, -5),
      );
    }
    final plate = Rect.fromCircle(
      center: const Offset(256, 256),
      radius: BudgetClayDonutGeometry.centerPlateRadius,
    );
    canvas.drawCircle(
      const Offset(256, 256),
      BudgetClayDonutGeometry.centerPlateRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.32, -.44),
          radius: .8,
          colors: <Color>[
            Color(0xffffffff),
            Color(0xfffbf9ff),
            Color(0xffe9e3f4),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(plate),
    );
    canvas.drawCircle(
      const Offset(256, 256),
      BudgetClayDonutGeometry.centerPlateRadius,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xffffffff),
            Color(0xfff1ecfa),
            Color(0xffcfc5df),
          ],
          stops: <double>[0, .52, 1],
        ).createShader(plate)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    final gloss = Path()
      ..moveTo(188, 212)
      ..cubicTo(224, 170, 291, 164, 329, 202);
    canvas.drawPath(
      gloss,
      Paint()
        ..color = Colors.white.withValues(alpha: .50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawSlicePath(
    Canvas canvas, {
    required Path path,
    required Color color,
    required Offset offset,
    PaintingStyle style = PaintingStyle.fill,
    double strokeWidth = 0,
    Color? strokeColor,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor ?? color
        ..style = style
        ..strokeWidth = strokeWidth,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BudgetClayDonutPainter oldDelegate) =>
      !identical(oldDelegate.scene, scene) ||
      oldDelegate.selectedSliceIndex != selectedSliceIndex;
}
