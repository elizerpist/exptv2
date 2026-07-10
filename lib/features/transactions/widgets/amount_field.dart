import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import 'themed_pill_field.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.focusNode,
    this.debugLabel = 'AmountField.amount',
    this.floatingLabelBehavior,
    this.surfaceColor = AppColors.gray50,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String debugLabel;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    return ThemedPillField(
      debugLabel: debugLabel,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      label: 'Összeg',
      suffixText: 'Ft',
      floatingLabelBehavior: floatingLabelBehavior,
      surfaceColor: surfaceColor,
      surfaceStyle: surfaceStyle,
    );
  }
}
