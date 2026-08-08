import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';

void main() {
  test('live rail child subtitles preserve parent temporal context', () {
    expect(
      SummaryNavigationProjector.liveRailChildSubtitle(
        plane: TimePlane.sum,
        visibleChildScope: const YearScope(2031),
        fallback: '2031',
      ),
      '2031',
      reason: 'SUM keeps its existing copy contract.',
    );
    expect(
      SummaryNavigationProjector.liveRailChildSubtitle(
        plane: TimePlane.year,
        visibleChildScope: const MonthScope(YearMonth(year: 2026, month: 6)),
        fallback: 'június',
      ),
      '2026 június',
    );
    expect(
      SummaryNavigationProjector.liveRailChildSubtitle(
        plane: TimePlane.month,
        visibleChildScope: DayScope(
          const YearMonth(year: 2026, month: 6).clampDay(16),
        ),
        fallback: '16',
      ),
      '2026 június 16',
    );
  });

  test(
    'live rail child subtitle derives year/month from the typed child scope',
    () {
      expect(
        SummaryNavigationProjector.liveRailChildSubtitle(
          plane: TimePlane.year,
          visibleChildScope: const MonthScope(YearMonth(year: 2025, month: 12)),
          fallback: 'december',
        ),
        '2025 december',
      );
      expect(
        SummaryNavigationProjector.liveRailChildSubtitle(
          plane: TimePlane.month,
          visibleChildScope: DayScope(
            const YearMonth(year: 2027, month: 1).clampDay(1),
          ),
          fallback: '1',
        ),
        '2027 január 1',
      );
    },
  );
}
