import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/native_bridge.dart';
import 'data/notification_repository.dart';
import 'state/notification_store.dart';
import 'widgets/notification_log_box.dart';
import 'widgets/notification_month_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.nativeBridge,
    this.active = true,
  });

  final NativeBridge nativeBridge;
  final bool active;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationStore _store;

  @override
  void initState() {
    super.initState();
    _store = NotificationStore(NotificationRepository(widget.nativeBridge));
    if (widget.active) _store.start();
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _store.refresh();
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        if (_store.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (_store.error != null) {
          return Center(
            child: Text(
              _store.error!,
              style: const TextStyle(color: AppColors.expense),
            ),
          );
        }
        final groups = _store.groupedCards;
        return Column(
          children: [
            const SizedBox(height: 36),
            NotificationMonthHeader(
              selectedMonth: _store.selectedMonth,
              hasCards: _store.visibleCards.isNotEmpty,
              onMonthShift: _store.shiftMonth,
              onClear: _store.clearVisibleMonth,
            ),
            Expanded(
              child: groups.isEmpty
                  ? const Center(
                      child: Text(
                        'Nincsenek értesítések',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      children: [
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray500,
                              ),
                            ),
                          ),
                          for (final card in entry.value)
                            NotificationLogBox(
                              card: card,
                              onMarkRead: _store.markRead,
                              onDelete: _store.deleteCard,
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
