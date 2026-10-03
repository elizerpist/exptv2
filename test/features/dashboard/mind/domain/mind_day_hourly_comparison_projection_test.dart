import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_day_hourly_comparison_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';

void main() {
  test(
    'MIND-DAY-COMP-01 RED: groups resident full and slider events into the same 24 hourly cells',
    () {
      const full = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 1, timeMinutes: 8 * 60 + 5, total: 1200),
        MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60 + 40, total: 2500),
        MindDayTimelineEvent(ordinal: 3, timeMinutes: 18 * 60, total: 5000),
      ];
      const selected = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60 + 40, total: 2500),
        MindDayTimelineEvent(ordinal: 3, timeMinutes: 18 * 60, total: 5000),
      ];

      final comparison = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: selected,
      );

      expect(comparison.hours, hasLength(24));
      expect(comparison.hour(8).fullTotal, 3700);
      expect(comparison.hour(8).selectedTotal, 2500);
      expect(comparison.hour(18).fullTotal, 5000);
      expect(comparison.hour(18).selectedTotal, 5000);
      expect(comparison.hour(1).fullTotal, 0);
      expect(comparison.hour(1).selectedTotal, 0);
    },
  );

  test(
    'MIND-DAY-COMP-02 RED: selected foreground is bounded by full-day background and scales from the full-day maximum',
    () {
      const full = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 1, timeMinutes: 7 * 60, total: 1000),
        MindDayTimelineEvent(ordinal: 2, timeMinutes: 18 * 60, total: 8000),
      ];
      const selected = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 1, timeMinutes: 7 * 60, total: 1000),
      ];

      final comparison = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: selected,
      );

      expect(comparison.maximumFullTotal, 8000);
      expect(comparison.hour(7).fullFraction, closeTo(.125, .0001));
      expect(comparison.hour(7).selectedFraction, closeTo(.125, .0001));
      expect(comparison.hour(18).selectedFraction, 0);
    },
  );

  test(
    'DAYHOUR-01: four transactions in four local hours retain four distinct hourly cells',
    () {
      const full = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 1, timeMinutes: 2 * 60, total: 100),
        MindDayTimelineEvent(ordinal: 2, timeMinutes: 7 * 60, total: 250),
        MindDayTimelineEvent(ordinal: 3, timeMinutes: 12 * 60, total: 600),
        MindDayTimelineEvent(ordinal: 4, timeMinutes: 18 * 60, total: 30000),
      ];

      final comparison = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: full,
      );

      for (final hour in <int>[2, 7, 12, 18]) {
        expect(
          comparison.hour(hour).fullTotal,
          greaterThan(0),
          reason: 'The $hour:00 transaction must stay in its own hour.',
        );
        expect(comparison.hour(hour).selectedTotal, greaterThan(0));
      }
      expect(comparison.hours.where((hour) => hour.fullTotal > 0).length, 4);
    },
  );

  test(
    'DAYHOUR-03: one hour sums every admitted transaction and shrinks at the same full-hour scale',
    () {
      const full = <MindDayTimelineEvent>[
        MindDayTimelineEvent(ordinal: 1, timeMinutes: 8 * 60 + 4, total: 2000),
        MindDayTimelineEvent(
          ordinal: 2,
          timeMinutes: 8 * 60 + 17,
          total: 15000,
        ),
        MindDayTimelineEvent(
          ordinal: 3,
          timeMinutes: 8 * 60 + 31,
          total: 47000,
        ),
        MindDayTimelineEvent(
          ordinal: 4,
          timeMinutes: 8 * 60 + 52,
          total: 90000,
        ),
      ];

      final atTenThousand = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: full.where((event) => event.total >= 10000),
      );
      final atTwentyThousand = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: full.where((event) => event.total >= 20000),
      );
      final atFiftyThousand = MindDayHourlyComparisonProjection.build(
        fullEvents: full,
        selectedEvents: full.where((event) => event.total >= 50000),
      );

      expect(atTenThousand.hour(8).fullTotal, 154000);
      expect(atTenThousand.hour(8).selectedTotal, 152000);
      expect(atTwentyThousand.hour(8).fullTotal, 154000);
      expect(atTwentyThousand.hour(8).selectedTotal, 137000);
      expect(atFiftyThousand.hour(8).fullTotal, 154000);
      expect(atFiftyThousand.hour(8).selectedTotal, 90000);
      expect(atFiftyThousand.maximumFullTotal, 154000);
      expect(
        atFiftyThousand.hour(8).selectedFraction,
        closeTo(90000 / 154000, .000001),
      );
    },
  );
}
