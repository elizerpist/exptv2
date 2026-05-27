import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/calendar_menu_mode.dart';

class CalendarModeSelector extends StatelessWidget {
  const CalendarModeSelector({
    super.key,
    required this.activeMode,
    required this.onModeChanged,
    this.transitionLocked = false,
  });

  final CalendarMenuMode activeMode;
  final ValueChanged<CalendarMenuMode> onModeChanged;
  final bool transitionLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('calendar-mode-selector'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CalendarMenuMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _ModeButton(
              mode: mode,
              active: mode == activeMode,
              onTap: transitionLocked ? null : () => onModeChanged(mode),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  final CalendarMenuMode mode;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = active ? 24.0 : 20.0;
    return InkWell(
      key: ValueKey('calendar-mode-${mode.name}'),
      onTap: onTap,
      customBorder: mode == CalendarMenuMode.heatmap
          ? null
          : const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _baseColor,
          shape: mode == CalendarMenuMode.heatmap
              ? BoxShape.rectangle
              : BoxShape.circle,
          borderRadius: mode == CalendarMenuMode.heatmap
              ? BorderRadius.circular(2)
              : null,
          border: Border.all(
            color: active ? AppColors.primary : _inactiveBorder,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            mode == CalendarMenuMode.heatmap ? 1 : 99,
          ),
          child: CustomPaint(painter: _ModeGlyphPainter(mode)),
        ),
      ),
    );
  }

  Color get _baseColor => switch (mode) {
    CalendarMenuMode.normal => AppColors.gray50,
    CalendarMenuMode.summary => AppColors.income,
    CalendarMenuMode.heatmap => AppColors.white,
    CalendarMenuMode.category => const Color(0xFFF97316),
  };

  Color get _inactiveBorder => switch (mode) {
    CalendarMenuMode.normal => const Color(0xFF9CA3AF),
    _ => AppColors.gray200,
  };
}

class _ModeGlyphPainter extends CustomPainter {
  const _ModeGlyphPainter(this.mode);

  final CalendarMenuMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == CalendarMenuMode.summary) {
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
        Paint()..color = AppColors.expense,
      );
    }
    if (mode == CalendarMenuMode.heatmap) {
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
        Paint()..color = AppColors.primary,
      );
    }
  }

  @override
  bool shouldRepaint(_ModeGlyphPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
