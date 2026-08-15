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
      _allOrdinals = DashboardFocusOrdinalSet.range(entries.length) {
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length != entries.length) {
      throw ArgumentError('Focus membership rows must have unique IDs.');
    }
  }

  final List<DashboardLedgerEntry> entries;
  final Map<String, DashboardFocusOrdinalSet> _categoryIndices;
  final Map<String, DashboardFocusOrdinalSet> _partnerIndices;
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
      );

  DashboardFocusMembershipProjection select({
    String? categoryId,
    String? partnerId,
  }) {
    final lookup = Stopwatch()..start();
    if (categoryId == null && partnerId == null) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: _allOrdinals,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    final category = categoryId == null ? null : _categoryIndices[categoryId];
    final partner = partnerId == null ? null : _partnerIndices[partnerId];
    if ((categoryId != null && category == null) ||
        (partnerId != null && partner == null)) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: DashboardFocusOrdinalSet.empty,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    if (category == null) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: partner!,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    if (partner == null) {
      lookup.stop();
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: category,
        membershipLookupMicros: lookup.elapsedMicroseconds,
      );
    }
    lookup.stop();
    final intersection = Stopwatch()..start();
    final ordinals = DashboardFocusOrdinalSet.intersection(category, partner);
    intersection.stop();
    return DashboardFocusMembershipProjection._(
      seed: this,
      entryIndices: ordinals,
      membershipLookupMicros: lookup.elapsedMicroseconds,
      intersectionMicros: intersection.elapsedMicroseconds,
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
