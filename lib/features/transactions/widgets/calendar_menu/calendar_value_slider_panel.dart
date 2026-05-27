import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_record.dart';

enum CalendarSliderKind { threshold, heatmap }

class CalendarValueSliderPanel extends StatelessWidget {
  const CalendarValueSliderPanel.threshold({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onMinChanged,
    required this.onMaxChanged,
  }) : kind = CalendarSliderKind.threshold;

  const CalendarValueSliderPanel.heatmap({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onMinChanged,
    required this.onMaxChanged,
  }) : kind = CalendarSliderKind.heatmap;

  final CalendarSliderKind kind;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    final label = kind == CalendarSliderKind.threshold
        ? 'Küszöbérték'
        : 'Aktuális színezés';
    final sliderKey = kind == CalendarSliderKind.threshold
        ? 'calendar-threshold-slider'
        : 'calendar-heatmap-slider';
    final effectiveMax = max <= min ? min + 1 : max;
    final effectiveValue = value.clamp(min, effectiveMax).toDouble();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Material(
          color: AppColors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            key: ValueKey('$sliderKey-panel'),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  '$label: ${formatHuf(value)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                Row(
                  children: [
                    _EditableLimitText(value: min, onSubmitted: onMinChanged),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.gray200,
                          thumbColor: AppColors.primary,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                        ),
                        child: Slider(
                          key: ValueKey(sliderKey),
                          value: effectiveValue,
                          min: min,
                          max: effectiveMax,
                          divisions: kind == CalendarSliderKind.heatmap
                              ? ((effectiveMax - min) / 100)
                                    .round()
                                    .clamp(1, 1000)
                                    .toInt()
                              : null,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                    _EditableLimitText(value: effectiveMax, onSubmitted: onMaxChanged),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableLimitText extends StatefulWidget {
  const _EditableLimitText({required this.value, required this.onSubmitted});

  final double value;
  final ValueChanged<double> onSubmitted;

  @override
  State<_EditableLimitText> createState() => _EditableLimitTextState();
}

class _EditableLimitTextState extends State<_EditableLimitText> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.round().toString());
  }

  @override
  void didUpdateWidget(covariant _EditableLimitText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.round().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onSubmitted: (text) {
          final parsed = double.tryParse(text);
          widget.onSubmitted(parsed == null ? widget.value : parsed);
        },
      ),
    );
  }
}
