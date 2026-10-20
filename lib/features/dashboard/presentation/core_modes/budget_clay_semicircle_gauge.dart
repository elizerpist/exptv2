import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_target.dart';
import '../../query/domain/ledger_direction.dart';

/// The direction-aware state is decided before paint. The painter deliberately
/// has no financial or income/expense policy branches.
enum BudgetClayGaugeHealth {
  expenseHealthy,
  expenseWarning,
  expenseDanger,
  incomeBelowTarget,
  incomeTargetReached,
  incomeExceededTarget,
}

abstract final class BudgetClayGaugeHealthResolver {
  static BudgetClayGaugeHealth resolve({
    required LedgerDirection direction,
    required double rawRatio,
  }) {
    final ratio = rawRatio.isFinite ? math.max(0.0, rawRatio).toDouble() : 0.0;
    return switch (direction) {
      LedgerDirection.expense when ratio > 1.10 =>
        BudgetClayGaugeHealth.expenseDanger,
      LedgerDirection.expense when ratio > 1 =>
        BudgetClayGaugeHealth.expenseWarning,
      LedgerDirection.expense => BudgetClayGaugeHealth.expenseHealthy,
      LedgerDirection.income when ratio > 1.10 =>
        BudgetClayGaugeHealth.incomeExceededTarget,
      LedgerDirection.income when ratio >= 1 =>
        BudgetClayGaugeHealth.incomeTargetReached,
      LedgerDirection.income => BudgetClayGaugeHealth.incomeBelowTarget,
    };
  }
}

/// Immutable one-zone material prepared by the semantic presentation layer.
@immutable
final class BudgetClayGaugeOvershootZone {
  const BudgetClayGaugeOvershootZone({
    required this.start,
    required this.end,
    required this.colors,
    required this.depthColors,
    required this.highlight,
  });

  final double start;
  final double end;
  final List<Color> colors;
  final List<Color> depthColors;
  final Color highlight;

  bool sameVisualAs(BudgetClayGaugeOvershootZone other) =>
      start == other.start &&
      end == other.end &&
      listEquals(colors, other.colors) &&
      listEquals(depthColors, other.depthColors) &&
      highlight == other.highlight;
}

/// Paint-ready data for [BudgetClaySemicircleGauge].
///
/// `rawRatio` is intentionally preserved for the KPI label while
/// `visualProgress` follows the explicit 0–120% scale. Nothing inside the
/// painter performs category lookup, repository reads, or health resolution.
@immutable
final class BudgetClayGaugePresentation {
  factory BudgetClayGaugePresentation.resolve({
    required double rawRatio,
    required LedgerDirection direction,
    required List<Color> activeGradient,
  }) {
    final safeRaw = rawRatio.isFinite
        ? math.max(0.0, rawRatio).toDouble()
        : 0.0;
    const visualMaximum = 1.20;
    final visualProgress = (safeRaw / visualMaximum).clamp(0.0, 1.0).toDouble();
    const targetProgress = 1 / visualMaximum;
    final active = _threeStops(activeGradient);
    final progressMaterial = _progressMaterial(
      direction: direction,
      active: active,
      targetProgress: targetProgress,
    );
    final health = BudgetClayGaugeHealthResolver.resolve(
      direction: direction,
      rawRatio: safeRaw,
    );
    final zones = <BudgetClayGaugeOvershootZone>[];
    if (safeRaw > 1) {
      if (direction == LedgerDirection.expense) {
        const warningEnd = 1.10 / visualMaximum;
        final visibleWarningEnd = math.min(visualProgress, warningEnd);
        if (visibleWarningEnd > targetProgress) {
          zones.add(
            _zone(
              start: targetProgress,
              end: visibleWarningEnd,
              colors: const <Color>[
                Color(0xFFF59E0B),
                Color(0xFFFB923C),
                Color(0xFFF97316),
              ],
            ),
          );
        }
        if (visualProgress > warningEnd) {
          zones.add(
            _zone(
              start: warningEnd,
              end: visualProgress,
              colors: const <Color>[
                Color(0xFFEF4444),
                Color(0xFFFB7185),
                Color(0xFFDC2626),
              ],
            ),
          );
        }
      } else {
        zones.add(
          _zone(
            start: targetProgress,
            end: visualProgress,
            colors: const <Color>[
              Color(0xFF14B8A6),
              Color(0xFF22C55E),
              Color(0xFF38BDF8),
            ],
          ),
        );
      }
    }
    final markerColor = _colorAt(
      colors: progressMaterial.colors,
      stops: progressMaterial.stops,
      position: visualProgress,
    );
    return BudgetClayGaugePresentation._(
      rawRatio: safeRaw,
      visualProgress: visualProgress,
      targetProgress: targetProgress,
      health: health,
      activeGradient: active,
      progressGradient: progressMaterial.colors,
      progressDepthGradient: _depthStops(progressMaterial.colors),
      progressStops: progressMaterial.stops,
      markerMaterial: BudgetProgressRingSphereMaterial.forHealthColor(
        markerColor,
      ),
      overshootZones: List<BudgetClayGaugeOvershootZone>.unmodifiable(zones),
      hasVisualOverflow: safeRaw > visualMaximum,
    );
  }

  const BudgetClayGaugePresentation._({
    required this.rawRatio,
    required this.visualProgress,
    required this.targetProgress,
    required this.health,
    required this.activeGradient,
    required this.progressGradient,
    required this.progressDepthGradient,
    required this.progressStops,
    required this.markerMaterial,
    required this.overshootZones,
    required this.hasVisualOverflow,
  });

  final double rawRatio;
  final double visualProgress;
  final double targetProgress;
  final BudgetClayGaugeHealth health;
  final List<Color> activeGradient;

  /// One global material ramp spans the entire semicircle. The normal target,
  /// warning, and danger semantics still exist, but no longer paint as
  /// separately glued-on arc segments.
  final List<Color> progressGradient;
  final List<Color> progressDepthGradient;
  final List<double> progressStops;

  /// This is deliberately the exact selected-avatar sphere material rather
  /// than a SUM-only marker treatment.
  final BudgetProgressRingSphereMaterial markerMaterial;
  final List<BudgetClayGaugeOvershootZone> overshootZones;
  final bool hasVisualOverflow;

  bool sameVisualAs(BudgetClayGaugePresentation other) =>
      rawRatio == other.rawRatio &&
      visualProgress == other.visualProgress &&
      targetProgress == other.targetProgress &&
      health == other.health &&
      listEquals(activeGradient, other.activeGradient) &&
      listEquals(progressGradient, other.progressGradient) &&
      listEquals(progressDepthGradient, other.progressDepthGradient) &&
      listEquals(progressStops, other.progressStops) &&
      markerMaterial.base == other.markerMaterial.base &&
      markerMaterial.highlight == other.markerMaterial.highlight &&
      markerMaterial.body == other.markerMaterial.body &&
      markerMaterial.depth == other.markerMaterial.depth &&
      hasVisualOverflow == other.hasVisualOverflow &&
      overshootZones.length == other.overshootZones.length &&
      _sameZones(overshootZones, other.overshootZones);

  static bool _sameZones(
    List<BudgetClayGaugeOvershootZone> left,
    List<BudgetClayGaugeOvershootZone> right,
  ) {
    for (var index = 0; index < left.length; index += 1) {
      if (!left[index].sameVisualAs(right[index])) return false;
    }
    return true;
  }

  static BudgetClayGaugeOvershootZone _zone({
    required double start,
    required double end,
    required List<Color> colors,
  }) {
    final material = _threeStops(colors);
    return BudgetClayGaugeOvershootZone(
      start: start,
      end: end,
      colors: material,
      depthColors: _depthStops(material),
      highlight: _highlightFor(material.first),
    );
  }

  static List<Color> _threeStops(List<Color> source) {
    assert(source.length >= 2);
    final start = source.first;
    final middle = source.length > 2
        ? source[source.length ~/ 2]
        : Color.lerp(start, source.last, .5)!;
    return List<Color>.unmodifiable(<Color>[start, middle, source.last]);
  }

  static List<Color> _depthStops(List<Color> source) =>
      List<Color>.unmodifiable(
        source
            .map((color) => Color.lerp(color, const Color(0xFF172554), .36)!)
            .toList(growable: false),
      );

  static _BudgetClayGaugeProgressMaterial _progressMaterial({
    required LedgerDirection direction,
    required List<Color> active,
    required double targetProgress,
  }) {
    // This is the same continuous-health-scale idea used by the selected
    // avatar SUM ring, projected onto the explicit 0–120% hero scale. The
    // half-window makes each semantic boundary blend through its midpoint
    // instead of exposing a hard orange/red seam.
    const transitionHalfWidth =
        BudgetProgressRingSumHealthScale.transitionHalfWidth * (2 / 3);
    const warningProgress = 1.10 / 1.20;
    final normalBlendStart = targetProgress - transitionHalfWidth;
    final normalBlendEnd = targetProgress + transitionHalfWidth;
    if (direction == LedgerDirection.income) {
      const reached = Color(0xFF14B8A6);
      const exceeded = Color(0xFF22C55E);
      return _BudgetClayGaugeProgressMaterial(
        colors: List<Color>.unmodifiable(<Color>[
          active.first,
          active[1],
          active.last,
          reached,
          exceeded,
        ]),
        stops: List<double>.unmodifiable(<double>[
          0,
          targetProgress * .48,
          normalBlendStart,
          normalBlendEnd,
          1,
        ]),
      );
    }
    return _BudgetClayGaugeProgressMaterial(
      colors: List<Color>.unmodifiable(<Color>[
        active.first,
        active[1],
        active.last,
        FluviVisualTokens.budgetProgressWarning,
        FluviVisualTokens.budgetProgressWarning,
        FluviVisualTokens.budgetProgressDanger,
        FluviVisualTokens.budgetProgressDanger,
      ]),
      stops: List<double>.unmodifiable(<double>[
        0,
        targetProgress * .48,
        normalBlendStart,
        normalBlendEnd,
        warningProgress - transitionHalfWidth,
        warningProgress + transitionHalfWidth,
        1,
      ]),
    );
  }

  static Color _colorAt({
    required List<Color> colors,
    required List<double> stops,
    required double position,
  }) {
    final value = position.clamp(0.0, 1.0).toDouble();
    for (var index = 1; index < stops.length; index += 1) {
      final end = stops[index];
      if (value > end) continue;
      final start = stops[index - 1];
      final local = (value - start) / (end - start);
      return Color.lerp(colors[index - 1], colors[index], local)!;
    }
    return colors.last;
  }

  static Color _highlightFor(Color color) =>
      Color.lerp(color, Colors.white, .72)!.withValues(alpha: .72);
}

@immutable
final class _BudgetClayGaugeProgressMaterial {
  const _BudgetClayGaugeProgressMaterial({
    required this.colors,
    required this.stops,
  });

  final List<Color> colors;
  final List<double> stops;
}

/// Uses the same category avatar palette source as the selected rail item.
/// This belongs to widget build, not the painter hot path.
abstract final class BudgetClayGaugeAccentResolver {
  static List<Color> resolve(
    BuildContext context, {
    required LedgerDirection direction,
    DashboardBudgetTargetPresentationItem? targetVisual,
  }) {
    final colorId = targetVisual?.colorId;
    if (colorId != null) {
      final token = CategoryAvatarPaletteCatalog.tokenFor(
        CategoryAvatarColorProfileScope.profileOf(context),
        CategoryColorCatalog.handleOf(colorId),
      );
      return token.colors;
    }
    final aggregate = DashboardBudgetAggregateVisual.forDirection(direction);
    final start = targetVisual?.gradientStartArgb ?? aggregate.startColorArgb;
    final middle = targetVisual?.baseColorArgb ?? aggregate.middleColorArgb;
    final end = targetVisual?.gradientEndArgb ?? aggregate.endColorArgb;
    return <Color>[Color(start), Color(middle), Color(end)];
  }
}

/// Isolated animated Canvas scene for the SUM Budget card.
///
/// One controller owns the active body, overshoot, and marker position. Its
/// repaint is contained by the boundary so changing a target cannot repaint
/// the surrounding dashboard card or pager.
final class BudgetClaySemicircleGauge extends StatefulWidget {
  const BudgetClaySemicircleGauge({
    super.key,
    required this.presentation,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final BudgetClayGaugePresentation presentation;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  State<BudgetClaySemicircleGauge> createState() =>
      _BudgetClaySemicircleGaugeState();
}

final class _BudgetClaySemicircleGaugeState
    extends State<BudgetClaySemicircleGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late double _fromProgress;
  late double _toProgress;

  @override
  void initState() {
    super.initState();
    _fromProgress = widget.presentation.visualProgress;
    _toProgress = widget.presentation.visualProgress;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant BudgetClaySemicircleGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.presentation.sameVisualAs(widget.presentation)) {
      _fromProgress = _visibleProgress;
      _toProgress = widget.presentation.visualProgress;
      _progressController.forward(from: 0);
    }
  }

  double get _visibleProgress =>
      Curves.easeOutCubic.transform(_progressController.value) *
          (_toProgress - _fromProgress) +
      _fromProgress;

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Semantics(
      label: '${widget.primaryLabel}, ${widget.secondaryLabel}',
      child: AnimatedBuilder(
        animation: _progressController,
        child: _GaugeTextLayer(
          primaryLabel: widget.primaryLabel,
          secondaryLabel: widget.secondaryLabel,
        ),
        builder: (context, child) => CustomPaint(
          painter: _BudgetClaySemicirclePainter(
            presentation: widget.presentation,
            animatedProgress: _visibleProgress,
          ),
          child: child,
        ),
      ),
    ),
  );
}

final class _GaugeTextLayer extends StatelessWidget {
  const _GaugeTextLayer({
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Align(
        // The face is the clipped upper half of the avatar's white disc, so
        // its optical centre sits above the arc baseline rather than in the
        // geometric centre of this rectangular hero slot.
        alignment: const Alignment(0, 0),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                primaryLabel,
                style: const TextStyle(
                  color: FluviVisualTokens.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                secondaryLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 7.2,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      const Align(
        alignment: Alignment(-.56, .96),
        child: ExcludeSemantics(child: Text('0%', style: _endpointStyle)),
      ),
      const Align(
        alignment: Alignment(.56, .96),
        child: ExcludeSemantics(child: Text('100%+', style: _endpointStyle)),
      ),
    ],
  );
}

const _endpointStyle = TextStyle(
  color: FluviVisualTokens.textSecondary,
  fontSize: 6.5,
  fontWeight: FontWeight.w700,
  height: 1,
);

@immutable
final class _GaugeGeometry {
  factory _GaugeGeometry.resolve(Size size) {
    final source = BudgetProgressRingGeometry.source;
    final labelBand = size.height * .105;
    final center = Offset(size.width / 2, size.height - labelBand);
    // The ring is never fitted into an oval: it is literally a circle whose
    // lower half is clipped. The white face must reach the top of the slot.
    final faceToTrack = source.faceRadius / source.trackRadius;
    final radius = math.min(size.width * .38, center.dy / faceToTrack);
    final scale = radius / source.trackRadius;
    final trackRect = Rect.fromCircle(center: center, radius: radius);
    return _GaugeGeometry._(
      trackRect: trackRect,
      faceRect: Rect.fromCircle(
        center: center,
        radius: source.faceRadius * scale,
      ),
      scale: scale,
      stroke: source.trackWidth * scale,
      markerRadius: BudgetProgressRingDayPaceMarkers.markerRadius * scale,
      clipBottom: center.dy + source.trackWidth * scale * .58,
    );
  }

  const _GaugeGeometry._({
    required this.trackRect,
    required this.faceRect,
    required this.scale,
    required this.stroke,
    required this.markerRadius,
    required this.clipBottom,
  });

  final Rect trackRect;
  final Rect faceRect;
  final double scale;
  final double stroke;
  final double markerRadius;
  final double clipBottom;
}

/// Multi-pass clay material renderer. Paint receives only prepared immutable
/// values and contains no semantic lookup or gradient-list construction.
final class _BudgetClaySemicirclePainter extends CustomPainter {
  const _BudgetClaySemicirclePainter({
    required this.presentation,
    required this.animatedProgress,
  });

  static const _startAngle = math.pi;
  static const _sweepAngle = math.pi;
  static const _gradientStops = <double>[0, .5, 1];

  final BudgetClayGaugePresentation presentation;
  final double animatedProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final geometry = _GaugeGeometry.resolve(size);
    // The lower circle never becomes a second visual component. Clipping here
    // makes this precisely the upper half of the selected avatar ring.
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, geometry.clipBottom));
    _paintCenterMedallion(canvas, geometry);
    _paintCastShadow(canvas, geometry);
    _paintRearDepth(canvas, geometry);
    _paintNeutralTrackBody(canvas, geometry);
    _paintActiveBody(canvas, geometry);
    _paintInnerShadow(canvas, geometry);
    _paintMarkerShadow(canvas, geometry);
    _paintMarker(canvas, geometry);
    canvas.restore();
  }

  void _paintCenterMedallion(Canvas canvas, _GaugeGeometry geometry) {
    final source = BudgetProgressRingGeometry.source;
    canvas.drawCircle(
      geometry.faceRect.center +
          Offset(
            source.faceShadowOffset.dx * geometry.scale,
            source.faceShadowOffset.dy * geometry.scale,
          ),
      geometry.faceRect.width / 2,
      Paint()
        ..color = source.trackShadowColor.withValues(alpha: .20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * geometry.scale),
    );
    canvas.drawCircle(
      geometry.faceRect.center,
      geometry.faceRect.width / 2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.28, -.42),
          radius: .78,
          colors: const <Color>[
            Color(0xFFFFFEFF),
            Color(0xFFFBF9FF),
            Color(0xFFEFEAF8),
          ],
          stops: _gradientStops,
        ).createShader(geometry.faceRect),
    );
    canvas.drawCircle(
      geometry.faceRect.center,
      geometry.faceRect.width / 2,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * geometry.scale,
    );
  }

  void _paintCastShadow(Canvas canvas, _GaugeGeometry geometry) {
    final source = BudgetProgressRingGeometry.source;
    canvas.drawOval(
      Rect.fromCenter(
        center: geometry.faceRect.center + Offset(0, geometry.stroke * .78),
        width: geometry.faceRect.width * .86,
        height: geometry.stroke * 1.1,
      ),
      Paint()
        ..color = source.trackShadowColor.withValues(alpha: .10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * geometry.scale),
    );
    canvas.drawArc(
      geometry.trackRect.shift(Offset(0, 5 * geometry.scale)),
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..color = source.trackShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = geometry.stroke + 4 * geometry.scale
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.5 * geometry.scale),
    );
  }

  void _paintRearDepth(Canvas canvas, _GaugeGeometry geometry) {
    final source = BudgetProgressRingGeometry.source;
    canvas.drawArc(
      geometry.trackRect,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..color = source.trackShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = geometry.stroke + 4 * geometry.scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintNeutralTrackBody(Canvas canvas, _GaugeGeometry geometry) {
    final source = BudgetProgressRingGeometry.source;
    canvas.drawArc(
      geometry.trackRect,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: source.trackGradientColors,
          stops: source.trackGradientStops,
        ).createShader(geometry.trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = geometry.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintActiveBody(Canvas canvas, _GaugeGeometry geometry) {
    if (animatedProgress <= 0) return;
    _paintContinuousMaterial(canvas, geometry);
  }

  void _paintInnerShadow(Canvas canvas, _GaugeGeometry geometry) {
    final inner = geometry.trackRect.deflate(geometry.stroke * .29);
    canvas.drawArc(
      inner,
      _startAngle,
      _sweepAngle,
      false,
      Paint()
        ..color = BudgetProgressRingGeometry.source.trackShadowColor.withValues(
          alpha: .24,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = geometry.stroke * .17
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, geometry.stroke * .08),
    );
  }

  void _paintContinuousMaterial(Canvas canvas, _GaugeGeometry geometry) {
    final sweep = _sweepAngle * animatedProgress;
    // The active colour is a strip nested in the neutral avatar-ring body,
    // rather than a second full-width tube that replaces that body. One
    // global SweepGradient keeps the category, warning, and danger material
    // continuous even when the semantic state crosses a threshold.
    final stripWidth = geometry.stroke * .46;
    canvas.drawArc(
      geometry.trackRect.shift(Offset(0, 5 * geometry.scale)),
      _startAngle,
      sweep,
      false,
      _progressPaint(
        geometry: geometry,
        colors: presentation.progressDepthGradient,
        stroke: stripWidth,
      )..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.5 * geometry.scale),
    );
    canvas.drawArc(
      geometry.trackRect,
      _startAngle,
      sweep,
      false,
      _progressPaint(
        geometry: geometry,
        colors: presentation.progressGradient,
        stroke: stripWidth,
      ),
    );
    canvas.drawArc(
      geometry.trackRect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..color = const Color(0x4DFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * geometry.scale
        ..strokeCap = StrokeCap.round,
    );
  }

  Paint _progressPaint({
    required _GaugeGeometry geometry,
    required List<Color> colors,
    required double stroke,
  }) => Paint()
    ..shader = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepAngle,
      colors: colors,
      stops: presentation.progressStops,
    ).createShader(geometry.trackRect)
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;

  Offset _markerCenter(_GaugeGeometry geometry) {
    final angle = _startAngle + _sweepAngle * animatedProgress;
    return Offset(
      geometry.trackRect.center.dx +
          math.cos(angle) * geometry.trackRect.width / 2,
      geometry.trackRect.center.dy +
          math.sin(angle) * geometry.trackRect.height / 2,
    );
  }

  void _paintMarkerShadow(Canvas canvas, _GaugeGeometry geometry) {
    final center = _markerCenter(geometry);
    final radius = geometry.markerRadius;
    canvas.drawCircle(
      center + Offset(0, 2 * geometry.scale),
      radius,
      Paint()
        ..color = presentation.markerMaterial.depth.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * geometry.scale),
    );
    if (presentation.hasVisualOverflow) {
      canvas.drawCircle(
        center,
        radius * 1.32,
        Paint()
          ..color = presentation.markerMaterial.body.withValues(alpha: .20)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            3.5 * geometry.scale,
          ),
      );
    }
  }

  void _paintMarker(Canvas canvas, _GaugeGeometry geometry) {
    final center = _markerCenter(geometry);
    final radius = geometry.markerRadius;
    final body = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          radius: .9,
          colors: <Color>[
            presentation.markerMaterial.highlight,
            presentation.markerMaterial.body,
            presentation.markerMaterial.depth,
          ],
          stops: const <double>[0, .42, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      center + Offset(-2.5 * geometry.scale, -3 * geometry.scale),
      2.2 * geometry.scale,
      Paint()..color = presentation.markerMaterial.highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetClaySemicirclePainter oldDelegate) =>
      animatedProgress != oldDelegate.animatedProgress ||
      !presentation.sameVisualAs(oldDelegate.presentation);
}
