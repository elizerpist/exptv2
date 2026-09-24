import '../../application/dashboard_balance_category_movers_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// Shared render-only labels for the immutable Movers payload. No formatter
/// here has access to ledger, Query, current time, or a widget state owner.
String balanceCategoryMoverPercentageLabel(
  DashboardBalanceCategoryMover mover,
) {
  if (mover.isNew) return 'New';
  final basisPoints = mover.percentageBasisPoints;
  if (basisPoints == null) return '0%';
  final rounded = (basisPoints / 100).round();
  return '${rounded > 0 ? '+' : ''}$rounded%';
}

String balanceCategoryMoverSignedAmountLabel(int amountMinor) =>
    '${amountMinor < 0 ? '-' : '+'}'
    '${DashboardPreparedFormatter.amountMinor(amountMinor.abs())}';

String balanceCategoryMoverComparisonLabel(
  DashboardBalanceCategoryMoversPresentation presentation,
) =>
    '${presentation.currentWindow.startInclusive.isoString} – '
    '${presentation.currentWindow.endInclusive.isoString} vs '
    '${presentation.referenceWindow.startInclusive.isoString} – '
    '${presentation.referenceWindow.endInclusive.isoString}';

String balanceCategoryMoverCompactComparisonLabel(
  DashboardBalanceCategoryMoversPresentation presentation,
) =>
    '${presentation.currentWindow.startInclusive.isoString} vs '
    '${presentation.referenceWindow.startInclusive.isoString}';
