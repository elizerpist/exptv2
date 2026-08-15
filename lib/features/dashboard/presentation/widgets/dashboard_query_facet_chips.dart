import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_visual_resolver.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../query/application/current_query_controller.dart';
import '../../query/domain/ledger_direction.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';

/// Applied Query facets and temporary focus facets below the LogBox count.
///
/// Base facets retain their existing intent: closing them mutates the committed
/// query through the composition root. A focus facet is intentionally a
/// different projection: closing it clears only that ephemeral dimension and
/// never reconstructs or edits the base query.
final class DashboardQueryFacetChips extends StatelessWidget {
  const DashboardQueryFacetChips({
    super.key,
    required this.currentQuery,
    this.visibleFrames,
    this.direction,
    this.focus,
    required this.onRemoveCategory,
    required this.onRemovePartner,
    required this.onClear,
    this.onClearFocusCategory,
    this.onClearFocusPartner,
    this.onClearFocus,
  });

  final CurrentQueryController currentQuery;
  final DashboardVisibleFrameStore? visibleFrames;
  final LedgerDirection? direction;
  final DashboardEphemeralFocusController? focus;
  final ValueChanged<String> onRemoveCategory;
  final ValueChanged<String> onRemovePartner;
  final VoidCallback onClear;
  final VoidCallback? onClearFocusCategory;
  final VoidCallback? onClearFocusPartner;
  final VoidCallback? onClearFocus;

  static const double height = 37;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[
      currentQuery,
      ?visibleFrames,
      ?focus,
    ]),
    builder: (context, _) {
      final activeDirection =
          direction ??
          visibleFrames?.value?.direction ??
          LedgerDirection.income;
      final scope = currentQuery.scopeFor(activeDirection);
      final facets = currentQuery.facetPresentationFor(activeDirection);
      final state = focus?.state;
      final activeFocus = state?.anchor.direction == activeDirection
          ? state
          : null;
      final categoryFocus = activeFocus?.category;
      final partnerFocus = activeFocus?.partner;
      final categories = categoryFocus == null
          ? <_DashboardFacetChipModel>[
              for (final category in facets?.categories ?? const [])
                if (scope.categoryIds.contains(category.id))
                  _DashboardFacetChipModel(
                    id: category.id,
                    displayName: category.displayName,
                    colorId: category.colorId,
                    iconId: category.iconId,
                    isPartner: false,
                    isFocus: false,
                    onPressed: () => onRemoveCategory(category.id),
                  ),
            ]
          : <_DashboardFacetChipModel>[
              _DashboardFacetChipModel.focus(
                facet: categoryFocus,
                isPartner: false,
                onPressed: onClearFocusCategory,
              ),
            ];
      final partners = partnerFocus == null
          ? <_DashboardFacetChipModel>[
              for (final partner in facets?.partners ?? const [])
                if (scope.partnerIds.contains(partner.id))
                  _DashboardFacetChipModel(
                    id: partner.id,
                    displayName: partner.displayName,
                    colorId: partner.categoryColorId,
                    iconId: partner.categoryIconId,
                    isPartner: true,
                    isFocus: false,
                    onPressed: () => onRemovePartner(partner.id),
                  ),
            ]
          : <_DashboardFacetChipModel>[
              _DashboardFacetChipModel.focus(
                facet: partnerFocus,
                isPartner: true,
                onPressed: onClearFocusPartner,
              ),
            ];
      if (categories.isEmpty && partners.isEmpty) {
        return const SizedBox.shrink();
      }
      final hasFocus = categoryFocus != null || partnerFocus != null;
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
                    _QueryFacetChip(model: category),
                    const SizedBox(width: 7),
                  ],
                  for (final partner in partners) ...[
                    _QueryFacetChip(model: partner),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('dashboard-query-clear'),
              tooltip: hasFocus ? 'Fókusz törlése' : 'Lekérdezés törlése',
              onPressed: hasFocus ? (onClearFocus ?? onClear) : onClear,
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

@immutable
final class _DashboardFacetChipModel {
  const _DashboardFacetChipModel({
    required this.id,
    required this.displayName,
    required this.colorId,
    required this.iconId,
    required this.isPartner,
    required this.isFocus,
    required this.onPressed,
  });

  factory _DashboardFacetChipModel.focus({
    required DashboardFocusFacet facet,
    required bool isPartner,
    required VoidCallback? onPressed,
  }) => _DashboardFacetChipModel(
    id: facet.id,
    displayName: facet.displayName,
    colorId: facet.colorId ?? '',
    iconId: facet.iconId ?? '',
    isPartner: isPartner,
    isFocus: true,
    onPressed: onPressed ?? () {},
  );

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
  final bool isPartner;
  final bool isFocus;
  final VoidCallback onPressed;
}

final class _QueryFacetChip extends StatelessWidget {
  const _QueryFacetChip({required this.model});

  final _DashboardFacetChipModel model;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisualResolver.resolve(
      colorId: model.colorId,
      iconId: model.iconId,
    );
    final tint = visual.gradient.middleColor;
    final kind = model.isPartner ? 'partner' : 'category';
    final prefix = model.isFocus ? 'dashboard-focus' : 'dashboard-query';
    return TextButton(
      key: ValueKey('$prefix-$kind-${model.id}'),
      onPressed: model.onPressed,
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
          if (model.isPartner) ...[
            DecoratedBox(
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: const SizedBox(width: 5, height: 5),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            model.displayName,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, size: 13),
        ],
      ),
    );
  }
}
