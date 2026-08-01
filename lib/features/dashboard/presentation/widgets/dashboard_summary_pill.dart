import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/presentation/summary_pill_view_model.dart';

/// Presentation-only summary and time-navigation entry point.
class DashboardSummaryPill extends StatefulWidget {
  const DashboardSummaryPill({
    super.key,
    required this.bounds,
    this.viewModel,
    this.onToggleRail,
    this.onMoveFiner,
    this.onMoveBroader,
    this.onMovePrevious,
    this.onMoveNext,
    // Kept source-compatible for the original primitive tests/callers.
    this.isRailVisible,
    this.onChevronTap,
  });

  final DashboardBounds bounds;
  final SummaryPillViewModel? viewModel;
  final VoidCallback? onToggleRail;
  final VoidCallback? onMoveFiner;
  final VoidCallback? onMoveBroader;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onMoveNext;

  final bool? isRailVisible;
  final VoidCallback? onChevronTap;

  @override
  State<DashboardSummaryPill> createState() => _DashboardSummaryPillState();
}

class _DashboardSummaryPillState extends State<DashboardSummaryPill> {
  _SummaryGestureAxis? _axis;
  double _dx = 0;
  double _dy = 0;
  Offset _contentEntryOffset = const Offset(0, 0.35);

  SummaryPillViewModel get _viewModel =>
      widget.viewModel ??
      SummaryPillViewModel(
        plane: TimePlane.month,
        periodLabel: 'Aktuális hónap',
        planeLabel: 'Hónap',
        amountText: '—',
        isRailOpen: widget.isRailVisible ?? false,
        isLoading: false,
        hasError: false,
      );

  VoidCallback get _toggleRail =>
      widget.onToggleRail ?? widget.onChevronTap ?? () {};

  @override
  Widget build(BuildContext context) {
    final model = _viewModel;
    final chevron = model.isRailOpen
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
    final chevronWidget = model.isRailOpen
        ? FluviHighlightMask(
            child: Icon(
              chevron,
              color: Colors.white,
              size: FluviVisualTokens.iconSize,
            ),
          )
        : Icon(
            chevron,
            color: FluviVisualTokens.textSecondary,
            size: FluviVisualTokens.iconSize,
          );

    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _axis = null;
          _dx = 0;
          _dy = 0;
        },
        onPanUpdate: (details) {
          _dx += details.delta.dx;
          _dy += details.delta.dy;
          _axis ??= _axisFor(_dx, _dy);
        },
        onPanEnd: (_) => _finishSwipe(),
        child: FluviRoundedBox(
          color: FluviVisualTokens.surface,
          child: Row(
            children: [
              const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
              const Icon(
                Icons.calendar_month_outlined,
                color: FluviVisualTokens.textSecondary,
                size: FluviVisualTokens.iconSize,
              ),
              const SizedBox(width: FluviVisualTokens.controlInnerGap),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: _contentEntryOffset,
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: Column(
                      key: ValueKey<String>(
                        '${model.plane.name}:${model.periodLabel}',
                      ),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.periodLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FluviVisualTokens.summaryLabelTextStyle,
                        ),
                        Text(
                          model.planeLabel,
                          style: FluviVisualTokens.summaryPlaneTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (model.amountText != '—')
                Padding(
                  padding: const EdgeInsets.only(
                    right: FluviVisualTokens.controlInnerGap,
                  ),
                  child: Opacity(
                    opacity: model.isLoading ? .55 : 1,
                    child: Text(
                      model.amountText,
                      style: FluviVisualTokens.summaryAmountTextStyle,
                    ),
                  ),
                ),
              Semantics(
                button: true,
                label: model.isRailOpen
                    ? 'Időválasztó bezárása'
                    : 'Időválasztó megnyitása',
                child: GestureDetector(
                  key: const ValueKey('dashboard-summary-chevron'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleRail,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: chevronWidget,
                  ),
                ),
              ),
              const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
            ],
          ),
        ),
      ),
    );
  }

  void _finishSwipe() {
    final axis = _axis;
    if (axis == _SummaryGestureAxis.vertical) {
      if (_dy < 0) {
        _commitNavigation(widget.onMoveFiner, const Offset(0, 1));
      } else if (_dy > 0) {
        _commitNavigation(widget.onMoveBroader, const Offset(0, -1));
      }
    } else if (axis == _SummaryGestureAxis.horizontal) {
      if (_dx < 0) {
        _commitNavigation(widget.onMoveNext, const Offset(1, 0));
      } else if (_dx > 0) {
        _commitNavigation(widget.onMovePrevious, const Offset(-1, 0));
      }
    }
    _axis = null;
    _dx = 0;
    _dy = 0;
  }

  void _commitNavigation(VoidCallback? callback, Offset entryOffset) {
    if (callback == null) return;
    _contentEntryOffset = entryOffset;
    callback();
  }

  _SummaryGestureAxis? _axisFor(double dx, double dy) {
    if (dx.abs() > 18 || dy.abs() > 18) {
      if (dx.abs() > dy.abs() * 1.25) return _SummaryGestureAxis.horizontal;
      if (dy.abs() > dx.abs() * 1.25) return _SummaryGestureAxis.vertical;
    }
    return null;
  }
}

enum _SummaryGestureAxis { horizontal, vertical }
