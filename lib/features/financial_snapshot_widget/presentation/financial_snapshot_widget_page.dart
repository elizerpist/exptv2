import 'package:flutter/material.dart';

import '../domain/financial_snapshot_widget_repository.dart';

class FinancialSnapshotWidgetPage extends StatefulWidget {
  const FinancialSnapshotWidgetPage({super.key, required this.repository});

  final FinancialSnapshotWidgetRepository repository;

  @override
  State<FinancialSnapshotWidgetPage> createState() =>
      _FinancialSnapshotWidgetPageState();
}

class _FinancialSnapshotWidgetPageState
    extends State<FinancialSnapshotWidgetPage> {
  FinancialSnapshotWidgetStatus? _status;
  bool _savingWidget = false;
  int _statusGeneration = 0;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_statusGeneration;
    try {
      final status = await widget.repository.load();
      if (mounted && generation == _statusGeneration) {
        setState(() {
          _status = status;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _statusGeneration) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _saveWidget(FinancialSnapshotWidgetConfiguration next) async {
    if (_savingWidget) return;
    final generation = ++_statusGeneration;
    setState(() => _savingWidget = true);
    try {
      final status = await widget.repository.saveWidget(next);
      if (mounted && generation == _statusGeneration) {
        setState(() => _status = status);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A pénzügyi widget mentése nem sikerült.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingWidget = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pénzügyi widget')),
    body: switch (_status) {
      final FinancialSnapshotWidgetStatus status => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FinancialSnapshotWidgetSettings(
            status: status,
            saving: _savingWidget,
            onSave: _saveWidget,
          ),
        ],
      ),
      null when _loadFailed => Center(
        child: TextButton(onPressed: _load, child: const Text('Újra betöltés')),
      ),
      null => const Center(child: CircularProgressIndicator()),
    },
  );
}

class _FinancialSnapshotWidgetSettings extends StatelessWidget {
  const _FinancialSnapshotWidgetSettings({
    required this.status,
    required this.saving,
    required this.onSave,
  });

  final FinancialSnapshotWidgetStatus status;
  final bool saving;
  final ValueChanged<FinancialSnapshotWidgetConfiguration> onSave;

  @override
  Widget build(BuildContext context) {
    final config = status.configuration;
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  config.valid
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                ),
                title: const Text('Hagyományos pénzügyi widget konfigurálva'),
                subtitle: Text(
                  config.valid
                      ? 'A kiválasztott fókusz mentve van.'
                      : 'Budget módhoz válassz érvényes, kerettel rendelkező kategóriát.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.widgets_outlined),
                title: const Text('Widgetpéldány a widgetgazdánál'),
                subtitle: Text(
                  status.hostWidgetCount == 0
                      ? 'Még nincs kihelyezett példány.'
                      : '${status.hostWidgetCount} példányt lát a Fluvi. Ez nem igazolja, hogy zárképernyőn vannak.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Dropdown<FinancialSnapshotMode>(
                  label: 'Mód',
                  value: config.mode,
                  values: FinancialSnapshotMode.values,
                  text: _modeLabel,
                  onChanged: saving
                      ? (_) {}
                      : (value) => onSave(config.copyWith(mode: value)),
                ),
                const SizedBox(height: 12),
                _Dropdown<FinancialSnapshotTimeAxis>(
                  label: 'Időtengely',
                  value: config.timeAxis,
                  values: FinancialSnapshotTimeAxis.values,
                  text: _axisLabel,
                  onChanged: saving
                      ? (_) {}
                      : (value) => onSave(config.copyWith(timeAxis: value)),
                ),
                if (config.mode == FinancialSnapshotMode.budget) ...[
                  const SizedBox(height: 12),
                  _Dropdown<FinancialSnapshotDirection>(
                    label: 'Irány',
                    value: config.direction,
                    values: FinancialSnapshotDirection.values,
                    text: (value) => value == FinancialSnapshotDirection.expense
                        ? 'Kiadás'
                        : 'Bevétel',
                    onChanged: saving
                        ? (_) {}
                        : (value) => onSave(
                            config.copyWith(
                              direction: value,
                              clearCategory: true,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (status.categories.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.account_balance_wallet_outlined),
                      title: Text('Nincs választható keret'),
                      subtitle: Text(
                        'A Budget-kategóriához előbb hozz létre keretet.',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: const ValueKey('financial-snapshot-widget-category'),
                      value:
                          status.categories.any(
                            (item) => item.id == config.categoryId,
                          )
                          ? config.categoryId
                          : null,
                      decoration: const InputDecoration(labelText: 'Kategória'),
                      items: status.categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: saving
                          ? null
                          : (value) =>
                                onSave(config.copyWith(categoryId: value)),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: FinancialSnapshotEventLine.values
                .map(
                  (value) => RadioListTile<FinancialSnapshotEventLine>(
                    value: value,
                    groupValue: config.eventLine,
                    onChanged: saving
                        ? null
                        : (next) => onSave(config.copyWith(eventLine: next)),
                    title: Text(_eventLineLabel(value)),
                    subtitle: value == FinancialSnapshotEventLine.related
                        ? const Text(
                            'Csak a fókuszhoz tartozó utolsó könyvelt tétel.',
                          )
                        : value == FinancialSnapshotEventLine.processed
                        ? const Text(
                            'A globálisan legutóbbi könyvelt tranzakció.',
                          )
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              RadioListTile<FinancialSnapshotPrivacy>(
                value: FinancialSnapshotPrivacy.discreet,
                groupValue: config.privacy,
                onChanged: saving
                    ? null
                    : (value) => onSave(config.copyWith(privacy: value)),
                title: const Text('Diszkrét'),
                subtitle: const Text(
                  'A widgetgazda nem kap összeget, partnert, kategóriát, pontszámot vagy állapotot eláruló színt.',
                ),
              ),
              RadioListTile<FinancialSnapshotPrivacy>(
                value: FinancialSnapshotPrivacy.full,
                groupValue: config.privacy,
                onChanged: saving
                    ? null
                    : (value) => onSave(config.copyWith(privacy: value)),
                title: const Text(
                  'Pénzügyi részletek megjelenítése a widgeten',
                ),
                subtitle: const Text(
                  'Csak a feloldott Fluvi alkalmazásban engedélyezhető. A widgetgazda megkapja az értékeket, és lezárt telefonon is láthatóvá teheti őket.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(labelText: label),
    items: values
        .map((item) => DropdownMenuItem(value: item, child: Text(text(item))))
        .toList(growable: false),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

String _modeLabel(FinancialSnapshotMode value) => switch (value) {
  FinancialSnapshotMode.mind => 'Mind',
  FinancialSnapshotMode.balance => 'Balance',
  FinancialSnapshotMode.budget => 'Budget',
};
String _axisLabel(FinancialSnapshotTimeAxis value) => switch (value) {
  FinancialSnapshotTimeAxis.sum => 'SUM',
  FinancialSnapshotTimeAxis.year => 'Év',
  FinancialSnapshotTimeAxis.month => 'Hónap',
  FinancialSnapshotTimeAxis.day => 'Nap',
};
String _eventLineLabel(FinancialSnapshotEventLine value) => switch (value) {
  FinancialSnapshotEventLine.related => 'Utolsó kapcsolódó tétel',
  FinancialSnapshotEventLine.processed => 'Utolsó feldolgozott tranzakció',
  FinancialSnapshotEventLine.hidden => 'Elrejtve',
};
