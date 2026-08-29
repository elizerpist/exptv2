import 'package:flutter/material.dart';

import '../../application/dashboard_spending_rhythm_controller.dart';
import 'spending_rhythm_bar_layout.dart';

/// Full-width, scope-aware Partner Spending Rhythm renderer. Its immutable
/// input already contains exact bucket identity and money; this widget only
/// resolves layout and paint fractions.
class SpendingRhythmBarChart extends StatefulWidget {
  const SpendingRhythmBarChart({super.key, required this.state});

  /// The footer is one named geometry contract, not an unexplained minimum.
  /// The authored 40dp plot grows by exactly ten percent. The 4dp delta is
  /// reclaimed by [BudgetPartnerDistributionLayout] from the upper chart
  /// region, never from the outer Card2 envelope.
  static const double titleLaneHeight = 8;
  static const double titleToPlotGap = 3;
  static const double plotToAxisGap = 2;
  static const double axisLaneHeight = 9;
  static const double minimumPlotLaneHeight = 35.2;
  static const double targetPlotLaneHeight = 44;
  static const double minimumLayoutHeight =
      titleLaneHeight +
      titleToPlotGap +
      targetPlotLaneHeight +
      plotToAxisGap +
      axisLaneHeight;

  final DashboardSpendingRhythmState state;

  @override
  State<SpendingRhythmBarChart> createState() => _SpendingRhythmBarChartState();
}

class _SpendingRhythmBarChartState extends State<SpendingRhythmBarChart> {
  final ScrollController _sumYearsController = ScrollController();

  @override
  void dispose() {
    _sumYearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.state.analysis;
    final buckets = analysis.buckets;
    if (buckets.isEmpty) {
      return const Center(
        child: Text(
          'Nincs adat',
          style: TextStyle(
            color: Color(0xff66738d),
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    final maximum = analysis.maxBucketActualScaled100;
    final average = maximum == 0
        ? null
        : analysis.averageActualScaled100 / maximum;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(widget.state.startColorArgb),
        Color(widget.state.middleColorArgb),
        Color(widget.state.endColorArgb),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = SpendingRhythmBarLayout.resolve(
          availableWidth: constraints.maxWidth,
          barCount: buckets.length,
          allowsHorizontalScroll: analysis is SumSpendingRhythm,
        );
        final content = _RhythmChartContent(
          analysis: analysis,
          buckets: buckets,
          layout: layout,
          maximum: maximum,
          averageFraction: average,
          gradient: gradient,
        );
        return Semantics(
          label:
              'Költési ritmus ${analysis.scope.canonicalKey}; '
              'maximum $maximum; '
              '${average == null ? 'nincs átlag' : 'átlag ${analysis.averageActualScaled100}'}',
          child: layout.scrollsHorizontally
              ? SingleChildScrollView(
                  key: const ValueKey('spending-rhythm-sum-scroll'),
                  controller: _sumYearsController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: layout.contentWidth, child: content),
                )
              : content,
        );
      },
    );
  }
}

class _RhythmChartContent extends StatelessWidget {
  const _RhythmChartContent({
    required this.analysis,
    required this.buckets,
    required this.layout,
    required this.maximum,
    required this.averageFraction,
    required this.gradient,
  });

  final SpendingRhythmAnalysis analysis;
  final List<SpendingRhythmBucket> buckets;
  final SpendingRhythmBarLayout layout;
  final int maximum;
  final double? averageFraction;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(
        height: SpendingRhythmBarChart.titleLaneHeight,
        child: Text(
          'Költési ritmus',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Color(0xff51617f),
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: SpendingRhythmBarChart.titleToPlotGap),
      Expanded(
        child: LayoutBuilder(
          key: const ValueKey('spending-rhythm-plot-lane'),
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (
                    var index = 0;
                    index < buckets.length;
                    index += 1
                  ) ...<Widget>[
                    SizedBox(
                      width: layout.barWidth,
                      child: _RhythmBar(
                        index: index,
                        bucket: buckets[index],
                        fraction: maximum == 0
                            ? 0
                            : buckets[index].actualScaled100 / maximum,
                        gradient: gradient,
                      ),
                    ),
                    if (index != buckets.length - 1)
                      SizedBox(width: layout.gap),
                  ],
                ],
              ),
              if (averageFraction != null)
                Positioned(
                  key: const ValueKey('spending-rhythm-average'),
                  left: 0,
                  right: 0,
                  bottom: (constraints.maxHeight * averageFraction!).clamp(
                    0.0,
                    constraints.maxHeight,
                  ),
                  child: const IgnorePointer(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(
                            height: 1,
                            thickness: .75,
                            color: Color(0x8866738d),
                          ),
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Átlag',
                          style: TextStyle(
                            color: Color(0xff66738d),
                            fontSize: 6,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: SpendingRhythmBarChart.plotToAxisGap),
      SizedBox(
        height: SpendingRhythmBarChart.axisLaneHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < buckets.length; index += 1) ...<Widget>[
              SizedBox(
                width: layout.barWidth,
                child: _AxisLabel(
                  label: _showsLabel(analysis, index, buckets.length)
                      ? buckets[index].label
                      : '',
                ),
              ),
              if (index != buckets.length - 1) SizedBox(width: layout.gap),
            ],
          ],
        ),
      ),
      if (maximum == 0)
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Nincs adat',
            style: TextStyle(
              color: Color(0xff66738d),
              fontSize: 6,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
}

class _RhythmBar extends StatelessWidget {
  const _RhythmBar({
    required this.index,
    required this.bucket,
    required this.fraction,
    required this.gradient,
  });

  final int index;
  final SpendingRhythmBucket bucket;
  final double fraction;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${bucket.accessibilityLabel}: ${bucket.actualScaled100}',
    child: LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        key: ValueKey('spending-rhythm-track-$index'),
        decoration: BoxDecoration(
          // Dense MONTH charts previously filled every zero-slot track. At
          // Android density those adjacent muted fills rasterised as a single
          // opaque grey slab during the cascading-card transform. An outline
          // still makes zero buckets discoverable, while preserving the card
          // material between independent bars at every collapse progress.
          color: Colors.transparent,
          border: Border.all(color: const Color(0x3651617f), width: .65),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            key: ValueKey('spending-rhythm-fill-$index'),
            height: constraints.maxHeight * fraction.clamp(0.0, 1.0),
            width: constraints.maxWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.clip,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xff66738d),
      fontSize: 6.4,
      height: 1,
      fontWeight: FontWeight.w900,
    ),
  );
}

bool _showsLabel(SpendingRhythmAnalysis analysis, int index, int count) {
  if (analysis is! MonthSpendingRhythm) return true;
  final day = index + 1;
  return day == 1 ||
      day == 5 ||
      day == 10 ||
      day == 15 ||
      day == 20 ||
      day == 25 ||
      day == count;
}
