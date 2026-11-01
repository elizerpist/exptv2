import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/navigation/creation_slide_up_route.dart';
import '../application/pulse_dashboard_controller.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_delivery_settings_page.dart';
import 'pulse_priority_inspector_page.dart';
import 'pulse_signal_detail_page.dart';
import 'pulse_triage_inspector_page.dart';
import 'widgets/pulse_indicator_card.dart';

const _pulseInk = Color(0xFF19264D);
const _pulseMuted = Color(0xFF718096);
const _pulseLine = Color(0xFFE5E9F0);
const _pulseIconSurface = Color(0xFFF1F5F9);
const _pulseSegmentSurface = Color(0xFFECEEF7);

/// The two everyday views share one native snapshot. Switching view or
/// filtering indicators never asks Core to calculate a second data set.
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
  final PulseStoryDraft? headerStory;
  final String? headerDeliveryKey;

  @override
  State<PulseDashboardPage> createState() => _PulseDashboardPageState();
}

enum _PulseView { overview, indicators }

class _PulseDashboardPageState extends State<PulseDashboardPage>
    with WidgetsBindingObserver {
  late final PulseDashboardController _controller;
  final _search = TextEditingController();
  StreamSubscription<Object?>? _coreRevisionSubscription;
  Timer? _revisionDebounce;
  _PulseView _view = _PulseView.overview;
  bool _headerStoryOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Do not invoke [load] in the assigning cascade: a synchronous loading
    // notification would otherwise reach the listener before the late field
    // itself has received the controller instance.
    _controller = PulseDashboardController(repository: widget.repository);
    _controller.addListener(_onControllerChanged);
    unawaited(_controller.load());
    _search.addListener(_onSearchChanged);
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

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    final story = widget.headerStory;
    final snapshot = _controller.snapshot;
    if (_headerStoryOpened || story == null || snapshot == null) return;
    final situation = snapshot.situations
        .where((item) => item.situationKey == story.situationKey)
        .firstOrNull;
    if (situation == null) return;
    _headerStoryOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSituation(situation, initialStory: story);
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revisionDebounce?.cancel();
    _coreRevisionSubscription?.cancel();
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.load();
  }

  Future<void> _openDetail(PulseIndicatorSnapshot indicator) async {
    await Navigator.of(context).push<void>(
      creationSlideUpRoute<void>(
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

  Future<void> _openSituation(
    PulseSituationSnapshot situation, {
    PulseStoryDraft? initialStory,
  }) async {
    final snapshot = _controller.snapshot;
    if (snapshot == null) return;
    await Navigator.of(context).push<void>(
      creationSlideUpRoute<void>(
        builder: (_) => PulseTriageInspectorPage(
          repository: widget.repository,
          scope: _controller.scope,
          situation: situation,
          indicators: snapshot.indicators,
          initialStory: initialStory,
        ),
      ),
    );
    if (mounted) _controller.load();
  }

  Future<void> _openSituations(PulseDashboardSnapshot snapshot) async {
    await Navigator.of(context).push<void>(
      creationSlideUpRoute<void>(
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

  Future<void> _openPriorityDiagnostics(PulseDashboardSnapshot snapshot) async {
    final priority = snapshot.priority;
    if (priority == null) return;
    await Navigator.of(context).push<void>(
      creationSlideUpRoute<void>(
        builder: (_) => PulsePriorityInspectorPage(
          repository: widget.repository,
          scope: _controller.scope,
          initialPriority: priority,
          initialSituations: snapshot.situations,
          indicators: snapshot.indicators,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      creationSlideUpRoute<void>(
        builder: (_) =>
            PulseDeliverySettingsPage(repository: widget.repository),
      ),
    );
    if (mounted) _controller.load();
  }

  void _showAbout() => showDialog<void>(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('A Pulse működése'),
      content: Text(
        'A Pulse a Fluvi Core valós Ledger-, Budget-, ismétlődési és Inbox-adataiból számol. A határértékek csak megjelenítési referenciák: nem indítanak automatikus műveletet.',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final snapshot = _controller.snapshot;
    final hasCurrent = _controller.hasSnapshotForScope;
    // The shell publishes the measured BottomNavigation obstruction through
    // this body's MediaQuery when it extends beneath it. A fullscreen Pulse
    // route has no shell bar, so it keeps only its natural terminal space.
    final contentBottomInset = widget.fullscreen
        ? 28.0
        : MediaQuery.paddingOf(context).bottom + 28;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _controller.load,
          child: CustomScrollView(
            key: const PageStorageKey('pulse-dashboard-page'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, contentBottomInset),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _PulseHeader(
                      fullscreen: widget.fullscreen,
                      onBack: () => Navigator.of(context).maybePop(),
                      onAction: (action) => switch (action) {
                        _PulseMenuAction.settings => _openSettings(),
                        _PulseMenuAction.about => _showAbout(),
                        _PulseMenuAction.diagnostics =>
                          snapshot == null
                              ? null
                              : _openPriorityDiagnostics(snapshot),
                      },
                    ),
                    const SizedBox(height: 18),
                    _PeriodRow(
                      scope: _controller.scope,
                      onPrevious: () => _controller.shiftMonth(-1),
                      onNext: () => _controller.shiftMonth(1),
                    ),
                    const SizedBox(height: 14),
                    _PulseSegmentedControl(
                      view: _view,
                      onChanged: (value) => setState(() => _view = value),
                    ),
                    const SizedBox(height: 22),
                    if (!hasCurrent && _controller.loading)
                      const _LoadingPanel()
                    else if (!hasCurrent && _controller.error != null)
                      _ErrorPanel(onRetry: _controller.load)
                    else if (snapshot != null && _view == _PulseView.overview)
                      _OverviewContent(
                        snapshot: snapshot,
                        headerStory: widget.headerStory,
                        onOpenSituation: _openSituation,
                        onOpenAll: () => _openSituations(snapshot),
                      )
                    else if (snapshot != null)
                      _IndicatorList(
                        searchController: _search,
                        indicators: snapshot.indicators,
                        onTap: _openDetail,
                      )
                    else
                      const _QuietEmpty(
                        text: 'Ehhez az időszakhoz még nincs Pulse-adat.',
                      ),
                    if (hasCurrent && _controller.loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PulseMenuAction { settings, about, diagnostics }

class _PulseHeader extends StatelessWidget {
  const _PulseHeader({
    required this.fullscreen,
    required this.onBack,
    required this.onAction,
  });
  final bool fullscreen;
  final VoidCallback onBack;
  final ValueChanged<_PulseMenuAction> onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (fullscreen)
        IconButton(
          tooltip: 'Vissza',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: _pulseInk),
        ),
      const Expanded(
        child: Text(
          'Pulse',
          style: TextStyle(
            color: _pulseInk,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      PopupMenuButton<_PulseMenuAction>(
        tooltip: 'Pulse műveletek',
        onSelected: onAction,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _PulseMenuAction.settings,
            child: Text('Pulse beállításai'),
          ),
          PopupMenuItem(
            value: _PulseMenuAction.about,
            child: Text('A Pulse működése'),
          ),
          PopupMenuItem(
            value: _PulseMenuAction.diagnostics,
            child: Text('Részletes diagnosztika'),
          ),
        ],
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.more_horiz_rounded, color: _pulseInk),
        ),
      ),
    ],
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _pulseLine),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Előző hónap',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            '${_monthName(scope.month)} ${scope.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _pulseInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Következő hónap',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

class _PulseSegmentedControl extends StatelessWidget {
  const _PulseSegmentedControl({required this.view, required this.onChanged});
  final _PulseView view;
  final ValueChanged<_PulseView> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _pulseSegmentSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PulseSegment(
            label: 'Áttekintés',
            selected: view == _PulseView.overview,
            onTap: () => onChanged(_PulseView.overview),
          ),
          _PulseSegment(
            label: 'Mutatók',
            selected: view == _PulseView.indicators,
            onTap: () => onChanged(_PulseView.indicators),
          ),
        ],
      ),
    ),
  );
}

class _PulseSegment extends StatelessWidget {
  const _PulseSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _pulseInk : _pulseMuted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.snapshot,
    required this.headerStory,
    required this.onOpenSituation,
    required this.onOpenAll,
  });
  final PulseDashboardSnapshot snapshot;
  final PulseStoryDraft? headerStory;
  final ValueChanged<PulseSituationSnapshot> onOpenSituation;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final situationsByKey = <String, PulseSituationSnapshot>{
      for (final situation in snapshot.situations)
        situation.situationKey: situation,
    };
    final selected = snapshot.priority?.selected;
    // A Header tap carries an immutable Story reservation. It wins over a
    // newer Priority result so the exact text that was tapped cannot turn into
    // a different situation while the route is opening.
    final highlighted = headerStory == null
        ? (selected == null
              ? snapshot.situations
                        .where(
                          (item) => item.state == PulseSituationState.ready,
                        )
                        .firstOrNull ??
                    snapshot.situations.firstOrNull
              : situationsByKey[selected.situationKey])
        : situationsByKey[headerStory!.situationKey];
    final rankedKeys =
        snapshot.priority?.rankedCandidates
            .map((candidate) => candidate.situationKey)
            .toList(growable: false) ??
        const <String>[];
    final ordered = <PulseSituationSnapshot>[
      for (final key in rankedKeys)
        if (situationsByKey[key] != null) situationsByKey[key]!,
      ...snapshot.situations.where(
        (situation) => !rankedKeys.contains(situation.situationKey),
      ),
    ];
    final previewKeys = <String>{};
    final previews = ordered
        .where(
          (situation) => situation.situationKey != highlighted?.situationKey,
        )
        .where((situation) => previewKeys.add(situation.situationKey))
        .take(3)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Kiemelt helyzet'),
        const SizedBox(height: 8),
        if (highlighted == null)
          const _QuietEmpty(text: 'Nincs kiemelt helyzet ebben az időszakban.')
        else
          _SituationFocusRow(
            situation: highlighted,
            story: headerStory?.situationKey == highlighted.situationKey
                ? headerStory
                : null,
            onTap: () => onOpenSituation(highlighted),
          ),
        const SizedBox(height: 24),
        _SectionHeading(
          title: 'További helyzetek',
          action: snapshot.situations.isEmpty ? null : 'Összes',
          onTap: onOpenAll,
        ),
        const SizedBox(height: 8),
        if (previews.isEmpty)
          const _QuietEmpty(text: 'Nincs további megjeleníthető helyzet.')
        else
          _PulseGroup(
            children: [
              for (final situation in previews)
                _SituationCompactRow(
                  situation: situation,
                  onTap: () => onOpenSituation(situation),
                ),
            ],
          ),
      ],
    );
  }
}

class _SituationFocusRow extends StatelessWidget {
  const _SituationFocusRow({
    required this.situation,
    required this.story,
    required this.onTap,
  });
  final PulseSituationSnapshot situation;
  final PulseStoryDraft? story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey('pulse-situation-${situation.situationKey}'),
    child: _PulseGroup(
      children: [
        _PulseRow(
          icon: Icons.auto_awesome_outlined,
          title: story?.headline ?? situation.title,
          subtitle:
              story?.detail ??
              situation.formationRule ??
              _stateLabel(situation.state),
          trailing: const Icon(Icons.chevron_right_rounded, color: _pulseMuted),
          onTap: onTap,
          tall: true,
        ),
      ],
    ),
  );
}

class _SituationCompactRow extends StatelessWidget {
  const _SituationCompactRow({required this.situation, required this.onTap});
  final PulseSituationSnapshot situation;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey('pulse-situation-${situation.situationKey}'),
    child: _PulseRow(
      icon: _situationIcon(situation.state),
      title: situation.title,
      subtitle: situation.formationRule ?? _stateLabel(situation.state),
      trailing: const Icon(Icons.chevron_right_rounded, color: _pulseMuted),
      onTap: onTap,
    ),
  );
}

class _IndicatorList extends StatelessWidget {
  const _IndicatorList({
    required this.searchController,
    required this.indicators,
    required this.onTap,
  });
  final TextEditingController searchController;
  final List<PulseIndicatorSnapshot> indicators;
  final ValueChanged<PulseIndicatorSnapshot> onTap;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = indicators
        .where(
          (indicator) =>
              query.isEmpty ||
              indicator.title.toLowerCase().contains(query) ||
              indicator.summary.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          key: const ValueKey('pulse-indicator-search'),
          decoration: InputDecoration(
            hintText: 'Mutató keresése',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: _pulseIconSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (visible.isEmpty)
          const _QuietEmpty(text: 'Nincs a keresésnek megfelelő mutató.')
        else
          for (final group in PulseGroup.values) ...[
            if (visible.any((indicator) => indicator.group == group)) ...[
              _SectionHeading(title: _groupLabel(group)),
              const SizedBox(height: 8),
              _PulseGroup(
                children: [
                  for (final indicator in visible.where(
                    (item) => item.group == group,
                  ))
                    _IndicatorRow(
                      indicator: indicator,
                      onTap: () => onTap(indicator),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
      ],
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.indicator, required this.onTap});
  final PulseIndicatorSnapshot indicator;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey('pulse-indicator-${indicator.id}'),
    child: _PulseRow(
      icon: _indicatorIcon(indicator.chartKind),
      title: indicator.title,
      subtitle: indicator.summary,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            pulseFormatValue(indicator),
            style: const TextStyle(
              color: _pulseInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.chevron_right_rounded, size: 18, color: _pulseMuted),
        ],
      ),
      onTap: onTap,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _pulseInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class _PulseGroup extends StatelessWidget {
  const _PulseGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10334155),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 1,
              indent: 65,
              endIndent: 12,
              color: _pulseLine,
            ),
          children[index],
        ],
      ],
    ),
  );
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.tall = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool tall;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: tall ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _pulseIconSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: _pulseMuted),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _pulseInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: tall ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _pulseMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(top: 2), child: trailing),
          ],
        ),
      ),
    ),
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 180,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _PulseGroup(
    children: [
      _PulseRow(
        icon: Icons.error_outline_rounded,
        title: 'A Pulse adatai nem tölthetők be',
        subtitle: 'Ellenőrizd a helyi adatokat, majd próbáld újra.',
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Újrapróbálás'),
        ),
        onTap: onRetry,
        tall: true,
      ),
    ],
  );
}

class _QuietEmpty extends StatelessWidget {
  const _QuietEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(color: _pulseMuted, fontSize: 13),
      ),
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

String _groupLabel(PulseGroup group) => switch (group) {
  PulseGroup.spending => 'Költések',
  PulseGroup.cashflow => 'Pénzáramlás',
  PulseGroup.systems => 'Rendszer és tervek',
};

String _stateLabel(PulseSituationState state) => switch (state) {
  PulseSituationState.forming => 'Alakuló helyzet',
  PulseSituationState.ready => 'Aktív helyzet',
  PulseSituationState.improving => 'Javuló helyzet',
  PulseSituationState.resolved => 'Lezárt helyzet',
  PulseSituationState.suspended => 'Szüneteltetett helyzet',
};

IconData _situationIcon(PulseSituationState state) => switch (state) {
  PulseSituationState.forming => Icons.hourglass_top_rounded,
  PulseSituationState.ready => Icons.auto_awesome_outlined,
  PulseSituationState.improving => Icons.trending_down_rounded,
  PulseSituationState.resolved => Icons.check_circle_outline_rounded,
  PulseSituationState.suspended => Icons.pause_circle_outline_rounded,
};

IconData _indicatorIcon(PulseChartKind kind) => switch (kind) {
  PulseChartKind.arcGauge => Icons.speed_outlined,
  PulseChartKind.thresholdBar => Icons.view_stream_outlined,
  PulseChartKind.trend => Icons.show_chart_rounded,
  PulseChartKind.forecast => Icons.timeline_outlined,
  PulseChartKind.ratio => Icons.pie_chart_outline_rounded,
  PulseChartKind.timeline => Icons.more_time_outlined,
};
