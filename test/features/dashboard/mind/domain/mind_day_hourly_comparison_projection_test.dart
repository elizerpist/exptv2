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
}
