import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/financial_limits/presentation/budget_ring_presentation.dart';
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

/// Paint-ready data for the shared SUM/MONTH semicircle hero.
///
/// `rawRatio` is intentionally preserved for the KPI label while
/// `visualProgress` follows the explicit 0–120% scale. Nothing inside the
/// painter performs category lookup, repository reads, or health resolution.
@immutable
final class BudgetSemicircleMaterialPresentation {
  factory BudgetSemicircleMaterialPresentation.resolve({
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
    final segmentedMaterial = BudgetClayActiveMaterial(
      colors: progressMaterial.colors,
      depthColors: _depthStops(progressMaterial.colors),
      stops: progressMaterial.stops,
      markerMaterial: BudgetProgressRingSphereMaterial.forHealthColor(
        markerColor,
      ),
    );
    final fixedHealthy = BudgetHealthyVisualColorResolver.resolve(
      mode: BudgetHealthyColorMode.fixedGreen,
      targetAccent: active[1],
      fixedGreen: FluviVisualTokens.budgetProgressHealthy,
    );
    final accentHealthy = BudgetHealthyVisualColorResolver.resolve(
      mode: BudgetHealthyColorMode.targetAccent,
      targetAccent: active[1],
      fixedGreen: FluviVisualTokens.budgetProgressHealthy,
    );
    return BudgetSemicircleMaterialPresentation._(
      rawRatio: safeRaw,
      visualProgress: visualProgress,
      targetProgress: targetProgress,
      health: health,
      activeGradient: active,
      progressGradient: segmentedMaterial.colors,
      progressDepthGradient: segmentedMaterial.depthColors,
      progressStops: segmentedMaterial.stops,
      markerMaterial: segmentedMaterial.markerMaterial,
      segmentedMaterial: segmentedMaterial,
      solidFixedGreenMaterial: _solidMaterial(
        _solidHealthColor(health: health, healthy: fixedHealthy),
      ),
      solidTargetAccentMaterial: _solidMaterial(
        _solidHealthColor(health: health, healthy: accentHealthy),
      ),
      overshootZones: List<BudgetClayGaugeOvershootZone>.unmodifiable(zones),
      hasVisualOverflow: safeRaw > visualMaximum,
    );
  }

  const BudgetSemicircleMaterialPresentation._({
    required this.rawRatio,
    required this.visualProgress,
    required this.targetProgress,
    required this.health,
    required this.activeGradient,
    required this.progressGradient,
    required this.progressDepthGradient,
    required this.progressStops,
    required this.markerMaterial,
    required this.segmentedMaterial,
    required this.solidFixedGreenMaterial,
    required this.solidTargetAccentMaterial,
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
  final BudgetClayActiveMaterial segmentedMaterial;
  final BudgetClayActiveMaterial solidFixedGreenMaterial;
  final BudgetClayActiveMaterial solidTargetAccentMaterial;
  final List<BudgetClayGaugeOvershootZone> overshootZones;
  final bool hasVisualOverflow;

  /// Selecting a material is a prepared-object lookup: no semantic health,
  /// category palette, or shader-stop work happens in the painter hot path.
  BudgetClayActiveMaterial materialFor({
    required BudgetProgressColorPresentation presentation,
    required BudgetHealthyColorMode healthyColorMode,
  }) => switch (presentation) {
    BudgetProgressColorPresentation.segmentedScale => segmentedMaterial,
    BudgetProgressColorPresentation.solidHealth => switch (healthyColorMode) {
      BudgetHealthyColorMode.fixedGreen => solidFixedGreenMaterial,
      BudgetHealthyColorMode.targetAccent => solidTargetAccentMaterial,
    },
  };

  bool sameVisualAs(BudgetSemicircleMaterialPresentation other) =>
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
      segmentedMaterial.sameVisualAs(other.segmentedMaterial) &&
      solidFixedGreenMaterial.sameVisualAs(other.solidFixedGreenMaterial) &&
      solidTargetAccentMaterial.sameVisualAs(other.solidTargetAccentMaterial) &&
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

  static Color _solidHealthColor({
    required BudgetClayGaugeHealth health,
    required Color healthy,
  }) => switch (health) {
    BudgetClayGaugeHealth.expenseHealthy ||
    BudgetClayGaugeHealth.incomeBelowTarget => healthy,
    BudgetClayGaugeHealth.expenseWarning =>
      FluviVisualTokens.budgetProgressWarning,
    BudgetClayGaugeHealth.expenseDanger =>
      FluviVisualTokens.budgetProgressDanger,
    BudgetClayGaugeHealth.incomeTargetReached => const Color(0xFF14B8A6),
    BudgetClayGaugeHealth.incomeExceededTarget => const Color(0xFF22C55E),
  };

  static BudgetClayActiveMaterial _solidMaterial(Color base) =>
      BudgetClayActiveMaterial.forSemanticBase(base);
}

/// One resolved Fluvi Budget clay-material family.
///
/// The semantic presentation resolves this before paint. It is intentionally
/// independent from semicircle geometry: SUM/MONTH use it for an active arc,
/// while YEAR uses the same light/body/depth family for delta capsules.
/// A solid semantic state still has highlight, body, depth and a matching
/// sphere; it is never a flat stroke.
@immutable
final class BudgetClayActiveMaterial {
  const BudgetClayActiveMaterial({
    required this.colors,
    required this.depthColors,
    required this.stops,
    required this.markerMaterial,
  });

  factory BudgetClayActiveMaterial.forSemanticBase(Color base) {
    final colors = List<Color>.unmodifiable(<Color>[
      Color.lerp(base, Colors.white, .32)!,
      base,
      Color.lerp(base, const Color(0xFF172554), .18)!,
    ]);
    final depthColors = List<Color>.unmodifiable(
      colors
          .map((color) => Color.lerp(color, const Color(0xFF172554), .36)!)
          .toList(growable: false),
    );
    return BudgetClayActiveMaterial(
      colors: colors,
      depthColors: depthColors,
      stops: const <double>[0, .5, 1],
      markerMaterial: BudgetProgressRingSphereMaterial.forHealthColor(base),
    );
  }

  final List<Color> colors;
  final List<Color> depthColors;
  final List<double> stops;
  final BudgetProgressRingSphereMaterial markerMaterial;

  bool sameVisualAs(BudgetClayActiveMaterial other) =>
      listEquals(colors, other.colors) &&
      listEquals(depthColors, other.depthColors) &&
      listEquals(stops, other.stops) &&
      markerMaterial.base == other.markerMaterial.base &&
      markerMaterial.highlight == other.markerMaterial.highlight &&
      markerMaterial.body == other.markerMaterial.body &&
      markerMaterial.depth == other.markerMaterial.depth;
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

/// The one shared material primitive for every Budget analysis semicircle.
/// Its upper-half hero geometry and marker are shared by SUM and MONTH.
enum BudgetSemicircleMaterialLayout { sumHero }

final class BudgetSemicircleMaterial extends StatelessWidget {
  const BudgetSemicircleMaterial({
    super.key,
    required this.presentation,
    required this.activeMaterial,
    required this.progress,
    required this.layout,
    required this.showNeutralTrack,
    required this.showNeutralDecorativeStrip,
    required this.showActiveProgressDecorativeStrip,
    required this.showMarker,
    required this.child,
  });

  final BudgetSemicircleMaterialPresentation presentation;
  final BudgetClayActiveMaterial activeMaterial;
  final double progress;
  final BudgetSemicircleMaterialLayout layout;
  final bool showNeutralTrack;
  final bool showNeutralDecorativeStrip;
  final bool showActiveProgressDecorativeStrip;
  final bool showMarker;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _BudgetSemicircleMaterialPainter(
        presentation: presentation,
        activeMaterial: activeMaterial,
        progress: progress,
        layout: layout,
        showNeutralTrack: showNeutralTrack,
        showNeutralDecorativeStrip: showNeutralDecorativeStrip,
        showActiveProgressDecorativeStrip: showActiveProgressDecorativeStrip,
        showMarker: showMarker,
      ),
      child: child,
    ),
  );
}

/// Binds the two session presentation preferences immediately above the one
/// repaintable material scene. Semantic colour resolution and financial
/// presentation stay outside this subtree, so a switch tap is paint-only.
final class BudgetSemicircleMaterialPreferences extends StatelessWidget {
  const BudgetSemicircleMaterialPreferences({
    super.key,
    required this.presentation,
    required this.progress,
    required this.layout,
    required this.showMarker,
    required this.child,
  });

  final BudgetSemicircleMaterialPresentation presentation;
  final double progress;
  final BudgetSemicircleMaterialLayout layout;
  final bool showMarker;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = BudgetRingPresentationScope.settingsOf(context);
    return BudgetSemicircleMaterial(
      presentation: presentation,
      activeMaterial: presentation.materialFor(
        presentation: settings.progressColorPresentation,
        healthyColorMode: settings.healthyColorMode,
      ),
      progress: progress,
      layout: layout,
      showNeutralTrack: settings.showBudgetNeutralTrack,
      showNeutralDecorativeStrip: settings.showBudgetNeutralDecorativeStrip,
      showActiveProgressDecorativeStrip:
          settings.showBudgetActiveProgressDecorativeStrip,
      showMarker: showMarker,
      child: child,
    );
  }
}

/// One shared SUM/MONTH hero. Semantic frame publication remains immediate,
/// while only the painted active extent and marker make a short visual sweep
/// between already-accepted values. No card opacity or data value animates.
final class BudgetSemicircleGauge extends StatefulWidget {
  const BudgetSemicircleGauge({
    super.key,
    required this.presentation,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final BudgetSemicircleMaterialPresentation presentation;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  State<BudgetSemicircleGauge> createState() => _BudgetSemicircleGaugeState();
}

final class _BudgetSemicircleGaugeState extends State<BudgetSemicircleGauge>
    with SingleTickerProviderStateMixin {
  static const _motionDuration = Duration(milliseconds: 320);

  late final AnimationController _motion;
  late final Animation<double> _curve;
  late double _fromProgress;
  late double _toProgress;

  @override
  void initState() {
    super.initState();
    // The first exact frame paints at its target immediately. Motion belongs
    // only to a subsequent semantic replacement of something already visible.
    _fromProgress = widget.presentation.visualProgress;
    _toProgress = widget.presentation.visualProgress;
    _motion = AnimationController(vsync: this, duration: _motionDuration)
      ..value = 1;
    _curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant BudgetSemicircleGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.presentation.visualProgress;
    if (next == _toProgress) return;

    // Retarget from the scalar actually on screen, not the last semantic
    // value. Rapid period/avatar navigation therefore has no visual snap.
    _fromProgress = _visibleProgress;
    _toProgress = next;
    _motion.forward(from: 0);
  }

  double get _visibleProgress =>
      lerpDouble(_fromProgress, _toProgress, _curve.value)!;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${widget.primaryLabel}, ${widget.secondaryLabel}',
    child: AnimatedBuilder(
      animation: _motion,
      child: _GaugeTextLayer(
        primaryLabel: widget.primaryLabel,
        secondaryLabel: widget.secondaryLabel,
      ),
      builder: (context, textLayer) => BudgetSemicircleMaterialPreferences(
        presentation: widget.presentation,
        progress: _visibleProgress,
        layout: BudgetSemicircleMaterialLayout.sumHero,
        showMarker: true,
        child: textLayer!,
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final geometry = BudgetSemicircleMaterialGeometry.resolve(
        constraints.biggest,
        layout: BudgetSemicircleMaterialLayout.sumHero,
      );
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            // The track preserves the upper-half avatar-ring optical centre;
            // its interior is intentionally the shared white Card2 surface.
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
          _EndpointLabel(
            key: const ValueKey<String>('budget-semicircle-left-endpoint'),
            label: '0%',
            center: geometry.leftEndpoint,
            top: geometry.endpointLabelTop,
          ),
          _EndpointLabel(
            key: const ValueKey<String>('budget-semicircle-right-endpoint'),
            label: '100%+',
            center: geometry.rightEndpoint,
            top: geometry.endpointLabelTop,
          ),
        ],
      );
    },
  );
}

final class _EndpointLabel extends StatelessWidget {
  const _EndpointLabel({
    super.key,
    required this.label,
    required this.center,
    required this.top,
  });

  final String label;
  final Offset center;
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    left: center.dx,
    top: top,
    child: FractionalTranslation(
      translation: const Offset(-.5, 0),
      child: ExcludeSemantics(child: Text(label, style: _endpointStyle)),
    ),
  );
}

const _endpointStyle = TextStyle(
  color: FluviVisualTokens.textSecondary,
  fontSize: 8.2,
  fontWeight: FontWeight.w700,
  height: 1,
);

@immutable
final class BudgetSemicircleMaterialGeometry {
  factory BudgetSemicircleMaterialGeometry.resolve(
    Size size, {
    required BudgetSemicircleMaterialLayout layout,
  }) {
    final source = BudgetProgressRingGeometry.source;
    // SUM and MONTH resolve this exact same hero geometry. The source avatar
    // ring owns every material proportion; scope adapters only supply data.
    // This is the canonical viewport used by SUM and MONTH. The Card2 layout
    // always reserves its footer lane, so this geometry never receives extra
    // height merely because the optional KPI cards are hidden.
    final center = Offset(size.width / 2, size.height * .78);
    final topInset = math.max(5 * (size.width / source.viewport.width), 4.0);
    final outerTrackRatio = 1 + source.trackWidth / (2 * source.trackRadius);
    final radius = math.min(
      size.width * .38,
      math.max(0.0, (center.dy - topInset) / outerTrackRatio),
    );
    final scale = radius / source.trackRadius;
    final trackRect = Rect.fromCircle(center: center, radius: radius);
    return BudgetSemicircleMaterialGeometry._(
      trackRect: trackRect,
      scale: scale,
      stroke: source.trackWidth * scale,
      markerRadius: BudgetProgressRingDayPaceMarkers.markerRadius * scale,
    );
  }

  const BudgetSemicircleMaterialGeometry._({
    required this.trackRect,
    required this.scale,
    required this.stroke,
    required this.markerRadius,
  });

  final Rect trackRect;
  final double scale;
  final double stroke;
  final double markerRadius;

  double get trackRadius => trackRect.width / 2;
  double get activeStripWidth => stroke * .46;
  double get decorativeStripWidth => 5 * scale;
  Offset get leftEndpoint => Offset(trackRect.left, trackRect.center.dy);
  Offset get rightEndpoint => Offset(trackRect.right, trackRect.center.dy);
  double get endpointLabelTop =>
      trackRect.center.dy + math.max(stroke * .5, markerRadius) + 3 * scale;
}

/// Multi-pass clay material renderer. Paint receives only prepared immutable
/// values and contains no semantic lookup or gradient-list construction.
final class _BudgetSemicircleMaterialPainter extends CustomPainter {
  const _BudgetSemicircleMaterialPainter({
    required this.presentation,
    required this.activeMaterial,
    required this.progress,
    required this.layout,
    required this.showNeutralTrack,
    required this.showNeutralDecorativeStrip,
    required this.showActiveProgressDecorativeStrip,
    required this.showMarker,
  });

  static const _startAngle = math.pi;
  static const _sweepAngle = math.pi;
  static const _neutralDecorativeStripStart = .5;

  final BudgetSemicircleMaterialPresentation presentation;
  final BudgetClayActiveMaterial activeMaterial;
  final double progress;
  final BudgetSemicircleMaterialLayout layout;
  final bool showNeutralTrack;
  final bool showNeutralDecorativeStrip;
  final bool showActiveProgressDecorativeStrip;
  final bool showMarker;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final geometry = BudgetSemicircleMaterialGeometry.resolve(
      size,
      layout: layout,
    );
    // The arcs themselves already have π sweep, so no painter-wide horizontal
    // clip or full-circle interior is needed. Card2's white physical surface
    // is the gauge interior; its outer rounded clip owns the final boundary.
    if (showNeutralTrack) {
      _paintCastShadow(canvas, geometry);
      _paintRearDepth(canvas, geometry);
      _paintNeutralTrackBody(canvas, geometry);
      if (showNeutralDecorativeStrip) {
        _paintNeutralDecorativeStrip(canvas, geometry);
      }
    }
    _paintActiveBody(canvas, geometry);
    if (showNeutralTrack) {
      _paintInnerShadow(canvas, geometry);
    }
    if (showMarker) {
      _paintMarkerShadow(canvas, geometry);
      _paintMarker(canvas, geometry);
    }
  }

  void _paintCastShadow(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    final source = BudgetProgressRingGeometry.source;
    // Only the physical semicircle track casts a shadow. A face-sized oval
    // would recreate a second full-circle object on the shared white surface.
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

  void _paintRearDepth(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
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

  void _paintNeutralTrackBody(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
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

  void _paintNeutralDecorativeStrip(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    // This is the selected-avatar ring's embedded neutral decoration, not a
    // free-floating hero-only gloss. It lives across the authored right half
    // of the neutral body; the active material is painted afterwards and
    // therefore physically covers the same lane as progress advances.
    canvas.drawArc(
      geometry.trackRect,
      _startAngle + _sweepAngle * _neutralDecorativeStripStart,
      _sweepAngle * (1 - _neutralDecorativeStripStart),
      false,
      _neutralDecorativeStripPaint(geometry),
    );
  }

  void _paintActiveBody(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    if (progress <= 0) return;
    _paintContinuousMaterial(canvas, geometry);
  }

  void _paintInnerShadow(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
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

  void _paintContinuousMaterial(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    final sweep = _sweepAngle * progress;
    // The active colour is a strip nested in the neutral avatar-ring body,
    // rather than a second full-width tube that replaces that body. One
    // global SweepGradient keeps the category, warning, and danger material
    // continuous even when the semantic state crosses a threshold.
    final stripWidth = geometry.activeStripWidth;
    canvas.drawArc(
      geometry.trackRect.shift(Offset(0, 5 * geometry.scale)),
      _startAngle,
      sweep,
      false,
      _progressPaint(
        geometry: geometry,
        colors: activeMaterial.depthColors,
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
        colors: activeMaterial.colors,
        stroke: stripWidth,
      ),
    );
    if (showActiveProgressDecorativeStrip) {
      canvas.drawArc(
        geometry.trackRect,
        _startAngle,
        sweep,
        false,
        _decorativeStripPaint(geometry),
      );
    }
  }

  Paint _decorativeStripPaint(
    BudgetSemicircleMaterialGeometry geometry,
  ) => Paint()
    // Same embedded progress-gloss cross-section as the selected avatar ring.
    ..color = const Color(0x3DFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = geometry.decorativeStripWidth
    ..strokeCap = StrokeCap.round;

  Paint _neutralDecorativeStripPaint(
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    final source = BudgetProgressRingGeometry.source;
    return Paint()
      ..color = source.trackGlossColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.decorativeStripWidth
      ..strokeCap = StrokeCap.round;
  }

  Paint _progressPaint({
    required BudgetSemicircleMaterialGeometry geometry,
    required List<Color> colors,
    required double stroke,
  }) => Paint()
    ..shader = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepAngle,
      colors: colors,
      stops: activeMaterial.stops,
    ).createShader(geometry.trackRect)
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;

  Offset _markerCenter(BudgetSemicircleMaterialGeometry geometry) {
    final angle = _startAngle + _sweepAngle * progress;
    return Offset(
      geometry.trackRect.center.dx +
          math.cos(angle) * geometry.trackRect.width / 2,
      geometry.trackRect.center.dy +
          math.sin(angle) * geometry.trackRect.height / 2,
    );
  }

  void _paintMarkerShadow(
    Canvas canvas,
    BudgetSemicircleMaterialGeometry geometry,
  ) {
    final center = _markerCenter(geometry);
    final radius = geometry.markerRadius;
    canvas.drawCircle(
      center + Offset(0, 2 * geometry.scale),
      radius,
      Paint()
        ..color = activeMaterial.markerMaterial.depth.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * geometry.scale),
    );
    if (presentation.hasVisualOverflow) {
      canvas.drawCircle(
        center,
        radius * 1.32,
        Paint()
          ..color = activeMaterial.markerMaterial.body.withValues(alpha: .20)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            3.5 * geometry.scale,
          ),
      );
    }
  }

  void _paintMarker(Canvas canvas, BudgetSemicircleMaterialGeometry geometry) {
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
            activeMaterial.markerMaterial.highlight,
            activeMaterial.markerMaterial.body,
            activeMaterial.markerMaterial.depth,
          ],
          stops: const <double>[0, .42, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      center + Offset(-2.5 * geometry.scale, -3 * geometry.scale),
      2.2 * geometry.scale,
      Paint()..color = activeMaterial.markerMaterial.highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetSemicircleMaterialPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      layout != oldDelegate.layout ||
      showNeutralTrack != oldDelegate.showNeutralTrack ||
      showNeutralDecorativeStrip != oldDelegate.showNeutralDecorativeStrip ||
      showActiveProgressDecorativeStrip !=
          oldDelegate.showActiveProgressDecorativeStrip ||
      showMarker != oldDelegate.showMarker ||
      !presentation.sameVisualAs(oldDelegate.presentation) ||
      !activeMaterial.sameVisualAs(oldDelegate.activeMaterial);
}
