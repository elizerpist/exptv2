import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'budget_allocation_partition_slider.dart';

/// Paint-ready, one-category allocation/progress truth.
///
/// It deliberately receives only already-resolved scalars.  The aggregate
/// partition remains the allocation authority; this small object makes the
/// selected category's edit range readable without creating a second
/// multi-category allocation calculation.
@immutable
final class CategoryLimitSliderPresentation {
  const CategoryLimitSliderPresentation._({
    required this.actualScaled100,
    required this.limitScaled100,
    required this.maxScaled100,
    required this.spentScaled100,
    required this.remainingAllocatedScaled100,
    required this.unallocatedCapacityScaled100,
    required this.overspendScaled100,
  });

  factory CategoryLimitSliderPresentation.resolve({
    required int actualScaled100,
    required int limitScaled100,
    required int maxScaled100,
  }) {
    final safeMax = maxScaled100 < 0 ? 0 : maxScaled100;
    final safeLimit = limitScaled100.clamp(0, safeMax).toInt();
    final safeActual = actualScaled100 < 0 ? 0 : actualScaled100;
    final spent = safeActual.clamp(0, safeLimit).toInt();
    return CategoryLimitSliderPresentation._(
      actualScaled100: safeActual,
      limitScaled100: safeLimit,
      maxScaled100: safeMax,
      spentScaled100: spent,
      remainingAllocatedScaled100: (safeLimit - spent)
          .clamp(0, safeLimit)
          .toInt(),
      unallocatedCapacityScaled100: (safeMax - safeLimit)
          .clamp(0, safeMax)
          .toInt(),
      overspendScaled100: (safeActual - safeLimit)
          .clamp(0, 0x7fffffffffffffff)
          .toInt(),
    );
  }

  final int actualScaled100;
  final int limitScaled100;
  final int maxScaled100;
  final int spentScaled100;
  final int remainingAllocatedScaled100;
  final int unallocatedCapacityScaled100;
  final int overspendScaled100;

  bool get isOverspent => overspendScaled100 > 0;
  bool get hasCapacity => maxScaled100 > 0;
  double get spentRatio => _ratio(spentScaled100);
  double get remainingAllocatedRatio => _ratio(remainingAllocatedScaled100);
  double get neutralCapacityRatio => _ratio(unallocatedCapacityScaled100);
  double get limitRatio => _ratio(limitScaled100);

  double _ratio(int value) =>
      maxScaled100 <= 0 ? 0 : (value / maxScaled100).clamp(0.0, 1.0).toDouble();
}

/// Direct-manipulation control for one category's exact-month limit.
///
/// The thumb is the limit; material before it distinguishes spent from
/// allocated-but-remaining.  It owns neither persistence nor repository
/// access: callers keep the draft and finalize one mutation on release.
final class CategoryLimitAllocationProgressSlider extends StatefulWidget {
  const CategoryLimitAllocationProgressSlider({
    required this.presentation,
    required this.accent,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final CategoryLimitSliderPresentation presentation;
  final Color accent;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  State<CategoryLimitAllocationProgressSlider> createState() =>
      _CategoryLimitAllocationProgressSliderState();
}

final class _CategoryLimitAllocationProgressSliderState
    extends State<CategoryLimitAllocationProgressSlider> {
  final GlobalKey _surfaceKey = GlobalKey();
  int? _lastPublished;
  bool _didChange = false;

  int get _current => widget.presentation.limitScaled100;

  int _valueAtGlobalDx(double globalDx) {
    final box = _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return _current;
    final localDx = box.globalToLocal(Offset(globalDx, 0)).dx;
    final ratio = (localDx / box.size.width).clamp(0.0, 1.0).toDouble();
    return BudgetAllocationPartitionSlider.snapToStep(
      amountScaled100: (widget.presentation.maxScaled100 * ratio).round(),
      maxScaled100: widget.presentation.maxScaled100,
    );
  }

  void _publishAt(double globalDx) {
    if (!widget.enabled || widget.presentation.maxScaled100 <= 0) return;
    final next = _valueAtGlobalDx(globalDx);
    if (next == _current || next == _lastPublished) return;
    _lastPublished = next;
    _didChange = true;
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _finish() {
    if (widget.enabled && _didChange) {
      widget.onChangeEnd(_lastPublished ?? _current);
    }
    _lastPublished = null;
    _didChange = false;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.presentation;
    return Semantics(
      slider: true,
      enabled: widget.enabled && value.hasCapacity,
      label: 'Kategória havi keret',
      value: '${value.limitScaled100 ~/ 100} Ft',
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
        onHorizontalDragCancel: _finish,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const thumbWidth = 12.0;
            const thumbHeight = 24.0;
            final maxLeft = (constraints.maxWidth - thumbWidth).clamp(
              0.0,
              double.infinity,
            );
            final left =
                (constraints.maxWidth * value.limitRatio - thumbWidth / 2)
                    .clamp(0.0, maxLeft)
                    .toDouble();
            return SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 6,
                    bottom: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: Color(0xffe3e7ef)),
                          ),
                          FractionallySizedBox(
                            widthFactor: value.limitRatio,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: .36),
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: value.spentRatio,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: widget.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    key: const ValueKey<String>('category-limit-slider-thumb'),
                    left: left,
                    top: 1,
                    child: Container(
                      width: thumbWidth,
                      height: thumbHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(thumbWidth / 2),
                        border: Border.all(
                          color: widget.accent.withValues(alpha: .7),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .14),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
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
