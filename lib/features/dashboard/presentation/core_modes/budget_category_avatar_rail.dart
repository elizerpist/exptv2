import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_catalog.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
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
          color: CategoryColorCatalog.resolve(item.colorId).middleColor,
          artworkIdentity: CategoryColorCatalog.handleOf(item.colorId),
          icon: atlas.categoryIcon(CategoryIconCatalog.handleOf(item.iconId)),
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
              height: BudgetCategoryAvatarGeometry.avatarCanvasSize,
              semanticsLabelBuilder: (item) => item.displayName,
              itemBuilder: (context, item, metrics) => SizedBox.square(
                dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
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
    required this.color,
    required this.artworkIdentity,
    required this.icon,
  }) : _normalArtworkSource = BudgetCategoryAvatarSvg.flutterRenderable(
         BudgetCategoryAvatarSvg.avatarDisc(
           color,
           artworkIdentity,
           variant: BudgetCategoryAvatarVariant.normalRail,
         ),
       ),
       _centeredCoreArtworkSource = BudgetCategoryAvatarSvg.flutterRenderable(
         BudgetCategoryAvatarSvg.avatarDisc(
           color,
           artworkIdentity,
           variant: BudgetCategoryAvatarVariant.centeredCore,
         ),
       );

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
  final Color color;
  final int artworkIdentity;
  final PreparedVectorPicture icon;

  /// Both visual variants are prepared with category input changes. Ticks only
  /// select a ready source; they never build or parse SVG markup.
  final String _normalArtworkSource;
  final String _centeredCoreArtworkSource;

  Widget avatarFor({required bool selected}) => BudgetCategoryAvatarArtwork(
    key: selected ? const ValueKey('budget-category-avatar-center') : null,
    color: color,
    icon: icon,
    semanticsLabel: displayName,
    svgSource: selected ? _centeredCoreArtworkSource : _normalArtworkSource,
    selected: selected,
  );
}

int _modulo(int value, int divisor) => ((value % divisor) + divisor) % divisor;
