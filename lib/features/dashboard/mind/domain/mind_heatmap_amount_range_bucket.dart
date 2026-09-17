/// One immutable sorted amount bucket shared by Mind's Year, Month and Sum
/// temporal projections. A live range preview uses two binary bounds and a
/// prefix-sum subtraction; it never re-scans source ledger rows.
final class MindHeatmapAmountRangeBucket {
  const MindHeatmapAmountRangeBucket._(this._values, this._prefixSums);

  factory MindHeatmapAmountRangeBucket.fromUnsorted(List<int> values) {
    if (values.isEmpty) return _empty;
    final sorted = List<int>.of(values)..sort();
    final prefix = List<int>.filled(sorted.length + 1, 0, growable: false);
    for (var index = 0; index < sorted.length; index += 1) {
      prefix[index + 1] = prefix[index] + sorted[index];
    }
    return MindHeatmapAmountRangeBucket._(
      List<int>.unmodifiable(sorted),
      List<int>.unmodifiable(prefix),
    );
  }

  static final _empty = MindHeatmapAmountRangeBucket._(
    const <int>[],
    const <int>[0],
  );

  final List<int> _values;
  final List<int> _prefixSums;

  int? sumWithin({required int minimum, required int maximum}) {
    if (_values.isEmpty || minimum > maximum) return null;
    final start = _lowerBound(minimum);
    final end = _upperBound(maximum);
    return start == end ? null : _prefixSums[end] - _prefixSums[start];
  }

  int _lowerBound(int value) {
    var low = 0;
    var high = _values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_values[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperBound(int value) {
    var low = 0;
    var high = _values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_values[middle] <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}
