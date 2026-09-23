import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// Read-only indicators for the real Balance insight domain.
///
/// The parent owns selection; indicators intentionally collect no gestures so
/// they cannot compete with the Header or carousel gesture owners.
class BalanceInsightIndicators extends StatelessWidget {
  const BalanceInsightIndicators({
    super.key,
    required this.bounds,
    required this.itemIds,
    required this.activeItemId,
  });

  final DashboardBounds bounds;
  final List<String> itemIds;
  final String activeItemId;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey<String>('dashboard-core-mode-balance-dots'),
    width: bounds.width,
    height: bounds.height,
    child: Semantics(
      label: 'Balance insight indicators',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final itemId in itemIds)
            _BalanceInsightIndicator(
              itemId: itemId,
              active: itemId == activeItemId,
            ),
        ],
      ),
    ),
  );
}

final class _BalanceInsightIndicator extends StatelessWidget {
  const _BalanceInsightIndicator({required this.itemId, required this.active});

  final String itemId;
  final bool active;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    label: 'Balance insight $itemId',
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluviVisualTokens.dotHorizontalInset,
      ),
      child: DecoratedBox(
        key: ValueKey<String>('balance-insight-indicator-$itemId'),
        decoration: BoxDecoration(
          gradient: active ? FluviVisualTokens.appHighlightGradient : null,
          color: active ? null : FluviVisualTokens.placeholderDotInactive,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: FluviVisualTokens.dotSize,
          height: FluviVisualTokens.dotSize,
        ),
      ),
    ),
  );
}
