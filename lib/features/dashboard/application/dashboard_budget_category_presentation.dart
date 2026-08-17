import 'package:flutter/foundation.dart';

import '../../../core/categories/domain/fluvi_category.dart';

/// Immutable presentation-only category identity for the Budget avatar rail.
///
/// This intentionally carries no budget calculation, selected-category state,
/// or repository handle. Its order is the authoritative category inventory
/// order supplied by the root application owner.
@immutable
final class BudgetCategoryAvatarPresentationItem {
  const BudgetCategoryAvatarPresentationItem({
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

/// Derives immutable Budget avatar input from the root category collection.
///
/// Query facets are specific to the Query editor and intentionally do not
/// participate in this application-inventory presentation boundary.
final class DashboardBudgetCategoryPresentation
    extends ValueNotifier<List<BudgetCategoryAvatarPresentationItem>> {
  DashboardBudgetCategoryPresentation({
    required ValueListenable<List<FluviCategory>> categoryCollection,
    ValueChanged<int>? onInputUpdated,
  }) : _categoryCollection = categoryCollection,
       _onInputUpdated = onInputUpdated,
       super(const <BudgetCategoryAvatarPresentationItem>[]) {
    _categoryCollection.addListener(_refresh);
    _refresh(initial: true);
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueChanged<int>? _onInputUpdated;

  void _refresh({bool initial = false}) {
    final next = List<BudgetCategoryAvatarPresentationItem>.unmodifiable([
      for (final category in _categoryCollection.value)
        BudgetCategoryAvatarPresentationItem(
          id: category.id,
          displayName: category.name,
          colorId: category.colorId,
          iconId: category.iconId,
        ),
    ]);
    if (!initial && _sameItems(value, next)) return;
    value = next;
    _onInputUpdated?.call(next.length);
  }

  static bool _sameItems(
    List<BudgetCategoryAvatarPresentationItem> left,
    List<BudgetCategoryAvatarPresentationItem> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      final previous = left[index];
      final next = right[index];
      if (previous.id != next.id ||
          previous.displayName != next.displayName ||
          previous.colorId != next.colorId ||
          previous.iconId != next.iconId) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _categoryCollection.removeListener(_refresh);
    super.dispose();
  }
}
