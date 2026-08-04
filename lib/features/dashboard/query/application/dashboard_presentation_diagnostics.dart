import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../domain/current_ledger_query_scope.dart';

/// Why a snapshot is visible at this moment. This is deliberately separate
/// from [DashboardDataOrigin]: a fresh result may be cached and later shown as
/// a rail preview.
enum DashboardPresentationMode { preview, committed }

/// Where the immutable data in a visible snapshot came from.
enum DashboardDataOrigin {
  childPreviewIndex,
  childPreviewBundle,
  memoryCache,
  persistentCache,
  freshQuery,
  liveObserver,
}

enum DashboardPreviewActivity { drag, ballistic, tap, programmatic }

enum DashboardPresentationDiagnosticKind {
  railChildCrossed,
  previewSnapshotSelected,
  previewPresentationPublished,
  parentPreviewSnapshotSelected,
  parentPreviewPresentationPublished,
  previewFramePresented,
  settlePromoted,
}

/// Scheduler abstraction keeps frame-boundary diagnostics deterministic in
/// unit tests and lets the production implementation use Flutter's frame
/// scheduler without making the rail motion engine depend on it.
abstract interface class DashboardFrameScheduler {
  void schedule(VoidCallback callback);
}

class _FlutterDashboardFrameScheduler implements DashboardFrameScheduler {
  const _FlutterDashboardFrameScheduler();

  @override
  void schedule(VoidCallback callback) {
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) => callback());
    } on Object {
      // Plain Dart controller tests do not install a Flutter binding. The
      // production/widget path still uses the real end-of-frame callback.
      callback();
    }
  }
}

@immutable
class DashboardPresentationDiagnosticEvent {
  const DashboardPresentationDiagnosticEvent({
    required this.kind,
    required this.queryKey,
    this.interactionEpoch = 0,
    this.presentationGeneration = 0,
    this.semanticChild,
    this.frameNumber,
    this.activity,
    this.amount,
    this.entryCount,
    this.logGroupCount,
    this.logRowCount,
    this.logDigest,
    this.contentDigest,
    this.presentationMode,
    this.dataOrigin,
    this.cacheHit,
    this.visualChange,
    this.amountRebound,
    this.countRebound,
    this.logRebound,
  });

  final DashboardPresentationDiagnosticKind kind;
  final LedgerQueryKey queryKey;
  final int interactionEpoch;
  final int presentationGeneration;
  final int? semanticChild;
  final int? frameNumber;
  final DashboardPreviewActivity? activity;
  final int? amount;
  final int? entryCount;
  final int? logGroupCount;
  final int? logRowCount;
  final int? logDigest;
  final int? contentDigest;
  final DashboardPresentationMode? presentationMode;
  final DashboardDataOrigin? dataOrigin;
  final bool? cacheHit;
  final bool? visualChange;
  final bool? amountRebound;
  final bool? countRebound;
  final bool? logRebound;
}

/// Compact, bounded diagnostics for the motion-to-presentation lane.
///
/// The class stores typed values only. Existing verbose FLOW logging remains a
/// separate optional compatibility channel and is not extended from the rail
/// hot path.
class DashboardPresentationDiagnostics {
  DashboardPresentationDiagnostics({
    int capacity = 256,
    DashboardFrameScheduler? frameScheduler,
    int Function()? frameNumber,
  }) : assert(capacity > 0),
       _capacity = capacity,
       _frameScheduler =
           frameScheduler ?? const _FlutterDashboardFrameScheduler(),
       _frameNumber = frameNumber ?? _defaultDiagnosticFrameNumber;

  final int _capacity;
  final DashboardFrameScheduler _frameScheduler;
  final int Function() _frameNumber;
  final ListQueue<DashboardPresentationDiagnosticEvent> _events =
      ListQueue<DashboardPresentationDiagnosticEvent>();

  int _railChildCrossedCount = 0;
  int _previewSnapshotSelectedCount = 0;
  int _previewPresentationPublishedCount = 0;
  int _parentPreviewSnapshotSelectedCount = 0;
  int _parentPreviewPresentationPublishedCount = 0;
  int _previewFramePresentedCount = 0;
  int _previewFrameCoalescedCount = 0;
  int _pendingFrameGeneration = 0;
  LedgerQueryKey? _pendingFrameQueryKey;
  int? _pendingFrameLogDigest;
  bool _frameCallbackPending = false;

  int get railChildCrossedCount => _railChildCrossedCount;
  int get previewSnapshotSelectedCount => _previewSnapshotSelectedCount;
  int get previewPresentationPublishedCount =>
      _previewPresentationPublishedCount;
  int get parentPreviewSnapshotSelectedCount =>
      _parentPreviewSnapshotSelectedCount;
  int get parentPreviewPresentationPublishedCount =>
      _parentPreviewPresentationPublishedCount;
  int get previewFramePresentedCount => _previewFramePresentedCount;
  int get previewFrameCoalescedCount => _previewFrameCoalescedCount;
  int get currentFrameNumber => _frameNumber();
  List<DashboardPresentationDiagnosticEvent> get events =>
      List<DashboardPresentationDiagnosticEvent>.unmodifiable(_events);

  void recordRailChildCrossed({
    required int interactionEpoch,
    required int semanticChild,
    required LedgerQueryKey queryKey,
    required DashboardPreviewActivity activity,
    required int frameNumber,
  }) {
    _railChildCrossedCount += 1;
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: DashboardPresentationDiagnosticKind.railChildCrossed,
        interactionEpoch: interactionEpoch,
        semanticChild: semanticChild,
        queryKey: queryKey,
        activity: activity,
        frameNumber: frameNumber,
      ),
    );
  }

  void recordPreviewSnapshotSelected({
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required int amount,
    required int entryCount,
    required int logGroupCount,
    required int logRowCount,
    required int contentDigest,
    required DashboardDataOrigin dataOrigin,
    required bool cacheHit,
  }) {
    _previewSnapshotSelectedCount += 1;
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: DashboardPresentationDiagnosticKind.previewSnapshotSelected,
        interactionEpoch: interactionEpoch,
        presentationGeneration: presentationGeneration,
        queryKey: queryKey,
        amount: amount,
        entryCount: entryCount,
        logGroupCount: logGroupCount,
        logRowCount: logRowCount,
        contentDigest: contentDigest,
        dataOrigin: dataOrigin,
        cacheHit: cacheHit,
      ),
    );
  }

  void recordPreviewPresentationPublished({
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required int amount,
    required int entryCount,
    required int logDigest,
    required DashboardPresentationMode presentationMode,
  }) {
    _previewPresentationPublishedCount += 1;
    _recordPreviewFrame(
      kind: DashboardPresentationDiagnosticKind.previewPresentationPublished,
      interactionEpoch: interactionEpoch,
      presentationGeneration: presentationGeneration,
      queryKey: queryKey,
      amount: amount,
      entryCount: entryCount,
      logDigest: logDigest,
      presentationMode: presentationMode,
    );
  }

  void recordParentPreviewSnapshotSelected({
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required int amount,
    required int entryCount,
    required int logGroupCount,
    required int logRowCount,
    required int contentDigest,
    required DashboardDataOrigin dataOrigin,
    required bool cacheHit,
  }) {
    _parentPreviewSnapshotSelectedCount += 1;
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: DashboardPresentationDiagnosticKind.parentPreviewSnapshotSelected,
        interactionEpoch: interactionEpoch,
        presentationGeneration: presentationGeneration,
        queryKey: queryKey,
        amount: amount,
        entryCount: entryCount,
        logGroupCount: logGroupCount,
        logRowCount: logRowCount,
        contentDigest: contentDigest,
        dataOrigin: dataOrigin,
        cacheHit: cacheHit,
      ),
    );
  }

  void recordParentPreviewPresentationPublished({
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required int amount,
    required int entryCount,
    required int logDigest,
  }) {
    _parentPreviewPresentationPublishedCount += 1;
    _recordPreviewFrame(
      kind: DashboardPresentationDiagnosticKind
          .parentPreviewPresentationPublished,
      interactionEpoch: interactionEpoch,
      presentationGeneration: presentationGeneration,
      queryKey: queryKey,
      amount: amount,
      entryCount: entryCount,
      logDigest: logDigest,
      presentationMode: DashboardPresentationMode.preview,
    );
  }

  void _recordPreviewFrame({
    required DashboardPresentationDiagnosticKind kind,
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required int amount,
    required int entryCount,
    required int logDigest,
    required DashboardPresentationMode presentationMode,
  }) {
    _pendingFrameGeneration = presentationGeneration;
    _pendingFrameQueryKey = queryKey;
    _pendingFrameLogDigest = logDigest;
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: kind,
        interactionEpoch: interactionEpoch,
        presentationGeneration: presentationGeneration,
        queryKey: queryKey,
        amount: amount,
        entryCount: entryCount,
        logDigest: logDigest,
        presentationMode: presentationMode,
      ),
    );
    if (_frameCallbackPending) {
      _previewFrameCoalescedCount += 1;
      return;
    }
    _frameCallbackPending = true;
    _frameScheduler.schedule(_recordPendingFrame);
  }

  void recordSettlePromoted({
    required int interactionEpoch,
    required int presentationGeneration,
    required LedgerQueryKey queryKey,
    required bool visualChange,
    required bool amountRebound,
    required bool countRebound,
    required bool logRebound,
  }) {
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: DashboardPresentationDiagnosticKind.settlePromoted,
        interactionEpoch: interactionEpoch,
        presentationGeneration: presentationGeneration,
        queryKey: queryKey,
        visualChange: visualChange,
        amountRebound: amountRebound,
        countRebound: countRebound,
        logRebound: logRebound,
      ),
    );
  }

  void _recordPendingFrame() {
    _frameCallbackPending = false;
    final queryKey = _pendingFrameQueryKey;
    if (queryKey == null) return;
    _previewFramePresentedCount += 1;
    _add(
      DashboardPresentationDiagnosticEvent(
        kind: DashboardPresentationDiagnosticKind.previewFramePresented,
        presentationGeneration: _pendingFrameGeneration,
        queryKey: queryKey,
        frameNumber: _frameNumber(),
        logDigest: _pendingFrameLogDigest,
        presentationMode: DashboardPresentationMode.preview,
      ),
    );
  }

  void _add(DashboardPresentationDiagnosticEvent event) {
    _events.addLast(event);
    while (_events.length > _capacity) {
      _events.removeFirst();
    }
  }
}

int _diagnosticFallbackFrameNumber = 0;

int _defaultDiagnosticFrameNumber() {
  try {
    return SchedulerBinding.instance.currentFrameTimeStamp.inMicroseconds;
  } on Object {
    _diagnosticFallbackFrameNumber += 1;
    return _diagnosticFallbackFrameNumber;
  }
}
