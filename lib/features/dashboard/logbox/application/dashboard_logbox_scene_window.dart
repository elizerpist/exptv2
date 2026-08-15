import 'package:flutter/foundation.dart';

import 'dashboard_log_viewport_state.dart';

/// Immutable identity of the exact structural payload coverage a prepared
/// scene bank must contain. A complete bank may contain both directions and
/// neighbouring plane catalogs, but a Query publication bank is deliberately
/// smaller. Its coverage must therefore include the canonical parent scope so
/// identical year/month coordinates never equate income, expense or distinct
/// applied Query payload sets.
@immutable
final class DashboardLogBoxSceneCoverageIdentity {
  const DashboardLogBoxSceneCoverageIdentity({
    required this.coreRevision,
    required this.indexGeneration,
    required this.visibleYear,
    required this.visibleMonth,
    required this.parentQueryKey,
  }) : assert(coreRevision >= 0),
       assert(indexGeneration >= 0),
       assert(visibleMonth >= 1 && visibleMonth <= 12);

  final int coreRevision;
  final int indexGeneration;
  final int visibleYear;
  final int visibleMonth;
  final String parentQueryKey;

  String get value =>
      'rev:$coreRevision|index:$indexGeneration|'
      'year:$visibleYear|month:$visibleYear-${visibleMonth.toString().padLeft(2, '0')}|'
      'parent:$parentQueryKey';

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxSceneCoverageIdentity &&
      other.coreRevision == coreRevision &&
      other.indexGeneration == indexGeneration &&
      other.visibleYear == visibleYear &&
      other.visibleMonth == visibleMonth &&
      other.parentQueryKey == parentQueryKey;

  @override
  int get hashCode => Object.hash(
    coreRevision,
    indexGeneration,
    visibleYear,
    visibleMonth,
    parentQueryKey,
  );

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
    final queryKeys = <String>{};
    for (final payload in this.payloads) {
      if (!queryKeys.add(payload.queryKey.value)) {
        throw ArgumentError.value(
          payloads,
          'payloads',
          'A scene window cannot contain one query twice.',
        );
      }
    }
  }

  final String identity;
  final DashboardLogBoxSceneCoverageIdentity? coverageIdentity;
  final List<DashboardLogViewportState> payloads;

  int get previewRowCount => payloads.fold<int>(
    0,
    (count, payload) => count + payload.previewRowCount,
  );

  int get sceneCount => payloads.length;

  /// Keeps the complete payload bank immutable while attaching controller-only
  /// locality diagnostics. Coverage is never part of rail render ownership.
  DashboardLogBoxSceneWindow withCoverage(
    DashboardLogBoxSceneCoverageIdentity? nextCoverage,
  ) {
    if (coverageIdentity == nextCoverage) return this;
    return DashboardLogBoxSceneWindow(
      identity: identity,
      coverageIdentity: nextCoverage,
      payloads: payloads,
    );
  }

  /// Combines two immutable requirements from the same prepared index without
  /// duplicating cyclic rail occurrences. This lets background interaction
  /// warmup also retain a tiny next-structural publication target while the
  /// currently visible window remains fully drawable.
  DashboardLogBoxSceneWindow union(
    DashboardLogBoxSceneWindow other, {
    DashboardLogBoxSceneCoverageIdentity? coverageIdentity,
  }) {
    if (identity != other.identity) {
      throw ArgumentError(
        'Only scene windows from the same immutable bank may be combined.',
      );
    }
    final combined = <String, DashboardLogViewportState>{
      for (final payload in payloads) payload.queryKey.value: payload,
      for (final payload in other.payloads) payload.queryKey.value: payload,
    };
    return DashboardLogBoxSceneWindow(
      identity: identity,
      coverageIdentity: coverageIdentity ?? this.coverageIdentity,
      payloads:
          (combined.values.toList()..sort(
                (left, right) =>
                    left.queryKey.value.compareTo(right.queryKey.value),
              ))
              .toList(growable: false),
    );
  }
}

/// Immutable proof that a scene bank is safe to publish to the renderer.
///
/// A staging bank may be slow or superseded, but it cannot become ready unless
/// every required scene and text-layout entry is present for one exact surface.
@immutable
final class DashboardLogBoxSceneWindowManifest {
  const DashboardLogBoxSceneWindowManifest({
    required this.requiredSceneCount,
    required this.completeSceneCount,
    required this.requiredTextLayoutCount,
    required this.completeTextLayoutCount,
    required this.generation,
    required this.coreRevision,
    required this.surfaceWidth,
    required this.devicePixelRatio,
  }) : assert(requiredSceneCount >= 0),
       assert(completeSceneCount >= 0),
       assert(requiredTextLayoutCount >= 0),
       assert(completeTextLayoutCount >= 0),
       assert(generation >= 0),
       assert(coreRevision >= 0),
       assert(surfaceWidth > 0),
       assert(devicePixelRatio > 0);

  final int requiredSceneCount;
  final int completeSceneCount;
  final int requiredTextLayoutCount;
  final int completeTextLayoutCount;
  final int generation;
  final int coreRevision;
  final double surfaceWidth;
  final double devicePixelRatio;

  int get missingSceneCount => requiredSceneCount - completeSceneCount;
  int get missingTextLayoutCount =>
      requiredTextLayoutCount - completeTextLayoutCount;
  bool get isComplete =>
      completeSceneCount == requiredSceneCount &&
      completeTextLayoutCount == requiredTextLayoutCount &&
      missingSceneCount == 0 &&
      missingTextLayoutCount == 0;

  Map<String, Object?> toReportMap() => <String, Object?>{
    'requiredSceneCount': requiredSceneCount,
    'completeSceneCount': completeSceneCount,
    'requiredTextLayoutCount': requiredTextLayoutCount,
    'completeTextLayoutCount': completeTextLayoutCount,
    'missingSceneCount': missingSceneCount,
    'missingTextLayoutCount': missingTextLayoutCount,
    'generation': generation,
    'coreRevision': coreRevision,
    'surfaceWidth': surfaceWidth,
    'devicePixelRatio': devicePixelRatio,
    'isComplete': isComplete,
  };
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

/// Stages a small, immutable Query candidate window in the existing scene
/// cache without replacing the currently active renderer bank.  Candidate
/// keys are controller-owned and revision-scoped; this is a cache capability,
/// not another render/state owner.
typedef DashboardLogBoxCandidateSceneWindowPreparer =
    Future<void> Function(
      DashboardLogBoxSceneWindow window, {
      required String candidateKey,
      required int? retainViewportId,
    });

/// Releases one invisible Query candidate bank when its draft/session/cache
/// entry is discarded.  It never touches the active renderer bank.
typedef DashboardLogBoxCandidateSceneWindowDiscarder =
    void Function(String candidateKey);

/// Verifies that an invisible candidate still owns the exact complete bank it
/// advertised when preparation finished. Retention is bounded, so a candidate
/// model may outlive its cache bank after LRU eviction; Apply must re-stage in
/// that case instead of attempting a partial activation.
typedef DashboardLogBoxCandidateSceneWindowLookup =
    bool Function(
      DashboardLogBoxSceneWindow window, {
      required String candidateKey,
    });

/// Updates the exact invisible candidate-bank keys protected as the applied
/// query's one-action chip-removal hotset. The scene cache remains the sole
/// resource owner; the controller supplies only immutable identity policy.
typedef DashboardLogBoxCandidateSceneWindowHotsetSetter =
    void Function(Set<String> candidateKeys);

typedef DashboardLogBoxRetainedSceneWindowPreparer =
    Future<void> Function(
      DashboardLogBoxSceneWindow window, {
      required String retainedKey,
      required int? retainViewportId,
    });

typedef DashboardLogBoxRetainedSceneWindowLookup =
    bool Function(DashboardLogBoxSceneWindow window);

/// Captures the current complete active bank as the one authoritative base
/// restoration target for an ephemeral focus session. The cache keeps the
/// resource ownership; the controller supplies the lifetime identity only.
typedef DashboardLogBoxActiveSceneWindowRetainer =
    bool Function(
      DashboardLogBoxSceneWindow window, {
      required String retainedKey,
    });

/// Releases the focus-base bank when its exact base identity is superseded.
typedef DashboardLogBoxRetainedFocusSceneWindowDiscarder =
    void Function(String retainedKey);

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
