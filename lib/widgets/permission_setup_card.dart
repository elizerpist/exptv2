import 'package:flutter/material.dart';

import '../models/service_status.dart';

class PermissionSetupCard extends StatelessWidget {
  const PermissionSetupCard({
    super.key,
    required this.status,
    required this.onOpenNotificationAccess,
    required this.onOpenAccessibility,
    required this.onOpenAppInfo,
  });

  final ServiceStatus? status;
  final VoidCallback onOpenNotificationAccess;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAppInfo;

  bool get _needsSetup {
    final current = status;
    if (current == null) return true;
    return !current.notificationListenerEnabled || !current.accessibilityEnabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsSetup) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permission setup', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'If Android shows Restricted settings, open App info, use the top-right menu, allow restricted settings, then return here.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onOpenAppInfo,
              icon: const Icon(Icons.info_outline),
              label: const Text('Open app info'),
            ),
            const SizedBox(height: 8),
            _PermissionRow(
              label: 'Notification Access',
              enabled: status?.notificationListenerEnabled ?? false,
              onPressed: onOpenNotificationAccess,
            ),
            _PermissionRow(
              label: 'Accessibility Service',
              enabled: status?.accessibilityEnabled ?? false,
              onPressed: onOpenAccessibility,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      leading: Icon(enabled ? Icons.check_circle : Icons.error_outline),
      trailing: TextButton(onPressed: onPressed, child: const Text('Open')),
    );
  }
}
