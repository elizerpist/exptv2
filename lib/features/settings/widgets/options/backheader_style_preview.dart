import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';

class BackheaderStylePreview extends StatelessWidget {
  const BackheaderStylePreview({super.key, required this.style});

  final BackheaderStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('backheader-style-preview-${style.nativeValue}'),
      width: 76,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Padding(padding: const EdgeInsets.all(6), child: _content()),
      ),
    );
  }

  Color get _background {
    return switch (style) {
      BackheaderStyle.partitionDashboard => const Color(0xFF111827),
      BackheaderStyle.colorFieldPartition ||
      BackheaderStyle.orbitBudget => const Color(0xFF22C55E),
      BackheaderStyle.ledgerStrip => const Color(0xFF0F766E),
      _ => AppColors.gray100,
    };
  }

  Widget _content() {
    return switch (style) {
      BackheaderStyle.heroToken => Row(
        children: [
          const CircleAvatar(radius: 13, backgroundColor: Color(0xFF22C55E)),
          const SizedBox(width: 5),
          Expanded(child: _miniStrip()),
        ],
      ),
      BackheaderStyle.orbitBudget => Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 5),
          ),
        ),
      ),
      BackheaderStyle.mosaicBudget => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: const [
          _Tile(width: 30, color: Color(0xFF22C55E)),
          _Tile(width: 18, color: Color(0xFFF59E0B)),
          _Tile(width: 22, color: Color(0xFFEF4444)),
          _Tile(width: 42, color: Color(0xFF3B82F6)),
        ],
      ),
      BackheaderStyle.ledgerStrip => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _miniStrip(),
          const SizedBox(height: 5),
          _line(AppColors.white),
        ],
      ),
      _ => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_line(_foreground), const SizedBox(height: 6), _miniStrip()],
      ),
    };
  }

  Color get _foreground => style == BackheaderStyle.partitionDashboard
      ? AppColors.white
      : AppColors.gray800;

  Widget _line(Color color) => Container(
    width: 44,
    height: 5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  Widget _miniStrip() {
    return SizedBox(
      height: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          children: const [
            Expanded(flex: 3, child: ColoredBox(color: Color(0xFF22C55E))),
            Expanded(flex: 2, child: ColoredBox(color: Color(0xFFF59E0B))),
            Expanded(flex: 2, child: ColoredBox(color: Color(0xFFEF4444))),
            Expanded(flex: 3, child: ColoredBox(color: Color(0xFF3B82F6))),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
