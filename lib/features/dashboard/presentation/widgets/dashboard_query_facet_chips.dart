import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_visual_resolver.dart';
import '../../query/application/current_query_controller.dart';
import '../../query/domain/query_menu_data.dart';
import '../../query/domain/ledger_direction.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';

/// Applied query facet preview positioned directly below the LogBox count.
///
/// It reads one centralized applied scope/presentation owner. Tapping a chip
/// only forwards an intent; canonical query replacement stays in the dashboard
/// composition root.
final class DashboardQueryFacetChips extends StatelessWidget {
  const DashboardQueryFacetChips({
    super.key,
    required this.currentQuery,
    this.visibleFrames,
    this.direction,
    required this.onRemoveCategory,
    required this.onRemovePartner,
    required this.onClear,
  });

  final CurrentQueryController currentQuery;
  final DashboardVisibleFrameStore? visibleFrames;
  final LedgerDirection? direction;
  final ValueChanged<String> onRemoveCategory;
  final ValueChanged<String> onRemovePartner;
  final VoidCallback onClear;

  static const double height = 37;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[currentQuery, ?visibleFrames]),
    builder: (context, _) {
      final activeDirection =
          direction ??
          visibleFrames?.value?.direction ??
          LedgerDirection.income;
      final scope = currentQuery.scopeFor(activeDirection);
      final facets = currentQuery.facetPresentationFor(activeDirection);
      if (facets == null) {
        return const SizedBox.shrink();
      }
      final categories = facets.categories
          .where((item) => scope.categoryIds.contains(item.id))
          .toList(growable: false);
      final partners = facets.partners
          .where((item) => scope.partnerIds.contains(item.id))
          .toList(growable: false);
      if (categories.isEmpty && partners.isEmpty) {
        return const SizedBox.shrink();
      }
      return SizedBox(
        key: const ValueKey('dashboard-query-facet-chips'),
        height: height,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(1, 2, 1, 4),
                children: [
                  for (final category in categories) ...[
                    _QueryFacetChip.category(
                      category: category,
                      onTap: () => onRemoveCategory(category.id),
                    ),
                    const SizedBox(width: 7),
                  ],
                  for (final partner in partners) ...[
                    _QueryFacetChip.partner(
                      partner: partner,
                      onTap: () => onRemovePartner(partner.id),
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('dashboard-query-clear'),
              tooltip: 'Lekérdezés törlése',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16),
              color: const Color(0xFF61718B),
              style: IconButton.styleFrom(
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  side: BorderSide(color: Color(0x1430405A)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

final class _QueryFacetChip extends StatelessWidget {
  const _QueryFacetChip.category({required this.category, required this.onTap})
    : partner = null;

  const _QueryFacetChip.partner({required this.partner, required this.onTap})
    : category = null;

  final QueryMenuCategoryFacet? category;
  final QueryMenuPartnerFacet? partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorId = category?.colorId ?? partner!.categoryColorId;
    final iconId = category?.iconId ?? partner!.categoryIconId;
    final visual = CategoryVisualResolver.resolve(
      colorId: colorId,
      iconId: iconId,
    );
    final tint = visual.gradient.middleColor;
    final name = category?.displayName ?? partner!.displayName;
    final keyPrefix = category == null ? 'partner' : 'category';
    final id = category?.id ?? partner!.id;
    return TextButton(
      key: ValueKey('dashboard-query-$keyPrefix-$id'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.fromLTRB(10, 0, 7, 0),
        foregroundColor: tint,
        backgroundColor: tint.withValues(alpha: .11),
        shape: StadiumBorder(
          side: BorderSide(color: tint.withValues(alpha: .25)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (partner != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: const SizedBox(width: 5, height: 5),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, size: 13),
        ],
      ),
    );
  }
}
