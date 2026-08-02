import 'package:flutter/material.dart';

import '../design/dashboard_mode_palette.dart';
import 'debug_console.dart';

/// Reference-compatible debug entry point. This widget is only inserted by
/// the debug-gated app shell and never owns dashboard layout or business state.
class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('debug-floating-button-position'),
      left: 16,
      bottom: FluviVisualTokens.navigationHeight + 12,
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
            builder: (_) => const DebugConsoleDialog(),
          ),
        ),
      ),
    );
  }
}
