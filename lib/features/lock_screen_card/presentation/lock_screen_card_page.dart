import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _LockScreenCardPageState extends State<LockScreenCardPage>
    with WidgetsBindingObserver {
  LockScreenCardStatus? _status;
  bool _saving = false;
  bool _savingWidget = false;
  bool _savingNative = false;
  int _statusGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final generation = ++_statusGeneration;
    final status = await widget.repository.load();
    if (mounted && generation == _statusGeneration) {
      setState(() => _status = status);
    }
  }

  Future<void> _save(LockScreenCardConfiguration next) async {
    if (_saving) return;
    final generation = ++_statusGeneration;
    setState(() => _saving = true);
    try {
      final status = await widget.repository.save(next);
      if (mounted && generation == _statusGeneration) {
        setState(() => _status = status);
      }
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

  Future<void> _saveNative(NativeKeyguardCardConfiguration next) async {
    if (_savingNative) return;
    final generation = ++_statusGeneration;
    setState(() => _savingNative = true);
    try {
      final status = await widget.repository.saveNativeKeyguardCard(next);
      if (mounted && generation == _statusGeneration) {
        setState(() => _status = status);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A natív zárképernyőkártya mentése nem sikerült.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNative = false);
    }
  }

  Future<void> _changeNativeRequested(bool value) async {
    final native = _status!.nativeCard.configuration;
    if (!value) {
      await _saveNative(native.copyWith(requested: false));
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fluvi-kártya a zárképernyőn'),
        content: const Text(
          'A Fluvi a saját pénzügyi kártyáját jeleníti meg a felébresztett zárképernyő fölött. '
          'A kisegítő szolgáltatás a rendszerablakok szerkezetéből ismeri fel a zárképernyőt, '
          'a PIN-bevitelt és a gyorsbeállításokat. Az alkalmazások szövegét nem olvassa vagy menti. '
          'A kártya kezdetben elrejti a pénzügyi részleteket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Folytatás az Android beállításaiban'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _saveNative(
      native.copyWith(requested: true, showFinancialDetails: false),
    );
    if (mounted) await widget.repository.openNativeKeyguardSettings();
  }

  Future<void> _changeNativeDetails(bool value) async {
    final native = _status!.nativeCard.configuration;
    if (!value) {
      await _saveNative(native.copyWith(showFinancialDetails: false));
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pénzügyi részletek a zárolt képernyőn'),
        content: const Text(
          'Aki felébreszti a telefonodat, láthatja az összeget, a kategóriát és a kiválasztott tranzakciós sort. '
          'Az értesítések elrejtése erre a külön Fluvi-kártyára nem vonatkozik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Engedélyezés'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _saveNative(native.copyWith(showFinancialDetails: true));
    }
  }

  Future<void> _copyNativeDiagnostic(NativeKeyguardCardStatus native) async {
    const buildCommit = String.fromEnvironment(
      'FLUVI_BUILD_COMMIT',
      defaultValue: 'ismeretlen',
    );
    await Clipboard.setData(
      ClipboardData(
        text: [
          'FLUVI_KEYGUARD_DIAGNOSTIC',
          'build=$buildCommit',
          'requested=${native.configuration.requested}',
          'systemEnabled=${native.systemServiceEnabled}',
          'serviceConnected=${native.serviceConnected}',
          'lastDecision=${native.lastDecisionReason}',
          'lastAttach=${native.lastAttachResult}',
          'renderer=${native.materialDiagnostics.rendererBackend}',
          'hardwareAccelerated=${native.materialDiagnostics.hardwareAccelerated}',
          'shaderCreations=${native.materialDiagnostics.shaderCreationCount}',
          'animationStarts=${native.materialDiagnostics.animationStartCount}',
          'animationStops=${native.materialDiagnostics.animationStopCount}',
          'drawCount=${native.materialDiagnostics.drawCount}',
          'frameIntervalP50=${native.materialDiagnostics.frameIntervalP50}',
          'frameIntervalP95=${native.materialDiagnostics.frameIntervalP95}',
          'largeFrameGaps=${native.materialDiagnostics.largeFrameGapCount}',
          'rendererFailure=${native.materialDiagnostics.lastRendererFailure}',
          native.diagnosticSummary,
        ].join('\n'),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utolsó zárolási próba a vágólapon.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final config = status.configuration;
    final native = status.nativeCard;
    return Scaffold(
      appBar: AppBar(title: const Text('Zárképernyő')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          _WidgetPreviewCard(status: status),
          const SizedBox(height: 18),
          const Text(
            'Fluvi-kártya a zárképernyőn',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  key: const ValueKey('native-keyguard-card-requested'),
                  value: native.configuration.requested,
                  onChanged: _savingNative ? null : _changeNativeRequested,
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('Fluvi-kártya a zárképernyőn'),
                  subtitle: const Text(
                    'A telefon felébresztésekor mutatja a kiválasztott pénzügyi fókuszt.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    native.systemServiceEnabled
                        ? Icons.verified_outlined
                        : Icons.pending_outlined,
                  ),
                  title: const Text('Android kisegítő szolgáltatás'),
                  subtitle: Text(
                    !native.configuration.requested
                        ? 'Kikapcsolva'
                        : !native.systemServiceEnabled
                        ? 'Android-engedély szükséges — keresd: Fluvi · Zárképernyőkártya'
                        : !native.serviceConnected
                        ? 'Engedélyezve, kapcsolódás folyamatban'
                        : 'Szolgáltatás csatlakoztatva',
                  ),
                  trailing: TextButton(
                    onPressed: widget.repository.openNativeKeyguardSettings,
                    child: const Text('Android-beállítások'),
                  ),
                ),
              ],
            ),
          ),
          if (native.configuration.requested) ...[
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey('native-keyguard-card-details'),
                    value: native.configuration.showFinancialDetails,
                    onChanged: _savingNative ? null : _changeNativeDetails,
                    title: const Text('Pénzügyi részletek a zárolt képernyőn'),
                    subtitle: const Text(
                      'Külön beleegyezés: az összeg, a kategória és az eseménysor a háttérképen is látható lehet.',
                    ),
                  ),
                  ListTile(
                    title: const Text('Animáció'),
                    subtitle: const Text(
                      'A header animációját és beállításait követi. Diszkrét módban a pénzügyi állapot színei rejtve maradnak.',
                    ),
                    trailing: DropdownButton<NativeKeyguardCardAnimationMode>(
                      key: const ValueKey('native-keyguard-animation-mode'),
                      value: native.configuration.animationMode,
                      onChanged: _savingNative
                          ? null
                          : (value) {
                              if (value != null) {
                                _saveNative(
                                  native.configuration.copyWith(
                                    animationMode: value,
                                  ),
                                );
                              }
                            },
                      items: NativeKeyguardCardAnimationMode.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_animationModeLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Függőleges pozíció'),
                    subtitle: Slider(
                      value: native.configuration.verticalOffsetDp.toDouble(),
                      min: -96,
                      max: 96,
                      divisions: 12,
                      label: '${native.configuration.verticalOffsetDp} dp',
                      onChanged: _savingNative
                          ? null
                          : (value) => _saveNative(
                              native.configuration.copyWith(
                                verticalOffsetDp: value.round(),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Zárképernyő-diagnosztika'),
                subtitle: Text(
                  'Utolsó döntés: ${native.lastDecisionReason}\n'
                  'Csatolás: ${native.lastAttachResult}\n'
                  'Rajzoló: ${native.materialDiagnostics.rendererBackend} · '
                  'p50/p95: ${native.materialDiagnostics.frameIntervalP50}/${native.materialDiagnostics.frameIntervalP95} ms',
                ),
                trailing: TextButton(
                  onPressed: () => _copyNativeDiagnostic(native),
                  child: const Text('Utolsó próba másolása'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'A kártya fókusza',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _FinancialSnapshotWidgetSettings(
            status: status,
            saving: _savingWidget,
            onSave: _saveWidget,
          ),
          const SizedBox(height: 28),
          const Text(
            'Pénzügyi értesítés',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile.adaptive(
              key: const ValueKey('lock-screen-card-enabled'),
              value: config.enabled,
              onChanged: _saving
                  ? null
                  : (value) => _save(config.copyWith(enabled: value)),
              secondary: const Icon(Icons.lock_outline),
              title: const Text('Pénzügyi értesítés'),
              subtitle: Text(
                config.enabled
                    ? 'A kiválasztott pénzügyi fókusz Android-értesítésként jelenik meg.'
                    : 'Kikapcsolva; a választott fókusz megmarad.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Értesítés: mit kövessen?',
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
              title: Text('Ez az opcionális rendszerértesítés'),
              subtitle: Text(
                'A fenti Pénzügyi widget ettől független. A widgethez nem kell '
                'értesítési engedély vagy Fluvi-háttérszolgáltatás.',
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

  static String _animationModeLabel(NativeKeyguardCardAnimationMode value) =>
      switch (value) {
        NativeKeyguardCardAnimationMode.off => 'Kikapcsolva',
        NativeKeyguardCardAnimationMode.orbOnly => 'Csak az orb',
        NativeKeyguardCardAnimationMode.orbAndBackground =>
          'Orb és kártyaháttér',
      };
}

class _FinancialSnapshotWidgetSettings extends StatelessWidget {
  const _FinancialSnapshotWidgetSettings({
    required this.status,
    required this.saving,
    required this.onSave,
  });

  final LockScreenCardStatus status;
  final bool saving;
  final ValueChanged<FinancialSnapshotWidgetConfiguration> onSave;

  @override
  Widget build(BuildContext context) {
    final config = status.widget.configuration;
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
                  status.widget.hostWidgetCount == 0
                      ? 'Még nincs kihelyezett példány.'
                      : '${status.widget.hostWidgetCount} példányt lát a Fluvi. Ez nem igazolja, hogy zárképernyőn vannak.',
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
                _Dropdown<LockScreenCardMode>(
                  label: 'Mód',
                  value: config.mode,
                  values: LockScreenCardMode.values,
                  text: _modeLabel,
                  onChanged: saving
                      ? (_) {}
                      : (value) => onSave(config.copyWith(mode: value)),
                ),
                const SizedBox(height: 12),
                _Dropdown<LockScreenCardTimeAxis>(
                  label: 'Időtengely',
                  value: config.timeAxis,
                  values: LockScreenCardTimeAxis.values,
                  text: _axisLabel,
                  onChanged: saving
                      ? (_) {}
                      : (value) => onSave(config.copyWith(timeAxis: value)),
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
                  if (status.widget.categories.isEmpty)
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
                          status.widget.categories.any(
                            (item) => item.id == config.categoryId,
                          )
                          ? config.categoryId
                          : null,
                      decoration: const InputDecoration(labelText: 'Kategória'),
                      items: status.widget.categories
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
            children: LockScreenCardEventLine.values
                .map(
                  (value) => RadioListTile<LockScreenCardEventLine>(
                    value: value,
                    groupValue: config.eventLine,
                    onChanged: saving
                        ? null
                        : (next) => onSave(config.copyWith(eventLine: next)),
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
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              RadioListTile<LockScreenCardPrivacy>(
                value: LockScreenCardPrivacy.discreet,
                groupValue: config.privacy,
                onChanged: saving
                    ? null
                    : (value) => onSave(config.copyWith(privacy: value)),
                title: const Text('Diszkrét'),
                subtitle: const Text(
                  'A widgetgazda nem kap összeget, partnert, kategóriát, pontszámot vagy állapotot eláruló színt.',
                ),
              ),
              RadioListTile<LockScreenCardPrivacy>(
                value: LockScreenCardPrivacy.full,
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
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.widgets_outlined),
            title: Text('Hagyományos widget (opcionális)'),
            subtitle: Text(
              'Ez a kezdőképernyős AppWidget külön felület. A fenti beépített Fluvi-kártyához nem kell widgetgazda vagy kihelyezett példány; '
              'egyszer az Android kisegítő lehetőségein kell engedélyezni a „Fluvi · Zárképernyőkártya” szolgáltatást.',
            ),
          ),
        ),
      ],
    );
  }
}

class _WidgetPreviewCard extends StatelessWidget {
  const _WidgetPreviewCard({required this.status});
  final LockScreenCardStatus status;

  @override
  Widget build(BuildContext context) {
    final content = status.widget.content;
    final discreet = !status.nativeCard.configuration.showFinancialDetails;
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
