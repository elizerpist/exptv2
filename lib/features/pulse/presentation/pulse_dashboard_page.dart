import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../application/pulse_dashboard_controller.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_signal_detail_page.dart';
import 'pulse_triage_inspector_page.dart';
import 'pulse_priority_inspector_page.dart';
import 'pulse_delivery_settings_page.dart';
import 'widgets/pulse_charts.dart';
import 'widgets/pulse_indicator_card.dart';

class PulseDashboardPage extends StatefulWidget {
  const PulseDashboardPage({
    super.key,
    required this.repository,
    this.coreRevisions,
    this.fullscreen = false,
    this.headerStory,
    this.headerDeliveryKey,
  });
  final PulseRepository repository;
  final Stream<Object?>? coreRevisions;
  final bool fullscreen;

  /// Immutable copy of the Story that was actually visible when the user
  /// tapped the dashboard header. It is not replaced by a newer ranking.
  final PulseStoryDraft? headerStory;
  final String? headerDeliveryKey;

  @override
  State<PulseDashboardPage> createState() => _PulseDashboardPageState();
}

class _PulseDashboardPageState extends State<PulseDashboardPage>
    with WidgetsBindingObserver {
  late final PulseDashboardController _controller;
  StreamSubscription<Object?>? _coreRevisionSubscription;
  Timer? _revisionDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PulseDashboardController(repository: widget.repository);
    _controller.load();
    final revisions =
        widget.coreRevisions ??
        const EventChannel(
          'com.fluvi/dashboard_core_revision_stream',
        ).receiveBroadcastStream();
    _coreRevisionSubscription = revisions.listen((_) {
      _revisionDebounce?.cancel();
      _revisionDebounce = Timer(const Duration(milliseconds: 180), () {
        if (mounted) _controller.load();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revisionDebounce?.cancel();
    _coreRevisionSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.load();
  }

  Future<void> _openDetail(PulseIndicatorSnapshot indicator) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseSignalDetailPage(
          indicator: indicator,
          repository: widget.repository,
          scope: _controller.scope,
          subscriptionOptions:
              _controller.snapshot?.subscriptionOptions ?? const [],
        ),
      ),
    );
    if (mounted) _controller.load();
  }

  Future<void> _openSituation(PulseSituationSnapshot situation) async {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseTriageInspectorPage(
          repository: widget.repository,
          scope: _controller.scope,
          situation: situation,
          indicators: snapshot.indicators,
        ),
      ),
    );
    if (mounted) _controller.load();
  }

  Future<void> _openSituations(PulseDashboardSnapshot snapshot) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseSituationsPage(
          repository: widget.repository,
          scope: _controller.scope,
          situations: snapshot.situations,
          indicators: snapshot.indicators,
        ),
      ),
    );
    if (mounted) _controller.load();
  }

  Future<void> _openPriority(PulseDashboardSnapshot snapshot) async {
    final priority = snapshot.priority;
    if (priority == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulsePriorityInspectorPage(
          repository: widget.repository,
          scope: _controller.scope,
          initialPriority: priority,
          initialSituations: snapshot.situations,
          indicators: snapshot.indicators,
        ),
      ),
    );
    if (mounted) _controller.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final snapshot = _controller.snapshot;
      return Material(
        color: FluviVisualTokens.pageBackground,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _controller.load,
            child: CustomScrollView(
              key: const ValueKey('pulse-dashboard-page'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _PulseHeader(
                        onInfo: _showAbout,
                        onSettings: _openSettings,
                        onBack: widget.fullscreen
                            ? () => Navigator.of(context).maybePop()
                            : null,
                      ),
                      if (widget.headerStory case final story?) ...[
                        const SizedBox(height: 12),
                        _HeaderStoryContextCard(
                          story: story,
                          deliveryKey: widget.headerDeliveryKey,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _PeriodRow(
                        scope: _controller.scope,
                        onPrevious: () => _controller.shiftMonth(-1),
                        onNext: () => _controller.shiftMonth(1),
                      ),
                      const SizedBox(height: 14),
                      if (snapshot == null && _controller.loading)
                        const _LoadingPanel()
                      else if (snapshot == null && _controller.error != null)
                        _ErrorPanel(onRetry: _controller.load)
                      else if (snapshot != null) ...[
                        _TrajectoryCard(
                          indicator: snapshot.byId('PULSE-004'),
                          onTap: () {
                            final indicator = snapshot.byId('PULSE-004');
                            if (indicator != null) _openDetail(indicator);
                          },
                        ),
                        const SizedBox(height: 18),
                        _SituationOverview(
                          situations: snapshot.situations,
                          historical: snapshot.triageHistorical,
                          priority: snapshot.priority,
                          onOpen: _openSituation,
                          onOpenAll: () => _openSituations(snapshot),
                          onOpenPriority: () => _openPriority(snapshot),
                        ),
                        const SizedBox(height: 18),
                        _GroupRail(
                          group: _controller.group,
                          onChanged: _controller.selectGroup,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
                  ),
                ),
                if (snapshot != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                    sliver: _IndicatorGrid(
                      indicators: snapshot.inGroup(_controller.group),
                      onTap: _openDetail,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _showAbout() => showDialog<void>(
    context: context,
    builder: (context) => const AlertDialog(
      title: Text('Pulse mérőműszerek'),
      content: Text(
        'A Pulse a Fluvi Core valós Ledger-, Budget-, ismétlődési és Inbox-adataiból számol. A triggerpontok ebben a fázisban csak megjelenítési referenciák: nem küldenek értesítést és nem indítanak automatikus műveletet.',
      ),
    ),
  );

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            PulseDeliverySettingsPage(repository: widget.repository),
      ),
    );
  }
}

class _PulseHeader extends StatelessWidget {
  const _PulseHeader({
    required this.onInfo,
    required this.onSettings,
    this.onBack,
  });
  final VoidCallback onInfo;
  final VoidCallback onSettings;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (onBack != null)
        IconButton(
          tooltip: 'Vissza a Ledgerhez',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulse',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                color: FluviVisualTokens.textPrimary,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Pénzügyi indikátorok',
              style: TextStyle(
                fontSize: 13,
                color: FluviVisualTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Pulse beállításai és adatforrásai',
        onPressed: onSettings,
        icon: const Icon(Icons.tune_outlined),
      ),
      IconButton(
        tooltip: 'A Pulse működéséről',
        onPressed: onInfo,
        icon: const Icon(Icons.info_outline_rounded),
      ),
    ],
  );
}

class _HeaderStoryContextCard extends StatelessWidget {
  const _HeaderStoryContextCard({required this.story, this.deliveryKey});

  final PulseStoryDraft story;
  final String? deliveryKey;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('pulse-header-story-context'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A fejlécben megnyitott történet',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          story.headline,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (story.detail case final detail?) ...[
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(fontSize: 13)),
        ],
        if (deliveryKey != null) ...[
          const SizedBox(height: 5),
          const Text(
            'A történet azóta frissülhet; ez a megnyitáskori példány.',
            style: TextStyle(
              fontSize: 11,
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.scope,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime scope;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Előző hónap',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${_monthName(scope.month)} ${scope.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Következő hónap',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 4),
        const Text(
          '21 mutató',
          style: TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _TrajectoryCard extends StatelessWidget {
  const _TrajectoryCard({required this.indicator, required this.onTap});
  final PulseIndicatorSnapshot? indicator;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    if (indicator == null) return const SizedBox.shrink();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: FluviVisualTokens.cardSurfaceShadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pénzügyi pálya',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    pulseFormatValue(indicator!),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                indicator!.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 144,
                width: double.infinity,
                child: PulseForecastChart(
                  indicator: indicator!,
                  size: PulseChartSize.expanded,
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  _Legend(
                    color: Color(0xFF6E5CF1),
                    label: 'Tényleges / baseline',
                  ),
                  SizedBox(width: 12),
                  _Legend(color: Color(0x88715EFB), label: 'Momentum'),
                  SizedBox(width: 12),
                  _Legend(color: Color(0xFF94A3B8), label: 'Keret'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: FluviVisualTokens.textSecondary,
        ),
      ),
    ],
  );
}

class _SituationOverview extends StatelessWidget {
  const _SituationOverview({
    required this.situations,
    required this.historical,
    required this.priority,
    required this.onOpen,
    required this.onOpenAll,
    required this.onOpenPriority,
  });
  final List<PulseSituationSnapshot> situations;
  final bool historical;
  final PulsePriorityFrame? priority;
  final ValueChanged<PulseSituationSnapshot> onOpen;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenPriority;

  @override
  Widget build(BuildContext context) {
    final ready = situations
        .where((item) => item.state == PulseSituationState.ready)
        .toList(growable: false);
    final forming = situations
        .where((item) => item.state == PulseSituationState.forming)
        .toList(growable: false);
    final selected = priority?.selected;
    final previews = [
      ...ready.where((item) => item.situationKey != selected?.situationKey),
      ...forming,
    ].take(2).toList(growable: false);
    final otherReady =
        priority?.rankedCandidates
            .where((candidate) => candidate.rank > 1)
            .take(2)
            .toList(growable: false) ??
        const <PulsePriorityCandidate>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FluviVisualTokens.border),
        boxShadow: FluviVisualTokens.cardSurfaceShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pénzügyi helyzetek',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Triage áttekintés',
                      style: TextStyle(
                        fontSize: 12,
                        color: FluviVisualTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.account_tree_outlined,
                color: FluviVisualTokens.textSecondary,
              ),
            ],
          ),
          if (historical)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Történeti kiértékelés',
                style: TextStyle(
                  fontSize: 12,
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 13),
          Row(
            children: [
              _SituationCount(label: 'Kész helyzetek', value: ready.length),
              const SizedBox(width: 10),
              _SituationCount(
                label: 'Alakuló helyzetek',
                value: forming.length,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selected != null) ...[
            _PriorityFocusCard(
              candidate: selected,
              situation: _situationByKey(situations, selected.situationKey),
              onTap: onOpenPriority,
            ),
            if (otherReady.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'További helyzetek',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              ...otherReady.map(
                (candidate) => _PriorityCompactRow(
                  candidate: candidate,
                  situation: _situationByKey(
                    situations,
                    candidate.situationKey,
                  ),
                  onTap: () {
                    final situation = situations.firstWhere(
                      (item) => item.situationKey == candidate.situationKey,
                    );
                    onOpen(situation);
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
          ] else if (!historical) ...[
            const _PriorityEmptyState(),
            const SizedBox(height: 12),
          ],
          if (previews.isEmpty)
            const Text(
              'Jelenleg nincs kialakuló vagy kész pénzügyi helyzet.',
              style: TextStyle(
                fontSize: 12,
                color: FluviVisualTokens.textSecondary,
              ),
            )
          else
            ...previews.map(
              (situation) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: const Color(0xFFF9F9FD),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: ValueKey('pulse-situation-${situation.situationKey}'),
                    onTap: () => onOpen(situation),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  situation.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${situation.independentEvidenceCount} független bizonyíték · ${situation.formationRule ?? 'feltétel még nem teljesült'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: FluviVisualTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            situation.state == PulseSituationState.ready
                                ? 'Kész'
                                : 'Alakuló',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (situations.length > 2)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpenAll,
                child: const Text('Összes helyzet'),
              ),
            ),
        ],
      ),
    );
  }
}

PulseSituationSnapshot? _situationByKey(
  List<PulseSituationSnapshot> situations,
  String key,
) {
  for (final situation in situations) {
    if (situation.situationKey == key) return situation;
  }
  return null;
}

class _PriorityFocusCard extends StatelessWidget {
  const _PriorityFocusCard({
    required this.candidate,
    required this.situation,
    required this.onTap,
  });
  final PulsePriorityCandidate candidate;
  final PulseSituationSnapshot? situation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF7F6FD),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: const ValueKey('pulse-priority-focus'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Aktuális fókusz',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '1. hely',
                  style: TextStyle(
                    fontSize: 11,
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    situation?.title ?? candidate.situationKey,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${candidate.finalScore}',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              '/ 100 pont',
              style: const TextStyle(
                fontSize: 11,
                color: FluviVisualTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: candidate.finalScore / 100,
                minHeight: 7,
                color: const Color(0xFF8B85B5),
                backgroundColor: const Color(0xFFE7E5F0),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                _PriorityPill('Alap ${candidate.basePriority}'),
                ...candidate.modifiers
                    .where((item) => item.applied)
                    .map(
                      (item) => _PriorityPill(
                        '${_priorityModifierLabel(item.id)} +${item.value}',
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Miért ez az első?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _PriorityCompactRow extends StatelessWidget {
  const _PriorityCompactRow({
    required this.candidate,
    required this.situation,
    required this.onTap,
  });
  final PulsePriorityCandidate candidate;
  final PulseSituationSnapshot? situation;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(
              '${candidate.rank}.',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                situation?.title ?? candidate.situationKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${candidate.finalScore}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const Icon(Icons.chevron_right, size: 17),
          ],
        ),
      ),
    ),
  );
}

class _PriorityEmptyState extends StatelessWidget {
  const _PriorityEmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nincs kiválasztott fókuszhelyzet.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 3),
        Text(
          'Jelenleg nincs olyan kész pénzügyi helyzet, amelyet a Priority Engine rangsorolhatna.',
          style: TextStyle(
            fontSize: 11,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}

String _priorityModifierLabel(String id) => switch (id) {
  'material-impact' => 'Hatás',
  'due-soon' => 'Esedékesség',
  'independent-evidence' => 'Bizonyíték',
  _ => id,
};

class _SituationCount extends StatelessWidget {
  const _SituationCount({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: FluviVisualTokens.textSecondary,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _GroupRail extends StatelessWidget {
  const _GroupRail({required this.group, required this.onChanged});
  final PulseGroup group;
  final ValueChanged<PulseGroup> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: PulseGroup.values
        .map(
          (candidate) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: candidate == PulseGroup.systems ? 0 : 7,
              ),
              child: ChoiceChip(
                key: ValueKey('pulse-group-${candidate.name}'),
                label: Text(
                  switch (candidate) {
                    PulseGroup.spending => 'Költés',
                    PulseGroup.cashflow => 'Cashflow',
                    PulseGroup.systems => 'Rendszerek',
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: candidate == group,
                onSelected: (_) => onChanged(candidate),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

class _IndicatorGrid extends StatelessWidget {
  const _IndicatorGrid({required this.indicators, required this.onTap});
  final List<PulseIndicatorSnapshot> indicators;
  final ValueChanged<PulseIndicatorSnapshot> onTap;
  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.crossAxisExtent >= 840
          ? 3
          : constraints.crossAxisExtent >= 560
          ? 2
          : 1;
      return SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => PulseIndicatorCard(
            indicator: indicators[index],
            onTap: () => onTap(indicators[index]),
          ),
          childCount: indicators.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 194,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
      );
    },
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        const Text(
          'A Pulse adatai nem tölthetők be.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        FilledButton(onPressed: onRetry, child: const Text('Újrapróbálás')),
      ],
    ),
  );
}

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
