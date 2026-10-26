import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../application/pulse_dashboard_controller.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_signal_detail_page.dart';
import 'widgets/pulse_charts.dart';
import 'widgets/pulse_indicator_card.dart';

class PulseDashboardPage extends StatefulWidget {
  const PulseDashboardPage({super.key, required this.repository});
  final PulseRepository repository;

  @override
  State<PulseDashboardPage> createState() => _PulseDashboardPageState();
}

class _PulseDashboardPageState extends State<PulseDashboardPage>
    with WidgetsBindingObserver {
  late final PulseDashboardController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PulseDashboardController(repository: widget.repository);
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
                      _PulseHeader(onInfo: _showAbout),
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
}

class _PulseHeader extends StatelessWidget {
  const _PulseHeader({required this.onInfo});
  final VoidCallback onInfo;
  @override
  Widget build(BuildContext context) => Row(
    children: [
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
        onPressed: onInfo,
        icon: const Icon(Icons.tune_outlined),
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
