import '../domain/time_plane.dart';

class SummaryPillViewModel {
  const SummaryPillViewModel({
    required this.plane,
    required this.periodLabel,
    required this.planeLabel,
    required this.amountText,
    required this.isRailOpen,
    required this.isLoading,
    required this.hasError,
  });

  final TimePlane plane;
  final String periodLabel;
  final String planeLabel;
  final String amountText;
  final bool isRailOpen;
  final bool isLoading;
  final bool hasError;
}
