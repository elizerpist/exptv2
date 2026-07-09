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
    BackheaderStyle.ambulanceSkin => const Color(0xFFF3C542),
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
      BackheaderStyle.centerBadgeBudget => Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 0, left: 0, child: _MiniAmount()),
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            ),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_MiniDot(), SizedBox(width: 3), _MiniDot()],
            ),
          ),
        ],
      ),
      BackheaderStyle.ambulanceSkin => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _line(AppColors.gray800),
          const SizedBox(height: 7),
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFE87522)),
                  Row(
                    children: const [
                      _MiniParallelogram(),
                      SizedBox(width: 5),
                      _MiniParallelogram(),
                      SizedBox(width: 5),
                      _MiniParallelogram(),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

class _MiniParallelogram extends StatelessWidget {
  const _MiniParallelogram();

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(-0.35),
      child: const SizedBox(
        width: 8,
        height: 8,
        child: ColoredBox(color: Color(0xFFFFD84D)),
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  const _MiniAmount();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.gray800,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  const _MiniDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.gray800,
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: 7, height: 7),
    );
  }
}
