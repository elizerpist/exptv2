import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_presentation_store.dart';
import 'dashboard_log_performance_diagnostics.dart';
import 'dashboard_log_view_models.dart';

/// Derived LogBox state. It observes the central presentation store but owns
/// no query, navigation, repository, or live-lease lifecycle.
class DashboardLogPresentationAdapter extends ChangeNotifier {
  DashboardLogPresentationAdapter({
    required DashboardPresentationStore store,
    DashboardLogPerformanceDiagnostics? performanceDiagnostics,
    int Function()? motionEpochProvider,
  }) : _store = store,
       _performanceDiagnostics = performanceDiagnostics,
       _motionEpochProvider = motionEpochProvider {
    _store.addListener(_handleStoreChanged);
    _store.addMetadataListener(_handleStoreChanged);
    _reproject();
  }

  final DashboardPresentationStore _store;
  final DashboardLogPerformanceDiagnostics? _performanceDiagnostics;
  final int Function()? _motionEpochProvider;
  DashboardLogViewportState? _state;
  DashboardPresentationSnapshot? _lastProjectedSnapshot;
  int _projectionCount = 0;
  int _listRebindCount = 0;

  DashboardLogViewportState? get state => _state;
  int get projectionCount => _projectionCount;
  int get listRebindCount => _listRebindCount;

  void _handleStoreChanged() => _reproject();

  void _reproject() {
    final lookupStopwatch = Stopwatch()..start();
    final snapshot = _store.activeSnapshot;
    if (snapshot == null) {
      lookupStopwatch.stop();
      return;
    }
    lookupStopwatch.stop();
    final motionEpoch = _motionEpochProvider?.call() ?? 0;
    final rowCount = snapshot.entries.length;
    final dataAttached = rowCount > 0;
    _performanceDiagnostics?.record(
      phase: DashboardLogPerformancePhase.railPreviewLookup,
      queryKey: snapshot.queryKey,
      entryCount: snapshot.entryCount ?? 0,
      rowCount: rowCount,
      dataAttached: dataAttached,
      durationMicros: lookupStopwatch.elapsedMicroseconds,
      motionEpoch: motionEpoch,
    );
    final selectionStopwatch = Stopwatch()..start();
    final previous = _state;
    final lastProjected = _lastProjectedSnapshot;
    if (previous != null &&
        lastProjected != null &&
        lastProjected.hasSameVisualValue(snapshot)) {
      selectionStopwatch.stop();
      _performanceDiagnostics?.record(
        phase: DashboardLogPerformancePhase.logBoxPreviewSelect,
        queryKey: snapshot.queryKey,
        entryCount: snapshot.entryCount ?? 0,
        rowCount: rowCount,
        dataAttached: dataAttached,
        durationMicros: selectionStopwatch.elapsedMicroseconds,
        motionEpoch: motionEpoch,
      );
      final metadata = previous.copyWith(
        queryKey: snapshot.queryKey,
        revision: snapshot.coreRevision,
        entryCount: snapshot.entryCount,
        nextCursor: snapshot.nextCursor,
        clearNextCursor: snapshot.nextCursor == null,
        isPreview: snapshot.isPreview,
        isCommitted: !snapshot.isPreview,
      );
      _lastProjectedSnapshot = snapshot;
      if (_sameMetadata(previous, metadata)) return;
      final bindStopwatch = Stopwatch()..start();
      _state = metadata;
      _performanceDiagnostics?.record(
        phase: DashboardLogPerformancePhase.summaryPreviewBind,
        queryKey: snapshot.queryKey,
        entryCount: snapshot.entryCount ?? 0,
        rowCount: rowCount,
        dataAttached: dataAttached,
        durationMicros: bindStopwatch.elapsedMicroseconds,
        motionEpoch: motionEpoch,
      );
      notifyListeners();
      return;
    }
    selectionStopwatch.stop();
    _performanceDiagnostics?.record(
      phase: DashboardLogPerformancePhase.logBoxPreviewSelect,
      queryKey: snapshot.queryKey,
      entryCount: snapshot.entryCount ?? 0,
      rowCount: rowCount,
      dataAttached: dataAttached,
      durationMicros: selectionStopwatch.elapsedMicroseconds,
      motionEpoch: motionEpoch,
    );
    final projectionStopwatch = Stopwatch()..start();
    final projected = DashboardLogViewModelProjector.presentSnapshot(snapshot);
    projectionStopwatch.stop();
    _projectionCount += 1;
    _lastProjectedSnapshot = snapshot;
    _performanceDiagnostics?.record(
      phase: DashboardLogPerformancePhase.logBoxViewModelProject,
      queryKey: snapshot.queryKey,
      entryCount: snapshot.entryCount ?? 0,
      rowCount: projected.groups.fold<int>(
        0,
        (total, group) => total + group.rows.length,
      ),
      dataAttached: projected.groups.isNotEmpty,
      durationMicros: projectionStopwatch.elapsedMicroseconds,
      motionEpoch: motionEpoch,
    );
    if (previous != null && previous.hasSameVisualValue(projected)) {
      // A preview->committed promotion may alter only paging/provenance. Keep
      // the already projected group/row list instance and update metadata.
      _state = projected.copyWith(groups: previous.groups);
      if (_state!.isPreview == previous.isPreview &&
          _state!.nextCursor == previous.nextCursor) {
        return;
      }
      final bindStopwatch = Stopwatch()..start();
      _performanceDiagnostics?.record(
        phase: DashboardLogPerformancePhase.summaryPreviewBind,
        queryKey: snapshot.queryKey,
        entryCount: snapshot.entryCount ?? 0,
        rowCount: rowCount,
        dataAttached: dataAttached,
        durationMicros: bindStopwatch.elapsedMicroseconds,
        motionEpoch: motionEpoch,
      );
      notifyListeners();
      return;
    }
    _listRebindCount += 1;
    final bindStopwatch = Stopwatch()..start();
    _state = projected;
    _performanceDiagnostics?.record(
      phase: DashboardLogPerformancePhase.summaryPreviewBind,
      queryKey: snapshot.queryKey,
      entryCount: snapshot.entryCount ?? 0,
      rowCount: rowCount,
      dataAttached: dataAttached,
      durationMicros: bindStopwatch.elapsedMicroseconds,
      motionEpoch: motionEpoch,
    );
    notifyListeners();
  }

  static bool _sameMetadata(
    DashboardLogViewportState left,
    DashboardLogViewportState right,
  ) =>
      left.queryKey == right.queryKey &&
      left.revision == right.revision &&
      left.entryCount == right.entryCount &&
      mapEquals(left.nextCursor, right.nextCursor) &&
      left.isPreview == right.isPreview &&
      left.isCommitted == right.isCommitted &&
      left.direction == right.direction;

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    _store.removeMetadataListener(_handleStoreChanged);
    super.dispose();
  }
}
