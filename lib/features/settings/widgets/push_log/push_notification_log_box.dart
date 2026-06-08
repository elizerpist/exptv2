import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/installed_app.dart';
import '../../models/push_notification_log_event.dart';
import '../installed_app_icon.dart';

class PushNotificationLogBox extends StatelessWidget {
  const PushNotificationLogBox({
    super.key,
    required this.event,
    required this.app,
    required this.onTap,
  });

  final PushNotificationLogEvent event;
  final InstalledApp? app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('push-logbox-${event.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 92,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AppBadge(app: app, label: event.sourceBadge),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.displayApp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray800,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(event.timestamp),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.fullText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray700,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(
                      text: event.statusText,
                      status: event.status,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBadge extends StatelessWidget {
  const _AppBadge({required this.app, required this.label});

  final InstalledApp? app;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selectedApp = app;
    if (selectedApp != null && selectedApp.hasIcon) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(child: InstalledAppIcon(app: selectedApp)),
      );
    }
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.gray800,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.status});

  final String text;
  final PushNotificationLogStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PushNotificationLogStatus.linked => const Color(0xFF059669),
      PushNotificationLogStatus.system => AppColors.gray500,
      PushNotificationLogStatus.all ||
        PushNotificationLogStatus.missing => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
