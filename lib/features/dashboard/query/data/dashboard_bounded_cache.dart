import 'dart:collection';

/// Small reusable LRU for bounded read/presentation payloads.
///
/// The cache owns no query or widget lifecycle. [weightOf] lets callers track
/// rows, bytes or another explicit payload unit without duplicating eviction
/// logic in each coordinator.
class DashboardBoundedCache<K, V> {
  DashboardBoundedCache({
    required int capacity,
    required int Function(V value) weightOf,
    int Function(V value)? byteWeightOf,
    int? maxBytes,
    bool Function(K key, V value)? isProtected,
  }) : assert(capacity > 0),
       assert(maxBytes == null || maxBytes > 0),
       _capacity = capacity,
       _weightOf = weightOf,
       _byteWeightOf = byteWeightOf ?? weightOf,
       _maxBytes = maxBytes,
       _isProtected = isProtected;

  final int _capacity;
  final int Function(V value) _weightOf;
  final int Function(V value) _byteWeightOf;
  final int? _maxBytes;
  final bool Function(K key, V value)? _isProtected;
  final LinkedHashMap<K, V> _values = LinkedHashMap<K, V>();
  int _estimatedWeight = 0;
  int _estimatedBytes = 0;
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  int get length => _values.length;
  int get estimatedWeight => _estimatedWeight;
  int get estimatedBytes => _estimatedBytes;
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get evictionCount => _evictionCount;
  Iterable<K> get keys => List<K>.unmodifiable(_values.keys);

  V? get(K key) {
    final value = _values[key];
    if (value == null) {
      _missCount += 1;
      return null;
    }
    _hitCount += 1;
    _values
      ..remove(key)
      ..[key] = value;
    return value;
  }

  /// Reads a value without changing hit/miss counters or recency.
  V? peek(K key) => _values[key];

  /// Marks an existing value as most recently used without counting a read.
  void touch(K key) {
    final value = _values.remove(key);
    if (value != null) _values[key] = value;
  }

  V? remove(K key) {
    final value = _values.remove(key);
    if (value == null) return null;
    _estimatedWeight -= _weightOf(value);
    _estimatedBytes -= _byteWeightOf(value);
    return value;
  }

  void put(K key, V value) {
    final previous = _values.remove(key);
    if (previous != null) {
      _estimatedWeight -= _weightOf(previous);
      _estimatedBytes -= _byteWeightOf(previous);
    }
    _values[key] = value;
    _estimatedWeight += _weightOf(value);
    _estimatedBytes += _byteWeightOf(value);
    while (_values.isNotEmpty &&
        (_values.length > _capacity ||
            (_maxBytes != null && _estimatedBytes > _maxBytes))) {
      K? oldestKey;
      for (final entry in _values.entries) {
        if (!(_isProtected?.call(entry.key, entry.value) ?? false)) {
          oldestKey = entry.key;
          break;
        }
      }
      if (oldestKey == null) break;
      final oldest = remove(oldestKey);
      if (oldest == null) break;
      _evictionCount += 1;
    }
  }

  void clear() {
    _values.clear();
    _estimatedWeight = 0;
    _estimatedBytes = 0;
  }
}
