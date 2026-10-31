import 'package:flutter/material.dart';

import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'push_training_editor_page.dart';
import 'review_push_notification_page.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({
    super.key,
    required this.repository,
    required this.profileId,
    this.onlyReview = false,
    this.selectionMode = false,
    this.onSelectForTraining,
  });
  final AutomationRepository repository;
  final String? profileId;
  final bool onlyReview;
  final bool selectionMode;
  final Widget Function(NotificationInboxItem event)? onSelectForTraining;
  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  List<NotificationInboxItem> _events = const [];
  bool _loading = true;
  PushReviewStatus? _filter;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await widget.repository.inbox(
        profileId: widget.profileId,
        reviewStatus: widget.onlyReview ? PushReviewStatus.pending : null,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = widget.onlyReview ? PushReviewStatus.pending : _filter;
    final shown = _events
        .where(
          (event) => activeFilter == null || event.reviewStatus == activeFilter,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionMode
              ? 'Tanítóminta kiválasztása'
              : 'Elkapott értesítések',
        ),
      ),
      body: Column(
        children: [
          if (!widget.selectionMode)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  for (final status in <PushReviewStatus?>[
                    null,
                    PushReviewStatus.approved,
                    PushReviewStatus.pending,
                    PushReviewStatus.ignored,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterText(status)),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                ? const Center(child: Text('Ebben a nézetben nincs értesítés.'))
                : ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => _InboxRow(
                      event: shown[index],
                      onTap: () => _open(shown[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(NotificationInboxItem event) async {
    final destination = widget.selectionMode
        ? widget.onSelectForTraining?.call(event) ??
              PushTrainingEditorPage(
                repository: widget.repository,
                profile: null,
                event: event,
              )
        : ReviewPushNotificationPage(
            repository: widget.repository,
            event: event,
          );
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => destination));
    if (mounted) _load();
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.event, required this.onTap});
  final NotificationInboxItem event;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: CircleAvatar(child: Icon(_icon(event.reviewStatus))),
    title: Text(
      event.title?.isNotEmpty == true
          ? event.title!
          : event.sourceAppLabel ?? 'Értesítés',
    ),
    subtitle: Text(event.rawText, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: Text(
      _filterText(event.reviewStatus),
      style: const TextStyle(fontSize: 11),
    ),
  );
}

String _filterText(PushReviewStatus? value) => switch (value) {
  null => 'Mind',
  PushReviewStatus.none => 'Új',
  PushReviewStatus.approved => 'Feldolgozva',
  PushReviewStatus.pending => 'Felülvizsgálandó',
  PushReviewStatus.ignored => 'Kihagyva',
  PushReviewStatus.rejected => 'Elutasítva',
};
IconData _icon(PushReviewStatus value) => switch (value) {
  PushReviewStatus.pending => Icons.pending_actions_outlined,
  PushReviewStatus.approved => Icons.check_circle_outline,
  PushReviewStatus.ignored ||
  PushReviewStatus.rejected => Icons.remove_circle_outline,
  PushReviewStatus.none => Icons.notifications_none,
};
