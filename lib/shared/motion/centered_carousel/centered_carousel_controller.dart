// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'centered_carousel_data_source.dart';
import 'centered_carousel_motion_diagnostics.dart';
import 'centered_carousel_physics.dart';
import 'centered_carousel_spec.dart';

enum CenteredCarouselMotionOrigin { userDrag, programmatic }

typedef CenteredCarouselScrollSample =
    void Function(double offset, double velocity);

class CenteredCarouselController extends ChangeNotifier {
  CenteredCarouselController({required int initialIndex})
    : _selectedLogicalIndex = initialIndex,
      _logicalOrigin = initialIndex,
      _rawCenteredIndex = initialIndex.toDouble(),
      _scrollController = ScrollController() {
    _scrollController.addListener(_handleScroll);
  }

  static const int virtualItemCount = 200001;
  static const int virtualAnchorIndex = 100000;
  static const int rebaseThresholdItems = 5000;

  final ScrollController _scrollController;
  CenteredCarouselDataMode _dataMode = CenteredCarouselDataMode.bounded;
  int _finiteLength = 0;
  int _physicalItemCount = 0;
  double _itemExtent = 0;
  int _selectedPhysicalIndex = 0;
  int _selectedLogicalIndex;
  int _logicalOrigin;
  double _rawCenteredIndex;
  bool _configured = false;
  bool _enableHaptics = false;
  Duration _hapticThrottle = const Duration(milliseconds: 38);
  Duration _programmaticScrollDuration =
      CenteredCarouselSpec.defaultProgrammaticScrollDuration;
  Curve _programmaticScrollCurve =
      CenteredCarouselSpec.defaultProgrammaticScrollCurve;
  bool _isScrolling = false;
  bool _isRebasing = false;
  bool _suppressScrollEvents = false;
  bool _suppressSelectionCallbacks = false;
  ValueListenable<bool>? _scrollingNotifier;
  int? _lastHapticLogicalIndex;
  DateTime? _lastHapticAt;
  int _motionCommandId = 0;
  int _activeMotionCommandId = 0;
  int? _lastSettledCommandId;
  CenterSnapPhysicsConfiguration? _physicsConfiguration;
  CenterSnapScrollPhysics? _physics;
  int _physicsCreationCount = 0;
  CenteredCarouselMotionDiagnosticSink? _motionDiagnostics;
  int _diagnosticGestureSequence = 0;
  int _activeDiagnosticGestureId = 0;
  int _diagnosticGestureStartMicros = 0;
  double _diagnosticGestureStartPixels = 0;
  int _diagnosticGestureStartLogicalIndex = 0;
  double _diagnosticBallisticInputVelocity = 0;
  int _diagnosticCrossedChildCount = 0;
  int _diagnosticMetricChangeCount = 0;
  int _diagnosticActivityInterruptCount = 0;
  int _diagnosticViewportIdentity = 0;
  double _diagnosticDevicePixelRatio = 1;
  CenteredCarouselScrollGeometry? _lastDiagnosticGeometry;
  CenteredCarouselActivityKind _lastDiagnosticActivity =
      CenteredCarouselActivityKind.detached;
  int _lastDiagnosticActivityIdentity = 0;

  /// Kept for compatibility with the original controller API.
  ValueChanged<int>? onSelectedChanged;
  ValueChanged<int>? onPreviewChanged;
  ValueChanged<int>? onSelectionSettled;
  ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted;
  ValueChanged<int>? onMotionIdle;
  VoidCallback? onHapticTick;
  CenteredCarouselScrollSample? onScrollSample;
  ValueChanged<double>? onBallisticStarted;

  int get selectedIndex => _selectedLogicalIndex;
  int get selectedLogicalIndex => _selectedLogicalIndex;
  int get selectedPhysicalIndex => _selectedPhysicalIndex;
  double get rawCenteredIndex => _rawCenteredIndex;
  double get rawCenteredLogicalIndex =>
      _logicalOrigin + _rawCenteredIndex - virtualAnchorIndex;
  int get logicalOrigin => _logicalOrigin;
  int get physicalItemCount => _physicalItemCount;
  CenteredCarouselDataMode get dataMode => _dataMode;
  bool get isInfinite => _dataMode != CenteredCarouselDataMode.bounded;
  bool get isRebasing => _isRebasing;
  bool get isScrolling => _isScrolling;
  // ScrollPosition.activity distinguishes ballistic/spring activity from a
  // user drag; both must be interruptible by an immediate retarget tap.
  bool get hasActiveScrollActivity =>
      _scrollController.hasClients &&
      _scrollController.position.activity is! IdleScrollActivity;
  ScrollController get scrollController => _scrollController;
  int get physicsCreationCount => _physicsCreationCount;

  void setMotionDiagnostics(CenteredCarouselMotionDiagnosticSink? diagnostics) {
    if (identical(_motionDiagnostics, diagnostics)) return;
    _motionDiagnostics = diagnostics;
    _lastDiagnosticGeometry = null;
    _lastDiagnosticActivity = CenteredCarouselActivityKind.detached;
    _lastDiagnosticActivityIdentity = 0;
  }

  /// Returns the one feature-owned physics identity for this controller.
  /// Geometry and item count are updated through its stable configuration.
  CenterSnapScrollPhysics physicsFor(CenteredCarouselSpec spec) {
    final configuration = _physicsConfiguration ??=
        CenterSnapPhysicsConfiguration(
          itemExtent: spec.itemExtent,
          itemCount: _physicalItemCount,
          frictionDrag: spec.frictionDrag,
          velocityMultiplier: spec.velocityMultiplier,
          minimumFlingVelocity: spec.minimumFlingVelocity,
          maximumFlingVelocity: spec.maximumFlingVelocity,
          maxItemsPerFling: spec.maxItemsPerFling,
          forceOneItemOnFling: spec.forceOneItemOnFling,
          snapSpring: spec.snapSpring,
          snapTolerance: spec.snapTolerance,
          onBallisticStarted: _emitBallisticStarted,
        );
    configuration.update(
      itemExtent: spec.itemExtent,
      itemCount: _physicalItemCount,
      frictionDrag: spec.frictionDrag,
      velocityMultiplier: spec.velocityMultiplier,
      minimumFlingVelocity: spec.minimumFlingVelocity,
      maximumFlingVelocity: spec.maximumFlingVelocity,
      maxItemsPerFling: spec.maxItemsPerFling,
      forceOneItemOnFling: spec.forceOneItemOnFling,
      snapSpring: spec.snapSpring,
      snapTolerance: spec.snapTolerance,
    );
    final existing = _physics;
    if (existing != null) return existing;
    _physicsCreationCount += 1;
    return _physics = CenterSnapScrollPhysics.configured(
      configuration: configuration,
      parent: const ClampingScrollPhysics(),
    );
  }

  /// Starts a new user-owned motion command.
  ///
  /// This is intentionally independent from the scroll physics. It only
  /// invalidates callbacks belonging to a previous drag/fling/animation.
  int beginMotionCommand({
    CenteredCarouselMotionOrigin origin =
        CenteredCarouselMotionOrigin.programmatic,
  }) {
    final commandId = ++_motionCommandId;
    _activeMotionCommandId = commandId;
    onMotionStarted?.call(origin);
    return commandId;
  }

  bool isCurrentMotionCommand(int commandId) => commandId == _motionCommandId;

  void updateConfiguration({
    required int itemCount,
    required double itemExtent,
    CenteredCarouselDataMode dataMode = CenteredCarouselDataMode.bounded,
    int? finiteLength,
    bool enableHaptics = false,
    Duration? hapticThrottle,
    Duration? programmaticScrollDuration,
    Curve? programmaticScrollCurve,
  }) {
    final nextFiniteLength = (finiteLength ?? itemCount).clamp(0, 1 << 30);
    final configurationChanged =
        !_configured ||
        _dataMode != dataMode ||
        _finiteLength != nextFiniteLength ||
        _itemExtent != itemExtent;

    _dataMode = dataMode;
    _finiteLength = nextFiniteLength;
    _itemExtent = itemExtent;
    _physicalItemCount = switch (dataMode) {
      CenteredCarouselDataMode.bounded => _finiteLength,
      CenteredCarouselDataMode.cyclic =>
        _finiteLength == 0 ? 0 : virtualItemCount,
      CenteredCarouselDataMode.generated => virtualItemCount,
    };
    _enableHaptics = enableHaptics;
    _hapticThrottle = hapticThrottle ?? _hapticThrottle;
    _programmaticScrollDuration =
        programmaticScrollDuration ?? _programmaticScrollDuration;
    _programmaticScrollCurve =
        programmaticScrollCurve ?? _programmaticScrollCurve;

    if (configurationChanged) {
      if (dataMode == CenteredCarouselDataMode.bounded) {
        _selectedLogicalIndex = _clampBounded(_selectedLogicalIndex);
        _logicalOrigin = 0;
        _selectedPhysicalIndex = _selectedLogicalIndex;
      } else {
        _logicalOrigin = _selectedLogicalIndex;
        _selectedPhysicalIndex = _physicalForLogical(_selectedLogicalIndex);
      }
      _rawCenteredIndex = _selectedPhysicalIndex.toDouble();
      _lastHapticLogicalIndex = _selectedLogicalIndex;
    }
    _configured = true;
    final physicsConfiguration = _physicsConfiguration;
    if (physicsConfiguration != null) {
      physicsConfiguration.itemExtent = _itemExtent;
      physicsConfiguration.itemCount = _physicalItemCount;
    }
    _attachScrollingNotifier();
    if (!configurationChanged) return;
    recenterSelected();
    notifyListeners();
  }

  /// Replaces only the semantic data configuration while retaining the
  /// controller, ScrollController, physics identity and visual spec.
  void updateDataConfiguration({
    required CenteredCarouselDataMode dataMode,
    required int finiteLength,
  }) {
    updateConfiguration(
      itemCount: finiteLength,
      itemExtent: _itemExtent > 0
          ? _itemExtent
          : (_physicsConfiguration?.itemExtent ?? 1),
      dataMode: dataMode,
      finiteLength: finiteLength,
      enableHaptics: _enableHaptics,
      hapticThrottle: _hapticThrottle,
      programmaticScrollDuration: _programmaticScrollDuration,
      programmaticScrollCurve: _programmaticScrollCurve,
    );
  }

  /// Replaces semantic meaning without moving the existing ScrollPosition.
  ///
  /// Parent/direction changes keep the same rail plane and physical belt. The
  /// current physical slot is therefore rebound to the retained semantic
  /// child by adjusting only the logical origin; drag/ballistic activity,
  /// pixels, velocity, controller and physics identities remain untouched.
  void installSemanticDomain({
    required CenteredCarouselDataMode dataMode,
    required int finiteLength,
    required int selectedLogicalIndex,
  }) {
    if (!_configured || dataMode != _dataMode) {
      updateDataConfiguration(dataMode: dataMode, finiteLength: finiteLength);
      jumpToIndexSilently(selectedLogicalIndex);
      return;
    }
    if (finiteLength <= 0) {
      throw ArgumentError.value(
        finiteLength,
        'finiteLength',
        'must be positive',
      );
    }
    _finiteLength = finiteLength;
    _physicalItemCount = dataMode == CenteredCarouselDataMode.bounded
        ? finiteLength
        : virtualItemCount;
    final centeredPhysical = _rawCenteredIndex.round().clamp(
      0,
      _physicalItemCount - 1,
    );
    if (dataMode == CenteredCarouselDataMode.bounded) {
      _selectedLogicalIndex = selectedLogicalIndex.clamp(0, finiteLength - 1);
      _selectedPhysicalIndex = centeredPhysical;
    } else {
      _selectedLogicalIndex = selectedLogicalIndex;
      _selectedPhysicalIndex = centeredPhysical;
      _logicalOrigin =
          selectedLogicalIndex - centeredPhysical + virtualAnchorIndex;
    }
    _lastHapticLogicalIndex = _selectedLogicalIndex;
    final physicsConfiguration = _physicsConfiguration;
    if (physicsConfiguration != null) {
      physicsConfiguration.itemCount = _physicalItemCount;
    }
    notifyListeners();
  }

  int logicalIndexForPhysical(int physicalIndex) {
    if (!isInfinite) return _clampBounded(physicalIndex);
    return _logicalOrigin + physicalIndex - virtualAnchorIndex;
  }

  int physicalIndexForLogical(int logicalIndex) {
    if (!isInfinite) return _clampBounded(logicalIndex);
    return (virtualAnchorIndex + logicalIndex - _logicalOrigin).clamp(
      0,
      virtualItemCount - 1,
    );
  }

  Future<void> animateToIndex(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    final logicalIndex = isInfinite ? index : _clampBounded(index);
    final physicalIndex = physicalIndexForLogical(logicalIndex);
    await _animateToPhysicalIndex(
      physicalIndex,
      logicalIndex: logicalIndex,
      duration: duration,
      curve: curve,
    );
  }

  /// Retargets directly to the physical slot that was tapped.
  ///
  /// This matters for infinite and cyclic carousels where the same domain
  /// value can be represented by more than one physical slot.
  Future<void> tapToPhysicalIndex(
    int physicalIndex, {
    Duration? duration,
    Curve? curve,
  }) async {
    if (_physicalItemCount <= 0) return;

    final targetPhysicalIndex = physicalIndex.clamp(0, _physicalItemCount - 1);
    final logicalIndex = logicalIndexForPhysical(targetPhysicalIndex);
    await _animateToPhysicalIndex(
      targetPhysicalIndex,
      logicalIndex: logicalIndex,
      duration: duration,
      curve: curve,
    );
  }

  Future<void> _animateToPhysicalIndex(
    int physicalIndex, {
    required int logicalIndex,
    Duration? duration,
    Curve? curve,
  }) async {
    final commandId = beginMotionCommand();
    if (!_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      _setSelection(logicalIndex, physicalIndex);
      _emitSettledForCommand(commandId);
      return;
    }

    await _scrollController.animateTo(
      _pixelsForPhysicalIndex(physicalIndex),
      duration: duration ?? _programmaticScrollDuration,
      curve: curve ?? _programmaticScrollCurve,
    );

    if (!isCurrentMotionCommand(commandId)) return;
    _emitSettledForCommand(commandId);
  }

  void jumpToIndex(int index) {
    final logicalIndex = isInfinite ? index : _clampBounded(index);
    _setSelection(logicalIndex, physicalIndexForLogical(logicalIndex));
    recenterSelected();
  }

  /// Moves the selected slot for an adapter/data-source transition without
  /// presenting the transition as a user preview or settled selection.
  ///
  /// This is intentionally separate from [jumpToIndex]: changing from years
  /// to months (or months to days) is a presentation reconfiguration, not a
  /// new user selection. It does not alter physics, snap, haptics, or rebase.
  void jumpToIndexSilently(int index) {
    if (!_configured) {
      _selectedLogicalIndex = index;
      _selectedPhysicalIndex = index;
      _rawCenteredIndex = index.toDouble();
      notifyListeners();
      return;
    }
    final logicalIndex = isInfinite ? index : _clampBounded(index);
    _suppressSelectionCallbacks = true;
    _setSelection(logicalIndex, physicalIndexForLogical(logicalIndex));
    recenterSelected();
    _suppressSelectionCallbacks = false;
    notifyListeners();
  }

  void recenterSelected() {
    if (!_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      return;
    }
    _attachScrollingNotifier();
    _suppressScrollEvents = true;
    _scrollController.jumpTo(_pixelsForPhysicalIndex(_selectedPhysicalIndex));
    _suppressScrollEvents = false;
    _rawCenteredIndex = _selectedPhysicalIndex.toDouble();
  }

  /// Returns true when the physical belt was moved back to its anchor.
  bool rebaseIfNeeded() {
    if (!isInfinite ||
        _isScrolling ||
        _isRebasing ||
        !_scrollController.hasClients ||
        _itemExtent <= 0) {
      return false;
    }

    final physicalIndex = _rawCenteredIndex.round();
    final delta = physicalIndex - virtualAnchorIndex;
    if (delta.abs() < rebaseThresholdItems) return false;

    _isRebasing = true;
    _logicalOrigin += delta;
    _selectedPhysicalIndex = virtualAnchorIndex;
    _rawCenteredIndex = virtualAnchorIndex.toDouble();
    _suppressScrollEvents = true;
    _scrollController.jumpTo(_pixelsForPhysicalIndex(virtualAnchorIndex));
    _suppressScrollEvents = false;
    _isRebasing = false;
    notifyListeners();
    return true;
  }

  void setOnSelectedChanged(ValueChanged<int>? callback) {
    onSelectedChanged = callback;
  }

  void setCallbacks({
    ValueChanged<int>? onPreviewChanged,
    ValueChanged<int>? onSelectionSettled,
    ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted,
    ValueChanged<int>? onMotionIdle,
  }) {
    this.onPreviewChanged = onPreviewChanged;
    this.onSelectionSettled = onSelectionSettled;
    this.onMotionStarted = onMotionStarted;
    this.onMotionIdle = onMotionIdle;
  }

  void _attachScrollingNotifier() {
    if (!_scrollController.hasClients) return;
    final nextNotifier = _scrollController.position.isScrollingNotifier;
    if (_scrollingNotifier == nextNotifier) return;
    _scrollingNotifier?.removeListener(_handleScrollingChanged);
    _scrollingNotifier = nextNotifier;
    _scrollingNotifier!.addListener(_handleScrollingChanged);
  }

  void _handleScrollingChanged() {
    final isScrolling = _scrollingNotifier?.value ?? false;
    if (isScrolling) {
      _isScrolling = true;
      _recordDiagnosticActivity(
        CenteredCarouselActivityChangeReason.scrollSample,
      );
      return;
    }
    if (!_isScrolling) return;
    _isScrolling = false;
    _recordDiagnosticActivity(
      CenteredCarouselActivityChangeReason.scrollingIdle,
    );
    final commandId = _activeMotionCommandId;
    if (!isCurrentMotionCommand(commandId)) return;
    rebaseIfNeeded();
    onMotionIdle?.call(_selectedLogicalIndex);
    _emitSettledForCommand(commandId);
  }

  /// Invalidates an in-flight programmatic motion when a new drag starts.
  void beginUserMotionCommand() {
    beginMotionCommand(origin: CenteredCarouselMotionOrigin.userDrag);
    _recordDiagnosticActivity(CenteredCarouselActivityChangeReason.dragStarted);
  }

  void _handleScroll() {
    if (_suppressScrollEvents ||
        !_scrollController.hasClients ||
        _itemExtent <= 0 ||
        _physicalItemCount <= 0) {
      return;
    }
    _attachScrollingNotifier();
    final position = _scrollController.position;
    _recordDiagnosticActivity(
      CenteredCarouselActivityChangeReason.scrollSample,
    );
    _rawCenteredIndex =
        (_scrollController.offset - position.minScrollExtent) / _itemExtent;
    onScrollSample?.call(position.pixels, position.activity?.velocity ?? 0);
    final nextPhysicalIndex = _rawCenteredIndex.round().clamp(
      0,
      _physicalItemCount - 1,
    );
    final nextLogicalIndex = logicalIndexForPhysical(nextPhysicalIndex);
    if (nextLogicalIndex != _selectedLogicalIndex) {
      _selectedPhysicalIndex = nextPhysicalIndex;
      _setSelection(nextLogicalIndex, nextPhysicalIndex);
    } else {
      _selectedPhysicalIndex = nextPhysicalIndex;
    }
    notifyListeners();
  }

  void _setSelection(int logicalIndex, int physicalIndex) {
    final changed = logicalIndex != _selectedLogicalIndex;
    _selectedLogicalIndex = logicalIndex;
    _selectedPhysicalIndex = physicalIndex;
    if (changed) _emitPreview(logicalIndex);
  }

  void _emitPreview(int logicalIndex) {
    if (_suppressSelectionCallbacks) return;
    if (_activeDiagnosticGestureId != 0) {
      _diagnosticCrossedChildCount += 1;
    }
    _emitHapticIfNeeded(logicalIndex);
    onPreviewChanged?.call(logicalIndex);
    if (onSelectedChanged != null && onSelectedChanged != onPreviewChanged) {
      onSelectedChanged!.call(logicalIndex);
    }
  }

  void _emitHapticIfNeeded(int logicalIndex) {
    if (!_enableHaptics ||
        _isRebasing ||
        logicalIndex == _lastHapticLogicalIndex) {
      return;
    }
    final now = DateTime.now();
    if (_lastHapticAt != null &&
        now.difference(_lastHapticAt!) < _hapticThrottle) {
      return;
    }
    _lastHapticLogicalIndex = logicalIndex;
    _lastHapticAt = now;
    onHapticTick?.call();
    if (!kIsWeb) {
      HapticFeedback.selectionClick();
    }
  }

  void _emitSettledForCommand(int commandId) {
    if (!isCurrentMotionCommand(commandId) ||
        _lastSettledCommandId == commandId) {
      return;
    }
    _lastSettledCommandId = commandId;
    _recordDiagnosticSettle();
    onSelectionSettled?.call(_selectedLogicalIndex);
  }

  void _emitBallisticStarted(double velocity) {
    _diagnosticBallisticInputVelocity = velocity;
    final diagnostics = _motionDiagnostics;
    if ((diagnostics?.isEnabled ?? false) &&
        _activeDiagnosticGestureId != 0 &&
        _scrollController.hasClients) {
      final position = _scrollController.position;
      final physics = _physics;
      final geometry = _diagnosticGeometry(position);
      double? targetRawIndex;
      double? targetPixels;
      if (physics != null && _itemExtent > 0 && _physicalItemCount > 0) {
        targetRawIndex = calculateTargetRawIndex(
          currentPixels: position.pixels,
          velocity: velocity,
          itemExtent: _itemExtent,
          minScrollExtent: position.minScrollExtent,
          physics: physics,
        );
        final targetIndex = targetRawIndex.round().clamp(
          0,
          _physicalItemCount - 1,
        );
        targetPixels = (position.minScrollExtent + targetIndex * _itemExtent)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
      }
      final activity = position.activity;
      diagnostics!.record(
        CenteredCarouselBallisticStarted(
          gestureId: _activeDiagnosticGestureId,
          timestampMicros: developer.Timeline.now,
          inputVelocity: velocity,
          simulationKind: CenteredCarouselSimulationKind.scrollSpring,
          simulationStartPosition: position.pixels,
          targetPixels: targetPixels,
          targetRawIndex: targetRawIndex,
          identities: _diagnosticIdentities(),
          geometry: geometry,
          activityIdentity: activity == null ? 0 : identityHashCode(activity),
        ),
      );
      _recordDiagnosticActivity(
        CenteredCarouselActivityChangeReason.ballisticStarted,
      );
    }
    onBallisticStarted?.call(velocity);
  }

  void recordDiagnosticGestureStart({
    required int eventTimestampMicros,
    required double pointerX,
    required double pointerY,
    required int viewportIdentity,
    required double devicePixelRatio,
  }) {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false)) return;
    _activeDiagnosticGestureId = ++_diagnosticGestureSequence;
    _diagnosticGestureStartMicros = developer.Timeline.now;
    _diagnosticGestureStartPixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0;
    _diagnosticGestureStartLogicalIndex = _selectedLogicalIndex;
    _diagnosticBallisticInputVelocity = 0;
    _diagnosticCrossedChildCount = 0;
    _diagnosticMetricChangeCount = 0;
    _diagnosticActivityInterruptCount = 0;
    _diagnosticViewportIdentity = viewportIdentity;
    _diagnosticDevicePixelRatio = devicePixelRatio;
    final geometry = _diagnosticGeometryOrEmpty();
    _lastDiagnosticGeometry = geometry;
    _captureDiagnosticActivityBaseline();
    diagnostics!.record(
      CenteredCarouselGestureStarted(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: _diagnosticGestureStartMicros,
        eventTimestampMicros: eventTimestampMicros,
        startPixels: _diagnosticGestureStartPixels,
        startLogicalIndex: _diagnosticGestureStartLogicalIndex,
        pointerX: pointerX,
        pointerY: pointerY,
        identities: _diagnosticIdentities(),
        geometry: geometry,
      ),
    );
  }

  void recordDiagnosticGestureSample({
    required int eventTimestampMicros,
    required double pointerX,
    required double pointerY,
  }) {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false) || _activeDiagnosticGestureId == 0) {
      return;
    }
    diagnostics!.record(
      CenteredCarouselGestureSample(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        eventTimestampMicros: eventTimestampMicros,
        pointerX: pointerX,
        pointerY: pointerY,
      ),
    );
  }

  void recordDiagnosticGestureRelease({
    required int eventTimestampMicros,
    required double velocityX,
    required double velocityY,
  }) {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false) || _activeDiagnosticGestureId == 0) {
      return;
    }
    final geometry = _diagnosticGeometryOrEmpty();
    diagnostics!.record(
      CenteredCarouselGestureReleased(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        eventTimestampMicros: eventTimestampMicros,
        dragEndVelocityX: velocityX,
        dragEndVelocityY: velocityY,
        primaryVelocity: velocityX,
        startPixels: _diagnosticGestureStartPixels,
        releasePixels: geometry.pixels,
        semanticStartIndex: _diagnosticGestureStartLogicalIndex,
        semanticReleaseIndex: _selectedLogicalIndex,
        identities: _diagnosticIdentities(),
        geometry: geometry,
      ),
    );
  }

  void cancelDiagnosticGesture() {
    _activeDiagnosticGestureId = 0;
  }

  void recordMetricsNotification(ScrollMetrics metrics) {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false)) return;
    final next = _diagnosticGeometry(metrics);
    final previous = _lastDiagnosticGeometry;
    _lastDiagnosticGeometry = next;
    if (previous == null || previous.hasSameScrollMetrics(next)) return;
    _diagnosticMetricChangeCount += 1;
    final activity = _scrollController.hasClients
        ? _scrollController.position.activity
        : null;
    diagnostics!.record(
      CenteredCarouselScrollMetricsChanged(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        oldGeometry: previous,
        newGeometry: next,
        correctedPixels: next.pixels,
        reason: CenteredCarouselMetricsChangeReason.viewportNotification,
        activityIdentity: activity == null ? 0 : identityHashCode(activity),
      ),
    );
    _recordDiagnosticActivity(
      CenteredCarouselActivityChangeReason.metricsChanged,
    );
  }

  void recordDiagnosticPositionAttached() {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false) || !_scrollController.hasClients) {
      return;
    }
    _lastDiagnosticGeometry = _diagnosticGeometry(_scrollController.position);
    _recordDiagnosticActivity(
      CenteredCarouselActivityChangeReason.positionAttached,
      force: true,
    );
  }

  void recordDiagnosticPositionDetached() {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false)) return;
    final previous = _lastDiagnosticActivity;
    final previousIdentity = _lastDiagnosticActivityIdentity;
    _lastDiagnosticActivity = CenteredCarouselActivityKind.detached;
    _lastDiagnosticActivityIdentity = 0;
    diagnostics!.record(
      CenteredCarouselScrollActivityChanged(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        previousActivity: previous,
        nextActivity: CenteredCarouselActivityKind.detached,
        previousActivityIdentity: previousIdentity,
        nextActivityIdentity: 0,
        reason: CenteredCarouselActivityChangeReason.positionDetached,
        currentPixels: _lastDiagnosticGeometry?.pixels ?? 0,
        currentVelocity: 0,
      ),
    );
  }

  void _recordDiagnosticSettle() {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false) || _activeDiagnosticGestureId == 0) {
      return;
    }
    final geometry = _diagnosticGeometryOrEmpty();
    diagnostics!.record(
      CenteredCarouselSettled(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        inputVelocity: _diagnosticBallisticInputVelocity,
        startPixels: _diagnosticGestureStartPixels,
        finalPixels: geometry.pixels,
        startLogicalIndex: _diagnosticGestureStartLogicalIndex,
        finalLogicalIndex: _selectedLogicalIndex,
        elapsedMicros: developer.Timeline.now - _diagnosticGestureStartMicros,
        crossedChildCount: _diagnosticCrossedChildCount,
        activityInterruptCount: _diagnosticActivityInterruptCount,
        metricChangeCount: _diagnosticMetricChangeCount,
        identities: _diagnosticIdentities(),
        geometry: geometry,
      ),
    );
    _activeDiagnosticGestureId = 0;
  }

  CenteredCarouselMotionIdentity _diagnosticIdentities() {
    final position = _scrollController.hasClients
        ? _scrollController.position
        : null;
    return CenteredCarouselMotionIdentity(
      controllerIdentity: identityHashCode(this),
      positionIdentity: position == null ? 0 : identityHashCode(position),
      physicsIdentity: _physics == null ? 0 : identityHashCode(_physics),
      viewportIdentity: _diagnosticViewportIdentity,
    );
  }

  CenteredCarouselScrollGeometry _diagnosticGeometryOrEmpty() {
    if (_scrollController.hasClients) {
      return _diagnosticGeometry(_scrollController.position);
    }
    return CenteredCarouselScrollGeometry(
      pixels: 0,
      minScrollExtent: 0,
      maxScrollExtent: 0,
      viewportDimension: 0,
      itemExtent: _itemExtent,
      devicePixelRatio: _diagnosticDevicePixelRatio,
    );
  }

  CenteredCarouselScrollGeometry _diagnosticGeometry(ScrollMetrics metrics) =>
      CenteredCarouselScrollGeometry(
        pixels: metrics.pixels,
        minScrollExtent: metrics.minScrollExtent,
        maxScrollExtent: metrics.maxScrollExtent,
        viewportDimension: metrics.viewportDimension,
        itemExtent: _itemExtent,
        devicePixelRatio: _diagnosticDevicePixelRatio,
      );

  void _captureDiagnosticActivityBaseline() {
    if (!_scrollController.hasClients) {
      _lastDiagnosticActivity = CenteredCarouselActivityKind.detached;
      _lastDiagnosticActivityIdentity = 0;
      return;
    }
    final activity = _scrollController.position.activity;
    _lastDiagnosticActivity = _diagnosticActivityKind(activity);
    _lastDiagnosticActivityIdentity = activity == null
        ? 0
        : identityHashCode(activity);
  }

  void _recordDiagnosticActivity(
    CenteredCarouselActivityChangeReason reason, {
    bool force = false,
  }) {
    final diagnostics = _motionDiagnostics;
    if (!(diagnostics?.isEnabled ?? false) || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final activity = position.activity;
    final next = _diagnosticActivityKind(activity);
    final nextIdentity = activity == null ? 0 : identityHashCode(activity);
    final previous = _lastDiagnosticActivity;
    final previousIdentity = _lastDiagnosticActivityIdentity;
    if (!force && next == previous && nextIdentity == previousIdentity) return;
    final ballisticWasReplaced =
        previous == CenteredCarouselActivityKind.ballistic &&
        next == CenteredCarouselActivityKind.ballistic &&
        nextIdentity != previousIdentity;
    final ballisticWasUnexpectedlyInterrupted =
        previous == CenteredCarouselActivityKind.ballistic &&
        next != CenteredCarouselActivityKind.ballistic &&
        next != CenteredCarouselActivityKind.idle &&
        reason != CenteredCarouselActivityChangeReason.dragStarted;
    if (ballisticWasReplaced || ballisticWasUnexpectedlyInterrupted) {
      _diagnosticActivityInterruptCount += 1;
    }
    _lastDiagnosticActivity = next;
    _lastDiagnosticActivityIdentity = nextIdentity;
    diagnostics!.record(
      CenteredCarouselScrollActivityChanged(
        gestureId: _activeDiagnosticGestureId,
        timestampMicros: developer.Timeline.now,
        previousActivity: previous,
        nextActivity: next,
        previousActivityIdentity: previousIdentity,
        nextActivityIdentity: nextIdentity,
        reason: reason,
        currentPixels: position.pixels,
        currentVelocity: activity?.velocity ?? 0,
      ),
    );
  }

  static CenteredCarouselActivityKind _diagnosticActivityKind(
    ScrollActivity? activity,
  ) => switch (activity) {
    null => CenteredCarouselActivityKind.detached,
    IdleScrollActivity() => CenteredCarouselActivityKind.idle,
    HoldScrollActivity() => CenteredCarouselActivityKind.hold,
    DragScrollActivity() => CenteredCarouselActivityKind.drag,
    BallisticScrollActivity() => CenteredCarouselActivityKind.ballistic,
    DrivenScrollActivity() => CenteredCarouselActivityKind.driven,
    _ => CenteredCarouselActivityKind.other,
  };

  int _physicalForLogical(int logicalIndex) =>
      physicalIndexForLogical(logicalIndex);

  int _clampBounded(int index) {
    if (_finiteLength <= 0) return 0;
    return index.clamp(0, _finiteLength - 1);
  }

  double _pixelsForPhysicalIndex(int physicalIndex) {
    final minScrollExtent = _scrollController.hasClients
        ? _scrollController.position.minScrollExtent
        : 0.0;
    return minScrollExtent + physicalIndex * _itemExtent;
  }

  @override
  void dispose() {
    _scrollingNotifier?.removeListener(_handleScrollingChanged);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
