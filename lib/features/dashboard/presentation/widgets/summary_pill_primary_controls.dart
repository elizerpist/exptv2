import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

/// The bounded primary controls inside the existing SummaryPill.
///
/// These controllers own only visual preview and shared-carousel motion. A
/// settled selection is forwarded to the existing prepared navigation path;
/// neither controller owns time, query, or Ledger state.
final class SummaryPillPrimaryControls extends StatefulWidget {
  const SummaryPillPrimaryControls({
    super.key,
    required this.height,
    required this.navigation,
    required this.onSelectPlaneTarget,
    required this.motherLabelForOffset,
    required this.onSelectMotherOffset,
    required this.railFeedback,
    this.onMotionActiveChanged,
  });

  final double height;
  final DashboardNavigationController navigation;
  final void Function(TimePlane target, {required bool finer})
  onSelectPlaneTarget;
  final String? Function(int offset) motherLabelForOffset;
  final ValueChanged<int> onSelectMotherOffset;
  final Widget railFeedback;
  final ValueChanged<bool>? onMotionActiveChanged;

  @override
  State<SummaryPillPrimaryControls> createState() =>
      _SummaryPillPrimaryControlsState();
}

final class _SummaryPillPrimaryControlsState
    extends State<SummaryPillPrimaryControls> {
  // The order is deliberately reversed from [TimePlane.values]: a physical
  // down-drag decreases the logical ListView index and therefore selects the
  // existing finer direction (SUM -> YEAR -> MONTH).
  static const _axisItems = <TimePlane>[
    TimePlane.sum,
    TimePlane.month,
    TimePlane.year,
  ];

  // The generated belt mounts a distant physical slot before its first
  // anchor-centering frame. Only the shared ballistic profile's reachable
  // selection window may ask the time-navigation owner for a sibling.
  static final _maximumMotherPreviewOffset =
      CenteredCarouselMotionProfiles.timeRefinementRail.maxItemsPerFling;

  late final CenteredCarouselController _axisController;
  late final CenteredCarouselController _motherController;
  late TimePlane _observedPlane;
  late Object _observedParentKey;
  late bool _observedRailOpen;
  int _axisMotionStartLogicalIndex = 0;

  @override
  void initState() {
    super.initState();
    _observedPlane = widget.navigation.state.plane;
    _observedParentKey = widget.navigation.state.parentQueryKey;
    _observedRailOpen = widget.navigation.state.isRailOpen;
    _axisController = CenteredCarouselController(
      initialIndex: _axisLogicalIndex(_observedPlane),
    );
    _motherController = CenteredCarouselController(initialIndex: 0);
    widget.navigation.addListener(_handleNavigationChanged);
  }

  @override
  void didUpdateWidget(covariant SummaryPillPrimaryControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.navigation, widget.navigation)) {
      oldWidget.navigation.removeListener(_handleNavigationChanged);
      _observedPlane = widget.navigation.state.plane;
      _observedParentKey = widget.navigation.state.parentQueryKey;
      _observedRailOpen = widget.navigation.state.isRailOpen;
      widget.navigation.addListener(_handleNavigationChanged);
      _axisController.jumpToIndexSilently(_axisLogicalIndex(_observedPlane));
      _motherController.jumpToIndexSilently(0);
    }
  }

  void _handleNavigationChanged() {
    final state = widget.navigation.state;
    final planeChanged = state.plane != _observedPlane;
    final parentChanged = state.parentQueryKey != _observedParentKey;
    final railChanged = state.isRailOpen != _observedRailOpen;
    if (!planeChanged && !parentChanged && !railChanged) return;
    _observedPlane = state.plane;
    _observedParentKey = state.parentQueryKey;
    _observedRailOpen = state.isRailOpen;
    if (planeChanged) {
      _axisController.jumpToIndexSilently(_axisLogicalIndex(state.plane));
    }
    _motherController.jumpToIndexSilently(0);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plane = widget.navigation.state.plane;
    final railOpen = widget.navigation.state.isRailOpen;
    final currentMotherLabel = _motherLabelForCurrentState();
    final nextMotherLabel = railOpen ? _motherLabelForOffset(1) : null;
    final previousMotherLabel = railOpen ? _motherLabelForOffset(-1) : null;
    final motherCarousel = plane == TimePlane.sum
        ? Semantics(
            label: 'Időszak: Minden időszak. Nincs testvér időszak.',
            child: Center(child: _MotherLabel(label: currentMotherLabel)),
          )
        : _buildMotherSelector();
    final motherSurface = Opacity(
      // The child-feedback overlay owns the open-rail copy, but the mother
      // carousel remains hit-testable underneath it. Keeping its stable
      // ScrollPosition attached preserves the primary horizontal control while
      // the child rail is open.
      opacity: railOpen ? 0 : 1,
      child: motherCarousel,
    );
    return Row(
      children: [
        SizedBox(
          key: const ValueKey('dashboard-summary-axis-selector'),
          width:
              FluviVisualTokens.iconSize +
              FluviVisualTokens.controlInnerGap * 2,
          height: widget.height,
          child: Semantics(
            label:
                'Időtengely: ${_planeSemantics(plane)}. '
                'Függőlegesen húzva válthat.',
            child: CenteredCarousel<TimePlane>(
              dataSource: const CyclicCarouselDataSource<TimePlane>(_axisItems),
              controller: _axisController,
              spec: CenteredCarouselSpec(
                itemExtent: widget.height,
                scrollDirection: Axis.vertical,
                visibleItemCount: 1,
                minScale: 1,
                neighborScale: 1,
                outerScale: 1,
                minOpacity: 1,
                neighborOpacity: 1,
                outerOpacity: 1,
                enableHaptics: true,
              ),
              height: widget.height,
              viewportKey: const ValueKey(
                'dashboard-summary-axis-carousel-viewport',
              ),
              semanticsLabelBuilder: (item) =>
                  'Időtengely: ${_planeSemantics(item)}',
              onMotionStarted: (_) {
                _axisMotionStartLogicalIndex = _axisController.selectedIndex;
                widget.onMotionActiveChanged?.call(true);
              },
              onMotionIdle: (_) => widget.onMotionActiveChanged?.call(false),
              onSelectionSettled: _settleAxis,
              itemBuilder: (context, item, metrics) => Icon(
                _iconFor(item),
                key: ValueKey('dashboard-summary-axis-${item.name}'),
                color: metrics.isSelected
                    ? FluviVisualTokens.textPrimary
                    : FluviVisualTokens.textSecondary,
                size: FluviVisualTokens.iconSize,
              ),
            ),
          ),
        ),
        Container(
          key: const ValueKey('dashboard-summary-axis-separator'),
          width: 1,
          height: widget.height - FluviVisualTokens.controlInnerGap * 2,
          color: FluviVisualTokens.border,
        ),
        Expanded(
          child: SizedBox(
            key: const ValueKey('dashboard-summary-mother-selector'),
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (railOpen)
                  Semantics(
                    key: const ValueKey(
                      'dashboard-summary-open-mother-semantics',
                    ),
                    label:
                        'Időszak: $currentMotherLabel. '
                        'Vízszintesen húzva testvér időszakot választhat.',
                    value: currentMotherLabel,
                    increasedValue: nextMotherLabel,
                    decreasedValue: previousMotherLabel,
                    onIncrease: nextMotherLabel == null
                        ? null
                        : () => _settleMother(1),
                    onDecrease: previousMotherLabel == null
                        ? null
                        : () => _settleMother(-1),
                    child: ExcludeSemantics(child: motherSurface),
                  )
                else
                  motherSurface,
                if (railOpen)
                  _PointerTransparentSemantics(
                    // The visual feedback must not block the physical
                    // carousel below, but it remains a readable child-context
                    // semantic node beside the actionable mother control.
                    child: widget.railFeedback,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMotherSelector() => LayoutBuilder(
    builder: (context, constraints) {
      final itemExtent = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
      return Semantics(
        label:
            'Időszak: ${_motherLabelForCurrentState()}. '
            'Vízszintesen húzva testvér időszakot választhat.',
        child: CenteredCarousel<int>(
          dataSource: GeneratedCarouselDataSource<int>((index) => index),
          controller: _motherController,
          spec: CenteredCarouselSpec(
            itemExtent: itemExtent,
            visibleItemCount: 1,
            minScale: 1,
            neighborScale: 1,
            outerScale: 1,
            minOpacity: 1,
            neighborOpacity: 1,
            outerOpacity: 1,
            enableHaptics: true,
          ),
          height: widget.height,
          viewportKey: const ValueKey(
            'dashboard-summary-mother-carousel-viewport',
          ),
          semanticsLabelBuilder: (offset) {
            final label = _motherLabelForOffset(offset);
            return label == null ? 'Nem elérhető időszak' : 'Időszak: $label';
          },
          onMotionStarted: (_) => widget.onMotionActiveChanged?.call(true),
          onMotionIdle: (_) => widget.onMotionActiveChanged?.call(false),
          onSelectionSettled: _settleMother,
          itemBuilder: (context, offset, metrics) => _MotherLabel(
            // The generic infinite belt attaches at its virtual anchor after
            // its first layout. Until then it may build a distant slot; keep
            // the committed mother readable instead of painting a blank label.
            label:
                _motherLabelForOffset(offset) ?? _motherLabelForCurrentState(),
          ),
        ),
      );
    },
  );

  void _settleAxis(int logicalIndex) {
    final target = _axisItems[_positiveModulo(logicalIndex, _axisItems.length)];
    if (target == widget.navigation.state.plane) return;
    final delta = logicalIndex - _axisMotionStartLogicalIndex;
    if (delta == 0) return;
    widget.onSelectPlaneTarget(target, finer: delta.isNegative);
  }

  void _settleMother(int offset) {
    if (offset == 0) return;
    if (_motherLabelForOffset(offset) == null) {
      _motherController.jumpToIndexSilently(0);
      return;
    }
    widget.onSelectMotherOffset(offset);
  }

  String? _motherLabelForOffset(int offset) {
    if (offset.abs() > _maximumMotherPreviewOffset) return null;
    return widget.motherLabelForOffset(offset);
  }

  String _motherLabelForCurrentState() {
    final state = widget.navigation.state;
    return switch (state.plane) {
      TimePlane.sum => 'Minden időszak',
      TimePlane.year => state.yearCursor.toString(),
      TimePlane.month => DashboardTimeLabelFormatter.yearMonth(
        state.monthCursor,
      ),
    };
  }

  static int _axisLogicalIndex(TimePlane plane) => _axisItems.indexOf(plane);

  static int _positiveModulo(int value, int modulus) =>
      ((value % modulus) + modulus) % modulus;

  static String _planeSemantics(TimePlane plane) => switch (plane) {
    TimePlane.sum => 'Összesen',
    TimePlane.year => 'Éves',
    TimePlane.month => 'Havi',
  };

  static IconData _iconFor(TimePlane plane) => switch (plane) {
    TimePlane.sum => Icons.all_inclusive_rounded,
    TimePlane.year => Icons.calendar_today_rounded,
    TimePlane.month => Icons.calendar_month_rounded,
  };

  @override
  void dispose() {
    widget.navigation.removeListener(_handleNavigationChanged);
    _axisController.dispose();
    _motherController.dispose();
    super.dispose();
  }
}

/// Keeps an overlaid visual/semantic child out of the pointer hit-test path.
///
/// The former IgnorePointer semantics flag used to provide this split behavior,
/// but it is deprecated. The child remains in the semantics tree while the
/// underlying mother carousel remains the sole physical hit-test target.
final class _PointerTransparentSemantics extends SingleChildRenderObjectWidget {
  const _PointerTransparentSemantics({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PointerTransparentSemanticsRenderBox();
}

final class _PointerTransparentSemanticsRenderBox extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}

final class _MotherLabel extends StatelessWidget {
  const _MotherLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: FluviVisualTokens.controlInnerGap),
    child: FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(label, style: FluviVisualTokens.summaryTitleTextStyle),
    ),
  );
}
