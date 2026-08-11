import 'query_temporal_filter.dart';

/// Product-defined temporal shortcuts for the Query composer.
///
/// The reference instant is explicit so preset semantics never accidentally
/// depend on the currently expanded custom year/month selector or on a stale
/// dashboard structural child.
final class QueryTemporalPresets {
  const QueryTemporalPresets._();

  static QueryTemporalFilter currentMonth(DateTime reference) =>
      QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(reference.year, reference.month),
      });

  static QueryTemporalFilter lastThreeMonths(DateTime reference) =>
      QueryTemporalFilter.periods(<QueryPeriodSelection>{
        for (var delta = 0; delta < 3; delta += 1)
          QueryPeriodSelection.month(
            DateTime(reference.year, reference.month - delta).year,
            DateTime(reference.year, reference.month - delta).month,
          ),
      });

  static QueryTemporalFilter yearToDate(DateTime reference) =>
      QueryTemporalFilter.periods(<QueryPeriodSelection>{
        for (var month = 1; month <= reference.month; month += 1)
          QueryPeriodSelection.month(reference.year, month),
      });
}
