import '../../query/data/dashboard_bounded_cache.dart';
import '../domain/dashboard_prepared_deck.dart';

enum DashboardPreparedDeckLookupStatus { hit, miss }

final class DashboardPreparedDeckLookup {
  const DashboardPreparedDeckLookup._({required this.status, this.deck});

  const DashboardPreparedDeckLookup.hit(DashboardPreparedDeck deck)
    : this._(status: DashboardPreparedDeckLookupStatus.hit, deck: deck);

  const DashboardPreparedDeckLookup.miss()
    : this._(status: DashboardPreparedDeckLookupStatus.miss);

  final DashboardPreparedDeckLookupStatus status;
  final DashboardPreparedDeck? deck;

  bool get isHit => status == DashboardPreparedDeckLookupStatus.hit;
}

/// Exact-key, access-ordered storage for complete immutable prepared decks.
final class DashboardPreparedDeckCache {
  factory DashboardPreparedDeckCache({
    required int capacity,
    int? maxEstimatedBytes,
  }) {
    if (capacity < 4) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'must retain active, previous, next and opposite-direction decks',
      );
    }
    final residency = <DashboardPreparedDeckKey>{};
    return DashboardPreparedDeckCache._(
      residency: residency,
      cache:
          DashboardBoundedCache<
            DashboardPreparedDeckKey,
            DashboardPreparedDeck
          >(
            capacity: capacity,
            weightOf: _deckWeight,
            byteWeightOf: _estimatedBytes,
            maxBytes: maxEstimatedBytes,
            isProtected: (key, _) => residency.contains(key),
          ),
    );
  }

  DashboardPreparedDeckCache._({
    required Set<DashboardPreparedDeckKey> residency,
    required DashboardBoundedCache<
      DashboardPreparedDeckKey,
      DashboardPreparedDeck
    >
    cache,
  }) : _residency = residency,
       _cache = cache;

  final DashboardBoundedCache<DashboardPreparedDeckKey, DashboardPreparedDeck>
  _cache;
  final Set<DashboardPreparedDeckKey> _residency;

  int get length => _cache.length;
  int get hitCount => _cache.hitCount;
  int get missCount => _cache.missCount;
  int get evictionCount => _cache.evictionCount;
  int get estimatedBytes => _cache.estimatedBytes;
  Iterable<DashboardPreparedDeckKey> get keys => _cache.keys;

  DashboardPreparedDeckLookup lookup(DashboardPreparedDeckKey key) {
    final deck = _cache.get(key);
    return deck == null
        ? const DashboardPreparedDeckLookup.miss()
        : DashboardPreparedDeckLookup.hit(deck);
  }

  DashboardPreparedDeck? peek(DashboardPreparedDeckKey key) => _cache.peek(key);

  void store(DashboardPreparedDeck deck) {
    if (deck.coreRevision <= 0 || !deck.isComplete) {
      throw StateError('Only complete nonzero-revision decks are cacheable.');
    }
    _cache.put(deck.key, deck);
  }

  void updateResidency({
    required DashboardPreparedDeckKey? active,
    required DashboardPreparedDeckKey? previous,
    required DashboardPreparedDeckKey? next,
    required DashboardPreparedDeckKey? oppositeDirection,
  }) {
    _residency
      ..clear()
      ..addAll(
        <DashboardPreparedDeckKey?>[
          active,
          previous,
          next,
          oppositeDirection,
        ].whereType<DashboardPreparedDeckKey>(),
      );
  }

  void retainOnlyRevision(int revision) {
    final stale = _cache.keys
        .where((key) => key.coreRevision != revision)
        .toList(growable: false);
    for (final key in stale) {
      _cache.remove(key);
      _residency.remove(key);
    }
  }

  void clear() {
    _cache.clear();
    _residency.clear();
  }

  static int _deckWeight(DashboardPreparedDeck deck) =>
      1 +
      deck.frames.length +
      deck.frames.values.fold<int>(
        0,
        (sum, frame) => sum + frame.stableRowIdentities.length,
      );

  static int _estimatedBytes(DashboardPreparedDeck deck) =>
      256 +
      deck.frames.values.fold<int>(
        0,
        (sum, frame) =>
            sum +
            192 +
            frame.amount.formattedAmount.length * 2 +
            frame.stableRowIdentities.length * 96,
      );
}
