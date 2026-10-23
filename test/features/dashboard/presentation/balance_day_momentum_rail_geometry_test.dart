import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_momentum_rail.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

DashboardBalanceDailyInsightsPresentation window(
  LocalDate date, {
  double magnitude = .3,
}) {
  final epoch = date.epochDay;
  DashboardBalanceDailyMomentumPoint point(int day) =>
      DashboardBalanceDailyMomentumPoint(
        epochDay: day,
        currentIncomeMinor: day * 100,
        referenceIncomeMinor: 100,
        currentExpenseMinor: 200,
        referenceExpenseMinor: 100,
        isCurrentHalf: day > epoch - 30,
        incomeAxis: .2,
        expenseAxis: .1,
        magnitude: magnitude,
      );
  return DashboardBalanceDailyInsightsPresentation(
    identity: const DashboardBalancePrimaryIdentity(
      upstreamScopeKey: 'q',
      indexGeneration: 1,
      coreRevision: 1,
    ),
    timeScope: DayScope(date),
    momentum: DashboardBalanceDailyMomentumPresentation(
      available: true,
      selected: point(epoch),
      rhythm: [for (var d = epoch - 59; d <= epoch; d++) point(d)],
    ),
    impact: DashboardBalanceDailyImpactPresentation.unavailable(
      todayNetMinor: 0,
      referenceAverageNetMinor: 0,
    ),
  );
}

void main() {
  for (final pair in [
    (
      const LocalDate(year: 2026, month: 1, day: 31),
      const LocalDate(year: 2026, month: 1, day: 1),
      1.0,
    ),
    (
      const LocalDate(year: 2026, month: 1, day: 1),
      const LocalDate(year: 2026, month: 1, day: 31),
      -1.0,
    ),
    (
      const LocalDate(year: 2024, month: 2, day: 29),
      const LocalDate(year: 2024, month: 2, day: 1),
      1.0,
    ),
  ]) {
    test(
      'wrap ${pair.$1} to ${pair.$2} remains one physical tick until exact idle',
      () {
        final old = window(pair.$1),
            next = window(pair.$2, magnitude: .8),
            resolver = BalanceDayMomentumRailWindowController(window(pair.$1));
        BalanceDayMomentumRailVisualWindow at(
          double q, {
          bool moving = true,
          DashboardBalanceDailyInsightsPresentation? data,
        }) => resolver.resolve(
          presentation: data ?? old,
          originEpochDay: pair.$1.epochDay,
          rawOffset: q * pair.$3,
          isMoving: moving,
          generation: 1,
          acceptedEpochDay: pair.$2.epochDay,
        );
        final before = at(.49), after = at(.51, data: next);
        expect(after.originEpochDay, before.originEpochDay);
        expect(
          after.rawOffset - before.rawOffset,
          closeTo(.02 * pair.$3, 1e-9),
        );
        expect(after.points.every((p) => p.magnitude == .3), isTrue);
        expect(after.points, hasLength(60));
        final waiting = at(1, moving: false);
        expect(waiting.originEpochDay, pair.$1.epochDay);
        final ready = at(1, moving: false, data: next);
        expect(ready.originEpochDay, pair.$2.epochDay);
        expect(ready.rawOffset, 0);
        expect(ready.wrapReplacement, isTrue);
        expect(ready.points.every((p) => p.magnitude == .8), isTrue);
      },
    );
  }
  test('preemption and stale generation cannot reanchor a frozen window', () {
    final old = window(const LocalDate(year: 2026, month: 1, day: 31));
    final next = window(const LocalDate(year: 2026, month: 1, day: 1));
    final resolver = BalanceDayMomentumRailWindowController(old);
    final flight = resolver.resolve(
      presentation: old,
      originEpochDay: old.momentum.selected.epochDay,
      rawOffset: .7,
      isMoving: true,
      generation: 4,
    );
    final preempted = resolver.resolve(
      presentation: old,
      originEpochDay: old.momentum.selected.epochDay,
      rawOffset: 0,
      isMoving: false,
      generation: 5,
    );
    expect(preempted.rawOffset, 0);
    final stale = resolver.resolve(
      presentation: next,
      originEpochDay: next.momentum.selected.epochDay,
      rawOffset: 0,
      isMoving: false,
      generation: 4,
      acceptedEpochDay: next.momentum.selected.epochDay,
    );
    expect(stale.originEpochDay, flight.originEpochDay);
    expect(stale.rawOffset, 0);
    final external = resolver.resolve(
      presentation: next,
      originEpochDay: next.momentum.selected.epochDay,
      rawOffset: 0,
      isMoving: false,
      generation: 5,
    );
    expect(external.originEpochDay, next.momentum.selected.epochDay);
  });
  test('new producer uses accepted tick rather than obsolete fraction', () {
    final old = window(const LocalDate(year: 2026, month: 7, day: 14));
    final next = window(const LocalDate(year: 2026, month: 7, day: 17));
    final r = BalanceDayMomentumRailWindowController(old);
    r.resolve(
      presentation: old,
      originEpochDay: old.momentum.selected.epochDay,
      rawOffset: 3.4,
      isMoving: true,
      generation: 1,
    );
    final fresh = r.resolve(
      presentation: next,
      originEpochDay: next.momentum.selected.epochDay,
      rawOffset: .25,
      isMoving: true,
      generation: 2,
    );
    expect(
      fresh.originEpochDay + fresh.rawOffset,
      next.momentum.selected.epochDay + .25,
    );
  });
  test(
    'exact contiguous flight replaces the whole prepared window without shifting surviving days',
    () {
      final old = window(const LocalDate(year: 2026, month: 7, day: 14));
      final next = window(
        const LocalDate(year: 2026, month: 7, day: 15),
        magnitude: .8,
      );
      final r = BalanceDayMomentumRailWindowController(old);
      final before = r.resolve(
        presentation: old,
        originEpochDay: old.momentum.selected.epochDay,
        rawOffset: 1.25,
        isMoving: true,
        generation: 1,
      );
      final ready = r.resolve(
        presentation: next,
        originEpochDay: old.momentum.selected.epochDay,
        rawOffset: 1.25,
        isMoving: true,
        generation: 1,
      );
      expect(identical(ready.points, next.momentum.rhythm), isTrue);
      expect(ready.points.last.epochDay, next.momentum.selected.epochDay);
      expect(ready.points.every((p) => p.magnitude == .8), isTrue);
      expect(ready.originEpochDay, before.originEpochDay);
      expect(ready.rawOffset, before.rawOffset);
      final survivingDay = old.momentum.selected.epochDay;
      double slot(BalanceDayMomentumRailVisualWindow frame) =>
          survivingDay - (frame.originEpochDay - 59) - frame.rawOffset;
      expect(slot(ready), slot(before));
    },
  );
  test(
    'fresh midflight follower starts at accepted ordinary day plus fraction',
    () {
      final origin = const LocalDate(year: 2026, month: 7, day: 14).epochDay;
      final accepted = window(const LocalDate(year: 2026, month: 7, day: 17));
      final r = BalanceDayMomentumRailWindowController(accepted);
      final frame = r.resolve(
        presentation: accepted,
        originEpochDay: origin,
        rawOffset: 3.25,
        isMoving: true,
        generation: 5,
        acceptedEpochDay: accepted.momentum.selected.epochDay,
      );
      expect(
        frame.originEpochDay + frame.rawOffset,
        accepted.momentum.selected.epochDay + .25,
      );
      expect(identical(frame.points, accepted.momentum.rhythm), isTrue);
    },
  );
  test(
    'fresh midflight follower at cyclic wrap uses accepted day plus fraction',
    () {
      final origin = const LocalDate(year: 2026, month: 1, day: 31).epochDay;
      final accepted = window(const LocalDate(year: 2026, month: 1, day: 1));
      final r = BalanceDayMomentumRailWindowController(accepted);
      final frame = r.resolve(
        presentation: accepted,
        originEpochDay: origin,
        rawOffset: 1.25,
        isMoving: true,
        generation: 5,
        acceptedEpochDay: accepted.momentum.selected.epochDay,
      );
      expect(
        frame.originEpochDay + frame.rawOffset,
        accepted.momentum.selected.epochDay + .25,
      );
      expect(frame.rawOffset, .25);
    },
  );
  test(
    'fresh deferred or intermediate follower keeps the original virtual timeline',
    () {
      final origin = const LocalDate(year: 2026, month: 7, day: 14).epochDay;
      final accepted = const LocalDate(year: 2026, month: 7, day: 17).epochDay;
      for (final day in [14, 15]) {
        final prepared = window(LocalDate(year: 2026, month: 7, day: day));
        final r = BalanceDayMomentumRailWindowController(prepared);
        final frame = r.resolve(
          presentation: prepared,
          originEpochDay: origin,
          rawOffset: 3.25,
          isMoving: true,
          generation: 5,
          acceptedEpochDay: accepted,
        );
        expect(frame.originEpochDay + frame.rawOffset, accepted + .25);
        expect(identical(frame.points, prepared.momentum.rhythm), isTrue);
      }
    },
  );
  test('ordinary next-day reanchor does not request a wrap fade', () {
    final date = const LocalDate(year: 2026, month: 6, day: 12);
    final old = window(date);
    final next = window(const LocalDate(year: 2026, month: 6, day: 13));
    final r = BalanceDayMomentumRailWindowController(old);
    r.resolve(
      presentation: old,
      originEpochDay: date.epochDay,
      rawOffset: 1,
      isMoving: true,
      generation: 1,
    );
    final ready = r.resolve(
      presentation: next,
      originEpochDay: date.epochDay,
      rawOffset: 1,
      isMoving: false,
      generation: 1,
      acceptedEpochDay: next.momentum.selected.epochDay,
    );
    expect(ready.wrapReplacement, isFalse);
  });
  testWidgets(
    'compact viewport keeps 60 real bars and omits duplicate heading',
    (tester) async {
      final data = window(const LocalDate(year: 2026, month: 7, day: 16));
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 65,
              child: BalanceDayMomentumRail(presentation: data, compact: true),
            ),
          ),
        ),
      );
      expect(find.text('Pénzügyi momentum'), findsNothing);
      expect(find.text('Előző 30 nap'), findsOneWidget);
      final paint =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('balance-day-rhythm-bars')),
                  )
                  .painter!
              as BalanceDayMomentumRailPainter;
      expect(paint.points, hasLength(60));
      expect(paint.points.last.epochDay - paint.points.first.epochDay, 59);
      expect(tester.takeException(), isNull);
    },
  );
}
