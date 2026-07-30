import 'package:flutter/foundation.dart';

import '../../../models/category_budget_bar_data.dart';
import '../../../models/overview_budget_data.dart';
import '../../../models/transaction_category.dart';
import '../../../models/transaction_record.dart';
import '../../../state/transaction_store.dart';

typedef BudgetV2RevisionOf<S> = Object? Function(S source);
typedef BudgetV2Prepare<S, P> = P Function(S source);
typedef BudgetV2AvatarDataOf<P> =
    Object? Function(P prepared, String avatarKey);

class BudgetV2SnapshotCache<S, P> {
  BudgetV2SnapshotCache({
    this.maximumCachedRevisions = 4,
    required BudgetV2RevisionOf<S> revisionOf,
    required BudgetV2Prepare<S, P> prepare,
    required BudgetV2AvatarDataOf<P> avatarDataOf,
  }) : _revisionOf = revisionOf,
       _prepare = prepare,
       _avatarDataOf = avatarDataOf,
       assert(maximumCachedRevisions > 0);

  final int maximumCachedRevisions;
  final BudgetV2RevisionOf<S> _revisionOf;
  final BudgetV2Prepare<S, P> _prepare;
  final BudgetV2AvatarDataOf<P> _avatarDataOf;
  final Map<Object?, BudgetV2ResolvedSnapshot<P>> _snapshotsByRevision =
      <Object?, BudgetV2ResolvedSnapshot<P>>{};

  BudgetV2ResolvedSnapshot<P> resolve(S source) {
    final revision = _revisionOf(source);
    final cached = _snapshotsByRevision.remove(revision);
    if (cached != null) {
      _snapshotsByRevision[revision] = cached;
      return cached;
    }
    final resolved = BudgetV2ResolvedSnapshot<P>._(
      prepared: _prepare(source),
      avatarDataOf: _avatarDataOf,
    );
    _snapshotsByRevision[revision] = resolved;
    if (_snapshotsByRevision.length > maximumCachedRevisions) {
      _snapshotsByRevision.remove(_snapshotsByRevision.keys.first);
    }
    return resolved;
  }
}

class BudgetV2ResolvedSnapshot<P> {
  const BudgetV2ResolvedSnapshot._({
    required P prepared,
    required BudgetV2AvatarDataOf<P> avatarDataOf,
  }) : _prepared = prepared,
       _avatarDataOf = avatarDataOf;

  final P _prepared;
  final BudgetV2AvatarDataOf<P> _avatarDataOf;

  P get prepared => _prepared;

  Object? avatarData(String avatarKey) => _avatarDataOf(_prepared, avatarKey);
}

@immutable
class BudgetV2SnapshotRevision {
  const BudgetV2SnapshotRevision._({
    required this.activeType,
    required this.weekEndDay,
    required this.recordsIdentity,
    required this.barsIdentity,
    required this.overviewIdentity,
  });

  final TransactionType activeType;
  final int weekEndDay;
  final Object recordsIdentity;
  final Object barsIdentity;
  final Object overviewIdentity;

  @override
  bool operator ==(Object other) {
    return other is BudgetV2SnapshotRevision &&
        other.activeType == activeType &&
        other.weekEndDay == weekEndDay &&
        identical(other.recordsIdentity, recordsIdentity) &&
        identical(other.barsIdentity, barsIdentity) &&
        identical(other.overviewIdentity, overviewIdentity);
  }

  @override
  int get hashCode => Object.hash(
    activeType,
    weekEndDay,
    identityHashCode(recordsIdentity),
    identityHashCode(barsIdentity),
    identityHashCode(overviewIdentity),
  );
}

@immutable
class BudgetV2SnapshotSource {
  const BudgetV2SnapshotSource._({
    required this.revision,
    required this.weekEndDate,
    required this.records,
    required this.bars,
    required this.overviewItems,
  });

  factory BudgetV2SnapshotSource.fromStore(TransactionStore store) {
    final records = store.windowedTransactions;
    final bars = store.categoryBudgetBars;
    final overviewItems = store.overviewBudgetItems;
    final referenceDate = store.summaryReferenceDate;
    final weekEndDate = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return BudgetV2SnapshotSource._(
      revision: BudgetV2SnapshotRevision._(
        activeType: store.activeType,
        weekEndDay:
            weekEndDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
        recordsIdentity: records,
        barsIdentity: bars,
        overviewIdentity: overviewItems,
      ),
      weekEndDate: weekEndDate,
      records: records,
      bars: bars,
      overviewItems: overviewItems,
    );
  }

  final BudgetV2SnapshotRevision revision;
  final DateTime weekEndDate;
  final List<TransactionRecord> records;
  final List<CategoryBudgetBarData> bars;
  final List<OverviewBudgetData> overviewItems;
}

@immutable
class BudgetV2VendorAggregate {
  const BudgetV2VendorAggregate({
    required this.key,
    required this.name,
    required this.amount,
    required this.count,
    required this.leadingCategoryId,
  });

  final String key;
  final String name;
  final double amount;
  final int count;
  final int? leadingCategoryId;
}

@immutable
class BudgetV2AvatarSnapshot {
  const BudgetV2AvatarSnapshot({
    required this.avatarKey,
    required this.records,
    required this.vendors,
    required this.weeklyAmounts,
    required this.recordsByVendorKey,
    this.bar,
    this.overviewItem,
  });

  final String avatarKey;
  final CategoryBudgetBarData? bar;
  final OverviewBudgetData? overviewItem;
  final List<TransactionRecord> records;
  final List<BudgetV2VendorAggregate> vendors;
  final List<double> weeklyAmounts;
  final Map<String, List<TransactionRecord>> recordsByVendorKey;

  List<TransactionRecord> recordsForVendor(String vendorKey) =>
      recordsByVendorKey[vendorKey] ?? const <TransactionRecord>[];
}

@immutable
class BudgetV2PreparedSnapshot {
  const BudgetV2PreparedSnapshot._(this._avatarsByKey);

  factory BudgetV2PreparedSnapshot.prepare(BudgetV2SnapshotSource source) {
    final byKey = <String, _BudgetV2AvatarAccumulator>{};
    final overviewAccumulators = <_BudgetV2AvatarAccumulator>[];
    final categoryAccumulators = <int, List<_BudgetV2AvatarAccumulator>>{};

    for (final overview in source.overviewItems) {
      final accumulator = _BudgetV2AvatarAccumulator(
        avatarKey: overview.key,
        overviewItem: overview,
        weekEndDate: source.weekEndDate,
      );
      byKey[overview.key] = accumulator;
      overviewAccumulators.add(accumulator);
    }
    for (final bar in source.bars) {
      final accumulator = _BudgetV2AvatarAccumulator(
        avatarKey: bar.key,
        bar: bar,
        weekEndDate: source.weekEndDate,
      );
      byKey[bar.key] = accumulator;
      categoryAccumulators
          .putIfAbsent(bar.targetId, () => <_BudgetV2AvatarAccumulator>[])
          .add(accumulator);
    }

    for (final record in source.records) {
      for (final accumulator in overviewAccumulators) {
        accumulator.add(record);
      }
      final categoryId = record.transactionCategoryID;
      if (categoryId == null) continue;
      for (final accumulator
          in categoryAccumulators[categoryId] ??
              const <_BudgetV2AvatarAccumulator>[]) {
        accumulator.add(record);
      }
    }

    return BudgetV2PreparedSnapshot._(
      Map<String, BudgetV2AvatarSnapshot>.unmodifiable(
        byKey.map(
          (key, accumulator) => MapEntry<String, BudgetV2AvatarSnapshot>(
            key,
            accumulator.freeze(),
          ),
        ),
      ),
    );
  }

  final Map<String, BudgetV2AvatarSnapshot> _avatarsByKey;

  BudgetV2AvatarSnapshot avatarData(String avatarKey) {
    final data = _avatarsByKey[avatarKey];
    if (data == null) {
      throw StateError('Unknown Budget V2 avatar key: $avatarKey');
    }
    return data;
  }
}

class BudgetV2StoreSnapshotCache {
  BudgetV2StoreSnapshotCache()
    : _cache =
          BudgetV2SnapshotCache<
            BudgetV2SnapshotSource,
            BudgetV2PreparedSnapshot
          >(
            revisionOf: (source) => source.revision,
            prepare: BudgetV2PreparedSnapshot.prepare,
            avatarDataOf: (prepared, avatarKey) =>
                prepared.avatarData(avatarKey),
          );

  final BudgetV2SnapshotCache<BudgetV2SnapshotSource, BudgetV2PreparedSnapshot>
  _cache;

  BudgetV2PreparedSnapshot resolve(BudgetV2SnapshotSource source) =>
      _cache.resolve(source).prepared;
}

class _BudgetV2AvatarAccumulator {
  _BudgetV2AvatarAccumulator({
    required this.avatarKey,
    required this.weekEndDate,
    this.bar,
    this.overviewItem,
  }) : weekStartDate = weekEndDate.subtract(const Duration(days: 6));

  final String avatarKey;
  final CategoryBudgetBarData? bar;
  final OverviewBudgetData? overviewItem;
  final DateTime weekEndDate;
  final DateTime weekStartDate;
  final List<TransactionRecord> records = <TransactionRecord>[];
  final Map<String, _BudgetV2VendorAccumulator> vendors =
      <String, _BudgetV2VendorAccumulator>{};
  final List<double> weeklyAmounts = List<double>.filled(7, 0);

  void add(TransactionRecord record) {
    records.add(record);
    final name = record.displayMerchant.trim();
    if (name.isNotEmpty) {
      vendors
          .putIfAbsent(name, () => _BudgetV2VendorAccumulator(name))
          .add(record);
    }
    final date = DateTime.tryParse(record.normalizedDate);
    if (date == null ||
        date.isBefore(weekStartDate) ||
        date.isAfter(weekEndDate)) {
      return;
    }
    weeklyAmounts[date.difference(weekStartDate).inDays] += record.amount.abs();
  }

  BudgetV2AvatarSnapshot freeze() {
    final frozenVendors =
        vendors.values.map((vendor) => vendor.freeze()).toList()
          ..sort((left, right) {
            final amountOrder = right.amount.compareTo(left.amount);
            return amountOrder != 0
                ? amountOrder
                : left.name.compareTo(right.name);
          });
    return BudgetV2AvatarSnapshot(
      avatarKey: avatarKey,
      bar: bar,
      overviewItem: overviewItem,
      records: List<TransactionRecord>.unmodifiable(records),
      vendors: List<BudgetV2VendorAggregate>.unmodifiable(frozenVendors),
      weeklyAmounts: List<double>.unmodifiable(weeklyAmounts),
      recordsByVendorKey: Map<String, List<TransactionRecord>>.unmodifiable(
        <String, List<TransactionRecord>>{
          for (final vendor in vendors.values)
            _budgetV2VendorKey(vendor.name):
                List<TransactionRecord>.unmodifiable(vendor.records),
        },
      ),
    );
  }
}

class _BudgetV2VendorAccumulator {
  _BudgetV2VendorAccumulator(this.name);

  final String name;
  var amount = 0.0;
  var count = 0;
  final List<TransactionRecord> records = <TransactionRecord>[];
  final Map<int, double> amountByCategory = <int, double>{};

  void add(TransactionRecord record) {
    records.add(record);
    final recordAmount = record.amount.abs();
    amount += recordAmount;
    count += 1;
    final categoryId = record.transactionCategoryID;
    if (categoryId != null) {
      amountByCategory.update(
        categoryId,
        (value) => value + recordAmount,
        ifAbsent: () => recordAmount,
      );
    }
  }

  BudgetV2VendorAggregate freeze() {
    final categories = amountByCategory.entries.toList()
      ..sort((left, right) {
        final amountOrder = right.value.compareTo(left.value);
        return amountOrder != 0 ? amountOrder : left.key.compareTo(right.key);
      });
    return BudgetV2VendorAggregate(
      key: _budgetV2VendorKey(name),
      name: name,
      amount: amount,
      count: count,
      leadingCategoryId: categories.firstOrNull?.key,
    );
  }
}

String _budgetV2VendorKey(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
