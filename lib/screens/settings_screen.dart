import 'package:flutter/material.dart';

import '../models/service_status.dart';
import '../state/event_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.store.refreshStatus();
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.store.status;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Capture mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<CaptureMode>(
            segments: const [
              ButtonSegment(
                value: CaptureMode.notificationListener,
                label: Text('NL'),
              ),
              ButtonSegment(
                value: CaptureMode.accessibility,
                label: Text('ACC'),
              ),
              ButtonSegment(value: CaptureMode.both, label: Text('Both')),
            ],
            selected: {status?.captureMode ?? CaptureMode.both},
            onSelectionChanged: (selection) {
              widget.store.setCaptureMode(selection.single);
            },
          ),
          const SizedBox(height: 24),
          _StatusTile(
            title: 'Notification Listener',
            enabled: status?.notificationListenerEnabled ?? false,
            active: status?.notificationListenerActive ?? false,
            lastEvent: status?.lastNotificationListenerEvent,
            onOpen: widget.store.openNotificationAccessSettings,
          ),
          _StatusTile(
            title: 'Accessibility Service',
            enabled: status?.accessibilityEnabled ?? false,
            active: status?.accessibilityActive ?? false,
            lastEvent: status?.lastAccessibilityEvent,
            onOpen: widget.store.openAccessibilitySettings,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Total stored events'),
            trailing: Text('${status?.totalEvents ?? 0}'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await widget.store.requestPostNotifications();
              await widget.store.sendTestNotification();
              await widget.store.refreshStatus();
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send test notification'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear database?'),
                  content: const Text('This removes every stored notification event.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await widget.store.clearDatabase();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear database'),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.enabled,
    required this.active,
    required this.lastEvent,
    required this.onOpen,
  });

  final String title;
  final bool enabled;
  final bool active;
  final DateTime? lastEvent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          'Enabled: $enabled\n'
          'Active in selected mode: $active\n'
          'Last event: ${lastEvent?.toLocal().toString() ?? 'never'}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Open settings',
          icon: const Icon(Icons.open_in_new),
          onPressed: onOpen,
        ),
      ),
    );
  }
}
