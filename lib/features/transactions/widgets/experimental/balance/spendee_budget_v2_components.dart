import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/debug/debug_console.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/category_limit.dart';
import '../../../models/transaction_record.dart';
import '../../../slots/category_color_resolver.dart';
import '../../category_slot_icon.dart';
import 'spendee_balance_collapse_controller.dart';
import 'spendee_balance_ticking_carousel.dart';
import 'spendee_balance_visual_spec.dart';

/// Final B3M-B Budget header.  This deliberately owns its material directly:
/// there is no intermediate scroll/viewport surface between the header and
/// the F1 page background.
class SpendeeBudgetV2Header extends StatelessWidget {
  const SpendeeBudgetV2Header({
    super.key,
    required this.bars,
    required this.collapseProgress,
  });

  final List<CategoryBudgetBarData> bars;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final visuals = SpendeeBalanceCollapseVisuals.forProgress(collapseProgress);
    final summary = BudgetV2BudgetSummary.fromBars(bars);
    BudgetV2ChartDiagnostics.header(summary: summary, bars: bars);
    final remainingCopy = summary.isOverBudget
        ? '${formatBudgetV2Forint(summary.remaining.abs())} túlköltve'
        : '${formatBudgetV2Forint(summary.remaining)} maradt';
    const radius = BorderRadius.all(Radius.circular(24));
    return SizedBox(
      key: const ValueKey('spendee-balance-hero'),
      width: SpendeeBalanceVisualSpec.contentWidth,
      height: visuals.heroHeight,
      child: DecoratedBox(
        key: const ValueKey('spendee-budget-v2-header-surface'),
        decoration: const BoxDecoration(
          gradient: CssLinearGradient(
            cssDegrees: 112,
            colors: <Color>[
              Color(0xFFBDF5FF),
              Color(0xFF06B6D4),
              Color(0xFF0057D9),
            ],
            stops: <double>[0, .5, 1],
          ),
          border: Border.fromBorderSide(BorderSide(color: Color(0x9EFFFFFF))),
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x2E0057D9),
              offset: Offset(0, 14),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Color(0x85FFFFFF),
              offset: Offset(0, 1),
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned(
                top: 16,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Budget',
                      style: TextStyle(
                        color: Color(0xF0FFFFFF),
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0x1F4C2B7A),
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${formatBudgetV2Forint(summary.spent)} / '
                      '${formatBudgetV2Forint(summary.limit)}',
                      key: const ValueKey('spendee-budget-v2-header-amount'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: .96,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.76,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0x1F4C2B7A),
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 10,
                left: 20,
                child: IgnorePointer(
                  ignoring: !visuals.insightsInteractive,
                  child: Transform.translate(
                    offset: Offset(0, visuals.heroStatsTranslateY),
                    child: Opacity(
                      key: const ValueKey('spendee-budget-v2-header-stats'),
                      opacity: visuals.heroStatsOpacity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '${summary.percent.round()}% elköltve',
                                style: const TextStyle(
                                  color: Color(0xD1FFFFFF),
                                  fontSize: 10,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .1,
                                ),
                              ),
                              Text(
                                remainingCopy,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          _BudgetV2PartitionProgress(
                            segments: summary.partitionSegments,
                          ),
                        ],
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

class BudgetV2BudgetSummary {
  const BudgetV2BudgetSummary({
    required this.spent,
    required this.limit,
    required this.partitionSegments,
  });

  factory BudgetV2BudgetSummary.fromBars(List<CategoryBudgetBarData> bars) {
    final limited = bars
        .where((bar) => bar.hasLimit && bar.limitAmount > 0)
        .toList(growable: false);
    final spent = limited.fold<double>(0, (sum, bar) => sum + bar.spent);
    final limit = limited.fold<double>(0, (sum, bar) => sum + bar.limitAmount);
    return BudgetV2BudgetSummary(
      spent: spent,
      limit: limit,
      partitionSegments: <BudgetV2PartitionSegment>[
        for (final bar in limited.take(5))
          BudgetV2PartitionSegment(
            fraction: limit == 0 ? 0 : (bar.spent / limit).clamp(0.0, 1.0),
            color: _resolvedColor(bar),
          ),
      ],
    );
  }

  final double spent;
  final double limit;
  final List<BudgetV2PartitionSegment> partitionSegments;

  /// The text and diagnostics must retain the real ratio.  The visual track
  /// still caps at one full width, but silently changing 476% into 100% makes
  /// the header claim a false budget state.
  double get remaining => limit - spent;
  double get percent => limit == 0 ? 0 : spent / limit * 100;
  double get visualPercent => percent.clamp(0, 100).toDouble();
  bool get isOverBudget => remaining < 0;
}

class BudgetV2PartitionSegment {
  const BudgetV2PartitionSegment({required this.fraction, required this.color});

  final double fraction;
  final Color color;
}

class _BudgetV2PartitionProgress extends StatelessWidget {
  const _BudgetV2PartitionProgress({required this.segments});

  final List<BudgetV2PartitionSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.fraction,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        key: const ValueKey('spendee-budget-v2-partition-progress'),
        height: 5,
        child: ColoredBox(
          color: const Color(0x6BFFFFFF),
          child: Row(
            children: <Widget>[
              for (var index = 0; index < segments.length; index += 1)
                if (segments[index].fraction > 0)
                  Expanded(
                    flex: math.max(
                      1,
                      (segments[index].fraction * 10000).round(),
                    ),
                    child: ColoredBox(
                      key: ValueKey('spendee-budget-v2-partition-$index'),
                      color: segments[index].color,
                    ),
                  ),
              if (total < 1)
                Expanded(
                  flex: math.max(1, ((1 - total) * 10000).round()),
                  child: const ColoredBox(color: Colors.transparent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five immediately-built C4W Fluvi discs.  The ticker keeps the neighbour
/// just outside either edge built/offstage, without an opaque scroll host or
/// a clipping box around the discs' authored SVG shadows.
class SpendeeBudgetV2AvatarBelt extends StatelessWidget {
  const SpendeeBudgetV2AvatarBelt({
    super.key,
    required this.bars,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CategoryBudgetBarData> bars;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    BudgetV2ChartDiagnostics.avatarBelt(bars);
    final selected = selectedIndex.clamp(0, bars.length - 1);
    return SizedBox(
      key: const ValueKey('spendee-budget-v2-avatar-belt'),
      width: 378,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            height: 70,
            child: SpendeeBalanceTickingViewport(
              key: const ValueKey('spendee-budget-v2-avatar-ticker'),
              width: 378,
              height: 70,
              itemCount: bars.length,
              selectedIndex: selected,
              slotDistance: 58,
              centerAnchor: 189,
              maxVisibleLogicalDistance: 2,
              prebuildWrappedNeighbour: true,
              clipToViewport: false,
              backgroundColor: SpendeeBalanceVisualSpec.pageBackground,
              semanticLabel: 'Budget kategória-avatarok',
              itemSizeBuilder: (_, _) => const Size(66, 66),
              itemScaleBuilder: (_, _, centeredness) =>
                  .491 + (.409 * centeredness),
              onIndexChanged: onSelected,
              onIndexSettled: onSelected,
              itemBuilder: (context, index, isSelected, select) {
                final bar = bars[index];
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${bar.title} budget',
                  child: GestureDetector(
                    key: ValueKey('spendee-budget-v2-avatar-${bar.key}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: select,
                    child: _BudgetV2FluviAvatarDisc(
                      bar: bar,
                      index: index,
                      iconSize: 30,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            left: 0,
            height: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (
                  var index = 0;
                  index < bars.length;
                  index += 1
                ) ...<Widget>[
                  SizedBox(
                    key: ValueKey('spendee-budget-v2-avatar-dot-$index'),
                    width: index == selected ? 6 : 4,
                    height: index == selected ? 6 : 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: index == selected
                            ? const Color(0xFFE84CAE)
                            : const Color(0x57808FAB),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: index == selected
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x4DE84CAE),
                                  offset: Offset(0, 2),
                                  blurRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  if (index < bars.length - 1) const SizedBox(width: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetV2FluviAvatarDisc extends StatelessWidget {
  const _BudgetV2FluviAvatarDisc({
    required this.bar,
    required this.index,
    required this.iconSize,
  });

  final CategoryBudgetBarData bar;
  final int index;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = _resolvedColor(bar);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          child: ExcludeSemantics(
            child: SvgPicture.string(
              BudgetV2FluviSvg.flutterRenderable(
                BudgetV2FluviSvg.avatarDisc(color, index),
              ),
              key: ValueKey('spendee-budget-v2-avatar-svg-${bar.key}'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        CategorySlotIcon(
          slot: bar.iconSlot,
          color: Colors.white,
          size: iconSize,
          strokeWidth: 1.35,
          listenForSlotChanges: true,
          debugSource: 'budget-v2-avatar-${bar.key}',
        ),
      ],
    );
  }
}

class SpendeeBudgetV2MotherCard extends StatefulWidget {
  const SpendeeBudgetV2MotherCard({
    super.key,
    required this.bar,
    required this.allBars,
    required this.weeklyRhythmValues,
    this.onLimitChanged,
  });

  final CategoryBudgetBarData bar;
  final List<CategoryBudgetBarData> allBars;
  final List<int> weeklyRhythmValues;
  final ValueChanged<double>? onLimitChanged;

  @override
  State<SpendeeBudgetV2MotherCard> createState() =>
      _SpendeeBudgetV2MotherCardState();
}

class _SpendeeBudgetV2MotherCardState extends State<SpendeeBudgetV2MotherCard> {
  var _vendorsPage = false;
  var _editingLimit = false;
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.bar.limitAmount.round().toString(),
    );
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetV2MotherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bar.key != widget.bar.key && !_editingLimit) {
      _limitController.text = widget.bar.limitAmount.round().toString();
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _toggleLimitEdit() {
    if (_editingLimit) {
      final value = double.tryParse(_limitController.text.replaceAll(' ', ''));
      if (value != null && value > 0) widget.onLimitChanged?.call(value);
    }
    setState(() => _editingLimit = !_editingLimit);
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.bar;
    final color = _resolvedColor(bar);
    return SizedBox(
      key: const ValueKey('spendee-budget-v2-mother-card'),
      width: 378,
      height: 210,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          border: Border.all(color: const Color(0x1C666FAB)),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140F172A),
              offset: Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 23,
                child: _BudgetV2CategoryHeading(
                  bar: bar,
                  editing: _editingLimit,
                  controller: _limitController,
                  onEdit: _toggleLimitEdit,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 96,
                      child: Column(
                        children: <Widget>[
                          Expanded(child: _BudgetV2LimitProgress(bar: bar)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 52,
                            child: _BudgetV2WeeklyRhythm(
                              values: widget.weeklyRhythmValues,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 104,
                      child: _BudgetV2DistributionPager(
                        key: ValueKey(
                          'spendee-budget-v2-summary-pager-${bar.key}',
                        ),
                        bar: bar,
                        bars: widget.allBars,
                        page: _vendorsPage,
                        onPageChanged: (value) =>
                            setState(() => _vendorsPage = value),
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetV2CategoryHeading extends StatelessWidget {
  const _BudgetV2CategoryHeading({
    required this.bar,
    required this.editing,
    required this.controller,
    required this.onEdit,
  });

  final CategoryBudgetBarData bar;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = _resolvedColor(bar);
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: const Color(0xC2FFFFFF)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2EEC4899),
                offset: Offset(0, 5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Color(0x7AFFFFFF),
                offset: Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: SizedBox(
            width: 23,
            height: 23,
            child: Center(
              child: CategorySlotIcon(
                slot: bar.iconSlot,
                color: Colors.white,
                size: 13,
                strokeWidth: 1.35,
                listenForSlotChanges: true,
                debugSource: 'budget-v2-heading-${bar.key}',
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            bar.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF25365C),
              fontSize: 8.4,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (editing)
          SizedBox(
            width: 64,
            height: 18,
            child: TextField(
              key: const ValueKey('spendee-budget-v2-limit-input'),
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Color(0xFF25365C),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0x5CEC4899)),
                ),
              ),
            ),
          )
        else
          Text(
            formatBudgetV2Forint(bar.limitAmount),
            style: const TextStyle(
              color: Color(0xFF25365C),
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          label: '${bar.title} limit szerkesztése',
          child: InkWell(
            key: const ValueKey('spendee-budget-v2-limit-edit'),
            borderRadius: BorderRadius.circular(6),
            onTap: onEdit,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x1A7D8798),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 10,
                  color: Color(0xFF7D8798),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetV2InnerPanel extends StatelessWidget {
  const _BudgetV2InnerPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xBDFFFFFF),
      border: Border.all(color: const Color(0xBDFFFFFF)),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x140F172A),
          offset: Offset(0, 7),
          blurRadius: 18,
        ),
      ],
    ),
    child: child,
  );
}

class _BudgetV2LimitProgress extends StatelessWidget {
  const _BudgetV2LimitProgress({required this.bar});

  final CategoryBudgetBarData bar;

  @override
  Widget build(BuildContext context) {
    final rawProgress = bar.rawProgress;
    final arcGradient = BudgetV2LimitArcGradient.fromCategoryColor(
      _resolvedColor(bar),
    );
    final visualProgress = BudgetV2LimitProgressRing.visualProgress(
      rawProgress,
    );
    final percent = BudgetV2LimitProgressRing.displayPercent(visualProgress);
    BudgetV2ChartDiagnostics.limitProgress(
      bar: bar,
      rawProgress: rawProgress,
      visualProgress: visualProgress,
      percent: percent,
      arcGradient: arcGradient,
    );
    return _BudgetV2InnerPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(
              height: 9,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Limit állása',
                  style: TextStyle(
                    color: Color(0xFF51617F),
                    fontSize: 7.4,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: BudgetV2LimitProgressRing(
                    key: const ValueKey('spendee-budget-v2-limit-circle'),
                    rawProgress: rawProgress,
                    categoryColor: arcGradient.start,
                  ),
                ),
              ),
            ),
            RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Elköltve: ',
                    style: TextStyle(
                      color: Color(0xFF8490A7),
                      fontSize: 7.2,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: formatBudgetV2Forint(bar.spent),
                    style: const TextStyle(
                      color: Color(0xFF25365C),
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flutter-native equivalent of the frozen B3M-B Fluvi circle progress SVG.
///
/// The source SVG stays in [BudgetV2FluviSvg.circleProgress] as the literal
/// HTML contract, but this widget deliberately owns the live paint path. This
/// keeps the dynamic limit meter out of flutter_svg/vector_graphics' parser
/// and retains the source 308px viewport, 122px shell and 96px track radii.
@immutable
class BudgetV2LimitArcGradient {
  const BudgetV2LimitArcGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  /// The source ring moves from pink A toward a lilac-pink B: a 46° hue turn
  /// with 90% saturation and 92% lightness. Preserve that relationship for
  /// every resolver-owned avatar colour rather than falling back to one
  /// global pink ring.
  factory BudgetV2LimitArcGradient.fromCategoryColor(Color start) {
    final hsl = HSLColor.fromColor(start);
    final end = hsl
        .withHue((hsl.hue - 46 + 360) % 360)
        .withSaturation((hsl.saturation * .9).clamp(0, 1).toDouble())
        .withLightness((hsl.lightness * .92).clamp(0, 1).toDouble())
        .toColor();
    return BudgetV2LimitArcGradient(
      start: start,
      middle: Color.lerp(start, end, .45)!,
      end: end,
    );
  }

  final Color start;
  final Color middle;
  final Color end;
}

class BudgetV2LimitProgressRing extends StatelessWidget {
  const BudgetV2LimitProgressRing({
    super.key,
    required this.rawProgress,
    this.categoryColor,
  });

  final double rawProgress;
  final Color? categoryColor;

  static double visualProgress(double rawProgress) {
    if (!rawProgress.isFinite) return 0;
    return rawProgress.clamp(0.0, 1.0).toDouble();
  }

  static int displayPercent(double visualProgress) =>
      (visualProgress.clamp(0.0, 1.0) * 100).round().clamp(1, 100).toInt();

  @override
  Widget build(BuildContext context) {
    final visual = visualProgress(rawProgress);
    final percent = displayPercent(visual);
    // The frozen SVG's setValue() clamps the rendered stroke to 1…100, so
    // the textual minimum and the actual arc never disagree at zero spend.
    final sourceProgress = percent / 100;
    final gradient = BudgetV2LimitArcGradient.fromCategoryColor(
      categoryColor ?? const Color(0xFFFF5AC8),
    );
    return Semantics(
      label: '$percent% limit állása',
      child: RepaintBoundary(
        child: CustomPaint(
          painter: BudgetV2LimitProgressPainter(
            progress: sourceProgress,
            percent: percent,
            startColor: gradient.start,
            middleColor: gradient.middle,
            endColor: gradient.end,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Paints the same geometry and palette as `createBudgetFluviCircleProgress`
/// in the locked HTML reference. All coordinates are source-SVG units and
/// scale together into the widget's 70×70 B3M-B allocation.
class BudgetV2LimitProgressPainter extends CustomPainter {
  const BudgetV2LimitProgressPainter({
    required this.progress,
    required this.percent,
    required this.startColor,
    required this.middleColor,
    required this.endColor,
    this.gradientStops = const <double>[0, .45, 1],
    this.percentFontSize = 48,
    this.percentBaseline = 172,
    this.centerCaption,
  });

  static const sourceViewport = Size(308, 308);
  static const sourceCenter = Offset(154, 154);
  static const sourceFaceRadius = 122.0;
  static const sourceTrackRadius = 96.0;
  static const sourceTrackWidth = 24.0;
  static const sourceGlossFraction = .24;

  final double progress;
  final int percent;
  final Color startColor;
  final Color middleColor;
  final Color endColor;
  final List<double> gradientStops;
  final double percentFontSize;
  final double percentBaseline;

  /// Kept as explicit paint state so the no-caption contract is observable
  /// in the widget regression without reintroducing an inner text node.
  final String? centerCaption;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / sourceViewport.width,
      size.height / sourceViewport.height,
    );
    final offset = Offset(
      (size.width - sourceViewport.width * scale) / 2,
      (size.height - sourceViewport.height * scale) / 2,
    );
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);

    final faceRect = Rect.fromCircle(
      center: sourceCenter,
      radius: sourceFaceRadius,
    );
    final trackRect = Rect.fromCircle(
      center: sourceCenter,
      radius: sourceTrackRadius,
    );
    const startAngle = -math.pi / 2;
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);

    // SVG: the wide, blurred 0.10-opacity ellipse below the sphere.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(154, 266), width: 252, height: 68),
      Paint()
        ..color = const Color(0x1ABD7CE8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // SVG softShadow: purple source-alpha shadow, offset 12px downward.
    canvas.drawCircle(
      const Offset(154, 166),
      sourceFaceRadius,
      Paint()
        ..color = const Color(0x33A763D7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      sourceCenter,
      sourceFaceRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.32, -.44),
          radius: .78,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFBF9FF),
            Color(0xFFEFEAF8),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      sourceCenter,
      sourceFaceRadius,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final shellHighlight = Path()
      ..moveTo(72, 86)
      ..cubicTo(114, 48, 189, 42, 236, 84);
    canvas.drawPath(
      shellHighlight,
      Paint()
        ..color = const Color(0x8CFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    // The full pale source track under the live progress arc.
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0x73CFC7DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F4FF),
            Color(0xFFECE8F8),
            Color(0xFFDCD6EC),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sourceTrackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2 * sourceGlossFraction,
      false,
      Paint()
        ..color = const Color(0x85FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    if (sweep > 0) {
      // Source proportions are A → 45%-mixed → B, where A is the selected
      // avatar's resolver colour and B is its deterministic lilac companion.
      canvas.drawArc(
        trackRect.shift(const Offset(0, 5)),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = endColor.withValues(alpha: .30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sourceTrackWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      canvas.drawArc(
        trackRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[startColor, middleColor, endColor],
            stops: gradientStops,
          ).createShader(trackRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sourceTrackWidth
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        trackRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = const Color(0x3DFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    _paintCenteredText(
      canvas,
      text: '$percent%',
      sourceBaselineY: percentBaseline,
      style: TextStyle(
        fontFamily: 'Inter',
        color: Color(0xFF2F3154),
        fontSize: percentFontSize,
        letterSpacing: -1,
        height: 1,
        fontWeight: FontWeight.w700,
      ),
    );
    canvas.restore();
  }

  void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required double sourceBaselineY,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeLineMetrics().first.baseline;
    painter.paint(
      canvas,
      Offset(sourceCenter.dx - painter.width / 2, sourceBaselineY - baseline),
    );
  }

  @override
  bool shouldRepaint(covariant BudgetV2LimitProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.percent != percent ||
      oldDelegate.startColor != startColor ||
      oldDelegate.middleColor != middleColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.gradientStops != gradientStops ||
      oldDelegate.percentFontSize != percentFontSize ||
      oldDelegate.percentBaseline != percentBaseline ||
      oldDelegate.centerCaption != centerCaption;
}

class _BudgetV2WeeklyRhythm extends StatelessWidget {
  const _BudgetV2WeeklyRhythm({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return _BudgetV2InnerPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(
              height: 9,
              child: Text(
                'Heti ritmus',
                style: TextStyle(
                  color: Color(0xFF51617F),
                  fontSize: 7.4,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SvgPicture.string(
                BudgetV2FluviSvg.flutterRenderable(
                  BudgetV2FluviSvg.weeklyRhythm(values),
                ),
                key: const ValueKey('spendee-budget-v2-weekly-rhythm'),
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetV2DistributionPager extends StatelessWidget {
  const _BudgetV2DistributionPager({
    super.key,
    required this.bar,
    required this.bars,
    required this.page,
    required this.onPageChanged,
    required this.color,
  });

  final CategoryBudgetBarData bar;
  final List<CategoryBudgetBarData> bars;
  final bool page;
  final ValueChanged<bool> onPageChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() >= 80) onPageChanged(velocity.isNegative);
      },
      onTap: () => onPageChanged(!page),
      child: Column(
        children: <Widget>[
          Expanded(
            child: _BudgetV2InnerPanel(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: const Duration(milliseconds: 140),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[...previous, ?current],
                ),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.18, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: page
                    ? _BudgetV2VendorPage(
                        key: const ValueKey('spendee-budget-v2-vendors-page'),
                        bar: bar,
                        color: color,
                      )
                    : _BudgetV2PiePage(
                        key: const ValueKey('spendee-budget-v2-pie-page'),
                        selected: bar,
                        bars: bars,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _BudgetV2PageDot(active: !page),
                const SizedBox(width: 4),
                _BudgetV2PageDot(active: page),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetV2PageDot extends StatelessWidget {
  const _BudgetV2PageDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: active ? 6 : 4,
    height: active ? 6 : 4,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE84CAE) : const Color(0x57808FAB),
        borderRadius: BorderRadius.circular(999),
        boxShadow: active
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x4DE84CAE),
                  offset: Offset(0, 2),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
    ),
  );
}

class _BudgetV2PiePage extends StatelessWidget {
  const _BudgetV2PiePage({
    super.key,
    required this.selected,
    required this.bars,
  });
  final CategoryBudgetBarData selected;
  final List<CategoryBudgetBarData> bars;

  @override
  Widget build(BuildContext context) {
    final top = [...bars]..sort((a, b) => b.spent.compareTo(a.spent));
    final pieBars = top.where((bar) => bar.spent > 0).toList(growable: false);
    final total = pieBars.fold<double>(0, (sum, item) => sum + item.spent);
    final selectedIndex = pieBars.indexWhere((bar) => bar.key == selected.key);
    final slices = pieBars
        .map(
          (bar) => BudgetV2FluviDonutSlice(
            label: bar.title,
            value: bar.spent,
            color: _resolvedColor(bar),
          ),
        )
        .toList(growable: false);
    final donutSvg = BudgetV2FluviSvg.flutterRenderable(
      BudgetV2FluviSvg.clayDonut(
        slices: slices,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      ),
    );
    BudgetV2ChartDiagnostics.distribution(
      selected: selected,
      bars: pieBars,
      total: total,
      svg: donutSvg,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(
            height: 9,
            child: Text(
              'Kategóriák eloszlása',
              style: TextStyle(
                color: Color(0xFF51617F),
                fontSize: 7.4,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: SvgPicture.string(
                donutSvg,
                errorBuilder: (_, error, stackTrace) {
                  BudgetV2ChartDiagnostics.rendererError(
                    chart: 'distribution',
                    scope: '${selected.window.name}:${selected.periodKey}',
                    categoryKey: selected.key,
                    error: error,
                    stackTrace: stackTrace,
                  );
                  return const SizedBox.expand();
                },
                key: const ValueKey('spendee-budget-v2-clay-donut'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Top 3 kategória',
            style: TextStyle(
              color: Color(0xFF51617F),
              fontSize: 6.8,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          for (final item in pieBars.take(3))
            _BudgetV2LegendRow(
              title: item.title,
              color: _resolvedColor(item),
              value: total == 0 ? 0 : (item.spent / total * 100).round(),
            ),
        ],
      ),
    );
  }
}

class _BudgetV2LegendRow extends StatelessWidget {
  const _BudgetV2LegendRow({
    required this.title,
    required this.color,
    required this.value,
  });
  final String title;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 9,
    child: Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 4, height: 4),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF66738D),
              fontSize: 6.1,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '$value%',
          style: const TextStyle(
            color: Color(0xFF25365C),
            fontSize: 6,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _BudgetV2VendorPage extends StatelessWidget {
  const _BudgetV2VendorPage({
    super.key,
    required this.bar,
    required this.color,
  });
  final CategoryBudgetBarData bar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const vendors = <(String, int)>[('Lidl', 48), ('Tesco', 31), ('Piac', 21)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 9,
            child: Text(
              '${bar.title} kereskedői',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF51617F),
                fontSize: 7.4,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          for (final vendor in vendors)
            _BudgetV2VendorRow(name: vendor.$1, share: vendor.$2, color: color),
        ],
      ),
    );
  }
}

class _BudgetV2VendorRow extends StatelessWidget {
  const _BudgetV2VendorRow({
    required this.name,
    required this.share,
    required this.color,
  });
  final String name;
  final int share;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 17,
    child: Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 5, height: 5),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF31415F),
              fontSize: 6.6,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: ColoredBox(
                color: const Color(0x22EC4899),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: share / 100,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$share%',
          style: const TextStyle(
            color: Color(0xFF25365C),
            fontSize: 6.1,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

Color _resolvedColor(CategoryBudgetBarData bar) =>
    CategoryColorResolver.color(category: bar.category, fallback: bar.color);

String formatBudgetV2Forint(double value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs().round().toString();
  final groups = <String>[];
  for (var end = absolute.length; end > 0; end -= 3) {
    final start = math.max(0, end - 3);
    groups.add(absolute.substring(start, end));
  }
  return '$sign${groups.reversed.join(' ')} Ft';
}

/// Bounded production diagnostics for BudgetV2's live chart boundaries.
/// Rebuilds are frequent during a ticking belt, therefore each distinct chart
/// input is emitted once while renderer failures remain separately visible.
abstract final class BudgetV2ChartDiagnostics {
  static String? _lastHeaderSignature;
  static String? _lastAvatarBeltSignature;
  static String? _lastDistributionSignature;
  static String? _lastLimitSignature;
  static final Set<String> _rendererErrors = <String>{};

  static void header({
    required BudgetV2BudgetSummary summary,
    required List<CategoryBudgetBarData> bars,
  }) {
    final scope = bars.isEmpty
        ? 'empty'
        : '${bars.first.window.name}:${bars.first.periodKey}';
    final signature =
        '$scope:${_svgNumber(summary.spent)}:'
        '${_svgNumber(summary.limit)}:${bars.length}';
    if (_lastHeaderSignature == signature) return;
    _lastHeaderSignature = signature;
    DebugConsole.log(
      '[BudgetV2Chart] header '
      'scope=$scope supplied_categories=${bars.length} '
      'spent=${_svgNumber(summary.spent)} '
      'limit=${_svgNumber(summary.limit)} '
      'raw_percent=${_svgNumber(summary.percent)} '
      'visual_percent=${_svgNumber(summary.visualPercent)} '
      'remaining=${_svgNumber(summary.remaining)} '
      'over_budget=${summary.isOverBudget}',
    );
  }

  static void avatarBelt(List<CategoryBudgetBarData> bars) {
    final keys = bars.map((bar) => bar.key).join('|');
    if (_lastAvatarBeltSignature == keys) return;
    _lastAvatarBeltSignature = keys;
    DebugConsole.log(
      '[BudgetV2Chart] avatar_belt '
      'supplied_categories=${bars.length} visible_slots=5 '
      'keys=$keys resolver=CategoryColorResolver',
    );
  }

  static void distribution({
    required CategoryBudgetBarData selected,
    required List<CategoryBudgetBarData> bars,
    required double total,
    required String svg,
  }) {
    final slices = bars
        .map(
          (bar) =>
              '${bar.targetId}:${_svgNumber(bar.spent)}:${_hex(_resolvedColor(bar))}',
        )
        .join('|');
    final signature =
        '${selected.window.name}:${selected.periodKey}:${selected.key}:$slices';
    if (_lastDistributionSignature == signature) return;
    _lastDistributionSignature = signature;
    DebugConsole.log(
      '[BudgetV2Chart] distribution '
      'scope=${selected.window.name}:${selected.periodKey} '
      'selected=${selected.key} '
      'input_categories=${bars.length} '
      'slice_total=${_svgNumber(total)} '
      'slices=$slices '
      'resolver=CategoryColorResolver '
      'svg_paths=${RegExp(r'<path\b').allMatches(svg).length} '
      'flutter_font_weight_750=${svg.contains('font-weight="750"')}',
    );
  }

  static void limitProgress({
    required CategoryBudgetBarData bar,
    required double rawProgress,
    required double visualProgress,
    required int percent,
    required BudgetV2LimitArcGradient arcGradient,
  }) {
    final signature =
        '${bar.key}:${_svgNumber(bar.spent)}:${_svgNumber(bar.limitAmount)}:'
        '$percent:${_hex(arcGradient.start)}:${_hex(arcGradient.end)}';
    if (_lastLimitSignature == signature) return;
    _lastLimitSignature = signature;
    DebugConsole.log(
      '[BudgetV2Chart] limit-circle '
      'scope=${bar.window.name}:${bar.periodKey} '
      'category=${bar.key} '
      'spent=${_svgNumber(bar.spent)} '
      'limit=${_svgNumber(bar.limitAmount)} '
      'raw_ratio=${_svgNumber(rawProgress)} '
      'visual_ratio=${_svgNumber(visualProgress)} '
      'percent=$percent '
      'gradient_a=${_hex(arcGradient.start)} '
      'gradient_b=${_hex(arcGradient.end)} '
      'gradient_stops=0,.45,1 '
      'center_caption=none '
      'renderer=flutter_custom_paint '
      'full_ring=${percent == 100}',
    );
  }

  static void rendererError({
    required String chart,
    required String scope,
    required String categoryKey,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final signature = '$chart:$scope:$categoryKey:$error';
    if (!_rendererErrors.add(signature)) return;
    DebugConsole.log(
      '[BudgetV2Chart] renderer_error '
      'chart=$chart scope=$scope category=$categoryKey error=$error '
      'stack=${stackTrace == null ? 'none' : stackTrace.toString().split('\n').first}',
    );
  }
}

/// The B3M-B donut consumes the actual category total, not a count of colour
/// slots.  Keeping label/value/colour together makes an accidental equal-slice
/// fallback impossible at the rendering boundary.
class BudgetV2FluviDonutSlice {
  const BudgetV2FluviDonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Resolves the exact seven B3M-B daily rhythm inputs for the selected
/// category. The SVG receives percentages of the live category limit, as the
/// source prototype does; it never synthesizes a decorative pattern.
abstract final class BudgetV2WeeklyRhythmValues {
  static List<int> resolve({
    required CategoryBudgetBarData bar,
    required Iterable<TransactionRecord> records,
    required DateTime endDate,
  }) {
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final start = end.subtract(const Duration(days: 6));
    final amounts = List<double>.filled(7, 0);
    if (bar.limitAmount <= 0) {
      return List<int>.unmodifiable(List<int>.filled(7, 0));
    }
    for (final record in records) {
      if (record.type != bar.transactionType ||
          record.transactionCategoryID != bar.targetId) {
        continue;
      }
      final isInBudgetWindow = switch (bar.window) {
        LimitWindow.monthly => record.yearMonthKey == bar.periodKey,
        LimitWindow.yearly => record.yearMonthKey.startsWith(
          '${bar.periodKey}-',
        ),
        LimitWindow.allTime => true,
      };
      if (!isInBudgetWindow) {
        continue;
      }
      final date = DateTime.tryParse(record.normalizedDate);
      if (date == null || date.isBefore(start) || date.isAfter(end)) {
        continue;
      }
      amounts[date.difference(start).inDays] += record.amount.abs();
    }
    return List<int>.unmodifiable(
      amounts
          .map(
            (amount) =>
                ((amount / bar.limitAmount) * 100).round().clamp(0, 100),
          )
          .cast<int>()
          .toList(growable: false),
    );
  }
}

/// Literal B3M-B Fluvi SVG templates. Dynamic data only changes the intended
/// segments/values; the SVG geometry, gradients and filters remain the HTML
/// source-of-truth vectors rather than a Flutter approximation.
abstract final class BudgetV2FluviSvg {
  /// flutter_svg/vector_graphics deliberately does not implement SVG filter
  /// primitives (the renderer reports an unhandled `<filter/>` and can drop
  /// the containing layer). Keep the full B3M-B source vector as the data
  /// contract, then remove only those unsupported effect nodes for Flutter's
  /// vector parser. The authored geometry, gradients, highlights, depths and
  /// all dynamic values remain exactly the source SVG.
  static String flutterRenderable(String source) => source
      .replaceAll(RegExp(r'<filter\b[^>]*>.*?</filter>', dotAll: true), '')
      .replaceAll(RegExp(r'\sfilter="url\(#[^)]+\)"'), '')
      // The source prototype's 750 maps to Flutter's nearest supported
      // numeric SVG weight. Leaving 750 in the string makes flutter_svg
      // reject the entire donut picture rather than only its center label.
      .replaceAll('font-weight="750"', 'font-weight="700"');

  static String circleProgress(int percent) {
    final safe = percent.clamp(1, 100);
    // flutter_svg does not apply SVG's `pathLength` normalization to stroke
    // dashes. The source prototype uses a 0..100 dash domain, so convert it
    // to the actual r=96 circumference before the vector reaches Flutter.
    final circumference = 2 * math.pi * 96;
    final progressLength = circumference * safe / 100;
    final progressGap = circumference - progressLength;
    final highlightLength = circumference * .24;
    final highlightGap = circumference - highlightLength;
    final circleLength = _svgNumber(circumference);
    final progressDashLength = _svgNumber(progressLength);
    final progressDashGap = _svgNumber(progressGap);
    final highlightDashLength = _svgNumber(highlightLength);
    final highlightDashGap = _svgNumber(highlightGap);
    return '''<svg class="budget-fluvi-circle-progress" viewBox="102 102 308 308" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
<defs><linearGradient id="trackGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f8f4ff"/><stop offset="0.48" stop-color="#ece8f8"/><stop offset="1" stop-color="#dcd6ec"/></linearGradient><linearGradient id="progressGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff5ac8"/><stop offset="0.45" stop-color="#ef42c4"/><stop offset="1" stop-color="#a948f5"/></linearGradient><radialGradient id="centerGrad" cx="34%" cy="28%" r="78%"><stop offset="0" stop-color="#ffffff"/><stop offset="0.48" stop-color="#fbf9ff"/><stop offset="1" stop-color="#efeaf8"/></radialGradient><radialGradient id="knobGrad" cx="34%" cy="28%" r="78%"><stop offset="0" stop-color="#fff6ff"/><stop offset="0.35" stop-color="#ff8cdd"/><stop offset="0.72" stop-color="#ef44c2"/><stop offset="1" stop-color="#ae35e9"/></radialGradient><filter id="softShadow" x="-60%" y="-60%" width="220%" height="220%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="10" result="blur"/><feOffset in="blur" dx="0" dy="12" result="offset"/><feFlood flood-color="#a763d7" flood-opacity="0.20" result="color"/><feComposite in="color" in2="offset" operator="in" result="shadow"/><feMerge><feMergeNode in="shadow"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="smallShadow" x="-80%" y="-80%" width="260%" height="260%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="4.5" result="blur"/><feOffset in="blur" dx="0" dy="5" result="offset"/><feFlood flood-color="#8d39d8" flood-opacity="0.30" result="color"/><feComposite in="color" in2="offset" operator="in" result="shadow"/><feMerge><feMergeNode in="shadow"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="innerGlow" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="4"/></filter><filter id="blur2" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="2.4"/></filter></defs>
<g id="circle-progress" transform="translate(256 256)"><ellipse cx="0" cy="112" rx="126" ry="34" fill="#bd7ce8" opacity="0.10" filter="url(#innerGlow)"/><circle cx="0" cy="0" r="122" fill="url(#centerGrad)" stroke="#ffffff" stroke-opacity="0.72" stroke-width="4" filter="url(#softShadow)"/><path d="M-82,-68 C-40,-106 35,-112 82,-70" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="12" stroke-linecap="round" filter="url(#blur2)"/><circle cx="0" cy="0" r="96" fill="none" stroke="#cfc7df" stroke-opacity="0.45" stroke-width="28" transform="rotate(-90)" stroke-linecap="round"/><circle id="track" cx="0" cy="0" r="96" fill="none" stroke="url(#trackGrad)" stroke-width="24" stroke-linecap="round" transform="rotate(-90)" stroke-dasharray="$circleLength 0" stroke-dashoffset="0"/><circle cx="0" cy="0" r="96" fill="none" stroke="#ffffff" stroke-opacity="0.52" stroke-width="5" stroke-linecap="round" transform="rotate(-90)" stroke-dasharray="$highlightDashLength $highlightDashGap" stroke-dashoffset="0"/><circle id="progress" cx="0" cy="0" r="96" fill="none" stroke="url(#progressGrad)" stroke-width="24" stroke-linecap="round" transform="rotate(-90)" stroke-dasharray="$circleLength 0" stroke-dashoffset="$progressDashGap" filter="url(#smallShadow)"/><circle id="progress-highlight" cx="0" cy="0" r="96" fill="none" stroke="#ffffff" stroke-opacity="0.24" stroke-width="5" stroke-linecap="round" transform="rotate(-90)" stroke-dasharray="$progressDashLength $progressDashGap" stroke-dashoffset="0"/><text id="value" x="0" y="18" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="48" letter-spacing="-1" font-weight="700" fill="#2f3154">$safe%</text></g></svg>''';
  }

  static String weeklyRhythm(List<int> values) {
    final supplied = values
        .take(7)
        .map((value) => math.max(0, value))
        .toList(growable: true);
    while (supplied.length < 7) {
      supplied.insert(0, 0);
    }
    final maximum = supplied.fold<int>(1, math.max);
    final bars = <String>[];
    for (var index = 0; index < 7; index += 1) {
      final value = supplied[index];
      final x = 56 + index * ((544 - (14 * 6)) / 7 + 14);
      if (value <= 0) {
        bars.add('<g data-weekly-rhythm-day="$index" data-value="0"></g>');
        continue;
      }
      final height = math.max(12, 204 * value / maximum).toDouble();
      final y = 270 - height;
      const barWidth = (544 - (14 * 6)) / 7;
      final radius = barWidth / 2;
      bars.add(
        '''<g data-weekly-rhythm-day="$index" data-value="$value"><rect x="${_svgNumber(x)}" y="${_svgNumber(y + 7)}" width="${_svgNumber(barWidth)}" height="${_svgNumber(height)}" rx="${_svgNumber(radius)}" fill="#b53bc8" opacity=".16" filter="url(#budgetFluviWeeklyBlur6)"/><rect x="${_svgNumber(x)}" y="${_svgNumber(y)}" width="${_svgNumber(barWidth)}" height="${_svgNumber(height)}" rx="${_svgNumber(radius)}" fill="url(#budgetFluviWeeklyBarGrad)" stroke="#fff" stroke-opacity=".55" stroke-width="2" filter="url(#budgetFluviWeeklyBarShadow)"/><rect x="${_svgNumber(x + (barWidth * .18))}" y="${_svgNumber(y + 4)}" width="${_svgNumber(barWidth * .36)}" height="${_svgNumber(math.max(10, height * .5).toDouble())}" rx="${_svgNumber(barWidth * .18)}" fill="#fff" opacity=".22" filter="url(#budgetFluviWeeklyBlur2)"/></g>''',
      );
    }
    final average = (supplied.fold<int>(0, (sum, value) => sum + value) / 7)
        .round();
    return '''<svg class="budget-fluvi-weekly-rhythm" viewBox="46 60 564 226" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Heti költési ritmus, átlag: $average%"><defs><linearGradient id="budgetFluviWeeklyBarGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff7bd7"/><stop offset=".45" stop-color="#ef4bc5"/><stop offset="1" stop-color="#ba45ee"/></linearGradient><linearGradient id="budgetFluviWeeklyBaseGrad" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#f5effb"/><stop offset=".5" stop-color="#ebe4f4"/><stop offset="1" stop-color="#f7f3fb"/></linearGradient><filter id="budgetFluviWeeklyBarShadow" x="-100%" y="-50%" width="300%" height="250%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="4" result="b"/><feOffset in="b" dx="0" dy="7" result="o"/><feFlood flood-color="#a633cf" flood-opacity=".22" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="budgetFluviWeeklyBlur6"><feGaussianBlur stdDeviation="6"/></filter><filter id="budgetFluviWeeklyBlur2"><feGaussianBlur stdDeviation="2.2"/></filter></defs><rect x="46" y="270" width="564" height="12" rx="6" fill="url(#budgetFluviWeeklyBaseGrad)"/><g id="budgetFluviWeeklyRhythmBars" data-fluvi-weekly-rhythm-bars="true">${bars.join()}</g><text id="budgetFluviWeeklyAverage" data-fluvi-weekly-rhythm-average="true" x="600" y="49" text-anchor="end" opacity="0">átlag: $average%</text></svg>''';
  }

  static String avatarDisc(Color color, int index) {
    final hex = _hex(color).toLowerCase();
    final id = 'budgetAvatarDisc$index';
    final light = _mixBudgetAvatarDiscColor(hex, '#ffffff', .78);
    final main = _mixBudgetAvatarDiscColor(hex, '#ffffff', .18);
    final depth = _mixBudgetAvatarDiscColor(hex, '#24113f', .32);
    final shadow = _mixBudgetAvatarDiscColor(hex, '#24113f', .18);
    return '''<svg class="budget-fluvi-avatar-disc" viewBox="94 78 324 342" preserveAspectRatio="xMidYMid meet" aria-hidden="true" focusable="false" data-fluvi-avatar-disc="true" data-budget-avatar-disc-color="$hex"><defs><radialGradient id="${id}Face" cx="32%" cy="26%" r="82%"><stop offset="0" stop-color="$light"/><stop offset=".38" stop-color="$main"/><stop offset=".72" stop-color="$hex"/><stop offset="1" stop-color="$depth"/></radialGradient><linearGradient id="${id}Rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".92"/><stop offset=".42" stop-color="#ffffff" stop-opacity=".38"/><stop offset="1" stop-color="$depth" stop-opacity=".55"/></linearGradient><filter id="${id}Shadow" x="-70%" y="-70%" width="240%" height="240%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="18" result="b"/><feOffset in="b" dx="0" dy="22" result="o"/><feFlood flood-color="$shadow" flood-opacity=".28" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="${id}SoftBlur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter></defs><g data-fluvi-avatar-disc-body="true" filter="url(#${id}Shadow)"><ellipse cx="256" cy="382" rx="126" ry="34" fill="$shadow" opacity=".10" filter="url(#${id}SoftBlur)"/><circle cx="256" cy="240" r="142" fill="url(#${id}Face)" stroke="url(#${id}Rim)" stroke-width="8"/><path d="M166 190 C205 132 300 118 353 174" fill="none" stroke="#ffffff" stroke-opacity=".42" stroke-width="20" stroke-linecap="round" filter="url(#${id}SoftBlur)"/><path d="M181 315 C233 357 307 355 350 311" fill="none" stroke="$depth" stroke-opacity=".18" stroke-width="24" stroke-linecap="round" filter="url(#${id}SoftBlur)"/></g></svg>''';
  }

  static String clayDonut({
    required List<BudgetV2FluviDonutSlice> slices,
    required int selectedIndex,
    Set<int> highlightedIndexes = const <int>{},
  }) {
    final items = slices
        .where((slice) => slice.value.isFinite && slice.value > 0)
        .toList(growable: false);
    final selected = selectedIndex
        .clamp(0, math.max(0, items.length - 1))
        .toInt();
    final highlighted = <int>{
      selected,
      ...highlightedIndexes.where(
        (index) => index >= 0 && index < items.length,
      ),
    };
    final total = items.fold<double>(0, (sum, item) => sum + item.value);
    final sidePaths = <String>[];
    final topPaths = <String>[];
    var angle = 0.0;
    final gap = items.length > 12
        ? .5
        : items.length > 7
        ? .9
        : 1.7;
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      final sweep = item.value / total * 360;
      final start = angle + gap / 2;
      final end = angle + sweep - gap / 2;
      angle += sweep;
      if (end <= start) continue;
      final isHighlighted = highlighted.contains(index);
      final isSelected = index == selected;
      final radius = isHighlighted ? 198.0 : 164.0;
      final midpoint = (start + end) / 2;
      final offset = isHighlighted ? _point(0, 0, 10, midpoint) : (0.0, 0.0);
      final transform = isHighlighted
          ? ' transform="translate(${_svgNumber(offset.$1.roundToDouble())} ${_svgNumber(offset.$2.roundToDouble())})"'
          : '';
      final selectedAttribute = isSelected
          ? ' data-fluvi-donut-selected="true"'
          : '';
      final highlightedAttribute = isHighlighted
          ? ' data-fluvi-donut-highlighted="true"'
          : '';
      sidePaths.add(
        '<path d="${_donutOuterSidePath(radius, start, end)}" fill="${_hex(item.color)}" opacity=".84" aria-hidden="true"$transform$highlightedAttribute$selectedAttribute/>',
      );
      final topPath = _donutRingSlicePath(radius, start, end);
      topPaths.add(
        '<path d="$topPath" fill="${_hex(item.color)}" stroke="#ffffff" stroke-opacity=".58" stroke-width="3" data-fluvi-donut-slice="$index" data-label="${_xmlEscape(item.label)}" data-value="${_svgNumber(item.value)}"$transform$highlightedAttribute$selectedAttribute/>',
      );
      final glossTransform = isHighlighted
          ? 'translate(${_svgNumber(offset.$1.roundToDouble() - 4)} ${_svgNumber(offset.$2.roundToDouble() - 5)})'
          : 'translate(-4 -5)';
      topPaths.add(
        '<path d="$topPath" fill="#ffffff" opacity=".08" transform="$glossTransform" aria-hidden="true"/>',
      );
    }
    final centerValue = items.isEmpty
        ? '0%'
        : '${(items[selected].value / total * 100).round()}%';
    final centerLabel = items.isEmpty ? 'nincs adat' : items[selected].label;
    return '''<svg class="budget-fluvi-clay-donut" viewBox="44 44 424 424" preserveAspectRatio="xMidYMid meet" role="img" data-budget-fluvi-clay-donut="true" data-budget-fluvi-donut-count="${items.length}"><defs><radialGradient id="budgetFluviDonutCenterPlate" cx="34%" cy="28%" r="80%"><stop offset="0" stop-color="#ffffff"/><stop offset=".48" stop-color="#fbf9ff"/><stop offset="1" stop-color="#e9e3f4"/></radialGradient><linearGradient id="budgetFluviDonutCenterRim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".52" stop-color="#f1ecfa" stop-opacity=".72"/><stop offset="1" stop-color="#cfc5df" stop-opacity=".82"/></linearGradient><filter id="budgetFluviDonutSoftShadow" x="-70%" y="-70%" width="240%" height="240%"><feGaussianBlur in="SourceAlpha" stdDeviation="13" result="b"/><feOffset in="b" dx="0" dy="16" result="o"/><feFlood flood-color="#75569c" flood-opacity=".22" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter><filter id="budgetFluviDonutBlur8" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="8"/></filter><clipPath id="budgetFluviDonutFrontSideClip"><rect x="44" y="256" width="424" height="212"/></clipPath></defs><ellipse cx="256" cy="426" rx="188" ry="38" fill="#8a6ab5" opacity=".11" filter="url(#budgetFluviDonutBlur8)"/><g id="donut-chart" filter="url(#budgetFluviDonutSoftShadow)"><g id="segment-sides" data-fluvi-donut-segment-sides="true" clip-path="url(#budgetFluviDonutFrontSideClip)">${sidePaths.join()}</g><g id="segment-tops" data-fluvi-donut-segment-tops="true">${topPaths.join()}</g><circle cx="256" cy="256" r="106" fill="url(#budgetFluviDonutCenterPlate)" stroke="url(#budgetFluviDonutCenterRim)" stroke-width="6"/><path d="M188 212 C224 170 291 164 329 202" fill="none" stroke="#ffffff" stroke-opacity=".50" stroke-width="13" stroke-linecap="round" filter="url(#budgetFluviDonutBlur8)"/><text id="center-value" x="256" y="252" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="48" font-weight="750" fill="#303358">$centerValue</text><text id="center-label" x="256" y="285" text-anchor="middle" font-family="Inter, Arial, sans-serif" font-size="18" font-weight="600" fill="#7a7e9a">${_xmlEscape(centerLabel)}</text></g></svg>''';
  }

  static String _donutRingSlicePath(double radius, double start, double end) {
    final outerStart = _point(256, 256, radius, start);
    final outerEnd = _point(256, 256, radius, end);
    final innerEnd = _point(256, 256, 92, end);
    final innerStart = _point(256, 256, 92, start);
    final large = end - start > 180 ? 1 : 0;
    return 'M ${_svgNumber(outerStart.$1)} ${_svgNumber(outerStart.$2)} A ${_svgNumber(radius)} ${_svgNumber(radius)} 0 $large 1 ${_svgNumber(outerEnd.$1)} ${_svgNumber(outerEnd.$2)} L ${_svgNumber(innerEnd.$1)} ${_svgNumber(innerEnd.$2)} A 92 92 0 $large 0 ${_svgNumber(innerStart.$1)} ${_svgNumber(innerStart.$2)} Z';
  }

  static String _donutOuterSidePath(double radius, double start, double end) {
    final topStart = _point(256, 256, radius, start);
    final topEnd = _point(256, 256, radius, end);
    final bottomEnd = _point(256, 256, radius, end, yOffset: 14);
    final bottomStart = _point(256, 256, radius, start, yOffset: 14);
    final large = end - start > 180 ? 1 : 0;
    return 'M ${_svgNumber(topStart.$1)} ${_svgNumber(topStart.$2)} A ${_svgNumber(radius)} ${_svgNumber(radius)} 0 $large 1 ${_svgNumber(topEnd.$1)} ${_svgNumber(topEnd.$2)} L ${_svgNumber(bottomEnd.$1)} ${_svgNumber(bottomEnd.$2)} A ${_svgNumber(radius)} ${_svgNumber(radius)} 0 $large 0 ${_svgNumber(bottomStart.$1)} ${_svgNumber(bottomStart.$2)} Z';
  }

  static (double, double) _point(
    double cx,
    double cy,
    double radius,
    double degrees, {
    double yOffset = 0,
  }) {
    final radians = (degrees - 90) * math.pi / 180;
    return (
      cx + radius * math.cos(radians),
      cy + radius * math.sin(radians) + yOffset,
    );
  }
}

String _mixBudgetAvatarDiscColor(String source, String target, double amount) {
  final ratio = amount.clamp(0.0, 1.0);
  final channels = List<int>.generate(3, (index) {
    final start = int.parse(
      source.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    final end = int.parse(
      target.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    return (start + (end - start) * ratio).round();
  });
  return '#${channels.map((channel) => channel.toRadixString(16).padLeft(2, '0')).join()}';
}

String _svgNumber(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < .000001) return rounded.toInt().toString();
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
