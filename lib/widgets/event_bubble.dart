import 'package:flutter/material.dart';

import '../models/notification_event.dart';

class EventBubble extends StatelessWidget {
  const EventBubble({super.key, required this.event});

  final NotificationEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(event.sourceBadge, style: theme.textTheme.labelMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.displayApp,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.isDuplicate)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.copy_all, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(event.packageName, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                if (event.title.isNotEmpty)
                  Text(event.title, style: theme.textTheme.titleMedium),
                if (event.bodyText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.bodyText),
                ],
                const SizedBox(height: 8),
                Text(
                  event.timestamp.toLocal().toString(),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
