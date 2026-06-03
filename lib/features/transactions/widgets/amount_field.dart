import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.focusNode,
    this.debugLabel = 'AmountField.amount',
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String debugLabel;

  @override
  Widget build(BuildContext context) {
    return DebugTextField(
      debugLabel: debugLabel,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: transactionFieldDecoration(
        'Összeg',
      ).copyWith(suffixText: 'Ft'),
    );
  }
}

InputDecoration transactionFieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.gray50,
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
