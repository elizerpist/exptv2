import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/categories/domain/fluvi_category.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import 'category_dropdown.dart';
import 'partner_selector.dart';

enum ManualTransactionEditorMode { create, edit }

final class ManualTransactionEditor extends StatefulWidget {
  const ManualTransactionEditor.create({
    super.key,
    required this.repository,
    required this.categories,
    required this.direction,
    this.onSaved,
  }) : mode = ManualTransactionEditorMode.create,
       entryId = null;

  const ManualTransactionEditor.edit({
    super.key,
    required this.repository,
    required this.categories,
    required String this.entryId,
    this.onSaved,
  }) : mode = ManualTransactionEditorMode.edit,
       direction = null;

  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final ManualTransactionEditorMode mode;
  final String? entryId;
  final LedgerDirection? direction;
  final ValueChanged<ManualTransactionSaveResult>? onSaved;

  @override
  State<ManualTransactionEditor> createState() =>
      _ManualTransactionEditorState();
}

final class _ManualTransactionEditorState
    extends State<ManualTransactionEditor> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  late DateTime _initialCreateDate;
  late TimeOfDay _initialCreateTime;
  LedgerDirection? _direction;
  LedgerEntryDetail? _entry;
  PartnerDirectoryEntry? _partner;
  ManualPartnerSelection? _partnerSelection;
  ManualCategorySelection _categorySelection =
      const ManualCategorySelection.partnerDefault();
  bool _loading = false;
  bool _saving = false;
  bool _revisionConflict = false;
  String? _error;

  bool get _editing => widget.mode == ManualTransactionEditorMode.edit;
  bool get _dirty {
    final entry = _entry;
    if (!_editing || entry == null) {
      return _amount.text.isNotEmpty ||
          _note.text.isNotEmpty ||
          _partnerSelection != null ||
          _date != _initialCreateDate ||
          _time.hour != _initialCreateTime.hour ||
          _time.minute != _initialCreateTime.minute;
    }
    final selectedPartnerId = switch (_partnerSelection) {
      ExistingManualPartner(:final partnerId) => partnerId,
      NewManualPartner() || null => null,
    };
    return selectedPartnerId != entry.partnerId ||
        _amount.text != _formatHungarianMinor(entry.amountScaled100) ||
        _note.text != (entry.note ?? '') ||
        _date != _dateFromEpochDay(entry.bookedLocalEpochDay) ||
        _time.hour * 60 + _time.minute != entry.bookedLocalTimeMinutes ||
        _categorySelection.mode.name != entry.categoryAssignmentMode.name ||
        _categorySelection.categoryId !=
            (entry.categoryAssignmentMode ==
                    ManualCategoryAssignmentMode.entryOverride
                ? entry.categoryId
                : null);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay.fromDateTime(now);
    _initialCreateDate = _date;
    _initialCreateTime = _time;
    _direction = widget.direction;
    if (_editing) _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _revisionConflict = false;
    });
    try {
      final entry = await widget.repository.getLedgerEntryById(widget.entryId!);
      final partner = await widget.repository.getPartnerById(entry.partnerId);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _direction = entry.direction;
        _partner = partner;
        _partnerSelection = ExistingManualPartner(entry.partnerId);
        _categorySelection =
            entry.categoryAssignmentMode ==
                ManualCategoryAssignmentMode.entryOverride
            ? ManualCategorySelection.entryOverride(entry.categoryId)
            : const ManualCategorySelection.partnerDefault();
        _date = _dateFromEpochDay(entry.bookedLocalEpochDay);
        _time = TimeOfDay(
          hour: entry.bookedLocalTimeMinutes ~/ 60,
          minute: entry.bookedLocalTimeMinutes % 60,
        );
        _amount.text = _formatHungarianMinor(entry.amountScaled100);
        _note.text = entry.note ?? '';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'A tranzakció nem tölthető be: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPartner() async {
    final selected = await Navigator.of(context).push<ManualPartnerSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PartnerSelector(
          repository: widget.repository,
          categories: widget.categories,
        ),
      ),
    );
    if (!mounted) return;
    if (selected == null) {
      final current = _partnerSelection;
      if (current is ExistingManualPartner &&
          _categorySelection.mode ==
              ManualCategoryAssignmentMode.partnerDefault) {
        final refreshed = await widget.repository.getPartnerById(
          current.partnerId,
        );
        if (mounted && refreshed != null) {
          setState(() => _partner = refreshed);
        }
      }
      return;
    }
    if (selected case ExistingManualPartner(:final partnerId)) {
      final partner = await widget.repository.getPartnerById(partnerId);
      if (!mounted) return;
      setState(() {
        _partnerSelection = selected;
        _partner = partner;
        _categorySelection = const ManualCategorySelection.partnerDefault();
      });
    } else if (selected case NewManualPartner(
      :final displayName,
      :final defaultCategoryId,
    )) {
      final category = _category(defaultCategoryId);
      setState(() {
        _partnerSelection = selected;
        _partner = PartnerDirectoryEntry(
          partnerId: '',
          displayName: displayName,
          originalName: displayName,
          defaultCategoryId: defaultCategoryId,
          defaultCategoryName: category?.name ?? 'Kategorizálatlan',
          categoryColorId: category?.colorId ?? 'fallback',
          categoryIconId: category?.iconId ?? 'fallback',
          isUncategorized: category?.isSystemUncategorized ?? true,
          searchNames: [displayName],
        );
        _categorySelection = const ManualCategorySelection.partnerDefault();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<bool> _confirmClose() async {
    if (!_dirty || _saving) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Változtatások elvetése?'),
            content: const Text(
              'A még nem mentett tranzakcióadatok elvesznek.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Maradok'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elvetés'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save({required bool keepOpen}) async {
    final partner = _partnerSelection;
    final direction = _direction;
    final scaled = _parseHungarianMinor(_amount.text);
    if (partner == null ||
        _partner == null ||
        direction == null ||
        scaled == null ||
        scaled <= 0) {
      setState(() => _error = 'Adj meg pozitív összeget és partnert.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _revisionConflict = false;
    });
    try {
      final day = _epochDay(_date);
      final minute = _time.hour * 60 + _time.minute;
      final occurred = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ).millisecondsSinceEpoch;
      if (_editing) {
        final existing = _entry!;
        final saved = await widget.repository.updateTransaction(
          entryId: existing.entryId,
          expectedRevision: existing.revision,
          partner: partner,
          categorySelection: _categorySelection,
          amountScaled100: scaled,
          bookedLocalEpochDay: day,
          bookedLocalTimeMinutes: minute,
          occurredAtUtcMs: existing.originKind == 'manual'
              ? occurred
              : existing.occurredAtUtcMs,
          note: _note.text,
        );
        final result = _saveResult(saved);
        widget.onSaved?.call(result);
        if (mounted) Navigator.of(context).pop(result);
        return;
      }
      final saved = await widget.repository.createManualTransaction(
        partner: partner,
        categorySelection: _categorySelection,
        direction: direction,
        amountScaled100: scaled,
        bookedLocalEpochDay: day,
        bookedLocalTimeMinutes: minute,
        occurredAtUtcMs: occurred,
        note: _note.text,
      );
      if (!mounted) return;
      if (!keepOpen) {
        final result = _saveResult(saved);
        widget.onSaved?.call(result);
        Navigator.of(context).pop(result);
        return;
      }
      final now = DateTime.now();
      setState(() {
        _amount.clear();
        _note.clear();
        _partner = null;
        _partnerSelection = null;
        _categorySelection = const ManualCategorySelection.partnerDefault();
        _date = DateTime(now.year, now.month, now.day);
        _time = TimeOfDay.fromDateTime(now);
        _initialCreateDate = _date;
        _initialCreateTime = _time;
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _revisionConflict = error.code == 'revision_conflict';
          _error = _revisionConflict
              ? 'A tranzakció időközben megváltozott. Töltsd újra a mentés előtt.'
              : 'A mentés nem sikerült: ${error.message ?? error.code}';
        });
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'A mentés nem sikerült: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ManualTransactionSaveResult _saveResult(LedgerEntryDetail entry) {
    FluviCategory? category;
    for (final candidate in widget.categories) {
      if (candidate.id == entry.categoryId) {
        category = candidate;
        break;
      }
    }
    return ManualTransactionSaveResult(
      entry: entry,
      partner: _partner!,
      effectiveCategory: category,
      globalCoreRevision: entry.coreRevision,
    );
  }

  FluviCategory? _category(String? id) {
    for (final category in widget.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final direction = _direction ?? LedgerDirection.expense;
    final expense = direction == LedgerDirection.expense;
    final color = expense ? const Color(0xFFE45C66) : const Color(0xFF2E9D72);
    final selectedCategoryId =
        _categorySelection.mode == ManualCategoryAssignmentMode.entryOverride
        ? _categorySelection.categoryId
        : _partner?.defaultCategoryId;
    final title = _editing
        ? expense
              ? 'Kiadás szerkesztése'
              : 'Bevétel szerkesztése'
        : expense
        ? 'Új kiadás'
        : 'Új bevétel';
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || await _confirmClose() == false || !context.mounted) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            tooltip: 'Bezárás',
            icon: const Icon(Icons.close_rounded),
            onPressed: _saving
                ? null
                : () async {
                    if (await _confirmClose() && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    TextField(
                      key: const ValueKey('manual-amount-field'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Összeg',
                        suffixText: 'HUF',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: color, width: 2),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      key: const ValueKey('manual-partner-field'),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        _partner?.displayName ?? 'Partner kiválasztása',
                      ),
                      subtitle: _partner == null
                          ? null
                          : Text(_partner!.defaultCategoryName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _saving ? null : _pickPartner,
                    ),
                    const SizedBox(height: 16),
                    CategoryDropdown(
                      categories: widget.categories,
                      selectedCategoryId: selectedCategoryId,
                      onSelected: (categoryId) => setState(
                        () => _categorySelection =
                            ManualCategorySelection.entryOverride(categoryId),
                      ),
                    ),
                    if (_categorySelection.mode ==
                        ManualCategoryAssignmentMode.entryOverride) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 4),
                          const Text('Egyedi kategória'),
                          const Spacer(),
                          TextButton(
                            onPressed: _partner == null
                                ? null
                                : () => setState(
                                    () => _categorySelection =
                                        const ManualCategorySelection.partnerDefault(),
                                  ),
                            child: const Text('Visszaállítás'),
                          ),
                        ],
                      ),
                    ] else if (_partner != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Partner alapértelmezése'),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_date),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pickTime,
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(_time.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _note,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Megjegyzés',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (_revisionConflict)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _saving ? null : _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Adatok újratöltése'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      if (!_editing) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _save(keepOpen: true),
                            child: const Text('Mentés és újabb'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving
                              ? null
                              : () => _save(keepOpen: false),
                          child: Text(
                            _saving
                                ? 'Mentés…'
                                : _editing
                                ? 'Módosítások mentése'
                                : 'Tranzakció hozzáadása',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _epochDay(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(1970)).inDays;

DateTime _dateFromEpochDay(int epochDay) =>
    DateTime.utc(1970).add(Duration(days: epochDay)).toLocal();

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
  return fraction == 0
      ? grouped.toString()
      : '${grouped.toString()},${fraction.toString().padLeft(2, '0')}';
}
