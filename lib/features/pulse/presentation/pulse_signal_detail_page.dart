import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'widgets/pulse_charts.dart';
import 'widgets/pulse_indicator_card.dart';

class PulseSignalDetailPage extends StatefulWidget {
  const PulseSignalDetailPage({super.key, required this.indicator, required this.repository});
  final PulseIndicatorSnapshot indicator;
  final PulseRepository repository;
  @override
  State<PulseSignalDetailPage> createState() => _PulseSignalDetailPageState();
}

class _PulseSignalDetailPageState extends State<PulseSignalDetailPage> {
  late PulseIndicatorSnapshot _indicator;
  late double _draft;
  late final TextEditingController _input;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _indicator = widget.indicator;
    _draft = _indicator.thresholds.firstOrNull?.value ?? 0;
    _input = TextEditingController(text: _draft.toStringAsFixed(_digits));
  }

  int get _digits => (_indicator.thresholds.firstOrNull?.definition.step ?? 1) < 1 ? 2 : 0;
  PulseThresholdValue? get _threshold => _indicator.thresholds.firstOrNull;

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _setDraft(double value) {
    final definition = _threshold?.definition;
    if (definition == null) return;
    setState(() {
      _draft = value.clamp(definition.minimum, definition.maximum);
      _dirty = true;
      _indicator = _indicator.withThreshold(_draft);
      _input.value = TextEditingValue(text: _draft.toStringAsFixed(_digits), selection: TextSelection.collapsed(offset: _draft.toStringAsFixed(_digits).length));
    });
  }

  Future<void> _save() async {
    final threshold = _threshold;
    if (threshold == null || !_dirty) return;
    setState(() => _saving = true);
    try {
      await widget.repository.setThreshold(indicatorId: _indicator.id, thresholdKey: threshold.key, value: _draft);
      if (mounted) setState(() => _dirty = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    final threshold = _threshold;
    if (threshold == null) return;
    await widget.repository.resetThreshold(indicatorId: _indicator.id, thresholdKey: threshold.key);
    if (mounted) {
      setState(() {
        _draft = threshold.definition.defaultValue;
        _indicator = _indicator.withThreshold(_draft);
        _input.text = _draft.toStringAsFixed(_digits);
        _dirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final threshold = _threshold;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: Text(_indicator.title),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 104),
            children: [
              Text(pulseFormatValue(_indicator), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: FluviVisualTokens.textPrimary)),
              const SizedBox(height: 3),
              Text(_indicator.description, style: const TextStyle(color: FluviVisualTokens.textSecondary)),
              const SizedBox(height: 18),
              SizedBox(height: 260, child: pulseChartFor(_indicator, PulseChartSize.expanded)),
              if (_indicator.availability != PulseAvailability.available) ...[
                const SizedBox(height: 10),
                _InfoPanel(title: 'Adatminőség', body: _indicator.missingReasons.isEmpty ? _indicator.summary : _indicator.missingReasons.join('\n')),
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
              _InfoPanel(title: 'Hogyan számoljuk?', body: _calculationText(_indicator)),
              const SizedBox(height: 12),
              _InfoPanel(title: 'Felhasznált adatok', body: '${_indicator.sources.join(' · ')}\nMintaszám: ${_indicator.sampleCount}'),
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
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(_saving ? 'Mentés…' : 'Beállítások mentése'),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _ThresholdEditor extends StatelessWidget {
  const _ThresholdEditor({required this.threshold, required this.value, required this.controller, required this.onChanged, required this.onReset});
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
      bodyWidget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A marker csak konfigurációs referencia; nem indít automatikus eseményt.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Slider(value: value, min: def.minimum, max: def.maximum, divisions: ((def.maximum - def.minimum) / def.step).round().clamp(1, 1000), onChanged: onChanged),
        Row(children: [
          SizedBox(width: 112, child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, labelText: 'Pontosan'),
            onSubmitted: (raw) => onChanged(double.tryParse(raw.replaceAll(',', '.')) ?? value),
          )),
          const Spacer(),
          TextButton(onPressed: onReset, child: const Text('Alapérték')),
        ]),
      ]),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, this.body, this.bodyWidget});
  final String title;
  final String? body;
  final Widget? bodyWidget;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: FluviVisualTokens.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      bodyWidget ?? Text(body ?? '', style: const TextStyle(color: FluviVisualTokens.textSecondary, height: 1.35)),
    ]),
  );
}

String _calculationText(PulseIndicatorSnapshot indicator) => switch (indicator.id) {
  'PULSE-004' => 'A könyvelt havi kiadásokhoz konzervatív történeti baseline és rövid távú momentum-forgatókönyv társul. A még pending ghost occurrence-ok csak egyszer, a várható napjukon jelennek meg.',
  'PULSE-003' => 'Az utolsó 7 nap átlagos változó költését vetjük össze a keretből vagy a 28 napos mintából számolt fenntartható napi ütemmel.',
  'PULSE-015' => 'A már realizált recurring tételek és a még pending ghostok havi összege egyszer szerepel. A teljesült occurrence nem kerül másodszor a forecastba.',
  _ => '${indicator.description} A mutató csak a felsorolt, valóban elérhető Core-adatokból számol; hiányzó bemenetnél ezt külön jelöli.',
};

extension on List<PulseThresholdValue> {
  PulseThresholdValue? get firstOrNull => isEmpty ? null : first;
}
