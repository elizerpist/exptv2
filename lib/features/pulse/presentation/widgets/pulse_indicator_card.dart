import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../domain/pulse_models.dart';
import 'pulse_charts.dart';

class PulseIndicatorCard extends StatelessWidget {
  const PulseIndicatorCard({super.key, required this.indicator, required this.onTap});
  final PulseIndicatorSnapshot indicator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${indicator.title}, ${indicator.summary}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            key: ValueKey('pulse-card-${indicator.id}'),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FluviVisualTokens.border.withValues(alpha: .75)),
              boxShadow: FluviVisualTokens.cardSurfaceShadows,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IndicatorIcon(kind: indicator.chartKind),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(indicator.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatValue(indicator), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(height: 64, width: double.infinity, child: pulseChartFor(indicator, PulseChartSize.compact)),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(child: Text(indicator.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)))),
                    if (indicator.availability != PulseAvailability.available)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.info_outline, size: 17, color: Color(0xFF7A8492)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicatorIcon extends StatelessWidget {
  const _IndicatorIcon({required this.kind});
  final PulseChartKind kind;
  @override
  Widget build(BuildContext context) => Container(
    width: 29,
    height: 29,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), shape: BoxShape.circle),
    child: Icon(switch (kind) {
      PulseChartKind.arcGauge => Icons.speed_outlined,
      PulseChartKind.thresholdBar => Icons.view_stream_outlined,
      PulseChartKind.trend => Icons.show_chart,
      PulseChartKind.forecast => Icons.timeline_outlined,
      PulseChartKind.ratio => Icons.pie_chart_outline,
      PulseChartKind.timeline => Icons.more_time_outlined,
    }, size: 17, color: Theme.of(context).colorScheme.primary),
  );
}

String pulseFormatValue(PulseIndicatorSnapshot indicator) => _formatValue(indicator);

String _formatValue(PulseIndicatorSnapshot indicator) {
  final value = indicator.value;
  if (value == null) return '—';
  return switch (indicator.unit) {
    PulseUnit.currency => '${(value / 100).round()} Ft',
    PulseUnit.percent => '${value.toStringAsFixed(value.abs() >= 100 ? 0 : 1)}%',
    PulseUnit.ratio => '${value.toStringAsFixed(2)}×',
    PulseUnit.days => '${value.round()} nap',
    PulseUnit.count => '${value.round()} db',
  };
}
