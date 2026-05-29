import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'amount_field.dart';

class DateTimeFields extends StatelessWidget {
  const DateTimeFields({
    super.key,
    required this.dateController,
    required this.timeController,
    this.onPickDate,
    this.onPickTime,
  });

  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback? onPickDate;
  final VoidCallback? onPickTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: dateController,
            keyboardType: TextInputType.datetime,
            decoration: transactionFieldDecoration('Dátum').copyWith(
              suffixIcon: IconButton(
                key: const ValueKey('transaction-date-picker-button'),
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                color: AppColors.gray500,
                tooltip: 'Dátum választása',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: timeController,
            keyboardType: TextInputType.datetime,
            decoration: transactionFieldDecoration('Idő').copyWith(
              suffixIcon: IconButton(
                key: const ValueKey('transaction-time-picker-button'),
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule_outlined, size: 20),
                color: AppColors.gray500,
                tooltip: 'Idő választása',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
