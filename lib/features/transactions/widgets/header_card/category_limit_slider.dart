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
    this.enabled = true,
    this.onChangeEnd,
  });

  final double value;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1.0 : max;
    final safeValue = value.clamp(0.0, safeMax).toDouble();
    final effectiveColor = enabled ? activeColor : AppColors.gray400;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: effectiveColor,
        inactiveTrackColor: AppColors.gray200,
        thumbColor: effectiveColor,
        overlayColor: effectiveColor.withValues(alpha: 0.14),
        valueIndicatorColor: effectiveColor,
      ),
      child: Slider(
        key: const ValueKey('category-limit-slider'),
        min: 0,
        max: safeMax,
        divisions: divisions < 1 ? 1 : divisions,
        value: safeValue,
        onChanged: enabled ? onChanged : null,
        onChangeEnd: enabled ? onChangeEnd : null,
      ),
    );
  }
}
