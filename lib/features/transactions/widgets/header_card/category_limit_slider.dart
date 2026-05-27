import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryLimitSlider extends StatelessWidget {
  const CategoryLimitSlider({
    super.key,
    required this.value,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  final double value;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1.0 : max;
    final safeValue = value.clamp(0.0, safeMax).toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: activeColor,
        inactiveTrackColor: AppColors.gray200,
        thumbColor: activeColor,
        overlayColor: activeColor.withValues(alpha: 0.14),
        valueIndicatorColor: activeColor,
      ),
      child: Slider(
        key: const ValueKey('category-limit-slider'),
        min: 0,
        max: safeMax,
        divisions: divisions < 1 ? 1 : divisions,
        value: safeValue,
        onChanged: onChanged,
      ),
    );
  }
}
