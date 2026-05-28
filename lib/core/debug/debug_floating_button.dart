import 'package:flutter/material.dart';

import 'debug_console.dart';

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;
    return Positioned(
      key: const ValueKey('debug-floating-button-position'),
      top: top,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Material(
            color: const Color(0xFF1E293B),
            shape: const CircleBorder(),
            elevation: 8,
            child: IconButton(
              key: const ValueKey('debug-floating-button'),
              tooltip: 'Debug log',
              icon: const Icon(
                Icons.terminal,
                size: 18,
                color: Color(0xFF06B6D4),
              ),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const DebugConsoleDialog(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
