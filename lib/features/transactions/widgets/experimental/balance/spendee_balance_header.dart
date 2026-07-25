import 'package:flutter/material.dart';

import 'spendee_balance_collapse_controller.dart';
import 'spendee_balance_visual_spec.dart';

typedef SpendeeBalanceHeaderSurfaceBuilder =
    Widget Function(
      BuildContext context,
      BorderRadius borderRadius,
      Widget child,
    );

class SpendeeBalanceHeader extends StatelessWidget {
  const SpendeeBalanceHeader({
    super.key,
    required this.balanceText,
    required this.reservePercent,
    required this.incomeRatio,
    required this.expenseRatio,
    required this.collapseProgress,
    this.surfaceBuilder,
  });

  final String balanceText;
  final int reservePercent;
  final int incomeRatio;
  final int expenseRatio;
  final double collapseProgress;
  final SpendeeBalanceHeaderSurfaceBuilder? surfaceBuilder;

  @override
  Widget build(BuildContext context) {
    final visuals = SpendeeBalanceCollapseVisuals.forProgress(collapseProgress);
    final radius = BorderRadius.circular(SpendeeBalanceVisualSpec.heroRadius);
    final decorated = DecoratedBox(
      key: const ValueKey('spendee-balance-hero-decoration'),
      decoration: BoxDecoration(
        gradient: SpendeeBalanceVisualSpec.heroGradient,
        border: SpendeeBalanceVisualSpec.heroBorder,
        borderRadius: radius,
        boxShadow: SpendeeBalanceVisualSpec.heroShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(top: 35, right: 142, child: _HeroSpeck()),
            const Positioned(top: 88, right: 26, child: _HeroSpeck()),
            const Positioned(top: 113, right: 54, child: _HeroSpeck()),
            Positioned(
              top: 16,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Egyenleg',
                    style: TextStyle(
                      color: Color(0xF0FFFFFF),
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    balanceText,
                    key: const ValueKey('spendee-balance-hero-amount'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: .94,
                      fontWeight: FontWeight.w900,
                      fontVariations: SpendeeBalanceVisualSpec.weight950,
                      shadows: [
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
              bottom: 12,
              left: 20,
              child: Transform.translate(
                offset: Offset(0, visuals.heroStatsTranslateY),
                child: Opacity(
                  key: const ValueKey('spendee-balance-hero-stats-opacity'),
                  opacity: visuals.heroStatsOpacity,
                  child: SizedBox(
                    key: const ValueKey('spendee-balance-hero-stat-grid'),
                    height: 45.2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 108,
                          child: _ReserveStat(
                            key: const ValueKey(
                              'spendee-balance-reserve-stat-track',
                            ),
                            percent: reservePercent,
                          ),
                        ),
                        const SizedBox(
                          key: ValueKey('spendee-balance-hero-divider-track'),
                          width: 1,
                          child: OverflowBox(
                            minWidth: 29,
                            maxWidth: 29,
                            child: Padding(
                              key: ValueKey(
                                'spendee-balance-hero-divider-margin-box',
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: ColoredBox(
                                key: ValueKey('spendee-balance-hero-divider'),
                                color: Color(0x66FFFFFF),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 92,
                          child: _RatioStat(
                            key: const ValueKey(
                              'spendee-balance-ratio-stat-track',
                            ),
                            incomeRatio: incomeRatio,
                            expenseRatio: expenseRatio,
                          ),
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
    );
    final content =
        surfaceBuilder?.call(context, radius, decorated) ?? decorated;
    return SizedBox(
      key: const ValueKey('spendee-balance-hero'),
      width: SpendeeBalanceVisualSpec.contentWidth,
      height: visuals.heroHeight,
      child: content,
    );
  }
}

class _HeroSpeck extends StatelessWidget {
  const _HeroSpeck();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 2,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xD1FFFFFF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ReserveStat extends StatelessWidget {
  const _ReserveStat({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ExactLineText('TARTALÉK', height: 8.2, style: _statLabelStyle),
        const SizedBox(height: 7),
        Row(
          children: [
            _ExactLineText(
              '$percent%',
              height: 17,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
                fontVariations: SpendeeBalanceVisualSpec.weight950,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              key: const ValueKey('spendee-balance-reserve-meter'),
              width: 96,
              height: 5,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: const Color(0x4550389E),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x243E2A80),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0, 1),
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xF0FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatioStat extends StatelessWidget {
  const _RatioStat({
    super.key,
    required this.incomeRatio,
    required this.expenseRatio,
  });

  final int incomeRatio;
  final int expenseRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ExactLineText(
          'BALANCE ARÁNY',
          height: 8.2,
          style: _statLabelStyle,
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RatioValue(
              value: incomeRatio,
              label: 'BEVÉTEL',
              color: const Color(0xFF16C797),
            ),
            const SizedBox(width: 14),
            _RatioValue(
              value: expenseRatio,
              label: 'KIADÁS',
              color: const Color(0xFFF83D77),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatioValue extends StatelessWidget {
  const _RatioValue({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExactLineText(
          '$value%',
          height: 17,
          style: TextStyle(
            color: color,
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w900,
            fontVariations: SpendeeBalanceVisualSpec.weight950,
          ),
        ),
        const SizedBox(height: 6),
        _ExactLineText(
          label,
          height: 7,
          style: const TextStyle(
            color: Color(0xEDFFFFFF),
            fontSize: 7,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExactLineText extends StatelessWidget {
  const _ExactLineText(this.text, {required this.height, required this.style});

  final String text;
  final double height;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, maxLines: 1, style: style),
      ),
    );
  }
}

const _statLabelStyle = TextStyle(
  color: Color(0xEDFFFFFF),
  fontSize: 8.2,
  height: 1,
  fontWeight: FontWeight.w900,
);
