import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_logbox_presentation_binding.dart';
import '../domain/dashboard_visible_frame.dart';

@immutable
final class DashboardVisibleFramePublishMetrics {
  const DashboardVisibleFramePublishMetrics({
    required this.published,
    required this.equalityMicros,
    required this.notifierMicros,
  });

  final bool published;
  final int equalityMicros;
  final int notifierMicros;
}

typedef DashboardVisibleFramePublishObserver =
    void Function(DashboardVisibleFramePublishMetrics metrics);

/// State of the narrow Mind preview while its one canonical Query commit is
/// reconciling.  The preview remains authoritative until a committed frame
/// proves the same complete projection; a matching query key alone is not
/// enough because it can still carry different rows or totals.
enum DashboardInteractionPreviewReconciliationState {
  idle,
  awaitingCanonical,
  reconciledExact,
  retainedMismatch,
}

/// Sole notifier for the complete visible dashboard presentation snapshot.
///
/// Every [value] contains amount, count and LogBox data for one exact
/// QueryKey/revision. The SummaryPill's amount lane may additionally receive
/// a prepared ephemeral-focus preview before its complete LogBox scene is
/// ready. That narrow publication never mutates [value], count or LogBox
/// lanes, so the stable viewport retains its atomic scene boundary.
final class DashboardVisibleFrameStore extends ChangeNotifier
    implements ValueListenable<DashboardVisibleFrame?> {
  DashboardVisibleFrame? _value;
  int _generationCursor = 0;
  final _navigationLane = _DashboardPresentationLane();
  final _amountLane = _DashboardPresentationLane();
  final _countLane = _DashboardPresentationLane();
  final _logBoxLane = _DashboardPresentationLane();
  final _logBoxPresentationLane = _DashboardLogBoxPresentationLane();

  @override
  DashboardVisibleFrame? get value => _value;

  ValueListenable<DashboardVisibleFrame?> get navigationLane => _navigationLane;
  ValueListenable<DashboardVisibleFrame?> get amountLane => _amountLane;
  ValueListenable<DashboardVisibleFrame?> get countLane => _countLane;
  ValueListenable<DashboardVisibleFrame?> get logBoxLane => _logBoxLane;
  ValueListenable<DashboardLogBoxPresentationBinding?>
  get logBoxPresentationLane => _logBoxPresentationLane;

  int visiblePublishCount = 0;
  int staleFrameRejectCount = 0;
  int visualNoOpCount = 0;
  int committedPromotionCount = 0;
  int logBoxPayloadNotifyCount = 0;
  int logBoxPresentationMetaNotifyCount = 0;
  int amountPreviewPublishCount = 0;
  int staleAmountPreviewRejectCount = 0;
  int _amountPreviewGeneration = 0;
  int interactionPreviewPublishCount = 0;
  int staleInteractionPreviewRejectCount = 0;
  int interactionPreviewCanonicalReconcileCount = 0;
  int interactionPreviewCanonicalMismatchRetainCount = 0;
  int mixedProjectionCount = 0;
  int _interactionPreviewGeneration = 0;
  DashboardVisibleFrame? _interactionPreviewFrame;
  DashboardInteractionPreviewReconciliationState
  interactionPreviewReconciliationState =
      DashboardInteractionPreviewReconciliationState.idle;

  /// These remain explicit proof counters: neither operation belongs here.
  int logRebindCount = 0;
  int amountRestartCount = 0;

  /// Issues the one process-local ordering token shared by prepared previews
  /// and committed-live frames.
  ///
  /// Keeping allocation beside the sole visible-frame store prevents two
  /// publishers from independently producing the same generation and making
  /// a newer semantic target look stale.
  int nextFrameGeneration() {
    final visibleGeneration = _value?.frameGeneration ?? 0;
    if (_generationCursor < visibleGeneration) {
      _generationCursor = visibleGeneration;
    }
    _generationCursor += 1;
    return _generationCursor;
  }

  /// Publishes a scalar SummaryPill preview from an already-derived focus
  /// frame without rotating the complete LogBox scene. [previewGeneration]
  /// is allocated by the Core focus owner; an older asynchronous focus result
  /// can therefore never replace a newer avatar tick's amount.
  bool publishPreparedAmountPreview(
    DashboardVisibleFrame frame, {
    required int previewGeneration,
  }) {
    if (previewGeneration < _amountPreviewGeneration) {
      staleAmountPreviewRejectCount += 1;
      return false;
    }
    if (previewGeneration == _amountPreviewGeneration &&
        _amountLane.value?.amountPresentationId == frame.amountPresentationId) {
      return false;
    }
    _amountPreviewGeneration = previewGeneration;
    _amountLane.stage(frame, frame.amountPresentationId);
    final published = _amountLane.flush();
    if (published) amountPreviewPublishCount += 1;
    return published;
  }

  /// Invalidates an ephemeral amount preview when its focus base becomes
  /// invalid. The next complete frame still owns the normal amount lane.
  void clearPreparedAmountPreview({required int previewGeneration}) {
    if (previewGeneration < _amountPreviewGeneration) return;
    _amountPreviewGeneration = previewGeneration;
    final visible = _value;
    if (visible == null) return;
    _amountLane.stage(visible, visible.amountPresentationId);
    _amountLane.flush();
  }

  /// Publishes one complete RAM-derived filter preview to the narrow content
  /// lanes without replacing structural navigation or the committed frame.
  /// This is the Mind drag boundary: rows/count/amount move together while a
  /// later release remains the sole canonical Query/index publication.
  bool publishPreparedInteractionPreview(
    DashboardVisibleFrame frame, {
    required int previewGeneration,
  }) {
    if (previewGeneration < _interactionPreviewGeneration) {
      staleInteractionPreviewRejectCount += 1;
      return false;
    }
    if (previewGeneration == _interactionPreviewGeneration &&
        _logBoxLane.value?.logBoxPresentationId == frame.logBoxPresentationId) {
      return false;
    }
    _interactionPreviewGeneration = previewGeneration;
    _interactionPreviewFrame = frame;
    interactionPreviewReconciliationState =
        DashboardInteractionPreviewReconciliationState.idle;
    _amountLane.stage(frame, frame.amountPresentationId);
    _countLane.stage(frame, frame.countPresentationId);
    _logBoxPresentationLane.stage(
      DashboardLogBoxPresentationBinding.fromFrame(frame),
    );
    _logBoxLane.stage(frame, frame.logBoxPresentationId);
    final amountChanged = _amountLane.flush();
    final countChanged = _countLane.flush();
    _flushLogBoxPresentationLane();
    final logBoxChanged = _logBoxLane.flush();
    final amountKey = _amountLane.value?.queryKey;
    final countKey = _countLane.value?.queryKey;
    final logBoxKey = _logBoxLane.value?.queryKey;
    if (amountKey != countKey || amountKey != logBoxKey) {
      mixedProjectionCount += 1;
      throw StateError(
        'Mixed live projection: amount=$amountKey count=$countKey '
        'logBox=$logBoxKey previewGeneration=$previewGeneration',
      );
    }
    if (logBoxChanged) logBoxPayloadNotifyCount += 1;
    final published = amountChanged || countChanged || logBoxChanged;
    if (published) interactionPreviewPublishCount += 1;
    return published;
  }

  /// Arms the release bridge after the newest Mind preview has really painted.
  /// A later canonical frame may clear the overlay only when it has the same
  /// full visible projection.  Newer interactions supersede this guard by
  /// publishing their own [previewGeneration].
  bool armPreparedInteractionPreviewCanonicalReconciliation({
    required int previewGeneration,
    required int frameGeneration,
  }) {
    final preview = _interactionPreviewFrame;
    if (preview == null ||
        previewGeneration != _interactionPreviewGeneration ||
        preview.frameGeneration != frameGeneration) {
      return false;
    }
    interactionPreviewReconciliationState =
        DashboardInteractionPreviewReconciliationState.awaitingCanonical;
    return true;
  }

  void clearPreparedInteractionPreview({required int previewGeneration}) {
    if (previewGeneration < _interactionPreviewGeneration) return;
    _interactionPreviewGeneration = previewGeneration;
    _interactionPreviewFrame = null;
    interactionPreviewReconciliationState =
        DashboardInteractionPreviewReconciliationState.idle;
    final committed = _value;
    if (committed == null) return;
    _amountLane.stage(committed, committed.amountPresentationId);
    _countLane.stage(committed, committed.countPresentationId);
    _logBoxPresentationLane.stage(
      DashboardLogBoxPresentationBinding.fromFrame(committed),
    );
    _logBoxLane.stage(committed, committed.logBoxPresentationId);
    _amountLane.flush();
    _countLane.flush();
    _flushLogBoxPresentationLane();
    if (_logBoxLane.flush()) logBoxPayloadNotifyCount += 1;
  }

  bool publish(
    DashboardVisibleFrame frame, {
    DashboardVisibleFramePublishObserver? onMeasured,
  }) {
    final measureStart = onMeasured == null ? 0 : developer.Timeline.now;
    final current = _value;
    if (current != null && _isStale(frame, current)) {
      staleFrameRejectCount += 1;
      _reportMeasurement(onMeasured, measureStart, published: false);
      return false;
    }

    final preview = _interactionPreviewFrame;
    final reconciliation = interactionPreviewReconciliationState;
    if (preview != null &&
        reconciliation != DashboardInteractionPreviewReconciliationState.idle) {
      if (!_hasExactInteractionProjection(frame, preview)) {
        // Canonical persistence remains useful to the non-visual owners, but
        // it must not replace the exact rows/count/amount that were already
        // painted during the held drag.  Keeping all three live lanes intact
        // prevents a mixed projection while a stale or divergent canonical
        // completion is investigated or superseded.
        _value = frame;
        interactionPreviewReconciliationState =
            DashboardInteractionPreviewReconciliationState.retainedMismatch;
        interactionPreviewCanonicalMismatchRetainCount += 1;
        _reportMeasurement(onMeasured, measureStart, published: false);
        return false;
      }
      _interactionPreviewFrame = null;
      interactionPreviewReconciliationState =
          DashboardInteractionPreviewReconciliationState.reconciledExact;
      interactionPreviewCanonicalReconcileCount += 1;
    }

    if (current != null &&
        frame.queryKey == current.queryKey &&
        frame.coreRevision == current.coreRevision &&
        frame.visualDigest == current.visualDigest) {
      if (frame.presentationEpoch > current.presentationEpoch ||
          frame.navigationEpoch > current.navigationEpoch ||
          frame.frameGeneration > current.frameGeneration) {
        _value = frame;
        _logBoxPresentationLane.stage(
          DashboardLogBoxPresentationBinding.fromFrame(frame),
        );
        _flushLogBoxPresentationLane();
      }
      visualNoOpCount += 1;
      _reportMeasurement(onMeasured, measureStart, published: false);
      return false;
    }

    _value = frame;
    visiblePublishCount += 1;
    _stageLanes(frame);
    final equalityMicros = onMeasured == null
        ? 0
        : developer.Timeline.now - measureStart;
    final notifierStart = onMeasured == null ? 0 : developer.Timeline.now;
    _flushLanes();
    notifyListeners();
    if (onMeasured != null) {
      onMeasured(
        DashboardVisibleFramePublishMetrics(
          published: true,
          equalityMicros: equalityMicros,
          notifierMicros: developer.Timeline.now - notifierStart,
        ),
      );
    }
    return true;
  }

  static void _reportMeasurement(
    DashboardVisibleFramePublishObserver? observer,
    int measureStart, {
    required bool published,
  }) {
    if (observer == null) return;
    observer(
      DashboardVisibleFramePublishMetrics(
        published: published,
        equalityMicros: developer.Timeline.now - measureStart,
        notifierMicros: 0,
      ),
    );
  }

  bool promoteCommitted({
    required LedgerQueryKey expectedKey,
    required int epoch,
    int? navigationEpoch,
  }) {
    final current = _value;
    if (current == null ||
        current.queryKey != expectedKey ||
        current.presentationEpoch != epoch ||
        current.mode == DashboardVisibleMode.committed ||
        (navigationEpoch != null &&
            navigationEpoch < current.navigationEpoch)) {
      return false;
    }
    _value = current.asCommitted(navigationEpoch: navigationEpoch);
    // This is an ownership-only retag, not a payload rebind. Still update the
    // narrow navigation lane before the canonical navigation notifier can
    // build SummaryPill, otherwise it can observe an old frame epoch and fall
    // back to a separate canonical presentation at settle. The payload lanes
    // intentionally retain their exact same frame references: this promotion
    // is forbidden from rebinding rows, amount, or count for the first time.
    _navigationLane.stage(_value!, _value!.navigationPresentationId);
    if (_value!.navigationEpoch != current.navigationEpoch) {
      _navigationLane.forceFlush();
    }
    _logBoxPresentationLane.stage(
      DashboardLogBoxPresentationBinding.fromFrame(_value!),
    );
    _flushLogBoxPresentationLane();
    committedPromotionCount += 1;
    return true;
  }

  static bool _isStale(
    DashboardVisibleFrame candidate,
    DashboardVisibleFrame current,
  ) {
    if (candidate.presentationEpoch < current.presentationEpoch ||
        candidate.navigationEpoch < current.navigationEpoch ||
        candidate.coreRevision < current.coreRevision) {
      return true;
    }
    if (candidate.presentationEpoch != current.presentationEpoch ||
        candidate.navigationEpoch != current.navigationEpoch) {
      return false;
    }
    if (candidate.frameGeneration < current.frameGeneration) return true;
    return candidate.frameGeneration == current.frameGeneration &&
        (candidate.queryKey != current.queryKey ||
            candidate.coreRevision != current.coreRevision ||
            candidate.visualDigest != current.visualDigest ||
            candidate.mode != current.mode);
  }

  static bool _hasExactInteractionProjection(
    DashboardVisibleFrame canonical,
    DashboardVisibleFrame preview,
  ) =>
      canonical.queryKey == preview.queryKey &&
      canonical.parentQueryKey == preview.parentQueryKey &&
      canonical.scope == preview.scope &&
      canonical.direction == preview.direction &&
      canonical.plane == preview.plane &&
      canonical.railOpen == preview.railOpen &&
      canonical.semanticChildIndex == preview.semanticChildIndex &&
      canonical.coreRevision == preview.coreRevision &&
      canonical.visualDigest == preview.visualDigest;

  void _stageLanes(DashboardVisibleFrame frame) {
    _navigationLane.stage(frame, frame.navigationPresentationId);
    _amountLane.stage(frame, frame.amountPresentationId);
    _countLane.stage(frame, frame.countPresentationId);
    _logBoxLane.stage(frame, frame.logBoxPresentationId);
    _logBoxPresentationLane.stage(
      DashboardLogBoxPresentationBinding.fromFrame(frame),
    );
  }

  void _flushLanes() {
    _navigationLane.flush();
    _amountLane.flush();
    _countLane.flush();
    // The lightweight scope metadata must reach the stable vertical viewport
    // before the sibling payload can schedule its first paint.
    _flushLogBoxPresentationLane();
    if (_logBoxLane.flush()) logBoxPayloadNotifyCount += 1;
  }

  void _flushLogBoxPresentationLane() {
    if (_logBoxPresentationLane.flush()) {
      logBoxPresentationMetaNotifyCount += 1;
    }
  }

  @override
  void dispose() {
    _navigationLane.dispose();
    _amountLane.dispose();
    _countLane.dispose();
    _logBoxLane.dispose();
    _logBoxPresentationLane.dispose();
    super.dispose();
  }
}

/// A staged lane updates every pointer before any listener is notified.
/// Therefore amount/count/LogBox builders can never observe mixed frames even
/// though their rebuild boundaries are independent.
final class _DashboardPresentationLane extends ChangeNotifier
    implements ValueListenable<DashboardVisibleFrame?> {
  DashboardVisibleFrame? _value;
  int? _presentationId;
  bool _needsNotification = false;

  @override
  DashboardVisibleFrame? get value => _value;

  void stage(DashboardVisibleFrame frame, int presentationId) {
    _value = frame;
    if (_presentationId == presentationId) return;
    _presentationId = presentationId;
    _needsNotification = true;
  }

  bool flush() {
    if (!_needsNotification) return false;
    _needsNotification = false;
    notifyListeners();
    return true;
  }

  void forceFlush() {
    _needsNotification = false;
    notifyListeners();
  }
}

/// A staged metadata-only lane. It deliberately has no row/payload reference:
/// changing committed ownership must not trigger a visual payload rebind.
final class _DashboardLogBoxPresentationLane extends ChangeNotifier
    implements ValueListenable<DashboardLogBoxPresentationBinding?> {
  DashboardLogBoxPresentationBinding? _value;
  bool _needsNotification = false;

  @override
  DashboardLogBoxPresentationBinding? get value => _value;

  void stage(DashboardLogBoxPresentationBinding binding) {
    if (_value == binding) return;
    _value = binding;
    _needsNotification = true;
  }

  bool flush() {
    if (!_needsNotification) return false;
    _needsNotification = false;
    notifyListeners();
    return true;
  }
}
