import 'dart:convert';

import 'package:flutter/material.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

class ReviewPushNotificationPage extends StatefulWidget {
  const ReviewPushNotificationPage({
    super.key,
    required this.repository,
    required this.event,
  });
  final AutomationRepository repository;
  final NotificationInboxItem event;
  @override
  State<ReviewPushNotificationPage> createState() =>
      _ReviewPushNotificationPageState();
}

class _ReviewPushNotificationPageState
    extends State<ReviewPushNotificationPage> {
  late final TextEditingController _merchant;
  final _amount = TextEditingController();
  LedgerDirection _direction = LedgerDirection.expense;
  bool _saving = false;
  bool _useCorrectionForTraining = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController();
    final suggested = widget.event.suggestedPayloadJson;
    if (suggested != null) {
      try {
        final payload = jsonDecode(suggested);
        if (payload is Map<String, dynamic>) {
          final amount = payload['amountScaled100'] as num?;
          if (amount != null && amount > 0) {
            final whole = amount.toInt() ~/ 100;
            final fraction = amount.toInt() % 100;
            _amount.text = fraction == 0
                ? '$whole'
                : '$whole,${fraction.toString().padLeft(2, '0')}';
          }
          _merchant.text = payload['merchant'] as String? ?? '';
        }
      } on FormatException {
        // Diagnostics are never a requirement for the user to correct a
        // review.  Leave the editable proposal blank if legacy data is bad.
      }
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? _parse() {
    final normalized = _amount.text
        .replaceAll(RegExp(r'[^0-9,]'), '')
        .replaceAll(',', '.');
    final pieces = normalized.split('.');
    final whole = int.tryParse(pieces.first) ?? 0;
    final cents = pieces.length > 1
        ? int.tryParse(pieces[1].padRight(2, '0').substring(0, 2)) ?? 0
        : 0;
    return whole > 0 ? whole * 100 + cents : null;
  }

  Future<void> _approve() async {
    final amount = _parse();
    if (amount == null || _merchant.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final local = DateTime.fromMillisecondsSinceEpoch(
      widget.event.receivedAtUtcMs,
    );
    try {
      await widget.repository.approveReview(
        notificationId: widget.event.notificationId,
        merchantName: _merchant.text.trim(),
        direction: _direction,
        amountScaled100: amount,
        bookedLocalEpochDay: DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).difference(DateTime.utc(1970)).inDays,
        bookedLocalTimeMinutes: local.hour * 60 + local.minute,
        occurredAtUtcMs: widget.event.receivedAtUtcMs,
        note: null,
        trainingCorrectionJson: _useCorrectionForTraining
            ? jsonEncode({
                'kind': 'reviewCorrection',
                'merchant': _merchant.text.trim(),
                'amountScaled100': amount,
                'direction': _direction.name,
              })
            : null,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Értesítés felülvizsgálata')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Eredeti push értesítés',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SelectableText(widget.event.rawText),
        const Divider(height: 36),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Összeg (Ft)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _merchant,
          decoration: const InputDecoration(labelText: 'Partner'),
        ),
        DropdownButtonFormField<LedgerDirection>(
          initialValue: _direction,
          decoration: const InputDecoration(labelText: 'Irány'),
          items: const [
            DropdownMenuItem(
              value: LedgerDirection.expense,
              child: Text('Kiadás'),
            ),
            DropdownMenuItem(
              value: LedgerDirection.income,
              child: Text('Bevétel'),
            ),
          ],
          onChanged: (value) => setState(() => _direction = value!),
        ),
        if (widget.event.profileId != null)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _useCorrectionForTraining,
            onChanged: (value) =>
                setState(() => _useCorrectionForTraining = value ?? false),
            title: const Text('Javítás felhasználása tanítómintaként'),
            subtitle: const Text(
              'A profil későbbi szabálytanításakor felhasználható lesz.',
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _approve,
          child: const Text('Jóváhagyás és könyvelés'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  try {
                    await widget.repository.ignoreReview(
                      widget.event.notificationId,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } on Object catch (error) {
                    if (mounted) setState(() => _error = '$error');
                  }
                },
          child: const Text('Figyelmen kívül hagyás'),
        ),
      ],
    ),
  );
}
