import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/fluvi_year_clay_capsule_painter.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
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
  });
  final DashboardBalanceDailyInsightsPresentation presentation;
  final DashboardDayRhythmNavigation? navigation;
  @override
  State<BalanceDayMomentumRail> createState() => _BalanceDayMomentumRailState();
}

class _BalanceDayMomentumRailState extends State<BalanceDayMomentumRail> {
  final Map<int, DashboardBalanceDailyMomentumPoint> _points = {};
  List<DashboardBalanceDailyMomentumPoint> _paintPoints = const [];
  @override
  void initState() {
    super.initState();
    _install();
  }

  @override
  void didUpdateWidget(covariant BalanceDayMomentumRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.identity != widget.presentation.identity) {
      _points.clear();
    }
    if (oldWidget.presentation.presentationId !=
        widget.presentation.presentationId) {
      _install();
    }
  }

  void _install() {
    for (final point in widget.presentation.momentum.rhythm) {
      _points[point.epochDay] = point;
    }
    final selected = widget.presentation.momentum.selected.epochDay;
    _points.removeWhere(
      (day, _) => day < selected - 125 || day > selected + 65,
    );
    _paintPoints = List.unmodifiable(_points.values);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final n = widget.navigation;
      Widget visual(int origin, double offset) => _RailVisual(
        points: _paintPoints,
        originEpochDay: origin,
        rawOffset: offset,
      );
      if (n == null) {
        return visual(widget.presentation.momentum.selected.epochDay, 0);
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
        itemExtent: c.maxWidth / 60,
        visibleItemCount: 61,
        onMotionActiveChanged: n.onMotionActiveChanged,
        onDirectInputStarted: n.onDirectInputStarted,
        onPointerDownDecision: n.onPointerDownDecision,
        motionDiagnostics: n.motionDiagnostics,
        coordinator: n.coordinator,
        releaseMotionOnDispose: true,
        visualBuilder: (context, state) {
          // Use the SAME availability/wrapping rule as Summary. A calendar
          // epoch plus an unbounded offset would show the wrong month at wrap.
          final tick = state.rawIndex.round();
          final target =
              n.candidateForOffset(state.origin, tick) ?? state.origin;
          return visual(
            LocalDate(
              year: target.yearCursor,
              month: target.monthCursor.month,
              day: target.dayCursor,
            ).epochDay,
            state.rawIndex - tick,
          );
        },
      );
    },
  );
}

class _RailVisual extends StatelessWidget {
  const _RailVisual({
    required this.points,
    required this.originEpochDay,
    required this.rawOffset,
  });
  final List<DashboardBalanceDailyMomentumPoint> points;
  final int originEpochDay;
  final double rawOffset;
  @override
  Widget build(BuildContext context) => Column(
    children: [
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
