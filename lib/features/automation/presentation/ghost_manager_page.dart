import 'package:flutter/material.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../../manual_transactions/presentation/category_dropdown.dart';
import '../../manual_transactions/presentation/partner_selector.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';

enum _GhostManagerLoadResult { applied, failed, superseded }

final class GhostManagerPage extends StatefulWidget {
  const GhostManagerPage({
    super.key,
    required this.repository,
    this.manualRepository,
    this.categories = const <FluviCategory>[],
    this.initialOccurrenceId,
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository? manualRepository;
  final List<FluviCategory> categories;
  final String? initialOccurrenceId;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  @override
  State<GhostManagerPage> createState() => _GhostManagerPageState();
}

class _GhostManagerPageState extends State<GhostManagerPage> {
  RecurrenceDashboardSnapshot? _data;
  List<RecurrenceOccurrence> _items = [];
  RecurrenceOccurrenceStatus? _filter;
  bool _openedInitial = false;
  bool _loading = true;
  Object? _loadError;
  int _loadRequest = 0;
  final Set<String> _skippingOccurrenceIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<_GhostManagerLoadResult> _load() async {
    final request = ++_loadRequest;
    if (_data == null && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final result = await Future.wait<Object>([
        widget.repository.recurrenceDashboard(),
        widget.repository.recurrenceOccurrences(status: _filter),
      ]);
      if (!mounted || request != _loadRequest) {
        return _GhostManagerLoadResult.superseded;
      }
      final data = result[0] as RecurrenceDashboardSnapshot;
      final items = result[1] as List<RecurrenceOccurrence>;
      RecurrenceOccurrence? selected;
      final initial = widget.initialOccurrenceId;
      if (initial != null) {
        for (final item in items) {
          if (item.occurrenceId == initial) {
            selected = item;
            break;
          }
        }
      }
      setState(() {
        _data = data;
        _items = items;
        _loading = false;
        _loadError = null;
        if (initial != null && selected == null) _filter = null;
      });
      if (selected != null && !_openedInitial) {
        _openedInitial = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => GhostOccurrenceDetailPage(
                repository: widget.repository,
                occurrence: selected!,
                manualRepository: widget.manualRepository,
                categories: widget.categories,
                onOpenLedgerEntry: widget.onOpenLedgerEntry,
              ),
            ),
          );
          if (mounted) _load();
        });
      }
      return _GhostManagerLoadResult.applied;
    } catch (error) {
      if (!mounted || request != _loadRequest) {
        return _GhostManagerLoadResult.superseded;
      }
      setState(() {
        _loading = false;
        _loadError = error;
      });
      return _GhostManagerLoadResult.failed;
    }
  }

  Future<void> _skipInline(String occurrenceId) async {
    if (_skippingOccurrenceIds.contains(occurrenceId)) return;
    setState(() => _skippingOccurrenceIds.add(occurrenceId));
    try {
      await widget.repository.skipRecurrenceOccurrence(occurrenceId);
    } catch (_) {
      _showFailure('Az alkalom kihagyása nem sikerült. Próbáld újra.');
      return;
    } finally {
      if (mounted) {
        setState(() => _skippingOccurrenceIds.remove(occurrenceId));
      }
    }

    if (!mounted) return;
    final refresh = await _load();
    if (refresh == _GhostManagerLoadResult.failed) {
      _showFailure('Az alkalom kimaradt, de a lista frissítése nem sikerült.');
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Ghost Manager')),
      body: d == null
          ? _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('A Ghost Manager betöltése nem sikerült.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Újrapróbálás'),
                          ),
                        ],
                      ),
                    ),
                  )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_loadError != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      title: const Text('A lista frissítése nem sikerült.'),
                      trailing: TextButton(
                        onPressed: _load,
                        child: const Text('Újra'),
                      ),
                    ),
                  ),
                Card(
                  child: SwitchListTile(
                    title: const Text('Ghostok megjelenítése'),
                    subtitle: const Text(
                      'Várható, áttetsző tranzakciók a Ledgerben.',
                    ),
                    value: d.showPendingGhostsInLedger,
                    onChanged: (v) async {
                      await widget.repository.setShowPendingGhosts(v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${d.pendingCount}', 'Várható'),
                    _stat('${d.dueCount}', 'Esedékes'),
                    _stat('${d.realizedCount}', 'Teljesült'),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButton<RecurrenceOccurrenceStatus?>(
                  value: _filter,
                  isExpanded: true,
                  hint: const Text('Minden előfordulás'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Minden előfordulás'),
                    ),
                    ...RecurrenceOccurrenceStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _filter = v);
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                ..._items.map(
                  (x) => Card(
                    color: x.occurrenceId == widget.initialOccurrenceId
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: Icon(
                        x.status == RecurrenceOccurrenceStatus.pending
                            ? Icons.visibility_outlined
                            : Icons.check_circle_outline,
                      ),
                      title: Text(
                        '${x.occurrenceKey} · ${x.expectedAmountScaled100 == null ? 'Változó összeg' : '${x.expectedAmountScaled100! / 100} Ft'}',
                      ),
                      subtitle: Text(
                        '${x.triggerKind.name} · ${x.status.name}',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => GhostOccurrenceDetailPage(
                              repository: widget.repository,
                              occurrence: x,
                              manualRepository: widget.manualRepository,
                              categories: widget.categories,
                              onOpenLedgerEntry: widget.onOpenLedgerEntry,
                            ),
                          ),
                        );
                        if (mounted) _load();
                      },
                      trailing: x.status == RecurrenceOccurrenceStatus.pending
                          ? IconButton(
                              key: ValueKey('ghost-skip-${x.occurrenceId}'),
                              icon: const Icon(Icons.skip_next),
                              tooltip: 'Alkalom kihagyása',
                              onPressed:
                                  _skippingOccurrenceIds.contains(
                                    x.occurrenceId,
                                  )
                                  ? null
                                  : () => _skipInline(x.occurrenceId),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String n, String l) => Column(
    children: [
      Text(
        n,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      Text(l),
    ],
  );
}

final class GhostOccurrenceDetailPage extends StatefulWidget {
  const GhostOccurrenceDetailPage({
    super.key,
    required this.repository,
    required this.occurrence,
    this.manualRepository,
    this.categories = const <FluviCategory>[],
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final RecurrenceOccurrence occurrence;
  final ManualTransactionRepository? manualRepository;
  final List<FluviCategory> categories;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  @override
  State<GhostOccurrenceDetailPage> createState() =>
      _GhostOccurrenceDetailPageState();
}

class _GhostOccurrenceDetailPageState extends State<GhostOccurrenceDetailPage> {
  late RecurrenceOccurrence _occurrence;
  bool _working = false;
  bool _loadingLedgerEntry = false;
  String? _ledgerEntryId;
  @override
  void initState() {
    super.initState();
    _occurrence = widget.occurrence;
    if (_occurrence.status == RecurrenceOccurrenceStatus.realized) {
      _loadingLedgerEntry = true;
      _loadRealizedLedgerEntry();
    }
  }

  Future<void> _loadRealizedLedgerEntry() async {
    try {
      final entryId = await widget.repository.realizedRecurrenceLedgerEntryId(
        _occurrence.occurrenceId,
      );
      if (mounted) setState(() => _ledgerEntryId = entryId);
    } finally {
      if (mounted) setState(() => _loadingLedgerEntry = false);
    }
  }

  Future<void> _openLinkedLedgerEntry() async {
    final entryId = _ledgerEntryId;
    final open = widget.onOpenLedgerEntry;
    if (entryId == null || open == null) return;
    setState(() => _working = true);
    try {
      await open(entryId);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  DateTime get _date => DateTime.utc(
    1970,
  ).add(Duration(days: _occurrence.expectedLocalEpochDay)).toLocal();

  Future<void> _edit() async {
    final amount = TextEditingController(
      text: _occurrence.expectedAmountScaled100 == null
          ? ''
          : _formatHungarianMinor(_occurrence.expectedAmountScaled100!),
    );
    final note = TextEditingController(text: _occurrence.note ?? '');
    var date = _date;
    var partnerId = _occurrence.partnerId;
    var categoryId = _occurrence.categoryId;
    var categoryMode = _occurrence.categoryAssignmentMode;
    var partnerOrCategoryChanged = false;
    String? partnerName;
    String? amountError;
    var time = TimeOfDay(
      hour: _occurrence.expectedLocalTimeMinutes ~/ 60,
      minute: _occurrence.expectedLocalTimeMinutes % 60,
    );
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Várható alkalom módosítása'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Várható összeg',
                    suffixText: 'HUF',
                    errorText: amountError,
                  ),
                  onChanged: (_) {
                    if (amountError != null) {
                      setDialogState(() => amountError = null);
                    }
                  },
                ),
                ListTile(
                  title: Text('${date.year}. ${date.month}. ${date.day}.'),
                  leading: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final next = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (next != null) setDialogState(() => date = next);
                  },
                ),
                ListTile(
                  title: Text(time.format(context)),
                  leading: const Icon(Icons.schedule),
                  onTap: () async {
                    final next = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (next != null) setDialogState(() => time = next);
                  },
                ),
                if (widget.manualRepository != null) ...[
                  ListTile(
                    title: Text(partnerName ?? 'Partner módosítása'),
                    subtitle: const Text('Csak ezt a várható alkalmat érinti'),
                    leading: const Icon(Icons.person_outline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await Navigator.of(context)
                          .push<ManualPartnerSelection>(
                            MaterialPageRoute(
                              builder: (_) => PartnerSelector(
                                repository: widget.manualRepository!,
                                categories: widget.categories,
                              ),
                            ),
                          );
                      if (selected is! ExistingManualPartner) return;
                      final partner = await widget.manualRepository!
                          .getPartnerById(selected.partnerId);
                      if (partner == null || !context.mounted) return;
                      setDialogState(() {
                        partnerId = partner.partnerId;
                        partnerName = partner.displayName;
                        categoryId = partner.defaultCategoryId;
                        categoryMode =
                            ManualCategoryAssignmentMode.partnerDefault;
                        partnerOrCategoryChanged = true;
                      });
                    },
                  ),
                  CategoryDropdown(
                    categories: widget.categories,
                    selectedCategoryId: categoryId,
                    label:
                        categoryMode ==
                            ManualCategoryAssignmentMode.partnerDefault
                        ? 'Kategória · Partner alapértelmezése'
                        : 'Kategória · Egyedi',
                    onSelected: (next) => setDialogState(() {
                      categoryId = next;
                      categoryMode = ManualCategoryAssignmentMode.entryOverride;
                      partnerOrCategoryChanged = true;
                    }),
                  ),
                ],
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Megjegyzés'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Mégse'),
            ),
            FilledButton(
              onPressed: () async {
                final rawAmount = amount.text.trim();
                final scaledAmount = rawAmount.isEmpty
                    ? null
                    : _parseHungarianMinor(rawAmount);
                if (rawAmount.isNotEmpty &&
                    (scaledAmount == null || scaledAmount <= 0)) {
                  setDialogState(
                    () => amountError = 'Adj meg pozitív, érvényes összeget.',
                  );
                  return;
                }
                await widget.repository.updateRecurrenceOccurrence(
                  occurrenceId: _occurrence.occurrenceId,
                  expectedAmountScaled100: scaledAmount,
                  expectedLocalEpochDay: _epochDay(date),
                  expectedLocalTimeMinutes: time.hour * 60 + time.minute,
                  partnerId: partnerId == _occurrence.partnerId
                      ? null
                      : partnerId,
                  categorySelection: !partnerOrCategoryChanged
                      ? null
                      : categoryMode ==
                            ManualCategoryAssignmentMode.partnerDefault
                      ? const ManualCategorySelection.partnerDefault()
                      : ManualCategorySelection.entryOverride(categoryId),
                  noteChanged: true,
                  note: note.text.trim().isEmpty ? null : note.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Mentés'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    note.dispose();
    if (changed == true && mounted) {
      // Fetching the page again is intentionally deferred to the manager; the
      // detail route only reflects the immediately edited fields on return.
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _skip() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await widget.repository.skipRecurrenceOccurrence(
        _occurrence.occurrenceId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Az alkalom kihagyása nem sikerült. Próbáld újra.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Várható tranzakció')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _occurrence.occurrenceKey,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _info('Állapot', _occurrence.status.name),
        _info(
          'Várható összeg',
          _occurrence.expectedAmountScaled100 == null
              ? 'Változó összeg'
              : '${_occurrence.expectedAmountScaled100! / 100} Ft',
        ),
        _info(
          'Időpont',
          '${_date.year}. ${_date.month}. ${_date.day}. · ${(_occurrence.expectedLocalTimeMinutes ~/ 60).toString().padLeft(2, '0')}:${(_occurrence.expectedLocalTimeMinutes % 60).toString().padLeft(2, '0')}',
        ),
        _info('Trigger', _occurrence.triggerKind.name),
        if (_occurrence.note != null) _info('Megjegyzés', _occurrence.note!),
        const SizedBox(height: 20),
        if (_occurrence.status == RecurrenceOccurrenceStatus.pending) ...[
          FilledButton.icon(
            onPressed: _working ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Egyedi módosítás'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _working ? null : _skip,
            icon: const Icon(Icons.skip_next),
            label: const Text('Alkalom kihagyása'),
          ),
        ] else if (_occurrence.status ==
            RecurrenceOccurrenceStatus.realized) ...[
          const SizedBox(height: 20),
          if (_loadingLedgerEntry)
            const Center(child: CircularProgressIndicator())
          else if (_ledgerEntryId != null && widget.onOpenLedgerEntry != null)
            FilledButton.icon(
              onPressed: _working ? null : _openLinkedLedgerEntry,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Kapcsolódó tranzakció megnyitása'),
            )
          else
            const Text(
              'A teljesült alkalomhoz nem található megnyitható Ledger-tranzakció.',
            ),
        ],
      ],
    ),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text('$label\n$value'),
  );
}

int _epochDay(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(1970)).inDays;

int? _parseHungarianMinor(String source) {
  final normalized = source
      .replaceAll(RegExp(r'[\s\u00A0.]'), '')
      .replaceAll(',', '.');
  if (normalized.isEmpty || normalized.startsWith('-')) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(normalized);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fractional = (match.group(2) ?? '').padRight(2, '0');
  final minor = int.tryParse(fractional);
  if (minor == null) return null;
  const maxStoredMinor = 9223372036854775807;
  if (whole > maxStoredMinor ~/ 100 ||
      whole == maxStoredMinor ~/ 100 && minor > maxStoredMinor.remainder(100)) {
    return null;
  }
  return whole * 100 + minor;
}

String _formatHungarianMinor(int minor) {
  final whole = minor ~/ 100;
  final fraction = minor % 100;
  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(' ');
    grouped.write(digits[index]);
  }
  return '$grouped,${fraction.toString().padLeft(2, '0')}';
}
