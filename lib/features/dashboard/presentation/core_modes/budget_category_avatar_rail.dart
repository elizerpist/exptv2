import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_catalog.dart';
import '../../../../core/categories/presentation/glossy_category_avatar.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_budget_category_presentation.dart';

/// Budget card1's presentation-only, five-position category avatar rail.
///
/// It owns neither category data nor a business selection. The only mutable
/// state is the shared carousel controller's local visual center.
class BudgetCategoryAvatarRail extends StatefulWidget {
  const BudgetCategoryAvatarRail({super.key, required this.categories});

  final ValueListenable<List<BudgetCategoryAvatarPresentationItem>> categories;

  @override
  State<BudgetCategoryAvatarRail> createState() =>
      _BudgetCategoryAvatarRailState();
}

class _BudgetCategoryAvatarRailState extends State<BudgetCategoryAvatarRail> {
  static const _itemExtent = 58.0;
  static const _canvasSize = 72.0;
  static const _iconSize = 30.0;

  late final CenteredCarouselController _controller;
  late final CenteredCarouselSpec _spec;
  List<_PreparedBudgetCategoryAvatar> _items =
      const <_PreparedBudgetCategoryAvatar>[];

  @override
  void initState() {
    super.initState();
    _controller = CenteredCarouselController(initialIndex: 0);
    _spec = CenteredCarouselPresets.budgetCategoryAvatarRail(
      itemExtent: _itemExtent,
    );
    _replaceItems(widget.categories.value, initial: true);
    widget.categories.addListener(_onCategoriesChanged);
  }

  @override
  void didUpdateWidget(covariant BudgetCategoryAvatarRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.categories, widget.categories)) return;
    oldWidget.categories.removeListener(_onCategoriesChanged);
    widget.categories.addListener(_onCategoriesChanged);
    _onCategoriesChanged();
  }

  @override
  void dispose() {
    widget.categories.removeListener(_onCategoriesChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onCategoriesChanged() {
    if (_replaceItems(widget.categories.value) && mounted) setState(() {});
  }

  bool _replaceItems(
    List<BudgetCategoryAvatarPresentationItem> next, {
    bool initial = false,
  }) {
    if (_sameItems(_items, next)) return false;
    final previousCenterId = _items.isEmpty
        ? null
        : _items[_modulo(_controller.selectedLogicalIndex, _items.length)].id;
    final prepared = _prepareItems(next);
    final nextCenter = previousCenterId == null
        ? 0
        : prepared.indexWhere((item) => item.id == previousCenterId);
    _items = prepared;
    if (!initial && prepared.isNotEmpty) {
      _controller.installSemanticDomain(
        dataMode: CenteredCarouselDataMode.cyclic,
        finiteLength: prepared.length,
        selectedLogicalIndex: nextCenter < 0 ? 0 : nextCenter,
      );
    }
    return true;
  }

  List<_PreparedBudgetCategoryAvatar> _prepareItems(
    List<BudgetCategoryAvatarPresentationItem> source,
  ) {
    if (source.isEmpty) return const <_PreparedBudgetCategoryAvatar>[];
    final atlas = PreparedVectorAssetAtlas.instance;
    if (!atlas.isReady) return const <_PreparedBudgetCategoryAvatar>[];
    return List<_PreparedBudgetCategoryAvatar>.unmodifiable([
      for (final item in source)
        _PreparedBudgetCategoryAvatar(
          id: item.id,
          displayName: item.displayName,
          colorId: item.colorId,
          iconId: item.iconId,
          gradient: atlas.categoryGradient(
            CategoryColorCatalog.handleOf(item.colorId),
          ),
          icon: atlas.categoryIcon(CategoryIconCatalog.handleOf(item.iconId)),
          canvasSize: _canvasSize,
          iconSize: _iconSize,
        ),
    ]);
  }

  bool _sameItems(
    List<_PreparedBudgetCategoryAvatar> current,
    List<BudgetCategoryAvatarPresentationItem> next,
  ) {
    if (current.length != next.length) return false;
    for (var index = 0; index < current.length; index += 1) {
      final existing = current[index];
      final candidate = next[index];
      if (existing.id != candidate.id ||
          existing.displayName != candidate.displayName ||
          existing.colorId != candidate.colorId ||
          existing.iconId != candidate.iconId) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: const ValueKey('budget-category-avatar-rail'),
    child: _items.isEmpty
        ? const SizedBox.shrink()
        : RepaintBoundary(
            child: CenteredCarousel<_PreparedBudgetCategoryAvatar>(
              key: const ValueKey('budget-category-avatar-carousel'),
              dataSource:
                  CyclicCarouselDataSource<_PreparedBudgetCategoryAvatar>(
                    _items,
                  ),
              controller: _controller,
              spec: _spec,
              height: _canvasSize,
              semanticsLabelBuilder: (item) => item.displayName,
              itemBuilder: (context, item, metrics) => SizedBox.square(
                dimension: _canvasSize,
                child: item.avatarFor(selected: metrics.isSelected),
              ),
            ),
          ),
  );
}

class _PreparedBudgetCategoryAvatar {
  _PreparedBudgetCategoryAvatar({
    required this.id,
    required this.displayName,
    required this.colorId,
    required this.iconId,
    required this.gradient,
    required this.icon,
    required this.canvasSize,
    required this.iconSize,
  });

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
  final Gradient gradient;
  final PreparedVectorPicture icon;
  final double canvasSize;
  final double iconSize;

  late final GlossyCategoryAvatar _unselectedAvatar = _buildAvatar(
    selected: false,
  );
  late final GlossyCategoryAvatar _selectedAvatar = _buildAvatar(
    selected: true,
  );

  Widget avatarFor({required bool selected}) =>
      selected ? _selectedAvatar : _unselectedAvatar;

  GlossyCategoryAvatar _buildAvatar({required bool selected}) =>
      GlossyCategoryAvatar(
        key: selected ? const ValueKey('budget-category-avatar-center') : null,
        gradient: gradient,
        icon: icon,
        semanticsLabel: displayName,
        size: canvasSize,
        iconSize: iconSize,
        selected: selected,
        scaleSelection: false,
        animateBodySize: false,
      );
}

int _modulo(int value, int divisor) => ((value % divisor) + divisor) % divisor;
