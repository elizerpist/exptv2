import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';
import '../../services/recurring_alarm_service.dart';
import 'debug_console.dart';

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({
    super.key,
    this.recurringAlarmService,
    this.onRecurringChanged,
    this.bottomOffset = AppDimensions.bottomNavHeight + 12,
  });

  final RecurringAlarmService? recurringAlarmService;
  final VoidCallback? onRecurringChanged;
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('debug-floating-button-position'),
      right: 16,
      bottom: bottomOffset,
      child: Material(
        color: const Color(0xFF1E293B),
        shape: const CircleBorder(),
        elevation: 8,
        child: IconButton(
          key: const ValueKey('debug-floating-button'),
          tooltip: 'Debug log',
          icon: const Icon(Icons.terminal, size: 18, color: Color(0xFF06B6D4)),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => DebugConsoleDialog(
              recurringAlarmService: recurringAlarmService,
              onRecurringChanged: onRecurringChanged,
            ),
          ),
        ),
      ),
    );
  }
}
