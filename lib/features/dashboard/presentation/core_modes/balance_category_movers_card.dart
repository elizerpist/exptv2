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

/// Local, transient presentation state for the two-page Movers card.  It is
/// deliberately independent from Summary scope, prepared data and carousel
/// selection; opening an explanation or the chart insight never changes any
/// Dashboard state outside this clipped card.
enum _CategoryMoverOverlay { none, explanation, metrics }

final class _BalanceCategoryMoversCardState
    extends State<BalanceCategoryMoversCard> {
  String? _selectedCategoryId;
  _MoversDirection? _selectedDirection;
  bool _directionWasChosen = false;
  _CategoryMoverOverlay _overlay = _CategoryMoverOverlay.none;

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
      _overlay = _CategoryMoverOverlay.none;
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
            onSelected: (mover) => setState(() {
              _selectedCategoryId = mover.id;
              _overlay = _CategoryMoverOverlay.none;
            }),
            onExplanationToggled: _toggleExplanation,
          )
        : _CategoryMoverTrendDetail(
            presentation: presentation,
            mover: selected,
            onBack: () => setState(() {
              _selectedCategoryId = null;
              _overlay = _CategoryMoverOverlay.none;
            }),
            onExplanationToggled: _toggleExplanation,
            onMetricsToggled: _toggleMetrics,
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
            if (_overlay != _CategoryMoverOverlay.none)
              _CategoryMoverOverlaySurface(
                overlay: _overlay,
                mover: selected,
                onClose: _closeOverlay,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleExplanation() => setState(() {
    _overlay = _overlay == _CategoryMoverOverlay.explanation
        ? _CategoryMoverOverlay.none
        : _CategoryMoverOverlay.explanation;
  });

  void _toggleMetrics() => setState(() {
    _overlay = _overlay == _CategoryMoverOverlay.metrics
        ? _CategoryMoverOverlay.none
        : _CategoryMoverOverlay.metrics;
  });

  void _closeOverlay() => setState(() => _overlay = _CategoryMoverOverlay.none);
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
    required this.onExplanationToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;
  final VoidCallback onExplanationToggled;

  @override
  Widget build(BuildContext context) {
    final movers =
        (direction == _MoversDirection.decrease
                ? presentation.topDecreases
                : presentation.topIncreases)
            .take(5)
            .toList(growable: false);
    return KeyedSubtree(
      key: const ValueKey<String>('balance-linked-detail-category-movers'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BalanceCategoryMoversVisualTokens.horizontalInset,
          4,
          BalanceCategoryMoversVisualTokens.horizontalInset,
          3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MoversOverviewTop(
              presentation: presentation,
              direction: direction,
              onDirectionSelected: onDirectionSelected,
              onExplanationToggled: onExplanationToggled,
            ),
            const SizedBox(height: 5),
            Expanded(
              child: movers.isEmpty
                  ? const Center(
                      child: Text(
                        'Nincs ebbe az irányba változó kategória',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              BalanceCategoryMoversVisualTokens.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : _CompactMoverRows(movers: movers, onSelected: onSelected),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list is finite and fully prepared (at most five entries).  A bounded
/// Column, not a nested scrollable, spends the card's remaining height on all
/// visible rows.  The production Balance envelope deliberately allocates the
/// carousel ten percent of the shared card split, so a settled Top 5 needs a
/// compact 23px minimum here. Stretch adds breathing room without changing
/// row semantics or introducing a nested scrollable.
final class _CompactMoverRows extends StatelessWidget {
  const _CompactMoverRows({required this.movers, required this.onSelected});

  final List<DashboardBalanceCategoryMover> movers;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rowHeight = (constraints.maxHeight / movers.length)
          .clamp(23.0, 42.0)
          .toDouble();
      return KeyedSubtree(
        key: const ValueKey<String>('balance-category-movers-list'),
        child: Column(
          children: <Widget>[
            for (var index = 0; index < movers.length; index += 1)
              SizedBox(
                height: rowHeight,
                child: _CategoryMoverRow(
                  mover: movers[index],
                  rank: index + 1,
                  showDivider: index != movers.length - 1,
                  compact: true,
                  onTap: () => onSelected(movers[index]),
                ),
              ),
          ],
        ),
      );
    },
  );
}

final class _MoversOverviewTop extends StatelessWidget {
  const _MoversOverviewTop({
    required this.presentation,
    required this.direction,
    required this.onDirectionSelected,
    required this.onExplanationToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final _MoversDirection direction;
  final ValueChanged<_MoversDirection> onDirectionSelected;
  final VoidCallback onExplanationToggled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _MoversOverviewHeader(
        presentation: presentation,
        onExplanationToggled: onExplanationToggled,
      ),
      const SizedBox(height: 2),
      _DirectionSelector(selected: direction, onSelected: onDirectionSelected),
    ],
  );
}

final class _MoversOverviewHeader extends StatelessWidget {
  const _MoversOverviewHeader({
    required this.presentation,
    required this.onExplanationToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final VoidCallback onExplanationToggled;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Row(
          children: <Widget>[
            const Flexible(
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
            const SizedBox(width: 7),
            _MoversInfoButton(
              key: const ValueKey<String>('balance-category-movers-info'),
              onTap: onExplanationToggled,
            ),
          ],
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

/// A 28px visual control inside the required 44px semantic hit target.  The
/// compact circle keeps explanation access beside a title without allocating a
/// persistent explanatory paragraph below it.
final class _MoversInfoButton extends StatelessWidget {
  const _MoversInfoButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Kategóriaváltozás magyarázata',
    child: SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                border: Border.all(
                  color: BalanceCategoryMoversVisualTokens.purple.withValues(
                    alpha: .55,
                  ),
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: BalanceCategoryMoversVisualTokens.purple,
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
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
      constraints: const BoxConstraints(maxWidth: 232),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: _DirectionSegment(
              key: const ValueKey<String>(
                'balance-category-movers-direction-decrease',
              ),
              direction: _MoversDirection.decrease,
              selected: selected == _MoversDirection.decrease,
              onSelected: onSelected,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 32,
            decoration: BoxDecoration(
              color: selected
                  ? null
                  : BalanceCategoryMoversVisualTokens.unselectedSegmentSurface,
              gradient: selected
                  ? BalanceCategoryMoversVisualTokens.selectedSegmentGradient
                  : null,
              borderRadius: BorderRadius.circular(16),
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
                    size: 14,
                    color: selected
                        ? Colors.white
                        : BalanceCategoryMoversVisualTokens.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : BalanceCategoryMoversVisualTokens.secondaryText,
                      fontSize: 12,
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
    required this.compact,
    required this.onTap,
  });

  final DashboardBalanceCategoryMover mover;
  final int rank;
  final bool showDivider;
  final bool compact;
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
            child: SizedBox.expand(
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
                      SizedBox(width: compact ? 4 : 6),
                      BalanceCategoryVisualBadge(
                        semanticLabel: mover.label,
                        categoryColorId: mover.categoryColorId,
                        categoryIconId: mover.categoryIconId,
                        size: compact ? 22 : 32,
                        iconSize: compact ? 13 : 18,
                      ),
                      SizedBox(width: compact ? 5 : 9),
                      Expanded(
                        child: Text(
                          mover.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                BalanceCategoryMoversVisualTokens.primaryText,
                            fontSize: compact ? 11.5 : 14.5,
                            height: compact ? 1 : 18 / 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 3 : 6),
                      SizedBox(
                        width: compact ? 70 : 88,
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
                                fontSize: compact ? 12 : 15.5,
                                height: compact ? 1 : 18 / 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: compact ? 0 : 1),
                            Text(
                              balanceCategoryMoverSignedAmountLabel(
                                mover.deltaMinor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BalanceCategoryMoversVisualTokens
                                    .secondaryText,
                                fontSize: compact ? 9 : 11.5,
                                height: compact ? 1 : 15 / 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: compact ? 2 : 7),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: compact ? 14 : 18,
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
    required this.onExplanationToggled,
    required this.onMetricsToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final VoidCallback onBack;
  final VoidCallback onExplanationToggled;
  final VoidCallback onMetricsToggled;

  @override
  Widget build(BuildContext context) {
    final accent = CategoryColorCatalog.resolve(
      mover.categoryColorId,
    ).middleColor;
    final labels = balanceCategoryMoverLegendLabels(presentation);
    final series = balanceCategoryMoverCumulativeSeries(mover.trend);
    return KeyedSubtree(
      key: const ValueKey<String>('balance-category-movers-detail'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BalanceCategoryMoversVisualTokens.horizontalInset,
          6,
          BalanceCategoryMoversVisualTokens.horizontalInset,
          8,
        ),
        child: _MoversDetailContent(
          presentation: presentation,
          mover: mover,
          labels: labels,
          series: series,
          accent: accent,
          onBack: onBack,
          onExplanationToggled: onExplanationToggled,
          onMetricsToggled: onMetricsToggled,
        ),
      ),
    );
  }
}

final class _MoversDetailContent extends StatelessWidget {
  const _MoversDetailContent({
    required this.presentation,
    required this.mover,
    required this.labels,
    required this.series,
    required this.accent,
    required this.onBack,
    required this.onExplanationToggled,
    required this.onMetricsToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final BalanceCategoryMoverLegendLabels labels;
  final BalanceCategoryMoverCumulativeSeries series;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onExplanationToggled;
  final VoidCallback onMetricsToggled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _MoversDetailHeader(
        presentation: presentation,
        mover: mover,
        onBack: onBack,
        onExplanationToggled: onExplanationToggled,
      ),
      const SizedBox(height: 3),
      _ChartHeader(labels: labels, accent: accent),
      const SizedBox(height: 4),
      Expanded(
        child: _MoverCumulativeChart(
          presentation: presentation,
          mover: mover,
          series: series,
          accent: accent,
          onTap: onMetricsToggled,
        ),
      ),
    ],
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
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: BalanceCategoryMoversVisualTokens.purple,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _MoversDetailHeader extends StatelessWidget {
  const _MoversDetailHeader({
    required this.presentation,
    required this.mover,
    required this.onBack,
    required this.onExplanationToggled,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final VoidCallback onBack;
  final VoidCallback onExplanationToggled;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _MoversBackTarget(onBack: onBack),
      BalanceCategoryVisualBadge(
        semanticLabel: mover.label,
        categoryColorId: mover.categoryColorId,
        categoryIconId: mover.categoryIconId,
        size: 34,
        iconSize: 19,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Row(
          children: <Widget>[
            Flexible(
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
            const SizedBox(width: 6),
            _MoversInfoButton(
              key: const ValueKey<String>(
                'balance-category-movers-detail-info',
              ),
              onTap: onExplanationToggled,
            ),
          ],
        ),
      ),
      const SizedBox(width: 2),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: _ScopeLabelAndCalendar(presentation: presentation),
        ),
      ),
    ],
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
    required this.onTap,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final DashboardBalanceCategoryMover mover;
  final BalanceCategoryMoverCumulativeSeries series;
  final Color accent;
  final VoidCallback onTap;

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
      button: true,
      label: semantics,
      hint: 'Érintse meg a részletes értékekhez',
      child: GestureDetector(
        key: const ValueKey<String>('balance-category-movers-chart-hit-area'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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

/// One in-card transient surface for both explanatory and chart insight copy.
/// It is a Stack layer, never normal-flow content, so it cannot enlarge the
/// shared Dashboard mode-content card or push the cumulative chart away.
final class _CategoryMoverOverlaySurface extends StatelessWidget {
  const _CategoryMoverOverlaySurface({
    required this.overlay,
    required this.mover,
    required this.onClose,
  });

  final _CategoryMoverOverlay overlay;
  final DashboardBalanceCategoryMover? mover;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final metrics = overlay == _CategoryMoverOverlay.metrics;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      children: <Widget>[
        if (metrics)
          Positioned(
            left: 0,
            right: 0,
            top: 48,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onClose,
            ),
          ),
        Positioned(
          left: 8,
          right: 8,
          top: metrics ? null : 50,
          bottom: metrics ? 8 : null,
          child: AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _MoversOverlayCard(
              key: ValueKey<String>(
                metrics
                    ? 'balance-category-movers-metrics-overlay'
                    : 'balance-category-movers-explanation-overlay',
              ),
              title: metrics ? 'Részletes értékek' : 'Mit jelent ez?',
              onClose: onClose,
              onTap: metrics ? onClose : null,
              child: metrics
                  ? _MoversMetricsOverlayBody(mover: mover!)
                  : _MoversExplanationOverlayBody(isDetail: mover != null),
            ),
          ),
        ),
      ],
    );
  }
}

final class _MoversOverlayCard extends StatelessWidget {
  const _MoversOverlayCard({
    super.key,
    required this.title,
    required this.onClose,
    this.onTap,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 11),
        decoration: BoxDecoration(
          color: BalanceCategoryMoversVisualTokens.transientOverlaySurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: BalanceCategoryMoversVisualTokens.transientOverlayBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: BalanceCategoryMoversVisualTokens.primaryText,
                      fontSize: 12.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>(
                    'balance-category-movers-overlay-close',
                  ),
                  tooltip: 'Bezárás',
                  onPressed: onClose,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: BalanceCategoryMoversVisualTokens.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    ),
  );
}

final class _MoversExplanationOverlayBody extends StatelessWidget {
  const _MoversExplanationOverlayBody({required this.isDetail});

  final bool isDetail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(
        isDetail ? Icons.insights_rounded : Icons.info_outline_rounded,
        size: 18,
        color: BalanceCategoryMoversVisualTokens.secondaryText,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          isDetail
              ? 'A grafikon a kiválasztott időszak és a megelőző azonos időszak kumulatív költését hasonlítja össze. Így látható, mikor és mekkora eltérés alakult ki.'
              : 'A lista a kiválasztott időszak kategóriaköltéseit hasonlítja a megelőző azonos időszakhoz. A százalék a relatív változás, az alatta lévő összeg pedig a pontos forintkülönbség.',
          style: const TextStyle(
            color: BalanceCategoryMoversVisualTokens.secondaryText,
            fontSize: 11.5,
            height: 14 / 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

final class _MoversMetricsOverlayBody extends StatelessWidget {
  const _MoversMetricsOverlayBody({required this.mover});

  final DashboardBalanceCategoryMover mover;

  @override
  Widget build(BuildContext context) {
    final positive = mover.deltaMinor > 0 || mover.isNew;
    final semantic = positive
        ? BalanceCategoryMoversVisualTokens.positive
        : BalanceCategoryMoversVisualTokens.negative;
    return Column(
      children: <Widget>[
        _MoversMetricLine(
          key: const ValueKey<String>(
            'balance-category-movers-metrics-current',
          ),
          label: 'Kiválasztott időszak',
          value: DashboardPreparedFormatter.amountMinor(mover.currentMinor),
          valueColor: BalanceCategoryMoversVisualTokens.primaryText,
        ),
        const SizedBox(height: 5),
        _MoversMetricLine(
          key: const ValueKey<String>(
            'balance-category-movers-metrics-percentage',
          ),
          label: 'Változás',
          value: balanceCategoryMoverPercentageLabel(mover),
          valueColor: semantic,
        ),
        const SizedBox(height: 5),
        _MoversMetricLine(
          key: const ValueKey<String>('balance-category-movers-metrics-delta'),
          label: 'Különbség',
          value: balanceCategoryMoverSignedAmountLabel(mover.deltaMinor),
          valueColor: mover.deltaMinor == 0
              ? BalanceCategoryMoversVisualTokens.secondaryText
              : semantic,
        ),
      ],
    );
  }
}

final class _MoversMetricLine extends StatelessWidget {
  const _MoversMetricLine({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: BalanceCategoryMoversVisualTokens.secondaryText,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor,
          fontSize: 16,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
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
