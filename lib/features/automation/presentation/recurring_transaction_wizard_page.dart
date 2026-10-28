import 'package:flutter/material.dart';

import '../../../core/categories/domain/fluvi_category.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../../manual_transactions/presentation/category_dropdown.dart';
import '../../manual_transactions/presentation/partner_selector.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'recurring_rule_manager_page.dart';

final class RecurringTransactionWizardPage extends StatefulWidget {
  const RecurringTransactionWizardPage({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required this.initialDirection,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository manualRepository;
  final List<FluviCategory> categories;
  final LedgerDirection initialDirection;
  @override
  State<RecurringTransactionWizardPage> createState() =>
      _RecurringTransactionWizardPageState();
}

class _RecurringTransactionWizardPageState
    extends State<RecurringTransactionWizardPage> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _amount = TextEditingController();
  final _tolerance = TextEditingController(text: '0');
  int _step = 0;
  PartnerDirectoryEntry? _partner;
  String? _overrideCategory;
  var _policy = RecurrenceAmountPolicy.fixed;
  var _trigger = RecurrenceTriggerKind.time;
  late DateTime _first;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;
  List<PushProfile> _profiles = const [];
  List<PushRule> _pushRules = const [];
  String? _pushProfileId;
  String? _pushRuleId;
  int _dayWindow = 2;

  @override
  void initState() {
    super.initState();
    _first = DateTime.now();
    _loadPushProfiles();
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _amount.dispose();
    _tolerance.dispose();
    super.dispose();
  }

  int? get _scaledAmount {
    final normalized = _amount.text
        .replaceAll(RegExp(r'[^0-9,]'), '')
        .replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final parts = normalized.split('.');
    final major = int.tryParse(parts.first) ?? 0;
    final minor = parts.length > 1
        ? int.tryParse('${parts[1]}00'.substring(0, 2)) ?? 0
        : 0;
    return major * 100 + minor;
  }

  int get _epochDay => _first.difference(DateTime(1970)).inDays;
  int get _minutes => _time.hour * 60 + _time.minute;
  int get _amountTolerance => int.tryParse(_tolerance.text.trim()) ?? 0;

  Future<void> _loadPushProfiles() async {
    try {
      final profiles = await widget.repository.listProfiles();
      if (mounted) setState(() => _profiles = profiles);
    } catch (_) {
      // The wizard can still save a deliberately unbound, prepared push rule.
    }
  }

  Future<void> _selectPushProfile(String? profileId) async {
    if (profileId == null) {
      setState(() {
        _pushProfileId = null;
        _pushRuleId = null;
        _pushRules = const [];
      });
      return;
    }
    setState(() {
      _pushProfileId = profileId;
      _pushRuleId = null;
      _pushRules = const [];
    });
    try {
      final rules = await widget.repository.rules(profileId);
      if (mounted && _pushProfileId == profileId) {
        setState(() => _pushRules = rules);
      }
    } catch (_) {
      // Keep the draft selectable; save-time Core validation remains final.
    }
  }

  bool get _canAdvance {
    if (_step == 0) return _name.text.trim().isNotEmpty && _partner != null;
    if (_step == 1) {
      return _policy == RecurrenceAmountPolicy.unknown ||
          (_scaledAmount ?? 0) > 0;
    }
    if (_step == 3 && _trigger == RecurrenceTriggerKind.time) {
      return _policy != RecurrenceAmountPolicy.unknown &&
          (_scaledAmount ?? 0) > 0;
    }
    return true;
  }

  Future<void> _pickPartner() async {
    final selected = await Navigator.of(context).push<ManualPartnerSelection>(
      MaterialPageRoute(
        builder: (_) => PartnerSelector(
          repository: widget.manualRepository,
          categories: widget.categories,
        ),
      ),
    );
    if (selected is! ExistingManualPartner) {
      if (selected != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Az új partnert előbb a partnerlistában mentsd el.'),
          ),
        );
      }
      return;
    }
    final partner = selected.directoryEntry;
    if (!mounted || partner == null) return;
    setState(() {
      _partner = partner;
      _overrideCategory = null;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _first,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _first = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final rule = await widget.repository.createRecurringRule(
        name: _name.text.trim(),
        partnerId: _partner!.partnerId,
        categorySelection: _overrideCategory == null
            ? const ManualCategorySelection.partnerDefault()
            : ManualCategorySelection.entryOverride(_overrideCategory),
        // The creation surface snapshots the Dashboard income/expense pill.
        // It intentionally cannot be changed within this wizard.
        direction: widget.initialDirection,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        triggerKind: _trigger,
        amountPolicy: _policy,
        amountScaled100: _policy == RecurrenceAmountPolicy.unknown
            ? null
            : _scaledAmount,
        dayOfMonth: _first.day,
        localTimeMinutes: _minutes,
        startLocalEpochDay: _epochDay,
        timezoneId: 'Europe/Budapest',
        pushProfileId: _trigger == RecurrenceTriggerKind.push
            ? _pushProfileId
            : null,
        pushRuleId: _trigger == RecurrenceTriggerKind.push ? _pushRuleId : null,
        amountToleranceScaled100: _amountTolerance * 100,
        dayWindow: _dayWindow,
      );
      if (mounted) {
        await Navigator.of(context).pushReplacement<bool, bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RecurringRuleDetailPage(
              repository: widget.repository,
              rule: rule,
              manualRepository: widget.manualRepository,
              categories: widget.categories,
            ),
          ),
          result: true,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Az ismétlődés nem menthető: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final directionTitle = widget.initialDirection == LedgerDirection.income
        ? 'bevételi'
        : 'kiadási';
    const titles = [
      'Alapadatok',
      'Összeg beállítása',
      'Gyakoriság és időzítés',
      'Hogyan teljesüljön?',
      'Ismétlődés áttekintése',
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Új ismétlődő $directionTitle tranzakció',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / titles.length),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_step + 1} / 5 · ${titles[_step]}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              Expanded(child: SingleChildScrollView(child: _stepBody(context))),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Előző'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : _step == 4
                        ? _save
                        : _canAdvance
                        ? () => setState(() => _step++)
                        : null,
                    child: Text(
                      _saving
                          ? 'Mentés…'
                          : _step == 4
                          ? 'Ismétlődés létrehozása'
                          : 'Következő',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Megnevezés',
                hintText: 'Netflix előfizetés',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffc8ced7)),
              ),
              leading: _partner == null
                  ? null
                  : PartnerCategoryAvatar(partner: _partner!),
              title: Text(_partner?.displayName ?? 'Partner kiválasztása'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickPartner,
            ),
            const SizedBox(height: 14),
            CategoryDropdown(
              categories: widget.categories,
              selectedCategoryId:
                  _overrideCategory ?? _partner?.defaultCategoryId,
              onSelected: (id) => setState(() => _overrideCategory = id),
              label: _overrideCategory == null
                  ? 'Kategória · Partner alapértelmezése'
                  : 'Kategória · Egyedi',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Megjegyzés (opcionális)',
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Összeg',
                suffixText: 'HUF',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final policy in RecurrenceAmountPolicy.values)
                  ChoiceChip(
                    label: Text(_policyTitle(policy)),
                    selected: _policy == policy,
                    onSelected: (_) => setState(() => _policy = policy),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _policy == RecurrenceAmountPolicy.unknown
                  ? 'A ghost nem mutat hamis 0 Ft-os összeget.'
                  : 'A ghost ezt az összeget mutatja.',
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            ListTile(
              title: Text('Minden hónap ${_first.day}. napján'),
              subtitle: const Text(
                'Rövidebb hónapokban a hónap utolsó napján.',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(_time.format(context)),
              subtitle: const Text('Várható / triggeridőpont'),
              trailing: const Icon(Icons.schedule),
              onTap: _pickTime,
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            ChoiceChip(
              label: const Text('Időalapú teljesülés'),
              selected: _trigger == RecurrenceTriggerKind.time,
              onSelected: (_) =>
                  setState(() => _trigger = RecurrenceTriggerKind.time),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text('A megadott időpontban automatikusan könyvel.'),
            ),
            ChoiceChip(
              label: const Text('Push-triggerelt teljesülés'),
              selected: _trigger == RecurrenceTriggerKind.push,
              onSelected: (_) =>
                  setState(() => _trigger = RecurrenceTriggerKind.push),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('A banki értesítés megerősíti a tényleges összeget.'),
            ),
            if (_trigger == RecurrenceTriggerKind.push)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String?>(
                      key: ValueKey('push-profile-$_pushProfileId'),
                      initialValue: _pushProfileId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Push profil (opcionális előkészítés)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Még nem kötöm profilhoz'),
                        ),
                        ..._profiles.map(
                          (profile) => DropdownMenuItem<String?>(
                            value: profile.profileId,
                            child: Text(profile.displayName),
                          ),
                        ),
                      ],
                      onChanged: _selectPushProfile,
                    ),
                    if (_pushProfileId != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        key: ValueKey('push-rule-$_pushRuleId'),
                        initialValue: _pushRuleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Aktív felismerési szabály',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Válassz szabályt később'),
                          ),
                          ..._pushRules
                              .where(
                                (rule) => rule.state == PushRuleState.active,
                              )
                              .map(
                                (rule) => DropdownMenuItem<String?>(
                                  value: rule.ruleId,
                                  child: Text(rule.name),
                                ),
                              ),
                        ],
                        onChanged: (value) =>
                            setState(() => _pushRuleId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tolerance,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Összegtolerancia',
                          suffixText: 'Ft',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: ValueKey('push-day-window-$_dayWindow'),
                        initialValue: _dayWindow,
                        decoration: const InputDecoration(
                          labelText: 'Megengedett napeltérés',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Csak aznap')),
                          DropdownMenuItem(value: 1, child: Text('± 1 nap')),
                          DropdownMenuItem(value: 2, child: Text('± 2 nap')),
                          DropdownMenuItem(value: 3, child: Text('± 3 nap')),
                          DropdownMenuItem(value: 7, child: Text('± 7 nap')),
                        ],
                        onChanged: (value) =>
                            setState(() => _dayWindow = value ?? _dayWindow),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Profil és aktív szabály nélkül a terv menthető, de nem teljesül automatikusan.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name.text, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${widget.initialDirection == LedgerDirection.expense ? 'Kiadás' : 'Bevétel'} · $_amountLabel',
            ),
            Text(
              'Havonta ${_first.day}. napján · ${_trigger == RecurrenceTriggerKind.time ? 'Időalapú' : 'Push-triggerelt'}',
            ),
            const SizedBox(height: 18),
            const Text('Első három várható alkalom'),
            for (var index = 0; index < 3; index++)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(
                  'Várható · ${_monthlyOccurrence(index).day}. ${_monthlyOccurrence(index).month}.',
                ),
                trailing: Text(_amountLabel),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'A várható tranzakciók megjelennek a Ledgerben, de csak teljesüléskor számítanak bele az egyenlegbe.',
              ),
            ),
          ],
        );
    }
  }

  String get _amountLabel => _policy == RecurrenceAmountPolicy.unknown
      ? 'Változó összeg'
      : '${((_scaledAmount ?? 0) / 100).toStringAsFixed(2)} Ft';
  String _policyTitle(RecurrenceAmountPolicy value) => switch (value) {
    RecurrenceAmountPolicy.fixed => 'Fix összeg',
    RecurrenceAmountPolicy.estimated => 'Várható összeg',
    RecurrenceAmountPolicy.unknown => 'Változó összeg',
  };

  DateTime _monthlyOccurrence(int offset) {
    final firstOfMonth = DateTime(_first.year, _first.month + offset, 1);
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      _first.day.clamp(1, lastDay).toInt(),
    );
  }
}
