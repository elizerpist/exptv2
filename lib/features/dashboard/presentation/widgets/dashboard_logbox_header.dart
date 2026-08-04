import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';

/// Paint-only upper edge of the future dashboard LogBox.
///
/// The count stays on the shared summary metrics presentation path, so a
/// child-rail preview can render immediately without creating a detailed
/// query, list, or secondary state owner.
class DashboardLogBoxHeader extends StatefulWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.metricsListenable,
    required this.metricsPresentationBuilder,
  });

  final DashboardBounds bounds;
  final Listenable metricsListenable;
  final SummaryMetricsPresentation Function() metricsPresentationBuilder;

  @override
  State<DashboardLogBoxHeader> createState() => _DashboardLogBoxHeaderState();
}

class _DashboardLogBoxHeaderState extends State<DashboardLogBoxHeader> {
  String? _lastLoggedPresentationKey;

  @override
  void initState() {
    super.initState();
    widget.metricsListenable.addListener(_handleMetricsPresentationChanged);
    _logPresentationIfChanged();
  }

  @override
  void didUpdateWidget(covariant DashboardLogBoxHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metricsListenable == widget.metricsListenable) return;
    oldWidget.metricsListenable.removeListener(
      _handleMetricsPresentationChanged,
    );
    _lastLoggedPresentationKey = null;
    widget.metricsListenable.addListener(_handleMetricsPresentationChanged);
    _logPresentationIfChanged();
  }

  @override
  void dispose() {
    widget.metricsListenable.removeListener(_handleMetricsPresentationChanged);
    super.dispose();
  }

  void _handleMetricsPresentationChanged() => _logPresentationIfChanged();

  void _logPresentationIfChanged() {
    final presentation = widget.metricsPresentationBuilder();
    if (presentation.isPreview && !DashboardQueryDebug.tracePreviewMetrics) {
      return;
    }
    final key = <Object?>[
      presentation.flowId,
      presentation.scopeKey,
      presentation.coreRevision,
      presentation.entryCount,
      presentation.isPreview,
      presentation.isLoading,
      presentation.isStale,
      presentation.hasError,
    ].join('|');
    if (key == _lastLoggedPresentationKey) return;
    _lastLoggedPresentationKey = key;
    DashboardQueryDebug.mark(
      'D11 LOG_BOX_ENTRY_COUNT_BOUND',
      flowId: presentation.flowId,
      queryKey: presentation.scopeKey,
      coreRevision: presentation.coreRevision,
      entryCount: presentation.entryCount,
      isStale: presentation.isStale,
      detail:
          'source=summaryMetricsPresentation '
          'metricsSource=${presentation.source.name} '
          'preview=${presentation.isPreview} '
          'loading=${presentation.isLoading} '
          'stale=${presentation.isStale} '
          'error=${presentation.hasError}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-header-repaint-boundary'),
      child: SizedBox(
        key: const ValueKey('dashboard-logbox-header'),
        width: widget.bounds.width,
        height: widget.bounds.height,
        child: ListenableBuilder(
          listenable: widget.metricsListenable,
          builder: (context, _) {
            final entryCount = widget
                .metricsPresentationBuilder()
                .formattedEntryCount;
            return Center(
              child: Text(
                '$entryCount tranzakció listázva',
                key: const ValueKey('dashboard-logbox-entry-count'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FluviVisualTokens.logBoxHeaderTextStyle,
              ),
            );
          },
        ),
      ),
    );
  }
}
