import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';

/// A deterministic future-feature surface. It intentionally owns no Ghost or
/// Forecast data and does not imply that zero-valued financial data exists.
class BalanceFuturePlaceholderCard extends StatelessWidget {
  const BalanceFuturePlaceholderCard.ghost({super.key})
    : _kind = _FutureKind.ghost;

  const BalanceFuturePlaceholderCard.forecast({super.key})
    : _kind = _FutureKind.forecast;

  final _FutureKind _kind;

  @override
  Widget build(BuildContext context) {
    final title = switch (_kind) {
      _FutureKind.ghost => 'Fix terhek',
      _FutureKind.forecast => 'Forecast',
    };
    final body = switch (_kind) {
      _FutureKind.ghost =>
        'A pending és aktiválódott Ghost tételek itt jelennek meg.',
      _FutureKind.forecast =>
        'A várható zárás a Ghost és előrejelzési adatok bekötése után jelenik meg.',
    };
    final secondary = switch (_kind) {
      _FutureKind.ghost => 'A Ghost funkció még nincs bekötve.',
      _FutureKind.forecast => 'Az előrejelzéshez még nincs adatforrás.',
    };
    final key = _kind == _FutureKind.ghost
        ? const ValueKey<String>('balance-linked-detail-ghost')
        : const ValueKey<String>('balance-linked-detail-forecast');
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 168 || constraints.maxHeight < 132) {
          return KeyedSubtree(
            key: key,
            child: Center(child: Text(title)),
          );
        }
        return KeyedSubtree(
          key: key,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: FluviVisualTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hamarosan',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: FluviVisualTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FluviVisualTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  secondary,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _FutureKind { ghost, forecast }
