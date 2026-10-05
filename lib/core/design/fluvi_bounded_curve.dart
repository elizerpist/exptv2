import 'dart:math' as math;
import 'dart:ui';

/// The consumer-owned constructor for a bounded cubic segment.
typedef FluviCurveSegmentFactory<T> =
    T Function({
      required Offset start,
      required Offset controlOne,
      required Offset controlTwo,
      required Offset end,
      required bool isLinear,
    });

/// Builds cubic controls bounded by each pair of genuine endpoint values.
///
/// The default [controlSpan] preserves Mind Sum's original controls exactly,
/// including floating-point operation order. A wider span rounds a renderer's
/// extrema without changing genuine endpoints or their bounded value range.
/// [create] keeps each consumer's representation; this owns no financial or
/// interaction state.
List<T> fluviBoundedMonotoneSegments<T>(
  List<Offset> points, {
  required FluviCurveSegmentFactory<T> create,
  double controlSpan = 1 / 3,
}) {
  assert(controlSpan > 0 && controlSpan <= .5);
  if (points.length < 2) return <T>[];

  final slopes = List<double>.filled(points.length, 0);
  final segments = List<double>.filled(points.length - 1, 0);
  for (var index = 0; index < segments.length; index += 1) {
    final dx = points[index + 1].dx - points[index].dx;
    segments[index] = dx <= 0
        ? 0
        : (points[index + 1].dy - points[index].dy) / dx;
  }
  slopes[0] = segments.first;
  slopes[slopes.length - 1] = segments.last;
  for (var index = 1; index < slopes.length - 1; index += 1) {
    final previous = segments[index - 1];
    final next = segments[index];
    slopes[index] = previous * next <= 0 ? 0 : (previous + next) / 2;
  }
  return List<T>.generate(points.length - 1, (index) {
    final start = points[index];
    final end = points[index + 1];
    final dx = end.dx - start.dx;
    if (dx <= 0) {
      return create(
        start: start,
        controlOne: start,
        controlTwo: end,
        end: end,
        isLinear: true,
      );
    }
    final lower = math.min(start.dy, end.dy);
    final upper = math.max(start.dy, end.dy);
    final defaultSpan = controlSpan == 1 / 3;
    final handleDx = defaultSpan ? dx / 3 : dx * controlSpan;
    final controlOneY =
        (start.dy +
                (defaultSpan
                    ? slopes[index] * dx / 3
                    : slopes[index] * handleDx))
            .clamp(lower, upper)
            .toDouble();
    final controlTwoY =
        (end.dy -
                (defaultSpan
                    ? slopes[index + 1] * dx / 3
                    : slopes[index + 1] * handleDx))
            .clamp(lower, upper)
            .toDouble();
    return create(
      start: start,
      controlOne: Offset(start.dx + handleDx, controlOneY),
      controlTwo: Offset(end.dx - handleDx, controlTwoY),
      end: end,
      isLinear: false,
    );
  }, growable: false);
}
