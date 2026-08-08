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

/// Sole notifier for the complete visible dashboard presentation snapshot.
///
/// Every notified value already contains amount, count and LogBox data for one
/// exact QueryKey/revision. Commit promotion changes ownership metadata only
/// and intentionally emits no visual notification.
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
  }) {
    final current = _value;
    if (current == null ||
        current.queryKey != expectedKey ||
        current.presentationEpoch != epoch ||
        current.mode == DashboardVisibleMode.committed) {
      return false;
    }
    _value = current.asCommitted();
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
