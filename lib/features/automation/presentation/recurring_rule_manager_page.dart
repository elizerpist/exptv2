import 'package:flutter/material.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'ghost_manager_page.dart';

final class RecurringRuleManagerPage extends StatefulWidget {
  const RecurringRuleManagerPage({
    super.key,
    required this.repository,
    this.manualRepository,
    this.categories = const <FluviCategory>[],
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository? manualRepository;
  final List<FluviCategory> categories;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  @override
  State<RecurringRuleManagerPage> createState() =>
      _RecurringRuleManagerPageState();
}

class _RecurringRuleManagerPageState extends State<RecurringRuleManagerPage> {
  List<RecurrenceRule>? _rules;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await widget.repository.recurringRules();
    if (mounted) setState(() => _rules = rules);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Szabályaim'),
      actions: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined),
          tooltip: 'Ghost Manager',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GhostManagerPage(
                repository: widget.repository,
                manualRepository: widget.manualRepository,
                categories: widget.categories,
                onOpenLedgerEntry: widget.onOpenLedgerEntry,
              ),
            ),
          ),
        ),
      ],
    ),
    body: _rules == null
        ? const Center(child: CircularProgressIndicator())
        : _rules!.isEmpty
        ? const Center(child: Text('Még nincs ismétlődő tranzakció.'))
        : ListView.builder(
            itemCount: _rules!.length,
            itemBuilder: (context, index) {
              final rule = _rules![index];
              final amount = rule.amountScaled100 == null
                  ? 'Változó összeg'
                  : '${rule.amountScaled100! / 100} Ft';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: Text(rule.name),
                  subtitle: Text(
                    '$amount · Havonta ${rule.dayOfMonth}. · ${rule.triggerKind.name}',
                  ),
                  onTap: () => Navigator.of(context)
                      .push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => RecurringRuleDetailPage(
                            repository: widget.repository,
                            rule: rule,
                            manualRepository: widget.manualRepository,
                            categories: widget.categories,
                            onOpenLedgerEntry: widget.onOpenLedgerEntry,
                          ),
                        ),
                      )
                      .then((_) => _load()),
                  trailing: Switch(
                    value: rule.isActive,
                    onChanged: (active) async {
                      await widget.repository.setRecurringRuleActive(
                        rule.ruleId,
                        active,
                      );
                      _load();
                    },
                  ),
                ),
              );
            },
          ),
  );
}

final class RecurringRuleDetailPage extends StatefulWidget {
  const RecurringRuleDetailPage({
    super.key,
    required this.repository,
    required this.rule,
    this.manualRepository,
    this.categories = const <FluviCategory>[],
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final RecurrenceRule rule;
  final ManualTransactionRepository? manualRepository;
  final List<FluviCategory> categories;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;

  @override
  State<RecurringRuleDetailPage> createState() =>
      _RecurringRuleDetailPageState();
}

class _RecurringRuleDetailPageState extends State<RecurringRuleDetailPage> {
  List<RecurrenceOccurrence>? _occurrences;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.repository.recurrenceOccurrences(limit: 200);
    if (mounted) {
      setState(
        () => _occurrences = all
            .where((occurrence) => occurrence.ruleId == widget.rule.ruleId)
            .toList(growable: false),
      );
    }
  }

  Future<void> _archive() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ismétlődési szabály archiválása?'),
        content: const Text(
          'A már könyvelt tranzakciók megmaradnak. A még várható és felülvizsgálat alatt álló alkalmak törlés nélkül leállnak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archiválás'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    final navigator = Navigator.of(context);
    setState(() => _updating = true);
    try {
      await widget.repository.archiveRecurringRule(widget.rule.ruleId);
      if (!mounted) return;
      navigator.pop(true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.rule.amountScaled100 == null
        ? 'Változó összeg'
        : '${widget.rule.amountScaled100! / 100} Ft';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ismétlődési szabály'),
        actions: [
          PopupMenuButton<String>(
            enabled: !_updating,
            onSelected: (action) {
              if (action == 'archive') _archive();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'archive', child: Text('Archiválás')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.rule.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _detail('Összeg', amount),
          _detail('Gyakoriság', 'Havonta ${widget.rule.dayOfMonth}. napján'),
          _detail(
            'Teljesülés',
            widget.rule.triggerKind == RecurrenceTriggerKind.time
                ? 'Időalapú'
                : 'Push-triggerelt',
          ),
          _detail('Partner', widget.rule.partnerId),
          _detail('Kategória', widget.rule.categoryId),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Szabály aktív'),
            subtitle: const Text(
              'A kikapcsolás nem törli a korábbi teljesüléseket.',
            ),
            value: widget.rule.isActive,
            onChanged: _updating
                ? null
                : (active) async {
                    setState(() => _updating = true);
                    try {
                      await widget.repository.setRecurringRuleActive(
                        widget.rule.ruleId,
                        active,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop(true);
                    } finally {
                      if (mounted) setState(() => _updating = false);
                    }
                  },
          ),
          const SizedBox(height: 16),
          Text(
            'Következő előfordulások',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_occurrences == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_occurrences!.isEmpty)
            const Text('Ehhez a szabályhoz még nincs létrehozott előfordulás.')
          else
            ..._occurrences!
                .take(6)
                .map(
                  (occurrence) => ListTile(
                    leading: Icon(
                      occurrence.status == RecurrenceOccurrenceStatus.pending
                          ? Icons.visibility_outlined
                          : Icons.check_circle_outline,
                    ),
                    title: Text(occurrence.occurrenceKey),
                    subtitle: Text(occurrence.status.name),
                    trailing: Text(
                      occurrence.expectedAmountScaled100 == null
                          ? 'Változó'
                          : '${occurrence.expectedAmountScaled100! / 100} Ft',
                    ),
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute<void>(
                            builder: (_) => GhostOccurrenceDetailPage(
                              repository: widget.repository,
                              occurrence: occurrence,
                              manualRepository: widget.manualRepository,
                              categories: widget.categories,
                              onOpenLedgerEntry: widget.onOpenLedgerEntry,
                            ),
                          ),
                        )
                        .then((_) => _load()),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text('$label\n$value'),
  );
}
