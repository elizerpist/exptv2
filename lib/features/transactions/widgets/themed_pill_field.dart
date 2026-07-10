import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';

class ThemedPillField extends StatelessWidget {
  const ThemedPillField({
    super.key,
    required this.debugLabel,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.focusNode,
    this.keyboardType,
    this.onChanged,
    this.suffixText,
    this.suffixIcon,
    this.minLines,
    this.maxLines,
    this.floatingLabelBehavior,
    this.surfaceColor = AppColors.gray50,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final Key? fieldKey;
  final String debugLabel;
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? suffixText;
  final Widget? suffixIcon;
  final int? minLines;
  final int? maxLines;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    if (!surfaceStyle.hasPressEffect) {
      return DebugTextField(
        fieldKey: fieldKey,
        debugLabel: debugLabel,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: transactionFieldDecoration(label, fillColor: surfaceColor)
            .copyWith(
              suffixText: suffixText,
              suffixIcon: suffixIcon,
              floatingLabelBehavior: floatingLabelBehavior,
            ),
      );
    }
    final radius = BorderRadius.circular(25);
    return ExpenseSurfaceContainer(
      surfaceKey: ValueKey('${_surfaceKeyValue()}-surface'),
      style: surfaceStyle,
      color: surfaceColor,
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      neutralBorder: Border.all(color: AppColors.gray200),
      child: Material(
        color: Colors.transparent,
        child: DebugTextField(
          fieldKey: fieldKey,
          debugLabel: debugLabel,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.transparent,
            suffixText: suffixText,
            suffixIcon: suffixIcon,
            floatingLabelBehavior: floatingLabelBehavior,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Object _surfaceKeyValue() {
    final key = fieldKey;
    if (key is ValueKey) return key.value;
    return debugLabel;
  }
}

InputDecoration transactionFieldDecoration(
  String label, {
  Color fillColor = AppColors.gray50,
}) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
