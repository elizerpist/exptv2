import 'local_date.dart';

/// Date-only query boundaries. The start is inclusive and the end exclusive.
class TimeScopeBoundaries {
  const TimeScopeBoundaries({
    required this.startInclusive,
    required this.endExclusive,
  });

  final LocalDate startInclusive;
  final LocalDate endExclusive;

  @override
  bool operator ==(Object other) =>
      other is TimeScopeBoundaries &&
      other.startInclusive == startInclusive &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(startInclusive, endExclusive);
}
