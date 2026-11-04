import 'package:flutter/material.dart';

import '../../lock_screen_card/domain/lock_screen_card_repository.dart';

class LockScreenCardPage extends StatefulWidget {
  const LockScreenCardPage({
    super.key,
    required this.repository,
    required this.openAndroidNotificationSettings,
  });

  final LockScreenCardRepository repository;
  final Future<void> Function() openAndroidNotificationSettings;

  @override
  State<LockScreenCardPage> createState() => _LockScreenCardPageState();
}

class _LockScreenCardPageState extends State<LockScreenCardPage> {
  LockScreenCardStatus? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await widget.repository.load();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _save(LockScreenCardConfiguration next) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final status = await widget.repository.save(next);
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A zárképernyős értesítés mentése nem sikerült.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final config = status.configuration;
    return Scaffold(
      appBar: AppBar(title: const Text('Zárképernyős értesítés')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          _PreviewCard(status: status),
          const SizedBox(height: 18),
          Card(
            child: SwitchListTile.adaptive(
              key: const ValueKey('lock-screen-card-enabled'),
              value: config.enabled,
              onChanged: _saving
                  ? null
                  : (value) => _save(config.copyWith(enabled: value)),
              secondary: const Icon(Icons.lock_outline),
              title: const Text('Zárképernyős értesítés'),
              subtitle: Text(
                config.enabled
                    ? 'A kiválasztott pénzügyi fókusz Android-értesítésként jelenik meg.'
                    : 'Kikapcsolva; a választott fókusz megmarad.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Mit kövessen?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Dropdown<LockScreenCardMode>(
                    label: 'Mód',
                    value: config.mode,
                    values: LockScreenCardMode.values,
                    text: _modeLabel,
                    onChanged: (value) => _save(config.copyWith(mode: value)),
                  ),
                  const SizedBox(height: 12),
                  _Dropdown<LockScreenCardTimeAxis>(
                    label: 'Időtengely',
                    value: config.timeAxis,
                    values: LockScreenCardTimeAxis.values,
                    text: _axisLabel,
                    onChanged: (value) =>
                        _save(config.copyWith(timeAxis: value)),
                  ),
                  if (config.mode == LockScreenCardMode.budget) ...[
                    const SizedBox(height: 12),
                    _Dropdown<LockScreenCardDirection>(
                      label: 'Irány',
                      value: config.direction,
                      values: LockScreenCardDirection.values,
                      text: (value) => value == LockScreenCardDirection.expense
                          ? 'Kiadás'
                          : 'Bevétel',
                      onChanged: (value) => _save(
                        config.copyWith(direction: value, clearCategory: true),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (status.categories.isEmpty)
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.account_balance_wallet_outlined),
                        title: Text('Nincs választható keret'),
                        subtitle: Text(
                          'A Budget kategóriához előbb hozz létre keretet.',
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: const ValueKey('lock-screen-card-category'),
                        value:
                            status.categories.any(
                              (item) => item.id == config.categoryId,
                            )
                            ? config.categoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Kategória',
                        ),
                        items: status.categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  _save(config.copyWith(categoryId: value)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Alsó információs sor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Card(
            child: Column(
              children: LockScreenCardEventLine.values
                  .map(
                    (value) => RadioListTile<LockScreenCardEventLine>(
                      value: value,
                      groupValue: config.eventLine,
                      onChanged: _saving
                          ? null
                          : (next) => _save(config.copyWith(eventLine: next)),
                      title: Text(_eventLineLabel(value)),
                      subtitle: value == LockScreenCardEventLine.related
                          ? const Text(
                              'Csak a fókuszhoz tartozó utolsó könyvelt tétel.',
                            )
                          : value == LockScreenCardEventLine.processed
                          ? const Text(
                              'A globálisan legutóbbi könyvelt tranzakció.',
                            )
                          : null,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Adatvédelem',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<LockScreenCardPrivacy>(
                  value: LockScreenCardPrivacy.discreet,
                  groupValue: config.privacy,
                  onChanged: _saving
                      ? null
                      : (value) => _save(config.copyWith(privacy: value)),
                  title: const Text('Diszkrét'),
                  subtitle: const Text(
                    'Lezárt telefonon sem összeg, sem partner, sem kategória nem látszik.',
                  ),
                ),
                RadioListTile<LockScreenCardPrivacy>(
                  value: LockScreenCardPrivacy.full,
                  groupValue: config.privacy,
                  onChanged: _saving
                      ? null
                      : (value) => _save(config.copyWith(privacy: value)),
                  title: const Text('Teljes'),
                  subtitle: const Text(
                    'Lezárt telefonon is látható lehet az összeg, a partner és a kategória.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Nem önálló Nothing-zárképernyőwidget'),
              subtitle: Text(
                'A Nothing OS zárképernyős widgetfelülete nem kínál fel '
                'külső Android AppWidgetProvidert. A Fluvi pillanatképe '
                'ezért rendszerértesítésként jelenhet meg a zárolt képernyőn.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Megjelenés a telefonon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    status.postNotificationsGranted
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  title: const Text('A Fluvi küldhet értesítést'),
                  subtitle: Text(
                    status.postNotificationsGranted
                        ? 'Engedélyezve'
                        : 'Android-engedély szükséges',
                  ),
                  trailing: TextButton(
                    onPressed: widget.openAndroidNotificationSettings,
                    child: const Text('Android-beállítások'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    status.statusChannelEnabled
                        ? Icons.settings_outlined
                        : Icons.error_outline,
                  ),
                  title: const Text('Pénzügyi értesítés csatornája'),
                  subtitle: Text(
                    'Csatornafontosság: ${status.statusChannelImportance}. '
                    'Zárolt képernyő: ${status.statusChannelLockscreenVisibility}. '
                    '${status.statusChannelEnabled ? '' : 'A csatorna ki van kapcsolva. '}'
                    'A Néma csatornát a Nothing nem teszi ki biztosan a zárolt képernyőre. '
                    'A Csatorna oldalon válassz normál (Alapértelmezett) megjelenítést, '
                    'és engedélyezd az értesítéseket a zárolt képernyőn.',
                  ),
                  trailing: TextButton(
                    onPressed: widget
                        .repository
                        .openRuntimeNotificationChannelSettings,
                    child: const Text('Csatorna'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.status});
  final LockScreenCardStatus status;

  @override
  Widget build(BuildContext context) {
    final content = status.content;
    final config = status.configuration;
    final discreet = config.privacy == LockScreenCardPrivacy.discreet;
    return Card(
      color: const Color(0xff17233d),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xff77c9ef), Color(0xff8366dc)],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discreet ? 'Fluvi · Pénzügyi pillanatkép' : content.focus,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      discreet ? 'Új tranzakció könyvelve' : content.primary,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discreet
                          ? 'A részletek feloldás után láthatók'
                          : content.secondary,
                      style: const TextStyle(color: Color(0xffc7d1e8)),
                    ),
                    if (!discreet && content.event != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        content.event!,
                        style: const TextStyle(color: Color(0xffc7d1e8)),
                      ),
                    ],
                    if (!content.available)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Mintaadat',
                          style: TextStyle(color: Color(0xffb8ccff)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

String _modeLabel(LockScreenCardMode value) => switch (value) {
  LockScreenCardMode.mind => 'Mind',
  LockScreenCardMode.balance => 'Balance',
  LockScreenCardMode.budget => 'Budget',
};
String _axisLabel(LockScreenCardTimeAxis value) => switch (value) {
  LockScreenCardTimeAxis.sum => 'SUM',
  LockScreenCardTimeAxis.year => 'Év',
  LockScreenCardTimeAxis.month => 'Hónap',
  LockScreenCardTimeAxis.day => 'Nap',
};
String _eventLineLabel(LockScreenCardEventLine value) => switch (value) {
  LockScreenCardEventLine.related => 'Utolsó kapcsolódó tétel',
  LockScreenCardEventLine.processed => 'Utolsó feldolgozott tranzakció',
  LockScreenCardEventLine.hidden => 'Elrejtve',
};
