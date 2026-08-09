import 'package:flutter/foundation.dart';

import 'dashboard_log_viewport_state.dart';

/// Immutable identity of the temporal payload coverage a prepared scene bank
/// must contain. Presentation plane and ledger direction are deliberately not
/// part of this key: the selector prepares both directions and all next-finer
/// catalogs for the same visible year/month coverage.
@immutable
final class DashboardLogBoxSceneCoverageIdentity {
  const DashboardLogBoxSceneCoverageIdentity({
    required this.coreRevision,
    required this.indexGeneration,
    required this.visibleYear,
    required this.visibleMonth,
  }) : assert(coreRevision >= 0),
       assert(indexGeneration >= 0),
       assert(visibleMonth >= 1 && visibleMonth <= 12);

  final int coreRevision;
  final int indexGeneration;
  final int visibleYear;
  final int visibleMonth;

  String get value =>
      'rev:$coreRevision|index:$indexGeneration|'
      'year:$visibleYear|month:$visibleYear-${visibleMonth.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxSceneCoverageIdentity &&
      other.coreRevision == coreRevision &&
      other.indexGeneration == indexGeneration &&
      other.visibleYear == visibleYear &&
      other.visibleMonth == visibleMonth;

  @override
  int get hashCode =>
      Object.hash(coreRevision, indexGeneration, visibleYear, visibleMonth);

  @override
  String toString() => value;
}

/// Immutable rail-reachable LogBox payload bank for one structural location.
///
/// It contains only already-projected bounded preview payloads. It is not a
/// vertical-list cache and never performs data access or formatting.
@immutable
final class DashboardLogBoxSceneWindow {
  DashboardLogBoxSceneWindow({
    required this.identity,
    required List<DashboardLogViewportState> payloads,
    this.coverageIdentity,
  }) : payloads = List<DashboardLogViewportState>.unmodifiable(payloads) {
    final viewportIds = <int>{};
    for (final payload in this.payloads) {
      if (!viewportIds.add(payload.viewportId)) {
        throw ArgumentError.value(
          payloads,
          'payloads',
          'A scene window cannot contain one viewport twice.',
        );
      }
    }
  }

  final String identity;
  final DashboardLogBoxSceneCoverageIdentity? coverageIdentity;
  final List<DashboardLogViewportState> payloads;

  int get previewRowCount => payloads.fold<int>(
    0,
    (count, payload) => count + payload.flatItems.length,
  );

  int get sceneCount => payloads.length;
}

/// The application coordinator requests this presentation capability after a
/// structural metadata commit. The cache implementation owns the Flutter
/// paragraphs; scene preparation is background maintenance and never an input
/// readiness barrier.
typedef DashboardLogBoxSceneWindowPreparer =
    Future<void> Function(
      DashboardLogBoxSceneWindow window, {
      required int? retainViewportId,
    });

/// Invalidates the current bounded background preparation slice. It does not
/// discard an already active immutable scene bank.
typedef DashboardLogBoxSceneWindowPreparationCanceller = void Function();

/// Presentation-owned frame adapter for entering background scene-window
/// maintenance. The application controller owns generations and cancellation;
/// it never owns a Flutter frame scheduler.
typedef DashboardLogBoxSceneWindowRebaseScheduler =
    void Function(void Function() task);

/// Expected control-flow signal used when a newer scene window supersedes a
/// background slice. It is not a rendering failure and must not be surfaced as
/// an input or navigation error.
final class DashboardLogBoxScenePreparationCancelled implements Exception {
  const DashboardLogBoxScenePreparationCancelled();
}

/// Schedules the next bounded UI-isolate preparation slice. Production uses a
/// post-frame opportunity; component tests may use the deterministic default.
typedef DashboardLogBoxScenePreparationYield = Future<void> Function();

typedef DashboardLogBoxSceneWindowActivator =
    void Function(DashboardLogBoxSceneWindow window);

typedef DashboardLogBoxSceneWindowReporter = Map<String, Object?> Function();
