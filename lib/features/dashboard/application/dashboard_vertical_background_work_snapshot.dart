import 'package:flutter/foundation.dart';

/// Read-only vertical diagnostic snapshot.
///
/// The dashboard core assembles speculative state while the explicit paging
/// owner reports its exact request/data/presentation stages; neither gains
/// ownership of the other's lifecycle.
@immutable
final class DashboardVerticalBackgroundWorkSnapshot {
  const DashboardVerticalBackgroundWorkSnapshot({
    required this.sceneSpeculationActive,
    required this.querySpeculationActive,
    required this.committedPageRequestInFlight,
    required this.committedPageDataPendingPresentation,
    required this.committedPagePresentationActive,
    required this.committedPageReadsStarted,
    required this.committedPageReadsCompleted,
    required this.committedPagesCommitted,
    this.deferredPresentationOrdinal,
  });

  final bool sceneSpeculationActive;
  final bool querySpeculationActive;
  final bool committedPageRequestInFlight;
  final bool committedPageDataPendingPresentation;
  final bool committedPagePresentationActive;
  final int committedPageReadsStarted;
  final int committedPageReadsCompleted;
  final int committedPagesCommitted;
  final int? deferredPresentationOrdinal;

  bool get anyActive =>
      sceneSpeculationActive ||
      querySpeculationActive ||
      committedPageRequestInFlight ||
      committedPageDataPendingPresentation ||
      committedPagePresentationActive;
}
