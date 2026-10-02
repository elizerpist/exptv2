import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
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
  late final CenteredCarouselController _carouselController =
      CenteredCarouselController(initialIndex: _indexOf(widget.selectedMode));
  late int _lastLogicalIndex = _indexOf(widget.selectedMode);
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
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      'dashboard-header-mode-icon-${widget.selectedMode.mode.name}',
                    ),
                    child: _visualFor(widget.selectedMode.mode),
                  ),
                ),
              IgnorePointer(
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
                      // The Header's 32px viewport is smaller than the
                      // platform touch slop. Starting at pointer-down lets a
                      // user see real directional travel before the 16px
                      // centered-index crossing, while the shared physics
                      // remains entirely unchanged.
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
    _detachVisualListeners(widget);
    _carouselController.dispose();
    super.dispose();
  }
}
