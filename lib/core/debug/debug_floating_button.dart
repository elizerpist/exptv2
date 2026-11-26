import 'package:flutter/material.dart';

import '../design/dashboard_mode_palette.dart';
import '../../features/automation/domain/automation_repository.dart';
import '../diagnostics/keyguard_timing_capture_bridge.dart';
import 'debug_console.dart';

typedef DebugPhysicalReportProvider = String Function();

/// Reference-compatible debug entry point. This widget is only inserted by
/// the debug-gated app shell and never owns dashboard layout or business state.
class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({
    super.key,
    this.physicalReportProvider,
    this.diagnosticStatusProvider,
    this.automationPermissions,
    this.keyguardTimingCapture,
    this.onDialogClosed,
  });

  final DebugPhysicalReportProvider? physicalReportProvider;
  final DebugDiagnosticStatusProvider? diagnosticStatusProvider;
  final AutomationPermissionRepository? automationPermissions;
  final KeyguardTimingCaptureBridge? keyguardTimingCapture;
  final VoidCallback? onDialogClosed;

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
          onPressed: () async {
            await showDialog<void>(
              context: context,
              builder: (_) => DebugConsoleDialog(
                physicalReportProvider: physicalReportProvider,
                diagnosticStatusProvider: diagnosticStatusProvider,
                automationPermissions: automationPermissions,
                keyguardTimingCapture: keyguardTimingCapture,
                initialKeyguard:
                    const bool.fromEnvironment('FLUVI_R448_SAFE_SAMPLE_ONLY') ||
                    const String.fromEnvironment('FLUVI_BUILD_PURPOSE') ==
                        'human_diagnostic',
              ),
            );
            if (context.mounted) onDialogClosed?.call();
          },
        ),
      ),
    );
  }
}
