import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../query/domain/ghost_filter_mode.dart';

/// A compact cycle control for the dashboard-wide ghost query dimension.
///
/// It intentionally owns no filter state. Its parent atomically publishes a
/// prepared ghost-membership projection, so this control can react on the
/// next frame without creating a widget-local filtering implementation.
final class DashboardGhostQuickFilter extends StatelessWidget {
  const DashboardGhostQuickFilter({
    super.key,
    required this.mode,
    required this.onTap,
  });

  final GhostFilterMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      GhostFilterMode.nonGhost => Icons.layers_clear_outlined,
      GhostFilterMode.onlyGhost => Icons.auto_awesome_outlined,
      GhostFilterMode.both => Icons.layers_outlined,
    };
    final dotCount = GhostFilterMode.values.length;
    final selectedIndex = GhostFilterMode.values.indexOf(mode);
    return Semantics(
      button: true,
      label: 'Ghost gyorsszűrő: ${mode.semanticLabel}',
      hint: 'Következő állapot',
      child: Tooltip(
        message: mode.semanticLabel,
        child: SizedBox(
          key: const ValueKey('dashboard-ghost-quick-filter'),
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 21,
                      color: FluviVisualTokens.textSecondary,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(dotCount, (index) {
                        final active = index == selectedIndex;
                        return Container(
                          width: active ? 5 : 3,
                          height: active ? 5 : 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: FluviVisualTokens.textSecondary.withValues(
                              alpha: active ? .85 : .28,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
