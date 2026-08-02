import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../time_navigation/presentation/summary_amount_presentation.dart';

/// Paint-only upper edge of the future dashboard LogBox.
///
/// The count stays on the existing summary amount presentation path, so a
/// child-rail preview can render immediately without creating a detailed
/// query, list, or secondary state owner.
class DashboardLogBoxHeader extends StatefulWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.amountListenable,
    required this.amountPresentationBuilder,
  });

  final DashboardBounds bounds;
  final Listenable amountListenable;
  final SummaryAmountPresentation Function() amountPresentationBuilder;

  @override
  State<DashboardLogBoxHeader> createState() => _DashboardLogBoxHeaderState();
}

class _DashboardLogBoxHeaderState extends State<DashboardLogBoxHeader> {
  String? _lastLoggedPresentationKey;

  @override
  void initState() {
    super.initState();
    widget.amountListenable.addListener(_handleAmountPresentationChanged);
    _logPresentationIfChanged();
  }

  @override
  void didUpdateWidget(covariant DashboardLogBoxHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amountListenable == widget.amountListenable) return;
    oldWidget.amountListenable.removeListener(_handleAmountPresentationChanged);
    _lastLoggedPresentationKey = null;
    widget.amountListenable.addListener(_handleAmountPresentationChanged);
    _logPresentationIfChanged();
  }

  @override
  void dispose() {
    widget.amountListenable.removeListener(_handleAmountPresentationChanged);
    super.dispose();
  }

  void _handleAmountPresentationChanged() => _logPresentationIfChanged();

  void _logPresentationIfChanged() {
    final presentation = widget.amountPresentationBuilder();
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
          'source=summaryAmountPresentation '
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
          listenable: widget.amountListenable,
          builder: (context, _) {
            final entryCount = widget.amountPresentationBuilder().entryCount;
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
