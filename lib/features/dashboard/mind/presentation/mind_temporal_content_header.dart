import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';

/// The one shared header envelope for every temporal Mind content card.
///
/// Individual views may render different charts below it, but title,
/// supporting text and optional actions retain this fixed measure and baseline.
const mindTemporalContentHeaderHeight = 34.0;

final class MindTemporalContentHeader extends StatelessWidget {
  const MindTemporalContentHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleKey,
    this.subtitleKey,
    this.trailing,
    this.trailingTitle,
    this.trailingSubtitle,
    this.trailingTitleKey,
    this.trailingSubtitleKey,
  });

  final String title;
  final String subtitle;
  final Key? titleKey;
  final Key? subtitleKey;
  final Widget? trailing;
  final String? trailingTitle;
  final String? trailingSubtitle;
  final Key? trailingTitleKey;
  final Key? trailingSubtitleKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: mindTemporalContentHeaderHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                key: titleKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 11,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                key: subtitleKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 8,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null || trailingTitle != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing ??
              _MindTemporalHeaderTrailingLines(
                title: trailingTitle!,
                subtitle: trailingSubtitle,
                titleKey: trailingTitleKey,
                subtitleKey: trailingSubtitleKey,
              ),
        ],
      ],
    ),
  );
}

final class _MindTemporalHeaderTrailingLines extends StatelessWidget {
  const _MindTemporalHeaderTrailingLines({
    required this.title,
    this.subtitle,
    this.titleKey,
    this.subtitleKey,
  });

  final String title;
  final String? subtitle;
  final Key? titleKey;
  final Key? subtitleKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      SizedBox(
        height: 11.55,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            title,
            key: titleKey,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      SizedBox(
        height: 8.4,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            subtitle ?? '',
            key: subtitleKey,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 8,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

/// One global, scope-level counter for real calendar days with no activity in
/// Mind's current resident amount-range frame. It deliberately shares the
/// temporal header’s small right-aligned typography, rather than making a
/// competing card or a per-year SUM label.
final class MindNoSpendDaysHeaderMetric extends StatelessWidget {
  const MindNoSpendDaysHeaderMetric({
    super.key,
    required this.noSpendDayCount,
    this.keyPrefix = 'mind-no-spend-days',
  });

  final int noSpendDayCount;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => _MindTemporalHeaderTrailingLines(
    title: 'Költésmentes',
    subtitle: '$noSpendDayCount nap',
    titleKey: ValueKey<String>('$keyPrefix-title'),
    subtitleKey: ValueKey<String>('$keyPrefix-value'),
  );
}
