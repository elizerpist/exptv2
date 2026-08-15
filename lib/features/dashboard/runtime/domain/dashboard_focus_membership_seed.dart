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
      _partnerIndices = _index(entries, (entry) => entry.partnerId) {
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length != entries.length) {
      throw ArgumentError('Focus membership rows must have unique IDs.');
    }
  }

  final List<DashboardLedgerEntry> entries;
  final Map<String, List<int>> _categoryIndices;
  final Map<String, List<int>> _partnerIndices;

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
    if (categoryId == null && partnerId == null) {
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: List<int>.generate(entries.length, (index) => index),
      );
    }
    final category = categoryId == null ? null : _categoryIndices[categoryId];
    final partner = partnerId == null ? null : _partnerIndices[partnerId];
    if ((categoryId != null && category == null) ||
        (partnerId != null && partner == null)) {
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: const <int>[],
      );
    }
    if (category == null) {
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: partner!,
      );
    }
    if (partner == null) {
      return DashboardFocusMembershipProjection._(
        seed: this,
        entryIndices: category,
      );
    }
    final smaller = category.length <= partner.length ? category : partner;
    final other = category.length <= partner.length ? partner : category;
    final otherSet = other.toSet();
    final intersection = smaller.where(otherSet.contains).toList()..sort();
    return DashboardFocusMembershipProjection._(
      seed: this,
      entryIndices: intersection,
    );
  }

  static Map<String, List<int>> _index(
    List<DashboardLedgerEntry> entries,
    String Function(DashboardLedgerEntry entry) selector,
  ) {
    final mutable = <String, List<int>>{};
    for (var index = 0; index < entries.length; index += 1) {
      mutable.putIfAbsent(selector(entries[index]), () => <int>[]).add(index);
    }
    return Map<String, List<int>>.unmodifiable(
      mutable.map(
        (key, value) =>
            MapEntry<String, List<int>>(key, List<int>.unmodifiable(value)),
      ),
    );
  }
}

@immutable
final class DashboardFocusMembershipProjection {
  DashboardFocusMembershipProjection._({
    required this.seed,
    required List<int> entryIndices,
  }) : entryIndices = List<int>.unmodifiable(entryIndices);

  final DashboardFocusMembershipSeed seed;
  final List<int> entryIndices;

  int get entryCount => entryIndices.length;
  Iterable<DashboardLedgerEntry> get entries =>
      entryIndices.map((index) => seed.entries[index]);
  List<String> get entryIds =>
      List<String>.unmodifiable(entries.map((entry) => entry.id));
}
