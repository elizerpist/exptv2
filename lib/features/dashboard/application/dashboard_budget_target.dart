import 'package:flutter/foundation.dart';

import '../query/domain/ledger_direction.dart';

/// Typed Budget-domain identity. Aggregate is deliberately not a category ID.
sealed class DashboardBudgetTargetIdentity {
  const DashboardBudgetTargetIdentity();
}

final class DashboardBudgetAggregateTarget
    extends DashboardBudgetTargetIdentity {
  const DashboardBudgetAggregateTarget();

  @override
  bool operator ==(Object other) => other is DashboardBudgetAggregateTarget;

  @override
  int get hashCode => Object.hash(DashboardBudgetAggregateTarget, 0);
}

final class DashboardBudgetCategoryTarget
    extends DashboardBudgetTargetIdentity {
  const DashboardBudgetCategoryTarget(this.categoryId)
    : assert(categoryId != 'aggregate');

  final String categoryId;

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetCategoryTarget && other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(DashboardBudgetCategoryTarget, categoryId);
}

/// Stable visual source supplied by the root category collection, not by a
/// database call from the rail.
@immutable
final class DashboardBudgetCategoryVisual {
  const DashboardBudgetCategoryVisual({
    required this.id,
    required this.displayName,
    required this.colorId,
    required this.iconId,
  });

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
}

/// Exact aggregate values from the approved local visual reference.
@immutable
final class DashboardBudgetAggregateVisual {
  const DashboardBudgetAggregateVisual._({
    required this.title,
    required this.iconAssetKey,
    required this.colorSlot,
    required this.startColorArgb,
    required this.middleColorArgb,
    required this.endColorArgb,
  });

  factory DashboardBudgetAggregateVisual.forDirection(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.expense => expense,
    LedgerDirection.income => income,
  };

  static const expense = DashboardBudgetAggregateVisual._(
    title: 'Budget',
    iconAssetKey: 'dollar-sign',
    colorSlot: 11,
    startColorArgb: 0xff22d3ee,
    middleColorArgb: 0xff2bc4f3,
    endColorArgb: 0xff39b8f4,
  );

  static const income = DashboardBudgetAggregateVisual._(
    title: 'Összbevételi cél',
    iconAssetKey: 'banknote',
    colorSlot: 16,
    startColorArgb: 0xff7c4dff,
    middleColorArgb: 0xff8b45ed,
    endColorArgb: 0xff9a3ddb,
  );

  final String title;
  final String iconAssetKey;
  final int colorSlot;
  final int startColorArgb;
  final int middleColorArgb;
  final int endColorArgb;
}

@immutable
final class DashboardBudgetTarget {
  const DashboardBudgetTarget.aggregate({this.handle = 0})
    : identity = const DashboardBudgetAggregateTarget(),
      category = null;

  const DashboardBudgetTarget._({
    required this.handle,
    required this.identity,
    this.category,
  });

  final int handle;
  final DashboardBudgetTargetIdentity identity;
  final DashboardBudgetCategoryVisual? category;

  bool get isAggregate => identity is DashboardBudgetAggregateTarget;
}

/// Immutable exact-revision target catalog. Handle zero is reserved for the
/// non-category aggregate; inventory order remains untouched for handles 1+.
@immutable
final class DashboardBudgetTargetCatalog {
  DashboardBudgetTargetCatalog._(this._targets)
    : assert(_targets.isNotEmpty),
      assert(_targets.first.identity is DashboardBudgetAggregateTarget);

  factory DashboardBudgetTargetCatalog.fromCategories(
    List<DashboardBudgetCategoryVisual> categories,
  ) => DashboardBudgetTargetCatalog._(
    List<DashboardBudgetTarget>.unmodifiable(<DashboardBudgetTarget>[
      const DashboardBudgetTarget._(
        handle: 0,
        identity: DashboardBudgetAggregateTarget(),
      ),
      for (var index = 0; index < categories.length; index += 1)
        DashboardBudgetTarget._(
          handle: index + 1,
          identity: DashboardBudgetCategoryTarget(categories[index].id),
          category: categories[index],
        ),
    ]),
  );

  final List<DashboardBudgetTarget> _targets;

  int get targetCount => _targets.length;
  List<DashboardBudgetTarget> get targets => _targets;

  DashboardBudgetTarget targetAtHandle(int handle) => _targets[handle];
}
