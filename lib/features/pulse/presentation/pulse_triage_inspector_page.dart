import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_signal_detail_page.dart';

class PulseSituationsPage extends StatefulWidget {
  const PulseSituationsPage({
    super.key,
    required this.repository,
    required this.scope,
    required this.situations,
    required this.indicators,
  });

  final PulseRepository repository;
  final DateTime scope;
  final List<PulseSituationSnapshot> situations;
  final List<PulseIndicatorSnapshot> indicators;

  @override
  State<PulseSituationsPage> createState() => _PulseSituationsPageState();
}

class _PulseSituationsPageState extends State<PulseSituationsPage> {
  _SituationFilter _filter = _SituationFilter.all;

  @override
  Widget build(BuildContext context) {
    final items = widget.situations
        .where(
          (item) => switch (_filter) {
            _SituationFilter.all => true,
            _SituationFilter.ready => item.state == PulseSituationState.ready,
            _SituationFilter.forming =>
              item.state == PulseSituationState.forming,
            _SituationFilter.history => switch (item.state) {
              PulseSituationState.improving ||
              PulseSituationState.resolved ||
              PulseSituationState.suspended => true,
              _ => false,
            },
          },
        )
        .toList(growable: false);
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pénzügyi helyzetek'),
            Text('Triage áttekintés', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        itemCount: 3 + (items.isEmpty ? 1 : items.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${widget.scope.year}. ${_monthName(widget.scope.month)}',
              style: const TextStyle(color: FluviVisualTokens.textSecondary),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_SituationFilter>(
                  segments: const [
                    ButtonSegment(
                      value: _SituationFilter.all,
                      label: Text('Összes'),
                    ),
                    ButtonSegment(
                      value: _SituationFilter.ready,
                      label: Text('Kész'),
                    ),
                    ButtonSegment(
                      value: _SituationFilter.forming,
                      label: Text('Alakuló'),
                    ),
                    ButtonSegment(
                      value: _SituationFilter.history,
                      label: Text('Előzmények'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.first),
                ),
              ),
            );
          }
          if (index == 2) return const SizedBox(height: 14);
          if (items.isEmpty) {
            return const _QuietEmpty(
              text: 'Ebben a nézetben nincs perzisztált pénzügyi helyzet.',
            );
          }
          final item = items[index - 3];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SituationCard(situation: item, onTap: () => _open(item)),
          );
        },
      ),
    );
  }

  Future<void> _open(PulseSituationSnapshot situation) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PulseTriageInspectorPage(
            repository: widget.repository,
            scope: widget.scope,
            situation: situation,
            indicators: widget.indicators,
          ),
        ),
      );
}

enum _SituationFilter { all, ready, forming, history }

class PulseTriageInspectorPage extends StatefulWidget {
  const PulseTriageInspectorPage({
    super.key,
    required this.repository,
    required this.scope,
    required this.situation,
    required this.indicators,
  });
  final PulseRepository repository;
  final DateTime scope;
  final PulseSituationSnapshot situation;
  final List<PulseIndicatorSnapshot> indicators;

  @override
  State<PulseTriageInspectorPage> createState() =>
      _PulseTriageInspectorPageState();
}

class _PulseTriageInspectorPageState extends State<PulseTriageInspectorPage> {
  PulseSituationInspection? _inspection;
  Object? _error;
  bool _loading = true;
  int _historyOffset = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = !more;
      _error = null;
    });
    try {
      final inspection = await widget.repository.triageInspection(
        year: widget.scope.year,
        month: widget.scope.month,
        situationKey: widget.situation.situationKey,
        historyOffset: more ? _historyOffset : 0,
      );
      if (!mounted) return;
      setState(() {
        _inspection = more && _inspection != null
            ? PulseSituationInspection(
                situation: inspection.situation,
                events: [..._inspection!.events, ...inspection.events],
              )
            : inspection;
        _historyOffset = _inspection!.events.length;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final situation = _inspection?.situation ?? widget.situation;
    final independent = situation.evidenceUnits
        .where((unit) => unit.countableForFormation)
        .toList(growable: false);
    final related = situation.evidenceUnits
        .where(
          (unit) =>
              !unit.countableForFormation &&
              unit.role != PulseEvidenceRole.excluded,
        )
        .toList(growable: false);
    final excluded = situation.evidenceUnits
        .where((unit) => unit.role == PulseEvidenceRole.excluded)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(situation.title),
            Text(situation.periodKey, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
        actions: [
          _StatePill(state: situation.state),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading && _inspection == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _inspection == null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: const Text('Újrapróbálás'),
              ),
            )
          : ListView(
              restorationId: 'triage-${situation.situationKey}',
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (situation.historicalInspection) const _HistoricalNotice(),
                _SummaryPanel(situation: situation),
                const SizedBox(height: 18),
                _SectionTitle('Bizonyítékok'),
                const SizedBox(height: 8),
                _EvidenceGroup(
                  title: 'Önálló bizonyítékok',
                  empty: 'Nincs beszámítható önálló bizonyíték.',
                  units: independent,
                  onTap: _openSignal,
                ),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EvidenceGroup(
                    title: 'Kapcsolódó bizonyítékok',
                    empty: '',
                    units: related,
                    onTap: _openSignal,
                  ),
                ],
                if (excluded.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EvidenceGroup(
                    title: 'Nem beszámítható jelek',
                    empty: '',
                    units: excluded,
                    onTap: _openSignal,
                  ),
                ],
                const SizedBox(height: 12),
                _IndependenceSummary(situation: situation),
                const SizedBox(height: 18),
                _SectionTitle('Helyzetképzési szabályok'),
                const SizedBox(height: 8),
                ...situation.decisionTrace.rules.map(
                  (rule) => _GateTile(rule: rule),
                ),
                if (situation.state == PulseSituationState.forming) ...[
                  const SizedBox(height: 16),
                  _WhyNotReady(trace: situation.decisionTrace),
                ],
                const SizedBox(height: 18),
                _SectionTitle('Helyzet előzményei'),
                const SizedBox(height: 8),
                if ((_inspection?.events ?? const []).isEmpty)
                  const _QuietEmpty(
                    text: 'Még nincs perzisztált helyzetátmenet.',
                  )
                else
                  ..._inspection!.events.map(_HistoryTile.new),
                if ((_inspection?.events.length ?? 0) >= 30)
                  TextButton.icon(
                    onPressed: _loading ? null : () => _load(more: true),
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('Korábbi események'),
                  ),
              ],
            ),
    );
  }

  Future<void> _openSignal(PulseEvidenceUnit unit) async {
    final indicator = widget.indicators
        .where((item) => item.id == unit.indicatorId)
        .firstOrNull;
    if (indicator == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseSignalDetailPage(
          indicator: indicator,
          repository: widget.repository,
          scope: widget.scope,
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.situation});
  final PulseSituationSnapshot situation;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HELYZETKÉPZÉS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 10),
        _Pair('Állapot', _stateTitle(situation.state)),
        _Pair(
          'Teljesült szabály',
          situation.formationRule ?? 'Még nem teljesült',
        ),
        _Pair(
          'Kapcsolódó jelek',
          '${situation.decisionTrace.relatedSignalCount}',
        ),
        _Pair(
          'Független bizonyítékok',
          '${situation.independentEvidenceCount}',
        ),
        _Pair(
          'Utolsó változás',
          _formatTime(situation.lastMaterialChangeAtUtcMs),
        ),
      ],
    ),
  );
}

class _EvidenceGroup extends StatelessWidget {
  const _EvidenceGroup({
    required this.title,
    required this.empty,
    required this.units,
    required this.onTap,
  });

  final String title;
  final String empty;
  final List<PulseEvidenceUnit> units;
  final ValueChanged<PulseEvidenceUnit> onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: FluviVisualTokens.textSecondary,
        ),
      ),
      const SizedBox(height: 7),
      if (units.isEmpty && empty.isNotEmpty)
        Text(
          empty,
          style: const TextStyle(
            fontSize: 12,
            color: FluviVisualTokens.textSecondary,
          ),
        )
      else
        ...units.map(
          (unit) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _EvidenceCard(unit: unit, onTap: () => onTap(unit)),
          ),
        ),
    ],
  );
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.unit, required this.onTap});
  final PulseEvidenceUnit unit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _surface(radius: 18),
        child: Row(
          children: [
            Icon(
              unit.countableForFormation
                  ? Icons.account_tree_outlined
                  : Icons.link_outlined,
              color: FluviVisualTokens.textSecondary,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    unit.indicatorId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_roleTitle(unit.role)} · ${_independenceTitle(unit.independence)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _strengthTitle(unit.strength),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (unit.measuredValue != null)
                  Text(
                    _decimal(unit.measuredValue!),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _IndependenceSummary extends StatelessWidget {
  const _IndependenceSummary({required this.situation});
  final PulseSituationSnapshot situation;
  @override
  Widget build(BuildContext context) {
    final units = situation.evidenceUnits;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bizonyíték-függetlenség',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _Pair(
            'Kapcsolódó jelek',
            '${situation.decisionTrace.relatedSignalCount}',
          ),
          _Pair(
            'Önálló bizonyítékok',
            '${units.where((u) => u.countableForFormation).length}',
          ),
          _Pair(
            'Származtatott / átfedő',
            '${units.where((u) => !u.countableForFormation).length}',
          ),
        ],
      ),
    );
  }
}

class _GateTile extends StatelessWidget {
  const _GateTile({required this.rule});
  final PulseTriageRuleResult rule;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
    title: Text(
      _gateTitle(rule.ruleId),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    trailing: Text(
      rule.passed
          ? 'Teljesült'
          : rule.applicable
          ? 'Nem teljesült'
          : 'Nem alkalmazható',
      style: TextStyle(
        fontSize: 12,
        color: rule.passed
            ? const Color(0xFF2C7A67)
            : FluviVisualTokens.textSecondary,
      ),
    ),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pair('Szükséges bizonyíték', '${rule.requiredEvidenceCount}'),
            _Pair('Rendelkezésre álló', '${rule.actualEvidenceCount}'),
            _Pair(
              'Adatminőség',
              rule.dataQualityPassed ? 'megfelelő' : 'nem megfelelő',
            ),
            if (rule.reasonCodes.isNotEmpty)
              Text(
                _reasonHu(rule.reasonCodes.first),
                style: const TextStyle(
                  fontSize: 12,
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _WhyNotReady extends StatelessWidget {
  const _WhyNotReady({required this.trace});
  final PulseTriageTrace trace;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mi hiányzik?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          trace.explanation.isNotEmpty
              ? trace.explanation.join('\n')
              : 'A döntési nyomvonal még nem mutat teljesült helyzetképzési feltételt.',
        ),
      ],
    ),
  );
}

class _SituationCard extends StatelessWidget {
  const _SituationCard({required this.situation, required this.onTap});
  final PulseSituationSnapshot situation;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _surface(radius: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          situation.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatePill(state: situation.state),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    situation.periodKey,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${situation.independentEvidenceCount} független bizonyíték · ${situation.formationRule ?? 'feltétel még nem teljesült'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});
  final PulseSituationState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EEFF),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      _stateTitle(state),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(this.event);
  final PulseSituationEvent event;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.timeline,
          size: 17,
          color: FluviVisualTokens.textSecondary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _eventTitle(event.kind),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (event.explanation.isNotEmpty)
                Text(
                  event.explanation.first,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
              Text(
                _formatTime(event.createdAtUtcMs),
                style: const TextStyle(
                  fontSize: 11,
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoricalNotice extends StatelessWidget {
  const _HistoricalNotice();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Text(
      'Történeti kiértékelés: ez a nézet nem állít elő élő helyzeteseményt.',
      style: TextStyle(fontSize: 12, color: FluviVisualTokens.textSecondary),
    ),
  );
}

class _QuietEmpty extends StatelessWidget {
  const _QuietEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _surface(),
    child: Text(
      text,
      style: const TextStyle(color: FluviVisualTokens.textSecondary),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
  );
}

class _Pair extends StatelessWidget {
  const _Pair(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _surface({double radius = 18}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: FluviVisualTokens.border),
  boxShadow: FluviVisualTokens.cardSurfaceShadows,
);

String _monthName(int month) => const [
  'január',
  'február',
  'március',
  'április',
  'május',
  'június',
  'július',
  'augusztus',
  'szeptember',
  'október',
  'november',
  'december',
][month - 1];
String _stateTitle(PulseSituationState state) => switch (state) {
  PulseSituationState.forming => 'Alakuló',
  PulseSituationState.ready => 'Kész',
  PulseSituationState.improving => 'Javuló',
  PulseSituationState.resolved => 'Feloldva',
  PulseSituationState.suspended => 'Szünetel',
};
String _strengthTitle(PulseSignalStrength? value) => switch (value) {
  PulseSignalStrength.weak => 'Gyenge',
  PulseSignalStrength.medium => 'Közepes',
  PulseSignalStrength.strong => 'Erős',
  PulseSignalStrength.critical => 'Kritikus',
  null => 'Nincs erősség',
};
String _roleTitle(PulseEvidenceRole role) => switch (role) {
  PulseEvidenceRole.leading => 'Vezető bizonyíték',
  PulseEvidenceRole.independentSupport => 'Önálló bizonyíték',
  PulseEvidenceRole.derivedSupport => 'Származtatott',
  PulseEvidenceRole.overlappingSupport => 'Átfedő',
  PulseEvidenceRole.contextOnly => 'Kontextus',
  PulseEvidenceRole.excluded => 'Nem beszámítható',
};
String _independenceTitle(PulseEvidenceIndependence value) => switch (value) {
  PulseEvidenceIndependence.independent => 'független',
  PulseEvidenceIndependence.derived => 'származtatott',
  PulseEvidenceIndependence.overlapping => 'átfedő',
  PulseEvidenceIndependence.unresolved => 'nem igazolható',
};
String _gateTitle(String id) =>
    const {
      'critical-single': 'Critical Single',
      'strong-material': 'Strong Material',
      'medium-pair': 'Medium Pair',
      'weak-triple': 'Weak Triple',
      'verified-recovery': 'Verified Recovery',
      'data-quality-operational': 'Operational',
    }[id] ??
    id;
String _reasonHu(String code) => switch (code) {
  'independent-medium-evidence-missing' =>
    'Nincs két független közepes bizonyíték.',
  'independent-weak-evidence-missing' =>
    'Nincs három független gyenge bizonyíték.',
  'material-impact-not-reached' =>
    'A számított pénzügyi hatás még nem éri el a domain küszöbét.',
  _ => 'A feltétel jelenleg nem teljesül.',
};
String _eventTitle(String kind) =>
    const {
      'formed': 'Alakuló helyzet létrejött.',
      'ready': 'Ready állapotba került.',
      'strengthened': 'A bizonyíték erősödött.',
      'weakened': 'A bizonyíték gyengült.',
      'improving': 'A helyzet javuló állapotba került.',
      'resolved': 'A helyzet feloldódott.',
      'suspended': 'A kiértékelés szünetel.',
      'reopened': 'A helyzet újra kialakult.',
      'configurationChanged': 'A konfiguráció változott.',
    }[kind] ??
    kind;
String _formatTime(int? utcMs) => utcMs == null
    ? 'Nincs korábbi változás'
    : '${DateTime.fromMillisecondsSinceEpoch(utcMs).toLocal().year}. ${DateTime.fromMillisecondsSinceEpoch(utcMs).toLocal().month.toString().padLeft(2, '0')}. ${DateTime.fromMillisecondsSinceEpoch(utcMs).toLocal().day.toString().padLeft(2, '0')}.';
String _decimal(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

extension _PulseFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
