import 'dart:convert';

import 'package:flutter/material.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

class PushTrainingEditorPage extends StatefulWidget {
  const PushTrainingEditorPage({
    super.key,
    required this.repository,
    required this.profile,
    required this.event,
  });
  final AutomationRepository repository;
  final PushProfile? profile;
  final NotificationInboxItem event;
  @override
  State<PushTrainingEditorPage> createState() => _PushTrainingEditorPageState();
}

class _PushTrainingEditorPageState extends State<PushTrainingEditorPage> {
  final _name = TextEditingController(text: 'Új felismerési szabály');
  final List<PushFieldSpan> _spans = [];
  TextSelection _selection = const TextSelection.collapsed(offset: -1);
  LedgerDirection _direction = LedgerDirection.expense;
  PushSampleKind _sampleKind = PushSampleKind.transaction;
  bool _saving = false;
  String? _message;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addRole(PushFieldRole role) {
    final range = _selection;
    if (!range.isValid || range.isCollapsed || range.start < 0) {
      setState(() => _message = 'Előbb jelölj ki egy szövegrészt.');
      return;
    }
    if (_spans.any(
      (span) =>
          span.role == role ||
          !(range.end <= span.start || range.start >= span.endExclusive),
    )) {
      setState(
        () => _message =
            'A szerep már foglalt vagy a kijelölések átfedik egymást.',
      );
      return;
    }
    setState(() {
      _spans.add(
        PushFieldSpan(start: range.start, endExclusive: range.end, role: role),
      );
      _spans.sort((a, b) => a.start.compareTo(b.start));
      _message = null;
    });
  }

  Future<void> _save() async {
    final profile = widget.profile;
    if (profile == null) return;
    if (_sampleKind == PushSampleKind.transaction &&
        (_spans.where((span) => span.role == PushFieldRole.amount).length !=
                1 ||
            _spans
                    .where((span) => span.role == PushFieldRole.merchant)
                    .length !=
                1)) {
      setState(
        () => _message = 'Egy AMOUNT és egy MERCHANT kijelölés kötelező.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_sampleKind == PushSampleKind.transaction) {
        await widget.repository.createRule(
          profileId: profile.profileId,
          notificationId: widget.event.notificationId,
          name: _name.text.trim(),
          direction: _direction,
          spans: _spans,
        );
      } else {
        await widget.repository.addTrainingSample(
          profileId: profile.profileId,
          notificationId: widget.event.notificationId,
          kind: _sampleKind,
          spansJson: jsonEncode(_spans.map((span) => span.toMap()).toList()),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Szabály tanítása')),
      body: profile == null
          ? const Center(child: Text('A tanításhoz profil szükséges.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              children: [
                const Text(
                  'Jelöld ki az eredeti értesítés mezőit',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A kiválasztás az eredeti üzenet karakterpozícióihoz kötődik. Az egyenleg nem válhat tranzakcióösszeggé.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<PushSampleKind>(
                  initialValue: _sampleKind,
                  decoration: const InputDecoration(
                    labelText: 'Az üzenet típusa',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PushSampleKind.transaction,
                      child: Text('Tranzakció'),
                    ),
                    DropdownMenuItem(
                      value: PushSampleKind.nonTransaction,
                      child: Text('Nem tranzakció'),
                    ),
                    DropdownMenuItem(
                      value: PushSampleKind.failedTransaction,
                      child: Text('Sikertelen / nem könyvelhető'),
                    ),
                    DropdownMenuItem(
                      value: PushSampleKind.ignored,
                      child: Text('Figyelmen kívül hagyandó'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _sampleKind = value!;
                    _message = null;
                  }),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f6f8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    widget.event.rawText,
                    onSelectionChanged: (selection, _) =>
                        setState(() => _selection = selection),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PushFieldRole.values
                      .map(
                        (role) => OutlinedButton(
                          onPressed: () => _addRole(role),
                          child: Text(role.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
                if (_spans.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ..._spans.map(
                    (span) => Chip(
                      label: Text(
                        '${span.role.name.toUpperCase()}: ${widget.event.rawText.substring(span.start, span.endExclusive)}',
                      ),
                      onDeleted: () => setState(() => _spans.remove(span)),
                    ),
                  ),
                ],
                if (_sampleKind == PushSampleKind.transaction) ...[
                  const SizedBox(height: 18),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Szabály neve',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LedgerDirection>(
                    initialValue: _direction,
                    decoration: const InputDecoration(
                      labelText: 'Tranzakció iránya',
                    ),
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
                ],
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Mentés…'
                        : _sampleKind == PushSampleKind.transaction
                        ? 'Szabály létrehozása és tesztelése'
                        : 'Tanítóminta mentése',
                  ),
                ),
              ],
            ),
    );
  }
}
