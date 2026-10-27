import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
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
                    _GhostQuickFilterIcon(mode: mode),
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

/// One stable ghost silhouette occupies the complete 24px icon field in every
/// state.  The slash and plus are overlays, so neither state relies on colour
/// alone and the button never changes height while it cycles.
final class _GhostQuickFilterIcon extends StatelessWidget {
  const _GhostQuickFilterIcon({required this.mode});

  final GhostFilterMode mode;

  @override
  Widget build(BuildContext context) {
    final color = FluviVisualTokens.textSecondary;
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: CategoryIconView(
              picture: PreparedVectorAssetAtlas.instance.categoryIcon(
                CategoryIconCatalog.handleOf('icon_28'),
              ),
              size: 24,
              color: color,
            ),
          ),
          if (mode == GhostFilterMode.nonGhost)
            Positioned.fill(
              child: CustomPaint(painter: _GhostSlashPainter(color)),
            ),
          if (mode == GhostFilterMode.both)
            Positioned(
              right: -1,
              bottom: -1,
              child: _GhostPlusMark(color: color),
            ),
        ],
      ),
    );
  }
}

final class _GhostSlashPainter extends CustomPainter {
  const _GhostSlashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .16, size.height * .84),
      Offset(size.width * .84, size.height * .16),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostSlashPainter oldDelegate) =>
      oldDelegate.color != color;
}

final class _GhostPlusMark extends StatelessWidget {
  const _GhostPlusMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Icon(Icons.add_rounded, size: 8, color: color),
  );
}
