import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/fluvi_year_clay_capsule_painter.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../dashboard_day_rhythm_navigation.dart';
import '../dashboard_summary_presentation.dart';
import '../widgets/dashboard_temporal_component_carousel.dart';
import 'budget_clay_semicircle_gauge.dart';

/// A new physical input surface for the existing temporal selector. All
/// semantic crossings, acceptance and settlement stay in the shared adapter.
final class BalanceDayMomentumRail extends StatefulWidget {
  const BalanceDayMomentumRail({
    super.key,
    required this.presentation,
    this.navigation,
    this.compact = false,
  });
  final DashboardBalanceDailyInsightsPresentation presentation;
  final DashboardDayRhythmNavigation? navigation;
  final bool compact;
  @override
  State<BalanceDayMomentumRail> createState() => _BalanceDayMomentumRailState();
}

class _BalanceDayMomentumRailState extends State<BalanceDayMomentumRail> {
  late BalanceDayMomentumRailWindowController _window;
  @override
  void initState() {
    super.initState();
    _window = BalanceDayMomentumRailWindowController(widget.presentation);
  }

  @override
  void didUpdateWidget(covariant BalanceDayMomentumRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.identity != widget.presentation.identity) {
      _window = BalanceDayMomentumRailWindowController(widget.presentation);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final n = widget.navigation;
      Widget visual(BalanceDayMomentumRailVisualWindow window) =>
          AnimatedSwitcher(
            duration: window.wrapReplacement
                ? const Duration(milliseconds: 120)
                : Duration.zero,
            child: _RailVisual(
              key: ValueKey(window.originEpochDay),
              points: window.points,
              compact: widget.compact,
              originEpochDay: window.originEpochDay,
              rawOffset: window.rawOffset,
            ),
          );
      if (n == null) {
        return visual(
          BalanceDayMomentumRailVisualWindow(
            points: widget.presentation.momentum.rhythm,
            originEpochDay: widget.presentation.momentum.selected.epochDay,
            rawOffset: 0,
          ),
        );
      }
      return DashboardTemporalComponentCarousel(
        key: const ValueKey('balance-day-rhythm-carousel'),
        height: c.maxHeight,
        visualContentOffset: 0,
        navigation: n.navigation,
        semanticsLabel: 'Pénzügyi momentum, napválasztás',
        candidateForOffset: n.candidateForOffset,
        labelForCandidate: (candidate) => '${candidate.dayCursor}',
        onCrossed: n.onCrossed,
        paintedTargets: n.paintedTargets,
        onVisualTargetPainted: n.onVisualTargetPainted,
        onSettled: n.onSettled,
        presentation: SummaryTemporalFlingPresentation.dynamicTrio,
        component: DashboardTemporalAnchorComponent.day,
        scrollDirection: Axis.horizontal,
        itemExtent: n.interactionExtent,
        motionSource: DashboardTemporalMotionSource.balanceRhythm,
        visibleItemCount: 61,
        onMotionActiveChanged: n.onMotionActiveChanged,
        onDirectInputStarted: n.onDirectInputStarted,
        onPointerDownDecision: n.onPointerDownDecision,
        motionDiagnostics: n.motionDiagnostics,
        coordinator: n.coordinator,
        releaseMotionOnDispose: true,
        visualBuilder: (context, state) {
          int epoch(DashboardNavigationState state) => LocalDate(
            year: state.yearCursor,
            month: state.monthCursor.month,
            day: state.dayCursor,
          ).epochDay;
          final motion = n.coordinator?.dayVisualMotion;
          return visual(
            _window.resolve(
              presentation: widget.presentation,
              originEpochDay: epoch(state.origin),
              rawOffset: state.rawIndex,
              isMoving: state.isMoving,
              generation: motion?.generation ?? n.coordinator?.motionEpoch ?? 0,
              acceptedEpochDay: motion?.acceptedTarget == null
                  ? null
                  : epoch(motion!.acceptedTarget!),
            ),
          );
        },
      );
    },
  );
}

/// One coherent prepared window and its purely physical placement.
@immutable
final class BalanceDayMomentumRailVisualWindow {
  const BalanceDayMomentumRailVisualWindow({
    required this.points,
    required this.originEpochDay,
    required this.rawOffset,
    this.wrapReplacement = false,
  });
  final bool wrapReplacement;
  final List<DashboardBalanceDailyMomentumPoint> points;
  final int originEpochDay;
  final double rawOffset;
}

/// Retains paint continuity without calculating or merging financial values.
/// A cyclic semantic day jump never becomes an epoch-distance animation.
final class BalanceDayMomentumRailWindowController {
  BalanceDayMomentumRailWindowController(
    DashboardBalanceDailyInsightsPresentation initial,
  ) : _visual = BalanceDayMomentumRailVisualWindow(
        points: initial.momentum.rhythm,
        originEpochDay: initial.momentum.selected.epochDay,
        rawOffset: 0,
      );
  BalanceDayMomentumRailVisualWindow _visual;
  int _generation = -1;
  bool _inFlight = false;
  bool _preempted = false;
  double _flightBaseOffset = 0;
  BalanceDayMomentumRailVisualWindow resolve({
    required DashboardBalanceDailyInsightsPresentation presentation,
    required int originEpochDay,
    required double rawOffset,
    required bool isMoving,
    required int generation,
    int? acceptedEpochDay,
  }) {
    if (generation < _generation) {
      return _visual;
    }
    if (!isMoving && generation > _generation && _inFlight) {
      _generation = generation;
      _preempted = true;
    }
    if (_preempted && !isMoving) {
      // An exact external month/day navigation may replace the scene after
      // preempting this lane; a cleared old pointer cannot do so by itself.
      if (presentation.momentum.selected.epochDay != originEpochDay) {
        return _visual;
      }
      _preempted = false;
      _inFlight = false;
    }
    if (isMoving) {
      final wasPreempted = _preempted;
      _preempted = false;
      if (!_inFlight || generation != _generation || wasPreempted) {
        // Preserve the currently painted exact window on a new pointer too.
        final initialGeneration = _generation < 0;
        _generation = generation;
        if (initialGeneration) {
          // A follower can mount after Summary has already accepted several
          // ticks. Its prepared window is then ahead of the motion origin.
          // Keep only the current fractional tick around an exact accepted
          // window; otherwise align a retained/intermediate real window to
          // the original continuous coordinate system.
          _flightBaseOffset = _visual.originEpochDay == acceptedEpochDay
              ? -rawOffset.roundToDouble()
              : (originEpochDay - _visual.originEpochDay).toDouble();
        } else {
          _flightBaseOffset = _visual.rawOffset.roundToDouble();
        }
        _inFlight = true;
      }
      final nextRawOffset = _flightBaseOffset + rawOffset;
      final contiguousTarget = _visual.originEpochDay + nextRawOffset.round();
      // A ready contiguous target supplies its entire coherent prepared
      // window, including genuinely entering days. Cyclic/deferred targets
      // retain the old window until the exact idle handoff.
      final points = presentation.momentum.selected.epochDay == contiguousTarget
          ? presentation.momentum.rhythm
          : _visual.points;
      _visual = BalanceDayMomentumRailVisualWindow(
        points: points,
        originEpochDay: _visual.originEpochDay,
        rawOffset: nextRawOffset,
      );
      return _visual;
    }
    _generation = generation;
    final target = acceptedEpochDay ?? originEpochDay;
    if (presentation.momentum.selected.epochDay == target) {
      if (target == _visual.originEpochDay &&
          _visual.rawOffset == 0 &&
          identical(presentation.momentum.rhythm, _visual.points)) {
        return _visual;
      }
      _visual = BalanceDayMomentumRailVisualWindow(
        points: presentation.momentum.rhythm,
        originEpochDay: target,
        rawOffset: 0,
        wrapReplacement:
            _inFlight &&
            (target - (_visual.originEpochDay + _visual.rawOffset.round()))
                    .abs() >
                1,
      );
      _inFlight = false;
    }
    // A cold/rejected target leaves the last complete window in place.
    return _visual;
  }
}

class _RailVisual extends StatelessWidget {
  const _RailVisual({
    super.key,
    required this.points,
    required this.originEpochDay,
    required this.rawOffset,
    this.compact = false,
  });
  final bool compact;
  final List<DashboardBalanceDailyMomentumPoint> points;
  final int originEpochDay;
  final double rawOffset;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (!compact)
        Row(
          children: [
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: const Color(0xfff4f4fc),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 15,
                color: Color(0xff9794bb),
              ),
            ),
            const SizedBox(width: 5),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pénzügyi momentum',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111d52),
                    ),
                  ),
                  Text(
                    'Az elmúlt 60 nap változásai',
                    maxLines: 1,
                    style: TextStyle(fontSize: 7, color: Color(0xff52618c)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xfff5f5fc),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Napi nézet',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff273b69),
                ),
              ),
            ),
          ],
        ),
      Expanded(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('balance-day-rhythm-bars'),
            painter: BalanceDayMomentumRailPainter(
              points: points,
              originEpochDay: originEpochDay,
              rawOffset: rawOffset,
            ),
            size: Size.infinite,
          ),
        ),
      ),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Előző 30 nap',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 7, color: Color(0xff65789f)),
            ),
          ),
          Expanded(
            child: Text(
              'Utolsó 30 nap',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 7, color: Color(0xff65789f)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
    ],
  );
}

/// Only prepared magnitudes are painted. Position depends on epoch-day identity,
/// never list position, so surviving days retain their places during each flight.
final class BalanceDayMomentumRailPainter extends CustomPainter {
  const BalanceDayMomentumRailPainter({
    required this.points,
    required this.originEpochDay,
    required this.rawOffset,
  });
  final List<DashboardBalanceDailyMomentumPoint> points;
  final int originEpochDay;
  final double rawOffset;
  static final _purple = BudgetClayActiveMaterial.forSemanticBase(
    const Color(0xffab64f3),
  );
  static final _teal = BudgetClayActiveMaterial.forSemanticBase(
    const Color(0xff27d4c7),
  );
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 1) return;
    final slot = size.width / 60;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final point in points) {
      final index = point.epochDay - (originEpochDay - 59) - rawOffset;
      final x = (index + .5) * slot;
      if (x < -slot || x > size.width + slot) continue;
      final h = math.max(
        1.0,
        (size.height - 3) * (.12 + point.magnitude * .88),
      );
      final material = x < size.width / 2 ? _purple : _teal;
      FluviYearClayCapsulePainter.paint(
        canvas,
        rect: Rect.fromLTWH(x - slot * .32, size.height - h, slot * .64, h),
        colors: material.colors,
        depthColors: material.depthColors,
        stops: material.stops,
        showDecorativeStrip: true,
      );
    }
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = const Color(0xffcec4e3)
        ..strokeWidth = .8,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BalanceDayMomentumRailPainter oldDelegate) =>
      oldDelegate.rawOffset != rawOffset ||
      oldDelegate.originEpochDay != originEpochDay ||
      oldDelegate.points != points;
}
