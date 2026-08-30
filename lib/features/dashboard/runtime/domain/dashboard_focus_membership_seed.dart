import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_entry.dart';

/// Immutable, exact base-scope row membership prepared before a focus gesture.
///
/// It deliberately stores semantic transport rows, not rich LogBox view
/// models/TextPainters. Category/partner inverted memberships make an
/// ephemeral focus derive from the committed base without a Room lookup or a
/// scan of the entire base scope on pointer-up.
@immutable
final class DashboardFocusMembershipSeed {
  DashboardFocusMembershipSeed(List<DashboardLedgerEntry> entries)
    : entries = List<DashboardLedgerEntry>.unmodifiable(entries),
      _categoryIndices = _index(entries, (entry) => entry.categoryId),
      _partnerIndices = _index(entries, (entry) => entry.partnerId),
      _amountIndex = _DashboardPreparedAmountIndex(entries),
      _searchIndex = DashboardPreparedLedgerSearchIndex(entries),
      _allOrdinals = DashboardFocusOrdinalSet.range(entries.length) {
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length != entries.length) {
      throw ArgumentError('Focus membership rows must have unique IDs.');
    }
  }

  final List<DashboardLedgerEntry> entries;
  final Map<String, DashboardFocusOrdinalSet> _categoryIndices;
  final Map<String, DashboardFocusOrdinalSet> _partnerIndices;
  final _DashboardPreparedAmountIndex _amountIndex;
  final DashboardPreparedLedgerSearchIndex _searchIndex;
  final DashboardFocusOrdinalSet _allOrdinals;

  int get entryCount => entries.length;

  int get estimatedMembershipBytes =>
      entries.length * 12 +
      _categoryIndices.values.fold<int>(
        0,
        (sum, indices) => sum + indices.length * 4,
      ) +
      _partnerIndices.values.fold<int>(
        0,
        (sum, indices) => sum + indices.length * 4,
      ) +
      _amountIndex.estimatedBytes +
      _searchIndex.estimatedBytes;

  DashboardFocusMembershipProjection select({
    String? categoryId,
    String? partnerId,
    String? normalizedSearch,
    int? minimumAmountScaled100,
    int? maximumAmountScaled100,
  }) {
    final lookup = Stopwatch()..start();
    if (categoryId == null &&
        partnerId == null &&
        normalizedSearch == null &&
        minimumAmountScaled100 == null &&
        maximumAmountScaled100 == null) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: _allOrdinals,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    final category = categoryId == null ? null : _categoryIndices[categoryId];
    final partner = partnerId == null ? null : _partnerIndices[partnerId];
    final amount =
        minimumAmountScaled100 == null && maximumAmountScaled100 == null
        ? null
        : _amountIndex.select(
            minimumScaled100: minimumAmountScaled100,
            maximumScaled100: maximumAmountScaled100,
          );
    if ((categoryId != null && category == null) ||
        (partnerId != null && partner == null)) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: DashboardFocusOrdinalSet.empty,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    DashboardFocusOrdinalSet selected =
        category ?? partner ?? amount ?? _allOrdinals;
    var intersectionMicros = 0;
    for (final dimension in <DashboardFocusOrdinalSet?>[
      category,
      partner,
      amount,
    ]) {
      if (dimension == null || identical(dimension, selected)) continue;
      final intersection = Stopwatch()..start();
      selected = DashboardFocusOrdinalSet.intersection(selected, dimension);
      intersection.stop();
      intersectionMicros += intersection.elapsedMicroseconds;
    }
    lookup.stop();
    if (normalizedSearch != null) {
      final search = Stopwatch()..start();
      final matches = _searchIndex.select(normalizedSearch);
      selected = DashboardFocusOrdinalSet.intersection(selected, matches);
      search.stop();
      intersectionMicros += search.elapsedMicroseconds;
    }
    return DashboardFocusMembershipProjection._(
      seed: this,
      entryIndices: selected,
      membershipLookupMicros: lookup.elapsedMicroseconds,
      intersectionMicros: intersectionMicros,
    );
  }

  DashboardLedgerEntry entryAt(int ordinal) {
    if (ordinal < 0 || ordinal >= entries.length) {
      throw RangeError.index(ordinal, entries, 'ordinal');
    }
    return entries[ordinal];
  }

  static Map<String, DashboardFocusOrdinalSet> _index(
    List<DashboardLedgerEntry> entries,
    String Function(DashboardLedgerEntry entry) selector,
  ) {
    final mutable = <String, List<int>>{};
    for (var index = 0; index < entries.length; index += 1) {
      mutable.putIfAbsent(selector(entries[index]), () => <int>[]).add(index);
    }
    return Map<String, DashboardFocusOrdinalSet>.unmodifiable(
      mutable.map(
        (key, value) => MapEntry<String, DashboardFocusOrdinalSet>(
          key,
          DashboardFocusOrdinalSet.fromSorted(value),
        ),
      ),
    );
  }
}

/// Amount-sorted immutable membership. Boundary lookup is logarithmic and
/// materializes only matching ordinals; the final ordinal sort preserves the
/// prepared timeline order required by every other focus dimension.
final class _DashboardPreparedAmountIndex {
  _DashboardPreparedAmountIndex(List<DashboardLedgerEntry> entries)
    : _values = List<_DashboardAmountOrdinal>.unmodifiable(
        <_DashboardAmountOrdinal>[
          for (var ordinal = 0; ordinal < entries.length; ordinal += 1)
            _DashboardAmountOrdinal(
              amountScaled100: entries[ordinal].amountMinor,
              ordinal: ordinal,
            ),
        ]..sort((left, right) {
          final amount = left.amountScaled100.compareTo(right.amountScaled100);
          return amount != 0 ? amount : left.ordinal.compareTo(right.ordinal);
        }),
      );

  final List<_DashboardAmountOrdinal> _values;

  int get estimatedBytes => _values.length * 12;

  DashboardFocusOrdinalSet select({
    int? minimumScaled100,
    int? maximumScaled100,
  }) {
    if (minimumScaled100 != null &&
        maximumScaled100 != null &&
        minimumScaled100 > maximumScaled100) {
      return DashboardFocusOrdinalSet.empty;
    }
    final start = _lowerBound(minimumScaled100 ?? -0x7FFFFFFFFFFFFFFF);
    final end = _upperBound(maximumScaled100 ?? 0x7FFFFFFFFFFFFFFF);
    if (start >= end) return DashboardFocusOrdinalSet.empty;
    final ordinals = <int>[
      for (var index = start; index < end; index += 1) _values[index].ordinal,
    ]..sort();
    return DashboardFocusOrdinalSet.fromSorted(ordinals);
  }

  int _lowerBound(int value) {
    var low = 0;
    var high = _values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_values[middle].amountScaled100 < value) {
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
      if (_values[middle].amountScaled100 <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

final class _DashboardAmountOrdinal {
  const _DashboardAmountOrdinal({
    required this.amountScaled100,
    required this.ordinal,
  });

  final int amountScaled100;
  final int ordinal;
}

/// Central text normalization for prepared Ledger search.
///
/// It is intentionally Unicode/case safe and whitespace-normalizing but does
/// not remove Hungarian accents: those are part of the user's actual text.
abstract final class DashboardLedgerSearchNormalizer {
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
    return normalized.isEmpty ? null : normalized;
  }
}

/// Immutable RAM-only text lookup built with the focus membership seed.
///
/// The index owns normalized partner-display and note text once, then maps
/// one-to-three-character ngrams to compact sorted ordinals. A live query
/// first intersects its grams and only verifies the remaining candidates with
/// an exact `contains`, so the SearchPill neither calls Room nor scans
/// presentation rows on each edit.
@immutable
final class DashboardPreparedLedgerSearchIndex {
  DashboardPreparedLedgerSearchIndex(List<DashboardLedgerEntry> entries)
    : _texts = List<_DashboardPreparedLedgerSearchText>.unmodifiable(
        entries.map(
          (entry) => _DashboardPreparedLedgerSearchText(
            partner: DashboardLedgerSearchNormalizer.normalize(
              entry.partnerDisplayName,
            ),
            note: DashboardLedgerSearchNormalizer.normalize(entry.note),
          ),
        ),
      ),
      _grams = _buildGrams(entries);

  final List<_DashboardPreparedLedgerSearchText> _texts;
  final Map<String, DashboardFocusOrdinalSet> _grams;

  int get estimatedBytes =>
      _texts.fold<int>(0, (sum, text) => sum + text.estimatedBytes) +
      _grams.values.fold<int>(0, (sum, ordinals) => sum + ordinals.length * 4);

  DashboardFocusOrdinalSet select(String normalizedQuery) {
    final query = DashboardLedgerSearchNormalizer.normalize(normalizedQuery);
    if (query == null) return DashboardFocusOrdinalSet.empty;
    final grams = _queryGrams(query);
    DashboardFocusOrdinalSet? candidates;
    for (final gram in grams) {
      final match = _grams[gram];
      if (match == null) return DashboardFocusOrdinalSet.empty;
      candidates = candidates == null
          ? match
          : DashboardFocusOrdinalSet.intersection(candidates, match);
      if (candidates.isEmpty) return DashboardFocusOrdinalSet.empty;
    }
    final verified = <int>[];
    for (final ordinal in candidates ?? DashboardFocusOrdinalSet.empty) {
      if (_texts[ordinal].contains(query)) verified.add(ordinal);
    }
    return verified.isEmpty
        ? DashboardFocusOrdinalSet.empty
        : DashboardFocusOrdinalSet.fromSorted(verified);
  }

  static Map<String, DashboardFocusOrdinalSet> _buildGrams(
    List<DashboardLedgerEntry> entries,
  ) {
    final mutable = <String, List<int>>{};
    for (var ordinal = 0; ordinal < entries.length; ordinal += 1) {
      final text = _DashboardPreparedLedgerSearchText(
        partner: DashboardLedgerSearchNormalizer.normalize(
          entries[ordinal].partnerDisplayName,
        ),
        note: DashboardLedgerSearchNormalizer.normalize(entries[ordinal].note),
      );
      final entryGrams = <String>{};
      for (final field in text.fields) {
        for (var width = 1; width <= 3 && width <= field.length; width += 1) {
          entryGrams.addAll(_gramsFor(field, width));
        }
      }
      for (final gram in entryGrams) {
        mutable.putIfAbsent(gram, () => <int>[]).add(ordinal);
      }
    }
    return Map<String, DashboardFocusOrdinalSet>.unmodifiable(
      mutable.map(
        (gram, ordinals) =>
            MapEntry(gram, DashboardFocusOrdinalSet.fromSorted(ordinals)),
      ),
    );
  }

  static Iterable<String> _queryGrams(String text) {
    final width = text.length < 3 ? text.length : 3;
    return _gramsFor(text, width);
  }

  static Iterable<String> _gramsFor(String text, int width) {
    if (width == 0) return const <String>[];
    final unique = <String>{};
    for (var index = 0; index + width <= text.length; index += 1) {
      unique.add(text.substring(index, index + width));
    }
    return unique;
  }
}

@immutable
final class _DashboardPreparedLedgerSearchText {
  const _DashboardPreparedLedgerSearchText({this.partner, this.note});

  final String? partner;
  final String? note;

  Iterable<String> get fields sync* {
    if (partner case final String value) yield value;
    if (note case final String value) yield value;
  }

  int get estimatedBytes => ((partner?.length ?? 0) + (note?.length ?? 0)) * 2;

  bool contains(String query) =>
      (partner?.contains(query) ?? false) || (note?.contains(query) ?? false);
}

/// Immutable compact ordinal membership retained by one prepared base index.
///
/// The private [Uint32List] gives category/partner membership a bounded packed
/// representation. Callers can iterate or index it but cannot mutate it or
/// accidentally turn a dimension-clear operation into a copied `List<int>`.
@immutable
final class DashboardFocusOrdinalSet extends IterableBase<int> {
  const DashboardFocusOrdinalSet._(this._ordinals);

  factory DashboardFocusOrdinalSet.fromSorted(Iterable<int> values) {
    final list = values is List<int> ? values : values.toList(growable: false);
    return DashboardFocusOrdinalSet._(Uint32List.fromList(list));
  }

  factory DashboardFocusOrdinalSet.range(int length) =>
      DashboardFocusOrdinalSet._(
        Uint32List.fromList(List<int>.generate(length, (index) => index)),
      );

  static final DashboardFocusOrdinalSet empty = DashboardFocusOrdinalSet._(
    Uint32List(0),
  );

  final Uint32List _ordinals;

  @override
  int get length => _ordinals.length;

  int operator [](int index) => _ordinals[index];

  @override
  Iterator<int> get iterator => _ordinals.iterator;

  /// Two sorted ordinal sets intersect in membership-size time, preserving the
  /// original prepared row order without allocating a `Set` or scanning base
  /// rows.
  static DashboardFocusOrdinalSet intersection(
    DashboardFocusOrdinalSet first,
    DashboardFocusOrdinalSet second,
  ) {
    if (first.isEmpty || second.isEmpty) return empty;
    final matches = <int>[];
    var left = 0;
    var right = 0;
    while (left < first.length && right < second.length) {
      final a = first[left];
      final b = second[right];
      if (a == b) {
        matches.add(a);
        left += 1;
        right += 1;
      } else if (a < b) {
        left += 1;
      } else {
        right += 1;
      }
    }
    return matches.isEmpty
        ? empty
        : DashboardFocusOrdinalSet.fromSorted(matches);
  }
}

@immutable
final class DashboardFocusMembershipProjection {
  const DashboardFocusMembershipProjection._({
    required this.seed,
    required this.entryIndices,
    required this.membershipLookupMicros,
    this.intersectionMicros = 0,
  });

  final DashboardFocusMembershipSeed seed;
  final DashboardFocusOrdinalSet entryIndices;
  final int membershipLookupMicros;
  final int intersectionMicros;

  int get entryCount => entryIndices.length;
  Iterable<DashboardLedgerEntry> get entries => entryIndices.map(seed.entryAt);
  List<String> get entryIds =>
      List<String>.unmodifiable(entries.map((entry) => entry.id));
}
