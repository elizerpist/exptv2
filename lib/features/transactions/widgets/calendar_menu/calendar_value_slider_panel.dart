import 'package:flutter/material.dart';

import '../../../../core/debug/debug_text_input.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_record.dart';

enum CalendarSliderKind { threshold, heatmap }

class CalendarValueSliderPanel extends StatefulWidget {
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
  State<CalendarValueSliderPanel> createState() =>
      _CalendarValueSliderPanelState();
}

class _CalendarValueSliderPanelState extends State<CalendarValueSliderPanel> {
  var _collapsed = false;
  var _verticalOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final label = widget.kind == CalendarSliderKind.threshold
        ? 'Domináns küszöb'
        : 'Hőtérkép skála';
    final sliderKey = widget.kind == CalendarSliderKind.threshold
        ? 'calendar-threshold-slider'
        : 'calendar-heatmap-slider';
    if (_collapsed) return _MiniButton(sliderKey: sliderKey, onTap: _expand);
    final effectiveMax = widget.max <= widget.min ? widget.min + 1 : widget.max;
    final effectiveValue = widget.value
        .clamp(widget.min, effectiveMax)
        .toDouble();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 20,
          right: 20,
          bottom: -_verticalOffset,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _handleDragUpdate,
            child: Material(
              color: AppColors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                key: ValueKey('$sliderKey-panel'),
                padding: const EdgeInsets.fromLTRB(14, 2, 10, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 36),
                        Expanded(
                          child: GestureDetector(
                            key: ValueKey('$sliderKey-drag-handle'),
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: _handleDragUpdate,
                            child: SizedBox(
                              height: 16,
                              child: Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.gray300,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const SizedBox(width: 46, height: 4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('$sliderKey-collapse'),
                          onPressed: _collapse,
                          tooltip: 'Kicsinyítés',
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.gray600,
                          ),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$label: ${formatHuf(widget.value)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      child: Row(
                        children: [
                          _EditableLimitText(
                            value: widget.min,
                            onSubmitted: widget.onMinChanged,
                          ),
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
                                min: widget.min,
                                max: effectiveMax,
                                divisions:
                                    widget.kind == CalendarSliderKind.heatmap
                                    ? ((effectiveMax - widget.min) / 100)
                                          .round()
                                          .clamp(1, 1000)
                                          .toInt()
                                    : null,
                                onChanged: widget.onChanged,
                              ),
                            ),
                          ),
                          _EditableLimitText(
                            value: effectiveMax,
                            onSubmitted: widget.onMaxChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalOffset = (_verticalOffset + details.delta.dy)
          .clamp(-420.0, 140.0)
          .toDouble();
    });
  }

  void _collapse() {
    setState(() => _collapsed = true);
  }

  void _expand() {
    setState(() => _collapsed = false);
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.sliderKey, required this.onTap});

  final String sliderKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 20, 112),
        child: Material(
          color: AppColors.gray800,
          elevation: 7,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(99),
          child: IconButton(
            key: ValueKey('$sliderKey-mini-button'),
            onPressed: onTap,
            tooltip: 'Slider megnyitása',
            icon: const Icon(Icons.tune, color: AppColors.white),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
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
      height: 30,
      child: Center(
        child: DebugTextField(
          debugLabel: 'CalendarValueSlider.limit',
          controller: _controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(height: 28),
          ),
          onSubmitted: (text) {
            final parsed = double.tryParse(text);
            widget.onSubmitted(parsed ?? widget.value);
          },
        ),
      ),
    );
  }
}
