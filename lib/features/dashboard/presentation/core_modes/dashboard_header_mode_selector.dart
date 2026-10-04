import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show
        Drag,
        DragEndDetails,
        DragStartBehavior,
        DragStartDetails,
        DragUpdateDetails,
        GestureRecognizer,
        PointerDeviceKind,
        Velocity,
        VerticalDragGestureRecognizer;
import 'package:flutter/material.dart';

import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_core_mode_controller.dart';
import '../../application/dashboard_mode_spec.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// The bounded physical Header control for the canonical three-mode ring.
/// Its carousel state is deliberately presentation-only; every crossing is
/// synchronously committed through [DashboardCoreModeController].
final class DashboardHeaderModeSelector extends StatefulWidget {
  const DashboardHeaderModeSelector({
    super.key,
    required this.controller,
    required this.selectedMode,
    this.balanceVisualFrame,
    this.budgetVisualFrame,
    this.mindVisualFrame,
  });

  final DashboardCoreModeController controller;
  final DashboardModeSpec selectedMode;
  final ValueListenable<DashboardHeaderVisualFrame>? balanceVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? budgetVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? mindVisualFrame;

  @override
  State<DashboardHeaderModeSelector> createState() =>
      _DashboardHeaderModeSelectorState();
}

final class _DashboardHeaderModeSelectorState
    extends State<DashboardHeaderModeSelector> {
  // The Header's 32px visual lane deliberately remains compact.  Scaling
  // input here—not item spacing or shared physics—means every semantic
  // boundary needs twice the physical finger travel while the established
  // carousel paints the same continuous outgoing/incoming icon motion.
  static const _inputGain = .5;

  late final CenteredCarouselController _carouselController =
      CenteredCarouselController(initialIndex: _indexOf(widget.selectedMode));
  late int _lastLogicalIndex = _indexOf(widget.selectedMode);
  Drag? _scaledDrag;
  var _directInputIsDown = false;
  var _initialCenterReady = false;

  @override
  void initState() {
    super.initState();
    _attachVisualListeners(widget);
    // A cyclic ListView reaches its virtual anchor after its first layout.
    // Until then expose the same prepared current icon, rather than a wrong
    // belt item for one frame. This adds no motion or semantic state owner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _initialCenterReady = true);
    });
  }

  @override
  void didUpdateWidget(covariant DashboardHeaderModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameVisualInputs(oldWidget, widget)) {
      _detachVisualListeners(oldWidget);
      _attachVisualListeners(widget);
    }
    // A programmatic mode write while idle must reflect the canonical mode
    // without creating another semantic event. During an actual user drag or
    // ballistic activity the physical controller remains authoritative.
    if (oldWidget.selectedMode != widget.selectedMode &&
        !_carouselController.hasActiveScrollActivity) {
      final index = _indexOf(widget.selectedMode);
      _lastLogicalIndex = index;
      _carouselController.jumpToIndexSilently(index);
    }
  }

  void _attachVisualListeners(DashboardHeaderModeSelector source) {
    source.balanceVisualFrame?.addListener(_onVisualFrameChanged);
    source.budgetVisualFrame?.addListener(_onVisualFrameChanged);
    source.mindVisualFrame?.addListener(_onVisualFrameChanged);
  }

  void _detachVisualListeners(DashboardHeaderModeSelector source) {
    source.balanceVisualFrame?.removeListener(_onVisualFrameChanged);
    source.budgetVisualFrame?.removeListener(_onVisualFrameChanged);
    source.mindVisualFrame?.removeListener(_onVisualFrameChanged);
  }

  void _onVisualFrameChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewportExtent = _viewportExtent;
    return SizedBox(
      key: const ValueKey<String>('dashboard-header-mode-selector'),
      width: viewportExtent,
      height: viewportExtent,
      child: Semantics(
        label:
            'Mód: ${_modeLabel(widget.selectedMode)}. Függőlegesen húzva válthat.',
        onIncrease: () =>
            widget.controller.switchMode(DashboardCoreModeDirection.forward),
        onDecrease: () =>
            widget.controller.switchMode(DashboardCoreModeDirection.backward),
        child: ExcludeSemantics(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (!_initialCenterReady)
                Center(
                  key: const ValueKey<String>(
                    'dashboard-header-mode-selector-fallback',
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      'dashboard-header-mode-icon-${widget.selectedMode.mode.name}',
                    ),
                    child: _visualFor(widget.selectedMode.mode),
                  ),
                ),
              // The shared carousel still owns the real ScrollPosition and
              // physics.  Once ready, the Header-local overlay wins hit
              // testing above this subtree and forwards its transformed drag
              // lifecycle into the same position.
              IgnorePointer(
                key: const ValueKey<String>(
                  'dashboard-header-mode-selector-carousel',
                ),
                ignoring: !_initialCenterReady,
                child: Opacity(
                  opacity: _initialCenterReady ? 1 : 0,
                  child: CenteredCarousel<DashboardModeSpec>(
                    dataSource:
                        const CyclicCarouselDataSource<DashboardModeSpec>(
                          DashboardModeSpec.values,
                        ),
                    controller: _carouselController,
                    spec: CenteredCarouselSpec(
                      itemExtent: viewportExtent,
                      scrollDirection: Axis.vertical,
                      visibleItemCount: 1,
                      minScale: 1,
                      neighborScale: 1,
                      outerScale: 1,
                      minOpacity: 1,
                      neighborOpacity: 1,
                      outerOpacity: 1,
                      motionProfile:
                          CenteredCarouselMotionProfiles.timeRefinementRail,
                      enableHaptics: true,
                      enableTapToCenter: false,
                      clipBehavior: Clip.hardEdge,
                      dragStartBehavior: DragStartBehavior.down,
                    ),
                    height: viewportExtent,
                    viewportKey: const ValueKey<String>(
                      'dashboard-header-mode-selector-viewport',
                    ),
                    onSelectedChanged: _commitCrossing,
                    itemBuilder: (context, item, metrics) => KeyedSubtree(
                      // A cyclic belt may build another physical instance of
                      // the same semantic item in its cache. The established
                      // Header key identifies the one physically centered
                      // icon, never every repeated belt instance.
                      key: metrics.isSelected
                          ? ValueKey<String>(
                              'dashboard-header-mode-icon-${item.mode.name}',
                            )
                          : null,
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          'dashboard-header-mode-selector-item-${item.mode.name}',
                        ),
                        child: _visualFor(item.mode),
                      ),
                    ),
                  ),
                ),
              ),
              if (_initialCenterReady)
                Positioned.fill(
                  child: Listener(
                    key: const ValueKey<String>(
                      'dashboard-header-mode-selector-input-gain',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _beginDirectInput(),
                    onPointerUp: (_) => _finishDirectInput(),
                    onPointerCancel: (_) => _finishDirectInput(),
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures:
                          <Type, GestureRecognizerFactory<GestureRecognizer>>{
                            _HeaderModeInputGainDragRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                  _HeaderModeInputGainDragRecognizer
                                >(() => _HeaderModeInputGainDragRecognizer(), (
                                  recognizer,
                                ) {
                                  recognizer
                                    ..dragStartBehavior = DragStartBehavior.down
                                    ..onStart = _startScaledDrag
                                    ..onUpdate = _updateScaledDrag
                                    ..onEnd = _endScaledDrag
                                    ..onCancel = _cancelScaledDrag;
                                }),
                          },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double get _viewportExtent {
    final sizePercent = <double>[
      widget.balanceVisualFrame?.value.headerModeIconSizePercent ?? 0,
      widget.budgetVisualFrame?.value.headerModeIconSizePercent ?? 0,
      widget.mindVisualFrame?.value.headerModeIconSizePercent ?? 0,
    ].reduce((largest, current) => largest > current ? largest : current);
    return DashboardHeaderModeIconButton.buttonExtentFor(sizePercent);
  }

  DashboardHeaderVisualFrame? _frameFor(DashboardMode mode) => switch (mode) {
    DashboardMode.balance => widget.balanceVisualFrame?.value,
    DashboardMode.budget => widget.budgetVisualFrame?.value,
    DashboardMode.mind => widget.mindVisualFrame?.value,
  };

  DashboardHeaderModeIconVisual _visualFor(DashboardMode mode) {
    final frame = _frameFor(mode);
    return DashboardHeaderModeIconVisual(
      mode: mode,
      color: frame?.headerIconColor ?? Colors.white,
      sizePercent: frame?.headerModeIconSizePercent ?? 0,
    );
  }

  void _beginDirectInput() {
    if (_directInputIsDown) return;
    _directInputIsDown = true;
    _carouselController.noteDirectPointerDown();
    _carouselController.interruptForDirectPointer();
  }

  void _startScaledDrag(DragStartDetails details) {
    if (!_directInputIsDown) {
      _beginDirectInput();
    }
    if (!_carouselController.scrollController.hasClients) return;
    _carouselController.beginUserMotionCommand();
    _scaledDrag = _carouselController.scrollController.position.drag(
      details,
      _onScaledDragCancelledByPosition,
    );
  }

  void _updateScaledDrag(DragUpdateDetails details) {
    final drag = _scaledDrag;
    if (drag == null) return;
    final scaledDelta = Offset(0, details.delta.dy * _inputGain);
    drag.update(
      DragUpdateDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        sourceTimeStamp: details.sourceTimeStamp,
        delta: scaledDelta,
        primaryDelta: details.primaryDelta == null
            ? null
            : details.primaryDelta! * _inputGain,
        kind: details.kind,
      ),
    );
  }

  void _endScaledDrag(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    _scaledDrag?.end(
      DragEndDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        velocity: Velocity(
          pixelsPerSecond: Offset(0, velocity.dy * _inputGain),
        ),
        primaryVelocity: details.primaryVelocity == null
            ? null
            : details.primaryVelocity! * _inputGain,
      ),
    );
    _scaledDrag = null;
    _finishDirectInput();
  }

  void _cancelScaledDrag() {
    _scaledDrag?.cancel();
    _scaledDrag = null;
    _finishDirectInput();
  }

  void _onScaledDragCancelledByPosition() {
    _scaledDrag = null;
    _finishDirectInput();
  }

  void _finishDirectInput() {
    if (!_directInputIsDown) return;
    _directInputIsDown = false;
    _carouselController.noteDirectPointerEnded();
  }

  void _commitCrossing(int logicalIndex) {
    final delta = logicalIndex - _lastLogicalIndex;
    _lastLogicalIndex = logicalIndex;
    if (delta == 0) return;
    final target = DashboardModeSpec
        .values[_positiveModulo(logicalIndex, DashboardModeSpec.values.length)];
    if (target == widget.controller.committedMode) return;
    widget.controller.commitModeTarget(
      target,
      delta > 0
          ? DashboardCoreModeDirection.forward
          : DashboardCoreModeDirection.backward,
    );
  }

  static bool _sameVisualInputs(
    DashboardHeaderModeSelector left,
    DashboardHeaderModeSelector right,
  ) =>
      identical(left.balanceVisualFrame, right.balanceVisualFrame) &&
      identical(left.budgetVisualFrame, right.budgetVisualFrame) &&
      identical(left.mindVisualFrame, right.mindVisualFrame);

  static int _indexOf(DashboardModeSpec mode) => DashboardModeSpec.values
      .indexWhere((candidate) => candidate.mode == mode.mode);

  static int _positiveModulo(int value, int divisor) {
    final result = value % divisor;
    return result < 0 ? result + divisor : result;
  }

  static String _modeLabel(DashboardModeSpec mode) => switch (mode.mode) {
    DashboardMode.balance => 'Balance',
    DashboardMode.budget => 'Budget',
    DashboardMode.mind => 'Mind',
  };

  @override
  void dispose() {
    _scaledDrag?.cancel();
    _detachVisualListeners(widget);
    _carouselController.dispose();
    super.dispose();
  }
}

/// This is intentionally local to the Header. The shared carousel's stock
/// scroll recognizer must keep its normal platform slop and physics for every
/// other consumer. The compact 32px Header lane needs its first real motion
/// sample immediately so the scaled delta remains a linear .5 mapping rather
/// than a delayed touch-slop approximation.
final class _HeaderModeInputGainDragRecognizer
    extends VerticalDragGestureRecognizer {
  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => true;
}
