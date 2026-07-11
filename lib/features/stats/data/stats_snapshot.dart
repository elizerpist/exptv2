import '../../transactions/models/transaction_category.dart';

enum StatsLayoutMode { sum, year, month }

class StatsSnapshotState {
  const StatsSnapshotState({
    required this.categoryScopeIds,
    required this.vendorScopeNames,
    required this.activeType,
    required this.threshold,
    required this.layoutMode,
    required this.activeYear,
    required this.activeMonth,
    required this.pageIndex,
  });

  final Set<int> categoryScopeIds;
  final Set<String> vendorScopeNames;
  final TransactionType activeType;
  final double threshold;
  final StatsLayoutMode layoutMode;
  final int activeYear;
  final int activeMonth;
  final int pageIndex;

  StatsSnapshotState copyWith({
    Set<int>? categoryScopeIds,
    Set<String>? vendorScopeNames,
    TransactionType? activeType,
    double? threshold,
    StatsLayoutMode? layoutMode,
    int? activeYear,
    int? activeMonth,
    int? pageIndex,
  }) {
    return StatsSnapshotState(
      categoryScopeIds: categoryScopeIds ?? this.categoryScopeIds,
      vendorScopeNames: vendorScopeNames ?? this.vendorScopeNames,
      activeType: activeType ?? this.activeType,
      threshold: threshold ?? this.threshold,
      layoutMode: layoutMode ?? this.layoutMode,
      activeYear: activeYear ?? this.activeYear,
      activeMonth: activeMonth ?? this.activeMonth,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}

class StatsSnapshot {
  const StatsSnapshot({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.includeCategoryScope,
    required this.includeVendorScope,
    required this.includeActiveType,
    required this.includeThreshold,
    required this.includeLayoutMode,
    required this.includePageIndex,
    this.categoryScopeIds = const <int>{},
    this.vendorScopeNames = const <String>{},
    this.activeType,
    this.threshold,
    this.layoutMode,
    this.activeYear,
    this.activeMonth,
    this.pageIndex,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool includeCategoryScope;
  final bool includeVendorScope;
  final bool includeActiveType;
  final bool includeThreshold;
  final bool includeLayoutMode;
  final bool includePageIndex;
  final Set<int> categoryScopeIds;
  final Set<String> vendorScopeNames;
  final TransactionType? activeType;
  final double? threshold;
  final StatsLayoutMode? layoutMode;
  final int? activeYear;
  final int? activeMonth;
  final int? pageIndex;

  StatsSnapshotState applyTo(StatsSnapshotState current) {
    return current.copyWith(
      categoryScopeIds: includeCategoryScope ? categoryScopeIds : null,
      vendorScopeNames: includeVendorScope ? vendorScopeNames : null,
      activeType: includeActiveType ? activeType : null,
      threshold: includeThreshold ? threshold : null,
      layoutMode: includeLayoutMode ? layoutMode : null,
      activeYear: includeLayoutMode ? activeYear : null,
      activeMonth: includeLayoutMode ? activeMonth : null,
      // Stored page metadata remains serializable for compatibility, but
      // snapshot recall never owns chevron-only page navigation.
      pageIndex: current.pageIndex,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'includeCategoryScope': includeCategoryScope,
      'includeVendorScope': includeVendorScope,
      'includeActiveType': includeActiveType,
      'includeThreshold': includeThreshold,
      'includeLayoutMode': includeLayoutMode,
      'includePageIndex': includePageIndex,
      'categoryScopeIds': categoryScopeIds.toList()..sort(),
      'vendorScopeNames': vendorScopeNames.toList()..sort(),
      'activeType': activeType?.name,
      'threshold': threshold,
      'layoutMode': layoutMode?.name,
      'activeYear': activeYear,
      'activeMonth': activeMonth,
      'pageIndex': pageIndex,
    };
  }

  static StatsSnapshot fromJson(Map<String, Object?> json) {
    return StatsSnapshot(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
      includeCategoryScope: json['includeCategoryScope'] == true,
      includeVendorScope: json['includeVendorScope'] == true,
      includeActiveType: json['includeActiveType'] == true,
      includeThreshold: json['includeThreshold'] == true,
      includeLayoutMode: json['includeLayoutMode'] == true,
      includePageIndex: json['includePageIndex'] == true,
      categoryScopeIds: _intSet(json['categoryScopeIds']),
      vendorScopeNames: _stringSet(json['vendorScopeNames']),
      activeType: _transactionType(json['activeType']),
      threshold: (json['threshold'] as num?)?.toDouble(),
      layoutMode: _layoutMode(json['layoutMode']),
      activeYear: (json['activeYear'] as num?)?.toInt(),
      activeMonth: (json['activeMonth'] as num?)?.toInt(),
      pageIndex: (json['pageIndex'] as num?)?.toInt(),
    );
  }

  static Set<int> _intSet(Object? value) {
    if (value is! List) return const <int>{};
    return {
      for (final item in value)
        if (item is num) item.toInt(),
    };
  }

  static DateTime _dateTime(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const <String>{};
    return {
      for (final item in value)
        if (item.toString().trim().isNotEmpty) item.toString(),
    };
  }

  static TransactionType? _transactionType(Object? value) {
    return switch (value?.toString()) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => null,
    };
  }

  static StatsLayoutMode? _layoutMode(Object? value) {
    return switch (value?.toString()) {
      'sum' => StatsLayoutMode.sum,
      'year' => StatsLayoutMode.year,
      'month' => StatsLayoutMode.month,
      _ => null,
    };
  }
}

class StatsSnapshotRecallGeneration {
  var _latest = 0;

  StatsSnapshotRecallToken begin() {
    return StatsSnapshotRecallToken._(this, ++_latest);
  }

  bool _isLatest(int value) => value == _latest;
}

class StatsSnapshotRecallToken {
  const StatsSnapshotRecallToken._(this._owner, this.value);

  final StatsSnapshotRecallGeneration _owner;
  final int value;

  bool get isLatest => _owner._isLatest(value);
}

abstract class StatsSnapshotRepository {
  Future<List<StatsSnapshot>> load();

  Future<void> upsert(StatsSnapshot snapshot);
}

class InMemoryStatsSnapshotRepository extends StatsSnapshotRepository {
  List<StatsSnapshot> _snapshots;

  InMemoryStatsSnapshotRepository([List<StatsSnapshot>? initial])
    : _snapshots = List<StatsSnapshot>.from(initial ?? const <StatsSnapshot>[]);

  @override
  Future<List<StatsSnapshot>> load() async => List.unmodifiable(_snapshots);

  @override
  Future<void> upsert(StatsSnapshot snapshot) async {
    _snapshots = [
      for (final item in _snapshots)
        if (item.id != snapshot.id) item,
      snapshot,
    ]..sort(_compareSnapshots);
  }
}

int compareStatsSnapshots(StatsSnapshot left, StatsSnapshot right) =>
    _compareSnapshots(left, right);

int _compareSnapshots(StatsSnapshot left, StatsSnapshot right) {
  final createdAt = left.createdAt.compareTo(right.createdAt);
  return createdAt != 0 ? createdAt : left.id.compareTo(right.id);
}
