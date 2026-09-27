import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_balance_category_movers_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_category_movers_presentation.dart';
import 'balance_category_movers_visual_tokens.dart';
import 'balance_category_visual_badge.dart';

/// Reference-locked two-page category-movers body. Financial values and
/// period semantics arrive only in [presentation]; local state changes neither
/// summary scope, query, carousel selection nor prepared Balance data.
final class BalanceCategoryMoversCard extends StatefulWidget {
  const BalanceCategoryMoversCard({super.key, required this.presentation});

  final DashboardBalanceCategoryMoversPresentation? presentation;

  @override
  State<BalanceCategoryMoversCard> createState() =>
      _BalanceCategoryMoversCardState();
}

enum _MoversDirection { decrease, increase }

final class _BalanceCategoryMoversCardState
    extends State<BalanceCategoryMoversCard> {
  String? _selectedCategoryId;
  _MoversDirection? _selectedDirection;
  bool _directionWasChosen = false;

  @override
  void didUpdateWidget(covariant BalanceCategoryMoversCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation?.presentationId ==
        widget.presentation?.presentationId) {
      return;
    }
    final next = widget.presentation;
    final selected = _selectedCategoryId;
    if (selected != null &&
        !_detailMovers(next).any((mover) => mover.id == selected)) {
      _selectedCategoryId = null;
    }
    if (!_directionWasChosen && next != null) {
      _selectedDirection = _initialDirection(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    if (presentation == null || presentation.isNoChange) {
      return const Center(
        key: ValueKey<String>('balance-linked-detail-category-movers-empty'),
        child: Text('Nincs kategóriaváltozás'),
      );
    }
    final selectedId = _selectedCategoryId;
    final selected = selectedId == null
        ? null
        : _detailMovers(
            presentation,
          ).where((mover) => mover.id == selectedId).firstOrNull;
    final page = selected == null
        ? _CategoryMoversOverview(
            presentation: presentation,
            direction: _selectedDirection ?? _initialDirection(presentation),
            onDirectionSelected: (_MoversDirection direction) => setState(() {
              _selectedDirection = direction;
              _directionWasChosen = true;
            }),
            onSelected: (mover) =>
                setState(() => _selectedCategoryId = mover.id),
          )
        : _CategoryMoverTrendDetail(
            presentation: presentation,
            mover: selected,
            onBack: () => setState(() => _selectedCategoryId = null),
          );
    // The outer DashboardPlaceholderCard owns the white base, shadow and
    // 22px border. Insets keep this decorative layer inside its crisp edge.
    return Padding(
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          BalanceCategoryMoversVisualTokens.outerRadius - 1,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const RepaintBoundary(
              child: CustomPaint(painter: _MoversTopTintPainter()),
            ),
            page,
          ],
        ),
      ),
    );
  }
}

_MoversDirection _initialDirection(
  DashboardBalanceCategoryMoversPresentation presentation,
) {
  final miniMover = presentation.movers.firstOrNull;
  if (miniMover != null) {
    return miniMover.deltaMinor < 0
        ? _MoversDirection.decrease
        : _MoversDirection.increase;
  }
  return presentation.topDecreases.isNotEmpty
      ? _MoversDirection.decrease
      : _MoversDirection.increase;
}

List<DashboardBalanceCategoryMover> _detailMovers(
  DashboardBalanceCategoryMoversPresentation? presentation,
) {
  if (presentation == null) return const <DashboardBalanceCategoryMover>[];
  final seen = <String>{};
  return <DashboardBalanceCategoryMover>[
    for (final mover in <DashboardBalanceCategoryMover>[
      ...presentation.topDecreases,
      ...presentation.topIncreases,
      ...presentation.movers,
    ])
      if (seen.add(mover.id)) mover,
  ];
}

final class _CategoryMoversOverview extends StatelessWidget {
  const _CategoryMoversOverview({
    required this.presentation,
    required this.direction,
    required this.onDirectionSelected,
    required this.onSelected,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;

  @override
  Widget build(BuildContext context) {
    final movers =
        (direction == _MoversDirection.decrease
                ? presentation.topDecreases
                : presentation.topIncreases)
            .take(5)
            .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => KeyedSubtree(
        key: const ValueKey<String>('balance-linked-detail-category-movers'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BalanceCategoryMoversVisualTokens.horizontalInset,
            12,
            BalanceCategoryMoversVisualTokens.horizontalInset,
            10,
          ),
          // The preserved 210px lower-card envelope cannot physically show
          // five 46px rows plus the reference header and footer. At that
          // inherited compact envelope the same reference anatomy scrolls as
          // one local surface; normal and stretched envelopes retain the
          // fully composed, non-scrolling reference layout.
          child: constraints.maxHeight < 445
              ? _MoversOverviewCompact(
                  presentation: presentation,
                  movers: movers,
                  direction: direction,
                  onDirectionSelected: onDirectionSelected,
                  onSelected: onSelected,
                )
              : _MoversOverviewExpanded(
                  presentation: presentation,
                  movers: movers,
                  direction: direction,
                  onDirectionSelected: onDirectionSelected,
                  onSelected: onSelected,
                ),
        ),
      ),
    );
  }
}

final class _MoversOverviewCompact extends StatelessWidget {
  const _MoversOverviewCompact({
    required this.presentation,
    required this.movers,
    required this.direction,
    required this.onDirectionSelected,
    required this.onSelected,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final List<DashboardBalanceCategoryMover> movers;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey<String>('balance-category-movers-list'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MoversOverviewTop(
          presentation: presentation,
          direction: direction,
          onDirectionSelected: onDirectionSelected,
        ),
        const SizedBox(height: 6),
        if (movers.isEmpty)
          const SizedBox(
            height: 64,
            child: Center(
              child: Text(
                'Nincs ebbe az irányba változó kategória',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BalanceCategoryMoversVisualTokens.secondaryText,
                  fontSize: 12.5,
                ),
              ),
            ),
          )
        else
          for (var index = 0; index < movers.length; index += 1)
            _CategoryMoverRow(
              mover: movers[index],
              rank: index + 1,
              showDivider: index != movers.length - 1,
              onTap: () => onSelected(movers[index]),
            ),
        const SizedBox(height: 6),
        const _MoversOverviewFooter(),
      ],
    ),
  );
}

final class _MoversOverviewExpanded extends StatelessWidget {
  const _MoversOverviewExpanded({
    required this.presentation,
    required this.movers,
    required this.direction,
    required this.onDirectionSelected,
    required this.onSelected,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final List<DashboardBalanceCategoryMover> movers;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _MoversOverviewTop(
        presentation: presentation,
        direction: direction,
        onDirectionSelected: onDirectionSelected,
      ),
      const SizedBox(height: 10),
      Expanded(
        child: Column(
          children: <Widget>[
            Expanded(
              child: movers.isEmpty
                  ? const Center(
                      child: Text(
                        'Nincs ebbe az irányba változó kategória',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              BalanceCategoryMoversVisualTokens.secondaryText,
                          fontSize: 12.5,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Stretch distributes the remaining list height
                        // through the rows first. The 28px cap keeps the
                        // reference rhythm generous but never sparse.
                        const safeGapCap = 28.0;
                        final remainingHeight = math.max(
                          0.0,
                          constraints.maxHeight -
                              movers.length *
                                  BalanceCategoryMoversVisualTokens.rowHeight,
                        );
                        final extraPerGap = movers.length < 2
                            ? 0.0
                            : math.min(
                                safeGapCap,
                                remainingHeight / (movers.length - 1),
                              );
                        final edgeInset =
                            math.max(
                              0.0,
                              remainingHeight -
                                  extraPerGap * math.max(0, movers.length - 1),
                            ) /
                            2;
                        return ListView.builder(
                          key: const ValueKey<String>(
                            'balance-category-movers-list',
                          ),
                          padding: EdgeInsets.symmetric(vertical: edgeInset),
                          itemCount: movers.length,
                          itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(
                              bottom: index == movers.length - 1
                                  ? 0
                                  : extraPerGap,
                            ),
                            child: _CategoryMoverRow(
                              mover: movers[index],
                              rank: index + 1,
                              showDivider: index != movers.length - 1,
                              onTap: () => onSelected(movers[index]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 6),
            const _MoversOverviewFooter(),
          ],
        ),
      ),
    ],
  );
}

final class _MoversOverviewTop extends StatelessWidget {
  const _MoversOverviewTop({
    required this.presentation,
    required this.direction,
    required this.onDirectionSelected,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _MoversOverviewHeader(presentation: presentation),
      const SizedBox(height: 3),
      const Text(
        'A kiválasztott időszak költéseinek változása\n'
        'a megelőző azonos időszakhoz képest.',
        maxLines: 2,
        style: TextStyle(
          color: BalanceCategoryMoversVisualTokens.secondaryText,
          fontSize: 12.5,
          height: 1.28,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 10),
      _DirectionSelector(selected: direction, onSelected: onDirectionSelected),
    ],
  );
}

final class _MoversOverviewFooter extends StatelessWidget {
  const _MoversOverviewFooter();

  @override
  Widget build(BuildContext context) => const _MoversInfoFooter(
    key: ValueKey<String>('balance-category-movers-footer'),
    copy:
        'A százalékos változás a kiválasztott időszak és a megelőző azonos időszak költéseinek különbségét mutatja.',
    icon: Icons.info_rounded,
    minHeight: 42,
    dense: true,
    maxLines: 2,
  );
}

final class _MoversOverviewHeader extends StatelessWidget {
  const _MoversOverviewHeader({required this.presentation});

  final DashboardBalanceCategoryMoversPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const Expanded(
        child: Text(
          'Kategóriaváltozás',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: BalanceCategoryMoversVisualTokens.primaryText,
            fontSize: BalanceCategoryMoversVisualTokens.titleSize,
            height: 22 / BalanceCategoryMoversVisualTokens.titleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _ScopeLabelAndCalendar(presentation: presentation),
    ],
  );
}

final class _ScopeLabelAndCalendar extends StatelessWidget {
  const _ScopeLabelAndCalendar({required this.presentation});

  final DashboardBalanceCategoryMoversPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        balanceCategoryMoverScopeLabel(presentation),
        maxLines: 1,
        style: const TextStyle(
          color: BalanceCategoryMoversVisualTokens.secondaryText,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 7),
      const _CalendarTile(),
    ],
  );
}

final class _CalendarTile extends StatelessWidget {
  const _CalendarTile();

  @override
  Widget build(BuildContext context) => Semantics(
    // The selected Summary scope owns period navigation. This is its compact,
    // non-interactive visual indicator, so it must not falsely advertise an
    // unavailable button to assistive technology.
    label: 'Kiválasztott időszak naptár jelzése',
    child: SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BalanceCategoryMoversVisualTokens.selectedPeriodSurface,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Center(
          child: Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: BalanceCategoryMoversVisualTokens.purple,
          ),
        ),
      ),
    ),
  );
}

final class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({required this.selected, required this.onSelected});

  final _MoversDirection selected;
  final ValueChanged<_MoversDirection> onSelected;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 266),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _DirectionSegment(
              key: const ValueKey<String>(
                'balance-category-movers-direction-decrease',
              ),
              direction: _MoversDirection.decrease,
              selected: selected == _MoversDirection.decrease,
              onSelected: onSelected,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DirectionSegment(
              key: const ValueKey<String>(
                'balance-category-movers-direction-increase',
              ),
              direction: _MoversDirection.increase,
              selected: selected == _MoversDirection.increase,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _DirectionSegment extends StatelessWidget {
  const _DirectionSegment({
    super.key,
    required this.direction,
    required this.selected,
    required this.onSelected,
  });

  final _MoversDirection direction;
  final bool selected;
  final ValueChanged<_MoversDirection> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDecrease = direction == _MoversDirection.decrease;
    final label = isDecrease ? 'Csökkenés' : 'Növekedés';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(direction),
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? null
                  : BalanceCategoryMoversVisualTokens.unselectedSegmentSurface,
              gradient: selected
                  ? BalanceCategoryMoversVisualTokens.selectedSegmentGradient
                  : null,
              borderRadius: BorderRadius.circular(19),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isDecrease
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : BalanceCategoryMoversVisualTokens.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : BalanceCategoryMoversVisualTokens.secondaryText,
                      fontSize: 12.5,
                      height: 1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CategoryMoverRow extends StatelessWidget {
  const _CategoryMoverRow({
    required this.mover,
    required this.rank,
    required this.showDivider,
    required this.onTap,
  });

  final DashboardBalanceCategoryMover mover;
  final int rank;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = mover.deltaMinor > 0 || mover.isNew;
    final semanticValue = mover.isNew
        ? 'Új, ${balanceCategoryMoverSignedAmountLabel(mover.deltaMinor)}'
        : '${balanceCategoryMoverPercentageLabel(mover)}, ${balanceCategoryMoverSignedAmountLabel(mover.deltaMinor)}';
    return Semantics(
      button: true,
      label: '${mover.label}, $semanticValue',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('balance-category-mover-${mover.id}'),
          onTap: onTap,
          child: Ink(
            decoration: rank == 1
                ? BoxDecoration(
                    color: BalanceCategoryMoversVisualTokens.lavenderSurface,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: SizedBox(
              height: BalanceCategoryMoversVisualTokens.rowHeight,
              child: Stack(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        child: Center(
                          child: Text(
                            '$rank.',
                            style: const TextStyle(
                              color: BalanceCategoryMoversVisualTokens.purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      BalanceCategoryVisualBadge(
                        semanticLabel: mover.label,
                        categoryColorId: mover.categoryColorId,
                        categoryIconId: mover.categoryIconId,
                        size: 32,
                        iconSize: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          mover.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                BalanceCategoryMoversVisualTokens.primaryText,
                            fontSize: 14.5,
                            height: 18 / 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              balanceCategoryMoverPercentageLabel(mover),
                              maxLines: 1,
                              style: TextStyle(
                                color: positive
                                    ? BalanceCategoryMoversVisualTokens.positive
                                    : BalanceCategoryMoversVisualTokens
                                          .negative,
                                fontSize: 15.5,
                                height: 18 / 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              balanceCategoryMoverSignedAmountLabel(
                                mover.deltaMinor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BalanceCategoryMoversVisualTokens
                                    .secondaryText,
                                fontSize: 11.5,
                                height: 15 / 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: BalanceCategoryMoversVisualTokens.purple,
                      ),
                    ],
                  ),
                  if (showDivider)
                    const Positioned(
                      left: 28,
                      right: 0,
                      bottom: 0,
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: BalanceCategoryMoversVisualTokens.hairline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CategoryMoverTrendDetail extends StatelessWidget {
  const _CategoryMoverTrendDetail({
    required this.presentation,
    required this.mover,
    required this.onBack,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final accent = CategoryColorCatalog.resolve(
      mover.categoryColorId,
    ).middleColor;
    final labels = balanceCategoryMoverLegendLabels(presentation);
    final series = balanceCategoryMoverCumulativeSeries(mover.trend);
    final positive = mover.deltaMinor > 0 || mover.isNew;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 445;
        // Header/copy/KPIs/chart label/footer are intentionally fixed to the
        // reference metrics. The chart alone consumes healthy surplus, capped
        // at its ~175px visual maximum; anything beyond that becomes balanced
        // breathing room instead of a stretched graph.
        const fixedVerticalSpace = 300.0;
        final availableContentHeight = math.max(
          0.0,
          constraints.maxHeight - 20,
        );
        final chartSpace = math.max(
          125.0,
          availableContentHeight - fixedVerticalSpace,
        );
        final chartHeight = math.min(175.0, chartSpace);
        final chartBreathing = compact
            ? 0.0
            : math.max(0.0, chartSpace - chartHeight);
        return KeyedSubtree(
          key: const ValueKey<String>('balance-category-movers-detail'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BalanceCategoryMoversVisualTokens.horizontalInset,
              10,
              BalanceCategoryMoversVisualTokens.horizontalInset,
              10,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                compact
                    ? SingleChildScrollView(
                        key: const ValueKey<String>(
                          'balance-category-movers-detail-scroll',
                        ),
                        child: _MoversDetailContent(
                          presentation: presentation,
                          mover: mover,
                          positive: positive,
                          labels: labels,
                          series: series,
                          accent: accent,
                          chartHeight: chartHeight,
                        ),
                      )
                    : _MoversDetailContent(
                        presentation: presentation,
                        mover: mover,
                        positive: positive,
                        labels: labels,
                        series: series,
                        accent: accent,
                        chartHeight: chartHeight,
                        chartBreathing: chartBreathing,
                      ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: _MoversBackTarget(onBack: onBack),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _MoversDetailContent extends StatelessWidget {
  const _MoversDetailContent({
    required this.presentation,
    required this.mover,
    required this.positive,
    required this.labels,
    required this.series,
    required this.accent,
    required this.chartHeight,
    this.chartBreathing = 0,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final bool positive;
  final BalanceCategoryMoverLegendLabels labels;
  final BalanceCategoryMoverCumulativeSeries series;
  final Color accent;
  final double chartHeight;
  final double chartBreathing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _MoversDetailHeader(presentation: presentation, mover: mover),
      const SizedBox(height: 3),
      const Text(
        'A kiválasztott időszak költéseinek összehasonlítása\n'
        'a megelőző azonos időszakkal.',
        maxLines: 2,
        style: TextStyle(
          color: BalanceCategoryMoversVisualTokens.secondaryText,
          fontSize: 12.5,
          height: 1.28,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 9),
      _MoverKpiRow(
        presentation: presentation,
        mover: mover,
        positive: positive,
        height: 86,
      ),
      const SizedBox(height: 10),
      _ChartHeader(labels: labels, accent: accent),
      const SizedBox(height: 6),
      SizedBox(
        height: chartHeight,
        child: _MoverCumulativeChart(
          presentation: presentation,
          mover: mover,
          series: series,
          accent: accent,
        ),
      ),
      if (chartBreathing > 0) SizedBox(height: chartBreathing),
      const SizedBox(height: 8),
      const _MoversDetailFooter(),
    ],
  );
}

final class _MoversDetailFooter extends StatelessWidget {
  const _MoversDetailFooter();

  @override
  Widget build(BuildContext context) => const _MoversInfoFooter(
    key: ValueKey<String>('balance-category-movers-detail-footer'),
    copy:
        'A grafikon a két időszak kumulatív költését mutatja,\n'
        'így jól látható, hol alakult ki a különbség.\n'
        'A jobb oldali értékek a teljes időszak végösszegei.',
    icon: Icons.lightbulb_outline_rounded,
    iconColor: BalanceCategoryMoversVisualTokens.purple,
    minHeight: 50,
    dense: true,
  );
}

/// Keeps the source-locked 20px visual arrow in its 36px header while giving
/// it the required 44px semantic/tap target without moving adjacent content.
final class _MoversBackTarget extends StatelessWidget {
  const _MoversBackTarget({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Vissza a kategóriaváltozásokhoz',
    child: Material(
      color: Colors.transparent,
      child: InkResponse(
        key: const ValueKey<String>('balance-category-movers-back'),
        onTap: onBack,
        radius: 24,
        child: const SizedBox(width: 44, height: 44),
      ),
    ),
  );
}

final class _MoversDetailHeader extends StatelessWidget {
  const _MoversDetailHeader({required this.presentation, required this.mover});

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const ExcludeSemantics(
        child: IgnorePointer(
          child: SizedBox(
            width: 28,
            height: 36,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: BalanceCategoryMoversVisualTokens.purple,
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      BalanceCategoryVisualBadge(
        semanticLabel: mover.label,
        categoryColorId: mover.categoryColorId,
        categoryIconId: mover.categoryIconId,
        size: 34,
        iconSize: 19,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          mover.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: BalanceCategoryMoversVisualTokens.primaryText,
            fontSize: 18,
            height: 22 / 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 4),
      _ScopeLabelAndCalendar(presentation: presentation),
    ],
  );
}

final class _MoverKpiRow extends StatelessWidget {
  const _MoverKpiRow({
    required this.presentation,
    required this.mover,
    required this.positive,
    required this.height,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final bool positive;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      children: <Widget>[
        Expanded(
          child: _MoverKpiTile(
            key: const ValueKey<String>('balance-category-movers-kpi-current'),
            background: BalanceCategoryMoversVisualTokens.selectedPeriodSurface,
            icon: Icons.stacked_line_chart_rounded,
            iconColor: BalanceCategoryMoversVisualTokens.purple,
            value: DashboardPreparedFormatter.amountMinor(mover.currentMinor),
            valueColor: BalanceCategoryMoversVisualTokens.primaryText,
            label: 'Kiválasztott időszak',
            detail: balanceCategoryMoverWindowLabel(presentation.currentWindow),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MoverKpiTile(
            key: const ValueKey<String>(
              'balance-category-movers-kpi-percentage',
            ),
            background: positive
                ? BalanceCategoryMoversVisualTokens.positiveSurface
                : BalanceCategoryMoversVisualTokens.negativeSurface,
            icon: positive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            iconColor: positive
                ? BalanceCategoryMoversVisualTokens.positive
                : BalanceCategoryMoversVisualTokens.negative,
            value: balanceCategoryMoverPercentageLabel(mover),
            valueColor: positive
                ? BalanceCategoryMoversVisualTokens.positive
                : BalanceCategoryMoversVisualTokens.negative,
            label: 'Változás az előző időszakhoz képest',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MoverKpiTile(
            key: const ValueKey<String>('balance-category-movers-kpi-delta'),
            background: positive
                ? BalanceCategoryMoversVisualTokens.positiveSurface
                : BalanceCategoryMoversVisualTokens.negativeSurface,
            icon: Icons.bar_chart_rounded,
            iconColor: positive
                ? BalanceCategoryMoversVisualTokens.positive
                : BalanceCategoryMoversVisualTokens.negative,
            value: balanceCategoryMoverSignedAmountLabel(mover.deltaMinor),
            valueColor: mover.deltaMinor == 0
                ? BalanceCategoryMoversVisualTokens.secondaryText
                : positive
                ? BalanceCategoryMoversVisualTokens.positive
                : BalanceCategoryMoversVisualTokens.negative,
            label: mover.deltaMinor < 0
                ? 'Különbség (ennyivel kevesebb)'
                : mover.deltaMinor > 0
                ? 'Különbség (ennyivel több)'
                : 'Különbség (nincs eltérés)',
          ),
        ),
      ],
    ),
  );
}

final class _MoverKpiTile extends StatelessWidget {
  const _MoverKpiTile({
    super.key,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    this.detail,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(9, 8, 8, 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 17.5,
            height: 21 / 17.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Expanded(
          child: Text(
            detail == null || detail!.isEmpty ? label : '$label\n$detail',
            maxLines: detail == null || detail!.isEmpty ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BalanceCategoryMoversVisualTokens.secondaryText,
              fontSize: 10.5,
              height: 13 / 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.labels, required this.accent});

  final BalanceCategoryMoverLegendLabels labels;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const Expanded(
        child: Text(
          'Költés alakulása',
          style: TextStyle(
            color: BalanceCategoryMoversVisualTokens.primaryText,
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _LegendItem(color: accent, label: labels.current),
      const SizedBox(width: 8),
      _LegendItem(
        color: BalanceCategoryMoversVisualTokens.referenceSeries,
        label: labels.reference,
      ),
    ],
  );
}

final class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BalanceCategoryMoversVisualTokens.secondaryText,
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _MoverCumulativeChart extends StatelessWidget {
  const _MoverCumulativeChart({
    required this.presentation,
    required this.mover,
    required this.series,
    required this.accent,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final BalanceCategoryMoverCumulativeSeries series;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final xLabels = balanceCategoryMoverChartXAxisLabels(
      presentation: presentation,
      bucketCount: series.currentMinor.length,
    );
    final semantics =
        '${mover.label}: ${DashboardPreparedFormatter.amountMinor(mover.currentMinor)} a kiválasztott időszakban, '
        '${DashboardPreparedFormatter.amountMinor(mover.referenceMinor)} a megelőzőben, '
        '${balanceCategoryMoverPercentageLabel(mover)}, ${balanceCategoryMoverSignedAmountLabel(mover.deltaMinor)}.';
    return Semantics(
      label: semantics,
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey<String>(
            'balance-category-movers-cumulative-chart',
          ),
          painter: _CategoryMoverCumulativePainter(
            series: series,
            currentColor: accent,
            xLabels: xLabels,
            currentEndpoint: balanceCategoryMoverCompactAmountLabel(
              mover.currentMinor,
            ),
            referenceEndpoint: balanceCategoryMoverCompactAmountLabel(
              mover.referenceMinor,
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

final class _CategoryMoverCumulativePainter extends CustomPainter {
  const _CategoryMoverCumulativePainter({
    required this.series,
    required this.currentColor,
    required this.xLabels,
    required this.currentEndpoint,
    required this.referenceEndpoint,
  });

  final BalanceCategoryMoverCumulativeSeries series;
  final Color currentColor;
  final List<String> xLabels;
  final String currentEndpoint;
  final String referenceEndpoint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const left = 38.0;
    const right = 42.0;
    const top = 14.0;
    const bottom = 22.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(1, size.width - left - right),
      math.max(1, size.height - top - bottom),
    );
    final maximum = math.max(
      1,
      <int>[...series.currentMinor, ...series.referenceMinor].fold(0, math.max),
    );
    final gridPaint = Paint()
      ..color = BalanceCategoryMoversVisualTokens.hairline
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(
      color: BalanceCategoryMoversVisualTokens.secondaryText,
      fontSize: 10,
      height: 1,
    );
    for (var index = 0; index <= 4; index += 1) {
      final fraction = index / 4;
      final y = plot.bottom - plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _paintText(
        canvas,
        balanceCategoryMoverCompactAmountLabel(
          (maximum * fraction).round(),
        ).replaceAll(' Ft', ''),
        Offset(0, y - 5),
        labelStyle,
        maxWidth: left - 5,
      );
    }
    final count = math.max(1, series.currentMinor.length);
    for (final index in <int>{0, (count - 1) ~/ 2, count - 1}) {
      final x = _xFor(index, count, plot);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        gridPaint
          ..color = BalanceCategoryMoversVisualTokens.hairline.withValues(
            alpha: .55,
          ),
      );
      if (index < xLabels.length) {
        _paintText(
          canvas,
          xLabels[index],
          Offset(x - 8, plot.bottom + 8),
          labelStyle,
          maxWidth: 28,
        );
      }
    }
    if (series.currentMinor.isEmpty) return;
    final isSingleBucket = count == 1;
    final current = _steppedPath(series.currentMinor, maximum, plot);
    final reference = _steppedPath(series.referenceMinor, maximum, plot);
    final referencePaint = Paint()
      ..color = BalanceCategoryMoversVisualTokens.referenceSeries
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final currentPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (isSingleBucket) {
      // A Day owns one canonical bucket. Keep the same chart frame and make
      // both totals legible as stable horizontal comparison marks instead of
      // a degenerate one-point path.
      final currentY = _yFor(series.currentMinor.last, maximum, plot);
      final referenceY = _yFor(series.referenceMinor.last, maximum, plot);
      canvas.drawRect(
        Rect.fromLTRB(plot.left, currentY, plot.right, plot.bottom),
        Paint()..color = currentColor.withValues(alpha: .09),
      );
      canvas
        ..drawLine(
          Offset(plot.left, referenceY),
          Offset(plot.right, referenceY),
          referencePaint,
        )
        ..drawLine(
          Offset(plot.left, currentY),
          Offset(plot.right, currentY),
          currentPaint,
        );
    } else {
      final fill = Path.from(current)
        ..lineTo(plot.right, plot.bottom)
        ..lineTo(plot.left, plot.bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()..color = currentColor.withValues(alpha: .09),
      );
      canvas.drawPath(reference, referencePaint);
      canvas.drawPath(current, currentPaint);
    }
    final endIndex = series.currentMinor.length - 1;
    final endX = isSingleBucket ? plot.right : _xFor(endIndex, count, plot);
    final currentY = _yFor(series.currentMinor.last, maximum, plot);
    final referenceY = _yFor(series.referenceMinor.last, maximum, plot);
    canvas.drawCircle(
      Offset(endX, referenceY),
      2,
      Paint()..color = BalanceCategoryMoversVisualTokens.referenceSeries,
    );
    canvas.drawCircle(
      Offset(endX, currentY),
      2.5,
      Paint()..color = currentColor,
    );
    _paintText(
      canvas,
      referenceEndpoint,
      Offset(plot.right + 4, referenceY - 11),
      labelStyle.copyWith(fontWeight: FontWeight.w600),
      maxWidth: right - 3,
    );
    _paintText(
      canvas,
      currentEndpoint,
      Offset(plot.right + 4, currentY + 2),
      labelStyle.copyWith(color: currentColor, fontWeight: FontWeight.w700),
      maxWidth: right - 3,
    );
  }

  Path _steppedPath(List<int> values, int maximum, Rect plot) {
    final path = Path();
    for (var index = 0; index < values.length; index += 1) {
      final x = _xFor(index, values.length, plot);
      final y = _yFor(values[index], maximum, plot);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, _yFor(values[index - 1], maximum, plot));
        path.lineTo(x, y);
      }
    }
    return path;
  }

  static double _xFor(int index, int count, Rect plot) => count <= 1
      ? plot.center.dx
      : plot.left + plot.width * index / (count - 1);

  static double _yFor(int value, int maximum, Rect plot) =>
      plot.bottom - plot.height * value / maximum;

  static void _paintText(
    Canvas canvas,
    String value,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(1, maxWidth));
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CategoryMoverCumulativePainter oldDelegate) =>
      oldDelegate.currentColor != currentColor ||
      oldDelegate.currentEndpoint != currentEndpoint ||
      oldDelegate.referenceEndpoint != referenceEndpoint ||
      !listEquals(oldDelegate.xLabels, xLabels) ||
      !listEquals(oldDelegate.series.currentMinor, series.currentMinor) ||
      !listEquals(oldDelegate.series.referenceMinor, series.referenceMinor);
}

final class _MoversInfoFooter extends StatelessWidget {
  const _MoversInfoFooter({
    super.key,
    required this.copy,
    required this.icon,
    required this.minHeight,
    this.iconColor = BalanceCategoryMoversVisualTokens.secondaryText,
    this.dense = false,
    this.maxLines = 3,
  });

  final String copy;
  final IconData icon;
  final Color iconColor;
  final double minHeight;
  final bool dense;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 4 : 7),
    decoration: BoxDecoration(
      color: BalanceCategoryMoversVisualTokens.lavenderSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            copy,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BalanceCategoryMoversVisualTokens.secondaryText,
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _MoversTopTintPainter extends CustomPainter {
  const _MoversTopTintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, math.min(72, size.height))
      ..cubicTo(
        size.width * .76,
        math.min(58, size.height),
        size.width * .56,
        math.min(92, size.height),
        size.width * .30,
        math.min(66, size.height),
      )
      ..cubicTo(
        size.width * .16,
        math.min(51, size.height),
        size.width * .08,
        math.min(70, size.height),
        0,
        math.min(56, size.height),
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = BalanceCategoryMoversVisualTokens.upperDecorationGradient
            .createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _MoversTopTintPainter oldDelegate) => false;
}
