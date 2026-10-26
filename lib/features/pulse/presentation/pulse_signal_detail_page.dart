import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'widgets/pulse_charts.dart';
import 'widgets/pulse_indicator_card.dart';

class PulseSignalDetailPage extends StatefulWidget {
  const PulseSignalDetailPage({
    super.key,
    required this.indicator,
    required this.repository,
    required this.scope,
    this.subscriptionOptions = const [],
  });
  final PulseIndicatorSnapshot indicator;
  final PulseRepository repository;
  final DateTime scope;
  final List<PulseSourceOption> subscriptionOptions;
  @override
  State<PulseSignalDetailPage> createState() => _PulseSignalDetailPageState();
}

class _PulseSignalDetailPageState extends State<PulseSignalDetailPage> {
  late PulseIndicatorSnapshot _indicator;
  late double _draft;
  late final TextEditingController _input;
  bool _saving = false;
  bool _dirty = false;
  bool _changingSources = false;
  late List<PulseSourceOption> _subscriptionOptions;
  List<PulseSignalInspection> _inspections = const [];
  bool _loadingInspector = true;

  @override
  void initState() {
    super.initState();
    _indicator = widget.indicator;
    _draft = _indicator.thresholds.firstOrNull?.value ?? 0;
    _input = TextEditingController(text: _draft.toStringAsFixed(_digits));
    _subscriptionOptions = widget.subscriptionOptions;
    _reloadInspector();
  }

  int get _digits =>
      (_indicator.thresholds.firstOrNull?.definition.step ?? 1) < 1 ? 2 : 0;
  PulseThresholdValue? get _threshold => _indicator.thresholds.firstOrNull;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _setDraft(double value) {
    final definition = _threshold?.definition;
    if (definition == null) return;
    setState(() {
      _draft = value.clamp(definition.minimum, definition.maximum);
      _dirty = true;
      _indicator = _indicator.withThreshold(_draft);
      _input.value = TextEditingValue(
        text: _draft.toStringAsFixed(_digits),
        selection: TextSelection.collapsed(
          offset: _draft.toStringAsFixed(_digits).length,
        ),
      );
    });
  }

  Future<void> _reloadInspector() async {
    try {
      final inspections = await widget.repository.signalInspection(
        year: widget.scope.year,
        month: widget.scope.month,
        indicatorId: _indicator.id,
      );
      if (mounted) {
        setState(() {
          _inspections = inspections;
          _loadingInspector = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInspector = false);
    }
  }

  Future<void> _refreshNativePulse() async {
    final snapshot = await widget.repository.dashboard(
      year: widget.scope.year,
      month: widget.scope.month,
    );
    if (!mounted) return;
    setState(() {
      _subscriptionOptions = snapshot.subscriptionOptions;
      _indicator = snapshot.byId(_indicator.id) ?? _indicator;
    });
    await _reloadInspector();
  }

  Future<void> _save() async {
    final threshold = _threshold;
    if (threshold == null || !_dirty) return;
    setState(() => _saving = true);
    try {
      await widget.repository.setThreshold(
        indicatorId: _indicator.id,
        thresholdKey: threshold.key,
        value: _draft,
      );
      if (mounted) setState(() => _dirty = false);
      await _refreshNativePulse();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setSubscriptionSource(
    PulseSourceOption option,
    bool selected,
  ) async {
    if (_changingSources) return;
    setState(() => _changingSources = true);
    try {
      await widget.repository.setSubscriptionSource(
        targetKey: option.targetKey,
        selected: selected,
      );
      await _refreshNativePulse();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Az előfizetés-forrás mentése nem sikerült.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingSources = false);
    }
  }

  Future<void> _reset() async {
    final threshold = _threshold;
    if (threshold == null) return;
    await widget.repository.resetThreshold(
      indicatorId: _indicator.id,
      thresholdKey: threshold.key,
    );
    if (mounted) {
      setState(() {
        _draft = threshold.definition.defaultValue;
        _indicator = _indicator.withThreshold(_draft);
        _input.text = _draft.toStringAsFixed(_digits);
        _dirty = false;
      });
      await _refreshNativePulse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final threshold = _threshold;
    return RepaintBoundary(
      key: const ValueKey('pulse-signal-detail-boundary'),
      child: Scaffold(
        backgroundColor: FluviVisualTokens.pageBackground,
        appBar: AppBar(
          title: Text(_indicator.title),
          backgroundColor: FluviVisualTokens.pageBackground,
          elevation: 0,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 104),
                children: [
                  Text(
                    pulseFormatValue(_indicator),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: FluviVisualTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _indicator.description,
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 260,
                    child: pulseChartFor(_indicator, PulseChartSize.expanded),
                  ),
                  if (_indicator.availability !=
                      PulseAvailability.available) ...[
                    const SizedBox(height: 10),
                    _InfoPanel(
                      title: 'Adatminőség',
                      body: _indicator.missingReasons.isEmpty
                          ? _indicator.summary
                          : _indicator.missingReasons.join('\n'),
                    ),
                  ],
                  if (threshold != null) ...[
                    const SizedBox(height: 18),
                    _ThresholdEditor(
                      threshold: threshold,
                      value: _draft,
                      controller: _input,
                      onChanged: _setDraft,
                      onReset: _reset,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SignalInspector(
                    indicator: _indicator,
                    inspections: _inspections,
                    loading: _loadingInspector,
                  ),
                  if (_indicator.id == 'PULSE-016') ...[
                    const SizedBox(height: 18),
                    _SubscriptionSourceEditor(
                      options: _subscriptionOptions,
                      changing: _changingSources,
                      onChanged: _setSubscriptionSource,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _InfoPanel(
                    title: 'Hogyan számoljuk?',
                    body: _calculationText(_indicator),
                  ),
                  const SizedBox(height: 12),
                  _InfoPanel(
                    title: 'Felhasznált adatok',
                    body:
                        '${_indicator.sources.join(' · ')}\nMintaszám: ${_indicator.sampleCount}',
                  ),
                ],
              ),
              if (_dirty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(
                          _saving ? 'Mentés…' : 'Beállítások mentése',
                        ),
                      ),
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

class _ThresholdEditor extends StatelessWidget {
  const _ThresholdEditor({
    required this.threshold,
    required this.value,
    required this.controller,
    required this.onChanged,
    required this.onReset,
  });
  final PulseThresholdValue threshold;
  final double value;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;
  final Future<void> Function() onReset;
  @override
  Widget build(BuildContext context) {
    final def = threshold.definition;
    return _InfoPanel(
      title: 'Triggerpontok',
      bodyWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A marker csak konfigurációs referencia; nem indít automatikus eseményt.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: def.minimum,
            max: def.maximum,
            divisions: ((def.maximum - def.minimum) / def.step).round().clamp(
              1,
              1000,
            ),
            onChanged: onChanged,
          ),
          Row(
            children: [
              SizedBox(
                width: 112,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Pontosan',
                  ),
                  onSubmitted: (raw) => onChanged(
                    double.tryParse(raw.replaceAll(',', '.')) ?? value,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onReset, child: const Text('Alapérték')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSourceEditor extends StatelessWidget {
  const _SubscriptionSourceEditor({
    required this.options,
    required this.changing,
    required this.onChanged,
  });
  final List<PulseSourceOption> options;
  final bool changing;
  final Future<void> Function(PulseSourceOption option, bool selected)
  onChanged;

  @override
  Widget build(BuildContext context) => _InfoPanel(
    title: 'Előfizetésnek jelölt források',
    bodyWidget: options.isEmpty
        ? const Text(
            'Nincs aktív recurring szabály vagy választható kategória.',
            style: TextStyle(color: FluviVisualTokens.textSecondary),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options
                .map(
                  (option) => FilterChip(
                    label: Text(
                      '${option.kind == 'rule' ? 'Szabály' : 'Kategória'} · ${option.label}',
                    ),
                    selected: option.isSelected,
                    onSelected: changing
                        ? null
                        : (selected) => onChanged(option, selected),
                  ),
                )
                .toList(growable: false),
          ),
  );
}

class _SignalInspector extends StatelessWidget {
  const _SignalInspector({
    required this.indicator,
    required this.inspections,
    required this.loading,
  });

  final PulseIndicatorSnapshot indicator;
  final List<PulseSignalInspection> inspections;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _InfoPanel(
        title: 'Signal Inspector',
        body: 'Diagnosztika betöltése…',
      );
    }
    if (inspections.isEmpty) {
      return const _InfoPanel(
        title: 'Signal Inspector',
        body: 'A jel ehhez az időszakhoz még nem értékelhető.',
      );
    }
    return _InfoPanel(
      title: 'Signal Inspector',
      bodyWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${indicator.title}\\n${indicator.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const Text(
                'Diagnosztika',
                style: TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...inspections.map(
            (inspection) => _SignalInspectionBlock(inspection: inspection),
          ),
        ],
      ),
    );
  }
}

class _SignalInspectionBlock extends StatelessWidget {
  const _SignalInspectionBlock({required this.inspection});
  final PulseSignalInspection inspection;

  @override
  Widget build(BuildContext context) {
    final trace = inspection.trace;
    final evidence = inspection.evidence;
    final missing = (trace['missingInputsHu'] as List<Object?>? ?? const [])
        .cast<String>();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inspection.targetKey.isNotEmpty) ...[
            Text(
              'Cél: ${inspection.targetKey}',
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _InspectorRow(
                  'Nyers jel',
                  _activityLabel(inspection.activityState),
                ),
                _InspectorRow('Erősség', _strengthLabel(inspection.strength)),
                _InspectorRow(
                  'Adatminőség',
                  _qualityLabel(inspection.dataQuality),
                ),
                _InspectorRow('Irány', inspection.trendDirection),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Miért ez az állapot?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _InspectorRow('Mért érték', _number(inspection.measuredValue)),
          _InspectorRow(
            'Beállított threshold',
            _number(inspection.thresholdValue),
          ),
          _InspectorRow(
            'Feltétel',
            (trace['thresholdConditionMet'] as bool? ?? false)
                ? 'teljesült'
                : 'nem teljesült',
          ),
          _InspectorRow(
            'Megerősítés',
            '${trace['confirmationCount'] ?? 0} / ${trace['confirmationRequired'] ?? 1}',
          ),
          if (missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                missing.join('\\n'),
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          if (inspection.activityState ==
                  PulseSignalActivityState.evaluationSuspended &&
              inspection.lastPersistedState != null) ...[
            const SizedBox(height: 8),
            _InspectorRow(
              'Utolsó valódi állapot',
              inspection.lastPersistedState!['activityState'] as String? ?? '—',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Jelazonosság és bizonyíték',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _InspectorRow(
            'Situation',
            evidence['situationKey'] as String? ?? '—',
          ),
          _InspectorRow(
            'Bizonyítékcsalád',
            evidence['evidenceFamily'] as String? ?? '—',
          ),
          _InspectorRow(
            'Cél',
            evidence['affectedTarget'] as String? ?? 'globális',
          ),
          _InspectorRow(
            'Pénzügyi hatás',
            _forint(
              (evidence['actualImpactMinor'] as num?)?.toInt() ??
                  (evidence['projectedImpactMinor'] as num?)?.toInt(),
            ),
          ),
          if (inspection.events.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Korábbi jelállapotok',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...inspection.events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.more_time_outlined,
                      size: 16,
                      color: Color(0xFF7A8492),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_eventLabel(event.kind)}\\n${event.cause}',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: FluviVisualTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

String _activityLabel(PulseSignalActivityState value) => switch (value) {
  PulseSignalActivityState.normal => 'Normál',
  PulseSignalActivityState.pendingConfirmation => 'Megerősítésre vár',
  PulseSignalActivityState.active => 'Aktív',
  PulseSignalActivityState.recovering => 'Javuló',
  PulseSignalActivityState.resolved => 'Feloldva',
  PulseSignalActivityState.evaluationSuspended => 'Kiértékelés szünetel',
};

String _strengthLabel(PulseSignalStrength? value) => switch (value) {
  PulseSignalStrength.weak => 'Gyenge',
  PulseSignalStrength.medium => 'Közepes',
  PulseSignalStrength.strong => 'Erős',
  PulseSignalStrength.critical => 'Kritikus',
  null => '—',
};

String _qualityLabel(PulseSignalDataQuality value) => switch (value) {
  PulseSignalDataQuality.sufficient => 'Megfelelő',
  PulseSignalDataQuality.limited => 'Korlátozott',
  PulseSignalDataQuality.insufficient => 'Hiányos',
  PulseSignalDataQuality.notApplicable => 'Nem alkalmazható',
};

String _eventLabel(String event) => switch (event) {
  'activated' => 'Nyers jel aktiválódott',
  'strengthened' => 'Erősebb lett',
  'weakened' => 'Gyengült',
  'resolved' => 'Feloldódott',
  'reactivated' => 'Újra aktív',
  'evaluationSuspended' => 'Kiértékelés szünetel',
  'evaluationRestored' => 'Kiértékelés helyreállt',
  'configurationChanged' => 'Beállítás módosult',
  _ => event,
};

String _number(double? value) =>
    value == null ? '—' : value.toStringAsFixed(value.abs() < 10 ? 2 : 0);
String _forint(int? value) =>
    value == null ? '—' : '${(value / 100).round()} Ft';

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, this.body, this.bodyWidget});
  final String title;
  final String? body;
  final Widget? bodyWidget;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        bodyWidget ??
            Text(
              body ?? '',
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                height: 1.35,
              ),
            ),
      ],
    ),
  );
}

String _calculationText(
  PulseIndicatorSnapshot indicator,
) => switch (indicator.id) {
  'PULSE-004' =>
    'A könyvelt havi kiadásokhoz konzervatív történeti baseline és rövid távú momentum-forgatókönyv társul. A még pending ghost occurrence-ok csak egyszer, a várható napjukon jelennek meg.',
  'PULSE-003' =>
    'Az utolsó 7 nap átlagos változó költését vetjük össze a keretből vagy a 28 napos mintából számolt fenntartható napi ütemmel.',
  'PULSE-015' =>
    'A már realizált recurring tételek és a még pending ghostok havi összege egyszer szerepel. A teljesült occurrence nem kerül másodszor a forecastba.',
  _ =>
    '${indicator.description} A mutató csak a felsorolt, valóban elérhető Core-adatokból számol; hiányzó bemenetnél ezt külön jelöli.',
};

extension on List<PulseThresholdValue> {
  PulseThresholdValue? get firstOrNull => isEmpty ? null : first;
}
