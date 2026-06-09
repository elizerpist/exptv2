import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import 'themed_pill_field.dart';

class DateTimeFields extends StatelessWidget {
  const DateTimeFields({
    super.key,
    required this.dateController,
    required this.timeController,
    this.onPickDate,
    this.onPickTime,
    this.dateFieldKey,
    this.timeFieldKey,
    this.datePickerKey = const ValueKey('transaction-date-picker-button'),
    this.timePickerKey = const ValueKey('transaction-time-picker-button'),
    this.dateFocusNode,
    this.timeFocusNode,
    this.debugLabelPrefix = 'DateTimeFields',
    this.surfaceColor = AppColors.gray50,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback? onPickDate;
  final VoidCallback? onPickTime;
  final Key? dateFieldKey;
  final Key? timeFieldKey;
  final Key datePickerKey;
  final Key timePickerKey;
  final FocusNode? dateFocusNode;
  final FocusNode? timeFocusNode;
  final String debugLabelPrefix;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ThemedPillField(
            fieldKey: dateFieldKey,
            debugLabel: '$debugLabelPrefix.date',
            controller: dateController,
            focusNode: dateFocusNode,
            keyboardType: TextInputType.datetime,
            label: 'Dátum',
            surfaceColor: surfaceColor,
            surfaceStyle: surfaceStyle,
            suffixIcon: IconButton(
              key: datePickerKey,
              onPressed: onPickDate ?? () => _pickDate(context),
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              color: AppColors.gray500,
              tooltip: 'Dátum választása',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ThemedPillField(
            fieldKey: timeFieldKey,
            debugLabel: '$debugLabelPrefix.time',
            controller: timeController,
            focusNode: timeFocusNode,
            keyboardType: TextInputType.datetime,
            label: 'Idő',
            surfaceColor: surfaceColor,
            surfaceStyle: surfaceStyle,
            suffixIcon: IconButton(
              key: timePickerKey,
              onPressed: onPickTime ?? () => _pickTime(context),
              icon: const Icon(Icons.schedule_outlined, size: 20),
              color: AppColors.gray500,
              tooltip: 'Idő választása',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final initialDate = _parseDate(dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    dateController.text = '${picked.year}-$month-$day';
  }

  Future<void> _pickTime(BuildContext context) async {
    final initialTime = _parseTime(timeController.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return;
    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    timeController.text = '$hour:$minute';
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[./]'), '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
