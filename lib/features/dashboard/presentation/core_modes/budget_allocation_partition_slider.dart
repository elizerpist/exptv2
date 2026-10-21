import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../dashboard/application/dashboard_budget_presentation_controller.dart';
import 'budget_allocation_partition_lane.dart';

/// The interactive counterpart of [BudgetAllocationPartitionLane].  It owns
/// only pointer-to-snapped-value geometry; callers keep the FinancialLimit
/// draft and choose the one release-time persistence operation.
final class BudgetAllocationPartitionSlider extends StatefulWidget {
  const BudgetAllocationPartitionSlider({
    required this.partition,
    required this.activeCategoryHandle,
    required this.valueScaled100,
    required this.maxScaled100,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  /// 1,000 Ft in the canonical scaled-money representation.
  static const stepScaled100 = 100000;

  /// Maximum allocation for one category without consuming another category's
  /// reserved share.  This is a presentation interaction range over the
  /// already-canonical partition; it deliberately owns no FinancialLimit
  /// persistence or allocation projection.
  static int maxForActiveCategory({
    required DashboardBudgetPartitionPresentation partition,
    required int activeCategoryHandle,
  }) {
    final active =
        partition.effectiveLimitForCategoryHandle(activeCategoryHandle) ?? 0;
    final other =
        (partition.liveAllocatedTotalScaled100 - (active > 0 ? active : 0))
            .clamp(0, 0x7fffffffffffffff)
            .toInt();
    return ((partition.effectiveAggregateLimitScaled100 ?? 0) - other)
        .clamp(0, 0x7fffffffffffffff)
        .toInt();
  }

  static int snapToStep({
    required int amountScaled100,
    required int maxScaled100,
  }) {
    if (maxScaled100 <= 0) return 0;
    final snapped = (amountScaled100 / stepScaled100).round() * stepScaled100;
    return snapped.clamp(0, maxScaled100).toInt();
  }

  final DashboardBudgetPartitionPresentation partition;
  final int activeCategoryHandle;
  final int valueScaled100;
  final int maxScaled100;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  State<BudgetAllocationPartitionSlider> createState() =>
      _BudgetAllocationPartitionSliderState();
}

final class _BudgetAllocationPartitionSliderState
    extends State<BudgetAllocationPartitionSlider> {
  final GlobalKey _surfaceKey = GlobalKey();
  int? _lastPublishedValue;
  bool _didChange = false;

  int get _clampedValue => widget.valueScaled100
      .clamp(0, widget.maxScaled100 < 0 ? 0 : widget.maxScaled100)
      .toInt();

  int _valueAtGlobalDx(double globalDx) {
    final box = _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) {
      return _clampedValue;
    }
    final localDx = box.globalToLocal(Offset(globalDx, 0)).dx;
    final ratio = (localDx / box.size.width).clamp(0.0, 1.0).toDouble();
    final raw = widget.maxScaled100 * ratio;
    return BudgetAllocationPartitionSlider.snapToStep(
      amountScaled100: raw.round(),
      maxScaled100: widget.maxScaled100,
    );
  }

  void _publishAt(double globalDx) {
    if (!widget.enabled) return;
    final next = _valueAtGlobalDx(globalDx);
    if (next == _lastPublishedValue || next == _clampedValue) return;
    _lastPublishedValue = next;
    _didChange = true;
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _finish() {
    if (!widget.enabled) return;
    if (_didChange) {
      widget.onChangeEnd(_lastPublishedValue ?? _clampedValue);
    }
    _lastPublishedValue = null;
    _didChange = false;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.maxScaled100 <= 0
        ? 0.0
        : (_clampedValue / widget.maxScaled100).clamp(0.0, 1.0).toDouble();
    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: 'Kategória keret kiosztása',
      value: '${_clampedValue ~/ 100} Ft',
      child: GestureDetector(
        key: _surfaceKey,
        behavior: HitTestBehavior.translucent,
        onTapUp: widget.enabled
            ? (details) {
                _publishAt(details.globalPosition.dx);
                _finish();
              }
            : null,
        onHorizontalDragUpdate: widget.enabled
            ? (details) => _publishAt(details.globalPosition.dx)
            : null,
        onHorizontalDragEnd: widget.enabled ? (_) => _finish() : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const handleWidth = 12.0;
            const handleHeight = 24.0;
            final maxLeft = (constraints.maxWidth - handleWidth).clamp(
              0.0,
              double.infinity,
            );
            final left = (constraints.maxWidth * ratio - handleWidth / 2)
                .clamp(0.0, maxLeft)
                .toDouble();
            return SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 4,
                    bottom: 4,
                    child: BudgetAllocationPartitionLane(
                      partition: widget.partition,
                      highlightedCategoryHandle: widget.activeCategoryHandle,
                    ),
                  ),
                  Positioned(
                    key: const ValueKey<String>(
                      'budget-allocation-partition-slider-handle',
                    ),
                    left: left,
                    top: 1,
                    child: Container(
                      width: handleWidth,
                      height: handleHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(handleWidth / 2),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .16),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
