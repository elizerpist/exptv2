class StatsScopeSelection {
  const StatsScopeSelection._({
    required this.isAll,
    required this.selectedCategoryIds,
  });

  final bool isAll;
  final Set<int> selectedCategoryIds;

  String get chipLabel => isAll ? 'ALL' : selectedCategoryIds.length.toString();

  bool includesCategory(int? categoryId) {
    if (isAll) return true;
    return categoryId != null && selectedCategoryIds.contains(categoryId);
  }

  static StatsScopeSelection normalize({
    required Set<int> selectedCategoryIds,
    required Set<int> availableCategoryIds,
  }) {
    final filtered = selectedCategoryIds
        .where(availableCategoryIds.contains)
        .toSet();
    if (filtered.isEmpty || filtered.length == availableCategoryIds.length) {
      return const StatsScopeSelection._(
        isAll: true,
        selectedCategoryIds: <int>{},
      );
    }
    return StatsScopeSelection._(
      isAll: false,
      selectedCategoryIds: Set.unmodifiable(filtered),
    );
  }
}
