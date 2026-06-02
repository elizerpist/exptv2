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

  Color get _background => switch (style) {
    BackheaderStyle.orbitBudget => const Color(0xFF22C55E),
    _ => AppColors.gray100,
  };

  Widget _content() {
    return switch (style) {
      BackheaderStyle.heroToken => Row(
        children: [
          const CircleAvatar(radius: 13, backgroundColor: Color(0xFF22C55E)),
          const SizedBox(width: 5),
          Expanded(child: _miniStrip()),
        ],
      ),
      BackheaderStyle.orbitBudget => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
          ),
          const SizedBox(height: 3),
          _miniStrip(light: true),
        ],
      ),
      BackheaderStyle.classic => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _line(AppColors.gray800),
          const SizedBox(height: 6),
          _miniStrip(),
        ],
      ),
    };
  }

  Widget _line(Color color) => Container(
    width: 44,
    height: 5,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  Widget _miniStrip({bool light = false}) {
    return SizedBox(
      height: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ColoredBox(
                color: light ? AppColors.white : const Color(0xFF22C55E),
              ),
            ),
            const Expanded(
              flex: 2,
              child: ColoredBox(color: Color(0xFFF59E0B)),
            ),
            const Expanded(
              flex: 2,
              child: ColoredBox(color: Color(0xFFEF4444)),
            ),
            const Expanded(
              flex: 3,
              child: ColoredBox(color: Color(0xFF3B82F6)),
            ),
          ],
        ),
      ),
    );
  }
}
